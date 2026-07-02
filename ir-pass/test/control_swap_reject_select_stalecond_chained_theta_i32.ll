; control_swap_reject_select_stalecond_chained_theta_i32.ll — DECLINE: the
; INTEGER twin of control_swap_reject_select_stalecond_chained_theta.ll (kjd1
; clearance probe p12). The stale-condition hole predates the fp un-staging —
; 4.4 shipped the select classifier without the wire guard both sibling
; classifiers carry — so the fix covers BOTH type families; this fixture pins
; the integer side. A chained cq_theta between the icmp and the select would
; mint a post-Ry flag at the select (verify-clean wrong unitary).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define void @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t   = add i32 %q, 1                                             ; derived data operand
  %c   = icmp sgt i32 %q, 5                                        ; SOURCE record: pre-Ry(0.7)
  %q2  = call i32 @cq_theta_si32(i32 %q, double 7.000000e-01)      ; chained theta on q's wire
  %sel = select i1 %c, i32 %t, i32 %x
  %m1  = call i32 @cq_measure_si32(i32 %sel)
  %m2  = call i32 @cq_measure_si32(i32 %q2)
  ret void
}
