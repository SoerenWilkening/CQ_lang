; lowering_reject_tainted_angle_opaque.ll — DECLINE: the opaque-call family of
; the straight-line tainted-ANGLE bug (test_C_libtooling-659), now owned by the
; module-wide taint-escape guard (test_C_libtooling-bxv).
;
; `%ang = call double @ext(i32 %q)` commits TWO violations at once:
;   (1) @ext CONSUMES the tainted %q in a non-angle position — after rotation
;       lowering's RAUW the surviving call would read the i32 RUNTIME HANDLE
;       TAG (verify-clean, links, runs, plausible trace: the silent-miscompile
;       class found by the test_C_libtooling-9hh §8 adversarial clearance);
;   (2) its result is `cq_phi`'s ANGLE operand — angle = f(quantum
;       value), no fixed unitary.
; Reachable from real C: `double t = f(q); cq_phi(t);` — no control flow.
;
; RE-POINTED (bxv): violation (1) is the more fundamental one and its guard
; (TaintPropagation::declineTaintEscapes) runs FIRST, before any lowering; opt
; exits at the first error diagnostic, so the escape message is what this
; program prints. The ANGLE guards (`deleteGlobalPhases` for `cq_phi`,
; RotationLowering::declineTaintedAngle for `cq_theta`) still backstop every
; non-escape producer — pinned by lowering_reject_tainted_angle_{cast,theta}.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare double @ext(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %ang = call double @ext(i32 %q)                 ; TAINTED angle producer + escape
  call void @cq_phi(double %ang)
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq taint escape: tainted value consumed by an unknown callee
