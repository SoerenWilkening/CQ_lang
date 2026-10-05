; lowering_reject_inloop_rail_record_postloop_theta.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 2, finding F-1). A CONFIRMED silent
; miscompile in the round-1 fence itself.
;
;     int q = 0; cq_theta(&q, .5);
;     for (i<2) { if (q==5) cq_phi(PI); cq_theta(&q,-.5); cq_theta(&q,.5); }
;     int mark = q;                 /* the record: the loop's EXIT state */
;     cq_theta(&q, 0.125);       /* an OFF-CHAIN in-place Ry on the same rail */
;     return cq_measure(mark) + cq_measure(q);
;
; THE HOLE. `collectRailGates` built the gate set from CHAIN MEMBERS only — the
; peeled root→PreV→phi→LatV chain's own `cq_theta` and in-place add/xor. A
; `cq_theta` whose arg-0 IS a member but whose RESULT is off the chain (the
; canonical case: a rotation applied to the loop's exit value) was therefore not a
; gate, `railGateBetween` returned false, and the rail collapsed. Emitted:
;
;     cqrt_ry_i32(%h, 0.125); measure(%h); measure(%h)
;
; `mark` names the PRE-Ry record and is measured AFTER it — a different unitary at
; `opt` exit 0, `opt -verify` clean and STRICT stage-2b free-pairing clean. Ry is
; ALWAYS lowered in place (`lowerRotations` RAUWs the result to the handle), so
; unlike an out-of-place value op there is no escape hatch.
;
; Reachable from `clang -O1` C: this file is the -O1 form of BOTH the record-after
; spelling above and the record-INSIDE spelling `for (…) { …; mark = q; }
; cq_theta(&q,.125);` — `-O1` sinks the latter's `mark` to the exit and the two
; produce the same IR modulo phi order, so one fixture pins both. The value-op
; twin of the same program (`mark * 7` in place of `cq_measure(mark)`) declines
; loudly at `declineStaleRecordOps`; only the measure/`ret` reads reach here, which
; is why this fence has to own them (Rule 14 — one predicate, not a neighbour's
; coverage).
;
; RETIRED INTO THIS FILE (bd jttf, 2026-10-05):
; lowering_reject_inloop_rail_record_offchain_rz.ll (round 3, F-3), whose RECORD
; was an off-chain name reached through a DIAGONAL hop, `int mark = cq_phi(q,
; 1.0)` (pre-3qlq register form). The 3qlq migration deleted the hop, which made
; the record the chain member itself with the gate behind it: this file's shape,
; with the same message. A register-free phase creates no SSA name, so the
; diagonal-hop record has no spelling; the non-diagonal hop is
; lowering_reject_inloop_rail_record_offchain_theta.ll.
;
; The GREEN twin is control_swap_inloop_postloop_railop.ll (the same program with
; an out-of-place `q + 9` in place of the Ry — that one is CORRECT today, because
; the M-C decision lowers it into a FRESH rail and the register never moves).
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
  %post = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)  ; OFF-CHAIN, in place
  %m0 = call i32 @cq_measure_si32(i32 %qn)                       ; the STALE record
  %m1 = call i32 @cq_measure_si32(i32 %post)
  %s = add i32 %m0, %m1
  ret i32 %s
}
