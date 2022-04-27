param deploymentPrefix string = uniqueString(resourceGroup().id)

@description('Location for all resources.')
param location string = resourceGroup().location

param privateEndpointSubnetId string
param vnetId string

// takes into account deployment prefix
@maxLength(30)
@minLength(3)
param accountName string

@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@allowed([
  'Eventual'
  'ConsistentPrefix'
  'Session'
  'BoundedStaleness'
  'Strong'
])
param defaultConsistencylevel string = 'BoundedStaleness'

@description('Max lag time (minutes). Required for BoundedStaleness. Valid ranges, Single Region: 5 to 84600. Multi Region: 300 to 86400.')
@minValue(5)
@maxValue(86400)
param maxIntervalInSeconds int = 300

@description('Max stale requests. Required for BoundedStaleness. Valid ranges, Single Region: 10 to 1000000. Multi Region: 100000 to 1000000.')
@minValue(10)
@maxValue(2147483647)
param maxStalenessPrefix int = 1000000
param enableAutomaticFailover bool = false
param enableMultipleWriteLocations bool = false
param databaseName string
param containerName string

@minValue(4000)
@maxValue(1000000)
param autoscaleMaxThroughput int = 4000

var privateEndpointCosmosDnsZoneName = 'privatelink.documents.azure.com'
var privateEndpointCosmosName = '${cosmosAccountName}-private-endpoint'
var locations = [
  {
    locationName: location
    failoverPriority: 0
    isZoneRedundant: false
  }
]
var cosmosAccountName = '${deploymentPrefix}-${toLower(accountName)}'
var consistencyPolicy = {
  Eventual: {
    defaultConsistencyLevel: 'Eventual'
  }
  ConsistentPrefix: {
    defaultConsistencyLevel: 'ConsistentPrefix'
  }
  Session: {
    defaultConsistencyLevel: 'Session'
  }
  BoundedStaleness: {
    defaultConsistencyLevel: 'BoundedStaleness'
    maxStalenessPrefix: maxStalenessPrefix
    maxIntervalInSeconds: maxIntervalInSeconds
  }
  Strong: {
    defaultConsistencyLevel: 'Strong'
  }
}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2021-10-15' = {
  name: cosmosAccountName
  location: location
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    consistencyPolicy: consistencyPolicy[defaultConsistencylevel]
    locations: locations
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: enableAutomaticFailover
    enableMultipleWriteLocations: enableMultipleWriteLocations
    publicNetworkAccess: publicNetworkAccess
  }
}

resource cosmosDatabase 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-10-15' = {
  name: '${cosmosAccount.name}/${databaseName}'
  dependsOn: [
    cosmosPrivateDnsZoneGroup
    cosmosDnsZoneLink
  ]
  properties: {
    resource: {
      id: databaseName
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-10-15' = {
  name: '${cosmosDatabase.name}/${containerName}'
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          {
            path: '/*'
          }
        ]
        excludedPaths: [
          {
            path: '/_etag/?'
          }
        ]
      }
    }
    options: {
      autoscaleSettings: {
        maxThroughput: autoscaleMaxThroughput
      }
    }
  }
}

resource cosmosDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateEndpointCosmosDnsZoneName
  location: 'global'
}

resource cosmosDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: cosmosDnsZone
  name: '${cosmosDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource cosmosPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: cosmosPrivateEndpoint
  name: 'appPrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config'
        properties: {
          privateDnsZoneId: cosmosDnsZone.id
        }
      }
    ]
  }
}

resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointCosmosName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'MyCosmosPrivateLinkConnection'
        properties: {
          privateLinkServiceId: cosmosAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}
