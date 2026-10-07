# Azure Blob Storage with BlobFuse2

This folder is dedicated to BlobFuse2 mounting patterns for Azure Blob Storage on Linux.

## In this folder

| File | Purpose |
|---|---|
| `blobfuse2.yaml` | BlobFuse2 configuration template for mounting a blob container as a local filesystem. |

> For broader Azure Blob CLI and AzCopy examples, use the parent blob pattern files rather than this BlobFuse2-specific guide.

## BlobFuse2 - Install, Configure, and Mount on Linux

BlobFuse2 lets you mount an Azure Blob Storage container as a Linux filesystem via FUSE. Primary target OS: **Red Hat Enterprise Linux (RHEL)**.

**References**
- [Install BlobFuse - Microsoft Learn](https://learn.microsoft.com/en-us/azure/storage/blobs/blobfuse2-install?tabs=RHEL)
- [Streaming vs Caching Mode - Microsoft Learn](https://learn.microsoft.com/en-us/azure/storage/blobs/blobfuse2-streaming-versus-caching)
- [Mount a Container on Linux - Microsoft Learn](https://learn.microsoft.com/en-us/azure/storage/blobs/blobfuse2-how-to-deploy)

## 1. Prerequisites

- RHEL or another supported Linux distribution
- Network access to `packages.microsoft.com` and `*.blob.core.windows.net`
- An Azure Storage account and container
- Appropriate data-plane permissions, such as `Storage Blob Data Contributor`

## 2. Install BlobFuse2 on RHEL

The repo RPM path requires your RHEL major version number. This command resolves it automatically:

```bash
RHEL_VER=$(rpm -E '%{rhel}')
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/${RHEL_VER}/packages-microsoft-prod.rpm
```

Install and verify BlobFuse2:

```bash
sudo dnf update
sudo yum install fuse3 fuse3-libs blobfuse2
blobfuse2 --version
```

## 3. Choose a Cache Mode

BlobFuse2 supports two data modes. Pick one before writing your config file.

| Mode | Best for | Avoid when |
|---|---|---|
| `block_cache` | Large files, sequential reads, AI/ML datasets, HPC workloads | Many small files, random read-write workloads |
| `file_cache` | Repeated reads of files that fit local disk, fuller local file semantics | Files that exceed disk capacity, memory-constrained hosts |

The `blobfuse2.yaml` template uses streaming mode with `block_cache`. To switch to caching mode, replace `block_cache` in `components` with `file_cache` and add a `file_cache` section with a local cache path.

## 4. Configure BlobFuse2

Copy the template and edit the placeholders for your environment:

```bash
sudo mkdir -p /etc/blobfuse2
sudo cp blob/blobfuse/blobfuse2.yaml /etc/blobfuse2/config.yaml
mkdir -p /home/$USER/.blobfuse2
```

Key settings in `blobfuse2.yaml`:

| Section | Purpose |
|---|---|
| `logging` | File or syslog output and log level. |
| `components` | BlobFuse2 pipeline order. |
| `libfuse` | FUSE mount behavior and metadata expiry. |
| `block_cache` | Streaming cache size, prefetch, and parallelism. |
| `attr_cache` | Attribute cache timeout. |
| `azstorage` | Storage account, container, endpoint, and credential mode. |

Credential modes:

| Mode | When to use | Required fields |
|---|---|---|
| `azcli` | Local dev with `az login` | None; uses current Azure CLI session. |
| `key` | Simple testing | `account-key` |
| `sas` | Time-limited least privilege | `sas`, without the leading `?` |
| `msi` | Azure VM, VMSS, AKS, or App Service | Optional `appid` for user-assigned identity. |
| `spn` | Automated pipelines | `tenantid`, `clientid`, `clientsecret` |

## 5. Mount the Container

```bash
sudo mkdir -p /mnt/blobstorage
sudo chown $USER:$USER /mnt/blobstorage
sudo blobfuse2 mount /mnt/blobstorage --config-file=/etc/blobfuse2/config.yaml
```

Verify the mount:

```bash
mount | grep blobfuse2
df -h /mnt/blobstorage
ls -la /mnt/blobstorage
```

Optional `/etc/fstab` entry:

```text
blobfuse2   /mnt/blobstorage   fuse   _netdev,allow_other,--config-file=/etc/blobfuse2/config.yaml,x-systemd.requires=network-online.target,x-systemd.after=network-online.target   0   0
```

Apply and validate:

```bash
sudo systemctl daemon-reload
sudo mount -a
findmnt /mnt/blobstorage
```

## 6. Verify Read-Write Access

```bash
cd /mnt/blobstorage
mkdir test
echo "hello from $(hostname)" > test/blob.txt
cat test/blob.txt
```

BlobFuse2 supports standard Linux file operations such as `mkdir`, `ls`, `cp`, `mv`, `rm`, `cat`, `echo`, and `find`. Writes are committed to Azure Blob Storage when the file handle is closed.

## 7. Unmount

```bash
sudo blobfuse2 unmount /mnt/blobstorage
sudo fusermount3 -u /mnt/blobstorage
```

Confirm the mount is gone:

```bash
mount | grep blobstorage
```