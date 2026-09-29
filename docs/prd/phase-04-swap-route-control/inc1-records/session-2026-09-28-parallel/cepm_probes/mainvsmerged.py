#!/usr/bin/env python3
"""mainvsmerged.py member... — for each member built by comp.sh, compare the C side's lowered
module and traces (argv `5 7`, `2 9`) between the frozen MAIN ba4fdad4 and the frozen MERGED
binary. Prints ll-same/ll-diff and trace same/DIFF per argv."""
import filecmp
import os
import subprocess
import sys

P = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
     "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/cepm/p")
for b in sys.argv[1:]:
    out = [b]
    for side in ("C", "T"):
        m = os.path.join(P, f"{b}{side}.tw.cq-opt.main_ba4fdad4")
        g = os.path.join(P, f"{b}{side}.tw.cq-opt.merged")
        if not (os.path.exists(m + ".exe") and os.path.exists(g + ".exe")):
            out.append(f"{side}: n/a (one side declines)")
            continue
        ll = "ll-same" if filecmp.cmp(m + ".ll", g + ".ll", shallow=False) else "ll-diff"
        tr = []
        for a in (["5", "7"], ["2", "9"]):
            x = subprocess.run([m + ".exe"] + a, capture_output=True).stdout
            y = subprocess.run([g + ".exe"] + a, capture_output=True).stdout
            tr.append("same" if x == y else "DIFF")
        out.append(f"{side}: {ll} traces {'/'.join(tr)}")
    print("  ".join(out))
