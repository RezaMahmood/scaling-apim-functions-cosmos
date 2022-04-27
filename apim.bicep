// TODO: https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.apimanagement/api-management-create-with-external-vnet-publicip/main.bicep

param deploymentPrefix string = uniqueString(resourceGroup().id)

@description('The name of the API Management service instance')
param apiManagementServiceName string = '${deploymentPrefix}-apim'

@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string

@description('The name of the owner of the service')
@minLength(1)
param publisherName string

@description('The pricing tier of this API Management service')
@allowed([
  'Developer'
  'Standard'
  'Premium'
])
param sku string = 'Developer'

@description('The instance size of this API Management service.')
@allowed([
  1
  2
])
param skuCount int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

param subnetId string

resource apim 'Microsoft.ApiManagement/service@2021-08-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: subnetId
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}
