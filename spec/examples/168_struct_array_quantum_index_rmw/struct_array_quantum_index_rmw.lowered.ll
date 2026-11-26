; HAND-WRITTEN. Rules: 20, 22, 21, 26, 16, 5, 6, 4, 3, 2; §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: arr[(i + 2) & 3].v + arr[(i + 1) & 3].w (measured, %38 -> %39); the cells of arr at exit, read from the bus at
; the block's address: arr[i & 3].v = v0[i & 3] + c, arr[(i + 1) & 3].w = that sum, every other field its initializer.
; Clean: the swap rail of the in-place form (%25, updated in place by rule 6; |0> after the swap-in, then freed), every
; address chain (and / zext / mul / add: %21..%24, %27..%30 and %32, %33..%36; %31 is the classical base + 4), each address rail uncomputed and freed right after its last access (idx1 %21 only after idx3's
; _unc, which reads it), and the load copy %37 (un-copied after the add: no memory version change lies between).
; Kept: the register i (%20, rotated); the 32 byte load copies of the initializer (%10 per trip), each the value rail of
; a kept byte store (rule 5, sentences 1 and 3; classical-valued, so no qubit, §0); the tape slots of the 32 byte stores
; and of the w store (backend rails, rule 5); the load copy %26 of arr[i & 3].v after the in-place form (the value rail
; of the kept w store, rule 5 sentence 3); the result %38 (measured).
; Rotations: (Ry, i, ti, 1).
; Expected: struct_array_quantum_index_rmw(0, .5, 10). Ry(.5) flips each of the 32 bits of i = 0 with s = sin^2(.25) =
; 0.061209, and everything after it is a basis permutation. With v = {1, 3, 5, 7} the result is v[k ^ 2] + v[k] + 10
; for k = i & 3: 16 at k = 0, 2 and 20 at k = 1, 3, so it reads only bit 0 of i: P(16) = 0.938791, P(20) = 0.061209.
; ONE BUS (rule 20): the alloca is BUS-RESIDENT (getelementptrs with a tainted index are among its users), so no alloca
; remains: its block is __cq_alloc(32, 16) at the alloca's program point (rule 16) and the lifetime markers are dropped.
; m = __cq_mem() is called once, at entry (§5). An array of structs in memory is bus memory at its address like any
; object (rule 26): nothing about the struct type is used beyond the getelementptr's offsets, and no column or per-field
; object exists. Each getelementptr with a tainted index is 64-bit template arithmetic into an address rail (rule 20):
; the index rail (-O1's zext to i64), mul_i64_hl by the element size 8 (sizeof(struct cell)), add_i64_hl of the
; classical part (the block's run-time address, plus 4 for field w: one classical i64). Every access is ONE i32 bus
; access at its address rail; no index is narrowed, bounded or checked.
; THE INITIALIZER (rule 22): llvm.memcpy of 32 bytes into the bus-resident block is a byte copy on the bus: a host loop
; of 32 qram_load_i8_hl at the constant global's host address (HOST cells, classical-valued copies), each handle pushed,
; then a host loop of 32 qram_store_i8_hl at the block popping them (bytes 31 down to 0), never widened into word
; accesses. Every value, address and control is classical-valued, so the stores write the host bytes and the cells stay
; HOST until the in-place form and the w store at address rails make the cells they can reach QUANTUM (§1.3).
; `arr[i & 3].v += c` is load, add, store on the SAME SSA pointer %8 with nothing between: rule 5's IN-PLACE FORM at an
; address rail (rule 6, "a memory cell"): swap-out into a fresh |0> rail, y' = y + c as rule 6's in-place update on
; that rail (addc_i32: the old value is dead after the add), swap-in of y', free of the rail that now holds |0>. No copy, tape slot or old value remains.
; Its result %10 has two later readers, the store into arr[(i + 1) & 3].w (-O1 forwarded the re-read of arr[i & 3].v)
; and the final add: both read ONE plain load of %8 taken right after the swap-in (rule 5, Readers). That copy is the
; value rail of the w store, a KEPT store at its address rail (rule 5 sentence 3), so it is kept and never un-copied.
; The final load at the third address rail is un-copied right after the add (its only reader, measured: no _unc to
; wait for) and before the measurement; no memory version change lies between. idx1 = i & 3 outlives idx3 = idx1 ^ 2.
source_filename = "struct_array_quantum_index_rmw.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.cell = type { i32, i32 }

@__const.struct_array_quantum_index_rmw.arr = private unnamed_addr constant [4 x %struct.cell] [%struct.cell { i32 1, i32 2 }, %struct.cell { i32 3, i32 4 }, %struct.cell { i32 5, i32 6 }, %struct.cell { i32 7, i32 8 }], align 16

define i32 @struct_array_quantum_index_rmw(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 32, i64 16)    ; IR: %4 = alloca [4 x %struct.cell], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; the block's run-time address, a classical i64 (rule 21)
  br label %7    ; IR: llvm.lifetime.start(32, %4) dropped (rule 16); llvm.memcpy(%4, @__const.struct_array_quantum_index_rmw.arr, 32)  [rule 22: load all 32 source bytes, then store all 32]

7:
  %8 = phi i64 [ 0, %3 ], [ %11, %7 ]    ; byte index of the load loop (classical)
  %9 = add i64 ptrtoint (ptr @__const.struct_array_quantum_index_rmw.arr to i64), %8    ; the source byte's host address (classical)
  %10 = call i32 @cqrt_qram_load_i8_hl(i32 %4, i64 %9)    ; IR: llvm.memcpy  [source byte: a bus load of a HOST cell; the copy is the value rail of that byte's store, KEPT (rule 5)]
  call void @cqrt_push(i32 %10)    ; IR: llvm.memcpy  [the handle crosses to the store loop on the word stack (rule 22)]
  %11 = add nuw nsw i64 %8, 1
  %12 = icmp eq i64 %11, 32
  br i1 %12, label %13, label %7

13:
  %14 = phi i64 [ 32, %7 ], [ %15, %13 ]    ; bytes left to store (classical)
  %15 = add nsw i64 %14, -1    ; byte index of this store: 31 down to 0 (the pop order)
  %16 = call i32 @cqrt_pop()    ; the load copy of byte %15
  %17 = add i64 %6, %15    ; the destination byte's address (classical)
  call void @cqrt_qram_store_i8_hl(i32 %4, i64 %17, i32 %16)    ; IR: llvm.memcpy  [destination byte: a kept store (rule 5); classical-valued, the cell stays HOST]
  %18 = icmp eq i64 %15, 0
  br i1 %18, label %19, label %13

19:
  %20 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register i]
  call void @cqrt_ry_i32(i32 %20, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %21 = call i32 @cq_template_and_i32_hl(i32 %20, i32 3)    ; IR: %6 = and i32 %5, 3  [idx1]
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %21)    ; IR: %7 = zext nneg i32 %6 to i64
  %23 = call i32 @cq_template_mul_i64_hl(i32 %22, i64 8)    ; IR: %8 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %7  [the tainted index scaled by the element size 8 (rule 20)]
  %24 = call i32 @cq_template_add_i64_hl(i32 %23, i64 %6)    ; IR: %8 = getelementptr  [+ the run-time base (field v: offset 0): the address rail of &arr[i & 3].v]
  %25 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %9 = load i32, ptr %8: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32(i32 %4, i32 %24, i32 %25)    ; IR: %9 = load i32, ptr %8: swap-out: the rail holds arr[idx1].v, the cell |0>
  call void @cqrt_addc_i32(i32 %25, i32 %2)    ; IR: %10 = add nsw i32 %9, %2  [rule 6, in-place update: the old arr[idx1].v is dead after the add, so y' IS the swap rail]
  call void @cqrt_qram_swap_i32(i32 %4, i32 %24, i32 %25)    ; IR: store i32 %10, ptr %8: swap-in: the cell holds arr[idx1].v + c, the rail the cell's |0>
  call void @cqrt_free(i32 %25)    ; IR: release the swap rail (|0>): nothing remains of the update
  %26 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %24)    ; IR: the readers of %10 (store at %14, add %19): a plain load of %8 taken after the swap-in (rule 5, Readers); the value rail of the kept w store, KEPT  ; SPEC GAP: rule 5 (Readers) does not say whether several later readers of y' share one load after the swap-in or each take their own; one load, right after the swap-in, serves both (no memory version change lies between)
  call void @cq_template_add_i64_hl_unc(i32 %24, i32 %23, i64 %6)    ; IR: uncompute %8  [the address rail's last access was the load %28, which is kept (rule 20)]
  call void @cqrt_free(i32 %24)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %23, i32 %22, i64 8)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %23)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %21)    ; IR: uncompute %7
  call void @cqrt_free(i32 %22)    ; IR: release the %7 rail (|0>)
  %27 = call i32 @cq_template_add_i32_hl(i32 %20, i32 1)    ; IR: %11 = add i32 %5, 1
  %28 = call i32 @cq_template_and_i32_hl(i32 %27, i32 3)    ; IR: %12 = and i32 %11, 3  [idx2]
  %29 = call i32 @cq_template_zext_i32_to_i64(i32 %28)    ; IR: %13 = zext nneg i32 %12 to i64
  %30 = call i32 @cq_template_mul_i64_hl(i32 %29, i64 8)    ; IR: %14 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %13, i32 1  [the tainted index scaled by 8]
  %31 = add i64 %6, 4    ; IR: %14 = getelementptr  [the untainted part: the run-time base + 4 (field w), one classical i64]
  %32 = call i32 @cq_template_add_i64_hl(i32 %30, i64 %31)    ; IR: %14 = getelementptr  [the address rail of &arr[(i + 1) & 3].w]
  call void @cqrt_qram_store_i32(i32 %4, i32 %32, i32 %26)    ; IR: store i32 %10, ptr %14  [a kept store at an address rail: its tape slot and its value rail %28 stay (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %32, i32 %30, i64 %31)    ; IR: uncompute %14  [the address rail follows its producer (rule 5)]
  call void @cqrt_free(i32 %32)    ; IR: release the %14 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %30, i32 %29, i64 8)    ; IR: uncompute %14 (the scaled index)
  call void @cqrt_free(i32 %30)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %29, i32 %28)    ; IR: uncompute %13
  call void @cqrt_free(i32 %29)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %28, i32 %27, i32 3)    ; IR: uncompute idx2 (%12)
  call void @cqrt_free(i32 %28)    ; IR: release the %12 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %27, i32 %20, i32 1)    ; IR: uncompute %11
  call void @cqrt_free(i32 %27)    ; IR: release the %11 rail (|0>)
  %33 = call i32 @cq_template_xor_i32_hl(i32 %21, i32 2)    ; IR: %15 = xor i32 %6, 2  [idx3 = (i + 2) & 3]
  %34 = call i32 @cq_template_zext_i32_to_i64(i32 %33)    ; IR: %16 = zext nneg i32 %15 to i64
  %35 = call i32 @cq_template_mul_i64_hl(i32 %34, i64 8)    ; IR: %17 = getelementptr inbounds [4 x %struct.cell], ptr %4, i64 0, i64 %16  [the tainted index scaled by 8]
  %36 = call i32 @cq_template_add_i64_hl(i32 %35, i64 %6)    ; IR: %17 = getelementptr  [+ the run-time base (field v): the address rail of &arr[(i + 2) & 3].v]
  %37 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %36)    ; IR: %18 = load i32, ptr %17  [a fresh copy of the 4 cells]
  %38 = call i32 @cq_template_add_i32(i32 %37, i32 %26)    ; IR: %19 = add nsw i32 %18, %10  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %37, i32 %4, i32 %36)    ; IR: un-copy %18 (rule 5 sentence 1: no memory version change since the load)
  call void @cqrt_free(i32 %37)    ; IR: release the %18 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %36, i32 %35, i64 %6)    ; IR: uncompute %17  [the address rail outlives its access's _unc (rule 20)]
  call void @cqrt_free(i32 %36)    ; IR: release the %17 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %35, i32 %34, i64 8)    ; IR: uncompute %17 (the scaled index)
  call void @cqrt_free(i32 %35)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %34, i32 %33)    ; IR: uncompute %16
  call void @cqrt_free(i32 %34)    ; IR: release the %16 rail (|0>)
  call void @cq_template_xor_i32_hl_unc(i32 %33, i32 %21, i32 2)    ; IR: uncompute idx3 (%15)
  call void @cqrt_free(i32 %33)    ; IR: release the %15 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %20, i32 3)    ; IR: uncompute idx1 (%6)
  call void @cqrt_free(i32 %21)    ; IR: release the %6 rail (|0>)
  %39 = call i32 @cqrt_measure_i32(i32 %38)    ; IR: %20 = cq_measure_si32(%19)
  ret i32 %39    ; IR: llvm.lifetime.end(32, %4) dropped (rule 16); ret i32 %20
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i32(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare void @cqrt_addc_i32(i32, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cq_template_xor_i32_hl(i32, i32)
declare void @cq_template_xor_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
