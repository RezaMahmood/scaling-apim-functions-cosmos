param vnetName string

@description('Location for all resources.')
param location string = resourceGroup().location

var defaultrules = json(loadTextContent('./default-nsg.json')).securityRules
var customrules = []

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
          networkSecurityGroup: {
            id: apimnsg.id
          }
        }
      }
      {
        name: 'pe' // Private Endpoints subnet
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: pensg.id
          }
        }
      }
      {
        name: 'devops' // Devops runner subnet
        properties: {
          addressPrefix: '10.0.4.0/24'
          networkSecurityGroup: {
            id: devopsnsg.id
          }
        }
      }
      {
        name: 'func' // FunctionApp Integration subnet
        properties: {
          addressPrefix: '10.0.3.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          networkSecurityGroup: {
            id: funcnsg.id
          }
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

//implement common NSG from file: https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/patterns-shared-variable-file
resource apimnsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vnetName}-apim-nsg-${location}'
  location: location
  properties: {
    securityRules: concat(defaultrules, customrules)
  }
}

resource funcnsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vnetName}-func-nsg-${location}'
  location: location
  properties: {
    securityRules: concat(defaultrules, customrules)
  }
}

resource pensg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vnetName}-pe-nsg-${location}'
  location: location
  properties: {
    securityRules: concat(defaultrules, customrules)
  }
}

resource devopsnsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: '${vnetName}-devops-nsg-${location}'
  location: location
  properties: {
    securityRules: concat(defaultrules, customrules)
  }
}

output vnetId string = vnet.id
output apimSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'apim')
output funcSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'func')
output peSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'pe')
output devopsSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, 'devops')
