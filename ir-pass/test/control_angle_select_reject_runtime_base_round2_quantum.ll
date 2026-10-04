; control_angle_select_reject_runtime_base_round2_quantum.ll — DECLINE (bd
; test_C_libtooling-z0re, the L1 re-ask `declineRound2QuantumPrepSeeds`): the
; angle-select twin of `control_inplace_ry_reject_stateprep_runtime_seed_round2_quantum.ll`.
;
;     int y = 5; if (q > 3) y = f(a);                 // 6.5 → `%out` rail at round 1
;     int r = y; cq_theta(&r, (q2 + y > 7) ? .9 : .3);  // angle select on base `y`
;
; At round 1 `%y` is an untainted 6.5 merge φ, so S3 admits it as a RUNTIME base and
; SKIPS S7's rail prong, S8 and S9 (a fresh rail has no pre-region name). The 6.5
; region then RAUWs `%y` to its `%out` rail and round 2 taints it: `lowerRotations`
; would lower the emitter's unconditional twin `cq_theta(%out, .3)` CHAINED — an
; in-place Ry on `%out` — under a flag minted from `q2 + %out`, i.e. a rotation arm
; ON THE CONDITION'S WIRE, the exact shape S8 (`rotation arm on a condition wire`)
; exists to refuse and was never asked. The emitter records the twin on the
; classifier's verdict (`ControlRegion::RuntimeSeedAdmitted`) and the post-fixpoint
; re-ask declines.
;
; On the ORACLE (main 9a230646) this module declines `rotation angle under quantum
; control` (S3's untainted-base return); the verdict is unchanged, the reason moves.
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
  %ang = select i1 %c2, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %y, double %ang)
  %m = call i32 @cq_measure_si32(i32 %t)
  ret i32 %m
}
attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: state prep seed became quantum under quantum control
