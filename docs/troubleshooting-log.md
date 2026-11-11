# Troubleshooting log


## B05 final plan-only delivery, 2026-11-11

Context and symptom: current main advanced after the earlier audit. Baseline merges preserved the existing feature commits, resolved README/root overlaps, and retained reviewed teammate modules unchanged. Offline verification exposed validation cycles, fixture syntax/argument quoting and inherited provider-lock/cache mismatches.

Root cause and resolution: B05 overlap validation now evaluates its input directly without a local-value cycle. Fixture blocks and PowerShell arguments were corrected. Expected Terraform diagnostic labels are checked explicitly. Positive graph inventories are evaluated separately from expected validation-error plans, with all required positive runs mandatory. B08 adds topic/policy regressions. B02 bootstrap tests now cover all environments. Original failed commands remain in the delivery evidence; operational caches and the shared launcher were left unchanged.

Preventive controls: use the approved launcher in a disposable isolated context; remove AWS credentials; initialize only with `-backend=false -input=false`; retain immutable provider locks; validate child aliases through complete roots; assert exact managed resource families and zero updates/deletes. Never treat a zero-resource selection plan as connection evidence.
