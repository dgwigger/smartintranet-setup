Function Get-GeneralConfig {
  [cmdletbinding()]

  $ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "../../smartintranet.settings.yml"
  if (-not(Test-Path -Path $ConfigPath -PathType Leaf)) {
    Write-Error "No configuration file found found" -ErrorAction Stop
  }

  $Content = (Get-Content -Path $ConfigPath) -join "`n"
  return ConvertFrom-Yaml $Content
}
