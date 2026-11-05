; ModuleID = 'tests/eff-conc/probes/setjmp_host.c'
source_filename = "tests/eff-conc/probes/setjmp_host.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@twice = internal global [37 x i32] zeroinitializer, align 16

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjh_local(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [37 x i32], align 16
  %5 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 148, ptr nonnull %4) #7
  %6 = call i32 @setjmp(ptr noundef nonnull %4) #8
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %8, label %9

8:                                                ; preds = %3
  call fastcc void @leave(ptr noundef nonnull %4, i32 noundef %2)
  br label %9

9:                                                ; preds = %8, %3
  %10 = add nsw i32 %5, 1
  %11 = call i32 @cq_measure_si32(i32 noundef %10) #7
  %12 = add nsw i32 %11, %6
  call void @llvm.lifetime.end.p0(i64 148, ptr nonnull %4) #7
  ret i32 %12
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: returns_twice
declare i32 @setjmp(ptr noundef) local_unnamed_addr #3

; Function Attrs: noinline nounwind ssp uwtable
define internal fastcc void @leave(ptr noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %5, label %4

4:                                                ; preds = %2
  tail call void @longjmp(ptr noundef %0, i32 noundef %1) #9
  unreachable

5:                                                ; preds = %2
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjh_two(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  %5 = call i32 @setjmp(ptr noundef nonnull @twice) #8
  %6 = icmp eq i32 %5, 0
  %7 = icmp eq i32 %2, 1
  %8 = and i1 %7, %6
  br i1 %8, label %9, label %10

9:                                                ; preds = %3
  call void @longjmp(ptr noundef nonnull @twice, i32 noundef 5) #9
  unreachable

10:                                               ; preds = %3
  %11 = call i32 @setjmp(ptr noundef nonnull @twice) #8
  %12 = icmp eq i32 %11, 0
  %13 = icmp eq i32 %2, 2
  %14 = and i1 %13, %12
  br i1 %14, label %15, label %16

15:                                               ; preds = %10
  call void @longjmp(ptr noundef nonnull @twice, i32 noundef 7) #9
  unreachable

16:                                               ; preds = %10
  %17 = call i32 @cq_measure_si32(i32 noundef %4) #7
  %18 = add i32 %11, %5
  %19 = add i32 %18, %17
  ret i32 %19
}

; Function Attrs: noreturn
declare void @longjmp(ptr noundef, i32 noundef) local_unnamed_addr #5

; Function Attrs: nounwind ssp uwtable
define i32 @p_sjh_pred(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [37 x i32], align 16
  %5 = call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #6
  call void @llvm.lifetime.start.p0(i64 148, ptr nonnull %4) #7
  %6 = call i32 @setjmp(ptr noundef nonnull %4) #8
  %7 = icmp eq i32 %6, 0
  %8 = icmp sgt i32 %5, %2
  %9 = select i1 %7, i1 %8, i1 false
  br i1 %9, label %10, label %11

10:                                               ; preds = %3
  call void @longjmp(ptr noundef nonnull %4, i32 noundef 1) #9
  unreachable

11:                                               ; preds = %3
  %12 = call i32 @cq_measure_si32(i32 noundef %5) #7
  %13 = add nsw i32 %12, %6
  call void @llvm.lifetime.end.p0(i64 148, ptr nonnull %4) #7
  ret i32 %13
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { returns_twice "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { noreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }
attributes #8 = { nounwind returns_twice }
attributes #9 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
