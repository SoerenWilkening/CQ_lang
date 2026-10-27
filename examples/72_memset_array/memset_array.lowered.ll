; HAND-WRITTEN. Rules: 22, 20, 14, 4, 5, 7, 2.
; Checked: memset_over_quantum: before + a[1], before = a[k & 3] read before the memset; memset_quantum_byte:
; b[0] + b[3] (measured).
; Clean: memset_over_quantum: the four fill-value rails x + i, both fixed-index copy-outs, the index rail x & 3, the
; basis-state handles 0 and c (rule 7), and the QRAM a (every store popped, then cqrt_qram_free); memset_quantum_byte:
; the fill byte (char)x, the index rail y & 3, both copy-outs and their zexts, the basis-state handle 7, and the QRAM b.
; In both, every store's tape slot (each pop returns it to |0>).
; Kept: the user registers (x; x and y); the result rail (measured).
; Rotations: Ry(th) on x (memset_over_quantum); Ry(tx) on x and Ry(ty) on y (memset_quantum_byte).
; Both arrays are written at a QUANTUM index (a[x & 3] = c, b[y & 3] = 7: a quantum-offset store), so each is a QRAM
; for its whole lifetime (rule 20; holding quantum values alone would only make a slot array; the per-cell circuit is
; the backend's; ABI = the QRAM contract of §1.3): cqrt_qram_alloc_<W>(n) at the alloca (cells |0>) and every access ONE
; call, the classical-offset accesses in their _hl form. The quantum-index store is what keeps this the QRAM memset
; witness. llvm.memset over such an array is a
; fixed-size intrinsic, not a loop (rule 22): its lowering is one fixed-index store cqrt_qram_store_<W>_hl(arr, j, val)
; per cell (_hl = classical INDEX), not an unrolled ladder. memset_over_quantum: the fill loop writes the quantum value
; x + i into cell i by store_hl at the classical loop index (the value rail stays live and is uncomputed by its
; producer in the reverse loop, after its store is popped); before = a[k & 3] is a fixed-index copy-out
; cqrt_qram_load_<W>_hl(arr, j) -> fresh rail (cell preserved; its _unc un-copies once the cell holds that value
; again); memset(a, 0) is four store_hl of ONE basis-state handle cqrt_alloc_i32(0) (a store value is ALWAYS a handle;
; a classical value is materialised once, shared by every store that reads it, and freed after its last store is
; popped); the quantum-index write a[x & 3] = c is one cqrt_qram_store_<W>(arr, idx, val) with the logical-i32 index
; rail (x & 3; -O1's zext to i64 and the gep scaling are not emitted) and c as a handle. memset_quantum_byte: the fill
; byte is a quantum rail (trunc of x) and every i8 cell takes it by store_hl (one rail may feed many stores; it is
; uncomputed once, by its trunc, after the four stores are popped); the fixed-index reads b[0], b[3] are copy-outs.
; Each store owns a fresh tape slot: the displaced cell is swapped into the slot, then cell ^= val (a copy; val
; unchanged), so a store is a permutation of (cells, tape slots), not of the cells alone. Pops (_unc, same arguments)
; need the value, index and cells at their forward values (every value rail here is unrotated and live until after
; its pop) and are ordered last-in-first-out only among stores that may touch the same cell: the quantum-index store
; may touch every cell and is popped first, then the memset stores (distinct cells: they commute; written in reverse),
; then the fill stores in the reverse loop (each after the memset store of its cell); a copy-out is un-copied while its
; cell holds the value it had at the load (before = a[k & 3] after the memset stores are popped). Each pop returns its
; slot to |0>; then cqrt_qram_free releases the all-|0> array. The backend chooses the circuit.
source_filename = "memset_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @memset_over_quantum(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %5 = alloca [4 x i32]: a 4-cell QRAM, cells |0> (it is written at a quantum index: a[x & 3] = c)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  br label %7    ; IR: br label %19

7:
  %8 = phi i64 [ 0, %4 ], [ %11, %7 ]    ; IR: %20 = phi i64 [ 0, %4 ], [ %24, %19 ]  (classical i)
  %9 = trunc nuw nsw i64 %8 to i32    ; IR: %21 = trunc nuw nsw i64 %20 to i32  (classical)
  %10 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %9)    ; IR: %22 = add i32 %6, %21  [a[i]'s value rail]
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 %9, i32 %10)    ; IR: store i32 %22, ptr %23: a[i] = x + i  (fixed index i; the %23 gep is not emitted; the cell takes the value, the rail stays live)
  call void @cqrt_push(i32 %10)    ; IR: %22 keeps its owner: the reverse loop pops it, pops its store and uncomputes it
  %11 = add nuw nsw i64 %8, 1    ; IR: %24 = add nuw nsw i64 %20, 1  (classical)
  %12 = icmp eq i64 %11, 4    ; IR: %25 = icmp eq i64 %24, 4  (classical bound)
  br i1 %12, label %13, label %7    ; IR: br i1 %25, label %7, label %19

13:
  %14 = and i32 %3, 3    ; IR: %8 = and i32 %3, 3  (classical index; the %9 zext and the %10 gep are not emitted)
  %15 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 %14)    ; IR: %11 = load i32, ptr %10: before = a[k & 3]  (fixed-index copy-out of a quantum cell)
  %16 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: call @llvm.memset(%5, 0, 16): the classical value 0 as ONE basis-state handle, shared by the four cell stores
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 0, i32 %16)    ; IR: memset: a[0] = 0  (the displaced x + 0 is swapped into this store's tape slot)
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 1, i32 %16)    ; IR: memset: a[1] = 0
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 2, i32 %16)    ; IR: memset: a[2] = 0
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 3, i32 %16)    ; IR: memset: a[3] = 0
  %17 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %12 = and i32 %6, 3  [the index rail; the %13 zext and the %14 gep are not emitted]
  %18 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %14: the classical value c as a basis-state handle
  call void @cqrt_qram_store_i32(i32 %5, i32 %17, i32 %18)    ; IR: store i32 %2, ptr %14: a[x & 3] = c  (one access; the backend fans out over the cells)
  %19 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 1)    ; IR: %16 = load i32, ptr %15: a[1]  (fixed-index copy-out; the %15 gep is not emitted)
  %20 = call i32 @cq_template_add_i32(i32 %19, i32 %15)    ; IR: %17 = add nsw i32 %16, %11  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %19, i32 %5, i32 1)    ; IR: uncompute %16 (un-copy; the cell is unchanged since the copy-out)
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %5, i32 %17, i32 %18)    ; IR: pop the quantum-index store: every cell holds its memset 0 again
  call void @cqrt_free(i32 %18)    ; IR: release the value handle (basis state c)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %6, i32 3)    ; IR: uncompute %12
  call void @cqrt_free(i32 %17)    ; IR: release the %12 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 3, i32 %16)    ; IR: pop the memset stores (after the quantum-index store that may touch the same cells; among themselves they commute): a[3] holds x + 3 again
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 2, i32 %16)    ; IR: a[2]
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 1, i32 %16)    ; IR: a[1]
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 0, i32 %16)    ; IR: a[0]
  call void @cqrt_free(i32 %16)    ; IR: release the basis-state handle 0 (its last store was popped)
  call void @cqrt_qram_load_i32_hl_unc(i32 %15, i32 %5, i32 %14)    ; IR: uncompute %11: a[k & 3] holds x + (k & 3) again, as at the copy-out
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  br label %21

21:
  %22 = phi i64 [ 3, %13 ], [ %25, %21 ]    ; IR: reverse of the fill loop: i from 3 down to 0
  %23 = call i32 @cqrt_pop()    ; IR: the %22 rail of this i
  %24 = trunc nuw nsw i64 %22 to i32    ; IR: %21 of that trip (classical)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 %24, i32 %23)    ; IR: pop store i32 %22, ptr %23: a[i] back to |0> (after the later stores to cell i: the fill stores were the first on the array)
  call void @cq_template_add_i32_hl_unc(i32 %23, i32 %6, i32 %24)    ; IR: uncompute %22
  call void @cqrt_free(i32 %23)    ; IR: release the %22 rail (|0>)
  %25 = add nsw i64 %22, -1
  %26 = icmp sgt i64 %22, 0
  br i1 %26, label %21, label %27

27:
  call void @cqrt_qram_free(i32 %5)    ; IR: llvm.lifetime.end: release the array (every store popped, all cells |0>)
  %28 = call i32 @cqrt_measure_i32(i32 %20)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %28    ; IR: ret i32 %18
}

define i32 @memset_quantum_byte(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @cqrt_qram_alloc_i8(i32 4)    ; IR: %5 = alloca [4 x i8]: a 4-cell i8 QRAM, cells |0> (it is written at a quantum index: b[y & 3] = 7)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %2)    ; IR: %6 = cq_theta_ui32(%0, %2)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %7 = cq_theta_ui32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %7, double %3)    ; IR: %7 = cq_theta_ui32(%1, %3)  [Ry]
  %8 = call i32 @cq_template_trunc_i32_to_i8(i32 %6)    ; IR: %8 = trunc i32 %6 to i8  [the fill byte rail]
  call void @cqrt_qram_store_i8_hl(i32 %5, i32 0, i32 %8)    ; IR: call @llvm.memset(%5, %8, 4): b[0] = (char)x  (fixed-index store of the quantum fill byte; the rail stays live)
  call void @cqrt_qram_store_i8_hl(i32 %5, i32 1, i32 %8)    ; IR: memset: b[1] = (char)x
  call void @cqrt_qram_store_i8_hl(i32 %5, i32 2, i32 %8)    ; IR: memset: b[2] = (char)x
  call void @cqrt_qram_store_i8_hl(i32 %5, i32 3, i32 %8)    ; IR: memset: b[3] = (char)x
  %9 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %9 = and i32 %7, 3  [the index rail; the %10 zext and the %11 gep are not emitted]
  %10 = call i32 @cqrt_alloc_i8(i8 7)    ; IR: store i8 7, ptr %11: the classical value 7 as a basis-state handle
  call void @cqrt_qram_store_i8(i32 %5, i32 %9, i32 %10)    ; IR: store i8 7, ptr %11: b[y & 3] = 7  (one access; the backend fans out over the cells)
  %11 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i32 0)    ; IR: %12 = load i8, ptr %5: b[0]  (fixed-index copy-out)
  %12 = call i32 @cq_template_zext_i8_to_i32(i32 %11)    ; IR: %13 = zext i8 %12 to i32
  %13 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i32 3)    ; IR: %15 = load i8, ptr %14: b[3]  (the %14 gep is not emitted)
  %14 = call i32 @cq_template_zext_i8_to_i32(i32 %13)    ; IR: %16 = zext i8 %15 to i32
  %15 = call i32 @cq_template_add_i32(i32 %14, i32 %12)    ; IR: %17 = add nuw nsw i32 %16, %13  [result rail]
  call void @cq_template_zext_i8_to_i32_unc(i32 %14, i32 %13)    ; IR: uncompute %16
  call void @cqrt_free(i32 %14)    ; IR: release the %16 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %13, i32 %5, i32 3)    ; IR: uncompute %15 (un-copy)
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_zext_i8_to_i32_unc(i32 %12, i32 %11)    ; IR: uncompute %13
  call void @cqrt_free(i32 %12)    ; IR: release the %13 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %11, i32 %5, i32 0)    ; IR: uncompute %12 (un-copy)
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i8_unc(i32 %5, i32 %9, i32 %10)    ; IR: pop the quantum-index store: every cell holds the fill byte again
  call void @cqrt_free(i32 %10)    ; IR: release the value handle (basis state 7)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %7, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release the %9 rail (|0>)
  call void @cqrt_qram_store_i8_hl_unc(i32 %5, i32 3, i32 %8)    ; IR: pop the memset stores (after the quantum-index store; among themselves they commute): b[3] back to |0>
  call void @cqrt_qram_store_i8_hl_unc(i32 %5, i32 2, i32 %8)    ; IR: b[2]
  call void @cqrt_qram_store_i8_hl_unc(i32 %5, i32 1, i32 %8)    ; IR: b[1]
  call void @cqrt_qram_store_i8_hl_unc(i32 %5, i32 0, i32 %8)    ; IR: b[0]
  call void @cq_template_trunc_i32_to_i8_unc(i32 %8, i32 %6)    ; IR: uncompute %8 (the fill byte all four cells took; its last store was popped)
  call void @cqrt_free(i32 %8)    ; IR: release the %8 rail (|0>)
  call void @cqrt_qram_free(i32 %5)    ; IR: llvm.lifetime.end: release the array (every store popped, all cells |0>)
  %16 = call i32 @cqrt_measure_i32(i32 %15)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %16    ; IR: ret i32 %18
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_alloc_i32(i32)
declare i32 @cqrt_qram_alloc_i8(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_unc(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i32)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_trunc_i32_to_i8(i32)
declare void @cq_template_trunc_i32_to_i8_unc(i32, i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
