// DDoS Protection Plan Module

@description('DDoS Protection Plan name')
param ddosPlanName string

@description('Azure region')
param location string

@description('Tags')
param tags object

resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2023-05-01' = {
  name: ddosPlanName
  location: location
  tags: tags
  properties: {}
}

output ddosPlanId string = ddosProtectionPlan.id
output ddosPlanName string = ddosProtectionPlan.name
