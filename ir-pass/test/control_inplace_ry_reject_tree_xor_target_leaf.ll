; control_inplace_ry_reject_tree_xor_target_leaf.ll — DECLINE: `if (a ^ t) cq_theta(&a, .7)` — an `xor i1` tree whose leaf is the target.
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
;   bool a,t (rotated); if (a ^ t) cq_theta(&a, .7);
;
; The dm7f.51 design-review hazard: the dm7f.4 kept-flag clause used to
; `cast<CmpInst>` the condition (UB in Release for a tree root). It is now a
; `dyn_cast` with an explicit `!CondIsTree` conjunct (K4), so a tree on the
; rotated register keeps R4's loud refusal and is never stripped dirty.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_measure_i1(i1)
declare i1 @cq_theta_i1(i1, double)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = xor i1 %1, %2
  br i1 %3, label %4, label %6

4:
  %5 = call i1 @cq_theta_i1(i1 %1, double 0x3FE6666666666666)
  br label %6

6:
  %7 = phi i1 [ %5, %4 ], [ %1, %0 ]
  %8 = call i1 @cq_measure_i1(i1 %7)
  %9 = zext i1 %8 to i32
  %10 = call i1 @cq_measure_i1(i1 %2)
  %11 = select i1 %10, i32 2, i32 0
  %12 = or disjoint i32 %11, %9
  ret i32 %12
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
