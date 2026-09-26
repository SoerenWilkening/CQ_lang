#!/usr/bin/env python3
"""Hand-inlined twins for 9bhg's alias-family population (v1, v12, w1..w15): replace
every call of the classical library functions `h(a,k) = k+1` / `hz(a,k) = k` by its
value, build the twin 2-TU module (same lib, so k1/k2/g stay out-of-line), lower
BOTH with the final merged binary under all three allocator modes (sys, lifo,
nofree), link, run with args "5 7" and "2 9", and compare traces. A trace
difference consisting ONLY of the twin uncomputing+freeing one dead register
(`cqrt_ry_<W>(hN, -x)` then `cqrt_free(hN)`, the classical clone's borrowed argument
left allocated in the original, Rule 6's accepted leak) is DEAD-REG-ONLY."""
import difflib
import os
import pathlib
import re
import subprocess

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
                 "agent-a50057998e957b90e")
A = S / "alias9"
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
DBG = S / "frozen/cq-opt-debugalloc.final"
SYS = S / "frozen/cq-opt.final"
RT, TPL = W / "build/runtime/libcq_runtime.a", W / "build/runtime/libcq_templates.a"
SUBS = [(r"\bhz\(\s*(\w+)\s*,\s*(\w+)\s*\)", r"(\2)"),
        (r"\bh\(\s*(\w+)\s*,\s*(\w+)\s*\)", r"(\2 + 1)")]


def sh(cmd, env=None, cwd=None):
    return subprocess.run(cmd, capture_output=True, text=True, env=env, cwd=cwd)


def lower(src_ll, out, mode):
    env = dict(os.environ)
    env.pop("CQ_OPT_DEBUG_ALLOC", None)
    b = SYS
    if mode != "sys":
        b = DBG
        env["CQ_OPT_DEBUG_ALLOC"] = mode
    return sh([str(b), "-passes=cq-lowering", "-S", str(src_ll), "-o", str(out)], env=env).returncode


def traces(ll):
    exe = ll.with_suffix(".exe")
    if sh([str(L / "clang"), str(ll), str(TPL), str(RT), "-o", str(exe)]).returncode:
        return None
    out = []
    for args in ("5 7", "2 9"):
        r = subprocess.run([str(exe)] + args.split(), capture_output=True, text=True)
        out.append(r.stdout.splitlines() + [f"exit={r.returncode}"])
    return out


def cls(tc, tt):
    if tc == tt:
        return "IDENT"
    for a, b in zip(tc, tt):
        d = [l for l in difflib.unified_diff(a, b, lineterm="", n=0)
             if not l.startswith(("---", "+++", "@@"))]
        minus = [l for l in d if l.startswith("-")]
        plus = [l[1:] for l in d if l.startswith("+")]
        if not d:
            continue
        # any number of (ry(hN, -x), free(hN)) PAIRS, nothing removed: one per dead
        # register (v12 calls `f` twice, so two borrowed registers)
        ok = not minus and len(plus) >= 2 and len(plus) % 2 == 0
        for i in range(0, len(plus), 2) if ok else []:
            m = re.fullmatch(r"cqrt_ry_\w+\((h\d+), -0x[0-9a-fp.+-]+\)", plus[i])
            ok = ok and bool(m) and plus[i + 1] == f"cqrt_free({m.group(1)})"
        if not ok:
            return "OTHER:\n    " + "\n    ".join(d[:12])
    return "DEAD-REG-ONLY"


rows = []
for fam, names in (("alias_gen5", ["v1", "v12"]), ("alias_gen6", [f"w{i}" for i in range(1, 16)])):
    d = A / fam
    for n in names:
        src = (d / f"{n}.c").read_text()
        tw = src
        for pat, rep in SUBS:
            tw = re.sub(pat, rep, tw)
        if re.search(r"\bhz?\(", tw.split("int main", 1)[1]) or re.search(r"return \bhz?\(", tw):
            rows.append((n, "TWIN-NOT-DERIVABLE", ""))
            continue
        (d / f"{n}T.c").write_text(tw)
        sh([str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
            f"{n}T.c", "-o", f"{n}T.caller.ll"], cwd=d)
        sh([str(L / "llvm-link"), "-S", f"{n}T.caller.ll", "lib.ll", "-o", f"{n}T.s1.ll"], cwd=d)
        verdicts = []
        for mode in ("sys", "lifo", "nofree"):
            rc_c = lower(d / f"{n}.s1.ll", d / f"{n}.tw_{mode}.s2.ll", mode)
            rc_t = lower(d / f"{n}T.s1.ll", d / f"{n}T.tw_{mode}.s2.ll", mode)
            if rc_c or rc_t:
                verdicts.append(f"{mode}: C rc={rc_c} T rc={rc_t}")
                continue
            tc = traces(d / f"{n}.tw_{mode}.s2.ll")
            tt = traces(d / f"{n}T.tw_{mode}.s2.ll")
            verdicts.append(f"{mode}: {cls(tc, tt)}")
        rows.append((n, "; ".join(verdicts), ""))
for n, v, _ in rows:
    print(f"{n:4} {v}")
