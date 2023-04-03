
FROM mcr.microsoft.com/powershell:lts-debian-11

# Set working directory so stuff doesn't end up in /

RUN apt-get update
RUN apt-get install xdg-utils -y


#TODO
#RUN GIT CHeckout MAIN

SHELL [ "pwsh", "-c" ]

RUN Install-Module -Force -Scope CurrentUser -Verbose -Name PnP.Powershell
RUN Install-Module -Force -Scope CurrentUser -Verbose -Name EPS
RUN Install-Module -Force -Scope CurrentUser -Verbose -Name powershell-yaml
#RUN Install-Module -Force -Scope CurrentUser -Verbose -Name CredentialManager

