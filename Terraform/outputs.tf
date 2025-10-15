# IP publique de l'EC2
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

# ID de l'instance
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web.id
}

# Security group ID
output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.web_sg.id
}
