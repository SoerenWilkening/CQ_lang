#!/usr/bin/env python3
"""Red-green witness for the round-2 F-1 fixtures against the PRE-FIX binary
(cq-opt.base): each reject fixture must FAIL (base accepts or misses the
string); the legit accept must PASS on both."""
import pathlib, subprocess
SP = pathlib.Path(__file__).parent
WT = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a784cc15f4136a8dc")
FC = "/usr/local/opt/llvm@19/bin/FileCheck"
MSG = "cq loop lowering: rail record read past an in-place gate on the same rail"
for opt in (SP / "cq-opt.base", SP / "cq-opt.r2", WT / "build/ir-pass/cq-opt"):
    print("==", opt.name)
    for f in sorted((WT / "ir-pass/test").glob("railbank_stale_*inloop_*.ll")):
        r = subprocess.run([str(opt), "-passes=cq-lowering", "-S", str(f), "-o", "-"],
                           capture_output=True, text=True)
        if "_reject_" in f.name:
            ok = r.returncode != 0 and MSG in r.stderr
        else:
            tmp = SP / "ctl" / (f.name + ".out"); tmp.write_text(r.stdout)
            ok = r.returncode == 0 and all(
                subprocess.run([FC, f"--check-prefix={p}", f"--input-file={tmp}", str(f)],
                               capture_output=True).returncode == 0
                for p in (["IR", "CXOR", "CMEAS", "NOTS"] if "legit" in f.name else ["IR", "CXORC", "CMEAS", "NOTS"]))
        print(f"  {'PASS' if ok else 'FAIL'} rc={r.returncode} {f.name}")
