; lowering_control_switch_jumptable_loadreuse.ll — Phase 4.x (test_C_libtooling-
; 5zu), NEGATIVE safety lock (adversarial review 2026-06-03). The table load %ang
; is used by a SECOND rotation in the lookup arm in addition to the merge φ.
; normalizeJumpTableAngle deletes the lookup arm, so a load with a live use beyond
; the φ would strand a dangling reference (a broken module). The recognizer
; requires the load to be single-use (the φ) and DECLINES otherwise → the
; memory-escape guard diagnoses, no broken module.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}quantum control
; CHECK-NOT: PHI nodes not grouped
@switch.table = private unnamed_addr constant [3 x double] [double 1.000000e-01, double 2.000000e-01, double 3.000000e-01], align 8
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
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
  %r2 = call i32 @cq_phi_si32(i32 %v, double %ang)
  br label %merge
merge:
  %a = phi double [ %ang, %lookup ], [ 9.000000e-01, %entry ]
  %r = call i32 @cq_phi_si32(i32 %v, double %a)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
