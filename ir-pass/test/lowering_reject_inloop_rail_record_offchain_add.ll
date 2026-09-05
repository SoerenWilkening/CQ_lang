; lowering_reject_inloop_rail_record_offchain_add.ll — DECLINE (bd
; test_C_libtooling-8h7d.5, Rule-13 ROUND 4, finding OD-A). The program that used
; to ship as lowering_reject_inloop_control_rail_fanout.ll, pinned at the fence
; that names its ACTUAL hazard:
;
;     for (...) { if (q > 5) q = cq_phi(q, b); q = q + 7; other = q_pre + 9; }
;     return cq_measure(other);
;
; `%o2 = add %qm, 9` is an OFF-CHAIN, unmarked `add` INSIDE the loop body, so M-C's
; G5 refuses it outright and `lowerOps` mints it a FRESH rail — it is `OutOfPlace`,
; never a second in-place mutator, and the Rule-8 fan-out guard correctly no longer
; counts it (`railValueConsumerDisposition`). THE PROGRAM STILL DECLINES, and the
; hazard it declines on is the one that was always there: `%o2` READS `%qm`, the
; pre-`addc` register, at a position AFTER the in-place `cqrt_addc_i32(%h, 7)` that
; `%qn` becomes. The emitted stream would compute `q+7+9`, not the source's `q+9` —
; a verify-clean silent miscompile, and exactly the class round 1's `staleRail
; RecordRead` / `kMsgRailRecordStale` fence was added for.
;
; WHY THIS FILE EXISTS AS ITS OWN FIXTURE. The message moved OWNER, not verdict,
; when the fan-out guard stopped over-counting — the same shape as round 3's
; r3f/m1 and r3p/t3 moves. A widened accept predicate that quietly relies on
; "something else will still catch it" is how an over-accept ships, so the catch is
; pinned here rather than assumed. It is also the mutation twin of
; control_swap_inloop_range_cond.ll: revert `railValueConsumerDisposition` to the
; bare dtzb shape and THIS file goes red (it declines with the fan-out message
; instead), while the range-cond accept goes red the other way.
;
; ORDER MATTERS AND IS PART OF THE PIN: step (2) (fan-out) runs BEFORE step (2b)
; (record liveness), so the two fences cannot both claim a program — whichever
; fires first owns the message. This file proves 2b is reached now that 2 declines
; to over-count.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq loop lowering: rail record read past an in-place gate on the same rail
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
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  br label %merge
merge:
  %qn = add i32 %q, 7                                 ; in-place rail self-update
  %o2 = add i32 %q, 9                                 ; reads the PRE-addc record
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, %n
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %o2)
  ret i32 %m
}
