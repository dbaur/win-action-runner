ARG TAG=ltsc2022
FROM mcr.microsoft.com/dotnet/framework/runtime:${TAG}
LABEL name=arc-runner-windows

# The "PLATFORM" argument is created to allow injecting it into the
# build environment.
# In this we can share the build scripts between X64 and ARM64.
ARG RUNNER_VERSION=2.330.0
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

# Install Azure CLI
RUN \
  $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; Remove-Item .\AzureCLI.msi

RUN powershell choco feature enable -n allowGlobalConfirmation

# Pre-install native build prerequisites for Rust (MSVC toolchain)
RUN powershell choco install vcredist140 -y

# Install Visual Studio Build Tools using the official Microsoft bootstrapper.
# Keep the runner image entrypoint unchanged; the Microsoft sample ENTRYPOINT is for
# interactive Build Tools containers and would otherwise replace your runner startup.
SHELL ["cmd", "/S", "/C"]
RUN curl -SL --output vs_buildtools.exe https://aka.ms/vs/17/release/vs_buildtools.exe \
    && (start /w vs_buildtools.exe --quiet --wait --norestart --nocache \
        --installPath "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools" \
        --add Microsoft.VisualStudio.Workload.VCTools \
        --includeRecommended \
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 \
        --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 \
        --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 \
        --remove Microsoft.VisualStudio.Component.Windows81SDK \
        || IF "%ERRORLEVEL%"=="3010" EXIT 0) \
    && del /q vs_buildtools.exe \

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';$ProgressPreference='silentlyContinue';"]
