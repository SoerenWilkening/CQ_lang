#!/usr/bin/env python3
"""bd vsfp ROUND 3 source mutants — ONLY the new/changed predicates (brief: <=8 + a null).
Same discipline as mutants2.py: apply in the scratch worktree `mutwt3` (a copy of the
round-3 working tree whose base build hashed BIT-IDENTICAL to the subject), anchor found
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
M = V / "mutwt3"
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
    # bd otam — the re-propagate after the store erasure (run() entry point)
    "O1_no_erase_repropagate": (CP, ERASE, "  eraseDeadVolatileScalarStores(M, taint);"),
    # bd otam — the re-propagate after the const-alloca fold
    "O2_no_constfold_repropagate": (CP, ALLOCA, "  foldVolatileConstAllocaLoads(M, taint);"),
    # bd otam — the freshness postcondition alone (a BACKSTOP: expected equivalent)
    "O3_no_postcondition": (TP, POST, "  return false;\n  TaintSet Fresh = propagate(M, wd);\n  const Value *Diff = nullptr;"),
    # bd otam — round 2's behaviour: no re-propagate AND no postcondition (two-site mutant)
    "O4_round2_stale": None,
    # bd stl3 — the global fold's arm fold
    "S1_no_globalfold_armfold": (QL, '  for (auto &[F, Blocks] : Emptied)\n    deleteDeadCones(*F, {}, taint, "volatile-globalfold", Blocks);',
                                 "  (void)Emptied;"),
    # bd stl3 — the condition seed only when no φ remains (round 2's rule)
    "S2_condseed_nophi_only": (DL, "    CondSeeds.push_back(Cond);", "    if (NewIn.empty())\n      CondSeeds.push_back(Cond);"),
    # bd tzfa — no neutralisation (the phantom read stays in the use list)
    "T1_no_neutralise": (SP, "          CB->setArgOperand(A, Constant::getNullValue(Op->getType()));",
                         "          (void)0;"),
    # bd tzfa — never decline an unread quantum operand
    "T2_no_unread_decline": (SP, "    if (userProgramReads(N.Op, *L, taint))\n      continue;",
                             "    (void)L;\n    continue;"),
}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


SUBJECT = sha(V / "bin/cq-opt.r3a")
only = set(sys.argv[1:])
for name, spec in MUT.items():
    if only and name not in only:
        continue
    edits = spec if spec is not None else None
    if name == "O4_round2_stale":
        edits = [(CP, ERASE, "  eraseDeadVolatileScalarStores(M, taint);"),
                 (TP, POST, "  return false;\n  TaintSet Fresh = propagate(M, wd);\n  const Value *Diff = nullptr;")]
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
