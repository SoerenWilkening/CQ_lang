; control_inplace_ry_tree_cmp_and.ll — ACCEPT: a compare-leaf tree, `x == 1 && y == 1` (issue shape p5).
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
;   int x,y,t (rotated); if (x == 1 && y == 1) cq_theta(&t, .7);   Each compare leaf mints its own flag (`_hl`) and is stripped by its `_unc` and freed AFTER the node undo — the LIFO mirror.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.cqd0.ll

declare i32 @cq_measure_si32(i32)
declare i32 @cq_theta_si32(i32, double)

define i32 @example() {
  %1 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %2 = call i32 @cq_theta_si32(i32 0, double 1.000000e+00)
  %3 = call i32 @cq_theta_si32(i32 0, double 2.000000e-01)
  %4 = icmp eq i32 %1, 1
  %5 = icmp eq i32 %2, 1
  %6 = select i1 %4, i1 %5, i1 false
  br i1 %6, label %7, label %9

7:
  %8 = call i32 @cq_theta_si32(i32 %3, double 0x3FE6666666666666)
  br label %9

9:
  %10 = phi i32 [ %8, %7 ], [ %3, %0 ]
  %11 = call i32 @cq_measure_si32(i32 %1)
  %12 = call i32 @cq_measure_si32(i32 %2)
  %13 = shl nsw i32 %12, 1
  %14 = add nsw i32 %13, %11
  %15 = call i32 @cq_measure_si32(i32 %10)
  %16 = shl nsw i32 %15, 2
  %17 = add nsw i32 %14, %16
  ret i32 %17
}

; CHECK:      %[[CX:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[X:[a-zA-Z0-9_.]+]], i32 1)
; CHECK-NEXT: %[[CY:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[Y:[a-zA-Z0-9_.]+]], i32 1)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[CX]], i32 %[[CY]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[G]], i32 %[[T:[a-zA-Z0-9_.]+]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[CX]], i32 %[[CY]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[CY]], i32 %[[Y]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CY]])
; CHECK-NEXT: call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[CX]], i32 %[[X]], i32 1)
; CHECK-NEXT: call void @cqrt_free(i32 %[[CX]])
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
; FCNT-COUNT-3: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT: call void @cqrt_x(
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
