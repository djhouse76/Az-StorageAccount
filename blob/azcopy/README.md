# Azure AzCopy patterns

This folder contains reusable AzCopy examples for Azure Blob Storage. It focuses on the common patterns teams use when moving data between local filesystems, blob containers, and Azure Storage endpoints.

## When to use AzCopy

Use AzCopy when you need one of the following:

- upload or download files to Azure Blob Storage
- copy data between blob containers
- sync local directories with blob storage
- run repeatable transfer tasks from scripts or automation
- move large datasets with progress reporting and resumable job handling

## Common auth patterns

Use the most appropriate identity for the environment:

1. Managed identity: best option when the workload runs in Azure.
2. Service principal: best option for CI/CD or automation outside Azure.
3. SAS token: best for short-lived, scoped transfer scenarios.

## Typical flow

```bash
# install azcopy
wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
sudo cp ./azcopy_linux_amd64_*/azcopy /usr/bin/

# log in with managed identity
azcopy login --identity --identity-client-id "<managed-identity-client-id>"

# upload a single file
azcopy copy "/path/to/file.txt" "https://<storage-account>.blob.core.windows.net/<container>/<path/to/blob>"

# upload a directory recursively
azcopy copy "/path/to/local/folder" "https://<storage-account>.blob.core.windows.net/<container>/<destination-path>/" --recursive

# list files in a container
azcopy list "https://<storage-account>.blob.core.windows.net/<container>"
```

## Security guidance

- Keep secrets out of versioned files.
- Prefer managed identity or service principal over embedded credentials.
- Use SAS tokens only for narrow, time-limited transfers.
- Store client secrets in environment variables, Key Vault, or another secret manager.

## Files in this folder

- `azcopy.azcli` — reusable AzCopy command examples and auth patterns.

## Related patterns

- BlobFuse2 mount patterns: [../blobfuse/README.md](../blobfuse/README.md)
- Blob CLI patterns: [../blob-storage.azcli](../blob-storage.azcli)
