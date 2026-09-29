#!/usr/bin/env python3
"""mutants_r2.py [--setup] [--all | NAME ...] — the round-2 mutation matrix (bd vaep strip, the
preallocated decline, the fence's re-derived location / liveness pair). Same machinery as
../tools/mutants.py (scratch tree + own build dir; a restore WRITES files and every mutant is
bracketed by a rebuild that must hash to the base — the boundary control that caught round 1's
contaminated run), with its own mutant table and result file."""
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "tools"))
import mutants as m  # noqa: E402

m.RES = pathlib.Path(__file__).resolve().parent.parent / "results" / "r2" / "mutants_r2.txt"
m.M = {
    "N0_null_r2": ("ir-pass/src/DeadValueLiveness.cpp",
                "void stripParamValueConstraints(Function &F, unsigned ArgNo) {",
                "// round-2 mutation-matrix null mutant: a comment only\n"
                "void stripParamValueConstraints(Function &F, unsigned ArgNo) {"),
    "V1_no_record_time_strip": ("ir-pass/src/Specialization.cpp",
                "      stripParamValueConstraints(*Clone, Arg.getArgNo());",
                "      (void)0;"),
    "V2_record_strip_range_only": ("ir-pass/src/DeadValueLiveness.cpp",
                "    for (Attribute::AttrKind K : {Attribute::Range, Attribute::NoFPClass})\n"
                "      F.removeParamAttr(ArgNo, K);",
                "    for (Attribute::AttrKind K : {Attribute::Range})\n"
                "      F.removeParamAttr(ArgNo, K);"),
    "V3_record_strip_every_param": ("ir-pass/src/Specialization.cpp",
                "    if (Arg.getArgNo() < 64 && ((DeadSlots >> Arg.getArgNo()) & 1))\n"
                "      stripParamValueConstraints(*Clone, Arg.getArgNo());",
                "    stripParamValueConstraints(*Clone, Arg.getArgNo());"),
    "V4_no_callsite_strip": ("ir-pass/src/Specialization.cpp",
                "              stripUnreadSlotValueConstraints(*CB, CB->getArgOperandNo(&U));",
                "              (void)0;"),
    "V5_decline_inalloca_too": ("ir-pass/src/SpecializeReject.cpp",
                "            if (CI->paramHasAttr(A, Attribute::Preallocated)) {",
                "            if (CI->paramHasAttr(A, Attribute::Preallocated) ||\n"
                "                CI->paramHasAttr(A, Attribute::InAlloca)) {"),
    "V6_no_preallocated_decline": ("ir-pass/src/SpecializeReject.cpp",
                "            if (CI->paramHasAttr(A, Attribute::Preallocated)) {",
                "            if (false && CI->paramHasAttr(A, Attribute::Preallocated)) {"),
    "V7_fence_value_is_existence": ("ir-pass/src/Specialization.cpp",
                "    const FunctionLiveness Value(*Clone, taint, SlotReads::Value);",
                "    const FunctionLiveness Value(*Clone, taint, SlotReads::Existence);"),
}

if __name__ == "__main__":
    if "--setup" in sys.argv:
        m.setup()
    for n in [a for a in sys.argv[1:] if not a.startswith("--")]:
        m.one(n)
    if "--all" in sys.argv:
        for n in m.M:
            m.one(n)
        m.restore()
        print("restored; rebuild base:", m.assert_base("the end"))
