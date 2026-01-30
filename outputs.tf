# Output definitions for your infrastructure
# Add outputs below as needed

output "aws_region" {
  description = "AWS region used"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.app_server.id
}

output "ec2_public_ip" {
  description = "EC2 instance public IP"
  value       = aws_instance.app_server.public_ip
}

output "ec2_security_group_id" {
  description = "Security group ID for EC2 instance"
  value       = aws_security_group.ec2_sg.id
}

output "ecr_repository_urls" {
  description = "URLs for ECR repositories"
  value = {
    for repo_name, repo in aws_ecr_repository.repositories :
    repo_name => repo.repository_url
  }
}

output "ecr_repository_arns" {
  description = "ARNs for ECR repositories"
  value = {
    for repo_name, repo in aws_ecr_repository.repositories :
    repo_name => repo.arn
  }
}


output "default_vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}

output "public_subnet_id" {
  description = "Public subnet ID where EC2 instance is deployed"
  value       = data.aws_subnets.default_public.ids[0]
}