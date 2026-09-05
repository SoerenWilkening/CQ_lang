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
; ⚠ THE MESSAGE IS `control flow`, NOT THE BARE-i1 ONE, AND THAT CHANGED AT THE
; PART-A/PART-B MERGE (Rule-13 round-1 findings F-L3-7 / F-L5-5). Part B wrote
; this header saying "the message is the bare-i1 one because the root is not a
; decomposable node and therefore not a tree at all". The first half is true of
; `collectCondTree`'s RETURN VALUE and the second half is false of the PROGRAM:
; `%c = select i1 %ca, i1 false, i1 %cb` IS a condition tree — it is the NOT
; complement of one the grammar admits — and telling a user to look for a bare
; `_Bool` from `cq_theta` sends them somewhere there is nothing to find. The
; pre-3qlq oracle said `control flow` for every shape in this family and was
; right about all of them.
;
; The refusal path now splits by SHAPE, not by which predicate happened to
; return false: a `select`/`and`/`or`/`xor`-over-`i1` root that the grammar
; refuses takes `control flow`; a condition that is NOT an instruction, or is a
; tainted `i1` VALUE (a `cq_theta` result, a `zext`/`trunc` of one, a load),
; keeps `branch phase on a bare i1 condition`. That is what keeps
; `control_phase_kickback_reject_bare_i1.ll` a DISCRIMINATOR: when the bare-i1
; shape is built, its string must STOP firing, and under one shared message it
; would go on firing here with no fixture able to tell.
;
; The DISPOSITION is unchanged — this shape declines, loudly, for exactly the
; reason the paragraph above gives. Only the string moved.
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

; CHECK: cq controlled lowering: control flow under quantum control
; CHECK-NOT: bare i1 condition
