#!/usr/bin/env python3
"""Post-merge battery for bd 9bhg (merged with main ba80bda1 = bd d88e).

Modules:
  * r1A's full probe set (review_r1A_9bhg/probes/src/*.c; a <b>.lib.c beside a
    <b>.c makes it 2-TU, llvm-linked; otherwise single TU) — exactly r1A's gen.sh;
  * the hand-inlined TWIN <b>T of every spec-classical caller <b>C, built with
    d88e's own mktwins.sh rule (`int t = h(q, m);` -> `int t = m + 1;`,
    `int t2 = h(q, m + 2);` -> `int t2 = m + 3;`, drop the `h` prototype); a twin
    that still calls `h` is reported and not used;
  * TRACK_9BHG's own 31-probe battery (scratchpad/p9/*.s1.ll, prebuilt).

Binaries (frozen copies; nothing here is ever rebuilt):
  sub    cq-opt.new3        8b837d1f  (commit 30529716, 9bhg alone)
  main   cq-opt.main_ba80   e587c191  (main ba80bda1 = d88e + xdu2.16)
  merged cq-opt.merged      242f8b61  (e4adabad, 9bhg merged with main)
  ora    cq-opt.main983     438c77bf  (983f9361)
  pre    cq-opt.preE        63e2f0bb  (aad63450)

Null controls FIRST: sub, main and merged each run TWICE over the whole module
list; any (exit, stdout-sha, stderr-sha) difference between the two runs of one
binary is reported as FLAKY with its denominator. Then movers merged-vs-sub and
merged-vs-main, classified A->D / D->A / DIAG / STREAM, and the twin table on
merged (twincmp.sh's rule: both decline -> stderr byte-identical; both accept ->
link and diff traces under args "5 7" and "2 9").
"""
import hashlib
import pathlib
import re
import shutil
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor

S = pathlib.Path("/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/"
                 "d2ac97c1-732d-4a6e-83a0-786b16babcc6/scratchpad")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
                 "agent-a50057998e957b90e")
R1A = W / ("docs/prd/phase-04-swap-route-control/inc1-records/"
           "session-2026-09-25-parallel-9bhg-xdu2-16/review_r1A_9bhg/probes/src")
P = S / "merge13" / "p"
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
RT = W / "build/runtime/libcq_runtime.a"
TPL = W / "build/runtime/libcq_templates.a"
BINS = {
    "sub": S / "frozen/cq-opt.new3",
    "main": S / "frozen/cq-opt.main_c113",
    "merged": S / "frozen/cq-opt.m12",
    "prev": S / "frozen/cq-opt.final",
    "ora": S / "frozen/cq-opt.main983",
    "pre": S / "frozen/cq-opt.preE",
}
P.mkdir(parents=True, exist_ok=True)


def sh(cmd, **kw):
    return subprocess.run(cmd, capture_output=True, text=True, **kw)


# ---- build r1A modules + twins -------------------------------------------------
def build(src):
    b = src.name[:-2]
    lib = src.with_name(b + ".lib.c")
    out = P / f"{b}.s1.ll"
    cq = [str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S"]
    if lib.exists():
        r1 = sh([str(L / "clang"), "-O1", "-emit-llvm", "-S", str(lib), "-o", str(P / f"{b}.lib.ll")])
        r2 = sh(cq + [str(src), "-o", str(P / f"{b}.caller.ll")])
        if r1.returncode or r2.returncode:
            return b, "GENFAIL"
        r3 = sh([str(L / "llvm-link"), "-S", str(P / f"{b}.caller.ll"), str(P / f"{b}.lib.ll"),
                 "-o", str(out)])
        if r3.returncode:
            return b, "GENFAIL-link"
    else:
        r = sh(cq + [str(src), "-o", str(out)])
        if r.returncode:
            return b, "GENFAIL"
    if out.stat().st_size < 200:
        return b, "TINY"
    return b, "ok"


srcs = sorted(s for s in R1A.glob("*.c") if not s.name.endswith(".lib.c")
              and s.name not in ("libC.c", "libQ.c"))
# twins, d88e's mktwins.sh rule
twins = []
twin_warn = []
for s in srcs:
    if not re.fullmatch(r"[a-z]+\d+C\.c", s.name):
        continue
    base = s.name[:-3]
    txt = s.read_text()
    t = txt.replace("int t = h(q, m);", "int t = m + 1;").replace(
        "int t2 = h(q, m + 2);", "int t2 = m + 3;")
    t = "\n".join(l for l in t.splitlines() if l.strip() != "int h(int a, int k);") + "\n"
    if "h(q" in t or re.search(r"\bh\(", t):
        twin_warn.append(base)
        continue
    tp = P / f"{base}T.c"
    tp.write_text(t)
    twins.append(base)
with ThreadPoolExecutor(8) as ex:
    gen = list(ex.map(build, srcs + [P / f"{b}T.c" for b in twins]))
bad = [(b, st) for b, st in gen if st != "ok"]
mods = [b for b, st in gen if st == "ok"]
# TRACK_9BHG's battery (prebuilt in p9)
own = ["rt1", "rt2", "rt3", "rq1", "rq2", "rx1", "ya", "yb", "yc", "yo", "ob1", "ob2", "ob3",
       "ob4", "ob5", "ob6", "ob7", "ob8", "ob9", "rp1", "rq3", "rfc", "rfq", "r65", "r65c",
       "rloop", "rsel", "rs1", "rm2", "fp2", "fp3"]
for o in own:
    shutil.copyfile(S / "p9" / f"{o}.s1.ll", P / f"own_{o}.s1.ll")
mods += [f"own_{o}" for o in own]
print(f"modules: {len(mods)} ({len(srcs)} r1A sources, {len(twins)} twins built, "
      f"{len(own)} own); build failures: {len(bad)} {bad[:8]}")
print(f"twins NOT derivable by the sed rule (still call h): {len(twin_warn)}: {' '.join(twin_warn)}")


# ---- run -----------------------------------------------------------------------
def run(tag, m, rep):
    r = subprocess.run([str(BINS[tag]), "-passes=cq-lowering", "-S", str(P / f"{m}.s1.ll"),
                        "-o", "-"], capture_output=True)
    out = r.stdout
    if rep == 0:
        (P / f"{m}.{tag}.s2.ll").write_bytes(out)
        (P / f"{m}.{tag}.err").write_bytes(r.stderr)
    err = ""
    for l in r.stderr.decode(errors="replace").splitlines():
        if "error:" in l:
            err = l.split("error:", 1)[1].strip()
            break
    return (r.returncode, hashlib.sha256(out).hexdigest()[:16],
            hashlib.sha256(r.stderr).hexdigest()[:16], err)


def sweep(tag, rep):
    with ThreadPoolExecutor(8) as ex:
        return dict(zip(mods, ex.map(lambda m: run(tag, m, rep), mods)))


res = {}
print("\n## null controls (each binary twice over the full list)")
for tag in ("sub", "main", "merged"):
    a = sweep(tag, 0)
    b = sweep(tag, 1)
    flaky = [m for m in mods if a[m] != b[m]]
    print(f"  {tag:6} run1 vs run2: {len(flaky)} of {len(mods)} differ {flaky}")
    res[tag] = a
for tag in ("ora", "pre", "prev"):
    res[tag] = sweep(tag, 0)


def cls(r, n):
    if r == n:
        return None
    if r[0] == 0 and n[0] != 0:
        return "A->D"
    if r[0] != 0 and n[0] == 0:
        return "D->A"
    if r[0] == 0 and n[0] == 0:
        return "STREAM" if r[1] != n[1] else "STDERR"
    return "DIAG" if r[3] != n[3] else "OTHER"


for ref in ("sub", "main", "prev"):
    mv = [(m, cls(res[ref][m], res["merged"][m])) for m in mods if cls(res[ref][m], res["merged"][m])]
    counts = {}
    for _, k in mv:
        counts[k] = counts.get(k, 0) + 1
    print(f"\n## movers merged vs {ref}: {len(mv)} of {len(mods)}  {counts}")
    for m, k in mv:
        print(f"  {k:6} {m}: {ref} rc={res[ref][m][0]} [{res[ref][m][3][:90]}]  ->  "
              f"merged rc={res['merged'][m][0]} [{res['merged'][m][3][:90]}]")


# ---- twins on merged -------------------------------------------------------------
def trace(tag, m, args):
    exe = P / f"{m}.{tag}.exe"
    if not exe.exists():
        r = sh([str(L / "clang"), str(P / f"{m}.{tag}.s2.ll"), str(TPL), str(RT), "-o", str(exe)])
        if r.returncode:
            return None
    r = subprocess.run([str(exe)] + args.split(), capture_output=True, text=True)
    return r.returncode, r.stdout


def twin(tag, b):
    c, t = res[tag][f"{b}C"], res[tag][f"{b}T"]
    if c[0] and t[0]:
        same = (P / f"{b}C.{tag}.err").read_bytes() == (P / f"{b}T.{tag}.err").read_bytes()
        return "DECL-SAME" if same else "DECL-DIFF"
    if not c[0] and not t[0]:
        for args in ("5 7", "2 9"):
            tc, tt = trace(tag, f"{b}C", args), trace(tag, f"{b}T", args)
            if tc is None or tt is None or tc != tt:
                return "ACC-DIFF"
        return "ACC-SAME"
    return f"VERDICT-DIFF(C rc={c[0]}, T rc={t[0]})"


print(f"\n## twin table (merged; also sub and main for the same pair)")
tw = {}
for b in twins:
    if f"{b}C" in mods and f"{b}T" in mods:
        tw[b] = {tag: twin(tag, b) for tag in ("merged", "sub", "main")}
for b, v in tw.items():
    print(f"  {b:6} merged={v['merged']:30} sub={v['sub']:30} main={v['main']}")
n = len(tw)
print(f"  denominator {n} pairs; twin-identical: merged "
      f"{sum(v['merged'] in ('DECL-SAME', 'ACC-SAME') for v in tw.values())}, sub "
      f"{sum(v['sub'] in ('DECL-SAME', 'ACC-SAME') for v in tw.values())}, main "
      f"{sum(v['main'] in ('DECL-SAME', 'ACC-SAME') for v in tw.values())}")

# ---- measure census on accepts ---------------------------------------------------
print("\n## cq_measure census (source calls vs cqrt_measure in the merged lowered IR, accepts only)")
for m in mods:
    if res["merged"][m][0]:
        continue
    s1 = (P / f"{m}.s1.ll").read_text()
    s2 = (P / f"{m}.merged.s2.ll").read_text()
    n_src = len(re.findall(r"call \S+ @cq_measure_\w+\(", s1))
    n_out = len(re.findall(r"call \S+ @cqrt_measure_\w+\(", s2))
    if n_src != n_out:
        print(f"  {m}: source {n_src} cq_measure, lowered {n_out} cqrt_measure")
print("done")
