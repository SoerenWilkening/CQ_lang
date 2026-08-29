; lowering_reject_inloop_rail_record_theta_chain.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 2, finding F-1 — the NON-TRANSITIVITY
; ARGUMENT, pinned).
;
;     int mark = q;
;     q = cq_theta(q, 0.125);    /* %p1 — a direct in-place Ry on a chain member */
;     q = cq_theta(q, 0.250);    /* %p2 — an Ry on %p1, which is on NO chain      */
;     return cq_measure(mark) + cq_measure(q);
;
; The forward rail extension is walked to a FIXPOINT, so both rotations are
; collected — but this fixture exists to pin the claim that the SECOND one is not
; needed, because the claim is what licenses stopping the walk at an out-of-place
; value op (see control_swap_inloop_postloop_railop.ll).
;
; THE ARGUMENT. Let `Def` be the member's definition, `t1 = cq_theta(Def,…)` and
; `t2 = cq_theta(t1,…)`. `Def` dominates `t1` (SSA: `t1` uses it) and `t1`
; dominates `t2`. Then EVERY CFG path from `Def` to `t2` crosses `t1`: a path
; avoiding `t1` could be prefixed by a SIMPLE entry→`Def` path — which cannot
; visit `t1`'s block, since `Def` dominates it and the path would have to repeat
; `Def`'s block — giving an entry→`t2` path avoiding `t1`, contradicting the
; dominance. So `t1` alone fires the fence at every position `t2` would, and the
; walk never has to reason about a gate two hops off the chain.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
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
  %g = call i32 @cq_phi_si32(i32 %q, double %b)
  br label %merge
merge:
  %qm = phi i32 [ %g, %mid ], [ %q, %loop ]
  %qn = call i32 @cq_theta_si32(i32 %qm, double -5.000000e-01)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %p1 = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)
  %p2 = call i32 @cq_theta_si32(i32 %p1, double 2.500000e-01)
  %m0 = call i32 @cq_measure_si32(i32 %qn)                       ; the STALE record
  %m1 = call i32 @cq_measure_si32(i32 %p2)
  %s = add i32 %m0, %m1
  ret i32 %s
}
