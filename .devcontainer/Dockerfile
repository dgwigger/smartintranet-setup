
FROM mcr.microsoft.com/powershell:lts-7.2-debian-11

# Set working directory so stuff doesn't end up in /

RUN apt-get update
RUN apt-get install xdg-utils -y

RUN pwsh -c "Install-Module -Force -Scope CurrentUser -Verbose -Name CredentialManager"
RUN pwsh -c "Install-Module -Force -Scope CurrentUser -Verbose -Name EPS"
RUN pwsh -c "Install-Module -Force -Scope CurrentUser -Verbose -Name powershell-yaml"
RUN pwsh -c "Install-Module -Force -Scope CurrentUser -Verbose -Name PnP.Powershell"

SHELL [ "pwsh", "-c" ]