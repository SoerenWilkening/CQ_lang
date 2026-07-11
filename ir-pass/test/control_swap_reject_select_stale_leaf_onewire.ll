; control_swap_reject_select_stale_leaf_onewire.ll — DECLINE (3c6m.12 L4
; probe): a chained theta stales ONE leaf's wire while the OTHER leaf sits on
; an untouched second register. The per-leaf gate-2c walk must decline on the
; UNION of leaf provenances — a walk seeded from only the first (or only the
; last) leaf would accept and mint a post-Ry flag for the staled leaf
; (verify-clean wrong unitary). Here %c2 reads %q1's wire, which gains
; a chained Ry(0.7) before the select; %c1's %q0 wire is clean.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @example(i32 %u0, i32 %u1, i32 %x) {
entry:
  %q0  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q1  = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %t   = add i32 %q0, 1
  %c1  = icmp sgt i32 %q0, 5                                       ; clean wire
  %c2  = icmp slt i32 %q1, 100                                     ; wire staled below
  %c   = or i1 %c1, %c2
  %q2  = call i32 @cq_theta_si32(i32 %q1, double 7.000000e-01)     ; chained theta on q1 ONLY
  %sel = select i1 %c, i32 %t, i32 %x
  %m1  = call i32 @cq_measure_si32(i32 %sel)
  %m2  = call i32 @cq_measure_si32(i32 %q2)
  ret void
}
