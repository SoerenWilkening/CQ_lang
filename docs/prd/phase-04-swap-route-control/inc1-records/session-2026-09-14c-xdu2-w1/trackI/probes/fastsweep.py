#!/usr/bin/env python3
"""fastsweep.py (Track I, bd 21re) — run ONE version of free_pairing_check.py
over every stage-2 module produced by sweep_s2.sh, IN PROCESS, and write one row
per module: exit class, the rail census (mint/leak), the free-site counts, and
the SET OF FINDING CODES. Comparing two such files is the zero-regression
measurement; it is finer than comparing the tool's summary line, because a
finding whose code changed but whose counts did not would be invisible there.

    python3 fastsweep.py before out_before.txt /path/to/old/free_pairing_check.py
    python3 fastsweep.py after  out_after.txt  tools/free_pairing_check.py
    diff out_before.txt out_after.txt

`out`'s DIRECTORY is where it looks for `s2/*.s2.ll`. In process on purpose: 368
subprocess spawns cost 8 minutes and this costs 30 seconds, and a measurement
nobody re-runs is a measurement that goes stale.
"""
import glob, importlib.util, os, sys
which, out = sys.argv[1], sys.argv[2]
path = sys.argv[3]
spec = importlib.util.spec_from_file_location("fpc_" + which, path)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
rows = []
for f in sorted(glob.glob(os.path.join(os.path.dirname(out), "s2", "*.s2.ll"))):
    txt = open(f).read()
    try:
        fnd, v, s, _p, (mi, lk) = m.check_module(txt)
        viol = sum(1 for x in fnd if x.kind == m.VIOLATION)
        unpr = sum(1 for x in fnd if x.kind == m.UNPROVEN)
        codes = ",".join(sorted({x.code for x in fnd}))
        rows.append(f"{os.path.basename(f)} | OK | mint={mi} leak={lk} sites={s} ver={v} viol={viol} unpr={unpr} | {codes}")
    except m.Unclassified as e:
        rows.append(f"{os.path.basename(f)} | UNCLASSIFIED | {e.sym} |")
    except Exception as e:
        rows.append(f"{os.path.basename(f)} | {type(e).__name__} | {e} |")
open(out, "w").write("\n".join(rows) + "\n")
print(which, len(rows), "modules")
