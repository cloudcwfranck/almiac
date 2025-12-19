# Example: Web Application Spoke Network

resource_group_name = "rg-webapp-prd-eus"
location            = "eastus"
environment         = "prod"
workload_name       = "webapp"

spoke_address_space = ["10.1.0.0/16"]

subnets = {
  "snet-frontend" = {
    address_prefix    = "10.1.1.0/24"
    service_endpoints = ["Microsoft.Storage", "Microsoft.KeyVault"]
    security_rules = [
      {
        name                       = "AllowHTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        destination_port_range     = "443"
        source_address_prefix      = "Internet"
        destination_address_prefix = "*"
      }
    ]
  }
  "snet-application" = {
    address_prefix    = "10.1.2.0/24"
    service_endpoints = ["Microsoft.Sql"]
  }
  "snet-database" = {
    address_prefix                            = "10.1.3.0/24"
    private_endpoint_network_policies_enabled = false
    associate_route_table                     = false
  }
}

hub_vnet_id             = "/subscriptions/.../virtualNetworks/vnet-hub-eus-prd"
hub_vnet_name           = "vnet-hub-eus-prd"
hub_resource_group_name = "rg-network-hub-prd-eus"
hub_firewall_private_ip = "10.0.1.4"

tags = {
  CostCenter  = "APP-001"
  Owner       = "webapp-team@company.com"
  Application = "customer-portal"
}
