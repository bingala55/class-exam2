provider "aws" {
  region     = "us-east-1"
}
  
#Create a VPC
resource "aws_vpc" "terraVPC" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraVPC"
  }
}

# Create subnet1
resource "aws_subnet" "terrasubnet_pub" {
  vpc_id                  = aws_vpc.terraVPC.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "terrasubnet_pub"
  }
}

# Create subnet2
resource "aws_subnet" "terrasubnet_priv" {
  vpc_id                  = aws_vpc.terraVPC.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "terrasubnet_priv"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "terra_gateway" {
  vpc_id = aws_vpc.terraVPC.id

  tags = {
    Name = "terra_gateway"
  }
}

# Create Route Table
resource "aws_route_table" "terra_routetable" {
  vpc_id = aws_vpc.terraVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terra_gateway.id
  }

  tags = {
    Name = "terra_routetable"
  }
}

# Create Routetable Association1
resource "aws_route_table_association" "association1" {
  subnet_id      = aws_subnet.terrasubnet_pub.id
  route_table_id = aws_route_table.terra_routetable.id
}

# Create Routetable Association2
resource "aws_route_table_association" "association2" {
  subnet_id      = aws_subnet.terrasubnet_priv.id
  route_table_id = aws_route_table.terra_routetable.id
}

# Create Sercurity Group
resource "aws_security_group" "terra_SG" {
  name        = "terra_SG"
  description = "terra_SG inbound traffic"
  vpc_id      = aws_vpc.terraVPC.id

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        self        = true
        cidr_blocks = ["0.0.0.0/0"]
     }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
     }


    ingress {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
     }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
     }

  tags = {
    Name = "terra_SG"
  }
}

# Create ec2 Instance
resource "aws_instance" "web" {
  ami           = "ami-000db10762d0c4c05"
  instance_type = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.terra_SG.id}"]
  subnet_id     = "${aws_subnet.terrasubnet_pub.id}"
  key_name      = "summerkey"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              set -x
              # output log of userdata to /var/log/user-data.log
              exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/conslole) 2>&1
              yum install -y httpd
              service httpd start
              chkonfig httpd on
              echo "<html><h1>Automation for the people</h2></html>" > /var/www/html/index.html
              EOF
 tags = {
    Name = "Terra" }

  lifecycle {
    create_before_destroy = true
  }
}

