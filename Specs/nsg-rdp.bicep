// This variable is not used in for the Template spec
var templateSpecName = 'nsg-rdp'
var version = '1.0'

param nsgname string
@description('The source IP or IP range')
param RDPsourceIP string
@description('The destination IP or IP range')
param RDPdestinationIP string

param location string = resourceGroup().location

var tagValues = {
  Source: 'TemplateSpecs'
  templateSpecName: templateSpecName
  templateSpecVersion: version
}

module nsg 'Modules/networkSecurityGroup.bicep' = {
  name: nsgname
  params: {
    ResourceName: nsgname
    location: location
    tagValues: tagValues
    securityRules: [
      {
        name: 'AllowRDP'
        protocol: 'TCP'
        sourcePortRange: '*'
        destinationPortRange: 3389
        sourceAddressPrefix: RDPsourceIP
        destinationAddressPrefix: RDPdestinationIP
        access: 'Allow'
        priority: 101
        direction: 'Inbound'
      }
    ]
  }
}
