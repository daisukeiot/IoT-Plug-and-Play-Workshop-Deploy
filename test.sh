subscriptionId=$(az account show --query id -o tsv)
adAppName="OpenPlatform-TSI-SP-Test-$subscriptionId"
echo $adAppName
spApp=$(az ad app create --display-name $adAppName --identifier-uris "https://$adAppName")
echo $spApp > $AZ_SCRIPTS_OUTPUT_PATH