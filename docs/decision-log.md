# D08 implementation decision register

Date: 2026-11-07. Owner: JR2. Refs aroma-pacifico/aroma-pacifico-roadmap#28.
This scoped register records unresolved integration decisions for review. It
does not change the private architecture repository's canonical decision log,
accepted ADRs, or another owner's story. No governance exception is approved.

| ID | Status | Required decision or integration |
|---|---|---|
| PD-B08-001 | Open | B09 must confirm the concrete endpoint/policy/topic contract and its adapter to `ingestion`. `{thing_name}` is this module's rendering interface, not an asserted existing B09 output or a selected production namespace. |
| PD-B08-002 | Open | A08 delegates the platform FarmId format to A16, but no concrete farm-ID syntax was found in the reviewed A16 design. The module accepts a nonblank opaque identifier without inventing a UUID/department format. The platform owner must confirm enrollment constraints before real use. |
| PD-B08-003 | Open | Canonical PD-071 asks for FarmId/CostCenter tags on dedicated farm resources. AWS provider 6.0.0 exposes no tags on the four approved IoT resource types. Registry attributes and desired metadata are not AWS cost tags. SR2 must reconcile cost attribution; no extra group/resource or exception is invented. |
| PD-B08-004 | Open | Actual environment wiring needs B01/B02/B03/B04 foundations, verified B09 references, an approved account-plan evidence model, and a real module release. PC-IAC-015 permits only the offline local sample until a reviewed SemVer release exists. |
| PD-B08-005 | Resolved 2026-11-10 | Fresh authenticated repository API checks confirm push permission. Publish the assigned feature branch and a Draft PR; no fork or alternate credentials are required. |

The only implemented service selection is the IoT identity boundary already
specified by ADR-003 and A09/A10. Department/location, hardware, firmware,
new networking, application ingestion and delivery algorithms remain outside
this module. Its message metadata labels are semantic requirements, not a new
wire schema. The short `farm_key` in the sample is a synthetic naming input,
not a replacement for platform farm identifiers.
