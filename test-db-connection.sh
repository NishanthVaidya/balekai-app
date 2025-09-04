#!/bin/bash

echo "🔍 Testing RDS Database Connection"
echo "=================================="
echo ""

# Database details from AWS
DB_ENDPOINT="balekai-postgres-new.cy7yeimaywkm.us-east-1.rds.amazonaws.com"
DB_PORT="5432"
DB_NAME="balekai_db"

echo "📊 Database Information:"
echo "Endpoint: $DB_ENDPOINT"
echo "Port: $DB_PORT"
echo "Database: $DB_NAME"
echo ""

echo "🔐 Testing connectivity..."
# Test if we can reach the endpoint
if nc -z $DB_ENDPOINT $DB_PORT 2>/dev/null; then
    echo "✅ Port $DB_PORT is reachable on $DB_ENDPOINT"
else
    echo "❌ Cannot reach port $DB_PORT on $DB_ENDPOINT"
    echo "This might be due to security group restrictions"
fi

echo ""
echo "📋 Next Steps:"
echo "1. Verify security group allows access from App Runner"
echo "2. Test with actual database credentials"
echo "3. Verify database schema and tables"
echo ""
echo "🎯 Ready to proceed with App Runner setup!"
