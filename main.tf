data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [var.ami_account_owner]
}
data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false

  #userdata
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
    #! /bin/bash
    apt-get -y update
    apt-get -y install nginx
    apt-get -y install jq

    ALB_DNS=${module.alb.lb_dns_name}
    
    sudo echo '<h1>Sample App Created by ASG with ALB - APP-1</h1>' | sudo tee /var/www/html/index.html
    sudo echo '<!DOCTYPE html> <html> <body style="background-color:rgb(250, 210, 210);"> <h1>Sample App created by ASG with ALB  - APP-1</h1> <p>Terraform Demo</p> <p>Application Version: V1</p> </body></html>' | sudo tee /var/www/html/app1/index.html

    systemctl restart nginx
    systemctl status nginx

    echo fin v1.00!

    EOF    
  }
}
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name

  azs                       = slice(data.aws_availability_zones.available.names, 0, 2)
  vpc_cidr                  = "10.0.0.0/16"
  name                      = var.prefix
  common_tags = merge({
    ManagedBy = "Terraform"
  }, var.tags)

}

#This module deploys a VPC in the specified region

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "4.0.1"

  name                   = join("-",[var.vpc_name,"${local.region}"])
  cidr                   = local.vpc_cidr
  public_subnets         = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k)]
  private_subnets        = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 10)]
  database_subnets       = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 20)]
  one_nat_gateway_per_az = true
  azs                    = local.azs
  enable_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  tags = merge(local.common_tags,{Env = "dev"})
}

module "web_sec_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "~> 4.17.2"

  name        = "web-sec-group"
  vpc_id      = module.vpc.vpc_id
  description = "Web security group"

  egress_with_cidr_blocks = [
    {
      description = "all all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  
  computed_ingress_with_source_security_group_id = [

    {
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "Allow from ALB only"
      source_security_group_id = module.alb.security_group_id

    },
    {
      from_port                = 80
      to_port                  = 80
      protocol                 = "tcp"
      description              = "Allow from ALB only"
      source_security_group_id = module.alb.security_group_id

    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 2

  tags = merge(local.common_tags,{Tier = "web"})

}

module "db_sec_group" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4.0"
  name        = "db-sec-group"
  vpc_id      = module.vpc.vpc_id
  description = "Database security group"


  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = "0.0.0.0/0"

    }
  ]

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.web_sec_group.security_group_id
    },
  ]

  tags = merge(local.common_tags,{Tier = "database"})

}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 8.0"

  name = join("-",[var.alb_name,"${local.region}"])

  load_balancer_type = "application"
  drop_invalid_header_fields = true

  vpc_id = module.vpc.vpc_id
  /* subnets = [element(module.vpc.public_subnets, 0), element(module.vpc.public_subnets, 1)] */
  subnets = module.vpc.public_subnets
  security_group_rules = {
    ingress_all_http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_all_https = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      description = "HTTPS web traffic"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress_all_icmp = {
      type        = "ingress"
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      description = "ICMP"
      cidr_blocks = ["0.0.0.0/0"]
    }
    /* egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_https_web = {
      type                     = "egress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      description              = "HTTPS web security egress traffic"
      source_security_group_id = module.web_sec_group.security_group_id
    } */
    egress_http_web = {
      type                     = "egress"
      from_port                = 0
      to_port                  = 0
      protocol                 = "-1"
      description              = "To HTTP web security egress traffic"
      source_security_group_id = module.web_sec_group.security_group_id
    }
  }
  #S3 bucket to store logs
  /* access_logs = {
    bucket = "s3_bucket_name"
  } */

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      /* conditions=[ {
      path_patterns = ["/"]
      
  }] */

  actions =[
    {
    type             = "forward"
    target_group_index = 0
  }
  ]

    }
  ]
  target_groups = [
    {
      name_prefix          = "apg-"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
      protocol_version = "HTTP1"      
    },
  ]
    tags = merge(local.common_tags,{Tier = "web"})

}

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"
  version = "6.9.0"

  # Autoscaling group
  name            = join("-",[var.asg_name,"${local.region}"])
  use_name_prefix = false
  instance_name   = "my-instance-asg"

  ignore_desired_capacity_changes = true

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  default_instance_warmup   = 60
  health_check_type         = "ELB"
  vpc_zone_identifier       = module.vpc.private_subnets

  initial_lifecycle_hooks = [
    {
      name                 = "ExampleStartupLifeCycleHook"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 60
      lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
      # This could be a rendered data resource
      notification_metadata = jsonencode({ "hello" = "world" })
    },
    {
      name                 = "ExampleTerminationLifeCycleHook"
      default_result       = "CONTINUE"
      heartbeat_timeout    = 180
      lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
      # This could be a rendered data resource
      notification_metadata = jsonencode({ "goodbye" = "world" })
    }
  ]

  instance_refresh = {
    strategy = "Rolling"
    preferences = {
      checkpoint_delay       = 600
      checkpoint_percentages = [35, 70, 100]
      instance_warmup        = 300
      min_healthy_percentage = 50
    }
    triggers = ["tag"]
  }

  # Launch template
  launch_template_name        = join("-",[var.template_name,"${local.region}"])
  launch_template_description = "Complete launch template example"
  update_default_version      = true
  ebs_optimized     = true

  image_id          = data.aws_ami.amazon_linux.id
  instance_type     = "t3.micro"
  user_data = base64encode(data.template_cloudinit_config.config.rendered)



  enable_monitoring = true

  create_iam_instance_profile = true
  iam_role_name               = "complete-${local.name}"
  iam_role_path               = "/ec2/"
  iam_role_description        = "Complete IAM role example"
  iam_role_tags = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  target_group_arns = module.alb.target_group_arns

  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
      }, {
      device_name = "/dev/sda1"
      no_device   = 1
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 20
        volume_type           = "gp2"
      }
    }
  ]

  capacity_reservation_specification = {
    capacity_reservation_preference = "open"
  }

  cpu_options = {
    core_count       = 1
    threads_per_core = 1
  }
  credit_specification = {
    cpu_credits = "standard"
  }

  # enclave_options = {
  #   enabled = true # Cannot enable hibernation and nitro enclaves on same instance nor on T3 instance type
  # }

  # hibernation_options = {
  #   configured = true # Root volume must be encrypted & not spot to enable hibernation
  # }


  # license_specifications = {
  #   license_configuration_arn = aws_licensemanager_license_configuration.test.arn
  # }

  maintenance_options = {
    auto_recovery = "default"
  }

  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
    instance_metadata_tags      = "enabled"
  }

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.web_sec_group.security_group_id]
    },
    {
      delete_on_termination = true
      description           = "eth1"
      device_index          = 1
      security_groups       = [module.web_sec_group.security_group_id]
    }
  ]

  placement = {
    availability_zone = "${local.region}a"
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { WhatAmI = "Instance" }
    },
    {
      resource_type = "volume"
      tags          = merge({ WhatAmI = "Volume" })
    }
  ]

  tags = merge(local.common_tags,{Tier = "web"})


  # Autoscaling Schedule
  schedules = {
    night = {
      min_size         = 0
      max_size         = 0
      desired_capacity = 0
      recurrence       = "0 18 * * 1-5" # Mon-Fri in the evening
      time_zone        = "America/Chicago"
    }

    morning = {
      min_size         = 0
      max_size         = 1
      desired_capacity = 1
      recurrence       = "0 7 * * 1-5" # Mon-Fri in the morning
      time_zone        = "America/Chicago"

    }

  }
  # Target scaling policy schedule based on average CPU load
  scaling_policies = {
    avg-cpu-policy-greater-than-50 = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 1200
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ASGAverageCPUUtilization"
        }
        target_value = 50.0
      }
    },
    predictive-scaling = {
      policy_type = "PredictiveScaling"
      predictive_scaling_configuration = {
        mode                         = "ForecastAndScale"
        scheduling_buffer_time       = 10
        max_capacity_breach_behavior = "IncreaseMaxCapacity"
        max_capacity_buffer          = 10
        metric_specification = {
          target_value = 32
          predefined_scaling_metric_specification = {
            predefined_metric_type = "ASGAverageCPUUtilization"
            resource_label         = "testLabel"
          }
          predefined_load_metric_specification = {
            predefined_metric_type = "ASGTotalCPUUtilization"
            resource_label         = "testLabel"
          }
        }
      }
    }
    request-count-per-target = {
      policy_type               = "TargetTrackingScaling"
      estimated_instance_warmup = 120
      target_tracking_configuration = {
        predefined_metric_specification = {
          predefined_metric_type = "ALBRequestCountPerTarget"
          resource_label         = "${module.alb.lb_arn_suffix}/${module.alb.target_group_arn_suffixes[0]}"
        }
        target_value = 800
      }
    }
  }
}

#------- Creating Aurora db  -------
module "cluster" {
  source = "terraform-aws-modules/rds/aws"
  version = "5.6.0"

  identifier                = var.db_identifier
  create_db_option_group    = false
  create_db_parameter_group = false

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group
  instance_class       = "db.t4g.large"

  allocated_storage = 20

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = "completePostgresql"
  username = "complete_postgresql"
  port     = 5432

  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.db_sec_group.security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0


    tags = merge(local.common_tags,{Tier = "database"})

}