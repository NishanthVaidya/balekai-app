# SSL Certificate Fix Guide for www.balekai.com

## Current Status
- **Certificate ARN**: `arn:aws:acm:us-east-1:422456985301:certificate/314d3959-54e4-4fdf-a300-0906d55cb9bc`
- **Domain**: `www.balekai.com`
- **Status**: FAILED (DNS validation not completed)
- **Validation Method**: DNS

## Required DNS Record

You need to add this CNAME record to your domain's DNS settings:

```
Type: CNAME
Name: _4e290a9f502d9751e15be5f32f77059f.www
Value: _bd8b21ba5d73b15714ded02759eaade0.xlfgrmvvlj.acm-validations.aws.
TTL: 300 (or default)
```

## Step-by-Step Fix

### Option 1: Fix Current Certificate (Recommended)

1. **Access your DNS provider** (wherever you manage DNS for `balekai.com`)
   - Common providers: GoDaddy, Namecheap, Cloudflare, Route 53, etc.

2. **Add the CNAME record**:
   - Go to DNS management
   - Add new record
   - Type: CNAME
   - Name: `_4e290a9f502d9751e15be5f32f77059f.www`
   - Value: `_bd8b21ba5d73b15714ded02759eaade0.xlfgrmvvlj.acm-validations.aws.`
   - TTL: 300 seconds

3. **Wait for validation** (5-30 minutes)

4. **Check certificate status**:
   ```bash
   aws acm describe-certificate --certificate-arn arn:aws:acm:us-east-1:422456985301:certificate/314d3959-54e4-4fdf-a300-0906d55cb9bc --region us-east-1 --query 'Certificate.Status'
   ```

### Option 2: Request New Certificate

If you can't access DNS settings or want a fresh start:

1. **Delete current certificate**:
   ```bash
   aws acm delete-certificate --certificate-arn arn:aws:acm:us-east-1:422456985301:certificate/314d3959-54e4-4fdf-a300-0906d55cb9bc --region us-east-1
   ```

2. **Request new certificate**:
   ```bash
   aws acm request-certificate --domain-name www.balekai.com --validation-method DNS --subject-alternative-names balekai.com --region us-east-1
   ```

3. **Get validation details**:
   ```bash
   aws acm describe-certificate --certificate-arn <NEW_CERTIFICATE_ARN> --region us-east-1 --query 'Certificate.DomainValidationOptions[0].ResourceRecord'
   ```

## After Certificate is Validated

Once your certificate shows "ISSUED" status, you can:

1. **Configure CloudFront** (if using):
   - Update distribution to use the validated certificate
   - Point to your ALB: `balekai-alb-new-626347040.us-east-1.elb.amazonaws.com`

2. **Configure Load Balancer** (if using):
   - Add HTTPS listener on port 443
   - Attach the validated certificate

3. **Update DNS**:
   - Point `www.balekai.com` to your CloudFront distribution or ALB

## Testing

After setup, test your SSL:
```bash
curl -I https://www.balekai.com
openssl s_client -connect www.balekai.com:443 -servername www.balekai.com
```

## Current Infrastructure

- **Load Balancer**: `balekai-alb-new-626347040.us-east-1.elb.amazonaws.com`
- **Backend**: Running on ECS with the ALB
- **Frontend**: Ready for deployment (Vercel recommended)

## Next Steps

1. Fix SSL certificate validation
2. Deploy frontend to Vercel or AWS
3. Configure domain routing
4. Test complete application

## Troubleshooting

If validation still fails after 30 minutes:
- Check DNS propagation: `dig _4e290a9f502d9751e15be5f32f77059f.www.balekai.com CNAME`
- Verify record format (no extra spaces, correct dots)
- Try requesting a new certificate with email validation instead
