; lowering_lift_resweep_own_arm_theta_accept.ll — ACCEPT (bd test_C_libtooling-dm7f.1;
; a DECLINE->ACCEPT flip, main 7b4e6359 declined it with `cq opcode lowering:
; operand predates a non-diagonal gate`). `clang -O1` of
;
;     int q = 7; cq_theta(&q, .5);
;     if (c) cq_theta(&q, .125);          // c classical
;     int v = q + 3;
;     return cq_measure(v);
;
; The merge phi `%8 = [%6, arm], [%3, entry]` is a one-register lift onto `%3`.
; The post-lift re-sweep, seeded at `%3`, used to see the arm's own `%6` as a
; sibling gate before the `add`. `%6` is ON the record the `add` reads: the lift
; proves it fires exactly when the arm edge is taken, and on that edge the phi
; IS `%6`. The per-use record (bd dm7f.1) exempts it for this read only.
;
; SEMANTIC EVIDENCE (hand trace of the stream below). h = alloc(7); Ry(.5) on h;
; if c: Ry(.125) on h; then add_hl(h, 3) mints a fresh rail holding h + 3 and is
; measured. On the c path the add reads Ry(.125)Ry(.5)|7>, the record `%6`; on
; the other path it reads Ry(.5)|7>, the record `%3`. That is `%8` on each path,
; which is exactly the source's `q`. The add rail is measured, so it is neither
; uncomputed nor freed, and h is the measured value's parent (left allocated).
; Before bd dm7f.1 the live-record warning also fired here (`R` = the add, `T` =
; the arm's `ry`), because the arm gate does not dominate the add; a lifted read
; that cannot reach the gate is now absent at it, so DIAG pins its silence.
;
; bd dm7f.83 (ruling-dm7f83-inplace-fence-refusal-loud-2026-10-16): FLIPPED TO
; LOUD. A classical-immediate in-place site here is refused by the M-C fence
; (`inPlaceFenceHolds`, G6: an earlier use of the register sits in a block that
; does not dominate the op, so `provablyBefore` cannot place it before the op
; although the op cannot reach it (asking reachability instead is the build))
; while its handle is a DEAD USER REGISTER (register-level: no later read,
; rotation or measure of its rail under any SSA name, `registerLiveAfter`, bd
; dm7f.83.3) beside a KEPT result, so out of place would leave the old rail
; beside the result, the r2j3.33 hazard class. MEASURED
; (laneL/dm7f83_flips.md): in THIS fixture that fallback was observably correct
; (the record is only measured, or every later Ry on it cancels, or its
; which-path information already sits in another kept rail), so this decline is
; the ruling's, an over-decline until the refusal is lowered. The in-place round now fails
; loudly (InPlaceQQImm.cpp), as owner Q1 requires. The fixture's original
; expectation is kept dormant: its RUN lines are spelled MC-CMD and no RUN line
; reads its CHECK prefixes. RETIREMENT: restore them when the refused shape
; converts (G6's lowering, named above).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=DM7F83
; DM7F83: error: {{.*}}cq in-place lowering: quantum reassignment of a dead register is not provable in place
;
; MC-CMD: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; MC-CMD: %filecheck %s < %t.ll
; DIAG-NOT: error
; DIAG-NOT: live derived record
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK:      %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[V]])
; CHECK-NOT:  cqrt_free
; CHECK:      ret i32

define i32 @f(i32 noundef %0, i32 %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %4 = icmp eq i32 %0, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %2
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 1.250000e-01)
  br label %7

7:                                                ; preds = %5, %2
  %8 = phi i32 [ %6, %5 ], [ %3, %2 ]
  %9 = add nsw i32 %8, 3
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
