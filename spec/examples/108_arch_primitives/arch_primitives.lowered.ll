; HAND-WRITTEN. Rules: 2, 4, 5, 6, 16, 18, 20, 21, 24; §1.3 (the bus, __cq_mem), §1.4 (own symbol).
; Checked: ctz_q: (unsigned)ctzll(x | 1 << 32) (measured, the trunc rail %6 -> %7); trap_q: x + 1 (measured, %6 -> %8);
; tls_q: tl * 2 (measured, the shl rail %11 -> %12), and the cell tl = x + 1 + c (read from the bus at exit at the
; thread-local's address).
; Clean: ctz_q: the or rail (%4) and the cttz rail (%5), uncomputed and freed; trap_q: the old x rail (%4, rule 6:
; dead after x + 1) and t = r - 1 (%7), both freed; tls_q: the old x rail (%5, rule 6: x + 1 is a bijection in x and x
; is dead after it; the image x + 1 is kept), t = (x + 1) - 1 (%7), and the load copy of tl (%10, un-copied after the
; shl, before the measurement: no memory version change follows the load); touch: the swapped-out old *p (%5, rule 6),
; the inverse t = y' - c (%7) and the rail the cell's |0> went to (%6).
; Kept: x in ctz_q (%3, 64 bits: a rotated user register whose result has no inverse); trap_q's result x + 1 (%6,
; measured) and its abort flag x > k (%5): a noreturn-arm predicate passed to cqrt_abort_i1 stays allocated and the
; backend measures it after the program's last own measurement; tls_q: by rule 5 the tape slot of the store
; `tl = x + 1` (no handle: it is in the backend and holds the displaced tl) and its value rail x + 1 (%6), and the shl
; rail (%11, measured). touch keeps nothing (the in-place form leaves no rail, tape slot or old value).
; Rotations: (Ry, x, th, 1) in each of the three functions (an i64 Ry in ctz_q).
; The three intrinsics the CQ musl architecture headers produce when their asm is spelled as
; builtins (LIBC_COVERAGE.md): llvm.cttz (a_ctz_64 = bsf) is the unary template cq_template_cttz_<W> exactly as 56's ctlz,
; the is_zero_poison literal being a promise about the operand, not an operand; llvm.trap (a_crash = hlt) is a noreturn
; under a quantum predicate, 45's abort arm: the predicate rail goes to cqrt_abort_i1 and stays allocated, the backend
; measures it after the program's last own measurement; llvm.threadlocal.address (every __thread access) and
; llvm.thread.pointer (__get_tp = mov %fs:0) are classical host intrinsics kept as they are: ONE THREAD (rule 24), so a
; thread-local object is the one thread's object at its host address, and llvm.threadlocal.address IS that address, a
; classical ptr. The object lives on the bus through the overlay like any global (rule 20): nothing is allocated, seeded
; or registered for it. The Darwin x86-64 backend has no code generation for llvm.thread.pointer, so this host's trace
; cannot exercise it; its lowering is the same as threadlocal.address's (a classical call returning an address), only the
; latter is shown.
; tls_q. `tl = x + 1` is a bus store at the classical address of tl (ptrtoint of the intrinsic's result), a KEPT store
; (rule 5, sentence 3): its tape slot and its value rail x + 1 stay for the shot. Because the image x + 1 now lives, x is
; dead after the add and rule 6 cleans it right after the update (t = (x + 1) - 1, copy, uncompute t, free x).
; touch(&tl, c) passes a classical pointer and a classical int: the all-zero mask (§1.4, rules 18, 21: a pointer is one
; scalar, nothing about the pointee crosses the call), touch's OWN symbol, never inlined. The call is a memory version
; change (touch writes memory). The load of tl after it is a fresh bus-load copy (rule 3); the shl reads it, and the copy
; is un-copied right after the shl, before its measurement (rule 5 sentence 1; no memory version change follows).
; touch. `*p += c` is load, add, store on the same SSA pointer with nothing between: rule 5's IN-PLACE FORM with a rule-6
; bijection (the add of the classical c) as its one step, as 195's bump: swap-out into a fresh |0> rail, y' = y + c with
; the clean of the old rail, swap-in of y', free of the rail that now holds the cell's |0>. The same body serves host
; callers and all-classical calls (§1.3 overlay).
; SPEC GAP: rule 19 / §1.3 ask for a __cq_clone_register row (the _t clone, _t_ctl and their twins) per externally
; visible function. No conforming example of the corpus emits one for a function that is only externally visible; this
; module follows the corpus (197, 200, 204) and registers nothing for ctz_q, trap_q and tls_q.
; SPEC GAP: CR fixes no calling convention, linkage or attributes for a lowered own symbol; touch keeps -O1's internal
; fastcc (195, 200), and the memory facts of the original (nocapture, memory(argmem: readwrite)) are dropped: the
; lowered body calls the backend.
source_filename = "arch_primitives.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@tl = internal thread_local global i32 0, align 4    ; IR: @tl  (the one thread's object at its host address, on the bus through the overlay: rules 20, 24)

define i32 @ctz_q(i64 noundef %0, double noundef %1) {
  %3 = call i32 @cqrt_alloc_i64(i64 %0)    ; IR: %3 = cq_theta_ull(%0, %1)  [register x, 64 bits]
  call void @cqrt_ry_i64(i32 %3, double %1)    ; IR: %3 = cq_theta_ull(%0, %1)  [Ry]
  %4 = call i32 @cq_template_or_i64_hl(i32 %3, i64 4294967296)    ; IR: %4 = or i64 %3, 4294967296
  %5 = call i32 @cq_template_cttz_i64(i32 %4)    ; IR: %5 = llvm.cttz.i64(%4, true)  (trailing zeros; the literal is a poison promise, not an operand)
  %6 = call i32 @cq_template_trunc_i64_to_i32(i32 %5)    ; IR: %6 = trunc i64 %5 to i32  [result rail]
  call void @cq_template_cttz_i64_unc(i32 %5, i32 %4)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  call void @cq_template_or_i64_hl_unc(i32 %4, i32 %3, i64 4294967296)    ; IR: uncompute %4
  call void @cqrt_free(i32 %4)    ; IR: release the %4 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_ui32(%6)
  ret i32 %7    ; IR: ret i32 %7
}

define i32 @trap_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %4, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [predicate of the noreturn block %6]
  call void @cqrt_abort_i1(i32 %5)    ; IR: block %6: llvm.trap(); unreachable  (noreturn arm flag, kept allocated; measured by the backend at end of shot)
  %6 = call i32 @cq_template_add_i32_hl(i32 %4, i32 1)    ; IR: %8 = add nsw i32 %4, 1  (block %7, runs uncontrolled)
  %7 = call i32 @cq_template_sub_i32_hl(i32 %6, i32 1)    ; IR: rule 6: t = r - 1 recomputes the old x (the update is a bijection in it)
  call void @cqrt_copy_i32(i32 %7, i32 %4)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %7, i32 %6, i32 1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %7)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the old x rail (|0> after the copy)
  %8 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %8    ; IR: ret i32 %9
}

define i32 @tls_q(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 1)    ; IR: %5 = add nsw i32 %4, 1
  %7 = call i32 @cq_template_sub_i32_hl(i32 %6, i32 1)    ; IR: rule 6: t = (x + 1) - 1 recomputes the old x (the add is a bijection in it; its image is kept by the store)
  call void @cqrt_copy_i32(i32 %7, i32 %5)    ; IR: rule 6: x ^= t: the dead x rail is now |0>
  call void @cq_template_sub_i32_hl_unc(i32 %7, i32 %6, i32 1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %7)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old x rail (|0> after the copy)
  %8 = call align 4 ptr @llvm.threadlocal.address.p0(ptr align 4 @tl)    ; IR: %6 = llvm.threadlocal.address(@tl)  (classical host intrinsic: the one thread's address of tl, rule 24)
  %9 = ptrtoint ptr %8 to i64    ; IR: %6 as its run-time address (the _hl operand)
  call void @cqrt_qram_store_i32_hl(i32 %4, i64 %9, i32 %6)    ; IR: store i32 %5, ptr %6: tl = x + 1  (kept store at a classical address: tape slot and value rail stay, no _unc)
  call fastcc void @touch(ptr %8, i32 %2)    ; IR: call fastcc void @touch(ptr %6, i32 %2): a classical pointer and a classical int, mask 00 = touch's own symbol (a memory version change)
  %10 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 %9)    ; IR: %7 = load i32, ptr %6: tl  (a fresh copy of the cell after touch's update)
  %11 = call i32 @cq_template_shl_i32_hl(i32 %10, i32 1)    ; IR: %8 = shl nsw i32 %7, 1  [result rail]
  call void @cqrt_qram_load_i32_hl_unc(i32 %10, i32 %4, i64 %9)    ; IR: un-copy %7 (its last reader %8 is done; no memory version change since the load, rule 5)
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  %12 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %9 = cq_measure_si32(%8)
  ret i32 %12    ; IR: ret i32 %9
}

define internal fastcc void @touch(ptr %0, i32 %1) unnamed_addr {
  %3 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %4 = ptrtoint ptr %0 to i64    ; IR: the address p as the _hl operand (classical, run time)
  %5 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %3 = load i32, ptr %0: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 %4, i32 %5)    ; IR: %3 = load i32, ptr %0: swap-out: the rail holds *p, the cell |0>
  %6 = call i32 @cq_template_add_i32_hl(i32 %5, i32 %1)    ; IR: %4 = add nsw i32 %3, %1
  %7 = call i32 @cq_template_sub_i32_hl(i32 %6, i32 %1)    ; IR: rule 6: t = y' - c recomputes the old *p
  call void @cqrt_copy_i32(i32 %7, i32 %5)    ; IR: rule 6: the old rail ^= t: |0>
  call void @cq_template_sub_i32_hl_unc(i32 %7, i32 %6, i32 %1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %7)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %5)    ; IR: release the old *p rail (|0> after the copy)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 %4, i32 %6)    ; IR: store i32 %4, ptr %0: swap-in: the cell holds *p + c, the rail the cell's |0>
  call void @cqrt_free(i32 %6)    ; IR: release the rail (|0>): nothing remains of the update
  ret void    ; IR: ret void
}

declare i32 @__cq_mem()
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_load_i32_hl_unc(i32, i32, i64)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_ry_i64(i32, double)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_abort_i1(i32)
declare i32 @cq_template_or_i64_hl(i32, i64)
declare void @cq_template_or_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_cttz_i64(i32)
declare void @cq_template_cttz_i64_unc(i32, i32)
declare i32 @cq_template_trunc_i64_to_i32(i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare i32 @cq_template_shl_i32_hl(i32, i32)
declare ptr @llvm.threadlocal.address.p0(ptr)

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
