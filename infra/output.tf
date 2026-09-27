output "public_ip" {
  description = "Public IP of the sentinel k3s node"
  value       = aws_instance.sentinel.public_ip
}