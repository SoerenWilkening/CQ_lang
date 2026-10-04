; lowering_classical_mux_phi_onereg_spec_quantum_base_switch_nway.ll — ACCEPT (bd
; test_C_libtooling-d88e, the SPEC-QUANTUM positive control at N=3).
;
; The N=3 `switch` twin of `lowering_reject_classical_mux_phi_spec_scrubbed_base_
; switch_nway_all_arms.ll` with the library `h` returning its QUANTUM argument:
; every edge (default included) rotates, the 3-incoming lift is a true renaming,
; and the re-ask after `specialize()` keeps it. Stream byte-identical to main
; `def1b088` (cq-opt `b1603d23`): each edge's Ry chain fires IN PLACE on the
; clone's returned handle, one measurement of that handle, no phi left.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = m; cq_theta(&q, .5); int t = h(q, m); int r; switch (m) { case 1: r = t; cq_theta(&r, .2); break; case 2: r = t; cq_theta(&r, .4); cq_theta(&r, .1); break; default: r = t; cq_theta(&r, .6); cq_theta(&r, .3); break; } return cq_measure(r); }
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_i32(i32 [[T]], double 2.000000e-01)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_i32(i32 [[T]], double 4.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 1.000000e-01)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_i32(i32 [[T]], double 6.000000e-01)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 3.000000e-01)
; CHECK-NOT:  {{phi|cqrt_alloc}}
; CHECK:      [[M:%[a-z0-9.]+]] = call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NEXT: }

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call i32 @atoi(ptr nocapture noundef %4)
  %6 = tail call i32 @cq_theta_si32(i32 noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call i32 @h(i32 noundef %6, i32 noundef %5) #4
  switch i32 %5, label %13 [
    i32 1, label %8
    i32 2, label %10
  ]

8:                                                ; preds = %2
  %9 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.000000e-01) #4
  br label %16

10:                                               ; preds = %2
  %11 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 4.000000e-01) #4
  %12 = tail call i32 @cq_theta_si32(i32 noundef %11, double noundef 1.000000e-01) #4
  br label %16

13:                                               ; preds = %2
  %14 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 6.000000e-01) #4
  %15 = tail call i32 @cq_theta_si32(i32 noundef %14, double noundef 3.000000e-01) #4
  br label %16

16:                                               ; preds = %13, %10, %8
  %17 = phi i32 [ %15, %13 ], [ %12, %10 ], [ %9, %8 ]
  %18 = tail call i32 @cq_measure_si32(i32 noundef %17) #4
  ret i32 %18
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare i32 @atoi(ptr nocapture noundef) local_unnamed_addr #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define i32 @h(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn memory(read) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
!6 = !{!7, !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
