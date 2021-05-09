// This variable is for the Template spec
var templateSpecName = 'vnet-with-2-Subnets'
var version = '1.0'

param vnetName string

@description('networkprefix must end in /16')
param virtualNetworkPrefix string
param location string = resourceGroup().location
var tagValues = {
  Source: 'TemplateSpecs'
  templateSpecName: templateSpecName
  templateSpecVersion: version
}

module nsg 'Modules/networkSecurityGroup.bicep' = {
  name: 'nsgDefault'
  params: {
    ResourceName: 'nsgDefault'
    tagValues: tagValues
    securityRules: [
      {
        name: 'Allow443'
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: 443
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
    ]
  }
}

module nsgRDP 'Modules/networkSecurityGroup.bicep' = {
  name: 'RDPNSG'
  params: {
    ResourceName: 'RDPNSG'
    tagValues: tagValues
    securityRules: [
      {
        name: 'AllowRDPInBound'
        protocol: 'Tcp'
        sourcePortRange: '*'
        sourceAddressPrefix: 'Internet'
        destinationPortRange: 3389
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
    ]
  }
}

module vnet 'Modules/virtualNetwork.bicep' = {
  name: vnetName
  params: {
    ResourceName: vnetName
    location: location
    tagValues: tagValues
    virtualNetworkPrefix: virtualNetworkPrefix
    subnets: [
      {
        name: 'default'
        subnetPrefix: replace(virtualNetworkPrefix, '0.0/16', '1.0/24')
        nsg: nsg.outputs.nsgid
        privateEndpointNetworkPolicies: 'disabled'
      }
      {
        name: 'LAB_VMs'
        subnetPrefix: replace(virtualNetworkPrefix, '0.0/16', '2.0/24')
        nsg: nsgRDP.outputs.nsgid
        privateEndpointNetworkPolicies: 'disabled'
      }
    ]
  }
}
