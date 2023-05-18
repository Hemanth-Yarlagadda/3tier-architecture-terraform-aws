variable "region" {
  description = "AWS Region where the infrastructure is to be deployed."
  type        = string
  default     = "us-east-1"
}

variable "prefix" {
  description = "The prefix name to be added to your resources"
  type        = string
  default     = "3-tier-artifact"
}

variable "tags" {
  description = "The generic tags to be used for your resources"
  type        = map(string)
  default = {
    "Terraform" = "true"
  }
}

########################
#VPC variables
########################
variable "vpc_name" {
  description = "The name of your VPC"
  type        = string
  default     = "terraform-deployed-vpc"
}

########################
#Ami variables
########################

variable "ami_name" {
  type =string
  description = "The name of the AMI"
  default = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
}

variable "ami_account_owner" {
  type =string
  description = "The owner account of the AMI image"
  default = "099720109477"
}

######################
#ALB variables
######################

variable "alb_name" {
  type =string
  description = "The name of the ALB"
  default = "3-tier-alb"
}

######################
#Auto Scaling Template variables
######################
variable "template_name" {
  type =string
  description = "The name of the Auto scaling template"
  default = "web-tier"
}

variable "asg_name" {
  type =string
  description = "The name of the Auto scaling group"
  default = "web-tier-asg"
}

######################
#RDS Instance variables
######################
variable "db_identifier" {
  type =string
  description = "Name to be used for the RDS instance"
  default = "db-postgres"
  
}
variable "instance_class" {
  type =string
  description = "The instance class to be used for the RDS instance"
  default = "db.r5.large"
}

variable "engine" {
  type =string
  description = "The database engine to be used for the RDS instance"
  default = "aurora-postgresql"
}

variable "engine_version" {
  type =string
  description = "The database engine version to be used for the RDS instance"
  default = "11.12"
}

