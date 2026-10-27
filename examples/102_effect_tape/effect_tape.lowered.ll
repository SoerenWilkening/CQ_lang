; HAND-WRITTEN. Rules: 16, 19, 20, 7, 8, 5, 2.
; Checked: raise_handled: x + hit; raise_default: x; remove_cond: x (measured).
; Clean: the predicate flag (x > k) in raise_handled and remove_cond.
; Kept: the user register x of each function; the tape rails (never freed, replayed by the backend); raise_default's
; predicate flag (it is the abort flag, kept and measured at the end of the shot); raise_handled's hit rail (measured
; by the user, stays allocated); @hit's seed rail alloc_i32(0) (still |0>, only read by the select, which is never
; uncomputed because the hit rail is measured; it is global storage seeded once for the program, 160).
; Rotations: Ry(th) on x (each function).
; CLASSICAL EFFECTS UNDER A QUANTUM PREDICATE (rule 16). A host effect cannot happen "in superposition" and executing it
; on a classical reading of the predicate would be a measurement, so every effect under a quantum predicate goes the way
; of printf (47): it is RECORDED on the function's tape with its predicate rail and REPLAYED by the backend after the
; program's last own measurement, on the shots where the predicate measured 1. The host call itself is never executed by
; the lowered program.
;   Effect entries: cqrt_tape_effect_controlled(pred, tape, name) opens an effect entry (name = the callee, as a string
;   constant); its arguments follow as the existing field entries (cqrt_tape_write_<W>[_controlled] for quantum values,
;   _lit for classical ones) plus cqrt_tape_write_str_lit(tape, ptr) for a string argument.
; raise(sig) splits by the classical signal table read off the module's signal() calls (closed world, as the callee set
; of 96/97): (a) a handler in the module runs as a CONTROLLED CLONE, the callee's clone with the predicate as its first
; parameter (__cq_q_h_0_ctl, rule 19: a pure clone is called unguarded as in 97, an effectful one takes the predicate
; because its stores must be guarded); the handler's volatile store to the internal global hit is a guarded store,
; hit = pred ? s : hit (67; the later volatile load reads the handle the slot holds). The slot cell is homogeneous (rule
; 20): it holds a handle on every path, so its first classical value, the initializer 0, is materialised once as a seed
; rail alloc_i32(0) by a module constructor (@hit is program-lifetime storage, as 160's global), the guarded store is the
; select_i32_lh of the literal s against that handle, and the classical original h stores a seed rail too; the delivery
; itself is also recorded on the tape; (b) no handler and a terminating default action (SIGABRT) is the noreturn arm of
; 45: the predicate goes to cqrt_abort_i1 and stays allocated, the signal number recorded on the tape as the shot's abort
; status. (c) remove(path) has nothing to run in the module: the tape entry alone. The return values of
; signal/raise/remove are unused and dropped; signal() is a classical host call and stays.
source_filename = "effect_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@hit = internal global i32 0, align 4    ; IR: @hit  (internal slot of a quantum value: it holds a HANDLE on every path, rule 20; the constructor below seeds it)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_slot_init_hit, ptr null }]    ; IR: program start: @hit's storage comes into existence before any entry runs (160)
@.str = private unnamed_addr constant [10 x i8] c"/tmp/cq_x\00", align 1    ; IR: @.str
@.cq.effect.raise = private unnamed_addr constant [6 x i8] c"raise\00", align 1    ; IR: effect entry name for raise
@.cq.effect.remove = private unnamed_addr constant [7 x i8] c"remove\00", align 1    ; IR: effect entry name for remove

define i32 @raise_handled(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape (output and effects)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call ptr @signal(i32 30, ptr @h)    ; IR: %5 = signal(30, @h)  (classical host call; the compiler reads SIGUSR1 -> @h off it)
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 %2)    ; IR: %6 = icmp sgt i32 %4, %2  [predicate of block %7]
  call void @cqrt_tape_effect_controlled(i32 %7, i32 %4, ptr @.cq.effect.raise)    ; IR: block %7: %8 = raise(30): the delivery, recorded under the predicate (replayed iff it measures 1)
  call void @cqrt_tape_write_i32_lit(i32 %4, i32 30)    ; IR: %8: argument 0, the signal number (classical)
  call fastcc void @__cq_q_h_0_ctl(i32 %7, i32 30)    ; IR: %8 = raise(30): the installed handler h(30) runs under the predicate (controlled clone)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %5, i32 %2)    ; IR: uncompute %6
  call void @cqrt_free(i32 %7)    ; IR: release the %6 rail (|0>)
  %8 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %10 = cq_measure_si32(%4)
  %9 = load i32, ptr @hit, align 4    ; IR: %11 = load volatile i32, ptr @hit  (the handle the guarded store left in the slot)
  %10 = call i32 @cqrt_measure_i32(i32 %9)    ; IR: %12 = cq_measure_si32(%11)  (measures the hit rail; it stays allocated)
  %11 = add nsw i32 %10, %8    ; IR: %13 = add nsw i32 %12, %10  (classical)
  ret i32 %11    ; IR: ret i32 %13
}

define internal void @__cq_slot_init_hit() {
  %1 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: @hit = internal global i32 0: the cell's first classical value, materialised as a seed rail (rule 7) because the cell holds a handle on another path (rule 20)
  store i32 %1, ptr @hit, align 4    ; IR: the slot holds the seed's handle
  ret void
}

define internal void @h(i32 noundef %0) {
  %2 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: store volatile i32 %0, ptr @hit  (classical original, referenced by signal()): the classical s as a seed rail, the cell stays a handle
  store volatile i32 %2, ptr @hit, align 4    ; IR: store volatile i32 %0, ptr @hit
  ret void    ; IR: ret void
}

define internal fastcc void @__cq_q_h_0_ctl(i32 %0, i32 %1) {
  %3 = load i32, ptr @hit, align 4    ; IR: hit before the store  (the handle the slot holds: the seed rail on this program's only path)
  %4 = call i32 @cq_template_select_i32_lh(i32 %0, i32 %1, i32 %3)    ; IR: store volatile i32 %0, ptr @hit under the predicate: hit = pred ? %0 : hit  [fresh rail; the stored s is the classical arm]
  store i32 %4, ptr @hit, align 4    ; IR: the slot takes the handle (67); the rail is read by the caller's measurement and is never freed here
  ret void    ; IR: ret void
}

define i32 @raise_default(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [predicate of block %6: a noreturn arm (SIGABRT, no handler: default action terminates)]
  call void @cqrt_tape_effect_controlled(i32 %6, i32 %4, ptr @.cq.effect.raise)    ; IR: block %6: %7 = raise(6): the delivery, recorded under the predicate
  call void @cqrt_tape_write_i32_lit(i32 %4, i32 6)    ; IR: %7: argument 0, the signal number (classical)
  call void @cqrt_abort_i1(i32 %6)    ; IR: block %6: raise(6) terminates the process: the abort arm of 45 (flag kept allocated, measured by the backend at end of shot)
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %9 = cq_measure_si32(%4)
  ret i32 %7    ; IR: ret i32 %9
}

define i32 @remove_cond(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [predicate of block %6]
  call void @cqrt_tape_effect_controlled(i32 %6, i32 %4, ptr @.cq.effect.remove)    ; IR: block %6: %7 = remove(@.str): recorded under the predicate; the host call is not executed
  call void @cqrt_tape_write_str_lit(i32 %4, ptr @.str)    ; IR: %7: argument 0, the path (classical string)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %9 = cq_measure_si32(%4)
  ret i32 %7    ; IR: ret i32 %9
}

declare ptr @signal(i32, ptr)
declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_effect_controlled(i32, i32, ptr)
declare void @cqrt_tape_write_i32_lit(i32, i32)
declare void @cqrt_tape_write_str_lit(i32, ptr)
declare void @cqrt_abort_i1(i32)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
