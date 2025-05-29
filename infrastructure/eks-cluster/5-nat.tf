resource "aws_eip" "nat" {
  count  = local.env == "dev" ? 0 : 1
  domain = "vpc"

  tags = {
    Name        = "${local.env}-nat"
    Terraform   = "true"
    Environment = local.env
  }
}

resource "aws_nat_gateway" "nat" {
  count         = local.env == "dev" ? 0 : 1
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public_zone1.id

  tags = {
    Name        = "${local.env}-nat"
    Terraform   = "true"
    Environment = local.env
  }

  depends_on = [aws_internet_gateway.igw]
}