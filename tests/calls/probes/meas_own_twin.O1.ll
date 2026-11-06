; ModuleID = 'tests/calls/probes/meas_own_twin.c'
source_filename = "tests/calls/probes/meas_own_twin.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable
define range(i64 -256, 255) i64 @rd(ptr nocapture noundef readonly %0) local_unnamed_addr #0 {
  %2 = load i8, ptr %0, align 1
  %3 = sext i8 %2 to i64
  %4 = getelementptr inbounds i8, ptr %0, i64 1
  %5 = load i8, ptr %4, align 1
  %6 = sext i8 %5 to i64
  %7 = add nsw i64 %6, %3
  ret i64 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @f(i8 noundef signext %0) local_unnamed_addr #1 {
  %2 = alloca [2 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %2) #4
  store i8 %0, ptr %2, align 1
  %3 = getelementptr inbounds i8, ptr %2, i64 1
  store i8 0, ptr %3, align 1
  %4 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #5
  store i8 %4, ptr %2, align 1
  %5 = call i64 @rd(ptr noundef nonnull %2)
  %6 = tail call i64 @cq_measure_sl(i64 noundef %5) #4
  %7 = trunc i64 %6 to i32
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %2) #4
  ret i32 %7
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #2

declare signext i8 @cq_theta_c(i8 noundef signext, double noundef) local_unnamed_addr #3

declare i64 @cq_measure_sl(i64 noundef) local_unnamed_addr #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #2

; Function Attrs: nounwind ssp uwtable
define i32 @g(i8 noundef signext %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = alloca [2 x i8], align 1
  call void @llvm.lifetime.start.p0(i64 2, ptr nonnull %3) #4
  store i8 %0, ptr %3, align 1
  %4 = getelementptr inbounds i8, ptr %3, i64 1
  store i8 0, ptr %4, align 1
  %5 = tail call signext i8 @cq_theta_c(i8 noundef signext %0, double noundef 3.000000e-01) #5
  store i8 %5, ptr %3, align 1
  %6 = call i64 @rd(ptr noundef nonnull %3)
  switch i32 %1, label %15 [
    i32 1, label %7
    i32 2, label %11
  ]

7:                                                ; preds = %2
  %8 = tail call i64 @cq_measure_sl(i64 noundef %6) #4
  %9 = trunc i64 %8 to i32
  %10 = add nsw i32 %9, 1
  br label %15

11:                                               ; preds = %2
  %12 = tail call i64 @cq_measure_sl(i64 noundef %6) #4
  %13 = trunc i64 %12 to i32
  %14 = mul nsw i32 %13, 3
  br label %15

15:                                               ; preds = %2, %11, %7
  %16 = phi i32 [ %10, %7 ], [ %14, %11 ], [ 0, %2 ]
  call void @llvm.lifetime.end.p0(i64 2, ptr nonnull %3) #4
  ret i32 %16
}

attributes #0 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: read) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind }
attributes #5 = { nomerge nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
