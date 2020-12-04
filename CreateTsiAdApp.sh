subscriptionId=$(az account show --query id -o tsv)

adAppName='OpenPlatform-TSI-SP'-"$subscriptionId"
echo 'adAppName : ' $adAppName

servicePrincipalAppId=$(az ad app list --show-mine --query "[?displayName=='$adAppName'].appId" -o tsv)
echo 'servicePrincipalAppId : ' $servicePrincipalAppId

if [ -z "$servicePrincipalAppId" ]; then
    servicePrincipalAppId=$(az ad app create --display-name $adAppName --identifier-uris "https://$adAppName"  --oauth2-allow-implicit-flow true --required-resource-accesses '[{"resourceAppId":"120d688d-1518-4cf7-bd38-182f158850b6","resourceAccess":[{"id":"a3a77dfe-67a4-4373-b02a-dfe8485e2248","type":"Scope"}]}]' --query appId -o tsv)
fi

servicePrincipalObjectId=$(az ad sp list --show-mine --query "[?appDisplayName=='$adAppName'].objectId" -o tsv)
echo 'servicePrincipalObjectId : ' $servicePrincipalObjectId

if [ -z "$servicePrincipalObjectId" ]; then
    servicePrincipalObjectId=$(az ad sp create --id $servicePrincipalAppId --query objectId -o tsv)
fi

servicePrincipalSecret=$(az ad app credential reset --append --id $servicePrincipalAppId --credential-description "TSISecret" --query password -o tsv)
servicePrincipalTenantId=$(az ad sp show --id $servicePrincipalAppId --query appOwnerTenantId -o tsv)

echo 'servicePrincipalSecret : ' $servicePrincipalSecret
echo 'servicePrincipalTenantId : ' $servicePrincipalTenantId


json="{\"appId\":\"$servicePrincipalAppId\",\"spSecret\":\"$servicePrincipalSecret\",\"tenantId\":\"$servicePrincipalTenantId\",\"spObjectId\":\"$servicePrincipalObjectId\"}"
echo "$json" > $AZ_SCRIPTS_OUTPUT_PATH
