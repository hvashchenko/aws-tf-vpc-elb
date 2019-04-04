variable "aws_region" {
  description = "Region for the VPC"
  default = "us-east-2"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet1" {
  description = "CIDR for the public subnet"
  default = "10.0.1.0/24"
}
variable "public_subnet2" {
  description = "CIDR for the public subnet"
  default = "10.0.2.0/24"
}


variable "ami" {
  description = "Windows Server 2016 Base"
  default = "ami-04be6a27b0206807f"
}
variable "instance_type" {
  description = "type for aws EC2 instance"
  default = "t2.micro"
}

