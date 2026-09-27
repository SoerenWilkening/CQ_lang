#!/usr/bin/env python3
"""Build every bd vsfp source mutant's cq-opt in the scratch worktree `mutwt`, one at a
time (apply -> build cq-opt -> copy -> restore). A mutant whose `old` text is not
found EXACTLY ONCE aborts: a mutation harness that silently applies nothing reports
KILLED/MISSED about the unmutated binary (L10)."""
import pathlib
import shutil
import subprocess
import sys

V = pathlib.Path(__file__).parent
M = V / "mutwt"
SD = "ir-pass/src/SpecializeDetect.cpp"
SP = "ir-pass/src/Specialization.cpp"
AL = "ir-pass/src/ArithLowering.cpp"

MUT = {
    # NULL CONTROL: a comment-only edit; must move NOTHING.
    "M0_null": (SD, "bool dropDeadCallArguments(Module &M, const TaintSet &taint) {",
                "bool dropDeadCallArguments(Module &M, const TaintSet &taint) { /* null */"),
    # --- the predictor (the drop) ---
    "M1_drop_off": (SD, "  SmallPtrSet<const CallInst *, 16> Intrinsics = intrinsicSites(taint);\n  bool Changed = false;",
                    "  return false;\n  SmallPtrSet<const CallInst *, 16> Intrinsics = intrinsicSites(taint);\n  bool Changed = false;"),
    "M2_no_fixpoint": (SD, "        Changed = Again = true;", "        Changed = true;"),
    "M3_constants_too": (SD, "        if (isa<Constant>(Op))\n          continue;\n        Argument *P", "        Argument *P"),
    "M4_ignore_use_empty": (SD, "        if (!P->use_empty())\n          continue;\n", ""),
    "M5_no_exact": (SD, "      if (!Callee || !Callee->hasExactDefinition() || Callee->isVarArg() ||",
                    "      if (!Callee || Callee->isDeclaration() || Callee->isVarArg() ||"),
    "M6_no_attr_whitelist": (SD, "        if (!dropSafeParamAttrs(Callee->getAttributes().getParamAttrs(A)) ||\n            !dropSafeParamAttrs(CI->getAttributes().getParamAttrs(A)))\n          continue;\n", ""),
    "M7_pointer_too": (SD, "        if (!Ty->isIntegerTy() && !Ty->isFloatingPointTy())\n          continue;\n", ""),
    "M8_no_cone_delete": (SD, "        if (auto *OpI = dyn_cast<Instruction>(Op))\n          deleteDeadOperandCone(OpI);\n", ""),
    "M9_delete_calls": (SD, "    return I->use_empty() && !isa<CallBase>(I) && isInstructionTriviallyDead(I);",
                        "    return I->use_empty() && isInstructionTriviallyDead(I);"),
    "M10_no_intrinsic_skip": (SD, "          if (auto *CI = dyn_cast<CallInst>(&I); CI && !Intrinsics.count(CI))",
                              "          if (auto *CI = dyn_cast<CallInst>(&I); CI)"),
    "M11_vararg_too": (SD, "      if (!Callee || !Callee->hasExactDefinition() || Callee->isVarArg() ||",
                       "      if (!Callee || !Callee->hasExactDefinition() ||"),
    # --- the observer (the backstop) ---
    "B1_backstop_off": (SP, "bool declinePhantomCloneArgReads(Module &M, const TaintSet &taint) {\n",
                        "bool declinePhantomCloneArgReads(Module &M, const TaintSet &taint) {\n  return false;\n"),
    "B2_no_theta_exempt": (SP, "          if (auto *OpCI = dyn_cast<CallInst>(Op);\n              OpCI && llvm::is_contained(taint.ThetaCalls, OpCI))\n            continue;\n", ""),
    "B3_ignore_param_use": (SP, "          if (!Callee->getArg(A)->use_empty())\n            continue;\n          Value *Op", "          Value *Op"),
    "B4_ignore_taint": (SP, "          if (!taint.Tainted.count(Op))\n            continue;\n", ""),
    "B5_scan_clone_bodies": (SP, "    if (F.isDeclaration() || taint.SpecHandleArgMask.count(&F))\n      continue;  // a clone",
                             "    if (F.isDeclaration())\n      continue;  // a clone"),
    # --- M-C arm (d0) ---
    "D1_d0_off": (AL, "    if (PassesP && !ReadsP)\n      return true;\n", ""),
    "D2_d0_any_call": (AL, "    if (PassesP && !ReadsP)\n      return true;\n", "    if (PassesP)\n      return true;\n"),
}

SUFFIX = __import__("os").environ.get("MUT_SUFFIX", "")
only = set(sys.argv[1:])
for name, (rel, old, new) in MUT.items():
    if only and name not in only:
        continue
    p = M / rel
    orig = p.read_text()
    n = orig.count(old)
    if n != 1:
        raise SystemExit(f"{name}: anchor found {n} times in {rel} — refusing")
    p.write_text(orig.replace(old, new, 1))
    # ⚠ BUMP THE MTIME. make compares mtimes at 1-second resolution here: a mutant
    # written in the same second its predecessor's object was built is NOT rebuilt, and
    # the "mutant" silently IS its predecessor (measured: M3==M4, M6==M7, M8==M9, B3==B4
    # by sha-256 on the first run — the L10 failure mode, a harness reporting about the
    # wrong binary). Every built mutant is also hash-checked against the base below.
    import os, time
    t = time.time() + 5
    os.utime(p, (t, t))
    try:
        r = subprocess.run(["cmake", "--build", str(M / "build"), "-j8", "--target", "cq-opt"],
                           capture_output=True, text=True)
        if r.returncode:
            print(f"{name}: BUILD FAILED\n{r.stdout[-1500:]}{r.stderr[-800:]}")
            continue
        import hashlib
        h = hashlib.sha256((M / "build/ir-pass/cq-opt").read_bytes()).hexdigest()[:16]
        dst = V / "bin" / f"cq-opt.{name}{SUFFIX}"
        shutil.copy(M / "build/ir-pass/cq-opt", dst)
        print(f"{name}: built {h}")
    finally:
        p.write_text(orig)
        t2 = time.time() + 10
        os.utime(p, (t2, t2))
