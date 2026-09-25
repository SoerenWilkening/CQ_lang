; lowering_classical_mux_phi_onereg_spec_quantum_base_fp_rebuilt.ll — ACCEPT (bd
; test_C_libtooling-d88e, the SPEC-QUANTUM control whose lifted BASE IS ERASED).
;
; The f64 twin of `lowering_classical_mux_phi_onereg_spec_quantum_base.ll`: the
; library `hf` returns its QUANTUM `double` argument, so the clone's verdict is
; QUANTUM and the one-register lift of `phi(t, cq_theta(t, .2))` is a true
; renaming. What this file adds is the ERASE: a tainted fp return is an `i32`
; handle at the call site, so `specialize()`'s `retargetSite` REBUILDS the call
; (`double @hf` -> `i32 @__cq_q_hf_01`), RAUWs the old result onto the new one and
; ERASES the old call — which is the lift's recorded BASE and one of its recorded
; incomings. The record holds `WeakTrackingVH`s, so it FOLLOWS that RAUW and the
; re-ask (`declineFalsifiedMergePhiLifts`) finds the rebuilt, tainted handle and
; says nothing. A plain `WeakVH` (or a raw pointer) would null or dangle there and
; decline a correct module; this file is what turns that mutant red. Stream
; byte-identical to main `def1b088` (cq-opt `b1603d23`).
;
; Library TU (plain C, no CQ.h):
;   double hf(double a, double k) { return a + k; }
;
; Caller TU (clang -O1 -include CQ.h):
;   #include <stdlib.h>
;   double hf(double a, double k);
;   int main(int c, char **v) { double m = atof(v[1]); double q = cq_theta(m, .5); double t = hf(q, m); double r = t; if (m > 3) r = cq_theta(t, .2); return (int) cq_measure(r); }
;
; Regenerate: clang -O1 -emit-llvm -S the two TUs as above, then
;   llvm-link -S caller.ll lib.ll -o <this file's body>.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
; RUN:   | %filecheck %s
; CHECK-LABEL: define i32 @main(
; CHECK:      [[Q:%[a-z0-9.]+]] = call i32 @cqrt_alloc_f64(double %5)
; CHECK-NEXT: call void @cqrt_ry_f64(i32 [[Q]], double 5.000000e-01)
; CHECK-NEXT: [[T:%[0-9]+]] = call i32 @__cq_q_hf_01(i32 [[Q]], double %5)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call void @cqrt_ry_f64(i32 [[T]], double 2.000000e-01)
; CHECK-NOT:  cqrt_alloc
; CHECK:      call double @cqrt_measure_f64(i32 [[T]])

; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @main(i32 noundef %0, ptr nocapture noundef readonly %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds i8, ptr %1, i64 8
  %4 = load ptr, ptr %3, align 8, !tbaa !6
  %5 = tail call double @atof(ptr noundef %4)
  %6 = tail call double @cq_theta_f64(double noundef %5, double noundef 5.000000e-01) #4
  %7 = tail call double @hf(double noundef %6, double noundef %5) #4
  %8 = fcmp ogt double %5, 3.000000e+00
  br i1 %8, label %9, label %11

9:                                                ; preds = %2
  %10 = tail call double @cq_theta_f64(double noundef %7, double noundef 2.000000e-01) #4
  br label %11

11:                                               ; preds = %9, %2
  %12 = phi double [ %10, %9 ], [ %7, %2 ]
  %13 = tail call double @cq_measure_f64(double noundef %12) #4
  %14 = fptosi double %13 to i32
  ret i32 %14
}

; Function Attrs: mustprogress nofree nounwind willreturn memory(read)
declare double @atof(ptr nocapture noundef) local_unnamed_addr #1

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable
define noundef double @hf(double noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = fadd double %0, %1
  ret double %3
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
