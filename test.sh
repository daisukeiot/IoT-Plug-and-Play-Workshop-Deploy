#!/bin/bash

subscriptionId=$(az account show --query id -o tsv)

spName='OpenPlatform-TSI-SP'-"$subscriptionId"

echo 'Subscription ID ' $servicePrincipalObjectId
echo 'SPName ' spName