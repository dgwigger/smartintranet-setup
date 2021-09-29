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
}
function New-SmartIntranet() {
    $tenantConfig = Get-TenantConfig -Tenant $Tenant  
    Write-Output "> CREATING new beeConnect Site Collection: $($tenantConfig.SharePoint.PortalSite)"
    $siteUrl = "$($tenantConfig.SharePoint.Url)/$($tenantConfig.SharePoint.PortalSite)"
    New-PnPSite -Type CommunicationSite -Title $tenantConfig.SharePoint.PortalTitle  -Url $siteUrl`
                -SiteDesign Blank -Wait -Lcid 1031 -Connection $global:BcAdminConnection -ErrorAction
    $site = Get-PnPTenantSite -Identity $siteUrl -Connection $global:BcAdminConnection -ErrorAction $ErrorActionPreference
        
    # Set Org News Site
    Write-Output "> SETTING UP AS ORG NEWS SITE (authoriative)"
    Add-PnPOrgNewsSite -OrgNewsSiteUrl $site.Url -Connection $global:BcAdminConnection

    # Provision Content
    Write-Output "> PROVISIONING CONTENT"
    $c = Connect-PnPOnline -Credentials $global:BcAdminCred -Url $site.Url -ReturnConnection

    $templatePath = Join-Path -Path $PSScriptRoot -ChildPath "../../templates/SmartIntranet.xml"
    Invoke-PnPSiteTemplate -Path $templatePath -Connection $c -ErrorAction $ErrorActionPreference
        
    # Set Theme
    Write-Output "> ADJUSTING THEME AND WEB SETTINGS (lastly already done in PnPSiteTemplate)"
    Set-PnPWeb -HeaderLayout "Extended" -HeaderEmphasis "Strong" -MembersCanShare:$false -CommentsOnSitePagesDisabled:$true -Connection $c

    # Adjust Permissions
    Write-Output "> ADJUSTING PERMISSIONS"
    Set-StandardPermissions -Connection $c
        
    Write-Output "> DONE! Don't forget to grant API access to the webparts through the SharePoint Admin Center..."
}

function Set-StandardPermissions($Connection) {
    Set-PnPGroup -Identity (Get-PnPGroup -AssociatedOwnerGroup -Connection $Connection) -Title "SmartIntranet Admins" -OnlyAllowMembersViewMembership $true -Connection $Connection
    Set-PnPGroup -Identity (Get-PnPGroup -AssociatedMemberGroup -Connection $Connection) -Title "SmartIntranet ContentAdmins" -OnlyAllowMembersViewMembership $true -Connection $Connection
    Set-PnPGroup -Identity (Get-PnPGroup -AssociatedVisitorGroup -Connection $Connection) -Title "SmartIntranet Users" -OnlyAllowMembersViewMembership $true -Connection $Connection
    
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedOwnerGroup -Connection $Connection) -AddRole @("Vollzugriff") -Connection $Connection
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedMemberGroup -Connection $Connection) -AddRole @("Mitwirken") -Connection $Connection
    Set-PnPGroupPermissions -Identity (Get-PnPGroup -AssociatedVisitorGroup -Connection $Connection) -AddRole @("Lesen") -Connection $Connection
}