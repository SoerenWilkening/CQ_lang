; ModuleID = 'forward_cell.c'
source_filename = "forward_cell.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fwd_once(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = alloca [1 x i32], align 4
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %4) #6
  %6 = add nsw i32 %5, %2
  call fastcc void @put(ptr noundef nonnull %4, i32 noundef %6)
  %7 = load i32, ptr %4, align 4, !tbaa !6
  %8 = mul nsw i32 %7, 3
  %9 = tail call i32 @cq_measure_si32(i32 noundef %8) #6
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %4) #6
  ret i32 %9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @put(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #3 {
  store i32 %1, ptr %0, align 4, !tbaa !6
  ret void
}

declare i32 @cq_measure_si32(i32 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

; Function Attrs: nounwind ssp uwtable
define i32 @fwd_loop(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = tail call i32 @cq_theta_si32(i32 noundef %0, double noundef %1) #5
  %6 = icmp sgt i32 %3, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %4
  %8 = zext i32 %2 to i64
  br label %12

9:                                                ; preds = %12, %4
  %10 = phi i32 [ 0, %4 ], [ %19, %12 ]
  %11 = tail call i32 @cq_measure_si32(i32 noundef %10) #6
  ret i32 %11

12:                                               ; preds = %7, %12
  %13 = phi i32 [ 0, %7 ], [ %19, %12 ]
  %14 = phi i32 [ 0, %7 ], [ %20, %12 ]
  %15 = tail call ptr @llvm.stacksave.p0()
  %16 = alloca i32, i64 %8, align 16
  %17 = xor i32 %14, %5
  call fastcc void @put2(ptr noundef nonnull %16, i32 noundef %17)
  %18 = load i32, ptr %16, align 16, !tbaa !6
  %19 = sub nsw i32 %13, %18
  tail call void @llvm.stackrestore.p0(ptr %15)
  %20 = add nuw nsw i32 %14, 1
  %21 = icmp eq i32 %20, %3
  br i1 %21, label %9, label %12, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare ptr @llvm.stacksave.p0() #4

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable
define internal fastcc void @put2(ptr nocapture noundef writeonly %0, i32 noundef %1) unnamed_addr #3 {
  store i32 %1, ptr %0, align 4, !tbaa !6
  ret void
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.stackrestore.p0(ptr) #4

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #5 = { nomerge nounwind }
attributes #6 = { nounwind }

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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
