#!/usr/bin/env python3
import sys, pathlib, subprocess, re, hashlib
R = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/rA_vsfp")
O = R / "samp"
L = "/usr/local/opt/llvm@19/bin"
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-abf65d7dcfbff38c8")
INC = W / "include"
SUB = str(W / "build/ir-pass/cq-opt")
ORA = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad/frozen/cq-opt.main_aee8"
RECS = [pathlib.Path(p) / "docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16" for p in
        ["/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e", str(W)]]
src_of = {}
for Rd in RECS:
    for d in Rd.iterdir():
        if not d.is_dir(): continue
        for s in d.rglob("*.c"):
            if s.name.endswith(".lib.c"): continue
            tag = "P_" + d.name + "__" + "_".join(s.relative_to(d).with_suffix("").parts)
            src_of.setdefault(tag, s)
def sh(c, **k): return subprocess.run(c, capture_output=True, text=True, **k)
def build(key, main, libs, cat=False):
    out = O / f"{key}.s1.ll"
    if cat:
        cs = O / f"{key}.cat.c"
        cs.write_text(main.read_text() + "\n" + "\n".join(l.read_text() for l in libs))
        r = sh([f"{L}/clang", f"-I{INC}", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(cs), "-o", str(out)])
        return out if r.returncode == 0 else None
    lls = [O / f"{key}.cq.ll"]
    r = sh([f"{L}/clang", f"-I{INC}", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(main), "-o", str(lls[0])])
    if r.returncode: return None
    for i, l in enumerate(libs):
        o = O / f"{key}.lib{i}.ll"; lls.append(o)
        r = sh([f"{L}/clang", f"-I{INC}", "-O1", "-emit-llvm", "-S", "-Wno-everything", str(l), "-o", str(o)])
        if r.returncode: return None
    r = sh([f"{L}/llvm-link", "-S", *map(str, lls), "-o", str(out)])
    return out if r.returncode == 0 else None
def verdict(binp, s1, key, args_list=(("5", "7"), ("2", "9"))):
    s2 = O / f"{key}.{pathlib.Path(binp).name}.s2.ll"
    r = sh([binp, "-passes=cq-lowering", "-S", str(s1), "-o", str(s2)])
    if r.returncode:
        e = [l for l in r.stderr.splitlines() if "error" in l]
        m = e[0].split("): ")[-1] if e else r.stderr[:80]
        return ("DECL", m, None)
    w = sum(1 for l in r.stderr.splitlines() if "warning" in l)
    exe = O / f"{key}.exe"
    r2 = sh([f"{L}/clang", "-Wno-everything", str(s2), str(W / "build/runtime/libcq_templates.a"), str(W / "build/runtime/libcq_runtime.a"), "-o", str(exe)])
    if r2.returncode: return ("LINKFAIL", "", None)
    tr = []
    for a in args_list:
        t = sh([str(exe), *a]); tr.append(f"rc={t.returncode}\n" + t.stdout)
    exe.unlink()
    return ("ACC", f"w={w}", hashlib.sha256("\n##\n".join(tr).encode()).hexdigest()[:12])
def twin_of(src):
    n = src.stem; c = [n + "T"]
    if n[-1:] in ("C", "S", "W", "f"): c.append(n[:-1] + "T")
    for x in c:
        p = src.with_name(x + ".c")
        if p.exists() and p != src: return p
def libs_of(src):
    return [p for p in [src.with_name(src.stem + ".lib.c")] if p.exists()]
def cls(a, b):
    if a[0] == "ACC" and b[0] == "ACC": return "TRACE-IDENT" if a[2] == b[2] else "TRACE-DIFF"
    if a[0] == "DECL" and b[0] == "DECL": return "DECL-SAME" if a[1] == b[1] else "DECL-DIFF"
    return "VERDICT-DIFF"
for line in open(sys.argv[1]):
    kind, tag, claimed = line.rstrip("\n").split("\t")[:3]
    src = src_of.get(tag)
    if not src: print(f"{tag}\tNO-SRC"); continue
    s1 = build(tag, src, libs_of(src))
    if not s1: print(f"{tag}\tBUILDFAIL"); continue
    vo, vs = verdict(ORA, s1, tag), verdict(SUB, s1, tag)
    mk = "A->D" if vo[0] == "ACC" and vs[0] != "ACC" else "D->A" if vo[0] != "ACC" and vs[0] == "ACC" else ("DIAG" if vo[0] != "ACC" else ("SAME" if vo == vs else "STREAM"))
    th = twin_of(src); rh = "-"
    if th:
        t1 = build(tag + "_T", th, libs_of(th))
        rh = cls(vs, verdict(SUB, t1, tag + "_T")) if t1 else "TBUILDFAIL"
    tc = build(tag + "_CAT", src, libs_of(src), cat=True)
    rc = cls(vs, verdict(SUB, tc, tag + "_CAT")) if tc else "CATFAIL"
    print(f"{tag}\tclaimed={kind}/{claimed}\tmeasured={mk}\thand={rh}\tcat={rc}\tSUB={vs[0]} {vs[1][:70]}", flush=True)
