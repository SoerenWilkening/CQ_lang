#!/usr/bin/env python3
"""Positive control for the matrix twin comparison: pair rolled row 30 (condprep)
with twin row 41 (a different program) — the runner MUST report a failure."""
import json, pathlib, shutil, subprocess
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
S = pathlib.Path(__file__).parent / "ctl"; S.mkdir(exist_ok=True)
shutil.copyfile(WT / "tests/e2e/railbank_stale_matrix.c", S / "m.c")
d = json.loads((WT / "tests/e2e/railbank_stale_matrix.c.cases.json").read_text())
d["twins"] = [{"rolled": 30, "twin": 41, "argv": [], "dropped_twin_lines": []}]
(S / "m.c.cases.json").write_text(json.dumps(d))
r = subprocess.run(["python3", str(WT / "tests/e2e/run_railbank_dynamic_matrix.py"),
                    "/usr/local/opt/llvm@19/bin/clang", str(WT / "build/ir-pass/cq-opt"),
                    str(WT / "build/ir-pass/libCQPass.so"), str(WT / "include"), str(S / "m.c"),
                    str(WT / "build/runtime/libcq_runtime.a"), str(WT / "build/runtime/libcq_templates.a")],
                   text=True, capture_output=True)
print("rc", r.returncode, r.stdout.strip(), [l for l in r.stderr.splitlines() if l.startswith("TWIN")])
