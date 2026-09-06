; control_phase_kickback_reject_tree_stale_leaf.ll — DECLINE. A chained
; `cq_theta` (an IN-PLACE, NON-DIAGONAL Ry) between a LEAF's compare and the
; branch — the compound mirror of the flat stale-condition guard.
;
; The network is minted AT THE BRANCH, so the flag reads the leaf's wire basis
; AFTER any gate in between. An Ry on `%r` there makes `%cb`'s minted flag encode
; the POST-Ry predicate while the SSA leaf denotes the pre-Ry record: the wrong
; branch is marked, the strip does not return the flag to |0>, and the free is
; then a dirty free — a hidden measurement (Rule 6). Verify-clean in every
; respect.
;
; ⚠ THE GUARD IS ASKED OVER THE LEAF UNION, NOT THE ROOT. A walk seeded from the
; root alone would cross the tree nodes, which carry no rotation wire of their
; own, and a walk seeded from ONE leaf would accept a theta staling the OTHER
; leaf's — which is exactly this module (the theta is on `%r`, the SECOND leaf's
; register, while the first leaf's `%q` is untouched). The 4.4 select learned the
; same lesson at `control_swap_reject_select_stale_leaf_onewire.ll`.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %ca = icmp eq i32 %q, 5
  %cb = icmp eq i32 %r, 3
  %r2 = call i32 @cq_theta_si32(i32 %r, double 7.000000e-01)
  %c = select i1 %ca, i1 %cb, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r2)
  %s = add i32 %m, %n
  ret i32 %s
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
