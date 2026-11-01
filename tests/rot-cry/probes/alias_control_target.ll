; rot-cry probes (cq-x80e): a controlled Ry whose control and target are slot-cell loads that may be
; one cell at run time (120 register_grid's `if (q[0][1]) cq_theta(&q[rows-1][1], c)`, rows == 1).
; CR §1.3: an in-place target is never one of its own controls. The two cell addresses are tested
; classically: distinct, the bare control rail; the same cell, the control copied into a fresh flag
; first (kept, 66). From C (bool cells, the i8 <-> i1 views written as i1 accesses):
;   bool q[2]; q[0] = q[1] = 0; for (j < 2) cq_theta(&q[j], theta[j]);
;   if (q[0]) cq_theta(&q[n & 1], c);  return cq_measure(q[0]) + cq_measure(q[1]);
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

declare zeroext i1 @cq_theta_i1(i1 noundef zeroext, double noundef)
declare zeroext i1 @cq_measure_i1(i1 noundef zeroext)

; CHECK alias_cell: %[[EQ]] = icmp eq ptr %{{a}}, %{{b}}
; CHECK alias_cell: br i1 %[[EQ]], label %[[SAME]], label %{{d}}
; CHECK alias_cell: call void @cqrt_xor_i1(i32 %{{c}}, i32 %[[F]])
; CHECK alias_cell: call void @cqrt_ry_i1_controlled(i32 %[[F]], i32 %{{t}}, double %2)
; CHECK-COUNT alias_cell: call void @cqrt_ry_i1_controlled( 2
define i32 @alias_cell(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) {
  %4 = alloca [2 x i8], align 1
  store i1 false, ptr %4, align 1
  %5 = getelementptr inbounds i8, ptr %4, i64 1
  store i1 false, ptr %5, align 1
  br label %9

6:                                                ; preds = %9
  %8 = load i1, ptr %4, align 1
  br i1 %8, label %20, label %28

9:                                                ; preds = %3, %9
  %10 = phi i64 [ 0, %3 ], [ %18, %9 ]
  %11 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %10
  %13 = load i1, ptr %11, align 1
  %14 = getelementptr inbounds double, ptr %0, i64 %10
  %15 = load double, ptr %14, align 8
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef %15)
  store i1 %16, ptr %11, align 1
  %18 = add nuw nsw i64 %10, 1
  %19 = icmp eq i64 %10, 0
  br i1 %19, label %9, label %6

20:                                               ; preds = %6
  %21 = and i32 %1, 1
  %22 = zext nneg i32 %21 to i64
  %23 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %22
  %25 = load i1, ptr %23, align 1
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %25, double noundef %2)
  store i1 %26, ptr %23, align 1
  br label %28

28:                                               ; preds = %20, %6
  %30 = load i1, ptr %4, align 1
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %30)
  %32 = zext i1 %31 to i32
  %34 = load i1, ptr %5, align 1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34)
  %36 = zext i1 %35 to i32
  %37 = add nuw nsw i32 %36, %32
  ret i32 %37
}

; Cells of one object at different constant offsets (q[0] controls q[1]): never one cell, no test.
; CHECK-COUNT distinct_cells: icmp eq ptr 0
; CHECK-COUNT distinct_cells: call void @cqrt_ry_i1_controlled( 1
define i32 @distinct_cells(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) {
  %4 = alloca [2 x i8], align 1
  store i1 false, ptr %4, align 1
  %5 = getelementptr inbounds i8, ptr %4, i64 1
  store i1 false, ptr %5, align 1
  br label %9

6:                                                ; preds = %9
  %8 = load i1, ptr %4, align 1
  br i1 %8, label %20, label %28

9:                                                ; preds = %3, %9
  %10 = phi i64 [ 0, %3 ], [ %18, %9 ]
  %11 = getelementptr inbounds [2 x i8], ptr %4, i64 0, i64 %10
  %13 = load i1, ptr %11, align 1
  %14 = getelementptr inbounds double, ptr %0, i64 %10
  %15 = load double, ptr %14, align 8
  %16 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %13, double noundef %15)
  store i1 %16, ptr %11, align 1
  %18 = add nuw nsw i64 %10, 1
  %19 = icmp eq i64 %10, 0
  br i1 %19, label %9, label %6

20:                                               ; preds = %6
  %23 = getelementptr inbounds i8, ptr %4, i64 1
  %25 = load i1, ptr %23, align 1
  %26 = tail call zeroext i1 @cq_theta_i1(i1 noundef zeroext %25, double noundef %2)
  store i1 %26, ptr %23, align 1
  br label %28

28:                                               ; preds = %20, %6
  %30 = load i1, ptr %4, align 1
  %31 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %30)
  %32 = zext i1 %31 to i32
  %34 = load i1, ptr %5, align 1
  %35 = tail call zeroext i1 @cq_measure_i1(i1 noundef zeroext %34)
  %36 = zext i1 %35 to i32
  %37 = add nuw nsw i32 %36, %32
  ret i32 %37
}
