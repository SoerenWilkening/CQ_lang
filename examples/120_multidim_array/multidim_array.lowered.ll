; HAND-WRITTEN. Rules: 2, 3, 4, 5, 8, 10, 11, 15, 16, 20, 21; §1.3 (the bus, qram_load, qram_swap, __cq_mem, __cq_alloc).
; Checked: table_2d's GRID[r & 3][c & 3] (the bus load copy %16 -> %17, measured); register_grid's q[0][1] (the load copy
; %41 -> %42) and q[rows-1][1] (the load copy %48 -> %49), measured and summed. Memory: the four cells of q (the block
; at P = %6) hold the four rotated registers at exit.
; Clean: table_2d's address chain (r & 3 %8, its zext %9, c & 3 %10, its zext %11, the scaled row %12 and column %13,
; their sum %14, the address rail %15 = &GRID + sum), uncomputed and freed right after the load. register_grid: the swap
; rail of every in-place form (%29 per cell in the first loop, %59 per row in the second, %40 for the cross-row arm),
; |0> after its swap-in.
; Kept: table_2d's registers r (%6) and c (%7) and the measured load copy %16 (rule 2). register_grid: the four cells
; q[i][j] (user registers living in the bus cells, two of them read by measured load copies); the seed %7 and the tape
; slot of the initializer `store i32 0` (a kept store, rule 5 sentence 3; classical-valued, so the cells stay HOST and
; no qubit is spent, §0); the two measured load copies %41 and %48 (rule 2). Left allocated, un-copied (rule 5
; sentence 1: overtaken by an in-place form): per trip of the first loop the angle load copy %28 of theta[2i+j]
; (classical-valued); per row of the second loop the flag %56 (the load copy of q[i][0] that controls the form on
; q[i][1]); the flag %35 (the load copy of q[0][1] taken BEFORE the cross-row form; on the rows == 1 path its un-copy
; reads the rotated cell and the rail keeps garbage).
; Rotations: (Ry, r, tr, 1); (Ry, c, tc, 1) in table_2d; (Ry, the cell q[i][j], the angle rail of theta[2i+j], 1) per
; cell in order; then (Ry, the cell q[i][1], c, copy of q[i][0]) per row i; then (Ry, the cell q[rows-1][1], c, copy of
; q[0][1] taken before the gate) (rows == 1: the same cell as the control's source).
; table_2d: a constant 2-D table read at a quantum row AND a quantum column is ONE bus load at an address rail (rule 20;
; QROM is retired). @GRID is a constant global, but its getelementptr has tainted indices, so the access is no
; host-resident access (rule 20 (a)): the load is cqrt_qram_load_i32 at the address rail, reading the HOST cells of the
; table through the overlay (nothing seeded, nothing registered). The address is -O1's own getelementptr
; [4 x [4 x i32]] @GRID, 0, %8, %10 as 64-bit template arithmetic: each tainted index as -O1 wrote it (and, then zext to
; i64), scaled by its element size (16 bytes a row, 4 a column: mul_i64_hl), summed (add_i64), plus the classical part,
; the run-time address of @GRID (add_i64_hl of `ptrtoint (ptr @GRID to i64)`). Nothing is narrowed, bounded or checked.
; The load copy is measured, so it is never un-copied (rule 2); the access is then the address rail's last reader and
; the whole chain is uncomputed LIFO right after the load (rule 20).
; register_grid: `bool q[2][2]` is an alloca stored tainted values, so it is BUS-RESIDENT (rule 20 (b)): one zeroed
; block __cq_alloc(4, 4) at the alloca's program point, no alloca remains, the lifetime markers are dropped (rule 16).
; Its initializer `store i32 0` is a kept bus store of the seed alloc_i32(0) (rules 5, 7). A cell is a byte on the bus,
; addressed classically (every index is classical): P + 2i + j, -O1's getelementptr kept as the classical instruction
; and read through ptrtoint (rule 20). theta[2i+j] is a load through a host pointer parameter, so it is a bus load and
; a rail (rule 3; over-taint is accepted), and a rotation angle loaded from the bus is a QUANTUM ANGLE (rule 11): the
; one primitive cqrt_ry_i1_qangle(h, A) (rule 15), never a classical double.
; `load i8; trunc nuw to i1; cq_theta_i1; zext; store i8` through the same pointer is rule 5's in-place form at width
; i1 (Width casts): alloc_i1(0), qram_swap_i1_hl out, the step on the swap rail, qram_swap_i1_hl in, free; the high 7
; bits of the cell never leave it. The angle load is a plain load at its own program point, before the swap-out.
; `if (q[i][0]) cq_theta(&q[i][1], c)`: the condition is a plain load of q[i][0] (qram_load_i1_hl, the bare i1 rail as
; the flag, rule 8), and the arm is rule 10 on a memory cell: the in-place form on q[i][1] under that flag (both swaps
; _controlled, the gate cqrt_ry_i1_controlled on the swap rail; under flag = 0 nothing is touched and the rail stays
; |0>). The cross-row arm `if (q[0][1]) cq_theta(&q[rows - 1][1], c)` is the same construction: when rows == 1 the
; target cell IS q[0][1], and nothing needs to know it: the control is the load COPY of q[0][1] taken before the form
; (the copy 66 needs for a self-conditioned rotation), never the cell, so no compile-time or run-time alias test is
; emitted (rule 5: no rule asks whether two addresses differ); the copy is un-copied after the swap-in and stays
; allocated with the other flags.
; The reads for cq_measure are plain loads of the cells after the forms (qram_load_i1_hl), measured and kept (rule 2).
; The flags and the angle copies are un-copied after their last reader (the controlled swap-in; for an angle, the
; rotation, the _unc placed after the swap-in: no bus access inside the form) and, overtaken by the form, not freed
; (rule 5 sentence 1); the flag and measured reads of form-written _Bool cells are taken at i1 by rule 5 Width casts.
source_filename = "multidim_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@GRID = internal unnamed_addr constant [4 x [4 x i32]] [[4 x i32] [i32 3, i32 1, i32 4, i32 1], [4 x i32] [i32 5, i32 9, i32 2, i32 6], [4 x i32] [i32 5, i32 3, i32 5, i32 8], [4 x i32] [i32 9, i32 7, i32 9, i32 3]], align 16

define i32 @table_2d(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %2)  [register r]
  call void @cqrt_ry_i32(i32 %6, double %2)    ; IR: %5 = cq_theta_ui32(%0, %2)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %6 = cq_theta_ui32(%1, %3)  [register c]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %6 = cq_theta_ui32(%1, %3)  [Ry]
  %8 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %7 = and i32 %5, 3
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: %8 = zext nneg i32 %7 to i64
  %10 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %9 = and i32 %6, 3
  %11 = call i32 @cq_template_zext_i32_to_i64(i32 %10)    ; IR: %10 = zext nneg i32 %9 to i64
  %12 = call i32 @cq_template_mul_i64_hl(i32 %9, i64 16)    ; IR: %11 = getelementptr inbounds [4 x [4 x i32]], ptr @GRID, i64 0, i64 %8, i64 %10  [the row index scaled by the row size, 16 bytes (rule 20)]
  %13 = call i32 @cq_template_mul_i64_hl(i32 %11, i64 4)    ; IR: %11 = getelementptr  [the column index scaled by the element size, 4 bytes]
  %14 = call i32 @cq_template_add_i64(i32 %12, i32 %13)    ; IR: %11 = getelementptr  [the tainted part of the offset]
  %15 = call i32 @cq_template_add_i64_hl(i32 %14, i64 ptrtoint (ptr @GRID to i64))    ; IR: %11 = getelementptr  [+ the classical part, the host address of @GRID: the address rail of &GRID[r & 3][c & 3]]
  %16 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %15)    ; IR: %12 = load i32, ptr %11, align 4  [ONE bus load at the address rail: fresh rail ^= the 4 HOST cells of the table; measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_hl_unc(i32 %15, i32 %14, i64 ptrtoint (ptr @GRID to i64))    ; IR: uncompute %11  [the load is the address rail's last reader (rule 20)]
  call void @cqrt_free(i32 %15)    ; IR: release the %11 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %14, i32 %12, i32 %13)    ; IR: uncompute %11 (the tainted offset)
  call void @cqrt_free(i32 %14)    ; IR: release the offset rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %13, i32 %11, i64 4)    ; IR: uncompute %11 (the scaled column)
  call void @cqrt_free(i32 %13)    ; IR: release the scaled-column rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %12, i32 %9, i64 16)    ; IR: uncompute %11 (the scaled row)
  call void @cqrt_free(i32 %12)    ; IR: release the scaled-row rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %11, i32 %10)    ; IR: uncompute %10
  call void @cqrt_free(i32 %11)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %7, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %10)    ; IR: release the %9 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %8
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %6, i32 3)    ; IR: uncompute %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  %17 = call i32 @cqrt_measure_i32(i32 %16)    ; IR: %13 = cq_measure_si32(%12)  (the load copy stays allocated, rule 2)
  ret i32 %17    ; IR: ret i32 %13
}

define i32 @register_grid(ptr noundef %0, i32 noundef %1, double noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %4 = alloca [2 x [2 x i8]], align 4  [bus-resident: one zeroed block, no alloca remains; lifetime.start dropped (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; IR: P = the block's run-time address (classical i64, rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: store i32 0, ptr %4  [the seed of the stored value: the store's value rail, kept with it (rule 7)]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %7)    ; IR: store i32 0, ptr %4, align 4  [ONE i32 store: the 4 cells q[0][0]..q[1][1]; kept: slot, seed (rule 5); classical-valued, the cells stay HOST]
  %8 = icmp sgt i32 %1, 0    ; IR: %5  (classical)
  br i1 %8, label %9, label %15    ; IR: br i1 %5

9:
  %10 = zext nneg i32 %1 to i64    ; IR: %7  (classical)
  br label %11

11:
  %12 = phi i64 [ 0, %9 ], [ %20, %19 ]    ; IR: %9  (classical row i)
  %13 = shl nsw i64 %12, 4    ; IR: %10  (classical)
  %14 = getelementptr inbounds i8, ptr %0, i64 %13    ; IR: %11  (classical: &theta[2 * i])
  br label %22

15:
  %16 = icmp sgt i32 %1, 0    ; IR: %13  (classical)
  br i1 %16, label %17, label %32    ; IR: br i1 %13

17:
  %18 = zext nneg i32 %1 to i64    ; IR: %15  (classical)
  br label %52

19:
  %20 = add nuw nsw i64 %12, 1    ; IR: %17  (classical)
  %21 = icmp eq i64 %20, %10    ; IR: %18  (classical)
  br i1 %21, label %15, label %11    ; IR: br i1 %18

22:
  %23 = phi i64 [ 0, %11 ], [ %30, %22 ]    ; IR: %20  (classical column j)
  %24 = getelementptr inbounds [2 x [2 x i8]], ptr %5, i64 0, i64 %12, i64 %23    ; IR: %21 = getelementptr [2 x [2 x i8]], ptr %4, 0, %9, %20  (the cell q[i][j]: classical indices, the instruction stays)
  %25 = ptrtoint ptr %24 to i64    ; IR: %21  (its run-time address P + 2i + j, classical, rule 20)
  %26 = getelementptr inbounds double, ptr %14, i64 %23    ; IR: %24  (classical: &theta[2 * i + j])
  %27 = ptrtoint ptr %26 to i64    ; IR: %24  (its run-time address, classical)
  %28 = call i32 @cqrt_qram_load_f64_hl(i32 %4, i64 %27)    ; IR: %25 = load double, ptr %24  [a load through a host pointer parameter: a bus load, a rail (rule 3); the angle rail A; overtaken by the form below: un-copied after the swap-in, not freed (rule 5 sentence 1)]
  %29 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %22 = load i8, ptr %21; %23 = trunc nuw i8 %22 to i1: in-place form at width i1, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %25, i32 %29)    ; IR: %22 = load i8, ptr %21; %23 = trunc: swap-out of the cell's low bit: the rail holds q[i][j], that bit |0>
  call void @cqrt_ry_i1_qangle(i32 %29, i32 %28)    ; IR: %26 = cq_theta_i1(%23, %25)  [Ry by the quantum angle A on the cell's content (rules 11, 15)]
  call void @cqrt_qram_swap_i1_hl(i32 %4, i64 %25, i32 %29)    ; IR: %27 = zext i1 %26 to i8; store i8 %27, ptr %21: swap-in: the cell holds the rotated bit (its high bits never left)
  call void @cqrt_free(i32 %29)    ; IR: release the swap rail (|0>)
  call void @cqrt_qram_load_f64_hl_unc(i32 %28, i32 %4, i64 %27)    ; IR: un-copy %25 (the angle rail A): its last reader, the rotation, is done; the form's swap-out lies between, so it is not freed (rule 5 sentence 1)
  %30 = add nuw nsw i64 %23, 1    ; IR: %28  (classical)
  %31 = icmp eq i64 %23, 0    ; IR: %29  (classical)
  br i1 %31, label %22, label %19    ; IR: br i1 %29

32:
  %33 = getelementptr inbounds i8, ptr %5, i64 1    ; IR: %31 = getelementptr i8, ptr %4, 1  (the cell q[0][1])
  %34 = ptrtoint ptr %33 to i64    ; IR: %31  (its run-time address P + 1, classical)
  %35 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %34)    ; IR: %32 = load i8, ptr %31; %33 = trunc nuw i8 %32 to i1  [the flag: a load copy of q[0][1] taken BEFORE the form it controls]  ; un-copied after its last reader, the controlled swap-in, and not freed: the form's swap-out, a memory version change, lies between (rule 5 sentence 1); taken at i1 by rule 5 Width casts (a reader of a form)
  %36 = add nsw i32 %1, -1    ; IR: %49  (classical, from the arm block %48: br i1 %33 is a quantum branch, the arm is flattened under the flag)
  %37 = sext i32 %36 to i64    ; IR: %50  (classical)
  %38 = getelementptr inbounds [2 x [2 x i8]], ptr %5, i64 0, i64 %37, i64 1    ; IR: %51  (the cell q[rows-1][1]; = %33 when rows == 1)
  %39 = ptrtoint ptr %38 to i64    ; IR: %51  (its run-time address, classical)
  %40 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %52 = load i8, ptr %51; %53 = trunc: in-place form on q[rows-1][1] under the flag %33, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %35, i32 %4, i64 %39, i32 %40)    ; IR: %52 = load i8, ptr %51: swap-out under the flag (flag = 0: nothing touched, the rail stays |0>)
  call void @cqrt_ry_i1_controlled(i32 %35, i32 %40, double %2)    ; IR: %54 = cq_theta_i1(%53, %2)  [Ry on q[rows-1][1] controlled by the copy of q[0][1] (rule 10 on a memory cell)]
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %35, i32 %4, i64 %39, i32 %40)    ; IR: %55 = zext; store i8 %55, ptr %51: swap-in under the flag: the cell holds the result, the rail |0> on both branches
  call void @cqrt_qram_load_i1_hl_unc(i32 %35, i32 %4, i64 %34)    ; IR: un-copy %33 (the flag) after its last reader, the controlled swap-in; not freed (rule 5 sentence 1). When rows == 1 the cell was rotated in between and the rail keeps garbage; no rule asks which
  call void @cqrt_free(i32 %40)    ; IR: release the swap rail (|0>)
  %41 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %34)    ; IR: %57 = load i8, ptr %31; %58 = trunc nuw i8 %57 to i1  (q[0][1], a plain load after the form; measured, kept (rule 2))
  %42 = call i1 @cqrt_measure_i1(i32 %41)    ; IR: %59 = cq_measure_i1(%58)
  %43 = zext i1 %42 to i32    ; IR: %60  (classical)
  %44 = add nsw i32 %1, -1    ; IR: %61  (classical)
  %45 = sext i32 %44 to i64    ; IR: %62  (classical)
  %46 = getelementptr inbounds [2 x [2 x i8]], ptr %5, i64 0, i64 %45, i64 1    ; IR: %63  (the cell q[rows-1][1])
  %47 = ptrtoint ptr %46 to i64    ; IR: %63  (its run-time address, classical)
  %48 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %47)    ; IR: %64 = load i8, ptr %63; %65 = trunc nuw i8 %64 to i1  (q[rows-1][1]; measured, kept (rule 2))
  %49 = call i1 @cqrt_measure_i1(i32 %48)    ; IR: %66 = cq_measure_i1(%65)
  %50 = zext i1 %49 to i32    ; IR: %67  (classical)
  %51 = add nuw nsw i32 %50, %43    ; IR: %68  (classical)
  ret i32 %51    ; IR: llvm.lifetime.end(4, %4) dropped (rule 16); ret i32 %68

52:
  %53 = phi i64 [ 0, %17 ], [ %61, %60 ]    ; IR: %35  (classical row i)
  %54 = getelementptr inbounds [2 x [2 x i8]], ptr %5, i64 0, i64 %53    ; IR: %36  (the cell q[i][0])
  %55 = ptrtoint ptr %54 to i64    ; IR: %36  (its run-time address P + 2i, classical)
  %56 = call i32 @cqrt_qram_load_i1_hl(i32 %4, i64 %55)    ; IR: %37 = load i8, ptr %36; %38 = trunc nuw i8 %37 to i1  [the flag: a load copy of q[i][0]]  ; un-copied after its last reader, the controlled swap-in, and not freed: the form's swap-out, a memory version change, lies between (rule 5 sentence 1); taken at i1 by rule 5 Width casts (a reader of a form)
  %57 = getelementptr inbounds i8, ptr %54, i64 1    ; IR: %40 = getelementptr i8, ptr %36, 1  (the cell q[i][1]; classical, from the arm block %39: br i1 %38 is a quantum branch, the arm is flattened under the flag)
  %58 = ptrtoint ptr %57 to i64    ; IR: %40  (its run-time address, classical)
  %59 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %41 = load i8, ptr %40; %42 = trunc: in-place form on q[i][1] under the flag %38, the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %56, i32 %4, i64 %58, i32 %59)    ; IR: %41 = load i8, ptr %40: swap-out under the flag
  call void @cqrt_ry_i1_controlled(i32 %56, i32 %59, double %2)    ; IR: %43 = cq_theta_i1(%42, %2)  [Ry on q[i][1] controlled by the copy of q[i][0] (rule 10 on a memory cell)]
  call void @cqrt_qram_swap_i1_hl_controlled(i32 %56, i32 %4, i64 %58, i32 %59)    ; IR: %44 = zext; store i8 %44, ptr %40: swap-in under the flag
  call void @cqrt_qram_load_i1_hl_unc(i32 %56, i32 %4, i64 %55)    ; IR: un-copy %38 (the flag) after its last reader, the controlled swap-in; not freed (rule 5 sentence 1)
  call void @cqrt_free(i32 %59)    ; IR: release the swap rail (|0>)
  br label %60    ; IR: br label %45

60:
  %61 = add nuw nsw i64 %53, 1    ; IR: %46  (classical)
  %62 = icmp eq i64 %61, %18    ; IR: %47  (classical)
  br i1 %62, label %32, label %52    ; IR: br i1 %47
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1_qangle(i32, i32)
declare void @cqrt_ry_i1_controlled(i32, i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_f64_hl(i32, i64)
declare void @cqrt_qram_load_f64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_load_i1_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i1_hl_controlled(i32, i32, i64, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
