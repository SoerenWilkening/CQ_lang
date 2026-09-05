; control_swap_reject_nested_cond_datause_unlowerable_cast.ll — DECLINE probe
; (ziov.4, nested path): a depth-2 phase nest whose OUTER condition is ALSO read
; as DATA through an UNSUPPORTED-width cast.
;
; Same shape as control_swap_reject_nested_cond_datause_outer.ll, but the data
; use is `sext %c1 to i256` (narrowed back + escaped) instead of a plain `zext`.
; (Width re-pointed i128 -> i256 in the n0ui follow-up: i128 is now a Tier-1
; supported intermediate width, so the unsupported-width probe uses i256.)
; The nested path (`recoverRegionTree`) ALREADY declines a cond-data-use before
; `NestedRouteEmit` mutates, so it was never the mutate-then-decline victim the
; flat path was — but it shares `condDataUseDisposition`, so ziov.4 makes the
; OUTER unlowerable-cast cond-data-use report the precise "has no template"
; reason rather than the generic "condition used outside the branch". Pure
; detection decline (Rule 9); over-declining is always safe (Prime Directive).
;
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: condition data use has no template under quantum control
; NEW: cq controlled lowering: condition used outside the branch under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: condition used outside the branch under quantum control
; CHECK-NOT: no template for opcode 'sext i256'
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  %d  = sext i1 %c1 to i256         ; DATA use of the OUTER condition, i256
  %e  = trunc i256 %d to i32        ; narrow back so the lineage escapes at i32
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  %r  = add i32 %m, %e              ; keep %e live — escapes via ret
  ret i32 %r
}
