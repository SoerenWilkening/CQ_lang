; control_inplace_ry_reject_stateprep_range_forward_ashr.ll — DECLINE (F2, the
; RANGE clause reaching FORWARD; the signed twin of `..._range_forward_lshr.ll`,
; kept because the two exercise DIFFERENT `ConstantRange` operations on the same
; edge and a sign-extending shift is the one that pins to a NEGATIVE seed).
;
; ⚠ A ROUND-2 RULE-13 FINDING, NOT A DESIGN ROW — one of the SIX plain-C
; spellings that ACCEPTED after the round-1 fix (round-2 review, lens R1 finding
; F-R1-1, CONFIRMED-MISCOMPILE, probe `p/x22_ashr31.c`):
;
;     int q = cq_theta(3, 0.3);
;     int s = q >> 31;
;     int r = -1;
;     if (s) r = cq_theta(s, 0.9);          /* an IN-PLACE Ry on s's own rail */
;     return (int) cq_measure(r) + (int) cq_measure(s);
;
; Same mechanism as the `lshr` file (the compare rewritten onto the ANCESTOR
; `%q`), and `%s` is alive as `ashr_i32_hl(h0,31) -> h3`, measured, unrotated.
;
; THIS FILE'S ALGEBRA: the false edge of `sgt -1` pins `%q` to `[INT_MIN, 0)`;
; `ConstantRange::ashr` takes the all-negative branch of its case analysis
; (`NegMin = INT_MIN.ashr(31) = -1`, `NegMax = (-1).ashr(31) + 1 = 0`), giving
; `[-1, 0)` — the singleton `{-1}`, which IS the seed.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 3.000000e-01)
  %c = icmp sgt i32 %q, -1
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 -1, double 9.000000e-01)
  br label %merge
merge:
  %rm  = phi i32 [ %rt, %arm ], [ -1, %entry ]
  %fwd = ashr i32 %q, 31
  %mr  = call i32 @cq_measure_si32(i32 %rm)
  %mf  = call i32 @cq_measure_si32(i32 %fwd)
  %s   = add i32 %mr, %mf
  ret i32 %s
}
