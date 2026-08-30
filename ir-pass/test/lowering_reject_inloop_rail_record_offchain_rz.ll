; lowering_reject_inloop_rail_record_offchain_rz.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, finding F-3 — the record itself
; reached through a DIAGONAL hop). A CONFIRMED silent miscompile.
;
;     for (i<2) { if (q==5) q=cq_phi(q,PI); q=cq_theta(q,-.5); q=cq_theta(q,.5); }
;     int mark = cq_phi(q, 1.0);      /* the RECORD is off-chain, behind an Rz */
;     int r    = cq_theta(mark, .125);/* a rail GATE after that record         */
;     return cq_measure(mark) + cq_measure(r);
;
; WHY THIS IS A SEPARATE FIXTURE FROM ITS `..._offchain_theta` SIBLING, AND WHY
; IT IS THE ONE THAT RULES OUT THE CHEAP REPAIR. The tempting narrow fix for F-3
; is "also ask about the direct `cq_theta` USERS of a chain member" — which reaches
; `%a` in the sibling fixture and does NOT reach `%mark` here, because `%mark` is a
; `cq_phi` (Rz). Rz is DIAGONAL and is deliberately never a gate (bd memory
; `rz-diag-flag-strip-invariant`); but it IS lowered in place, so `%mark` is a
; genuine SSA name for this register, and the Ry behind it moves the register out
; from under that name. Measured at the round-2 HEAD: `opt` exit 0 and
;
;     cqrt_rz_i32(%h, 1.0); cqrt_ry_i32(%h, 0.125); measure(%h); measure(%h)
;
; So the record set has to be the rail's own FORWARD CLOSURE — the same closure the
; gate set already was, diagonal hops followed and not counted — which is exactly
; what `collectRailGates`' `OnRailOut` hands `staleRailRecordRead`.
;
; Note the mirror-image relationship to
; lowering_reject_inloop_rail_record_offchain_rz_theta.ll (round 2, F-1): there the
; RECORD is a chain member and the GATE sits behind the Rz; here the GATE is direct
; and the RECORD sits behind the Rz. One fixture per direction, because the two
; were fixed by two different edits a round apart.
;
; `clang -O1` form of the C above (rotated 2-trip do-while, `icmp eq %i, 0` back
; edge, value-propagated `cq_phi(5, PI)` on the equality arm — Rule 9).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %latch
  %mark = call i32 @cq_phi_si32(i32 %qn, double 1.000000e+00)   ; OFF-CHAIN record
  %r = call i32 @cq_theta_si32(i32 %mark, double 1.250000e-01)  ; a rail gate AFTER it
  %m0 = call i32 @cq_measure_si32(i32 %mark)                    ; the STALE read
  %m1 = call i32 @cq_measure_si32(i32 %r)
  %s = add nsw i32 %m1, %m0
  ret i32 %s

loop:                                             ; preds = %entry, %latch
  %q = phi i32 [ %q0, %entry ], [ %qn, %latch ]
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %c1 = icmp eq i32 %q, 5
  br i1 %c1, label %arm, label %latch

arm:                                              ; preds = %loop
  %g = call i32 @cq_phi_si32(i32 5, double 0x400921FB54442D18)
  br label %latch

latch:                                            ; preds = %arm, %loop
  %qm = phi i32 [ %g, %arm ], [ %q, %loop ]
  %qh = call i32 @cq_theta_si32(i32 %qm, double -5.000000e-01)
  %qn = call i32 @cq_theta_si32(i32 %qh, double 5.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i, 0
  br i1 %done, label %loop, label %exit
}
