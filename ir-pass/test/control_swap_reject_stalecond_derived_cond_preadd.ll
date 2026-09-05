; control_swap_reject_stalecond_derived_cond_preadd.ll — DECLINE: derived
; stale condition with the mediating add scheduled BEFORE the chained theta —
; the layout that pins ArmClassify's PROVENANCE-SEEDED wire walk (the
; test_C_libtooling-ee5 hardening) now that the pass-wide straight-line guard
; exists.
;
; `%d = add i32 %q, 1` precedes the chained `cq_theta(%q, %t2)`, so the
; straight-line stale-record guard (OpcodeLowering::declineStaleRecordOps,
; test_C_libtooling-uzb) correctly stays SILENT: the add's template fires
; pre-Ry at its own position — emission-exact for the add itself. The REGION
; is still not lowerable: the flag is minted at the BRANCH, after the chained
; Ry on the condition's provenance wire, and per MINT_AT_COMPARE.md §2 no
; flag-freeing compilation of a condition whose wire gains a non-diagonal
; gate is source-exact — ArmClassify seeds its wire walk from the condition's
; full tainted backward provenance (condProvenance reaches `%q` one pure hop
; behind the compare) and declines. Without this fixture, the sibling
; control_swap_reject_stalecond_derived_cond.ll (add scheduled AFTER the
; theta) would no longer observe the provenance seeding at all: there the
; straight-line guard fires first and opt exits at the first diagnostic.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %t2, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d = add i32 %q, 1                                  ; BEFORE the chained Ry
  %q2 = call i32 @cq_theta_si32(i32 %q, double %t2)   ; chained Ry on the wire
  %c = icmp sgt i32 %d, 5                             ; DERIVED condition
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
