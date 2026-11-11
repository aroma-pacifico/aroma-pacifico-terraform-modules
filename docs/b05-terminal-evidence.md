# Actual terminal verification excerpts

All resource graphs below are OFFLINE MOCKED TERRAFORM PLAN. Commands run through the approved isolated launcher.

## final-b05-graphs

```text
OFFLINE MOCKED TERRAFORM PLAN modules\collection-center-association / cross_account_graph: B05=5, total creates=5, updates=0, deletes=0; assertions PASS
OFFLINE MOCKED TERRAFORM PLAN modules\collection-center-association / same_account_graph: B05=4, total creates=4, updates=0, deletes=0; assertions PASS
PASS native scenarios: 8; no state files: True
OFFLINE MOCKED TERRAFORM PLAN modules\collection-center-association\sample / single_association: B05=5, total creates=5, updates=0, deletes=0; assertions PASS
PASS native scenarios: 1; no state files: True
OFFLINE MOCKED TERRAFORM PLAN modules\collection-center-association\sample\b04-integration / reviewed_b04_outputs: B05=5, total creates=168, updates=0, deletes=0; assertions PASS
PASS native scenarios: 1; no state files: True
PASS ownership: workload VPC attachment; hub accepter/customer gateway/VPN/prefix list; no B07 route/firewall ownership

EXIT 0
```

## final-b05-private

```text
OFFLINE MOCKED TERRAFORM PLAN private association root / cauca_connection: selected=cauca, CIDR=10.41.0.0/16, creates=5, updates=0, deletes=0; assertions PASS
OFFLINE MOCKED TERRAFORM PLAN private association root / huila_connection: selected=huila, CIDR=10.42.0.0/16, creates=5, updates=0, deletes=0; assertions PASS
OFFLINE MOCKED TERRAFORM PLAN private association root / tolima_connection: selected=tolima, CIDR=10.43.0.0/16, creates=5, updates=0, deletes=0; assertions PASS
PASS negative full-graph fixture: multi_center_list; expected error exit 1
PASS negative full-graph fixture: buenaventura; expected error exit 1
PASS negative full-graph fixture: wrong_cidr; expected error exit 1
PASS negative full-graph fixture: missing_certificate; expected error exit 1
PASS negative full-graph fixture: dev_connection; expected error exit 1
PASS negative full-graph fixture: permanent_qa; expected error exit 1
PASS: release template unchanged; isolated local source only; no remote backend or cloud calls

EXIT 0
```
