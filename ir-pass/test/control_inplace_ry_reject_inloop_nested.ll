; control_inplace_ry_reject_inloop_nested.ll — DECLINE (PRD §13.2 row L-f): a
; DEPTH-2 tainted-condition NEST whose Ry arm sits in the inner region, inside a
; loop.
;
; The nest never reaches `classifyArms` at all: `ControlDetect` recovers it as
; `RegionShape::Nested` and dispatches to `recoverRegionTree`, which declines on
; `regionEntryInLoop` with its own string. The 4.3 depth-2 nest was cleared for
; homogeneous PHASE arms and keeps its loop decline; a controlled Ry inside one is
; two unshipped capabilities composed, and Increment 3 scoped neither.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}nested control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rout, %mo ]
  %i = phi i32 [ 0, %entry ], [ %inext, %mo ]
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %mo
mid:
  %c2 = icmp sgt i32 %q, 7
  br i1 %c2, label %arm, label %mi
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %mi
mi:
  %ri = phi i32 [ %rt, %arm ], [ %r, %mid ]
  br label %mo
mo:
  %rout = phi i32 [ %ri, %mi ], [ %r, %loop ]
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rout)
  ret i32 %m
}
