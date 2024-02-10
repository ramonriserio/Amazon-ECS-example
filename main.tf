provider "aws" {
  region = "us-east-1"
}

variable "name" {
  default = "myapp"
}

variable "image_url" {
  default = "nginx:latest"
}

resource "aws_ecs_cluster" "cluster" {
  name = "${var.name}-cluster"
}

resource "aws_iam_role" "role" {
  name = "${var.name}-role"
  assume_role_policy = jsonencode({
    "Version" : "2017-10-17",
    "Statement" : [{
      "Action" : "sts.AssumeRole",
      "Principal" : {
        "Service" : "ecs-tasks.amazonaws.com"
      },
      "Effect" : "Allow",
      "Sid" : ""
    }]
  })
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = var.name
  container_definitions    = <<EOF
    [{
        "name": "${var.name}",
        "image": "${var.image_url}",
        "essential": true,
        "portMappings": [{
            "containerPort": 80,
            "hostPort": 80
        }]
    }]
    EOF
  task_role_arn            = aws_iam_role.role.arn
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_service" "service" {
  name            = "${var.name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"
}