; HAND-WRITTEN. Rules: 16 (signal table, effect entries), 19 (address rail dispatch, table clones), 20, 24 (unobservable
; volatile), 2, 5, 7, 8, 14; §1.3 (bundle), §1.4 (table clone, activation counter).
; Checked: raise_handled: x (measured) and hit (the load copy of @hit after the join, measured); the cell __cq_sig[30]
; at exit = the address of h (HOST); the cell @hit at exit = (x > k ? 30 : 0), given hit = 0 at entry. raise_default:
; x (measured). remove_cond: x (measured).
; Expected: raise_handled(0, .5, 1): Ry(.5) acts on every qubit of the i32 rail x = 0, each bit 1 with probability
; s = sin^2(.25) = 0.061209; P(x > 1) = (1 - s)(1 - (1 - s)^30) = 0.797654. On that branch the cell __cq_sig[30] holds
; the address of h, the one registered function of type void (i32), so its flag is 1, h's _ctl table clone stores 30
; into @hit, and the complement predicate is 0 (the effect entry raise is never performed): (x, hit) = (v, 30) for
; v > 1 and (v, 0) for v <= 1. raise_default(0, .5, 1): nothing is registered at __cq_sig[6] (the cell is 0), so h's
; flag is 0 on every branch and the complement predicate is x > 1: the effect entry raise(6) is performed by the
; backend on the shots where it reads 1 (P = 0.797654), and the default action of SIGABRT terminates there.
; remove_cond(0, .5, 1): the effect entry remove("/tmp/cq_x") is performed where x > 1 (P = 0.797654).
; Clean: raise_handled and raise_default: the dead result of signal (raise_handled only: the load copy of
; __cq_sig[30], un-copied before the store); the arm flag x > k; per candidate of the dispatch: its flag f_i and the
; complement predicate p_{i+1}, pushed and uncomputed by the reverse loop. remove_cond: the predicate flag (x > k).
; Kept: the user register x of each function (rotated, measured); raise_handled: the load copy of hit (measured), by
; rule 5 sentence 3 the tape slot and the value seed (the i64 address of h) of the store into __cq_sig[30];
; raise_handled and raise_default: the load copy of the signal cell under the arm flag (the address rail of the
; dispatch), un-copied under the arm flag after the reverse loop, its last reader, and left allocated (the table clone
; call is a memory version change between, rule 5 sentence 1), per candidate the conjunction
; f & f_i and the |sig> argument seed (the control rail and the value rail of the kept store h's _ctl table clone
; makes, rules 5, 7, 8; SPEC GAP below), and the tape slot of that store (one per candidate call, also under a
; control that reads 0); the function's tape (each function). h: the tape slot and the value seed of its store.
; At the cutoff (not reached here) __cq_q_h_1_t_ctl keeps one overflow predicate rail (rule 14).
; Rotations: (Ry, x, th, 1) in each function.
; CLASSICAL EFFECTS UNDER A QUANTUM PREDICATE (rule 16). A host effect cannot happen "in superposition", and executing
; it on a classical reading of the predicate would be a measurement, so a call with no body under a quantum predicate is
; an EFFECT ENTRY on the function's tape: its fields (a classical argument a tape_write_<W>_lit, a pointer its address
; as an i64), then cqrt_tape_effect_controlled(pred, tape, name), name = @.cq.effect.<callee>. When the backend
; performs it is BACKEND_ABI §1.11; the host call itself is never executed by the lowered program. The flag is
; uncomputed after the entry like any flag.
; MEMORY (rules 20, 24). static volatile sig_atomic_t hit is an internal global whose every use is a load or a store
; through it: its volatile is unobservable (rule 24), the qualifier is dropped, and its accesses are bus accesses at
; its host address (rule 20): nothing is allocated, seeded or registered for it, and its initializer 0 is the host
; byte the overlay reads. The later read of hit is a bus load after the join, a rail, measured (rule 2).
; SIGNAL (rule 16, signal table). signal(SIGUSR1, h) has classical arguments and no predicate in scope: the host call
; as it stands, then the bus load of the cell &__cq_sig[30] (its result, unused: un-copied before the store) and a
; kept store of h's address there (an i64 seed at a classical address). Everything is classical-valued, so the store
; writes the host array and the cell stays HOST (§1.3).
; RAISE (rules 16, 19). No handler is tracked at compile time: raise(sig) under the arm flag loads the cell
; &__cq_sig[sig] by the _hl_controlled form and calls through that address rail, a call of function type void (i32)
; with sig as its one actual. The candidates are the functions of that type in the clone table, read at run time
; (__cq_clone_count / __cq_clone_at; a classical loop); candidate i has the flag f_i = (rail == a_i), and its _ctl
; table clone (kind 1) is called under f & f_i with sig as a seed rail and K, its _ctl twin (kind 3) right after it.
; The complement branch is the effect entry raise with sig as its _lit field under p_n, where p_0 = f and
; p_{i+1} = p_i & NOT f_i. raise_handled and raise_default are the same construction: SIGABRT is no longer the abort
; arm of 45 (whether a handler exists is a run-time fact; the default action is the backend's performance of the
; entry). remove(path) has no body: the effect entry remove with the path's address as its _lit field. The results of
; signal/raise/remove are unused: the bare effect form.
; H (rules 5, 19, §1.4). Its address is taken (passed to signal), so it has the four table clones, one row of the
; clone table registered by a module constructor, and an activation counter. hit = s is a store with no load: a kept
; store (rule 5 sentence 3) of the seed alloc_i32(s) in the own symbol, of the formal rail s in __cq_q_h_1_t, and the
; _hl_controlled store under the predicate in __cq_q_h_1_t_ctl. h writes memory, so rule 18 gives it no twin: the
; table twins pop nothing; the _ctl twin counts its activation like the clone.
; SPEC GAP: rule 5 sentence 3 lets a caller that passed a store's value or control rail to a storing callee treat it
; by its own rules, and the dispatch caller has no record of the callee (rule 19), so its own rules would uncompute
; the conjunction f & f_i after the twin and free the |sig> seed (as 212 does for its non-storing handler). Here the
; callee stores both, and _tools/trace_check.py reports a free of a store's value or control rail without function
; boundaries; this example KEEPS the conjunction and the seed of every candidate call (rule 8: a flag that controls a
; kept store is kept with it; rule 7: the seed a store of a classical value mints is kept with it). Both readings leave
; the measured distribution unchanged: the conjunction is a function of f and f_i, and the seed is an unentangled
; basis state.
; SPEC GAP: rule 16's ordinary-host-call test makes every externally visible function "called after an event" when
; the module contains one; the signal-table bullet asks only for classical arguments and no predicate in scope and
; wins (212): the host call is made as it stands.
; SPEC GAP: rule 16 does not say what raise dispatches. As 212: a call of function type void (i32) with the signal
; number as its one actual (a seed, table clone ABI), the entry raise with the signal number as its one field.
; SPEC GAP: CR fixes no module-internal name. As in 205, 211 and 212: the activation counter @__cq_act_h, the cut test
; icmp ult d, K, the constructor @__cq_register at priority 65535, the sig string @.cq.sig, effect names
; @.cq.effect.<name>. §6 compares no name.
; SPEC GAP: rule 19 gives the complement of the candidate flags no spelling; as 211 and 212 (not_i1 / and_i1 /
; not_i1 per candidate, p_i and f_i pushed and uncomputed by the reverse loop).
; SPEC GAP (corpus convention, §5): the clone-table rows of the externally visible raise_handled, raise_default and
; remove_cond (their _t, _t_ctl and twins) are omitted as in 197, 200, 204, 211 and 212; none has type void (i32).
; SPEC GAP: the table twins take K last, _unc(s, K) and _ctl_unc(pred, s, K), as 212 (BACKEND_ABI §3).
source_filename = "effect_tape.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@hit = internal global i32 0, align 4    ; IR: @hit  (lives at its host address on the bus, rule 20; nothing seeded)
@.str = private unnamed_addr constant [10 x i8] c"/tmp/cq_x\00", align 1    ; IR: @.str
@__cq_sig = external global [65 x i64]    ; IR: the bundle's signal table (§1.3)
@.cq.effect.raise = private unnamed_addr constant [6 x i8] c"raise\00", align 1    ; IR: effect entry name for raise
@.cq.effect.remove = private unnamed_addr constant [7 x i8] c"remove\00", align 1    ; IR: effect entry name for remove
@.cq.sig = private unnamed_addr constant [11 x i8] c"void (i32)\00", align 1    ; IR: the function type of a signal handler, the key of the dispatch and of h's row
@__cq_act_h = internal global i32 0, align 4    ; IR: h's live _ctl activations (§1.4: it has a table clone)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]    ; IR: the module constructor that registers the clone-table rows

define i32 @raise_handled(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape (effects)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call ptr @signal(i32 noundef 30, ptr noundef nonnull @h)    ; IR: %5 = signal(30, @h): classical arguments, no predicate in scope: the host call as it stands (its host result is not read)
  %8 = call i32 @cqrt_qram_load_i64_hl(i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: %5 = signal(...): the bus load of the cell &__cq_sig[30], the call's result (the previous handler address)
  call void @cqrt_qram_load_i64_hl_unc(i32 %8, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: un-copy %5 (unused; before the store, the next memory version change)
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  %9 = call i32 @cqrt_alloc_i64(i64 ptrtoint (ptr @h to i64))    ; IR: %5 = signal(...): the handler address as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i64_hl(i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64), i32 %9)    ; IR: %5 = signal(...): the bus store of the handler address into &__cq_sig[30]  (kept store, rule 5)
  %10 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %6 = icmp sgt i32 %4, %2  [arm flag f of block %7]
  %11 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %10, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: %8 = raise(30): the cell &__cq_sig[30] loaded under the arm flag  [the address rail of the call; un-copied after the reverse loop, not freed]
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
  call void @cqrt_and_i1(i32 %10, i32 %20, i32 %21)    ; IR: %8 = raise(30): f & f_i, the predicate of candidate i  [kept: the control rail of the callee's store, SPEC GAP]
  %22 = call i32 @cqrt_alloc_i32(i32 30)    ; IR: %8 = raise(30): the classical actual 30 as a seed (table clone ABI: every formal a handle)  [kept: the value rail of the callee's store, SPEC GAP]
  %23 = call ptr @__cq_clone_resolve(ptr %18, i32 1)    ; IR: %8 = raise(30): the _ctl table clone of a_i (kind 1)
  call void %23(i32 %21, i32 %22, i32 4)    ; IR: %8 = raise(30): the handler under f & f_i  [K]  (a memory version change)
  %24 = call ptr @__cq_clone_resolve(ptr %18, i32 3)    ; IR: %8 = raise(30): the _ctl twin of a_i (kind 3)
  call void %24(i32 %21, i32 %22, i32 4)    ; IR: %8 = raise(30): the twin, called exactly once (no result: right after the call)  [K]
  %25 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %8 = raise(30): fresh |0> for p_{i+1}
  call void @cqrt_not_i1(i32 %20)    ; IR: X bracket: NOT f_i
  call void @cqrt_and_i1(i32 %15, i32 %20, i32 %25)    ; IR: %8 = raise(30): p_{i+1} = p_i & NOT f_i
  call void @cqrt_not_i1(i32 %20)    ; IR: X bracket closes
  call void @cqrt_push(i32 %15)    ; IR: p_i for the reverse loop
  call void @cqrt_push(i32 %20)    ; IR: f_i for the reverse loop
  %26 = add nuw nsw i32 %14, 1
  br label %13
27:
  call void @cqrt_tape_write_i32_lit(i32 %5, i32 30)    ; IR: %8 = raise(30): argument 0 of the effect entry, the signal number (classical): a _lit field
  call void @cqrt_tape_effect_controlled(i32 %15, i32 %5, ptr @.cq.effect.raise)    ; IR: %8 = raise(30): the complement branch (no registered function), the effect entry raise under p_n; bare form, %8 is unused
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
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %11, i32 %10, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 30) to i64))    ; IR: un-copy the %8 = raise(30) cell load under the arm flag, after its last reader (the reverse loop); the table clone calls lie between, so it stays allocated (rule 5 sentence 1)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %10, i32 %6, i32 %2)    ; IR: uncompute %6 (after its last controlled gate; before x is measured)
  call void @cqrt_free(i32 %10)    ; IR: release the %6 rail (|0>)
  %39 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %10 = cq_measure_si32(%4)
  %40 = call i32 @cqrt_qram_load_i32_hl(i32 %4, i64 ptrtoint (ptr @hit to i64))    ; IR: %11 = load volatile i32, ptr @hit  [unobservable volatile, rule 24: a bus load after the join, a rail]
  %41 = call i32 @cqrt_measure_i32(i32 %40)    ; IR: %12 = cq_measure_si32(%11)  [the load copy is the measured rail, rule 2]
  %42 = add nsw i32 %41, %39    ; IR: %13 = add nsw i32 %12, %10  (classical: two outcomes)
  ret i32 %42    ; IR: ret i32 %13
}

; the own symbol (the all-zero mask, §1.4): what host code reaches when the host delivers the signal
define internal void @h(i32 noundef %0) {
  %2 = call i32 @__cq_mem()    ; IR: the bus M
  %3 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: store volatile i32 %0, ptr @hit: the classical value as a seed (rule 7), kept with its store
  call void @cqrt_qram_store_i32_hl(i32 %2, i64 ptrtoint (ptr @hit to i64), i32 %3)    ; IR: store volatile i32 %0, ptr @hit  [unobservable volatile, rule 24: a bus store, kept, rule 5]
  ret void    ; IR: ret void
}

; the table clone (§1.4): every formal a handle, then K; no result, nothing minted, nothing pushed
define internal void @__cq_q_h_1_t(i32 %0, i32 %1) {
  %3 = call i32 @__cq_mem()    ; IR: the bus M
  call void @cqrt_qram_store_i32_hl(i32 %3, i64 ptrtoint (ptr @hit to i64), i32 %0)    ; IR: store volatile i32 %0, ptr @hit  [s is a rail: the store's value rail; kept store, rule 5]
  ret void    ; IR: ret void
}

; the table clone's twin: h writes memory, so rule 18 gives it no twin; nothing was pushed, nothing to pop
define internal void @__cq_q_h_1_t_unc(i32 %0, i32 %1) {
  ret void
}

; the _ctl table clone: the predicate first, every bus access under it
define internal void @__cq_q_h_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M
  %5 = load i32, ptr @__cq_act_h, align 4    ; IR: the activation's depth d (§1.4), read on entry
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr @__cq_act_h, align 4    ; IR: one more live _ctl activation
  %7 = icmp ult i32 %5, %2    ; IR: rule 14: the body runs while d is below K
  br i1 %7, label %8, label %9
8:
  call void @cqrt_qram_store_i32_hl_controlled(i32 %0, i32 %4, i64 ptrtoint (ptr @hit to i64), i32 %1)    ; IR: store volatile i32 %0, ptr @hit under the predicate  [kept store: tape slot, value rail and control rail stay, rule 5]
  store i32 %5, ptr @__cq_act_h, align 4    ; IR: the activation ends (the counter is d again)
  ret void    ; IR: ret void
9:
  %10 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: rule 14, the cut at d = K: fresh |0>
  call void @cqrt_copy_i1(i32 %0, i32 %10)    ; IR: rule 14: the predicate copied out, the kept overflow predicate (an output rail)
  store i32 %5, ptr @__cq_act_h, align 4    ; IR: the activation ends
  ret void    ; IR: ret void (no result)
}

; the _ctl twin: no rule-18 twin and nothing pushed; it counts its activation like the clone (§1.4)
define internal void @__cq_q_h_1_t_ctl_unc(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_h, align 4    ; IR: the activation's depth d, read on entry
  %5 = add nsw i32 %4, 1
  store i32 %5, ptr @__cq_act_h, align 4    ; IR: one more live _ctl activation
  store i32 %4, ptr @__cq_act_h, align 4    ; IR: the activation ends
  ret void
}

define i32 @raise_default(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; IR: the bus M (§5: once, at function entry)
  %5 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %6, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [arm flag f of block %6]
  %8 = call i32 @cqrt_qram_load_i64_hl_controlled(i32 %7, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 6) to i64))    ; IR: %7 = raise(6): the cell &__cq_sig[6] loaded under the arm flag  [the address rail of the call; un-copied after the reverse loop, not freed]
  %9 = call i32 @__cq_clone_count(ptr @.cq.sig)    ; IR: %7 = raise(6): rule 19, the number n of registered functions of type void (i32)
  br label %10
10:
  %11 = phi i32 [ 0, %3 ], [ %23, %14 ]    ; IR: candidate index i (classical loop over the clone table)
  %12 = phi i32 [ %7, %3 ], [ %22, %14 ]    ; IR: complement predicate p_i  (p_0 = the arm flag)
  %13 = icmp ult i32 %11, %9
  br i1 %13, label %14, label %24
14:
  %15 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %11)    ; IR: %7 = raise(6): candidate address a_i
  %16 = ptrtoint ptr %15 to i64    ; IR: a_i as its run-time address
  %17 = call i32 @cq_template_icmp_eq_i64_hl(i32 %8, i64 %16)    ; IR: %7 = raise(6): f_i = (address rail == a_i)
  %18 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %7 = raise(6): fresh |0> for the conjunction
  call void @cqrt_and_i1(i32 %7, i32 %17, i32 %18)    ; IR: %7 = raise(6): f & f_i, the predicate of candidate i  [kept: the control rail of the callee's store, SPEC GAP]
  %19 = call i32 @cqrt_alloc_i32(i32 6)    ; IR: %7 = raise(6): the classical actual 6 as a seed (table clone ABI)  [kept: the value rail of the callee's store, SPEC GAP]
  %20 = call ptr @__cq_clone_resolve(ptr %15, i32 1)    ; IR: %7 = raise(6): the _ctl table clone of a_i (kind 1)
  call void %20(i32 %18, i32 %19, i32 4)    ; IR: %7 = raise(6): the candidate under f & f_i  [K]  (a memory version change)
  %21 = call ptr @__cq_clone_resolve(ptr %15, i32 3)    ; IR: %7 = raise(6): the _ctl twin of a_i (kind 3)
  call void %21(i32 %18, i32 %19, i32 4)    ; IR: %7 = raise(6): the twin, called exactly once  [K]
  %22 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %7 = raise(6): fresh |0> for p_{i+1}
  call void @cqrt_not_i1(i32 %17)    ; IR: X bracket: NOT f_i
  call void @cqrt_and_i1(i32 %12, i32 %17, i32 %22)    ; IR: %7 = raise(6): p_{i+1} = p_i & NOT f_i
  call void @cqrt_not_i1(i32 %17)    ; IR: X bracket closes
  call void @cqrt_push(i32 %12)    ; IR: p_i for the reverse loop
  call void @cqrt_push(i32 %17)    ; IR: f_i for the reverse loop
  %23 = add nuw nsw i32 %11, 1
  br label %10
24:
  call void @cqrt_tape_write_i32_lit(i32 %5, i32 6)    ; IR: %7 = raise(6): argument 0, the signal number (classical): a _lit field
  call void @cqrt_tape_effect_controlled(i32 %12, i32 %5, ptr @.cq.effect.raise)    ; IR: %7 = raise(6): the complement branch, the effect entry raise under p_n (performed by the backend: SIGABRT's default action terminates); bare form, %7 is unused
  br label %25
25:
  %26 = phi i32 [ %9, %24 ], [ %30, %29 ]    ; IR: candidates still to undo, from n down to 0
  %27 = phi i32 [ %12, %24 ], [ %32, %29 ]    ; IR: p_{j+1}, the predicate being undone
  %28 = icmp sgt i32 %26, 0
  br i1 %28, label %29, label %35
29:
  %30 = add nsw i32 %26, -1    ; IR: candidate index j
  %31 = call i32 @cqrt_pop()    ; IR: f_j
  %32 = call i32 @cqrt_pop()    ; IR: p_j
  %33 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %30)    ; IR: candidate address a_j again
  %34 = ptrtoint ptr %33 to i64    ; IR: a_j as its run-time address
  call void @cqrt_not_i1(i32 %31)    ; IR: X bracket: NOT f_j
  call void @cqrt_and_i1(i32 %32, i32 %31, i32 %27)    ; IR: uncompute p_{j+1} (after the effect entry, its last use)
  call void @cqrt_not_i1(i32 %31)    ; IR: X bracket closes
  call void @cqrt_free(i32 %27)    ; IR: release p_{j+1} (|0>)
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %31, i32 %8, i64 %34)    ; IR: uncompute f_j
  call void @cqrt_free(i32 %31)    ; IR: release f_j (|0>)
  br label %25
35:
  call void @cqrt_qram_load_i64_hl_controlled_unc(i32 %8, i32 %7, i32 %4, i64 ptrtoint (ptr getelementptr inbounds ([65 x i64], ptr @__cq_sig, i64 0, i64 6) to i64))    ; IR: un-copy the %7 = raise(6) cell load under the arm flag, after its last reader (the reverse loop); the table clone calls lie between, so it stays allocated (rule 5 sentence 1)
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %7, i32 %6, i32 %2)    ; IR: uncompute %5 (after its last controlled gate; before x is measured)
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  %36 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %9 = cq_measure_si32(%4)
  ret i32 %36    ; IR: ret i32 %9
}

define i32 @remove_cond(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_tape_alloc()    ; IR: the function's tape
  %5 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %5, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %6 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %5, i32 %2)    ; IR: %5 = icmp sgt i32 %4, %2  [predicate of block %6]
  call void @cqrt_tape_write_i64_lit(i32 %4, i64 ptrtoint (ptr @.str to i64))    ; IR: %7 = remove(@.str): argument 0, the path: a pointer is its address, classical: a _lit field (the string is not expanded into fields)
  call void @cqrt_tape_effect_controlled(i32 %6, i32 %4, ptr @.cq.effect.remove)    ; IR: block %6: %7 = remove(@.str): the effect entry under the predicate, complete after its field; the host call is not executed; bare form, %7 is unused
  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %6, i32 %5, i32 %2)    ; IR: uncompute %5
  call void @cqrt_free(i32 %6)    ; IR: release the %5 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %9 = cq_measure_si32(%4)
  ret i32 %7    ; IR: ret i32 %9
}

; module constructor: one row per address-taken function (§1.3): fn, sig, _t, _t_ctl, _t_unc, _t_ctl_unc
define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @h, ptr @.cq.sig, ptr @__cq_q_h_1_t, ptr @__cq_q_h_1_t_ctl, ptr @__cq_q_h_1_t_unc, ptr @__cq_q_h_1_t_ctl_unc)    ; IR: h's row (its address is passed to signal)
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
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_load_i64_hl(i32, i64)
declare void @cqrt_qram_load_i64_hl_unc(i32, i32, i64)
declare i32 @cqrt_qram_load_i64_hl_controlled(i32, i32, i64)
declare void @cqrt_qram_load_i64_hl_controlled_unc(i32, i32, i32, i64)
declare void @cqrt_qram_store_i64_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare void @cqrt_qram_store_i32_hl(i32, i64, i32)
declare void @cqrt_qram_store_i32_hl_controlled(i32, i32, i64, i32)
declare i32 @cqrt_tape_alloc()
declare void @cqrt_tape_write_i32_lit(i32, i32)
declare void @cqrt_tape_write_i64_lit(i32, i64)
declare void @cqrt_tape_effect_controlled(i32, i32, ptr)
declare i32 @cq_template_icmp_sgt_i32_hl(i32, i32)
declare void @cq_template_icmp_sgt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)

attributes #0 = { nounwind ssp uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
