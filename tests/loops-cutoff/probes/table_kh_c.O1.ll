; ModuleID = 'table_kh.c'
source_filename = "table_kh.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_k_h1 = internal constant i32 2, align 4
@__cq_k_h2 = internal constant i32 2, align 4
@__cq_k_h3 = internal constant i32 2, align 4
@__cq_k_h6 = internal constant i32 2, align 4
@__cq_k_h1o = internal constant i32 4, align 4
@__cq_k_h2o = internal constant i32 4, align 4
@__cq_k_t2 = internal constant i32 2, align 4
@__cq_k_r6 = internal constant i32 2, align 4
@__cq_k_t5 = internal constant i32 3, align 4
@__cq_k_h5 = internal constant i32 3, align 4
@__cq_k_g3k = internal constant i32 3, align 4
@p1 = global ptr @t1, align 8
@p2 = global ptr @t2, align 8
@p3 = global ptr @t3, align 8
@p6 = global ptr @t6, align 8
@p5 = global ptr @t5, align 8
@__cq_k_kh_1 = internal constant i32 2, align 4
@__cq_k_kh_2 = internal constant i32 2, align 4
@__cq_k_kh_3 = internal constant i32 2, align 4
@__cq_k_kh_6 = internal constant i32 2, align 4
@__cq_k_kh_r6 = internal constant i32 2, align 4
@__cq_k_kh_cls = internal constant i32 2, align 4
@__cq_k_kh_twin = internal constant i32 2, align 4
@__cq_k_kh_after = internal constant i32 2, align 4
@__cq_k_kh_seq = internal constant i32 2, align 4
@llvm.used = appending global [20 x ptr] [ptr @__cq_k_g3k, ptr @__cq_k_h1, ptr @__cq_k_h1o, ptr @__cq_k_h2, ptr @__cq_k_h2o, ptr @__cq_k_h3, ptr @__cq_k_h5, ptr @__cq_k_h6, ptr @__cq_k_kh_1, ptr @__cq_k_kh_2, ptr @__cq_k_kh_3, ptr @__cq_k_kh_6, ptr @__cq_k_kh_after, ptr @__cq_k_kh_cls, ptr @__cq_k_kh_r6, ptr @__cq_k_kh_seq, ptr @__cq_k_kh_twin, ptr @__cq_k_r6, ptr @__cq_k_t2, ptr @__cq_k_t5], section "llvm.metadata"

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t1(i32 noundef %0, i32 noundef %1) #0 {
  %3 = tail call fastcc i32 @h1(i32 noundef %0, i32 noundef %1)
  %4 = add i32 %3, 1
  ret i32 %4
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t2(i32 noundef %0, i64 noundef %1) #0 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %15

4:                                                ; preds = %2
  %5 = trunc i64 %1 to i32
  br label %6

6:                                                ; preds = %4, %6
  %7 = phi i32 [ 0, %4 ], [ %11, %6 ]
  %8 = phi i32 [ %0, %4 ], [ %10, %6 ]
  %9 = mul i32 %8, %5
  %10 = add i32 %9, 1
  %11 = add i32 %7, 1
  %12 = icmp ugt i32 %10, 9
  br i1 %12, label %6, label %13, !llvm.loop !6

13:                                               ; preds = %6
  %14 = mul i32 %11, 100
  br label %15

15:                                               ; preds = %13, %2
  %16 = phi i32 [ %0, %2 ], [ %10, %13 ]
  %17 = phi i32 [ 0, %2 ], [ %14, %13 ]
  %18 = tail call fastcc i32 @h2(i32 noundef %16)
  %19 = add i32 %18, %17
  ret i32 %19
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t3(i32 noundef %0, i16 noundef zeroext %1) #0 {
  %3 = zext i16 %1 to i32
  %4 = tail call fastcc i32 @h3(i32 noundef %0, i32 noundef %3)
  %5 = xor i32 %4, 5
  ret i32 %5
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal range(i64 0, 4294967296) i64 @t6(i32 noundef %0, i32 noundef %1) #0 {
  %3 = tail call fastcc i32 @h6(i32 noundef %0, i32 noundef %1)
  %4 = zext i32 %3 to i64
  ret i64 %4
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t5(i32 noundef %0, i8 noundef zeroext %1) #0 {
  %3 = zext i8 %1 to i32
  %4 = add nuw nsw i32 %3, 1
  %5 = tail call fastcc i32 @h5(i32 noundef %0, i32 noundef %4)
  %6 = icmp ugt i32 %0, 9
  br i1 %6, label %7, label %16

7:                                                ; preds = %2, %7
  %8 = phi i32 [ %12, %7 ], [ 0, %2 ]
  %9 = phi i32 [ %11, %7 ], [ %0, %2 ]
  %10 = mul i32 %9, %3
  %11 = add i32 %10, 1
  %12 = add i32 %8, 1
  %13 = icmp ugt i32 %11, 9
  br i1 %13, label %7, label %14, !llvm.loop !9

14:                                               ; preds = %7
  %15 = mul i32 %12, 100
  br label %16

16:                                               ; preds = %14, %2
  %17 = phi i32 [ 0, %2 ], [ %15, %14 ]
  %18 = add i32 %17, %5
  ret i32 %18
}

; Function Attrs: nounwind ssp uwtable
define i32 @kh_1(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = load volatile ptr, ptr @p1, align 8, !tbaa !10
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #7
  %7 = tail call i32 @cq_measure_ui32(i32 noundef %6) #7
  ret i32 %7
}

declare i32 @cq_theta_ui32(i32 noundef, double noundef) local_unnamed_addr #2

declare i32 @cq_measure_ui32(i32 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @kh_2(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = load volatile ptr, ptr @p2, align 8, !tbaa !10
  %6 = zext i32 %2 to i64
  %7 = tail call i32 %5(i32 noundef %4, i64 noundef %6) #7
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #7
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @kh_3(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = load volatile ptr, ptr @p3, align 8, !tbaa !10
  %6 = trunc i32 %2 to i16
  %7 = tail call i32 %5(i32 noundef %4, i16 noundef zeroext %6) #7
  %8 = tail call i32 @cq_measure_ui32(i32 noundef %7) #7
  ret i32 %8
}

; Function Attrs: nounwind ssp uwtable
define i32 @kh_6(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = load volatile ptr, ptr @p6, align 8, !tbaa !10
  %6 = tail call i64 %5(i32 noundef %4, i32 noundef %2) #7
  %7 = tail call i64 @cq_measure_ull(i64 noundef %6) #7
  %8 = trunc i64 %7 to i32
  ret i32 %8
}

declare i64 @cq_measure_ull(i64 noundef) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define range(i32 0, 65536) i32 @kh_r6(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = and i32 %2, 1
  %6 = icmp eq i32 %5, 0
  %7 = select i1 %6, ptr @q6, ptr @r6
  %8 = tail call zeroext i16 %7(i32 noundef %4, i32 noundef %2) #7, !callees !14
  %9 = tail call zeroext i16 @cq_measure_ui16(i16 noundef zeroext %8) #7
  %10 = zext i16 %9 to i32
  ret i32 %10
}

; Function Attrs: noinline nounwind ssp uwtable
define internal zeroext i16 @r6(i32 noundef %0, i32 noundef %1) unnamed_addr #3 {
  %3 = icmp ugt i32 %0, 2
  br i1 %3, label %4, label %14

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %10, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %7, %4 ], [ %0, %2 ]
  %7 = add i32 %6, -3
  %8 = and i32 %7, 1
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #7
  %10 = add i32 %9, %5
  %11 = icmp ugt i32 %7, 2
  br i1 %11, label %4, label %12, !llvm.loop !15

12:                                               ; preds = %4
  %13 = shl i32 %10, 8
  br label %14

14:                                               ; preds = %12, %2
  %15 = phi i32 [ %0, %2 ], [ %7, %12 ]
  %16 = phi i32 [ 0, %2 ], [ %13, %12 ]
  %17 = add i32 %15, %1
  %18 = add i32 %17, %16
  %19 = trunc i32 %18 to i16
  ret i16 %19
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable
define internal noundef zeroext i16 @q6(i32 noundef %0, i32 noundef %1) unnamed_addr #4 {
  %3 = add i32 %1, %0
  %4 = trunc i32 %3 to i16
  ret i16 %4
}

declare zeroext i16 @cq_measure_ui16(i16 noundef zeroext) local_unnamed_addr #2

; Function Attrs: nounwind ssp uwtable
define i32 @kh_cls(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #1 {
  %5 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %6 = and i32 %3, 1
  %7 = icmp eq i32 %6, 0
  %8 = select i1 %7, ptr @t8, ptr @t7
  %9 = tail call i32 %8(i32 noundef %5, i32 noundef %2, i32 noundef 5) #7, !callees !16
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %9) #7
  ret i32 %10
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t7(i32 noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #0 {
  %4 = tail call fastcc i32 @h1(i32 noundef %0, i32 noundef %1)
  %5 = add i32 %4, %2
  ret i32 %5
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal i32 @t8(i32 noundef %0, i32 noundef %1, i32 noundef %2) unnamed_addr #0 {
  %4 = tail call fastcc i32 @h3(i32 noundef %0, i32 noundef %1)
  %5 = xor i32 %4, %2
  ret i32 %5
}

; Function Attrs: nounwind ssp uwtable
define i32 @kh_twin(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = load volatile ptr, ptr @p1, align 8, !tbaa !10
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #7
  %7 = and i32 %6, 3
  %8 = add i32 %7, %4
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #7
  ret i32 %9
}

; Function Attrs: nounwind ssp uwtable
define i32 @kh_after(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = load volatile ptr, ptr @p1, align 8, !tbaa !10
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #7
  %7 = lshr i32 %4, 2
  %8 = tail call fastcc i32 @h1o(i32 noundef %7, i32 noundef %2)
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %6) #7
  %10 = mul i32 %9, 1000
  %11 = tail call i32 @cq_measure_ui32(i32 noundef %8) #7
  %12 = add i32 %10, %11
  ret i32 %12
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h1o(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = and i32 %0, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %12, label %5

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %9, %5 ], [ 0, %2 ]
  %7 = phi i32 [ %8, %5 ], [ %0, %2 ]
  %8 = tail call i32 @llvm.fshl.i32(i32 %1, i32 %7, i32 31)
  %9 = add i32 %6, 1
  %10 = and i32 %8, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %5, !llvm.loop !17

12:                                               ; preds = %5, %2
  %13 = phi i32 [ 0, %2 ], [ %9, %5 ]
  ret i32 %13
}

; Function Attrs: noinline nounwind ssp uwtable
define i32 @g3k(i32 noundef %0, i8 noundef zeroext %1, i16 noundef zeroext %2) local_unnamed_addr #3 {
  %4 = load volatile ptr, ptr @p5, align 8, !tbaa !10
  %5 = tail call i32 %4(i32 noundef %0, i8 noundef zeroext %1) #7
  %6 = zext i16 %2 to i32
  %7 = add i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind ssp uwtable
define i32 @kh_seq(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = load volatile ptr, ptr @p1, align 8, !tbaa !10
  %6 = tail call i32 %5(i32 noundef %4, i32 noundef %2) #7
  %7 = trunc i32 %2 to i8
  %8 = tail call i32 @g3k(i32 noundef %4, i8 noundef zeroext %7, i16 noundef zeroext 1)
  %9 = tail call fastcc i32 @h2o(i32 noundef %4)
  %10 = tail call i32 @cq_measure_ui32(i32 noundef %6) #7
  %11 = mul i32 %10, 1000000
  %12 = tail call i32 @cq_measure_ui32(i32 noundef %8) #7
  %13 = mul i32 %12, 1000
  %14 = add i32 %13, %11
  %15 = tail call i32 @cq_measure_ui32(i32 noundef %9) #7
  %16 = add i32 %14, %15
  ret i32 %16
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h2o(i32 noundef %0) unnamed_addr #0 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %13, label %4

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %8, %4 ], [ 0, %1 ]
  %6 = phi i32 [ %7, %4 ], [ %0, %1 ]
  %7 = lshr i32 %6, 1
  %8 = add i32 %5, 1
  %9 = and i32 %6, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %4, !llvm.loop !18

11:                                               ; preds = %4
  %12 = shl i32 %8, 3
  br label %13

13:                                               ; preds = %11, %1
  %14 = phi i32 [ %0, %1 ], [ %7, %11 ]
  %15 = phi i32 [ 0, %1 ], [ %12, %11 ]
  %16 = add i32 %15, %14
  ret i32 %16
}

; Function Attrs: nounwind ssp uwtable
define i32 @kh_direct(i32 noundef %0, double noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = tail call i32 @cq_theta_ui32(i32 noundef %0, double noundef %1) #6
  %5 = tail call fastcc i32 @h1o(i32 noundef %4, i32 noundef %2)
  %6 = tail call i32 @cq_measure_ui32(i32 noundef %5) #7
  %7 = mul i32 %6, 1000
  %8 = tail call fastcc i32 @h2o(i32 noundef %4)
  %9 = tail call i32 @cq_measure_ui32(i32 noundef %8) #7
  %10 = add i32 %9, %7
  ret i32 %10
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h1(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = and i32 %0, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %12, label %5

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %9, %5 ], [ 0, %2 ]
  %7 = phi i32 [ %8, %5 ], [ %0, %2 ]
  %8 = tail call i32 @llvm.fshl.i32(i32 %1, i32 %7, i32 31)
  %9 = add i32 %6, 1
  %10 = and i32 %8, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %5, !llvm.loop !19

12:                                               ; preds = %5, %2
  %13 = phi i32 [ 0, %2 ], [ %9, %5 ]
  ret i32 %13
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h2(i32 noundef %0) unnamed_addr #0 {
  %2 = and i32 %0, 1
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %13, label %4

4:                                                ; preds = %1, %4
  %5 = phi i32 [ %8, %4 ], [ 0, %1 ]
  %6 = phi i32 [ %7, %4 ], [ %0, %1 ]
  %7 = lshr i32 %6, 1
  %8 = add i32 %5, 1
  %9 = and i32 %6, 2
  %10 = icmp eq i32 %9, 0
  br i1 %10, label %11, label %4, !llvm.loop !20

11:                                               ; preds = %4
  %12 = shl i32 %8, 3
  br label %13

13:                                               ; preds = %11, %1
  %14 = phi i32 [ %0, %1 ], [ %7, %11 ]
  %15 = phi i32 [ 0, %1 ], [ %12, %11 ]
  %16 = add i32 %15, %14
  ret i32 %16
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h3(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %11

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %9, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %8, %4 ], [ %0, %2 ]
  %7 = mul i32 %6, %1
  %8 = add i32 %7, 1
  %9 = add i32 %5, 2
  %10 = icmp ugt i32 %8, 9
  br i1 %10, label %4, label %11, !llvm.loop !21

11:                                               ; preds = %4, %2
  %12 = phi i32 [ %0, %2 ], [ %8, %4 ]
  %13 = phi i32 [ 0, %2 ], [ %9, %4 ]
  %14 = tail call fastcc i32 @h2(i32 noundef %12)
  %15 = add i32 %14, %13
  ret i32 %15
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h6(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = icmp ugt i32 %0, 9
  br i1 %3, label %4, label %13

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %9, %4 ], [ 0, %2 ]
  %6 = phi i32 [ %8, %4 ], [ %0, %2 ]
  %7 = mul i32 %6, %1
  %8 = add i32 %7, 1
  %9 = add i32 %8, %5
  %10 = icmp ugt i32 %8, 9
  br i1 %10, label %4, label %11, !llvm.loop !22

11:                                               ; preds = %4
  %12 = shl i32 %9, 6
  br label %13

13:                                               ; preds = %11, %2
  %14 = phi i32 [ %0, %2 ], [ %8, %11 ]
  %15 = phi i32 [ 0, %2 ], [ %12, %11 ]
  %16 = or disjoint i32 %15, %14
  ret i32 %16
}

; Function Attrs: nofree noinline norecurse nosync nounwind ssp memory(none) uwtable
define internal fastcc i32 @h5(i32 noundef %0, i32 noundef %1) unnamed_addr #0 {
  %3 = and i32 %0, 1
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %12, label %5

5:                                                ; preds = %2, %5
  %6 = phi i32 [ %9, %5 ], [ 0, %2 ]
  %7 = phi i32 [ %8, %5 ], [ %0, %2 ]
  %8 = tail call i32 @llvm.fshl.i32(i32 %1, i32 %7, i32 31)
  %9 = add i32 %6, 1
  %10 = and i32 %8, 1
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %5, !llvm.loop !23

12:                                               ; preds = %5, %2
  %13 = phi i32 [ 0, %2 ], [ %9, %5 ]
  ret i32 %13
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.fshl.i32(i32, i32, i32) #5

attributes #0 = { nofree noinline norecurse nosync nounwind ssp memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { noinline nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree noinline norecurse nosync nounwind ssp willreturn memory(none) uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #6 = { nomerge nounwind }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
!6 = distinct !{!6, !7, !8}
!7 = !{!"llvm.loop.mustprogress"}
!8 = !{!"llvm.loop.unroll.disable"}
!9 = distinct !{!9, !7, !8}
!10 = !{!11, !11, i64 0}
!11 = !{!"any pointer", !12, i64 0}
!12 = !{!"omnipotent char", !13, i64 0}
!13 = !{!"Simple C/C++ TBAA"}
!14 = !{ptr @q6, ptr @r6}
!15 = distinct !{!15, !7, !8}
!16 = !{ptr @t7, ptr @t8}
!17 = distinct !{!17, !7, !8}
!18 = distinct !{!18, !7, !8}
!19 = distinct !{!19, !7, !8}
!20 = distinct !{!20, !7, !8}
!21 = distinct !{!21, !7, !8}
!22 = distinct !{!22, !7, !8}
!23 = distinct !{!23, !7, !8}
