provider "aws" {
  secret_key = "SECRET_KEY"
  access_key = "ACCESS_KEY"
  region     = "${var.aws_region}"
}
    
