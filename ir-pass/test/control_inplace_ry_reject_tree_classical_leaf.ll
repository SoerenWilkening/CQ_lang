; control_inplace_ry_reject_tree_classical_leaf.ll — DECLINE: a tree mixing a MEASURED (classical) value and a rail.
;
; bd test_C_libtooling-dm7f.52 — the in-place controlled Ry / controlled state
; prep under a COMPOUND i1 condition. Before dm7f.52 every such region declined
; `control flow under quantum control` at `classifyArms`' first gate while the
; `cq_phi` twin lowered (docs/CQ_FINDINGS.md F2). The mechanism: the condition
; tree is minted into ONE flag by `CondTreeEmit::emitCondNetwork` (the branch
; phase's network), `cqrt_ry_<W>_controlled(flag, h, θ)` fires, and
; `stripCondNetwork` returns every ancilla to |0> (LIFO) before its free. The
; target must lie off every leaf wire (`classifyArms` R4 over the leaf-union
; `Prov`), which is what makes the strip exact. IR transcribed from clang -O1.
;
;   bool m = cq_measure(a); if (m & b) cq_theta(&t, .7);
;
; The classical leaf is refused exactly as the branch phase refuses it
; (`condtree_classical_leaf_reject_phase.ll`; it is not a compare, so the
; grammar has no leaf kind for it). Physically valid (the 4.4 select lowers
; it through a `CondLiteral` node): an OVER-DECLINE, filed as a follow-up of
; bd dm7f.52 — flip this file when the literal route reaches both consumers.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_measure_i1(i1)
declare i1 @cq_theta_i1(i1, double)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = call i1 @cq_measure_i1(i1 %1)
  %4 = and i1 %2, %3
  br i1 %4, label %5, label %7

5:
  %6 = call i1 @cq_theta_i1(i1 false, double 0x3FE6666666666666)
  br label %7

7:
  %8 = phi i1 [ %6, %5 ], [ false, %0 ]
  %9 = zext i1 %3 to i32
  %10 = call i1 @cq_measure_i1(i1 %2)
  %11 = select i1 %10, i32 2, i32 0
  %12 = or disjoint i32 %11, %9
  %13 = call i1 @cq_measure_i1(i1 %8)
  %14 = select i1 %13, i32 4, i32 0
  %15 = or disjoint i32 %12, %14
  ret i32 %15
}

; CHECK: cq controlled lowering: control flow under quantum control
