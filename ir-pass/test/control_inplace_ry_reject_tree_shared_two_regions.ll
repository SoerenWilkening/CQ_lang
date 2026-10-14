; control_inplace_ry_reject_tree_shared_two_regions.ll — DECLINE: two Ry regions sharing ONE CSE'd tree root.
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
;   if (a & b) cq_theta(&t, .7); if (a & b) cq_theta(&u, .5);   (-O1 CSEs the `and`)
;
; The second branch is a user of the first region's root, and the tree
; consumers' shape fence refuses any out-of-tree user. An OVER-DECLINE (each
; region could mint its own network from the leaves); the `cq_phi` twin
; lowers only because -O1 fuses its two arms into one. Filed as a follow-up
; of bd dm7f.52 (dm7f.53 neighbourhood) — flip this file when built.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare i1 @cq_measure_i1(i1)
declare i1 @cq_theta_i1(i1, double)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %4 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %5 = and i1 %1, %2
  br i1 %5, label %6, label %8

6:
  %7 = call i1 @cq_theta_i1(i1 %3, double 0x3FE6666666666666)
  br label %8

8:
  %9 = phi i1 [ %7, %6 ], [ %3, %0 ]
  br i1 %5, label %10, label %12

10:
  %11 = call i1 @cq_theta_i1(i1 %4, double 5.000000e-01)
  br label %12

12:
  %13 = phi i1 [ %11, %10 ], [ %4, %8 ]
  %14 = call i1 @cq_measure_i1(i1 %1)
  %15 = zext i1 %14 to i32
  %16 = call i1 @cq_measure_i1(i1 %2)
  %17 = select i1 %16, i32 2, i32 0
  %18 = or disjoint i32 %17, %15
  %19 = call i1 @cq_measure_i1(i1 %9)
  %20 = select i1 %19, i32 4, i32 0
  %21 = or disjoint i32 %18, %20
  %22 = call i1 @cq_measure_i1(i1 %13)
  %23 = select i1 %22, i32 8, i32 0
  %24 = or disjoint i32 %21, %23
  ret i32 %24
}

; CHECK: cq controlled lowering: condition used outside the branch under quantum control
