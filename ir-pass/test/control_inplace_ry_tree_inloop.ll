; control_inplace_ry_tree_inloop.ll — ACCEPT: a tree region ROLLED inside a classically-bounded loop, with a leaf re-rotated every trip.
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
;   for (i < n) { cq_theta(&b, .1); if (a & b) cq_theta(&t, .7); }   The network is minted, used, stripped and freed INSIDE each trip (an iteration-local ancilla), after that trip's Ry on `b`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=XCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CRCNT < %t.cqd0.ll

declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)

define i32 @example(i32 %0, ptr %1) {
  %3 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %4 = call i1 @cq_theta_i1(i1 false, double 1.000000e+00)
  %5 = call i32 @cq_theta_si32(i32 0, double 2.000000e-01)
  %6 = icmp sgt i32 %0, 0
  br i1 %6, label %18, label %7

7:
  %8 = phi i1 [ %4, %2 ], [ %22, %26 ]
  %9 = phi i32 [ %5, %2 ], [ %27, %26 ]
  %10 = call i1 @cq_measure_i1(i1 %3)
  %11 = zext i1 %10 to i32
  %12 = call i1 @cq_measure_i1(i1 %8)
  %13 = select i1 %12, i32 2, i32 0
  %14 = or disjoint i32 %13, %11
  %15 = call i32 @cq_measure_si32(i32 %9)
  %16 = shl nsw i32 %15, 2
  %17 = or disjoint i32 %14, %16
  ret i32 %17

18:
  %19 = phi i32 [ %28, %26 ], [ 0, %2 ]
  %20 = phi i32 [ %27, %26 ], [ %5, %2 ]
  %21 = phi i1 [ %22, %26 ], [ %4, %2 ]
  %22 = call i1 @cq_theta_i1(i1 %21, double 1.000000e-01)
  %23 = and i1 %3, %22
  br i1 %23, label %24, label %26

24:
  %25 = call i32 @cq_theta_si32(i32 %20, double 0x3FE6666666666666)
  br label %26

26:
  %27 = phi i32 [ %25, %24 ], [ %20, %18 ]
  %28 = add nuw nsw i32 %19, 1
  %29 = icmp eq i32 %28, %0
  br i1 %29, label %7, label %18
}

; CHECK:      call void @cqrt_ry_i1(i32 %[[B:[a-zA-Z0-9_.]+]], double 1.000000e-01)
; CHECK-NEXT: %[[G:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A:[a-zA-Z0-9_.]+]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[G]], i32 %[[T:[a-zA-Z0-9_.]+]], double 0x3FE6666666666666)
; CHECK-NEXT: call void @cqrt_toffoli(i32 %[[A]], i32 %[[B]], i32 %[[G]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[G]])
; CHECK-NEXT: {{.*}} = add nuw nsw i32
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
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; XCNT-NOT: call void @cqrt_x(
; CRCNT-COUNT-1: call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
; CRCNT-NOT:     call void @cqrt_ry_{{[a-z0-9]+}}_controlled(
