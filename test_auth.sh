#!/bin/bash

echo "🔐 Testing Authentication Endpoints"
echo "==================================="
echo ""

echo "1. Testing Firebase test endpoint:"
curl -s -X GET "http://localhost:8080/auth/test" | jq '.' 2>/dev/null || curl -s -X GET "http://localhost:8080/auth/test"
echo ""
echo ""

echo "2. Testing boards endpoint without auth (should fail with 401):"
curl -s -X GET "http://localhost:8080/boards" | jq '.' 2>/dev/null || curl -s -X GET "http://localhost:8080/boards"
echo ""
echo ""

echo "3. Testing boards endpoint with invalid token (should fail with 401):"
curl -s -X GET "http://localhost:8080/boards" \
  -H "Authorization: Bearer invalid-token" | jq '.' 2>/dev/null || curl -s -X GET "http://localhost:8080/boards" \
  -H "Authorization: Bearer invalid-token"
echo ""
echo ""

echo "4. Testing boards endpoint with valid-looking token (should fail with 401):"
curl -s -X GET "http://localhost:8080/boards" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6InRlc3QiLCJ0eXAiOiJKV1QifQ.test.test" | jq '.' 2>/dev/null || curl -s -X GET "http://localhost:8080/boards" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6InRlc3QiLCJ0eXAiOiJKV1QifQ.test.test"
echo ""
echo ""

echo "5. Testing POST boards without auth (should fail with 401):"
curl -s -X POST "http://localhost:8080/boards" \
  -H "Content-Type: application/json" \
  -d '{"name":"Security Test Board","ownerId":"test-user","ownerName":"Test User","isPrivate":false}' | jq '.' 2>/dev/null || curl -s -X POST "http://localhost:8080/boards" \
  -H "Content-Type: application/json" \
  -d '{"name":"Security Test Board","ownerId":"test-user","ownerName":"Test User","isPrivate":false}'
echo ""
