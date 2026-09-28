#!/usr/bin/env python3
"""z0re mutation matrix: build one cq-opt per mutant of the NEW/CHANGED predicates.

  mutants.py build   — for each mutant: back up the pristine source, apply the
                       one-edit mutant, `cmake --build build --target cq-opt -j2`,
                       copy the binary to scratchpad/z0re_bins/cq-opt.<M>, restore
                       the pristine source. Refuses to run if a patch does not
                       apply EXACTLY ONCE (a mutant that silently fails to apply
                       measures the unmutated binary — L10's failure mode).
The caller rebuilds the subject afterwards (a full `cmake --build build`).
"""
import os
import shutil
import subprocess
import sys

W = "/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-a284a60d747f2ed82"
S = "/private/tmp/claude-501/-Users-sorenwilkening-Desktop-Projects-CQ-lang/e5b5b1db-0ae7-4581-b33c-ce92d95d4f38/scratchpad"
BINS = S + "/z0re_bins"
AC = "ir-pass/src/ArmClassify.cpp"
SR = "ir-pass/src/SwapRouteEmit.cpp"
AS = "ir-pass/src/AngleSelectEmit.cpp"

MUTANTS = {
    # NULL: reorder two independent disjuncts — no behaviour change. MUST move 0.
    "M0_null": [(AC,
                 "  if (!isa<Instruction>(V) && !isa<Argument>(V))\n    return false;  // a `BasicBlock`",
                 "  if (!isa<Argument>(V) && !isa<Instruction>(V))\n    return false;  // a `BasicBlock`")],
    # F1 back to literal-only (the oracle's clause).
    "M1_f1_literal_only": [(AC,
                            "            !isa<ConstantFP>(RotBase) &&\n            !isRuntimeStatePrepSeed(RotBase, Taint)) {",
                            "            !isa<ConstantFP>(RotBase)) {")],
    # F2 relational, integer half: drop the three exclusions.
    "M2_rel_int_noexcl": [(AC,
                           "          if (V->getType() != SeedV->getType() || excludedAtTest(V))",
                           "          if (V->getType() != SeedV->getType())")],
    # F2 relational, fp half: drop the three exclusions.
    "M3_rel_fp_noexcl": [(AC,
                          "          if (H->getType() == SeedV->getType() && Taint.Tainted.count(H) &&\n              !excludedAtTest(H))",
                          "          if (H->getType() == SeedV->getType() && Taint.Tainted.count(H))")],
    # L1 record at the diamond emitter removed.
    "M4_no_record_prep": [(SR,
                           "  if (R.RuntimeSeedAdmitted)\n    taint.RuntimeSeedSourceThetas.push_back(SourceTheta);",
                           "  (void)SourceTheta;")],
    # L1 record at the angle-select emitter removed.
    "M5_no_record_angle": [(AS,
                            "  if (R.RuntimeSeedAdmitted)\n    taint.RuntimeSeedSourceThetas.push_back(T0);",
                            "")],
    # S3 admits a LITERAL base too (the drbq.13 widening this change refuses), at
    # the classifier AND the emitter's lockstep re-ask.
    "M7_s3_literal_base": [
        (AC, "  if (UntaintedBase && !(IsTheta && isRuntimeStatePrepSeed(RotBase, Taint)))",
             "  if (UntaintedBase && !(IsTheta && (isRuntimeStatePrepSeed(RotBase, Taint) || isa<ConstantInt>(RotBase))))"),
        (AC, "  R.RuntimeSeedAdmitted = UntaintedBase;",
             "  R.RuntimeSeedAdmitted = UntaintedBase && !isa<Constant>(RotBase);"),
        (AS, "  if (UntaintedBase && !(IsTheta && isRuntimeStatePrepSeed(Base, taint))) {",
             "  if (UntaintedBase && !(IsTheta && (isRuntimeStatePrepSeed(Base, taint) || isa<ConstantInt>(Base)))) {")],
    # S7-rail / S8 / S9 NOT skipped for an untainted base (the closure of `t`).
    "M8_no_s789_skip": [(AC,
                         "  if (!IsPhase && !UntaintedBase)\n    railWireClosure(RotBase, Taint, WireDir::BothWays, nullptr, nullptr,",
                         "  if (!IsPhase)\n    railWireClosure(RotBase, Taint, WireDir::BothWays, nullptr, nullptr,")],
    # The re-ask disabled outright.
    "M6_no_reask": [(AC,
                     "  (void)M;  // the record is module-wide already; kept for the slot's signature.\n  for (const WeakTrackingVH &H : Taint.RuntimeSeedSourceThetas) {",
                     "  (void)M;  // the record is module-wide already; kept for the slot's signature.\n  return false;\n  for (const WeakTrackingVH &H : Taint.RuntimeSeedSourceThetas) {")],
}


def build_one(name, edits):
    backups = {}
    try:
        for f, old, new in edits:
            p = os.path.join(W, f)
            if p not in backups:
                backups[p] = open(p).read()
            src = open(p).read()
            n = src.count(old)
            if n != 1:
                raise SystemExit(f"{name}: patch for {f} applies {n} times, not once — refusing")
            open(p, "w").write(src.replace(old, new))
        r = subprocess.run(["cmake", "--build", W + "/build", "--target", "cq-opt", "-j2"],
                           capture_output=True, text=True)
        if r.returncode:
            print(r.stdout[-3000:], r.stderr[-3000:])
            raise SystemExit(f"{name}: build failed")
        dst = os.path.join(BINS, "cq-opt." + name)
        shutil.copyfile(W + "/build/ir-pass/cq-opt", dst)
        os.chmod(dst, 0o755)
        print(f"{name}: built {dst}", flush=True)
    finally:
        for p, text in backups.items():
            open(p, "w").write(text)


if __name__ == "__main__":
    os.makedirs(BINS, exist_ok=True)
    which = sys.argv[2:] or list(MUTANTS)
    for m in which:
        build_one(m, MUTANTS[m])
