#S3 bucket output values
output "alb_dns_name" {
    value= module.alb.lb_dns_name
}