; control_swap_ifelse_derived_stalecond.ll — ACCEPT: derived base, STALE condition operand.
;
; Same derived-base if/else as control_swap_ifelse_derived.ll, but the condition
; reads the THETA result %q while the arms rotate the pre-region-derived %qd.
; This is still correct to accept: %q and %qd denote the SAME physical qubit
; (an Rz is in-place — rotation lowering RAUWs both to one i32 handle), and Rz
; is diagonal, so basis(%q) == basis(%qd) and the flag minted from icmp(%q)
; equals the flag icmp(%qd) would mint. The strip icmp_inv likewise lands on the
; same handle. The lowered stream is byte-identical to the live-condition
; variant. (clang -O1 can produce this when it CSEs/reorders the compare against
; an intervening cq_phi.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5                                    ; STALE operand: the theta result
  br i1 %c, label %then, label %else
then:
  call void @cq_phi(double %a)
  br label %merge
else:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; Identical stream to the live-condition variant — one handle underneath.
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; Both arms controlled IN PLACE on the ONE handle (drbq Inc 2a). That the THEN
; and ELSE gates name the SAME %[[Q]] as the flag mint IS the point of this file:
; %q and %qd are one physical qubit, so the stale-condition spelling collapses to
; the live-condition one.
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %a)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag; the two work rails went with the route at
; drbq Inc 2a), no second anywhere.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; No swap route survives: no |0> work rail, no CSWAP — window is `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
