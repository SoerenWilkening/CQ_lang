; loop_rail_closed_exit_value.ll — ACCEPT (bd test_C_libtooling-8h7d.14).
; `clang -O1` output (attributes and metadata dropped) of
;
;     int p2(int u, int n) {                    // the issue's reproducer
;       int q = u; cq_theta(&q, .5);
;       for (int i = 0; i < n; i++) {
;         int d = q * q;
;         if (q < 9) cq_phi(.75);
;         if (d > 5) cq_phi(.25);
;         q += 1;
;       }
;       return cq_measure(q);
;     }
;
; `@step3`: the body `if (q < 9) cq_phi(.75); q += 3;` (closed form `q0 + 3n`).
; `@plus_one`: `@p2`'s body without the `q < 9` region, then `int t = q + 1;
; return cq_measure(t) + cq_measure(q);`.
;
; THE DEFECT (main 7b4e6359, all three declined `rail record read past an
; in-place gate on the same rail`). IndVars closes the affine recurrence: the
; exit block computes `%6 = add %3, %1` (`q0 + n`) from the ROOT record instead
; of reading the latch value through an LCSSA φ, while the body's `q += 1`
; survives (the body still reads q). After the round-2 collapse `%6` would be an
; out-of-place add on the register the body's `addc`s already moved (`q0 + 2n`);
; the record-liveness fence declined it as a stale read of `%3`.
;
; THE FIX (`reopenClosedRailExits`, round 2 step (1b)). ScalarEvolution proves
; SCEV(`%6`) == SCEV-at-exit(latch value `%20`) (both `(%1 + %3)`), and `%6`
; runs only after a completed trip (its block's only predecessor is the latch).
; `%6` is replaced by the φ `-O1` would have written, `phi [%20, latch]`, and
; erased; that φ is collapsed onto the rail like any exit φ, and the fence asks
; its readers positionally. The decline twin, a pre-loop alias read after the
; loop that is NOT the exit value: `loop_rail_closed_exit_value_reject_pre_alias.ll`.
;
; TRACE ARGUMENT (h the register of q; per trip i the register holds q0 + i):
;   @p2: Ry(h,.5); per trip: d = h*h (fresh rail); f1 = [h <s 9], Rz(.75) on
;     f1, f1⁻¹, free; f2 = [d >u 5], Rz(.25) on f2, f2⁻¹; d⁻¹ (h unchanged since
;     the mul, so d returns to |0>), free d, free f2; addc(h, 1). After the loop
;     (n > 0) or on the zero-trip path (n <= 0) h holds q0 + max(n, 0), which is
;     `%8`, and `measure(h)` reads it. No add is emitted after the loop.
;   @step3: the same with addc(h, 3); h holds q0 + 3n = `%8`.
;   @plus_one: t = add_hl(h, 1) on a fresh rail AFTER the loop, then measure(t),
;     measure(h): t = q_final + 1 as the source says.
; Linked and run from C for `@p2` (n = 2): two trips, then `measure(h0)`;
; stage 2b `0 violation(s)`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll

declare i32 @cq_theta_si32(i32 noundef, double noundef)
declare void @cq_phi(double noundef)
declare i32 @cq_measure_si32(i32 noundef)

define i32 @p2(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %10, label %7

5:
  %6 = add i32 %3, %1
  br label %7

7:
  %8 = phi i32 [ %3, %2 ], [ %6, %5 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8)
  ret i32 %9

10:
  %11 = phi i32 [ %20, %19 ], [ %3, %2 ]
  %12 = phi i32 [ %21, %19 ], [ 0, %2 ]
  %13 = mul nsw i32 %11, %11
  %14 = icmp slt i32 %11, 9
  br i1 %14, label %15, label %16

15:
  tail call void @cq_phi(double noundef 7.500000e-01)
  br label %16

16:
  %17 = icmp ugt i32 %13, 5
  br i1 %17, label %18, label %19

18:
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %19

19:
  %20 = add nsw i32 %11, 1
  %21 = add nuw nsw i32 %12, 1
  %22 = icmp eq i32 %21, %1
  br i1 %22, label %5, label %10
}

define i32 @step3(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %9

5:
  %6 = mul i32 %1, 3
  br label %12

7:
  %8 = add i32 %3, %6
  br label %9

9:
  %10 = phi i32 [ %3, %2 ], [ %8, %7 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10)
  ret i32 %11

12:
  %13 = phi i32 [ %19, %17 ], [ 0, %5 ]
  %14 = phi i32 [ %18, %17 ], [ %3, %5 ]
  %15 = icmp slt i32 %14, 9
  br i1 %15, label %16, label %17

16:
  tail call void @cq_phi(double noundef 7.500000e-01)
  br label %17

17:
  %18 = add nsw i32 %14, 3
  %19 = add nuw nsw i32 %13, 1
  %20 = icmp eq i32 %19, %1
  br i1 %20, label %7, label %12
}

define i32 @plus_one(i32 noundef %0, i32 noundef %1) {
  %3 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01)
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %13, label %7

5:
  %6 = add i32 %3, %1
  br label %7

7:
  %8 = phi i32 [ %3, %2 ], [ %6, %5 ]
  %9 = add nsw i32 %8, 1
  %10 = tail call i32 @cq_measure_si32(i32 noundef %9)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %8)
  %12 = add nsw i32 %11, %10
  ret i32 %12

13:
  %14 = phi i32 [ %20, %19 ], [ %3, %2 ]
  %15 = phi i32 [ %21, %19 ], [ 0, %2 ]
  %16 = mul nsw i32 %14, %14
  %17 = icmp ugt i32 %16, 5
  br i1 %17, label %18, label %19

18:
  tail call void @cq_phi(double noundef 2.500000e-01)
  br label %19

19:
  %20 = add nsw i32 %14, 1
  %21 = add nuw nsw i32 %15, 1
  %22 = icmp eq i32 %21, %1
  br i1 %22, label %5, label %13
}

; CHECK-LABEL: define i32 @p2(
; CHECK-NEXT: %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = icmp sgt i32 %1, 0
; CHECK-NEXT: br i1 %[[G]], label %[[LOOP:[a-zA-Z0-9_.]+]], label %[[JOIN:[a-zA-Z0-9_.]+]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[EXIT:[0-9]+]]:
; CHECK-NEXT: br label %[[JOIN]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[JOIN]]:
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NEXT: ret i32 %[[M]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[LOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[Q]], i32 %[[Q]])
; CHECK-NEXT: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[Q]], i32 9)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F1]], double 7.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[F1]], i32 %[[Q]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i32_hl(i32 %[[D]], i32 5)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[F2]], double 2.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_ugt_i32_hl_unc(i32 %[[F2]], i32 %[[D]], i32 5)
; CHECK-NEXT: call void @cq_template_mul_i32_unc(i32 %[[D]], i32 %[[Q]], i32 %[[Q]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[Q]], i32 1)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1 %{{[0-9]+}}, label %[[EXIT]], label %[[LOOP]]
; CHECK-NEXT: {{^}}}
;
; CHECK-LABEL: define i32 @step3(
; CHECK-NEXT: %[[SQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[SQ]], double 5.000000e-01)
; CHECK-NEXT: %[[SG:[a-zA-Z0-9_.]+]] = icmp sgt i32 %1, 0
; CHECK-NEXT: br i1 %[[SG]], label %[[SPRE:[0-9]+]], label %[[SJOIN:[0-9]+]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[SPRE]]:
; CHECK-NEXT: mul i32 %1, 3
; CHECK-NEXT: br label %[[SLOOP:[0-9]+]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[SEXIT:[0-9]+]]:
; CHECK-NEXT: br label %[[SJOIN]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[SJOIN]]:
; CHECK-NEXT: %[[SM:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[SQ]])
; CHECK-NEXT: ret i32 %[[SM]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[SLOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: %[[SF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[SQ]], i32 9)
; CHECK-NEXT: call void @cqrt_rz_i1(i32 %[[SF]], double 7.500000e-01)
; CHECK-NEXT: call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[SF]], i32 %[[SQ]], i32 9)
; CHECK-NEXT: call void @cqrt_free(i32 %[[SF]])
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %[[SQ]], i32 3)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1 %{{[0-9]+}}, label %[[SEXIT]], label %[[SLOOP]]
; CHECK-NEXT: {{^}}}
;
; CHECK-LABEL: define i32 @plus_one(
; CHECK-NEXT: %[[PQ:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[PQ]], double 5.000000e-01)
; CHECK-NEXT: %[[PG:[a-zA-Z0-9_.]+]] = icmp sgt i32 %1, 0
; CHECK-NEXT: br i1 %[[PG]], label %[[PLOOP:[a-zA-Z0-9_.]+]], label %[[PJOIN:[a-zA-Z0-9_.]+]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[PEXIT:[0-9]+]]:
; CHECK-NEXT: br label %[[PJOIN]]
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[PJOIN]]:
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[PQ]], i32 1)
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[T]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[PQ]])
; CHECK-NEXT: add nsw i32
; CHECK-NEXT: ret i32
; CHECK-EMPTY:
; CHECK-NEXT: {{^}}[[PLOOP]]:
; CHECK-NEXT: phi i32
; CHECK-NEXT: %[[PD:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32(i32 %[[PQ]], i32 %[[PQ]])
; CHECK: call void @cq_template_mul_i32_unc(i32 %[[PD]], i32 %[[PQ]], i32 %[[PQ]])
; CHECK: call void @cqrt_addc_i32(i32 %[[PQ]], i32 1)
; CHECK-NEXT: add nuw nsw i32
; CHECK-NEXT: icmp eq i32
; CHECK-NEXT: br i1 %{{[0-9]+}}, label %[[PEXIT]], label %[[PLOOP]]
; CHECK-NEXT: {{^}}}
