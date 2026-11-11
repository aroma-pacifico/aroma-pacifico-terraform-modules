# Scoped implementation decision register


## B05 final scope clarification, 2026-11-11

The new module preserves ASM-120/121/200 ownership and routing boundaries. Test-only account/certificate identifiers are generated synthetic values. Secrets Manager PSK storage is a provider-supported defense in addition to the required certificate authentication; it introduces no plaintext key input. No production certificate or account approval is asserted.

The user confirms mocked plan-only delivery and excludes all cloud provisioning. The constitution already agrees. ADR-003's account-plan CI wording and open PD-019 still need SR1/SR2 to record the mock-only evidence decision in the canonical architecture log; ASM-051's qa account-plan restriction does not turn a pdn synthetic test into an account plan. No canonical decision or acceptance criterion is rewritten here. Independent review, release publication and acceptance remain owner actions. Operational deployment and migration are outside scope, not delivery blockers.
