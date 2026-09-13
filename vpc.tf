# -----------------------------------------------------------------------------
# VPC (Virtual Private Cloud)
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  
  # Ermöglicht, dass Ressourcen AWS-interne DNS-Server nutzen können.
  enable_dns_support   = true
  # Erlaubt die Zuweisung von menschenlesbaren DNS-Namen an EC2-Instanzen.
  enable_dns_hostnames = true

  # Name Tag zur Übersichtlichkeit vergeben
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# -----------------------------------------------------------------------------
# PUBLIC SUBNETS (Für Load Balancer & NAT Gateway)
# -----------------------------------------------------------------------------
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  # /24 stellt 256 IPs bereit (wovon AWS 5 für interne Zwecke reserviert).
  cidr_block              = "10.0.1.0/24"
  # Verteilung auf Availability Zone A für physische Ausfallsicherheit.
  availability_zone       = "${var.region}a"
  
  # Zwingend für Public Subnets: Ressourcen erhalten automatisch eine externe IP.
  map_public_ip_on_launch = true 

  tags = { Name = "${var.project_name}-public-subnet-1a" }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  # Verteilung auf Availability Zone B (Redundanz).
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-public-subnet-1b" }
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS (Für EC2 Webserver, keine Public IPs)
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.region}a"
  tags = { Name = "${var.project_name}-private-subnet-1a" }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.region}b"
  tags = { Name = "${var.project_name}-private-subnet-1b" }
}

# -----------------------------------------------------------------------------
# GATEWAYS (Verbindungen nach draußen)
# -----------------------------------------------------------------------------
# Internet Gateway (IGW) - Damit das VPC ins Internet kann.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-igw" }
}

# Elastic IP (EIP) - Eine statische, öffentliche IP-Adresse für das NAT Gateway.
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-nat-eip" }
}

# NAT Gateway - Sitzt im Public Subnet und leitet Traffic aus privaten Subnetzen ins Internet weiter.
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_1.id 
  
  # Terraform soll das IGW zuerst erstellen, bevor das NAT gestartet wird.
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "${var.project_name}-nat-gateway" }
}

# -----------------------------------------------------------------------------
# ROUTE TABLES (Steuerung des Datenverkehrs)
# -----------------------------------------------------------------------------
# Public Route Table - Leitet allen unbekannten Traffic (0.0.0.0/0) zum Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Private Route Table: Leitet allen unbekannten Traffic zum NAT Gateway (NICHT ans IGW!).
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}