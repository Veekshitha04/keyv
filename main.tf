data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_key_vault" "kv" {
  name                        = var.keyvault_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
}

resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
resource "azurerm_role_assignment" "app_service_kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_app_service.as.identity[0].principal_id
}
 
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.vnet_address]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.web_subnet_prefix]

  delegation {
    name = "delegation-to-web-serverfarms"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


resource "azurerm_subnet" "subnet2" {
  name                 = "${var.prefix}-s2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.sql_subnet_prefix]
}

resource "azurerm_app_service_plan" "asp" {
  name                = "${var.prefix}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = var.app_service_plan_tier
    size = var.app_service_plan_sku
  }
}

resource "azurerm_app_service" "as" {
  name                = "${var.prefix}-webapp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    linux_fx_version = "PYTHON|3.10"
    always_on        = true
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "SQL_USER"     = var.sql_admin_username
    "SQL_SERVER"   = "${azurerm_mssql_server.server.name}.database.windows.net"
    "SQL_DATABASE" = "${var.prefix}-db"
    "SQL_PASSWORD" = "StrongP@ssw0rd123"
    "PYTHON_ENV"   = "production"
  }

  lifecycle {
    ignore_changes = [
      app_settings
    ]
  }
}

resource "azurerm_mssql_server" "server" {
  name                         = "${var.prefix}-sql"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = var.sql_server_version
  administrator_login          = var.sql_admin_username
  administrator_login_password = var.sql_admin_password
#   administrator_login          = data.azurerm_key_vault_secret.example1.value
#   administrator_login_password = data.azurerm_key_vault_secret.example2.value
}

# resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
#   name             = "AllowAzureServices"
#   server_id        = azurerm_mssql_server.server.id
#   start_ip_address = "0.0.0.0"
#   end_ip_address   = "0.0.0.0"
# }

# resource "azurerm_mssql_database" "db" {
#   name           = "${var.prefix}-db"
#   server_id      = azurerm_mssql_server.server.id
#   collation      = "SQL_Latin1_General_CP1_CI_AS"
#   license_type   = "LicenseIncluded"
#   max_size_gb    = 2
#   sku_name       = var.sql_sku
#   enclave_type   = "VBS"
# }

# resource "azurerm_private_endpoint" "conn" {
#   name                = "${var.prefix}-conn"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   subnet_id           = azurerm_subnet.subnet2.id

#   private_service_connection {
#     name                           = "${var.prefix}-sql-pe-connection"
#     private_connection_resource_id = azurerm_mssql_server.server.id
#     is_manual_connection           = false
#     subresource_names              = ["sqlServer"]
#   }
# }

# resource "azurerm_private_dns_zone" "sql_dns" {
#   name                = "privatelink.database.windows.net"
#   resource_group_name = azurerm_resource_group.rg.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
#   name                  = "${var.prefix}-sql-dns-link"
#   resource_group_name   = azurerm_resource_group.rg.name
#   private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
#   virtual_network_id    = azurerm_virtual_network.vnet.id
# }

# resource "azurerm_private_dns_a_record" "sql_a_record" {
#   name                = azurerm_mssql_server.server.name
#   zone_name           = azurerm_private_dns_zone.sql_dns.name
#   resource_group_name = azurerm_resource_group.rg.name
#   ttl                 = 300
#   records             = [azurerm_private_endpoint.conn.private_service_connection[0].private_ip_address]
# }

# resource "azurerm_app_service_virtual_network_swift_connection" "connect" {
#   app_service_id = azurerm_app_service.as.id
#   subnet_id      = azurerm_subnet.subnet1.id
# }

# output "app_service_name" {
#   value = azurerm_app_service.as.name
# }

# output "resource_group_name" {
#   value = azurerm_resource_group.rg.name
# }
