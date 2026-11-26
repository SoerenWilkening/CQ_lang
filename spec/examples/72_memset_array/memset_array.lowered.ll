; HAND-WRITTEN. Rules: 22, 20, 21, 16, 14, 5, 6, 7, 4, 2.
; Checked: memset_over_quantum: before + a[1] (the add rail, measured), before = a[k & 3] read before the memset;
; memset_quantum_byte: b[0] + b[3] (the zext rail of b[3], updated in place into the sum, measured). The cells of the two blocks are not named outputs.
; Clean: memset_over_quantum: the address chain of &a[x & 3] (x & 3, its zext, the scaled index, the address rail),
; each uncomputed by its template's _unc right after the store and freed; the load copy a[1], un-copied after the add,
; before the measurement (no memory version change lies between the load and its _unc) and freed; the load copy
; before = a[k & 3], un-copied after the add, its last reader, and left allocated (rule 5 sentence 1: the memset, a
; memory version change, lies between the load and that point).
; memset_quantum_byte: the address chain of &b[y & 3] (y & 3, its zext, the address rail; size 1, no scale),
; uncomputed right after the store and freed; the load copy b[3], un-copied after its zext and freed; the zext of b[0]
; and its load copy, uncomputed after the add, before the measurement, and freed.
; Kept: memset_over_quantum: x (rotated register); the four fill-value rails x + i (each the value rail of its trip's
; kept store, rule 5); the i8 seed 0 (the value rail of the memset's 16
; kept byte stores, rules 7, 22); the i32 seed c (the value rail of the store a[x & 3] = c); the tape slots of the 4
; fill stores, the 16 memset byte stores and the quantum-address store (rule 5); the sum (measured).
; memset_quantum_byte: x and y (rotated registers); the fill byte rail (char)x (the value rail of the memset's 4 kept
; byte stores, rule 22); the i8 seed 7 (value rail of the store b[y & 3] = 7); the tape slots of the 4 memset byte
; stores and of the quantum-address store; the zext rail of b[3], updated in place into the sum (measured).
; Rotations: memset_over_quantum: (Ry, x, th, 1). memset_quantum_byte: (Ry, x, tx, 1); (Ry, y, ty, 1).
; ONE BUS (rules 20, 21): a[] and b[] are written at a QUANTUM address (a[x & 3] = c, b[y & 3] = 7: a getelementptr with
; a tainted index) and take quantum values, so each alloca is BUS-RESIDENT: __cq_alloc(size, align) at its program
; point, one zeroed block, no alloca remains, and the lifetime markers emit nothing (rule 16). m = __cq_mem() once at
; function entry (§5). Every access is ONE bus call at the run-time address: _hl with the classical i64 (ptrtoint of
; the block or of a getelementptr that stays because nothing in it is tainted), the plain form with a 64-bit address
; rail (x & 3, zext as -O1 wrote it, mul_i64_hl by the element size, add_i64_hl of the classical base). Every load is a
; bus load whose result is a rail; every store is a KEPT store (rule 5 sentence 3: no pop, the tape slot and the value
; rail stay; a classical value is first a seed, rule 7).
; MEMSET (rule 22): llvm.memset is ONE host loop of n byte stores qram_store_i8_hl at the classical addresses
; base + j of ONE i8 value rail, never unrolled although n is a constant (16 for a[], 4 for b[]), never widened into
; word stores, and emitted although the __cq_alloc block is already zero (memset_over_quantum's fill 0: the seed
; alloc_i8(0)); memset_quantum_byte's fill is the quantum rail trunc (char)x, kept with its stores.
; THE FILL LOOP (rule 14, classical bound): it stays the classical loop. Trip i's only rail, x + i, is the value rail of
; a kept store and is kept, so nothing is pushed and there is no reverse loop (as 204).
; before = a[k & 3] is a bus load at a classical address taken before the memset: it is un-copied after the add, its
; last reader, and stays allocated, not freed (rule 5 sentence 1: overtaken by the memset). a[1] is loaded after the quantum-address store and un-copied before the
; measurement. A load copy is never cleaned by rule 6, so the add's operands are not cleaned by it.
; In memset_quantum_byte both operands of b[0] + b[3] are zexts of load copies, rule-5 garbage; the add is a plain
; add of a dead value, so rule 6's in-place update (owner ruling 2026-11-26: it applies though the operand is garbage)
; makes it ONE core gate add_i32(zext b[0], zext b[3]) on the rail of operand 0 of the IR add (both are garbage), which
; is the sum from there on and is measured. That zext's _unc is never called; its load copy b[3] is un-copied right
; after the zext, its last reader. The zext of b[0] and its load copy are uncomputed after the add as before.
source_filename = "memset_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @memset_over_quantum(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %6 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %5 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %7 = ptrtoint ptr %6 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  br label %9    ; IR: llvm.lifetime.start(16, %5) dropped (rule 16); br label %19

9:
  %10 = phi i64 [ 0, %4 ], [ %15, %9 ]    ; IR: %20 = phi i64 [ 0, %4 ], [ %24, %19 ]  (classical i)
  %11 = trunc nuw nsw i64 %10 to i32    ; IR: %21 = trunc nuw nsw i64 %20 to i32  (classical)
  %12 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %11)    ; IR: %22 = add i32 %6, %21  [a[i]'s value rail, kept with its store]
  %13 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %10    ; IR: %23 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %20  (nothing tainted: the getelementptr stays)
  %14 = ptrtoint ptr %13 to i64    ; the run-time address of a[i]
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %14, i32 %12)    ; IR: store i32 %22, ptr %23: a[i] = x + i  [kept store at a classical address (rule 5)]
  %15 = add nuw nsw i64 %10, 1    ; IR: %24 = add nuw nsw i64 %20, 1  (classical)
  %16 = icmp eq i64 %15, 4    ; IR: %25 = icmp eq i64 %24, 4  (classical bound)
  br i1 %16, label %17, label %9    ; IR: br i1 %25, label %7, label %19

17:
  %18 = and i32 %3, 3    ; IR: %8 = and i32 %3, 3  (classical)
  %19 = zext nneg i32 %18 to i64    ; IR: %9 = zext nneg i32 %8 to i64  (classical)
  %20 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %19    ; IR: %10 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %9  (nothing tainted: stays)
  %21 = ptrtoint ptr %20 to i64    ; the run-time address of a[k & 3]
  %22 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %21)    ; IR: %11 = load i32, ptr %10: before = a[k & 3]  [a bus load copy; the memset follows before its last reader, so it is un-copied after it but not freed (rule 5 sentence 1)]
  %23 = call i32 @cqrt_alloc_i8(i8 0)    ; IR: call @llvm.memset(%5, i8 0, 16): the fill byte as ONE seed rail (rules 7, 22), kept with its stores
  br label %24

24:
  %25 = phi i64 [ 0, %17 ], [ %27, %24 ]    ; IR: call @llvm.memset(%5, i8 0, 16): byte j of the classical length 16 (host loop, rule 22)
  %26 = add i64 %7, %25    ; the classical address a + j
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %26, i32 %23)    ; IR: call @llvm.memset(%5, i8 0, 16): byte store j  [kept store (rule 5)]
  %27 = add nuw nsw i64 %25, 1
  %28 = icmp eq i64 %27, 16
  br i1 %28, label %29, label %24

29:
  %30 = call i32 @cq_template_and_i32_hl(i32 %8, i32 3)    ; IR: %12 = and i32 %6, 3
  %31 = call i32 @cq_template_zext_i32_to_i64(i32 %30)    ; IR: %13 = zext nneg i32 %12 to i64
  %32 = call i32 @cq_template_mul_i64_hl(i32 %31, i64 4)    ; IR: %14 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 %13  [the tainted index scaled by the element size (rule 20)]
  %33 = call i32 @cq_template_add_i64_hl(i32 %32, i64 %7)    ; IR: %14: plus the classical base address  [the address rail of &a[x & 3]]
  %34 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %14: the classical value c as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32(i32 %5, i32 %33, i32 %34)    ; IR: store i32 %2, ptr %14: a[x & 3] = c  [kept store at an address rail (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %33, i32 %32, i64 %7)    ; IR: uncompute %14  [the address rail: a template result, uncomputed after the store (rule 5)]
  call void @cqrt_free(i32 %33)    ; IR: release the %14 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %32, i32 %31, i64 4)    ; IR: uncompute %14 (the scaled index)
  call void @cqrt_free(i32 %32)    ; IR: release the scaled index (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %31, i32 %30)    ; IR: uncompute %13
  call void @cqrt_free(i32 %31)    ; IR: release the %13 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %30, i32 %8, i32 3)    ; IR: uncompute %12
  call void @cqrt_free(i32 %30)    ; IR: release the %12 rail (|0>)
  %35 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %15 = getelementptr inbounds i8, ptr %5, i64 4  (nothing tainted: stays)
  %36 = ptrtoint ptr %35 to i64    ; the run-time address of a[1]
  %37 = call i32 @cqrt_qram_load_i32_hl(i32 %5, i64 %36)    ; IR: %16 = load i32, ptr %15: a[1]  [a bus load copy]
  %38 = call i32 @cq_template_add_i32(i32 %37, i32 %22)    ; IR: %17 = add nsw i32 %16, %11  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %37, i32 %5, i64 %36)    ; IR: un-copy %16 (its last reader %17 is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %37)    ; IR: release the %16 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %22, i32 %5, i64 %21)    ; IR: un-copy %11 after its last reader %17; the memset and the store lie between, so it stays allocated (rule 5 sentence 1)
  %39 = call i32 @cqrt_measure_i32(i32 %38)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %39    ; IR: ret i32 %18  (llvm.lifetime.end dropped)
}

define i32 @memset_quantum_byte(i32 noundef %0, i32 noundef %1, double noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %6 = call ptr @__cq_alloc(i64 4, i64 1)    ; IR: %5 = alloca [4 x i8], align 1  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %7 = ptrtoint ptr %6 to i64    ; the block's run-time address, a classical i64 (rule 21)
  %8 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %2)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %2)    ; IR: %6 = cq_theta_ui32(%0, %2)  [Ry]
  %9 = call i32 @cqrt_alloc_i32(i32 %1)    ; IR: %7 = cq_theta_ui32(%1, %3)  [register y]
  call void @cqrt_ry_i32(i32 %9, double %3)    ; IR: %7 = cq_theta_ui32(%1, %3)  [Ry]
  %10 = call i32 @cq_template_trunc_i32_to_i8(i32 %8)    ; IR: %8 = trunc i32 %6 to i8  [the fill byte rail: the memset's ONE value rail, kept with its stores (rule 22)]
  br label %11    ; IR: llvm.lifetime.start(4, %5) dropped (rule 16)

11:
  %12 = phi i64 [ 0, %4 ], [ %14, %11 ]    ; IR: call @llvm.memset(%5, i8 %8, 4): byte j of the classical length 4 (host loop, rule 22)
  %13 = add i64 %7, %12    ; the classical address b + j
  call void @cqrt_qram_store_i8_hl(i32 %5, i64 %13, i32 %10)    ; IR: call @llvm.memset(%5, i8 %8, 4): b[j] = (char)x  [kept store (rule 5)]
  %14 = add nuw nsw i64 %12, 1
  %15 = icmp eq i64 %14, 4
  br i1 %15, label %16, label %11

16:
  %17 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: %9 = and i32 %7, 3
  %18 = call i32 @cq_template_zext_i32_to_i64(i32 %17)    ; IR: %10 = zext nneg i32 %9 to i64
  %19 = call i32 @cq_template_add_i64_hl(i32 %18, i64 %7)    ; IR: %11 = getelementptr inbounds [4 x i8], ptr %5, i64 0, i64 %10  [element size 1: no scale; plus the classical base: the address rail of &b[y & 3]]
  %20 = call i32 @cqrt_alloc_i8(i8 7)    ; IR: store i8 7, ptr %11: the classical value 7 as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i8(i32 %5, i32 %19, i32 %20)    ; IR: store i8 7, ptr %11: b[y & 3] = 7  [kept store at an address rail (rule 5)]
  call void @cq_template_add_i64_hl_unc(i32 %19, i32 %18, i64 %7)    ; IR: uncompute %11  [the address rail, after the store (rule 5)]
  call void @cqrt_free(i32 %19)    ; IR: release the %11 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %18, i32 %17)    ; IR: uncompute %10
  call void @cqrt_free(i32 %18)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %9, i32 3)    ; IR: uncompute %9
  call void @cqrt_free(i32 %17)    ; IR: release the %9 rail (|0>)
  %21 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %7)    ; IR: %12 = load i8, ptr %5: b[0]  [a bus load copy]
  %22 = call i32 @cq_template_zext_i8_to_i32(i32 %21)    ; IR: %13 = zext i8 %12 to i32
  %23 = getelementptr inbounds i8, ptr %6, i64 3    ; IR: %14 = getelementptr inbounds i8, ptr %5, i64 3  (nothing tainted: stays)
  %24 = ptrtoint ptr %23 to i64    ; the run-time address of b[3]
  %25 = call i32 @cqrt_qram_load_i8_hl(i32 %5, i64 %24)    ; IR: %15 = load i8, ptr %14: b[3]  [a bus load copy]
  %26 = call i32 @cq_template_zext_i8_to_i32(i32 %25)    ; IR: %16 = zext i8 %15 to i32
  call void @cqrt_qram_load_i8_hl_unc(i32 %25, i32 %5, i64 %24)    ; IR: un-copy %15 after its last reader, the zext %16 (no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %25)    ; IR: release the %15 rail (|0>)
  call void @cqrt_add_i32(i32 %22, i32 %26)    ; IR: %17 = add nuw nsw i32 %16, %13  [rule 6, in-place update (owner ruling 2026-11-26: it applies to the zext, rule-5 garbage): %16 is dead after the add, so the result IS the %16 rail: %16 += %13]
  call void @cq_template_zext_i8_to_i32_unc(i32 %22, i32 %21)    ; IR: uncompute %13
  call void @cqrt_free(i32 %22)    ; IR: release the %13 rail (|0>)
  call void @cqrt_qram_load_i8_hl_unc(i32 %21, i32 %5, i64 %7)    ; IR: un-copy %12
  call void @cqrt_free(i32 %21)    ; IR: release the %12 rail (|0>)
  %27 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %27    ; IR: ret i32 %18  (llvm.lifetime.end dropped)
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i8(i8)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_qram_store_i8(i32, i32, i32)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_load_i8_hl_unc(i32, i32, i64)
declare void @cqrt_add_i32(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i32_to_i8(i32)
declare i32 @cq_template_zext_i8_to_i32(i32)
declare void @cq_template_zext_i8_to_i32_unc(i32, i32)
