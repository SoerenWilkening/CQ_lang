#!/usr/bin/env python3
"""Exit-code sweep: this binary vs the frozen pre-xdu2.13 binary over the
name-matched fixtures (scratch). Prints the denominator and every mover."""
import fnmatch
import pathlib
import subprocess

W = pathlib.Path(__file__).resolve().parent.parent
NEW = W / "build/ir-pass/cq-opt"
OLD = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                   "7c7a42b7-0d81-41a3-a96f-61401a5ee1b7/scratchpad/frozen/cq-opt.preE")
PATS = ["*select*", "*condtree*", "*cond_tree*", "*classical*", "*leaf*",
        "*hybrid*", "*predmux*", "*kickback*"]
files = sorted(f for f in (W / "ir-pass/test").glob("*.ll")
               if any(fnmatch.fnmatch(f.name, p) for p in PATS))


def rc(b, f):
    return subprocess.run([str(b), "-passes=cq-lowering", "-S", str(f), "-o", "/dev/null"],
                          capture_output=True).returncode


# null control: the frozen binary against itself on the first 20 files
null = sum(rc(OLD, f) != rc(OLD, f) for f in files[:20])
movers = []
for f in files:
    a, b = rc(OLD, f), rc(NEW, f)
    if a != b:
        movers.append((f.name, a, b))
print(f"null control: {null} of {min(20, len(files))} movers")
print(f"swept {len(files)} fixtures; {len(movers)} exit-code mover(s)")
for m in movers:
    print("  MOVER", m)
