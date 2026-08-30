; lowering_reject_loop_rail_record_offchain_theta.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 3, the RULE-14 PIN for finding F-3).
;
; NOTE THE NAME: `loop`, not `inloop`. This is the SAME C program as
; lowering_reject_inloop_rail_record_offchain_theta.ll with the in-body tainted
; `if` REMOVED —
;
;     int q = cq_theta(0, .5);
;     for (i<2) { q = cq_theta(q,-.5); q = cq_theta(q,.5); }   /* NO tainted control */
;     int a = cq_theta(q, 0.125);
;     int b = cq_theta(a, 0.25);
;     return cq_measure(a) + cq_measure(b);
;
; — so it is claimed by ROUND 1 (`tryCaseA`, whose CLOSURE calls the fence over its
; `railRoot` set) instead of by ROUND 2 (`collapseRailPhisIn` step 2b, over
; `ChainsByRoot`). It ALREADY declined before this round, and that is exactly why
; it is here: the two rounds compute the rail's forward extension with two
; different spellings, and on this program they must agree.
;
; WHAT THE PAIR PINS. Round 1's `railRoot` fixpoint is itself a forward walk ("an
; in-place gate on a rail value joins the SAME rail"), so `%a` and `%b` were
; already IN its member set and the record loop reached them for free. Round 2
; peels a `root → PreV → phi → LatV` CHAIN, which `%a` and `%b` are not on — so the
; identical source program was a loud decline in round 1 and a silent miscompile in
; round 2 (F-3). Two spellings survive on purpose (see `collectRailGates`'s Rule-14
; note: round 1 is building a CLAIM set and needs "ALL incomings"; round 2 is
; building an ∃-path staleness witness and needs "SOME incoming"), so the guarantee
; that they have not drifted apart on the reach that MATTERS has to be a test, not
; a comment. If either extension is narrowed, one of these two files goes red.
;
; `clang -O1` form: with no tainted control the body collapses to a single block
; that is its own latch.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
; CHECK-NOT: cqrt_measure_i32
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

exit:                                             ; preds = %loop
  %a = call i32 @cq_theta_si32(i32 %qn, double 1.250000e-01)   ; OFF-CHAIN record
  %b = call i32 @cq_theta_si32(i32 %a, double 2.500000e-01)    ; a rail gate AFTER it
  %m0 = call i32 @cq_measure_si32(i32 %a)                      ; the STALE read
  %m1 = call i32 @cq_measure_si32(i32 %b)
  %s = add nsw i32 %m1, %m0
  ret i32 %s

loop:                                             ; preds = %entry, %loop
  %q = phi i32 [ %q0, %entry ], [ %qn, %loop ]
  %i = phi i32 [ 0, %entry ], [ %inext, %loop ]
  %qh = call i32 @cq_theta_si32(i32 %q, double -5.000000e-01)
  %qn = call i32 @cq_theta_si32(i32 %qh, double 5.000000e-01)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i, 0
  br i1 %done, label %loop, label %exit
}
