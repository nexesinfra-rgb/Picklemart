#requires -Version 5.1
param(
  [string]$Endpoint = "https://fra.cloud.appwrite.io/v1",
  [string]$ProjectId = "68e35cdc002643a034b3",
  [string]$DatabaseId = "68e39841002c733d8621",
  [string]$CollectionId = "profiles",
  [string]$ApiKey
)

if (-not $ApiKey) {
  Write-Error "ApiKey is required. Pass -ApiKey '<your_appwrite_api_key>'";
  exit 1
}

function Invoke-Appwrite {
  param(
    [string]$Method,
    [string]$Path,
    [object]$Body
  )
  $uri = "$Endpoint$Path"
  $headers = @{
    "X-Appwrite-Project" = $ProjectId
    "X-Appwrite-Key"     = $ApiKey
    "Content-Type"       = "application/json"
  }
  $json = $null
  if ($Body) { $json = ($Body | ConvertTo-Json -Depth 10) }
  try {
    if ($Method -eq "GET") {
      return Invoke-RestMethod -Method Get -Uri $uri -Headers $headers
    } else {
      return Invoke-RestMethod -Method $Method -Uri $uri -Headers $headers -Body $json
    }
  } catch {
    Write-Warning ("{0} {1} failed: {2}" -f $Method, $Path, $_.Exception.Message)
    throw
  }
}

Write-Host "Creating collection '$CollectionId' in database '$DatabaseId'..."
$collectionBody = @{
  collectionId     = $CollectionId
  name             = "Profiles"
  documentSecurity = $false
  enabled          = $true
  permissions      = @{
    create = @("role:users")
    read   = @("role:users")
    write  = @("role:users")
  }
}
try {
  Invoke-Appwrite -Method "POST" -Path "/databases/$DatabaseId/collections" -Body $collectionBody | Out-Null
} catch {
  Write-Warning "Collection may already exist. Continuing..."
}

function Add-StringAttribute {
  param(
    [string]$Key,
    [int]$Size,
    [bool]$Required,
    [bool]$Array = $false
  )
  $body = @{ key = $Key; size = $Size; required = $Required; array = $Array }
  try {
    Invoke-Appwrite -Method "POST" -Path "/databases/$DatabaseId/collections/$CollectionId/attributes/string" -Body $body | Out-Null
    Write-Host "Requested attribute '$Key' (string)"
  } catch {
    Write-Warning "Attribute '$Key' request failed or already exists. Continuing..."
  }
}

function Add-DateTimeAttribute {
  param(
    [string]$Key,
    [bool]$Required,
    [bool]$Array = $false
  )
  $body = @{ key = $Key; required = $Required; array = $Array }
  try {
    Invoke-Appwrite -Method "POST" -Path "/databases/$DatabaseId/collections/$CollectionId/attributes/datetime" -Body $body | Out-Null
    Write-Host "Requested attribute '$Key' (datetime)"
  } catch {
    Write-Warning "Attribute '$Key' request failed or already exists. Continuing..."
  }
}

# Attributes expected by the Flutter client
Add-StringAttribute    -Key "userId"     -Size 36  -Required $true
Add-StringAttribute    -Key "name"       -Size 128 -Required $true
Add-StringAttribute    -Key "email"      -Size 254 -Required $true
Add-StringAttribute    -Key "phone"      -Size 32  -Required $false
Add-StringAttribute    -Key "alias"      -Size 64  -Required $false
Add-StringAttribute    -Key "gender"     -Size 16  -Required $false
Add-DateTimeAttribute  -Key "dateOfBirth"           -Required $false
Add-DateTimeAttribute  -Key "createdAt"             -Required $true

# Poll until attributes are available
$expectedKeys = @("userId","name","email","phone","alias","gender","dateOfBirth","createdAt")
$deadline = (Get-Date).AddMinutes(2)
Write-Host "Waiting for attributes to become available..."
do {
  Start-Sleep -Seconds 3
  $coll = Invoke-Appwrite -Method "GET" -Path "/databases/$DatabaseId/collections/$CollectionId" -Body $null
  $present = @()
  $statuses = @{}
  if ($coll.attributes) {
    foreach ($attr in $coll.attributes) {
      $present += $attr.key
      $statuses[$attr.key] = $attr.status
    }
  }
  $missing = $expectedKeys | Where-Object { $_ -notin $present }
  $pending = $expectedKeys | Where-Object { ($statuses.ContainsKey($_)) -and ($statuses[$_] -ne "available") }
  Write-Host ("Ready: {0}/{1} | Pending: {2} | Missing: {3}" -f ($expectedKeys.Count - $missing.Count - $pending.Count), $expectedKeys.Count, $pending.Count, $missing.Count)
} while ((($missing.Count -gt 0) -or ($pending.Count -gt 0)) -and ((Get-Date) -lt $deadline))

function Create-Index {
  param(
    [string]$Key,
    [string]$Type,
    [string[]]$Attributes,
    [string[]]$Orders
  )
  $body = @{ key = $Key; type = $Type; attributes = $Attributes; orders = $Orders }
  try {
    Invoke-Appwrite -Method "POST" -Path "/databases/$DatabaseId/collections/$CollectionId/indexes" -Body $body | Out-Null
    Write-Host "Requested index '$Key' ($Type) on [$($Attributes -join ', ')]"
  } catch {
    Write-Warning "Index '$Key' request failed or already exists. Continuing..."
  }
}

Create-Index -Key "unique_userId" -Type "unique" -Attributes @("userId") -Orders @("ASC")
Create-Index -Key "idx_email"     -Type "key"    -Attributes @("email")  -Orders @("ASC")
Create-Index -Key "idx_alias"     -Type "key"    -Attributes @("alias")  -Orders @("ASC")
Create-Index -Key "idx_phone"     -Type "key"    -Attributes @("phone")  -Orders @("ASC")

$final = Invoke-Appwrite -Method "GET" -Path "/databases/$DatabaseId/collections/$CollectionId" -Body $null
Write-Host "Provisioning complete. Collection summary:"
Write-Output ($final | ConvertTo-Json -Depth 6)