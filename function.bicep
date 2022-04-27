// https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.web/function-app-storage-private-endpoints/main.bicep

param deploymentPrefix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

@description('OS used for Functions hosting plan')
@allowed([
  'Windows'
  'Linux'
])
param functionPlanOS string = 'Windows'

param vnetId string
param funcSubnetId string
param privateEndpointSubnetId string

param functionAppName string = '${deploymentPrefix}-func'
param appServicePlanName string = '${deploymentPrefix}-plan'
param functionStorageAccountName string = '${deploymentPrefix}st'

var appInsightsName = '${deploymentPrefix}-appinsights'
var privateStorageFileDnsZoneName = 'privatelink.file.${environment().suffixes.storage}'
var privateEndpointStorageFileName = '${storageAccount.name}-file-private-endpoint'
var privateStorageTableDnsZoneName = 'privatelink.table.${environment().suffixes.storage}'
var privateEndpointStorageTableName = '${storageAccount.name}-table-private-endpoint'
var privateStorageBlobDnsZoneName = 'privatelink.blob.${environment().suffixes.storage}'
var privateEndpointStorageBlobName = '${storageAccount.name}-blob-private-endpoint'
var privateStorageQueueDnsZoneName = 'privatelink.queue.${environment().suffixes.storage}'
var privateEndpointStorageQueueName = '${storageAccount.name}-queue-private-endpoint'

var functionContentShareName = 'function-content-share'
var isReserved = (functionPlanOS == 'Linux') ? true : false

resource functionapp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: isReserved ? 'functionapp,linux' : 'functionapp'
  dependsOn: [
    storageFilePrivateDnsZoneGroup
    storageBlobPrivateDnsZoneGroup
    storageQueuePrivateDnsZoneGroup
    storageTablePrivateDnsZoneGroup

    storageBlobDnsZoneLink
    storageQueueDnsZoneLink
    storageFileDnsZoneLink
    storageTableDnsZoneLink

    functionContentShare
  ]
  properties: {
    serverFarmId: appServicePlan.id
    reserved: isReserved
    siteConfig: {
      functionsRuntimeScaleMonitoringEnabled: true
      linuxFxVersion: isReserved ? 'dotnet|3.1' : json('null')
      appSettings: [
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsights.properties.InstrumentationKey
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTOVERVNET'
          value: '1'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: functionContentShareName
        }
      ]
    }
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  kind: 'elastic'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
    family: 'EP'
    size: 'EP1'
  }
  properties: {
    maximumElasticWorkerCount: 20
    reserved: isReserved
  }
}

// Private DNS Zones
resource storageFileDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageFileDnsZoneName
  location: 'global'
}

resource storageBlobDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageBlobDnsZoneName
  location: 'global'
}

resource storageQueueDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageQueueDnsZoneName
  location: 'global'
}

resource storageTableDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateStorageTableDnsZoneName
  location: 'global'
}

// Private DNS Zone Links
resource storageFileDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageFileDnsZone
  name: '${storageFileDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource storageBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageBlobDnsZone
  name: '${storageBlobDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource storageTableDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageTableDnsZone
  location: 'global'
  name: '${storageTableDnsZone.name}-link'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource storageQueueDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: storageQueueDnsZone
  name: '${storageQueueDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

// -- Private DNS Zone Groups --
resource storageFilePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageFilePrivateEndpoint
  name: 'filePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: storageFileDnsZone.id
        }
      }
    ]
  }
}

resource storageBlobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageBlobPrivateEndpoint
  name: 'blobPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: storageBlobDnsZone.id
        }
      }
    ]
  }
}

resource storageTablePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageTablePrivateEndpoint
  name: 'tablePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: storageTableDnsZone.id
        }
      }
    ]
  }
}

resource storageQueuePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  parent: storageQueuePrivateEndpoint
  name: 'tablePrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: storageQueueDnsZone.id
        }
      }
    ]
  }
}

// Private Endpoints
resource storageFilePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-03-01' = {
  name: privateEndpointStorageFileName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageFilePrivateLinkConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource storageTablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointStorageTableName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageTablePrivateLinkConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource storageQueuePrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointStorageQueueName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageQueuePrivateLinkConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'queue'
          ]
        }
      }
    ]
  }
}

resource storageBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: privateEndpointStorageBlobName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyStorageBlobPrivateLinkConnection'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: functionStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
    }
  }
}

resource functionContentShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: '${storageAccount.name}/default/${functionContentShareName}'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
  }
}

resource planNetworkConfig 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  parent: functionapp
  name: 'virtualNetwork'
  properties: {
    subnetResourceId: funcSubnetId
    swiftSupported: true
  }
}
