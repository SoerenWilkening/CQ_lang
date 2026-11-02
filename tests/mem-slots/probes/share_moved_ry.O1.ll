; ModuleID = 'share_moved_ry.c'
source_filename = "share_moved_ry.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @share_moved_ry(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [2 x i32], align 4
  %5 = alloca [2 x i32], align 4
  %6 = alloca [2 x i32], align 4
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %4) #3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %5) #3
  call void @llvm.lifetime.start.p0(i64 8, ptr nonnull %6) #3
  %7 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 1.000000e+00) #4
  store i32 %7, ptr %4, align 4, !tbaa !6
  %8 = getelementptr inbounds i8, ptr %4, i64 4
  store i32 %7, ptr %8, align 4, !tbaa !6
  store i32 %7, ptr %5, align 4, !tbaa !6
  %9 = getelementptr inbounds i8, ptr %5, i64 4
  store i32 %7, ptr %9, align 4, !tbaa !6
  %10 = and i32 %1, 1
  %11 = zext nneg i32 %10 to i64
  %12 = getelementptr inbounds [2 x i32], ptr %4, i64 0, i64 %11
  %13 = load i32, ptr %12, align 4, !tbaa !6
  %14 = and i32 %0, 1
  %15 = zext nneg i32 %14 to i64
  %16 = getelementptr inbounds [2 x i32], ptr %6, i64 0, i64 %15
  store i32 %13, ptr %16, align 4, !tbaa !6
  %17 = xor i32 %14, 1
  %18 = zext nneg i32 %17 to i64
  %19 = getelementptr inbounds [2 x i32], ptr %6, i64 0, i64 %18
  store i32 0, ptr %19, align 4, !tbaa !6
  %20 = and i32 %2, 1
  %21 = zext nneg i32 %20 to i64
  %22 = getelementptr inbounds [2 x i32], ptr %6, i64 0, i64 %21
  %23 = load i32, ptr %22, align 4, !tbaa !6
  %24 = tail call i32 @cq_theta_si32(i32 noundef %23, double noundef 0x3FE6666666666666) #4
  store i32 %24, ptr %22, align 4, !tbaa !6
  %25 = tail call i32 @cq_measure_si32(i32 noundef %24) #3
  %26 = getelementptr inbounds [2 x i32], ptr %5, i64 0, i64 %21
  %27 = load i32, ptr %26, align 4, !tbaa !6
  %28 = tail call i32 @cq_measure_si32(i32 noundef %27) #3
  %29 = shl nsw i32 %28, 1
  %30 = add nsw i32 %29, %25
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %6) #3
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %5) #3
  call void @llvm.lifetime.end.p0(i64 8, ptr nonnull %4) #3
  ret i32 %30
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
attributes #3 = { nounwind }
attributes #4 = { nomerge nounwind }

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
; r[i & 1] takes a basis copy of the rail it loads from q (p still holds it), so the Ry acts on r's own rail.
; CHECK-COUNT share_moved_ry: call void @cqrt_copy_i32( 1
; USERCHECK share_moved_ry
