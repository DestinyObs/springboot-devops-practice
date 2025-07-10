#!/bin/bash

# CORS Testing Script
# This script tests CORS configuration for the User Registration Service

BASE_URL="${1:-http://localhost:8080}"
TEST_ORIGIN="${2:-http://localhost:3000}"

echo "=============================================="
echo "CORS Configuration Test"
echo "=============================================="
echo "Testing CORS for: $BASE_URL"
echo "From origin: $TEST_ORIGIN"
echo ""

# Test 1: Preflight request for login endpoint
echo "Test 1: Preflight request (OPTIONS)"
echo "------------------------------------"
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Origin: $TEST_ORIGIN" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type,Authorization" \
    -X OPTIONS \
    "$BASE_URL/api/v1/auth/login")

echo "$response"
echo ""

# Test 2: Actual POST request
echo "Test 2: Actual POST request"
echo "----------------------------"
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Origin: $TEST_ORIGIN" \
    -H "Content-Type: application/json" \
    -X POST \
    "$BASE_URL/api/v1/auth/login" \
    -d '{"username":"invalid","password":"invalid"}')

echo "$response"
echo ""

# Test 3: Health endpoint
echo "Test 3: Health endpoint (GET)"
echo "------------------------------"
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Origin: $TEST_ORIGIN" \
    -X GET \
    "$BASE_URL/api/v1/health")

echo "$response"
echo ""

# Test 4: Swagger UI access
echo "Test 4: Swagger UI access"
echo "--------------------------"
response=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -H "Origin: $TEST_ORIGIN" \
    -X GET \
    "$BASE_URL/swagger-ui.html")

if [[ "$response" == *"HTTP_CODE:200"* ]]; then
    echo "✅ Swagger UI is accessible"
else
    echo "❌ Swagger UI access failed"
fi
echo ""

# Test 5: Check CORS headers
echo "Test 5: CORS Headers Check"
echo "---------------------------"
echo "Checking for CORS headers in response..."

headers=$(curl -s -I \
    -H "Origin: $TEST_ORIGIN" \
    -H "Access-Control-Request-Method: POST" \
    -H "Access-Control-Request-Headers: Content-Type" \
    -X OPTIONS \
    "$BASE_URL/api/v1/auth/login")

echo "Response headers:"
echo "$headers" | grep -i "access-control"
echo ""

# Summary
echo "=============================================="
echo "Test Summary"
echo "=============================================="
echo ""

if echo "$headers" | grep -q "Access-Control-Allow-Origin"; then
    echo "✅ CORS is configured"
    origin_header=$(echo "$headers" | grep -i "access-control-allow-origin" | head -1)
    echo "   $origin_header"
else
    echo "❌ CORS headers not found"
fi

if echo "$headers" | grep -q "Access-Control-Allow-Methods"; then
    methods_header=$(echo "$headers" | grep -i "access-control-allow-methods" | head -1)
    echo "✅ Allowed methods configured"
    echo "   $methods_header"
else
    echo "❌ Allowed methods not configured"
fi

if echo "$headers" | grep -q "Access-Control-Allow-Headers"; then
    headers_header=$(echo "$headers" | grep -i "access-control-allow-headers" | head -1)
    echo "✅ Allowed headers configured"
    echo "   $headers_header"
else
    echo "❌ Allowed headers not configured"
fi

echo ""
echo "💡 Tips for troubleshooting:"
echo "- Check your CORS_ALLOWED_ORIGINS environment variable"
echo "- Verify the origin '$TEST_ORIGIN' is allowed"
echo "- Check application logs for CORS-related errors"
echo "- Use browser developer tools to see CORS errors"
echo ""
echo "For more help, see CORS_CONFIGURATION.md"
echo "=============================================="
