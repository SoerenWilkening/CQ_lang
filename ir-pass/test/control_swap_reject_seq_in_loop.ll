; control_swap_reject_seq_in_loop.ll — DECLINE (bd hcrg decline partition): a
; sequential PAIR whose regions sit inside a loop body.
;
; Admitting sequential regions (bd hcrg) moved this shape onto a NEW code path
; and that is the whole reason this fixture exists. Before hcrg, the first
; region recovered as `RegionShape::Nested` (its merge hosted a tainted branch)
; and was declined by the `regionEntryInLoop` guard on the NESTED dispatch arm.
; It now recovers as a flat `Diamond` and is declined by the `regionEntryInLoop`
; guard on the DIAMOND/IFELSE arm instead — a different call site, reached for
; the first time by this shape. The d8jl loop hazard is unchanged and undiluted:
; `RegionFlatten` would erase the merge, i.e. the loop's latch/backedge source,
; leaving the header phi dangling (a BROKEN MODULE, not a decline).
;
; Without this fixture the hcrg change silently relies on a guard nothing
; exercises through the sequential path.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  br label %head
head:
  %i = phi i32 [ 0, %entry ], [ %inext, %m2 ]
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %arm1, label %m1
arm1:
  %g1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %m1
m1:
  %p1 = phi i32 [ %g1, %arm1 ], [ %q, %head ]
  %c2 = icmp sgt i32 %p1, 3
  br i1 %c2, label %arm2, label %m2
arm2:
  %g2 = call i32 @cq_phi_si32(i32 %p1, double %b)
  br label %m2
m2:
  %p2 = phi i32 [ %g2, %arm2 ], [ %p1, %m1 ]
  %mm = call i32 @cq_measure_si32(i32 %p2)
  %inext = add i32 %i, 1
  %done = icmp slt i32 %inext, 4
  br i1 %done, label %head, label %exit
exit:
  ret i32 %mm
}

; CHECK: error{{.*}}cq controlled lowering: control flow inside a loop body under quantum control
