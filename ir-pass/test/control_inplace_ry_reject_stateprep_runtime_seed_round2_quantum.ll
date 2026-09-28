; control_inplace_ry_reject_stateprep_runtime_seed_round2_quantum.ll — DECLINE (bd
; test_C_libtooling-z0re, the L1 re-ask `declineRound2QuantumPrepSeeds`): a RUNTIME
; state-prep seed that is CLASSICAL when F1 accepts it at round 1 and QUANTUM at the
; taint `lowerRotations` decides `Chained` on.
;
;     int y = 5; if (q > 3) y = f(a);          // 6.5 classical call under quantum control
;     int r = y; if (q2 + y > 7) r = cq_theta(y, .2);
;
; At round 1 the 6.5 merge φ `%y` is untainted (its incomings are classical), so the
; second region is a controlled STATE PREP with the runtime seed `%y` and F1 admits
; it (the Pred incoming IS `%y`). Round 1 then lowers the 6.5 region, RAUWs `%y` to
; its fresh `%out` rail, and `repropagateControlMerges` re-seeds taint from it: the
; hoisted theta's arg-0 is now a QUANTUM register, so `lowerRotations` would lower it
; CHAINED — an in-place controlled Ry on the `%out` rail that R4/R6 (skipped for a
; prep) never vetted. Here the hazard is concrete: the condition reads `q2 + y`, so
; the rotated rail IS on the condition's wire (R4's defect — the `add` template rail
; the flag is minted from is uncomputed by the spine AFTER `%out` was rotated).
;
; A LITERAL seed can never turn quantum, which is why the Inc-4 accept owed no record.
; The block `%mid` between the two regions is the bd fn1q probe's trick: without it
; the pair declines earlier at `lowerControlRegions`' precedence check (bd 35t0).
;
; On the ORACLE (main 9a230646) this module declines at F1's literal-only clause
; (`state prep seed does not match the merge incoming`), so the verdict is unchanged
; and only the reason moves. Without the re-ask (mutant M-L1, TRACK_Z0RE.md §7) the
; subject ACCEPTS it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}
define i32 @example(i32 %u0, i32 %v0, i32 %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm1, label %merge1
arm1:
  %r = call i32 @f(i32 %a)
  br label %merge1
merge1:
  %y = phi i32 [ %r, %arm1 ], [ 5, %entry ]
  br label %mid
mid:
  %sum = add i32 %q2, %y
  %c2 = icmp sgt i32 %sum, 7
  br i1 %c2, label %arm2, label %merge2
arm2:
  %t = call i32 @cq_theta_si32(i32 %y, double 2.000000e-01)
  br label %merge2
merge2:
  %rm = phi i32 [ %t, %arm2 ], [ %y, %mid ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: state prep seed became quantum under quantum control
