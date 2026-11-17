; HAND-WRITTEN. Rules: 20, 22, 21, 16, 5, 4, 2.
; Checked: r = a[j & 3] (measured, %34 -> %35); the cells of a at exit, read from the bus at the block's address:
; a[i] = (i == (k & 3)) ? x : i + 1.
; Clean: the two address chains, each and / zext / mul / add (%26..%29 for the store, %30..%33 for the load),
; uncomputed and freed right after their access.
; Kept: k, j, x (%10, %11, %12, the rotated registers; x is also the value rail of the kept store, rule 5); the 16
; byte load copies of the initializer (%16 per trip), each the value rail of a kept byte store (rule 5, sentences 1
; and 3; classical-valued, so no qubit, §0); the tape slots of the 16 byte stores and of the i32 store (backend
; rails, rule 5); the load copy r (%34, measured, rule 2).
; Rotations: (Ry, k, tk, 1); (Ry, j, tj, 1); (Ry, x, tx, 1).
; Expected: bus_quantum_address(1, .5, 2, .25, 9, .75). Each Ry acts on all 32 qubits of its register and everything
; after the three rotations is a basis permutation, so r is distributed as the C program on independent bit flips:
; a bit of k flips with p = sin^2(.25) = 0.061209, of j with q = sin^2(.125) = 0.015544, of x with s = sin^2(.375) =
; 0.134156. k & 3 = 0, 1, 2, 3 with 0.057462, 0.881329, 0.003747, 0.057462; j & 3 = 0, 1, 2, 3 with 0.015302,
; 0.000242, 0.969154, 0.015302. The two indices meet with probability 0.005602 and r is then x = 9 ^ e, each e with
; s^|e| (1 - s)^(32 - |e|) (x = 9: 0.009956); otherwise r = (j & 3) + 1. In total P(r = 3) = 0.965524, P(r = 1) =
; 0.014432, P(r = 4) = 0.014423, P(r = 2) = 0.000029, P(r = 9) = 0.000056, and 0.005536 over the other values of x.
; ONE BUS (rule 20): the alloca is BUS-RESIDENT, because a getelementptr with a tainted index is among its users, so
; no alloca remains: its block is __cq_alloc(16, 16) at the alloca's program point (rule 16) and the lifetime markers
; are dropped. m = __cq_mem() is called once, at entry (§5). Nothing is known about an address at compile time: the
; base is the block's run-time address as a classical i64, and each getelementptr with a tainted index is 64-bit
; template arithmetic into an address rail: the index rail (-O1's zext to i64), mul_i64_hl by the element size 4,
; add_i64_hl of the classical part (the base; the constant indices contribute 0). The store is ONE qram_store_i32 at
; the address rail and the load ONE qram_load_i32 at the other; no index is narrowed, bounded or checked. The store is
; kept (no _unc, its tape slot and its value rail x stay); its address rail is template garbage, uncomputed after the
; store. The load copy is measured, so it is never un-copied; its address rail is uncomputed after the load.
; THE INITIALIZER (rule 22): llvm.memcpy of 16 bytes into a bus-resident destination is a byte copy on the bus, a
; host loop of 16 qram_load_i8_hl at the source address and then a host loop of 16 qram_store_i8_hl at the block,
; never widened into word accesses. The source is the constant global at its host address (HOST cells through the
; overlay, nothing seeded); every value, address and control is classical-valued, so the stores write the host bytes
; and the cells of a stay HOST until the store at the address rail makes the cells it can reach QUANTUM (§1.3). A
; handle is never stored in program memory (§1.1), so the load loop pushes its 16 handles and the store loop pops
; them: the stores run from byte 15 down to byte 0 (a copy has no direction).
source_filename = "bus_quantum_address.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.bus_quantum_address.a = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

define i32 @bus_quantum_address(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4, double noundef %5) {
  %7 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %8 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %9 = ptrtoint ptr %8 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %10 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %10, double %1)    ; IR: %8 = cq_theta_ui32(%0, %1)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %9 = cq_theta_ui32(%2, %3)  [register j]
  call void @cqrt_ry_i32(i32 %11, double %3)    ; IR: %9 = cq_theta_ui32(%2, %3)  [Ry]
  %12 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: %10 = cq_theta_si32(%4, %5)  [register x]
  call void @cqrt_ry_i32(i32 %12, double %5)    ; IR: %10 = cq_theta_si32(%4, %5)  [Ry]
  br label %13    ; IR: llvm.lifetime.start(16, %7) dropped (rule 16); llvm.memcpy(%7, @__const.bus_quantum_address.a, 16)  [rule 22: load all 16 source bytes, then store all 16]

13:
  %14 = phi i64 [ 0, %6 ], [ %17, %13 ]    ; byte index of the load loop (classical)
  %15 = add i64 ptrtoint (ptr @__const.bus_quantum_address.a to i64), %14    ; the source byte's host address (classical)
  %16 = call i32 @cqrt_qram_load_i8_hl(i32 %7, i64 %15)    ; IR: llvm.memcpy  [source byte i: a bus load of a HOST cell; the copy is the value rail of byte i's store, KEPT (rule 5)]  ; SPEC GAP: the source is a host-resident constant; rule 22's bus load is taken, not rule 20's plain classical load
  call void @cqrt_push(i32 %16)    ; the handle outlives its SSA value (§1.1)  ; SPEC GAP: rule 22 names no carrier between its two loops; cqrt_push is the only one §1.1 allows
  %17 = add nuw nsw i64 %14, 1
  %18 = icmp eq i64 %17, 16
  br i1 %18, label %19, label %13

19:
  %20 = phi i64 [ 16, %13 ], [ %21, %19 ]    ; bytes left to store (classical)
  %21 = add nsw i64 %20, -1    ; byte index of this store: 15 down to 0 (the pop order)
  %22 = call i32 @cqrt_pop()    ; the load copy of byte %21
  %23 = add i64 %9, %21    ; the destination byte's address (classical)
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %23, i32 %22)    ; IR: llvm.memcpy  [destination byte: a kept store (rule 5); classical-valued, the cell stays HOST]  ; SPEC GAP: rule 22 does not say what becomes of the load copy; it is the store's value rail, so never un-copied, never freed (rule 5)
  %24 = icmp eq i64 %21, 0
  br i1 %24, label %25, label %19

25:
  %26 = call i32 @cq_template_and_i32_hl(i32 %10, i32 3)    ; IR: %11 = and i32 %8, 3
  %27 = call i32 @cq_template_zext_i32_to_i64(i32 %26)    ; IR: %12 = zext nneg i32 %11 to i64
  %28 = call i32 @cq_template_mul_i64_hl(i32 %27, i64 4)    ; IR: %13 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %12  [the tainted index scaled by the element size (rule 20)]
  %29 = call i32 @cq_template_add_i64_hl(i32 %28, i64 %9)    ; IR: %13 = getelementptr  [+ the classical part, the run-time base: the address rail of &a[k & 3]]
  call void @cqrt_qram_store_i32(i32 %7, i32 %29, i32 %12)    ; IR: store i32 %10, ptr %13, align 4  [a kept store at an address rail: its tape slot and its value rail x stay (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %29, i32 %28, i64 %9)    ; IR: uncompute %13  [the address rail follows its producer (rule 5)]
  call void @cqrt_free(i32 %29)    ; IR: release the %13 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %28, i32 %27, i64 4)    ; IR: uncompute %13 (the scaled index)
  call void @cqrt_free(i32 %28)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %27, i32 %26)    ; IR: uncompute %12
  call void @cqrt_free(i32 %27)    ; IR: release the %12 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %26, i32 %10, i32 3)    ; IR: uncompute %11
  call void @cqrt_free(i32 %26)    ; IR: release the %11 rail (|0>)
  %30 = call i32 @cq_template_and_i32_hl(i32 %11, i32 3)    ; IR: %14 = and i32 %9, 3
  %31 = call i32 @cq_template_zext_i32_to_i64(i32 %30)    ; IR: %15 = zext nneg i32 %14 to i64
  %32 = call i32 @cq_template_mul_i64_hl(i32 %31, i64 4)    ; IR: %16 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %15  [the tainted index scaled by the element size (rule 20)]
  %33 = call i32 @cq_template_add_i64_hl(i32 %32, i64 %9)    ; IR: %16 = getelementptr  [+ the run-time base: the address rail of &a[j & 3]]
  %34 = call i32 @cqrt_qram_load_i32(i32 %7, i32 %33)    ; IR: %17 = load i32, ptr %16, align 4  [a load at an address rail: fresh rail r ^= the 4 cells; measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_hl_unc(i32 %33, i32 %32, i64 %9)    ; IR: uncompute %16  [the address rail outlives its access (rule 20)]
  call void @cqrt_free(i32 %33)    ; IR: release the %16 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %32, i32 %31, i64 4)    ; IR: uncompute %16 (the scaled index)
  call void @cqrt_free(i32 %32)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %31, i32 %30)    ; IR: uncompute %15
  call void @cqrt_free(i32 %31)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %30, i32 %11, i32 3)    ; IR: uncompute %14
  call void @cqrt_free(i32 %30)    ; IR: release the %14 rail (|0>)
  %35 = call i32 @cqrt_measure_i32(i32 %34)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %35    ; IR: llvm.lifetime.end(16, %7) dropped (rule 16); ret i32 %18
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
