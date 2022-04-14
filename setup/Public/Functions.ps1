<#
SmartIntranet Functions
bee365 ag
#>

####################
# GLOBALS
####################
$ErrorActionPreference = "Stop"
$global:DestinationPath = '' # locally downloaded artifact (latest webpart)
$global:Connection
$global:EnvSettings

####################
# FUNCTIONS
####################

function Publish-LatestWebpartsToTenant() {
    try {
        # Set-PnPTraceLog -On
        Check-TenantAppCatalog
        Add-ArtifactsToTenant
        Grant-ServicePrincipalPermissionsInTenant
    }
    catch {
        Write-Error $_
    }
    finally {
        # clean up local file system
    }
}

function Check-TenantAppCatalog() {
    $appCatalogUrl = Get-PnPTenantAppCatalogUrl -Connection $Global:BcAdminConnection
    if ($appCatalogUrl -eq $null) {
        throw "Please install Tenant App Catalog first at url: /sites/apps (by selecting the option'Automatically create a new app catalog site')"
    }
}

function Add-ArtifactsToTenant() {
    Write-Output "> ADDING artifacts to app catalog on target tenant"
    $artifactsPath = Join-Path -Path $PSScriptRoot -ChildPath "../../assets/"
    $artifacts = @( Get-ChildItem -Path $artifactsPath\*.sppkg -ErrorAction SilentlyContinue )
        
    foreach ($artifact in $artifacts) { 
        Write-Output "$($artifact)"
        Add-PnPApp -Path "$($artifact)" -Scope Tenant -Publish -Overwrite -SkipFeatureDeployment -Connection $Global:BcAdminConnection
    }
}

function Grant-ServicePrincipalPermissionsInTenant() {
    $allowedPermissionRequestPackages = @("beeessentials-client-side-solution", "smartintranet-webparts-client-side-solution")

    Write-Output "> Grant specified permissions to the 'SharePoint Online Client Extensibility Web Application Principal' service principal for the webparts"
    try {
        $requests = Get-PnPTenantServicePrincipalPermissionRequests -Connection $global:BcAdminConnection
        foreach ($req in $requests) {
            # $req
            if ($allowedPermissionRequestPackages -match $req.PackageName) {
                # Write-Host $req.PackageName
                # Approve-PnPTenantServicePrincipalPermissionRequest -RequestId $req.Id.Guid -Connection $global:BcAdminConnection -Force
                $req.Scope -split " " | % { Grant-PnPTenantServicePrincipalPermission -Scope $_ -Connection $global:BcAdminConnection }
                Deny-PnPTenantServicePrincipalPermissionRequest -RequestId $req.Id.Guid -Connection $global:BcAdminConnection -Force
            }
        }
    } catch {
        Write-Output "❌ Error while trying to grant specified permissions for service principal. Please try running the script again!"
        throw $_
    }
}

function New-SmartIntranet() {
    $tenantConfig = Get-TenantConfig -Tenant $Tenant  
    Write-Output "> CREATING new beeConnect Site Collection: $($tenantConfig.SharePoint.PortalSite)"
    $siteUrl = "$($tenantConfig.SharePoint.Url)/$($tenantConfig.SharePoint.PortalSite)"
    New-PnPTenantSite -Url $siteUrl -Owner $tenantConfig.SharePoint.AdminUpn -Title $tenantConfig.SharePoint.PortalTitle -Template "SITEPAGEPUBLISHING#0" -Timezone 4 -LCID 1031 `
                      -Wait -ErrorAction SilentlyContinue -Connection $global:BcAdminConnection
    $site = Get-PnPTenantSite -Identity $siteUrl -Connection $global:BcAdminConnection -ErrorAction $ErrorActionPreference
        
    # Set Org News Site
    Write-Output "`n> SETTING UP AS ORG NEWS SITE (authoriative)"
    Add-PnPOrgNewsSite -OrgNewsSiteUrl $site.Url -Connection $global:BcAdminConnection

    # Set Hub Site
    Write-Output "> SETTING UP AS HUB SITE"
    Register-PnPHubSite -Site $site.Url -Connection $global:BcAdminConnection -ErrorAction Continue
    Set-PnPHubSite -Identity $site.Url -Title $tenantConfig.SharePoint.PortalTitle -EnablePermissionsSync -HideNameInNavigation -Connection $global:BcAdminConnection

    # Provision Content
    Write-Output "> PROVISIONING CONTENT"
    $c = Connect-PnPOnline -Credentials $global:BcAdminCred -Url $site.Url -ReturnConnection

    $templatePath = Join-Path -Path $PSScriptRoot -ChildPath "../../templates/SmartIntranet.xml"
    Invoke-PnPSiteTemplate -Path $templatePath -Connection $c -ErrorAction $ErrorActionPreference
        
    # Set Theme
    Write-Output "> ADJUSTING THEME AND WEB SETTINGS (lastly already done in PnPSiteTemplate)"
    Set-PnPWeb -HeaderLayout Minimal -HeaderEmphasis "Strong" -MembersCanShare:$false -CommentsOnSitePagesDisabled:$true -Connection $c

    # Adjust Permissions
    Write-Output "> ADJUSTING PERMISSIONS"
    Set-StandardPermissions -Connection $c
        
    Write-Output "> ✅ DONE! Don't forget to grant API access to the webparts through the SharePoint Admin Center..."
}

function Set-StandardPermissions($Connection) {
    $ErrorAction = "Continue"
    Write-Output "disregard any error in case of occurrence..."
    Set-PnPGroup -Identity (Get-PnPGroup -AssociatedOwnerGroup -Connection $Connection) -Title "SmartIntranet Admins" -OnlyAllowMembersViewMembership $true -Connection $Connection
    Set-PnPGroup -Identity (Get-PnPGroup -AssociatedMemberGroup -Connection $Connection) -Title "SmartIntranet ContentAdmins" -OnlyAllowMembersViewMembership $true -Connection $Connection
    Set-PnPGroup -Identity (Get-PnPGroup -AssociatedVisitorGroup -Connection $Connection) -Title "SmartIntranet Users" -OnlyAllowMembersViewMembership $true -Connection $Connection
    
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedOwnerGroup -Connection $Connection) -AddRole @("Vollzugriff") -Connection $Connection -ErrorAction $ErrorAction
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedOwnerGroup -Connection $Connection) -AddRole @("Full Control") -Connection $Connection -ErrorAction $ErrorAction
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedMemberGroup -Connection $Connection) -AddRole @("Mitwirken") -Connection $Connection -ErrorAction $ErrorAction
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedMemberGroup -Connection $Connection) -AddRole @("Contribute") -Connection $Connection -ErrorAction $ErrorAction
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedVisitorGroup -Connection $Connection) -AddRole @("Lesen") -Connection $Connection -ErrorAction $ErrorAction
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedVisitorGroup -Connection $Connection) -AddRole @("Read") -Connection $Connection -ErrorAction $ErrorAction
}