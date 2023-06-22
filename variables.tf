variable "project" {
  default     = "magento"
  description = "Application"
}
variable "environment" {
  default     = "development"
  description = "Environment"
}
variable "region" {
  default     = "ap-south-1"
  description = "Project Region"
}
variable "ami_id" {
  default     = "ami-01a4f99c4ac11b03c"
  description = "ap-south-1 AMI_ID"
}
variable "vpc_cidr" {
  default     = "172.16.0.0/16"
  description = "VPC CIDR"
}
variable "switch_nat" {}
locals {
  common_tags = {
    "project"     = var.project
    "environment" = var.environment
  }
  description = "Local Tags"
}
variable "instance-type" {
  default     = "t2.micro"
  description = "Instance Type"
}
variable "private-domain" {
  default     = "backtracker.local"
  description = "DB_HOST Value"
}
variable "public-domain" {
  default     = "backtracker.tech"
  description = "Magento application Hostname"
}


