variable "sub_id" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "sp_id" {
  type = string
}

variable "sp_secret" {
  type      = string
  sensitive = true
}

variable "rg_names" {
  type = string
}

variable "rg_loc" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "vm_name" {
  type = string
}

variable "nic_name" {
  type = string
}

variable "public_ip_name" {
  type = string
}