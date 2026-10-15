; control_inplace_ry_reject_tree_target_leaf.ll — DECLINE: the rotated register IS a leaf of its own condition tree.
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
;   bool a,b (rotated); if (a & b) cq_theta(&b, .7);
;
; The strip would recompute `a & b` from a `b` the gate just rotated, so the
; root ancilla would not return to |0> and its free would be a hidden
; measurement (R5). R4 over the leaf-union `Prov` refuses it (re-spelled as the
; deferred wire-gate message). bd dm7f.51 / dm7f.9 own the real lowering (a
; kept or CNOT-copied flag); until then it is loud. Retirement trigger: when
; dm7f.51 lowers this, flip to an accept with an analytic stream check.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_measure_i1(i1)
declare i1 @cq_theta_i1(i1, double)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = and i1 %1, %2
  br i1 %3, label %4, label %6

4:
  %5 = call i1 @cq_theta_i1(i1 %2, double 0x3FE6666666666666)
  br label %6

6:
  %7 = phi i1 [ %5, %4 ], [ %2, %0 ]
  %8 = call i1 @cq_measure_i1(i1 %1)
  %9 = zext i1 %8 to i32
  %10 = call i1 @cq_measure_i1(i1 %7)
  %11 = select i1 %10, i32 2, i32 0
  %12 = or disjoint i32 %11, %9
  ret i32 %12
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
