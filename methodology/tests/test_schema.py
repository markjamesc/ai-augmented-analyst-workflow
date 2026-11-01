"""Validate schema/template compatibility for inactive and active scientific modules."""
import copy
import json
from pathlib import Path
import sys
from jsonschema import Draft202012Validator

root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
schema = json.loads((root / "methodology/schema.json").read_text())
design = json.loads((root / "templates/methodology/design.example.json").read_text())
Draft202012Validator.check_schema(schema)
validator = Draft202012Validator(schema)
cases = [("base example", design, True)]
for module in design["modules"]:
    x = copy.deepcopy(design)
    x["modules"][module] = {"required": True, "rationale": "Triggered", "plan": "Project plan"}
    cases.append((f"active {module}", x, True))
    x = copy.deepcopy(x)
    del x["modules"][module]["plan"]
    cases.append((f"missing plan {module}", x, False))
x = copy.deepcopy(design)
x["sensitivity"]["specifications"] = [{"id": "malformed"}]
cases.append(("malformed sensitivity", x, False))
failed = []
for name, value, expected in cases:
    actual = validator.is_valid(value)
    if actual != expected:
        failed.append(name)
    print("PASS" if actual == expected else "FAIL", name)
print(f"Schema compatibility: {len(cases)-len(failed)}/{len(cases)} checks passed")
if failed:
    raise SystemExit("Schema failures: " + ", ".join(failed))
