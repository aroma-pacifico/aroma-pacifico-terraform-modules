# Changelog

## Unreleased

Add the VPC and the eight-tier subnet layout of the addressing plan (box D04, part 1 of B04a).
Add the sample root with synthetic pdn values and its overlap test.
Add routing: an internet gateway for public_query only, one route table per tier and the summary route to the collection centers through a transit gateway in four tiers.
Add one network ACL per tier with the rules of the cloud firewall policy and an explicit final deny.
Add S3 and DynamoDB gateway endpoints limited to the organization, data driven interface endpoints in three tiers with HTTPS only security groups, and an optional flow log of rejected traffic.
No release tag has been assigned.
