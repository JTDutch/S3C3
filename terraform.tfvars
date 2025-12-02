#####################################
# Project identification
#####################################
project_name = "cs3"
region       = "eu-west-1"

#####################################
# Networking
#####################################
vpc_cidr               = "10.0.0.0/16"
public_subnet_1a_cidr  = "10.0.1.0/24"
public_subnet_1b_cidr  = "10.0.2.0/24"
private_subnet_db_cidr = "10.0.10.0/24"

#####################################
# Database credentials
#####################################
db_username = "admin"
db_password = "SuperSecureDBPassword123!"

#####################################
# ECS Container Image
# MUST exist in your AWS ECR OR public repo
#####################################
web_image = "public.ecr.aws/docker/library/php:8.2-apache"

