locals {
  # Calculate subnet CIDRs based on VPC CIDR
  vpc_cidr_prefix  = split(".", local.vpc_cidr)[0]
  vpc_second_octet = split(".", local.vpc_cidr)[1]

  private_subnet_zone1_cidr = "${local.vpc_cidr_prefix}.${local.vpc_second_octet}.0.0/19"
  private_subnet_zone2_cidr = "${local.vpc_cidr_prefix}.${local.vpc_second_octet}.32.0/19"
  public_subnet_zone1_cidr  = "${local.vpc_cidr_prefix}.${local.vpc_second_octet}.64.0/19"
  public_subnet_zone2_cidr  = "${local.vpc_cidr_prefix}.${local.vpc_second_octet}.96.0/19"
}

resource "aws_subnet" "private_zone1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_zone1_cidr
  availability_zone = local.zone1
  enable_resource_name_dns_a_record_on_launch = true
  

  tags = {
    "Name"                                                 = "${local.env}-private-${local.zone1}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
    Terraform                                              = "true"
    Environment                                            = local.env
  }
}

resource "aws_subnet" "private_zone2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = local.private_subnet_zone2_cidr
  availability_zone = local.zone2

  tags = {
    "Name"                                                 = "${local.env}-private-${local.zone2}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
    Terraform                                              = "true"
    Environment                                            = local.env
  }
}

resource "aws_subnet" "public_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_zone1_cidr
  availability_zone       = local.zone1
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone1}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
    Terraform                                              = "true"
    Environment                                            = local.env
  }
}

resource "aws_subnet" "public_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_subnet_zone2_cidr
  availability_zone       = local.zone2
  map_public_ip_on_launch = true

  tags = {
    "Name"                                                 = "${local.env}-public-${local.zone2}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
    Terraform                                              = "true"
    Environment                                            = local.env
  }
}