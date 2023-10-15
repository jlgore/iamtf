resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${random_pet.bucket.id}-vpc"
  }
}


resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"
  cidr_block        = var.private_subnet_cidrs[0]

  tags = {
    Name = "Private Subnet 1 ${random_pet.bucket.id}"
  }

}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1b"
  cidr_block        = var.private_subnet_cidrs[1]

  tags = {
    Name = "Private Subnet 2 ${random_pet.bucket.id}"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pubilc_subnet_cidrs[0]
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "Public Subnet ${random_pet.bucket.id}"
  }

}

resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.pubilc_subnet_cidrs[1]
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "Public Subnet 2 ${random_pet.bucket.id}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${random_pet.bucket.id}-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${random_pet.bucket.id}-rt"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.rt.id
}
