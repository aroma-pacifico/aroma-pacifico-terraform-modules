"""Verify D08 mocked resource graphs and mandatory-input rejection; never call AWS."""

from collections import Counter
from copy import deepcopy
import json
from pathlib import Path
import re
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
MODULE = ROOT / "modules" / "farm"
TYPES = {"aws_iot_thing", "aws_iot_certificate",
         "aws_iot_thing_principal_attachment", "aws_iot_policy_attachment"}


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def execute(directory, *arguments):
    result = subprocess.run(
        ["terraform", f"-chdir={directory}", *arguments], capture_output=True,
        text=True, encoding="utf-8", errors="replace", timeout=60,
    )
    events = [json.loads(line) for line in result.stdout.splitlines()]
    return result, events


def verify_graphs(directory, expected_passes, expected_farms, *arguments):
    result, events = execute(directory, "test", "-json", "-verbose", "-no-color", *arguments)
    require(result.returncode == 0, result.stdout + result.stderr)
    summary = next(event["test_summary"] for event in events if event.get("type") == "test_summary")
    require(summary["passed"] == expected_passes and summary["failed"] == 0, str(summary))
    observed = set()
    for event in events:
        if event.get("type") != "test_plan" or event["@testrun"] not in expected_farms:
            continue
        run = event["@testrun"]
        observed.add(run)
        changes = event["test_plan"]["resource_changes"]
        require(Counter(change["type"] for change in changes) == Counter({kind: 2 for kind in TYPES}), run)
        require(all(change["change"]["actions"] == ["create"] for change in changes), run)
        require(all(change["index"] in {"crop", "drying"} for change in changes), run)
        farms = {change["change"]["after"]["attributes"]["FarmId"] for change in changes
                 if change["type"] == "aws_iot_thing"}
        require(farms == {expected_farms[run]}, f"Unexpected farms: {farms}")
        for change in changes:
            if change["type"] == "aws_iot_certificate":
                after = change["change"]["after"]
                require(after["csr"].replace("\r\n", "\n") == (MODULE / "tests/fixtures" / f'{change["index"]}.csr').read_text(), run)
                require(after["private_key"] == "", "Mock unexpectedly generated private-key material")
        print(f"PASS {run}: one farm, two node roles, eight mocked creates, zero destroys/replacements")
    require(observed == set(expected_farms), "Missing valid-scenario plan events")
    print(f"PASS {expected_passes} native scenarios in {directory.relative_to(ROOT)}")


for path in MODULE.rglob("*.tftest.hcl"):
    commands = re.findall(r"command\s*=\s*(\w+)", path.read_text())
    require(commands and all(command == "plan" for command in commands), str(path))
    require('mock_provider "aws"' in path.read_text(), f"Missing mock: {path}")

verify_graphs(MODULE, 19, {"farm_a": "fixture-a", "farm_b": "fixture-b", "dev_isolation": "fixture-a"})
verify_graphs(MODULE / "sample", 3, {"qa_association": "fixture-a", "dev_association": "fixture-b", "pdn_workload_association": "fixture-a"},
              "-var-file=terraform.tfvars")

base = {
    "client": "fx", "project": "cf", "environment": "qa",
    "farm_id": "fixture-a", "name_prefix": "fx-cf-qa-iot-a",
    "nodes": {role: {"csr": (MODULE / "tests/fixtures" / f"{role}.csr").read_text()}
              for role in ["crop", "drying"]},
    "ingestion": {"environment": "qa", "endpoint": "ingestion.example.invalid",
                  "policy_name": "fixture-policy", "topic_template": "fixture/{thing_name}"},
}
cases = {}
for name, field in [("missing_ingestion", "ingestion"), ("missing_nodes", "nodes")]:
    values = deepcopy(base)
    del values[field]
    cases[name] = (values, "No value for required variable")
values = deepcopy(base)
del values["ingestion"]["endpoint"]
cases["missing_endpoint_reference"] = (values, "Invalid value for input variable")
values = deepcopy(base)
values["farm_id"] = ["fixture-a", "fixture-b"]
cases["farm_inventory_as_identifier"] = (values, "Invalid value for input variable")
values = deepcopy(base)
values["farm_id"] = None
cases["null_farm_identifier"] = (values, "Required variable not set")

scratch = MODULE / ".local"
scratch.mkdir(exist_ok=True)
with tempfile.TemporaryDirectory(prefix="d08-rejections-", dir=scratch) as temporary:
    directory = Path(temporary)
    (directory / "reject.tftest.hcl").write_text(
        'mock_provider "aws" { alias = "project" }\nrun "reject" { command = plan }\n', encoding="utf-8")
    for name, (values, diagnostic) in cases.items():
        variables = directory / "inputs.tfvars.json"
        variables.write_text(json.dumps(values), encoding="utf-8")
        result, events = execute(MODULE, "test", "-json", "-no-color",
                                 f"-test-directory={directory.relative_to(MODULE).as_posix()}", f"-var-file={variables}")
        diagnostics = [event["diagnostic"] for event in events if event.get("type") == "diagnostic"]
        require(result.returncode != 0 and any(item["severity"] == "error" and item["summary"] == diagnostic
                                               for item in diagnostics), name + ": " + result.stdout)
        print(f"PASS {name}: rejected ({diagnostic})")

require(not list(MODULE.rglob("*.tfstate*")), "Unexpected state file")
print("PASS scope: only IoT cloud identities, no hardware/network/compute, no 200-farm graph, no state files")
print("PASS offline workload composition; B09 references are explicitly synthetic; release and runtime verification are not claimed")
