; control_inplace_ry_inloop_seq.ll — ACCEPT: TWO SEQUENTIAL in-loop
; control-in-place Ry regions on ONE rotated register (bd
; test_C_libtooling-drbq Inc 3).
;
;     for (...) { if (q > 5) r = cq_theta(r, .9); if (q > 3) r = cq_theta(r, .7); }
;
; THIS IS THE M-β AUDIT ROW MADE EXECUTABLE. Region 2's `RoutedBase` IS region 1's
; merge φ, and M-β changes what that φ is RAUW'd to (the hoisted gate, not the
; base). `ControlRegion::RoutedBase` is a `WeakTrackingVH`, so it FOLLOWS the
; RAUW — and region 2's own arm theta's arg-0 followed the SAME RAUW, so the
; emitter's identity re-validation (`T->getArgOperand(0) != Base`) still matches.
; If either half stopped following, this module would decline `control flow` at
; emission with the diamond already half-built.
;
; It also pins the bd hcrg emission ORDER inside a loop: region 1's flatten erases
; the block region 2 calls `Pred`, so the precedence graph emits region 2 FIRST
; while the emitted stream stays in SOURCE order (each emitter inserts positionally
; into its own pred).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F1]], i32 %[[R:[a-zA-Z0-9_.]+]], double 9.0
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %[[H]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT: %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F2]], i32 %[[R]], double 0x3FE6666666666666
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F2]])
;
; NOROUTE-NOT: call void @cqrt_cswap
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %p2, %m2 ]
  %i = phi i32 [ 0, %entry ], [ %inext, %m2 ]
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %g1 = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %m1
m1:
  %p1 = phi i32 [ %g1, %arm1 ], [ %r, %loop ]
  %c2 = icmp sgt i32 %q, 3
  br i1 %c2, label %arm2, label %m2
arm2:
  %g2 = call i32 @cq_theta_si32(i32 %p1, double 7.000000e-01)
  br label %m2
m2:
  %p2    = phi i32 [ %g2, %arm2 ], [ %p1, %m1 ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
