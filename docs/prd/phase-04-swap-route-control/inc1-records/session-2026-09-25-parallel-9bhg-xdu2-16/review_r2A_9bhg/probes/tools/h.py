#!/usr/bin/env python3
"""r2A harness. build <name>: <name>.c [+ <name>.lib.c] -> <name>.s1.ll (llvm-linked like run_slice_multi).
opt(bin, name): exit, stderr-first-error, lowered IR path. run: 2b strict + link (templates BEFORE runtime) + trace."""
import hashlib, os, pathlib, subprocess, sys
S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
P = S / "r2A/p"
O = S / "r2A/out"
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
TPL = W / "build/runtime/libcq_templates.a"
RT = W / "build/runtime/libcq_runtime.a"
BINS = {
    "sub": S / "frozen/cq-opt.final",          # bfb441d3 subject
    "main": S / "frozen/cq-opt.main_aee8",     # 69250fea
    "alone": S / "frozen/cq-opt.9bhg_only",    # 8b837d1f (30529716)
    "ora": S / "frozen/cq-opt.main983",        # 438c77bf
    "pre": S / "frozen/cq-opt.preE",           # 63e2f0bb
    "dbg": S / "frozen/cq-opt-debugalloc.final",
    "ins": S / "r2A/build/ir-pass/cq-opt",     # instrumented subject
}
O.mkdir(exist_ok=True)

def sh(cmd, env=None, **kw):
    e = dict(os.environ)
    if env: e.update(env)
    return subprocess.run(cmd, capture_output=True, text=True, env=e, **kw)

def build(b, d=P):
    src = d / f"{b}.c"; lib = d / f"{b}.lib.c"; out = O / f"{b}.s1.ll"
    cq = [str(L/"clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything"]
    if lib.exists():
        r1 = sh([str(L/"clang"), "-O1", "-emit-llvm", "-S", "-Wno-everything", str(lib), "-o", str(O/f"{b}.lib.ll")])
        r2 = sh(cq + [str(src), "-o", str(O/f"{b}.caller.ll")])
        if r1.returncode or r2.returncode: return None, "GENFAIL " + r1.stderr + r2.stderr
        r3 = sh([str(L/"llvm-link"), "-S", str(O/f"{b}.caller.ll"), str(O/f"{b}.lib.ll"), "-o", str(out)])
        if r3.returncode: return None, "LINKFAIL " + r3.stderr
    else:
        r = sh(cq + [str(src), "-o", str(out)])
        if r.returncode: return None, "GENFAIL " + r.stderr
    if out.stat().st_size < 200: return None, "TINY"
    return out, ""

def opt(binname, b, env=None, tag=None):
    s1 = O / f"{b}.s1.ll"; tag = tag or binname
    s2 = O / f"{b}.{tag}.s2.ll"
    r = sh([str(BINS[binname]), "-passes=cq-lowering", "-S", str(s1), "-o", str(s2)], env=env)
    err = [l for l in r.stderr.splitlines() if "error" in l or "Assert" in l or "LLVM ERROR" in l or "Stack" in l]
    msg = err[0].split("error: ")[-1] if err else ""
    if r.returncode != 0 and s2.exists(): s2.unlink()
    return r.returncode, msg, (s2 if r.returncode == 0 else None), r.stderr

def check2b(s2):
    r = sh(["python3", str(W/"tools/free_pairing_check.py"), str(s2)])
    lines = [l for l in r.stdout.splitlines() + r.stderr.splitlines() if l.strip()]
    return r.returncode, lines

def linkrun(s2, args, tag):
    exe = O / f"{tag}.exe"
    r = sh([str(L/"clang"), "-Wno-everything", str(s2), str(TPL), str(RT), "-o", str(exe)])
    if r.returncode: return None, "LINKFAIL " + r.stderr[-400:]
    t = sh([str(exe)] + [str(a) for a in args])
    exe.unlink()
    return t.returncode, t.stdout + t.stderr

def sha(p): return hashlib.sha256(open(p,'rb').read()).hexdigest()[:12] if p else "-"

if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "show":
        # show <bin> <name> [args...]
        bn, b = sys.argv[2], sys.argv[3]; args = sys.argv[4:] or ["5", "7"]
        s1, e = build(b)
        if not s1: print(e); sys.exit(1)
        rc, msg, s2, stderr = opt(bn, b)
        print(f"[{bn}] {b}: exit={rc} {msg}")
        if s2:
            c, l = check2b(s2); print("  2b:", c, " | ".join(l[-3:]))
            x, tr = linkrun(s2, args, f"{b}.{bn}")
            print(f"  run exit={x}"); print("  " + tr.replace("\n", "\n  "))
