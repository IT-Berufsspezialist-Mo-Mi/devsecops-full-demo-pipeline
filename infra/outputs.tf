output "instance_public_ip" {
  value = aws_instance.web.public_ip
}

output "health_url" {
  value = "http://${aws_instance.web.public_ip}/health"
}