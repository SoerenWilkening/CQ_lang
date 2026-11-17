; HAND-WRITTEN. Rules: 21, 20, 26, 9, 5, 4, 7, 16, 2.
; Checked: n.p[n.w] (the load copy %44, measured -> %45): with g = (x > k) (signed), n.p = g ? bufA : bufB and
; n.w = x & 3, the value is g ? a + (x & 3) : b + (x & 3); and the cells of bufA and bufB at exit, read from the bus at
; the blocks' addresses: bufA[i] = a + i, bufB[i] = b + i (no store reaches them after the initializer).
; Clean: the compare flag %38; the address rail n.p = select(flag, &bufA, &bufB) (%39); n.w (%40); the address chain
; of &n.p[n.w] (its zext %41, the scaling by 4 %42, the add of n.p %43), uncomputed and freed right after the load
; it addresses, then n.w, n.p and the flag.
; Kept: the register x (%37, rotated); the load copy n.p[n.w] (%44, measured: rule 2); by rule 5, for the shot: the
; tape slots of the eight initializer stores bufA[0..3] = a .. a + 3 and bufB[0..3] = b .. b + 3, and their seed value
; rails %10, %14, %18, %22 (a .. a + 3) and %24, %28, %32, %36 (b .. b + 3) (rule 7; classical-valued, so no qubit, §0).
; Rotations: (Ry, x, tx, 1).
; Expected: struct_quantum_ptr_field(0, .5, 1, 10, 20): Ry(.5) on each of the 32 qubits of x = 0 flips each bit
; independently with p = sin^2(.25) = 0.061209; everything after the rotation is a basis permutation. x > 1 iff bit 31
; is 0 and some bit 1..30 is 1. Measured value: 10 with 0.694886, 11 0.045306, 12 0.053945, 13 0.003517 (bufA,
; a + (x & 3)); 20 with 0.186443, 21 0.012156, 22 0.003517, 23 0.000229 (bufB, b + (x & 3)).
; A POINTER IS AN INTEGER (rule 21). `struct node n = { (x > k) ? bufA : bufB, x & 3 }` never reaches memory (-O1
; scalarises it), so by rule 26 the struct is the tuple of its fields: n.p is the select of two pointers under the
; quantum flag x > k, i.e. ONE 64-bit address rail select_i64_ll(flag, &bufA, &bufB) with both incomings entering as
; their classical run-time i64 addresses (rule 21, Merge); n.w is the rail x & 3. Nothing about bufA or bufB belongs to
; n.p: no tag, no object table, no extent. BOTH ARRAYS ARE BUS-RESIDENT (rule 20 (b)): each alloca has the pointer
; select among its users, which is none of the host-resident users, so each is one __cq_alloc(16, 16) block at its
; program point, no alloca remains and the lifetime markers are dropped (rule 16). The initializer stores are bus
; stores at classical addresses (qram_store_i32_hl), each value first its seed alloc_i32(v) (rule 7); value, address
; and control are classical-valued, so the cells stay HOST (§1.3). The getelementptr &n.p[n.w] has a tainted base and
; a tainted index, so it is 64-bit template arithmetic into an address rail (rule 20): -O1's zext of the index to i64
; (the zext template), mul_i64_hl by the element size 4, and add_i64 of the base rail n.p (no classical part remains).
; The dereference is ONE qram_load_i32 at that address rail (rule 21: no guard, no bounds check, no per-object read):
; the QRAM query decides which block is read. The load copy is measured, so it is never un-copied (rules 2, 5); its
; address rail's last reader is the load, so the chain is uncomputed right after it (rule 20), then n.w (its last
; reader was the zext's _unc), n.p (the add's _unc) and the flag (the select's _unc), LIFO.
source_filename = "struct_quantum_ptr_field.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @struct_quantum_ptr_field(i32 noundef %0, double noundef %1, i32 noundef %2, i32 noundef %3, i32 noundef %4) {
  %6 = call i32 @__cq_mem()    ; IR: (function entry) the bus M (§5: once per function that accesses the bus)
  %7 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %6 = alloca [4 x i32], align 16  [bufA, bus-resident: its address enters the pointer select (rules 16, 20)]
  %8 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = alloca [4 x i32], align 16  [bufB, bus-resident]
  %9 = ptrtoint ptr %7 to i64    ; IR: llvm.lifetime.start(16, %6) dropped (rule 16); the run-time address of bufA (classical)
  %10 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: store i32 %3, ptr %6: the value seed a (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %9, i32 %10)    ; IR: store i32 %3, ptr %6  (bufA[0] = a: kept store at a classical address)
  %11 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %8 = getelementptr inbounds i8, ptr %6, i64 4  (classical)
  %12 = ptrtoint ptr %11 to i64    ; IR: %8 as its run-time address (classical)
  %13 = add nsw i32 %3, 1    ; IR: %9 = add nsw i32 %3, 1  (classical)
  %14 = call i32 @cqrt_alloc_i32(i32 %13)    ; IR: store i32 %9, ptr %8: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %12, i32 %14)    ; IR: store i32 %9, ptr %8  (bufA[1]: kept store)
  %15 = getelementptr inbounds i8, ptr %7, i64 8    ; IR: %10 = getelementptr inbounds i8, ptr %6, i64 8  (classical)
  %16 = ptrtoint ptr %15 to i64    ; IR: %10 as its run-time address (classical)
  %17 = add nsw i32 %3, 2    ; IR: %11 = add nsw i32 %3, 2  (classical)
  %18 = call i32 @cqrt_alloc_i32(i32 %17)    ; IR: store i32 %11, ptr %10: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %16, i32 %18)    ; IR: store i32 %11, ptr %10  (bufA[2]: kept store)
  %19 = getelementptr inbounds i8, ptr %7, i64 12    ; IR: %12 = getelementptr inbounds i8, ptr %6, i64 12  (classical)
  %20 = ptrtoint ptr %19 to i64    ; IR: %12 as its run-time address (classical)
  %21 = add nsw i32 %3, 3    ; IR: %13 = add nsw i32 %3, 3  (classical)
  %22 = call i32 @cqrt_alloc_i32(i32 %21)    ; IR: store i32 %13, ptr %12: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %20, i32 %22)    ; IR: store i32 %13, ptr %12  (bufA[3]: kept store)
  %23 = ptrtoint ptr %8 to i64    ; IR: llvm.lifetime.start(16, %7) dropped (rule 16); the run-time address of bufB (classical)
  %24 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: store i32 %4, ptr %7: the value seed b (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %23, i32 %24)    ; IR: store i32 %4, ptr %7  (bufB[0] = b: kept store)
  %25 = getelementptr inbounds i8, ptr %8, i64 4    ; IR: %14 = getelementptr inbounds i8, ptr %7, i64 4  (classical)
  %26 = ptrtoint ptr %25 to i64    ; IR: %14 as its run-time address (classical)
  %27 = add nsw i32 %4, 1    ; IR: %15 = add nsw i32 %4, 1  (classical)
  %28 = call i32 @cqrt_alloc_i32(i32 %27)    ; IR: store i32 %15, ptr %14: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %26, i32 %28)    ; IR: store i32 %15, ptr %14  (bufB[1]: kept store)
  %29 = getelementptr inbounds i8, ptr %8, i64 8    ; IR: %16 = getelementptr inbounds i8, ptr %7, i64 8  (classical)
  %30 = ptrtoint ptr %29 to i64    ; IR: %16 as its run-time address (classical)
  %31 = add nsw i32 %4, 2    ; IR: %17 = add nsw i32 %4, 2  (classical)
  %32 = call i32 @cqrt_alloc_i32(i32 %31)    ; IR: store i32 %17, ptr %16: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %30, i32 %32)    ; IR: store i32 %17, ptr %16  (bufB[2]: kept store)
  %33 = getelementptr inbounds i8, ptr %8, i64 12    ; IR: %18 = getelementptr inbounds i8, ptr %7, i64 12  (classical)
  %34 = ptrtoint ptr %33 to i64    ; IR: %18 as its run-time address (classical)
  %35 = add nsw i32 %4, 3    ; IR: %19 = add nsw i32 %4, 3  (classical)
  %36 = call i32 @cqrt_alloc_i32(i32 %35)    ; IR: store i32 %19, ptr %18: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i32_hl(i32 %6, i64 %34, i32 %36)    ; IR: store i32 %19, ptr %18  (bufB[3]: kept store)
  %37 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %20 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %37, double %1)    ; IR: %20 = cq_theta_si32(%0, %1)  [Ry]
  %38 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %37, i32 %2)    ; IR: %21 = icmp sgt i32 %20, %2  [the select's flag]
  %39 = call i32 @cq_template_select_i64_ll(i32 %38, i64 %9, i64 %23)    ; IR: %22 = select i1 %21, ptr %6, ptr %7  [n.p: ONE 64-bit address rail, flag ? &bufA : &bufB (rule 21)]
  %40 = call i32 @cq_template_and_i32_hl(i32 %37, i32 3)    ; IR: %23 = and i32 %20, 3  [n.w]
  %41 = call i32 @cq_template_zext_i32_to_i64(i32 %40)    ; IR: %24 = zext nneg i32 %23 to i64
  %42 = call i32 @cq_template_mul_i64_hl(i32 %41, i64 4)    ; IR: %25 = getelementptr inbounds i32, ptr %22, i64 %24  [the tainted index scaled by the element size (rule 20)]
  %43 = call i32 @cq_template_add_i64(i32 %39, i32 %42)    ; IR: %25: plus the base rail n.p  [the address rail of &n.p[n.w]]
  %44 = call i32 @cqrt_qram_load_i32(i32 %6, i32 %43)    ; IR: %26 = load i32, ptr %25, align 4  [ONE bus load at the address rail (rule 21); measured below, so never un-copied (rules 2, 5)]
  call void @cq_template_add_i64_unc(i32 %43, i32 %39, i32 %42)    ; IR: uncompute %25  [its last reader was the load (rule 20)]
  call void @cqrt_free(i32 %43)    ; IR: release the %25 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %42, i32 %41, i64 4)    ; IR: uncompute %25 (the scaled index)
  call void @cqrt_free(i32 %42)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %41, i32 %40)    ; IR: uncompute %24
  call void @cqrt_free(i32 %41)    ; IR: release the %24 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %40, i32 %37, i32 3)    ; IR: uncompute %23 (n.w)
  call void @cqrt_free(i32 %40)    ; IR: release the %23 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %39, i32 %38, i64 %9, i64 %23)    ; IR: uncompute n.p %22
  call void @cqrt_free(i32 %39)    ; IR: release the %22 rail (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %38, i32 %37, i32 %2)    ; IR: uncompute %21
  call void @cqrt_free(i32 %38)    ; IR: release the %21 rail (|0>)
  %45 = call i32 @cqrt_measure_i32(i32 %44)    ; IR: %27 = cq_measure_si32(%26)
  ret i32 %45    ; IR: llvm.lifetime.end(16, %7), llvm.lifetime.end(16, %6) dropped (rule 16); ret i32 %27
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
