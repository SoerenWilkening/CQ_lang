#!/usr/bin/env python3
"""gate_sweep.py BIN LIST OUT [MODE] — run the gate-instrumented cq-opt over every
module of LIST (CQ_GATE_TRACE=1) and tabulate, per gate: evaluations, modules
reaching it, FLIPS (live_empty=1 raw_empty=0: the gate reads "nothing" where the
pre-8e5r raw table held only DEAD members), and the modules that flipped.
Denominator printed. MODE: system (default) or an rb8-* policy (polenv)."""
import os, subprocess, sys
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import polenv
b, lst, out = sys.argv[1:4]
mode = sys.argv[4] if len(sys.argv) > 4 else "system"
files = [l.strip() for l in open(lst) if l.strip()]
print(f"denominator: {len(files)} modules, binary {b}, allocator {mode}", flush=True)


def one(f):
    env = polenv.env_for(mode)
    env["CQ_GATE_TRACE"] = "1"
    r = subprocess.run([b, "-passes=cq-lowering", "-S", f, "-o", "/dev/null"], env=env,
                       capture_output=True, text=True)
    ev = [l.split() for l in r.stderr.splitlines() if l.startswith("CQGATE ")]
    return f, r.returncode, ev


with ThreadPoolExecutor(10) as ex:
    res = list(ex.map(one, files))
evals = defaultdict(int); mods = defaultdict(set); flips = defaultdict(set); rev = defaultdict(set)
for f, rc, ev in res:
    for _, gid, le, re_ in ev:
        evals[gid] += 1; mods[gid].add(f)
        le = le.endswith("1"); ra = re_.endswith("1")
        if le and not ra:
            flips[gid].add(os.path.basename(f))
        if ra and not le:
            rev[gid].add(os.path.basename(f))
with open(out, "w") as o:
    for gid in sorted(evals):
        line = (f"{gid:36s} evals={evals[gid]:6d} modules={len(mods[gid]):5d} "
                f"FLIPS={len(flips[gid])} impossible_reverse={len(rev[gid])}")
        print(line); o.write(line + "\n")
        for m in sorted(flips[gid])[:12]:
            print("      flip:", m); o.write("      flip: " + m + "\n")
print("gates never reached:", sorted({"G1a_run_ThetaCalls", "G2_ValueArmConeOps", "G3_FreePoint_IterationLocalBlocks",
                                      "G4_Uncompute_IterationLocalBlocks", "G5a_lowerRotations_ThetaCalls",
                                      "G6_UserChainedRotations", "G7_LiftedConsumers", "G8_UntaintedMergeRails",
                                      "G9_lowerMeasures_MeasureCalls", "G10_InLoopFlattenedPreds",
                                      "G11_Dephasing_Tainted"} - set(evals)))
