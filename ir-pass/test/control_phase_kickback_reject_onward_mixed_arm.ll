; control_phase_kickback_reject_onward_mixed_arm.ll — DECLINE. The SECOND
; reproducer of the Rule-13 round-1 CONFIRMED SILENT MISCOMPILE F-L3-1, and the
; half that makes the grading unambiguous: it was an OVER-ACCEPT of a shape the
; pre-3qlq oracle DECLINES LOUDLY (bd test_C_libtooling-3qlq Inc 1 part A, L3).
;
;     int slice(void) {
;         int q = 3; cq_theta(&q, 0.5);
;         int w = 9; cq_theta(&w, 0.2);
;         int y = 5;
;         if (q > 5) y = ext_f(7);                  // 6.5 classical-call arm -> %out
;         if (y > 50) { cq_phi(0.25); w = w + 1; }  // ONWARD: branch phase BESIDE a value arm
;         return cq_measure(w) + cq_measure(y);
;     }
;
; `clang -O1` + `llvm-link` verbatim, the shipped two-TU onward harness.
;
; BEFORE THE FIX: exit 0, STRICT stage 2b PASS, 29 trace lines, ZERO `cqrt_rz` of
; any width — and the trace ROUTED `w` under the very same flag
; (`icmp_sgt_i32_hl(h3,50) -> h6` … `cqrt_cswap(h6,h1,h7)` … `add_i32_hl(h7,1)`).
; So the compiler treated that branch as quantum-conditional while dropping the
; phase on it: the relative phase e^{i·0.25} between the (q>5) and (q<=5)
; components is simply absent. A different unitary at exit 0.
;
; The cause is F-L3-1's, exactly: `deleteGlobalPhases` ran BEFORE
; `repropagateControlMerges`, so the `cq_phi` was deleted as a global phase and
; round 2 then met a pure VALUE arm and lowered it. Two measured controls prove
; the acceptance came from the deletion and not from any deliberate widening —
; the same program with `cq_phi` removed from the SOURCE compiles to 23 lines,
; and the same arm content under a ROUND-1 tainted condition declines
; `impure value arm under quantum control`.
;
; AFTER THE FIX the phase survives into round 2, the arm is `{cq_phi, add}` — a
; MIXED arm — and the region declines with the message the round-1 control
; already produced. The oracle's old-surface twin declines too, with
; `mixed phase/value arm under quantum control`; the two spellings partition the
; same shape and both are loud, which is all the Prime Directive asks.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq controlled lowering: impure value arm under quantum control


; Function Attrs: nounwind ssp uwtable
define i32 @slice() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 9, double noundef 2.000000e-01) #3
  %3 = icmp sgt i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ 5, %0 ]
  %8 = icmp sgt i32 %7, 50
  br i1 %8, label %9, label %11

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  %10 = add nsw i32 %2, 1
  br label %11

11:                                               ; preds = %9, %6
  %12 = phi i32 [ %10, %9 ], [ %2, %6 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  %15 = add nsw i32 %14, %13
  ret i32 %15
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

declare void @cq_phi(double noundef) local_unnamed_addr #1

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main() local_unnamed_addr #0 {
  %1 = tail call i32 @cq_theta_si32(i32 noundef 3, double noundef 5.000000e-01) #3
  %2 = tail call i32 @cq_theta_si32(i32 noundef 9, double noundef 2.000000e-01) #3
  %3 = icmp sgt i32 %1, 5
  br i1 %3, label %4, label %6

4:                                                ; preds = %0
  %5 = tail call i32 @ext_f(i32 noundef 7) #3
  br label %6

6:                                                ; preds = %4, %0
  %7 = phi i32 [ %5, %4 ], [ 5, %0 ]
  %8 = icmp sgt i32 %7, 50
  br i1 %8, label %9, label %11

9:                                                ; preds = %6
  tail call void @cq_phi(double noundef 2.500000e-01) #3
  %10 = add nsw i32 %2, 1
  br label %11

11:                                               ; preds = %9, %6
  %12 = phi i32 [ %10, %9 ], [ %2, %6 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #3
  %14 = tail call i32 @cq_measure_si32(i32 noundef %7) #3
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define range(i32 -2147483548, -2147483648) i32 @ext_f(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 100
  ret i32 %2
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
