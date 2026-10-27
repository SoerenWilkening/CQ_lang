; HAND-WRITTEN. Rules: 2, 4, 5, 10, 20.
; Checked: table_2d's GRID[r & 3][c & 3] (the QROM result %11 -> %12, measured); register_grid's q[0][1] (%36 -> %55) and
; q[rows-1][1] (%40 -> %57), measured and summed.
; Clean: table_2d's index chain (r & 3 %7, c & 3 %8, the row offset %9, the linear index %10), each |0> at its free.
; Kept: table_2d's registers r (%5) and c (%6) and the measured QROM result %11; register_grid's four cells q[i][j]
; (%5..%8, user registers; two of them measured) and, on the rows == 1 path only, the flag %53 (a copy of q[0][1] taken
; before the rotation it controls, entangled with the rotated cell).
; Rotations: (Ry, r, tr, 1); (Ry, c, tc, 1) in table_2d; (Ry, q[i][j], theta[2i+j], 1) per cell in order; then
; (Ry, q[i][1], c, q[i][0]) per row i; then (Ry, q[rows-1][1], c, q[0][1]) (rows > 1) or (Ry, q[0][1], c, flag = copy of
; q[0][1] before the gate) (rows == 1).
; table_2d: a constant 2D table read with a quantum row AND a quantum column is a QROM (29) over the FLATTENED table: -O1
; keeps one getelementptr [4 x [4 x i32]] with two quantum indices, whose element offset is row * 4 + col. That linear
; index is computed into a fresh rail at the width of the C index expressions (i32: shl of r & 3 by the row stride, add
; c & 3), the QROM selects the entry into a fresh result rail, and the index chain is uncomputed LIFO. -O1's zexts to i64
; and the gep's byte scaling are address arithmetic and are not emitted (rule 20); the row flattening is the logical index
; of the 2-D table, not address arithmetic. The table is passed as a pointer literal with 16 cells.
; register_grid: `bool q[2][2]` is a 2D array of classical SLOTS (58), one i1 rail per cell; classical-index accesses
; q[i][j] load the cell's handle; `if (q[i][0]) cq_theta(&q[i][1], c)` is cqrt_ry_i1_controlled with the bare control rail
; (59). The cross-row arm `if (q[0][1]) cq_theta(&q[rows - 1][1], c)` ALIASES when rows == 1: control and target are then
; the SAME cell, i.e. 66's self-conditioned rotation on a bare rail, and a controlled gate whose control is its own target
; is not a gate. The two cell addresses are classical, so the alias question is a classical runtime test on the two slot
; pointers: distinct -> one cRy(q[0][1], q[rows-1][1]); equal -> 66's discipline: the condition is copied into a fresh |0>
; flag BEFORE the rotation (a CNOT copies the basis label the branch reads), cRy(flag, cell), and the flag STAYS ALLOCATED,
; entangled with the cell (it cannot be uncomputed from a cell that changed under it). The four cells are user registers
; and stay allocated.
source_filename = "multidim_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@GRID = internal unnamed_addr constant [4 x [4 x i32]] [[4 x i32] [i32 3, i32 1, i32 4, i32 1], [4 x i32] [i32 5, i32 9, i32 2, i32 6], [4 x i32] [i32 5, i32 3, i32 5, i32 8], [4 x i32] [i32 9, i32 7, i32 9, i32 3]], align 16

define i32 @table_2d(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register r]
  call void @cqrt_ry_i32(i32 %5, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %6 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register c]
  call void @cqrt_ry_i32(i32 %6, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 3)    ; IR: %7 = and i32 %5, 3
  %8 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %9 = and i32 %6, 3
  %9 = call i32 @cq_template_shl_i32_hl(i32 %7, i32 2)    ; IR: %8 = zext %7; %10 = zext %9; %11 = getelementptr [4 x [4 x i32]], @GRID, 0, %8, %10  (row stride 4 cells: %7 << 2, at the i32 index width)
  %10 = call i32 @cq_template_add_i32(i32 %9, i32 %8)    ; IR: %11  (linear cell index %7 * 4 + %9, the logical index rail)
  %11 = call i32 @cq_template_qrom_load_i32(ptr @GRID, i64 16, i32 %10)    ; IR: %12 = load i32, ptr %11  [QROM over the flattened 16-cell table, fresh result rail]
  call void @cq_template_add_i32_unc(i32 %10, i32 %9, i32 %8)    ; IR: uncompute the linear index
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_shl_i32_hl_unc(i32 %9, i32 %7, i32 2)    ; IR: uncompute the row offset
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %6, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %8)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %7)    ; IR: release the %7 rail (|0>)
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %13 = cq_measure_si32(%12)
  ret i32 %12    ; IR: ret i32 %13
}

define i32 @register_grid(ptr nocapture noundef readonly %0, i32 noundef %1, double noundef %2) {
  %4 = alloca [2 x [2 x i32]], align 4    ; IR: %4 = alloca [2 x [2 x i8]]  (classical slots: one handle per cell)
  %5 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i32 0, ptr %4: q[0][0] = 0  [register q[0][0]]
  %6 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i32 0, ptr %4: q[0][1] = 0  [register q[0][1]]
  %7 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i32 0, ptr %4: q[1][0] = 0  [register q[1][0]]
  %8 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: store i32 0, ptr %4: q[1][1] = 0  [register q[1][1]]
  store i32 %5, ptr %4, align 4    ; IR: store i32 0, ptr %4  (slot [0][0])
  %9 = getelementptr inbounds [2 x [2 x i32]], ptr %4, i64 0, i64 0, i64 1    ; IR: (slot [0][1])
  store i32 %6, ptr %9, align 4    ; IR: store i32 0, ptr %4  (slot [0][1])
  %10 = getelementptr inbounds [2 x [2 x i32]], ptr %4, i64 0, i64 1, i64 0    ; IR: (slot [1][0])
  store i32 %7, ptr %10, align 4    ; IR: store i32 0, ptr %4  (slot [1][0])
  %11 = getelementptr inbounds [2 x [2 x i32]], ptr %4, i64 0, i64 1, i64 1    ; IR: (slot [1][1])
  store i32 %8, ptr %11, align 4    ; IR: store i32 0, ptr %4  (slot [1][1])
  %12 = icmp sgt i32 %1, 0    ; IR: %5  (classical)
  br i1 %12, label %13, label %19    ; IR: br i1 %5

13:
  %14 = zext nneg i32 %1 to i64    ; IR: %7  (classical)
  br label %15

15:
  %16 = phi i64 [ 0, %13 ], [ %24, %23 ]    ; IR: %9  (classical row i)
  %17 = shl nsw i64 %16, 4    ; IR: %10  (classical)
  %18 = getelementptr inbounds i8, ptr %0, i64 %17    ; IR: %11  (classical: &theta[2 * i])
  br label %26

19:
  %20 = icmp sgt i32 %1, 0    ; IR: %13  (classical)
  br i1 %20, label %21, label %34    ; IR: br i1 %13

21:
  %22 = zext nneg i32 %1 to i64    ; IR: %15  (classical)
  br label %42

23:
  %24 = add nuw nsw i64 %16, 1    ; IR: %17  (classical)
  %25 = icmp eq i64 %24, %14    ; IR: %18  (classical)
  br i1 %25, label %19, label %15    ; IR: br i1 %18

26:
  %27 = phi i64 [ 0, %15 ], [ %32, %26 ]    ; IR: %20  (classical column j)
  %28 = getelementptr inbounds [2 x [2 x i32]], ptr %4, i64 0, i64 %16, i64 %27    ; IR: %21 = getelementptr [2 x [2 x i8]], ptr %4, 0, %9, %20  (slot of q[i][j])
  %29 = load i32, ptr %28, align 4    ; IR: %22 = load i8; %23 = trunc to i1  (handle of q[i][j]; no gate)
  %30 = getelementptr inbounds double, ptr %18, i64 %27    ; IR: %24  (classical)
  %31 = load double, ptr %30, align 8    ; IR: %25 = load double  (classical angle)
  call void @cqrt_ry_i1(i32 %29, double %31)    ; IR: %26 = cq_theta_i1(%23, %25)  [Ry in place on q[i][j]]; %27/store: handle unchanged
  %32 = add nuw nsw i64 %27, 1    ; IR: %28  (classical)
  %33 = icmp eq i64 %27, 0    ; IR: %29  (classical)
  br i1 %33, label %26, label %23    ; IR: br i1 %29

34:
  %35 = getelementptr inbounds [2 x [2 x i32]], ptr %4, i64 0, i64 0, i64 1    ; IR: %31 = getelementptr i8, ptr %4, 1  (slot of q[0][1])
  %36 = load i32, ptr %35, align 4    ; IR: %32 = load i8; %33 = trunc to i1  (handle of q[0][1]: the control rail)
  %37 = add nsw i32 %1, -1    ; IR: %49  (classical, hoisted from block %48: pure)
  %38 = sext i32 %37 to i64    ; IR: %50  (classical)
  %39 = getelementptr inbounds [2 x [2 x i32]], ptr %4, i64 0, i64 %38, i64 1    ; IR: %51  (slot of q[rows-1][1])
  %40 = load i32, ptr %39, align 4    ; IR: %52 = load i8; %53 = trunc to i1  (handle of q[rows-1][1]: the target)
  %41 = icmp eq ptr %35, %39    ; IR: classical alias test of the two cells (true iff rows == 1)
  br i1 %41, label %52, label %51

42:
  %43 = phi i64 [ 0, %21 ], [ %49, %48 ]    ; IR: %35  (classical row i)
  %44 = getelementptr inbounds [2 x [2 x i32]], ptr %4, i64 0, i64 %43    ; IR: %36  (slot of q[i][0])
  %45 = load i32, ptr %44, align 4    ; IR: %37 = load i8; %38 = trunc to i1  (handle of q[i][0]: the control rail)
  %46 = getelementptr inbounds i32, ptr %44, i64 1    ; IR: %40 = getelementptr i8, ptr %36, 1  (slot of q[i][1], hoisted from block %39: pure)
  %47 = load i32, ptr %46, align 4    ; IR: %41 = load i8; %42 = trunc to i1  (handle of q[i][1]: the target; a different column, never the control)
  call void @cqrt_ry_i1_controlled(i32 %45, i32 %47, double %2)    ; IR: br i1 %38 -> block %39: %43 = cq_theta_i1(%42, %2)  [Ry on q[i][1] controlled by q[i][0]]; %44/store: handle unchanged
  br label %48    ; IR: br label %45

48:
  %49 = add nuw nsw i64 %43, 1    ; IR: %46  (classical)
  %50 = icmp eq i64 %49, %22    ; IR: %47  (classical)
  br i1 %50, label %34, label %42    ; IR: br i1 %47

51:
  call void @cqrt_ry_i1_controlled(i32 %36, i32 %40, double %2)    ; IR: br i1 %33 -> block %48: %54 = cq_theta_i1(%53, %2)  [distinct cells: Ry on q[rows-1][1] controlled by the bare rail q[0][1]]
  br label %54

52:
  %53 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: br i1 %33  [flag rail: the condition read BEFORE the rotation]
  call void @cqrt_copy_i1(i32 %36, i32 %53)    ; IR: %33 copied into the |0> flag (CNOT)
  call void @cqrt_ry_i1_controlled(i32 %53, i32 %40, double %2)    ; IR: block %48: %54 = cq_theta_i1(%53, %2)  [same cell: Ry under the flag; %f stays allocated, entangled (66)]
  br label %54

54:
  %55 = call i1 @cqrt_measure_i1(i32 %36)    ; IR: %57 = load i8, ptr %31; %59 = cq_measure_i1(%58)  (handle of q[0][1])
  %56 = zext i1 %55 to i32    ; IR: %60  (classical)
  %57 = call i1 @cqrt_measure_i1(i32 %40)    ; IR: %64 = load i8, ptr %63; %66 = cq_measure_i1(%65)  (%63 is %51: handle of q[rows-1][1])
  %58 = zext i1 %57 to i32    ; IR: %67  (classical)
  %59 = add nuw nsw i32 %58, %56    ; IR: %68  (classical)
  ret i32 %59    ; IR: ret i32 %68
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare void @cqrt_copy_i1(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
