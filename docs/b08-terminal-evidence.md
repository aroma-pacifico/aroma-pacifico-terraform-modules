# Actual terminal verification excerpts

All resource graphs below are OFFLINE MOCKED TERRAFORM PLAN. Commands run through the approved isolated launcher.

## final-b08-graphs

```text
PASS farm_a: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS farm_b: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS dev_isolation: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS 19 native scenarios in modules\farm
PASS qa_association: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS dev_association: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS pdn_workload_association: one farm, two node roles, eight mocked creates, zero destroys/replacements
PASS 3 native scenarios in modules\farm\sample
PASS missing_ingestion: rejected (No value for required variable)
PASS missing_nodes: rejected (No value for required variable)
PASS missing_endpoint_reference: rejected (Invalid value for input variable)
PASS farm_inventory_as_identifier: rejected (Invalid value for input variable)
PASS null_farm_identifier: rejected (Required variable not set)
PASS scope: only IoT cloud identities, no hardware/network/compute, no 200-farm graph, no state files
PASS offline workload composition; B09 references are explicitly synthetic; release and runtime verification are not claimed

EXIT 0
```

## b08-crop-csr

```text
Certificate request self-signature verify OK

EXIT 0
```

## b08-drying-csr

```text
Certificate request self-signature verify OK

EXIT 0
```
