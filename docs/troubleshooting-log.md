# Troubleshooting log

## Duplicate CSR text representations (2026-11-10)

**Context and symptom:** A new mocked regression reused the crop CSR with
trailing whitespace for drying. The old validation accepted it: Terraform
reported `Failure! 15 passed, 1 failed` because the expected rejection was absent.

**Root cause:** Raw string comparison treated PEM formatting as identity.

**Resolution:** Strip PEM whitespace for duplicate comparison only. Preserve
the original public request passed to AWS. The corrected module passes all
16 plan-mode scenarios, including the added formatting regressions.

**Preventive architecture:** Keep device keys outside Terraform and verify
distinct public keys during real enrollment. Text normalization does not
prove possession, CSR signatures, or unique keys in independently signed requests.

## D08 provider and local tooling

**Context and symptom:** Sandbox registry access failed with a forbidden socket,
and copying the verified local provider failed with Access denied. Registry web
pages required JavaScript and pinned source fetches returned cache misses.

**Root cause:** Sandbox network/filesystem restrictions and documentation-rendering
limitations; not an AWS credential or infrastructure error.

**Resolution:** Initialized the pinned provider with approved Windows-user
execution, inspected its actual schema, and read pinned certificate source via
GitHub CLI. Reused the installed provider for offline module/sample tests. The
child mirror lock was platform-local and ignored; the sample commits the original
registry lock with checksums. PDF tooling was also installed/read with the user
identity after sandbox lookup/import failures; the fresh PDF extraction matched
the previously reviewed nine-page extraction.

**Prevention:** Keep tooling and raw evidence ignored, pin the sample provider,
inspect installed schemas and distinguish local mirror trust from registry signing.

## D08 root example and verification fixes

**Context and symptom:** Initial sample tests reported `Unsupported attribute`
when evaluating CSR paths. Early graph checks reported false CSR differences,
checked incomplete negative-test plans as if valid, and rejected an absolute
testing-directory argument. Unquoted dotted CLI arguments were split by PowerShell.

**Root cause:** A loop variable called path shadowed Terraform's path namespace;
Windows CSR line endings differed from Python universal-newline reads; expected
validation failures can emit partial plans; Terraform requires a relative local
test-directory argument.

**Resolution:** Renamed the variable to csr_path, normalized only CRLF for CSR
comparison, restricted full graph assertions to the five valid scenarios, and
used relative test-directory paths plus quoted/native-argv CLI arguments. Final
results: 14 child tests, two root tests and five rejection fixtures pass.

**Prevention:** Keep native plan-only tests and diagnostic assertions, require
all expected positive plan events, and validate children through consuming roots.
Direct child validation lacks its injected alias and is not fixed by adding a
provider to the reusable module or by changing state.

## D08 scanner and publication limits

**Context and symptom:** The first Trivy run could not download checks and used
embedded checks. GitHub authenticated successfully but reported push permission false.

**Resolution:** Reran Trivy with approved network access; checks downloaded and
the final scan returned exit 0 with zero failures. Publication is kept local;
no push, alternate credential, fork, remote change, or PR creation was attempted.

**Prevention:** Recheck repository permissions before publication and clearly
distinguish mocked plans/static scans from account-plan and delivery evidence.


## B08 final plan-only delivery, 2026-11-11

Context and symptom: current main advanced after the earlier audit. Baseline merges preserved the existing feature commits, resolved README/root overlaps, and retained reviewed teammate modules unchanged. Offline verification exposed validation cycles, fixture syntax/argument quoting and inherited provider-lock/cache mismatches.

Root cause and resolution: B05 overlap validation now evaluates its input directly without a local-value cycle. Fixture blocks and PowerShell arguments were corrected. Expected Terraform diagnostic labels are checked explicitly. Positive graph inventories are evaluated separately from expected validation-error plans, with all required positive runs mandatory. B08 adds topic/policy regressions. B02 bootstrap tests now cover all environments. Original failed commands remain in the delivery evidence; operational caches and the shared launcher were left unchanged.

Preventive controls: use the approved launcher in a disposable isolated context; remove AWS credentials; initialize only with `-backend=false -input=false`; retain immutable provider locks; validate child aliases through complete roots; assert exact managed resource families and zero updates/deletes. Never treat a zero-resource selection plan as connection evidence.
