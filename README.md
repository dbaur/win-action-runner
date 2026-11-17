# win-action-runner

Windows x64 container image with GitHub Actions runner **2.338.2**, based on
**Windows Server Core LTSC 2025** with .NET Framework 4.8.1. Includes
PowerShell 7.6.6 (`pwsh`), Git, Unix command-line tools, and Azure CLI.

Build with `docker build -t win-action-runner .` using Docker in Windows
container mode on a compatible host, such as Windows Server 2025.
See [Windows container host compatibility](https://learn.microsoft.com/en-us/virtualization/windowscontainers/deploy-containers/version-compatibility)
for supported host and isolation combinations.

CI builds on `windows-2025` for pull requests and pushes to `main`, without
publishing. Windows 2022 builds are no longer produced.

The `TAG` and `RUNNER_VERSION` build arguments can override the base image tag
and runner version. CI uses the Dockerfile defaults.

## Releases

[Google release-please](https://github.com/googleapis/release-please) manages
image versions independently of the bundled GitHub Actions runner version.
The first release is `v1.0.0`; `version.txt` is `0.0.0` until the first release
PR updates it.

Use Conventional Commit titles when squash-merging PRs:

- `fix: ...` creates a patch release.
- `feat: ...` creates a minor release.
- `feat!: ...` or a `BREAKING CHANGE:` footer creates a major release.
- `chore: ...` and `docs: ...` alone do not trigger a release.

On pushes to `main`, release-please opens or updates a release PR containing
`version.txt`, `CHANGELOG.md`, and the release manifest. Review its changes and
wait for CI before merging. Merging creates the Git tag and GitHub release;
the same workflow then builds the released commit and publishes these GHCR tags
(example for image release `v1.0.0` bundling runner `2.338.2`):

- `ghcr.io/dbaur/win-action-runner:windows-2025-v1.0.0`
- `ghcr.io/dbaur/win-action-runner:windows-2025` (latest successful release)
- `ghcr.io/dbaur/win-action-runner:windows-2025-2.338.2` (compatibility alias)

The runner-version alias can move when an image release changes tools or fixes
without changing the runner version. Use the image release tag or image digest
to pin a particular image.

If publishing fails after a GitHub release is created, re-run the failed
`publish` job in that workflow run; do not create another release.
The Release Please workflow also supports manual dispatch to update release PRs.

### Automation setup

Create a repository Actions secret named `RELEASE_PLEASE_TOKEN` containing a
fine-grained PAT scoped to this repository with **Contents**, **Issues**, and
**Pull requests** read/write permissions. Its owner must have write access.
An equivalent GitHub App installation token can also be supplied, but token
generation and renewal must be configured separately.

Use this token rather than `GITHUB_TOKEN` so release-please's PRs trigger CI.
GHCR publishing uses the built-in `GITHUB_TOKEN` with `packages: write`, not
the release-please token. Fork PRs only build and do not receive publishing
credentials.