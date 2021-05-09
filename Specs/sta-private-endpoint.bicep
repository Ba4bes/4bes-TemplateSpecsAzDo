// This variable is for the Template spec
var templateSpecName = 'storageAccount-Private-Endpoint'
var version = '1.1'

@description('first part of resource name. Max 11 characters')
param resourcePrefix string
param vnetName string

@description('new or existing subnet in the virtual network')
param subnetName string
@description('new or existing subnetAddressSpace.')
param subnetAddressSpace string
param currentDate string = utcNow('yyyy-MM-dd')
@description('Change if the virtual network is in a different resource group then the storage account')
param vnetResourceGroup string = resourceGroup().name



var tagValues = {
  Source: 'TemplateSpecs'
  templateSpecName : templateSpecName
  templateSpecVersion : version
}

module sta 'Modules/storageAccount.bicep' = {
  name: 'sta'
  params: {
    storageAccountPrefix: resourcePrefix
    tagValues: tagValues
  }
}

module privateEndPoint 'Modules/privateEndpoint.bicep' = {
  name: 'privateEndPoint'
  params: {
    tagValues: tagValues
    privateEndpointName: '${resourcePrefix}-pep'
    storageAccountId: sta.outputs.staid
    subnetId: subnet.outputs.newSubnetId
  }
}

module nsg 'Modules/networkSecurityGroup.bicep' = {
  name: 'nsg'
  scope: resourceGroup(vnetResourceGroup)
  params: {
    ResourcePrefix: resourcePrefix
    tagValues: tagValues
    securityRules: []
  }
}

module subnet 'Modules/subnet.bicep' = {
  name: subnetName
  scope: resourceGroup(vnetResourceGroup)
  params: {
    vnetName: vnetName
    subnet: {
      name: subnetName
      virtualNetworkPrefix: subnetAddressSpace
      privateEndpointNetworkPolicies: 'Disabled'
      privateLinkServiceNetworkPolicies: 'Disabled'
      nsg: nsg.outputs.nsgid
    }
  }
}
