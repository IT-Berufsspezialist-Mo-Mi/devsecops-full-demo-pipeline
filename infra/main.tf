resource "aws_s3_bucket" "demo_bucket" {
  bucket = "devsecops-demo-bucket-1234567890"

  tags = {
    Name        = "devsecops-demo-bucket"
    Environment = "dev"
    Owner       = "training"
  }
}

resource "aws_s3_bucket_public_access_block" "demo_bucket_pab" {
  bucket = aws_s3_bucket.demo_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_security_group" "web_sg" {
  name        = "devsecops-demo-sg"
  description = "Security group for demo EC2"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devsecops-demo-sg"
    Environment = "dev"
    Owner       = "training"
  }
}

resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl enable httpd
              systemctl start httpd
              echo "DevSecOps Demo Server" > /var/www/html/index.html
              echo "OK" > /var/www/html/health
              EOF

  tags = {
    Name        = "devsecops-demo-ec2"
    Environment = "dev"
    Owner       = "training"
  }
}