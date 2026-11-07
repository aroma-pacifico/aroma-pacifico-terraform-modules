# Troubleshooting log

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
