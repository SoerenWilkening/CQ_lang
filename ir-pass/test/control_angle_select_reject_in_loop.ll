; control_angle_select_reject_in_loop.ll — DECLINE (S7): the consumer is inside a
; classically-bounded LOOP (bd drbq Inc 2b; Increment 3 = drbq.4 owns loops).
;
;     for (int i = 0; i < 3; ++i)
;       if (q == 5) r = cq_theta(r, .9); else r = cq_theta(r, .3);
;
; THE IR IS THE `-O1` SHAPE, NOT A HAND-BUILT ONE (measured — probe q8): the
; compare AND the angle select are loop-invariant, so LICM hoists them into the
; preheader and leaves the CONSUMER in the body. That is why S7 asks about all
; THREE blocks (`Cond`, `Sel`, `T`) rather than just the select's, and why it is
; asked BEFORE S6: without it, S6's "one block" clause would fire first and the
; module would decline with a POSITIONAL message that says nothing true about the
; refusal. `classifyArms` asks R7's loop clause before R6 for exactly this reason.
;
; What Inc 3 has to prove before lifting this: both of S9's position predicates
; are FLAT (`provablyBefore` and `cannotFollowGate` have no per-activation
; reading), so a loop-carried register's own header phi — reached as a wire member
; AROUND THE BACK EDGE — reads as a stale record when it is simply the next
; iteration's value. That is the bd 8h7d.5 `provablyBeforePerActivation`
; distinction, and it is a Rule-13 change, not a clause deletion.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  br label %body
body:
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  %rp = phi i32 [ %r, %entry ], [ %rt, %body ]
  %rt = call i32 @cq_theta_si32(i32 %rp, double %ang)
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %body
exit:
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rt)
  %s = add i32 %mq, %mr
  ret i32 %s
}
