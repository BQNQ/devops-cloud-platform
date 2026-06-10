resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "flask-app-${terraform.workspace}-vpc",
    Env  = terraform.workspace
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidr)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "flask-app-${terraform.workspace}-subnet-public${count.index}-${var.azs[count.index]}",
    Env  = terraform.workspace
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidr)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "flask-app-${terraform.workspace}-subnet-private${count.index}-${var.azs[count.index]}",
    Env  = terraform.workspace
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "flask-app-${terraform.workspace}-igw",
    Env  = terraform.workspace
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "flask-app-${terraform.workspace}-nat-eip",
    Env  = terraform.workspace
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "flask-app-${terraform.workspace}-nat-public1-${var.azs[0]}",
    Env  = terraform.workspace
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "flask-app-${terraform.workspace}-rtb-public",
    Env  = terraform.workspace
  }
}


resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidr)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "flask-app-${terraform.workspace}-rtb-private",
    Env  = terraform.workspace
  }
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidr)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
