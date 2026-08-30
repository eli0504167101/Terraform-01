output "frontend_instance_id" {
  description = "ID of the frontend EC2 instance"
  value       = aws_instance.frontend.id
}

output "frontend_public_ip" {
  description = "Public IPv4 address of the frontend server"
  value       = aws_instance.frontend.public_ip
}

output "frontend_url" {
  description = "HTTP URL of the frontend application"
  value       = "http://${aws_instance.frontend.public_ip}"
}
output "backend_instance_id" {
  description = "ID of the backend EC2 instance"
  value       = aws_instance.backend.id
}

output "backend_private_ip" {
  description = "Private IPv4 address of the backend server"
  value       = aws_instance.backend.private_ip
}