#!/usr/bin/env python3
"""pairs.py TAG PAIRFILE [--args A B ...] [--jobs 4] [--no-build]

Parallel version of pairs.sh (same verdicts). TAG is S (this worktree's build), O (the
frozen ORACLE) or a path to a cq-opt binary. PAIRFILE lines: "subject twin" (paths
relative to ../src, no extension; '#' comments). Every UNIQUE name is built once
(tools/build.sh) before any run, so a twin shared by several cells is never built
concurrently. Each module runs through tools/run.sh (lower, 2b STRICT + CENSUS, link,
run); rc is cq-opt's own. Verdicts:
  TRACE-IDENT / TRACE-DIFF   both accept; traces byte-identical / not
  DECL-SAME / DECL-DIFF      both decline; same first error line / not
  VERDICT-DIFF               one accepts, the other declines (or crashes)
A module whose opt rc is neither 0 nor 1 (an abort) prints as `opt=<rc>`.
"""
import argparse
import concurrent.futures as cf
import os
import subprocess

H = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.join(H, "..", "src")
SP = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad"
OUT = os.path.join(SP, "nlfd", "out")


def build(n):
    r = subprocess.run([os.path.join(H, "build.sh"), os.path.join(SRC, n)],
                       capture_output=True, text=True)
    return n, r.returncode


def run(tag, n, args):
    env = dict(os.environ, OUT=OUT)
    r = subprocess.run([os.path.join(H, "run.sh"), tag, os.path.join(SRC, n + ".s1.ll")] + args,
                       capture_output=True, text=True, env=env)
    return r.stdout.strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tag")
    ap.add_argument("pairfile")
    ap.add_argument("--args", nargs="*", default=["5", "7"])
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--no-build", action="store_true")
    a = ap.parse_args()
    os.makedirs(OUT, exist_ok=True)
    pairs = []
    for line in open(a.pairfile):
        f = line.split()
        if not f or f[0].startswith("#"):
            continue
        pairs.append((f[0], f[1]))
    names = sorted({n for p in pairs for n in p})
    with cf.ThreadPoolExecutor(a.jobs) as ex:
        if not a.no_build:
            for n, rc in ex.map(build, names):
                if rc:
                    print("BUILD-FAIL", n)
        res = dict(zip(names, ex.map(lambda n: run(a.tag, n, a.args), names)))
    tb = os.path.basename(a.tag)
    for s, t in pairs:
        rs, rt = res[s], res[t]
        acs, act = rs.startswith("opt=0 "), rt.startswith("opt=0 ")
        if acs and act:
            ts = os.path.join(OUT, os.path.basename(s) + "." + tb + ".trace")
            tt = os.path.join(OUT, os.path.basename(t) + "." + tb + ".trace")
            same = open(ts, "rb").read() == open(tt, "rb").read()
            v = "TRACE-IDENT" if same else "TRACE-DIFF"
        elif not acs and not act:
            es, et = rs.split(" ", 1)[-1], rt.split(" ", 1)[-1]
            v = "DECL-SAME" if es == et and rs.startswith("opt=1 ") else "DECL-DIFF"
        else:
            v = "VERDICT-DIFF"
        print(f"{v:<12} {s:<24} vs {t:<16} | S: {rs} | T: {rt}")


if __name__ == "__main__":
    main()
