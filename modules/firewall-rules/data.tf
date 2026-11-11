# AWS managed prefix list of the CloudFront origin-facing addresses (CL-PUB-03). It is read only when
# the load balancer rule is enabled, so a plan without a load balancer needs no such list.
data "aws_ec2_managed_prefix_list" "cloudfront_origin" {
  count = var.enable_cloudfront_origin_rule ? 1 : 0

  provider = aws.project

  name = "com.amazonaws.global.cloudfront.origin-facing"
}
