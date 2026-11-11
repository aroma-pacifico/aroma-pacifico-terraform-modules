# Actual terminal verification excerpts

All resource graphs below are OFFLINE MOCKED TERRAFORM PLAN. Commands run through the approved isolated launcher.

## final-b02-policies

```text
PASS qa_backend: one environment, eight mocked creates, zero destroys/replacements
PASS dev_backend: one environment, eight mocked creates, zero destroys/replacements
PASS pdn_backend: one environment, eight mocked creates, zero destroys/replacements
PASS plan_only_domain: one environment, eight mocked creates, zero destroys/replacements
PASS policy: plan reads own state
PASS policy: plan cannot write state
PASS policy: plan writes own lock
PASS policy: plan releases own lock
PASS policy: cross-domain read denied
PASS policy: cross-domain lock denied
PASS policy: writer writes own state
PASS policy: writer cannot delete state
PASS policy: writer cannot delete a version
PASS policy: non-TLS rejected
PASS policy: unknown role rejected
PASS policy: wrong encryption rejected
PASS policy: KMS without key rejected
PASS policy: wrong CMK rejected
PASS policy: approved explicit CMK accepted
PASS policy: plan lists own prefix
PASS policy: other prefix has no grant
PASS policy: plan decrypts S3 state
PASS policy: plan encrypts S3 lock
PASS policy: direct decrypt has no grant
PASS policy: cross-domain KMS context has no grant
PASS policy: unknown KMS principal has no grant
PASS policy: auditor reads policy
PASS policy: auditor cannot change policy
PASS policy: administrator cannot decrypt by default
PASS policy: administrator changes policy
PASS policy: administrator has no deletion grant
PASS 18 native scenarios and 27 policy decisions
LIMIT: simplified policy evaluation and mocks do not establish AWS IAM/backend behavior

EXIT 0
```

## final-b02-bootstrap

```text
PASS private root: backend-disabled initialization
Success! The configuration is valid.
OFFLINE MOCKED TERRAFORM PLAN private bootstrap / bootstrap_without_backend: creates=8, updates=0, deletes=0; four domains; assertions PASS
OFFLINE MOCKED TERRAFORM PLAN private bootstrap / dev_bootstrap_without_backend: creates=8, updates=0, deletes=0; four domains; assertions PASS
OFFLINE MOCKED TERRAFORM PLAN private bootstrap / pdn_bootstrap_without_backend: creates=8, updates=0, deletes=0; four domains; assertions PASS
PASS private root: four native scenarios; three isolated environments, eight mocked creates each, zero destroys/replacements
PASS source substitution is restricted to a temporary development fixture; inactive release template unchanged
PARTIAL shared-root consumption: reviewed SemVer release and concrete owner contracts remain pending; bootstrap execution is outside plan-only scope

EXIT 0
```

## final-b02-routing

```text
test_backend_metadata_match_and_mismatch (__main__.RoutingTests.test_backend_metadata_match_and_mismatch) ... ok
test_bound_cli_renders_proven_effective_destination (__main__.RoutingTests.test_bound_cli_renders_proven_effective_destination) ... ok
test_cached_workspace_is_rejected (__main__.RoutingTests.test_cached_workspace_is_rejected) ... ok
test_changed_launcher_is_rejected (__main__.RoutingTests.test_changed_launcher_is_rejected) ... ok
test_dedicated_environment_roots_and_contexts_are_distinct (__main__.RoutingTests.test_dedicated_environment_roots_and_contexts_are_distinct) ... ok
test_environment_checkout_mismatch_is_rejected_before_git (__main__.RoutingTests.test_environment_checkout_mismatch_is_rejected_before_git) ... ok
test_mismatched_registration_is_rejected (__main__.RoutingTests.test_mismatched_registration_is_rejected) ... ok
test_missing_registration_is_rejected_without_creation (__main__.RoutingTests.test_missing_registration_is_rejected_without_creation) ... ok
test_own_checkout_and_commit_are_required (__main__.RoutingTests.test_own_checkout_and_commit_are_required) ... ok
test_real_dispatcher_with_fake_native (__main__.RoutingTests.test_real_dispatcher_with_fake_native) ... ok
test_route_inspection_writes_nothing (__main__.RoutingTests.test_route_inspection_writes_nothing) ... ok
test_same_root_cannot_gain_environment_isolation_from_tf_data_dir (__main__.RoutingTests.test_same_root_cannot_gain_environment_isolation_from_tf_data_dir) ... ok
test_validation_rejects_backend_metadata (__main__.RoutingTests.test_validation_rejects_backend_metadata) ... ok
test_wrong_executable_is_rejected (__main__.RoutingTests.test_wrong_executable_is_rejected) ... ok
test_wrong_expected_account_is_rejected (__main__.RoutingTests.test_wrong_expected_account_is_rejected) ... ok
test_wrong_workspace_and_cli_overrides_are_rejected (__main__.RoutingTests.test_wrong_workspace_and_cli_overrides_are_rejected) ... ok

----------------------------------------------------------------------
Ran 16 tests in 0.923s

OK

EXIT 0
```
