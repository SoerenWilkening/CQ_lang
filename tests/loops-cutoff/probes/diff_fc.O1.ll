; ModuleID = 'diff_fc.c'
source_filename = "diff_fc.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !6
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr i32 %5, 1
  br i1 %7, label %9, label %4, !llvm.loop !7

9:                                                ; preds = %4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !10
  tail call void @__cq_invert_end() #5
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %5) #6
  ret i32 %10
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #1

; Function Attrs: noduplicate
declare void @__cq_invert_begin() local_unnamed_addr #2

; Function Attrs: noduplicate
declare void @__cq_invert_end() local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #1

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_do(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !11
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %9, %4 ]
  %6 = phi i32 [ 3, %2 ], [ %8, %4 ]
  %7 = mul i32 %6, 5
  %8 = add i32 %7, %5
  %9 = lshr i32 %5, 1
  %10 = and i32 %5, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !12

12:                                               ; preds = %4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !13
  tail call void @__cq_invert_end() #5
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %8) #6
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_call(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !14
  %4 = tail call fastcc i32 @fc_g(i32 noundef %3)
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !15
  tail call void @__cq_invert_end() #5
  %5 = tail call i32 @cq_measure_ui32(i32 noundef %4) #6
  ret i32 %5
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @fc_g(i32 noundef %0) unnamed_addr #3 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %12, label %4

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %8, %4 ], [ 1, %1 ]
  %6 = phi i32 [ %9, %4 ], [ %0, %1 ]
  %7 = mul i32 %5, 3
  %8 = add i32 %7, %6
  %9 = lshr i32 %6, 1
  %10 = and i32 %6, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !16

12:                                               ; preds = %4, %1
  %13 = phi i32 [ 1, %1 ], [ %8, %4 ]
  ret i32 %13
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_trip(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !17
  %6 = and i32 %4, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %15, label %8

8:                                                ; preds = %3, %8
  %9 = phi i32 [ %12, %8 ], [ %5, %3 ]
  %10 = phi i32 [ %11, %8 ], [ %4, %3 ]
  %11 = lshr i32 %10, 1
  %12 = tail call i32 @cq_theta_ui32(i32 noundef %9, double noundef %2) #4
  %13 = and i32 %10, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %8, !llvm.loop !18

15:                                               ; preds = %8, %3
  %16 = phi i32 [ %4, %3 ], [ %11, %8 ]
  %17 = phi i32 [ %5, %3 ], [ %12, %8 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !19
  tail call void @__cq_invert_end() #5
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #6
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %16) #6
  %20 = add i32 %19, %18
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_cbound(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !20
  %5 = and i32 %1, 7
  %6 = icmp ne i32 %5, 0
  %7 = and i32 %4, 1
  %8 = icmp ne i32 %7, 0
  %9 = select i1 %6, i1 %8, i1 false
  br i1 %9, label %13, label %10

10:                                               ; preds = %13, %3
  %11 = phi i32 [ 1, %3 ], [ %18, %13 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !21
  tail call void @__cq_invert_end() #5
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %11) #6
  ret i32 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %20, %13 ], [ 0, %3 ]
  %15 = phi i32 [ %18, %13 ], [ 1, %3 ]
  %16 = phi i32 [ %19, %13 ], [ %4, %3 ]
  %17 = shl i32 %15, 1
  %18 = add i32 %17, %16
  %19 = lshr i32 %16, 1
  %20 = add nuw nsw i32 %14, 1
  %21 = icmp ult i32 %20, %5
  %22 = and i32 %16, 2
  %23 = icmp ne i32 %22, 0
  %24 = select i1 %21, i1 %23, i1 false
  br i1 %24, label %13, label %10, !llvm.loop !22
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_r6cls(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !23
  %5 = and i32 %1, 7
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %10, %3
  %8 = phi i32 [ 1, %3 ], [ %15, %10 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !24
  tail call void @__cq_invert_end() #5
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #6
  ret i32 %9

10:                                               ; preds = %3, %10
  %11 = phi i32 [ %17, %10 ], [ 0, %3 ]
  %12 = phi i32 [ %15, %10 ], [ 1, %3 ]
  %13 = phi i32 [ %16, %10 ], [ %4, %3 ]
  %14 = mul i32 %12, 3
  %15 = add i32 %14, %13
  %16 = lshr i32 %13, 1
  %17 = add nuw nsw i32 %11, 1
  %18 = icmp eq i32 %17, %5
  br i1 %18, label %7, label %10, !llvm.loop !25
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_r6bnd(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !26
  %5 = and i32 %1, 7
  %6 = icmp ne i32 %5, 0
  %7 = and i32 %4, 1
  %8 = icmp ne i32 %7, 0
  %9 = select i1 %6, i1 %8, i1 false
  br i1 %9, label %13, label %10

10:                                               ; preds = %13, %3
  %11 = phi i32 [ 1, %3 ], [ %17, %13 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !27
  tail call void @__cq_invert_end() #5
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %11) #6
  ret i32 %12

13:                                               ; preds = %3, %13
  %14 = phi i32 [ %19, %13 ], [ 0, %3 ]
  %15 = phi i32 [ %17, %13 ], [ 1, %3 ]
  %16 = phi i32 [ %18, %13 ], [ %4, %3 ]
  %17 = add i32 %15, %16
  %18 = lshr i32 %16, 1
  %19 = add nuw nsw i32 %14, 1
  %20 = icmp ult i32 %19, %5
  %21 = and i32 %16, 2
  %22 = icmp ne i32 %21, 0
  %23 = select i1 %20, i1 %22, i1 false
  br i1 %23, label %13, label %10, !llvm.loop !28
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_r6k(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !29
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %13, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %9, %6 ], [ 1, %2 ]
  %8 = phi i32 [ %10, %6 ], [ %3, %2 ]
  %9 = add i32 %7, %8
  %10 = lshr i32 %8, 1
  %11 = and i32 %8, 2
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %6, !llvm.loop !30

13:                                               ; preds = %6, %2
  %14 = phi i32 [ 1, %2 ], [ %9, %6 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !31
  tail call void @__cq_invert_end() #5
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %14) #6
  ret i32 %15
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_r6pre(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !32
  %6 = and i32 %4, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %15, label %8

8:                                                ; preds = %3, %8
  %9 = phi i32 [ %11, %8 ], [ %5, %3 ]
  %10 = phi i32 [ %12, %8 ], [ %4, %3 ]
  %11 = xor i32 %9, %10
  %12 = lshr i32 %10, 1
  %13 = and i32 %10, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %8, !llvm.loop !33

15:                                               ; preds = %8, %3
  %16 = phi i32 [ %5, %3 ], [ %11, %8 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !34
  tail call void @__cq_invert_end() #5
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %16) #6
  ret i32 %17
}

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { noduplicate "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { nomerge nounwind }
attributes #5 = { noduplicate nounwind }
attributes #6 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = !{i64 2147514425}
!7 = distinct !{!7, !8, !9}
!8 = !{!"llvm.loop.mustprogress"}
!9 = !{!"llvm.loop.unroll.disable"}
!10 = !{i64 2147514481}
!11 = !{i64 2147516350}
!12 = distinct !{!12, !8, !9}
!13 = !{i64 2147516406}
!14 = !{i64 2147518275}
!15 = !{i64 2147518331}
!16 = distinct !{!16, !8, !9}
!17 = !{i64 2147521215}
!18 = distinct !{!18, !8, !9}
!19 = !{i64 2147522286}
!20 = !{i64 2147524913}
!21 = !{i64 2147524969}
!22 = distinct !{!22, !8, !9}
!23 = !{i64 2147526838}
!24 = !{i64 2147526894}
!25 = distinct !{!25, !8, !9}
!26 = !{i64 2147528763}
!27 = !{i64 2147528819}
!28 = distinct !{!28, !8, !9}
!29 = !{i64 2147530688}
!30 = distinct !{!30, !8, !9}
!31 = !{i64 2147530744}
!32 = !{i64 2147533628}
!33 = distinct !{!33, !8, !9}
!34 = !{i64 2147533684}
