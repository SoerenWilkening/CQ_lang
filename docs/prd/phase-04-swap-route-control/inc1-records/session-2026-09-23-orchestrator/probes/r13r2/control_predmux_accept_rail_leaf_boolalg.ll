; control_predmux_accept_rail_leaf_boolalg.ll — ACCEPT (bd test_C_libtooling-fn1q
; increment 2, Rule-13 round 1 finding P2-2: a new accept surface the increment
; opened, that it had SHIPPED WITH NO FIXTURE).
;
; THE BoolAlg PATH. A bare-rail region whose merge carries an `i1` phi — here the
; arm's incoming is a tainted compare — takes `convertPhis`' BOOLEAN-ALGEBRA branch
; rather than the select chain: the phi is composed as `and(EP, incoming)` and
; `or`-accumulated, with NO select built. That path was never audited by the
; implementer and was named as the prime suspect in the review brief. It is SOUND,
; and this fixture is the witness that was missing.
;
; ⚠ IT IS A DIFFERENT CODE PATH FROM THE OTHER RAIL-LEAF FIXTURES and the
; increment's select-site arm-swap fold does NOT cover it: the BoolAlg composer
; builds `and(EP, X)` directly, so a ¬rail edge predicate survives there as a real
; `xor` node. On the POSITIVE polarity (this file) the edge predicate is the rail
; itself and the composer emits `cqrt_toffoli(rail, cmp, g)`. On the NEGATIVE
; polarity the `xor` reaches `collectCondTree`, which refuses `xor X, const`, and
; the module declines — on BOTH binaries, and so does its hand-if-converted twin.
; Consistent, and left declining.
;
; THE CLEARANCE IS INHERITED, MECHANICALLY. The `diff` RUN lines below assert that
; this module's lowered GATE STREAM is IDENTICAL to
; control_predmux_accept_rail_leaf_boolalg_twin.ll — the same program written as
; plain `select`s, which the ORACLE ALREADY ACCEPTS. So the increment adds an
; ACCEPT, not a STREAM: the circuit is one the cleared 4.4 substrate was already
; emitting for the if-converted spelling, and `-O1` choosing `br` over `select` is
; the only difference (the axis this whole bead turns on).
;
; ⚠ THE COMPARISON IS THE GATE STREAM, NOT THE WHOLE FUNCTION BODY, and that is
; stated because the difference matters: the two modules' SSA names and their
; residual classical instructions differ. `grep -oE` over the emitted calls is what
; is asserted. A reader must not quote this as "byte-identical modules".
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %S/control_predmux_accept_rail_leaf_boolalg_twin.ll > %t.twin.ll
; RUN: grep -oE "call (void|i32|i1) @(cqrt|cq_template)_[a-z0-9_]*" %t.cqd0.ll > %t.a.gates
; RUN: grep -oE "call (void|i32|i1) @(cqrt|cq_template)_[a-z0-9_]*" %t.twin.ll > %t.b.gates
; RUN: diff %t.a.gates %t.b.gates
; RUN: %filecheck %s --check-prefix=TOFF < %t.cqd0.ll
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  br i1 %rail, label %arm, label %merge
arm:
  br label %merge
merge:
  %p  = phi i1  [ %c, %arm ], [ false, %entry ]
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %c6 = phi i32 [ 2, %arm ], [ 7, %entry ]
  %sel = select i1 %p, i32 %a4, i32 %b5
  %m1 = call i32 @cq_measure_si32(i32 %sel)
  %m2 = call i32 @cq_measure_si32(i32 %c6)
  %mb = call i1 @cq_measure_i1(i1 %rail)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}

; the rail is allocated and rotated, then read ONLY as a control:
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[R]], double 5.000000e-01)
; the BoolAlg node: the rail and the compare flag conjoined onto a fresh ancilla.
; CHECK:     call void @cqrt_toffoli(
; ⚠ EXACTLY TWO `cqrt_toffoli` — the conjunction node's forward mint and its
; self-inverse STRIP, which is what returns the ancilla to |0> before its free.
; The count is closed by a whole-file negative so it is "exactly 2" and not "at
; least 2"; an open-ended count misses an injected extra gate after the last
; positive match (Rule-13 round 1, P3-1). ⚠ It was written as COUNT-1 first, on
; the assumption that a node mints once — the strip is the half that assumption
; forgot, and the closed count is what caught it.
; TOFF-COUNT-2: call void @cqrt_toffoli(
; TOFF-NOT:     call void @cqrt_toffoli(
