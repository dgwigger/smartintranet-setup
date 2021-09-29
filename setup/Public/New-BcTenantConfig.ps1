Function New-BcTenantConfig {
  [cmdletbinding()]
  param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Name of the tenant"
    )][string]$Tenant,
    [Parameter(
        Mandatory = $true,
        HelpMessage = "UPN of the Sharepoint Administrator"
    )][string]$AdminUpn,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Title of the Intranet Portal (Intranet Home)"
    )][string]$PortalTitle = "Intranet Home",
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Path to the Intranet Portal (sites/beeConnect)"
    )][string]$PortalSite = "sites/beeConnect"
  )

  $Binding = @{
    Tenant = $Tenant
    PortalSite = $PortalSite
    PortalTitle = $PortalTitle
    AdminUpn = $AdminUpn
  }

  $TenantConfigDirectory = Join-Path -Path $PSScriptRoot -ChildPath ../../tenants
  if (!(Test-Path $TenantConfigDirectory)) {
    [void](New-Item -ItemType Directory -Path $TenantConfigDirectory)
  }

  $TenantConfigPath = Join-Path -Path $TenantConfigDirectory -ChildPath "$($Tenant).yml"
  if (Test-Path -Path $TenantConfigPath -PathType Leaf) {
    Write-Warning "Tenant configuration already exists" -WarningAction Inquire
  }
  $TemplatePath = Join-Path -Path $PSScriptRoot -ChildPath ../../templates/tenantConfig.eps -Resolve
  $TenantConfig = Invoke-EpsTemplate -Path $TemplatePath -Binding $Binding

  $TenantConfig | Out-File -FilePath $TenantConfigPath -NoNewline
}
