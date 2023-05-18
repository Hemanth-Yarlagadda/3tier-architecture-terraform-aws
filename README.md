## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.22 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.22 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | terraform-aws-modules/alb/aws | ~> 8.0 |
| <a name="module_asg"></a> [asg](#module\_asg) | terraform-aws-modules/autoscaling/aws | 6.9.0 |
| <a name="module_cluster"></a> [cluster](#module\_cluster) | terraform-aws-modules/rds/aws | 5.6.0 |
| <a name="module_db_sec_group"></a> [db\_sec\_group](#module\_db\_sec\_group) | terraform-aws-modules/security-group/aws | ~> 4.0 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | 4.0.1 |
| <a name="module_web_sec_group"></a> [web\_sec\_group](#module\_web\_sec\_group) | terraform-aws-modules/security-group/aws | ~> 4.17.2 |

## Resources

| Name | Type |
|------|------|
| [aws_ami.amazon_linux](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [template_cloudinit_config.config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_name"></a> [alb\_name](#input\_alb\_name) | The name of the ALB | `string` | `"3-tier-alb"` | no |
| <a name="input_ami_account_owner"></a> [ami\_account\_owner](#input\_ami\_account\_owner) | The owner account of the AMI image | `string` | `"099720109477"` | no |
| <a name="input_ami_name"></a> [ami\_name](#input\_ami\_name) | The name of the AMI | `string` | `"ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"` | no |
| <a name="input_asg_name"></a> [asg\_name](#input\_asg\_name) | The name of the Auto scaling group | `string` | `"web-tier-asg"` | no |
| <a name="input_db_identifier"></a> [db\_identifier](#input\_db\_identifier) | Name to be used for the RDS instance | `string` | `"db-postgres"` | no |
| <a name="input_engine"></a> [engine](#input\_engine) | The database engine to be used for the RDS instance | `string` | `"aurora-postgresql"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | The database engine version to be used for the RDS instance | `string` | `"11.12"` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | The instance class to be used for the RDS instance | `string` | `"db.r5.large"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix name to be added to your resources | `string` | `"3-tier-artifact"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region where the infrastructure is to be deployed. | `string` | `"us-east-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The generic tags to be used for your resources | `map(string)` | <pre>{<br>  "Terraform": "true"<br>}</pre> | no |
| <a name="input_template_name"></a> [template\_name](#input\_template\_name) | The name of the Auto scaling template | `string` | `"web-tier"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of your VPC | `string` | `"terraform-deployed-vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | S3 bucket output values |
