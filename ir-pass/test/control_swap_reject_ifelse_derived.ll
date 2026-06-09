; control_swap_reject_ifelse_derived.ll — DECLINE: if/else routing a DERIVED base.
;
; An if/else whose two arm spines both bottom at a PRE-REGION cq_phi
; (`%qd = cq_phi(%q, ...)` applied unconditionally BEFORE the branch) — a derived /
; pre-rotated routed handle, NOT a leaf quantum source. WI-3 routes only an
; un-derived handle, so this declines loudly ("control flow"). The
; derived-handle ROUTING generalization is deferred (over-decline is safe; Prime
; Directive).
;
; REGRESSION GUARD (§8 adversarial review 2026-06-09, reproduced as a real crash):
; before the arm-block-bounded phase-spine walk, the UNBOUNDED walk hopped past
; %qd to the theta %q, so both arms appeared to bottom at the same handle and the
; region was ACCEPTED — then the emitter collected the SHARED %qd once per arm and
; the §6.1 reverse-erase DOUBLE-FREED it (SIGSEGV, exit 139). A sibling shape where
; the shared pre-phi is ALSO the icmp operand (@prephi_is_cond) instead emitted a
; broken module (dangling `void <badref>` in the flag-strip, exit 134). The diamond
; analog was immune (it declined via Base != StraightThrough); this is the if/else
; generalization of that same boundary discipline. See
; [[swap-route-ifelse-derived-base-boundary]].
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

; Both arm spines bottom at the pre-region %qd (shared prefix) — the SIGSEGV shape.
define i32 @derived_routed(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)   ; UNCONDITIONAL pre-rotation
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %qd, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; The shared pre-region cq_phi is ALSO the icmp condition operand — the
; broken-module variant. Must DECLINE cleanly (no verifier abort, no `<badref>`).
define i32 @prephi_is_cond(i32 %u0, double %a, double %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %then, label %else
then:
  %qt = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
else:
  %qe = call i32 @cq_phi_si32(i32 %qd, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %then ], [ %qe, %else ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}control flow under quantum control
