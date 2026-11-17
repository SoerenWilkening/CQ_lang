; HAND-WRITTEN. Rules: 21, 20, 18, 9, 8, 5, 4, 2, 7, 16; §1.3, §1.4.
; Checked: r = p ? *p : -1 with p = pick(a, x) (the merge rail, measured): x & 1 ? a0 + ((x >> 1) & 3) : -1; the
; cells of a at exit: a[i] = a0 + i (only the initializer stores them). For the driver ptr_return(0, .5, 7) (Ry(.5)
; on every bit of x, a bit flips with p = sin^2(.25) = 0.061209): r = -1 with 0.938791, 7 with 0.053945, 8 and 9 with
; 0.003517 each, 10 with 0.000229.
; Clean: the address rail p that __cq_q_pick_01 returned, zeroed by its twin __cq_q_pick_01_unc after its last reader
; (the NULL flag's _unc, after the load's _unc) and freed; the NULL flag p == 0; the load copy *p, un-copied under its X-bracketed control right
; after the merge (no memory version change since the load) and freed; every rail inside the clone and its twin.
; Kept: the user register x; the merge rail r (measured); by rule 5 the tape slots of the four initializer stores
; and their value seeds (i32 a0, a0 + 1, a0 + 2, a0 + 3; classical-valued, no qubit, §0).
; Rotations: (Ry, x, th, 1).
; A POINTER IS ITS ADDRESS (rule 21): pick returns a pointer computed from the rail k, so it is ONE i32 handle to a
; 64-bit address rail. Inside the clone the gep with a tainted index is rule 20's 64-bit template arithmetic: -O1's
; zext nneg to i64, mul_i64_hl by the element size 4, add_i64_hl of the classical run-time address of the pointer
; formal; the NULL arm of the select is the literal 0 (select_i64_lh). The pointer formal a is classical at the call,
; so the mask over pick's two scalar formals (ptr a, i32 k) is 01: __cq_q_pick_01(ptr, i32); nothing about the
; pointee crosses the call (§1.4, rule 18). pick has no bus access, so its twin exists and the caller runs it after the
; address rail's last reader. pick's own symbol has no caller left and is dropped (§1.4).
; Caller: the NULL test is icmp_eq_i64_hl(p, 0) (rule 21: null is the literal 0), a tainted br and so a flag (rule 8).
; The load *p sits on the flag's FALSE edge: it is ONE bus access at the address rail (rule 20), never hoisted, the
; _controlled form under NOT flag, an X bracket (not_i1) around it (rules 8, 9); under flag = 1 nothing is touched and
; the copy stays |0>. There is no object, guard, tag or bound: an address is not resolved at compile time (§0). The
; phi is one select_i32_lh(flag, -1, copy) (rule 9). The copy is un-copied by the _controlled_unc inside the same X
; bracket (rule 5).
; THE ALLOCA IS BUS-RESIDENT (rule 20 (b)): a is passed to a call, a user that is not in the host-resident list, so it
; is __cq_alloc(16, 16) at its program point, no alloca remains and the lifetime markers are dropped (rule 16). Its
; four -O1 initializer stores are bus stores at classical addresses (qram_store_i32_hl), each value a seed (rule 7),
; KEPT with its tape slot (rule 5); all classical-valued, so the cells stay HOST and the load through p reads the host
; bytes (§1.3). The constant geps &a[1..3] stay (nothing tainted) and are spelled ptrtoint for the _hl address.
; Everything else is uncomputed in reverse.
source_filename = "pointer_return.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @ptr_return(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call ptr @__cq_alloc(i64 16, i64 16)    ; IR: %4 = alloca [4 x i32], align 16  [bus-resident: a is passed to a call (rule 20); one zeroed block (rule 16)]
  %6 = ptrtoint ptr %5 to i64    ; IR: %4 as its run-time address (rule 21)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: store i32 %2, ptr %4: the classical value as a seed (rule 7), kept with its store; llvm.lifetime.start dropped (rule 16)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %6, i32 %8)    ; IR: store i32 %2, ptr %4  (a[0] = a0: kept store at a classical address, rule 5)
  %9 = getelementptr inbounds i8, ptr %5, i64 4    ; IR: %6 = getelementptr inbounds i8, ptr %4, i64 4  (nothing tainted: the gep stays)
  %10 = add nsw i32 %2, 1    ; IR: %7 = add nsw i32 %2, 1  (classical)
  %11 = ptrtoint ptr %9 to i64    ; IR: %6 as its run-time address
  %12 = call i32 @cqrt_alloc_i32(i32 %10)    ; IR: store i32 %7, ptr %6: the value as a seed (rule 7)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %11, i32 %12)    ; IR: store i32 %7, ptr %6  (a[1]: kept store)
  %13 = getelementptr inbounds i8, ptr %5, i64 8    ; IR: %8 = getelementptr inbounds i8, ptr %4, i64 8  (nothing tainted: the gep stays)
  %14 = add nsw i32 %2, 2    ; IR: %9 = add nsw i32 %2, 2  (classical)
  %15 = ptrtoint ptr %13 to i64    ; IR: %8 as its run-time address
  %16 = call i32 @cqrt_alloc_i32(i32 %14)    ; IR: store i32 %9, ptr %8: the value as a seed (rule 7)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %15, i32 %16)    ; IR: store i32 %9, ptr %8  (a[2]: kept store)
  %17 = getelementptr inbounds i8, ptr %5, i64 12    ; IR: %10 = getelementptr inbounds i8, ptr %4, i64 12  (nothing tainted: the gep stays)
  %18 = add nsw i32 %2, 3    ; IR: %11 = add nsw i32 %2, 3  (classical)
  %19 = ptrtoint ptr %17 to i64    ; IR: %10 as its run-time address
  %20 = call i32 @cqrt_alloc_i32(i32 %18)    ; IR: store i32 %11, ptr %10: the value as a seed (rule 7)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %19, i32 %20)    ; IR: store i32 %11, ptr %10  (a[3]: kept store)
  %21 = call fastcc i32 @__cq_q_pick_01(ptr %5, i32 %7)    ; IR: %12 = call fastcc ptr @pick(ptr %4, i32 %5): the clone of mask 01 (the classical ptr stays a ptr, k a rail); the pointer result is ONE handle to a 64-bit address rail
  %22 = call i32 @cq_template_icmp_eq_i64_hl(i32 %21, i64 0)    ; IR: %13 = icmp eq ptr %12, null  [the address compared with the literal 0 (rule 21); the branch flag (rule 8)]
  call void @cqrt_not_i1(i32 %22)    ; IR: br i1 %13, label %16, label %14: block %14 is the false edge, X bracket
  %23 = call i32 @cqrt_qram_load_i32_controlled(i32 %22, i32 %4, i32 %21)    ; IR: %15 = load i32, ptr %12  [ONE bus load at the address rail, under p != null (rules 9, 20); |0> on the other branch]
  call void @cqrt_not_i1(i32 %22)    ; IR: X bracket closes
  %24 = call i32 @cq_template_select_i32_lh(i32 %22, i32 -1, i32 %23)    ; IR: %17 = phi i32 [ %15, %14 ], [ -1, %3 ]: null ? -1 : the load  [result rail]
  call void @cqrt_not_i1(i32 %22)    ; IR: X bracket (the control the load had)
  call void @cqrt_qram_load_i32_controlled_unc(i32 %23, i32 %22, i32 %4, i32 %21)    ; IR: un-copy %15 (its last reader %17 is done; no memory version change since the load, rule 5)
  call void @cqrt_not_i1(i32 %22)    ; IR: X bracket closes
  call void @cqrt_free(i32 %23)    ; IR: release the %15 rail (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %22, i32 %21, i64 0)    ; IR: uncompute %13
  call void @cqrt_free(i32 %22)    ; IR: release the %13 rail (|0>)
  call fastcc void @__cq_q_pick_01_unc(i32 %21, ptr %5, i32 %7)    ; IR: uncompute %12 (the twin, after the address rail's last reader)
  call void @cqrt_free(i32 %21)    ; IR: release the %12 rail (|0>)
  %25 = call i32 @cqrt_measure_i32(i32 %24)    ; IR: %18 = cq_measure_si32(%17)
  ret i32 %25    ; IR: ret i32 %18  (llvm.lifetime.end dropped, rule 16)
}

define internal fastcc i32 @__cq_q_pick_01(ptr %0, i32 %1) {
  %3 = ptrtoint ptr %0 to i64    ; IR: %0 as its run-time address (mask digit 0: the formal is the C ptr)
  %4 = call i32 @cq_template_and_i32_hl(i32 %1, i32 1)    ; IR: %3 = and i32 %1, 1
  %5 = call i32 @cq_template_icmp_eq_i32_hl(i32 %4, i32 0)    ; IR: %4 = icmp eq i32 %3, 0
  %6 = call i32 @cq_template_lshr_i32_hl(i32 %1, i32 1)    ; IR: %5 = lshr i32 %1, 1
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 3)    ; IR: %6 = and i32 %5, 3
  %8 = call i32 @cq_template_zext_i32_to_i64(i32 %7)    ; IR: %7 = zext nneg i32 %6 to i64
  %9 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 4)    ; IR: %8 = getelementptr inbounds i32, ptr %0, i64 %7: the index scaled by the element size (rule 20)
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 %3)    ; IR: %8: plus the classical base address  [address rail]
  %11 = call i32 @cq_template_select_i64_lh(i32 %5, i64 0, i32 %10)    ; IR: %9 = select i1 %4, ptr null, ptr %8  [null is the literal 0 (rule 21)]
  %12 = call i32 @cqrt_alloc_i64(i64 0)    ; IR: ret ptr %9  [fresh result rail]
  call void @cqrt_copy_i64(i32 %11, i32 %12)    ; IR: ret ptr %9  [copy the address out]
  call void @cq_template_select_i64_lh_unc(i32 %11, i32 %5, i64 0, i32 %10)    ; IR: uncompute %9
  call void @cqrt_free(i32 %11)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 %3)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %9, i32 %8, i64 4)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %9)    ; IR: release the scaled index (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %8, i32 %7)    ; IR: uncompute %7
  call void @cqrt_free(i32 %8)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %6, i32 %1, i32 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %5, i32 %4, i32 0)    ; IR: uncompute %4
  call void @cqrt_free(i32 %5)    ; IR: release the %4 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %4, i32 %1, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %4)    ; IR: release the %3 rail (|0>)
  ret i32 %12    ; IR: ret ptr %9
}

define internal fastcc void @__cq_q_pick_01_unc(i32 %0, ptr %1, i32 %2) {
  %4 = ptrtoint ptr %1 to i64    ; IR: %0 as its run-time address
  %5 = call i32 @cq_template_and_i32_hl(i32 %2, i32 1)    ; IR: recompute %3
  %6 = call i32 @cq_template_icmp_eq_i32_hl(i32 %5, i32 0)    ; IR: recompute %4
  %7 = call i32 @cq_template_lshr_i32_hl(i32 %2, i32 1)    ; IR: recompute %5
  %8 = call i32 @cq_template_and_i32_hl(i32 %7, i32 3)    ; IR: recompute %6
  %9 = call i32 @cq_template_zext_i32_to_i64(i32 %8)    ; IR: recompute %7
  %10 = call i32 @cq_template_mul_i64_hl(i32 %9, i64 4)    ; IR: recompute %8 (the scaled index)
  %11 = call i32 @cq_template_add_i64_hl(i32 %10, i64 %4)    ; IR: recompute %8
  %12 = call i32 @cq_template_select_i64_lh(i32 %6, i64 0, i32 %11)    ; IR: recompute %9
  call void @cqrt_copy_i64(i32 %12, i32 %0)    ; IR: ret ptr %9  [xor the address out of the result rail]
  call void @cq_template_select_i64_lh_unc(i32 %12, i32 %6, i64 0, i32 %11)    ; IR: uncompute %9
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i64_hl_unc(i32 %11, i32 %10, i64 %4)    ; IR: uncompute %8
  call void @cqrt_free(i32 %11)    ; IR: release the %8 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %10, i32 %9, i64 4)    ; IR: uncompute %8 (the scaled index)
  call void @cqrt_free(i32 %10)    ; IR: release the scaled index (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %9, i32 %8)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %8, i32 %7, i32 3)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_lshr_i32_hl_unc(i32 %7, i32 %2, i32 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  call void @cq_template_icmp_eq_i32_hl_unc(i32 %6, i32 %5, i32 0)    ; IR: uncompute %4
  call void @cqrt_free(i32 %6)    ; IR: release the %4 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %2, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %5)    ; IR: release the %3 rail (|0>)
  ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_copy_i64(i32, i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_controlled(i32, i32, i32)
declare void @cqrt_qram_load_i32_controlled_unc(i32, i32, i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare i32 @cq_template_select_i64_lh(i32, i64, i32)
declare void @cq_template_select_i64_lh_unc(i32, i32, i64, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i32_hl(i32, i32)
declare void @cq_template_icmp_eq_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_lshr_i32_hl(i32, i32)
declare void @cq_template_lshr_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
