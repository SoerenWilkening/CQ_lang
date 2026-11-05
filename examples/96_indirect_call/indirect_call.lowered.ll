; HAND-WRITTEN. Rules: 19 (classical function pointer, clone table), 18, 16, 21, 9, 4, 5, 7, 2, 14; §1.3 (clone table), §1.4
; (table clones, activation counter).
; Checked: fp(x) with fp = which ? dbl : sq (the copy of the table clone's result, measured): x + x where which != 0,
; x * x where which = 0.
; Clean: inside whichever table clone runs: its arm value (copied out, then uncomputed and freed); the clone's
; result rail, zeroed and freed by its table twin (__cq_q_<fn>_1_t_unc, resolved as kind 2; the caller frees no
; result of a table clone, §1.4); on the host branch (never taken here) the |1> seed of the effect entry (rule 7).
; Kept: the user register x; the copy of the call's result (measured; rule 18: a measured result is copied before the
; twin runs); the function's tape (allocated at entry on every path, rule 16). On the host branch (never taken here):
; the tape field rail of x and the entry's result rail r_e (measured).
; Rotations: (Ry, x, th, 1).
; An INDIRECT CALL through a CLASSICAL function pointer with a quantum argument (rule 19). Which functions fp can
; denote is never analysed (clang's !callees metadata is not read): fp is resolved at run time through the clone
; table. The module constructor registers one row for each address-taken function (dbl, sq: their addresses are the
; select's operands): its host address, the type string "i32 (i32)", its table clone and that clone's _ctl, _unc and
; _ctl_unc (§1.3). The call is __cq_clone_resolve(fp, 0), the forward table clone, with the table ABI: every formal a
; handle (x), then K = 4, the K of this function (§0). The caller has no record of the callee, so the call is a memory
; version change, and its twin (__cq_clone_resolve(fp, 2)) is called exactly once at its rule-18 position: the result
; is measured, so it is first copied into a fresh rail, the twin zeroes and frees the clone's own result, and the
; copy is measured (rule 18). A null resolve means fp is host code: the call is rule 16's effect entry with a null
; name, fp's address as its first field (a classical i64, a _lit field) and x as its second, under an alloc_i1(true)
; seed; its result rail r_e is measured. The two results merge by a classical phi of handles (the branch is
; classical). No predicate is in scope, so no _ctl clone is called here; the _ctl forms exist because every row
; names them.
; THE TABLE CLONES (§1.4). Each takes the handle and K and returns one handle; neither function mints a register, so
; nothing is pushed and the twins pop nothing. Their bodies keep the copy-out form of rule 18 (compute, copy the
; result out, uncompute, free). dbl and sq write no memory and do not measure, so the table twins are rule 18's twin:
; recompute, XOR the result out with copy_i32, uncompute, then free both rails (§1.4: a table twin frees the results
; it zeroes). A _ctl table clone whose body is only templates computes unguarded and reads its predicate only for the
; cut: it and its twin read the function's activation counter d on entry, add 1 and subtract 1 at the return; at
; d >= K the clone returns a |0> rail and keeps a copy_i1 of its predicate as the overflow rail, and the twin frees
; that |0> rail (rule 14). The _ctl forms are not called in this program.
; THE OWN SYMBOLS. dbl and sq have no bus access, no cq_* call and no call: each is its own lowering (rule 19), and
; their host addresses are the table's keys. The per-mask clones __cq_q_dbl_1 / __cq_q_sq_1 have no call by name and
; are dropped (§1.4).
; Corpus convention (§5): the clone-table row, table clone, _t_ctl and twins of the externally visible indirect_call
; (type i32 (i32, double, i32)), whose address is never taken, are omitted; the compiler emits them (§1.3, rule 19).
; SPEC GAP: CR fixes no module-internal name: as in 205, 211 and 212 the constructor is internal void @__cq_register()
; at priority 65535, the sig string is private @.cq.sig, the activation counters are internal i32 @__cq_act_<fn>.
; The host branch is rule 16's effect entry, not the instruction as it stands: its argument x is a rail, so it is not
; an ordinary host call (rule 16: every argument classical). The _i32 form is used because the program reads the result.
; SPEC GAP: rule 18 lets a one-template body return its rail directly (211's inc); the copy-out form of the previous
; lowering is kept here, which rule 18 also allows.
source_filename = "indirect_call.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1    ; the LLVM function type of dbl, sq and the indirect call, as a C string (§1.3)
@__cq_act_dbl = internal global i32 0, align 4    ; live _ctl activations of dbl (§1.4: it has a table clone)
@__cq_act_sq = internal global i32 0, align 4    ; live _ctl activations of sq (§1.4)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @dbl, ptr @.cq.sig, ptr @__cq_q_dbl_1_t, ptr @__cq_q_dbl_1_t_ctl, ptr @__cq_q_dbl_1_t_unc, ptr @__cq_q_dbl_1_t_ctl_unc)    ; row of dbl (address taken by the select): fn, sig, table clone, _ctl, _unc, _ctl_unc (rule 19)
  call void @__cq_clone_register(ptr @sq, ptr @.cq.sig, ptr @__cq_q_sq_1_t, ptr @__cq_q_sq_1_t_ctl, ptr @__cq_q_sq_1_t_unc, ptr @__cq_q_sq_1_t_ctl_unc)    ; row of sq (address taken by the select)
  ret void
}

define i32 @indirect_call(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; the function's tape (one tape_alloc at entry, on every path; the host branch's effect entry records on it, rule 16)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = icmp eq i32 %2, 0    ; IR: %5 = icmp eq i32 %2, 0  (classical)
  %7 = select i1 %6, ptr @sq, ptr @dbl    ; IR: %6 = select i1 %5, ptr @sq, ptr @dbl  (classical function pointer: a host address)
  %8 = call ptr @__cq_clone_resolve(ptr %7, i32 0)    ; IR: %7 = call %6(%4)  [the table clone of fp (kind 0), from the clone table at run time (rule 19)]
  %9 = icmp eq ptr %8, null    ; IR: %7: no row, fp is host code
  br i1 %9, label %14, label %10    ; IR: %7: classical branch

10:
  %11 = call i32 %8(i32 %5, i32 4)    ; IR: %7 = call %6(%4)  [the table clone: the argument rail x, K; a memory version change (rule 19)]  [K]
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %7  [the copy of the result that is measured (rule 18)]
  call void @cqrt_copy_i32(i32 %11, i32 %12)    ; IR: %7  [copy the result out before the twin]
  %13 = call ptr @__cq_clone_resolve(ptr %7, i32 2)    ; IR: %7  [the table twin of fp (kind 2)]
  call void %13(i32 %11, i32 %5, i32 4)    ; IR: %7  [the twin, exactly once: the result, the argument, K; it zeroes and frees the result (§1.4)]  [K]
  br label %19    ; IR: %7

14:
  %15 = call i32 @cqrt_alloc_i1(i1 true)    ; IR: %7 = call %6(%4)  [host code: no predicate in scope, the |1> seed (rule 16)]
  %16 = ptrtoint ptr %7 to i64    ; IR: %6 as a classical i64 (rule 21)
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 %16)    ; IR: %7  [field 0: the callee's address, classical (rule 19)]
  %17 = call i32 @cqrt_tape_write_i32(i32 %4, i32 %5)    ; IR: %7  [field 1: the argument rail x (KEPT tape rail)]
  %18 = call i32 @cqrt_tape_effect_i32_controlled(i32 %15, i32 %4, ptr null)    ; IR: %7  [the effect entry with a null name: r_e, its result rail, KEPT (rule 16)]
  call void @cqrt_free(i32 %15)    ; IR: release the seed (|1>, never written: freed directly, rule 7)
  br label %19    ; IR: %7

19:
  %20 = phi i32 [ %12, %10 ], [ %18, %14 ]    ; IR: %7  [result handle, classical phi of handles]
  %21 = call i32 @cqrt_measure_i32(i32 %20)    ; IR: %8 = cq_measure_si32(%7)
  ret i32 %21    ; IR: ret i32 %8
}

define internal i32 @dbl(i32 noundef %0) {
  %2 = shl nsw i32 %0, 1    ; IR: %2 = shl nsw i32 %0, 1  (the own symbol: its own lowering, rule 19; its address is the table key)
  ret i32 %2    ; IR: ret i32 %2
}

define internal i32 @sq(i32 noundef %0) {
  %2 = mul nsw i32 %0, %0    ; IR: %2 = mul nsw i32 %0, %0  (the own symbol: its own lowering, rule 19; its address is the table key)
  ret i32 %2    ; IR: ret i32 %2
}

define internal i32 @__cq_q_dbl_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_shl_i32_hl(i32 %0, i32 1)    ; IR: %2 = shl nsw i32 %0, 1  (table clone: the handle, then K)
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %2  [result rail of the call]
  call void @cqrt_copy_i32(i32 %3, i32 %4)    ; IR: ret i32 %2  [copy the result out]
  call void @cq_template_shl_i32_hl_unc(i32 %3, i32 %0, i32 1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %3)    ; IR: release the %2 rail (|0>)
  ret i32 %4    ; IR: ret i32 %2
}

define internal void @__cq_q_dbl_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_shl_i32_hl(i32 %1, i32 1)    ; IR: %2 = shl nsw i32 %0, 1  (twin: recompute; the result, the argument, K)
  call void @cqrt_copy_i32(i32 %4, i32 %0)    ; IR: ret i32 %2  [XOR the result out: it is |0>]
  call void @cq_template_shl_i32_hl_unc(i32 %4, i32 %1, i32 1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %4)    ; IR: release the %2 rail (|0>)
  call void @cqrt_free(i32 %0)    ; IR: release the result rail (|0>): a table clone's twin frees what it zeroes (§1.4)
  ret void
}

define internal i32 @__cq_q_dbl_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_dbl, align 4    ; d: this activation's depth (§1.4)
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_dbl, align 4    ; one more live _ctl activation of dbl
  %6 = icmp ult i32 %4, %2    ; d below K: the body runs (rule 14)
  br i1 %6, label %7, label %12

7:
  %8 = call i32 @cq_template_shl_i32_hl(i32 %1, i32 1)    ; IR: %2 = shl nsw i32 %0, 1  (a template on an SSA value: computed unguarded, the caller merges by select, rule 9)
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %2  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %2  [copy the result out]
  call void @cq_template_shl_i32_hl_unc(i32 %8, i32 %1, i32 1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %8)    ; IR: release the %2 rail (|0>)
  %10 = load i32, ptr @__cq_act_dbl, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_dbl, align 4    ; the activation ends
  ret i32 %9    ; IR: ret i32 %2

12:
  %13 = call i32 @cqrt_alloc_i32(i32 0)    ; the cut: the result is a |0> rail (rule 14)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; the overflow predicate of this cut activation, an output rail (KEPT)
  call void @cqrt_copy_i1(i32 %0, i32 %14)    ; a copy of the predicate
  %15 = load i32, ptr @__cq_act_dbl, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_dbl, align 4    ; the activation ends
  ret i32 %13
}

define internal void @__cq_q_dbl_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_dbl, align 4    ; d (§1.4): the twin makes the same cut
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_dbl, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %10

8:
  %9 = call i32 @cq_template_shl_i32_hl(i32 %2, i32 1)    ; IR: %2 = shl nsw i32 %0, 1  (twin: predicate, the result, the argument, K)
  call void @cqrt_copy_i32(i32 %9, i32 %1)    ; IR: ret i32 %2  [XOR the result out]
  call void @cq_template_shl_i32_hl_unc(i32 %9, i32 %2, i32 1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %9)    ; IR: release the %2 rail (|0>)
  br label %10

10:
  call void @cqrt_free(i32 %1)    ; IR: release the result rail (|0>: zeroed above, or the cut activation's |0> rail)
  %11 = load i32, ptr @__cq_act_dbl, align 4
  %12 = add i32 %11, -1
  store i32 %12, ptr @__cq_act_dbl, align 4
  ret void
}

define internal i32 @__cq_q_sq_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %2 = mul nsw i32 %0, %0  (table clone: the handle, then K)
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %2  [result rail of the call]
  call void @cqrt_copy_i32(i32 %3, i32 %4)    ; IR: ret i32 %2  [copy the result out]
  call void @cq_template_mul_i32_unc(i32 %3, i32 %0, i32 %0)    ; IR: uncompute %2
  call void @cqrt_free(i32 %3)    ; IR: release the %2 rail (|0>)
  ret i32 %4    ; IR: ret i32 %2
}

define internal void @__cq_q_sq_1_t_unc(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @cq_template_mul_i32(i32 %1, i32 %1)    ; IR: %2 = mul nsw i32 %0, %0  (twin: recompute; the result, the argument, K)
  call void @cqrt_copy_i32(i32 %4, i32 %0)    ; IR: ret i32 %2  [XOR the result out: it is |0>]
  call void @cq_template_mul_i32_unc(i32 %4, i32 %1, i32 %1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %4)    ; IR: release the %2 rail (|0>)
  call void @cqrt_free(i32 %0)    ; IR: release the result rail (|0>): a table clone's twin frees what it zeroes (§1.4)
  ret void
}

define internal i32 @__cq_q_sq_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_sq, align 4    ; d: this activation's depth (§1.4)
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_sq, align 4    ; one more live _ctl activation of sq
  %6 = icmp ult i32 %4, %2    ; d below K: the body runs (rule 14)
  br i1 %6, label %7, label %12

7:
  %8 = call i32 @cq_template_mul_i32(i32 %1, i32 %1)    ; IR: %2 = mul nsw i32 %0, %0  (a template on an SSA value: computed unguarded, the caller merges by select, rule 9)
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %2  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %2  [copy the result out]
  call void @cq_template_mul_i32_unc(i32 %8, i32 %1, i32 %1)    ; IR: uncompute %2
  call void @cqrt_free(i32 %8)    ; IR: release the %2 rail (|0>)
  %10 = load i32, ptr @__cq_act_sq, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_sq, align 4    ; the activation ends
  ret i32 %9    ; IR: ret i32 %2

12:
  %13 = call i32 @cqrt_alloc_i32(i32 0)    ; the cut: the result is a |0> rail (rule 14)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; the overflow predicate of this cut activation, an output rail (KEPT)
  call void @cqrt_copy_i1(i32 %0, i32 %14)    ; a copy of the predicate
  %15 = load i32, ptr @__cq_act_sq, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_sq, align 4    ; the activation ends
  ret i32 %13
}

define internal void @__cq_q_sq_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_sq, align 4    ; d (§1.4): the twin makes the same cut
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_sq, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %10

8:
  %9 = call i32 @cq_template_mul_i32(i32 %2, i32 %2)    ; IR: %2 = mul nsw i32 %0, %0  (twin: predicate, the result, the argument, K)
  call void @cqrt_copy_i32(i32 %9, i32 %1)    ; IR: ret i32 %2  [XOR the result out]
  call void @cq_template_mul_i32_unc(i32 %9, i32 %2, i32 %2)    ; IR: uncompute %2
  call void @cqrt_free(i32 %9)    ; IR: release the %2 rail (|0>)
  br label %10

10:
  call void @cqrt_free(i32 %1)    ; IR: release the result rail (|0>: zeroed above, or the cut activation's |0> rail)
  %11 = load i32, ptr @__cq_act_sq, align 4
  %12 = add i32 %11, -1
  store i32 %12, ptr @__cq_act_sq, align 4
  ret void
}

declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)
declare ptr @__cq_clone_resolve(ptr, i32)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i1(i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_write_i64_lit(i32, i64)
declare i32 @cqrt_tape_write_i32(i32, i32)
declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare void @cq_template_shl_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_mul_i32(i32, i32)
declare void @cq_template_mul_i32_unc(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
