ARG TAG=ltsc2022
FROM mcr.microsoft.com/dotnet/framework/runtime:${TAG}
LABEL name=arc-runner-windows

# The "PLATFORM" argument is created to allow injecting it into the
# build environment.
# In this we can share the build scripts between X64 and ARM64.
ARG RUNNER_VERSION=2.311.0
ENV RUNNER_VERSION=$RUNNER_VERSION

WORKDIR /actions-runner

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';$ProgressPreference='silentlyContinue';"]

# Get Action runner.
RUN \
    Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v${env:RUNNER_VERSION}/actions-runner-win-x64-${env:RUNNER_VERSION}.zip -OutFile actions-runner-win.zip ; \
    Add-Type -AssemblyName System.IO.Compression.FileSystem ; \
    [System.IO.Compression.ZipFile]::ExtractToDirectory('actions-runner-win.zip', $PWD) ;\
    rm actions-runner-win.zip

# Get Git and Linux tools
RUN powershell Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

RUN powershell choco install git.install --params "'/GitAndUnixToolsOnPath'" -y

# Install Azure CLI
RUN \
  $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; Remove-Item .\AzureCLI.msi

RUN powershell choco feature enable -n allowGlobalConfirmation