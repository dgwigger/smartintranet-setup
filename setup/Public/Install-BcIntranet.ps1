. './setup/Public/Functions.ps1'

function Install-BcIntranet {
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Name of the tenant'
        )][string]$Tenant,
        [Parameter(
            Mandatory = $false,
            HelpMessage = 'Skip Webpart Deployment'
        )][switch]$SkipWebpartDeployment
    )

    $tenantConfig = Get-TenantConfig -Tenant $Tenant  
    $generalConfig = Get-GeneralConfig

    Initialize-AdminConnection $tenantConfig
    if (-not($SkipWebpartDeployment)) {
        Publish-LatestWebpartsToTenant
    }

    New-SmartIntranet
} 