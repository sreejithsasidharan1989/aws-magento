variable "project" {
  default     = "$project"
  description = "Application"
}
variable "environment" {
  default     = "$environment"
  description = "Environment"
}
variable "region" {
  default     = "$region"
  description = "Project Region"
}
variable "ami_id" {
  default     = "$ami_id"
  description = "$region AMI_ID"
}
variable "vpc_cidr" {
  default     = "$vpc_cidr"
  description = "VPC CIDR"
}
variable "nat_switch" {}
locals {
  common_tags = {
    "project"     = var.project
    "environment" = var.environment
  }
  description = "Local Tags"
}
variable "instance-type" {
  default     = "$instance_type"
  description = "Instance Type"
}
variable "private-zone" {
  default     = "$private"
  description = "Private DNS Zone Name"
}
variable "public-zone" {
  default     = "$public"
  description = "Public DNS Zone Name"
}
variable "backend" {
  default     = "$db_server"
  description = "Database server hostname"
}
variable "docker" {
  default     = "$docker_server"
  description = "Docker server hostname"
}
variable "frontend" {
  default     = "$website_name"
  description = "Magento application hostname"
}
variable "alb_switch" {}
variable "cert_arn" {}
variable "cert_switch" {}
variable "dns_switch" {}
