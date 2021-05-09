param vnetName string
param subnet object

resource newSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  name: '${vnetName}/${subnet.name}'
  properties: {
    addressPrefix: subnet.virtualNetworkPrefix
    networkSecurityGroup: {
      id: subnet.nsg
    }
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
    ]
    privateEndpointNetworkPolicies: subnet.privateEndpointNetworkPolicies
  }
}

output newSubnetId string = newSubnet.id
