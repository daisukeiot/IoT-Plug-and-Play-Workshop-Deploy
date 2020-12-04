$progressPreference = 'silentlyContinue'
$ErrorActionPreference = 'silentlyContinue'
$WarningPreference = "SilentlyContinue"

$DeploymentScriptOutputs = @{}

Install-Module -Name Az.AzureAD -SkipPublisherCheck -Force -AcceptLicense -AllowClobber > $output

$DeploymentScriptOutputs['output'] = $out