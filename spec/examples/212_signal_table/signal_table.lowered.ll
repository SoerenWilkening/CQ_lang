; HAND-WRITTEN. Rules: 16 (signal table, effect entry), 19 (address rail dispatch, table clones), 2, 5, 6, 7, 8, 14, 20;
; §1.3 (bundle), §1.4 (table clone, activation counter).
; Checked: signal_table: x (%6, measured -> %39) and hit (the load copy %40, measured -> %41); the cell __cq_sig[30]
; at exit = the address of on_usr1 (HOST); the cell hit at exit = (x > k ? 30 : 0), given hit = 0 at entry.
; Expected: signal_table(0, .5, 1): Ry(.5) acts on every qubit of the i32 rail x = 0, so each bit is 1 with
; probability s = sin^2(.25) = 0.061209. x > 1 (signed) iff bit 31 is 0 and one of bits 1..30 is 1:
; P(x > 1) = (1 - s)(1 - (1 - s)^30) = 0.797654. On that branch the cell __cq_sig[30] holds the address of on_usr1,
; the one registered function of type void (i32), so its flag is 1, on_usr1 runs once and hit = 30; the complement
; predicate is 0 on every branch and the effect entry raise is never performed. The two measurements are perfectly
; correlated: (x, hit) = (v, 30) for v > 1 and (v, 0) for v <= 1; P(hit = 30) = 0.797654, P(hit = 0) = 0.202346
; (x = 0: 0.132498; x = 1: 0.008639; x < 0: 0.061209). The function returns v + 30 (v > 1) or v: 0 with p = 0.132498,
; 2^b + 30 with p = (1 - s)^31 s = 0.008639 for each bit b in 1..30.
; Clean: signal_table: the dead result of signal (%8: a load copy with no consumer, un-copied before the store);
; the arm flag x > k (%10); per candidate of the dispatch: its flag (%20), the conjunction with the arm flag (%21),
; the |30> argument seed (%22) and the complement predicate of the chain (%25), the chain popped and uncomputed by
; the reverse loop; un-copied under the arm flag but left allocated (rule 5 sentence 1: the table clone call, a
; memory version change, overtakes it): the load copy of the cell __cq_sig[30] (%11, the address rail of the
; dispatch), un-copied after the reverse loop, its last reader the last flag's _unc. __cq_q_on_usr1_1_t_ctl: the swapped-out old hit (%9), the sum (%10), the inverse of the composite
; update (%12, %13) and the rail the cell's |0> went to (%11). on_usr1 and __cq_q_on_usr1_1_t: the swap rail only (the
; add is rule 6's in-place update on it, addc_i32 / add_i32; |0> after the swap-in).
; Kept: signal_table: x (rotated, measured); the load copy of hit (measured); by rule 5 sentence 3 the tape slot and the value seed (%9, the i64 address of on_usr1)
; of the store into __cq_sig[30]; the function's tape (%5). The clones keep nothing: hit += s is the in-place form.
; At the cutoff (not reached here) __cq_q_on_usr1_1_t_ctl keeps one overflow predicate rail (rule 14).
; Rotations: (Ry, x, th, 1).
; SIGNAL (rule 16, signal table). signal(SIGUSR1, on_usr1) has classical arguments and no predicate in scope: the host
; call is made as it stands, then the cell &__cq_sig[30] is loaded (the call's result: the previously registered
; address) and the handler's address is stored there, a kept store of an i64 seed at a classical address. Everything
; is classical-valued, so the store writes the host array and the cell stays HOST (§1.3).
; RAISE (rules 16, 19). raise(SIGUSR1) sits in the arm of x > k: the cell is loaded by the _hl_controlled form under
; the arm flag (rule 5: no access is hoisted; the rail is |0> where the flag is 0) and the call goes through that
; address rail. No handler is tracked: the candidates are the functions of type void (i32) in the clone table, read
; at run time (__cq_clone_count / __cq_clone_at; a classical loop). Candidate i has the flag f_i = (rail == a_i);
; its _ctl table clone (__cq_clone_resolve(a_i, 1)) is called under f & f_i with the signal number as a seed rail and
; K, and its _ctl twin (kind 3) once, right after it (no result to keep). The complement branch is the effect entry
; "raise" with the signal number as its _lit field, under p_n, where p_0 = f and p_{i+1} = p_i & NOT f_i.
; ON_USR1 (rules 5, 6, 19, §1.4). Its address is taken, so it has the four table clones and one row of the clone
; table, registered by a module constructor. hit += s is load, add, store on one pointer with no memory version
; change between: the in-place form on the cell (swap-out, add as rule 6's in-place update on the swap rail, swap-in). In
; the _ctl clone the swaps are _hl_controlled and the update is the composite c ? hit + s : hit (rule 6's clean, never
; the in-place gate). on_usr1 writes memory, so
; rule 18 gives it no twin: the table twins do nothing (nothing was pushed). The _ctl clone and its twin count the
; live _ctl activations in a module-internal counter and the clone is cut at K (§1.4, rule 14).
; SPEC GAP: rule 16's ordinary-host-call test makes every externally visible function "called after an event" when
; the module contains one (here the effect entry raise), which would turn this signal call into an effect entry; the
; signal-table bullet asks only for classical arguments and no predicate in scope. The bullet wins (the signal table
; is a class below "effect entry"): the host call is made as it stands whatever precedes it, and the
; ordinary-host-call test is not asked for signal.
; SPEC GAP: the result of signal is unused. Rule 16 says signal IS the load and the store; the load is emitted and
; un-copied at once (rule 5 sentence 1, no consumer). Omitting a dead load is semantically equal (§6).
; SPEC GAP: rule 16 does not say what raise dispatches. Here: a call of function type void (i32) (C's handler type)
; with the signal number as its one actual (a seed, table clone ABI), and the entry raise has the signal number as
; its one field. The result of raise is unused here, so the bare effect form is used (rule 16: the _<W> form only
; when the program reads the result; BACKEND_ABI §1.11's "a callee without a result" is the narrower wording). A
; result the program reads would be the _i32 entry's rail under the complement and 0 under every candidate flag.
; SPEC GAP: CR fixes no module-internal name. As in 205 and 211: the activation counter is the internal global
; i32 @__cq_act_<fn>, the cut test icmp ult d, K, the constructor internal void @__cq_register() at priority 65535,
; the sig string private @.cq.sig (the LLVM 19 type print of the function type); effect names are @.cq.effect.<name>
; (102, 209). §6 compares no name.
; SPEC GAP: rule 19 gives the complement of the candidate flags no spelling. Used: p_0 = the predicate in scope,
; p_{i+1} = p_i & NOT f_i (not_i1(f_i), and_i1(p_i, f_i, fresh), not_i1(f_i)) in the candidate loop, p_n the entry's
; predicate; p_i and f_i are pushed and the reverse loop uncomputes them (rule 14's classical loop). Each
; candidate's conjunction is and_i1 of the arm flag and f_i. 211 spells it the same way (not_i1 / and_i1 /
; not_i1 per candidate).
; SPEC GAP: CR does not say whether an effect entry's predicate rail is kept; it is uncomputed after the entry (102,
; and rule 8: only a flag that controls a kept store is kept).
; SPEC GAP (corpus convention, §5): §1.3 / rule 19 ask for a clone-table row per externally visible function too
; (signal_table: its _t, _t_ctl and twins with the angle as an f64 rail). The example never takes that address, so
; the row, its table clones and twins are omitted as in 197, 200, 204 and 211; the compiler emits them, and the
; omission is not part of the pinned lowering. signal_table has another function type, so the dispatch is the same.
; SPEC GAP: §1.4 makes the _ctl twin read and restore the activation counter even where the twin does nothing else
; (as 211's peek twin), and CR §1.4 names K only for the clone while BACKEND_ABI §3 gives the twin K as its last
; argument: the table twins take K last, _unc(s, K) and _ctl_unc(pred, s, K).
source_filename = "signal_table.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@hit = internal global i32 0, align 4
@__cq_sig = external global [65 x i64]    ; IR: the bundle's signal table (§1.3)
@.cq.effect.raise = private unnamed_addr constant [6 x i8] c"raise\00", align 1    ; IR: effect entry name for raise (a host string)
@.cq.sig = private unnamed_addr constant [11 x i8] c"void (i32)\00", align 1    ; IR: the function type of a signal handler, the key of the dispatch and of on_usr1's row
@__cq_act_on_usr1 = internal global i32 0, align 4    ; IR: on_usr1's live _ctl activations (§1.4: it has a table clone)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]    ; IR: the module constructor that registers the clone-table rows

define i32 @signal_table(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call ptr @signal(i32 noundef 30, ptr noundef nonnull @on_usr1)    ; IR: %5 = signal(30, @on_usr1): classical arguments, no predicate in scope: the host call as it stands (its host result is not read)
  %8 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: %5 = signal(...): the bus load of the cell &__cq_sig[30], the call's result (the previous handler address)
  call void @cqrt_qram_load_i64_hl_unc(i32 %8, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: un-copy %5 (unused; before the store, the next memory version change)
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  %9 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @on_usr1 to i64))    ; IR: %5 = signal(...): the handler address as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64), i32 %9)    ; IR: %5 = signal(...): the bus store of the handler address into &__cq_sig[30]  (kept store, rule 5)
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %6 = icmp sgt i32 %4, %2  [arm flag f of block %7]
  %11 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %10, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: %8 = raise(30): the cell &__cq_sig[30] loaded under the arm flag  [the address rail of the call; overtaken by the clone call, un-copied after the reverse loop]
  %12 = call i32 @__cq_clone_count(ptr @.cq.sig)    ; IR: %8 = raise(30): rule 19, the number n of registered functions of type void (i32)
  br label %13
13:
  %14 = phi i32 [ 0, %3 ], [ %26, %17 ]    ; IR: candidate index i (classical loop over the clone table)
  %15 = phi i32 [ %10, %3 ], [ %25, %17 ]    ; IR: complement predicate p_i  (p_0 = the arm flag)
  %16 = icmp ult i32 %14, %12
  br i1 %16, label %17, label %27
17:
  %18 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %14)    ; IR: %8 = raise(30): candidate address a_i
  %19 = ptrtoint ptr %18 to i64    ; IR: a_i as its run-time address
  %20 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %19)    ; IR: %8 = raise(30): f_i = (address rail == a_i)
  %21 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %8 = raise(30): fresh |0> for the conjunction
  call void @cqrt_and_i1(i32 %10, i32 %20, i32 %21)    ; IR: %8 = raise(30): f & f_i, the predicate of candidate i
  %22 = call i32 @cqrt_alloc_i32(i32 30)    ; IR: %8 = raise(30): the classical actual 30 as a seed (table clone ABI: every formal a handle)
  %23 = call ptr @__cq_clone_resolve(ptr %18, i32 1)    ; IR: %8 = raise(30): the _ctl table clone of a_i (kind 1)
  call void %23(i32 %21, i32 %22, i32 4)    ; IR: %8 = raise(30): the handler under f & f_i  [K]  (a memory version change)
  %24 = call ptr @__cq_clone_resolve(ptr %18, i32 3)    ; IR: %8 = raise(30): the _ctl twin of a_i (kind 3)
  call void %24(i32 %21, i32 %22, i32 4)    ; IR: %8 = raise(30): the twin, called exactly once (no result: right after the call)  [K]
  call void @cqrt_free(i32 %22)    ; IR: release the seed (|30>, never written, rule 7)
  call void @cqrt_and_i1(i32 %10, i32 %20, i32 %21)    ; IR: uncompute the conjunction (after its last controlled call)
  call void @cqrt_free(i32 %21)    ; IR: release the conjunction (|0>)
  %25 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %8 = raise(30): fresh |0> for p_{i+1}
  call void @cqrt_not_i1(i32 %20)    ; IR: X bracket: NOT f_i
  call void @cqrt_and_i1(i32 %15, i32 %20, i32 %25)    ; IR: %8 = raise(30): p_{i+1} = p_i & NOT f_i
  call void @cqrt_not_i1(i32 %20)    ; IR: X bracket closes
  call void @cqrt_push(i32 %15)    ; IR: p_i for the reverse loop
  call void @cqrt_push(i32 %20)    ; IR: f_i for the reverse loop
  %26 = add nuw nsw i32 %14, 1
  br label %13
27:
  call void @cqrt_tape_write_i32_lit(i32 %5, i32 30)    ; IR: %8 = raise(30): argument 0 of the effect entry, classical: a _lit field
  call void @cqrt_tape_effect_controlled(i32 %15, i32 %5, ptr @.cq.effect.raise, i32 1)    ; IR: %8 = raise(30): the complement branch (no registered function), the effect entry raise under p_n; bare form, %8 is unused
  br label %28
28:
  %29 = phi i32 [ %12, %27 ], [ %33, %32 ]    ; IR: candidates still to undo, from n down to 0
  %30 = phi i32 [ %15, %27 ], [ %35, %32 ]    ; IR: p_{j+1}, the predicate being undone
  %31 = icmp sgt i32 %29, 0
  br i1 %31, label %32, label %38
32:
  %33 = add nsw i32 %29, -1    ; IR: candidate index j
  %34 = call i32 @cqrt_pop()    ; IR: f_j
  %35 = call i32 @cqrt_pop()    ; IR: p_j
  %36 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %33)    ; IR: candidate address a_j again
  %37 = ptrtoint ptr %36 to i64    ; IR: a_j as its run-time address
  call void @cqrt_not_i1(i32 %34)    ; IR: X bracket: NOT f_j
  call void @cqrt_and_i1(i32 %35, i32 %34, i32 %30)    ; IR: uncompute p_{j+1} (after the effect entry, its last use)
  call void @cqrt_not_i1(i32 %34)    ; IR: X bracket closes
  call void @cqrt_free(i32 %30)    ; IR: release p_{j+1} (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %34, i32 %11, i64 %37)    ; IR: uncompute f_j (the address rail still holds the loaded value)
  call void @cqrt_free(i32 %34)    ; IR: release f_j (|0>)
  br label %28
38:
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %11, i32 %10, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: un-copy %8's load copy under the arm flag (after its last reader, the last flag's _unc; overtaken by the clone call, so it stays allocated: rule 5 sentence 1)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %6, i32 %2)    ; IR: uncompute %6 (after its last controlled gate; before x is measured)
  call void @cqrt_free(i32 %10)    ; IR: release the %6 rail (|0>)
  %39 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %10 = cq_measure_si32(%4)
  %40 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr @hit to i64))    ; IR: %11 = load i32, ptr @hit  [a bus load after the join, a rail]
  %41 = call i32 @cqrt_measure_i32(i32 %40)    ; IR: %12 = cq_measure_si32(%11)  [the load copy is the measured rail, rule 2]
  %42 = add nsw i32 %41, %39    ; IR: %13 = add nsw i32 %12, %10  (classical: two outcomes)
  ret i32 %42    ; IR: ret i32 %13
}

; the own symbol (the all-zero mask, §1.4): what host code reaches when the host delivers the signal
define internal void @on_usr1(i32 noundef %0) {
  %2 = call i32 @__cq_mem()    ; IR: the bus M
  %3 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = load i32, ptr @hit: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @hit to i64), i32 %3)    ; IR: %2 = load i32, ptr @hit: swap-out: the rail holds hit, the cell |0>
  call void @cqrt_addc_i32(i32 %3, i32 %0)    ; IR: %3 = add nsw i32 %2, %0  [rule 6, in-place update: the old hit is dead after the add, so y' IS the swap rail]
  call void @cqrt_qram_swap_i32_hl(i32 %2, i64 ptrtoint (ptr @hit to i64), i32 %3)    ; IR: store i32 %3, ptr @hit: swap-in: the cell holds hit + s, the rail the cell's |0>
  call void @cqrt_free(i32 %3)    ; IR: release the swap rail (|0>): nothing remains of the update
  ret void    ; IR: ret void
}

; the table clone (§1.4): every formal a handle, then K; no result, nothing minted, nothing pushed
define internal void @__cq_q_on_usr1_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()    ; IR: the bus M
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = load i32, ptr @hit: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @hit to i64), i32 %4)    ; IR: %2 = load i32, ptr @hit: swap-out
  call void @cqrt_add_i32(i32 %0, i32 %4)    ; IR: %3 = add nsw i32 %2, %0  (s is a rail)  [rule 6, in-place update: the old hit is dead after the add, so y' IS the swap rail]
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @hit to i64), i32 %4)    ; IR: store i32 %3, ptr @hit: swap-in
  call void @cqrt_free(i32 %4)    ; IR: release the swap rail (|0>)
  ret void    ; IR: ret void
}

; the table clone's twin: on_usr1 writes memory, so rule 18 gives it no twin; nothing was pushed, nothing to pop
define internal void @__cq_q_on_usr1_1_t_unc(i32 %0, i32 %1) {
  ret void
}

; the _ctl table clone: the predicate first, every gate under it
define internal void @__cq_q_on_usr1_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M
  %5 = load i32, ptr @__cq_act_on_usr1, align 4    ; IR: the activation's depth d (§1.4), read on entry
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr @__cq_act_on_usr1, align 4    ; IR: one more live _ctl activation
  %7 = icmp ult i32 %5, %2    ; IR: rule 14: the body runs while d is below K
  br i1 %7, label %8, label %14
8:
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = load i32, ptr @hit: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %4, i64 ptrtoint (ptr @hit to i64), i32 %9)    ; IR: %2 = load i32, ptr @hit: swap-out under the predicate (pred = 0: nothing touched, the rail stays |0>)
  %10 = call i32 @cq_template_add_i32(i32 %9, i32 %1)    ; IR: %3 = add nsw i32 %2, %0
  %11 = call i32 @cq_template_select_i32(i32 %0, i32 %10, i32 %9)    ; IR: %3: the composite update y' = pred ? hit + s : hit (rule 5, under a quantum predicate)
  call void @cq_template_add_i32_unc(i32 %10, i32 %9, i32 %1)    ; IR: uncompute the sum (it reads the old rail: first, rule 6)
  call void @cqrt_free(i32 %10)    ; IR: release the sum (|0>)
  %12 = call i32 @cq_template_sub_i32(i32 %11, i32 %1)    ; IR: rule 6: y' - s
  %13 = call i32 @cq_template_select_i32(i32 %0, i32 %12, i32 %11)    ; IR: rule 6: t = pred ? y' - s : y', the inverse of the composite: the old rail's value
  call void @cqrt_copy_i32(i32 %13, i32 %9)    ; IR: rule 6: the old rail ^= t: |0>
  call void @cq_template_select_i32_unc(i32 %13, i32 %0, i32 %12, i32 %11)    ; IR: rule 6: uncompute t
  call void @cq_template_sub_i32_unc(i32 %12, i32 %11, i32 %1)    ; IR: rule 6: uncompute y' - s
  call void @cqrt_free(i32 %13)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %12)    ; IR: release y' - s (|0>)
  call void @cqrt_free(i32 %9)    ; IR: release the old hit rail (|0> after the copy)
  call void @cqrt_qram_swap_i32_hl_controlled(i32 %0, i32 %4, i64 ptrtoint (ptr @hit to i64), i32 %11)    ; IR: store i32 %3, ptr @hit: swap-in under the predicate: the cell holds hit + s, the rail |0> on both branches
  call void @cqrt_free(i32 %11)    ; IR: release the rail (|0>)
  store i32 %5, ptr @__cq_act_on_usr1, align 4    ; IR: the activation ends (the counter is d again)
  ret void    ; IR: ret void
14:
  %15 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: rule 14, the cut at d = K: fresh |0>
  call void @cqrt_copy_i1(i32 %0, i32 %15)    ; IR: rule 14: the predicate copied out, the kept overflow predicate (an output rail)
  store i32 %5, ptr @__cq_act_on_usr1, align 4    ; IR: the activation ends
  ret void    ; IR: ret void (no result)
}

; the _ctl twin: no rule-18 twin and nothing pushed; it counts its activation like the clone (§1.4)
define internal void @__cq_q_on_usr1_1_t_ctl_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_on_usr1, align 4    ; IR: the activation's depth d, read on entry
  %5 = add nsw i32 %4, 1
  store i32 %5, ptr @__cq_act_on_usr1, align 4    ; IR: one more live _ctl activation
  store i32 %4, ptr @__cq_act_on_usr1, align 4    ; IR: the activation ends
  ret void
}

; module constructor: one row per address-taken function (§1.3): fn, sig, _t, _t_ctl, _t_unc, _t_ctl_unc
define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @on_usr1, ptr @.cq.sig, ptr @__cq_q_on_usr1_1_t, ptr @__cq_q_on_usr1_1_t_ctl, ptr @__cq_q_on_usr1_1_t_unc, ptr @__cq_q_on_usr1_1_t_ctl_unc)    ; IR: on_usr1's row (its address is passed to signal)
  ret void
}

declare ptr @signal(i32 noundef, ptr noundef)
declare i32 @__cq_mem()
declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)
declare ptr @__cq_clone_resolve(ptr, i32)
declare i32 @__cq_clone_count(ptr)
declare ptr @__cq_clone_at(ptr, i32)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i64(i64)
declare void @cqrt_free(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_copy_i1(i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare void @cqrt_qram_swap_i32_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_write_i32_lit(i32, i32)
declare void @cqrt_tape_effect_controlled(i32, i32, ptr, i32)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare void @cqrt_addc_i32(i32, i32)
declare void @cqrt_add_i32(i32, i32)
declare i32 @cq_template_add_i32(i32, i32)
declare void @cq_template_add_i32_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32(i32, i32)
declare void @cq_template_sub_i32_unc(i32, i32, i32)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
