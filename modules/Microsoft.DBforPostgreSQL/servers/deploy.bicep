@description('Conditional. The administrator username for the server. Required if no `administrators` object for AAD authentication is provided.')
param administratorLogin string = ''

@description('Conditional. The administrator login password. Required if no `administrators` object for AAD authentication is provided.')
@secure()
param administratorLoginPassword string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. The name of the server.')
param name string

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@allowed([
  ''
  'CanNotDelete'
  'ReadOnly'
])
@description('Optional. Specify the type of lock.')
param lock string = ''

@description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
param roleAssignments array = []

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Optional. Enable telemetry via the Customer Usage Attribution ID (GUID).')
param enableDefaultTelemetry bool = true

@allowed([
  'Default'
  'GeoRestore'
  'PointInTimeRestore'
  'Replica'
])
@description('Optional.	Set the object type.')
param createMode string = 'Default'

@description('Conditional. The source server id to restore from. Required, if "createMode" is not "Default".')
param sourceServerId string = ''

@description('Conditional. Restore point creation time (ISO8601 format), specifying the time to restore from. Required, if "createMode" is "Restore".')
param restorePointInTime string = ''

@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'DataPlaneRequests'
  'MongoRequests'
  'QueryRuntimeStatistics'
  'PartitionKeyStatistics'
  'PartitionKeyRUConsumption'
  'ControlPlaneRequests'
  'CassandraRequests'
  'GremlinRequests'
  'TableApiRequests'
])
param diagnosticLogCategoriesToEnable array = [
  'DataPlaneRequests'
  'MongoRequests'
  'QueryRuntimeStatistics'
  'PartitionKeyStatistics'
  'PartitionKeyRUConsumption'
  'ControlPlaneRequests'
  'CassandraRequests'
  'GremlinRequests'
  'TableApiRequests'
]

@allowed([
  'Requests'
])
@description('Optional. The name of metrics that will be streamed.')
param diagnosticMetricsToEnable array = [
  'Requests'
]

@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${name}-diagnosticSettings'

@allowed([
  'Basic'
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('Optional. The tier of the particular SKU, e.g. Basic.')
param skuTier string = 'GeneralPurpose'

@allowed([
  2
  4
  8
  16
  32
  64
])
@description('Optional. The scale up/out capacity, representing server\'s compute units.')
param capacity int = 4

@allowed([
  'Gen5'
])
@description('Optional. The family of hardware.')
param skuFamily string = 'Gen5'

@description('Optional. The size code, to be interpreted by resource as appropriate.')
param skuSize string

@allowed([
  'Disabled'
  'Enabled'
])
@description('Optional. Status showing whether the server enabled infrastructure encryption.')
param infrastructureEncryption string = 'Enabled'

@allowed([
  '10'
  '11'
])
@description('Optional. Server version.')
param version string = '11'

@allowed([
  'TLS1_0'
  'TLS1_1'
  'TLS1_2'
  'TLSEnforcementDisabled'
])
@description('Optional. Enforce a minimal Tls version for the server.')
param minimalTlsVersion string = 'TLS1_2'

@allowed([
  'Disabled'
  'Enabled'
])
@description('Optional. Whether or not public network access is allowed for this server. Value is optional but if passed in, must be "Enabled" or "Disabled".')
param publicNetworkAccess string = 'Enabled'

@allowed([
  'Disabled'
  'Enabled'
])
@description('Optional. Whether or not public network access is allowed for this server. Value is optional but if passed in, must be "Enabled" or "Disabled".')
param sslEnforcement string = 'Enabled'

@description('Optional. Storage profile of a server.')
param storageProfile object = {
  backupRetentionDays: 7
  geoRedundantBackup: 'Disabled'
  storageAutogrow: 'Enabled'
  storageMB: 100 * 1000
}

var skuName = '${skuTier == 'Basic' ? 'B' : skuTier == 'GeneralPurpose' ? 'GP' : 'MO'}_${skuFamily}_${capacity}'

var diagnosticsLogs = [for category in diagnosticLogCategoriesToEnable: {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

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

resource server 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    capacity: capacity
    family: skuFamily
    name: skuName
    size: skuSize
    tier: skuTier
  }
  identity: {
    type: systemAssignedIdentity ? 'SystemAssigned' : null
  }
  properties: {
    infrastructureEncryption: infrastructureEncryption
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: publicNetworkAccess
    sslEnforcement: sslEnforcement
    storageProfile: storageProfile
    version: version
    #disable-next-line BCP225
    createMode: createMode
    sourceServerId: createMode != 'Default' ? sourceServerId : null
    administratorLogin: createMode == 'Default' ? administratorLogin : null
    administratorLoginPassword: createMode == 'Default' ? administratorLoginPassword : null
    restorePointInTime: createMode == 'Restore' ? restorePointInTime : null
  }
}

resource server_lock 'Microsoft.Authorization/locks@2017-04-01' = if (!empty(lock)) {
  name: '${server.name}-${lock}-lock'
  properties: {
    level: any(lock)
    notes: lock == 'CanNotDelete' ? 'Cannot delete resource or child resources.' : 'Cannot modify the resource or child resources.'
  }
  scope: server
}

resource server_diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(diagnosticWorkspaceId)) || (!empty(diagnosticEventHubAuthorizationRuleId)) || (!empty(diagnosticEventHubName))) {
  name: diagnosticSettingsName
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: server
}

module server_rbac '.bicep/nested_rbac.bicep' = [for (roleAssignment, index) in roleAssignments: {
  name: '${uniqueString(deployment().name, location)}-Rbac-${index}'
  params: {
    description: contains(roleAssignment, 'description') ? roleAssignment.description : ''
    principalIds: roleAssignment.principalIds
    principalType: contains(roleAssignment, 'principalType') ? roleAssignment.principalType : ''
    roleDefinitionIdOrName: roleAssignment.roleDefinitionIdOrName
    resourceId: server.id
  }
}]

/* module sqlDatabases_resource 'sqlDatabases/deploy.bicep' = [for sqlDatabase in sqlDatabases: {
  name: '${uniqueString(deployment().name, location)}-sqldb-${sqlDatabase.name}'
  params: {
    databaseAccountName: databaseAccount.name
    name: sqlDatabase.name
    containers: contains(sqlDatabase, 'containers') ? sqlDatabase.containers : []
    enableDefaultTelemetry: enableReferencedModulesTelemetry
  }
}]
 */
