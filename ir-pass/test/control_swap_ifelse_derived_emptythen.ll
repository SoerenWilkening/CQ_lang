; control_swap_ifelse_derived_emptythen.ll — ACCEPT: derived base, gate-free
; TRUE arm, gates on the FALSE arm (¬flag bracket PRESENT).
;
; The mirror of control_swap_ifelse_derived_emptyelse.ll: the THEN arm is empty
; (contributes %qd unchanged) and the ELSE arm carries the gate, so the single
; surviving stream fires on ¬flag — the route cswaps MUST be wrapped in the
; self-inverse `cqrt_x(flag)` bracket (the emptyelse fixture pins the bracket's
; ABSENCE; this one pins its PRESENCE — the §8 completeness review noted only
; one direction was covered, 2026-06-10).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT2 < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %then, label %else
then:
  br label %merge
else:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; one controlled gate, ¬flag-bracketed (the gates live on the FALSE arm). Since
; drbq Inc 2a the bracket wraps the GATE RUN, so there is ONE pair, not the two
; the route needed (one around each cswap).
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_rz_i32(i32 %[[Q]], double 9.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %[[Q]], double %b)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])
; CHECK-NOT: call void @cqrt_free
; CHECK-NOT: cqrt_copy
; CHECK-NOT: phi i32

; Exact free count — one (the flag; no work rail since drbq Inc 2a), no second.
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(
; Exactly TWO cqrt_x — the single bracket pair around the arm's gate run (four
; before drbq Inc 2a: one pair per routed cswap).
; CNT2-COUNT-2: call void @cqrt_x(
; CNT2-NOT:     call void @cqrt_x(
; No swap route survives: no |0> work rail, no CSWAP — window is `define` -> EOF.
; NOROUTE:     define
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call i32 @cqrt_alloc_i32(i32 0)
