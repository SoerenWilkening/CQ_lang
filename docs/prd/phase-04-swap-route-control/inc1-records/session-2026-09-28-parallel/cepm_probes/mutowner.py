#!/usr/bin/env python3
"""mutowner.py M... — for every fixture a mutant KILLED (its <M>.sub.txt vs base.txt), print
the mutant binary's exit code and FIRST error line, so a kill can be attributed to an
OWNER (e.g. M6's kills should be `specialize()`'s kMsgPredictedClassicalQuantum check).
Also counts, per mutant, how many killed fixtures decline with that check's string."""
import os
import subprocess
import sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d"
MD = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
      "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/cepm/mut")
GUARD = "lifted callee returns a quantum register where propagation predicted a classical result"


def verdicts(p):
    return dict(l.split()[::-1] for l in open(p) if l.strip())


b = verdicts(os.path.join(MD, "base.txt"))
for m in sys.argv[1:]:
    v = verdicts(os.path.join(MD, m + ".sub.txt"))
    killed = sorted(k for k in v if b.get(k) in ("PASS", "XFAIL") and v[k] != b[k])
    other = sorted(k for k in v if b.get(k) not in ("PASS", "XFAIL") and v[k] != b.get(k))
    nguard = 0
    owners = {}
    for k in killed:
        p = subprocess.run([os.path.join(MD, "cq-opt." + m), "-passes=cq-lowering", "-S",
                            os.path.join(W, "ir-pass/test", k), "-o", "/dev/null"],
                           capture_output=True, text=True)
        err = next((l.split("error:", 1)[1].strip() for l in p.stderr.splitlines() if "error:" in l), "")
        own = err.split(": ", 1)[-1] if err else f"accept rc={p.returncode}"
        owners[own] = owners.get(own, 0) + 1
        if GUARD in err:
            nguard += 1
    print(f"{m}: {len(killed)} killed; {nguard} by the specialize() check; other moves: {other}")
    for o, c in sorted(owners.items(), key=lambda x: -x[1]):
        print(f"   {c:4d}  {o}")
