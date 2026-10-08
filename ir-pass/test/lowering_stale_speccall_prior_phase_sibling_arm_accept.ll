; lowering_stale_speccall_prior_phase_sibling_arm_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.6, review round 2 R2-3: an over-decline regression of the
; round-1 snapshot 8c517ac4 against main).
;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int c = 0; cq_theta(&c, .7);
;     if (c > 3) cq_phi(.2);                       // a TAINTED phase region, merged
;     int s = 0;
;     if (argc > 1) s = (int)cq_measure(f(q));     // reads q; no gate on this path
;     else          cq_theta(&q, .3);              // the sibling arm rotates q
;     return s + (int)cq_measure(q) + (int)cq_measure(c);
;   }
;
; lowering_stale_speccall_classical_sibling_arm_accept.ll behind an unrelated tainted
; phase `if`. The classical arms are NOT control-dependent on the tainted branch (its
; region merges at %7), but `instUnderTaintedControl` said they were (dominated by
; the tainted branch's block, which they do not post-dominate), so the lifted call
; got the pure-op policy and declined. The policy now asks exact control dependence
; (`controlDependsOnTaintedBranch`: the iterated post-dominance frontier of the
; call's block holds no tainted br/switch). The lowered IR is byte-identical to
; main's for the C program, including main's one live-record warning (review probe
; p4_prior_phase_sibling, 2026-10-08).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck %s < %t.ll
;
; CHECK-LABEL: define i32 @main(
; CHECK:      %[[H:.*]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:      %[[R:.*]] = tail call i32 @__cq_q_f_1(i32 noundef %[[H]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[H]], double 3.000000e-01)

define i32 @f(i32 noundef %0) local_unnamed_addr #0 {
  %2 = mul nsw i32 %0, 3
  %3 = add nsw i32 %2, 1
  ret i32 %3
}

define i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #1 {
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #2
  %4 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 0x3FE6666666666666) #2
  %5 = icmp sgt i32 %4, 3
  br i1 %5, label %6, label %7

6:                                                ; preds = %2
  tail call void @cq_phi(double noundef 2.000000e-01) #3
  br label %7

7:                                                ; preds = %6, %2
  %8 = icmp sgt i32 %0, 1
  br i1 %8, label %9, label %12

9:                                                ; preds = %7
  %10 = tail call i32 @f(i32 noundef %3)
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #3
  br label %14

12:                                               ; preds = %7
  %13 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #2
  br label %14

14:                                               ; preds = %12, %9
  %15 = phi i32 [ %3, %9 ], [ %13, %12 ]
  %16 = phi i32 [ %11, %9 ], [ 0, %12 ]
  %17 = tail call i32 @cq_measure_si32(i32 noundef %15) #3
  %18 = add nsw i32 %17, %16
  %19 = tail call i32 @cq_measure_si32(i32 noundef %4) #3
  %20 = add nsw i32 %18, %19
  ret i32 %20
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare void @cq_phi(double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
