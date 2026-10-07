# Azure Files Patterns

This folder contains reusable Azure Files patterns for file shares, SMB/NFS mounting, and AzCopy transfers.

## Files

| File | Purpose |
|---|---|
| `file-share.azcli` | Azure CLI and AzCopy snippets for Azure file shares. |

## Service Fit

Use Azure Files when the workload expects a managed file share with SMB or NFS semantics. Use Blob Storage when the workload is object-oriented, optimized for blob APIs, static content, analytics data, or BlobFuse2-based access.

| Pattern | Prefer Azure Files when |
|---|---|
| SMB mount | Windows or Linux clients need a shared filesystem over SMB. |
| NFS mount | Linux clients need POSIX-like access and the account/share support NFS. |
| AzCopy transfer | You need scripted upload, download, sync, or migration to a file share. |

## Mount an SMB Share on Linux

Install prerequisites:

```bash
sudo apt-get update
sudo apt-get install -y cifs-utils
```

Create the mount point:

```bash
sudo mkdir -p /mnt/azfiles/<share-name>
```

Mount with a storage account key:

```bash
sudo mount -t cifs //<storage-account>.file.core.windows.net/<share-name> /mnt/azfiles/<share-name> \
 -o vers=3.0,username=<storage-account>,password=<storage-account-key>,serverino,nosharesock,actimeo=30,mfsymlinks
```

For production hosts, store credentials outside shell history, such as in a root-owned credential file or Key Vault-backed automation.

## Mount an NFS Share on Linux

Install prerequisites:

```bash
sudo apt-get update
sudo apt-get install -y nfs-common
```

Create the mount point and mount the share:

```bash
sudo mkdir -p /mnt/azfiles/<share-name>
sudo mount -t nfs <storage-account>.file.core.windows.net:/<storage-account>/<share-name> /mnt/azfiles/<share-name> -o vers=4,minorversion=1,sec=sys
```

NFS requires a supported storage account configuration and network rules that allow access from the client subnet.

## AzCopy

See `file-share.azcli` for reusable Azure Files command templates.