; HAND-WRITTEN. Rules: 21, 20, 16, 7, 5, 4, 2.
; Checked: *q + *r (measured, %46 -> %47), q = align_down(&a[x & 7], 16), r = align_down(&a[x & 7] + 12 bytes, 16), with
; P = the block's run-time address (16-aligned, __cq_alloc) and c = x & 7: q = P + 16 * (c >> 2) and r = P + 16 *
; ((c + 3) >> 2), so *q + *r = 2v (c = 0), 2v + 4 (c = 1..3), 2v + 8 (c = 4), and for c = 5..7 r = P + 32, one past
; the end of a: *r reads the 4 host bytes there (the C program's own undefined behaviour; 0 per §2 when they are not
; readable host memory), so *q + *r = v + 4 + H with H that host word. Memory: the 8 cells of a hold v .. v + 7 at exit.
; Clean: the pointer-arithmetic rails (x & 7, its zext, the shl by 2; the address rail p; the masked address q; p + 12;
; the masked address r), and the two load copies *q and *r (rule 5 sentence 1: no memory version change follows them).
; Kept: the user register x; the result rail (measured). Rule 5: the 8 seeds v + j (%8, %12, %16, ..., %36, each the
; value rail of a kept store; classical-valued, no qubit) and the tape slots of the 8 i32 stores (backend rails).
; Rotations: (Ry, x, th, 1).
; Expected: ptrmask_q(0, .5, 3): Ry(.5) on every qubit of x = 0 flips each bit with s = sin^2(.25) = 0.061209, so
; P(c = 0) = 0.827384 (result 6), P(c = 1..3) = 0.111407 (result 10), P(c = 4) = 0.053945 (result 14), P(c = 5..7) =
; 0.007264 (result 7 + H, H the host word at P + 32).
; ONE BUS (rule 20): a's alloca has a getelementptr with a tainted index among its users, so it is BUS-RESIDENT: its
; block is __cq_alloc(32, 16) at the alloca's program point (rule 16), no alloca remains and the lifetime markers are
; dropped. m = __cq_mem() is called once, at entry (§5). The eight initializer stores are bus stores at classical
; addresses (the constant getelementptrs stay, spelled ptrtoint as their run-time i64): each stores the seed
; alloc_i32(v + j) (rule 7) and is KEPT (rule 5 sentence 3); every value, address and control is classical-valued, so
; they write the host bytes and the cells stay HOST (§1.3).
; POINTERS ARE INTEGERS (rule 21): p = a + (x & 7) is ONE 64-bit address rail: the index rail (-O1's zext to i64),
; shl_i64_hl by log2 of the element size 4, add_i64_hl of the classical base P (rule 20). llvm.ptrmask(p, -16) is
; rule 4's integer template and_i64_hl(p, -16) on the address rail (rule 21: ptrtoint/inttoptr are identities, so the
; mask acts on the address itself); %24 = p + 12 bytes is add_i64_hl(p, 12) (element size 1, no scale). Nothing is
; known about what p points into: no object, base, extent or provenance is carried, no cell index is rebuilt, no range
; is tested, and the `align 16` on the ptrmask results is never consulted. Each dereference is ONE qram_load_i32 at
; its address rail (rule 21), with no guard and no bounds check.
; UNCOMPUTE (rule 5): the add is the last consumer of both load copies and is measured; no memory version change follows,
; so each copy is un-copied right after the add (at the cells' values at the load) and freed; then each address rail,
; which outlives its load's _unc (rule 20), and the chain below it, in reverse.
source_filename = "ptrmask.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptrmask_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call ptr @__cq_alloc(i64 32, i64 16)    ; IR: %4 = alloca [8 x i32], align 16  [bus-resident: one zeroed block, no alloca remains (rules 16, 20)]
  %6 = ptrtoint ptr %5 to i64    ; P = the block's run-time address, a classical i64 (rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %4  [seed v: the store's value rail, kept with it (rule 7); llvm.lifetime.start dropped (rule 16)]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %8)    ; IR: store i32 %2, ptr %4  (a[0] = v: a kept store at a classical address; classical-valued, the cells stay HOST)
  %9 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %6 = &a[1]  (nothing tainted: the gep stays)
  %10 = add nsw i32 %2, 1    ; IR: %7 = add nsw i32 %2, 1  (classical)
  %11 = ptrtoint ptr %9 to i64    ; IR: %6 as its run-time address
  %12 = call i32 @cqrt_alloc_i32(i32 %10)    ; IR: store i32 %7, ptr %6  [seed v + 1]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %11, i32 %12)    ; IR: store i32 %7, ptr %6  (a[1], kept)
  %13 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %8 = &a[2]
  %14 = add nsw i32 %2, 2    ; IR: %9 = add nsw i32 %2, 2  (classical)
  %15 = ptrtoint ptr %13 to i64    ; IR: %8 as its run-time address
  %16 = call i32 @cqrt_alloc_i32(i32 %14)    ; IR: store i32 %9, ptr %8  [seed v + 2]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %15, i32 %16)    ; IR: store i32 %9, ptr %8  (a[2], kept)
  %17 = getelementptr inbounds i8, ptr %5, i64 12    ; IR: %10 = &a[3]
  %18 = add nsw i32 %2, 3    ; IR: %11 = add nsw i32 %2, 3  (classical)
  %19 = ptrtoint ptr %17 to i64    ; IR: %10 as its run-time address
  %20 = call i32 @cqrt_alloc_i32(i32 %18)    ; IR: store i32 %11, ptr %10  [seed v + 3]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %19, i32 %20)    ; IR: store i32 %11, ptr %10  (a[3], kept)
  %21 = getelementptr inbounds i8, ptr %5, i64 16    ; IR: %12 = &a[4]
  %22 = add nsw i32 %2, 4    ; IR: %13 = add nsw i32 %2, 4  (classical)
  %23 = ptrtoint ptr %21 to i64    ; IR: %12 as its run-time address
  %24 = call i32 @cqrt_alloc_i32(i32 %22)    ; IR: store i32 %13, ptr %12  [seed v + 4]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %23, i32 %24)    ; IR: store i32 %13, ptr %12  (a[4], kept)
  %25 = getelementptr inbounds i8, ptr %5, i64 20    ; IR: %14 = &a[5]
  %26 = add nsw i32 %2, 5    ; IR: %15 = add nsw i32 %2, 5  (classical)
  %27 = ptrtoint ptr %25 to i64    ; IR: %14 as its run-time address
  %28 = call i32 @cqrt_alloc_i32(i32 %26)    ; IR: store i32 %15, ptr %14  [seed v + 5]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %27, i32 %28)    ; IR: store i32 %15, ptr %14  (a[5], kept)
  %29 = getelementptr inbounds i8, ptr %5, i64 24    ; IR: %16 = &a[6]
  %30 = add nsw i32 %2, 6    ; IR: %17 = add nsw i32 %2, 6  (classical)
  %31 = ptrtoint ptr %29 to i64    ; IR: %16 as its run-time address
  %32 = call i32 @cqrt_alloc_i32(i32 %30)    ; IR: store i32 %17, ptr %16  [seed v + 6]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %31, i32 %32)    ; IR: store i32 %17, ptr %16  (a[6], kept)
  %33 = getelementptr inbounds i8, ptr %5, i64 28    ; IR: %18 = &a[7]
  %34 = add nsw i32 %2, 7    ; IR: %19 = add nsw i32 %2, 7  (classical)
  %35 = ptrtoint ptr %33 to i64    ; IR: %18 as its run-time address
  %36 = call i32 @cqrt_alloc_i32(i32 %34)    ; IR: store i32 %19, ptr %18  [seed v + 7]
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %35, i32 %36)    ; IR: store i32 %19, ptr %18  (a[7], kept)
  %37 = call i32 @cq_template_and_i32_hl(i32 %7, i32 7)    ; IR: %20 = and i32 %5, 7
  %38 = call i32 @cq_template_zext_i32_to_i64(i32 %37)    ; IR: %21 = zext nneg i32 %20 to i64
  %39 = call i32 @cq_template_shl_i64_hl(i32 %38, i64 2)    ; IR: %22 = getelementptr inbounds i32, ptr %4, i64 %21  [the tainted index scaled by the element size 4 (rule 20)]
  %40 = call i32 @cq_template_add_i64_hl(i32 %39, i64 %6)    ; IR: %22 = getelementptr  [+ the classical base P: the address rail p (rule 21)]
  %41 = call i32 @cq_template_and_i64_hl(i32 %40, i64 -16)    ; IR: %23 = llvm.ptrmask(%22, -16)  [the integer mask on the address rail (rules 4, 21): q]
  %42 = call i32 @cq_template_add_i64_hl(i32 %40, i64 12)    ; IR: %24 = getelementptr inbounds i8, ptr %22, i64 12  [element size 1: p + 12]
  %43 = call i32 @cq_template_and_i64_hl(i32 %42, i64 -16)    ; IR: %25 = llvm.ptrmask(%24, -16)  [r]
  %44 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %41)    ; IR: %26 = load i32, ptr %23  [*q: ONE load at the address rail q, no guard (rule 21)]
  %45 = call i32 @cqrt_qram_load_i32(i32 %4, i32 %43)    ; IR: %27 = load i32, ptr %25  [*r: ONE load at the address rail r; P + 32 for c = 5..7 reads the host bytes past a (§2)]  ; the cells are HOST (§1.3: a HOST cell reads the host byte at its address), so for c = 5..7 *r is the host word H at P + 32, one past a: the C program's own UB, with a value fixed by the host layout and not by the spec; §6 compares *q + *r for c = 0..4 only
  %46 = call i32 @cq_template_add_i32(i32 %45, i32 %44)    ; IR: %28 = add nsw i32 %27, %26  [result rail]
  call void @cqrt_qram_load_i32_unc(i32 %45, i32 %4, i32 %43)    ; IR: un-copy %27 (rule 5 sentence 1: no memory version change since the load)  ; SPEC GAP: sentence 1 asks for the last consumer's uncompute, and the consumer %28 is measured (never uncomputed); read as 195/199: un-copied right after the add, before the measurement
  call void @cqrt_free(i32 %45)    ; IR: release the %27 rail (|0>)
  call void @cqrt_qram_load_i32_unc(i32 %44, i32 %4, i32 %41)    ; IR: un-copy %26
  call void @cqrt_free(i32 %44)    ; IR: release the %26 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %43, i32 %42, i64 -16)    ; IR: uncompute %25 (the address rail r, after its load's _unc)
  call void @cqrt_free(i32 %43)    ; IR: release the %25 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %42, i32 %40, i64 12)    ; IR: uncompute %24
  call void @cqrt_free(i32 %42)    ; IR: release the %24 rail (|0>)
  call void @cq_template_and_i64_hl_unc(i32 %41, i32 %40, i64 -16)    ; IR: uncompute %23 (the address rail q)
  call void @cqrt_free(i32 %41)    ; IR: release the %23 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %40, i32 %39, i64 %6)    ; IR: uncompute %22 (the address rail p)
  call void @cqrt_free(i32 %40)    ; IR: release the %22 rail (|0>)
  call void @cq_template_shl_i64_hl_unc(i32 %39, i32 %38, i64 2)    ; IR: uncompute %22 (the scaled index)
  call void @cqrt_free(i32 %39)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %38, i32 %37)    ; IR: uncompute %21
  call void @cqrt_free(i32 %38)    ; IR: release the %21 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %37, i32 %7, i32 7)    ; IR: uncompute %20
  call void @cqrt_free(i32 %37)    ; IR: release the %20 rail (|0>)
  %47 = call i32 @cqrt_measure_i32(i32 %46)    ; IR: %29 = cq_measure_si32(%28)
  ret i32 %47    ; IR: llvm.lifetime.end(32, %4) dropped (rule 16); ret i32 %29
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32(i32, i32)
declare void @cqrt_qram_load_i32_unc(i32, i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_shl_i64_hl(i32, i64)
declare void @cq_template_shl_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_and_i64_hl(i32, i64)
declare void @cq_template_and_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32(i32, i32)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
