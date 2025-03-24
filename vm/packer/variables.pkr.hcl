variable "azure_subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "azure_client_id" {
  type        = string
  description = "Azure client ID"
}

variable "azure_client_secret" {
  type        = string
  description = "Azure client secret"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure tenant ID"
}

variable "resource_group" {
  type        = string
  description = "Resource group"
  default     = "is-azure-marketplace-poc"
}

variable "sig_gallery_name" {
  type        = string
  description = "Name of the Shared Image Gallery"
  default     = "acgisazuremarketplace"
}

variable "sig_image_name" {
  type        = string
  description = "Name of the image in the Shared Image Gallery"
  default     = "imgisazuremarketplacedemo"
}

variable "sig_image_version" {
  type        = string
  description = "Version of the image in the Shared Image Gallery"
}

variable "location" {
  type        = string
  description = "Azure region for the resources"
  default     = "eastus2"
}
