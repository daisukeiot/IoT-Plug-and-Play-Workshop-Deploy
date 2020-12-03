param([string] [Parameter(Mandatory=$true)] $subscriptionId,
      [string] [Parameter(Mandatory=$true)] $mapSubscriptionKey
)

$DeploymentScriptOutputs = @{}
$Debug = $false
$SleepTime = 5.0
$global:progressPreference = 'silentlyContinue'
$global:ErrorActionPreference = 'silentlyContinue'

Write-Host "Azure Subscription ID $($subscriptionId)"
Write-Host "Azure Map Subscription key $($mapSubscriptionKey)"

#$mapSubscriptionKey = "RBi-MAGMlhhUrt4UNZGtUuZd3gOzSzuEqz5gw8Vpu4M"
$mapSubscriptionKey = "d0ds-Qlako5q0oX0UvVMZp52uaDIZ3NoP2c5W37OySM"

$spName="IoTPnPWS-TSI-SP-$($subscriptionId)"

$servicePrincipalAppId=(az ad app list --show-mine --query "[?displayName==$($spName)].appId" -o tsv)

if ($servicePrincipalAppId -eq $null )
{
    servicePrincipalAppId=(az ad app create --display-name $($spName) --identifier-uris "https://$($spName)"  --oauth2-allow-implicit-flow true --required-resource-accesses '[{"resourceAppId":"120d688d-1518-4cf7-bd38-182f158850b6","resourceAccess":[{"id":"a3a77dfe-67a4-4373-b02a-dfe8485e2248","type":"Scope"}]}]' --query appId -o tsv)
}

$servicePrincipalObjectId=(az ad sp list --show-mine --query "[?appDisplayName==$($spName)].objectId" -o tsv)

if ($servicePrincipalObjectId -eq $null)
{
    $servicePrincipalObjectId=(az ad sp create --id $servicePrincipalAppId --query objectId -o tsv)
}

$servicePrincipalSecret=(az ad app credential reset --append --id $servicePrincipalAppId --credential-description "TSISecret" --query password -o tsv)
$servicePrincipalTenantId=(az ad sp show --id $servicePrincipalAppId --query appOwnerTenantId -o tsv)

echo 'Service Principal App Id    :' $servicePrincipalAppId
echo 'Service Principal Password  :' $servicePrincipalSecret
echo 'Service Principal Tenant Id :' $servicePrincipalTenantId
echo 'Service Principal Object Id :' $servicePrincipalObjectId

$DeploymentScriptOutputs['servicePrincipalAppId'] = $servicePrincipalAppId
$DeploymentScriptOutputs['servicePrincipalSecret'] = $servicePrincipalSecret
$DeploymentScriptOutputs['servicePrincipalTenantId'] = $servicePrincipalTenantId
$DeploymentScriptOutputs['servicePrincipalObjectId'] = $servicePrincipalObjectId
##################################################
# Step 1 : Download sample Drawing data
##################################################
$url = "https://github.com/Azure-Samples/am-creator-indoor-data-examples/raw/master/Sample%20-%20Contoso%20Drawing%20Package.zip"
Invoke-WebRequest -Uri $url -Method Get -OutFile ".\Drawing.zip"

##################################################
# Step 2 : Upload Drawing data
##################################################
$url = "https://atlas.microsoft.com/mapData/upload?api-version=1.0&dataFormat=zip&subscription-key=$($mapSubscriptionKey)"
$resp = Invoke-WebRequest -Uri $url -Method Post -ContentType 'application/octet-stream' -InFile ".\Drawing.zip"

# Make sure the drawing was uploaded.
$url = "$($resp.Headers.Location)&subscription-key=$($mapSubscriptionKey)" 

do {
    $resp = Invoke-RestMethod -Uri $url -Method Get
    if ($resp.status -ne "Succeeded") {
        if ($Debug -eq $true) {
            Write-Host "Upload : $($resp.status)"
        }
        Start-Sleep -Seconds $SleepTime
    }
    else {
        Write-Host "Upload : completed"
        $resLocation = [uri]$resp.resourceLocation
        $udid = $resLocation.Segments[3]
        break;
    }
} while ($true)

$url = "https://atlas.microsoft.com/mapData/metadata/$($udid)?api-version=1.0&subscription-key=$($mapSubscriptionKey)"
Write-Host "Calling RESTful API at $($url)"
$resp = Invoke-RestMethod -Uri $url -Method Get

# double check status
if ($resp.uploadStatus -ne "Completed") {
    Write-Error "Upload Failed. Status : $($resp.uploadStatus)"
    return
}
$udid = $resp.udid

##################################################
# Step 3 : Convert a Drawing package
##################################################
$url = "https://atlas.microsoft.com/conversion/convert?subscription-key=$($mapSubscriptionKey)&api-version=1.0&udid=$($udid)&inputType=DWG"
Write-Host "Calling RESTful API at $($url)"
$resp = Invoke-WebRequest -Uri $url -Method Post
$url = "$($resp.Headers.Location)&subscription-key=$($mapSubscriptionKey)" 
$SleepTime = 1.0

do {
    $resp = Invoke-RestMethod -Uri $url -Method Get
    if ($resp.status -ne "Succeeded") {
        if ($Debug -eq $true) {
            Write-Host "Conversion : $($resp.status)"
        }
        Start-Sleep -Seconds $SleepTime
    }
    else {
        Write-Host "Conversion : completed"
        $resLocation = [uri]$resp.resourceLocation
        $conversionId = $resLocation.Segments[2]
        break;
    }
} while ($true)

##################################################
# Step 4 : Create a dataset
##################################################

$url = "https://atlas.microsoft.com/dataset/create?api-version=1.0&conversionID=$($conversionId)&type=facility&subscription-key=$($mapSubscriptionKey)"
Write-Host "Calling RESTful API at $($url)"
$resp = Invoke-WebRequest -Uri $url -Method Post
$url = "$($resp.Headers.Location)&subscription-key=$($mapSubscriptionKey)" 
$SleepTime = 1.0

do {
    $resp = Invoke-RestMethod -Uri $url -Method Get
    if ($resp.status -ne "Succeeded") {
        if ($Debug -eq $true) {
            Write-Host "Dataset : $($resp.status)"
        }
        Start-Sleep -Seconds $SleepTime
    }
    else {
        Write-Host "Dataset : completed"
        $resLocation = [uri]$resp.resourceLocation
        $dataSetId = $resLocation.Segments[2]
        break;
    }
} while ($true)

##################################################
# Step 5 : Create a tileset
##################################################
$url = "https://atlas.microsoft.com/tileset/create/vector?api-version=1.0&datasetID=$($dataSetId)&subscription-key=$($mapSubscriptionKey)"
Write-Host "Calling RESTful API at $($url)"
$resp = Invoke-WebRequest -Uri $url -Method Post
$url = "$($resp.Headers.Location)&subscription-key=$($mapSubscriptionKey)" 
$SleepTime = 1.0

do {
    $resp = Invoke-RestMethod -Uri $url -Method Get
    if ($resp.status -ne "Succeeded") {
        if ($Debug -eq $true) {

            Write-Host "Conversion : $($resp.status)"
        }
        Start-Sleep -Seconds $SleepTime
    }
    else {
        Write-Host "Conversion : completed"
        $resLocation = [uri]$resp.resourceLocation
        $tileSetId = $resLocation.Segments[2]
        break;
    }
} while ($true)

if ($Debug -eq $true) {
    #
    # Query Dataset
    #
    $url = "https://atlas.microsoft.com/wfs/datasets/$($dataSetId)/collections?subscription-key=$($mapSubscriptionKey)&api-version=1.0"
    Write-Host "Calling RESTful API at $($url)"
    $resp = Invoke-RestMethod -Uri $url -Method Get
    $url = "https://atlas.microsoft.com/wfs/datasets/$($dataSetId)/collections/unit/items?subscription-key=$($mapSubscriptionKey)&api-version=1.0"
}

##################################################
# Step 6 : Create a feature stateset
##################################################
$stateSet = '{
    "styles":[
       {
          "keyname":"occupied",
          "type":"boolean",
          "rules":[
             {
                "true":"#FF0000",
                "false":"#00FF00"
             }
          ]
       },
       {
          "keyname":"temperature",
          "type":"number",
          "rules":[
             {
                "range":{
                   "exclusiveMaximum":66
                },
                "color":"#00204e"
             },
             {
                "range":{
                   "minimum":66,
                   "exclusiveMaximum":70
                },
                "color":"#0278da"
             },
             {
                "range":{
                   "minimum":70,
                   "exclusiveMaximum":74
                },
                "color":"#187d1d"
             },
             {
                "range":{
                   "minimum":74,
                   "exclusiveMaximum":78
                },
                "color":"#fef200"
             },
             {
                "range":{
                   "minimum":78,
                   "exclusiveMaximum":82
                },
                "color":"#fe8c01"
             },
             {
                "range":{
                   "minimum":82
                },
                "color":"#e71123"
             }
          ]
       }
    ]
 }'

$url = "https://atlas.microsoft.com/featureState/stateset?api-version=1.0&datasetId=$($dataSetId)&subscription-key=$($mapSubscriptionKey)"
Write-Host "Calling RESTful API at $($url)"
$resp = Invoke-RestMethod -Uri $url -Method Post -ContentType 'application/json' -Body $stateSet
$stateSetId = $resp.statesetId

$DeploymentScriptOutputs['statesetId'] = $stateSetId

Write-Host "Stateset ID $($stateSetId)"
#
# Delete Map Data
#
$url = "https://atlas.microsoft.com/mapData?subscription-key=$($mapSubscriptionKey)&api-version=1.0"
$mapData = Invoke-RestMethod -Uri $url -Method Get

foreach ($mapDataItem in $mapData.mapDataList) {
    Write-Host "Deleting $($mapDataItem.udid)"
    $url = "https://atlas.microsoft.com/mapData/$($mapDataItem.udid)?subscription-key=$($mapSubscriptionKey)&api-version=1.0"
    Invoke-RestMethod -Uri $url -Method Delete
}