; control_phase_kickback_reject_tree_qq_leaf.ll — DECLINE. A Q+Q leaf (BOTH
; compare operands tainted) inside a compound branch-phase condition.
;
;     if (q == 5 && q < r) cq_phi(0.3);
;
; ⚠ THE DECLINE IS AT DETECTION, AND THAT PLACEMENT IS THE POINT. `q < r` IS
; `compareFlagMintable` — bd adia lifted the categorical Q+Q-leaf decline for the
; 4.4 select, which mints its network with `AllowQQLeaves = true`. The
; BRANCH-PHASE network mints with `AllowQQLeaves = false`, so a Q+Q leaf here
; would return null MID-NETWORK, after earlier leaf flags and node ancillas were
; already emitted: mutate-then-decline (the ziov.4 class). The classifier refuses
; it BEFORE the first mint instead.
;
; ⚠ THE MESSAGE IS NOW SHARED WITH THE SINGLE-COMPARE PATH — Rule-13 ROUND-2
; finding F-B2-2. This header used to record that the two paths had "the same
; DISPOSITION and different MESSAGES, deliberately", the single-compare one
; keeping `no template for opcode 'icmp i1'`. That was not a message difference,
; it was a LAYER difference: the single-compare path was declining in the OPCODE
; net because `classifyPhaseKickback` never asked the Q+Q question, so its
; tainted `br` was neither claimed nor declined by the control layer (Rule 1's
; third path). Both paths now take the control layer's own
; `quantum-quantum compare condition`, asked per leaf before any emission.
; Widening the tree to Q+Q still means giving the branch phase the select's
; `qqSelectLeafWidth` policy — one argument — and re-deriving part A's Q+Q
; disposition with it. Filed, not done here.
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
  %cb = icmp slt i32 %q, %r
  %c = select i1 %ca, i1 %cb, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}

; CHECK: cq controlled lowering: quantum-quantum compare condition under quantum control
