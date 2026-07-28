variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC where resources will be deployed"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet where EC2 will run"
  type        = string
}
