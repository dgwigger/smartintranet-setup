Function Get-TenantConfig {
  [cmdletbinding()]
  param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Name of the tenant"
    )][string]$Tenant
  )

  $TenantConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ../../tenants/$Tenant.yml
  if (-not(Test-Path -Path $TenantConfigPath -PathType Leaf)) {
    Write-Error "No tenant configuration for $Tenant found" -ErrorAction Stop
  }

  $Content = (Get-Content -Path $TenantConfigPath) -join "`n"
  $Config = ConvertFrom-Yaml $Content
  return $Config
}
