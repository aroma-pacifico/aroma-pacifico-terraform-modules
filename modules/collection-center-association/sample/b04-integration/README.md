# Reviewed B04 output integration

This mock-only root invokes the unchanged reviewed `modules/network` module and feeds its `vpc_id`, `vpc_cidr_block`, and `transit_attachment_subnet_ids` outputs directly to B05. It uses B04's published synthetic sample configuration, explicit synthetic owner accounts, a nonexistent certificate reference, mocked availability zones, and deterministic VPC/transit subnet overrides. Nothing is deployed.

Run backend-disabled init, validate, and `terraform test -var-file=terraform.tfvars` through the approved launcher. The exact graph is 168 creates: 163 B04 and five B05, zero updates/deletes/replacements. B04 routes are owned by that reviewed module; B05 creates no route or firewall resource. The fixture is interface evidence, not proof that every B04 endpoint service exists or that a VPN can connect. See the [module contract](../../README.md).
