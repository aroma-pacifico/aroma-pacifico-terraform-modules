# AWS maps Availability Zone names to physical zones per account, so zones are resolved by ID.
data "aws_availability_zones" "available" {
  provider = aws.project

  state = "available"
}

# The endpoint service names embed the Region of the provider.
data "aws_region" "current" {
  provider = aws.project
}
