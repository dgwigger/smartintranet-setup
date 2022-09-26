Function Initialize-AdminConnection {
  param(
    [Parameter(Mandatory = $true)][hashtable]$config
  )

  if ($global:BcAdminConnection) {
    return
  }
  Write-Output "Please provide account information to the admin connection with user '$($tenantConfig.SharePoint.AdminUpn)'"
  # BEESUPP-441: Change to modern authentication via interactive mode
  $global:BcAdminConnection = Connect-PnPOnline -Url $config.SharePoint.AdminUrl -Interactive -ReturnConnection
}
