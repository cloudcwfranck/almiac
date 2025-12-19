// Route Table Module

@description('Route table name')
param routeTableName string

@description('Azure region')
param location string

@description('Firewall private IP address')
param firewallPrivateIp string

@description('Tags')
param tags object

// Route Table
resource routeTable 'Microsoft.Network/routeTables@2023-05-01' = {
  name: routeTableName
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'default-route-to-firewall'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
      {
        name: 'azure-internet-route'
        properties: {
          addressPrefix: 'Internet'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: firewallPrivateIp
        }
      }
    ]
  }
}

// Outputs
output routeTableId string = routeTable.id
output routeTableName string = routeTable.name
