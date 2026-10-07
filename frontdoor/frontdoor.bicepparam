using 'frontdoor.bicep'

param profileName = '<front-door-profile>'
param endpointName = '<endpoint-name>'
param origins = [
  '<weu-storage-account>.z33.web.core.windows.net'
  '<secondary-storage-account>.z33.web.core.windows.net'
]
param activeActive = false
param customDomainHostName = ''
param enableOriginAuthentication = false
param originStorageAccountNames = []
