#!/usr/bin/env python3
"""Exit-code sweep: this binary vs the frozen pre-xdu2.13 binary over the
name-matched fixtures (scratch). Prints the denominator and every mover."""
import fnmatch
import pathlib
import subprocess

W = pathlib.Path(__file__).resolve().parent.parent
NEW = W / "build/ir-pass/cq-opt"
import sys
OLD = pathlib.Path(sys.argv[1])
PATS = ["*"]
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
