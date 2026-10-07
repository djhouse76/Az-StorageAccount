// Azure Front Door in front of regional Storage static websites.
// Deploy: az deployment group create -g <rg> -f frontdoor.bicep -p frontdoor.bicepparam
// Each origin is a static website endpoint, e.g. from static-site/static-site.bicep (one account per region).

@description('Front Door profile name.')
param profileName string

@description('Endpoint name; becomes <name>-<hash>.z01.azurefd.net.')
param endpointName string

@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
param skuName string = 'Standard_AzureFrontDoor'

@description('Static website hostnames, first entry is the primary (e.g. stuksdswatest.z33.web.core.windows.net).')
@minLength(1)
param origins array

@description('true: all origins serve traffic (lowest-latency routing). false: first origin is primary, the rest are failover only.')
param activeActive bool = false

@description('Active/active only: origins within this latency of the fastest are treated as equal.')
param latencySensitivityMs int = 50

@description('Optional custom domain (e.g. portal.contoso.com). Leave empty to use the azurefd.net hostname.')
param customDomainHostName string = ''

@description('Health probe path; must exist in every origin.')
param probePath string = '/index.html'

@description('Send a Front Door managed-identity token to origins. Storage static website endpoints are anonymous and ignore it; it only takes effect for blob endpoint origins.')
param enableOriginAuthentication bool = false

@description('Origin storage accounts in this resource group; the Front Door identity gets Storage Blob Data Reader on each.')
param originStorageAccountNames array = []

param tags object = {}

var storageBlobDataReader = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'

resource profile 'Microsoft.Cdn/profiles@2025-06-01' = {
  name: profileName
  location: 'global'
  tags: tags
  sku: {
    name: skuName
  }
  identity: enableOriginAuthentication ? {
    type: 'SystemAssigned'
  } : null
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-02-01' = {
  parent: profile
  name: endpointName
  location: 'global'
  tags: tags
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2025-06-01' = {
  parent: profile
  name: 'static-site'
  properties: {
    authentication: enableOriginAuthentication ? {
      type: 'SystemAssignedIdentity'
      scope: 'https://storage.azure.com/.default'
    } : null
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: latencySensitivityMs
    }
    healthProbeSettings: {
      probePath: probePath
      probeRequestType: 'HEAD'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource originResources 'Microsoft.Cdn/profiles/originGroups/origins@2025-06-01' = [for (hostName, i) in origins: {
  parent: originGroup
  name: 'origin-${i}'
  properties: {
    hostName: hostName
    originHostHeader: hostName
    httpPort: 80
    httpsPort: 443
    priority: activeActive || i == 0 ? 1 : 2
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}]

resource customDomain 'Microsoft.Cdn/profiles/customDomains@2024-02-01' = if (!empty(customDomainHostName)) {
  parent: profile
  name: replace(customDomainHostName, '.', '-')
  properties: {
    hostName: customDomainHostName
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-02-01' = {
  parent: endpoint
  name: 'default'
  dependsOn: [
    originResources
  ]
  properties: {
    originGroup: {
      id: originGroup.id
    }
    customDomains: !empty(customDomainHostName) ? [
      {
        id: customDomain.id
      }
    ] : []
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
    cacheConfiguration: {
      queryStringCachingBehavior: 'IgnoreQueryString'
      compressionSettings: {
        isCompressionEnabled: true
        contentTypesToCompress: [
          'text/html'
          'text/css'
          'application/javascript'
          'application/json'
          'image/svg+xml'
        ]
      }
    }
  }
}

resource originStorage 'Microsoft.Storage/storageAccounts@2023-05-01' existing = [for name in originStorageAccountNames: {
  name: name
}]

resource readerAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for (name, i) in originStorageAccountNames: if (enableOriginAuthentication) {
  scope: originStorage[i]
  name: guid(originStorage[i].id, profile.id, storageBlobDataReader)
  properties: {
    principalId: profile.?identity.principalId ?? ''
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataReader)
  }
}]

output endpointHostName string = endpoint.properties.hostName
output frontDoorPrincipalId string = profile.?identity.principalId ?? ''
output customDomainValidationToken string = customDomain.?properties.validationProperties.validationToken ?? ''
