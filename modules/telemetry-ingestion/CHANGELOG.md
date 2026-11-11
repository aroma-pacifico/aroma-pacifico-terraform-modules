# Changelog

## Unreleased

Add the device IoT policy: connect as the attached thing and publish only to its own topic.
Add the IoT Core data endpoint domain configuration with a TLS 1.2 minimum security policy (CL-TEL-01, CL-TEL-02).
Add the telemetry topic rule with the DynamoDB write and the threshold queue action of ASM-161, and the rule error queue.
Add the telemetry table keyed by node and original reading timestamp, encrypted with the telemetry key, with time to live and point-in-time recovery.
Add the IoT Core log group and account logging at ERROR (PD-073).
Add the ingestion output in the shape of the farm module input, the sample root and plan-mode tests on mock providers.
No release tag has been assigned.
