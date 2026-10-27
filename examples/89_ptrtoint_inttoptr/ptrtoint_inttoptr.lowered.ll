; HAND-WRITTEN. Rules: 21, 20, 4, 9, 5, 2.
; Checked: *q + v, q = (int *)((uintptr_t)((x & 1) ? a : b) ^ (x & 4)) (measured): (x & 1 ? a : b)[(x & 4) >> 2] + v.
; Clean: every pointer-arithmetic rail (the tag select, both object flags, the base select, the flat address, the
; rebuilt byte offset and cell index), both QROM loads and their merge select.
; Kept: the user register x; the result rail (measured).
; Rotations: Ry(th) on x.
; A quantum pointer is a fat pointer (tag, idx) (84, rule 21): p = (x & 1) ? a : b has the quantum tag select(x & 1 == 0,
; 2, 1) over the object table (object 1 = a (%4), object 2 = b (%5); 8 bytes, 2 i32 cells each) and the classical cell idx
; 0. ptrtoint and inttoptr are the two crossings between the fat form and the flat host address:
;   ptrtoint  u = base[tag] + 4 * idx  a select on the object flag over the classical bases (provenance {a, b}: b is the
;                                      complement, no NULL arm), plus the byte offset of idx (nothing here: idx = 0);
;   inttoptr  of an integer DERIVED FROM ptrtoint(p) keeps p's provenance (rule 21, LLVM's rule): tag = p's tag (the
;             same rail), idx = (u' - base[tag]) / 4 with base[tag] the rail ptrtoint built: sub, then lshr by log2 4
;             and trunc to the logical i32 index rail. No range test: the result never depends on where the host placed
;             a and b (only an integer of unknown origin is decoded by range tests over the candidate objects).
; The integer arithmetic in between (`or disjoint` = the xor of the C source) is the ordinary i64 template (rule 4). The
; host addresses are classical runtime operands of the templates (the trace prints them as P<n>+<off>); a and b are
; 8-aligned, so `or disjoint` with x & 4 adds 0 or 4 bytes and the rebuilt cell index is (x & 4) >> 2, in range. That
; cell index is QUANTUM, so the deref is a quantum-offset access of each object in the provenance {a, b} (rule 21); a and
; b only ever hold classical values (their -O1 initializers), so by rule 20 each access is a QROM read over the object's
; current contents (cq_template_qrom_load_i32, length 2) and both arrays stay ordinary classical memory, never a QRAM.
; The pure per-object loads run unguarded and are merged by one select on the guard g_a = tag == 1 (block predicate:
; none), b the complement innermost (rule 9). Everything is uncomputed in reverse.
source_filename = "ptrtoint_inttoptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptr_roundtrip(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca [2 x i32], align 8    ; IR: %4 = alloca [2 x i32]  (object 1: a, classical memory: holds only classical values; base[1] = its host address)
  %5 = alloca [2 x i32], align 8    ; IR: %5 = alloca [2 x i32]  (object 2: b, classical memory; base[2])
  store i64 8589934593, ptr %4, align 8    ; IR: store i64 8589934593, ptr %4  (a = {1, 2}, classical)
  store i64 17179869187, ptr %5, align 8    ; IR: store i64 17179869187, ptr %5  (b = {3, 4}, classical)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %6 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %6 = cq_theta_ui32(%0, %1)  [Ry]
  %7 = ptrtoint ptr %4 to i64    ; IR: base[1] = &a  (classical, from the object table)
  %8 = ptrtoint ptr %5 to i64    ; IR: base[2] = &b  (classical)
  %9 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)    ; IR: %7 = and i32 %6, 1
  %10 = call i32 @cq_template_icmp_eq_i32_hl(i32 %9, i32 0)    ; IR: %8 = icmp eq i32 %7, 0
  %11 = call i32 @cq_template_select_i32_ll(i32 %10, i32 2, i32 1)    ; IR: %9 = select i1 %8, ptr %5, ptr %4  [the pointer's tag: b (2) or a (1); idx is the classical cell 0]
  %12 = call i32 @cq_template_icmp_eq_i32_hl(i32 %11, i32 1)    ; IR: %10 = ptrtoint ptr %9 to i64: the object flag g_a = tag == 1 (else b)
  %13 = call i32 @cq_template_select_i64_ll(i32 %12, i64 %7, i64 %8)    ; IR: %10 = ptrtoint ptr %9 to i64: base[tag] (base[1] when a, else base[2])  [the flat address base[tag] + 4 * idx; idx is the classical 0, so nothing is added]
  %14 = call i32 @cq_template_and_i32_hl(i32 %6, i32 4)    ; IR: %11 = and i32 %6, 4
  %15 = call i32 @cq_template_zext_i32_to_i64(i32 %14)    ; IR: %12 = zext nneg i32 %11 to i64
  %16 = call i32 @cq_template_or_i64(i32 %13, i32 %15)    ; IR: %13 = or disjoint i64 %10, %12
  %17 = call i32 @cq_template_sub_i64(i32 %16, i32 %13)    ; IR: %14 = inttoptr i64 %13 to ptr: provenance of %9 (tag %9's rail); byte offset = %13 - base[tag]
  %18 = call i32 @cq_template_lshr_i64_hl(i32 %17, i64 2)    ; IR: %14: the byte offset rescaled to the cell index (i32 cells: >> 2)
  %19 = call i32 @cq_template_trunc_i64_to_i32(i32 %18)    ; IR: %14: the logical-i32 cell index rail  [q = (tag %9, this idx)]
  %20 = call i32 @cq_template_qrom_load_i32(ptr %4, i64 2, i32 %19)    ; IR: %15 = load i32, ptr %14 in a: a[idx], a QROM over the classical array (quantum index)
  %21 = call i32 @cq_template_qrom_load_i32(ptr %5, i64 2, i32 %19)    ; IR: %15 in b: b[idx], a QROM over the classical array
  %22 = call i32 @cq_template_select_i32(i32 %12, i32 %20, i32 %21)    ; IR: %15 = load i32, ptr %14: g_a ? a[idx] : b[idx]  [the load: the per-object merge]
  %23 = call i32 @cq_template_add_i32_hl(i32 %22, i32 %2)    ; IR: %16 = add nsw i32 %15, %2  [result rail]
  call void @cq_template_select_i32_unc(i32 %22, i32 %12, i32 %20, i32 %21)    ; IR: uncompute the merged load %15
  call void @cqrt_free(i32 %22)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %21, ptr %5, i64 2, i32 %19)    ; IR: uncompute b's read
  call void @cqrt_free(i32 %21)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %20, ptr %4, i64 2, i32 %19)    ; IR: uncompute a's read
  call void @cqrt_free(i32 %20)    ; IR: release it (|0>)
  call void @cq_template_trunc_i64_to_i32_unc(i32 %19, i32 %18)    ; IR: uncompute the cell index rail
  call void @cqrt_free(i32 %19)    ; IR: release it (|0>)
  call void @cq_template_lshr_i64_hl_unc(i32 %18, i32 %17, i64 2)    ; IR: uncompute the rescaled offset
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_sub_i64_unc(i32 %17, i32 %16, i32 %13)    ; IR: uncompute the byte offset
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_or_i64_unc(i32 %16, i32 %13, i32 %15)    ; IR: uncompute %13
  call void @cqrt_free(i32 %16)    ; IR: release the %13 rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %15, i32 %14)    ; IR: uncompute %12
  call void @cqrt_free(i32 %15)    ; IR: release the %12 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %14, i32 %6, i32 4)    ; IR: uncompute %11
  call void @cqrt_free(i32 %14)    ; IR: release the %11 rail (|0>)
  call void @cq_template_select_i64_ll_unc(i32 %13, i32 %12, i64 %7, i64 %8)    ; IR: uncompute base[tag] (%10)
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %12, i32 %11, i32 1)    ; IR: uncompute the object flag g_a
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %11, i32 %10, i32 2, i32 1)    ; IR: uncompute the pointer's tag %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %10, i32 %9, i32 0)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %6, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  %24 = call i32 @cqrt_measure_i32(i32 %23)    ; IR: %17 = cq_measure_si32(%16)
  ret i32 %24    ; IR: ret i32 %17
}

declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i64_ll(i32, i64, i64)
declare void @cq_template_select_i64_ll_unc(i32, i32, i64, i64)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_or_i64(i32, i32)
declare void @cq_template_or_i64_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i64_hl(i32, i64)
declare void @cq_template_lshr_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare void @cq_template_trunc_i64_to_i32_unc(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_sub_i64(i32, i32)
declare void @cq_template_sub_i64_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
