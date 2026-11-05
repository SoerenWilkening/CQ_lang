; HAND-WRITTEN. Rules: 19, 10, 8, 14, 18, 20, 21, 5 (in-place form; Memory, sentences 1 and 3), 2, 7, 16; §1.3 (the bus, qram_swap), §1.4.
; Checked: r + x + b (measured). r is the 4 cells at P, the address of the bus-resident r, read after the loop by the
; load copy %21 -> %22; the cells at P at exit hold r after every trip.
; Clean: inside every trip's clone call: the callee flag f = (x > k + i) (%8), the composed flag g = b & f (%9) and the
; swap rail of the in-place form (%10, |0> after its swap-in on both branches of g).
; Kept: the user registers x and b (control and compare inputs only, measured). r is the cell at P (rotated in place
; under control, rule 10 on a memory cell). Rule 5 sentence 3: the tape slot of the store r = r0 and its value rail, the
; seed alloc_i32(r0) (%13). Rule 2: the load copy of r (%21), measured, never un-copied.
; Rotations: Ry(tx) on x; Ry(tb) on b; for each trip i = 0..n-1 (classical, n > 0): Ry(t) on the cell at P (r) under
; b & (x > k + i).
; A CONTROLLED RY UNDER A COMPOSED CONTROL, ACROSS A CALL, INSIDE A CLASSICAL LOOP THAT SITS IN A QUANTUM ARM. Three
; pieces, each from an existing example:
;   (1) -O1 fuses the outer `if (b)` with the loop guard `n > 0` into one `and i1 %10, %11`. One operand is the bare
;       _Bool rail b (a rail is a condition by itself), the other is classical. A classical conjunct is split off as
;       a classical branch (rule 8): when it is false nothing runs, when it is true the predicate IS b. No AND flag is
;       computed in the caller, and the trip counter, the bound and `k + i` all stay classical (rule 14, classical
;       bound: no trip-local rail remains in the caller, so nothing is pushed and there is no reverse loop).
;   (2) `step(&r, ...)` takes r's ADDRESS, a call user, so the alloca of r is bus-resident (rule 20 (b)):
;       __cq_alloc(4, 4) at its program point, P = its run-time address (a classical i64), no alloca remains and the
;       lifetime markers are dropped (rule 16). `r = r0` is a bus store of the seed alloc_i32(r0) at P, a kept store
;       (rules 5, 7). The call to step runs under the quantum predicate b, and step has a rotation and bus accesses, so
;       it becomes a CONTROLLED CLONE with the predicate as its first parameter (rule 19: __cq_q_<fn>_<mask>_ctl). A
;       pointer is one scalar (§1.4, rules 18, 21): &r is a classical ptr (not computed from a rail), digit 0, and the
;       formal stays the C ptr; x is quantum, digit 1; k and t are classical: __cq_q_step_0100_ctl. Nothing about the
;       pointee crosses the call. The clone writes memory (an in-place form), so it has no twin, it has no result, and
;       each call is a memory version change (rules 5, 18).
;   (3) Inside the clone, the callee's own condition x > k becomes a flag f, and the composed control pred AND f is a
;       Toffoli into a fresh |0> flag g (rule 8). `*r = cq_theta(*r, t)` is `load p; cq_theta; store p` on the same
;       SSA pointer with no memory version change between: rule 5's in-place form at the classical address
;       p = ptrtoint %1, under g (rule 10 on a memory cell): swap-out into a |0> rail under g, Ry(t) under g on that
;       rail, swap-in under g, free (g = 0: nothing touched, the rail stays |0>). The cell is the register. Then g is
;       uncomputed with the same Toffoli (pred and f are unchanged) and f with its compare's _unc; both are freed
;       provably |0>. One clone call per trip; g, f and the swap rail are trip-local, so nothing survives the loop.
; After the loop `cq_measure(r)` reads r through a plain bus load at P (rule 3): the copy is the measured rail (rule 2).
; Nothing non-diagonal touches a user register except the in-place form on r's cell at P: the controlled swap pair and
; the controlled Ry between them, all under g.
; b and x are only control or compare inputs, so they are left untouched and measured by the user.
; SPEC GAP (corpus convention, §5): §1.3 / rule 19 ask for a __cq_clone_register row (the _t clone, _t_ctl and their
; twins) per externally visible function. As in 61, 200, 204, 211 and 212 nothing is registered for
; callee_controlled_ry_in_loop (its address is never taken here); the omission is not part of the pinned lowering.
; Regenerated 2026-11-05 for the flat bus (the earlier version kept r's handle in a classical slot, passed the slot to
; __cq_q_step_1100_ctl with a pointee digit and rotated the handle it loaded from the slot).
source_filename = "callee_controlled_ry_in_loop.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

define i32 @callee_controlled_ry_in_loop(i32 noundef %0, double noundef %1, double noundef %2, i32 noundef %3, i32 noundef %4, double noundef %5, i32 noundef %6) {
  %8 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %9 = call ptr @__cq_alloc(i64 4, i64 4)    ; IR: %8 = alloca i32, align 4: bus-resident (rule 20 (b): its address is a call argument), one zeroed block (rule 16)
  %10 = ptrtoint ptr %9 to i64    ; IR: %8 as its run-time address P (classical i64)
  %11 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %9 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %11, double %1)    ; IR: %9 = cq_theta_si32(%0, %1)  [Ry]
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %10 = cq_theta_i1(false, %2)  [register b]
  call void @cqrt_ry_i1(i32 %12, double %2)    ; IR: %10 = cq_theta_i1(false, %2)  [Ry]
  %13 = call i32 @cqrt_alloc_i32(i32 %3)    ; IR: llvm.lifetime.start dropped (rule 16); store i32 %3, ptr %8: the classical value r0 as a seed (rule 7), the store's value rail, kept with it
  call void @cqrt_qram_store_i32_hl(i32 %8, i64 %10, i32 %13)    ; IR: store i32 %3, ptr %8  [r = r0: kept store at P, rule 5 sentence 3]
  %14 = icmp sgt i32 %6, 0    ; IR: %11 = icmp sgt i32 %6, 0  (classical)
  br i1 %14, label %15, label %20    ; IR: %12 = and i1 %10, %11; br i1 %12  (classical conjunct split off; the quantum conjunct b is the predicate of every call below)

15:; preds = %7, %15
  %16 = phi i32 [ %18, %15 ], [ 0, %7 ]    ; IR: %14  (classical trip counter i)
  %17 = add nsw i32 %16, %4    ; IR: %15 = add nsw i32 %14, %4  (classical k + i)
  call fastcc void @__cq_q_step_0100_ctl(i32 %12, ptr noundef %9, i32 noundef %11, i32 noundef %17, double noundef %5)    ; IR: call fastcc void @step(%8, %9, %15, %5) under predicate %10: the controlled clone of mask 0100 (classical ptr, x quantum); it writes memory, no twin (rule 18)
  %18 = add nuw nsw i32 %16, 1    ; IR: %16  (classical)
  %19 = icmp eq i32 %18, %6    ; IR: %17  (classical)
  br i1 %19, label %20, label %15    ; IR: br i1 %17

20:; preds = %15, %7
  %21 = call i32 @cqrt_qram_load_i32_hl(i32 %8, i64 %10)    ; IR: %19 = load i32, ptr %8  [r: a bus load at P, a rail (rule 3)]
  %22 = call i32 @cqrt_measure_i32(i32 %21)    ; IR: %20 = cq_measure_si32(%19)  [the load copy is the measured rail, rule 2: never un-copied, stays allocated]
  %23 = call i32 @cqrt_measure_i32(i32 %11)    ; IR: %21 = cq_measure_si32(%9)
  %24 = add nsw i32 %23, %22    ; IR: %22  (classical)
  %25 = call i1 @cqrt_measure_i1(i32 %12)    ; IR: %23 = cq_measure_i1(%10)
  %26 = zext i1 %25 to i32    ; IR: %24  (classical)
  %27 = add nsw i32 %24, %26    ; IR: %25  (classical)
  ret i32 %27    ; IR: ret i32 %25  (llvm.lifetime.end dropped)
}

define internal fastcc void @__cq_q_step_0100_ctl(i32 %0, ptr noundef %1, i32 noundef %2, i32 noundef %3, double noundef %4) unnamed_addr {
  %6 = call i32 @__cq_mem()    ; IR: the bus M
  %7 = ptrtoint ptr %1 to i64    ; IR: %0 as its run-time address p (mask digit 0: the formal is the C ptr)
  %8 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %2, i32 %3)    ; IR: %5 = icmp sgt i32 %1, %2  [the callee's own predicate]
  %9 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: path predicate of block %6 = pred & %5  [fresh |0> flag]
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %9)    ; IR: pred & %5  (Toffoli into the |0> flag)
  %10 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: block %6: %7 = load i32, ptr %0: in-place form under pred & %5, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %6, i64 %7, i32 %10)    ; IR: block %6: %7 = load i32, ptr %0: swap-out under pred & %5 (0: nothing touched, the rail stays |0>)
  call void @cqrt_ry_i32_controlled(i32 %9, i32 %10, double %4)    ; IR: block %6: %8 = cq_theta_si32(%7, %3)  [Ry on the cell's content under pred & %5, rule 10 on a memory cell]
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %9, i32 %6, i64 %7, i32 %10)    ; IR: block %6: store i32 %8, ptr %0: swap-in under pred & %5: the cell holds %8, the rail |0> on both branches
  call void @cqrt_free(i32 %10)    ; IR: release the swap rail (|0>)
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %9)    ; IR: uncompute pred & %5 (pred, %5 unchanged)
  call void @cqrt_free(i32 %9)    ; IR: release the composed flag (|0>)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %8, i32 %2, i32 %3)    ; IR: uncompute %5 (x unchanged: it is not the rotated register)
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  ret void    ; IR: ret void
}

declare i32 @__cq_mem()
declare ptr @__cq_alloc(i64, i64)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1(i32, double)
declare void @cqrt_ry_i32_controlled(i32, i32, double)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare void @cqrt_free(i32)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
