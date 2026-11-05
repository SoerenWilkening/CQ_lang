; HAND-WRITTEN. Rules: 5 (Memory, sentences 1 and 3), 20, 22, 21, 16, 14, 8, 12, 4, 2, 7.
; Checked: a[0] at exit = ((k & 3) == 0 ? y : 1), measured through load 3 (%38 -> %39); the cells a[0..3] on the bus at
; exit: a[k & 3] = y, each other cell a[i] = i + 1 (its initializer value).
; Clean: the address chain of load 1 and of the store (k & 3 %25, its zext %26, the scaled index %27, the address rail
; A1 %28: one chain, -O1 reuses the gep %12), uncomputed after the STORE; the copy L1 (%29) of load 1 and its flag L1 >
; 2 (%30), uncomputed and freed before the store; the address chain of load 2 (k >> 2, & 3, zext, scaled index, A2:
; %31..%35), uncomputed right after the un-copy of L2; the flag L2 > 2 (%37), uncomputed after its phase.
; Kept: k (%10) and y (%11) (rotated registers; y is also the value rail of the kept store). Rule 5 sentence 3: the tape
; slot of the store a[k & 3] = y, and the 16 tape slots of the initializer's byte stores with their 16 value rails, the
; load copies of the source bytes (%15, one per trip of the load loop, handed to the store loop by cqrt_push /
; cqrt_pop; rule 22: never un-copied, never freed). Rule 5 sentence 1: the copy L2 (%36) of load 2 (the store
; overtakes it before its consumer %22: un-copied after %22's uncompute, left allocated). Rule 2: L3 (%38, measured).
; Rotations: (Ry, k, tk, 1); (Ry, y, ty, 1); (P, flag, p1, INIT[k & 3] > 2); (P, flag, p2, INIT[(k >> 2) & 3] > 2), with
; INIT = {1, 2, 3, 4}: the predicates are bit 1 of k and bit 3 of k. Both phases read the cells BEFORE the store.
; Expected for the driver bus_kept_and_uncopied(1, .5, 9, .25, .125, .375) (analytic, not replayed): Ry(t) flips each
; qubit of a basis register with probability sin^2(t/2). The result is y iff bits 1..0 of k are 00: k0 = 1, so bit 0
; must flip and bit 1 must not, probability sin^2(.25) cos^2(.25) = sin^2(.5) / 4 = 0.057462; otherwise it is 1
; (0.942538). Given the store hit a[0], the result is y0 = 9 with each of its 32 bits flipped independently with
; probability s = sin^2(.125) = 0.015544. So P(1) = 0.942538 + 0.057462 s (1 - s)^31 = 0.943088, P(9) = 0.057462 (1 -
; s)^32 = 0.034807, and P(v) = 0.057462 s^d (1 - s)^(32 - d) for any other v at Hamming distance d from 9. The two
; phases are diagonal and precede no rotation: they do not change this distribution. On the unrotated branch (k = 1)
; load 2 reads a[0] = 1 and the store hits a[1]; on every branch where bits 3..2 of k equal bits 1..0 the two hit the
; same cell, and t is the initializer value there (before the store), never y.
; NOTHING IS DEFERRED. The bus is one linear value and no two accesses commute for the compiler (rule 5): whether load 1
; and the store hit the same cell is never asked, although here they share the SSA address %12. A load copy has exactly
; two fates, decided by where its last consumer and that consumer's uncompute lie relative to the next memory version
; change. Load 1 (%13): its only consumer is the flag %14, whose last controlled gate is the phase p1 in block %15; the
; flag is uncomputed, then the copy is un-copied (cqrt_qram_load_i32_unc, the cells still hold what the load read) and
; freed, all before the store. Load 2 (%21): its consumer %22 follows the store, so the copy is un-copied after the
; flag's uncompute (at the same address rail A2, which stays alive until then) and left allocated: the store came
; between. The store is a kept store: no _unc exists, its tape slot holds the displaced cell content, and
; its value rail y is never freed. Its address rail A1 is a template result and is uncomputed AFTER the store; A2 is
; uncomputed right after L2's un-copy, its last reader.
; MEMORY. a is bus-resident (a getelementptr with a tainted index reaches it, rule 20): no alloca remains, the block is
; __cq_alloc(16, 16) at the alloca's program point, and the lifetime markers are dropped (rule 16). The initializer
; memcpy is rule 22 at the classical length 16, never unrolled: a host loop of 16 qram_load_i8_hl at the source address,
; each byte's copy pushed on cqrt_push, then a host loop of 16 qram_store_i8_hl at the block that pops them, so the
; stores run from byte 15 down to byte 0 (a copy has no direction). The source is the constant global at its host
; address, read as HOST cells through the overlay (rule 22: the copies classical-valued); every address and value is
; classical-valued, so the cells stay HOST until the store at A1 makes the cells it can reach QUANTUM (§1.3). The geps
; %12 and %20 are 64-bit template arithmetic on the run-time base (rule 20): zext, mul by sizeof(int), add of the
; classical base. Load 3 is at the classical address of a[0]: the _hl form.
source_filename = "bus_kept_and_uncopied.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__const.bus_kept_and_uncopied.a = private unnamed_addr constant [4 x i32] [i32 1, i32 2, i32 3, i32 4], align 16

define i32 @bus_kept_and_uncopied(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3, double noundef %4, double noundef %5) {
  %7 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle, once at function entry
  %8 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = alloca [4 x i32], align 16  [bus-resident: one zeroed block, rule 20]
  %9 = ptrtoint ptr %8 to i64    ; IR: %7 as its run-time address (the classical literal of the address arithmetic, rule 21)
  %10 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %10, double %1)    ; IR: %8 = cq_theta_ui32(%0, %1)  [Ry]
  %11 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %9 = cq_theta_si32(%2, %3)  [register y]
  call void @cqrt_ry_i32(i32 %11, double %3)    ; IR: %9 = cq_theta_si32(%2, %3)  [Ry]
  br label %12    ; IR: llvm.lifetime.start(16, %7) dropped (rule 16); llvm.memcpy(%7, @__const.bus_kept_and_uncopied.a, 16)  [rule 22: load all 16 source bytes, then store all 16]

12:
  %13 = phi i64 [ 0, %6 ], [ %16, %12 ]    ; byte index of the load loop (classical)
  %14 = add i64 ptrtoint (ptr @__const.bus_kept_and_uncopied.a to i64), %13    ; the source byte's host address (classical)
  %15 = call i32 @cqrt_qram_load_i8_hl(i32 %7, i64 %14)    ; IR: llvm.memcpy  [source byte: a bus load of a HOST cell (rule 22); the copy is the value rail of that byte's store, KEPT (rule 5)]
  call void @cqrt_push(i32 %15)    ; IR: llvm.memcpy  [the byte rail handed to the store loop (rule 22)]
  %16 = add nuw nsw i64 %13, 1
  %17 = icmp eq i64 %16, 16
  br i1 %17, label %18, label %12

18:
  %19 = phi i64 [ 16, %12 ], [ %20, %18 ]    ; bytes left to store (classical)
  %20 = add nsw i64 %19, -1    ; byte index of this store: 15 down to 0 (the pop order)
  %21 = call i32 @cqrt_pop()    ; IR: llvm.memcpy  [the load copy of byte %20]
  %22 = add i64 %9, %20    ; IR: llvm.memcpy  [the destination byte's address (classical)]
  call void @cqrt_qram_store_i8_hl(i32 %7, i64 %22, i32 %21)    ; IR: llvm.memcpy  [destination byte: a kept store (rule 5); address and value classical-valued, the cell stays HOST]
  %23 = icmp eq i64 %20, 0
  br i1 %23, label %24, label %18

24:
  %25 = call i32 @cq_template_and_i32_hl(i32 %10, i32 3)    ; IR: %10 = and i32 %8, 3
  %26 = call i32 @cq_template_zext_i32_to_i64(i32 %25)    ; IR: %11 = zext nneg i32 %10 to i64
  %27 = call i32 @cq_template_mul_i64_hl(i32 %26, i64 4)    ; IR: %12 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %11  [index * sizeof(int)]
  %28 = call i32 @cq_template_add_i64_hl(i32 %27, i64 %9)    ; IR: %12 = getelementptr ...  [+ the run-time base: the address rail A1]
  %29 = call i32 @cqrt_qram_load_i32(i32 %7, i32 %28)    ; IR: %13 = load i32, ptr %12  (load 1)
  %30 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %29, i32 2)    ; IR: %14 = icmp sgt i32 %13, 2
  call void @cqrt_rz_i1(i32 %30, double %4)    ; IR: block %15 under br i1 %14: cq_phi(%4)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %30, i32 %29, i32 2)    ; IR: uncompute %14
  call void @cqrt_free(i32 %30)    ; IR: release the %14 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %29, i32 %7, i32 %28)    ; IR: un-copy %13: its last consumer %14 and that flag's uncompute precede the next memory version change (rule 5 sentence 1)
  call void @cqrt_free(i32 %29)    ; IR: release the %13 rail (|0>)
  %31 = call i32 @cq_template_lshr_i32_hl(i32 %10, i32 2)    ; IR: %17 = lshr i32 %8, 2
  %32 = call i32 @cq_template_and_i32_hl(i32 %31, i32 3)    ; IR: %18 = and i32 %17, 3
  %33 = call i32 @cq_template_zext_i32_to_i64(i32 %32)    ; IR: %19 = zext nneg i32 %18 to i64
  %34 = call i32 @cq_template_mul_i64_hl(i32 %33, i64 4)    ; IR: %20 = getelementptr inbounds [4 x i32], ptr %7, i64 0, i64 %19  [index * sizeof(int)]
  %35 = call i32 @cq_template_add_i64_hl(i32 %34, i64 %9)    ; IR: %20 = getelementptr ...  [the address rail A2]
  %36 = call i32 @cqrt_qram_load_i32(i32 %7, i32 %35)    ; IR: %21 = load i32, ptr %20  (load 2: the store below overtakes it before its consumer %22: un-copied after %22's uncompute, not freed)
  call void @cqrt_qram_store_i32(i32 %7, i32 %28, i32 %11)    ; IR: store i32 %9, ptr %12  (a kept store: no _unc, its tape slot and its value rail y stay, rule 5 sentence 3)
  call void @cq_template_add_i64_hl_unc(i32 %28, i32 %27, i64 %9)    ; IR: uncompute %12: the store's address rail is a template result, uncomputed after the store
  call void @cqrt_free(i32 %28)    ; IR: release the %12 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %27, i32 %26, i64 4)    ; IR: uncompute %12 (the scaled index)
  call void @cqrt_free(i32 %27)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %26, i32 %25)    ; IR: uncompute %11
  call void @cqrt_free(i32 %26)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %25, i32 %10, i32 3)    ; IR: uncompute %10
  call void @cqrt_free(i32 %25)    ; IR: release the %10 rail (|0>)
  %37 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %36, i32 2)    ; IR: %22 = icmp sgt i32 %21, 2  [reads the overtaken copy: the value before the store]
  call void @cqrt_rz_i1(i32 %37, double %5)    ; IR: block %23 under br i1 %22: cq_phi(%5)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %37, i32 %36, i32 2)    ; IR: uncompute %22 (against the copy %21, un-copied next)
  call void @cqrt_free(i32 %37)    ; IR: release the %22 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %36, i32 %7, i32 %35)    ; IR: un-copy %21 (L2) after its last reader, the _unc of %22; the store came between, so it is not freed (overtaken, rule 5 sentence 1)
  call void @cq_template_add_i64_hl_unc(i32 %35, i32 %34, i64 %9)    ; IR: uncompute %20 (A2) after the un-copy of L2, its last reader
  call void @cqrt_free(i32 %35)    ; IR: release the %20 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %34, i32 %33, i64 4)    ; IR: uncompute %20 (the scaled index)
  call void @cqrt_free(i32 %34)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %33, i32 %32)    ; IR: uncompute %19
  call void @cqrt_free(i32 %33)    ; IR: release the %19 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %32, i32 %31, i32 3)    ; IR: uncompute %18
  call void @cqrt_free(i32 %32)    ; IR: release the %18 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %31, i32 %10, i32 2)    ; IR: uncompute %17
  call void @cqrt_free(i32 %31)    ; IR: release the %17 rail (|0>)
  %38 = call i32 @cqrt_qram_load_i32_hl(i32 %7, i64 %9)    ; IR: %25 = load i32, ptr %7  (load 3: a classical address, the _hl form; measured, rule 2)
  %39 = call i32 @cqrt_measure_i32(i32 %38)    ; IR: %26 = cq_measure_si32(%25)
  ret i32 %39    ; IR: ret i32 %26  [llvm.lifetime.end of %7 is dropped, rule 16]
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_rz_i1(i32, double)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i32 @cqrt_qram_load_i8_hl(i32, i64)
declare void @cqrt_qram_store_i8_hl(i32, i64, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
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
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
