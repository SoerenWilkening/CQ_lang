#!/usr/bin/env python3
"""mk_gate_instr.py SRC_TREE — instrument EVERY `empty()` gate over a self-cleaning
TaintSet table (the L2 enumeration, Rule-13 delta r2 item 1) in a scratch copy of
a tree: each gate evaluation prints `CQGATE <id> live_empty=<0|1> raw_empty=<0|1>`
to stderr when CQ_GATE_TRACE is set. `raw_empty` is what the pre-8e5r RAW
container would have answered (dead entries still stored). A FLIP is
live_empty=1 raw_empty=0: a gate that now reads "nothing" where the raw table held
only DEAD members — exactly F-R2-1's shape. Instrument only; never committed."""
import sys
S = sys.argv[1]


def rep(path, a, b, n=1):
    p = S + "/" + path
    s = open(p).read()
    assert s.count(a) == n, (path, a[:80], s.count(a))
    open(p, "w").write(s.replace(a, b))


# rawEmpty() on the four container kinds + a gate reporter
rep("ir-pass/include/ScrubOnDelete.h",
    "  bool empty() const { return C->S.size() == C->Dead.size(); }\n",
    "  bool empty() const { return C->S.size() == C->Dead.size(); }\n  bool rawEmpty() const { return C->S.empty(); }\n", 2)
rep("ir-pass/include/ScrubOnDelete.h",
    "  bool empty() const { return begin() == end(); }\n",
    "  bool empty() const { return begin() == end(); }\n  bool rawEmpty() const { return C->S.empty(); }\n")
rep("ir-pass/include/ScrubOnDelete.h", "}  // namespace scrub\n", """template <typename C> inline void gate(const char *Id, const C &Cont) {
  static int On = -1;
  if (On < 0)
    On = std::getenv("CQ_GATE_TRACE") != nullptr;
  if (On)
    std::fprintf(stderr, "CQGATE %s live_empty=%d raw_empty=%d\\n", Id, (int)Cont.empty(),
                 (int)Cont.rawEmpty());
}
}  // namespace scrub
""")
rep("ir-pass/include/ScrubOnDelete.h", "#include <algorithm>\n", "#include <algorithm>\n#include <cstdio>\n#include <cstdlib>\n")

G = [
    ("ir-pass/src/CQLoweringPass.cpp",
     "  TaintSet taint = propagate(M, wd);\n\n  // No quantum work anywhere in the module: leave the IR byte-identical",
     "  TaintSet taint = propagate(M, wd);\n  cq::scrub::gate(\"G1a_run_ThetaCalls\", taint.ThetaCalls); cq::scrub::gate(\"G1b_run_PhiCalls\", taint.PhiCalls); cq::scrub::gate(\"G1c_run_PhaseCalls\", taint.PhaseCalls); cq::scrub::gate(\"G1d_run_MeasureCalls\", taint.MeasureCalls);\n\n  // No quantum work anywhere in the module: leave the IR byte-identical"),
    ("ir-pass/src/ArmClassify.cpp",
     "  if (Taint.ValueArmConeOps.empty())\n    return false;",
     "  cq::scrub::gate(\"G2_ValueArmConeOps\", Taint.ValueArmConeOps);\n  if (Taint.ValueArmConeOps.empty())\n    return false;"),
    ("ir-pass/src/FreePoint.cpp",
     "  const bool TermIterLocal =\n",
     "  cq::scrub::gate(\"G3_FreePoint_IterationLocalBlocks\", taint.IterationLocalBlocks);\n  const bool TermIterLocal =\n"),
    ("ir-pass/src/Uncomputation.cpp",
     "      Loop *L = LI.getLoopFor(Term->getParent());\n      if (L && !taint.IterationLocalBlocks.empty() &&",
     "      Loop *L = LI.getLoopFor(Term->getParent());\n      cq::scrub::gate(\"G4_Uncompute_IterationLocalBlocks\", taint.IterationLocalBlocks);\n      if (L && !taint.IterationLocalBlocks.empty() &&"),
    ("ir-pass/src/RotationLowering.cpp",
     "  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty())\n    return;",
     "  cq::scrub::gate(\"G5a_lowerRotations_ThetaCalls\", taint.ThetaCalls); cq::scrub::gate(\"G5b_lowerRotations_PhiCalls\", taint.PhiCalls);\n  if (taint.ThetaCalls.empty() && taint.PhiCalls.empty())\n    return;"),
    ("ir-pass/src/RotationLowering.cpp",
     "  if (taint.UserChainedRotations.empty())\n",
     "  cq::scrub::gate(\"G6_UserChainedRotations\", taint.UserChainedRotations);\n  if (taint.UserChainedRotations.empty())\n"),
    ("ir-pass/src/OpcodeLowering.cpp",
     "  if (taint.LiftedConsumers.empty())\n",
     "  cq::scrub::gate(\"G7_LiftedConsumers\", taint.LiftedConsumers);\n  if (taint.LiftedConsumers.empty())\n"),
    ("ir-pass/src/TaintPropagation.cpp",
     "  if (taint.UntaintedMergeRails.empty())\n    return;  // no 6.5",
     "  cq::scrub::gate(\"G8_UntaintedMergeRails\", taint.UntaintedMergeRails);\n  if (taint.UntaintedMergeRails.empty())\n    return;  // no 6.5"),
    ("ir-pass/src/MeasureLowering.cpp",
     "  if (taint.MeasureCalls.empty())\n    return;",
     "  cq::scrub::gate(\"G9_lowerMeasures_MeasureCalls\", taint.MeasureCalls);\n  if (taint.MeasureCalls.empty())\n    return;"),
    ("ir-pass/src/LoopLowering.cpp",
     "  if (taint.InLoopFlattenedPreds.empty())\n",
     "  cq::scrub::gate(\"G10_InLoopFlattenedPreds\", taint.InLoopFlattenedPreds);\n  if (taint.InLoopFlattenedPreds.empty())\n"),
    ("ir-pass/src/LoopLowering.cpp",
     "  if (taint.Tainted.empty())\n    return;\n  SmallPtrSet<CallInst *, 32> GateCalls;",
     "  cq::scrub::gate(\"G11_Dephasing_Tainted\", taint.Tainted);\n  if (taint.Tainted.empty())\n    return;\n  SmallPtrSet<CallInst *, 32> GateCalls;"),
]
for path, a, b in G:
    rep(path, a, b)
print(f"instrumented {len(G)} gate sites")
