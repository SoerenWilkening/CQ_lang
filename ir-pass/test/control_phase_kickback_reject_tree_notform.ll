; control_phase_kickback_reject_tree_notform.ll — DECLINE. The NOT-carrying
; logical-select complement `select i1 %ca, i1 false, i1 %cb` (≡ `¬ca ∧ cb`).
;
; The grammar admits exactly TWO logical-select spellings — `select %a, %b,
; false` (AND) and `select %a, true, %b` (OR) — and refuses the two complements
; `select %a, false, %b` and `select %a, %b, true`, which carry an implicit NOT.
; That is the same line the `xor X, 1` fence draws for the BinaryOperator
; spelling, and it is drawn for the same reason: a negated leaf needs a `cqrt_x`
; bracket on THAT leaf's rail inside the node, which the emitter supports
; (`CondNetwork::Node::NegL/NegR`, used by the P4 nest) but which NO probe family
; covers on this path. Admitting it would be an unprobed accept.
;
; The message is the bare-i1 one because the root is not a decomposable node and
; therefore not a tree at all — `collectCondTree` returns false, exactly as it
; does for a `trunc`/`freeze`/phi root.
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
  %c = select i1 %ca, i1 false, i1 %cb
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

; CHECK: cq controlled lowering: branch phase on a bare i1 condition under quantum control
