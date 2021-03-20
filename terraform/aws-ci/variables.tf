variable "vpc_cidr" {
    description = "CIDR for the whole VPC"
    default = "10.83.0.0/16"
}

variable "public_subnet_cidr" {
    description = "CIDR for the Public Subnet"
    default = "10.83.0.0/24"
}

variable "private_subnet_cidr" {
    description = "CIDR for the Private Subnet"
    default = "10.84.1.0/24"
}
