data "azurerm_client_config" "current" {}   #to fetch info about tenanat,object id for keyvault accesss
data "azuread_service_principal" "sp" {
  client_id = "b8e0ea58-6ab1-4082-a770-0719bbcc6dba"
}
resource "azurerm_resource_group" "rg" {
  name     = var.res_grp_name
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
resource "azurerm_role_assignment" "sp_kv_secrets_officer" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azuread_service_principal.sp.object_id
}
 
resource "azurerm_role_assignment" "user_secret_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = "0478ae62-bf06-425a-904c-d23d941b3f1e"
}
resource "azurerm_key_vault_secret" "example1" {
  name         = "SQL-PASSWORD1"
  value        = var.sql_pa
  key_vault_id = azurerm_key_vault.kv.id
  depends_on          = [azurerm_role_assignment.sp_kv_secrets_officer]
}
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.v_add
}
resource "azurerm_subnet" "subnet1" {
  name                 = "${var.prefix}-s1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.s1_add
 
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
  address_prefixes     = var.s2_add
}
resource "azurerm_app_service_plan" "asp" {
  name                = var.asn
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = var.plan_kind
  reserved            = true
  sku {
    tier = var.plan_tier
    size = var.plan_size
  }
}
resource "azurerm_app_service" "apps" {
  name                = var.app_service_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.asp.id
 
  site_config {
    linux_fx_version = "NODE|18-lts"
    always_on        = true
  }
 
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "SQL_USER"                 = "rajitha"
    "SQL_SERVER"               = "rajitha-sql.database.windows.net"
    "SQL_DATABASE"             = "rajitha-db"
     "SQL_PASSWORD" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.example1.id})"
 
   
   
   
 
    "NODE_ENV" = "production"
  }
  identity {
    type = "SystemAssigned"
  }
  lifecycle {
 
    ignore_changes = [
      source_control
    ]
 
 
  }
  depends_on = [
   azurerm_key_vault_secret.example1,
  azurerm_role_assignment.sp_kv_secrets_officer,
  azurerm_role_assignment.user_secret_user
]
 
 
 
}
 
resource "azurerm_app_service_virtual_network_swift_connection" "connect" {
  app_service_id = azurerm_app_service.apps.id
  subnet_id      = azurerm_subnet.subnet1.id
}
 
resource "azurerm_mssql_server" "server" {
  name                         = var.sql_server_name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.server_login
  administrator_login_password = var.server_pass
 
}
 
resource "azurerm_mssql_database" "db" {
  name         = "${var.prefix}-db"
  server_id    = azurerm_mssql_server.server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  license_type = "LicenseIncluded"
  max_size_gb  = 2
  sku_name     = "S0"
}
 
resource "azurerm_private_endpoint" "conn" {
  name                = "${var.prefix}-conn"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.subnet2.id
 
  private_service_connection {
    name                           = "example-sql-connection"
    private_connection_resource_id = azurerm_mssql_server.server.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }
}
 
resource "azurerm_private_dns_zone" "sql_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}
 
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "${var.prefix}-sdl"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
 
resource "azurerm_private_dns_a_record" "sql_a_record" {
  name                = azurerm_mssql_server.server.name
  zone_name           = azurerm_private_dns_zone.sql_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.conn.private_service_connection[0].private_ip_address]
}