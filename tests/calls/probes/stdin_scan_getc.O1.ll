; ModuleID = 'stdin_scan_getc.c'
source_filename = "stdin_scan_getc.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.str = private unnamed_addr constant [3 x i8] c"%d\00", align 1

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_scan_getc(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = alloca i32, align 4
  %3 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #5
  store i32 -1, ptr %2, align 4, !tbaa !6
  %4 = call i32 (ptr, ...) @scanf(ptr noundef nonnull @.str, ptr noundef nonnull %2)
  %5 = call i32 @getchar()
  %6 = sext i8 %3 to i32
  %7 = and i32 %6, 2
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %12, label %9

9:                                                ; preds = %1
  %10 = call i32 (ptr, ...) @scanf(ptr noundef nonnull @.str, ptr noundef nonnull %2)
  %11 = mul nsw i32 %10, 100
  br label %12

12:                                               ; preds = %9, %1
  %13 = phi i32 [ %11, %9 ], [ 0, %1 ]
  %14 = call i32 @getchar()
  %15 = mul nsw i32 %4, 1000
  %16 = load i32, ptr %2, align 4, !tbaa !6
  %17 = mul nsw i32 %16, 10
  %18 = mul nsw i32 %14, 3
  %19 = add i32 %15, %6
  %20 = add i32 %19, %5
  %21 = add i32 %20, %13
  %22 = add i32 %21, %18
  %23 = add i32 %22, %17
  %24 = call i32 @cq_measure_si32(i32 noundef %23) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #5
  ret i32 %24
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @scanf(ptr nocapture noundef readonly, ...) local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i32 @getchar() local_unnamed_addr #3

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!6 = !{!7, !7, i64 0}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
