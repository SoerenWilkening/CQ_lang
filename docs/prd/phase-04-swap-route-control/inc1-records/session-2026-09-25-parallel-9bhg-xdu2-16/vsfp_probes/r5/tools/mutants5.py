#!/usr/bin/env python3
"""bd vsfp ROUND 5 source mutants — ONLY the new/changed predicates (brief: <=8 + a null).
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
M = V / "mutwt5"
CP = "ir-pass/src/CQLoweringPass.cpp"
TP = "ir-pass/src/TaintPropagation.cpp"
QL = "ir-pass/src/QramLowering.cpp"
SP = "ir-pass/src/Specialization.cpp"
DL = "ir-pass/src/DeadValueLiveness.cpp"
ERASE = "  if (eraseDeadVolatileScalarStores(M, taint))\n    taint = propagate(M, wd);"
ALLOCA = "  if (foldVolatileConstAllocaLoads(M, taint))\n    taint = propagate(M, wd);"
POST = "  TaintSet Fresh = propagate(M, wd);\n  const Value *Diff = nullptr;"

MUT = {
    "N0_null": (SP, "bool resolvePhantomCloneArgReads(Module &M, const TaintSet &taint) {",
                "bool resolvePhantomCloneArgReads(Module &M, const TaintSet &taint) { /* null */"),
    # bd 91k9 — the drop's slot eligibility inside the one rewrite (and the liveness call-slot rule)
    "E1_no_slot_eligibility": (DL, "  return isRecordedDeadSlot(CB, ArgNo, taint) && dropEligibleSlot(CB, ArgNo);",
                               "  return isRecordedDeadSlot(CB, ArgNo, taint);"),
    # bd 91k9 — decline a QUANTUM operand in an ineligible slot (else keep it silently)
    "E2_no_ineligible_decline": (SP, "            if (!isQuantumCallerValue(Op, taint))\n              continue;\n            F.getContext().diagnose(DiagnosticInfoUnsupported(\n                F, kMsgPhantomArgRead, CB->getDebugLoc()));\n            return true;",
                                 "            continue;"),
    # bd qce6 — the implicit (#pragma clang section) section
    "Q1_no_implicit_section": (QL, "    if (G.hasSection() || G.hasImplicitSection() || G.isAbsoluteSymbolRef() ||",
                               "    if (G.hasSection() || G.isAbsoluteSymbolRef() ||"),
    # owner decision 2026-09-27 — the non-default address space
    "A1_no_addrspace": (QL, "    if (G.hasSection() || G.hasImplicitSection() || G.isAbsoluteSymbolRef() ||\n        G.getAddressSpace() != 0)",
                        "    if (G.hasSection() || G.hasImplicitSection() || G.isAbsoluteSymbolRef())"),
}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


SUBJECT = sha(V / "bin/cq-opt.r5a")
only = set(sys.argv[1:])
for name, spec in MUT.items():
    if only and name not in only:
        continue
    edits = spec if spec is not None else None
    if name == "U1_raw_seeds":
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
