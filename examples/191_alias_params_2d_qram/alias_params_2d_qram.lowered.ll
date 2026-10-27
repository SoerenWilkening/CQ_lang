; HAND-WRITTEN. Rules: 2, 4, 5, 7, 18, 20, 21, 22, §1.3 (QRAM contract), §1.4.
; Checked: alias_params: a[0] after addto (measured): 2 * a0 when x & 1 == 0 (q aliases p), a0 + a1 when x & 1 == 1.
; qram_2d: g[1][2] + g[r & 3][0] (measured): v * [r & 3 == 1 && c & 3 == 2] + v * [c & 3 == 0].
; Clean: alias_params: the clone's two load copy-outs and its sum (inside the clone), the stored value rail (popped, then
; cleared by the twin), the two initializer seeds a0, a1, the index rail x & 1, every tape slot, and the 2-cell QRAM a
; (qram_free). qram_2d: the two load copy-outs, the flattened index rail, the row-offset rail, r & 3, c & 3, the value
; seed v, the shared memset seed 0, every tape slot, and the 16-cell QRAM g (qram_free).
; Kept: alias_params: x (rotated register) and the measured result a[0]. qram_2d: r, c (rotated registers) and the
; measured result.
; Rotations: alias_params: (Ry, x, tx, 1). qram_2d: (Ry, r, tr, 1); (Ry, c, tc, 1).
; alias_params: a = {a0, a1} is read through q = a + (x & 1) inside addto, a QUANTUM-OFFSET load, and a[0] is later
; written with the quantum sum, so a may hold a handle: by rule 20 the whole object is a QRAM (qram_alloc_i32(2); the
; initializer is one store_hl per cell of a basis-state seed). Both pointer arguments cross the clone boundary as fat
; pointers (rule 21): (object, tag, i32 idx) with object = the QRAM bus handle of a (the object table; no mask digit), tag the
; classical 1 (single-object provenance {a}: no guard), idx the CELL index: p = (a, 1, 0) classical, q = (a, 1, x & 1)
; with a quantum idx. Mask per §1.4 over the fields tag_p, idx_p, tag_q, idx_q: 0001; the pointee cells add no digits,
; since a is a QRAM (§1.4: QRAM cells get no mask digits, a QRAM object is quantum by definition). In the clone *q is
; qram_load_i32 (quantum idx), *p is qram_load_i32_hl (classical idx), and *p = sum is qram_store_i32_hl. ALIASING:
; both loads are executed before the store (-O1's order), so when x & 1 == 0 both copy-outs read cell 0 = a0 and the
; store writes 2 * a0, exactly C's result; when x & 1 == 1 they read a1 and a0. Rule 18 copy-out: the sum is copied
; into a fresh rail v and the body (sum, both loads) is uncomputed BEFORE the store, while every cell still holds the
; value it had at the loads (a load's _unc requires that; after the store cell 0 has changed). The store keeps v as its
; value rail, and the pop precondition (§1.3) needs v at its forward value until the store is popped, so the clone
; RETURNS v as an extra i32 result (rule 18: a callee storing into a caller's QRAM returns each stored value rail)
; instead of freeing it. The caller copies
; out a[0], and at the lifetime end of a pops the clone's store first (it touched cell 0, after both initializer
; stores), then calls the twin __cq_q_addto_0001_unc(v, args...) (rule 18): with the store popped the cells are again a0, a1, so
; the twin recomputes both loads and the sum, XORs v to |0> with copy_i32 and uncomputes; the caller frees v. The
; initializer stores (distinct cells: they commute) are popped, their seeds freed, x & 1 uncomputed, the QRAM freed.
; The measured copy-out a[0] stands while the stores are popped (a pop permutes the cells only; 186).
; qram_2d: g is written at a QUANTUM offset, so it is a 16-cell QRAM. -O1's llvm.memset(g, 0, 64) is one store_hl per
; i32 cell of the shared seed 0 (rule 22, as in 30). The 2-D index is FLATTENED to the cell index (rule 20): the store's
; index rail is (r & 3) * 4 + (c & 3) (mul_i32_hl by the row length 4, then add_i32); -O1's gep %11 = &g[r & 3] is the
; row offset (r & 3) * 4, which is also the cell index of the load g[r & 3][0], so the two accesses share that rail.
; g[1][2] (-O1's byte offset 24) is cell 6: qram_load_i32_hl(g, 6). The zexts to i64 and the gep scaling are address
; arithmetic and are not emitted. At the lifetime end the copy-outs are un-copied, the quantum-index store (it may
; touch every cell) is popped before the 16 memset stores (distinct cells, written in reverse), and the QRAM is freed.
source_filename = "alias_params_2d_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @alias_params(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @cqrt_qram_alloc_i32(i32 2)    ; IR: %5 = alloca [2 x i32]: a 2-cell QRAM a, cells |0> (a quantum-offset load reads it and it may hold a handle)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %5: a0 as a basis-state handle
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 0, i32 %7)    ; IR: store i32 %2, ptr %5: a[0] = a0
  %8 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: store i32 %3, ptr %7: a1 as a basis-state handle
  call void @cqrt_qram_store_i32_hl(i32 %5, i32 1, i32 %8)    ; IR: store i32 %3, ptr %7: a[1] = a1
  %9 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)    ; IR: %8 = and i32 %6, 1  [q's cell index rail; zext %9 and gep %10 not emitted]
  %10 = call fastcc i32 @__cq_q_addto_0001(i32 %5, i32 1, i32 0, i32 %5, i32 1, i32 %9)    ; IR: call fastcc void @addto(ptr %5, ptr %10): p = (a, tag 1, idx 0), q = (a, tag 1, idx x & 1); returns the stored value rail v
  %11 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i32 0)    ; IR: %11 = load i32, ptr %5: a[0]  (copy-out)  [result rail]
  ; IR: llvm.lifetime.end(%5): the lifetime of a ends; clean-up in reverse order of its accesses
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 0, i32 %10)    ; IR: pop the clone's store *p = sum (last store to cell 0): cells a0, a1 again
  call fastcc void @__cq_q_addto_0001_unc(i32 %10, i32 %5, i32 1, i32 0, i32 %5, i32 1, i32 %9)    ; IR: twin: recompute the clone's loads and sum, XOR v to |0>
  call void @cqrt_free(i32 %10)    ; IR: release v (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 1, i32 %8)    ; IR: pop a[1] = a1
  call void @cqrt_free(i32 %8)    ; IR: release the seed a1 (rule 7)
  call void @cqrt_qram_store_i32_hl_unc(i32 %5, i32 0, i32 %7)    ; IR: pop a[0] = a0
  call void @cqrt_free(i32 %7)    ; IR: release the seed a0 (rule 7)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %6, i32 1)    ; IR: uncompute %8
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cqrt_qram_free(i32 %5)    ; IR: llvm.lifetime.end(%5): release the QRAM a (every store popped)
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %12 = cq_measure_si32(%11)
  ret i32 %12    ; IR: ret i32 %12
}

define internal fastcc i32 @__cq_q_addto_0001(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5) {
  %7 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %5)    ; IR: %3 = load i32, ptr %1: *q  (quantum cell index; tag classical, single object: no guard)
  %8 = call i32 @cqrt_qram_load_i32_hl(i32 %0, i32 %2)    ; IR: %4 = load i32, ptr %0: *p  (classical cell index)
  %9 = call i32 @cq_template_add_i32(i32 %8, i32 %7)    ; IR: %5 = add nsw i32 %4, %3
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %5  [copy-out v: the value the store keeps]
  call void @cqrt_copy_i32(i32 %9, i32 %10)    ; IR: %5
  call void @cq_template_add_i32_unc(i32 %9, i32 %8, i32 %7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %8, i32 %0, i32 %2)    ; IR: un-copy %4 (cells unchanged since the load)
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %7, i32 %3, i32 %5)    ; IR: un-copy %3 (cells unchanged since the load)
  call void @cqrt_free(i32 %7)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl(i32 %0, i32 %2, i32 %10)    ; IR: store i32 %5, ptr %0: *p = sum  (after both loads: aliasing gives C's result)
  ret i32 %10    ; IR: ret void  (v is returned: the store's pop needs it)
}

define internal fastcc void @__cq_q_addto_0001_unc(i32 %0, i32 %1, i32 %2, i32 %3, i32 %4, i32 %5, i32 %6) {
  %8 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %6)    ; IR: recompute %3 (*q; the caller popped the store, cells as at the clone's loads)
  %9 = call i32 @cqrt_qram_load_i32_hl(i32 %1, i32 %3)    ; IR: recompute %4 (*p)
  %10 = call i32 @cq_template_add_i32(i32 %9, i32 %8)    ; IR: recompute %5
  call void @cqrt_copy_i32(i32 %10, i32 %0)    ; IR: XOR v out: v is |0>, the caller frees it
  call void @cq_template_add_i32_unc(i32 %10, i32 %9, i32 %8)    ; IR: uncompute %5
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %9, i32 %1, i32 %3)    ; IR: un-copy %4
  call void @cqrt_free(i32 %9)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %8, i32 %4, i32 %6)    ; IR: un-copy %3
  call void @cqrt_free(i32 %8)    ; IR: release it (|0>)
  ret void
}

define i32 @qram_2d(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @cqrt_qram_alloc_i32(i32 16)    ; IR: %6 = alloca [4 x [4 x i32]]: a 16-cell QRAM g (written at a quantum offset), cells |0>
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register r]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_ui32(%2, %3)  [register c]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %8 = cq_theta_ui32(%2, %3)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: call @llvm.memset(%6, 0, 64): 0 as ONE basis-state handle shared by the 16 cell stores (rule 22)
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 0, i32 %9)    ; IR: memset: cell 0
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 1, i32 %9)    ; IR: memset: cell 1
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 2, i32 %9)    ; IR: memset: cell 2
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 3, i32 %9)    ; IR: memset: cell 3
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 4, i32 %9)    ; IR: memset: cell 4
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 5, i32 %9)    ; IR: memset: cell 5
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 6, i32 %9)    ; IR: memset: cell 6
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 7, i32 %9)    ; IR: memset: cell 7
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 8, i32 %9)    ; IR: memset: cell 8
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 9, i32 %9)    ; IR: memset: cell 9
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 10, i32 %9)    ; IR: memset: cell 10
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 11, i32 %9)    ; IR: memset: cell 11
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 12, i32 %9)    ; IR: memset: cell 12
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 13, i32 %9)    ; IR: memset: cell 13
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 14, i32 %9)    ; IR: memset: cell 14
  call void @cqrt_qram_store_i32_hl(i32 %6, i32 15, i32 %9)    ; IR: memset: cell 15
  %10 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %9 = and i32 %7, 3  [row; zext %10 not emitted]
  %11 = call i32 @cq_template_mul_i32_hl(i32 %10, i32 4)    ; IR: %11 = getelementptr [4 x [4 x i32]], %6, 0, %10: row offset (r & 3) * 4 in cells
  %12 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %12 = and i32 %8, 3  [column; zext %13 not emitted]
  %13 = call i32 @cq_template_add_i32(i32 %11, i32 %12)    ; IR: %14 = getelementptr [4 x [4 x i32]], %6, 0, %10, %13: flattened cell index (r & 3) * 4 + (c & 3)
  %14 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: store i32 %4, ptr %14: v as a basis-state handle
  call void @cqrt_qram_store_i32(i32 %6, i32 %13, i32 %14)    ; IR: store i32 %4, ptr %14: g[r & 3][c & 3] = v  (one QRAM store)
  %15 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i32 6)    ; IR: %15 = gep %6, 24; %16 = load i32, ptr %15: g[1][2] = cell 6
  %16 = call i32 @cqrt_qram_load_i32(i32 %6, i32 %11)    ; IR: %17 = load i32, ptr %11: g[r & 3][0] = cell (r & 3) * 4
  %17 = call i32 @cq_template_add_i32(i32 %16, i32 %15)    ; IR: %18 = add nsw i32 %17, %16  [result rail]
  ; IR: llvm.lifetime.end(%6): clean-up in reverse order of the accesses
  call void @cqrt_qram_load_i32_unc(i32 %16, i32 %6, i32 %11)    ; IR: un-copy %17
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %15, i32 %6, i32 6)    ; IR: un-copy %16
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_unc(i32 %6, i32 %13, i32 %14)    ; IR: pop g[r & 3][c & 3] = v (may touch every cell: before the memset stores)
  call void @cqrt_free(i32 %14)    ; IR: release the seed v (rule 7)
  call void @cq_template_add_i32_unc(i32 %13, i32 %11, i32 %12)    ; IR: uncompute the flattened index
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %12, i32 %8, i32 3)    ; IR: uncompute %12
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_mul_i32_hl_unc(i32 %11, i32 %10, i32 4)    ; IR: uncompute the row offset
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %7, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 15, i32 %9)    ; IR: pop the memset stores (distinct cells, reverse order): cell 15
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 14, i32 %9)    ; IR: cell 14
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 13, i32 %9)    ; IR: cell 13
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 12, i32 %9)    ; IR: cell 12
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 11, i32 %9)    ; IR: cell 11
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 10, i32 %9)    ; IR: cell 10
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 9, i32 %9)    ; IR: cell 9
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 8, i32 %9)    ; IR: cell 8
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 7, i32 %9)    ; IR: cell 7
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 6, i32 %9)    ; IR: cell 6
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 5, i32 %9)    ; IR: cell 5
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 4, i32 %9)    ; IR: cell 4
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 3, i32 %9)    ; IR: cell 3
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 2, i32 %9)    ; IR: cell 2
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 1, i32 %9)    ; IR: cell 1
  call void @cqrt_qram_store_i32_hl_unc(i32 %6, i32 0, i32 %9)    ; IR: cell 0
  call void @cqrt_free(i32 %9)    ; IR: release the shared seed 0 (its last store popped)
  call void @cqrt_qram_free(i32 %6)    ; IR: llvm.lifetime.end(%6): release the QRAM g
  %18 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %19 = cq_measure_si32(%18)
  ret i32 %18    ; IR: ret i32 %19
}

declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_qram_alloc_i32(i32)
declare void @cqrt_qram_free(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i32)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32_hl(i32, i32)
declare void @cq_template_mul_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
