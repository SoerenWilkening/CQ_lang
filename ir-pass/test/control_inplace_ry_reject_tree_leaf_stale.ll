; control_inplace_ry_reject_tree_leaf_stale.ll — DECLINE: a leaf's register is rotated BETWEEN the leaf compare and the branch.
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
;   bool c = (x == 1) & (y == 1); cq_theta(&y, .4); if (c) cq_theta(&t, .7);
;
; Minting at the branch would read `y` after its Ry, not the basis the source
; compare read. `condWireDisposition` over the leaf-union `Prov` refuses it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %3 = icmp eq i32 %1, 1
  %4 = icmp eq i32 %2, 1
  %5 = and i1 %3, %4
  %6 = call i32 @cq_theta_si32(i32 %2, double 4.000000e-01)
  br i1 %5, label %7, label %9

7:
  %8 = call i1 @cq_theta_i1(i1 false, double 0x3FE6666666666666)
  br label %9

9:
  %10 = phi i1 [ %8, %7 ], [ false, %0 ]
  %11 = call i32 @cq_measure_si32(i32 %1)
  %12 = call i32 @cq_measure_si32(i32 %6)
  %13 = shl nsw i32 %12, 1
  %14 = add nsw i32 %13, %11
  %15 = call i1 @cq_measure_i1(i1 %10)
  %16 = select i1 %15, i32 4, i32 0
  %17 = add nsw i32 %14, %16
  ret i32 %17
}

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
