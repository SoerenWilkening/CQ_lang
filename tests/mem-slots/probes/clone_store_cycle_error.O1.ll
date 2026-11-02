; ModuleID = 'clone_store_cycle_error.c'
source_filename = "clone_store_cycle_error.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @clone_store_cycle_error(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca i32, align 4
  %3 = tail call i32 @cq_theta_si32(i32 noundef 0, double noundef 5.000000e-01) #4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #5
  %4 = mul nsw i32 %3, 3
  store i32 %4, ptr %2, align 4, !tbaa !6
  %5 = add nsw i32 %0, 3
  %6 = and i32 %5, 15
  call fastcc void @w(ptr noundef nonnull %2, i32 noundef %3, i32 noundef %6)
  %7 = load i32, ptr %2, align 4, !tbaa !6
  %8 = ashr i32 %0, 4
  %9 = xor i32 %7, %8
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #5
  ret i32 %9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr nocapture) #1

declare i32 @cq_theta_si32(i32 noundef, double noundef) local_unnamed_addr #2

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(argmem: write) uwtable
define internal fastcc void @w(ptr nocapture noundef writeonly %0, i32 noundef %1, i32 noundef %2) unnamed_addr #3 {
  br label %5

4:                                                ; preds = %12
  ret void

5:                                                ; preds = %3, %12
  %6 = phi i32 [ 0, %3 ], [ %13, %12 ]
  %7 = shl nuw nsw i32 1, %6
  %8 = and i32 %7, %2
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %12, label %10

10:                                               ; preds = %5
  %11 = add nsw i32 %6, %1
  store i32 %11, ptr %0, align 4, !tbaa !6
  br label %12

12:                                               ; preds = %5, %10
  %13 = add nuw nsw i32 %6, 1
  %14 = icmp eq i32 %13, 4
  br i1 %14, label %4, label %5, !llvm.loop !10
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr nocapture) #1

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(argmem: write) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
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
!10 = distinct !{!10, !11, !12}
!11 = !{!"llvm.loop.mustprogress"}
!12 = !{!"llvm.loop.unroll.disable"}
; EXPECT-ERROR: or itself on a cycle (two slot results for one cell)
