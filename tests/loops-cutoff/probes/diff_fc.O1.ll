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

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_add(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !35
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr i32 %5, 1
  br i1 %7, label %9, label %4, !llvm.loop !36

9:                                                ; preds = %4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !37
  tail call void @__cq_invert_end() #5
  %10 = add i32 %5, 3
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #6
  ret i32 %11
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_in(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !38
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %16, label %6

6:                                                ; preds = %2, %6
  %7 = phi i32 [ %11, %6 ], [ %3, %2 ]
  %8 = phi i32 [ %10, %6 ], [ 3, %2 ]
  %9 = mul i32 %8, 5
  %10 = add i32 %9, %7
  %11 = lshr i32 %7, 1
  %12 = and i32 %7, 2
  %13 = icmp eq i32 %12, 0
  br i1 %13, label %14, label %6, !llvm.loop !39

14:                                               ; preds = %6
  %15 = mul i32 %10, 7
  br label %16

16:                                               ; preds = %14, %2
  %17 = phi i32 [ 21, %2 ], [ %15, %14 ]
  %18 = phi i32 [ %3, %2 ], [ %11, %14 ]
  %19 = add i32 %17, %18
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !40
  tail call void @__cq_invert_end() #5
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #6
  ret i32 %20
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rcls(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %5 = xor i32 %0, 9
  %6 = tail call i32 @cq_theta_ui32(i32 noundef %5, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !41
  %7 = and i32 %1, 7
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %14

9:                                                ; preds = %14, %3
  %10 = phi i32 [ 1, %3 ], [ %19, %14 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !42
  tail call void @__cq_invert_end() #5
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %6) #6
  %12 = add i32 %11, %10
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %12) #6
  ret i32 %13

14:                                               ; preds = %3, %14
  %15 = phi i32 [ %21, %14 ], [ 0, %3 ]
  %16 = phi i32 [ %19, %14 ], [ 1, %3 ]
  %17 = phi i32 [ %20, %14 ], [ %4, %3 ]
  %18 = mul i32 %16, 3
  %19 = add i32 %18, %17
  %20 = lshr i32 %17, 1
  %21 = add nuw nsw i32 %15, 1
  %22 = icmp eq i32 %21, %7
  br i1 %22, label %9, label %14, !llvm.loop !43
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rclsin(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !44
  %5 = and i32 %1, 7
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %12

7:                                                ; preds = %12
  %8 = add i32 %17, 1
  br label %9

9:                                                ; preds = %7, %3
  %10 = phi i32 [ 2, %3 ], [ %8, %7 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !45
  tail call void @__cq_invert_end() #5
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #6
  ret i32 %11

12:                                               ; preds = %3, %12
  %13 = phi i32 [ %19, %12 ], [ 0, %3 ]
  %14 = phi i32 [ %17, %12 ], [ 1, %3 ]
  %15 = phi i32 [ %18, %12 ], [ %4, %3 ]
  %16 = mul i32 %14, 3
  %17 = add i32 %16, %15
  %18 = lshr i32 %15, 1
  %19 = add nuw nsw i32 %13, 1
  %20 = icmp eq i32 %19, %5
  br i1 %20, label %7, label %12, !llvm.loop !46
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rdo(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !47
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %9, %4 ]
  %6 = phi i32 [ 3, %2 ], [ %8, %4 ]
  %7 = mul i32 %6, 5
  %8 = add i32 %7, %5
  %9 = lshr i32 %5, 1
  %10 = and i32 %5, 2
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %4, !llvm.loop !48

12:                                               ; preds = %4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !49
  tail call void @__cq_invert_end() #5
  %13 = xor i32 %8, 5
  %14 = tail call i32 @cq_measure_ui32(i32 noundef %13) #6
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rnest(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !50
  %5 = and i32 %1, 3
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %3, %19
  %8 = phi i32 [ %21, %19 ], [ 0, %3 ]
  %9 = phi i32 [ %20, %19 ], [ %4, %3 ]
  br label %14

10:                                               ; preds = %19, %3
  %11 = phi i32 [ %4, %3 ], [ %20, %19 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !51
  tail call void @__cq_invert_end() #5
  %12 = mul i32 %11, 3
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %12) #6
  ret i32 %13

14:                                               ; preds = %14, %7
  %15 = phi i32 [ %18, %14 ], [ %9, %7 ]
  %16 = and i32 %15, 1
  %17 = icmp eq i32 %16, 0
  %18 = lshr i32 %15, 1
  br i1 %17, label %19, label %14, !llvm.loop !52

19:                                               ; preds = %14
  %20 = add i32 %15, 3
  %21 = add nuw nsw i32 %8, 1
  %22 = icmp eq i32 %21, %5
  br i1 %22, label %10, label %7, !llvm.loop !53
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rtwo(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !54
  br label %4

4:                                                ; preds = %4, %2
  %5 = phi i32 [ %3, %2 ], [ %8, %4 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr i32 %5, 1
  br i1 %7, label %9, label %4, !llvm.loop !55

9:                                                ; preds = %4
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !56
  tail call void @__cq_invert_end() #5
  %10 = add i32 %5, 3
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %10) #6
  %12 = mul i32 %5, 5
  %13 = tail call i32 @cq_measure_ui32(i32 noundef %12) #6
  %14 = add i32 %13, %11
  ret i32 %14
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rbk(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !57
  %4 = and i32 %3, 1
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %6, label %11

6:                                                ; preds = %11, %2
  %7 = phi i32 [ %3, %2 ], [ %15, %11 ]
  %8 = phi i32 [ 0, %2 ], [ %16, %11 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !58
  tail call void @__cq_invert_end() #5
  %9 = sub i32 %7, %8
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #6
  ret i32 %10

11:                                               ; preds = %2, %11
  %12 = phi i32 [ %17, %11 ], [ 0, %2 ]
  %13 = phi i32 [ %16, %11 ], [ 0, %2 ]
  %14 = phi i32 [ %15, %11 ], [ %3, %2 ]
  %15 = lshr i32 %14, 1
  %16 = add nuw nsw i32 %13, 2
  %17 = add nuw nsw i32 %12, 1
  %18 = icmp ult i32 %12, 8
  %19 = and i32 %14, 2
  %20 = icmp ne i32 %19, 0
  %21 = select i1 %18, i1 %20, i1 false
  br i1 %21, label %11, label %6, !llvm.loop !59
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rpre(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !60
  %4 = mul i32 %3, 3
  br label %5

5:                                                ; preds = %5, %2
  %6 = phi i32 [ %4, %2 ], [ %9, %5 ]
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  %9 = lshr i32 %6, 1
  br i1 %8, label %10, label %5, !llvm.loop !61

10:                                               ; preds = %5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !62
  tail call void @__cq_invert_end() #5
  %11 = add i32 %6, 3
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %11) #6
  ret i32 %12
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_rr6k(i32 noundef %0, double noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #4
  %4 = xor i32 %0, 9
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %4, double noundef %1) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !63
  %6 = and i32 %3, 1
  %7 = icmp eq i32 %6, 0
  br i1 %7, label %15, label %8

8:                                                ; preds = %2, %8
  %9 = phi i32 [ %11, %8 ], [ 1, %2 ]
  %10 = phi i32 [ %12, %8 ], [ %3, %2 ]
  %11 = add i32 %9, %10
  %12 = lshr i32 %10, 1
  %13 = and i32 %10, 2
  %14 = icmp eq i32 %13, 0
  br i1 %14, label %15, label %8, !llvm.loop !64

15:                                               ; preds = %8, %2
  %16 = phi i32 [ 1, %2 ], [ %11, %8 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !65
  tail call void @__cq_invert_end() #5
  %17 = tail call i32 @cq_measure_ui32(i32 noundef %5) #6
  %18 = xor i32 %17, %16
  %19 = tail call i32 @cq_measure_ui32(i32 noundef %18) #6
  ret i32 %19
}

; Function Attrs: nounwind ssp uwtable
define i32 @fc_inv_slrot(i32 noundef %0, i32 noundef %1, double noundef %2) local_unnamed_addr #0 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %2) #4
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %1, double noundef %2) #4
  tail call void @__cq_invert_begin() #5
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !66
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
  br i1 %14, label %15, label %8, !llvm.loop !67

15:                                               ; preds = %8, %3
  %16 = phi i32 [ %4, %3 ], [ %11, %8 ]
  %17 = phi i32 [ %5, %3 ], [ %12, %8 ]
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #6, !srcloc !68
  tail call void @__cq_invert_end() #5
  %18 = tail call i32 @cq_measure_ui32(i32 noundef %17) #6
  %19 = add i32 %16, 3
  %20 = tail call i32 @cq_measure_ui32(i32 noundef %19) #6
  %21 = add i32 %20, %18
  ret i32 %21
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
!6 = !{i64 2147518544}
!7 = distinct !{!7, !8, !9}
!8 = !{!"llvm.loop.mustprogress"}
!9 = !{!"llvm.loop.unroll.disable"}
!10 = !{i64 2147518600}
!11 = !{i64 2147520469}
!12 = distinct !{!12, !8, !9}
!13 = !{i64 2147520525}
!14 = !{i64 2147522394}
!15 = !{i64 2147522450}
!16 = distinct !{!16, !8, !9}
!17 = !{i64 2147525334}
!18 = distinct !{!18, !8, !9}
!19 = !{i64 2147526405}
!20 = !{i64 2147529032}
!21 = !{i64 2147529088}
!22 = distinct !{!22, !8, !9}
!23 = !{i64 2147530957}
!24 = !{i64 2147531013}
!25 = distinct !{!25, !8, !9}
!26 = !{i64 2147532882}
!27 = !{i64 2147532938}
!28 = distinct !{!28, !8, !9}
!29 = !{i64 2147534807}
!30 = distinct !{!30, !8, !9}
!31 = !{i64 2147534863}
!32 = !{i64 2147537747}
!33 = distinct !{!33, !8, !9}
!34 = !{i64 2147537803}
!35 = !{i64 2147539672}
!36 = distinct !{!36, !8, !9}
!37 = !{i64 2147539728}
!38 = !{i64 2147541605}
!39 = distinct !{!39, !8, !9}
!40 = !{i64 2147541661}
!41 = !{i64 2147544545}
!42 = !{i64 2147544601}
!43 = distinct !{!43, !8, !9}
!44 = !{i64 2147548620}
!45 = !{i64 2147548676}
!46 = distinct !{!46, !8, !9}
!47 = !{i64 2147550553}
!48 = distinct !{!48, !8, !9}
!49 = !{i64 2147550609}
!50 = !{i64 2147552486}
!51 = !{i64 2147552542}
!52 = distinct !{!52, !8, !9}
!53 = distinct !{!53, !8, !9}
!54 = !{i64 2147554419}
!55 = distinct !{!55, !8, !9}
!56 = !{i64 2147554475}
!57 = !{i64 2147557118}
!58 = !{i64 2147557174}
!59 = distinct !{!59, !8, !9}
!60 = !{i64 2147559051}
!61 = distinct !{!61, !8, !9}
!62 = !{i64 2147559107}
!63 = !{i64 2147561999}
!64 = distinct !{!64, !8, !9}
!65 = !{i64 2147562055}
!66 = !{i64 2147567089}
!67 = distinct !{!67, !8, !9}
!68 = !{i64 2147568160}
