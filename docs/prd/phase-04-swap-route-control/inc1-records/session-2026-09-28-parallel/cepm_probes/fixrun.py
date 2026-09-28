#!/usr/bin/env python3
"""fixrun.py BIN OUT fixture.ll... — redgreen.py's RUN-line emulation, 4 workers, over
many fixtures: writes one `VERDICT name` line per fixture to OUT and prints the
denominator. %cq-opt := BIN; a fixture using a substitution this runner does not know
(e.g. %debugalloc-cq-opt) is SKIP, never PASS. An `XFAIL:` fixture is reported XFAIL
(pass means unexpectedly passing is not distinguished — it is compared across binaries)."""
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

FC = "/usr/local/opt/llvm@19/bin/FileCheck"
BIN, OUT = sys.argv[1], sys.argv[2]
FILES = sys.argv[3:]
KNOWN = ("%cq-opt", "%cq-pass", "%filecheck", "%s", "%t")
ENV = dict(os.environ, PATH="/usr/local/opt/llvm@19/bin:" + os.environ["PATH"])


def one(f):
    runs, cur, xfail = [], "", False
    for line in open(f, errors="replace"):
        if re.match(r"^;\s*XFAIL:", line):
            xfail = True
        m = re.match(r"^;\s*RUN:\s?(.*)$", line.rstrip("\n"))
        if not m:
            continue
        part = m.group(1)
        if part.endswith("\\"):
            cur += part[:-1] + " "
            continue
        runs.append(cur + part)
        cur = ""
    t = os.path.join(tempfile.mkdtemp(prefix="cepm_fx_"), "t")
    for r in runs:
        for tok in re.findall(r"%[A-Za-z][A-Za-z0-9_-]*", r):
            if tok not in KNOWN:
                return f, "SKIP"
        cmd = (r.replace("%cq-opt", BIN).replace("%cq-pass", "/dev/null")
                .replace("%filecheck", FC).replace("%s", f).replace("%t", t))
        try:
            rc = subprocess.run(["bash", "-c", cmd], env=ENV, stdout=subprocess.DEVNULL,
                                stderr=subprocess.DEVNULL, timeout=600).returncode
        except subprocess.TimeoutExpired:
            return f, "TIMEOUT"
        if rc != 0:
            return f, "XFAIL" if xfail else "FAIL"
    return f, "XPASS" if xfail else "PASS"


with ThreadPoolExecutor(4) as ex:
    res = list(ex.map(one, FILES))
with open(OUT, "w") as o:
    for f, v in res:
        o.write(f"{v} {os.path.basename(f)}\n")
cnt = {}
for _, v in res:
    cnt[v] = cnt.get(v, 0) + 1
print(f"{os.path.basename(BIN)}: denominator {len(res)} fixtures: {cnt}")
