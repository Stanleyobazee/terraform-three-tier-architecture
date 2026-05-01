# This is the main.tf file where we create the real infrastructure.

# Create VPC

resource "aws_vpc" "Three_Tier_VPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Three_Tier_VPC"
  }
}

# Create the six required subnets

# Create the two public subnets for ALB in different availability zones for high availability and fault tolerance.

resource "aws_subnet" "web_public_A" {
  vpc_id     = aws_vpc.Three_Tier_VPC.id    
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "web_public_A"
  }
}

resource "aws_subnet" "web_public_B" {
  vpc_id     = aws_vpc.Three_Tier_VPC.id    
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "web_public_B"
  }
}

# Create the two private application subnets in different availability zones for high availability and fault tolerance.

resource "aws_subnet" "app_private_A" {
  vpc_id     = aws_vpc.Three_Tier_VPC.id    
  cidr_block = "10.0.10.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "app_private_A"
  }
}

resource "aws_subnet" "app_private_B" {
  vpc_id     = aws_vpc.Three_Tier_VPC.id    
  cidr_block = "10.0.11.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "app_private_B"
  }
}

# Create the two private database subnets in different availability zones for high availability and fault tolerance.    

resource "aws_subnet" "db_private_A" {
  vpc_id     = aws_vpc.Three_Tier_VPC.id    
  cidr_block = "10.0.20.0/24"
  availability_zone = "eu-north-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "db_private_A"
  }
}

resource "aws_subnet" "db_private_B" {
  vpc_id     = aws_vpc.Three_Tier_VPC.id    
  cidr_block = "10.0.21.0/24"
  availability_zone = "eu-north-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "db_private_B"
  }
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "Three_Tier_IGW" {
  vpc_id = aws_vpc.Three_Tier_VPC.id

  tags = {
    Name = "Three_Tier_IGW"
  }
}

# Create a NAT Gateway in the public subnet to allow outbound internet access for resources in the private subnets

resource "aws_nat_gateway" "Three_Tier_NAT" {
  allocation_id = aws_eip.Three_Tier_NAT_EIP_A.id
  subnet_id     = aws_subnet.web_public_A.id

  tags = {
        Name = "Three_Tier_NAT"
    }
    depends_on = [ aws_internet_gateway.Three_Tier_IGW]
}


# Create an Elastic IP for the NAT Gateway

resource "aws_eip" "Three_Tier_NAT_EIP_A" {
  domain   = "vpc"

    tags = {
        Name = "Three_Tier_NAT_EIP_A"
    }
}


# Create a route table for the public subnets and associate it with the public subnets

resource "aws_route_table" "Three_Tier_Public_RT" {
  vpc_id = aws_vpc.Three_Tier_VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Three_Tier_IGW.id
  }

    tags = {
        Name = "Three_Tier_Public_RT"
    }
}

resource "aws_route_table_association" "web_public_A_association" {
  subnet_id      = aws_subnet.web_public_A.id
  route_table_id = aws_route_table.Three_Tier_Public_RT.id
}   

resource "aws_route_table_association" "web_public_B_association" {
  subnet_id      = aws_subnet.web_public_B.id
  route_table_id = aws_route_table.Three_Tier_Public_RT.id
}

# Create a route table for the private subnets and associate it with the private subnets    

resource "aws_route_table" "Three_Tier_Private_RT" {
  vpc_id = aws_vpc.Three_Tier_VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Three_Tier_NAT.id
  }
  tags = {
    Name = "Three_Tier_Private_RT"
  }
}       

resource "aws_route_table_association" "app_private_A_association" {
  subnet_id      = aws_subnet.app_private_A.id
  route_table_id = aws_route_table.Three_Tier_Private_RT.id
}       

resource "aws_route_table_association" "app_private_B_association" {
  subnet_id      = aws_subnet.app_private_B.id
  route_table_id = aws_route_table.Three_Tier_Private_RT.id
}

resource "aws_route_table_association" "db_private_A_association" {
  subnet_id      = aws_subnet.db_private_A.id
  route_table_id = aws_route_table.Three_Tier_Private_RT.id
}   

resource "aws_route_table_association" "db_private_B_association" {
  subnet_id      = aws_subnet.db_private_B.id
  route_table_id = aws_route_table.Three_Tier_Private_RT.id
}

# Create Security Groups for the web layer and allow inbound traffic on ports 22, 80, and 443 from anywhere and allow all outbound traffic.

resource "aws_security_group" "Three_Tier_Web_SG" {
  name        = "Three_Tier_Web_SG"
  description = "Security group for web layer"
  vpc_id      = aws_vpc.Three_Tier_VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
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


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Three_Tier_Web_SG"
  }
}

# Create Security Groups for the application layer and allow inbound traffic on ports 8080 from the web security group and allow all outbound traffic.  

resource "aws_security_group" "Three_Tier_App_SG" {
  name        = "Three_Tier_App_SG"
  description = "Security group for app layer"
  vpc_id      = aws_vpc.Three_Tier_VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.Three_Tier_Web_SG.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.Three_Tier_Web_SG.id]
  }


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [aws_security_group.Three_Tier_Web_SG.id]
  }

    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    security_groups = [aws_security_group.Three_Tier_Web_SG.id]
  }

ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.Three_Tier_Web_SG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Three_Tier_App_SG"
  }
}

# Create Security Groups for the database layer and allow inbound traffic on port 3306 from the application security group and allow all outbound traffic. 

resource "aws_security_group" "Three_Tier_DB_SG" {
  name        = "Three_Tier_DB_SG"
  description = "Security group for db layer"
  vpc_id      = aws_vpc.Three_Tier_VPC.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.Three_Tier_App_SG.id]
  }

ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.Three_Tier_App_SG.id]
  }


  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.Three_Tier_App_SG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Three_Tier_DB_SG"
  }
}   

# Create an Application Load Balancer in the public subnets and associate it with the web security group.
resource "aws_lb" "Three_Tier_ALB" {
  name               = "Three-Tier-ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.Three_Tier_Web_SG.id]
  subnets            = [aws_subnet.web_public_A.id, aws_subnet.web_public_B.id]

  tags = {
    Name = "Three_Tier_ALB"
  }
}   

# Create a target group for the application layer and associate it with the application security group.

resource "aws_lb_target_group" "Three_Tier_App_TG" {
  name     = "Three-Tier-App-TG"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.Three_Tier_VPC.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "Three_Tier_App_TG"
  }
}   

# Create a listener for the Application Load Balancer and associate it with the target group.

resource "aws_lb_listener" "Three_Tier_ALB_Listener" {
  load_balancer_arn = aws_lb.Three_Tier_ALB.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.Three_Tier_App_TG.arn
    type             = "forward"
  }
}   

# Create an Auto Scaling Group for the application layer and associate it with the target group and the application security group.

resource "aws_autoscaling_group" "Three_Tier_App_ASG" {
  name                      = "Three_Tier_App_ASG"
  max_size                  = 2
  min_size                  = 1
  desired_capacity          = 1
  vpc_zone_identifier       = [aws_subnet.app_private_A.id, aws_subnet.app_private_B.id]
  target_group_arns         = [aws_lb_target_group.Three_Tier_App_TG.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300 
  launch_template {
    id      = aws_launch_template.Three_Tier_App_LC.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "Three_Tier_App_ASG"
    propagate_at_launch = true
  }
}

# Create a launch template for the Auto Scaling Group and associate it with the application security group.

resource "aws_launch_template" "Three_Tier_App_LC" {
  name          = "Three_Tier_App_LC"
  image_id      = "ami-0a4640f53fa171eb4" # Ubuntu 22.04 LTS eu-north-1
  instance_type = "t3.micro"

  network_interfaces {
    security_groups = [aws_security_group.Three_Tier_App_SG.id]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create an RDS instance for the database layer and associate it with the database security group.

#resource "aws_db_instance" "Three_Tier_DB" {
 # identifier             = "Three_Tier_DB"
  #engine                 = "mysql"
  #engine_version         = "8.0"
  #instance_class         = "db.t3.micro"
  #db_name                = "mydb"
  #username               = var.db_username
  #password               = var.db_password
  #allocated_storage      = 20
  #storage_type           = "gp2"
  #vpc_security_group_ids = [aws_security_group.Three_Tier_DB_SG.id]
  #db_subnet_group_name   = aws_db_subnet_group.Three_Tier_DB_subnet_group.name
  #skip_final_snapshot    = true

  #tags = {
   # Name = "Three_Tier_DB"
#  }
#}   

# Create a DB subnet group for the RDS instance and associate it with the private database subnets.

#resource "aws_db_subnet_group" "Three_Tier_DB_subnet_group" {
 # name       = "three-tier-db-subnet-group"
  #subnet_ids = [aws_subnet.db_private_A.id, aws_subnet.db_private_B.id]

  #tags = {
   # Name = "Three_Tier_DB_SG"
#  }
#}



# Create a Bastion Host in the public subnet and associate it with the web security group.  
resource "aws_instance" "Three_Tier_Bastion_Instance" {
  ami           = "ami-0a4640f53fa171eb4" # Ubuntu 22.04 LTS eu-north-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.web_public_A.id
  vpc_security_group_ids = [aws_security_group.Three_Tier_Web_SG.id]
  key_name               = var.key_name

  tags = {
    Name = "Three_Tier_Bastion_Instance"
  }
}   

# Create a web server instance in the public subnet and associate it with the web security group.
resource "aws_instance" "Three_Tier_Web_Instance" {
  ami           = "ami-0a4640f53fa171eb4" # Ubuntu 22.04 LTS eu-north-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.web_public_B.id
  vpc_security_group_ids = [aws_security_group.Three_Tier_Web_SG.id]
  key_name               = var.key_name

  tags = {
    Name = "Three_Tier_Web_Instance"
  }
}

# Create an application server instance in the private subnet and associate it with the application security group.
resource "aws_instance" "Three_Tier_App_Instance" {
  ami           = "ami-0a4640f53fa171eb4" # Ubuntu 22.04 LTS eu-north-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.app_private_A.id
  vpc_security_group_ids = [aws_security_group.Three_Tier_App_SG.id]
  key_name               = var.key_name

  tags = {
    Name = "Three_Tier_App_Instance"
  }
}

# Create a database server instance in the private subnet and associate it with the database security group.
resource "aws_instance" "Three_Tier_DB_Instance" {
  ami           = "ami-0a4640f53fa171eb4" # Ubuntu 22.04 LTS eu-north-1
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.db_private_A.id
  vpc_security_group_ids = [aws_security_group.Three_Tier_DB_SG.id]
  key_name               = var.key_name

  tags = {
    Name = "Three_Tier_DB_Instance"
  }
}