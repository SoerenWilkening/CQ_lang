; lowering_reject_inloop_rail_record_offchain_rz.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, finding F-3 — the record itself
; reached through a DIAGONAL hop). A CONFIRMED silent miscompile.
;
;     for (i<2) { if (q==5) cq_phi(PI); cq_theta(&q,-.5); cq_theta(&q,.5); }
;     int mark = q;                       /* the RECORD: the loop's exit value */
;     int r    = mark; cq_theta(&r, .125);/* a rail GATE after that record     */
;     return cq_measure(mark) + cq_measure(r);
;
; WHAT IT PINS TODAY. Before bd 3qlq the record was `int mark = cq_phi(q, 1.0)`: an
; off-chain name reached through a DIAGONAL Rz hop, which a fix keyed on the direct
; `cq_theta` users of a chain member would miss (the `..._offchain_theta` sibling).
; Measured at the round-2 HEAD: `opt` exit 0 and
;
;     cqrt_rz_i32(%h, 1.0); cqrt_ry_i32(%h, 0.125); measure(%h); measure(%h)
;
; The fix made the record set the rail's own FORWARD CLOSURE, diagonal hops followed
; and not counted (`collectRailGates`' `OnRailOut`, handed to `staleRailRecordRead`).
; The 3qlq migration deleted that uncontrolled phase, so the record is now the chain
; member `%qn` itself with the gate `%r` behind it — the shape of
; lowering_reject_inloop_rail_record_postloop_theta.ll — and it declines with the
; same message.
;
; `clang -O1` form of the C above (rotated 2-trip do-while, `icmp eq %i, 0` back
; edge, `cq_phi(PI)` on the equality arm).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %latch
  %r = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)  ; a rail gate AFTER it
  %m0 = call i32 @cq_measure_si32(i32 %qn)                    ; the STALE read
  %m1 = call i32 @cq_measure_si32(i32 %r)
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
