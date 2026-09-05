; lowering_reject_tainted_angle_cast.ll — DECLINE: quantum-derived rotation
; ANGLE in STRAIGHT-LINE code, cast (sitofp) family.
;
; `%ang = sitofp i32 %q to double` is TAINTED (any non-angle user of a tainted
; value is), and it feeds `cq_phi`'s arg-1 ANGLE slot. The source semantics
; (angle = f(quantum value), value in superposition) admit NO fixed unitary —
; there is nothing correct to emit. There is NO control flow here, so the
; region-level guard (ArmClassify::taintedAngleGate, the
; control_swap_reject_tainted_angle* family) never runs. Without the
; straight-line guard, rotation lowering emits `cqrt_rz(h, %ang)` and
; CastLowering then cross-type-RAUWs the f64 cast result to an i32 handle
; INSIDE that emitted call — which is FINAL (never erased), so the mistyped
; call reaches the verifier: LLVM ERROR Broken module, opt exit 134
; (loud-but-wrong; found by the test_C_libtooling-9hh §8 adversarial
; clearance, tracked as test_C_libtooling-659).
;
; The guard (RotationLowering::lowerRotations, arg-1 taint check before any
; emission) is the straight-line root fix: decline loudly, lower nothing.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = sitofp i32 %q to double                  ; TAINTED angle producer
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
