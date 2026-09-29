#!/usr/bin/env python3
"""Round 2 (bd z0re): both Rule-13 reviewers' probe batteries, re-run WITHOUT writing into
their directories (their REVIEW dirs are committed untouched).

  review_battery.py ORACLE SUBJ_R1 SUBJ_R2

For every probe in review_r1A_z0re/probes/src and review_r1B_z0re/probes/src (a `.c` with an
optional `<b>.lib.c`, compiled plain and llvm-linked; or a hand `.ll`):
  1. VERDICT on the oracle, the round-1 subject (the binary the reviewers examined) and the
     round-2 subject: (exit, first `error:` line).  BEFORE = round 1, AFTER = round 2.
  2. For every probe the round-2 subject ACCEPTS: STRICT stage 2b, link, run at two argument
     vectors, and the trace is compared with the ROUND-1 subject's (same program, two binaries).
  3. The TWIN pairs the reviewers named, by file name: r1A `<b>C`/`<b>T`; r1B `<b>`/`<b>_unr`,
     `<b>`/`<b>_twin`, `k<n>C`/`k<n>T`, and `<b>`/`<b>_lit` (the literal side on the ORACLE, the
     runtime side run with argv[1] = 6, the literal).
Denominators are printed; ≤4 workers.
"""
import glob
import os
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82"
L = "/usr/local/opt/llvm@19/bin"
R = W + "/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel"
ORA, S1, S2 = sys.argv[1], sys.argv[2], sys.argv[3]
BINS = {"ORA": ORA, "R1": S1, "R2": S2}
T = tempfile.mkdtemp(prefix="z0re_rb_")
RT = W + "/build/runtime/libcq_runtime.a"
TPL = W + "/build/runtime/libcq_templates.a"


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, **kw)


def stage1(src):
    key = re.sub(r"[^A-Za-z0-9]", "_", os.path.relpath(src, R))
    if src.endswith(".ll"):
        return key, src
    cq = os.path.join(T, key + ".cq.ll")
    if sh([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
           src, "-o", cq]).returncode:
        return key, None
    lib = src[:-2] + ".lib.c"
    if os.path.exists(lib):
        ll = os.path.join(T, key + ".lib.ll")
        comb = os.path.join(T, key + ".s1.ll")
        if sh([L + "/clang", "-I" + W + "/include", "-O1", "-emit-llvm", "-S", lib, "-o", ll]).returncode:
            return key, None
        if sh([L + "/llvm-link", "-S", cq, ll, "-o", comb]).returncode:
            return key, None
        return key, comb
    return key, cq


def lower(tag, key, s1):
    out = os.path.join(T, f"{key}.{tag}.s2.ll")
    p = sh([BINS[tag], "-passes=cq-lowering", "-S", s1, "-o", out])
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    first = err[0].split("lowering:", 1)[-1].strip() if err else ""
    return p.returncode, first, out


def trace(s2, args, key, tag):
    exe = os.path.join(T, f"{key}.{tag}.exe")
    if sh([L + "/clang", s2, TPL, RT, "-o", exe]).returncode:
        return None
    return sh([exe] + args).stdout


def two_b(s2):
    p = sh(["python3", W + "/tools/free_pairing_check.py", s2])
    m = re.search(r"(\d+) violation\(s\), (\d+) unproven", p.stdout.decode() + p.stderr.decode())
    return (p.returncode, m.group(0) if m else "?")


srcs = []
for d in (R + "/review_r1A_z0re/probes/src", R + "/review_r1B_z0re/probes/src"):
    for f in sorted(glob.glob(d + "/*.c")) + sorted(glob.glob(d + "/*.ll")):
        if f.endswith(".lib.c"):
            continue
        srcs.append(f)


def one(src):
    key, s1 = stage1(src)
    if not s1:
        return src, key, None
    res = {tag: lower(tag, key, s1) for tag in BINS}
    info = {"v": {t: (r[0], r[1]) for t, r in res.items()}, "s2": {t: r[2] for t, r in res.items()}}
    if res["R2"][0] == 0:
        info["2b"] = two_b(res["R2"][2])
        same = True
        for args in (["5", "7"], ["-3", "11"]):
            t2 = trace(res["R2"][2], args, key, "R2")
            t1 = trace(res["R1"][2], args, key, "R1") if res["R1"][0] == 0 else None
            if t1 is None or t2 is None or t1 != t2:
                same = False
        info["r1r2trace"] = same
    return src, key, info


with ThreadPoolExecutor(4) as ex:
    rows = list(ex.map(one, srcs))

short = lambda s: os.path.relpath(s, R)
print(f"denominator: {len(rows)} probe sources ({sum(1 for r in rows if r[2])} built at stage 1)")
moved = 0
for src, key, info in rows:
    if not info:
        print(f"STAGE1-FAIL\t{short(src)}")
        continue
    v = info["v"]
    fmt = lambda t: "ACCEPT" if v[t][0] == 0 else f"DECLINE[{v[t][1][:70]}]"
    mv = "" if v["R1"] == v["R2"] else "  <== R1/R2 MOVER"
    moved += v["R1"] != v["R2"]
    extra = ""
    if "2b" in info:
        extra = f"  2b={info['2b'][1]}  R1==R2 trace={'yes' if info['r1r2trace'] else 'NO'}"
    print(f"{short(src)}\tORA={fmt('ORA')}\tR1={fmt('R1')}\tR2={fmt('R2')}{extra}{mv}")
print(f"R1 -> R2 verdict movers: {moved}")

# ---- twins
by = {os.path.basename(s)[:-2] if s.endswith(".c") else os.path.basename(s)[:-3]: (s, k, i)
      for s, k, i in rows}
pairs = []
for name in by:
    if name.endswith("C") and name[:-1] + "T" in by:
        pairs.append((name, name[:-1] + "T", "R2", "R2", [["5", "7"], ["2", "9"]]))
    for suf in ("_unr", "_twin"):
        if name + suf in by:
            pairs.append((name, name + suf, "R2", "R2", [["5", "7"], ["2", "9"]]))
    if name + "_lit" in by:
        pairs.append((name, name + "_lit", "R2", "ORA", [["6", "4"], ["6", "7"]]))
print(f"twin pairs: {len(pairs)}")
same_n = 0
for a, b, ta, tb, argvs in pairs:
    ia, ib = by[a][2], by[b][2]
    if not ia or not ib:
        print(f"{a} vs {b}: STAGE1-FAIL")
        continue
    va, vb = ia["v"][ta], ib["v"][tb]
    if va[0] != 0 or vb[0] != 0:
        tagv = "DECL-SAME" if va == vb else "VERDICT-DIFF"
        print(f"{a}({ta}) vs {b}({tb}): {tagv}  A=[{'ACCEPT' if va[0]==0 else va[1][:60]}] B=[{'ACCEPT' if vb[0]==0 else vb[1][:60]}]")
        same_n += tagv == "DECL-SAME"
        continue
    ok = True
    for args in argvs:
        x = trace(ia["s2"][ta], args, by[a][1], ta + "t")
        y = trace(ib["s2"][tb], args, by[b][1], tb + "t")
        ok = ok and x is not None and x == y
    same_n += ok
    print(f"{a}({ta}) vs {b}({tb}): {'ACC-SAME' if ok else 'ACC-DIFF'}  args={argvs}")
print(f"twin pairs twin-identical: {same_n} of {len(pairs)}")
