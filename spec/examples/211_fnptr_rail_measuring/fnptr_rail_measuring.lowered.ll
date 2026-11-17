; HAND-WRITTEN. Rules: 19, 2, 4, 5, 7, 8, 9, 13, 14, 16, 18, 20, 21; §1.3 (clone table), §1.4 (table clones).
; Checked: r = ops[k & 1](x) (the copied-out result of the merge, measured): x + 1 where k & 1 = 0 (inc), x where
; k & 1 = 1 (peek); the cells of ops are unchanged.
; Clean: the address chain of &ops[k & 1] (the and, its zext, the scaled index, the address rail), uncomputed right
; after the un-copy of fp (after the reverse loop) and freed; per candidate: the flag f_i (fp == a_i), the complement rail p_{i+1} and the select rail
; out_{i+1}, popped and uncomputed by the reverse loop and freed; the outer select rail (after the copy-out); the
; seeds p_0 (|1>) and out_0 (|0>), never written and freed directly (rule 7); inc's result rail x + 1, zeroed and
; freed by its twin __cq_q_inc_1_t_ctl_unc.
; Kept: k and x (the rotated registers); fp, the load copy of ops[k & 1] (rule 5 sentence 1: un-copied after its last
; reader, the reverse loop's last flag _unc, but left allocated: the dispatch, a memory version change, lies between); per candidate the copy c_i of its
; result (rule 19: the result is kept across the next memory version change as a copy); peek's measured rail t (the
; controlled copy of x, rule 19; measured, rule 2); the result rail r_e of the complement's effect entry, its two
; tape field rails and the tape (rule 16); the copied-out result R (measured).
; Rotations: (Ry, k, tk, 1); (Ry, x, tx, 1).
; Expected: fnptr_rail_measuring(1, .5, 4, .25). Each Ry acts on all 32 qubits of its register: a bit of k flips with
; p = sin^2(.25) = 0.061209, a bit of x with s = sin^2(.125) = 0.015544. k & 1 = 1 (peek) with 0.938791 and 0 (inc)
; with 0.061209; x = 4 ^ e, each e with s^|e| (1 - s)^(32 - |e|) (x = 4: 0.605738; one given bit flipped: 0.009564).
; r = x on the peek branch and x + 1 on the inc branch: P(r = 4) = 0.568662 (peek, x = 4; plus inc, x = 3: 1.5e-7),
; P(r = 5) = 0.046055 (inc, x = 4: 0.037076; peek, x = 5: 0.008979), P(r = 6) = 0.009564, P(r = 0) = 0.008979, and
; 0.385283 in total over the values other than 4 and 5. The measurement inside peek's clone reads t = x on the peek
; branch and 0 on the inc branch (P(t = 0) = 0.070187): it tells the branches apart, where the C program measures x
; only when peek is called, and it leaves r's distribution as the C program's. Both cells of ops hold registered
; functions of type i32 (i32), so one flag is 1 on every branch, the complement predicate is 0 and the effect entry is
; never performed (deferred by the backend, its r_e is |0>).
; A FUNCTION POINTER LOADED AT AN ADDRESS RAIL (rules 19, 20, 21). ops is a constant global at its host address: HOST
; cells seen through the overlay, nothing seeded and no derived table. The gep with the tainted index is 64-bit
; template arithmetic (the zext as -O1 wrote it, mul by the element size 8, add of the classical base) and the load is
; ONE qram_load_i64 at the address rail: fp is a 64-bit rail holding the callee's host address.
; THE DISPATCH. Which functions fp can denote is never analysed: the candidates are the registered functions of the
; call's function type, read from the clone table at run time. The module constructor registers one row for each
; address-taken function (inc, peek): its host address, the type string "i32 (i32)", its table clone and that clone's
; _ctl, _unc and _ctl_unc. The dispatch is a classical loop (rule 14: i < __cq_clone_count(sig), registration order).
; Trip i takes a_i = __cq_clone_at(sig, i), the flag f_i = icmp_eq_i64_hl(fp, a_i), and calls the _t_ctl clone of a_i
; (kind 1) under f_i with the table ABI: predicate first, every formal a handle (x), then K = 4, the K of this
; function. The caller has no record of a callee: every call is a memory version change, so the result is copied into
; a fresh rail c_i that is KEPT, and the twin (kind 3, same flag) is called right after, before the next memory
; version change (the next candidate's call, or the effect entry). The trip then extends the complement p_{i+1} =
; p_i & NOT f_i (an X bracket on f_i around and_i1 into a fresh rail, rule 8; p_0 is a |1> seed, no predicate being in
; scope) and the merge out_{i+1} = select_i32(f_i, c_i, out_i) (rule 9; out_0 is a |0> seed), and pushes p_i, out_i,
; c_i and f_i. After the loop p_n says "fp is no registered function": fp is host code there, and p_n itself is the
; predicate of the effect entry with a null name, fp its first field and x its second, result rail r_e. The call's
; value is select_i32(p_n, r_e, out_n): the complement's r_e where no candidate matched, else the candidates' merge.
; It is copied out (rule 14), the outer select is uncomputed, the reverse loop pops the trips and uncomputes each
; select, each p_{i+1} and each flag (a_i again from the table), the seeds are freed and the copy is measured.
; THE TABLE CLONES (§1.4). Each takes handles and K, returns one handle and pushes nothing (neither function mints a
; register). inc is one template: its clones return the template's rail, its twins are that template's _unc and the
; free (the caller frees no result of a table clone). A _ctl clone guards gates, and inc has only a template, so
; __cq_q_inc_1_t_ctl computes unguarded (rule 9) and the caller's select does the rest. peek measures, so it has no
; rule-18 twin: both its twins do nothing and its result stays allocated. In __cq_q_peek_1_t a kept copy of the
; argument rail is measured (t = alloc_i32(0); copy_i32(v, t); measure_i32(t), §1.4; the caller's rail is never a
; measured rail) and the outcome returned as a seed rail. In __cq_q_peek_1_t_ctl the measurement is of a CONTROLLED COPY
; (rule 19): t = alloc_i32(0); copy_i32_controlled(pred, v, t); measure_i32(t). x is not collapsed where the flag is 0,
; and t, which holds the tainted outcome, is the result. Every _t_ctl clone and _t_ctl_unc twin reads its function's
; activation counter d on entry, adds 1 and subtracts 1 at its return (§1.4); at d >= K the clone returns a |0> rail
; and keeps a copy_i1 of its predicate as the overflow rail, and the twin frees that |0> rail (rule 14). Nothing
; re-enters here, so d is 0 at every call and no activation is cut.
; THE OWN SYMBOLS. inc and peek stay, at the host addresses the cells of ops hold (the table's keys). inc has no bus
; access, no cq_* call and no call: it is its own lowering. peek's cq_measure of a classical value is that value.
; SPEC GAP: rule 19 / §1.3 ask for a clone-table row per externally visible function too. fnptr_rail_measuring gets
; none here (as in 195-203): its type is not the call's, so the dispatch does not see the difference.
; SPEC GAP: rule 19 does not say how the complement predicate and the select chain are built for a candidate count
; known only at run time. Rule 9's chain with the complement innermost needs r_e, hence every flag, before the first
; select; over the one push/pop stack (§1.1) that takes four loops and every flag twice. Chosen instead, as in 212:
; ONE loop and its reverse. The loop carries the complement p (p_0 = the predicate in scope, here an alloc_i1(true)
; seed; p_{i+1} = p_i & NOT f_i: not_i1(f_i), and_i1(p_i, f_i, fresh), not_i1(f_i)) and the merge out (out_0 =
; alloc_i32(0)). The effect entry is made under p_n and one outer select on p_n takes r_e, else out_n: the complement
; is an arm of the outermost select, not the innermost arm of one chain. The flags are pairwise exclusive (distinct
; addresses), so the value is the same on every branch. With a predicate P in scope a candidate's control would be
; and_i1(P, f_i, fresh), uncomputed after the twin (212).
; SPEC GAP: neither rule 16 nor BACKEND_ABI §1.11 says that an effect entry captures its predicate. p_n is uncomputed
; and freed after the entry like any flag (138, 212; rule 8 keeps only a flag that controls a kept store), so the
; backend must capture it at the call.
; SPEC GAP: no name is fixed for the module constructor, the type-string global or the activation counters; the
; counters are plain module-internal i32 globals, read and written by plain instructions.
; SPEC GAP: rule 18's clone copies each result into a fresh rail; a measured rail cannot be uncomputed, so
; __cq_q_peek_1_t_ctl returns the measured rail t itself. Whether t is a "register it minted" to push (§1.4) is not
; said; it is not pushed (its twin does nothing).
; SPEC GAP: rule 2 does not spell cq_measure of a value that never was a rail (peek's own symbol): the value itself.
; SPEC GAP: §1.4 lets every _ctl_unc twin count an activation; a twin with nothing to do (peek's) does so too.
source_filename = "fnptr_rail_measuring.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@ops = internal unnamed_addr constant [2 x ptr] [ptr @inc, ptr @peek], align 16    ; IR: @ops  (at its host address: HOST cells on the bus, rule 20)
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1    ; the LLVM function type of inc, peek and the indirect call, as a C string (§1.3)
@__cq_act_inc = internal global i32 0, align 4    ; live _ctl activations of inc (§1.4)
@__cq_act_peek = internal global i32 0, align 4    ; live _ctl activations of peek (§1.4)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @inc, ptr @.cq.sig, ptr @__cq_q_inc_1_t, ptr @__cq_q_inc_1_t_ctl, ptr @__cq_q_inc_1_t_unc, ptr @__cq_q_inc_1_t_ctl_unc)    ; row of inc (address taken in @ops): fn, sig, table clone, _ctl, _unc, _ctl_unc (rule 19)
  call void @__cq_clone_register(ptr @peek, ptr @.cq.sig, ptr @__cq_q_peek_1_t, ptr @__cq_q_peek_1_t_ctl, ptr @__cq_q_peek_1_t_unc, ptr @__cq_q_peek_1_t_ctl_unc)    ; row of peek (address taken in @ops)
  ret void
}

define i32 @fnptr_rail_measuring(i32 noundef %0, double noundef %1, i32 noundef %2, double noundef %3) {
  %5 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %6 = call i32 @cqrt_tape_alloc()    ; the function's tape (the complement's effect entry, rule 16)
  %7 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %5 = cq_theta_ui32(%0, %1)  [register k]
  call void @cqrt_ry_i32(i32 %7, double %1)    ; IR: %5 = cq_theta_ui32(%0, %1)  [Ry]
  %8 = call i32 @cqrt_alloc_i32(i32 %2)    ; IR: %6 = cq_theta_si32(%2, %3)  [register x]
  call void @cqrt_ry_i32(i32 %8, double %3)    ; IR: %6 = cq_theta_si32(%2, %3)  [Ry]
  %9 = call i32 @cq_template_and_i32_hl(i32 %7, i32 1)    ; IR: %7 = and i32 %5, 1
  %10 = call i32 @cq_template_zext_i32_to_i64(i32 %9)    ; IR: %8 = zext nneg i32 %7 to i64
  %11 = call i32 @cq_template_mul_i64_hl(i32 %10, i64 8)    ; IR: %9 = getelementptr inbounds [2 x ptr], ptr @ops, i64 0, i64 %8  [the tainted index scaled by the element size (rule 20)]
  %12 = call i32 @cq_template_add_i64_hl(i32 %11, i64 ptrtoint (ptr @ops to i64))    ; IR: %9 = getelementptr  [+ the classical base: the address rail of &ops[k & 1]]
  %13 = call i32 @cqrt_qram_load_i64(i32 %5, i32 %12)    ; IR: %10 = load ptr, ptr %9, align 8  [a load at an address rail: fp, a 64-bit rail holding the callee's address; the dispatch overtakes it: un-copied after the reverse loop, not freed (rule 5)]
  %14 = call i32 @__cq_clone_count(ptr @.cq.sig)    ; IR: %11 = call i32 %10(i32 %6)  [n, the number of registered functions of type i32 (i32): the candidates (rule 19)]
  %15 = call i32 @cqrt_alloc_i1(i1 true)    ; p_0: the complement of no flag (a |1> seed: no predicate in scope, rules 7, 16)
  %16 = call i32 @cqrt_alloc_i32(i32 0)    ; out_0: the merge of no candidate (a seed)
  br label %17    ; the dispatch: one trip per candidate, classical code (rules 14, 19)

17:
  %18 = phi i32 [ 0, %4 ], [ %32, %22 ]    ; candidate index i (classical)
  %19 = phi i32 [ %15, %4 ], [ %30, %22 ]    ; p_i: 1 iff fp is none of a_0 .. a_{i-1}
  %20 = phi i32 [ %16, %4 ], [ %31, %22 ]    ; out_i: the merge of candidates 0 .. i-1
  %21 = icmp ult i32 %18, %14
  br i1 %21, label %22, label %33

22:
  %23 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %18)    ; a_i: the host address of candidate i (registration order)
  %24 = ptrtoint ptr %23 to i64    ; a_i as a classical i64 (rule 21)
  %25 = call i32 @cq_template_icmp_eq_i64_hl(i32 %13, i64 %24)    ; IR: %11 = call i32 %10(i32 %6)  [flag f_i: fp == a_i (rule 13's compare)]
  %26 = call ptr @__cq_clone_resolve(ptr %23, i32 1)    ; the _t_ctl clone of a_i (kind 1)
  %27 = call i32 %26(i32 %25, i32 %8, i32 4)    ; IR: %11 = call i32 %10(i32 %6)  [candidate i under f_i: predicate, the argument rail x, K; a memory version change (rule 19)]  [K]
  %28 = call i32 @cqrt_alloc_i32(i32 0)    ; c_i: the copy that is KEPT in the result's place (rule 19)
  call void @cqrt_copy_i32(i32 %27, i32 %28)    ; c_i ^= the result, before the next memory version change
  %29 = call ptr @__cq_clone_resolve(ptr %23, i32 3)    ; the _t_ctl_unc twin of a_i (kind 3)
  call void %29(i32 %25, i32 %27, i32 %8, i32 4)    ; IR: the twin, exactly once, under the same flag: predicate, the result, the argument, K (it frees what it zeroes)  [K]
  %30 = call i32 @cqrt_alloc_i1(i1 false)    ; p_{i+1}
  call void @cqrt_not_i1(i32 %25)    ; X bracket: NOT f_i (rule 8)
  call void @cqrt_and_i1(i32 %19, i32 %25, i32 %30)    ; p_{i+1} = p_i & NOT f_i
  call void @cqrt_not_i1(i32 %25)    ; close the X bracket
  %31 = call i32 @cq_template_select_i32(i32 %25, i32 %28, i32 %20)    ; IR: %11 = call i32 %10(i32 %6)  [merge: candidate i's result under f_i, else the merge so far (rule 9)]
  call void @cqrt_push(i32 %19)    ; p_i, out_i, c_i and f_i, for the reverse loop (rule 14)
  call void @cqrt_push(i32 %20)
  call void @cqrt_push(i32 %28)
  call void @cqrt_push(i32 %25)
  %32 = add nuw i32 %18, 1
  br label %17

33:
  %34 = call i32 @cqrt_tape_write_i64_controlled(i32 %19, i32 %6, i32 %13)    ; IR: %11 = call i32 %10(i32 %6)  [under p_n, the complement of the flags: the entry's first field, the callee's address, the rail fp (rule 19)]
  %35 = call i32 @cqrt_tape_write_i32_controlled(i32 %19, i32 %6, i32 %8)    ; the argument x
  %36 = call i32 @cqrt_tape_effect_i32_controlled(i32 %19, i32 %6, ptr null, i32 2)    ; IR: %11 = call i32 %10(i32 %6)  [fp is host code: the effect entry with a null name; r_e, its result rail, KEPT (rule 16)]
  %37 = call i32 @cq_template_select_i32(i32 %19, i32 %36, i32 %20)    ; IR: %11 = call i32 %10(i32 %6)  [the call's value: the complement's r_e where p_n, else the candidates' merge]  ; SPEC GAP: the complement is an arm of this outer select (header)
  %38 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %11 = call i32 %10(i32 %6)  [copied-out result R (rule 14)]
  call void @cqrt_copy_i32(i32 %37, i32 %38)    ; IR: %11
  call void @cq_template_select_i32_unc(i32 %37, i32 %19, i32 %36, i32 %20)    ; IR: uncompute the outer select
  call void @cqrt_free(i32 %37)    ; IR: release it (|0>)
  br label %39    ; the reverse loop: candidates n-1 .. 0 (the pop order)

39:
  %40 = phi i32 [ %14, %33 ], [ %45, %44 ]    ; trips left to undo (classical)
  %41 = phi i32 [ %19, %33 ], [ %49, %44 ]    ; p_{i+1} of the trip being undone
  %42 = phi i32 [ %20, %33 ], [ %48, %44 ]    ; out_{i+1} of the trip being undone
  %43 = icmp eq i32 %40, 0
  br i1 %43, label %52, label %44

44:
  %45 = add i32 %40, -1    ; the trip's candidate index i
  %46 = call i32 @cqrt_pop()    ; f_i
  %47 = call i32 @cqrt_pop()    ; c_i (kept: only its handle is read)
  %48 = call i32 @cqrt_pop()    ; out_i
  %49 = call i32 @cqrt_pop()    ; p_i
  call void @cq_template_select_i32_unc(i32 %42, i32 %46, i32 %47, i32 %48)    ; IR: uncompute the merge of candidate i
  call void @cqrt_free(i32 %42)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %46)    ; X bracket: NOT f_i
  call void @cqrt_and_i1(i32 %49, i32 %46, i32 %41)    ; uncompute p_{i+1} (after its last use: the uncompute of p_{i+2}, or for p_n the effect entry and the outer select)
  call void @cqrt_not_i1(i32 %46)    ; close the X bracket
  call void @cqrt_free(i32 %41)    ; release it (|0>)
  %50 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %45)    ; a_i again, from the trip index (rule 14)
  %51 = ptrtoint ptr %50 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %46, i32 %13, i64 %51)    ; IR: uncompute the flag f_i (after its last use)
  call void @cqrt_free(i32 %46)    ; IR: release it (|0>)
  br label %39

52:
  call void @cqrt_qram_load_i64_unc(i32 %13, i32 %5, i32 %12)    ; IR: un-copy %10 (fp) after its last reader, the _unc of f_0; the dispatch calls lie between, so it stays allocated (rule 5 sentence 1)
  call void @cq_template_add_i64_hl_unc(i32 %12, i32 %11, i64 ptrtoint (ptr @ops to i64))    ; IR: uncompute %9  [the address rail outlives the _unc of its load (rules 5, 20)]
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %11, i32 %10, i64 8)    ; IR: uncompute %9 (the scaled index)
  call void @cqrt_free(i32 %11)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %10, i32 %9)    ; IR: uncompute %8
  call void @cqrt_free(i32 %10)    ; IR: release the %8 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %9, i32 %7, i32 1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cqrt_free(i32 %41)    ; release p_0 (a |1> seed, never written: a known basis state, rule 7)
  call void @cqrt_free(i32 %42)    ; release out_0 (a seed, never written: |0>, rule 7)
  %53 = call i32 @cqrt_measure_i32(i32 %38)    ; IR: %12 = cq_measure_si32(%11)  [not in a _ctl clone: the result rail itself is measured (rule 2)]
  ret i32 %53    ; IR: ret i32 %12
}

define internal i32 @inc(i32 noundef %0) {
  %2 = add nsw i32 %0, 1    ; IR: %2 = add nsw i32 %0, 1  (the own symbol: no bus access, no cq_* call, no call, so its own lowering, rule 19; its address is the cell value in @ops and the table key)
  ret i32 %2    ; IR: ret i32 %2
}

define internal i32 @peek(i32 noundef %0) {
  ret i32 %0    ; IR: %2 = cq_measure_si32(%0); ret i32 %2  (the own symbol, all-classical: the measurement of a classical value is the value)  ; SPEC GAP: rule 2 does not spell this case
}

define internal i32 @__cq_q_inc_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_add_i32_hl(i32 %0, i32 1)    ; IR: %2 = add nsw i32 %0, 1  (table clone: the handle, then K; a one-template body returns its rail, rule 18)
  ret i32 %3    ; IR: ret i32 %2
}

define internal void @__cq_q_inc_1_t_unc(i32 %0, i32 %1, i32 %2) {
  call void @cq_template_add_i32_hl_unc(i32 %0, i32 %1, i32 1)    ; IR: uncompute %2  (twin: the result, the argument, K)
  call void @cqrt_free(i32 %0)    ; IR: release the result rail (|0>): a table clone's twin frees what it zeroes (§1.4)
  ret void
}

define internal i32 @__cq_q_inc_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_inc, align 4    ; d: this activation's depth (§1.4)
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_inc, align 4    ; one more live _ctl activation of inc
  %6 = icmp ult i32 %4, %2    ; d below K: the body runs (rule 14)
  br i1 %6, label %7, label %11

7:
  %8 = call i32 @cq_template_add_i32_hl(i32 %1, i32 1)    ; IR: %2 = add nsw i32 %0, 1  (a template on an SSA value: computed unguarded, the caller merges by select, rule 9; the predicate %0 guards no gate here)
  %9 = load i32, ptr @__cq_act_inc, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_inc, align 4    ; the activation ends
  ret i32 %8    ; IR: ret i32 %2

11:
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; the cut: the result is a |0> rail (rule 14)
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; the overflow predicate of this cut activation, an output rail (KEPT)
  call void @cqrt_copy_i1(i32 %0, i32 %13)    ; a copy of the predicate
  %14 = load i32, ptr @__cq_act_inc, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_inc, align 4    ; the activation ends
  ret i32 %12
}

define internal void @__cq_q_inc_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_inc, align 4    ; d (§1.4): the twin makes the same cut
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_inc, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %9

8:
  call void @cq_template_add_i32_hl_unc(i32 %1, i32 %2, i32 1)    ; IR: uncompute %2  (twin: predicate, the result, the argument, K)
  br label %9

9:
  call void @cqrt_free(i32 %1)    ; IR: release the result rail (|0>: zeroed above, or the cut activation's |0> rail)
  %10 = load i32, ptr @__cq_act_inc, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_inc, align 4
  ret void
}

define internal i32 @__cq_q_peek_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = cq_measure_si32(%0)  [t: in a table clone without a predicate a formal is measured through a kept copy (§1.4)]
  call void @cqrt_copy_i32(i32 %0, i32 %3)    ; IR: %2 = cq_measure_si32(%0)  [t ^= v; the caller's rail v is not the measured rail and is uncomputed by the caller as always]
  %4 = call i32 @cqrt_measure_i32(i32 %3)    ; IR: %2 = cq_measure_si32(%0)  [t is measured and stays allocated (rule 2); not pushed]
  %5 = call i32 @cqrt_alloc_i32(i32 %4)    ; IR: ret i32 %2  [the classical outcome as a seed rail: every result of a table clone is a handle (§1.4)]
  ret i32 %5    ; IR: ret i32 %2
}

define internal void @__cq_q_peek_1_t_unc(i32 %0, i32 %1, i32 %2) {
  ret void    ; peek measures: no rule-18 twin; nothing was pushed, so nothing is popped, and the result stays allocated (§1.4)
}

define internal i32 @__cq_q_peek_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_peek, align 4    ; d: this activation's depth (§1.4)
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_peek, align 4    ; one more live _ctl activation of peek
  %6 = icmp ult i32 %4, %2    ; d below K: the body runs (rule 14)
  br i1 %6, label %7, label %12

7:
  %8 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %2 = cq_measure_si32(%0)  [t: inside a _ctl clone the measurement is of a controlled copy (rule 19)]
  call void @cqrt_copy_i32_controlled(i32 %0, i32 %1, i32 %8)    ; IR: %2 = cq_measure_si32(%0)  [t ^= v under the predicate: v is not collapsed where the predicate is 0]
  %9 = call i32 @cqrt_measure_i32(i32 %8)    ; IR: %2 = cq_measure_si32(%0)  [t is the measured rail; the outcome is tainted, so the rail is the value]
  %10 = load i32, ptr @__cq_act_peek, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_peek, align 4    ; the activation ends
  ret i32 %8    ; IR: ret i32 %2  [the measured rail itself: it is never uncomputed, so no copy is taken]  ; SPEC GAP: rule 18's copy-out is not taken for a measured rail

12:
  %13 = call i32 @cqrt_alloc_i32(i32 0)    ; the cut: the result is a |0> rail (rule 14)
  %14 = call i32 @cqrt_alloc_i1(i1 false)    ; the overflow predicate of this cut activation, an output rail (KEPT)
  call void @cqrt_copy_i1(i32 %0, i32 %14)    ; a copy of the predicate
  %15 = load i32, ptr @__cq_act_peek, align 4
  %16 = add i32 %15, -1
  store i32 %16, ptr @__cq_act_peek, align 4    ; the activation ends
  ret i32 %13
}

define internal void @__cq_q_peek_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_peek, align 4    ; d (§1.4)  ; SPEC GAP: a twin with nothing to do still counts its activation
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_peek, align 4
  %7 = load i32, ptr @__cq_act_peek, align 4
  %8 = add i32 %7, -1
  store i32 %8, ptr @__cq_act_peek, align 4
  ret void    ; peek measures: no rule-18 twin; nothing to pop, and the result stays allocated (§1.4)
}

declare i32 @__cq_mem()
declare void @__cq_clone_register(ptr, ptr, ptr, ptr, ptr, ptr)
declare ptr @__cq_clone_resolve(ptr, i32)
declare i32 @__cq_clone_count(ptr)
declare ptr @__cq_clone_at(ptr, i32)
declare i32 @cqrt_alloc_i1(i1)
declare i32 @cqrt_alloc_i32(i32)
declare void @cqrt_free(i32)
declare void @cqrt_ry_i32(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_copy_i1(i32, i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_copy_i32_controlled(i32, i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_load_i64(i32, i32)
declare void @cqrt_qram_load_i64_unc(i32, i32, i32)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)
declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)
declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr, i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_zext_i32_to_i64(i32)
declare void @cq_template_zext_i32_to_i64_unc(i32, i32)
declare i32 @cq_template_mul_i64_hl(i32, i64)
declare void @cq_template_mul_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i64_hl(i32, i64)
declare void @cq_template_add_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_eq_i64_hl(i32, i64)
declare void @cq_template_icmp_eq_i64_hl_unc(i32, i32, i64)
declare i32 @cq_template_select_i32(i32, i32, i32)
declare void @cq_template_select_i32_unc(i32, i32, i32, i32)
