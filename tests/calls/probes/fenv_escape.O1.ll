; ModuleID = 'llvm-link'
source_filename = "llvm-link"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@fe_jb = global [37 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @fe_escape(double noundef %0, double noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = call double @cq_theta_f64(double noundef %0, double noundef %1) #6
  %5 = call i32 @setjmp(ptr noundef nonnull @fe_jb) #7
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = call i32 @fe_inner(double noundef %4, double noundef %2) #8
  %9 = add nsw i32 %8, 2
  br label %10

10:                                               ; preds = %7, %3
  %11 = phi i32 [ %9, %7 ], [ -1, %3 ]
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #8
  ret i32 %12
}

declare double @cq_theta_f64(double noundef, double noundef) local_unnamed_addr #1

; Function Attrs: returns_twice
declare i32 @setjmp(ptr noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: noinline nounwind ssp strictfp uwtable
define noundef i32 @fe_inner(double noundef %0, double noundef %1) local_unnamed_addr #3 {
  %3 = tail call double @llvm.experimental.constrained.fmul.f64(double %0, double 5.000000e-01, metadata !"round.dynamic", metadata !"fpexcept.strict") #9
  %4 = tail call i1 @llvm.experimental.constrained.fcmps.f64(double %3, double %1, metadata !"ogt", metadata !"fpexcept.strict") #9
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @fe_jb, i32 noundef 1) #10
  unreachable

6:                                                ; preds = %2
  ret i32 7
}

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare double @llvm.experimental.constrained.fmul.f64(double, double, metadata, metadata) #4

; Function Attrs: nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite)
declare i1 @llvm.experimental.constrained.fcmps.f64(double, double, metadata, metadata) #4

; Function Attrs: noreturn
declare void @longjmp(ptr noundef, i32 noundef) local_unnamed_addr #5

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { returns_twice "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp strictfp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind strictfp willreturn memory(inaccessiblemem: readwrite) }
attributes #5 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind returns_twice }
attributes #8 = { nounwind }
attributes #9 = { strictfp }
attributes #10 = { noreturn nounwind strictfp }

!llvm.ident = !{!0, !0}
!llvm.module.flags = !{!1, !2, !3, !4, !5}

!0 = !{!"Homebrew clang version 19.1.7"}
!1 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!2 = !{i32 1, !"wchar_size", i32 4}
!3 = !{i32 8, !"PIC Level", i32 2}
!4 = !{i32 7, !"uwtable", i32 2}
!5 = !{i32 7, !"frame-pointer", i32 2}
