# 1. VPC e Internet Gateway
resource "aws_vpc" "vpc_shared_services" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "vpc-shared-services" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_shared_services.id
  tags       = { Name = "main-igw" }
}

# 2. Subnets Públicas
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.vpc_shared_services.id
  cidr_block        = var.public_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags              = { Name = "public-subnet-${var.azs[count.index]}" }
}

# 3. NAT Gateways (Uno por AZ)
resource "aws_eip" "nat" {
  count = 2
  domain = "vpc"
}

resource "aws_nat_gateway" "gw" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id # Se coloca en la subnet pública
  tags          = { Name = "nat-gw-${var.azs[count.index]}" }
}

# 4. Subnets Privadas
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.vpc_shared_services.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]
  tags              = { Name = "private-subnet-${var.azs[count.index]}" }
}

# 5. Tablas de Rutas Privadas (apuntando a su respectivo NAT)
resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.vpc_shared_services.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.gw[count.index].id
  }
  tags = { Name = "rt-private-${var.azs[count.index]}" }
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
