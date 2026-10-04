// slice_loop_carried_handle_narrow.c — bd `test_C_libtooling-11qv`, the
// NARROW-WIDTH loop-carried handle variable.
//
// THIS IS THE OWNER'S ROLLED CASCADE (`example/grover/grover_oracle_uncompute.c`,
// the bd `zujr` headline) WITH ONE CHARACTER CHANGED: `int a` is `short a`.
// Everything else — `bool b0[3]`, three trips, the `a >= 3` guard, the `a -= 3`
// value arm, the four measurements — is the shipped program.
//
// WHY THE ONE CHARACTER IS THE WHOLE SLICE.  Until 2026-09-20 this program
// declined `cq controlled lowering: iteration-local value read after the loop
// under quantum control`, because `loopCarriedHandlePhi` clause (Z3) required the
// carried phi to be `i32` and a refused phi is not exempted from R7-loop clause
// (c3).  The clause was a CRASH FENCE: `cqrt_alloc_<W>` returns `i32` at EVERY
// width (Rule 15), so a promoted `i16` phi muxed two `i32` values through a phi
// of the wrong type, and a build that merely deleted the test aborted `opt` with
// exit 134 on `PHI node operands are not the same type as the result!`.
// The promotion now RETYPES the phi (`mutateType(i32)`), which is the
// `RailBankPromote.cpp` idiom, and records the LOGICAL width in
// `taint.HandleWidth` so nothing downstream recovers `i32` from the laundered
// type.
//
// ⚠ WHAT TO READ IN THE GOLDEN, because it is the only thing that distinguishes
// a correct retype from a wrong-width silent miscompile: EVERY width-bearing
// symbol says `i16` — `cqrt_alloc_i16`, `cq_template_add_i16_hl`,
// `cqrt_copy_i16_controlled`, `cqrt_measure_i16` — while every HANDLE is `i32`.
// An `i32` suffix on any of those four would be the defect
// `CompareLowering.cpp` refuses in writing (*"NEVER default empty -> i32"*).
//
// ⚠ THE `i16` LITERAL RENDERS UNSIGNED (`65533` for `-3`) AND THAT IS
// PRE-EXISTING, NOT THIS INCREMENT'S.  The lowered IR carries `i16 -3` against
// `declare i32 @cq_template_add_i16_hl(i32, i16)`; the runtime's C definition
// takes an `int16_t`, which Clang's x86-64 ABI marks `signext`, and the pass
// emits the literal operand with no extension attribute.  MEASURED on the ORACLE
// binary with a LOOP-FREE program that has no carried handle at all, so it is
// not reachable from anything here.  Filed separately; do not "fix" it by
// editing this golden.
//
// The stream is the `int` cascade's stream modulo the width token — 50 trace
// lines, STRICT stage 2b `2 verified, 0 violation(s), 0 unproven`.
#include "CQ.h"
int main(void) {
    short a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        if (a >= 3) {
            cq_theta(&b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }
    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2])
         + (int)cq_measure(a);
}
