variable "resource_group_location" {
  type        = string
  default     = "UK South"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "sm"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

variable "username" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default     = "smarlk"
}