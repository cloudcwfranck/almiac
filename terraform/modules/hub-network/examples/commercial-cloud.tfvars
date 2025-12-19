# Example: Azure Commercial Cloud Hub Network

resource_group_name = "rg-network-hub-prd-eus"
location            = "eastus"
environment         = "prod"
azure_cloud         = "public"

hub_address_space                     = ["10.0.0.0/16"]
firewall_subnet_address_prefix        = "10.0.1.0/26"
bastion_subnet_address_prefix         = "10.0.2.0/26"
gateway_subnet_address_prefix         = "10.0.3.0/27"
management_subnet_address_prefix      = "10.0.4.0/24"
shared_services_subnet_address_prefix = "10.0.5.0/24"

firewall_sku_tier    = "Premium"
idps_mode            = "Alert"
enable_vpn_gateway   = true
vpn_gateway_sku      = "VpnGw2AZ"
availability_zones   = ["1", "2", "3"]

tags = {
  CostCenter  = "IT-OPS-001"
  Owner       = "network-team@company.com"
  Criticality = "Mission-Critical"
}
