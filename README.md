# Azure Storage Patterns

This repository contains reusable Azure Storage patterns, templates, and command snippets. Each Azure Storage service keeps its examples in a dedicated folder so blob, file, and future storage patterns can evolve independently.


## Repository Layout

| Path | Pattern | Notes |
|---|---|---|
| [blob/azcopy/README.md](blob/azcopy/README.md) | AzCopy transfer patterns | Managed identity, service principal, SAS, and copy/list job examples. |
| [blob/blobfuse/README.md](blob/blobfuse/README.md) | BlobFuse2 mount patterns | Linux FUSE mount workflow and BlobFuse2 configuration. |
| [blob/blob-storage.azcli](blob/blob-storage.azcli) | Azure CLI blob admin | Blob CRUD and container operations using `az storage`. |
| [blob/blob-sftp.azcli](blob/blob-sftp.azcli) | Blob Storage SFTP | SFTP feature enablement and SSH/SFTP access patterns. |
| [file/README.md](file/README.md) | Azure Files patterns | SMB/NFS and file-share usage patterns. |
| [HNS/README.md](HNS/README.md) | Storage account architecture | HNS migration for existing Blob Storage accounts and ADLS Gen2 adoption. |
| [static-site/static-site.bicep](static-site/static-site.bicep) | Storage static website | Bicep template for the storage account; enable the website and upload content with Azure CLI. |
| [frontdoor/README.md](frontdoor/README.md) | Front Door in front of static websites | Bicep template, routing modes, and findings for multi-region static site delivery. |

## Pattern Rules

- Keep reusable templates under the relevant storage service folder.
- Keep real tenant IDs, client IDs, passwords, account keys, and SAS tokens out of tracked examples.
- Prefer placeholders such as `<storage-account>`, `<container>`, `<share-name>`, and `<sas-token>` in shared snippets.

## Available Patterns

- [AzCopy transfer patterns](blob/azcopy/README.md)
- [BlobFuse2 mount patterns](blob/blobfuse/README.md)
- [Azure Files patterns](file/README.md)
- [Storage account architecture: HNS migration](HNS/README.md)
- [Storage static website template](static-site/static-site.bicep)
- [Azure Front Door for static websites](frontdoor/README.md)

## Quick Start with Dev Container

This repository includes a **Dev Container** configuration that sets up a complete development environment with:
- Azure CLI (`az`)
- AzCopy (`azcopy`)
- PowerShell (`pwsh`)
- All necessary dependencies

### Open in Dev Container

1. Install [VS Code Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Open this folder in VS Code
3. Click the green **`><`** button in the bottom-left corner
4. Select **"Reopen in Container"**

The environment will automatically build and be ready to use.

### Verify Installation

Once the container is ready:
```bash
azcopy --version
az --version
pwsh --version
```
