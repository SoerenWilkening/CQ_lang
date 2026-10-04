; lowering_reject_inloop_rail_record_onepath_theta.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 2, finding F-1 — the ∃-PATH edge).
;
;     for (i<2) { if (q==5) q = cq_phi(q,PI); cq_theta(&q,-.5); cq_theta(&q,.5); }
;     int mark = q;
;     if (n & 1) { cq_theta(&q, 0.125); }   /* the gate fires on ONE path; result dropped */
;     return cq_measure(mark);
;
; Same defect as the sibling lowering_reject_inloop_rail_record_postloop_theta.ll
; with the off-chain Ry moved onto a CLASSICAL side path and its result thrown
; away. Two things this pins that the straight-line twin cannot:
;
;   * the fence is an ∃-PATH test, not a dominance test. `%post` neither dominates
;     nor post-dominates the read; on the even path the record is live and on the
;     odd path it is stale, and ONE bad path is a wrong unitary (`opt` cannot know
;     which way `%n` goes). Over-declining the even path is the safe half of the
;     Prime Directive; accepting the odd one is the unforgivable half.
;   * the gate is USE-EMPTY. A collection keyed on "is this value read back onto
;     the rail" would miss it entirely — what makes it a gate is that Ry is lowered
;     IN PLACE on `%h`, whatever happens to the SSA result.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %b, i32 %n) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qn, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %odd = and i32 %n, 1
  %even = icmp eq i32 %odd, 0
  br i1 %even, label %read, label %gate
gate:
  %post = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)  ; fires on ONE path
  br label %read
read:
  %m0 = call i32 @cq_measure_si32(i32 %qn)                       ; the STALE record
  ret i32 %m0
}
