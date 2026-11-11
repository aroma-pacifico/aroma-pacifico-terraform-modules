# Identity of the calling account and Region, used to build ARN patterns without hardcoding them.
data "aws_caller_identity" "current" {
  provider = aws.project
}

data "aws_region" "current" {
  provider = aws.project
}

data "aws_partition" "current" {
  provider = aws.project
}
