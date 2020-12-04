subscriptionId=$(az account show --query id -o tsv)
adAppName="OpenPlatform-TSI-SP-Test-$subscriptionId"
echo $adAppName
servicePrincipalAppId=$(az ad app create --display-name $adAppName --identifier-uris "https://$adAppName"  --oauth2-allow-implicit-flow true --required-resource-accesses '[{"resourceAppId":"120d688d-1518-4cf7-bd38-182f158850b6","resourceAccess":[{"id":"a3a77dfe-67a4-4373-b02a-dfe8485e2248","type":"Scope"}]}]')
echo $servicePrincipalAppId > $AZ_SCRIPTS_OUTPUT_PATH