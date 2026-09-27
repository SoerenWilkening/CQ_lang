#!/usr/bin/env python3
"""buildcorp5.py : the round-3 corpus (brief: lit + e2e + multi-TU + the review probe dirs
ONLY). Stage-1 modules under corp5/:
  R_<dir>__<name>  every .c (with its .lib.c) and every stage-1 .ll of the five review dirs:
                   review_r1A_vsfp, review_r1B_vsfp, review_r2A_vsfp, review_r2B_vsfp (this
                   worktree's record) and review_r2A_9bhg (bd 9bhg's record, read-only in its
                   own worktree);
  E_/M_<ctest>     every run_slice.sh / run_slice_multi.sh registration in tests/e2e.
Writes corp5_lit.txt (ir-pass/test/*.ll), corp5_probe.txt, corp5_e2e.txt, corp5_multi.txt
and corp5_all.txt, and prints the counts."""
import concurrent.futures as cf
import pathlib
import re
import subprocess
from collections import Counter

V = pathlib.Path(__file__).parent
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8")
REC = W / "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16"
REC9 = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16")
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
C = V / "corp5"
C.mkdir(exist_ok=True)
CQ = [str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything"]
DIRS = [(REC, "review_r1A_vsfp"), (REC, "review_r1B_vsfp"), (REC, "review_r2A_vsfp"), (REC, "review_r3A_vsfp"), (REC, "review_r3B_vsfp"), (REC, "review_r4A_vsfp"), (REC, "review_r4B_vsfp"),
        (REC, "review_r2B_vsfp"), (REC9, "review_r2A_9bhg")]


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def build2(src, libs, tag):
    out = C / f"{tag}.s1.ll"
    parts = []
    b = run(CQ + [str(src), "-o", str(C / f"{tag}.caller.tmp.ll")])
    if b.returncode:
        return tag, "GENFAIL"
    parts.append(str(C / f"{tag}.caller.tmp.ll"))
    for i, lib in enumerate(libs):
        a = run([str(L / "clang"), f"-I{W}/include", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(lib), "-o", str(C / f"{tag}.lib{i}.tmp.ll")])
        if a.returncode:
            return tag, "GENFAIL"
        parts.append(str(C / f"{tag}.lib{i}.tmp.ll"))
    if len(parts) == 1:
        pathlib.Path(parts[0]).rename(out)
        return tag, "1tu"
    c = run([str(L / "llvm-link"), "-S"] + parts + ["-o", str(out)])
    for p in parts:
        pathlib.Path(p).unlink()
    if c.returncode:
        return tag, "LINKFAIL"
    return tag, f"{len(parts)}tu"


def pjob(job):
    src, tag = job
    if src.suffix == ".ll":
        (C / f"{tag}.s1.ll").write_text(src.read_text())
        return tag, "ll"
    lib = src.with_name(src.name[:-2] + ".lib.c")
    return build2(src, [lib] if lib.exists() else [], tag)


jobs = []
for root, d in DIRS:
    for src in sorted((root / d).rglob("*.c")):
        if src.name.endswith(".lib.c") or "/out/" in str(src):
            continue
        jobs.append((src, "R_" + d + "__" + "_".join(src.relative_to(root / d).with_suffix("").parts)))
    for ll in sorted((root / d).rglob("*.ll")):
        n = ll.name
        if ".s2" in n or "lowered" in n or "/out/" in str(ll):
            continue
        jobs.append((ll, "R_" + d + "__LL_" + "_".join(ll.relative_to(root / d).with_suffix("").parts)))

cm = (W / "tests/e2e/CMakeLists.txt").read_text()
ejobs = []
for m in re.finditer(r'add_test\(NAME (e2e-[\w-]+)\s+COMMAND bash "\$\{CMAKE_CURRENT_SOURCE_DIR\}/(run_slice(?:_multi)?\.sh)"(.*?)\)', cm, re.S):
    name, script, body = m.group(1), m.group(2), m.group(3)
    toks = re.findall(r'"([^"]*)"', body)
    srcs = [t.replace("${CMAKE_CURRENT_SOURCE_DIR}", str(W / "tests/e2e")) for t in toks if t.startswith("${CMAKE_CURRENT_SOURCE_DIR}") and t.endswith(".c")]
    if script == "run_slice.sh":
        if srcs:
            ejobs.append((name, pathlib.Path(srcs[0]), [], "E"))
    else:
        cq = None
        libs = []
        for t in toks:
            tt = t.replace("${CMAKE_CURRENT_SOURCE_DIR}", str(W / "tests/e2e"))
            if cq is None and tt.endswith(".c"):
                cq = pathlib.Path(tt)
                continue
            if cq is not None and ".c" in tt and not tt.endswith(".log"):
                libs += [pathlib.Path(x) for x in tt.split() if x.endswith(".c")]
                break
        if cq:
            ejobs.append((name, cq, libs, "M"))


def ejob(j):
    name, cq, libs, kind = j
    return build2(cq, libs, ("E_" if kind == "E" else "M_") + name)


cnt = Counter()
with cf.ThreadPoolExecutor(10) as ex:
    for tag, st in ex.map(pjob, jobs):
        cnt["R:" + st] += 1
    for tag, st in ex.map(ejob, ejobs):
        cnt[tag[:2] + st] += 1
print(len(jobs), len(ejobs), dict(cnt))


def ok(p):
    t = p.read_text(errors="ignore")
    return p.stat().st_size >= 200 and ("cq_theta" in t or "cq_measure" in t or "cq_phi" in t)


LIT = sorted(str(p) for p in (W / "ir-pass/test").glob("*.ll"))
R = [str(p) for p in sorted(C.glob("R_*.s1.ll")) if ok(p)]
E = [str(p) for p in sorted(C.glob("E_*.s1.ll")) if ok(p)]
M = [str(p) for p in sorted(C.glob("M_*.s1.ll")) if ok(p)]
for n, l in (("lit", LIT), ("probe", R), ("e2e", E), ("multi", M)):
    (V / f"corp5_{n}.txt").write_text("\n".join(l) + "\n")
(V / "corp5_all.txt").write_text("\n".join(LIT + R + E + M) + "\n")
print(f"lit {len(LIT)} probe {len(R)} e2e {len(E)} multi {len(M)} total {len(LIT) + len(R) + len(E) + len(M)}")
