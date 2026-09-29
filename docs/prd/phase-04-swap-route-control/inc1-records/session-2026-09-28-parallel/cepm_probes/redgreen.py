#!/usr/bin/env python3
"""redgreen.py BIN fixture.ll... — run each fixture's RUN lines (lit syntax, `\\`
continuations joined) with %cq-opt := BIN, under bash with pipefail OFF (lit's
default), and report PASS/FAIL per fixture plus the denominator. Substitutions:
%cq-opt, %cq-pass (ignored by cq-opt), %filecheck, %s, %t. A fixture that uses a
substitution this runner does not know is reported SKIP, never PASS."""
import os
import re
import subprocess
import sys
import tempfile

FC = "/usr/local/opt/llvm@19/bin/FileCheck"
BIN = sys.argv[1]
KNOWN = ("%cq-opt", "%cq-pass", "%filecheck", "%s", "%t")
n = npass = nskip = 0
for f in sys.argv[2:]:
    n += 1
    runs, cur = [], ""
    for line in open(f):
        m = re.match(r"^;\s*RUN:\s?(.*)$", line.rstrip("\n"))
        if not m:
            continue
        part = m.group(1)
        if part.endswith("\\"):
            cur += part[:-1] + " "
            continue
        runs.append(cur + part)
        cur = ""
    tmpd = tempfile.mkdtemp(prefix="cepm_rg_")
    t = os.path.join(tmpd, "t")
    verdict = "PASS"
    for r in runs:
        for tok in re.findall(r"%[A-Za-z][A-Za-z0-9_-]*", r):
            if tok not in KNOWN:
                verdict = "SKIP(" + tok + ")"
        if verdict.startswith("SKIP"):
            break
        cmd = (r.replace("%cq-opt", BIN).replace("%cq-pass", "/dev/null")
                .replace("%filecheck", FC).replace("%s", f).replace("%t", t))
        # lit resolves `not` from the LLVM tools dir; use it explicitly.
        env = dict(os.environ, PATH="/usr/local/opt/llvm@19/bin:" + os.environ["PATH"])
        rc = subprocess.run(["bash", "-c", cmd], env=env, stdout=subprocess.DEVNULL,
                            stderr=subprocess.DEVNULL).returncode
        if rc != 0:
            verdict = "FAIL"
            break
    if verdict == "PASS":
        npass += 1
    elif verdict.startswith("SKIP"):
        nskip += 1
    print(f"{verdict:6s} {os.path.basename(f)}")
print(f"denominator: {n} fixtures, {npass} pass, {nskip} skip, {n - npass - nskip} fail")
