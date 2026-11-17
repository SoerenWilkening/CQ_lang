; HAND-WRITTEN. Rules: 20, 21, 16, 5, 6, 4, 2.
; Checked: a[0] ^ a[1] ^ a[2] ^ a[3] after a[x & 3] += y over a = {y, y+1, y+2, y+3} (measured, %29 -> %30); the cells
; of a on the bus at exit: a[i] = (i == (x & 3)) ? 2y + i : y + i, mod 2^32.
; Clean: the address chain of a[x & 3] (x & 3 %16, its zext %17, the scaled index %18, the address rail %19),
; uncomputed after the second swap of the in-place form; the in-place form's rails (the swapped-out old a[x & 3] %20,
; cleaned by rule 6 through the inverse t = sum - y %22; the sum rail %21, |0> after the swap-in); the four
; fixed-address load copies (%23, %24, %26, %28, un-copied: no memory version change follows them) and the two inner
; xors (%25, %27).
; Kept: the user registers x and y (%8, %9; y is also the value rail of the kept store a[0] = y). Rule 5 sentence 3:
; the tape slots of the four initializer stores and their value rails y + 1, y + 2, y + 3 (%11, %13, %15). The result
; rail (%29, measured).
; Rotations: (Ry, x, tx, 1); (Ry, y, ty, 1).
; ONE BUS (rule 20): the alloca is BUS-RESIDENT (a tainted value is stored through it and a getelementptr with a
; tainted index reaches it), so no alloca remains: its block is __cq_alloc(16, 16) at the alloca's program point (rule
; 16) and both lifetime markers are dropped. m = __cq_mem() is called once, at entry. Nothing is known about an address
; at compile time: the base is the block's run-time address, a classical i64 (ptrtoint), and the constant-offset geps
; are classical i64 adds. The initializer is four kept i32 stores at classical addresses (qram_store_i32_hl): no _unc
; exists, the tape slots stay, and so do the value rails (y, and the template results y + 1, y + 2, y + 3, which are
; therefore no longer uncomputed).
; THE READ-MODIFY-WRITE (rules 5 and 6, "a memory cell"): `a[x & 3] += y` is load %16, add, store %16 on the same SSA
; pointer with no memory version change between them, and the add is a rule-6 bijection in the loaded value, so it is
; the in-place form at the address rail: the gep with the tainted index is 64-bit template arithmetic (-O1's zext,
; mul_i64_hl by 4, add_i64_hl of the run-time base), then at the store's position a |0> rail is swapped with the four
; cells (qram_swap_i32), the sum is computed into a fresh rail, the old value is cleaned by rule 6 (t = sum - y,
; copy, un-t), the sum rail is swapped into the cells, and the rail that receives the cells' |0> is freed. No copy, no
; tape slot and no old value remains. The address rail is template garbage, uncomputed after the second swap.
; THE FIXED-ADDRESS LOADS: four qram_load_i32_hl at the classical addresses of a[0..3], copy-outs into fresh rails;
; the xors go into fresh rails. No memory version change follows the loads, so each copy is un-copied (its _unc, same
; arguments) after its last reader and that reader's uncompute where it has one (a[3]'s reader is the measured result,
; which has none), before the measurement: the inner xors first, then the
; copies of a[3], a[2], a[1], a[0]. The end of a's lifetime undoes nothing (rule 20).
source_filename = "quantum_cells_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @quantum_cells_rmw(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (no instruction) the bus m, once at function entry
  %6 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %5 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address (classical, rule 21)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %2)    ; IR: %6 = cq_theta_ui32(%0, %2)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %7 = cq_theta_ui32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %7 = cq_theta_ui32(%1, %3)  [Ry]
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %7, i32 %9)    ; IR: llvm.lifetime.start dropped (rule 16); store i32 %7, ptr %5: a[0] = y  (a kept store at a classical address: tape slot and value rail y stay)
  %10 = add i64 %7, 4    ; IR: %8 = getelementptr inbounds i8, ptr %5, i64 4  (classical: &a[1])
  %11 = call i32 @cq_template_add_i32_hl(i32 %9, i32 1)    ; IR: %9 = add i32 %7, 1
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %10, i32 %11)    ; IR: store i32 %9, ptr %8: a[1] = y + 1  (kept store: tape slot and value rail %9 stay)
  %12 = add i64 %7, 8    ; IR: %10 = getelementptr inbounds i8, ptr %5, i64 8  (classical: &a[2])
  %13 = call i32 @cq_template_add_i32_hl(i32 %9, i32 2)    ; IR: %11 = add i32 %7, 2
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %12, i32 %13)    ; IR: store i32 %11, ptr %10: a[2] = y + 2  (kept store: tape slot and value rail %11 stay)
  %14 = add i64 %7, 12    ; IR: %12 = getelementptr inbounds i8, ptr %5, i64 12  (classical: &a[3])
  %15 = call i32 @cq_template_add_i32_hl(i32 %9, i32 3)    ; IR: %13 = add i32 %7, 3
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %14, i32 %15)    ; IR: store i32 %13, ptr %12: a[3] = y + 3  (kept store: tape slot and value rail %13 stay)
  %16 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %14 = and i32 %6, 3
  %17 = call i32 @cq_template_zext_i32_to_i64(i32 %16)    ; IR: %15 = zext nneg i32 %14 to i64
  %18 = call i32 @cq_template_mul_i64_hl(i32 %17, i64 4)    ; IR: %16 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %15  [the tainted index scaled by sizeof(i32) (rule 20)]
  %19 = call i32 @cq_template_add_i64_hl(i32 %18, i64 %7)    ; IR: %16 = getelementptr  [+ the run-time base: the address rail of &a[x & 3]]
  %20 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %17 = load i32, ptr %16: in-place form (rules 5, 6), the swap rail (|0>)
  call void @cqrt_qram_swap_i32(i32 %5, i32 %19, i32 %20)    ; IR: %17 = load i32, ptr %16: swap-out at the address rail: the rail holds old a[x & 3], the cells |0>
  %21 = call i32 @cq_template_add_i32(i32 %20, i32 %9)    ; IR: %18 = add i32 %17, %7  [sum, a fresh rail]
  %22 = call i32 @cq_template_sub_i32(i32 %21, i32 %9)    ; IR: rule 6: t = sum - y recomputes the old value
  call void @cqrt_copy_i32(i32 %22, i32 %20)    ; IR: rule 6: the old rail ^= t: |0>
  call void @cq_template_sub_i32_unc(i32 %22, i32 %21, i32 %9)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %22)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %20)    ; IR: release the old-value rail (|0> after the copy)
  call void @cqrt_qram_swap_i32(i32 %5, i32 %19, i32 %21)    ; IR: store i32 %18, ptr %16: swap-in: the cells hold the sum, the rail the cells' |0>
  call void @cqrt_free(i32 %21)    ; IR: release the rail (|0>): nothing remains of the update
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %18, i64 %7)    ; IR: uncompute %16  [the address rail, after the second swap (rule 20)]
  call void @cqrt_free(i32 %19)    ; IR: release the %16 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %18, i32 %17, i64 4)    ; IR: uncompute %16 (the scaled index)
  call void @cqrt_free(i32 %18)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %17, i32 %16)    ; IR: uncompute %15
  call void @cqrt_free(i32 %17)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %16, i32 %8, i32 3)    ; IR: uncompute %14
  call void @cqrt_free(i32 %16)    ; IR: release the %14 rail (|0>)
  %23 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %7)    ; IR: %19 = load i32, ptr %5: a[0]  (a classical address: copy-out into a fresh rail)
  %24 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %10)    ; IR: %20 = load i32, ptr %8: a[1]
  %25 = call i32 @cq_template_xor_i32(i32 %24, i32 %23)    ; IR: %21 = xor i32 %20, %19
  %26 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %12)    ; IR: %22 = load i32, ptr %10: a[2]
  %27 = call i32 @cq_template_xor_i32(i32 %25, i32 %26)    ; IR: %23 = xor i32 %21, %22
  %28 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %14)    ; IR: %24 = load i32, ptr %12: a[3]
  %29 = call i32 @cq_template_xor_i32(i32 %27, i32 %28)    ; IR: %25 = xor i32 %23, %24  [result rail]
  call void @cq_template_xor_i32_unc(i32 %27, i32 %25, i32 %26)    ; IR: uncompute %23
  call void @cqrt_free(i32 %27)    ; IR: release the %23 rail (|0>)
  call void @cq_template_xor_i32_unc(i32 %25, i32 %24, i32 %23)    ; IR: uncompute %21
  call void @cqrt_free(i32 %25)    ; IR: release the %21 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %28, i32 %5, i64 %14)    ; IR: un-copy %24 (a[3]; rule 5 sentence 1: its only consumer %25 is measured, so there is no _unc to wait for; no memory version change follows the load, so it is un-copied before the measurement)
  call void @cqrt_free(i32 %28)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %26, i32 %5, i64 %12)    ; IR: un-copy %22 (a[2])
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %24, i32 %5, i64 %10)    ; IR: un-copy %20 (a[1])
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %23, i32 %5, i64 %7)    ; IR: un-copy %19 (a[0])
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  %30 = call i32 @cqrt_measure_i32(i32 %29)    ; IR: %26 = cq_measure_ui32(%25)
  ret i32 %30    ; IR: llvm.lifetime.end dropped (rule 16); ret i32 %26
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_xor_i32(i32, i32)
declare void @cq_template_xor_i32_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
