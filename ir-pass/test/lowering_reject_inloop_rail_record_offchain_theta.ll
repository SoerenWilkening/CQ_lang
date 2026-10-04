; lowering_reject_inloop_rail_record_offchain_theta.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, finding F-3). A CONFIRMED silent
; miscompile, and F-1's EXACT TWIN one hop out.
;
;     int q = 0; cq_theta(&q, .5);
;     for (i<2) { if (q==5) q=cq_phi(q,PI); cq_theta(&q,-.5); cq_theta(&q,.5); }
;     int a = q; cq_theta(&a, 0.125);  /* arg-0 IS a chain member — the RESULT is not */
;     int b = a; cq_theta(&b, 0.25);  /* a rail gate AFTER the record `a`            */
;     return cq_measure(a) + cq_measure(b);
;
; THE HOLE. Round 2 (F-1) widened `collectRailGates`'s GATE set from the peeled
; chain to the whole RAIL — `%a` and `%b` are both gates here, and both were
; collected. What it did NOT widen is the RECORD set: `staleRailRecordRead`
; enumerated the chain `Members` and asked "is any read of THIS stale?", so the
; only records ever examined were chain values. `%a` is one hop off the chain, so
; nothing ever asked about it, and the module lowered to
;
;     cqrt_ry_i32(%h, 0.125); cqrt_ry_i32(%h, 0.25); measure(%h); measure(%h)
;
; — `%a` names the PRE-`%b` register and is measured AFTER `%b`. `opt` exit 0,
; `opt -verify` clean, STRICT stage-2b free-pairing clean: the gate stream is
; perfectly self-consistent and only the state is wrong. Ry is ALWAYS lowered in
; place (`lowerRotations` RAUWs the result to the arg-0 handle), so there is no
; out-of-place escape hatch here.
;
; THE FIX is `collectRailGates`'s `OnRailOut`: the record loop runs over the rail's
; own closure, not over the chain. The SKIP set stays the chain's — see
; lowering_reject_inloop_rail_frozen_gate_first.ll for the fixture that pins why
; those two sets must not be unified.
;
; THIS IS THE `clang -O1` FORM of the C above, hand-named but structurally
; verbatim: the rotated 2-trip do-while, the `icmp eq %i, 0` back edge, and the
; value-propagated `cq_phi(5, PI)` on the equality arm (Rule 9's canonicalization).
;
; THE ROUND-1 TWIN IS lowering_reject_loop_rail_record_offchain_theta.ll — the
; SAME C program with the in-body tainted `if` removed, so it is claimed by
; `tryCaseA`'s `railRoot` fixpoint instead of by round 2's `collectRailGates`.
; Both must decline with this message; the pair is the Rule-14 pin that the two
; forward-extension spellings have not diverged.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %latch
  %a = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)   ; OFF-CHAIN record
  %b = call i32 @cq_theta_si32(i32 %a, double 2.500000e-01)    ; a rail gate AFTER it
  %m0 = call i32 @cq_measure_si32(i32 %a)                      ; the STALE read
  %m1 = call i32 @cq_measure_si32(i32 %b)
  %s = add nsw i32 %m1, %m0
  ret i32 %s

loop:                                             ; preds = %entry, %latch
  %q = phi i32 [ %q0, %entry ], [ %qn, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %arm, label %latch

arm:                                              ; preds = %loop
  call void @cq_phi(double 0x400921FB54442D18)
  br label %latch

latch:                                            ; preds = %arm, %loop
  %qh = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %qn = call i32 @cq_theta_si32(i32 %qh, double 5.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i, 0
  br i1 %done, label %loop, label %exit
}
