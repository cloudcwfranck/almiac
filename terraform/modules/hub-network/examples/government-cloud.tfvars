# Example: Azure Government Cloud Hub Network

resource_group_name = "rg-network-hub-prd-ugv"
location            = "usgovvirginia"
environment         = "prod"
azure_cloud         = "usgovernment"

hub_address_space                     = ["10.100.0.0/16"]
firewall_subnet_address_prefix        = "10.100.1.0/26"
bastion_subnet_address_prefix         = "10.100.2.0/26"
gateway_subnet_address_prefix         = "10.100.3.0/27"
management_subnet_address_prefix      = "10.100.4.0/24"
shared_services_subnet_address_prefix = "10.100.5.0/24"

firewall_sku_tier           = "Premium"
idps_mode                   = "Deny"
enable_tls_inspection       = true
enable_vpn_gateway          = true
enable_expressroute_gateway = true
vpn_gateway_sku             = "VpnGw3AZ"
expressroute_gateway_sku    = "ErGw2AZ"
enable_ddos_protection      = true
availability_zones          = ["1", "2", "3"]

tags = {
  CostCenter  = "GOV-OPS-001"
  Owner       = "network-team@agency.gov"
  Compliance  = "FedRAMP-High,NIST-800-53"
}
