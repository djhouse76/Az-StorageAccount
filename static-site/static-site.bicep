// Storage account for a static website. The static website setting is data-plane,
// so enable it and upload content with Azure CLI after deployment.
// Deploy: az deployment group create -g <rg> -f static-site.bicep -p static-site.bicepparam

@description('Globally unique storage account name (3-24 lowercase letters/digits).')
@minLength(3)
@maxLength(24)
param storageName string

param location string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param skuName string = 'Standard_LRS'

param tags object = {}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: skuName
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false // static website endpoint is public regardless of this setting
    allowSharedKeyAccess: false
    accessTier: 'Hot'
  }
}

output storageAccountId string = storage.id
output staticSiteUrl string = storage.properties.primaryEndpoints.web
