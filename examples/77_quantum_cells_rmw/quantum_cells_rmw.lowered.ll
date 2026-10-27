; HAND-WRITTEN. Rules: 20, 4, 5, 2.
; Checked: a[0] ^ a[1] ^ a[2] ^ a[3] after a[x & 3] += y over a = {y, y+1, y+2, y+3} (measured).
; Clean: the three initializer rails y+1, y+2, y+3, the index rail x & 3, the old-value copy-out and the sum, the four
; fixed-index copy-outs and the two inner xors, every store's tape slot (each pop returns it to |0>), and the QRAM a
; (every store popped, then cqrt_qram_free).
; Kept: the user registers x and y (y is also cell 0's value; never freed); the result rail (measured).
; Rotations: Ry(tx) on x; Ry(ty) on y.
; The four cells hold QUANTUM values from the start (a[0] is the register y itself, a[1..3] fresh rails y+1..y+3) and
; the array is read AND written at a quantum index, so the whole local array is a QRAM (rule 20; address decoding
; is the backend's circuit; ABI = the QRAM contract of §1.3, reference conversions 30 and 84):
; cqrt_qram_alloc_i32(4) at the alloca (cells |0>), and each initializer cell is one cqrt_qram_store_i32_hl(arr, j,
; rail) with the classical index (_hl = classical INDEX) and the VALUE always a handle (the rail stays live and is
; uncomputed later by its own producer; y is the user register and is never freed). `a[x & 3] += y` with quantum x is
; a read-modify-write at the quantum index rail idx = x & 3 (the logical-i32 index: -O1's zext to i64 and the gep
; scaling are not emitted): ONE cqrt_qram_load_i32(arr, idx) -> old (copy-out, cells preserved), sum = add(old, y) into
; a fresh rail, ONE cqrt_qram_store_i32(arr, idx, sum) (the store owns a fresh tape slot: the displaced cell[idx] is swapped
; into it, then cell[idx] ^= sum, a copy; sum unchanged). The
; fixed-index loads after it are cqrt_qram_load_i32_hl(arr, j) copy-outs, and the xors go into fresh rails.
; Uncomputation runs in reverse order before the measurement: the xors, the four fixed-index copy-outs, then the
; stores are popped (_unc, same arguments: the value, index and cells hold their forward values; y, a store value, is
; not rotated again), last-in-first-out among stores that may touch the same cell: the quantum-index store, which may
; touch every cell, first; then the initializer stores of cells 3, 2, 1, 0 (distinct cells: they commute), sum and
; old between them (old is un-copied after the store it preceded is popped, when cell[idx] holds the old value again),
; each initializer rail by its own producer, and cqrt_qram_free once every cell and every tape slot is |0> again. The
; contract fixes the unitary (a permutation of (cells, tape slots): slot <-> cell[idx], then cell[idx] ^= sum); the
; backend chooses the circuit (fan-out per cell as in
; Bennett.jl memory.jl, bucket brigade).
source_filename = "quantum_cells_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_cells_rmw(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %5 = alloca [4 x i32]: a 4-cell QRAM, cells |0> (the array holds quantum values and is written at a quantum index)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %2)    ; IR: %6 = cq_theta_ui32(%0, %2)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %7 = cq_theta_ui32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_ui32(%1, %3)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 0, i32 %7)    ; IR: store i32 %7, ptr %5: a[0] = y  (fixed index, the value a handle: the register y itself)
  %8 = call i32 @cq_template_add_i32_hl(i32 %7, i32 1)    ; IR: %9 = add i32 %7, 1
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 1, i32 %8)    ; IR: store i32 %9, ptr %8: a[1] = y + 1  (%8 = gep 4 is cell 1)
  %9 = call i32 @cq_template_add_i32_hl(i32 %7, i32 2)    ; IR: %11 = add i32 %7, 2
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 2, i32 %9)    ; IR: store i32 %11, ptr %10: a[2] = y + 2  (%10 = gep 8 is cell 2)
  %10 = call i32 @cq_template_add_i32_hl(i32 %7, i32 3)    ; IR: %13 = add i32 %7, 3
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 3, i32 %10)    ; IR: store i32 %13, ptr %12: a[3] = y + 3  (%12 = gep 12 is cell 3)
  %11 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %14 = and i32 %6, 3  [the index rail idx; %15 = zext to i64 and the gep %16 are not emitted: the index is the logical-i32 rail]
  %12 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %11)    ; IR: %17 = load i32, ptr %16: old = a[x & 3]  (one access: copy-out into a fresh rail, cells preserved)
  %13 = call i32 @cq_template_add_i32(i32 %12, i32 %7)    ; IR: %18 = add i32 %17, %7  [sum, a fresh rail]
  call void @cqrt_qram_store_i32(i32 %5, i32 %11, i32 %13)    ; IR: store i32 %18, ptr %16: a[x & 3] = sum  (one access; the displaced cell goes into this store's tape slot)
  %14 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 0)    ; IR: %19 = load a[0]  (fixed index into the quantum array: copy-out)
  %15 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 1)    ; IR: %20 = load a[1]
  %16 = call i32 @cq_template_xor_i32(i32 %15, i32 %14)    ; IR: %21 = xor i32 %20, %19
  %17 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 2)    ; IR: %22 = load a[2]
  %18 = call i32 @cq_template_xor_i32(i32 %16, i32 %17)    ; IR: %23 = xor i32 %21, %22
  %19 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 3)    ; IR: %24 = load a[3]
  %20 = call i32 @cq_template_xor_i32(i32 %18, i32 %19)    ; IR: %25 = xor i32 %23, %24  [result rail]
  call void @cq_template_xor_i32_unc(i32 %18, i32 %16, i32 %17)    ; IR: uncompute %23
  call void @cqrt_free(i32 %18)    ; IR: release the %23 rail (|0>)
  call void @cq_template_xor_i32_unc(i32 %16, i32 %15, i32 %14)    ; IR: uncompute %21
  call void @cqrt_free(i32 %16)    ; IR: release the %21 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %19, i32 %5, i32 3)    ; IR: un-copy %24 (a[3])
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %17, i32 %5, i32 2)    ; IR: un-copy %22 (a[2])
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %15, i32 %5, i32 1)    ; IR: un-copy %20 (a[1])
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %14, i32 %5, i32 0)    ; IR: un-copy %19 (a[0])
  call void @cqrt_free(i32 %14)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %5, i32 %11, i32 %13)    ; IR: pop the quantum-index store (the last store that may touch each cell): cell[idx] holds old again
  call void @cq_template_add_i32_unc(i32 %13, i32 %12, i32 %7)    ; IR: uncompute %18 (sum)
  call void @cqrt_free(i32 %13)    ; IR: release the %18 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %12, i32 %5, i32 %11)    ; IR: un-copy %17 (old) against the restored cell[idx]
  call void @cqrt_free(i32 %12)    ; IR: release the %17 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %11, i32 %6, i32 3)    ; IR: uncompute %14 (idx)
  call void @cqrt_free(i32 %11)    ; IR: release the %14 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 3, i32 %10)    ; IR: pop the initializer of a[3]
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %7, i32 3)    ; IR: uncompute %13 by its producer
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 2, i32 %9)    ; IR: pop the initializer of a[2]
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %7, i32 2)    ; IR: uncompute %11 by its producer
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 1, i32 %8)    ; IR: pop the initializer of a[1]
  call void @cq_template_add_i32_hl_unc(i32 %8, i32 %7, i32 1)    ; IR: uncompute %9 by its producer
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 0, i32 %7)    ; IR: pop the initializer of a[0] (the register y stays allocated: a user register)
  call void @cqrt_qram_free(i32 %5)    ; IR: llvm.lifetime.end: release the array (all cells |0>)
  %21 = call i32 @cqrt_measure_i32(i32 %20)    ; IR: %26 = cq_measure_ui32(%25)
  ret i32 %21    ; IR: ret i32 %26
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_xor_i32(i32, i32)
declare void @cq_template_xor_i32_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
