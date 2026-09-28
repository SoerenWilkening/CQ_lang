; control_inplace_ry_reject_stateprep_runtime_seed_mismatch.ll — DECLINE (F1's
; IDENTITY clause, bd test_C_libtooling-z0re): two DIFFERENT runtime values.
;
;     int r = s2; if (q > 3) r = cq_theta(s1, .2);
;
; The owner's ruling admits a runtime seed only as "the same SSA value as the
; merge's Pred incoming". Here the arm prepares `|s1⟩` while the straight-through
; edge carries `s2`: on the `f=0` component the fresh rail would hold `s1` where
; the source holds `s2` — a DATA MUX between a prepared rail and an unrelated
; classical value, with no rotation-arm lowering. F1's first clause now ADMITS
; `%s1` (it is a runtime seed); the SECOND clause — pointer identity of the Pred
; incoming with the seed, unchanged — is what refuses it, with the string that
; names the seed. The pair with `…_runtime_seed.ll` (accept, same value) is the
; red-green for "identity, not runtime-ness, is the fence".
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed does not match the merge incoming under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %s1, i32 %s2) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %s1, double 2.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %s2, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %sum = add i32 %mq, %mr
  ret i32 %sum
}
