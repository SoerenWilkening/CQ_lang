; control_inplace_ry_reject_tree_leaf_measured_before.ll — DECLINE: a compare leaf's register is MEASURED before the branch.
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
;   int mx = cq_measure(x); if (x == 1 && y == 1) cq_theta(&t, .7);
;
; The branch phase's rung (ii) for compare leaves (`condCmpMeasuredBeforeReadPoint`),
; CALLED by the Ry consumer: a flag minted from a collapsed register is refused.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %3 = call i32 @cq_measure_si32(i32 %1)
  %4 = icmp eq i32 %1, 1
  %5 = icmp eq i32 %2, 1
  %6 = select i1 %4, i1 %5, i1 false
  br i1 %6, label %7, label %9

7:
  %8 = call i1 @cq_theta_i1(i1 false, double 0x3FE6666666666666)
  br label %9

9:
  %10 = phi i1 [ %8, %7 ], [ false, %0 ]
  %11 = call i32 @cq_measure_si32(i32 %2)
  %12 = shl nsw i32 %11, 1
  %13 = add nsw i32 %12, %3
  %14 = call i1 @cq_measure_i1(i1 %10)
  %15 = select i1 %14, i32 4, i32 0
  %16 = add nsw i32 %13, %15
  ret i32 %16
}

; CHECK: cq controlled lowering: condition measured before the control route under quantum control
