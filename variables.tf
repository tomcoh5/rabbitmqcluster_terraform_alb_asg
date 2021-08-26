variable "admin_password" {
  default = "my123"
}

variable "rabbit_password" {
  default = "my123"
}

variable "secret_cookie" {
  default = "my123"
}

variable "region" {
  default = "eu-west-1"
}
variable "vpc_id" {
  default = "vpc-2efb4d57"
}

variable "ssh_key_name" {
  description = "ssh key name"
  default =  "cli"
}

variable "name" {
  description = "nme"
  default = "main"
}

variable "min_size" {
  description = "Minimum number of RabbitMQ nodes"
  default     = 2
}

variable "desired_size" {
  description = "Desired number of RabbitMQ nodes"
  default     = 4
}

variable "max_size" {
  description = "Maximum number of RabbitMQ nodes"
  default     = 5
}

variable "s" {
  
}

variable "subnet_ids" {
  description = "Subnets for RabbitMQ nodes"
  type        = list(string)
  default = ["subnet-9eec1fd5", "subnet-3608256c"]
}

variable "nodes_additional_security_group_ids" {
  type    = list(string)
  default = []
}

variable "elb_additional_security_group_ids" {
  type    = list(string)
  default = []
}

variable "instance_type" {
  default = "m5.large"
}

variable "instance_volume_type" {
  default = "standard"
}

variable "instance_volume_size" {
  default = "0"
}

variable "instance_volume_iops" {
  default = "0"
}
