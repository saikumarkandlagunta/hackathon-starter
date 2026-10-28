data "aws_availability_zones" "available" {
  state = "available"
}

variable "admin_cidr" {
  description = "Your public IPv4 address in /32 format, allowed to reach the EKS API"
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && endswith(var.admin_cidr, "/32")
    error_message = "Enter your public IPv4 address followed by /32."
  }
}

locals {
  name = "hackathon-starter-eks"

  tags = {
    Project     = "hackathon-starter"
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = local.name
  cidr = "10.20.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.20.0.0/20", "10.20.16.0/20"]
  private_subnets = []

  enable_nat_gateway      = false
  enable_dns_support      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"              = "1"
    "kubernetes.io/cluster/${local.name}" = "shared"
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = local.name
  kubernetes_version = "1.36"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.public_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = [var.admin_cidr]

  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = false
  create_kms_key                           = false
  encryption_config                        = null

  iam_role_name            = "${local.name}-cluster"
  iam_role_use_name_prefix = false

  addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = { before_compute = true }
  }

  eks_managed_node_groups = {
    app = {
      instance_types = ["t3.small"]
      min_size       = 1
      max_size       = 1
      desired_size   = 1

      iam_role_name            = "${local.name}-node"
      iam_role_use_name_prefix = false
    }
  }

  tags = local.tags
}
