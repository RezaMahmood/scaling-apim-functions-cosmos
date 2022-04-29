// Based on:

// Global Params
param deploymentPrefix string = uniqueString(resourceGroup().id)
@description('Location for all resources.')
param location string = resourceGroup().location

// Network Params
param vnetName string = '${deploymentPrefix}-vnet'

// APIM Params
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

// Functions Params
@description('OS used for Functions hosting plan')
@allowed([
  'Windows'
  'Linux'
])
param functionPlanOS string = 'Windows'
param functionAppName string = '${deploymentPrefix}-func'
param appServicePlanName string = '${deploymentPrefix}-plan'
param functionStorageAccountName string = '${deploymentPrefix}st'

// Cosmos Params
@maxLength(44)
@minLength(3)
param cosmosAccountName string
param cosmosDatabaseName string
param cosmosContainerName string

module network './network.bicep' = {
  name: 'myNetworkDeployment'
  params: {
    vnetName: vnetName
    location: location
  }
}

module apim './apim.bicep' = {
  name: 'myApimDeployment'
  params: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    subnetId: network.outputs.apimSubnetId
    location: location
    apiManagementServiceName: apiManagementServiceName
    skuCount: skuCount
    sku: sku
    deploymentPrefix: deploymentPrefix
  }
}
module functions './function.bicep' = {
  name: 'myFunctionsDeployment'
  params: {
    funcSubnetId: network.outputs.funcSubnetId
    location: location
    privateEndpointSubnetId: network.outputs.peSubnetId
    vnetId: network.outputs.vnetId
    appServicePlanName: appServicePlanName
    functionAppName: functionAppName
    functionStorageAccountName: functionStorageAccountName
    functionPlanOS: functionPlanOS
    deploymentPrefix: deploymentPrefix
  }
}

module cosmos './cosmos.bicep' = {
  name: 'myCosmosDeployment'
  params: {
    accountName: cosmosAccountName
    containerName: cosmosContainerName
    databaseName: cosmosDatabaseName
    privateEndpointSubnetId: network.outputs.peSubnetId
    vnetId: network.outputs.vnetId
    location: location
  }
}
