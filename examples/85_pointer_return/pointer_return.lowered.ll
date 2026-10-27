; HAND-WRITTEN. Rules: 21, 20, 18, 9, 4, 5, 2.
; Checked: r = p ? *p : -1, p = pick(a, x) (measured).
; Clean: the clone's tag and idx result rails (zeroed by the twin, then freed), the NULL flag, the object guard, the
; QROM load and its object merge, every rail inside the clone and its twin.
; Kept: the user register x; the result rail (measured).
; Rotations: Ry(th) on x.
; A quantum pointer is a fat pointer (tag, idx) (example 84, rule 21): tag an i32 rail naming the object (0 = NULL, 1 =
; a), idx an i32 rail holding the CELL index inside it (-O1's zext to i64 and the gep scaling are not emitted; the
; provenance here has one cell width, so no byte offset is carried). POINTERS ACROSS A CLONE BOUNDARY: a classical
; pointer parameter from which the callee may derive a quantum pointer is passed as the triple (object, tag, idx): the
; object itself (here the classical array a: the host component for the callee's own accesses; pick has none), and the
; caller's tag and cell idx for the pointer arithmetic that becomes quantum. Mask per §1.4, left to right over the
; clone's formals: the object gets no digit, tag 0, idx 0 (both classical at the call), k 1: __cq_q_pick_001. A quantum
; pointer result is the aggregate { tag, idx } of two i32 handles (the ABI of 64), copied out and uncomputed through the
; clone's _unc twin like any result (rule 18). pick: idx' = idx0 + index (cell index), then select against NULL (tag 0,
; idx 0) on both halves. Caller: the NULL test is tag == 0. The load through p has a QUANTUM idx, so it is a
; quantum-offset access of each object in p's provenance {NULL, a} (rule 21); a only ever holds the classical values a0
; .. a0 + 3, so by rule 20 the access is a QROM read over its current contents (cq_template_qrom_load_i32, length 4) and
; a stays ordinary classical memory with its -O1 initializer stores, never a QRAM. The pure load runs unguarded (rule 9)
; and is merged by select on the object guard g_a = B and tag == 1 (B, the predicate of block %14, is tag != 0, which
; tag == 1 implies, so the guard is the object flag alone) against NULL's value 0; the phi over the diamond is then a
; select on the NULL flag.
; Everything is uncomputed in reverse.
source_filename = "pointer_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptr_return(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = alloca [4 x i32], align 16    ; IR: %4 = alloca [4 x i32]  (object 1: a, classical memory: holds only classical values)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  store i32 %2, ptr %4, align 16    ; IR: store i32 %2, ptr %4  (a[0] = a0, classical)
  %6 = getelementptr inbounds i8, ptr %4, i64 4    ; IR: %6 = &a[1]
  %7 = add nsw i32 %2, 1    ; IR: %7 = add nsw i32 %2, 1  (classical)
  store i32 %7, ptr %6, align 4    ; IR: store i32 %7, ptr %6  (a[1])
  %8 = getelementptr inbounds i8, ptr %4, i64 8    ; IR: %8 = &a[2]
  %9 = add nsw i32 %2, 2    ; IR: %9 = add nsw i32 %2, 2  (classical)
  store i32 %9, ptr %8, align 8    ; IR: store i32 %9, ptr %8  (a[2])
  %10 = getelementptr inbounds i8, ptr %4, i64 12    ; IR: %10 = &a[3]
  %11 = add nsw i32 %2, 3    ; IR: %11 = add nsw i32 %2, 3  (classical)
  store i32 %11, ptr %10, align 4    ; IR: store i32 %11, ptr %10  (a[3])
  %12 = call fastcc { i32, i32 } @__cq_q_pick_001(ptr %4, i32 1, i32 0, i32 %5)    ; IR: %12 = call @pick(%4, %5), clone (mask 001: a's tag and cell idx classical, k quantum; the object gets no digit); a passed as (object a, tag 1, cell idx 0)  [the pointer: { tag, idx }]
  %13 = extractvalue { i32, i32 } %12, 0    ; IR: %12: the tag rail
  %14 = extractvalue { i32, i32 } %12, 1    ; IR: %12: the idx rail (cell index)
  %15 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 0)    ; IR: %13 = icmp eq ptr %12, null: tag == 0
  %16 = call i32 @cq_template_icmp_eq_i32_hl(i32 %13, i32 1)    ; IR: %15 = load i32, ptr %12: guard g_a = B and tag == 1 (B = tag != 0 is implied; object a addressed iff tag == 1)
  %17 = call i32 @cq_template_qrom_load_i32(ptr %4, i64 4, i32 %14)    ; IR: %15 = load i32, ptr %12: a[idx], a QROM over the classical array (quantum index; pure, unguarded)
  %18 = call i32 @cq_template_select_i32_hl(i32 %16, i32 %17, i32 0)    ; IR: %15: g_a ? a[idx] : 0 (NULL contributes 0)  [the load]
  %19 = call i32 @cq_template_select_i32_lh(i32 %15, i32 -1, i32 %18)    ; IR: %17 = phi [%15, %14], [-1, %3]: null ? -1 : the load  [result rail]
  call void @cq_template_select_i32_hl_unc(i32 %18, i32 %16, i32 %17, i32 0)    ; IR: uncompute the merged load %15
  call void @cqrt_free(i32 %18)    ; IR: release it (|0>)
  call void @cq_template_qrom_load_i32_unc(i32 %17, ptr %4, i64 4, i32 %14)    ; IR: uncompute a's read
  call void @cqrt_free(i32 %17)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %16, i32 %13, i32 1)    ; IR: uncompute the guard g_a
  call void @cqrt_free(i32 %16)    ; IR: release it (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %15, i32 %13, i32 0)    ; IR: uncompute %13
  call void @cqrt_free(i32 %15)    ; IR: release the %13 rail (|0>)
  call fastcc void @__cq_q_pick_001_unc(i32 %13, i32 %14, ptr %4, i32 1, i32 0, i32 %5)    ; IR: uncompute %12 (adjoint of the call)
  call void @cqrt_free(i32 %13)    ; IR: release the tag rail (|0>)
  call void @cqrt_free(i32 %14)    ; IR: release the idx rail (|0>)
  %20 = call i32 @cqrt_measure_i32(i32 %19)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %20    ; IR: ret i32 %18
}

define internal fastcc { i32, i32 } @__cq_q_pick_001(ptr %0, i32 %1, i32 %2, i32 %3) {
  %5 = call i32 @cq_template_and_i32_hl(i32 %3, i32 1)    ; IR: %3 = and i32 %1, 1
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)    ; IR: %4 = icmp eq i32 %3, 0
  %7 = call i32 @cq_template_lshr_i32_hl(i32 %3, i32 1)    ; IR: %5 = lshr i32 %1, 1
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: %6 = and i32 %5, 3  [the element index; %7 = zext to i64 is not emitted]
  %9 = call i32 @cq_template_add_i32_hl(i32 %8, i32 %2)    ; IR: %8 = getelementptr i32, ptr %0, i64 %7: idx = idx0 + index, a CELL index (the gep's 4-byte scaling is not emitted; tag stays %tag0, classical)
  %10 = call i32 @cq_template_select_i32_ll(i32 %6, i32 0, i32 %1)    ; IR: %9 = select i1 %4, ptr null, ptr %8: tag = NULL (0) or tag0
  %11 = call i32 @cq_template_select_i32_lh(i32 %6, i32 0, i32 %9)    ; IR: %9: idx = 0 or %8's idx
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret ptr %9  [result tag rail]
  call void @cqrt_copy_i32(i32 %10, i32 %12)    ; IR: ret ptr %9  [copy the tag out]
  %13 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret ptr %9  [result idx rail]
  call void @cqrt_copy_i32(i32 %11, i32 %13)    ; IR: ret ptr %9  [copy the idx out]
  call void @cq_template_select_i32_lh_unc(i32 %11, i32 %6, i32 0, i32 %9)    ; IR: uncompute %9's idx
  call void @cqrt_free(i32 %11)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %10, i32 %6, i32 0, i32 %1)    ; IR: uncompute %9's tag
  call void @cqrt_free(i32 %10)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %8, i32 %2)    ; IR: uncompute %8
  call void @cqrt_free(i32 %9)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %7, i32 %3, i32 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)    ; IR: uncompute %4
  call void @cqrt_free(i32 %6)    ; IR: release the %4 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %3, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  %14 = insertvalue { i32, i32 } poison, i32 %12, 0    ; IR: ret ptr %9: the tag handle
  %15 = insertvalue { i32, i32 } %14, i32 %13, 1    ; IR: ret ptr %9: the idx handle
  ret { i32, i32 } %15    ; IR: ret ptr %9
}

define internal fastcc void @__cq_q_pick_001_unc(i32 %0, i32 %1, ptr %2, i32 %3, i32 %4, i32 %5) {
  %7 = call i32 @cq_template_and_i32_hl(i32 %5, i32 1)    ; IR: recompute %3
  %8 = call i32 @cq_template_icmp_eq_i32_hl(i32 %7, i32 0)    ; IR: recompute %4
  %9 = call i32 @cq_template_lshr_i32_hl(i32 %5, i32 1)    ; IR: recompute %5
  %10 = call i32 @cq_template_and_i32_hl(i32 %9, i32 3)    ; IR: recompute %6
  %11 = call i32 @cq_template_add_i32_hl(i32 %10, i32 %4)    ; IR: recompute %8 (the cell idx)
  %12 = call i32 @cq_template_select_i32_ll(i32 %8, i32 0, i32 %3)    ; IR: recompute %9's tag
  %13 = call i32 @cq_template_select_i32_lh(i32 %8, i32 0, i32 %11)    ; IR: recompute %9's idx
  call void @cqrt_copy_i32(i32 %12, i32 %0)    ; IR: ret ptr %9  [xor the tag out of %otag]
  call void @cqrt_copy_i32(i32 %13, i32 %1)    ; IR: ret ptr %9  [xor the idx out of %oidx]
  call void @cq_template_select_i32_lh_unc(i32 %13, i32 %8, i32 0, i32 %11)    ; IR: uncompute %9's idx
  call void @cqrt_free(i32 %13)    ; IR: release it (|0>)
  call void @cq_template_select_i32_ll_unc(i32 %12, i32 %8, i32 0, i32 %3)    ; IR: uncompute %9's tag
  call void @cqrt_free(i32 %12)    ; IR: release it (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %11, i32 %10, i32 %4)    ; IR: uncompute %8
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %10, i32 %9, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %10)    ; IR: release the %6 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %9, i32 %5, i32 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %9)    ; IR: release the %5 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %8, i32 %7, i32 0)    ; IR: uncompute %4
  call void @cqrt_free(i32 %8)    ; IR: release the %4 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %5, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %7)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @cq_template_qrom_load_i32(ptr, i64, i32)
declare void @cq_template_qrom_load_i32_unc(i32, ptr, i64, i32)
declare i32 @cq_template_select_i32_hl(i32, i32, i32)
declare void @cq_template_select_i32_hl_unc(i32, i32, i32, i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_ll(i32, i32, i32)
declare void @cq_template_select_i32_ll_unc(i32, i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
