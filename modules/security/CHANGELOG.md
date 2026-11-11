# Changelog

## Unreleased

Add the security baseline (box D06, B06): eight rotated customer-managed keys with explicit key policies, a staff user pool that requires TOTP and a field user pool with passwordless codes, seven role groups, the revocation role for devices and users, and optional secure transport statements for S3 buckets.
Add the IoT topic rule role and the IoT logging role, with the outputs `iot_rule_role_arn` and `iot_logging_role_arn`, for the telemetry-ingestion module (B06a, ASM-400, ASM-401). The `telemetry` and `records` key policies admit the rule role.
Add the sample root with synthetic values and plan-mode tests for the module and the sample.
Planned tag: v0.5.0 (published by the reviewer after merge).
