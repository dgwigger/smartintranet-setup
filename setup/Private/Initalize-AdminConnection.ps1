Function Initialize-AdminConnection {
  param(
    [Parameter(Mandatory = $true)][hashtable]$config
  )

  if ($global:BcAdminConnection) {
    return
  }
  Write-Output "Please provide account information to the admin connection"
  $global:BcAdminCred = Get-Credential -UserName $tenantConfig.SharePoint.AdminUpn
  $global:BcAdminConnection = Connect-PnPOnline -Url $config.SharePoint.AdminUrl -Credential $global:BcAdminCred -ReturnConnection
}
