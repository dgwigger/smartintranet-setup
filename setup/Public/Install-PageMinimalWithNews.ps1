. './setup/Public/Functions.ps1'

function Install-PageMinimalWithNews {
    [cmdletbinding()]
    param(
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Name of the tenant'
        )][string]$Tenant
    )

    $tenantConfig = Get-TenantConfig -Tenant $Tenant  
    $generalConfig = Get-GeneralConfig

    Initialize-AdminConnection $tenantConfig
    Add-PageMinimalWithNews
} 