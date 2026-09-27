#!/usr/bin/env python3
"""vsfp harness.
build(dir, name): <name>.c [+ <name>.lib.c] -> out/<dir>__<name>.s1.ll (llvm-linked like run_slice_multi.sh).
opt(tag, s1): cq-opt.<tag> -> (rc, first-error, s2 path, stderr)
run(s2, args): 2b strict + link (templates BEFORE runtime) + trace.
"""
import hashlib, os, pathlib, subprocess, sys

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
V = S / "vsfp"
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8")
O = V / "out"
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
TPL = W / "build/runtime/libcq_templates.a"
RT = W / "build/runtime/libcq_runtime.a"
BIN = V / "bin"
O.mkdir(exist_ok=True)


def binpath(tag):
    if tag == "main":
        return S / "frozen/cq-opt.main_aee8"
    return BIN / f"cq-opt.{tag}"


def sh(cmd, env=None, **kw):
    e = dict(os.environ)
    if env:
        e.update(env)
    return subprocess.run(cmd, capture_output=True, text=True, env=e, **kw)


def build(d, b):
    d = V / d
    src = d / f"{b}.c"
    lib = d / f"{b}.lib.c"
    tag = f"{d.name}__{b}"
    out = O / f"{tag}.s1.ll"
    cq = [str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything"]
    if lib.exists():
        r1 = sh([str(L / "clang"), "-O1", "-emit-llvm", "-S", "-Wno-everything", str(lib), "-o", str(O / f"{tag}.lib.ll")])
        r2 = sh(cq + [str(src), "-o", str(O / f"{tag}.caller.ll")])
        if r1.returncode or r2.returncode:
            return None, "GENFAIL " + r1.stderr + r2.stderr
        r3 = sh([str(L / "llvm-link"), "-S", str(O / f"{tag}.caller.ll"), str(O / f"{tag}.lib.ll"), "-o", str(out)])
        if r3.returncode:
            return None, "LINKFAIL " + r3.stderr
    else:
        r = sh(cq + [str(src), "-o", str(out)])
        if r.returncode:
            return None, "GENFAIL " + r.stderr
    if out.stat().st_size < 200:
        return None, "TINY"
    return out, ""


def opt(tag, s1, env=None):
    s2 = pathlib.Path(str(s1).replace(".s1.ll", f".{tag}.s2.ll"))
    r = sh([str(binpath(tag)), "-passes=cq-lowering", "-S", str(s1), "-o", str(s2)], env=env)
    err = [l for l in r.stderr.splitlines() if "error" in l or "Assert" in l or "LLVM ERROR" in l or "Stack" in l]
    msg = err[0].split("error: ")[-1] if err else ""
    if r.returncode != 0 and s2.exists():
        s2.unlink()
    return r.returncode, msg, (s2 if r.returncode == 0 else None), r.stderr


def check2b(s2):
    r = sh(["python3", str(W / "tools/free_pairing_check.py"), str(s2)])
    lines = [l for l in r.stdout.splitlines() + r.stderr.splitlines() if l.strip()]
    return r.returncode, lines


def linkrun(s2, args):
    exe = pathlib.Path(str(s2) + ".exe")
    r = sh([str(L / "clang"), "-Wno-everything", str(s2), str(TPL), str(RT), "-o", str(exe)])
    if r.returncode:
        return None, "LINKFAIL " + r.stderr[-400:]
    t = sh([str(exe)] + [str(a) for a in args])
    exe.unlink()
    return t.returncode, t.stdout + t.stderr


def sha(p):
    return hashlib.sha256(open(p, "rb").read()).hexdigest()[:12] if p else "-"


def verdict(tag, d, b, args=("5", "7")):
    s1, e = build(d, b)
    if not s1:
        return {"v": e}
    rc, msg, s2, stderr = opt(tag, s1)
    warn = sum(1 for l in stderr.splitlines() if "warning:" in l)
    if rc != 0:
        return {"v": f"DECL", "msg": msg, "rc": rc}
    c, l = check2b(s2)
    x, tr = linkrun(s2, args)
    return {"v": "ACC", "warn": warn, "2b": c, "2bl": (l[-1] if l else ""), "trace": tr, "run": x, "s2": s2}


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "show":
        tag, d, b = sys.argv[2], sys.argv[3], sys.argv[4]
        args = sys.argv[5:] or ["5", "7"]
        r = verdict(tag, d, b, args)
        print(f"[{tag}] {d}/{b}: {r['v']} {r.get('msg','')} warn={r.get('warn','')} 2b={r.get('2b','')} {r.get('2bl','')}")
        if "trace" in r:
            print("  " + r["trace"].replace("\n", "\n  "))
    elif cmd == "pair":
        # pair <tag> <dir> <subject> <twin> [args]: compare verdicts + traces
        tag, d, b, t = sys.argv[2:6]
        args = sys.argv[6:] or ["5", "7"]
        rs = verdict(tag, d, b, args)
        rt = verdict(tag, d, t, args)
        same = None
        if rs["v"] == "ACC" and rt["v"] == "ACC":
            same = "TRACE-IDENT" if rs["trace"] == rt["trace"] else "TRACE-DIFF"
        elif rs["v"] == rt["v"] == "DECL":
            same = "DECL-SAME" if rs.get("msg") == rt.get("msg") else "DECL-DIFFSTR"
        else:
            same = "VERDICT-DIFF"
        print(f"[{tag}] {b} vs {t}: {same} | S={rs['v']} {rs.get('msg','')} w={rs.get('warn','')} 2b={rs.get('2bl','')} | T={rt['v']} {rt.get('msg','')} w={rt.get('warn','')}")
