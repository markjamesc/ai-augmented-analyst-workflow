from pathlib import Path
import json
import re
import sys

path = Path("benchmark/generated_engine_output.R")
code = path.read_text(encoding="utf-8")

required = {
    "tidyverse pipe": r"%>%",
    "purrr map": r"\bmap\s*\(",
    "purrr imap": r"\bimap\s*\(",
    "nested tibble": r"nest\s*\(\s*\.by\s*=",
    "dynamic column access": r"\.data\[\[",
    "explicit metric list": r"pack_funs\s*<-\s*list\s*\(",
    "visible workbook": r"createWorkbook\s*\(",
    "insertPlot publishing": r"insertPlot\s*\(",
}

forbidden = {
    "positional data[,1]": r"data\s*\[\s*,\s*1\s*\]",
    "positional df[[1]]": r"df\s*\[\[\s*1\s*\]\]",
    "names(df)[1]": r"names\s*\(\s*df\s*\)\s*\[\s*1\s*\]",
    "map_df": r"\bmap_df\s*\(",
    "as.list(str_split": r"as\.list\s*\(\s*str_split\s*\(",
    "duplicated hard-coded setNames": r"setNames\s*\(\s*c\s*\(",
    "expand.grid": r"\bexpand\.grid\s*\(",
    "list_flatten": r"\blist_flatten\s*\(",
    "caret": r"\bcaret\b",
}

stage_functions = [
    "configure", "load", "clean", "complete", "shape",
    "measure", "expand", "assure", "publish"
]

findings = {
    "required": {},
    "forbidden": {},
    "stage_functions": {},
    "function_count": 0,
}

failed = False

for name, pattern in required.items():
    ok = re.search(pattern, code) is not None
    findings["required"][name] = ok
    failed = failed or not ok

for name, pattern in forbidden.items():
    present = re.search(pattern, code) is not None
    findings["forbidden"][name] = present
    failed = failed or present

for name in stage_functions:
    ok = re.search(rf"(?m)^{re.escape(name)}\s*<-\s*function\s*\(", code) is not None
    findings["stage_functions"][name] = ok
    failed = failed or not ok

findings["function_count"] = len(re.findall(r"(?m)^[A-Za-z][A-Za-z0-9_]*\s*<-\s*function\s*\(", code))

# Nine stage functions plus meaningful analytical helpers should exist.
if findings["function_count"] < 15:
    failed = True
    findings["modularity_note"] = "Too few named functions for this benchmark."
else:
    findings["modularity_note"] = "Named-function decomposition threshold passed."

# The generated output should preserve readable analyst code rather than
# becoming a dense OOP or metaprogramming framework.
oop_markers = ["R6Class(", "setRefClass(", "setClass("]
findings["oop_markers_present"] = [x for x in oop_markers if x in code]
if findings["oop_markers_present"]:
    failed = True

Path("benchmark/results").mkdir(parents=True, exist_ok=True)
Path("benchmark/results/style_audit.json").write_text(
    json.dumps(findings, indent=2),
    encoding="utf-8",
)

print(json.dumps(findings, indent=2))

if failed:
    print("STYLE/MODULARITY BENCHMARK: FAIL")
    sys.exit(1)

print("STYLE/MODULARITY BENCHMARK: PASS")
