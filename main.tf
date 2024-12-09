# Provider Configuration
provider "aws" {
  region = "us-west-2" # Specifies the AWS region to use
}

# VPC and Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16" # The CIDR block for the VPC
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id                  = aws_vpc.main.id # Associates the subnet with the VPC
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index) # Creates subnets within the VPC's CIDR block
  map_public_ip_on_launch = true # Automatically assigns a public IP to instances launched in this subnet
  availability_zone       = ["us-west-2a", "us-west-2b"][count.index] # Specifies the availability zones for the subnets
}

resource "aws_subnet" "private" {
  count = 2
  vpc_id            = aws_vpc.main.id # Associates the subnet with the VPC
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, 2 + count.index) # Creates subnets within the VPC's CIDR block
  availability_zone = ["us-west-2a", "us-west-2b"][count.index] # Specifies the availability zones for the subnets
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id # Associates the internet gateway with the VPC
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id # Associates the route table with the VPC

  route {
    cidr_block = "0.0.0.0/0" # Default route for all traffic
    gateway_id = aws_internet_gateway.main.id # Routes traffic to the internet gateway
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id # Associates the route table with the public subnets
  route_table_id = aws_route_table.public.id # Specifies the route table to associate
}

# Security Groups
resource "aws_security_group" "aarif_public_sg" {
  vpc_id = aws_vpc.main.id # Associates the security group with the VPC

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows HTTP traffic from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows all outbound traffic
  }
}

resource "aws_security_group" "aarif_private_sg" {
  vpc_id = aws_vpc.main.id # Associates the security group with the VPC

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.aarif_public_sg.id] # Allows all traffic from the public security group
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allows all outbound traffic
  }
}

# EC2 Instances and ASG
resource "aws_launch_template" "aarif_public_instance" {
  name          = "aarif-public-instance-template-3" # Name of the launch template #Check
  instance_type = "t2.micro" # Instance type
  image_id      = "ami-055e3d4f0bbeb5878" # Amazon Linux 2 AMI ID
  iam_instance_profile {
    name = aws_iam_instance_profile.aarif_public_instance_profile.name # Associates the instance profile
  }
  vpc_security_group_ids = [aws_security_group.aarif_public_sg.id] # Associates the security group
}

resource "aws_autoscaling_group" "aarif_public_asg" {
  desired_capacity    = 2 # Desired number of instances
  max_size            = 3 # Maximum number of instances
  min_size            = 1 # Minimum number of instances
  vpc_zone_identifier = aws_subnet.public[*].id # Subnets for the ASG
  launch_template {
    id      = aws_launch_template.aarif_public_instance.id # Launch template ID
    version = "$Latest" # Latest version of the launch template
  }
  target_group_arns = [aws_lb_target_group.aarif_app_targets.arn] # Associates the target group
}

resource "aws_instance" "aarif_private_instance" {
  ami                    = "ami-055e3d4f0bbeb5878" # Amazon Linux 2 AMI ID
  instance_type          = "t2.micro" # Instance type
  subnet_id              = aws_subnet.private[0].id # Subnet ID
  vpc_security_group_ids = [aws_security_group.aarif_private_sg.id] # Associates the security group
}

# Load Balancers
resource "aws_lb" "aarif_application" {
  name               = "aarif-app-lb" # Name of the load balancer
  internal           = false # Indicates it's an internet-facing load balancer
  load_balancer_type = "application" # Type of load balancer
  security_groups    = [aws_security_group.aarif_public_sg.id] # Associates the security group
  subnets            = aws_subnet.public[*].id # Subnets for the load balancer
}

resource "aws_lb_target_group" "aarif_app_targets" {
  name     = "aarif-app-targets" # Name of the target group
  port     = 80 # Port for the target group
  protocol = "HTTP" # Protocol for the target group
  vpc_id   = aws_vpc.main.id # Associates the target group with the VPC
}

resource "aws_lb_listener" "aarif_app_listener" {
  load_balancer_arn = aws_lb.aarif_application.arn # Load balancer ARN
  port              = 80 # Port for the listener
  protocol          = "HTTP" # Protocol for the listener
  default_action {
    type             = "forward" # Action type
    target_group_arn = aws_lb_target_group.aarif_app_targets.arn # Target group ARN
  }
}

resource "aws_lb" "aarif_network" {
  name               = "aarif-net-lb" # Name of the load balancer
  internal           = true # Indicates it's an internal load balancer
  load_balancer_type = "network" # Type of load balancer
  subnets            = aws_subnet.private[*].id # Subnets for the load balancer
}

resource "aws_lb_target_group" "aarif_network_targets" {
  name     = "aarif-net-targets" # Name of the target group
  port     = 80 # Port for the target group
  protocol = "TCP" # Protocol for the target group
  vpc_id   = aws_vpc.main.id # Associates the target group with the VPC
}

# S3 Bucket
resource "aws_s3_bucket" "aarif-private-bucket" {
  bucket = "aarif-private-bucket" # Name of the S3 bucket
}

resource "aws_s3_bucket_ownership_controls" "aarif_private_bucket_ownership_controls" {
  bucket = aws_s3_bucket.aarif-private-bucket.id # Associates the ownership controls with the bucket
  rule {
    object_ownership = "BucketOwnerPreferred" # Sets the object ownership rule
  }
}

# S3 Bucket ACL
resource "aws_s3_bucket_acl" "aarif_private_bucket_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.aarif_private_bucket_ownership_controls] # Ensures ownership controls are created first
  bucket = aws_s3_bucket.aarif-private-bucket.id # Associates the ACL with the bucket
  acl = "private" # Applies private ACL
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.aarif-private-bucket.id # Associates versioning with the bucket
  versioning_configuration {
    status = "Enabled" # Enables versioning
  }
}

# IAM Role
resource "aws_iam_role" "aarif_public_role" {
  name               = "aarif-public-role" # Name of the IAM role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = { Service = "ec2.amazonaws.com" } # Allows EC2 to assume this role
      }
    ]
  })
}
resource "aws_iam_policy" "aarif_s3_access" {
  name        = "aarif-s3-access" # Name of the IAM policy
  description = "Full access to the S3 bucket" # Description of the policy
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["s3:*"], # Allows all S3 actions
        Effect   = "Allow", # Allows the specified actions
        Resource = [aws_s3_bucket.aarif-private-bucket.arn, "${aws_s3_bucket.aarif-private-bucket.arn}/*"] # Specifies the S3 bucket and its objects
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "aarif_attach_policy" {
  role       = aws_iam_role.aarif_public_role.name # Attaches the policy to the IAM role
  policy_arn = aws_iam_policy.aarif_s3_access.arn # Specifies the policy ARN
}

resource "aws_iam_instance_profile" "aarif_public_instance_profile" {
  name = "aarif-public-instance-profile-3" # Name of the instance profile #Check
  role = aws_iam_role.aarif_public_role.name # Associates the IAM role with the instance profile
}
