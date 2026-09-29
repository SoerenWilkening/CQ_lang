#!/usr/bin/env python3
"""mkcorpus.py [lit,e2e,multi,probes] — build the stage-1 module lists the A/B sweeps
run over, into $S/cepm/corpus/<section>.txt (default: every section):
  lit    every ir-pass/test/*.ll
  e2e    every tests/e2e/*.c at its default CASE (+ every CASE of a CASE-matrix
         source), single TU with -include CQ.h (a source that needs another TU or
         flags fails stage 1 and is COUNTED and listed as not swept)
  multi  every run_slice_multi.sh ctest entry, llvm-linked exactly as the harness does
  probes the prior session's 9bhg / d88e / r2B-9bhg probe sources (2-TU) + this
         track's battery ($S/cepm/p/*.s1.ll)
4 workers (load discipline)."""
import glob
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a3c46257bc3bd028d"
S = ("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
     "e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad")
L = "/usr/local/opt/llvm@19/bin"
C = os.path.join(S, "cepm", "corpus")
PREV = os.path.join(W, "docs/prd/phase-04-swap-route-control/inc1-records/"
                       "session-2026-09-25-parallel-9bhg-xdu2-16")
INC = os.path.join(W, "include")
ONLY = set(sys.argv[1].split(",")) if len(sys.argv) > 1 else {"lit", "e2e", "multi", "probes"}
os.makedirs(C, exist_ok=True)


def sh(args):
    return subprocess.run(args, capture_output=True).returncode == 0


def cq(src, out, extra=()):
    return sh([L + "/clang", "-I" + INC, "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
               *extra, src, "-o", out])


def plain(src, out):
    return sh([L + "/clang", "-I" + INC, "-O1", "-emit-llvm", "-S", src, "-o", out])


def link(parts, out):
    return sh([L + "/llvm-link", "-S", *parts, "-o", out])


def build_multi(tag, cqsrc, libs, d):
    os.makedirs(d, exist_ok=True)
    parts = [os.path.join(d, tag + ".cq.ll")]
    if not cq(cqsrc, parts[0]):
        return None
    for i, lib in enumerate(libs):
        p = os.path.join(d, f"{tag}.lib{i}.ll")
        if not plain(lib, p):
            return None
        parts.append(p)
    out = os.path.join(d, tag + ".s1.ll")
    return out if link(parts, out) else None


def write(name, items):
    open(os.path.join(C, name), "w").write("\n".join(items) + "\n")


def do_lit():
    fs = sorted(glob.glob(W + "/ir-pass/test/*.ll"))
    write("lit.txt", fs)
    print(f"lit: {len(fs)} fixtures")


def do_e2e():
    jobs = []
    for c in sorted(glob.glob(W + "/tests/e2e/*.c")):
        src = open(c, errors="replace").read()
        cases = sorted(set(int(x) for x in re.findall(r"#define\s+CASE_\w+\s+(\d+)\b", src)))
        if cases and "#ifndef CASE" in src:
            for k in cases:
                jobs.append((c, ["-DCASE=%d" % k]))
        else:
            jobs.append((c, []))
    E = os.path.join(C, "e2e")
    os.makedirs(E, exist_ok=True)

    def one(j):
        c, d = j
        tag = os.path.basename(c)[:-2] + ("" if not d else "_CASE" + d[0][7:])
        out = os.path.join(E, tag + ".s1.ll")
        return out if cq(c, out, d) else ("FAIL:" + tag)

    with ThreadPoolExecutor(4) as ex:
        r = list(ex.map(one, jobs))
    ok = [x for x in r if not x.startswith("FAIL:")]
    write("e2e.txt", ok)
    write("e2e.notswept.txt", [x for x in r if x.startswith("FAIL:")])
    print(f"e2e: {len(jobs)} jobs, {len(ok)} built, {len(jobs) - len(ok)} not swept (need other TUs/flags)")


def do_multi():
    E2E = os.path.join(W, "tests/e2e")
    text = open(os.path.join(E2E, "CMakeLists.txt")).read()
    mj = []
    for m in re.finditer(r"add_test\(NAME\s+(\S+)\s+COMMAND\s+bash\s+\"\$\{CMAKE_CURRENT_SOURCE_DIR\}/"
                         r"run_slice_multi\.sh\"(.*?)\)\s*\n", text, re.S):
        toks = re.findall(r'"([^"]*)"', m.group(2))
        if len(toks) < 10:
            continue
        cqsrc = toks[5].replace("${CMAKE_CURRENT_SOURCE_DIR}", E2E)
        libs = toks[6].replace("${CMAKE_CURRENT_SOURCE_DIR}", E2E).split()
        mj.append((m.group(1), cqsrc, libs))
    MD = os.path.join(C, "multi")
    with ThreadPoolExecutor(4) as ex:
        r = list(ex.map(lambda j: build_multi(j[0], j[1], j[2], MD), mj))
    ok = [x for x in r if x]
    write("multi.txt", ok)
    print(f"multi: {len(mj)} registrations, {len(ok)} built")


def do_probes():
    pj = []
    P9 = os.path.join(PREV, "probes")
    for c in sorted(glob.glob(P9 + "/*.c")):
        b = os.path.basename(c)[:-2]
        if b.startswith("lib") or b.endswith(".lib"):
            continue
        lib = os.path.join(P9, b + ".lib.c")
        pj.append(("9bhg_" + b, c, [lib if os.path.exists(lib) else os.path.join(P9, "lib.c")]))
    PD = os.path.join(PREV, "d88e_probes/src")
    for c in sorted(glob.glob(PD + "/*.c")):
        b = os.path.basename(c)[:-2]
        if b.endswith(".lib"):
            continue
        lib = os.path.join(PD, b + ".lib.c")
        pj.append(("d88e_" + b, c, [lib] if os.path.exists(lib) else []))
    PR = os.path.join(PREV, "review_r2B_9bhg/probes/src")
    for c in sorted(glob.glob(PR + "/*.c")):
        b = os.path.basename(c)[:-2]
        if b in ("lib", "libf"):
            continue
        lib = os.path.join(PR, "libf.c" if b.startswith("F") else "lib.c")
        pj.append(("r2B_" + b, c, [lib]))
    PP = os.path.join(C, "probes")
    with ThreadPoolExecutor(4) as ex:
        r = list(ex.map(lambda j: build_multi(j[0], j[1], j[2], PP), pj))
    ok = [x for x in r if x]
    mine = sorted(glob.glob(os.path.join(S, "cepm/p/*.s1.ll")))
    write("probes.txt", ok + mine)
    print(f"probes: {len(pj)} prior sources, {len(ok)} built; + {len(mine)} battery modules")


for sec, fn in (("lit", do_lit), ("e2e", do_e2e), ("multi", do_multi), ("probes", do_probes)):
    if sec in ONLY:
        fn()
