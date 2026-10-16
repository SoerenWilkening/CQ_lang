; spec_accept_consume_param_imm.ll — ACCEPT, in place (bd test_C_libtooling-
; dm7f.83 / r2j3.37.1): the LIFTED half of the twin cell. `t = h(q, m)` with
; `h(a,k) = a + k`, `q` dead and rotated, `m` a classical parameter: the call is
; consumed, and the consumer's body applies `cqrt_addc_i32(t, k)` — `k` is a
; non-handle slot of the clone, classical by the specializer's handle mask, so the
; G4 worry (a rail in the immediate slot) cannot arise. The INLINED half is LOUD:
; lowering_mc_dead_register_param_imm_phi_reject.ll. RETIREMENT TRIGGER (dm7f.83
; follow-up): the cell closes when the inlined half accepts in place.
;
; Source: n3.c (lane L scratch), clang-19 -O1 -include CQ.h.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll 2> %t.err
; RUN: %filecheck %s < %t.ll
; RUN: %filecheck %s --check-prefix=ERR --allow-empty < %t.err
; ERR-NOT: error
; ERR-NOT: warning
;
; CHECK-LABEL: define {{.*}}i32 @slice(
; CHECK:      [[Q:%[a-z0-9]+]] = call i32 @cqrt_alloc_i32(i32 %0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: call void @__cq_q_h_01_c0(i32 [[Q]], i32 %0), !cq.inplace.qq
; CHECK-LABEL: define internal void @__cq_q_h_01_c0(i32 %0, i32 %1)
; CHECK-NEXT: call void @cqrt_addc_i32(i32 %0, i32 %1)
; CHECK-NEXT: ret void
source_filename = "n3.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @slice(i32 noundef %0) local_unnamed_addr #1 {
  %2 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef 5.000000e-01) #4
  %3 = tail call i32 @h(i32 noundef %2, i32 noundef %0)
  %4 = icmp sgt i32 %0, 3
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = tail call i32 @cq_theta_si32(i32 noundef %3, double noundef 2.000000e-01) #4
  br label %7

7:                                                ; preds = %5, %1
  %8 = phi i32 [ %6, %5 ], [ %3, %1 ]
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #5
  ret i32 %9
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define noundef i32 @main(i32 noundef %0, ptr nocapture noundef readnone %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %0, 4
  %4 = tail call i32 @slice(i32 noundef %3)
  ret i32 0
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
