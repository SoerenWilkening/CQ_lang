; HAND-WRITTEN. Rules: 26, 20, 4, 5, 7, 2, §1.3 (QRAM contract).
; Checked: arr[(i + 2) & 3].v + arr[(i + 1) & 3].w (measured).
; Clean: the three index rails, old, sum, the second load, every initializer handle, both field arrays (every store
;        popped LIFO per array, then released).
; Kept: the register i (frozen) and the measured result rail.
; Rotations: Ry(ti) on i.
; An array of structs written AND read at a quantum index is a QRAM (rule 20, owner ruling 2026-10-25); by rule 26 a
; struct cell is its fields, so the object is ONE QRAM PER FIELD COLUMN: arr_v and arr_w, 4 i32 cells each (the stride
; of the struct gep is the column choice, -O1's zext to i64 and the gep scaling are address arithmetic and are not
; emitted; the index rail is the logical-i32 index at the C expression's width). The memcpy of the constant initializer
; is one cqrt_qram_store_i32_hl(col, j, cqrt_alloc_i32(v)) per cell per column (the value always a handle; a
; basis-state seed, freed once its store is popped; rule 22's per-cell fixed-index stores). `arr[i & 3].v += c` is 77's
; READ-MODIFY-WRITE on the v column at idx1 = i & 3: ONE cqrt_qram_load_i32(arr_v, idx1) -> old (copy-out, cells
; preserved), sum = add_hl(old, c) into a fresh rail, ONE cqrt_qram_store_i32(arr_v, idx1, sum). The second statement
; stores the SAME rail sum (-O1 forwarded the re-read of arr[i & 3].v) into the w column at idx2 = (i + 1) & 3, and the
; final read is a load of the v column at idx3 = idx1 ^ 2 (-O1's spelling of (i + 2) & 3), added to sum into the
; result rail. Uncomputation runs in reverse (rule 5): the second load is un-copied, idx3 uncomputed, the w store popped
; (the only store on arr_w) and idx2's chain uncomputed, the v store popped (cell[idx1] holds old again), sum and then
; old uncomputed (old against the restored cell), idx1 uncomputed; then the initializer stores are popped LIFO per
; column, each seed handle freed, and both columns are released (all cells |0>).
source_filename = "struct_array_quantum_index_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @struct_array_quantum_index_rmw(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %4 = alloca [4 x %struct.cell]: the v column, a 4-cell i32 QRAM (cells |0>)
  %5 = call i32 @cqrt_qram_alloc_i32(i32 4)    ; IR: %4: the w column, a 4-cell i32 QRAM
  %6 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: llvm.memcpy(%4, @__const...arr, 32): arr[0].v = 1 as a basis-state handle
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 0, i32 %6)    ; IR: memcpy: arr[0].v = 1
  %7 = call i32 @cqrt_alloc_i32(i32 2)    ; IR: memcpy: arr[0].w = 2
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 0, i32 %7)    ; IR: memcpy: arr[0].w = 2
  %8 = call i32 @cqrt_alloc_i32(i32 3)    ; IR: memcpy: arr[1].v = 3
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 1, i32 %8)    ; IR: memcpy: arr[1].v = 3
  %9 = call i32 @cqrt_alloc_i32(i32 4)    ; IR: memcpy: arr[1].w = 4
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 1, i32 %9)    ; IR: memcpy: arr[1].w = 4
  %10 = call i32 @cqrt_alloc_i32(i32 5)    ; IR: memcpy: arr[2].v = 5
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 2, i32 %10)    ; IR: memcpy: arr[2].v = 5
  %11 = call i32 @cqrt_alloc_i32(i32 6)    ; IR: memcpy: arr[2].w = 6
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 2, i32 %11)    ; IR: memcpy: arr[2].w = 6
  %12 = call i32 @cqrt_alloc_i32(i32 7)    ; IR: memcpy: arr[3].v = 7
  call void @cqrt_qram_store_i32_hl(i32 %4, i32 3, i32 %12)    ; IR: memcpy: arr[3].v = 7
  %13 = call i32 @cqrt_alloc_i32(i32 8)    ; IR: memcpy: arr[3].w = 8
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 3, i32 %13)    ; IR: memcpy: arr[3].w = 8
  %14 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register i]
  call void @cqrt_ry_i32(i32 %14, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %15 = call i32 @cq_template_and_i32_hl(i32 %14, i32 3)    ; IR: %6 = and i32 %5, 3  [idx1; %7 = zext and the struct gep %8 are not emitted: the index is the logical-i32 rail, the gep's field 0 picks the v column]
  %16 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %15)    ; IR: %9 = load i32, ptr %8: old = arr[idx1].v  (one access: copy-out, cells preserved)
  %17 = call i32 @cq_template_add_i32_hl(i32 %16, i32 %2)    ; IR: %10 = add nsw i32 %9, %2  [sum, a fresh rail]
  call void @cqrt_qram_store_i32(i32 %4, i32 %15, i32 %17)    ; IR: store i32 %10, ptr %8: arr[idx1].v = sum  (one access; the backend keeps the displaced cell on its tape)
  %18 = call i32 @cq_template_add_i32_hl(i32 %14, i32 1)    ; IR: %11 = add i32 %5, 1
  %19 = call i32 @cq_template_and_i32_hl(i32 %18, i32 3)    ; IR: %12 = and i32 %11, 3  [idx2; %13 = zext and the gep %14 (field 1: the w column) are not emitted]
  call void @cqrt_qram_store_i32(i32 %5, i32 %19, i32 %17)    ; IR: store i32 %10, ptr %14: arr[idx2].w = sum  (the forwarded re-read of arr[i & 3].v is the sum rail itself)
  %20 = call i32 @cq_template_xor_i32_hl(i32 %15, i32 2)    ; IR: %15 = xor i32 %6, 2  [idx3 = (i + 2) & 3; %16 = zext and the gep %17 are not emitted]
  %21 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %20)    ; IR: %18 = load i32, ptr %17: arr[idx3].v  (copy-out)
  %22 = call i32 @cq_template_add_i32(i32 %21, i32 %17)    ; IR: %19 = add nsw i32 %18, %10  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %21, i32 %4, i32 %20)    ; IR: un-copy %18
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_xor_i32_hl_unc(i32 %20, i32 %15, i32 2)    ; IR: uncompute idx3
  call void @cqrt_free(i32 %20)    ; IR: release the %15 rail (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %5, i32 %19, i32 %17)    ; IR: pop the w store (the last and only store on the w column)
  call void @cq_template_and_i32_hl_unc(i32 %19, i32 %18, i32 3)    ; IR: uncompute idx2
  call void @cqrt_free(i32 %19)    ; IR: release the %12 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %18, i32 %14, i32 1)    ; IR: uncompute %11
  call void @cqrt_free(i32 %18)    ; IR: release the %11 rail (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %4, i32 %15, i32 %17)    ; IR: pop the quantum-index store on the v column (LIFO: its last store): cell[idx1] holds old again
  call void @cq_template_add_i32_hl_unc(i32 %17, i32 %16, i32 %2)    ; IR: uncompute %10 (sum)
  call void @cqrt_free(i32 %17)    ; IR: release the %10 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %16, i32 %4, i32 %15)    ; IR: un-copy %9 (old) against the restored cell[idx1]
  call void @cqrt_free(i32 %16)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %15, i32 %14, i32 3)    ; IR: uncompute idx1
  call void @cqrt_free(i32 %15)    ; IR: release the %6 rail (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 3, i32 %13)    ; IR: pop the initializer (LIFO per column): arr[3].w
  call void @cqrt_free(i32 %13)    ; IR: release the basis-state handle 8
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 3, i32 %12)    ; IR: arr[3].v
  call void @cqrt_free(i32 %12)    ; IR: release the basis-state handle 7
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 2, i32 %11)    ; IR: arr[2].w
  call void @cqrt_free(i32 %11)    ; IR: release the basis-state handle 6
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 2, i32 %10)    ; IR: arr[2].v
  call void @cqrt_free(i32 %10)    ; IR: release the basis-state handle 5
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 1, i32 %9)    ; IR: arr[1].w
  call void @cqrt_free(i32 %9)    ; IR: release the basis-state handle 4
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 1, i32 %8)    ; IR: arr[1].v
  call void @cqrt_free(i32 %8)    ; IR: release the basis-state handle 3
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 0, i32 %7)    ; IR: arr[0].w
  call void @cqrt_free(i32 %7)    ; IR: release the basis-state handle 2
  call void @cqrt_qram_store_i32_hl_unc(i32 %4, i32 0, i32 %6)    ; IR: arr[0].v
  call void @cqrt_free(i32 %6)    ; IR: release the basis-state handle 1
  call void @cqrt_qram_free(i32 %5)    ; IR: llvm.lifetime.end(%4): release the w column (all cells |0>)
  call void @cqrt_qram_free(i32 %4)    ; IR: llvm.lifetime.end(%4): release the v column
  %23 = call i32 @cqrt_measure_i32(i32 %22)    ; IR: %20 = cq_measure_si32(%19)
  ret i32 %23    ; IR: ret i32 %20
}

declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_xor_i32_hl(i32, i32)
declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
