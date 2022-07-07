@description('Conditional. The administrator username for the server. Required if no `administrators` object for AAD authentication is provided.')
param administratorLogin string = ''

@description('Conditional. The administrator login password. Required if no `administrators` object for AAD authentication is provided.')
@secure()
param administratorLoginPassword string = ''

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Required. The name of the server.')
param name string

@description('Optional. Availability zone information of the server. If zero, then availability zones is not used.')
@allowed([
  '0'
  '1'
  '2'
  '3'
])
param availabilityZone string = '0'

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
  'Create'
  'Default'
  'PointInTimeRestore'
  'Update'
])
@description('Optional.	Set the object type.')
param createMode string = 'Default'

@description('Optional. Max storage allowed for a server.')
param storageSizeGB int = 512

@description('Optional. Backup retention days for the server.')
param backupRetentionDays int = 0

@allowed([
  'Enabled'
  'Disabled'
])
@description('Optional. A value indicating whether Geo-Redundant backup is enabled on the server.')
param geoRedundantBackup string = 'Disabled'

@allowed([
  'Disabled'
  'SameZone'
  'ZoneRedundant'
])
@description('Optional. The HA mode for the server.')
param mode string = 'Disabled'

@description('Optional.	Availability zone information of the standby.')
param standbyAvailabilityZone string = '0'

@description('Conditional. The source server resource ID to restore from. It\'s required when "createMode" is "PointInTimeRestore"..')
param sourceServerResourceId string = ''

@description('Conditional. Restore point creation time (ISO8601 format), specifying the time to restore from. It\'s required when "createMode" is "PointInTimeRestore".')
param pointInTimeUTC string = ''

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

@description('Required. The name of the sku, typically, tier + family + cores, e.g. Standard_D4s_v3.')
param skuName string

@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
@description('Optional. The tier of the particular SKU, e.g. Basic.')
param skuTier string = 'GeneralPurpose'

@allowed([
  '11'
  '12'
  '13'
])
@description('Optional. PostgreSQL Server version.')
param version string = '11'

@description('Optional. Delegated subnet arm resource id.')
param delegatedSubnetResourceId string = ''

@description('Optional. Private dns zone arm resource id.')
param privateDnsZoneArmResourceId string = ''

@description('Optional. ')
param maintenanceWindow object = {
  customWindow: 'Disabled'
  dayOfWeek: 0
  startHour: 0
  startMinute: 0
}

var network = !empty(delegatedSubnetResourceId) || !empty(privateDnsZoneArmResourceId) ? union(
  !empty(delegatedSubnetResourceId) ? {} : { delegatedSubnetResourceId: delegatedSubnetResourceId },
  !empty(delegatedSubnetResourceId) ? {} : { privateDnsZoneArmResourceId: privateDnsZoneArmResourceId }
) : null

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

resource server 'Microsoft.DBforPostgreSQL/flexibleServers@2022-01-20-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: contains(pickZones('Microsoft.DBforPostgreSQL', 'flexibleServers', location, 3), availabilityZone) ? availabilityZone : '0'
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    createMode: createMode
    highAvailability: {
      mode: mode
      standbyAvailabilityZone: standbyAvailabilityZone
    }
    maintenanceWindow: maintenanceWindow
    network: network
    pointInTimeUTC: createMode == 'PointInTimeRestore' ? pointInTimeUTC : null
    sourceServerResourceId: createMode == 'PointInTimeRestore' ? sourceServerResourceId : null
    storage: {
      storageSizeGB: storageSizeGB
    }
    version: version
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
