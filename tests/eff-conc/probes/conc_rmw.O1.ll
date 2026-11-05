; ModuleID = 'conc_rmw.c'
source_filename = "conc_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @p_rmw_qram(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [4 x i32], align 16
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #3
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %4) #4
  store i32 %2, ptr %4, align 16, !tbaa !6
  %6 = getelementptr inbounds i8, ptr %4, i64 4
  %7 = add nsw i32 %2, 1
  store i32 %7, ptr %6, align 4, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %4, i64 8
  %9 = add nsw i32 %2, 2
  store i32 %9, ptr %8, align 8, !tbaa !6
  %10 = getelementptr inbounds i8, ptr %4, i64 12
  %11 = add nsw i32 %2, 3
  store i32 %11, ptr %10, align 4, !tbaa !6
  %12 = and i32 %5, 3
  %13 = zext nneg i32 %12 to i64
  %14 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %13
  %15 = atomicrmw add ptr %14, i32 5 seq_cst, align 4
  %16 = add nsw i32 %5, 1
  %17 = and i32 %16, 3
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [4 x i32], ptr %4, i64 0, i64 %18
  %20 = cmpxchg ptr %19, i32 %2, i32 9 seq_cst seq_cst, align 4
  %21 = load i32, ptr %4, align 16, !tbaa !6
  %22 = add nsw i32 %21, %15
  %23 = load i32, ptr %6, align 4, !tbaa !6
  %24 = add nsw i32 %22, %23
  %25 = load i32, ptr %8, align 8, !tbaa !6
  %26 = add nsw i32 %24, %25
  %27 = load i32, ptr %10, align 4, !tbaa !6
  %28 = add nsw i32 %26, %27
  %29 = call i32 @cq_measure_si32(i32 noundef %28) #4
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %4) #4
  ret i32 %29
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nomerge nounwind }
attributes #4 = { nounwind }

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
