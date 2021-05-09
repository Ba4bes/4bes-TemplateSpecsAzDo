@maxLength(11)
param storageAccountPrefix string
param location string = resourceGroup().location
param tagValues object

resource sta 'Microsoft.Storage/storageAccounts@2021-01-01' = {
  name: concat(storageAccountPrefix, uniqueString(resourceGroup().id))
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  tags: tagValues
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

output staid string = sta.id
