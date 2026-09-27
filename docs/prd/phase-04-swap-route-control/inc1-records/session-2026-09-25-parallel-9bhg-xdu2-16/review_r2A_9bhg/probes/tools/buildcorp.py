#!/usr/bin/env python3
import pathlib, subprocess, concurrent.futures as cf, sys
R = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16")
W = pathlib.Path("/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a50057998e957b90e")
L = pathlib.Path("/usr/local/opt/llvm@19/bin")
C = pathlib.Path(__file__).parent / "corp"; C.mkdir(exist_ok=True)
dirs = ["review_r1A_9bhg","review_r1B_9bhg","d88e_probes","review_r1A_d88e","review_r1B_d88e","review_r1A_xdu2_16","review_r1B_xdu2_16","track_8e5r_probes","xdu2_16_probes","probes","review_r2_delta_8e5r"]
jobs = []
for d in dirs:
    for src in sorted((R/d).rglob("*.c")):
        if src.name.endswith(".lib.c"): continue
        tag = d + "__" + "_".join(src.relative_to(R/d).with_suffix("").parts)
        jobs.append((src, tag))
    for ll in sorted((R/d).rglob("*.ll")):
        tag = d + "__LL_" + "_".join(ll.relative_to(R/d).with_suffix("").parts)
        jobs.append((ll, tag))
def run(cmd): return subprocess.run(cmd, capture_output=True, text=True)
def build(job):
    src, tag = job; out = C / f"{tag}.s1.ll"
    if src.suffix == ".ll":
        out.write_text(src.read_text()); return tag, "ll"
    lib = src.with_name(src.name[:-2] + ".lib.c")
    cq = [str(L/"clang"), f"-I{W}/include", "-include", "CQ.h", "-O1", "-emit-llvm", "-S", "-Wno-everything"]
    if lib.exists():
        a = run([str(L/"clang"), "-O1", "-emit-llvm", "-S", "-Wno-everything", str(lib), "-o", str(C/f"{tag}.lib.tmp.ll")])
        b = run(cq + [str(src), "-o", str(C/f"{tag}.caller.tmp.ll")])
        if a.returncode or b.returncode: return tag, "GENFAIL"
        c = run([str(L/"llvm-link"), "-S", str(C/f"{tag}.caller.tmp.ll"), str(C/f"{tag}.lib.tmp.ll"), "-o", str(out)])
        (C/f"{tag}.lib.tmp.ll").unlink(); (C/f"{tag}.caller.tmp.ll").unlink()
        if c.returncode: return tag, "LINKFAIL"
        return tag, "2tu"
    r = run(cq + [str(src), "-o", str(out)])
    if r.returncode: return tag, "GENFAIL"
    return tag, "1tu"
from collections import Counter
cnt = Counter()
with cf.ThreadPoolExecutor(10) as ex:
    for tag, st in ex.map(build, jobs): cnt[st] += 1
print(len(jobs), cnt)
# drop tiny / no-cq modules
keep = []
for p in sorted(C.glob("*.s1.ll")):
    t = p.read_text(errors="ignore")
    if p.stat().st_size < 200 or ("cq_theta" not in t and "cq_measure" not in t and "cq_phi" not in t): continue
    keep.append(str(p))
open(pathlib.Path(__file__).parent / "corp_list.txt", "w").write("\n".join(keep) + "\n")
print("kept", len(keep))
