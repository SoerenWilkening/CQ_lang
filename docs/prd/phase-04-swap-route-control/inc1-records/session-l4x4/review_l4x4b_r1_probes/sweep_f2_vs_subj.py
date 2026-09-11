#!/usr/bin/env python3
import subprocess, sys, os, glob, re, json
BINS = {"f2": "/Users/sorenwilkening/Desktop/CQ_f2",
        "subj": "/Users/sorenwilkening/Desktop/CQ_l4x4"}
TEST = "/Users/sorenwilkening/Desktop/CQ_l4x4/ir-pass/test"
DIAG = re.compile(r"lowering: (.*?) under quantum control")
def run(b, f):
    p = subprocess.run([f"{b}/build/ir-pass/cq-opt", "-load-pass-plugin",
                        f"{b}/build/ir-pass/libCQPass.so", "-passes=cq-lowering",
                        "-S", f, "-o", "-"], capture_output=True, text=True)
    m = DIAG.search(p.stderr)
    return p.returncode, (m.group(1) if m else ""), p.stdout
files = sorted(glob.glob(os.path.join(TEST, "*.ll")))
rc_m = diag_m = out_m = 0
for f in files:
    r1, d1, o1 = run(BINS["f2"], f)
    r2, d2, o2 = run(BINS["subj"], f)
    n = os.path.basename(f)
    if r1 != r2:
        rc_m += 1; print(f"RCDIFF  {n}: f2 rc={r1} [{d1}] -> subj rc={r2} [{d2}]", flush=True)
    elif d1 != d2:
        diag_m += 1; print(f"DIAGDIFF {n}: [{d1}] -> [{d2}]", flush=True)
    elif o1 != o2:
        out_m += 1; print(f"OUTDIFF {n}", flush=True)
print(f"files={len(files)} RCDIFF={rc_m} DIAGDIFF={diag_m} OUTDIFF={out_m}")
