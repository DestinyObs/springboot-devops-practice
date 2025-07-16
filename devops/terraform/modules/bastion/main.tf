# Bastion Host Module for Secure Access to Private Instances

# Data source for bastion host AMI
data "aws_ami" "bastion_ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Bastion Host Security Group
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-${var.environment}-bastion-"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from authorized IPs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-bastion-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Bastion Host Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.bastion_ubuntu.id
  instance_type          = var.bastion_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion.id]
  subnet_id              = var.public_subnet_id
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 10
    encrypted   = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3-pip
              pip3 install ansible
              EOF

  tags = {
    Name        = "${var.project_name}-${var.environment}-bastion"
    Environment = var.environment
    Project     = var.project_name
    Type        = "bastion"
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  tags = {
    Name        = "${var.project_name}-${var.environment}-bastion-eip"
    Environment = var.environment
    Project     = var.project_name
  }
}
