locals {
  # Environment configuration based on workspace
  env                 = terraform.workspace == "default" ? "staging" : terraform.workspace
  default_eks_version = "1.32"
  kubectl_version     = "1.32"
  # Common configuration
  region = "ap-south-1"
  zone1  = "ap-south-1a"
  zone2  = "ap-south-1b"

  # Environment-specific configurations
  env_config = {
    dev = {
      eks_name    = "sandbox-geeth-eks"
      eks_version = "1.31"
      bastion_key = "geeth-k3s-test"
      vpc_cidr    = "10.0.0.0/16"
      eks_private_access_type = true
      eks_public_access_type = true
    }
    staging = {
      eks_name    = "sandbox-geeth-eks"
      eks_version = "1.31"
      bastion_key = "geeth-k3s-test"
      vpc_cidr    = "10.1.0.0/16"
      eks_private_access_type = true
      eks_public_access_type = true
    }
    prod = {
      eks_name    = "sandbox-geeth-eks"
      eks_version = "1.30"
      bastion_key = "geeth-k3s-test"
      vpc_cidr    = "10.2.0.0/16"
      eks_private_access_type = true
      eks_public_access_type = false
    }
  }

  # Set default values if workspace doesn't match any environment
  env_defaults = {
    eks_name    = "geeth-eks-${local.env}"
    eks_version = local.default_eks_version
    bastion_key = "geeth-k3s-${local.env}"
  }

  # Merge the appropriate environment config with defaults
  env_settings = merge(
    local.env_defaults,
    lookup(local.env_config, local.env, {})
  )

  # Outputs
  eks_name    = local.env_settings.eks_name
  bastion_key = local.env_settings.bastion_key
  vpc_cidr    = lookup(local.env_settings, "vpc_cidr", "10.0.0.0/16")
  eks_version = local.env_settings.eks_version
}