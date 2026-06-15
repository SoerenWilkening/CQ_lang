; control_swap_reject_nested_cond_datause_outer.ll — DECLINE probe (ziov.3): a
; depth-2 phase nest whose OUTER condition is ALSO read as DATA.
;
; `int f=(q>5); if (q>5) { q=rz(q,b); if (q<9) { q=rz(q,a); } }; measure(q)+f` —
; clang -O1 CSEs `f=(q>5)` and the outer `if (q>5)` to ONE `icmp sgt q, 5` with a
; `br` (control) AND a `zext` (data, escaped via ret). The flat 4.1 phase path
; SHARES one physical flag for this shape (ziov WI-1, condDataUseDisposition →
; ShareCondFlag). NestedRouteEmit does NOT yet share, so left unchecked it
; DUPLICATE-MINTS: `flattenRegionTree`'s use_empty() guard correctly keeps the
; live data compare, then `lowerOps` mints a SECOND `cq_template_icmp_sgt_i32_hl`
; — one flag routed/stripped/freed (control), one LEAKED entangled-with-q flag
; (the data compare). opt -verify clean, a real qubit leak reachable from -O1.
;
; ziov.3 declines LOUDLY in detection (recoverRegionTree), BEFORE NestedRouteEmit
; mutates — applying the SAME disposition predicate the flat path uses, keyed on
; the outer route block (Pred). The owned (escaped) lineage is the flat path's
; ShareOk accept; the nested path declines it ("condition used outside the
; branch") because nested flag-SHARING is a later WI. Over-declining is safe
; (Prime Directive).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition used outside the branch under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  %d  = zext i1 %c1 to i32          ; DATA use of the OUTER condition
  br i1 %c1, label %mid, label %merge
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %h, %arm ], [ %g, %mid ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  %r  = add i32 %m, %d              ; keep %d live — escapes via ret
  ret i32 %r
}
