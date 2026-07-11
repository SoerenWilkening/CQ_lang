; control_swap_reject_select_stale_leaf_crossblock.ll — DECLINE (3c6m.12
; Rule-13 clearance MINOR, harness-honesty lens): the CROSS-BLOCK staling
; theta that ONLY the leaf-UNION `findNonDiagonalWireGate` seeding can catch.
; The chained theta on %q1's wire sits in a DIFFERENT block from the leaf
; compares, outside the positional prong-(c) same-block `[leaf, Sel)` window —
; so this fixture regression-pins the union-seeding walk itself: the sibling
; stale_leaf fixtures (same-block) go green under a hypothetical revert of the
; leaf-UNION seeding to single-leaf seeding, but THIS one does not (%q1 is the
; SECOND leaf's wire; a first-leaf-only seed never visits it).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @example(i32 %u0, i32 %u1, i32 %x) {
entry:
  %q0  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1  = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %t   = add i32 %q0, 1
  %c1  = icmp sgt i32 %q0, 5                                     ; clean wire
  %c2  = icmp slt i32 %q1, 100                                   ; wire staled below
  %c   = or i1 %c1, %c2
  br label %next
next:
  %q2  = call i32 @cq_theta_si32(i32 %q1, double 7.000000e-01)   ; cross-block chained theta
  %sel = select i1 %c, i32 %t, i32 %x
  %m1  = call i32 @cq_measure_si32(i32 %sel)
  %m2  = call i32 @cq_measure_si32(i32 %q2)
  ret void
}
