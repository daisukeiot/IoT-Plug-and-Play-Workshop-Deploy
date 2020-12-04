param([string] [Parameter(Mandatory=$true)] $mapSubscriptionKey,
      [string] [Parameter(Mandatory=$true)] $resourceGroupName,
      [string] [Parameter(Mandatory=$true)] $webAppName
)

$DeploymentScriptOutputs = @{}
$Debug = $true
$global:progressPreference = 'silentlyContinue'
$global:ErrorActionPreference = 'silentlyContinue'

Write-Host "Azure Map Subscription key $($mapSubscriptionKey)"

# Install-Module -Name Az.AzureAD -SkipPublisherCheck -Force -AcceptLicense -AllowClobber
# Install-Module -Name Az.Websites -SkipPublisherCheck -Force -AcceptLicense -AllowClobber

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
$SleepTime = 3.0
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

Start-Sleep -Seconds 5
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

Start-Sleep -Seconds 5
##################################################
# Step 4 : Create a dataset
##################################################
$url = "https://atlas.microsoft.com/dataset/create?api-version=1.0&conversionID=$($conversionId)&type=facility&subscription-key=$($mapSubscriptionKey)"
Write-Host "Calling RESTful API at $($url)"
$resp = Invoke-WebRequest -Uri $url -Method Post
Write-Host "response status : $($resp.StatusCode)"
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

Start-Sleep -Seconds 5
##################################################
# Step 5 : Create a tileset
##################################################
$url = "https://atlas.microsoft.com/tileset/create/vector?api-version=1.0&datasetID=$($dataSetId)&subscription-key=$($mapSubscriptionKey)"
Write-Host "Calling RESTful API at $($url)"
$resp = Invoke-WebRequest -Uri $url -Method Post
Write-Host "response status : $($resp.StatusCode)"
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

Start-Sleep -Seconds 5
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
Write-Host "response status : $($resp.StatusCode)"
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

#
# Update for Webapp
#
$resourceGroupName = "PnPWS10"
$webapp = Get-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName
$appSettings = $webapp.SiteConfig.AppSettings

$newAppSettings = @{}
ForEach ($item in $appSettings) {
    $newAppSettings[$item.Name] = $item.Value
}

$newAppSettings['Azure__AzureMap__TilesetId'] = $tileSetId
$newAppSettings['Azure__AzureMap__StatesetId'] = $stateSetId



Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName  -AppSettings $newAppSettings

$resGroup = Get-AzResourceGroup -Name $resourceGroupName
$subscriptionId = ($resGroup.ResourceId.split('/'))[2]
$subscription = Get-AzSubscription -SubscriptionId $subscriptionId
$tenantId = $subscription.tenantId

$adAppName = "OpenPlatform-TSI-SP-$($subscriptionId)"
$adAppUri  = "https://$($adAppName)"
$adApp = Get-AzureRmADApplication -IdentifierUri $adAppUri
#$adApp = Get-AzureADApplication -Filter "identifierUris/any(uri:uri eq '$adAppUri')"

if ($adApp -eq $null)
{
    # create new app
    $adApp = New-AzureRmADApplication --display-name $adAppName --IdentifierUri $adAppUri 
    #$adApp = New-AzureADApplication -DisplayName $adAppName -IdentifierUris $adAppUri -Oauth2AllowImplicitFlow $true -RequiredResourceAccess '[{"resourceAppId":"120d688d-1518-4cf7-bd38-182f158850b6","resourceAccess":[{"id":"a3a77dfe-67a4-4373-b02a-dfe8485e2248","type":"Scope"}]}]'
}

$adAppObjectId = $adApp.ObjectId
#$adAppId = $adApp.AppId
$adAppId = $adApp.ApplicationId
$adSp = Get-AzureADServicePrincipal -Filter ("appId eq '{0}'" -f $adAppId)
$adSpObjectId = $adSp.ObjectId

$websiteHostName = "https://$($webapp.HostNames)"
Set-AzureADApplication -ObjectId $adAppObjectId -ReplyUrls @("$($websiteHostName)")

$appSecret = New-AzureADApplicationPasswordCredential -ObjectId $adAppObjectId  -CustomKeyIdentifier "TSISecret"
Write-Host "App App Id $($adAppId)"
Write-Host "App Object Id $($adAppObjectId)"
Write-Host "Tenant ID $($tenantId)"
Write-Host "SP Object ID $($adSpObjectId)"
Write-Host "App Secret $($appSecret.Value)"

$newAppSettings['Azure__TimeSeriesInsights__tsiSecret'] = $appSecret.Value
$newAppSettings['Azure__TimeSeriesInsights__clientId'] = $adAppId
$newAppSettings['Azure__TimeSeriesInsights__tenantId'] = $tenantId
Set-AzWebApp -ResourceGroupName $resourceGroupName -Name $webAppName  -AppSettings $newAppSettings

#Install-Module -Name Az.TimeSeriesInsights

Get-AzTimeSeriesInsightsEnvironment -ResourceGroupName $resourceGroupName