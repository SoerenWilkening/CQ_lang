; HAND-WRITTEN. Rules: 2, 4, 5, 7, 20, 22.
; Checked: local_array_quantum_index: v = arr[x & 3] (measured, %13 -> %14); local_array_quantum_write: arr[0] + arr[2]
; (measured, %11 -> %12).
; Clean: local_array_quantum_index: the index rail %12. local_array_quantum_write: the two fixed-index load rails %9, %10,
; the store's value handle %8 (basis state a, freed once its store is popped), the shared memset handle %5 (basis state
; 0, freed once its four stores are popped), the index rail %7, every store's tape slot (each pop returns it to |0>), and
; the 4-cell QRAM %4 (every cell back to |0> after every store is popped, then qram_free).
; Kept: x (%6 in each entry, the rotated register) and the two measured result rails; nothing else.
; Rotations: (Ry, x, th, 1) in each entry.
; A local array of classical values that is only READ at a quantum index stays classical memory and the read is a QROM
; over its contents at the load, not a QRAM, BECAUSE the array only ever holds classical values (rule 20: no store at a
; quantum index, no cell holding a quantum value, no quantum pointer into it; a, b, a + b, a * b are classical)
; (cq_template_qrom_load: table literal, length = the object's 4 cells, logical index rail x & 3 at the C expression's
; i32 width, fresh rail; -O1's zext to i64 and the gep scaling are address arithmetic and are not emitted, the same
; index form as the write). An array WRITTEN at a quantum index is a QRAM (address decoding is the backend's circuit;
; the ABI is the QRAM contract of §1.3): cqrt_qram_alloc_<W>(n) at the alloca (cells |0>). The initializer
; `= {0, 0, 0, 0}` is -O1's llvm.memset(arr, 0, 16): a memory intrinsic with a classical length over a QRAM is one
; cqrt_qram_store_<W>_hl(arr, j, val) per cell (rule 22; _hl = classical index), all four reading ONE basis-state
; handle cqrt_alloc_i32(0) (a store value is always a handle; a classical value is materialised once and shared, and
; freed after its last store is popped). The memset is emitted even though the cells already hold 0: every store owns
; a tape slot and the stores are part of the circuit the C program denotes. The quantum-index store is ONE
; cqrt_qram_store_<W>(arr, idx, val) with the logical-i32 index rail (x & 3) and the value a as a basis-state handle.
; Each store owns a fresh tape slot: the displaced cell is swapped into the slot, then the cell takes cell ^= val (a
; copy; val unchanged), so the store is a permutation of (cells, tape slots), not of the cells alone. A fixed-index read
; of the quantum array is cqrt_qram_load_<W>_hl(arr, j) -> fresh rail (copy-out, cell preserved; its _unc un-copies
; while the cell still holds the value it had at the load). Pops (_unc, same arguments) need the value, index and cells
; at their forward values and are ordered last-in-first-out only among stores that may touch the same cell: the
; quantum-index store may touch every cell, so it is popped first; the four memset stores touch distinct cells and
; commute (written in reverse order). After every store is popped each tape slot is |0> and released, the cells are
; |0>, and cqrt_qram_free releases the array.
source_filename = "local_array_quantum_index.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @local_array_quantum_index(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = alloca [4 x i32], align 16    ; IR: %5 = alloca [4 x i32]  (classical memory: holds only classical values)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  store i32 %2, ptr %5, align 16    ; IR: store i32 %2, ptr %5  (classical)
  %7 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %7
  store i32 %3, ptr %7, align 4    ; IR: store i32 %3, ptr %7  (classical)
  %8 = add nsw i32 %3, %2    ; IR: %8 = add nsw i32 %3, %2  (classical)
  %9 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %9
  store i32 %8, ptr %9, align 8    ; IR: store i32 %8, ptr %9  (classical)
  %10 = mul nsw i32 %3, %2    ; IR: %10 = mul nsw i32 %3, %2  (classical)
  %11 = getelementptr inbounds i8, ptr %5, i64 12    ; IR: %11
  store i32 %10, ptr %11, align 4    ; IR: store i32 %10, ptr %11  (classical)
  %12 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %12 = and i32 %6, 3
  %13 = call i32 @cq_template_qrom_load_i32(ptr %5, i64 4, i32 %12)    ; IR: %13 = zext %12; %14 = getelementptr %5, %13; %15 = load i32, ptr %14  [QROM over the classical array; index = the logical-i32 rail %12]
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %6, i32 3)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release the %12 rail (|0>)
  %14 = call i32 @cqrt_measure_i32(i32 %13)    ; IR: %16 = cq_measure_si32(%15)
  ret i32 %14    ; IR: ret i32 %16
}

define i32 @local_array_quantum_write(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %4 = alloca [4 x i32]: a 4-cell QRAM, cells |0> (the array is written at a quantum index)
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: call @llvm.memset(%4, 0, 16): the classical value 0 as ONE basis-state handle, shared by the four cell stores (rule 22)
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 0, i32 %5)    ; IR: memset: arr[0] = 0  (fixed-index store; its tape slot takes the displaced |0> cell)
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 1, i32 %5)    ; IR: memset: arr[1] = 0
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 2, i32 %5)    ; IR: memset: arr[2] = 0
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 3, i32 %5)    ; IR: memset: arr[3] = 0
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %6 = and i32 %5, 3  [the index; %7 = zext to i64 and the gep %8 are not emitted: the index is the logical-i32 rail]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2: the classical value a as a basis-state handle (the QRAM contract: a value is always a handle)
  call void @cqrt_qram_store_i32(i32 %4, i32 %7, i32 %8)    ; IR: store i32 %2, ptr %8: arr[x & 3] = a  (one access; the displaced cell goes into this store's tape slot)
  %9 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 0)    ; IR: %9 = load arr[0]  (fixed index into the quantum array: copy-out)
  %10 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i32 2)    ; IR: %11 = load arr[2]
  %11 = call i32 @cq_template_add_i32(i32 %10, i32 %9)    ; IR: %12 = add nsw i32 %11, %9  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %10, i32 %4, i32 2)    ; IR: uncompute %11
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %9, i32 %4, i32 0)    ; IR: uncompute %9
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %4, i32 %7, i32 %8)    ; IR: pop the quantum-index store (it may touch every cell, so it is popped before the memset stores): every cell holds its memset 0 again, its tape slot is |0> and released
  call void @cqrt_free(i32 %8)    ; IR: release the value handle (basis state a)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 3, i32 %5)    ; IR: pop the memset stores (distinct cells: they commute; written in reverse): arr[3] back to |0>
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 2, i32 %5)    ; IR: arr[2]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 1, i32 %5)    ; IR: arr[1]
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 0, i32 %5)    ; IR: arr[0]
  call void @cqrt_free(i32 %5)    ; IR: release the basis-state handle 0 (its last store was popped)
  call void @cqrt_qram_free(i32 %4)    ; IR: llvm.lifetime.end: release the array (every store popped, all cells |0>)
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %13 = cq_measure_si32(%12)
  ret i32 %12    ; IR: ret i32 %13
}

declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare void @cqrt_ry_i32(i32, double)
