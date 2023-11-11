terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC 
resource "aws_vpc" "myVPC" {
    cidr_block = var.cidr_block[0]

    tags = {
      Name = "myVPC"
    }
}

# Create Public Subnet 
resource "aws_subnet" "MySubnet1" {
    vpc_id = aws_vpc.myVPC.id
    cidr_block = var.cidr_block[1]

    tags = {
        Name = "mySubnet1"
    } 
}

#Create Internet Gateway
resource "aws_internet_gateway" "INTGW" {
    vpc_id = aws_vpc.myVPC.id

    tags = {
        Name = "myInternetGW"
    }
  
}

#Create Security Group
resource "aws_security_group" "Sec_Group" {
    name = "My Security Group"
    description = "To allow inbound and outbound traffic"
    vpc_id = aws_vpc.myVPC.id

    #inbound traffic
    dynamic ingress {
        iterator = port
        for_each = var.ports
        content {
          from_port = port.value
          to_port = port.value
          protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"] 
        }   
    }

    #outbound traffic
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1" #all
        cidr_blocks = ["0.0.0.0/0"] 
    }

    tags = {
      Name = "Allow traffic"
    }
  
}

#Create route table and association
resource "aws_route_table" "myRouteTable" {
  vpc_id = aws_vpc.myVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.INTGW.id
  }

  tags = {
      Name = "myRouteTable"
    }
  
}

resource "aws_route_table_association" "myAssociation" {
  subnet_id = aws_subnet.MySubnet1.id
  route_table_id = aws_route_table.myRouteTable.id
  
}

# Create an AWS EC2 instance
resource "aws_instance" "DemoResource" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name = "EC2-keypair"
  vpc_security_group_ids = [aws_security_group.Sec_Group.id]
  subnet_id = aws_subnet.MySubnet1.id
  associate_public_ip_address = true


  tags = {
    Name = "DemoInstance"
  }
}