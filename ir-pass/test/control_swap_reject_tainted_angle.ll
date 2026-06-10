; control_swap_reject_tainted_angle.ll — DECLINE: quantum-derived rotation ANGLE
; in an accepted-shape derived-base region.
;
; `%ang = sitofp i32 %qd to double` is TAINTED (any user of a tainted value is),
; and the arm gate rotates by it: `cq_phi(%qd, %ang)`. The source semantics
; (angle = f(quantum value), value in superposition) admit NO fixed unitary, so
; there is nothing correct to emit — yet the shape passes every OTHER predicate
; (pure spine, derived base == straight-through, tainted base, classical-looking
; CFG). Without the angle-classicality guard the emitter replays the angle
; operand verbatim onto the rail: a verify-clean silent miscompile — confirmed
; live by the §8 adversarial review of test_C_libtooling-9hh (2026-06-10), then
; with an opaque-call producer. Reachable from real C:
; `double t = (double)q; if (q > 5) q = cq_phi(q, t);` (clang -O1 keeps the
; unconditional conversion in the pred, so the arm stays a pure spine).
;
; The guard (ArmClassify::taintedAngleGate) is the criterion-3 parallel for
; arg-1: every spine gate's angle (and a derived base's own angle) must be
; UNTAINTED, else decline loudly.
;
; PRODUCER CHOICE (test_C_libtooling-bxv re-shape): the original opaque-call
; producer (`call double @ext(i32 %qd)`) now declines EARLIER at the
; module-wide taint-escape guard (@ext consuming the handle is an escape in
; its own right, pinned by lowering_reject_taint_escape_opaque_call.ll), and
; opt exits at the first error diagnostic. A sitofp producer is NOT an escape
; (casts are lowerOps' class), so this fixture keeps pointing at the region
; ARM-gate angle check it exists to pin.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %qd = call i32 @cq_phi_si32(i32 %q, double 9.000000e-01)
  %ang = sitofp i32 %qd to double                ; TAINTED angle producer
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %qd, double %ang)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %qd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}rotation angle under quantum control
