; l1_round2_grow_65arm.ll — THE L1 REACHABILITY WITNESS for bd `tu9q`'s round-1
; grant. A 6.5 classical-call arm OUTSIDE the loop whose merged result is read
; INSIDE it. At `lowerLoops` (round-1 taint, BEFORE `detectControlRegions`) the
; merge phi's incomings are a classical call result and a constant, so the phi is
; UNTAINTED, it is not a `Cand`, and the loop is granted the root-mint marking on
; `%y` alone. After `repropagateControlMerges` the body reads the emitter's `%out`
; rail, which IS tainted.
;
; MEASURED: on ORACLE `0e280fc62a91cec2` this module declines with bd `s82e`'s
; string; on the stale-roots spelling of the re-ask (S1/S2) it declines with
; `cq loop lowering: round-1 iteration-local marking falsified by round-2 taint`,
; which is the proof that the window is REACHABLE and not a prediction. On the
; SHIPPED spelling, which re-derives the roots under FINAL taint, clause (ii-b)
; admits `%out` as a merge out-rail and the module ACCEPTS — the grant was still
; justified, just by a root the round-1 record could not name (Track T finding
; T-1). Kept as a record; `l2_round2_grow_derived.ll` is the sibling that must
; still decline.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @slice(i32 %u0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %y = call i32 @cq_theta_si32(i32 7, double 3.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %r = call i32 @f(i32 %a)
  br label %merge
merge:
  %m = phi i32 [ %r, %arm ], [ 5, %entry ]
  br label %loop
loop:
  %k = phi i32 [ 1, %merge ], [ %k2, %loop ]
  %acc = phi i32 [ 0, %merge ], [ %s2, %loop ]
  %sh = lshr i32 %y, %k
  %an = and i32 %sh, %m
  %ms = call i32 @cq_measure_si32(i32 %an)
  %s2 = add i32 %ms, %acc
  %k2 = add i32 %k, 1
  %e = icmp eq i32 %k2, 3
  br i1 %e, label %out, label %loop
out:
  %y2 = call i32 @cq_theta_si32(i32 %y, double 9.000000e-01)
  %mm = call i32 @cq_measure_si32(i32 %y2)
  %t = add i32 %s2, %mm
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }
