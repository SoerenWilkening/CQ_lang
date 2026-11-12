; ModuleID = 'stdin_pred.c'
source_filename = "stdin_pred.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__stdinp = external local_unnamed_addr global ptr, align 8

; Function Attrs: nounwind ssp uwtable
define i32 @stdin_pred(i8 noundef signext %0) local_unnamed_addr #0 {
  %2 = alloca [4 x i8], align 4
  %3 = tail call signext i8 @cq_theta_si8(i8 noundef signext %0, double noundef 3.000000e-01) #4
  %4 = sext i8 %3 to i32
  %5 = and i32 %4, 1
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %1
  %8 = tail call i32 @getchar()
  %9 = mul nsw i32 %8, 7
  br label %10

10:                                               ; preds = %7, %1
  %11 = phi i32 [ %9, %7 ], [ 0, %1 ]
  %12 = tail call i32 @getchar()
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #5
  store i32 0, ptr %2, align 4
  %13 = load ptr, ptr @__stdinp, align 8, !tbaa !6
  %14 = call i64 @fread(ptr noundef nonnull %2, i64 noundef 1, i64 noundef 3, ptr noundef %13)
  %15 = mul nsw i32 %12, 3
  %16 = load i8, ptr %2, align 4, !tbaa !10
  %17 = sext i8 %16 to i32
  %18 = getelementptr inbounds i8, ptr %2, i64 2
  %19 = load i8, ptr %18, align 2, !tbaa !10
  %20 = sext i8 %19 to i32
  %21 = mul nsw i32 %20, 5
  %22 = add i32 %11, %4
  %23 = add i32 %22, %15
  %24 = add i32 %23, %17
  %25 = add i32 %24, %21
  %26 = tail call i32 @cq_measure_si32(i32 noundef %25) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #5
  ret i32 %26
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare signext i8 @cq_theta_si8(i8 noundef signext, double noundef) local_unnamed_addr #2

; Function Attrs: nofree nounwind
declare noundef i32 @getchar() local_unnamed_addr #3

; Function Attrs: nofree nounwind
declare noundef i64 @fread(ptr nocapture noundef, i64 noundef, i64 noundef, ptr nocapture noundef) local_unnamed_addr #3

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
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!8, !8, i64 0}
