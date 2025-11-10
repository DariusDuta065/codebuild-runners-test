output "private_subnet_ids" {
  description = "List of private subnet IDs (existing subnets from private-subnets-nat-gateway module)"
  value       = data.aws_subnets.existing_private.ids
}

output "private_subnet_cidrs" {
  description = "List of private subnet CIDR blocks (existing subnets from private-subnets-nat-gateway module)"
  value       = [for subnet in data.aws_subnet.existing_private : subnet.cidr_block]
}

output "nat_instance_arn" {
  description = "ARN of the fck-nat EC2 instance"
  value       = aws_instance.fck_nat.arn
}

output "nat_instance_public_ip" {
  description = "Public IP address of the fck-nat instance"
  value       = aws_eip.fck_nat.public_ip
}

output "private_route_table_id" {
  description = "ID of the private route table (existing route table from private-subnets-nat-gateway module, now updated to use fck-nat)"
  value       = data.aws_route_table.existing_private.id
}

output "vpc_id" {
  description = "ID of the VPC where resources are created"
  value       = data.aws_vpc.default.id
}

output "nat_instance_id" {
  description = "ID of the fck-nat EC2 instance"
  value       = aws_instance.fck_nat.id
}

output "ssm_instance_profile_name" {
  description = "Name of the IAM instance profile attached to the fck-nat instance for SSM"
  value       = aws_iam_instance_profile.fck_nat_ssm.name
}

