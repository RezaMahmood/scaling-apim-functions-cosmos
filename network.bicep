param vnetName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'apim' // APIM subnet
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'pe' // Private Endpoints subnet
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'func' // FunctionApp Integration subnet
        properties: {
          addressPrefix: '10.0.3.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'webapp'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

//TODO: implement common NSG from file: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file
resource apimnsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vnetName}-apim-nsg-${location}'
  location: location
  properties: {
    securityRules: [
      {}
    ]
  }
}

output vnetId string = vnet.id
output apimSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'apim')
output funcSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'func')
output peSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'pe')
