; ModuleID = 'setjmp.c'
source_filename = "setjmp.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@jb1 = internal global [37 x i32] zeroinitializer, align 16
@jb2 = internal global [37 x i32] zeroinitializer, align 16
@jb3 = internal global [37 x i32] zeroinitializer, align 16
@jb4 = internal global [37 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @p_sj_scalar(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @jb1) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = call fastcc i32 @sq(i32 noundef %4, i32 noundef %2)
  %9 = xor i32 %8, 5
  br label %10

10:                                               ; preds = %3, %7
  %11 = phi i32 [ %9, %7 ], [ 9, %3 ]
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #7
  ret i32 %12
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: returns_twice
declare i32 @setjmp(ptr noundef) local_unnamed_addr #2

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483648, 2147483645) i32 @sq(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = icmp sgt i32 %0, %1
  br i1 %3, label %4, label %5

4:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @jb1, i32 noundef 7) #8
  unreachable

5:                                                ; preds = %2
  %6 = mul nsw i32 %0, %0
  %7 = add nsw i32 %6, -3
  ret i32 %7
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_sj_void(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @jb2) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  call fastcc void @check(i32 noundef %4, i32 noundef %2)
  %8 = add nsw i32 %4, 1
  br label %9

9:                                                ; preds = %3, %7
  %10 = phi i32 [ %8, %7 ], [ 0, %3 ]
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #7
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @check(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = icmp slt i32 %0, %1
  br i1 %3, label %4, label %5

4:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @jb2, i32 noundef 0) #8
  unreachable

5:                                                ; preds = %2
  ret void
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_sj_classical(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @jb3) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = call fastcc i32 @kk(i32 noundef %4, i32 noundef %2)
  br label %9

9:                                                ; preds = %3, %7
  %10 = phi i32 [ %8, %7 ], [ -2, %3 ]
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #7
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483644, -2147483648) i32 @kk(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = icmp eq i32 %0, %1
  br i1 %3, label %4, label %5

4:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @jb3, i32 noundef 1) #8
  unreachable

5:                                                ; preds = %2
  %6 = add nsw i32 %1, 4
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_sj_qarm(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @jb4) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = call fastcc i32 @dbl(i32 noundef %4, i32 noundef %2)
  %9 = add nsw i32 %8, 1
  br label %10

10:                                               ; preds = %3, %7
  %11 = phi i32 [ %9, %7 ], [ %4, %3 ]
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #7
  ret i32 %12
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @dbl(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = and i32 %0, 3
  %4 = icmp eq i32 %3, %1
  br i1 %4, label %5, label %6

5:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @jb4, i32 noundef 1) #8
  unreachable

6:                                                ; preds = %2
  %7 = shl nsw i32 %0, 1
  ret i32 %7
}

; Function Attrs: noreturn
declare void @longjmp(ptr noundef, i32 noundef) local_unnamed_addr #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { returns_twice "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind returns_twice }
attributes #7 = { nounwind }
attributes #8 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
