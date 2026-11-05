; HAND-WRITTEN. Rules: 19, 2, 4, 5, 7, 8, 9, 13, 14, 16, 18, 20, 21; §1.3 (clone table), §1.4 (table clones).
; Checked: r = fps[x & 1](c + x) (the copied-out result of the merge, measured): 2(c + x) where x & 1 = 0 (dbl),
; (c + x)^2 where x & 1 = 1 (sq); the cells of fps are unchanged.
; Clean: the address chain of &fps[x & 1] (the and %5, its zext %6, the scaled index, the address rail %7), uncomputed
; right after fp's un-copy and freed; the argument c + x (%9), uncomputed after its last reader, the effect entry's field;
; per candidate: the flag f_i (fp == a_i), the complement rail p_{i+1} and the select rail out_{i+1}, popped and
; uncomputed by the reverse loop and freed; the outer select rail (after the copy-out); the seeds p_0 (|1>) and out_0
; (|0>), never written and freed directly (rule 7); dbl's and sq's result rails (2(c + x), (c + x)^2), zeroed and freed
; by their twins __cq_q_dbl_1_t_ctl_unc and __cq_q_sq_1_t_ctl_unc; fp, the load copy of fps[x & 1], un-copied after
; the reverse loop (its last reader is the last flag's _unc) and left allocated (rule 5 sentence 1: the dispatch, a
; memory version change, overtakes it).
; Kept: x (the rotated register); per candidate the copy c_i of its result (rule
; 19: the result is kept across the next memory version change as a copy); the result rail r_e of the complement's
; effect entry, its two tape field rails and the tape (rule 16); the copied-out result R (measured).
; Rotations: (Ry, x, th, 1).
; Expected: quantum_fnptr(0, .5, 3). Ry acts on all 32 qubits of x: each bit flips with p = sin^2(.25) = 0.061209.
; x & 1 = 0 (dbl) with 0.938791 and 1 (sq) with 0.061209; r = 2(3 + x) on the dbl branch and (3 + x)^2 on the sq
; branch. P(r = 6) = 0.141137 (dbl with x = 0: 0.132498; with x = 2^31: 0.008639; no square is 6 mod 2^32). Both cells
; of fps hold registered functions of type i32 (i32), so one flag is 1 on every branch, the complement predicate is 0
; and the effect entry is never performed (deferred by the backend, its r_e is |0>).
; A FUNCTION POINTER LOADED AT AN ADDRESS RAIL (rules 19, 20, 21). fps is a constant global at its host address: HOST
; cells seen through the overlay, nothing seeded and no derived table. Its index is tainted, so the access is not the
; host-resident plain load of rule 20 (a): the gep is 64-bit template arithmetic (the zext as -O1 wrote it, mul by the
; element size 8, add of the classical base) and the load is ONE qram_load_i64 at the address rail: fp is a 64-bit rail
; holding the callee's host address.
; THE DISPATCH (as 211). Which functions fp can denote is never analysed: the candidates are the registered functions of
; the call's function type, read from the clone table at run time. The module constructor registers one row for each
; address-taken function (dbl, sq): its host address, the type string "i32 (i32)", its table clone and that clone's
; _ctl, _unc and _ctl_unc. The dispatch is a classical loop (rule 14: i < __cq_clone_count(sig), registration order).
; Trip i takes a_i = __cq_clone_at(sig, i), the flag f_i = icmp_eq_i64_hl(fp, a_i), and calls the _t_ctl clone of a_i
; (kind 1) under f_i with the table ABI: predicate first, every formal a handle (the argument rail c + x), then K = 4,
; the K of this function. The caller has no record of a callee: every call is a memory version change, so the result is
; copied into a fresh rail c_i that is KEPT, and the twin (kind 3, same flag) is called right after, before the next
; memory version change (the next candidate's call, or the effect entry). The trip then extends the complement p_{i+1} =
; p_i & NOT f_i (an X bracket on f_i around and_i1 into a fresh rail, rule 8; p_0 is a |1> seed, no predicate being in
; scope) and the merge out_{i+1} = select_i32(f_i, c_i, out_i) (rule 9; out_0 is a |0> seed), and pushes p_i, out_i,
; c_i and f_i. After the loop p_n says "fp is no registered function": fp is host code there, and p_n itself is the
; predicate of the effect entry with a null name, fp its first field and c + x its second, result rail r_e. The call's
; value is select_i32(p_n, r_e, out_n). It is copied out (rule 14), the outer select is uncomputed, the reverse loop
; pops the trips and uncomputes each select, each p_{i+1} and each flag (a_i again from the table), the seeds are freed
; and the copy is measured.
; THE TABLE CLONES (§1.4). Each takes handles and K, returns one handle and pushes nothing (neither function mints a
; register). dbl and sq are one template each: their clones return the template's rail, their twins are that
; template's _unc and the free (the caller frees no result of a table clone). A _ctl clone guards gates, and neither
; body has one, so the _t_ctl clones compute unguarded (rule 9) and the caller's select does the rest. Every _t_ctl
; clone and _t_ctl_unc twin reads its function's activation counter d on entry, adds 1 and subtracts 1 at its return
; (§1.4); at d >= K the clone returns a |0> rail and keeps a copy_i1 of its predicate as the overflow rail, and the twin
; frees that |0> rail (rule 14). Nothing re-enters here, so d is 0 at every call and no activation is cut.
; THE OWN SYMBOLS. dbl and sq stay, at the host addresses the cells of fps hold (the table's keys): neither has a bus
; access, a cq_* call or a call, so each is its own lowering. No clone of either is called by name, so there is no
; rule-18 clone __cq_q_dbl_1 / __cq_q_sq_1.
; SPEC GAP: rule 19 / §1.3 ask for a clone-table row per externally visible function too. quantum_fnptr gets none here
; (as in 211, §5): its type is not the call's, so the dispatch does not see the difference.
; SPEC GAP: rule 19 does not say how the complement predicate and the select chain are built for a candidate count
; known only at run time. Chosen, as in 211 and 212: ONE loop and its reverse; the complement is an arm of one outer
; select on p_n, not the innermost arm of one chain. The flags are pairwise exclusive (distinct addresses), so the
; value is the same on every branch.
; SPEC GAP: neither rule 16 nor BACKEND_ABI §1.11 says that an effect entry captures its predicate. p_n is uncomputed
; and freed after the entry like any flag (138, 211, 212), so the backend must capture it at the call.
; SPEC GAP: no name is fixed for the module constructor, the type-string global or the activation counters beyond
; §1.3/§1.4's spellings; the counters are plain module-internal i32 globals, read and written by plain instructions.
source_filename = "quantum_fnptr.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@fps = internal unnamed_addr constant [2 x ptr] [ptr @dbl, ptr @sq], align 16    ; IR: @fps  (at its host address: HOST cells on the bus, rule 20)
@.cq.sig = private unnamed_addr constant [10 x i8] c"i32 (i32)\00", align 1    ; the LLVM function type of dbl, sq and the indirect call, as a C string (§1.3)
@__cq_act_dbl = internal global i32 0, align 4    ; live _ctl activations of dbl (§1.4)
@__cq_act_sq = internal global i32 0, align 4    ; live _ctl activations of sq (§1.4)
@llvm.global_ctors = appending global [1 x { i32, ptr, ptr }] [{ i32, ptr, ptr } { i32 65535, ptr @__cq_register, ptr null }]

define internal void @__cq_register() {
  call void @__cq_clone_register(ptr @dbl, ptr @.cq.sig, ptr @__cq_q_dbl_1_t, ptr @__cq_q_dbl_1_t_ctl, ptr @__cq_q_dbl_1_t_unc, ptr @__cq_q_dbl_1_t_ctl_unc)    ; row of dbl (address taken in @fps): fn, sig, table clone, _ctl, _unc, _ctl_unc (rule 19)
  call void @__cq_clone_register(ptr @sq, ptr @.cq.sig, ptr @__cq_q_sq_1_t, ptr @__cq_q_sq_1_t_ctl, ptr @__cq_q_sq_1_t_unc, ptr @__cq_q_sq_1_t_ctl_unc)    ; row of sq (address taken in @fps)
  ret void
}

define i32 @quantum_fnptr(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @__cq_mem()    ; the bus M, once at function entry (§5)
  %5 = call i32 @cqrt_tape_alloc()    ; the function's tape (the complement's effect entry, rule 16)
  %6 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register x]
  call void @cqrt_ry_i32(i32 %6, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %7 = call i32 @cq_template_and_i32_hl(i32 %6, i32 1)    ; IR: %5 = and i32 %4, 1
  %8 = call i32 @cq_template_zext_i32_to_i64(i32 %7)    ; IR: %6 = zext nneg i32 %5 to i64
  %9 = call i32 @cq_template_mul_i64_hl(i32 %8, i64 8)    ; IR: %7 = getelementptr inbounds [2 x ptr], ptr @fps, i64 0, i64 %6  [the tainted index scaled by the element size (rule 20)]
  %10 = call i32 @cq_template_add_i64_hl(i32 %9, i64 ptrtoint (ptr @fps to i64))    ; IR: %7 = getelementptr  [+ the classical base: the address rail of &fps[x & 1]]
  %11 = call i32 @cqrt_qram_load_i64(i32 %4, i32 %10)    ; IR: %8 = load ptr, ptr %7, align 8  [a load at an address rail: fp, a 64-bit rail holding the callee's address; overtaken by the dispatch, un-copied after the reverse loop (rule 5)]
  %12 = call i32 @cq_template_add_i32_hl(i32 %6, i32 %2)    ; IR: %9 = add nsw i32 %4, %2  [the call's argument rail]
  %13 = call i32 @__cq_clone_count(ptr @.cq.sig)    ; IR: %10 = call i32 %8(i32 %9)  [n, the number of registered functions of type i32 (i32): the candidates (rule 19)]
  %14 = call i32 @cqrt_alloc_i1(i1 true)    ; p_0: the complement of no flag (a |1> seed: no predicate in scope, rules 7, 16)
  %15 = call i32 @cqrt_alloc_i32(i32 0)    ; out_0: the merge of no candidate (a seed)
  br label %16    ; the dispatch: one trip per candidate, classical code (rules 14, 19)

16:
  %17 = phi i32 [ 0, %3 ], [ %31, %21 ]    ; candidate index i (classical)
  %18 = phi i32 [ %14, %3 ], [ %29, %21 ]    ; p_i: 1 iff fp is none of a_0 .. a_{i-1}
  %19 = phi i32 [ %15, %3 ], [ %30, %21 ]    ; out_i: the merge of candidates 0 .. i-1
  %20 = icmp ult i32 %17, %13
  br i1 %20, label %21, label %32

21:
  %22 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %17)    ; a_i: the host address of candidate i (registration order)
  %23 = ptrtoint ptr %22 to i64    ; a_i as a classical i64 (rule 21)
  %24 = call i32 @cq_template_icmp_eq_i64_hl(i32 %11, i64 %23)    ; IR: %10 = call i32 %8(i32 %9)  [flag f_i: fp == a_i (rule 13's compare)]
  %25 = call ptr @__cq_clone_resolve(ptr %22, i32 1)    ; the _t_ctl clone of a_i (kind 1)
  %26 = call i32 %25(i32 %24, i32 %12, i32 4)    ; IR: %10 = call i32 %8(i32 %9)  [candidate i under f_i: predicate, the argument rail c + x, K; a memory version change (rule 19)]  [K]
  %27 = call i32 @cqrt_alloc_i32(i32 0)    ; c_i: the copy that is KEPT in the result's place (rule 19)
  call void @cqrt_copy_i32(i32 %26, i32 %27)    ; c_i ^= the result, before the next memory version change
  %28 = call ptr @__cq_clone_resolve(ptr %22, i32 3)    ; the _t_ctl_unc twin of a_i (kind 3)
  call void %28(i32 %24, i32 %26, i32 %12, i32 4)    ; IR: the twin, exactly once, under the same flag: predicate, the result, the argument, K (it frees what it zeroes)  [K]
  %29 = call i32 @cqrt_alloc_i1(i1 false)    ; p_{i+1}
  call void @cqrt_not_i1(i32 %24)    ; X bracket: NOT f_i (rule 8)
  call void @cqrt_and_i1(i32 %18, i32 %24, i32 %29)    ; p_{i+1} = p_i & NOT f_i
  call void @cqrt_not_i1(i32 %24)    ; close the X bracket
  %30 = call i32 @cq_template_select_i32(i32 %24, i32 %27, i32 %19)    ; IR: %10 = call i32 %8(i32 %9)  [merge: candidate i's result under f_i, else the merge so far (rule 9)]
  call void @cqrt_push(i32 %18)    ; p_i, out_i, c_i and f_i, for the reverse loop (rule 14)
  call void @cqrt_push(i32 %19)
  call void @cqrt_push(i32 %27)
  call void @cqrt_push(i32 %24)
  %31 = add nuw i32 %17, 1
  br label %16

32:
  %33 = call i32 @cqrt_tape_write_i64_controlled(i32 %18, i32 %5, i32 %11)    ; IR: %10 = call i32 %8(i32 %9)  [under p_n, the complement of the flags: the entry's first field, the callee's address, the rail fp (rule 19)]
  %34 = call i32 @cqrt_tape_write_i32_controlled(i32 %18, i32 %5, i32 %12)    ; the argument c + x
  %35 = call i32 @cqrt_tape_effect_i32_controlled(i32 %18, i32 %5, ptr null)    ; IR: %10 = call i32 %8(i32 %9)  [fp is host code: the effect entry with a null name; r_e, its result rail, KEPT (rule 16)]
  call void @cq_template_add_i32_hl_unc(i32 %12, i32 %6, i32 %2)    ; IR: uncompute %9  [after its last reader, the entry's field (rule 5)]
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  %36 = call i32 @cq_template_select_i32(i32 %18, i32 %35, i32 %19)    ; IR: %10 = call i32 %8(i32 %9)  [the call's value: the complement's r_e where p_n, else the candidates' merge]  ; SPEC GAP: the complement is an arm of this outer select (header)
  %37 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %10 = call i32 %8(i32 %9)  [copied-out result R (rule 14)]
  call void @cqrt_copy_i32(i32 %36, i32 %37)    ; IR: %10
  call void @cq_template_select_i32_unc(i32 %36, i32 %18, i32 %35, i32 %19)    ; IR: uncompute the outer select
  call void @cqrt_free(i32 %36)    ; IR: release it (|0>)
  br label %38    ; the reverse loop: candidates n-1 .. 0 (the pop order)

38:
  %39 = phi i32 [ %13, %32 ], [ %44, %43 ]    ; trips left to undo (classical)
  %40 = phi i32 [ %18, %32 ], [ %48, %43 ]    ; p_{i+1} of the trip being undone
  %41 = phi i32 [ %19, %32 ], [ %47, %43 ]    ; out_{i+1} of the trip being undone
  %42 = icmp eq i32 %39, 0
  br i1 %42, label %51, label %43

43:
  %44 = add i32 %39, -1    ; the trip's candidate index i
  %45 = call i32 @cqrt_pop()    ; f_i
  %46 = call i32 @cqrt_pop()    ; c_i (kept: only its handle is read)
  %47 = call i32 @cqrt_pop()    ; out_i
  %48 = call i32 @cqrt_pop()    ; p_i
  call void @cq_template_select_i32_unc(i32 %41, i32 %45, i32 %46, i32 %47)    ; IR: uncompute the merge of candidate i
  call void @cqrt_free(i32 %41)    ; IR: release it (|0>)
  call void @cqrt_not_i1(i32 %45)    ; X bracket: NOT f_i
  call void @cqrt_and_i1(i32 %48, i32 %45, i32 %40)    ; uncompute p_{i+1} (after its last use: the uncompute of p_{i+2}, or for p_n the effect entry and the outer select)
  call void @cqrt_not_i1(i32 %45)    ; close the X bracket
  call void @cqrt_free(i32 %40)    ; release it (|0>)
  %49 = call ptr @__cq_clone_at(ptr @.cq.sig, i32 %44)    ; a_i again, from the trip index (rule 14)
  %50 = ptrtoint ptr %49 to i64
  call void @cq_template_icmp_eq_i64_hl_unc(i32 %45, i32 %11, i64 %50)    ; IR: uncompute the flag f_i (after its last use)
  call void @cqrt_free(i32 %45)    ; IR: release it (|0>)
  br label %38

51:
  call void @cqrt_free(i32 %40)    ; release p_0 (a |1> seed, never written: a known basis state, rule 7)
  call void @cqrt_free(i32 %41)    ; release out_0 (a seed, never written: |0>, rule 7)
  call void @cqrt_qram_load_i64_unc(i32 %11, i32 %4, i32 %10)    ; IR: un-copy %8  [fp, after its last reader (the last flag's _unc); overtaken by the dispatch, so it stays allocated (rule 5 sentence 1)]
  call void @cq_template_add_i64_hl_unc(i32 %10, i32 %9, i64 ptrtoint (ptr @fps to i64))    ; IR: uncompute %7  [the address rail, after the load's _unc (rule 5)]
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  call void @cq_template_mul_i64_hl_unc(i32 %9, i32 %8, i64 8)    ; IR: uncompute %7 (the scaled index)
  call void @cqrt_free(i32 %9)    ; IR: release the scaled-index rail (|0>)
  call void @cq_template_zext_i32_to_i64_unc(i32 %8, i32 %7)    ; IR: uncompute %6
  call void @cqrt_free(i32 %8)    ; IR: release the %6 rail (|0>)
  call void @cq_template_and_i32_hl_unc(i32 %7, i32 %6, i32 1)    ; IR: uncompute %5
  call void @cqrt_free(i32 %7)    ; IR: release the %5 rail (|0>)
  %52 = call i32 @cqrt_measure_i32(i32 %37)    ; IR: %11 = cq_measure_si32(%10)  [not in a _ctl clone: the result rail itself is measured (rule 2)]
  ret i32 %52    ; IR: ret i32 %11
}

define internal i32 @dbl(i32 noundef %0) {
  %2 = shl nsw i32 %0, 1    ; IR: %2 = shl nsw i32 %0, 1  (the own symbol: no bus access, no cq_* call, no call, so its own lowering, rule 19; its address is the cell value in @fps and the table key)
  ret i32 %2    ; IR: ret i32 %2
}

define internal i32 @sq(i32 noundef %0) {
  %2 = mul nsw i32 %0, %0    ; IR: %2 = mul nsw i32 %0, %0  (the own symbol, its own lowering, rule 19; the table key of the second cell of @fps)
  ret i32 %2    ; IR: ret i32 %2
}

define internal i32 @__cq_q_dbl_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_shl_i32_hl(i32 %0, i32 1)    ; IR: %2 = shl nsw i32 %0, 1  (table clone: the handle, then K; a one-template body returns its rail, rule 18)
  ret i32 %3    ; IR: ret i32 %2
}

define internal void @__cq_q_dbl_1_t_unc(i32 %0, i32 %1, i32 %2) {
  call void @cq_template_shl_i32_hl_unc(i32 %0, i32 %1, i32 1)    ; IR: uncompute %2  (twin: the result, the argument, K)
  call void @cqrt_free(i32 %0)    ; IR: release the result rail (|0>): a table clone's twin frees what it zeroes (§1.4)
  ret void
}

define internal i32 @__cq_q_dbl_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_dbl, align 4    ; d: this activation's depth (§1.4)
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_dbl, align 4    ; one more live _ctl activation of dbl
  %6 = icmp ult i32 %4, %2    ; d below K: the body runs (rule 14)
  br i1 %6, label %7, label %11

7:
  %8 = call i32 @cq_template_shl_i32_hl(i32 %1, i32 1)    ; IR: %2 = shl nsw i32 %0, 1  (a template on an SSA value: computed unguarded, the caller merges by select, rule 9; the predicate %0 guards no gate here)
  %9 = load i32, ptr @__cq_act_dbl, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_dbl, align 4    ; the activation ends
  ret i32 %8    ; IR: ret i32 %2

11:
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; the cut: the result is a |0> rail (rule 14)
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; the overflow predicate of this cut activation, an output rail (KEPT)
  call void @cqrt_copy_i1(i32 %0, i32 %13)    ; a copy of the predicate
  %14 = load i32, ptr @__cq_act_dbl, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_dbl, align 4    ; the activation ends
  ret i32 %12
}

define internal void @__cq_q_dbl_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_dbl, align 4    ; d (§1.4): the twin makes the same cut
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_dbl, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %9

8:
  call void @cq_template_shl_i32_hl_unc(i32 %1, i32 %2, i32 1)    ; IR: uncompute %2  (twin: predicate, the result, the argument, K)
  br label %9

9:
  call void @cqrt_free(i32 %1)    ; IR: release the result rail (|0>: zeroed above, or the cut activation's |0> rail)
  %10 = load i32, ptr @__cq_act_dbl, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_dbl, align 4
  ret void
}

define internal i32 @__cq_q_sq_1_t(i32 %0, i32 %1) {
  %3 = call i32 @cq_template_mul_i32(i32 %0, i32 %0)    ; IR: %2 = mul nsw i32 %0, %0  (table clone: the handle, then K; a one-template body returns its rail, rule 18)
  ret i32 %3    ; IR: ret i32 %2
}

define internal void @__cq_q_sq_1_t_unc(i32 %0, i32 %1, i32 %2) {
  call void @cq_template_mul_i32_unc(i32 %0, i32 %1, i32 %1)    ; IR: uncompute %2  (twin: the result, the argument, K)
  call void @cqrt_free(i32 %0)    ; IR: release the result rail (|0>): a table clone's twin frees what it zeroes (§1.4)
  ret void
}

define internal i32 @__cq_q_sq_1_t_ctl(i32 %0, i32 %1, i32 %2) {
  %4 = load i32, ptr @__cq_act_sq, align 4    ; d: this activation's depth (§1.4)
  %5 = add i32 %4, 1
  store i32 %5, ptr @__cq_act_sq, align 4    ; one more live _ctl activation of sq
  %6 = icmp ult i32 %4, %2    ; d below K: the body runs (rule 14)
  br i1 %6, label %7, label %11

7:
  %8 = call i32 @cq_template_mul_i32(i32 %1, i32 %1)    ; IR: %2 = mul nsw i32 %0, %0  (a template on SSA values: computed unguarded, the caller merges by select, rule 9; the predicate %0 guards no gate here)
  %9 = load i32, ptr @__cq_act_sq, align 4
  %10 = add i32 %9, -1
  store i32 %10, ptr @__cq_act_sq, align 4    ; the activation ends
  ret i32 %8    ; IR: ret i32 %2

11:
  %12 = call i32 @cqrt_alloc_i32(i32 0)    ; the cut: the result is a |0> rail (rule 14)
  %13 = call i32 @cqrt_alloc_i1(i1 false)    ; the overflow predicate of this cut activation, an output rail (KEPT)
  call void @cqrt_copy_i1(i32 %0, i32 %13)    ; a copy of the predicate
  %14 = load i32, ptr @__cq_act_sq, align 4
  %15 = add i32 %14, -1
  store i32 %15, ptr @__cq_act_sq, align 4    ; the activation ends
  ret i32 %12
}

define internal void @__cq_q_sq_1_t_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {
  %5 = load i32, ptr @__cq_act_sq, align 4    ; d (§1.4): the twin makes the same cut
  %6 = add i32 %5, 1
  store i32 %6, ptr @__cq_act_sq, align 4
  %7 = icmp ult i32 %5, %3
  br i1 %7, label %8, label %9

8:
  call void @cq_template_mul_i32_unc(i32 %1, i32 %2, i32 %2)    ; IR: uncompute %2  (twin: predicate, the result, the argument, K)
  br label %9

9:
  call void @cqrt_free(i32 %1)    ; IR: release the result rail (|0>: zeroed above, or the cut activation's |0> rail)
  %10 = load i32, ptr @__cq_act_sq, align 4
  %11 = add i32 %10, -1
  store i32 %11, ptr @__cq_act_sq, align 4
  ret void
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
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_push(i32)
declare i32 @cqrt_pop()
declare i32 @cqrt_qram_load_i64(i32, i32)
declare void @cqrt_qram_load_i64_unc(i32, i32, i32)
declare i32 @cqrt_tape_alloc()
declare i32 @cqrt_tape_write_i64_controlled(i32, i32, i32)
declare i32 @cqrt_tape_write_i32_controlled(i32, i32, i32)
declare i32 @cqrt_tape_effect_i32_controlled(i32, i32, ptr)
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
