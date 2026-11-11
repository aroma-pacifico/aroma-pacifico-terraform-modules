"""Verify complete B05 mock plans, resource ownership and negative scenarios offline."""
from collections import Counter
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "modules/collection-center-association"
EXPECTED = {"aws_ec2_transit_gateway_vpc_attachment", "aws_customer_gateway", "aws_vpn_connection", "aws_ec2_managed_prefix_list"}

def execute(root, *arguments):
    result = subprocess.run(["terraform", f"-chdir={root}", *arguments], capture_output=True,
                            text=True, encoding="utf-8", errors="replace", timeout=180)
    if result.returncode:
        raise RuntimeError(result.stdout + result.stderr)
    return result.stdout

def verify(root, passed, extra=(), *arguments):
    events = [json.loads(line) for line in execute(root, "test", "-json", "-verbose", "-no-color", *arguments).splitlines()]
    summary = next(e["test_summary"] for e in events if e.get("type") == "test_summary")
    assert summary["passed"] == passed and summary["failed"] == 0, summary
    expected_runs = {"cross_account_graph", "same_account_graph"} if root == MODULE else ({"reviewed_b04_outputs"} if extra else {"single_association"})
    observed = set()
    for event in events:
        if event.get("type") != "test_plan":
            continue
        if event["@testrun"] not in expected_runs:
            continue
        observed.add(event["@testrun"])
        changes = event["test_plan"].get("resource_changes", [])
        changes = [c for c in changes if c["mode"] == "managed"]
        association = [c for c in changes if c["type"] in EXPECTED or c["type"] == "aws_ec2_transit_gateway_vpc_attachment_accepter"]
        count = 4 if event["@testrun"] == "same_account_graph" else 5
        expected = Counter({kind: 1 for kind in EXPECTED})
        if count == 5:
            expected["aws_ec2_transit_gateway_vpc_attachment_accepter"] = 1
        assert Counter(c["type"] for c in association) == expected, event["@testrun"]
        assert all(c["change"]["actions"] == ["create"] for c in changes), "Unexpected update/delete/replacement"
        if not extra:
            assert len(changes) == count, "Unexpected resource family"
        else:
            assert len(changes) == 168, "Reviewed B04 graph (163) plus one B05 graph (5) changed"
        vpn = next(c["change"]["after"] for c in association if c["type"] == "aws_vpn_connection")
        assert vpn["preshared_key_storage"] == "SecretsManager" and vpn["tunnel1_preshared_key"] == "" and vpn["tunnel2_preshared_key"] == ""
        prefix = next(c["change"]["after"] for c in association if c["type"] == "aws_ec2_managed_prefix_list")
        assert len(prefix["entry"]) == 1 and prefix["entry"][0]["cidr"] == vpn["local_ipv4_network_cidr"]
        print(f"OFFLINE MOCKED TERRAFORM PLAN {root.relative_to(ROOT)} / {event['@testrun']}: B05={count}, total creates={len(changes)}, updates=0, deletes=0; assertions PASS")
    assert observed == expected_runs, "Missing positive graph evidence"
    print(f"PASS native scenarios: {passed}; no state files: {not list(root.rglob('*.tfstate*'))}")

for path in MODULE.rglob("*.tftest.hcl"):
    assert set(re.findall(r"command\s*=\s*(\w+)",path.read_text())) == {"plan"}
source = (MODULE/"main.tf").read_text()
# Parse provider ownership independently of Terraform's injected mock output values.
blocks = re.findall(r'resource "([^"]+)" "([^"]+)" \{(.*?)(?=\nresource |\Z)', source, re.S)
for kind, name, body in blocks:
    owner = "project" if kind == "aws_ec2_transit_gateway_vpc_attachment" else "network"
    assert re.search(r"provider\s*=\s*aws\."+owner+r"\b",body), (kind,owner)
assert len(blocks) == 5
verify(MODULE, 8)
verify(MODULE/"sample", 1)
verify(MODULE/"sample/b04-integration", 1, ("B04",), "-var-file=terraform.tfvars")
assert not list(MODULE.rglob("*.tfstate*")), "Unexpected local state"
print("PASS ownership: workload VPC attachment; hub accepter/customer gateway/VPN/prefix list; no B07 route/firewall ownership")
