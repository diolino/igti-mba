terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.region
}


resource "aws_s3_bucket" "project-bucket-gtdiolino" {
  bucket = "project-bucket-gtdiolino"

  tags = {
    project        = "gtdiolino-lab-project"    
    Name        = "project-bucket-gtdiolino"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "project-bucket-gtdiolino-acl" {
  bucket = aws_s3_bucket.project-bucket-gtdiolino.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "project-bucket-gtdiolino-versioning" {
  bucket = aws_s3_bucket.project-bucket-gtdiolino.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "project-bucket-gtdiolino-obj1" {
  bucket = aws_s3_bucket_versioning.project-bucket-gtdiolino-versioning.bucket
  key    = "obj1" //name of the object
  source = "obj1.txt"
  tags = {
    project        = "gtdiolino-lab-project"    
  }
}