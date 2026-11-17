ARG TAG=4.8.1-windowsservercore-ltsc2025
FROM mcr.microsoft.com/dotnet/framework/runtime:${TAG}
LABEL name=arc-runner-windows

# The "PLATFORM" argument is created to allow injecting it into the
# build environment.
# In this we can share the build scripts between X64 and ARM64.
ARG RUNNER_VERSION=2.338.2
ENV RUNNER_VERSION=$RUNNER_VERSION

WORKDIR /actions-runner

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';$ProgressPreference='silentlyContinue';"]

RUN Invoke-WebRequest -Uri "http://dp1.liebherr.com/LiebherrRootCA2.crt" -OutFile LiebherrRootCA2.crt
RUN Invoke-WebRequest -Uri "http://dp1.liebherr.com/LiebherrEnterpriseCA02.crt" -OutFile LiebherrEnterpriseCA02.crt
RUN Import-Certificate -FilePath "LiebherrRootCA2.crt" -CertStoreLocation Cert:\LocalMachine\Root


# Get Action runner.
RUN \
    Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v${env:RUNNER_VERSION}/actions-runner-win-x64-${env:RUNNER_VERSION}.zip -OutFile actions-runner-win.zip ; \
    Add-Type -AssemblyName System.IO.Compression.FileSystem ; \
    [System.IO.Compression.ZipFile]::ExtractToDirectory('actions-runner-win.zip', $PWD) ;\
    rm actions-runner-win.zip

# Get Git and Linux tools
RUN powershell Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

RUN powershell choco install git.install --params "'/GitAndUnixToolsOnPath'" -y

# Install PowerShell 7 alongside Windows PowerShell.
RUN \
    $msi = 'PowerShell-7.6.6-win-x64.msi'; \
    Invoke-WebRequest -Uri "https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/$msi" -OutFile $msi; \
    if ((Get-FileHash -Path $msi -Algorithm SHA256).Hash -ne '958838FF55091E1C8705D89EFED0CC7E8245A3A6EF6C0CCFAE20015227108AD8') { throw 'PowerShell MSI checksum verification failed.' }; \
    $installer = Start-Process msiexec.exe -Wait -PassThru -ArgumentList '/package PowerShell-7.6.6-win-x64.msi /quiet ADD_PATH=1 DISABLE_TELEMETRY=1'; \
    if ($installer.ExitCode -ne 0) { throw "PowerShell installation failed with exit code $($installer.ExitCode)." }; \
    Remove-Item $msi

# Install Azure CLI
RUN \
  $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; Remove-Item .\AzureCLI.msi

RUN powershell choco feature enable -n allowGlobalConfirmation

RUN pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion; if ($PSVersionTable.PSVersion.Major -ne 7 -or $PSVersionTable.PSVersion.Minor -ne 6 -or $PSVersionTable.PSVersion.Patch -ne 6) { exit 1 }'
