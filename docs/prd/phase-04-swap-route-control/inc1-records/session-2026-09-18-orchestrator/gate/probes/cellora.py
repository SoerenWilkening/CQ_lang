#!/usr/bin/env python3
"""cellora.py <cell> ... — run a matrix cell's ROLLED half on the ORACLE and report its verdict.

Verifies the attribution of a newly-diverging cell: if the rolled half DECLINES on the
oracle with Track D's P4 string and ACCEPTS on the combined binary, the divergence is D's.
"""
import os, sys, subprocess, tempfile, shutil

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc"
ORC = "/Users/sorenwilkening/Desktop/Projects/CQ_lang"
LLVM = "/usr/local/opt/llvm@19/bin"
sys.path.insert(0, os.path.join(W, "tools"))
import loop_twin_matrix as M


def run(root, csrc, tag):
    T = tempfile.mkdtemp(prefix="cellora_")
    try:
        c = os.path.join(T, tag + ".c")
        open(c, "w").write(csrc)
        s1 = os.path.join(T, "s1.ll")
        r = subprocess.run([os.path.join(LLVM, "clang"), "-I", os.path.join(W, "include"),
                            "-include", "CQ.h", "-O1", "-emit-llvm", "-S", c, "-o", s1],
                           capture_output=True, text=True)
        if r.returncode:
            return "CLANGERR"
        r = subprocess.run([os.path.join(root, "build/ir-pass/cq-opt"),
                            "-load-pass-plugin", os.path.join(root, "build/ir-pass/libCQPass.so"),
                            "-passes=cq-lowering", "-S", s1, "-o", os.path.join(T, "s2.ll")],
                           capture_output=True, text=True)
        if r.returncode == 0:
            return "ACCEPT"
        for l in r.stderr.splitlines():
            if "error:" in l:
                i = l.find("cq ")
                return "DECLINE: " + (l[i:].replace(" under quantum control", "").strip() if i >= 0 else l)
        return "DECLINE (no message)"
    finally:
        shutil.rmtree(T, ignore_errors=True)


by = {M.cell_name(c): c for c in M.cells_of_matrix()}
for name in sys.argv[1:]:
    if name not in by:
        print(f"{name}: NOT A CELL"); continue
    p, reg, suf, rec, rg = by[name]
    r_src, u_src = M.sources(p, reg, suf, rec, rg, "void")
    print(f"{name}")
    print(f"   ROLLED  on ORACLE  : {run(ORC, r_src, name)}")
    print(f"   ROLLED  on COMBINED: {run(W, r_src, name)}")
    print(f"   UNROLLED on ORACLE : {run(ORC, u_src, name + '_u')}")
