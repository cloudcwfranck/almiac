// VPN and ExpressRoute Gateway Module

@description('Gateway name prefix')
param gatewayNamePrefix string

@description('Azure region')
param location string

@description('Gateway subnet ID')
param gatewaySubnetId string

@description('Enable VPN Gateway')
param enableVpnGateway bool = true

@description('VPN Gateway SKU')
@allowed([
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw4'
  'VpnGw5'
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
  'VpnGw4AZ'
  'VpnGw5AZ'
])
param vpnGatewaySku string = 'VpnGw2AZ'

@description('Enable VPN active-active')
param vpnActiveActive bool = false

@description('Enable VPN BGP')
param vpnEnableBgp bool = true

@description('VPN BGP ASN')
@minValue(64512)
@maxValue(65534)
param vpnBgpAsn int = 65515

@description('Enable ExpressRoute Gateway')
param enableExpressRouteGateway bool = false

@description('ExpressRoute Gateway SKU')
@allowed([
  'Standard'
  'HighPerformance'
  'UltraPerformance'
  'ErGw1AZ'
  'ErGw2AZ'
  'ErGw3AZ'
])
param expressRouteGatewaySku string = 'Standard'

@description('Availability zones')
param availabilityZones array = [
  '1'
  '2'
  '3'
]

@description('Tags')
param tags object

// VPN Gateway Resources
resource vpnGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableVpnGateway) {
  name: '${gatewayNamePrefix}-vpn-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: contains(vpnGatewaySku, 'AZ') ? availabilityZones : []
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource vpnGatewayPublicIp2 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableVpnGateway && vpnActiveActive) {
  name: '${gatewayNamePrefix}-vpn-pip2'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  zones: contains(vpnGatewaySku, 'AZ') ? availabilityZones : []
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = if (enableVpnGateway) {
  name: '${gatewayNamePrefix}-vpn'
  location: location
  tags: tags
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    sku: {
      name: vpnGatewaySku
      tier: vpnGatewaySku
    }
    activeActive: vpnActiveActive
    enableBgp: vpnEnableBgp
    bgpSettings: vpnEnableBgp ? {
      asn: vpnBgpAsn
    } : null
    ipConfigurations: concat([
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: vpnGatewayPublicIp.id
          }
        }
      }
    ], vpnActiveActive ? [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: vpnGatewayPublicIp2.id
          }
        }
      }
    ] : [])
  }
}

// ExpressRoute Gateway Resources
resource erGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2023-05-01' = if (enableExpressRouteGateway && !enableVpnGateway) {
  name: '${gatewayNamePrefix}-er-pip'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource expressRouteGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = if (enableExpressRouteGateway && !enableVpnGateway) {
  name: '${gatewayNamePrefix}-er'
  location: location
  tags: tags
  properties: {
    gatewayType: 'ExpressRoute'
    sku: {
      name: expressRouteGatewaySku
      tier: expressRouteGatewaySku
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetId
          }
          publicIPAddress: {
            id: erGatewayPublicIp.id
          }
        }
      }
    ]
  }
}

// Outputs
output vpnGatewayId string = enableVpnGateway ? vpnGateway.id : ''
output vpnGatewayName string = enableVpnGateway ? vpnGateway.name : ''
output vpnGatewayPublicIp string = enableVpnGateway ? vpnGatewayPublicIp.properties.ipAddress : ''
output expressRouteGatewayId string = enableExpressRouteGateway && !enableVpnGateway ? expressRouteGateway.id : ''
output expressRouteGatewayName string = enableExpressRouteGateway && !enableVpnGateway ? expressRouteGateway.name : ''
