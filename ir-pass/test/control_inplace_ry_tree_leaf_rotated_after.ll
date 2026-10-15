; control_inplace_ry_tree_leaf_rotated_after.ll — ACCEPT: a condition LEAF rotated AFTER the region (adversarial probe: the strip must precede the later Ry).
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
;   if (a & b) cq_theta(&t, .7); cq_theta(&a, .3);   The leaf's later Ry is ProvenPostRegion; the network is stripped and freed BEFORE it, so the strip reads the basis the mint read.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.cqd0.ll

declare i1 @cq_measure_i1(i1)
declare i1 @cq_theta_i1(i1, double)

define i32 @example() {
  %1 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %2 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %3 = call i1 @cq_theta_i1(i1 false, double 2.000000e-01)
  %4 = and i1 %1, %2
  br i1 %4, label %5, label %7

5:
  %6 = call i1 @cq_theta_i1(i1 %3, double 0x3FE6666666666666)
  br label %7

7:
  %8 = phi i1 [ %6, %5 ], [ %3, %0 ]
  %9 = call i1 @cq_theta_i1(i1 %1, double 3.000000e-01)
  %10 = call i1 @cq_measure_i1(i1 %9)
  %11 = zext i1 %10 to i32
  %12 = call i1 @cq_measure_i1(i1 %2)
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = call i1 @cq_measure_i1(i1 %8)
  %16 = select i1 %15, i32 4, i32 0
  %17 = or disjoint i32 %14, %16
  ret i32 %17
}

; CHECK:      call void @cqrt_ry_i1(i32 %{{[a-zA-Z0-9_.]+}}, double 2.000000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[B:[a-zA-Z0-9_.]+]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1_controlled(i32 %[[G]], i32 %[[T:[a-zA-Z0-9_.]+]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i1(i32 %[[A]], double 3.000000e-01)
;
; The negatives are whole-file and pure (a positive directive in a prefix
; windows every negative after it): NOROUTE pins no route/copy/inverse gate
; and that every condition node and leaf is gone; FCNT/XCNT/CRCNT count.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: call i1 @cq_theta
; NOROUTE-NOT: select i1 {{.*}}, i1 
; NOROUTE-NOT: = and i1
; NOROUTE-NOT: = xor i1
; NOROUTE-NOT: = or i1
; NOROUTE-NOT: = icmp
; NOROUTE-NOT: = phi
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT: call void @cqrt_x(
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
