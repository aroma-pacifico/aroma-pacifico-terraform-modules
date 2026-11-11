# Changelog

## Unreleased

Add the event-driven inference function pattern (box D10, B10): one SQS queue, one dead-letter queue, one Lambda function with an SQS event source mapping and one least-privilege role per function.
Add the result record contract (timestamp, confidence and source object identifier) as environment variables and an output.
Add the sample root with the four functions of Part E and plan-mode tests for the permission, retry and no-persistent-compute guarantees.
No release tag has been assigned.
