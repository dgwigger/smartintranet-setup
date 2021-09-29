Function Show-BcTenantConfig {
  [cmdletbinding()]
  param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Name of the tenant"
    )][string]$Tenant,
    [Parameter(
        Mandatory = $false,
        HelpMessage = "Show the raw configuration rather then interpreting it"
    )][switch]$Raw
  )

  $TenantConfigPath = Join-Path -Path $PSScriptRoot -ChildPath ../../tenants/$Tenant.yml
  if (-not(Test-Path -Path $TenantConfigPath -PathType Leaf)) {
    Write-Error "No tenant configuration for $Tenant found" -ErrorAction Stop
  }

  if ($Raw) {
    Write-Output $( Get-Content -Path $TenantConfigPath )
    return
  }

  $c = Get-TenantConfig -Tenant $Tenant
  $d = Get-DefaultTenantConfig -Tenant $Tenant

  $Title = "Configuration for $( $c.Tenant )"
  Write-Output "$Title`n$( "=" * $Title.Length )"

  Write-Output "`nSharePoint Settings"
  Write-OutputCompared "- Site" "SharePoint.PortalSite" $c $d

  Write-Output "`nInstallations"
  Write-InstallHint "Base" $c
}

Function Get-DefaultTenantConfig {
  param(
    [Parameter(
        Mandatory = $true,
        HelpMessage = "Name of the tenant"
    )][string]$Tenant
  )

  $Binding = @{
    Tenant = $Tenant
  }

  $TemplatePath = Join-Path -Path $PSScriptRoot -ChildPath ../../templates/tenantConfig.eps -Resolve
  $Content = Invoke-EpsTemplate -Path $TemplatePath -Binding $Binding
  return ConvertFrom-Yaml $Content
}

Function Get-NestedValue {
  param(
    [Parameter(Mandatory = $true)][string]$Property,
    [Parameter(Mandatory = $true)][hashtable]$Object
  )

  $Path = $Property -split '\.'
  $Position = $Object
  $Path | ForEach-Object { $Position = $Position.$_ }
  return $Position
}

Function Write-OutputCompared {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$Property,
    [Parameter(Mandatory = $true)][hashtable]$c,
    [Parameter(Mandatory = $true)][hashtable]$d
  )

  $cValue = Get-NestedValue $Property $c
  $dValue = Get-NestedValue $Property $d
  $append = ""
  if ($cValue -ne $dValue) {
    $append = "*"
  }
  return "$Label`: $cValue$append"
}

Function Write-InstallHint {
  param(
    [Parameter(Mandatory = $true)][string]$Item,
    [Parameter(Mandatory = $true)][hashtable]$c
  )

  if (!$c.ContainsKey("Installation")) {
    return "- $Item (pending)"
  }

  $i = $c.Installation
  if (!$i.ContainsKey($Item)) {
    return "- $Item (pending)"
  }

  $timestamp = ([datetime]$i.$Item.Date).ToShortDateString()
  return "- $Item ($($i.$Item.Maintainer) @ $timestamp)"
}
