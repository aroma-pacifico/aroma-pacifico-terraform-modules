# The partition and the Region of the provider build the foundation model ARN, so no Region or
# partition is hardcoded in the module.
data "aws_partition" "current" {
  provider = aws.project
}

data "aws_region" "current" {
  provider = aws.project
}
