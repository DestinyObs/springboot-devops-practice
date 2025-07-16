# EC2 Module for Spring Boot Application

# Data source to get the latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
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

resource "aws_instance" "app_server" {
  count                  = var.instance_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_ids[count.index % length(var.subnet_ids)]
  associate_public_ip_address = true
  iam_instance_profile   = var.iam_instance_profile

  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    encrypted   = true
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-app-${count.index + 1}"
    Type = "application"
  })
}

# Elastic IP for instances (optional)
resource "aws_eip" "app_eip" {
  count    = var.enable_eip ? var.instance_count : 0
  instance = aws_instance.app_server[count.index].id
  domain   = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eip-${count.index + 1}"
  })
}


