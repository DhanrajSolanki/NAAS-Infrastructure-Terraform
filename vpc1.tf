provider "aws" {
  region = "ap-south-1"
  profile ="default"
}

variable cidr_vpc{
 description = "Creating a Range for VPC"
 default = "192.168.0.0/16"
}

variable cidr_subnet1{
 description = "Creating a Range for Subnet1 from Given VPC Range"
 default = "192.168.1.0/24"
}

variable cidr_subnet2{
 description = "Creating a Range for Subnet2 from Given VPC Range"
 default = "192.168.2.0/24"
}

//Create a Variable of ami_id of Wordpress  

variable "ami_WpID"{
 type = string
 default = "ami-000cbce3e1b899ebd"
}

//Create a Variable of ami_id of MYSQL

variable "ami_MySQLID"{
 type = string
 default = "ami-08706cb5f68222d09"
}

//Create a Variable of ami_type(Instance Type) for Instance

variable "ami_type"{
  type = string
  default = "t2.micro"
}


//CREATE A VPC USING TERRAFORM

resource "aws_vpc" "VPC_TERA" {
  cidr_block = "${var.cidr_vpc}"
  enable_dns_hostnames = true
 tags = {
   Name= "MyOwnVPC"
 }
}

//Output for VPC ID

output "my-vpc-op"{
    value= aws_vpc.VPC_TERA.id
}

// Create a Public Subnet in our VPC

resource "aws_subnet" "Public_Sub_1a" {
  vpc_id     = "${aws_vpc.VPC_TERA.id}"
  cidr_block = "${var.cidr_subnet1}"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public-1a"
  }
}

// Create a Private Subnet in our VPC

resource "aws_subnet" "Private_Sub_1b" {
  vpc_id     = "${aws_vpc.VPC_TERA.id}"
  cidr_block = "${var.cidr_subnet2}"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Private-1b"
  }
}

//Create a Internet Gateway for our VPC

resource "aws_internet_gateway" "IG_VPC" {
  vpc_id = "${aws_vpc.VPC_TERA.id}"

  tags = {
    Name = "IG-Public=Subnet"
  }
}

//Output of our Internet Gateway ID

output "IG-ID" {
   value= aws_internet_gateway.IG_VPC.id
}

// Create a Routing Table

resource "aws_route_table" "Route_TERA" {
   vpc_id = "${aws_vpc.VPC_TERA.id}"
   
   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.IG_VPC.id
   }
  
  tags = {
   Name = "Route-Tera"
   }
}

//Output of Out Route table ID

output "Route-Table" {
   value = aws_route_table.Route_TERA.id
}

//Create a Subnet Association For Our Public Subnet

resource "aws_route_table_association" "SUBNET_ASSO" {
  subnet_id      = "${aws_subnet.Public_Sub_1a.id}"
  route_table_id = "${aws_route_table.Route_TERA.id}"
}

//Assign Default Ip

resource "aws_default_subnet" "default_ip" {
  availability_zone = "ap-south-1a"

  tags = {
    Name = "AssignAutoIp"
  }
}


// Created a Security-Group For Wordpress

resource "aws_security_group" "sg_wp" {
  name        = "WP SEC"
  description = "Allow ssh httpd icmp"
  vpc_id      = "${aws_vpc.VPC_TERA.id}"

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "MySQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    Name = "WP-TERA-SEC"
  }
}


// Created a Security-Group For MYSQl

resource "aws_security_group" "sg_mysql" {
  name        = "SQL SEC"
  description = "Allow ssh httpd icmp"
  vpc_id      = "${aws_vpc.VPC_TERA.id}"

  ingress {
    description = "MYSQL SEC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["${aws_security_group.sg_wp.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// Launching Wordpress instance using ami_id of Wordpress in public subnet

resource "aws_instance" "WordInstance" {
  ami           = "${var.ami_WpID}"
  instance_type = "${var.ami_type}"
  key_name = "dev"
  vpc_security_group_ids = ["${aws_security_group.sg_wp.id}"]
  subnet_id ="${aws_subnet.Public_Sub_1a.id}"
  associate_public_ip_address = true
  tags = {
    Name = "WordPress"
  }
  depends_on = [
	aws_security_group.sg_wp
	]
}


// Launching MYSQL instance using ami_id of MYSQL in private subnet

resource "aws_instance" "MysqlInstance" {
  ami           = "${var.ami_MySQLID}"
  instance_type = "${var.ami_type}"
  key_name = "dev"
  vpc_security_group_ids = ["${aws_security_group.sg_mysql.id}"]
  subnet_id ="${aws_subnet.Private_Sub_1b.id}"
  associate_public_ip_address = true
  tags = {
    Name = "MySQL"
  }
  depends_on = [
	aws_security_group.sg_mysql
	]
}