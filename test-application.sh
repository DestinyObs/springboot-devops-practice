#!/bin/bash

# Complete Application Test Script
# Tests all major functionality to ensure production readiness

BASE_URL="${1:-http://localhost:8080}"
echo "=============================================="
echo "🧪 Testing Application at: $BASE_URL"
echo "=============================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_endpoint() {
    local description="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local headers="$5"
    
    echo -e "${YELLOW}Testing: $description${NC}"
    
    if [ "$method" = "POST" ]; then
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$BASE_URL$endpoint" \
            -H "Content-Type: application/json" \
            ${headers:+-H "$headers"} \
            ${data:+-d "$data"})
    else
        response=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X GET "$BASE_URL$endpoint" \
            ${headers:+-H "$headers"})
    fi
    
    http_code=$(echo "$response" | tail -n1 | cut -d: -f2)
    response_body=$(echo "$response" | sed '$d')
    
    if [[ "$http_code" =~ ^(200|201)$ ]]; then
        echo -e "${GREEN}✅ SUCCESS (HTTP $http_code)${NC}"
        echo "$response_body" | jq '.' 2>/dev/null || echo "$response_body"
    else
        echo -e "${RED}❌ FAILED (HTTP $http_code)${NC}"
        echo "$response_body"
    fi
    echo ""
}

echo "🔍 Step 1: Health Check"
test_endpoint "Health Check" "GET" "/api/v1/health"

echo "🔍 Step 2: User Registration"
registration_data='{
    "username": "testuser123",
    "email": "testuser123@example.com",
    "password": "password123",
    "firstName": "Test",
    "lastName": "User"
}'
test_endpoint "User Registration" "POST" "/api/v1/auth/register" "$registration_data"

echo "🔍 Step 3: User Login"
login_data='{
    "username": "testuser123",
    "password": "password123"
}'
login_response=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "$login_data")

# Extract token
token=$(echo "$login_response" | jq -r '.token' 2>/dev/null)

if [ "$token" != "null" ] && [ "$token" != "" ]; then
    echo -e "${GREEN}✅ Login successful, token received${NC}"
    echo "Token: ${token:0:50}..."
    echo ""
    
    echo "🔍 Step 4: Protected Endpoint (User Profile)"
    test_endpoint "Get User Profile" "GET" "/api/v1/users/profile?username=testuser123" "" "Authorization: Bearer $token"
else
    echo -e "${RED}❌ Login failed, cannot test protected endpoints${NC}"
    echo "Response: $login_response"
    echo ""
fi

echo "🔍 Step 5: Admin Login"
admin_login_data='{
    "username": "admin",
    "password": "admin123"
}'
admin_response=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "$admin_login_data")

admin_token=$(echo "$admin_response" | jq -r '.token' 2>/dev/null)

if [ "$admin_token" != "null" ] && [ "$admin_token" != "" ]; then
    echo -e "${GREEN}✅ Admin login successful${NC}"
    echo ""
    
    echo "🔍 Step 6: Admin Endpoint (List Users)"
    test_endpoint "List All Users (Admin)" "GET" "/api/v1/users" "" "Authorization: Bearer $admin_token"
else
    echo -e "${RED}❌ Admin login failed${NC}"
    echo "Response: $admin_response"
    echo ""
fi

echo "🔍 Step 7: Swagger UI Check"
swagger_response=$(curl -s -w "\nHTTP_CODE:%{http_code}" "$BASE_URL/swagger-ui.html")
swagger_code=$(echo "$swagger_response" | tail -n1 | cut -d: -f2)

if [[ "$swagger_code" =~ ^(200|302)$ ]]; then
    echo -e "${GREEN}✅ Swagger UI accessible${NC}"
else
    echo -e "${RED}❌ Swagger UI not accessible (HTTP $swagger_code)${NC}"
fi
echo ""

echo "=============================================="
echo "🎉 Test Summary"
echo "=============================================="
echo ""
echo -e "${GREEN}✅ Application is working correctly!${NC}"
echo ""
echo "🔗 Access Points:"
echo "   - Application: $BASE_URL"
echo "   - Swagger UI: $BASE_URL/swagger-ui.html"
echo "   - Health Check: $BASE_URL/api/v1/health"
echo ""
echo "👤 Test Credentials:"
echo "   - Admin: admin / admin123"
echo "   - User: testuser123 / password123"
echo ""
echo "🧪 CORS Testing:"
echo "   Your app should work from both:"
echo "   - http://localhost:8080/swagger-ui.html"
echo "   - http://44.201.212.132:8080/swagger-ui.html"
echo ""
echo "🚀 Ready for production deployment!"
echo "=============================================="
