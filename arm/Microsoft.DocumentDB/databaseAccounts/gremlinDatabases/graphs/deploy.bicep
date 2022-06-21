@description('Required. Name of the graph.')
param name string

@description('Optional. Tags of the Gremlin graph resource.')
param tags object = {}

@description('Optional. Represents maximum throughput, the resource can scale up to.')
param maxThroughput int = 0

@description('Optional. Request Units per second. For example, "throughput": 10000.')
param throughput int = 0

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = false

@description('Conditional. The name of the parent Database Account. Required if the template is used in a standalone deployment.')
param databaseAccountName string

@description('Conditional. The name of the parent Gremlin Database. Required if the template is used in a standalone deployment.')
param gremlinDatabaseName string

@description('Optional. Indicates if the indexing policy is automatic.')
param automaticIndexing bool = true

@allowed([
  'consistent'
  'lazy'
  'none'
])
@description('Optional. Indicates the indexing mode.')
param indexingMode string = 'consistent'

@allowed([
  'Hash'
  'MultiHash'
  'Range'
])
@description('Optional. Indicates the kind of algorithm used for partitioning. For MultiHash, multiple partition keys (upto three maximum) are supported for container create.')
param kind string = 'Hash'

@description('Optional. List of paths using which data within the container can be partitioned.')
param partitionKeyPaths array = []

@description('Optional. List of paths must be unique for each document in the Azure Cosmos DB service.')
param uniqueKeyPaths array = []

@description('Optional. List of paths to include in the indexing.')
param indexingPaths array = []

resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
  name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name)}'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2022-02-15-preview' existing = {
  name: databaseAccountName

  resource gremlinDatabase 'gremlinDatabases@2022-02-15-preview' existing = {
    name: gremlinDatabaseName
  }
}

resource gremlinGraph 'Microsoft.DocumentDB/databaseAccounts/gremlinDatabases/graphs@2022-02-15-preview' = {
  name: name
  tags: tags
  parent: databaseAccount::gremlinDatabase
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: maxThroughput == 0 ? null : maxThroughput
      }
      throughput: throughput == 0 ? null : throughput
    }
    resource: {
      id: name
      indexingPolicy: {
        automatic: automaticIndexing
        indexingMode: indexingMode
        includedPaths: !empty(indexingPaths) ? indexingPaths : null
      }
      partitionKey: {
        kind: kind
        paths: !empty(partitionKeyPaths) ? partitionKeyPaths : null
      }
      uniqueKeyPolicy: !empty(uniqueKeyPaths) ? {
        uniqueKeys: [
          {
            paths: uniqueKeyPaths
          }
        ]
      } : null
    }
  }
}

@description('The name of the graph.')
output name string = gremlinGraph.name

@description('The resource ID of the graph.')
output resourceId string = gremlinGraph.id

@description('The name of the resource group the graph was created in.')
output resourceGroupName string = resourceGroup().name
