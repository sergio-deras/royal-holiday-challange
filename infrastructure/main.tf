# ANSWER TO QUESTION 3
### How would you validate the terraform or CDK code for the above workload (question 2), to avoid errors during the apply phase?
# To validate: terraform validate
# To prevent errors: Use terraform plan -out=<resulting_plan>
# To reduce even more the possibility of errors: Use a different AWS account (different credentials) as a pre-deploy stage, deploy the changes
#   there in order to validate the results before promoting them into the main stage (prod)   
###

# ANSWER TO QUESTION 4
### Explain how you would monitor the above workload (question 2).What metrics (Golden Signals) do you consider most important to monitor?
# The most important signals to monitor for this application would be traffic and errors, given that it is a self container application, the latency 
# should not vary too much, we can even cached it or even mock it (but just because it is an example). The number of errors is a metric that should be
# observed as it might indicate a problem with the containers or the network. While traffic might gives us the hint of a DDoS attack. 
### Develop a basic idea using AWS CloudWatch Metrics or another monitoring product you are familiar with.
# We could check the ALB access logs with a data analysis tool/service to review, like AWS Athena. 
###

# ANSWER TO QUESTION 4
### If you have the need to implement a rollback for the previous deployment service, explain how you can build it.
# First, I would implement a Canary or Blue/Green deployment strategy, so we could reduce the downtime or at least the percentage of tasks running the 
#   version that we want to rollback.
# And given that we cannot use the previous revision and it seems like we want to use GitFLow for this, we could opt to use the 'git revert' command to
#   go back to the previous (or desired commit) while maintaing the history or commits and then push to master and deploy the previous code.      


provider "aws" {
  region = "us-east-1"  
}

# Data source to retrieve the availability zones in the selected region
data "aws_availability_zones" "available" {
  state = "available"
}

# Define the CIDR blocks for each subnet in different AZs
locals {
  subnet_cidr_blocks = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

# Create a VPC
resource "aws_vpc" "challange_vpc" {
  cidr_block = "10.0.0.0/16" 
}

# Create subnets in different Availability Zones (AZs)
resource "aws_subnet" "challange_subnets" {
  count             = length(local.subnet_cidr_blocks)
  cidr_block        = local.subnet_cidr_blocks[count.index]
  vpc_id            = aws_vpc.challange_vpc.id
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

# Create a security group allowing inbound traffic on port 80
resource "aws_security_group" "alb_service_sg" {
  name_prefix = "allow-port-80-"
  vpc_id      = aws_vpc.challange_vpc.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }
}

# Create a security group allowing inbound traffic on port 80
resource "aws_security_group" "ecs_service_sg" {
  name_prefix = "allow-alb"
  vpc_id      = aws_vpc.challange_vpc.id
  
  ingress {
    security_groups = [aws_security_group.alb_service_sg.id]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
}

# Create an ECR private repository
resource "aws_ecr_repository" "challange_ecr_repository" {
  name = "challange-ecr-repo"  
}

resource "aws_ecs_cluster" "challange_ecs_cluster" {
  name = "challange-ecs-cluster"  
}

# Task definition with a single container
resource "aws_ecs_task_definition" "challange_task_definition" {
  family                   = "challange-task-family"
  container_definitions    = jsonencode([{
    name  = "challange-container"
    image = aws_ecr_repository.challange_ecr_repository.repository_url  
    port_mappings = {
      container_port = 80
      host_port      = 80
    }
  }])
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"  # You can adjust these resource values based on your needs
  memory                   = "512"
}

# Create an ECS service with Fargate launch type
resource "aws_ecs_service" "challange_ecs_service" {
  name            = "challange-ecs-service"
  cluster         = aws_ecs_cluster.challange_ecs_cluster.id
  task_definition = aws_ecs_task_definition.challange_task_definition.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  # Reference the security group for the ECS service
  network_configuration {
    subnets          = [aws_subnet.challange_subnets[*].id]  # Replace with the subnet ID where you want to deploy the service
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = true  # Set to false if you want to use a private IP address
  }
}


# Create an Application Load Balancer (ALB) listening on port 80
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  load_balancer_type = "application"
  
  subnets            = [aws_subnet.challange_subnets[*].id] 
  security_groups    = [aws_security_group.ecs_alb_sg.id]
}

# Create an ALB listener on port 80
resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_alb_target_group.arn
  }
}

# Create an ALB target group to route traffic to the ECS service
resource "aws_lb_target_group" "ecs_alb_target_group" {
  name        = "ecs-alb-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.challange_vpc.id
  target_type = "ip"
}

# Create a target group attachment to associate the ECS service with the ALB target group
resource "aws_lb_target_group_attachment" "ecs_alb_target_group_attachment" {
  target_group_arn = aws_lb_target_group.ecs_alb_target_group.arn
  target_id        = aws_ecs_service.challange_ecs_service.id
  port             = 80
}
