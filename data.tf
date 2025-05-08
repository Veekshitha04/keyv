# data "azurerm_key_vault" "example" {
#   name                = var.keyvault_name
#   resource_group_name = "${var.prefix}-rg"
#   depends_on = [azurerm_key_vault.kv]
# }
 
# data "azurerm_key_vault_secret" "example1" {
#   name         = "username"
#   key_vault_id = data.azurerm_key_vault.example.id
# }
# data "azurerm_key_vault_secret" "example2" {
#   name         = "password"
#   key_vault_id = data.azurerm_key_vault.example.id
# }
# # data "azurerm_key_vault_secret" "sqlpass" {
# #   name         = "sql-p"
# #   key_vault_id = data.azurerm_key_vault.example.id
# # }