# Hierarchical Namespace Migration

Azure Blob Storage accounts with a flat namespace can be upgraded to use a hierarchical namespace (HNS). HNS enables Azure Data Lake Storage Gen2 capabilities, including directory-aware operations, access control lists (ACLs), and analytics-oriented tooling.

## Use Case

Use HNS migration when an existing blob storage account needs Data Lake Storage Gen2 capabilities without creating a new account and copying all data to it. Typical reasons include:

- Introducing directory semantics for analytics, ETL, or data-lake workloads.
- Applying POSIX-style ACLs to directories and files.
- Using tools and services that require an HNS-enabled account, such as Data Lake Storage Gen2 integrations.
- Reducing the operational effort and downtime associated with a separate account-and-copy migration.

Migration changes the namespace behavior of the existing account. Review application compatibility and the service limitations documented by Azure before starting.

## Migration Stages

The migration should be treated as a controlled, one-way change:

1. **Validation** checks whether the account and its data are eligible for migration. It does not perform the upgrade.
2. **Upgrade** enables HNS after validation succeeds. The upgrade can take time, depending on the account and data. Do not start it until the workload owner has approved the change.
3. **Verification** confirms that applications, data access, ACLs, and dependent services behave as expected.

The HNS upgrade is not a routine toggle and should be planned as an irreversible migration. Maintain an independent recovery plan and test critical workloads before production migration.

## Prerequisites and Planning

- Confirm that the storage account type, region, replication, and enabled features are supported by HNS migration.
- Inventory applications, SDKs, tools, and services that access the account. Test path handling, rename operations, ACL behavior, and authentication.
- Review feature compatibility, including SFTP, NFS, blob versioning, change feed, soft delete, immutable storage, and third-party integrations.
- Ensure the operator is signed in to the correct tenant and subscription and has permission to validate and update the storage account.
- Schedule the change with the workload owner. Avoid writes that depend on namespace behavior changing during the upgrade.
- Capture the current account configuration and establish monitoring and rollback/recovery procedures. HNS migration does not provide a simple rollback switch.

## Run the Migration

Set the variables for the target account before running the commands. Keep values local and do not commit tenant IDs, credentials, keys, or SAS tokens.

```bash
storageName=<storage-account>
RG=<resource-group>
subscription=<subscription-id>
```

Start validation first:

```bash
az storage account hns-migration start \
  --type validation \
  --name "$storageName" \
  --resource-group "$RG" \
  --subscription "$subscription"
```

Review the validation result and resolve every reported issue. Only after validation succeeds should the upgrade be started:

```bash
az storage account hns-migration start \
  --type upgrade \
  --name "$storageName" \
  --resource-group "$RG" \
  --subscription "$subscription"
```

The same commands are in [hns-setup.azcli](hns-setup.azcli). Azure CLI variable syntax may differ between Bash, PowerShell, and Cloud Shell, so confirm that the values expand correctly in the shell being used.

## Verification Checklist

- Confirm the account reports HNS as enabled in the Azure portal or with Azure CLI.
- List containers and representative paths using the tools used by the workload.
- Test reads, writes, directory creation, rename, delete, and recursive operations.
- Validate Microsoft Entra ID authentication and ACL evaluation for representative identities.
- Check data-processing jobs, mounts, backup processes, event consumers, and monitoring integrations.
- Review application logs and Azure Activity Log entries for failed requests after the change.

## Troubleshooting

### Validation reports unsupported features

Use the validation output as the source of truth for the specific account. Compare each reported feature with the current Azure HNS migration support matrix. Options may include disabling or replacing the feature, moving the workload to a new HNS-enabled account, or postponing the migration. Do not proceed by ignoring validation findings.

### The command targets the wrong account or subscription

Check the active subscription and resolve the account explicitly:

```bash
az account show --output table
az storage account show \
  --name "$storageName" \
  --resource-group "$RG" \
  --subscription "$subscription" \
  --output table
```

### Authorization fails

Confirm that the signed-in identity has access to the subscription, resource group, and storage account, and that the required storage-account action is allowed by Azure RBAC. Also check deny assignments, Azure Policy, and whether the command is using the intended tenant.

### The upgrade is still running

Treat the operation as long-running. Do not start a second upgrade or make configuration changes solely to force progress. Check the operation state in the Azure portal, Activity Log, and the command output. If it remains unchanged beyond the expected maintenance window, collect the operation ID, timestamps, account resource ID, and validation output before opening an Azure support request.

### Applications fail after migration

Check whether the application assumes flat namespace behavior, uses unsupported APIs, depends on blob names that resemble directories, or lacks the required ACL permissions. Reproduce with a small test path, compare the failing request and authentication method with a working request, and review service-specific HNS compatibility guidance.

### Access is denied after migration

Separate authentication from authorization troubleshooting. Verify the token or credential first, then check the account, container, directory, and file ACLs, including execute permission on parent directories. Also confirm that the client uses the intended endpoint and that its identity has the necessary data-plane role.

### Migration cannot be rolled back

HNS migration should be considered one-way. Restore service by correcting application compatibility or moving data to another supported account; do not plan on disabling HNS as an emergency rollback. Keep tested backups and a documented recovery path before upgrading.

## Useful Diagnostics

```bash
az account show --output json
az storage account show \
  --name "$storageName" \
  --resource-group "$RG" \
  --subscription "$subscription" \
  --output json
az monitor activity-log list \
  --resource-id "/subscriptions/$subscription/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$storageName" \
  --max-events 50 \
  --output table
```

When escalating, include the storage account resource ID, subscription, region, account kind and SKU, migration type, command timestamp, operation or correlation ID, complete validation output, and the exact client error. Redact secrets and access tokens.

## References

- [Azure Data Lake Storage hierarchical namespace](https://learn.microsoft.com/azure/storage/blobs/data-lake-storage-namespace)
- [Azure Storage account feature support](https://learn.microsoft.com/azure/storage/blobs/features-support-account)
- [Azure CLI storage account commands](https://learn.microsoft.com/cli/azure/storage/account)