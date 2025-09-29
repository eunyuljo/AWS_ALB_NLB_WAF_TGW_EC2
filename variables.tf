variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hub-spoke"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "hub_vpc_cidr" {
  description = "CIDR block for hub VPC"
  type        = string
  default     = "10.0.0.0/16"
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "key_name" {
  description = "EC2 Key Pair name"
  type        = string
  default     = ""
}