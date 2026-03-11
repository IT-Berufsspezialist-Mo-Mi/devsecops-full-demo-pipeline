resource "aws_s3_bucket" "demo_bucket" {
  bucket = "devsecops-demo-bucket-1234567890"

  tags = {
    Name        = "devsecops-demo-bucket"
    Environment = "dev"
    Owner       = "training"
  }
}
# Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
resource "aws_s3_bucket_public_access_block" "demo_bucket_pab" {
  bucket = aws_s3_bucket.demo_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
resource "aws_s3_bucket_versioning" "demo_bucket_versioning" {
  bucket = aws_s3_bucket.demo_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
# Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
resource "aws_s3_bucket_server_side_encryption_configuration" "demo_bucket_encryption" {
  bucket = aws_s3_bucket.demo_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
# Check: CKV2_AWS_41: "Ensure an IAM role is attached to EC2 instance"
resource "aws_iam_role" "ec2_role" {
  name = "devsecops-demo-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "devsecops-demo-ec2-role"
    Environment = "dev"
    Owner       = "training"
  }
}

# s.o.
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "devsecops-demo-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# Check: CKV_AWS_23: "Ensure every security group and rule has a description"
# Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
# Check: CKV_AWS_382: "Ensure no security groups allow egress from 0.0.0.0:0 to port -1"
# Check: CKV_AWS_260: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 80"
resource "aws_security_group" "web_sg" {
  name        = "devsecops-demo-sg"
  description = "Security group for demo EC2"

  ingress {
    description = "HTTP from internal network only"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "SSH from internal network only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow outbound HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "devsecops-demo-sg"
    Environment = "dev"
    Owner       = "training"
  }
}

# Füge Rolle an Instanz an
resource "aws_instance" "web" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  monitoring    = true
  ebs_optimized = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
  }

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