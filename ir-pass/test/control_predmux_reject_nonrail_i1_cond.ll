; control_predmux_reject_nonrail_i1_cond.ll — DECLINE (bd test_C_libtooling-fn1q
; increment 2). THE LEAF IS A RAIL, NOT "ANY TAINTED i1".
;
; The condition is `trunc i32 %q to i1` on a tainted register: an `i1`, tainted,
; and a perfectly ordinary branch condition — and it still declines, because the
; E6 leaf calls `isCondRailLeaf` (SelectClassify.h), which is a `cq_theta_i1`
; CALL and nothing else.
;
; ⚠ THIS FIXTURE EXISTS BECAUSE THE OBVIOUS SPELLING OF THE WIDENING IS WRONG.
; "Admit an opaque tainted `i1` as a cond-tree leaf" would take this module too,
; and `isSupportedCondTree` has NO TaintSet in scope — so the test would have had
; to be structural ("an i1 that is not a cmp/phi/and/or/xor/select"), which admits
; a CLASSICAL i1 at any INTERIOR position of the tree. The backstop there is
; `SelectClassify`'s GATE-2 per-leaf taint check, i.e. a claim-then-decline where
; the oracle declined pre-claim — the bd 3c6m.67 self-operand lesson verbatim.
; Calling `isCondRailLeaf` avoids the whole question: a `cq_theta_i1` result is
; ALWAYS tainted (Rule 3 — `cq_theta` is the sole taint source), so the narrow
; predicate is also the one that needs no taint argument. Ask the question you
; mean, not a shape that resembles it (the bd 11qv round-4 (P4) lesson).
;
; ⚠ RETIREMENT TRIGGER (L8): `trunc`/`zext`/phi/argument `i1` conditions are bd
; `r903`'s filed residual family. If that bead lands, this becomes an ACCEPT —
; re-derive the stream, do not delete the file.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %t = trunc i32 %q to i1
  br i1 %t, label %arm, label %merge
arm:
  br label %merge
merge:
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %m1 = call i32 @cq_measure_si32(i32 %a4)
  %m2 = call i32 @cq_measure_si32(i32 %b5)
  %m3 = call i32 @cq_measure_si32(i32 %q)
  %s = add i32 %m1, %m2
  %s2 = add i32 %s, %m3
  ret i32 %s2
}

; CHECK: error:
; CHECK-SAME: cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy_i32_controlled
