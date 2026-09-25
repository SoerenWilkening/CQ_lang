; lowering_classical_mux_phi_onereg_spec_quantum_base.ll — ACCEPT (bd
; test_C_libtooling-d88e, the SPEC-QUANTUM positive control).
;
; The d88e decline family's exact caller (`lowering_reject_classical_mux_phi_spec_
; scrubbed_base.ll`) with the library `h` returning its QUANTUM argument. The
; clone's verdict is QUANTUM, `specialize()` scrubs nothing, and `t` really IS a
; register: the one-register lift of `phi(t, cq_theta(t, .2))` was a true
; renaming, so the re-ask after `specialize()` (`declineFalsifiedMergePhiLifts`)
; finds its recorded premise intact at FINAL taint and says nothing. The stream
; is byte-identical to main `def1b088` (cq-opt `b1603d23`): the arm's Ry fires IN
; PLACE on the clone's returned handle and the user's measurement reads that same
; handle — no fresh rail in the arm, one `cqrt_measure`.
;
; Library TU (plain C, no CQ.h):
;   int h(int a, int k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   int h(int a, int k);
;   int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (m > 3) r = cq_theta(t, .2); return cq_measure(r); }
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_i32(i32 %5)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = tail call i32 @__cq_q_h_01(i32 noundef [[Q]], i32 noundef %5)
; CHECK-NEXT: [[C:%[0-9]+]] = icmp sgt i32 %5, 3
; CHECK-NEXT: br i1 [[C]], label %[[ARM:[0-9]+]], label %[[JOIN:[0-9]+]]
; CHECK:      [[ARM]]:
; CHECK-NEXT: call void @cqrt_ry_i32(i32 [[T]], double 2.000000e-01)
; CHECK-NEXT: br label %[[JOIN]]
; CHECK:      [[JOIN]]:
; CHECK-NEXT: [[M:%[a-z0-9.]+]] = call i32 @cqrt_measure_i32(i32 [[T]])
; CHECK-NEXT: ret i32 [[M]]
; CHECK-NEXT: }
; CHECK-LABEL: define internal i32 @__cq_q_h_01(

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
  %8 = icmp sgt i32 %5, 3
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = tail call i32 @cq_theta_si32(i32 noundef %7, double noundef 2.000000e-01) #4
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi i32 [ %10, %9 ], [ %7, %2 ]
  %13 = tail call i32 @cq_measure_si32(i32 noundef %12) #4
  ret i32 %13
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
