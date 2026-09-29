#!/usr/bin/env python3
"""ab.py [--build] OPT_A OPT_B [LABEL]

Corpus A/B for bd nlfd / bd ev3m. The corpus (built once by --build into the scratchpad,
listed in corpus.txt there):
  lit    every ir-pass/test/*.ll of this worktree
  e2e    every tests/e2e/*.c at its default CASE and every declared CASE (single TU,
         clang -O1 -include CQ.h), exactly as xdu2_16's ab_e2e.py
  multi  every run_slice_multi.sh entry of tests/e2e/CMakeLists.txt (CQ TU + its libs,
         llvm-linked — the harness recipe)
  probe  every stage-1 module of the prior review/probe dirs this track touches
         (session-2026-09-25 review_r{1A..6}_vsfp, vsfp_probes, review_r2A_9bhg) and of
         nlfd_probes/src: each *.ll that is not a lowered output, and each *.c built with
         its <name>.lib.c (2 TUs) or alone; a build failure is listed, never swept
Compares exit code, stdout sha-256 and the first error line; prints the DENOMINATOR per
set first, then every mover classified D->A / A->D / STRING / STREAM. ≤4 workers."""
import glob
import hashlib
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a333a1777db2f2295"
SP = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad/nlfd/corpus"
L = "/usr/local/opt/llvm@19/bin"
R = W + "/docs/prd/phase-04-swap-route-control/inc1-records"
PROBE_DIRS = [R + "/session-2026-09-25-parallel-9bhg-xdu2-16/" + d for d in
              ["review_r1A_vsfp", "review_r1B_vsfp", "review_r2A_vsfp", "review_r2B_vsfp",
               "review_r3A_vsfp", "review_r3B_vsfp", "review_r4A_vsfp", "review_r4B_vsfp",
               "review_r5_vsfp", "review_r6_vsfp", "vsfp_probes", "review_r2A_9bhg"]] + \
             [R + "/session-2026-09-28-parallel/nlfd_probes/src",
              # round 2: both Rule-13 round-1 reviewers' probe batteries
              R + "/session-2026-09-28-parallel/review_r1A_nlfd/probes",
              R + "/session-2026-09-28-parallel/review_r1B_nlfd/probes"]


def sh(cmd):
    return subprocess.run(cmd, capture_output=True)


def build():
    os.makedirs(SP, exist_ok=True)
    jobs = []  # (set, tag, kind, args)
    for f in sorted(glob.glob(W + "/ir-pass/test/*.ll")):
        jobs.append(("lit", os.path.basename(f), "copy", [f]))
    for c in sorted(glob.glob(W + "/tests/e2e/*.c")):
        src = open(c, errors="replace").read()
        cases = sorted(set(int(x) for x in re.findall(r"#define\s+CASE_\w+\s+(\d+)\b", src)))
        if cases and "#ifndef CASE" in src:
            for k in cases:
                jobs.append(("e2e", f"{os.path.basename(c)}:{k}", "c1", [c, f"-DCASE={k}"]))
        else:
            jobs.append(("e2e", os.path.basename(c), "c1", [c]))
    cm = open(W + "/tests/e2e/CMakeLists.txt").read()
    for m in re.finditer(r'add_test\(NAME (\S+)\s+COMMAND bash "\$\{CMAKE_CURRENT_SOURCE_DIR\}/run_slice_multi\.sh"(.*?)\)\n', cm, re.S):
        srcs = re.findall(r'"\$\{CMAKE_CURRENT_SOURCE_DIR\}/([^"]+)"', m.group(2))
        cq = [s for s in srcs if s.endswith(".c")]
        if not cq:
            continue
        # first .c is the CQ TU; the next quoted arg is the lib list (space-separated)
        libs_raw = re.findall(r'"([^"]*)"', m.group(2))
        # find the quoted arg right after the CQ source
        idx = libs_raw.index("${CMAKE_CURRENT_SOURCE_DIR}/" + cq[0])
        libs = [x.replace("${CMAKE_CURRENT_SOURCE_DIR}", W + "/tests/e2e")
                for x in libs_raw[idx + 1].split()] if idx + 1 < len(libs_raw) else []
        libs = [x for x in libs if x.endswith(".c")]
        jobs.append(("multi", m.group(1), "c2", [W + "/tests/e2e/" + cq[0]] + libs))
    for d in PROBE_DIRS:
        for f in sorted(glob.glob(d + "/**/*", recursive=True)):
            b = os.path.basename(f)
            rel = os.path.relpath(f, R)
            if b.endswith(".ll"):
                if re.search(r"\.(s2|S|O|M|R\d|sub|ora|low|out)\.|lowered|\.s2\b", b) or "/results/" in f or "/out/" in f:
                    continue
                if os.path.exists(f[:-3] + ".c"):
                    continue  # built from its source below
                jobs.append(("probe", rel, "copy", [f]))
            elif b.endswith(".c") and ".lib" not in b and "lib." not in b and not b.startswith("lib"):
                lib = f[:-2] + ".lib.c"
                jobs.append(("probe", rel, "c2" if os.path.exists(lib) else "c1",
                             [f] + ([lib] if os.path.exists(lib) else [])))
    out = []

    def mk(j):
        st, tag, kind, a = j
        dst = os.path.join(SP, st + "__" + re.sub(r"[^\w.:-]", "_", tag) + ".s1.ll")
        if kind == "copy":
            data = open(a[0], "rb").read()
            if not data.strip():
                return st, tag, None
            open(dst, "wb").write(data)
            return st, tag, dst
        if kind == "c1":
            p = sh([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm",
                    "-S", "-Wno-everything"] + a[1:] + [a[0], "-o", dst])
            return st, tag, dst if p.returncode == 0 and os.path.getsize(dst) else None
        cq, libs = a[0], a[1:]
        parts = [dst + ".cq.ll"]
        p = sh([L + "/clang", "-I" + W + "/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
                "-Wno-everything", cq, "-o", parts[0]])
        if p.returncode:
            return st, tag, None
        for i, lb in enumerate(libs):
            parts.append(dst + f".lib{i}.ll")
            p = sh([L + "/clang", "-I" + W + "/include", "-O1", "-emit-llvm", "-S", "-Wno-everything",
                    lb, "-o", parts[-1]])
            if p.returncode:
                return st, tag, None
        p = sh([L + "/llvm-link", "-S"] + parts + ["-o", dst])
        for x in parts:
            os.remove(x)
        return st, tag, dst if p.returncode == 0 else None

    with ThreadPoolExecutor(4) as ex:
        for st, tag, dst in ex.map(mk, jobs):
            out.append((st, tag, dst))
    with open(os.path.join(SP, "corpus.txt"), "w") as f:
        for st, tag, dst in out:
            f.write(f"{st}\t{tag}\t{dst or 'BUILD-FAIL'}\n")
    for st in ("lit", "e2e", "multi", "probe"):
        n = sum(1 for x in out if x[0] == st)
        bad = sum(1 for x in out if x[0] == st and not x[2])
        print(f"built {st}: {n} jobs, {n - bad} modules, {bad} build failures")


def run(opt, f):
    p = subprocess.run([opt, "-passes=cq-lowering", "-S", f, "-o", "-"], capture_output=True, timeout=600)
    err = [l for l in p.stderr.decode(errors="replace").splitlines() if "error:" in l]
    return (p.returncode, hashlib.sha256(p.stdout).hexdigest()[:16],
            err[0].split("error:", 1)[1].strip() if err else "")


def main():
    args = [a for a in sys.argv[1:] if a != "--build"]
    if "--build" in sys.argv:
        build()
        if not args:
            return
    A, B = args[0], args[1]
    rows = [l.rstrip("\n").split("\t") for l in open(os.path.join(SP, "corpus.txt"))]
    mods = [(st, tag, f) for st, tag, f in rows if f != "BUILD-FAIL"]
    for st in ("lit", "e2e", "multi", "probe"):
        n = sum(1 for r in rows if r[0] == st)
        m = sum(1 for r in mods if r[0] == st)
        print(f"denominator {st}: {m} modules ({n - m} build failures not swept)")
    print(f"denominator total: {len(mods)}  A={A}  B={B}", flush=True)

    def one(x):
        st, tag, f = x
        return st, tag, run(A, f), run(B, f)

    with ThreadPoolExecutor(4) as ex:
        res = list(ex.map(one, mods))
    mov = [r for r in res if r[2] != r[3]]
    print(f"movers {len(mov)} of {len(res)}")
    for st, tag, a, b in mov:
        kind = ("D->A" if a[0] != 0 and b[0] == 0 else "A->D" if a[0] == 0 and b[0] != 0
                else "STRING" if a[0] != 0 else "STREAM")
        print(f"{kind}\t{st}\t{tag}\tA={a}\tB={b}")


if __name__ == "__main__":
    main()
