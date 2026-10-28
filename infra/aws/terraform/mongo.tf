data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]

  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "mongodb" {
  name        = "${local.name}-mongodb"
  description = "SSH from the administrator and MongoDB from EKS nodes"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH from administrator"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description     = "MongoDB from EKS nodes only"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    description = "Allow outbound traffic for package installation and updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.name}-mongodb-sg"
  })
}

resource "aws_instance" "mongodb" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mongodb.id]
  key_name                    = "hackathon-starter-mongo-ansible"

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = 12
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = merge(local.tags, {
    Name = "${local.name}-mongodb"
  })
}

output "mongodb_public_ip" {
  description = "Public IP Ansible will use to SSH to the MongoDB server"
  value       = aws_instance.mongodb.public_ip
}

output "mongodb_private_ip" {
  description = "Private IP the application will use to connect to MongoDB"
  value       = aws_instance.mongodb.private_ip
}
