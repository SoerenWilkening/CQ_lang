; HAND-WRITTEN. Rules: 2, 4, 5, 6, 8, 9, 14, 18, 19, 20; §1.3 (the bus, __cq_mem), §1.4 (Recursion: one _ctl clone, the activation counter).
; Checked: quantum_depth_one_clone: down(n, a) with the recursion cut at K = 4 (the copied-out result %5, measured -> %6).
;          bool_cell_rotate: flag (the load copy %4, measured -> %5), the cell `flag` = the rotated bit.
;          theta_add_cell: acc (the load copy %7, measured -> %8), the cell `acc` = the rotated 5, plus d.
; Clean: in __cq_q_down_10, in every activation of __cq_q_down_10_ctl that runs its body and of its twin: the base-case
;        flag c, n - 1, the conjunction p & !c (_ctl and twin only), the callee's result (zeroed by the twin, then freed;
;        a |0> rail at the cut), the difference and the merge. bool_cell_rotate: the swap rail (%3). theta_add_cell: the
;        rotated old rail (%4, rule 6), the inverse t = y' - d (%6) and the rail the cell's |0> went to (%5).
; Kept: quantum_depth_one_clone: the user register n (%4), the result rail of __cq_q_down_10 (%5, measured), and ONE
;       overflow rail per cut activation of __cq_q_down_10_ctl (rule 14): each a copy_i1 of that activation's predicate,
;       [n >= 5]; 2^K = 16 of them in one call of the entry (see SPEC GAP 4). bool_cell_rotate: the load copy of flag (%4,
;       measured). theta_add_cell: the load copy of acc (%7, measured). No tape slot: both cell updates are in-place forms.
; Rotations: quantum_depth_one_clone: (Ry, n, th, 1). bool_cell_rotate: (Ry at width i1, the cell flag, th, 1).
;            theta_add_cell: (Ry, the cell acc, th, 1).
; Expected (Ry(th) acts on every qubit of a rail, so each bit flips with probability s(th) = sin^2(th/2), independently):
;   quantum_depth_one_clone(2, .5, 1): n from 2 with s = 0.0612087. With the cut, down(n, 1) is 1 for n <= 0, -1 for
;     n = 1, 2 for n = 2, -2 for n = 3, 3 for n = 4, and 3 for every n >= 5 (the cut activation returns |0>, so the
;     deepest running level returns a + 4 and the levels above give -1, a + 3, -2, a + 2; C would give another value
;     there, and every overflow rail reads 1). Measured: 3 with probability 0.788452 (0.787889 of it from n >= 5,
;     0.000563 from n = 4), 2 with 0.132498 (n unchanged), 1 with 0.069848 (n < 0: 0.061209, n = 0: 0.008639), -2 with
;     0.008639, -1 with 0.000563. P(overflow rails = 1) = 0.787889.
;   bool_cell_rotate(.5): flag from 0 with s = 0.0612087: 1 with probability 0.0612087, 0 with 0.9387913.
;   theta_add_cell(.25, 3): acc from 5 with s = 0.0155438: the measured acc + 3 is 8 with probability 0.605738 (acc
;     unchanged); each single-bit flip of acc has probability 0.009564.
; RECURSION WITH QUANTUM DEPTH, ONE CLONE (§1.4, rule 14). down's base-case test reads the rail n, and its recursive call
; sits in the arm n > 0: a call under a quantum predicate of a function on a call cycle, so the callee is the _ctl clone
; (rule 19), __cq_q_down_10_ctl(pred, n, a): mask 10 at every depth (a + 1 stays classical), ONE clone whatever the
; depth, and no depth is passed. The entry calls down with no predicate in scope: __cq_q_down_10(n, a), the rule-18 clone
; of mask 10. down's own symbol has no remaining use and is dropped (§1.4).
; The clone body (all three definitions share it). c = (n < 1) is the base-case flag. The recursive arm's pure code
; (n - 1; a + 1 is classical) is hoisted and computed unguarded (rule 9); the call stays in its arm, under NOT c: an X
; bracket on c in __cq_q_down_10 (rule 8: the false edge), and in the _ctl clone the conjunction f = p & !c in a fresh
; rail (and_i1 inside the X bracket), which is the callee's predicate. The call is not tail: a - r is computed after it
; (sub_lh, unguarded: r is read by nothing when c holds), and the phi merges by select on c (rule 9). The clone copies
; the merge out, uncomputes select and sub, zeroes r by the callee's twin __cq_q_down_10_ctl_unc(pred, r, n - 1, a + 1)
; under the same predicate value (the same bracket, or f before its teardown), frees r, and uncomputes f, n - 1 and c.
; The twin recomputes the same chain, XORs the merge out of the result rail and uncomputes; the caller frees the result.
; __cq_q_down_10 has no twin (nobody calls one, §1.4): its result is measured by the entry.
; THE ACTIVATION COUNTER AND THE CUT. down lies on a call cycle, so it has one module-internal classical counter of its
; live _ctl activations, @__cq_act_down (§1.4). __cq_q_down_10_ctl and its twin read it on entry (the depth d), add 1,
; and subtract 1 at their return. A classical branch on d decides: while d < K = 4 [K] the body runs; at d = K the
; clone returns at once, its result a |0> rail, and a copy_i1 of its predicate into a fresh rail is the kept overflow
; predicate (rule 14: one per cut activation; no range fact bounds n, so it is kept). The twin makes the same cut: it
; returns at once and touches nothing (the result it would zero is |0> already). __cq_q_down_10 is no _ctl clone and
; does not count, so the activations are: __cq_q_down_10 on n, then _ctl at d = 0..3 on n - 1..n - 4, and the cut at
; d = 4, whose predicate is n >= 1 & n >= 2 & .. & n >= 5 = [n >= 5]. The host recursion gives every activation its own
; rails. Cost: each body calls the next level's clone and its twin, so 2^(d+1) bodies run at depth d and 2^K = 16
; forward activations reach the cut.
; bool_cell_rotate. `load i8 @flag (!range [0, 2)); trunc nuw to i1; cq_theta_i1; zext to i8; store i8 @flag` is rule 5's
; in-place form through the Width-casts clause: the form at width i1 (rule 2: <W> is the cq_theta's own width, not the
; cell's access type): qram_swap_i1_hl, ry_i1, qram_swap_i1_hl, free. The high 7 bits of the cell never leave it.
; cq_measure reads the rotated value %4, a second reader of a value at the cq_theta step: it reads a plain load taken
; after the swap-in (rule 5, Readers), and that copy is measured and stays (rule 2).
; theta_add_cell. `load @acc; cq_theta_si32; add %1; store @acc` is ONE in-place form with two steps: the Ry on the
; swap rail, then the rule-6 bijection y' = y + d with the clean of the previous (rotated) rail, then the swap-in of y'.
; Nothing remains: no copy of the cell, no tape slot, no old value. cq_measure reads y' = %5, which the store also
; reads: a plain load taken after the swap-in, measured.
; SPEC GAPS (each marked at its line; the choice is the one that needs least from an implementer):
;  1. The activation counter has no name in §1.4. Chosen: internal global i32 @__cq_act_<fn>, zero-initialised, as in
;     211; "adds 1" / "subtracts 1" are load, add, store on it. It is compiler state, not program memory: no bus access,
;     no memory version change (rule 5), and it does not make down a function that writes memory (so the twin exists).
;  2. The parameter order of a _ctl clone's twin. Chosen: _ctl_unc(pred, outs.., args..), the predicate first as for
;     _t_ctl_unc (§1.4) and as in 211.
;  3. "_ctl controls every gate" (§1.4) for a clone that returns a value: the controlled arithmetic grid is retired, so
;     the templates run unguarded (rule 9) and the copy-out is the plain copy_<W> of rule 18's one form; the result under
;     pred = 0 is then not |0>, and the caller's select (rule 9) never reads it there. Only the callee's predicate (the
;     conjunction) and the overflow copy read pred.
;  4. Whether the forward _ctl clone called from a twin's recomputation keeps an overflow rail again. Rule 14 says one
;     per cut activation and rule 18's _pure removes phases only, so every forward cut activation keeps one (16 here,
;     all copies of the same predicate) and the twin's own cut keeps none.
;  5. The type of the Readers clause's plain load under the Width-casts clause. Chosen: the form's width U
;     (qram_load_i1_hl, §1.3: loaded from the low bit), not a load at the cell type followed by a trunc template.
source_filename = "quantum_depth_one_clone.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@acc = local_unnamed_addr global i32 5, align 4
@flag = local_unnamed_addr global i8 0, align 1
@__cq_act_down = internal global i32 0, align 4    ; SPEC GAP 1: the counter of down's live _ctl activations (§1.4 names none; compiler state, not program memory)

define i32 @quantum_depth_one_clone(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register n]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call fastcc i32 @__cq_q_down_10(i32 %4, i32 %2)    ; IR: %5 = call @down(%4, %2): the clone of mask 10 (arg 0 quantum), no predicate in scope
  %6 = call i32 @cqrt_measure_i32(i32 %5)    ; IR: %6 = cq_measure_si32(%5)  (the clone's copied-out result rail stays allocated)
  ret i32 %6    ; IR: ret i32 %6
}

define internal fastcc i32 @__cq_q_down_10(i32 %0, i32 %1) {    ; IR: down(n quantum, a classical), no predicate
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)    ; IR: %3 = icmp slt i32 %0, 1  [base-case flag c; block %6 runs under NOT c]
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %7 = add nsw i32 %0, -1  (pure arm code, hoisted: rule 9)
  %5 = add nsw i32 %1, 1    ; IR: %8 = add nsw i32 %1, 1  (classical)
  call void @cqrt_not_i1(i32 %3)    ; IR: bracket: block %6 runs under NOT %3
  %6 = call fastcc i32 @__cq_q_down_10_ctl(i32 %3, i32 %4, i32 %5)    ; IR: %9 = call @down(%7, %8) under the predicate n > 0: the _ctl clone (rule 19: a call cycle), depth d = 0
  call void @cqrt_not_i1(i32 %3)    ; IR: bracket
  %7 = call i32 @cq_template_sub_i32_lh(i32 %1, i32 %6)    ; IR: %10 = sub nsw i32 %1, %9  (after the call: not a tail call)
  %8 = call i32 @cq_template_select_i32_lh(i32 %3, i32 %1, i32 %7)    ; IR: %5 = phi [ %10, %6 ], [ %1, %2 ]: c ? a : %10
  %9 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %8, i32 %9)    ; IR: ret i32 %5  [copy the result out]
  call void @cq_template_select_i32_lh_unc(i32 %8, i32 %3, i32 %1, i32 %7)    ; IR: uncompute %5
  call void @cqrt_free(i32 %8)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %7, i32 %1, i32 %6)    ; IR: uncompute %10
  call void @cqrt_free(i32 %7)    ; IR: release the %10 rail (|0>)
  call void @cqrt_not_i1(i32 %3)    ; IR: bracket: the twin runs under the predicate value the call had
  call fastcc void @__cq_q_down_10_ctl_unc(i32 %3, i32 %6, i32 %4, i32 %5)    ; IR: uncompute %9 (the _ctl clone's twin, depth d = 0)  SPEC GAP 2: (pred, out, args)
  call void @cqrt_not_i1(i32 %3)    ; IR: bracket
  call void @cqrt_free(i32 %6)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %4)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %9    ; IR: ret i32 %5
}

define internal fastcc i32 @__cq_q_down_10_ctl(i32 %0, i32 %1, i32 %2) {    ; IR: down(n quantum, a classical) under the predicate %0: ONE clone for every depth
  %4 = load i32, ptr @__cq_act_down, align 4    ; IR: §1.4: the activation's depth d = the live _ctl activations of down
  %5 = add i32 %4, 1    ; IR: §1.4: this activation is live
  store i32 %5, ptr @__cq_act_down, align 4    ; IR: §1.4: the counter adds 1
  %6 = icmp ult i32 %4, 4    ; IR: rule 14: the classical branch on entry, d below the cutoff  [K]
  br i1 %6, label %7, label %16    ; IR: rule 14: the body runs while d < K; at d = K the activation is cut

7:
  %8 = call i32 @cq_template_icmp_slt_i32_hl(i32 %1, i32 1)    ; IR: %3 = icmp slt i32 %0, 1  [base-case flag c; block %6 runs under NOT c]
  %9 = call i32 @cq_template_add_i32_hl(i32 %1, i32 -1)    ; IR: %7 = add nsw i32 %0, -1  (pure arm code, hoisted: rule 9)
  %10 = add nsw i32 %2, 1    ; IR: %8 = add nsw i32 %1, 1  (classical)
  %11 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: the predicate of block %6: f = pred & NOT c (rule 8: a conjunction into a fresh |0>)
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket: NOT %3
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %11)    ; IR: br i1 %3 not taken under the clone's predicate: f = pred & NOT c
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket
  %12 = call fastcc i32 @__cq_q_down_10_ctl(i32 %11, i32 %9, i32 %10)    ; IR: %9 = call @down(%7, %8) under f: the same clone, depth d + 1
  %13 = call i32 @cq_template_sub_i32_lh(i32 %2, i32 %12)    ; IR: %10 = sub nsw i32 %1, %9  (after the call: not a tail call)
  %14 = call i32 @cq_template_select_i32_lh(i32 %8, i32 %2, i32 %13)    ; IR: %5 = phi [ %10, %6 ], [ %1, %2 ]: c ? a : %10
  %15 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %14, i32 %15)    ; IR: ret i32 %5  [copy the result out]  SPEC GAP 3: the plain copy; the caller's select never reads it where pred = 0
  call void @cq_template_select_i32_lh_unc(i32 %14, i32 %8, i32 %2, i32 %13)    ; IR: uncompute %5
  call void @cqrt_free(i32 %14)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %13, i32 %2, i32 %12)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_down_10_ctl_unc(i32 %11, i32 %12, i32 %9, i32 %10)    ; IR: uncompute %9 (the twin under the same f, depth d + 1)  SPEC GAP 2: (pred, out, args)
  call void @cqrt_free(i32 %12)    ; IR: release the %9 rail (|0>)
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket: NOT %3
  call void @cqrt_and_i1(i32 %0, i32 %8, i32 %11)    ; IR: uncompute f (after its last controlled call)
  call void @cqrt_not_i1(i32 %8)    ; IR: bracket
  call void @cqrt_free(i32 %11)    ; IR: release the f rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %9, i32 %1, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %9)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %8, i32 %1, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %8)    ; IR: release the %3 rail (|0>)
  br label %19    ; IR: to the return

16:
  %17 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: rule 14: the cut activation's overflow rail (fresh |0>)
  call void @cqrt_copy_i1(i32 %0, i32 %17)    ; IR: rule 14: copy_i1 of the predicate: the KEPT overflow predicate (an output rail, one per cut activation)  SPEC GAP 4
  %18 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: rule 14: the cut activation returns at once, its result a |0> rail
  br label %19    ; IR: to the return

19:
  %20 = phi i32 [ %15, %7 ], [ %18, %16 ]    ; IR: ret i32 %5  (classical choice of the handle: body or cut)
  %21 = load i32, ptr @__cq_act_down, align 4    ; IR: §1.4: the counter at the return
  %22 = add i32 %21, -1    ; IR: §1.4: this activation ends
  store i32 %22, ptr @__cq_act_down, align 4    ; IR: §1.4: the counter subtracts 1
  ret i32 %20    ; IR: ret i32 %5
}

define internal fastcc void @__cq_q_down_10_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {    ; IR: twin of __cq_q_down_10_ctl: (pred, out, n, a)  SPEC GAP 2
  %5 = load i32, ptr @__cq_act_down, align 4    ; IR: §1.4: the activation's depth d (the twin counts like its clone)
  %6 = add i32 %5, 1    ; IR: §1.4: this activation is live
  store i32 %6, ptr @__cq_act_down, align 4    ; IR: §1.4: the counter adds 1
  %7 = icmp ult i32 %5, 4    ; IR: rule 14: the twin makes the same cut  [K]
  br i1 %7, label %8, label %16    ; IR: rule 14: at d = K the result is |0> already: nothing to zero, no overflow rail (SPEC GAP 4)

8:
  %9 = call i32 @cq_template_icmp_slt_i32_hl(i32 %2, i32 1)    ; IR: recompute %3
  %10 = call i32 @cq_template_add_i32_hl(i32 %2, i32 -1)    ; IR: recompute %7
  %11 = add nsw i32 %3, 1    ; IR: %8  (classical)
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute f = pred & NOT c (fresh |0>)
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket: NOT %3
  call void @cqrt_and_i1(i32 %0, i32 %9, i32 %12)    ; IR: f = pred & NOT c
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket
  %13 = call fastcc i32 @__cq_q_down_10_ctl(i32 %12, i32 %10, i32 %11)    ; IR: recompute %9 = call @down(%7, %8) under f (the clone, depth d + 1)
  %14 = call i32 @cq_template_sub_i32_lh(i32 %3, i32 %13)    ; IR: recompute %10
  %15 = call i32 @cq_template_select_i32_lh(i32 %9, i32 %3, i32 %14)    ; IR: recompute %5
  call void @cqrt_copy_i32(i32 %15, i32 %1)    ; IR: ret i32 %5  [xor the result out of the result rail: |0>]
  call void @cq_template_select_i32_lh_unc(i32 %15, i32 %9, i32 %3, i32 %14)    ; IR: uncompute %5
  call void @cqrt_free(i32 %15)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %14, i32 %3, i32 %13)    ; IR: uncompute %10
  call void @cqrt_free(i32 %14)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_down_10_ctl_unc(i32 %12, i32 %13, i32 %10, i32 %11)    ; IR: uncompute %9 (the twin under the same f, depth d + 1)
  call void @cqrt_free(i32 %13)    ; IR: release the %9 rail (|0>)
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket: NOT %3
  call void @cqrt_and_i1(i32 %0, i32 %9, i32 %12)    ; IR: uncompute f
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket
  call void @cqrt_free(i32 %12)    ; IR: release the f rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %10, i32 %2, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %10)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %9, i32 %2, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %9)    ; IR: release the %3 rail (|0>)
  br label %16    ; IR: to the return

16:
  %17 = load i32, ptr @__cq_act_down, align 4    ; IR: §1.4: the counter at the return
  %18 = add i32 %17, -1    ; IR: §1.4: this activation ends
  store i32 %18, ptr @__cq_act_down, align 4    ; IR: §1.4: the counter subtracts 1
  ret void
}

define range(i32 0, 2) i32 @bool_cell_rotate(double noundef %0) {
  %2 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %3 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: %2 = load i8, ptr @flag; %3 = trunc nuw i8 %2 to i1: in-place form at width i1 (Width casts), the swap rail (|0>)
  call void @cqrt_qram_swap_i1_hl(i32 %2, i64 ptrtoint (ptr @flag to i64), i32 %3)    ; IR: %2 = load i8, ptr @flag; %3 = trunc: swap-out of the low bit: the rail holds flag, the cell's bit |0>
  call void @cqrt_ry_i1(i32 %3, double %0)    ; IR: %4 = cq_theta_i1(%3, %0)  [Ry at the cq_theta's width on the cell's content]
  call void @cqrt_qram_swap_i1_hl(i32 %2, i64 ptrtoint (ptr @flag to i64), i32 %3)    ; IR: %5 = zext i1 %4 to i8; store i8 %5, ptr @flag: swap-in: the cell holds the rotated bit (its high bits never left)
  call void @cqrt_free(i32 %3)    ; IR: release the swap rail (|0>)
  %4 = call i32 @cqrt_qram_load_i1_hl(i32 %2, i64 ptrtoint (ptr @flag to i64))    ; IR: the second reader of %4: a plain load of @flag taken after the swap-in (rule 5, Readers)  SPEC GAP 5: at the form's width i1
  %5 = call i1 @cqrt_measure_i1(i32 %4)    ; IR: %6 = cq_measure_i1(%4)  (the measured load copy stays allocated)
  %6 = zext i1 %5 to i32    ; IR: %7 = zext i1 %6 to i32  (classical)
  ret i32 %6    ; IR: ret i32 %7
}

define i32 @theta_add_cell(double noundef %0, i32 noundef %1) {
  %3 = call i32 @__cq_mem()    ; IR: the bus m (§5: once, at function entry)
  %4 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: %3 = load i32, ptr @acc: in-place form, the swap rail (|0>)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @acc to i64), i32 %4)    ; IR: %3 = load i32, ptr @acc: swap-out: the rail holds acc, the cell |0>
  call void @cqrt_ry_i32(i32 %4, double %0)    ; IR: %4 = cq_theta_si32(%3, %0)  [step 1: Ry on the cell's content]
  %5 = call i32 @cq_template_add_i32_hl(i32 %4, i32 %1)    ; IR: %5 = add nsw i32 %4, %1  [step 2: a rule-6 bijection in the previous value]
  %6 = call i32 @cq_template_sub_i32_hl(i32 %5, i32 %1)    ; IR: rule 6: t = y' - d recomputes the previous (rotated) value
  call void @cqrt_copy_i32(i32 %6, i32 %4)    ; IR: rule 6: the previous rail ^= t: |0>
  call void @cq_template_sub_i32_hl_unc(i32 %6, i32 %5, i32 %1)    ; IR: rule 6: uncompute t
  call void @cqrt_free(i32 %6)    ; IR: release t (|0>)
  call void @cqrt_free(i32 %4)    ; IR: release the previous rail (|0> after the copy)
  call void @cqrt_qram_swap_i32_hl(i32 %3, i64 ptrtoint (ptr @acc to i64), i32 %5)    ; IR: store i32 %5, ptr @acc: swap-in: the cell holds the rotated acc + d, the rail the cell's |0>
  call void @cqrt_free(i32 %5)    ; IR: release the rail (|0>): nothing remains of the update
  %7 = call i32 @cqrt_qram_load_i32_hl(i32 %3, i64 ptrtoint (ptr @acc to i64))    ; IR: the second reader of %5: a plain load of @acc taken after the swap-in (rule 5, Readers)
  %8 = call i32 @cqrt_measure_i32(i32 %7)    ; IR: %6 = cq_measure_si32(%5)  (the measured load copy stays allocated)
  ret i32 %8    ; IR: ret i32 %6
}

declare i32 @__cq_mem()
declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_ry_i1(i32, double)
declare i32 @cqrt_measure_i32(i32)
declare i1 @cqrt_measure_i1(i32)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_copy_i1(i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare void @cqrt_free(i32)
declare void @cqrt_qram_swap_i1_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i1_hl(i32, i64)
declare void @cqrt_qram_swap_i32_hl(i32, i64, i32)
declare i32 @cqrt_qram_load_i32_hl(i32, i64)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_hl(i32, i32)
declare void @cq_template_sub_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_lh(i32, i32)
declare void @cq_template_sub_i32_lh_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)
