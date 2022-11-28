terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.9.0"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  region  = var.region
}

resource "aws_launch_template" "linux-web-server-lt" {
  name = "linux-web-server-lt"

  /*block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }*/

  /*capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }*/

  /*cpu_options {
    core_count       = 4
    threads_per_core = 2
  }*/

  /*credit_specification {
    cpu_credits = "standard"
  }*/

  //disable_api_stop        = true
  //disable_api_termination = true

  //ebs_optimized = true

  /*elastic_gpu_specifications {
    type = "test"
  }*/

  /*elastic_inference_accelerator {
    type = "eia1.medium"
  }*/

  /*iam_instance_profile {
    name = "test"
  }*/

  image_id = "ami-0224b73ead90b40d7"

  instance_initiated_shutdown_behavior = "terminate"

  /*instance_market_options {
    market_type = "spot"
  }*/

  instance_type = "t3a.medium"

  //kernel_id = "test"

  key_name = aws_key_pair.aws-key.id // associa keypair  

  /*license_specification {
    license_configuration_arn = "arn:aws:license-manager:eu-west-1:123456789012:license-configuration:lic-0123456789abcdef0123456789abcdef"
  }*/

  /*metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }*/

  /*monitoring {
    enabled = true
  }*/

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ "${module.security_group_linux_web_server.linux_web_server_sg_id}" ]
    subnet_id                   = module.main_vpc.web_public_subnet_id
    delete_on_termination       = true 
  }

  placement {
    availability_zone = "us-east-1a"
  }

  //ram_disk_id = "test"

  //vpc_security_group_ids = [ "${module.security_group_linux_web_server.linux_web_server_sg_id}" ]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "linux-web-server-lt"
    }
  }
  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "linux-web-server-lt"
    }
  }

  //user_data = filebase64("${path.module}/example.sh")

  // keypair
}

resource "aws_autoscaling_group" "web-server-asg" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 2
  max_size           = 4
  min_size           = 2

  health_check_grace_period = 300
  health_check_type         = "EC2"

  //vpc_zone_identifier       = [module.main_vpc.web_public_subnet_id]

  launch_template {
    id      = aws_launch_template.linux-web-server-lt.id
    version = "$Latest"
  }
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "asg_alb_attachment" {
  autoscaling_group_name = aws_autoscaling_group.web-server-asg.id
   lb_target_group_arn = aws_lb_target_group.web_server_lb_tg.arn
}

resource "aws_lb" "web_server_alb" {
  name               = "web-server-alb"
  internal           = false //internal = false -> aberto na internet.
  load_balancer_type = "application"
  security_groups    = ["${module.security_group_linux_web_server.linux_web_server_sg_id}"]
  subnets            = [module.main_vpc.web_public_subnet_id, module.main_vpc.bastion_public_subnet_id]

  //enable_deletion_protection = true

  /*access_logs {
    bucket  = aws_s3_bucket.lb_logs.bucket
    prefix  = "test-lb"
    enabled = true
  }*/

  tags = {
    Environment = "development"
  }
}
resource "aws_lb_listener" "web_server_alb_listener" {
  load_balancer_arn = aws_lb.web_server_alb.arn
  port              = "80"
  protocol          = "HTTP"
  //ssl_policy        = "ELBSecurityPolicy-2016-08"
  //certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_lb_tg.arn
  }
}

resource "aws_lb_target_group" "web_server_lb_tg" {
  name     = "web-server-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.main_vpc.main_vpc_id
}

# scale down alarm
resource "aws_autoscaling_policy" "web-server-cpu-policy-scaledown" {
  name = "web-server-cpu-policy-scaledown"
  autoscaling_group_name = aws_autoscaling_group.web-server-asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "-1"
  cooldown = "30"
  policy_type = "SimpleScaling"
}

# scale up alarm
resource "aws_autoscaling_policy" "web-server-cpu-policy-scaleup" {
  name = "web-server-cpu-policy-scaleup"
  autoscaling_group_name = aws_autoscaling_group.web-server-asg.name
  adjustment_type = "ChangeInCapacity"
  scaling_adjustment = "1"
  cooldown = "30"
  policy_type = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "web_server_high_cpu_alarm" {
  alarm_name = "web_server_high_cpu_alarm"
  alarm_description = "web_server_high_cpu_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "8"
  dimensions = {
  "AutoScalingGroupName" = "${aws_autoscaling_group.web-server-asg.name}"
  }
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.web-server-cpu-policy-scaleup.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "web_server_low_cpu_alarm" {
  alarm_name = "web_server_low_cpu_alarm"
  alarm_description = "web_server_low_cpu_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "5"
  dimensions = {
  "AutoScalingGroupName" = "${aws_autoscaling_group.web-server-asg.name}"
  }
  actions_enabled = true
  alarm_actions = ["${aws_autoscaling_policy.web-server-cpu-policy-scaledown.arn}"]
}

/*resource "aws_instance" "linux_web_server" {
  ami           = "ami-0224b73ead90b40d7" //AMI customizada Ubuntu Linux com Apache
  instance_type = "t3a.medium"
  key_name = aws_key_pair.aws-key.id // associa keypair  
  subnet_id = module.main_vpc.web_public_subnet_id
  
  vpc_security_group_ids = [ "${module.security_group_linux_web_server.linux_web_server_sg_id}" ]
  

  tags = {
    Name = "EC2 Linux Web Server",
    Change = "True",
    Desliga = "True"
  }
}*/

// keypair
resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = file(var.PUBLIC_KEY_PATH)// Path is in the variables file
}

module "main_vpc" {
  source = "./modules/vpc"
}

module "security_group_linux_web_server" {
  source = "./modules/sg-linux"
 vpc_id = "${module.main_vpc.main_vpc_id}"
}

module "iam_ec2_profile" {
  source = "./modules/IAM"  
}

