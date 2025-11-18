# ==========================================
# 1. CONFIGURATION
# ==========================================

# [ACTION REQUIRED] PASTE YOUR CONNECTED APP CREDENTIALS BELOW
$ClientId = "3MVG9dAEux2v1sLvTjGff_V961TUeeASROBdfkNEfOpRu08wXxNNHiEyy.HocoBaY9rnaTROCpNaqDwhN.p0w"
$ClientSecret = "54B075BCA497D76BA02488AAD66378379604154BEB5F257E9912469870AC22A9"

# Your Org Domain
$LoginDomain = "https://orgfarm-a04e6110eb-dev-ed.develop.my.salesforce.com"
$ApiEndpoint = "$LoginDomain/services/apexrest/UniversalQuery"

# Safety Check
if ($ClientId -eq "YOUR_CONSUMER_KEY_HERE") {
    Write-Host "⚠️  STOP: You must edit this file and paste your Client ID and Secret." -ForegroundColor Red
    exit
}

Write-Host "----------------------------------------------------" -ForegroundColor Cyan
Write-Host "STEP 1: Authenticating..."
Write-Host "Flow: Client Credentials"
Write-Host "----------------------------------------------------" -ForegroundColor Cyan

# ==========================================
# 2. AUTHENTICATE (Get Access Token)
# ==========================================

$AuthUri = "$LoginDomain/services/oauth2/token"
$AuthBody = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
}

try {
    # Send the request to Salesforce to get the token
    $AuthResponse = Invoke-RestMethod -Method Post -Uri $AuthUri -Body $AuthBody
    
    # PowerShell automatically parses the JSON response
    $AccessToken = $AuthResponse.access_token
    
    if ([string]::IsNullOrEmpty($AccessToken)) {
        Write-Host "❌ Authentication Failed! No token received." -ForegroundColor Red
        exit
    }
    
    Write-Host "✅ Authentication Successful!" -ForegroundColor Green
    Write-Host "Token: $($AccessToken.Substring(0, 15))..." 
}
catch {
    Write-Host "❌ Authentication Failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message
    # Attempt to read detailed error stream if available
    if ($_.Exception.Response) {
        $Stream = $_.Exception.Response.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($Stream)
        Write-Host "Server Response: $($Reader.ReadToEnd())"
    }
    exit
}

Write-Host ""
Write-Host "----------------------------------------------------" -ForegroundColor Cyan
Write-Host "STEP 2: Verifying Identity via Universal Query..."
Write-Host "----------------------------------------------------" -ForegroundColor Cyan

# ==========================================
# 3. EXECUTE QUERY
# ==========================================

$Query = "SELECT Id, Name, Email, Username FROM User WHERE Username = 'arvind.balijepalli873@agentforce.com'"

Write-Host "Executing Query: $Query"
Write-Host ""

# Convert the body to JSON
$QueryBody = @{
    queryStr = $Query
} | ConvertTo-Json

# Set up the headers with the Bearer token
$Headers = @{
    Authorization = "Bearer $AccessToken"
    "Content-Type" = "application/json"
}

try {
    # Call the custom Apex REST Endpoint
    $ApiResponse = Invoke-RestMethod -Method Post -Uri $ApiEndpoint -Headers $Headers -Body $QueryBody
    
    # Output the results nicely
    Write-Host "✅ Query Response:" -ForegroundColor Green
    Write-Host ($ApiResponse | ConvertTo-Json -Depth 5)
}
catch {
    Write-Host "❌ Query Failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message
     if ($_.Exception.Response) {
        $Stream = $_.Exception.Response.GetResponseStream()
        $Reader = New-Object System.IO.StreamReader($Stream)
        Write-Host "Server Response: $($Reader.ReadToEnd())"
    }
}

Write-Host ""
Write-Host "Script Completed."