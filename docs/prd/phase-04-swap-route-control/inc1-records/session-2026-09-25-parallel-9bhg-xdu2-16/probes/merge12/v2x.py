#!/usr/bin/env python3
"""F-9C-1 table on the merged binary (cq-opt.m12). For every member of r2A_9bhg's
F-9C-1 population, build the 2-TU module (r2A's recipe) and its hand-inlined twin:
r2A's own <b>T.c where it exists, otherwise GENERATED from <b>.c by replacing each
call `h(A, K)` with `(K + 1)` and `h2(A, B, K)` with `(K + 3)` (the library bodies,
verified below), linked with the member's own lib so any other callee resolves.
Then, per binary (m12 merged; main_c113 for reference):
  verdict (exit + first error), stage 2b STRICT (rc + the CENSUS clause), trace for
  args "5 7" and "2 9" (exit code included), and whether the member's trace and
  CENSUS equal the twin's."""
import os
import pathlib
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
SRC = W / ("docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/"
           "review_r1B_vsfp/probes/src")
O = S / "merge12" / "v2x"
O.mkdir(parents=True, exist_ok=True)
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
TPL, RT = W / "build/runtime/libcq_templates.a", W / "build/runtime/libcq_runtime.a"
BINS = {"m12": S / "frozen/cq-opt.m12", "main": S / "frozen/cq-opt.main_c113"}
MEMBERS = ["v21", "v22", "v23", "v24", "v25"]


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


def replace_calls(src, name, repl):
    """Replace every CALL name(args...) (not the prototype) by repl(args)."""
    out, i = [], 0
    pat = re.compile(r"\b" + name + r"\(")
    while True:
        m = pat.search(src, i)
        if not m:
            out.append(src[i:])
            return "".join(out)
        # skip prototypes / definitions: preceded by a type keyword
        before = src[max(0, m.start() - 6):m.start()]
        if re.search(r"\bint\s*$", before):
            out.append(src[i:m.end()])
            i = m.end()
            continue
        j, depth, args, cur = m.end(), 1, [], ""
        while depth:
            ch = src[j]
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0:
                    break
            if ch == "," and depth == 1:
                args.append(cur.strip())
                cur = ""
            else:
                cur += ch
            j += 1
        args.append(cur.strip())
        out.append(src[i:m.start()])
        out.append(repl(args))
        i = j + 1


def build(name, csrc, libsrc):
    c = O / f"{name}.c"
    c.write_text(csrc)
    cq = [str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
          "-Wno-everything"]
    if libsrc is not None:
        (O / f"{name}.lib.c").write_text(libsrc)
        a = sh([str(L / "clang"), "-O1", "-emit-llvm", "-S", "-Wno-everything",
                str(O / f"{name}.lib.c"), "-o", str(O / f"{name}.lib.ll")])
        b = sh(cq + [str(c), "-o", str(O / f"{name}.caller.ll")])
        assert not a.returncode and not b.returncode, (name, a.stderr, b.stderr)
        r = sh([str(L / "llvm-link"), "-S", str(O / f"{name}.caller.ll"), str(O / f"{name}.lib.ll"),
                "-o", str(O / f"{name}.s1.ll")])
    else:
        r = sh(cq + [str(c), "-o", str(O / f"{name}.s1.ll")])
    assert not r.returncode, (name, r.stderr)


def lower(bn, name):
    s2 = O / f"{name}.{bn}.s2.ll"
    r = sh([str(BINS[bn]), "-passes=cq-lowering", "-S", str(O / f"{name}.s1.ll"), "-o", str(s2)])
    err = next((l.split("error:", 1)[1].strip() for l in r.stderr.splitlines() if "error:" in l), "")
    warn = sorted({l.split("warning:", 1)[1].strip()[:80] for l in r.stderr.splitlines()
                   if "warning:" in l})
    if r.returncode:
        return {"rc": r.returncode, "err": err, "warn": warn}
    fp = sh(["python3", str(W / "tools/free_pairing_check.py"), str(s2)])
    last = [l for l in (fp.stdout + fp.stderr).splitlines() if l.strip()][-1]
    census = last[last.find("rail mint"):] if "rail mint" in last else last
    exe = O / f"{name}.{bn}.exe"
    lk = sh([str(L / "clang"), "-Wno-everything", str(s2), str(TPL), str(RT), "-o", str(exe)])
    assert not lk.returncode, lk.stderr
    tr = []
    for args in (["5", "7"], ["2", "9"]):
        t = subprocess.run([str(exe)] + args, capture_output=True, text=True)
        tr.append(t.stdout + f"exit={t.returncode}\n")
    return {"rc": 0, "warn": warn, "fp_rc": fp.returncode, "census": census, "trace": tr}


rows = []


def one(b):
    csrc = (SRC / f"{b}.c").read_text()
    lib = (SRC / f"{b}.lib.c").read_text()
    assert "int h(int a, int k) { volatile char z = a; return k + 1; }" in lib, b
    build(b, csrc, lib)
    if (SRC / f"{b}T.c").exists():
        tsrc = (SRC / f"{b}T.c").read_text()
        tlib = (SRC / f"{b}T.lib.c").read_text() if (SRC / f"{b}T.lib.c").exists() else None
        tkind = "r2A"
    else:
        if "h2(" in lib:
            assert "int h2(int a, int b, int k) { return k + 3; }" in lib, b
        tsrc = replace_calls(csrc, "h2", lambda a: f"({a[2]} + 3)")
        tsrc = replace_calls(tsrc, "h", lambda a: f"({a[1]} + 1)")
        tlib, tkind = lib, "generated"
    build(b + "T", tsrc, tlib)
    res = {}
    for bn in BINS:
        res[bn] = (lower(bn, b), lower(bn, b + "T"))
    return b, tkind, res


with ThreadPoolExecutor(6) as ex:
    rows = list(ex.map(one, MEMBERS))


def verdict(m, t):
    if m["rc"] and t["rc"]:
        return "DECL-BOTH" + ("-SAME" if m["err"] == t["err"] else "-DIFF")
    if m["rc"] or t["rc"]:
        return f"VERDICT-DIFF(C rc={m['rc']} T rc={t['rc']})"
    same_tr = m["trace"] == t["trace"]
    same_c = m["census"] == t["census"]
    return ("TRACE-IDENT" if same_tr else "TRACE-DIFF") + ("" if same_c else " CENSUS-DIFF")


print(f"{'member':6} {'twin':9} | merged m12 vs twin | 2b(m12) | warn(m12) | main_c113 vs twin")
for b, tkind, res in rows:
    m, t = res["m12"]
    mm, mt = res["main"]
    print(f"{b:6} {tkind:9} | {verdict(m, t):28} | "
          f"{('rc=' + str(m.get('fp_rc'))) if not m['rc'] else '-':5} | {len(m['warn'])} | "
          f"{verdict(mm, mt)}")
    if not m["rc"]:
        print(f"         census m12: {m['census']}")
        print(f"         census twin: {t['census']}")
print()
for b, tkind, res in rows:
    if b in ("v22",):
        m, t = res["m12"]
        print(f"--- {b} merged trace (5 7):\n{m['trace'][0]}--- twin:\n{t['trace'][0]}")
