; control_angle_select_reject_round2_quantum_false_arm.ll — DECLINE (bd
; test_C_libtooling-dm7f.6 round-1 review finding F-B2). The FALSE arm of a Ry
; angle select is CLASSICAL when the select is classified and emitted, and turns
; QUANTUM only after the round-2 fixpoint:
;
;     static int f(int a) { return a + 100; }      // nounwind willreturn memory(none)
;     int m = 0; if (q > 3) m = f(k);              // 6.5 classical call under control
;     cq_theta(&r, (q == 5) ? 0.9 : m * 0.1);
;
; The 6.5 region hoists `f(k)` and RAUWs the merge `m` to its tainted `%out`;
; `repropagateControlMerges` then taints `sitofp m * 0.1`, which the angle-select
; emitter (run in round 1, when it was classical) has already placed verbatim in
; one controlled gate slot. That is a QUANTUM angle (CLAUDE.md R3, bd 94ad), and
; `lowerRotations`' producer-agnostic `declineTaintedAngle` refuses it.
;
; Under the dm7f.6 round-1 subtraction-free stream the FALSE-arm variant died at
; `unsupported frozen quantum wire` (the emitter froze `B`); the X-bracket route
; reads each arm once with no freeze, so BOTH variants now give the
; tainted-angle message (sibling: `control_angle_select_reject_round2_quantum_true_arm.ll`).
;
; RETIREMENT TRIGGER (L7): when bd `94ad` lowers a quantum-valued angle, this
; becomes an accept of that lowering.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error: {{.*}}cq rotation lowering: unsupported quantum-derived rotation angle

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define internal i32 @f(i32 %a) #0 {
  %r = add i32 %a, 100
  ret i32 %r
}

define i32 @example(i32 %u0, i32 %u1, i32 %k) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c1 = icmp sgt i32 %q, 3
  br i1 %c1, label %arm, label %join

arm:
  %v = call i32 @f(i32 %k)
  br label %join

join:
  %m = phi i32 [ %v, %arm ], [ 0, %entry ]
  %mf = sitofp i32 %m to double
  %ang1 = fmul double %mf, 1.000000e-01
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double %ang1
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}

attributes #0 = { nounwind willreturn memory(none) }
