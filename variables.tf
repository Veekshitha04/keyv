variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "keyvault_name"{
    description="name of the keyvault"
    type  = string
}
variable "vnet_address" {
  description = "Address space for the virtual network"
  type        = string
}

variable "web_subnet_prefix" {
  description = "Subnet address prefix for the web subnet"
  type        = string
}

variable "sql_subnet_prefix" {
  description = "Subnet address prefix for the SQL subnet"
  type        = string
}

variable "sql_database_name" {
  description = "The name of the SQL database"
  type        = string
}

variable "app_service_plan_tier" {
  description = "The tier of the App Service Plan"
  type        = string
}

variable "app_service_plan_sku" {
  description = "The SKU of the App Service Plan"
  type        = string
}

variable "sql_admin_username" {
  description = "The SQL server administrator username"
  type        = string
}

variable "sql_admin_password" {
  description = "The SQL server administrator password"
  type        = string
}

variable "sql_server_version" {
  description = "The SQL server version"
  type        = string
}

variable "sql_sku" {
  description = "The SKU of the SQL server"
  type        = string
}

variable "web_app_name" {
  description = "The name of the web application"
  type        = string
}

variable "service_connection" {
  description = "The name of the private service connection"
  type        = string
}

variable "dns_name" {
  description = "The DNS name for the private link"
  type        = string
}

