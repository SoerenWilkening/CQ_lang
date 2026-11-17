; HAND-WRITTEN. Rules: 2, 3, 4, 5, 6, 7, 16, 18, 19, 20, 21, 22; §1.3 (the bus, __cq_mem, __cq_alloc), §1.4.
; Checked: alias_params: a[0] after addto (the load copy, measured): 2 * a0 when x & 1 == 0 (q aliases p), a0 + a1 when
; x & 1 == 1; the cells of a at exit: a[0] = that value, a[1] = a1.
; qram_2d: g[1][2] + g[r & 3][0] (the add rail, measured): v * [r & 3 == 1 && c & 3 == 2] + v * [c & 3 == 0]; the cells
; of g at exit: g[r & 3][c & 3] = v, every other cell 0.
; Clean: alias_params: the address chain of q = &a[x & 1] (x & 1, its zext, the scaled index, the address rail),
; uncomputed by the caller after the call (the clone stored through p; rule 5 sentence 3) and freed; in the clone the
; three rails of the in-place form (the swap rail holding the old *p, the rule-6 inverse t, the updated rail after the
; swap-in). qram_2d: the address chain of the store &g[r & 3][c & 3] (both scaled indices, their sum, the address rail),
; uncomputed right after the store, then c & 3 and its zext; the two load copies g[1][2] and g[r & 3][0], un-copied
; after the add, before the measurement; the address chain of the load &g[r & 3] (the scaled row index, the address
; rail), uncomputed after that load's un-copy, then r & 3 and its zext.
; Kept: alias_params: x (rotated register), the load copy a[0] (measured), and by rule 5 for the shot: the tape slots of
; the two initializer stores with their seed value rails a0, a1. Left allocated, un-copied: in the clone the load copy
; of *q (un-copied after the swap-in; overtaken by the in-place form, a memory version change, so not freed: rule 5
; sentence 1). The in-place form itself keeps nothing. qram_2d: r, c (rotated registers),
; the sum (measured), and by rule 5: the 64 tape slots of the memset's byte stores with their one value seed (i8 0), the
; tape slot of the store g[r & 3][c & 3] = v with its seed value rail v.
; Rotations: alias_params: (Ry, x, tx, 1). qram_2d: (Ry, r, tr, 1); (Ry, c, tc, 1).
; ONE BUS (rules 20, 21). Every load is a bus load (a rail), every store a bus store, at the pointer's run-time i64 address
; (_hl) or at a 64-bit address rail; m = __cq_mem() once at the entry of every function that accesses the bus (§5).
; alias_params: the alloca a has a gep with a tainted index and a call among its users, so it is bus-resident (rule 20
; (b)): __cq_alloc(8, 4) at its program point, no alloca remains, the lifetime markers are dropped (rule 16). The
; initializer is two kept stores at the classical addresses a and a + 4, each of a seed (rule 7). q = a + (x & 1) is
; 64-bit template arithmetic (rule 20): zext (as -O1 wrote it), mul by the element size 4, add of the classical base
; address: ONE address rail (rule 21). A POINTER IS ONE SCALAR (§1.4): addto(p, q) passes the classical ptr a (digit 0)
; and the address rail q (digit 1): the clone __cq_q_addto_01(ptr, i32). Nothing about the pointee, no object, tag or
; cell index crosses the call, and nothing asks whether p and q are equal. In the clone `*p += *q` is load q, load p,
; add, store p on the same SSA pointer p with no memory version change between the load of p and the store: rule 5's
; IN-PLACE FORM at the classical address p, with the add (a rule-6 bijection in *p) as its one step. The load of *q a
; step reads is a plain bus load at its own program point, before the swap-out, so when q == p it copies the old *p and
; the update is 2 * a0, exactly C's result; that copy is overtaken by the form: un-copied after its last reader (rule
; 6's _unc of t), placed after the swap-in (no bus access inside the form), and not freed (rule 5 sentence 1; when
; q == p the un-copy reads the updated cell and the rail keeps garbage, no rule asks which). The form is emitted at the store's position: swap-out into a fresh |0> rail, y' = y + *q with rule 6's
; clean of the old rail (t = y' - *q), swap-in of y', free. addto writes memory, so the clone has NO TWIN (rule 18) and
; returns nothing; addto's own symbol has no caller left and is dropped (§1.4). The caller uncomputes the address rail
; it passed after the call (rule 5 sentence 3). The load of a[0] after the call (a memory version change) is a fresh
; copy, measured: rule 2's measured rail, never un-copied.
; qram_2d: g is indexed by rails, so it is bus-resident: __cq_alloc(64, 16). -O1's llvm.memset(g, 0, 64) is rule 22's
; ONE host loop of 64 kept byte stores of one i8 seed at the classical addresses g + j (never unrolled, emitted although
; the block is already zero). Each tainted getelementptr is its own address arithmetic (rule 20): %11 = &g[r & 3] is
; zext(r & 3) * 16 + g; %14 = &g[r & 3][c & 3] emits its own scale of the shared zext rail, zext(c & 3) * 4, their sum and
; + g. g[1][2] is -O1's classical gep g + 24 (it stays) and a _hl load. The store of v is a kept store at the address
; rail %14; its address chain is uncomputed right after it (the store is its last reader). The load g[r & 3][0] at the
; address rail %11 is un-copied after the add, so %11 outlives that _unc (rule 20).
source_filename = "alias_params_2d_qram.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @alias_params(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %6 = call ptr @__cq_alloc(i64 8, i64 4)    ; IR: %5 = alloca [2 x i32], align 4: bus-resident (a tainted-index gep and a call use it; rule 20): one zeroed block, no alloca remains
  %7 = ptrtoint ptr %6 to i64    ; IR: %5 as its run-time address
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %5: a0 as a seed (rule 7), kept with its store; llvm.lifetime.start dropped
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %7, i32 %9)    ; IR: store i32 %2, ptr %5: a[0] = a0  (kept store, classical address)
  %10 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %7 = getelementptr inbounds i8, ptr %5, i64 4  (nothing tainted: the gep stays)
  %11 = ptrtoint ptr %10 to i64    ; IR: %7 as its run-time address
  %12 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: store i32 %3, ptr %7: a1 as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %11, i32 %12)    ; IR: store i32 %3, ptr %7: a[1] = a1  (kept store)
  %13 = call i32 @cq_template_and_i32_hl(i32 %8, i32 1)    ; IR: %8 = and i32 %6, 1
  %14 = call i32 @cq_template_zext_i32_to_i64(i32 %13)    ; IR: %9 = zext nneg i32 %8 to i64
  %15 = call i32 @cq_template_mul_i64_hl(i32 %14, i64 4)    ; IR: %10 = getelementptr inbounds i32, ptr %5, i64 %9: the index scaled by the element size (rule 20)
  %16 = call i32 @cq_template_add_i64_hl(i32 %15, i64 %7)    ; IR: %10: plus the classical base address  [address rail q = &a[x & 1]]
  call fastcc void @__cq_q_addto_01(ptr %6, i32 %16)    ; IR: call fastcc void @addto(ptr %5, ptr %10): the clone of mask 01 (classical ptr p, address rail q); it stores, so it has no twin (rule 18)
  call void @cq_template_add_i64_hl_unc(i32 %16, i32 %15, i64 %7)    ; IR: uncompute %10 (the address rail passed to a storing callee, rule 5 sentence 3)
  call void @cqrt_free(i32 %16)    ; IR: release the %10 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %15, i32 %14, i64 4)    ; IR: uncompute %10 (the scaled index)
  call void @cqrt_free(i32 %15)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %14, i32 %13)    ; IR: uncompute %9
  call void @cqrt_free(i32 %14)    ; IR: release the %9 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %8, i32 1)    ; IR: uncompute %8
  call void @cqrt_free(i32 %13)    ; IR: release the %8 rail (|0>)
  %17 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %7)    ; IR: %11 = load i32, ptr %5: a[0]  (a fresh copy after the call, a memory version change)
  %18 = call i32 @cqrt_measure_i32(i32 %17)    ; IR: %12 = cq_measure_si32(%11)  (the measured load copy stays allocated, rule 2; llvm.lifetime.end dropped)
  ret i32 %18    ; IR: ret i32 %12
}

define internal fastcc void @__cq_q_addto_01(ptr noundef %0, i32 noundef %1) unnamed_addr {
  %3 = call i32 @__cq_mem()    ; IR: the bus M
  %4 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  %5 = call i32 @cqrt_qram_load_i32(i32 %3, i32 %1)    ; IR: %3 = load i32, ptr %1: *q at the address rail  (a plain load a step reads, before the swap-out; overtaken by the form: un-copied after the swap-in, not freed)
  %6 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %4 = load i32, ptr %0 ... store i32 %5, ptr %0: the in-place form (rule 5), a fresh |0> rail
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 %4, i32 %6)    ; IR: %4 = load i32, ptr %0: swap-out: the rail holds *p, the cell |0>
  %7 = call i32 @cq_template_add_i32(i32 %6, i32 %5)    ; IR: %5 = add nsw i32 %4, %3
  %8 = call i32 @cq_template_sub_i32(i32 %7, i32 %5)    ; IR: rule 6: t = y' - *q recomputes the old *p (the add is a bijection in it)
  call void @cqrt_copy_i32(i32 %8, i32 %6)    ; IR: rule 6: the old rail ^= t: |0>
  call void @cq_template_sub_i32_unc(i32 %8, i32 %7, i32 %5)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %8)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %6)    ; IR: release the old *p rail (|0> after the copy)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 %4, i32 %7)    ; IR: store i32 %5, ptr %0: swap-in: the cell holds *p + *q, the rail the cell's |0>
  call void @cqrt_free(i32 %7)    ; IR: release the rail (|0>): nothing remains of the update
  call void @cqrt_qram_load_i32_unc(i32 %5, i32 %3, i32 %1)    ; IR: un-copy %3 (*q) after its last reader, rule 6's _unc of t; the form lies between, so it is not freed (rule 5 sentence 1); the caller's address rail q outlives it
  ret void    ; IR: ret void
}

define i32 @qram_2d(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %7 = call ptr @__cq_alloc(i64 64, i64 16)    ; IR: %6 = alloca [4 x [4 x i32]], align 16: bus-resident (indexed by rails; rule 20): one zeroed block, no alloca remains
  %8 = ptrtoint ptr %7 to i64    ; IR: %6 as its run-time address
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %7 = cq_theta_ui32(%0, %1)  [register r]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %7 = cq_theta_ui32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %8 = cq_theta_ui32(%2, %3)  [register c]
  call void @cqrt_ry_i32(i32 %10, double %3)    ; IR: %8 = cq_theta_ui32(%2, %3)  [Ry]
  %11 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%6, i8 0, 64): the byte value as ONE seed rail (rules 7, 22), kept with its stores; llvm.lifetime.start dropped
  br label %12
12:
  %13 = phi i64 [ 0, %5 ], [ %15, %12 ]    ; IR: call @llvm.memset(%6, i8 0, 64): byte j of the classical length 64 (host loop, rule 22)
  %14 = add i64 %8, %13    ; IR: the classical address g + j
  call void @cqrt_qram_store_i8_hl(i32 %6, i64 %14, i32 %11)    ; IR: call @llvm.memset(%6, i8 0, 64): byte store j  (kept store, rule 5)
  %15 = add nuw nsw i64 %13, 1
  %16 = icmp eq i64 %15, 64
  br i1 %16, label %17, label %12
17:
  %18 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %9 = and i32 %7, 3
  %19 = call i32 @cq_template_zext_i32_to_i64(i32 %18)    ; IR: %10 = zext nneg i32 %9 to i64
  %20 = call i32 @cq_template_mul_i64_hl(i32 %19, i64 16)    ; IR: %11 = getelementptr [4 x [4 x i32]], ptr %6, i64 0, i64 %10: the row index scaled by the row size 16 (rule 20)
  %21 = call i32 @cq_template_add_i64_hl(i32 %20, i64 %8)    ; IR: %11: plus the classical base address  [address rail &g[r & 3]]
  %22 = call i32 @cq_template_and_i32_hl(i32 %10, i32 3)    ; IR: %12 = and i32 %8, 3
  %23 = call i32 @cq_template_zext_i32_to_i64(i32 %22)    ; IR: %13 = zext nneg i32 %12 to i64
  %24 = call i32 @cq_template_mul_i64_hl(i32 %19, i64 16)    ; IR: %14 = getelementptr [4 x [4 x i32]], ptr %6, i64 0, i64 %10, i64 %13: its own scale of the row index (rule 20: per getelementptr)
  %25 = call i32 @cq_template_mul_i64_hl(i32 %23, i64 4)    ; IR: %14: the column index scaled by the element size 4
  %26 = call i32 @cq_template_add_i64(i32 %24, i32 %25)    ; IR: %14: the two scaled indices added  ; SPEC GAP: rule 20 fixes the scale and add per tainted index, not the association of two tainted indices with the classical part; taken as (row + column) + base, the classical i64 last as the _hl literal
  %27 = call i32 @cq_template_add_i64_hl(i32 %26, i64 %8)    ; IR: %14: plus the classical base address  [address rail &g[r & 3][c & 3]]
  %28 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: store i32 %4, ptr %14: v as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32(i32 %6, i32 %27, i32 %28)    ; IR: store i32 %4, ptr %14: g[r & 3][c & 3] = v  (kept store at the address rail)
  call void @cq_template_add_i64_hl_unc(i32 %27, i32 %26, i64 %8)    ; IR: uncompute %14 (the store was its last reader, rule 20)
  call void @cqrt_free(i32 %27)    ; IR: release the %14 rail (|0>)
  call void @cq_template_add_i64_unc(i32 %26, i32 %24, i32 %25)    ; IR: uncompute %14 (the sum of the scaled indices)
  call void @cqrt_free(i32 %26)    ; IR: release it (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %25, i32 %23, i64 4)    ; IR: uncompute %14 (the scaled column index)
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %24, i32 %19, i64 16)    ; IR: uncompute %14 (its scaled row index)
  call void @cqrt_free(i32 %24)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %23, i32 %22)    ; IR: uncompute %13
  call void @cqrt_free(i32 %23)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %22, i32 %10, i32 3)    ; IR: uncompute %12
  call void @cqrt_free(i32 %22)    ; IR: release the %12 rail (|0>)
  %29 = getelementptr inbounds i8, ptr %7, i64 24    ; IR: %15 = getelementptr inbounds i8, ptr %6, i64 24  (nothing tainted: the gep stays)
  %30 = ptrtoint ptr %29 to i64    ; IR: %15 as its run-time address
  %31 = call i32 @cqrt_qram_load_i32_hl(i32 %6, i64 %30)    ; IR: %16 = load i32, ptr %15: g[1][2]  (a bus load at a classical address: a rail)
  %32 = call i32 @cqrt_qram_load_i32(i32 %6, i32 %21)    ; IR: %17 = load i32, ptr %11: g[r & 3][0]  (at the address rail %11)
  %33 = call i32 @cq_template_add_i32(i32 %32, i32 %31)    ; IR: %18 = add nsw i32 %17, %16  [result rail]  ; SPEC GAP: rule 6 'both operands dead' with two bus load copies: taken as rule-5 garbage, so rule 6 has no trigger (as 198)
  call void @cqrt_qram_load_i32_unc(i32 %32, i32 %6, i32 %21)    ; IR: un-copy %17 (no memory version change since the load)  ; SPEC GAP: sentence 1 asks for the consumer's uncompute; the consumer %18 is measured and has none (as 195, 198): un-copied before the measurement
  call void @cqrt_free(i32 %32)    ; IR: release the %17 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %21, i32 %20, i64 %8)    ; IR: uncompute %11 (it outlived its load's _unc, rule 20)
  call void @cqrt_free(i32 %21)    ; IR: release the %11 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %20, i32 %19, i64 16)    ; IR: uncompute %11 (the scaled row index)
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %19, i32 %18)    ; IR: uncompute %10
  call void @cqrt_free(i32 %19)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %18, i32 %9, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %18)    ; IR: release the %9 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %31, i32 %6, i64 %30)    ; IR: un-copy %16  ; SPEC GAP: as at %17
  call void @cqrt_free(i32 %31)    ; IR: release the %16 rail (|0>)
  %34 = call i32 @cqrt_measure_i32(i32 %33)    ; IR: %19 = cq_measure_si32(%18)  (llvm.lifetime.end dropped)
  ret i32 %34    ; IR: ret i32 %19
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i8(i8)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
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
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
