; lowering_q_plus_arg.ll — Q+C dispatch where the classical operand is a
; function argument (not a ConstantInt). Taint-set membership selects the
; dispatch: %c is not tainted, so the add lowers to add_i32_hl.
;
; bd dm7f.83 (ruling-dm7f83-inplace-fence-refusal-loud-2026-10-16): FLIPPED TO
; LOUD. A classical-immediate in-place site here is refused by the M-C fence
; (`inPlaceFenceHolds`: G4's parameter immediate, G5 in a loop, or G6/G7 position)
; while its handle is a DEAD USER REGISTER beside a KEPT result, so the old rail
; would stand beside the result — the r2j3.33 wrong unitary the out-of-place
; fallback used to ship with at most a warning. The in-place round now fails
; loudly (InPlaceQQImm.cpp), as owner Q1 requires. The fixture's original
; expectation is kept dormant: its RUN lines are spelled MC-CMD and no RUN line
; reads its CHECK prefixes. RETIREMENT: restore them when the refused shape
; converts (the dm7f.83 follow-up drops G4; G5-G7 refusals need their own
; lowering).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DM7F83
; DM7F83: error: {{.*}}cq in-place lowering: quantum reassignment of a dead register is not provable in place
;
; MC-CMD: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; MC-CMD: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i32(i32 3)
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 %c)
; CHECK:     call i32 @cqrt_measure_i32(
;
; CHECK-NOT: call i32 @cq_template_add_i32(
; CHECK-NOT: cq_theta_si32
; CHECK-NOT: cq_measure_si32
; CHECK-NOT: add i32

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %c) {
entry:
  %a = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %d = add i32 %a, %c   ; rhs is a fn-arg classical i32
  %m = call i32 @cq_measure_si32(i32 %d)
  ret i32 %m
}
