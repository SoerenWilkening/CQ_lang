#!/usr/bin/env python3
"""bd vsfp ROUND 6 source mutants — ONLY the new/changed predicates (brief: <=8 + a null).
Same discipline as mutants2.py: apply in the scratch worktree `mutwt4` (a copy of the
round-4 working tree whose base build hashed BIT-IDENTICAL to the subject), anchor found
EXACTLY once or abort, bump mtime, build cq-opt AND cq-opt-debugalloc, refuse a mutant whose
binary equals the subject (compiled away / stale), and refuse a null that does NOT."""
import hashlib
import os
import pathlib
import shutil
import subprocess
import sys
import time

V = pathlib.Path(__file__).parent
M = V / "mutwt6"
CP = "ir-pass/src/CQLoweringPass.cpp"
TP = "ir-pass/src/TaintPropagation.cpp"
QL = "ir-pass/src/QramLowering.cpp"
SP = "ir-pass/src/Specialization.cpp"
DL = "ir-pass/src/DeadValueLiveness.cpp"
ERASE = "  if (eraseDeadVolatileScalarStores(M, taint))\n    taint = propagate(M, wd);"
ALLOCA = "  if (foldVolatileConstAllocaLoads(M, taint))\n    taint = propagate(M, wd);"
POST = "  TaintSet Fresh = propagate(M, wd);\n  const Value *Diff = nullptr;"

AL = "ir-pass/src/ArithLowering.cpp"
RL = "ir-pass/src/RotationLowering.cpp"
MUT = {
    "N0_null": (SP, "bool resolvePhantomCloneArgReads(Module &M, const TaintSet &taint) {",
                "bool resolvePhantomCloneArgReads(Module &M, const TaintSet &taint) { /* null */"),
    # bd w7nm — the liveness/rewrite slot question back to the drop's WHOLE eligibility (round 5)
    "W1_policy_in_liveness": (DL, "  return isRecordedDeadSlot(CB, ArgNo, taint) && nullSafeSlot(CB, ArgNo);",
                              "  return isRecordedDeadSlot(CB, ArgNo, taint) && dropEligibleSlot(CB, ArgNo);"),
    # Rule 14 — M-C (d0) and M-A back to the bare record (round 5)
    "W2_bare_record_consumers": None,
}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


SUBJECT = sha(V / "bin/cq-opt.r6a")
only = set(sys.argv[1:])
for name, spec in MUT.items():
    if only and name not in only:
        continue
    edits = spec if spec is not None else None
    if name == "W2_bare_record_consumers":
        edits = [(AL, "      if (!isRewritableDeadSlot(*CI, A, taint)) {", "      if (!isRecordedDeadSlot(*CI, A, taint)) {"),
                 (RL, "    if (!isRewritableDeadSlot(*CI, K, taint))", "    if (!isRecordedDeadSlot(*CI, K, taint))")]
    elif name == "U1_raw_seeds":
        edits = [(DL, "  SmallVector<WeakTrackingVH, 4> CondSeeds;", "  SmallVector<Value *, 4> CondSeeds;"),
                 (DL, "  for (WeakTrackingVH &H : CondSeeds)", "  for (Value *H : CondSeeds)")]
    elif name == "U2_weakvh_seeds":
        edits = [(DL, "  SmallVector<WeakTrackingVH, 4> CondSeeds;", "  SmallVector<WeakVH, 4> CondSeeds;"),
                 (DL, "  for (WeakTrackingVH &H : CondSeeds)", "  for (WeakVH &H : CondSeeds)")]
    else:
        edits = [edits]
    origs = {}
    try:
        for rel, old, new in edits:
            p = M / rel
            orig = origs.setdefault(rel, p.read_text())
            cur = p.read_text()
            n = cur.count(old)
            if n != 1:
                raise SystemExit(f"{name}: anchor found {n} times in {rel} — refusing to build")
            p.write_text(cur.replace(old, new, 1))
            t = time.time() + 5
            os.utime(p, (t, t))
        r = subprocess.run(["cmake", "--build", str(M / "build"), "-j8", "--target", "cq-opt", "cq-opt-debugalloc"],
                           capture_output=True, text=True)
        if r.returncode:
            print(f"{name}: BUILD FAILED\n{r.stdout[-2000:]}{r.stderr[-2000:]}")
            continue
        h = sha(M / "build/ir-pass/cq-opt")
        if name != "N0_null" and h == SUBJECT:
            print(f"{name}: IDENTICAL-BINARY {h} — compiled away or STALE; not copied", flush=True)
            continue
        if name == "N0_null" and h != SUBJECT:
            raise SystemExit(f"N0_null: {h} != subject {SUBJECT} — the null control FAILED")
        hd = sha(M / "build/ir-pass/cq-opt-debugalloc")
        shutil.copy(M / "build/ir-pass/cq-opt", V / "bin" / f"cq-opt.{name}")
        shutil.copy(M / "build/ir-pass/cq-opt-debugalloc", V / "bin" / f"cq-opt-debugalloc.{name}")
        print(f"{name}: built {h} debugalloc {hd}", flush=True)
    finally:
        for rel, orig in origs.items():
            p = M / rel
            p.write_text(orig)
            t2 = time.time() + 10
            os.utime(p, (t2, t2))
