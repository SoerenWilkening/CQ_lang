#!/usr/bin/env python3
"""ctlprobe.py <control-name> ... — build a loop_twin_matrix BOUNDARY CONTROL's two
halves and compare their TRACES, WITHOUT the harness's STRICT stage-2b abort.

Answers the question decision (B) rests on: `q_armoncond` is pinned TRACE-DIVERGENCE
and the run reported HARNESS-ERROR. If the error is only the 2b `UNPROVEN` abort
(Track C's subject), then past that abort the control may still diverge with its
ORIGINAL pinned signature -- in which case NO re-pin is owed at all.
"""
import os, sys, subprocess, tempfile, shutil, hashlib, difflib, collections

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
    r = subprocess.run([CLANG, "-I", INC, "-include", "CQ.h", "-O1", "-emit-llvm", "-S", c, "-o", s1],
                       capture_output=True, text=True)
    if r.returncode:
        return {"stage": "clang", "err": r.stderr[:300]}
    s2 = os.path.join(work, name + ".s2.ll")
    r = subprocess.run([OPT, "-load-pass-plugin", PLUGIN, "-passes=cq-lowering", "-S", s1, "-o", s2],
                       capture_output=True, text=True)
    if r.returncode:
        first = next((l for l in r.stderr.splitlines() if "error:" in l), "")
        return {"stage": "decline", "err": first[:200]}
    pc = subprocess.run([sys.executable, os.path.join(W, "tools/free_pairing_check.py"), s2],
                        capture_output=True, text=True)
    census = next((l for l in (pc.stdout + pc.stderr).splitlines()
                   if l.startswith("free_pairing_check:")), "")
    nunproven = sum(1 for l in (pc.stdout + pc.stderr).splitlines() if "UNPROVEN" in l)
    exe = os.path.join(work, name + ".exe")
    r = subprocess.run([CLANG, s2, TPL, RT, "-o", exe], capture_output=True, text=True)
    if r.returncode:
        return {"stage": "link", "err": r.stderr[:300]}
    r = subprocess.run([exe], capture_output=True, text=True)
    return {"stage": "ok", "trace": r.stdout.splitlines(), "census": census,
            "pc_rc": pc.returncode, "unproven": nunproven}


for name in sys.argv[1:]:
    print("=" * 78)
    try:
        r_src, u_src = M.control_sources(name, "void")
    except Exception as e:
        print(f"{name}: not a control ({e})")
        continue
    work = tempfile.mkdtemp(prefix="ctlprobe_")
    try:
        R = build(work, name, r_src)
        U = build(work, name + "_u", u_src)
    finally:
        shutil.rmtree(work, ignore_errors=True)
    print(f"CONTROL {name}")
    pin = M.SURFACE_CONTROL_VERDICTS.get("void", {}).get(name)
    print(f"  PINNED in SURFACE_CONTROL_VERDICTS['void']: {pin}")
    for side, D in (("rolled", R), ("unrolled", U)):
        print(f"  {side}: stage={D['stage']}" + (f" {D.get('err','')}" if D["stage"] != "ok" else ""))
    if R["stage"] != "ok" or U["stage"] != "ok":
        continue
    print(f"  rolled 2b  : {R['census']}  (rc={R['pc_rc']}, UNPROVEN lines={R['unproven']})")
    print(f"  unrolled 2b: {U['census']}  (rc={U['pc_rc']}, UNPROVEN lines={U['unproven']})")
    rt, ut = R["trace"], U["trace"]
    print(f"  trace lines: rolled {len(rt)} unrolled {len(ut)}")
    print(f"  BYTE-IDENTICAL: {rt == ut}")
    print(f"  MULTISET-EQUAL: {collections.Counter(l.split('(')[0] for l in rt) == collections.Counter(l.split('(')[0] for l in ut)}")
    if rt != ut:
        d = list(difflib.unified_diff(rt, ut, "rolled", "unrolled", lineterm="", n=1))
        print("  --- unified diff ---")
        for l in d:
            print("   " + l)
        # the quarantine/control signature is sha256 of the FULL unified diff, 16 hex
        print(f"  DIFF SIGNATURE (sha256[:16]): {hashlib.sha256(chr(10).join(d).encode()).hexdigest()[:16]}")
