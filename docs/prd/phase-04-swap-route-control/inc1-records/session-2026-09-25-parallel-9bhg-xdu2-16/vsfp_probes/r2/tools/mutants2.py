#!/usr/bin/env python3
"""bd vsfp ROUND 2 source mutants. Build each mutant's cq-opt in the scratch worktree
`mutwt2` (a copy of the round-2 working tree), one at a time: apply -> BUMP MTIME ->
build cq-opt -> hash -> copy -> restore -> bump again. A mutant whose `old` text is
not found EXACTLY ONCE aborts (a harness that applies nothing reports about the
unmutated binary, L10); a mutant whose binary hashes equal to the base aborts too
(the round-1 stale-object trap: make's 1-second mtime resolution)."""
import hashlib
import os
import pathlib
import shutil
import subprocess
import sys
import time

V = pathlib.Path(__file__).parent
M = V / "mutwt2"
SD = "ir-pass/src/SpecializeDetect.cpp"
DL = "ir-pass/src/DeadValueLiveness.cpp"
QL = "ir-pass/src/QramLowering.cpp"
CP = "ir-pass/src/CQLoweringPass.cpp"
SP = "ir-pass/src/Specialization.cpp"
AL = "ir-pass/src/ArithLowering.cpp"

MUT = {
    "N0_null": (SD, "bool dropDeadCallArguments(Module &M, const TaintSet &taint) {",
                "bool dropDeadCallArguments(Module &M, const TaintSet &taint) { /* null */"),
    # --- the drop ---
    "R1_drop_off": (SD, "  SmallPtrSet<const CallInst *, 16> Intrinsics = intrinsicSites(taint);\n  bool Changed = false;",
                    "  return false;\n  SmallPtrSet<const CallInst *, 16> Intrinsics = intrinsicSites(taint);\n  bool Changed = false;"),
    "R2_no_fixpoint": (SD, "        Seeds[CI->getFunction()].push_back(Op);\n        Changed = Again = true;",
                       "        Seeds[CI->getFunction()].push_back(Op);\n        Changed = true;"),
    "R3_constants_too": (SD, "        if (isa<Constant>(Op))\n          continue;\n        Argument *P", "        Argument *P"),
    "R4_all_args_dead": (SD, "      const uint64_t Mask = It->second;", "      const uint64_t Mask = ~uint64_t(0); (void)It;"),
    "R5_use_empty_mask": (SD, "      const uint64_t Mask = It->second;",
                          "      uint64_t Mask = 0; (void)It;\n      for (Argument &Ar : Callee->args()) if (Ar.getArgNo() < 64 && Ar.use_empty()) Mask |= uint64_t(1) << Ar.getArgNo();"),
    "R6_naked_too": (SD, "         !F->hasFnAttribute(Attribute::Naked) && !F->isVarArg();", "         !F->isVarArg();"),
    "R7_musttail_too": (SD, "      if (!dropEligibleCallee(Callee) || CI->isMustTailCall() ||", "      if (!dropEligibleCallee(Callee) ||"),
    "R12_varargs_too": (SD, "         !F->hasFnAttribute(Attribute::Naked) && !F->isVarArg();", "         !F->hasFnAttribute(Attribute::Naked);"),
    "R8_no_attr_strip": (SD, "          Callee->removeParamAttr(A, K);\n          CI->removeParamAttr(A, K);", "          (void)K;"),
    "R9_no_intrinsic_skip": (SD, "          if (auto *CI = dyn_cast<CallInst>(&I); CI && !Intrinsics.count(CI))\n            Sites.push_back(CI);",
                             "          if (auto *CI = dyn_cast<CallInst>(&I); CI)\n            Sites.push_back(CI);"),
    "R10_no_deadcall_seeds": (SD, "              Seeds[&F].push_back(CI);", "              (void)CI;"),
    "R11_no_slotB": (CP, "  // bd `test_C_libtooling-vsfp` round 2 — THE DEAD CALL-ARGUMENT DROP, SLOT B.",
                     "  if (false) // SLOTB-MUTANT: the next statement (slot B) is skipped\n  // bd `test_C_libtooling-vsfp` round 2 — THE DEAD CALL-ARGUMENT DROP, SLOT B."),
    # --- the liveness predicate ---
    "L1_calls_always_roots": (DL, "  if (I.isTerminator() || I.isEHPad())\n    return true;",
                              "  if (I.isTerminator() || I.isEHPad() || isa<CallBase>(I))\n    return true;"),
    "L2_no_frontend_membership": (DL, "    if (isFrontEndIntrinsicSite(*CB, taint))\n      return true;\n", "    (void)0;\n"),
    "L3_no_clone_root": (DL, "      if (taint.SpecHandleArgMask.count(Callee))\n        return true;", "      (void)Callee;"),
    "L4_no_body_purity": (DL, "    return !Callee || !isa<CallInst>(CB) || !bodyIsSideEffectFree(*Callee);",
                          "    (void)Callee; (void)CB;\n    return true;"),
    "L10_no_reserved_name": (DL, '      if (N.starts_with("cq_") || N.starts_with("__cq_") || N.starts_with("cqrt_"))\n        return true;',
                             "      (void)N;"),
    "L11_no_identity_roots": (DL, "  if (const auto *CB = dyn_cast<CallBase>(&I)) {\n    // ROOTS BY IDENTITY",
                              "  if (const auto *CB = dyn_cast<CallBase>(&I); CB && false) {\n    // ROOTS BY IDENTITY"),
    "L5_loops_pure": (DL, "  if (!BackEdges.empty())\n    return false;", "  (void)BackEdges;"),
    "L6_no_recorded_dead_slot": (DL, "  return (It->second >> ArgNo) & 1;", "  return false;"),
    "L7_no_fold": (DL, "    if (!S0 || S0 != S1 || S0 == P)\n      continue;", "    continue;\n    if (!S0 || S0 != S1 || S0 == P)\n      continue;"),
    "L8_no_phi_fold": (DL, "    if (HasPhi) {", "    if (HasPhi) continue;\n    if (HasPhi) {"),
    "L9_no_block_merge": (DL, "        MergeBlockIntoPredecessor(S);", "        (void)S;"),
    # --- the fenv stages ---
    "V1_no_erase_cone": (QL, '      deleteDeadCones(F, Stored, taint, "volatile-erase", Emptied);', "      (void)Stored;"),
    "V2_no_promote_cone": (QL, '    deleteDeadCones(F, Stored, taint, "volatile-promote", Emptied);', "    (void)Stored; (void)Emptied;"),
    "V3_no_constfold_arm": (QL, '      deleteDeadCones(F, {}, taint, "volatile-constfold", Emptied);', "      (void)Emptied;"),
    "V4_erase_arm_untouched": (QL, '      deleteDeadCones(F, Stored, taint, "volatile-erase", Emptied);', '      deleteDeadCones(F, Stored, taint, "volatile-erase");'),
    # --- the backstop ---
    "B1_backstop_off": (SP, "bool declinePhantomCloneArgReads(Module &M, const TaintSet &taint) {\n",
                        "bool declinePhantomCloneArgReads(Module &M, const TaintSet &taint) {\n  return false;\n"),
    "B2_no_theta_exempt": (SP, "              OpCI && taint.ThetaCalls.contains(OpCI))", "              OpCI && false)"),
    "B3_no_keeper_check": (SP, "          if (keptAliveElsewhere(Op, *L, taint))", "          if (false)"),
    "B4_ignore_quantum": (SP, "          if (isa<Constant>(Op) || !isQuantumCallerValue(Op, taint))", "          if (isa<Constant>(Op))"),
    "B5_scan_clone_bodies": (SP, "    if (F.isDeclaration() || taint.SpecHandleArgMask.count(&F))", "    if (F.isDeclaration())"),
    "B6_no_record": (SP, "  taint.SpecDeadArgMask[Clone] = deadParamMask(*Clone, taint);", "  (void)0;"),
    # --- M-C arm (d0) ---
    "D1_d0_off": (AL, "    if (PassesP && !ReadsP)\n      return true;\n  }\n\n  // (d) — a producer", "    (void)ReadsP; (void)PassesP;\n  }\n\n  // (d) — a producer"),
    "D2_d0_any_slot": (AL, "      if (!isRecordedDeadSlot(*CI, A, taint)) {", "      if (false) {"),
}


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


SUBJECT = sha(V / "bin/cq-opt.r2g")
only = set(sys.argv[1:])
base = None
for name, (rel, old, new) in MUT.items():
    if only and name not in only:
        continue
    p = M / rel
    orig = p.read_text()
    n = orig.count(old)
    if n != 1:
        raise SystemExit(f"{name}: anchor found {n} times in {rel} — refusing to build")
    p.write_text(orig.replace(old, new, 1))
    t = time.time() + 5
    os.utime(p, (t, t))
    try:
        r = subprocess.run(["cmake", "--build", str(M / "build"), "-j8", "--target", "cq-opt", "cq-opt-debugalloc"],
                           capture_output=True, text=True)
        if r.returncode:
            print(f"{name}: BUILD FAILED\n{r.stdout[-2000:]}{r.stderr[-2000:]}")
            continue
        h = sha(M / "build/ir-pass/cq-opt")
        if name != "N0_null" and h == SUBJECT:
            print(f"{name}: IDENTICAL-BINARY {h} — the mutation compiled away (equivalent by construction) or the object is STALE; not copied", flush=True)
            continue
        if name == "N0_null" and h != SUBJECT:
            raise SystemExit(f"N0_null: {h} != subject {SUBJECT} — the null control FAILED; the matrix would measure the wrong base")
        hd = sha(M / "build/ir-pass/cq-opt-debugalloc")
        shutil.copy(M / "build/ir-pass/cq-opt", V / "bin" / f"cq-opt.{name}")
        # The MUTANT's own debugalloc driver (it links cq-opt's objects), so the five
        # `%debugalloc-cq-opt` fixtures test the mutant too, not the subject.
        shutil.copy(M / "build/ir-pass/cq-opt-debugalloc", V / "bin" / f"cq-opt-debugalloc.{name}")
        print(f"{name}: built {h} debugalloc {hd}", flush=True)
    finally:
        p.write_text(orig)
        t2 = time.time() + 10
        os.utime(p, (t2, t2))
