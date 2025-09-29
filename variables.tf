variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "central-spoke"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "central_vpc_cidr" {
  description = "CIDR block for central VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "spoke_vpc_cidr" {
  description = "CIDR block for the single spoke VPC"
  type        = string
  default     = "10.1.0.0/16"
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