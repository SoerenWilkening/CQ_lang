#!/usr/bin/env python3
"""Build stage-1 modules for EVERY probe directory under the session record dir
(every review_* dir, probes/, d88e_probes/, track_8e5r_probes/, xdu2_16_probes/,
vsfp_probes/): each <n>.c (plus <n>.lib.c if present, llvm-linked as
run_slice_multi.sh does) and each committed .ll. r2A's buildcorp.py recipe,
extended to every dir that exists at the vsfp merge. Writes corp/<tag>.s1.ll and
corp_list.txt (modules that contain a cq_* call and are not tiny), and
twins.tsv: for every module <tag> whose source has a sibling hand-inlined twin
(<stem>T.c, or <stem-minus-C/Q>T.c), the twin's tag."""
import pathlib, subprocess, concurrent.futures as cf
from collections import Counter

R = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/"
                 "agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/"
                 "session-2026-09-25-parallel-9bhg-xdu2-16")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
H = pathlib.Path(__file__).parent
C = H / "corp"
C.mkdir(exist_ok=True)
dirs = sorted(d.name for d in R.iterdir() if d.is_dir())
jobs = []
for d in dirs:
    for src in sorted((R / d).rglob("*.c")):
        if src.name.endswith(".lib.c"):
            continue
        tag = d + "__" + "_".join(src.relative_to(R / d).with_suffix("").parts)
        jobs.append((src, tag))
    for ll in sorted((R / d).rglob("*.ll")):
        tag = d + "__LL_" + "_".join(ll.relative_to(R / d).with_suffix("").parts)
        jobs.append((ll, tag))


def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def build(job):
    src, tag = job
    out = C / f"{tag}.s1.ll"
    if src.suffix == ".ll":
        out.write_text(src.read_text(errors="replace"))
        return tag, "ll"
    lib = src.with_name(src.name[:-2] + ".lib.c")
    if not lib.exists():
        # a SHARED library TU in the same directory (r2B's lib.c/libf.c, r1B's
        # battery/l3oi/lib.c, d88e's and r1A's libC/libQ/libT, my own probes' lib.c):
        # without it the module declines at "unknown callee" on every binary and the
        # A/B measures nothing (first build of this corpus did exactly that).
        stem = src.name[:-2]
        cands = []
        if stem[-1:] in ("C", "Q", "T"):
            cands.append(src.with_name("lib" + stem[-1] + ".c"))
        if stem.startswith(("FA", "FB")):
            cands.append(src.with_name("libf.c"))
        cands.append(src.with_name("lib.c"))
        lib = next((c for c in cands if c.exists()), lib)
    cq = [str(L / "clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S",
          "-Wno-everything"]
    if lib.exists():
        a = run([str(L / "clang"), "-O1", "-emit-llvm", "-S", "-Wno-everything", str(lib), "-o",
                 str(C / f"{tag}.lib.tmp.ll")])
        b = run(cq + [str(src), "-o", str(C / f"{tag}.caller.tmp.ll")])
        if a.returncode or b.returncode:
            return tag, "GENFAIL"
        c = run([str(L / "llvm-link"), "-S", str(C / f"{tag}.caller.tmp.ll"),
                 str(C / f"{tag}.lib.tmp.ll"), "-o", str(out)])
        (C / f"{tag}.lib.tmp.ll").unlink()
        (C / f"{tag}.caller.tmp.ll").unlink()
        if not c.returncode:
            return tag, "2tu"
        # the caller defines a symbol the shared lib also defines (a self-contained
        # probe that happens to sit beside a shared lib.c): build it single-TU.
        r = run(cq + [str(src), "-o", str(out)])
        return tag, ("GENFAIL" if r.returncode else "1tu-fallback")
    r = run(cq + [str(src), "-o", str(out)])
    return tag, ("GENFAIL" if r.returncode else "1tu")


cnt = Counter()
with cf.ThreadPoolExecutor(10) as ex:
    for tag, st in ex.map(build, jobs):
        cnt[st] += 1
print(f"{len(dirs)} dirs, {len(jobs)} jobs: {dict(cnt)}")
keep = []
for p in sorted(C.glob("*.s1.ll")):
    t = p.read_text(errors="ignore")
    if p.stat().st_size < 200 or ("cq_theta" not in t and "cq_measure" not in t
                                  and "cq_phi" not in t):
        continue
    keep.append(str(p))
(H / "corp_list.txt").write_text("\n".join(keep) + "\n")
print("kept", len(keep))
# twins
tags = {pathlib.Path(k).name[: -len(".s1.ll")] for k in keep}
tw = []
for src, tag in jobs:
    if src.suffix != ".c" or tag not in tags:
        continue
    stem = src.name[:-2]
    cands = [stem + "T"]
    if stem[-1:] in ("C", "Q"):
        cands.append(stem[:-1] + "T")
    for c in cands:
        t = src.with_name(c + ".c")
        if t.exists() and c != stem:
            ttag = tag[: len(tag) - len(stem)] + c
            if ttag in tags:
                tw.append((tag, ttag))
            break
(H / "twins.tsv").write_text("".join(f"{a}\t{b}\n" for a, b in tw))
print("twin pairs", len(tw))
