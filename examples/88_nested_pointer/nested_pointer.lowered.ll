; HAND-WRITTEN. Rules: 21, 20, 5 (Memory, sentences 1 and 3), 16, 7, 4, 3, 2; §1.3 (the bus, __cq_mem, __cq_alloc).
; Checked: a[0] + b[1] + *q (the add rail %47, measured -> %48) after p[(x >> 1) & 1] = v through p = tab[x & 1] and
; tab[(x >> 2) & 1] = &s.g, q = tab[1]; and the cells of a, b, s and tab read from the bus at exit. With b0, b1, b2 the
; low three bits of x: p = b0 ? &b : &a, the cell p[b1] = v; tab[b2] = &s.g; q = b2 ? &s.g : &b, so
; a[0] = (b0 == 0 && b1 == 0) ? v : 1, b[1] = (b0 == 1 && b1 == 1) ? v : 4, *q = b2 ? 6 : b[1].
; Clean: the three address chains (x & 1, its zext, the scaling by 8, the add of tab's address: %21..%24, uncomputed
; right after the un-copy of the load p it addresses; x >> 1, & 1, zext, the scaling by 4, the add of p: %26..%30, uncomputed right
; after the store p[j] = v; x >> 2, & 1, zext, the scaling by 8, the add of tab's address: %34..%38, uncomputed right
; after the store tab[k] = &s.g); the load copies q = tab[1] (%40), a[0] (%41), b[1] (%44) and *q (%46) and the sum
; a[0] + b[1] (%45), all uncomputed before the measurement: no memory version change follows the load of q.
; Kept: the user register x (%9); the result rail (%47, measured); by rule 5 sentence 3, for the shot: the tape slots of
; the seven stores (the initializers of a, b and s, tab[0] = &a, tab[1] = &b, p[j] = v, tab[k] = &s.g) and their seed
; value rails %11, %13, %15, %17, %20, %31, %39; by rule 5 sentence 1, the load copy p = tab[x & 1] (%25) is un-copied
; after its last reader (the _unc of the address rail p + 4 j) but left allocated (overtaken: the store p[j] = v, a
; memory version change, came between); its address chain (%21..%24) is uncomputed and freed after that un-copy.
; Rotations: (Ry, x, th, 1).
; A POINTER IS AN INTEGER (rule 21). a, b, s and tab are bus-resident (rule 20 (b)): the addresses of a, b and s.g are
; stored as VALUES (into tab) and tab is indexed by a rail, so each alloca is one __cq_alloc block at its program point
; and the lifetime markers are dropped (rule 16). Every store is a bus store and every load a bus load, one call per
; access at the width of its IR type: the initializer `store i64` of a, b and s is ONE qram_store_i64_hl of an i64 seed
; (rule 7), not two i32 stores. A pointer stored in a cell is its run-time address, an i64 seed (rule 21, nested
; pointers). pp = tab + (x & 1) is 64-bit template arithmetic (zext, mul by 8, add of tab's run-time address) into an
; address rail; p = *pp is qram_load_i64 at that rail: ONE 64-bit rail, the address of the next access as it stands.
; &p[j] is add_i64 of p and j scaled by 4; the store of v there is the plain qram_store_i32 at that rail: no object, no
; tag, no guard, no provenance. tab[k] = &s.g stores the classical address of s.g (s + 4, a seed) at the rail
; tab + 8 k. q = tab[1] is the bus load at the classical address tab + 8 (_hl), and *q is qram_load_i32 at the rail q.
; Nothing in the lowering asks which of a, b and s any pointer addresses, or whether two addresses are equal.
source_filename = "nested_pointer.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

%struct.S = type { i32, i32 }

define i32 @nested_pointer(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (called once, at function entry)
  %5 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %4 = alloca [2 x i32], align 8: a is bus-resident (its address is stored as a value)
  %6 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %5 = alloca [2 x i32], align 8: b is bus-resident (its address is stored as a value)
  %7 = call ptr @__cq_alloc(i64 8, i64 8)    ; IR: %6 = alloca %struct.S, align 8: s is bus-resident (the address of s.g is stored as a value)
  %8 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %7 = alloca [2 x ptr], align 16: tab is bus-resident (indexed by a rail)
  %9 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %8 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %9, double %1)    ; IR: %8 = cq_theta_ui32(%0, %1)  [Ry]
  %10 = ptrtoint ptr %5 to i64    ; IR: the run-time address of a (classical; llvm.lifetime.start dropped)
  %11 = call i32 @cqrt_alloc_i64(i64 8589934593)    ; IR: store i64 8589934593, ptr %4: the value seed (rule 7; kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %10, i32 %11)    ; IR: store i64 8589934593, ptr %4: a = {1, 2}  (one kept i64 store, classical address)
  %12 = ptrtoint ptr %6 to i64    ; IR: the run-time address of b (classical)
  %13 = call i32 @cqrt_alloc_i64(i64 17179869187)    ; IR: store i64 17179869187, ptr %5: the value seed (kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %12, i32 %13)    ; IR: store i64 17179869187, ptr %5: b = {3, 4}  (kept store)
  %14 = ptrtoint ptr %7 to i64    ; IR: the run-time address of s (classical)
  %15 = call i32 @cqrt_alloc_i64(i64 25769803781)    ; IR: store i64 25769803781, ptr %6: the value seed (kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %14, i32 %15)    ; IR: store i64 25769803781, ptr %6: s = {5, 6}  (kept store)
  %16 = ptrtoint ptr %8 to i64    ; IR: the run-time address of tab (classical)
  %17 = call i32 @cqrt_alloc_i64(i64 %10)    ; IR: store ptr %4, ptr %7: the pointer a is its address, an i64 seed (rules 7, 21; kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %16, i32 %17)    ; IR: store ptr %4, ptr %7: tab[0] = a  (kept store of an i64 cell value)
  %18 = getelementptr inbounds i8, ptr %8, i64 8    ; IR: %9 = getelementptr inbounds i8, ptr %7, i64 8  (classical)
  %19 = ptrtoint ptr %18 to i64    ; IR: the run-time address of tab[1] (classical)
  %20 = call i32 @cqrt_alloc_i64(i64 %12)    ; IR: store ptr %5, ptr %9: the pointer b, an i64 seed (kept with the store)
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 %19, i32 %20)    ; IR: store ptr %5, ptr %9: tab[1] = b  (kept store)
  %21 = call i32 @cq_template_and_i32_hl(i32 %9, i32 1)    ; IR: %10 = and i32 %8, 1
  %22 = call i32 @cq_template_zext_i32_to_i64(i32 %21)    ; IR: %11 = zext nneg i32 %10 to i64
  %23 = call i32 @cq_template_mul_i64_hl(i32 %22, i64 8)    ; IR: %12 = getelementptr inbounds ptr, ptr %7, i64 %11: the index scaled by the element size
  %24 = call i32 @cq_template_add_i64_hl(i32 %23, i64 %16)    ; IR: %12: plus tab's run-time address  [address rail pp = &tab[x & 1]]
  %25 = call i32 @cqrt_qram_load_i64(i32 %4, i32 %24)    ; IR: %13 = load ptr, ptr %12: p = *pp, a 64-bit rail holding an address (rule 21; an overtaken load copy)
  %26 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 1)    ; IR: %14 = lshr i32 %8, 1
  %27 = call i32 @cq_template_and_i32_hl(i32 %26, i32 1)    ; IR: %15 = and i32 %14, 1
  %28 = call i32 @cq_template_zext_i32_to_i64(i32 %27)    ; IR: %16 = zext nneg i32 %15 to i64
  %29 = call i32 @cq_template_mul_i64_hl(i32 %28, i64 4)    ; IR: %17 = getelementptr inbounds i32, ptr %13, i64 %16: the index scaled by the element size
  %30 = call i32 @cq_template_add_i64(i32 %25, i32 %29)    ; IR: %17: plus the address rail p  [address rail &p[(x >> 1) & 1]]  ; SPEC GAP: rule 20 names add_i64 for a tainted base but not the operand order of two rails (rule 4's handle-first does not decide it); the base is operand 0, as the gep writes it
  %31 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %17: the value seed v (rule 7; kept with the store)
  call void @cqrt_qram_store_i32(i32 %4, i32 %30, i32 %31)    ; IR: store i32 %2, ptr %17: p[(x >> 1) & 1] = v  (kept store at the address rail)
  call void @cq_template_add_i64_unc(i32 %30, i32 %25, i32 %29)    ; IR: uncompute %17 after the store (rule 5 sentence 3; p, a load copy, is now overtaken)
  call void @cqrt_free(i32 %30)    ; IR: release the %17 rail (|0>)
  call void @cqrt_qram_load_i64_unc(i32 %25, i32 %4, i32 %24)    ; IR: un-copy %13 (p) after its last reader, the _unc of %17; the store p[j] = v came between, so it is not freed (overtaken, rule 5 sentence 1)
  call void @cq_template_add_i64_hl_unc(i32 %24, i32 %23, i64 %16)    ; IR: uncompute %12, the address rail pp, after the un-copy of p, its last reader (rule 5 sentence 1)
  call void @cqrt_free(i32 %24)    ; IR: release the %12 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %23, i32 %22, i64 8)    ; IR: uncompute the scaled index
  call void @cqrt_free(i32 %23)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %22, i32 %21)    ; IR: uncompute %11
  call void @cqrt_free(i32 %22)    ; IR: release the %11 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %21, i32 %9, i32 1)    ; IR: uncompute %10
  call void @cqrt_free(i32 %21)    ; IR: release the %10 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %29, i32 %28, i64 4)    ; IR: uncompute the scaled index
  call void @cqrt_free(i32 %29)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %28, i32 %27)    ; IR: uncompute %16
  call void @cqrt_free(i32 %28)    ; IR: release the %16 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %27, i32 %26, i32 1)    ; IR: uncompute %15
  call void @cqrt_free(i32 %27)    ; IR: release the %15 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %26, i32 %9, i32 1)    ; IR: uncompute %14
  call void @cqrt_free(i32 %26)    ; IR: release the %14 rail (|0>)
  %32 = getelementptr inbounds i8, ptr %7, i64 4    ; IR: %18 = getelementptr inbounds i8, ptr %6, i64 4  (&s.g, classical)
  %33 = ptrtoint ptr %32 to i64    ; IR: the run-time address of s.g (classical)
  %34 = call i32 @cq_template_lshr_i32_hl(i32 %9, i32 2)    ; IR: %19 = lshr i32 %8, 2
  %35 = call i32 @cq_template_and_i32_hl(i32 %34, i32 1)    ; IR: %20 = and i32 %19, 1
  %36 = call i32 @cq_template_zext_i32_to_i64(i32 %35)    ; IR: %21 = zext nneg i32 %20 to i64
  %37 = call i32 @cq_template_mul_i64_hl(i32 %36, i64 8)    ; IR: %22 = getelementptr inbounds [2 x ptr], ptr %7, i64 0, i64 %21: the index scaled by the element size
  %38 = call i32 @cq_template_add_i64_hl(i32 %37, i64 %16)    ; IR: %22: plus tab's run-time address  [address rail &tab[(x >> 2) & 1]]
  %39 = call i32 @cqrt_alloc_i64(i64 %33)    ; IR: store ptr %18, ptr %22: the pointer &s.g, an i64 seed (kept with the store)
  call void @cqrt_qram_store_i64(i32 %4, i32 %38, i32 %39)    ; IR: store ptr %18, ptr %22: tab[(x >> 2) & 1] = &s.g  (kept store at the address rail)
  call void @cq_template_add_i64_hl_unc(i32 %38, i32 %37, i64 %16)    ; IR: uncompute %22 after the store (rule 5 sentence 3)
  call void @cqrt_free(i32 %38)    ; IR: release the %22 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %37, i32 %36, i64 8)    ; IR: uncompute the scaled index
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %36, i32 %35)    ; IR: uncompute %21
  call void @cqrt_free(i32 %36)    ; IR: release the %21 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %35, i32 %34, i32 1)    ; IR: uncompute %20
  call void @cqrt_free(i32 %35)    ; IR: release the %20 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %34, i32 %9, i32 2)    ; IR: uncompute %19
  call void @cqrt_free(i32 %34)    ; IR: release the %19 rail (|0>)
  %40 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 %19)    ; IR: %23 = load ptr, ptr %9: q = tab[1], a 64-bit address rail (classical address tab + 8)
  %41 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %10)    ; IR: %24 = load i32, ptr %4: a[0]
  %42 = getelementptr inbounds i8, ptr %6, i64 4    ; IR: %25 = getelementptr inbounds i8, ptr %5, i64 4  (&b[1], classical)
  %43 = ptrtoint ptr %42 to i64    ; IR: the run-time address of b[1] (classical)
  %44 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %43)    ; IR: %26 = load i32, ptr %25: b[1]
  %45 = call i32 @cq_template_add_i32(i32 %44, i32 %41)    ; IR: %27 = add nsw i32 %26, %24
  %46 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %40)    ; IR: %28 = load i32, ptr %23: *q, one bus load at the address rail q (no guard, no merge)
  %47 = call i32 @cq_template_add_i32(i32 %45, i32 %46)    ; IR: %29 = add nsw i32 %27, %28  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %46, i32 %4, i32 %40)    ; IR: un-copy %28 (no memory version change since the load)
  call void @cqrt_free(i32 %46)    ; IR: release the %28 rail (|0>)
  call void @cqrt_qram_load_i64_hl_unc(i32 %40, i32 %4, i64 %19)    ; IR: un-copy %23 (q), right after its last reader, the un-copy of *q
  call void @cqrt_free(i32 %40)    ; IR: release it (|0>)
  call void @cq_template_add_i32_unc(i32 %45, i32 %44, i32 %41)    ; IR: uncompute %27
  call void @cqrt_free(i32 %45)    ; IR: release the %27 rail (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %44, i32 %4, i64 %43)    ; IR: un-copy %26 (b[1])
  call void @cqrt_free(i32 %44)    ; IR: release it (|0>)
  call void @cqrt_qram_load_i32_hl_unc(i32 %41, i32 %4, i64 %10)    ; IR: un-copy %24 (a[0])
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  %48 = call i32 @cqrt_measure_i32(i32 %47)    ; IR: %30 = cq_measure_si32(%29)  (llvm.lifetime.end x4 dropped: bus-resident objects)
  ret i32 %48    ; IR: ret i32 %30
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare void @cqrt_qram_store_i64(i32, i32, i32)
declare void @cqrt_qram_store_i32(i32, i32, i32)
declare i32 @cqrt_qram_load_i64(i32, i32)
declare void @cqrt_qram_load_i64_unc(i32, i32, i32)
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
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
declare i32 @cq_template_add_i64(i32, i32)
declare void @cq_template_add_i64_unc(i32, i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
