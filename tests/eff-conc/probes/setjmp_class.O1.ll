; ModuleID = 'setjmp_class.c'
source_filename = "setjmp_class.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@j1 = internal global [37 x i32] zeroinitializer, align 16
@j2 = internal global [37 x i32] zeroinitializer, align 16
@j3 = internal global [37 x i32] zeroinitializer, align 16
@j4 = internal global [37 x i32] zeroinitializer, align 16
@j5a = internal global [37 x i32] zeroinitializer, align 16
@j5b = internal global [37 x i32] zeroinitializer, align 16
@j6 = internal global [37 x i32] zeroinitializer, align 16
@j7 = internal global [37 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjc_samefn(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @j1) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %12

7:                                                ; preds = %3
  %8 = icmp sgt i32 %4, %2
  br i1 %8, label %9, label %10

9:                                                ; preds = %7
  call void @longjmp(ptr noundef nonnull @j1, i32 noundef 2) #7
  unreachable

10:                                               ; preds = %7
  %11 = add nsw i32 %4, 1
  br label %12

12:                                               ; preds = %3, %10
  %13 = phi i32 [ %11, %10 ], [ 7, %3 ]
  %14 = call i32 @cq_measure_si32(i32 noundef %13) #8
  ret i32 %14
}

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: returns_twice
declare i32 @setjmp(ptr noundef) local_unnamed_addr #2

; Function Attrs: noreturn
declare void @longjmp(ptr noundef, i32 noundef) local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjc_depth3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @j2) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = call fastcc i32 @a3(i32 noundef %4, i32 noundef %2)
  br label %9

9:                                                ; preds = %3, %7
  %10 = phi i32 [ %8, %7 ], [ -5, %3 ]
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #8
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @a3(i32 noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = add nsw i32 %0, 1
  %4 = tail call fastcc i32 @b3(i32 noundef %3, i32 noundef %1)
  %5 = xor i32 %4, 6
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjc_value(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @j3) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = call fastcc i32 @f3(i32 noundef %4, i32 noundef %2)
  br label %11

9:                                                ; preds = %3
  %10 = mul nsw i32 %5, 10
  br label %11

11:                                               ; preds = %9, %7
  %12 = phi i32 [ %8, %7 ], [ %10, %9 ]
  %13 = call i32 @cq_measure_si32(i32 noundef %12) #8
  ret i32 %13
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483646, -2147483648) i32 @f3(i32 noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = icmp sgt i32 %0, %1
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = and i32 %0, 3
  tail call void @longjmp(ptr noundef nonnull @j3, i32 noundef %5) #7
  unreachable

6:                                                ; preds = %2
  %7 = add nsw i32 %0, 2
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjc_retry(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @j4) #6
  %6 = icmp slt i32 %5, 3
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = call fastcc i32 @g4(i32 noundef %4, i32 noundef %5)
  %9 = add nsw i32 %8, %2
  br label %10

10:                                               ; preds = %7, %3
  %11 = phi i32 [ %9, %7 ], [ -1, %3 ]
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #8
  ret i32 %12
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483648, 5) i32 @g4(i32 noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = icmp sgt i32 %0, %1
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = add nsw i32 %1, 1
  tail call void @longjmp(ptr noundef nonnull @j4, i32 noundef %5) #7
  unreachable

6:                                                ; preds = %2
  %7 = shl nsw i32 %0, 1
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjc_two(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @j5a) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %12

7:                                                ; preds = %3
  %8 = call i32 @setjmp(ptr noundef nonnull @j5b) #6
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %12

10:                                               ; preds = %7
  %11 = call fastcc i32 @h5(i32 noundef %4, i32 noundef %2)
  br label %12

12:                                               ; preds = %3, %7, %10
  %13 = phi i32 [ %4, %10 ], [ 1, %7 ], [ 2, %3 ]
  %14 = call i32 @cq_measure_si32(i32 noundef %13) #8
  ret i32 %14
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483647, -2147483648) i32 @h5(i32 noundef returned %0, i32 noundef %1) unnamed_addr #4 {
  %3 = icmp sgt i32 %0, %1
  br i1 %3, label %4, label %5

4:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @j5a, i32 noundef 1) #7
  unreachable

5:                                                ; preds = %2
  %6 = sub nsw i32 0, %1
  %7 = icmp sgt i32 %6, %0
  br i1 %7, label %8, label %9

8:                                                ; preds = %5
  tail call void @longjmp(ptr noundef nonnull @j5b, i32 noundef 1) #7
  unreachable

9:                                                ; preds = %5
  ret i32 %0
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjc_ptr(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @j6) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %3
  %8 = call fastcc i32 @f6(i32 noundef %4, i32 noundef %2)
  br label %9

9:                                                ; preds = %3, %7
  %10 = phi i32 [ %8, %7 ], [ 0, %3 ]
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #8
  ret i32 %11
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc range(i32 -2147483639, -2147483648) i32 @f6(i32 noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = icmp eq i32 %0, %1
  br i1 %3, label %4, label %5

4:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @j6, i32 noundef 1) #7
  unreachable

5:                                                ; preds = %2
  %6 = add nsw i32 %0, 9
  ret i32 %6
}

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjc_loop(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %5 = call i32 @setjmp(ptr noundef nonnull @j7) #6
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %3
  %8 = call fastcc i32 @f7(i32 noundef %4)
  %9 = add nsw i32 %8, %2
  br label %10

10:                                               ; preds = %3, %7
  %11 = phi i32 [ %9, %7 ], [ 3, %3 ]
  %12 = call i32 @cq_measure_si32(i32 noundef %11) #8
  ret i32 %12
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc noundef i32 @f7(i32 noundef %0) unnamed_addr #4 {
  %2 = icmp ult i32 %0, 4
  br i1 %2, label %5, label %3

3:                                                ; preds = %1
  %4 = shl i32 %0, 2
  ret i32 %4

5:                                                ; preds = %1
  tail call void @longjmp(ptr noundef nonnull @j7, i32 noundef 1) #7
  unreachable
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @b3(i32 noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = tail call fastcc i32 @c3(i32 noundef %0, i32 noundef %1)
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %4, %0
  ret i32 %5
}

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc i32 @c3(i32 noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = icmp sgt i32 %0, %1
  br i1 %3, label %4, label %5

4:                                                ; preds = %2
  tail call void @longjmp(ptr noundef nonnull @j2, i32 noundef 1) #7
  unreachable

5:                                                ; preds = %2
  %6 = sub nsw i32 %0, %1
  ret i32 %6
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { returns_twice "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind returns_twice }
attributes #7 = { noreturn nounwind }
attributes #8 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
