; /* tests/spine probe (CR rule 6 "A seed (rule 7) is freed directly instead"; cq-181j p6a, cq-4yzy collapse2): fetestexcept after
;  * its flags' sources are measured is the host call, seeded where taint records the flags quantum; `+ a` reads the seed.
;  * The seed is freed directly, never rule-6-cleaned by a copy (which left it in no known basis state: the verifier's
;  * free-without-unc).
;  * Regenerate seed_freed_directly.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h seed_freed_directly.c */
; USERCHECK collapse_in_arm
; CHECK-COUNT p6d: cqrt_copy_i32 0
; CHECK-COUNT p6d: cq_template_sub_i32 0
; ModuleID = 'seed_freed_directly.c'
source_filename = "seed_freed_directly.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @collapse_in_arm(i32 noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %1, double noundef %3) #3
  %6 = icmp eq i32 %0, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %4
  %8 = tail call double @llvm.experimental.constrained.fmul.f64(double %5, double %2, metadata !"round.dynamic", metadata !"fpexcept.strict") #4
  %9 = tail call double @cq_measure_f64(double noundef %5) #5
  br label %10

10:                                               ; preds = %7, %4
  %11 = phi double [ %8, %7 ], [ 0.000000e+00, %4 ]
  %12 = tail call i32 @fetestexcept(i32 noundef 63) #5
  %13 = tail call double @cq_measure_f64(double noundef %11) #5
  %14 = tail call i32 @llvm.experimental.constrained.fptosi.i32.f64(double %13, metadata !"fpexcept.strict") #4
  %15 = add nsw i32 %14, %12
  ret i32 %15
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #2

declare double @cq_measure_f64(double noundef) local_unnamed_addr #1

declare i32 @fetestexcept(i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i32 @llvm.experimental.constrained.fptosi.i32.f64(double, metadata) #2

; Function Attrs: nounwind ssp strictfp uwtable
define i32 @p6d(double noundef %0, double noundef %1, double noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call double @cq_theta_f64(double noundef %0, double noundef %1) #3
  %6 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %5, double %2, metadata !"ogt", metadata !"fpexcept.strict") #4
  br i1 %6, label %7, label %9

7:                                                ; preds = %4
  %8 = tail call i32 @feraiseexcept(i32 noundef 8) #5
  br label %9

9:                                                ; preds = %7, %4
  %10 = tail call double @cq_measure_f64(double noundef %5) #5
  %11 = tail call i32 @fetestexcept(i32 noundef 63) #5
  %12 = add nsw i32 %11, %3
  ret i32 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #2

declare i32 @feraiseexcept(i32 noundef) local_unnamed_addr #1

attributes #0 = { nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #3 = { nomerge nounwind strictfp }
attributes #4 = { strictfp }
attributes #5 = { nounwind strictfp }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
