# Multi-Tiered Web Application Infrastructure on AWS

## Overview
This project aims to design a secure, scalable, and highly available infrastructure for a multi-tiered web application on AWS. The solution includes creating application tiers, security groups, load balancers, an S3 bucket, IAM roles, and provisioning resources using Terraform.

## Technologies Used
- **HashiCorp Terraform**
- **GitHub**
- **AWS (Amazon Web Services)**

## Infrastructure Design
The infrastructure is designed to ensure high availability, security, and scalability. 

Design:
![design](https://github.com/Aarifmedharsha/Devops1/blob/main/Picture1.png)

The key components include:

### Application Tiers
- **Autoscaling Group (ASG)** in a public subnet with servers running in at least 2 Availability Zones (AZs).
- **Single EC2 Instance** in a private subnet.

### Security Groups
- **Public Subnet Security Group**: Allows HTTP (port 80) and SSH (port 22) traffic. Attached to the ASG.
- **Private Subnet Security Group**: Allows all traffic from the public subnet's security group. Attached to the EC2 instance.

### Load Balancers
- **Application Load Balancer (ALB)**: Directs traffic to the ASG in the public subnet.
- **Network Load Balancer (NLB)**: Directs traffic to the EC2 instance in the private subnet.

### S3 Bucket
- Not publicly accessible.
- Versioning enabled.

### IAM Role
- Full access to the S3 bucket.
- Attached to the instances in the ASG in the public subnet.

## Terraform Configuration
The Terraform configuration sets up the AWS infrastructure with the following resources:
- VPC with a CIDR block of 10.0.0.0/16.
- Two public and two private subnets across different AZs.
- Internet Gateway and Route Table for internet access in public subnets.
- Security groups for public and private subnets.
- Autoscaling Group (ASG) in public subnets with a launch template for EC2 instances.
- Single EC2 instance in a private subnet.
- Application Load Balancer (ALB) and Network Load Balancer (NLB).
- S3 bucket with private access and versioning.
- IAM role with full access to the S3 bucket.

## GitHub Repository
The Terraform code is stored in the following GitHub repository:
[Repository](https://github.com/Aarifmedharsha/Devops1/)

## AWS CodeBuild Setup
AWS CodeBuild is used to automate the provisioning of the infrastructure. The build process is defined in the `buildspec.yml` file, which includes:
- Environment setup.
- Fetching Terraform code from GitHub.
- Running Terraform commands to create and destroy resources.

## Conclusion
This project successfully provisions a multi-tiered web application environment in AWS using Terraform. The setup ensures a secure, scalable, and highly available infrastructure, with automated provisioning and management using AWS CodeBuild.

## References
- [AWS Official Documentation](https://docs.aws.amazon.com/)
- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Documentation](https://docs.github.com/en)
- [AWS CodeBuild Documentation](https://docs.aws.amazon.com/codebuild/)
