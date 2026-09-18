; loop_pairing_reject_nest_multiexit_hoisted.ll — DECLINE (bd
; `test_C_libtooling-4jok`, Rule-13 round 5 finding F-1, 2026-09-21).
;
; ⚠ THIS FILE EXISTS BECAUSE CLAUSE (ii-d)'s COMMENT WAS WRONG ABOUT WHY (ii-d) IS
; SAFE, AND THIS IS THE SHAPE THAT SHOWS IT.  The comment used to say
; *"`loopExitDischargePoint` is the SAME predicate P2's anchor walk calls: if
; there is no once-per-mint point, there is no licence, and the root is
; refused."*  It IS the same predicate — asked of a DIFFERENT LOOP:
;
;     the CLAUSE   asks `loopExitDischargePoint(L)`     — the loop being MARKED
;     the ANCHOR   asks `loopExitDischargePoint(LOut)`  — the OUTERMOST loop
;                  enclosing the CONSUMER that does not contain the mint
;                  (`Uncomputation.cpp:369-381`)
;
; THE MODULE puts those two loops in disagreement.  `%m2 = mul i32 %q, 2` is
; minted outside the whole nest and read only by the INNER body.  The INNER loop
; has a unique exit (`%outerlatch`), so the clause grants the Root and records an
; exit-discharge obligation.  The OUTER loop has TWO exit destinations (`%bailout`
; from the header, `%out` from the latch), so `loopExitDischargePoint(outer)` is
; null and the anchor has NOWHERE to place the discharge.
;
; ⚠ WHAT STOPS IT IS THE POSTCONDITION, NOT THE CLAUSE — which is the whole point
; of the file.  By the time the anchor abandons, `markIfRailLocal` has marked the
; body and conjunct (1) of `declineDephasingUnmarkedLoopRails` is already
; SILENCED, so the leak would ship with the fence for its own hazard class
; disarmed and no diagnostic anywhere.  `declineUndischargedExitObligations` is
; the only member left, and it fires.  **So do not narrow, move or drop that
; postcondition on the reading that "the clause already refuses": it cannot,
; because it cannot see which loop the anchor will choose.**
;
; ⚠ READ THE `MAIN` COLUMN BEFORE FILING ANYTHING AGAINST THE COMPOSITION.  On the
; pre-landing compiler (`cq-opt` 8280ea8d…) this module ACCEPTS at exit 0 with
; ZERO `cq_template_mul_i32_hl_unc` in the lowered module and
; `cqrt_ry_i32(i32 %h, double 9.000000e-01)` standing over the live record — the
; bd `s82e` / bd `1m5p` class, carrying only the bd `lyyf` ruled WARNING.  **On
; this shape the landing is strictly STRICTER**: a ruled warning becomes a loud
; decline.
;
; ⚠ AND IT IS THE FIXTURE bd `tu9q`'s OWN RECORD SAYS IT OWES AND HAS NOT GOT.
; `trackT2/IMPL_T3.md` §3 F-R2-1: the genuinely multi-exit path *"is owed a
; fixture and has none: three C shapes were built for it and `-O1` renormalised or
; declined every one … a PREDICTION rather than a test."*  It is a test now.  It
; is hand-written IR for that reason, and its ACCEPT control is
; `loop_pairing_accept_nest_singleexit_hoisted.ll` — ONE conjunct of difference
; (the outer loop's exit uniqueness, which the clause never asks about).
;
; ⚠ L8 RETIREMENT TRIGGER: this file moves the day clause (ii-d) starts asking
; about the loop the ANCHOR will choose rather than the loop it is marking, or the
; day `anchorForConsumer` stops walking outermost.  RE-DERIVE it then — and do not
; predict which string it lands on: every trigger in this bead's history that
; named the next wall has been a LOWER BOUND.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
;
; ⚠ The `not` inversion is what pins the decline — a `DS_Error` writes 0 bytes to
; stdout, so an IR-text `CHECK-NOT` here would be VACUOUS (Rule 12 defect (b)).
; CHECK: cq loop lowering: hoisted invariant rail admitted for in-loop discharge was not discharged

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0, i32 %n) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y = call i32 @cq_theta_si32(i32 7, double 3.000000e-01)
  %m2 = mul i32 %q, 2
  br label %outer

outer:
  %o = phi i32 [ 0, %entry ], [ %o2, %outerlatch ]
  %acc = phi i32 [ 0, %entry ], [ %acc3, %outerlatch ]
  %bail = icmp eq i32 %o, %n
  br i1 %bail, label %bailout, label %inner

inner:
  %k = phi i32 [ 1, %outer ], [ %k2, %inner ]
  %acc2 = phi i32 [ %acc, %outer ], [ %s2, %inner ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m2
  %ms = call i32 @cq_measure_si32(i32 %an)
  %s2 = add i32 %ms, %acc2
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %outerlatch, label %inner

outerlatch:
  %acc3 = phi i32 [ %s2, %inner ]
  %o2 = add i32 %o, 1
  %done = icmp eq i32 %o2, 3
  br i1 %done, label %out, label %outer

bailout:
  br label %out

out:
  %accf = phi i32 [ %acc3, %outerlatch ], [ %acc, %bailout ]
  %q2 = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %q2)
  %t = add i32 %accf, %mm
  ret i32 %t
}
