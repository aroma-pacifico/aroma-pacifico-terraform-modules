# Single-farm cloud identity pattern (D08)

Refs aroma-pacifico/aroma-pacifico-roadmap#28. Unreleased; integration is partial.
One invocation represents one farm with exactly two logical node identities,
`crop` and `drying`. It plans two IoT things, two CSR-based certificates, two
thing-principal attachments and two attachments to an existing ingestion policy.
These are cloud registry objects, not hardware installations. There is no
inventory of pilot farms and no per-farm VPC, subnet, VPN or compute workload.

## Contract

| Input | Type | Meaning |
|---|---|---|
| `client`, `project`, `environment` | Strings | Root governance; environment is dev, qa or pdn |
| `name_prefix` | String | Root-built governance/resource prefix, at most 21 characters; node suffixes keep names within 28 |
| `farm_id` | String | One nonblank opaque platform identifier; no unapproved UUID or inventory format is imposed |
| `nodes` | Map of objects with `csr` | Exactly crop and drying, each with a distinct public PEM CSR |
| `ingestion` | Object | Environment, endpoint hostname, existing policy name, and publish topic template |
| `additional_tags` | Map of strings, default empty | Desired non-secret metadata only; see tagging limitation |

`ingestion.topic_template` must contain exactly one `{thing_name}` placeholder
and no MQTT wildcard. The ingestion owner supplies the actual namespace and
matching policy; this module does not select a production topic scheme. The
template adapter is a module interface, not a claim that B09 exposes it today.
The ingestion environment must match this farm's environment. Hostname checks
reject URI schemes, paths and ports; they do not prove endpoint ownership,
existence, TLS policy or correct AWS account. The caller must verify those.

Public outputs are `node_names`, `certificate_arns`, `ingestion_endpoint`,
`telemetry_topics`, `store_and_forward_contract` and `desired_cost_tags`.
Full resource objects, certificate PEMs and private keys are not exported.
CSR comparison ignores PEM whitespace so reformatting the same request cannot
bypass duplicate detection. Syntax checks are not signature or public-key
verification; AWS validates real CSRs. Distinct requests are not proof that
devices generated distinct private keys; enrollment must verify that separately.
The input accepts no private key, and CSR registration avoids generating one.
The contract's message metadata labels are semantic requirements, not a new
wire-format schema. B09 retains ownership of the accepted payload and topics.

## Store-and-forward boundary

A10 requires MQTT over TLS 1.2 or later, QoS 1, original timestamp, node identity,
sequence number and values. Live readings go first on reconnect, then retained
readings oldest first; the encrypted node buffer keeps at most 24 hours and
releases on PUBACK. The outputs expose destinations and identity references for
that integration. They do not implement buffers, retry algorithms, firmware,
draining, persistence, alerts, or a guaranteed delivery/latency outcome.

## Architecture and limitations

The private architecture source is ADR-003's device-identity boundary, A10
sections 4.1 to 4.4, A09 section 6, A07 section 5, and A19's D08 box mapping.
Farms publish to the public regional IoT endpoint without crossing a collection
center or VPC subnet. B04 therefore does not block this identity module's mocked
plan; environment-wide composition remains dependent on that story and the
root foundations. B09 owns ingestion policy, endpoint and namespace contracts.
No ingestion service, policy document, role, table or queue is created here.

No location/department input is needed by the approved identity boundary.
Farm membership/location remains in the platform registry. Real identifiers,
coordinates and endpoints must not be added to this public repository.

AWS provider 6.0.0 exposes no tag argument on these four resource types.
`FarmId`, `Environment` and `NodeRole` are registry attributes, not AWS tags.
`desired_cost_tags` exposes intent without falsely claiming tags were applied.
PD-071 remains unresolved and requires the architecture owner's decision;
no new IoT group or resource is invented to work around that limitation.

The child has no provider/backend configuration. Consumers supply `aws.project`.
Use a real reviewed SemVer release before shared-environment composition;
there are no published module tags yet. The local `sample/` is for offline
verification under PC-IAC-015/026 only, never deployment.

## Layout

```text
farm/
|-- .gitignore
|-- CHANGELOG.md
|-- README.md
|-- data.tf
|-- locals.tf
|-- main.tf
|-- outputs.tf
|-- providers.tf
|-- variables.tf
|-- versions.tf
|-- sample/ (offline root, lockfile, fixtures and association tests)
`-- tests/
    |-- farm_unit_test.tftest.hcl
    `-- fixtures/ (crop.csr, drying.csr; synthetic public requests only)
```

## Verification

The child declares `aws.project` without configuring it. Validate through the
sample root, which supplies that alias; a direct child-as-root `validate`
reports a missing provider configuration. That diagnostic is not evidence of
existing state. Native tests inject mocks and run no AWS calls.

After initializing both the child and sample with the supported provider,
run `python scripts/verify-farm.py` from the repository root. It executes 16
child scenarios, two root association scenarios and five isolated rejection
fixtures. It inspects five valid JSON plan events for exactly eight identity
creates, one farm and two node roles, with no destroys or replacements. These
are mocked plan results, not account-plan or delivery evidence.
