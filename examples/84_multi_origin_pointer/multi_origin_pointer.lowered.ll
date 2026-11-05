; HAND-WRITTEN. Rules: 21, 20, 5, 9, 8, 7, 16, 4, 2.
; Checked: a[0] + b[1], the returned sum (the add rail %26 -> %27). The store reaches a[0] iff B and x & 1 == 1 and
; (x >> 1) & 1 == 0, b[1] iff B and x & 1 == 0 and (x >> 1) & 1 == 1 (B = x > 5; a[1] and b[0] are not read), so the sum
; is 1 + 4 = 5, v + 4 or 1 + v.
; Clean: the arm's pure chain: x & 1 (%13), the flag (x & 1) == 0 (%14), the address rail p = select(flag, b, a) (%15),
; x >> 1 (%16), the index (%17) and the gep chain zext / mul / add (%18..%20), all uncomputed and freed right after the
; store, their last reader (rule 20); the two fixed-address load copies a[0] and b[1] (%22, %25), un-copied after the add
; (no memory version change follows them, rule 5 sentence 1).
; Kept: x (%9, the rotated register); the sum (%26, measured); the predicate B = x > 5 (%12), the control rail of the
; kept store (rules 5, 8); the seed v (%21, the value rail of the kept store); the seeds 8589934593 and 17179869187
; (%10, %11, the value rails of the two kept initializer stores, rule 7); the tape slots of the three stores (store i64
; 8589934593, ptr %4; store i64 17179869187, ptr %5; store i32 %2, ptr %15).
; Rotations: (Ry, x, th, 1).
; ONE BUS (rules 20, 21). Both allocas are BUS-RESIDENT: a select of their addresses under a quantum flag is among
; their users, which no clause of rule 20 (b) allows. So each is __cq_alloc(8, 8) at its program point (rule 16), no
; alloca remains and the lifetime markers are dropped; m = __cq_mem() is called once, at entry (§5). The initializers
; are the -O1 i64 stores, each ONE qram_store_i64_hl at the block's classical run-time address, its value the seed
; alloc_i64(lit) (rules 7, 20); every value, address and control is classical-valued, so the cells stay HOST.
; A POINTER IS AN INTEGER (rule 21): p = (x & 1) ? a : b is select_i64_ll on the quantum flag (IR %10, lowered %14) over the two blocks'
; classical i64 addresses, ONE 64-bit address rail; nothing about a, b, objects or origins belongs to it. The arm's
; pure code is hoisted and computed unguarded (rule 9): the index chain and the gep, 64-bit template arithmetic into an
; address rail (rule 20): -O1's zext to i64, mul_i64_hl by the element size 4, add_i64 of the address rail p (a rail,
; so no _hl). The store p[(x >> 1) & 1] = v is ONE bus access, qram_store_i32_controlled under the block predicate B
; (rule 5: a bus access is never hoisted), with no guard per origin and no bounds check (rule 21); the classical v is
; first the seed alloc_i32(v). The store is KEPT: its tape slot, its value rail and its control rail B stay (rule 5
; sentence 3, rule 8), so B is never uncomputed. The address rail and its whole chain are template garbage, uncomputed
; right after the store. After the join no quantum predicate is in scope: a[0] and b[1] are plain bus loads at the
; classical addresses a and b + 4 (qram_load_i32_hl; &b[1] is the untainted gep, which stays, and its ptrtoint, %23 and
; %24, rule 20), un-copied by their _unc after the add, their last reader.
source_filename = "multi_origin_pointer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptr_select_store(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %4 = alloca [2 x i32], align 8  (a)  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (classical, rule 21)
  %7 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %5 = alloca [2 x i32], align 8  (b)  [bus-resident]
  %8 = ptrtoint ptr %7 to i64    ; IR: %5 as its run-time address (classical)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %10 = call i32 @cqrt_alloc_i64(i64 8589934593)    ; IR: store i64 8589934593, ptr %4  (a = {1, 2})  [the stored value as a seed rail, kept with its store: rule 7; llvm.lifetime.start(8, %4) dropped (rule 16)]
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %6, i32 %10)    ; IR: store i64 8589934593, ptr %4  [ONE i64 access at a: a kept store (rule 5); classical-valued, the cells stay HOST]
  %11 = call i32 @cqrt_alloc_i64(i64 17179869187)    ; IR: store i64 17179869187, ptr %5  (b = {3, 4})  [seed rail, kept with its store; llvm.lifetime.start(8, %5) dropped]
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %8, i32 %11)    ; IR: store i64 17179869187, ptr %5  [a kept store at b]
  %12 = call i32 @cq_template_icmp_ugt_i32_hl(i32 %9, i32 5)    ; IR: %7 = icmp ugt i32 %6, 5  [predicate B of block %8; it controls the kept store, so it is kept (rules 5, 8)]
  %13 = call i32 @cq_template_and_i32_hl(i32 %9, i32 1)    ; IR: %9 = and i32 %6, 1
  %14 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)    ; IR: %10 = icmp eq i32 %9, 0
  %15 = call i32 @cq_template_select_i64_ll(i32 %14, i64 %8, i64 %6)    ; IR: %11 = select i1 %10, ptr %5, ptr %4  [rule 21: the address rail p = flag ? b : a, the classical addresses as literals]
  %16 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 1)    ; IR: %12 = lshr i32 %6, 1
  %17 = call i32 @cq_template_and_i32_hl(i32 %16, i32 1)    ; IR: %13 = and i32 %12, 1
  %18 = call i32 @cq_template_zext_i32_to_i64(i32 %17)    ; IR: %14 = zext nneg i32 %13 to i64  [the index brought to i64 (rule 20)]
  %19 = call i32 @cq_template_mul_i64_hl(i32 %18, i64 4)    ; IR: %15 = getelementptr inbounds i32, ptr %11, i64 %14  [the tainted index scaled by the element size 4]
  %20 = call i32 @cq_template_add_i64(i32 %19, i32 %15)    ; IR: %15 = getelementptr  [+ the address rail p: the address rail of &p[(x >> 1) & 1]]
  %21 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %15: the classical value v as a seed rail (rule 7), the value rail of the kept store
  call void @cqrt_qram_store_i32_controlled(i32 %12, i32 %4, i32 %20, i32 %21)    ; IR: store i32 %2, ptr %15  [ONE bus access at the address rail under B (rule 5); kept: its slot, v and B stay]
  call void @cq_template_add_i64_unc(i32 %20, i32 %19, i32 %15)    ; IR: uncompute %15  [the address rail, its store its last reader (rule 20)]
  call void @cqrt_free(i32 %20)    ; IR: release the %15 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %19, i32 %18, i64 4)    ; IR: uncompute %15 (the scaled index)
  call void @cqrt_free(i32 %19)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %18, i32 %17)    ; IR: uncompute %14
  call void @cqrt_free(i32 %18)    ; IR: release the %14 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %17, i32 %16, i32 1)    ; IR: uncompute %13
  call void @cqrt_free(i32 %17)    ; IR: release the %13 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %16, i32 %9, i32 1)    ; IR: uncompute %12
  call void @cqrt_free(i32 %16)    ; IR: release the %12 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %15, i32 %14, i64 %8, i64 %6)    ; IR: uncompute the address rail p (%11)
  call void @cqrt_free(i32 %15)    ; IR: release the %11 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %14, i32 %13, i32 0)    ; IR: uncompute %10
  call void @cqrt_free(i32 %14)    ; IR: release the %10 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %13, i32 %9, i32 1)    ; IR: uncompute %9
  call void @cqrt_free(i32 %13)    ; IR: release the %9 rail (|0>)
  %22 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %6)    ; IR: %17 = load i32, ptr %4  (a[0], no quantum predicate in scope: a plain bus load at a classical address)
  %23 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %18 = getelementptr inbounds i8, ptr %5, i64 4  (&b[1]: nothing tainted, the gep stays on the block, rule 20)
  %24 = ptrtoint ptr %23 to i64    ; IR: %18 as its run-time address (classical)
  %25 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %24)    ; IR: %19 = load i32, ptr %18  (b[1])
  %26 = call i32 @cq_template_add_i32(i32 %25, i32 %22)    ; IR: %20 = add nsw i32 %19, %17  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %25, i32 %4, i64 %24)    ; IR: un-copy %19 (its last reader done, no memory version change since the load: rule 5 sentence 1)
  call void @cqrt_free(i32 %25)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %22, i32 %4, i64 %6)    ; IR: un-copy %17
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  %27 = call i32 @cqrt_measure_i32(i32 %26)    ; IR: %21 = cq_measure_si32(%20)
  ret i32 %27    ; IR: llvm.lifetime.end(8, %5), llvm.lifetime.end(8, %4) dropped (rule 16); ret i32 %21
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_controlled(i32, i32, i32, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32(i32, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_ugt_i32_hl(i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
