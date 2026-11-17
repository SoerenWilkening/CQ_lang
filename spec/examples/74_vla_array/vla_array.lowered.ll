; HAND-WRITTEN. Rules: 2, 4, 5, 14, 16, 20, 21, 3, 7; §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: a[x % n] (the load copy at the address rail, %28, measured -> %29); the cells of the block on the bus at
; exit: a[i] = i * c, 0 <= i < n.
; Clean: the address chain of &a[x % n]: the index rail x % n (%24), its zext to i64 (%25), the scaled index (%26) and
; the address rail (%27), uncomputed and freed right after the load (the load copy is measured, so the load is the
; address rail's last reader, rule 20).
; Kept: x (%6, the rotated register: urem is no bijection, so rule 6 has no trigger); rule 5 sentence 3, per fill
; trip: the tape slot of the store a[i] = i * c (it holds the displaced zero bytes of the block) and its value rail,
; the seed alloc_i32(i * c) (%20, rule 7; classical-valued, so no qubit, §0); the load copy a[x % n] (%28, measured,
; rule 2).
; Rotations: (Ry, x, th, 1).
; Driver vla_array(0, .5, 5, 3): Ry(.5) flips each of the 32 bits of x0 = 0 with probability s = sin^2(.25) =
; 0.061209, independently. The cells are a = {0, 3, 6, 9, 12} and the measured value is 3*(x mod 5): 0 with
; probability 0.263952 (x = 0 alone contributes (1 - s)^32 = 0.132498), and 3, 6, 9, 12 with 0.184012 each.
; ONE BUS (rules 16, 20, 21). The VLA's users are the fill loop's stores through a getelementptr with an untainted index
; and the load through a getelementptr with the TAINTED index x % n: that user is none rule 20 (b) allows, so the alloca
; is BUS-RESIDENT. It is __cq_alloc(n * 4, 16) at the alloca's program point (rule 16: a variable-length alloca alike;
; the alignment is the alloca's 16; zeroed host memory at an address never reused, its size in the 8 bytes before it),
; and no alloca remains. The size is classical (n is a parameter), so no K2 and no overflow predicate. At -O1 a VLA at
; function scope has no llvm.stacksave/stackrestore; inside a loop or a block they would be dropped (rule 16). m =
; __cq_mem() is called once, at entry (§5). Nothing is known about the block at compile time: its base is its run-time
; address, a classical i64.
; The fill loop has a classical bound (rule 14) and classical contents. Its getelementptr has an untainted index and
; stays; the store's address is its ptrtoint, and every store is a bus store: cqrt_qram_store_i32_hl of the seed
; alloc_i32(i * c) (a store's value is always a handle). Each is a KEPT store (rule 5 sentence 3): its tape slot and its
; seed stay for the shot, so no trip rail is pushed and there is no reverse loop. Value, address and control are all
; classical-valued, so the stores write the host bytes and the cells stay HOST (§1.3).
; The quantum-index read is ONE bus load at an ADDRESS RAIL (rule 20; QROM is retired): urem_i32_hl(x, n) is the index
; rail, -O1's zext to i64 is the zext template, the getelementptr is mul_i64_hl by the element size 4 and add_i64_hl of
; the classical base, and qram_load_i32 reads the 4 cells at that address. No index is narrowed, bounded or checked
; (rule 21): for n > 0, x % n lies in [0, n) and the load reads a cell the fill loop wrote. n == 0 is undefined
; behaviour in C; the lowering is total all the same: urem(x, 0) = x (§2), the block has size 0, and the load reads
; whatever the bus holds at base + 4x (§2: an unreadable HOST cell reads 0, never a fault). The load copy is measured,
; so it is never un-copied (rule 5 sentence 1); the address chain is template garbage, uncomputed in reverse order
; right after the load and before the measurement.
source_filename = "vla_array.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @vla_array(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3) {
  %5 = call i32 @__cq_mem()    ; IR: (no instruction) the bus handle m (once, at function entry, §5)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = zext i32 %2 to i64    ; IR: %6 = zext i32 %2 to i64  (classical element count)
  %8 = shl nuw nsw i64 %7, 2    ; IR: %7 = alloca i32, i64 %6  (classical: n * sizeof(int) bytes)
  %9 = call ptr @__cq_alloc(i64 %8, i64 16)    ; IR: %7 = alloca i32, i64 %6, align 16  [bus-resident (a load through a tainted-index gep): one zeroed block, no alloca remains (rules 16, 20)]
  %10 = ptrtoint ptr %9 to i64    ; IR: %7 as its run-time address, the classical part of the read's address (rule 21)
  %11 = icmp sgt i32 %2, 0    ; IR: %8 = icmp sgt i32 %2, 0  (classical)
  br i1 %11, label %12, label %23    ; IR: br i1 %8, label %9, label %11

12:
  %13 = zext nneg i32 %2 to i64    ; IR: %10 = zext nneg i32 %2 to i64  (classical)
  br label %14    ; IR: br label %17

14:
  %15 = phi i64 [ 0, %12 ], [ %21, %14 ]    ; IR: %18 = phi i64 [ 0, %9 ], [ %22, %17 ]  (classical i)
  %16 = getelementptr inbounds i32, ptr %9, i64 %15    ; IR: %19 = getelementptr inbounds i32, ptr %7, i64 %18  (untainted: stays)
  %17 = ptrtoint ptr %16 to i64    ; IR: %19 as its run-time address (the _hl operand)
  %18 = trunc i64 %15 to i32    ; IR: %20 = trunc i64 %18 to i32  (classical)
  %19 = mul i32 %18, %3    ; IR: %21 = mul i32 %20, %3  (classical)
  %20 = call i32 @cqrt_alloc_i32(i32 %19)    ; IR: store i32 %21, ptr %19  [the seed of the classical value i * c: the store's value rail, KEPT with it (rules 5, 7)]
  call void @cqrt_qram_store_i32_hl(i32 %5, i64 %17, i32 %20)    ; IR: store i32 %21, ptr %19, align 4  [a kept store at a classical address: its tape slot and its seed stay (rule 5 sentence 3); classical-valued, the cells stay HOST]
  %21 = add nuw nsw i64 %15, 1    ; IR: %22 = add nuw nsw i64 %18, 1  (classical)
  %22 = icmp eq i64 %21, %13    ; IR: %23 = icmp eq i64 %22, %10  (classical bound)
  br i1 %22, label %23, label %14    ; IR: br i1 %23, label %11, label %17

23:
  %24 = call i32 @cq_template_urem_i32_hl(i32 %6, i32 %2)    ; IR: %12 = urem i32 %5, %2
  %25 = call i32 @cq_template_zext_i32_to_i64(i32 %24)    ; IR: %13 = zext i32 %12 to i64
  %26 = call i32 @cq_template_mul_i64_hl(i32 %25, i64 4)    ; IR: %14 = getelementptr inbounds i32, ptr %7, i64 %13  [the tainted index scaled by the element size (rule 20)]
  %27 = call i32 @cq_template_add_i64_hl(i32 %26, i64 %10)    ; IR: %14 = getelementptr  [+ the classical part, the run-time base: the address rail of &a[x % n]]
  %28 = call i32 @cqrt_qram_load_i32(i32 %5, i32 %27)    ; IR: %15 = load i32, ptr %14, align 4  [a load at an address rail: fresh rail ^= the 4 cells; measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_hl_unc(i32 %27, i32 %26, i64 %10)    ; IR: uncompute %14  [the address rail: the load is its last reader (rule 20)]
  call void @cqrt_free(i32 %27)    ; IR: release the %14 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %26, i32 %25, i64 4)    ; IR: uncompute %14 (the scaled index)
  call void @cqrt_free(i32 %26)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %25, i32 %24)    ; IR: uncompute %13
  call void @cqrt_free(i32 %25)    ; IR: release the %13 rail (|0>)
  call void @cq_template_urem_i32_hl_unc(i32 %24, i32 %6, i32 %2)    ; IR: uncompute %12
  call void @cqrt_free(i32 %24)    ; IR: release the %12 rail (|0>)
  %29 = call i32 @cqrt_measure_i32(i32 %28)    ; IR: %16 = cq_measure_si32(%15)
  ret i32 %29    ; IR: ret i32 %16
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cq_template_urem_i32_hl(i32, i32)
declare void @cq_template_urem_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
