; HAND-WRITTEN. Rules: 2, 4, 5, 8, 9, 14, 18, 19; §1.4 (Recursion: one _ctl clone, the activation counter).
; Checked: chain(n & 3, a) with the recursion cut at K = 4 (the copied-out result %6, measured -> %7).
; Clean: the scrutinee n & 3; in __cq_q_chain_10_b3, in every activation of __cq_q_chain_10_ctl that runs its body and of
;        its twin: the base-case flag c, n - 1, the conjunction p & !c (_ctl and twin only), the callee's result (zeroed
;        by the twin, then freed; a |0> rail at the cut), the difference and the merge.
; Kept: the user register n (%4); the result rail of __cq_q_chain_10_b3 (%6, measured); ONE overflow rail per cut
;       activation of __cq_q_chain_10_ctl (rule 14): each a copy_i1 of that activation's predicate, [(n & 3) >= 5] = |0>
;       on every branch (B = 3 < K: rule 14's recursion clause has no B condition); 2^K = 16 of them in one call of the entry.
; Rotations: (Ry, n, th, 1).
; Expected (Ry(th) acts on every qubit of a rail, so each bit flips with probability s(th) = sin^2(th/2), independently):
;   quantum_depth_recursion(0, .5, 2): m = n & 3 is the two low bits of n, each flipped from 0 with s = 0.0612087.
;     chain(m, 2) is 2 for m = 0, -1 for m = 1, 3 for m = 2, -2 for m = 3 (the cut never binds: m <= 3, so at most
;     three activations of the _ctl clone run their base case or recurse with a predicate that can be 1). Measured: 2
;     with probability 0.881329, -1 with 0.057462, 3 with 0.057462, -2 with 0.003747. Every overflow rail reads 0.
; TRUE RECURSION WITH QUANTUM DEPTH, ONE CLONE (§1.4, rule 14). clang cannot loop-convert chain (the result is used
; non-associatively), so the clone recurses. chain's base-case test reads the rail n, and its recursive call sits in the
; arm n > 0: a call under a quantum predicate of a function on a call cycle, so the callee is the _ctl clone (rule 19),
; __cq_q_chain_10_ctl(pred, n, a): mask 10 at every depth (a + 1 stays classical), ONE clone whatever the depth, and no
; depth is passed. The entry calls chain with no predicate in scope: __cq_q_chain_10_b3(n & 3, a), the rule-18 clone of
; mask 10 with the bound 3 of its quantum argument (§1.4 _bN: the range fact of `and %4, 3` at the call site). chain's
; own symbol has no remaining use and is dropped (§1.4).
; The clone body (all three definitions share it). c = (n < 1) is the base-case flag. The recursive arm's pure code
; (n - 1; a + 1 is classical) is hoisted and computed unguarded (rule 9); the call stays in its arm, under NOT c: an X
; bracket on c in __cq_q_chain_10_b3 (rule 8: the false edge), and in the _ctl clone the conjunction f = p & !c in a
; fresh rail (and_i1 inside the X bracket), which is the callee's predicate. The call is not tail: a - r is computed
; after it (sub_lh, unguarded: r is read by nothing when c holds), and the phi merges by select on c (rule 9). The clone
; copies the merge out, uncomputes select and sub, zeroes r by the callee's twin __cq_q_chain_10_ctl_unc(pred, r, n - 1,
; a + 1) under the same predicate value (the same bracket, or f before its teardown), frees r, and uncomputes f, n - 1
; and c. The twin recomputes the same chain, XORs the merge out of the result rail and uncomputes; the caller frees the
; result. __cq_q_chain_10_b3 has no twin (nobody calls one, §1.4): its result is measured by the entry. chain touches
; no memory: no bus, no __cq_mem.
; THE ACTIVATION COUNTER AND THE CUT. chain lies on a call cycle, so it has one module-internal classical counter of its
; live _ctl activations, @__cq_act_chain (§1.4). __cq_q_chain_10_ctl and its twin read it on entry (the depth d), add
; 1, and subtract 1 at their return. A classical branch on d decides: while d < K = 4 [K] the body runs; at d = K the
; clone returns at once, its result a |0> rail, and a copy_i1 of its predicate into a fresh rail is the kept overflow
; predicate (rule 14: one per cut activation). __cq_q_chain_10_b3 is no _ctl clone and does not count, so the
; activations are: __cq_q_chain_10_b3 on m = n & 3, then _ctl at d = 0..3 on m - 1..m - 4, and the cut at d = 4, whose
; predicate is m >= 1 & .. & m >= 5 = [m >= 5], |0> since m <= 3. The host recursion gives every activation its own
; rails. Cost: each body calls the next level's clone and its twin, so 2^(d+1) bodies run at depth d and 2^K = 16
; forward activations reach the cut.
; THE CUT. Rule 14's recursion clause cuts at K whatever decides the depth and keeps one overflow copy per cut
; activation (no B condition: that is the loop clause); §1.4 _bN bounds serve loop cutoffs only, and the one _ctl clone
; carries none. The forward clone that a twin calls to recompute keeps its copy at the cut; the twin's own cut mints
; nothing and calls no gate (rule 14).
source_filename = "quantum_depth_recursion.c"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx16.0.0"

@__cq_act_chain = internal global i32 0, align 4    ; §1.4: the counter of chain's live _ctl activations (compiler state, not program memory)

define i32 @quantum_depth_recursion(i32 noundef %0, double noundef %1, i32 noundef %2) {
  %4 = call i32 @cqrt_alloc_i32(i32 %0)    ; IR: %4 = cq_theta_si32(%0, %1)  [register n]
  call void @cqrt_ry_i32(i32 %4, double %1)    ; IR: %4 = cq_theta_si32(%0, %1)  [Ry]
  %5 = call i32 @cq_template_and_i32_hl(i32 %4, i32 3)    ; IR: %5 = and i32 %4, 3
  %6 = call fastcc i32 @__cq_q_chain_10_b3(i32 %5, i32 %2)    ; IR: %6 = call @chain(%5, %2): the clone of mask 10 (arg 0 quantum, bound 3), no predicate in scope
  call void @cq_template_and_i32_hl_unc(i32 %5, i32 %4, i32 3)    ; IR: uncompute %5
  call void @cqrt_free(i32 %5)    ; IR: release the %5 rail (|0>)
  %7 = call i32 @cqrt_measure_i32(i32 %6)    ; IR: %7 = cq_measure_si32(%6)  (the clone's copied-out result rail stays allocated)
  ret i32 %7    ; IR: ret i32 %7
}

define internal fastcc i32 @__cq_q_chain_10_b3(i32 %0, i32 %1) {    ; IR: chain(n quantum, a classical), no predicate
  %3 = call i32 @cq_template_icmp_slt_i32_hl(i32 %0, i32 1)    ; IR: %3 = icmp slt i32 %0, 1  [base-case flag c; block %6 runs under NOT c]
  %4 = call i32 @cq_template_add_i32_hl(i32 %0, i32 -1)    ; IR: %7 = add nsw i32 %0, -1  (pure arm code, hoisted: rule 9)
  %5 = add nsw i32 %1, 1    ; IR: %8 = add nsw i32 %1, 1  (classical)
  call void @cqrt_not_i1(i32 %3)    ; IR: bracket: block %6 runs under NOT %3
  %6 = call fastcc i32 @__cq_q_chain_10_ctl(i32 %3, i32 %4, i32 %5)    ; IR: %9 = call @chain(%7, %8) under the predicate n > 0: the _ctl clone (rule 19: a call cycle), depth d = 0; rule 14: no bound
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
  call fastcc void @__cq_q_chain_10_ctl_unc(i32 %3, i32 %6, i32 %4, i32 %5)    ; IR: uncompute %9 (the _ctl clone's twin, depth d = 0)  §1.4: _ctl_unc(pred, outs.., args..)
  call void @cqrt_not_i1(i32 %3)    ; IR: bracket
  call void @cqrt_free(i32 %6)    ; IR: release the %9 rail (|0>)
  call void @cq_template_add_i32_hl_unc(i32 %4, i32 %0, i32 -1)    ; IR: uncompute %7
  call void @cqrt_free(i32 %4)    ; IR: release the %7 rail (|0>)
  call void @cq_template_icmp_slt_i32_hl_unc(i32 %3, i32 %0, i32 1)    ; IR: uncompute %3
  call void @cqrt_free(i32 %3)    ; IR: release the %3 rail (|0>)
  ret i32 %9    ; IR: ret i32 %5
}

define internal fastcc i32 @__cq_q_chain_10_ctl(i32 %0, i32 %1, i32 %2) {    ; IR: chain(n quantum, a classical) under the predicate %0: ONE clone for every depth
  %4 = load i32, ptr @__cq_act_chain, align 4    ; IR: §1.4: the activation's depth d = the live _ctl activations of chain
  %5 = add i32 %4, 1    ; IR: §1.4: this activation is live
  store i32 %5, ptr @__cq_act_chain, align 4    ; IR: §1.4: the counter adds 1
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
  %12 = call fastcc i32 @__cq_q_chain_10_ctl(i32 %11, i32 %9, i32 %10)    ; IR: %9 = call @chain(%7, %8) under f: the same clone, depth d + 1
  %13 = call i32 @cq_template_sub_i32_lh(i32 %2, i32 %12)    ; IR: %10 = sub nsw i32 %1, %9  (after the call: not a tail call)
  %14 = call i32 @cq_template_select_i32_lh(i32 %8, i32 %2, i32 %13)    ; IR: %5 = phi [ %10, %6 ], [ %1, %2 ]: c ? a : %10
  %15 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: ret i32 %5  [result rail of the call]
  call void @cqrt_copy_i32(i32 %14, i32 %15)    ; IR: ret i32 %5  [copy the result out, unguarded (§1.4 _ctl): not |0> where pred = 0; the caller merges by select and its twin XORs the same value back]
  call void @cq_template_select_i32_lh_unc(i32 %14, i32 %8, i32 %2, i32 %13)    ; IR: uncompute %5
  call void @cqrt_free(i32 %14)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %13, i32 %2, i32 %12)    ; IR: uncompute %10
  call void @cqrt_free(i32 %13)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_chain_10_ctl_unc(i32 %11, i32 %12, i32 %9, i32 %10)    ; IR: uncompute %9 (the twin under the same f, depth d + 1)  §1.4: _ctl_unc(pred, outs.., args..)
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
  call void @cqrt_copy_i1(i32 %0, i32 %17)    ; IR: rule 14: copy_i1 of the predicate: the KEPT overflow predicate (one per cut activation; [m >= 5] = |0> here)  rule 14: a forward clone called from a twin keeps its copy too
  %18 = call i32 @cqrt_alloc_i32(i32 0)    ; IR: rule 14: the cut activation returns at once, its result a |0> rail
  br label %19    ; IR: to the return

19:
  %20 = phi i32 [ %15, %7 ], [ %18, %16 ]    ; IR: ret i32 %5  (classical choice of the handle: body or cut)
  %21 = load i32, ptr @__cq_act_chain, align 4    ; IR: §1.4: the counter at the return
  %22 = add i32 %21, -1    ; IR: §1.4: this activation ends
  store i32 %22, ptr @__cq_act_chain, align 4    ; IR: §1.4: the counter subtracts 1
  ret i32 %20    ; IR: ret i32 %5
}

define internal fastcc void @__cq_q_chain_10_ctl_unc(i32 %0, i32 %1, i32 %2, i32 %3) {    ; IR: twin of __cq_q_chain_10_ctl: (pred, out, n, a)  §1.4
  %5 = load i32, ptr @__cq_act_chain, align 4    ; IR: §1.4: the activation's depth d (the twin counts like its clone)
  %6 = add i32 %5, 1    ; IR: §1.4: this activation is live
  store i32 %6, ptr @__cq_act_chain, align 4    ; IR: §1.4: the counter adds 1
  %7 = icmp ult i32 %5, 4    ; IR: rule 14: the twin makes the same cut  [K]
  br i1 %7, label %8, label %16    ; IR: rule 14: at d = K the result is |0> already: nothing to zero, no overflow rail (rule 14: the twin's cut mints nothing and calls no gate)

8:
  %9 = call i32 @cq_template_icmp_slt_i32_hl(i32 %2, i32 1)    ; IR: recompute %3
  %10 = call i32 @cq_template_add_i32_hl(i32 %2, i32 -1)    ; IR: recompute %7
  %11 = add nsw i32 %3, 1    ; IR: %8  (classical)
  %12 = call i32 @cqrt_alloc_i1(i1 false)    ; IR: recompute f = pred & NOT c (fresh |0>)
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket: NOT %3
  call void @cqrt_and_i1(i32 %0, i32 %9, i32 %12)    ; IR: f = pred & NOT c
  call void @cqrt_not_i1(i32 %9)    ; IR: bracket
  %13 = call fastcc i32 @__cq_q_chain_10_ctl(i32 %12, i32 %10, i32 %11)    ; IR: recompute %9 = call @chain(%7, %8) under f (the clone, depth d + 1)
  %14 = call i32 @cq_template_sub_i32_lh(i32 %3, i32 %13)    ; IR: recompute %10
  %15 = call i32 @cq_template_select_i32_lh(i32 %9, i32 %3, i32 %14)    ; IR: recompute %5
  call void @cqrt_copy_i32(i32 %15, i32 %1)    ; IR: ret i32 %5  [xor the result out of the result rail: |0>]
  call void @cq_template_select_i32_lh_unc(i32 %15, i32 %9, i32 %3, i32 %14)    ; IR: uncompute %5
  call void @cqrt_free(i32 %15)    ; IR: release the %5 rail (|0>)
  call void @cq_template_sub_i32_lh_unc(i32 %14, i32 %3, i32 %13)    ; IR: uncompute %10
  call void @cqrt_free(i32 %14)    ; IR: release the %10 rail (|0>)
  call fastcc void @__cq_q_chain_10_ctl_unc(i32 %12, i32 %13, i32 %10, i32 %11)    ; IR: uncompute %9 (the twin under the same f, depth d + 1)
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
  %17 = load i32, ptr @__cq_act_chain, align 4    ; IR: §1.4: the counter at the return
  %18 = add i32 %17, -1    ; IR: §1.4: this activation ends
  store i32 %18, ptr @__cq_act_chain, align 4    ; IR: §1.4: the counter subtracts 1
  ret void
}

declare i32 @cqrt_alloc_i32(i32)
declare i32 @cqrt_alloc_i1(i1)
declare void @cqrt_ry_i32(i32, double)
declare void @cqrt_copy_i32(i32, i32)
declare void @cqrt_copy_i1(i32, i32)
declare void @cqrt_not_i1(i32)
declare void @cqrt_and_i1(i32, i32, i32)
declare i32 @cqrt_measure_i32(i32)
declare void @cqrt_free(i32)
declare i32 @cq_template_and_i32_hl(i32, i32)
declare void @cq_template_and_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_icmp_slt_i32_hl(i32, i32)
declare void @cq_template_icmp_slt_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_add_i32_hl(i32, i32)
declare void @cq_template_add_i32_hl_unc(i32, i32, i32)
declare i32 @cq_template_sub_i32_lh(i32, i32)
declare void @cq_template_sub_i32_lh_unc(i32, i32, i32)
declare i32 @cq_template_select_i32_lh(i32, i32, i32)
declare void @cq_template_select_i32_lh_unc(i32, i32, i32, i32)


!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}
!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 26, i32 4]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 8, !"PIC Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Homebrew clang version 19.1.7"}
