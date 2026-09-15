#!/usr/bin/env python3
"""Attribute corpus movers per track BY STRING.
Rows: <rel>|<oracle verdict>|<subject verdict>; verdict = A:md5 | D:exit:sha | CLANGERR | EMPTY
Decline rows are hashed over FULL STDERR, so a D->D string change is visible."""
import subprocess, sys, os, collections, hashlib

T = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-CQ-lang/1c53d18f-fd04-48d9-8e6f-94acf28a1db2/scratchpad"
SUBJ = "/Users/sorenwilkening/Desktop/CQ_VERIFY"
ORC = "/Users/sorenwilkening/Desktop/CQ_lang"
LLVM = "/usr/local/opt/llvm@19/bin"
rows = [l.rstrip("\n").split("|") for l in open(sys.argv[1]) if l.strip()]
print(f"rows={len(rows)}")
cls = collections.Counter()
movers = []
for r in rows:
    if len(r) != 3:
        cls["MALFORMED"] += 1; continue
    rel, o, s = r
    if o in ("CLANGERR", "EMPTY"):
        cls[o] += 1; continue
    if o == s:
        cls["IDENTICAL"] += 1; continue
    od = o.startswith("D:"); sd = s.startswith("D:")
    k = ("D->A" if od and not sd else "A->D" if sd and not od
         else "D->D(string)" if od and sd else "A->A(stream)")
    cls[k] += 1
    movers.append((k, rel, o, s))
print("classes:", dict(cls))
print(f"MOVERS={len(movers)}")

# Re-run each mover to recover its FULL diagnostic text on both binaries.
def diag(root, s1):
    p = subprocess.run([f"{root}/build/ir-pass/cq-opt", "-load-pass-plugin",
                        f"{root}/build/ir-pass/libCQPass.so", "-passes=cq-lowering",
                        "-S", s1, "-o", "/dev/null"], capture_output=True, text=True)
    if p.returncode == 0:
        return "ACCEPT"
    for ln in p.stderr.splitlines():
        if "error:" in ln:
            return ln.split("):", 1)[-1].strip() if "):" in ln else ln.strip()
    return f"exit{p.returncode}"

import tempfile, shutil
out = []
for k, rel, o, s in movers:
    f = os.path.join(SUBJ, rel)
    td = tempfile.mkdtemp()
    try:
        s1 = os.path.join(td, "s1.ll")
        if f.endswith(".c"):
            q = subprocess.run([f"{LLVM}/clang", f"-I{SUBJ}/include", "-include", "CQ.h",
                                "-O1", "-g", "-emit-llvm", "-S", f, "-o", s1],
                               capture_output=True)
            if q.returncode != 0:
                out.append((k, rel, "CLANGERR", "CLANGERR")); continue
        else:
            shutil.copy(f, s1)
        out.append((k, rel, diag(ORC, s1), diag(SUBJ, s1)))
    finally:
        shutil.rmtree(td, ignore_errors=True)
for k, rel, od, sd in sorted(out):
    print(f"{k}\t{rel}\n\tORACLE : {od}\n\tSUBJECT: {sd}")
