#!/usr/bin/env python3
"""Build stage-1 modules for (a) the probe corpus from every session record dir
(read-only; the r2A buildcorp recipe) and (b) the e2e corpus (every run_slice*.sh
registration in tests/e2e/CMakeLists.txt). Writes corp/*.s1.ll, probe_list.txt,
e2e_list.txt, multi_list.txt."""
import concurrent.futures as cf
import pathlib
import re
import subprocess
from collections import Counter

V = pathlib.Path(__file__).parent
R = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8")
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
C = V / "corp"
C.mkdir(exist_ok=True)
dirs = ["review_r1A_9bhg", "review_r1B_9bhg", "review_r2A_9bhg", "review_r2B_9bhg", "d88e_probes",
        "review_r1A_d88e", "review_r1B_d88e", "review_r1A_xdu2_16", "review_r1B_xdu2_16",
        "track_8e5r_probes", "xdu2_16_probes", "probes", "review_r2_delta_8e5r",
        "review_r1A_8e5r", "review_r1B_8e5r", "review_r3_8e5r"]


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


CQ = [str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything"]


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
for d in dirs:
    if not (R / d).exists():
        continue
    for src in sorted((R / d).rglob("*.c")):
        if src.name.endswith(".lib.c"):
            continue
        tag = "P_" + d + "__" + "_".join(src.relative_to(R / d).with_suffix("").parts)
        jobs.append((src, tag))
    for ll in sorted((R / d).rglob("*.ll")):
        if ".s2" in ll.name or "out" in ll.name:
            continue
        tag = "P_" + d + "__LL_" + "_".join(ll.relative_to(R / d).with_suffix("").parts)
        jobs.append((ll, tag))

# bd vsfp round 2: this worktree's own review/probe corpora + the r1B working set
R2 = W / "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16"
EXTRA = [(R2, "review_r1A_vsfp"), (R2, "review_r1B_vsfp"), (R2, "vsfp_probes"),
         (V.parent, "r1Bv"), (V, "fx"), (V, "r2src")]
for root, d in EXTRA:
    if not (root / d).exists():
        continue
    for src in sorted((root / d).rglob("*.c")):
        if src.name.endswith(".lib.c") or "/out/" in str(src):
            continue
        tag = "Q_" + d + "__" + "_".join(src.relative_to(root / d).with_suffix("").parts)
        jobs.append((src, tag))

# e2e registrations
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
        # CQSRC is the first .c, LIBSRCS the space-separated string token after it
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
            if cq is not None and tt == "":
                break
        if cq:
            ejobs.append((name, cq, libs, "M"))


def ejob(j):
    name, cq, libs, kind = j
    tag = ("E_" if kind == "E" else "M_") + name
    return build2(cq, libs, tag)


cnt = Counter()
with cf.ThreadPoolExecutor(10) as ex:
    for tag, st in ex.map(pjob, jobs):
        cnt["P:" + st] += 1
    for tag, st in ex.map(ejob, ejobs):
        cnt[tag[:2] + st] += 1
print(len(jobs), len(ejobs), dict(cnt))


def ok(p):
    t = p.read_text(errors="ignore")
    return p.stat().st_size >= 200 and ("cq_theta" in t or "cq_measure" in t or "cq_phi" in t)


P = [str(p) for p in sorted(C.glob("P_*.s1.ll")) if ok(p)]
Q = [str(p) for p in sorted(C.glob("Q_*.s1.ll")) if ok(p)]
(V / "probe2_list.txt").write_text("\n".join(Q) + "\n")
print("kept round-2 probe", len(Q))
E = [str(p) for p in sorted(C.glob("E_*.s1.ll")) if ok(p)]
M = [str(p) for p in sorted(C.glob("M_*.s1.ll")) if ok(p)]
(V / "probe_list.txt").write_text("\n".join(P) + "\n")
(V / "e2e_list.txt").write_text("\n".join(E) + "\n")
(V / "multi_list.txt").write_text("\n".join(M) + "\n")
print("kept probe", len(P), "e2e", len(E), "multi", len(M))
