#!/bin/bash

subscriptionId=$(az account show --query id -o tsv)
adAppName='OpenPlatform-TSI-SP'-"$subscriptionId"
# az login --identity
servicePrincipalAppId=$(az ad app create --display-name $adAppName --identifier-uris "https://$adAppName"  --oauth2-allow-implicit-flow true --required-resource-accesses '[{"resourceAppId":"120d688d-1518-4cf7-bd38-182f158850b6","resourceAccess":[{"id":"a3a77dfe-67a4-4373-b02a-dfe8485e2248","type":"Scope"}]}]' --query appId -o tsv)
servicePrincipalObjectId=$(az ad sp list --show-mine --query "[?appDisplayName=='$adAppName'].objectId" -o tsv)
if [ -z "$servicePrincipalObjectId" ]; then
    servicePrincipalObjectId=$(az ad sp create --id $servicePrincipalAppId --query objectId -o tsv)
fi
servicePrincipalSecret=$(az ad app credential reset --append --id $servicePrincipalAppId --credential-description "TSISecret" --query password -o tsv)
servicePrincipalTenantId=$(az ad sp show --id $servicePrincipalAppId --query appOwnerTenantId -o tsv)
echo $("servicePrincipalSecret :   $servicePrincipalSecret")
echo $("servicePrincipalTenantId : $servicePrincipalTenantId")
json="{\"appId\":\"$servicePrincipalAppId\",\"spSecret\":\"$servicePrincipalSecret\",\"tenantId\":\"$servicePrincipalTenantId\",\"spObjectId\":\"$servicePrincipalObjectId\"}"
echo $("$json")
echo "$json" > $AZ_SCRIPTS_OUTPUT_PATH
