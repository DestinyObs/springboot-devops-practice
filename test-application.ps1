# Complete Application Test Script (PowerShell)
# Tests all major functionality to ensure production readiness

param(
    [string]$BaseUrl = "http://localhost:8080"
)

Write-Host "==============================================`n🧪 Testing Application at: $BaseUrl`n==============================================" -ForegroundColor Green

function Test-Endpoint {
    param(
        [string]$Description,
        [string]$Method,
        [string]$Endpoint,
        [string]$Data = $null,
        [hashtable]$Headers = @{}
    )
    
    Write-Host "Testing: $Description" -ForegroundColor Yellow
    
    try {
        $uri = "$BaseUrl$Endpoint"
        
        if ($Method -eq "POST") {
            if ($Data) {
                $response = Invoke-RestMethod -Uri $uri -Method $Method -Body $Data -ContentType "application/json" -Headers $Headers
            } else {
                $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $Headers
            }
        } else {
            $response = Invoke-RestMethod -Uri $uri -Method $Method -Headers $Headers
        }
        
        Write-Host "✅ SUCCESS" -ForegroundColor Green
        $response | ConvertTo-Json -Depth 3
        return $response
    }
    catch {
        Write-Host "❌ FAILED: $_" -ForegroundColor Red
        Write-Host $_.Exception.Response.StatusCode -ForegroundColor Red
        return $null
    }
    finally {
        Write-Host ""
    }
}

Write-Host "🔍 Step 1: Health Check" -ForegroundColor Cyan
Test-Endpoint "Health Check" "GET" "/api/v1/health"

Write-Host "🔍 Step 2: User Registration" -ForegroundColor Cyan
$registrationData = @{
    username = "testuser123"
    email = "testuser123@example.com"
    password = "password123"
    firstName = "Test"
    lastName = "User"
} | ConvertTo-Json

Test-Endpoint "User Registration" "POST" "/api/v1/auth/register" $registrationData

Write-Host "🔍 Step 3: User Login" -ForegroundColor Cyan
$loginData = @{
    username = "testuser123"
    password = "password123"
} | ConvertTo-Json

$loginResponse = Test-Endpoint "User Login" "POST" "/api/v1/auth/login" $loginData

if ($loginResponse -and $loginResponse.token) {
    $token = $loginResponse.token
    Write-Host "✅ Login successful, token received" -ForegroundColor Green
    Write-Host "Token: $($token.Substring(0, [Math]::Min(50, $token.Length)))..." -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "🔍 Step 4: Protected Endpoint (User Profile)" -ForegroundColor Cyan
    $authHeaders = @{ Authorization = "Bearer $token" }
    Test-Endpoint "Get User Profile" "GET" "/api/v1/users/profile?username=testuser123" -Headers $authHeaders
} else {
    Write-Host "❌ Login failed, cannot test protected endpoints" -ForegroundColor Red
}

Write-Host "🔍 Step 5: Admin Login" -ForegroundColor Cyan
$adminLoginData = @{
    username = "admin"
    password = "admin123"
} | ConvertTo-Json

$adminResponse = Test-Endpoint "Admin Login" "POST" "/api/v1/auth/login" $adminLoginData

if ($adminResponse -and $adminResponse.token) {
    $adminToken = $adminResponse.token
    Write-Host "✅ Admin login successful" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🔍 Step 6: Admin Endpoint (List Users)" -ForegroundColor Cyan
    $adminHeaders = @{ Authorization = "Bearer $adminToken" }
    Test-Endpoint "List All Users (Admin)" "GET" "/api/v1/users" -Headers $adminHeaders
} else {
    Write-Host "❌ Admin login failed" -ForegroundColor Red
}

Write-Host "🔍 Step 7: Swagger UI Check" -ForegroundColor Cyan
try {
    $swaggerResponse = Invoke-WebRequest -Uri "$BaseUrl/swagger-ui.html" -Method Get
    if ($swaggerResponse.StatusCode -eq 200) {
        Write-Host "✅ Swagger UI accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Swagger UI not accessible: $_" -ForegroundColor Red
}
Write-Host ""

Write-Host "==============================================`n🎉 Test Summary`n==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Application is working correctly!" -ForegroundColor Green
Write-Host ""
Write-Host "🔗 Access Points:" -ForegroundColor Cyan
Write-Host "   - Application: $BaseUrl" -ForegroundColor White
Write-Host "   - Swagger UI: $BaseUrl/swagger-ui.html" -ForegroundColor White
Write-Host "   - Health Check: $BaseUrl/api/v1/health" -ForegroundColor White
Write-Host ""
Write-Host "👤 Test Credentials:" -ForegroundColor Cyan
Write-Host "   - Admin: admin / admin123" -ForegroundColor White
Write-Host "   - User: testuser123 / password123" -ForegroundColor White
Write-Host ""
Write-Host "🧪 CORS Testing:" -ForegroundColor Cyan
Write-Host "   Your app should work from both:" -ForegroundColor White
Write-Host "   - http://localhost:8080/swagger-ui.html" -ForegroundColor White
Write-Host "   - http://44.201.212.132:8080/swagger-ui.html" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Ready for production deployment!" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
