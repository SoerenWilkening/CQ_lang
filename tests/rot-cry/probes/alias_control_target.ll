; rot-cry probes (cq-x80e): a controlled Ry whose control and target are slot-cell loads that may be
; one cell at run time (120 register_grid's `if (q[0][1]) cq_theta(&q[rows-1][1], c)`, rows == 1).
; CR §1.3: an in-place target is never one of its own controls. The two cell addresses are tested
; classically: distinct, the bare control rail; the same cell, the control copied into a fresh flag
; first (kept, 66). From C (bool cells, the i8 <-> i1 views written as i1 accesses):
;   bool q[2]; q[0] = q[1] = 0; for (j < 2) cq_theta(&q[j], theta[j]);
;   if (q[0]) cq_theta(&q[n & 1], c);  return cq_measure(q[0]) + cq_measure(q[1]);
; §6: `cqcheck user --o1 <this file> --lowered <its lowering> --entry alias_cell` (main before cq-x80e:
; one bare cqrt_ry_i1_controlled, its target aliasing its control when n is even).
; CHECK alias_cell: %[[EQ]] = icmp eq ptr %{{a}}, %{{b}}
; CHECK alias_cell: br i1 %[[EQ]], label %[[SAME]], label %{{d}}
; CHECK alias_cell: call void @cqrt_xor_i1(i32 %{{c}}, i32 %[[F]])
; CHECK alias_cell: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %{{t}}, double %2)
; CHECK-COUNT alias_cell: call void @cqrt_ry_i1_controlled( 2
; Cells of one object at different constant offsets (q[0] controls q[1]): never one cell, no test.
; CHECK-COUNT distinct_cells: icmp eq ptr 0
; CHECK-COUNT distinct_cells: call void @cqrt_ry_i1_controlled( 1
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)

declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)

define i32 @alias_cell(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) {
  %4 = alloca [2 x i8], align 1
  store i1 false, ptr %4, align 1
  %5 = getelementptr inbounds i8, ptr %4, i64 1
  store i1 false, ptr %5, align 1
  br label %8

6:                                                ; preds = %8
  %7 = load i1, ptr %4, align 1
  br i1 %7, label %17, label %23

8:                                                ; preds = %8, %3
  %9 = phi i64 [ 0, %3 ], [ %15, %8 ]
  %10 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %9
  %11 = load i1, ptr %10, align 1
  %12 = getelementptr inbounds double, ptr %0, i64 %9
  %13 = load double, ptr %12, align 8
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef %13)
  store i1 %14, ptr %10, align 1
  %15 = add nuw nsw i64 %9, 1
  %16 = icmp eq i64 %9, 0
  br i1 %16, label %8, label %6

17:                                               ; preds = %6
  %18 = and i32 %1, 1
  %19 = zext nneg i32 %18 to i64
  %20 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %19
  %21 = load i1, ptr %20, align 1
  %22 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %21, double noundef %2)
  store i1 %22, ptr %20, align 1
  br label %23

23:                                               ; preds = %17, %6
  %24 = load i1, ptr %4, align 1
  %25 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %24)
  %26 = zext i1 %25 to i32
  %27 = load i1, ptr %5, align 1
  %28 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %27)
  %29 = zext i1 %28 to i32
  %30 = add nuw nsw i32 %29, %26
  ret i32 %30
}

define i32 @distinct_cells(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) {
  %4 = alloca [2 x i8], align 1
  store i1 false, ptr %4, align 1
  %5 = getelementptr inbounds i8, ptr %4, i64 1
  store i1 false, ptr %5, align 1
  br label %8

6:                                                ; preds = %8
  %7 = load i1, ptr %4, align 1
  br i1 %7, label %17, label %21

8:                                                ; preds = %8, %3
  %9 = phi i64 [ 0, %3 ], [ %15, %8 ]
  %10 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %9
  %11 = load i1, ptr %10, align 1
  %12 = getelementptr inbounds double, ptr %0, i64 %9
  %13 = load double, ptr %12, align 8
  %14 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %11, double noundef %13)
  store i1 %14, ptr %10, align 1
  %15 = add nuw nsw i64 %9, 1
  %16 = icmp eq i64 %9, 0
  br i1 %16, label %8, label %6

17:                                               ; preds = %6
  %18 = getelementptr inbounds i8, ptr %4, i64 1
  %19 = load i1, ptr %18, align 1
  %20 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %19, double noundef %2)
  store i1 %20, ptr %18, align 1
  br label %21

21:                                               ; preds = %17, %6
  %22 = load i1, ptr %4, align 1
  %23 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %22)
  %24 = zext i1 %23 to i32
  %25 = load i1, ptr %5, align 1
  %26 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %25)
  %27 = zext i1 %26 to i32
  %28 = add nuw nsw i32 %27, %24
  ret i32 %28
}
