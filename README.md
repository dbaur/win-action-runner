# win-action-runner

Windows x64 container image with GitHub Actions runner **2.338.2**, based on
**Windows Server Core LTSC 2025** with .NET Framework 4.8.1. Includes Git,
Unix command-line tools, and Azure CLI.

Build with `docker build -t win-action-runner .` using Docker in Windows
container mode on a compatible host, such as Windows Server 2025.
See [Windows container host compatibility](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility)
for supported host and isolation combinations.

CI builds on `windows-2025` and publishes
`ghcr.io/dbaur/win-action-runner:windows-2025-2.338.2`.
Windows 2022 builds are no longer produced.

The `TAG` and `RUNNER_VERSION` build arguments can override the base image tag
and runner version. When updating the runner, keep the Dockerfile default and
the workflow's `RUNNER_VERSION` in sync.