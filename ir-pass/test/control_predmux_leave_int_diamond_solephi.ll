; control_predmux_leave_int_diamond_solephi.ll — DECLINE (bd vyqi, W5
; CONTAINMENT pin): the INTEGER twin of the W5-claimed fp diamond — a sole-phi
; both-arms-write i32 if/else whose arms bottom at the very register the
; condition reads. The W5 witness is deliberately FP-ONLY, and what THIS pin
; proves is precisely that W5 does not claim a DECLINING int sole-phi diamond:
; this condition-reading same-base form keeps its ArmClassify
; provenance-overlap decline exactly as before the widening (if it ever
; compiles, the W5 witness has leaked past fp). The other half of int
; containment — an ACCEPTED independent-base int sole-phi if/else keeping its
; cswap method-B routed stream rather than being stolen into a select-copy —
; is pinned by the pre-existing control_swap_value_ifelse.ll, whose CHECK-NEXT
; cswap stream turns red on any such leak (Rule-13 adjudication note,
; 2026-07-24). Together the two pins cover both int directions.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control
; CHECK-NOT: cqrt_copy
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp slt i32 %q, 5
  br i1 %c, label %lo, label %hi
lo:
  %a = add i32 %q, 7
  br label %merge
hi:
  %b = mul i32 %q, 3
  br label %merge
merge:
  %zv = phi i32 [ %a, %lo ], [ %b, %hi ]
  %m = call i32 @cq_measure_si32(i32 %zv)
  ret i32 %m
}
