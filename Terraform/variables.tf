variable "aws_access_key" {
  type        = string
  description = "AWS Access Key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Secret Key"
}
variable "region" {
  type    = string
  default = "us-west-2"
  description = "AWS Region"
}
variable "environment" {
  type    = string
  default = "dev"
}

variable "key_name" {
  type    = string
  default = "ec2-key"
  description = "EC2 key pair name"
}
