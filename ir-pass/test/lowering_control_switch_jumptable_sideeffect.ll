; lowering_control_switch_jumptable_sideeffect.ll — Phase 4.x (test_C_libtooling-
; 5zu), NEGATIVE safety lock (adversarial review 2026-06-03). The lookup arm has
; conditionally-executed SIDE EFFECTS (a `store` and a `call`) beyond the table
; gep/load. normalizeJumpTableAngle collapses the diamond and DELETES the lookup
; block, so it MUST validate the arm contains nothing but the cast/gep/load/br —
; else those side effects are silently dropped (a miscompile). The recognizer
; DECLINES (unexpected instruction in the lookup arm), so the memory-escape guard
; diagnoses and the side effects are preserved.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}memory addressing under quantum control
; CHECK-NOT: cqrt_rz_i32_controlled
@switch.table = private unnamed_addr constant [3 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01], align 8
@sink = global i32 0, align 4
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare void @sideeffect()
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %idx = add i32 %q, -1
  %bound = icmp ult i32 %idx, 3
  br i1 %bound, label %lookup, label %merge
lookup:
  %zext = zext i32 %idx to i64
  %gep = getelementptr inbounds [3 x double], ptr @switch.table, i64 0, i64 %zext
  %ang = load double, ptr %gep, align 8
  store i32 42, ptr @sink, align 4
  call void @sideeffect()
  br label %merge
merge:
  %a = phi double [ %ang, %lookup ], [ 9.000000e-01, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %a)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
