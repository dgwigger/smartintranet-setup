# Automated Setup Scripts for smartintranet

## Prerequisites

```powershell
Install-Module -Name EPS -Scope CurrentUser
Install-Module -Name powershell-yaml -Scope CurrentUser
Install-Module -Name PnP.PowerShell -Scope CurrentUser
Install-Module -Name CredentialManager -Scope CurrentUser
```

...or...

```powershell
Install-Module -Name EPS, powershell-yaml, PnP.PowerShell, CredentialManager -Scope CurrentUser
```

## Usage

```powershell
Import-Module .\setup\SmartIntranet.psm1 -Force

$Tenant = "contoso" # or your tenant 😉

# this is only required once in the tenant lifetime, unless the enterpise application gets deleted
#   use an administration account, that can consent the rights on Azure here
Connect-PnPOnline -Url "https://$Tenant.sharepoint.com" -Interactive
Disconnect-PnPOnline

New-BcTenantConfig -Tenant $Tenant
Show-BcTenantConfig -Tenant $Tenant

Install-BcIntranet -Tenant $Tenant # -SkipWebpartDeployment

# OPTIONAL: if you'd like to add another page with a minimal template and company news, then go for it:
Install-PageMinimalWithNews -Tenant $Tenant
```

## Repository Structure

* `/assets` contains resources that are deployed or installed on foreign tenants
* `/setup` powershell scripts that do all the magic
    * `/setup/private` internal used functions
    * `/setup/public` public commandlets of the module
* `/templates` templates that are used for the setup
* `smartintranet.settings.yml` global settings and constants
