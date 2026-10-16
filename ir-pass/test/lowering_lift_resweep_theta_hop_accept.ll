; lowering_lift_resweep_theta_hop_accept.ll — ACCEPT (bd test_C_libtooling-dm7f.1,
; DECLINE->ACCEPT; main 7b4e6359 declined it with `cq opcode lowering: operand
; predates a non-diagonal gate`). The lifted read sits one in-place gate past the
; phi:
;
;     int q = 7; cq_theta(&q, .5);
;     if (c) cq_theta(&q, .125);
;     cq_theta(&q, .2);
;     int v = q + 3;
;
; The `add` reads `%8 = cq_theta(%7, .2)`. Its backward closure crosses `%8` to
; the base `%2`, so the arm's `%5` shows up as a sibling. `%8`'s arg 0 is a
; recorded use of the lifted phi `%7`, and `%8`'s record extends `%7`'s, so `%5`
; is on it.
;
; SEMANTIC EVIDENCE (hand trace). h = alloc(7); Ry(.5); [c] Ry(.125); Ry(.2);
; add_hl(h, 3) measured. On each path the add reads exactly the gates `q` has
; received, which is the source's `q` after the `.2` rotation.
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
; MC-CMD: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s -o %t.ll 2>&1 | %filecheck %s --check-prefix=DIAG --allow-empty
; MC-CMD: %filecheck %s < %t.ll
; DIAG-NOT: error
; DIAG-NOT: live derived record
; CHECK-LABEL: define i32 @f(
; CHECK:      %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 7)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 1.250000e-01)
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 2.000000e-01)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[V]])

define i32 @f(i32 noundef %0) {
  %2 = tail call i32 @cq_theta_si32(i32 noundef 7, double noundef 5.000000e-01)
  %3 = icmp eq i32 %0, 0
  br i1 %3, label %6, label %4

4:                                                ; preds = %1
  %5 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 1.250000e-01)
  br label %6

6:                                                ; preds = %4, %1
  %7 = phi i32 [ %5, %4 ], [ %2, %1 ]
  %8 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.000000e-01)
  %9 = add nsw i32 %8, 3
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  ret i32 %10
}

declare i32 @cq_theta_si32(i32 noundef, double noundef)

declare i32 @cq_measure_si32(i32 noundef)
