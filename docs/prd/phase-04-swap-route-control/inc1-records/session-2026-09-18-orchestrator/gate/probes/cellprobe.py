#!/usr/bin/env python3
"""cellprobe.py <cellname> [...]

Build a loop_twin_matrix CELL's rolled and unrolled halves and compare their
TRACES, WITHOUT the harness's STRICT stage-2b abort. The matrix returns
HARNESS-ERROR for any cell whose rolled side reports `unproven` (a deliberate
policy), which means it never reaches the trace comparison for those cells. This
reproduces everything AFTER that gate so the cell can still be adjudicated.

Prints, per cell: both exits, the stage-2b census line (informational), trace
line counts, whether the traces are byte-identical, whether the gate-symbol
MULTISETS are identical, and the unified diff.
"""
import os, sys, subprocess, tempfile, shutil, hashlib, collections

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-ac2acfdde3461becc"
LLVM = "/usr/local/opt/llvm@19/bin"
sys.path.insert(0, os.path.join(W, "tools"))
import loop_twin_matrix as M

CLANG = os.path.join(LLVM, "clang")
OPT = os.path.join(W, "build/ir-pass/cq-opt")
PLUGIN = os.path.join(W, "build/ir-pass/libCQPass.so")
INC = os.path.join(W, "include")
RT = os.path.join(W, "build/runtime/libcq_runtime.a")
TPL = os.path.join(W, "build/runtime/libcq_templates.a")


def build(work, name, csrc):
    c = os.path.join(work, name + ".c")
    open(c, "w").write(csrc)
    s1 = os.path.join(work, name + ".s1.ll")
    r = subprocess.run([CLANG, "-I", INC, "-include", "CQ.h", "-O1",
                        "-emit-llvm", "-S", c, "-o", s1],
                       capture_output=True, text=True)
    if r.returncode:
        return {"stage": "clang", "rc": r.returncode, "err": r.stderr[:400]}
    s2 = os.path.join(work, name + ".s2.ll")
    r = subprocess.run([OPT, "-load-pass-plugin", PLUGIN, "-passes=cq-lowering",
                        "-S", s1, "-o", s2], capture_output=True, text=True)
    if r.returncode:
        first = next((l for l in r.stderr.splitlines() if "error:" in l), "")
        return {"stage": "decline", "rc": r.returncode, "err": first[:200]}
    pc = subprocess.run([sys.executable, os.path.join(W, "tools/free_pairing_check.py"),
                         "-q", s2], capture_output=True, text=True)
    census = next((l for l in (pc.stdout + pc.stderr).splitlines()
                   if l.startswith("free_pairing_check:")), "")
    exe = os.path.join(work, name + ".exe")
    r = subprocess.run([CLANG, s2, TPL, RT, "-o", exe],
                       capture_output=True, text=True)
    if r.returncode:
        return {"stage": "link", "rc": r.returncode, "err": r.stderr[:400]}
    r = subprocess.run([exe], capture_output=True, text=True)
    return {"stage": "ok", "rc": 0, "trace": r.stdout.splitlines(),
            "census": census, "pc_rc": pc.returncode,
            "warn": [l for l in (pc.stdout + pc.stderr).splitlines() if "UNPROVEN" in l]}


def multiset(trace):
    return collections.Counter(l.split("(")[0] for l in trace)


def main():
    by_name = {M.cell_name(c): c for c in M.cells_of_matrix()}
    for name in sys.argv[1:]:
        print("=" * 78)
        if name not in by_name:
            print(f"{name}: NOT A CELL"); continue
        prefix, region, suffix, record, rgate = by_name[name]
        r_src, u_src = M.sources(prefix, region, suffix, record, rgate, "void")
        work = tempfile.mkdtemp(prefix="cellprobe_")
        try:
            R = build(work, name, r_src)
            U = build(work, name + "_u", u_src)
        finally:
            shutil.rmtree(work, ignore_errors=True)
        print(f"CELL {name}")
        print(f"  rolled  : stage={R['stage']} rc={R['rc']}" + (f"  {R.get('err','')}" if R['stage'] != 'ok' else ""))
        print(f"  unrolled: stage={U['stage']} rc={U['rc']}" + (f"  {U.get('err','')}" if U['stage'] != 'ok' else ""))
        if R["stage"] != "ok" or U["stage"] != "ok":
            continue
        print(f"  rolled 2b  : {R['census']}   (check rc={R['pc_rc']})")
        print(f"  unrolled 2b: {U['census']}   (check rc={U['pc_rc']})")
        rt, ut = R["trace"], U["trace"]
        same = rt == ut
        msame = multiset(rt) == multiset(ut)
        print(f"  trace lines: rolled {len(rt)}  unrolled {len(ut)}")
        print(f"  BYTE-IDENTICAL : {same}")
        print(f"  MULTISET-EQUAL : {msame}")
        if not same:
            import difflib
            d = list(difflib.unified_diff(rt, ut, "rolled", "unrolled", lineterm="", n=1))
            print("  --- unified diff ---")
            for l in d:
                print("   " + l)
            sig = hashlib.sha256("\n".join(d).encode()).hexdigest()[:16]
            print(f"  DIFF SIGNATURE (sha256[:16] of the unified diff): {sig}")


if __name__ == "__main__":
    main()
