# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy in"
  default     = "us-east-1"
}

variable "key_pair_name" {
  description = "The name of the EC2 Key Pair"
  type        = string
  # Supply your key pair name here or via a .tfvars file
  # default = "your-key-pair-name"
}
