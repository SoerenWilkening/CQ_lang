#!/usr/bin/env python3
"""bd vsfp ROUND 4 source mutants — ONLY the new/changed predicates (brief: <=8 + a null).
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
M = V / "mutwt4"
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
    # bd 1xp9 — the condition seeds back to RAW pointers (round 3's code)
    "U1_raw_seeds": None,
    # bd 1xp9 — WeakVH instead of WeakTrackingVH (a nulled seed is skipped, not followed)
    "U2_weakvh_seeds": None,
    # round 4 — no folder on the two-entry-phi fold (always a new select)
    "U3_no_simplify": (DL, "      Value *NV = VT == VF ? VT\n                           : simplifySelectInst(Cond, VT, VF,\n                                                SimplifyQuery(F.getParent()->getDataLayout()));",
                       "      Value *NV = VT == VF ? VT : nullptr;"),
    # bd f061 — the neutralising constant takes the OPERAND's type (round 3)
    "F1_operand_type": (DL, "  Type *SlotTy = A < FT->getNumParams() ? FT->getParamType(A) : U.get()->getType();",
                        "  Type *SlotTy = U.get()->getType(); (void)FT;"),
    # bd sqjq — no dead-cone deletion after the record
    "Q1_no_clone_dead_cone": (SP, '      deleteDeadCones(*Clone, DeadUsers, taint, "clone-dead-slot");', "      (void)DeadUsers;"),
    # bd xh17 — every cqrt_copy slot counts as construction (round 3's rule, slot-blind)
    "X1_copy_any_slot": (SP, "  return CB->getArgOperandNo(&U) + 1 == CB->arg_size();", "  return true;"),
    # owner ruling — no named-section conjunct
    "S1_no_section": (QL, "    if (G.hasSection() || G.isAbsoluteSymbolRef() ||", "    if (G.isAbsoluteSymbolRef() ||"),
    # owner ruling — no absolute-address conjunct
    "S2_no_absolute": (QL, "    if (G.hasSection() || G.isAbsoluteSymbolRef() ||\n        G.getMetadata(LLVMContext::MD_absolute_symbol))",
                       "    if (G.hasSection())"),
}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


SUBJECT = sha(V / "bin/cq-opt.r4f")
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
