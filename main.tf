resource "aws_instance" "ec2_jenkins" {
  ami           = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.my_key_pair.key_name

  tags = {
    Name = "jenkins"
  }
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "my-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Create an ECS cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "jenkins-cluster"  # Replace with your desired cluster name
}

# Launch configuration for EC2 Spot instances
resource "aws_launch_configuration" "my_launch_config" {
  name_prefix   = "jenkins-launch-config"
  image_id      = "ami-0123456789abcdef0"  # Replace with your desired AMI ID
  instance_type = "t2.micro"  # EC2 instance type (free tier eligible)
  key_name      = aws_key_pair.my_key_pair.key_name
  spot_price    = "0.005"  # Set your desired Spot price
}

# Auto Scaling Group for EC2 Spot instances
resource "aws_autoscaling_group" "my_asg" {
  name                 = "jenkins-asg"
  launch_configuration = aws_launch_configuration.my_launch_config.name
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  vpc_zone_identifier  = ["subnet-079849065a0edeb2a"]  # Replace with your subnet ID
}

# Attach the ECS cluster to the ASG
resource "aws_ecs_cluster_attachment" "my_cluster_attachment" {
  cluster = aws_ecs_cluster.my_cluster.id
  instances = aws_autoscaling_group.my_asg.id
}

resource "aws_ecs_task_definition" "my_task_definition" {
  family                   = "jenkins-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]

  container_definitions = jsonencode([{
    name  = "jenkins-container"
    image = "jenkins/jenkins:latest"
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
    }]
    memory = 512
    cpu    = 256
  }])
}