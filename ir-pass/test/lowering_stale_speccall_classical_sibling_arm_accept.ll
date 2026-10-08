; lowering_stale_speccall_classical_sibling_arm_accept.ll — ACCEPT (bd
; test_C_libtooling-r2j3.6, review round 1 F1: an over-decline regression of the
; first snapshot, 0c1c0697).
;
;   __attribute__((noinline)) int f(int x) { return x * 3 + 1; }
;   int main(int argc, char **argv) {
;     int q = 0; cq_theta(&q, .5);
;     int s = 0;
;     if (argc > 1) s = (int)cq_measure(f(q));   // reads q; no gate on this path
;     else          cq_theta(&q, .3);            // the SIBLING arm rotates q
;     return s + (int)cq_measure(q);
;   }
;
; A CLASSICAL branch: exactly one arm runs, so the lifted call never co-executes with
; the Ry. Main compiled this correctly; the first r2j3.6 snapshot asked the lifted
; call the PURE-OP question, whose `gateFollowsRead` needs the gate to post-dominate
; the read (a sibling arm never does), and declined. A lifted call off tainted control
; is now asked with WireWalk's reader policy (`RequireEmitDominance=false`, bd 3d8q's
; one spelling of path exclusivity: leg 1, `!isPotentiallyReachable(T, I)`). Its
; tainted-branch twin keeps the pure-op policy:
; lowering_stale_speccall_reject_tainted_sibling_arms.ll. The pure-op classical twin
; still declines (lowering_reject_stale_record_exclusive_arms.ll, its own increment).
; For the C program the lowered IR is byte-identical to main's (review probe
; p2_sibling, measured 2026-10-08). `opt` also prints one `non-diagonal gate
; over a live derived record` warning for the `.3` Ry: the late live-record pass
; does not see that the clone's rail lives only in the other arm. That warning is not
; this fence's, and this file does not pin it either way.
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
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %8

5:                                                ; preds = %2
  %6 = tail call i32 @f(i32 noundef %3)
  %7 = tail call i32 @cq_measure_si32(i32 noundef %6) #3
  br label %10

8:                                                ; preds = %2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 3.000000e-01) #2
  br label %10

10:                                               ; preds = %8, %5
  %11 = phi i32 [ %3, %5 ], [ %9, %8 ]
  %12 = phi i32 [ %7, %5 ], [ 0, %8 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %11) #3
  %14 = add nsw i32 %13, %12
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind }
attributes #2 = { nomerge nounwind }
attributes #3 = { nounwind }
