; HAND-WRITTEN. Rules: 2, 4, 5, 6, 7, 16, 20, 21.
; Checked: a + b (the add rail %37, measured -> %38), and the cells of a, b and slot read from the bus at exit:
; with i = k & 1 and j = (k >> 1) & 1: slot[0] = &a, slot[1] = &b; *slot[i] = v; *slot[j] += 3.
;   i = 0, j = 0: a = v + 3, b = x          i = 0, j = 1: a = v, b = x + 3
;   i = 1, j = 0: a = 4,     b = v          i = 1, j = 1: a = 1, b = v + 3
; so a + b = v + 3 + x when bit 0 of k is 0 and v + 4 when it is 1, whatever bit 1 of k is.
; Clean: both address chains (k & 1, its zext, the scaling by 8, the add of slot's address: %20..%23; k >> 1, & 1,
; zext, scaling, add: %26..%30), uncomputed and freed right after the un-copy of the load they address; the three rails of the
; in-place form (the swap rail %32, the rule-6 inverse %34, the updated rail %33); the load copies of a and b (%35,
; %36), un-copied after the add: no memory version change follows them.
; Kept: k (%10) and x (%11), the rotated registers (x is also the value rail of the kept store b = x); the sum (%37,
; measured); by rule 5, for the shot: the tape slots of the five stores (a = 1, b = x, slot[0] = &a, slot[1] = &b,
; *p = v) and their seed value rails %13 (1), %16 (&a), %19 (&b), %25 (v); left allocated after their un-copy (rule 5
; sentence 1, overtaken): the load copy p = slot[k & 1] (%24), the address rail of the store *p = v, un-copied after
; that store; the load copy *pp = slot[(k >> 1) & 1] (%31), the address rail of the in-place form, un-copied after
; its second swap. The in-place form itself keeps nothing.
; Rotations: (Ry, k, tk, 1); (Ry, x, tx, 1).
; Expected: bus_pointer_cell(1, .5, 4, .25, 9): Ry(.5) on every qubit of k = 1 leaves bit 0 of k at 1 with probability
; cos^2(.25) = 0.9388, and then the measured value is v + 4 = 13; with probability sin^2(.25) = 0.0612 it is
; 12 + x mod 2^32 for the value x the rotated register holds (x = 4, measured value 16, has probability
; cos^2(.125)^32 = 0.6057 within that branch: 0.0371 in all). Bit 1 of k (1 with probability sin^2(.25)) decides only
; which cell took the + 3, never the sum.
; A POINTER IS AN INTEGER (rule 21). a, b and slot are bus-resident (rule 20 (b)): the addresses of a and b are
; stored as VALUES (not a store through them) and slot is indexed by a rail, so each alloca is one __cq_alloc block at
; its program point and the lifetime markers are dropped (rule 16). Every store is a bus store and every load a bus
; load. &a and &b enter their cells as i64 seed rails holding the run-time address (rule 7). The load at the address
; rail &slot[k & 1] (the getelementptr spelled as zext, mul by 8, add of slot's run-time address) is qram_load_i64:
; its result is ONE 64-bit rail, the pointer p, and it is the address operand of the next access as it stands: no
; object, no tag, no guard. *p = v is the plain qram_store_i32 at that rail: a kept store, and the rail p, a load
; copy, is overtaken by it: un-copied after it and not freed (rule 5, sentences 1 and 3). **pp += 3 is load ptr; load i32; add; store i32
; through the same SSA pointer %20 with no memory version change between: the in-place form (rules 5, 6) at the
; address rail *pp, emitted at the store's position: the cell is swapped out into a fresh rail, updated there with
; rule 6's clean of the previous rail, and swapped back; no copy of the cell, tape slot or old value remains. The
; rail *pp is a load copy and the form is a memory version change: un-copied after the second swap, not freed. Nothing in the lowering asks
; whether p and *pp are equal, or which of a and b either addresses.
source_filename = "bus_pointer_cell.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @bus_pointer_cell(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: the bus M (called once, at function entry)
  %7 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %6 = alloca i32, align 4: a is bus-resident (its address is stored as a value)
  %8 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %7 = alloca i32, align 4: b is bus-resident
  %9 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %8 = alloca [2 x ptr], align 16: slot is bus-resident (indexed by a rail)
  %10 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %10, double %1)    ; IR: %9 = cq_theta_ui32(%0, %1)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %10 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %3)    ; IR: %10 = cq_theta_si32(%2, %3)  [Ry]
  %12 = ptrtoint ptr %7 to i64    ; IR: the run-time address of a (classical)
  %13 = call i32 @cqrt_alloc_i32(i32 1)    ; IR: store i32 1, ptr %6: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %12, i32 %13)    ; IR: store i32 1, ptr %6: a = 1  (kept store, classical address)
  %14 = ptrtoint ptr %8 to i64    ; IR: the run-time address of b (classical)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %14, i32 %11)    ; IR: store i32 %10, ptr %7: b = x  (kept store; the value rail is the register x)
  %15 = ptrtoint ptr %9 to i64    ; IR: the run-time address of slot (classical)
  %16 = call i32 @cqrt_alloc_i64(i64 %12)    ; IR: store ptr %6, ptr %8: the pointer &a is its address, an i64 seed (rules 7, 21; kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %15, i32 %16)    ; IR: store ptr %6, ptr %8: slot[0] = &a  (kept store of an i64 cell value)
  %17 = getelementptr inbounds i8, ptr %9, i64 8    ; IR: %11 = getelementptr inbounds i8, ptr %8, i64 8  (classical)
  %18 = ptrtoint ptr %17 to i64    ; IR: the run-time address of slot[1] (classical)
  %19 = call i32 @cqrt_alloc_i64(i64 %14)    ; IR: store ptr %7, ptr %11: the pointer &b, an i64 seed (kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %6, i64 %18, i32 %19)    ; IR: store ptr %7, ptr %11: slot[1] = &b  (kept store)
  %20 = call i32 @cq_template_and_i32_hl(i32 %10, i32 1)    ; IR: %12 = and i32 %9, 1
  %21 = call i32 @cq_template_zext_i32_to_i64(i32 %20)    ; IR: %13 = zext nneg i32 %12 to i64
  %22 = call i32 @cq_template_mul_i64_hl(i32 %21, i64 8)    ; IR: %14 = getelementptr [2 x ptr], ptr %8, i64 0, i64 %13: the index scaled by the element size
  %23 = call i32 @cq_template_add_i64_hl(i32 %22, i64 %15)    ; IR: %14: plus slot's run-time address  [address rail &slot[k & 1]]
  %24 = call i32 @cqrt_qram_load_i64(i32 %6, i32 %23)    ; IR: %15 = load ptr, ptr %14: p, a 64-bit rail holding an address (rule 21)
  %25 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: store i32 %4, ptr %15: the value seed v (rule 7; kept with the store)
  call void @cqrt_qram_store_i32(i32 %6, i32 %24, i32 %25)    ; IR: store i32 %4, ptr %15: *p = v  (kept store at the address rail p; p, a load copy, is overtaken: un-copied after it, not freed)
  call void @cqrt_qram_load_i64_unc(i32 %24, i32 %6, i32 %23)    ; IR: un-copy %15 (p) after its last reader, the store; overtaken by it, so not freed (rule 5 sentences 1 and 3)
  call void @cq_template_add_i64_hl_unc(i32 %23, i32 %22, i64 %15)    ; IR: uncompute %14 after the un-copy of p, its last reader (rule 5 sentence 1)
  call void @cqrt_free(i32 %23)    ; IR: release the %14 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %22, i32 %21, i64 8)    ; IR: uncompute the scaled index
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %21, i32 %20)    ; IR: uncompute %13
  call void @cqrt_free(i32 %21)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %20, i32 %10, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %20)    ; IR: release the %12 rail (|0>)
  %26 = call i32 @cq_template_lshr_i32_hl(i32 %10, i32 1)    ; IR: %16 = lshr i32 %9, 1
  %27 = call i32 @cq_template_and_i32_hl(i32 %26, i32 1)    ; IR: %17 = and i32 %16, 1
  %28 = call i32 @cq_template_zext_i32_to_i64(i32 %27)    ; IR: %18 = zext nneg i32 %17 to i64
  %29 = call i32 @cq_template_mul_i64_hl(i32 %28, i64 8)    ; IR: %19 = getelementptr [2 x ptr], ptr %8, i64 0, i64 %18: the index scaled by the element size
  %30 = call i32 @cq_template_add_i64_hl(i32 %29, i64 %15)    ; IR: %19: plus slot's run-time address  [address rail pp = &slot[(k >> 1) & 1]]
  %31 = call i32 @cqrt_qram_load_i64(i32 %6, i32 %30)    ; IR: %20 = load ptr, ptr %19: *pp, a 64-bit address rail
  %32 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %21 = load i32, ptr %20 ... store i32 %22, ptr %20: the in-place form (rule 5), a fresh |0> rail
  call void @cqrt_qram_swap_i32(i32 %6, i32 %31, i32 %32)    ; IR: %21 = load i32, ptr %20: swap out: the rail holds **pp, the cell |0>
  %33 = call i32 @cq_template_add_i32_hl(i32 %32, i32 3)    ; IR: %22 = add nsw i32 %21, 3
  %34 = call i32 @cq_template_sub_i32_hl(i32 %33, i32 3)    ; IR: rule 6: t = y' - 3 recomputes the old value (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %34, i32 %32)    ; IR: rule 6: the old rail ^= t: now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %34, i32 %33, i32 3)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %34)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %32)    ; IR: release the old rail (|0> after the copy)
  call void @cqrt_qram_swap_i32(i32 %6, i32 %31, i32 %33)    ; IR: store i32 %22, ptr %20: swap in: the cell holds **pp + 3, the rail |0>
  call void @cqrt_free(i32 %33)    ; IR: release the %22 rail (|0>)
  call void @cqrt_qram_load_i64_unc(i32 %31, i32 %6, i32 %30)    ; IR: un-copy %20 (*pp) after its last reader, the second swap; the form overtook it, so not freed (rule 5 sentence 1)
  call void @cq_template_add_i64_hl_unc(i32 %30, i32 %29, i64 %15)    ; IR: uncompute %19 after the un-copy of *pp, its last reader
  call void @cqrt_free(i32 %30)    ; IR: release the %19 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %29, i32 %28, i64 8)    ; IR: uncompute the scaled index
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %28, i32 %27)    ; IR: uncompute %18
  call void @cqrt_free(i32 %28)    ; IR: release the %18 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %27, i32 %26, i32 1)    ; IR: uncompute %17
  call void @cqrt_free(i32 %27)    ; IR: release the %17 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %26, i32 %10, i32 1)    ; IR: uncompute %16
  call void @cqrt_free(i32 %26)    ; IR: release the %16 rail (|0>)
  %35 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %12)    ; IR: %23 = load i32, ptr %6: a  (bus load at a classical address: a rail)
  %36 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %14)    ; IR: %24 = load i32, ptr %7: b
  %37 = call i32 @cq_template_add_i32(i32 %36, i32 %35)    ; IR: %25 = add nsw i32 %24, %23  [result rail]  ; SPEC GAP: rule 6 'both operands dead' does not say that two bus load copies are 'garbage that rule 5 uncomputes anyway'; taken as such (as 195), so rule 6 has no trigger
  call void @cqrt_qram_load_i32_hl_unc(i32 %36, i32 %6, i64 %14)    ; IR: un-copy %24 (no memory version change since the load)  ; SPEC GAP: sentence 1 asks for the consumer's uncompute; the consumer %25 is measured and has none (as 195): un-copied before the measurement
  call void @cqrt_free(i32 %36)    ; IR: release the %24 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %35, i32 %6, i64 %12)    ; IR: un-copy %23  ; SPEC GAP: as at %24
  call void @cqrt_free(i32 %35)    ; IR: release the %23 rail (|0>)
  %38 = call i32 @cqrt_measure_i32(i32 %37)    ; IR: %26 = cq_measure_si32(%25)
  ret i32 %38    ; IR: ret i32 %26
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i64(i32, i32)
declare void @cqrt_qram_load_i64_unc(i32, i32, i32)
declare void @cqrt_qram_swap_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
