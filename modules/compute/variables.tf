variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the instance will be created"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet ID for the EC2 instance"
  type        = string
}
