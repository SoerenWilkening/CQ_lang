; spec_reject_cq_primitive.ll — Phase 6.1 WI-1.5: a callee body that contains a
; quantum primitive (`@cq_phi_*`) is NOT classical and is loudly declined by the
; specialization classifier (exact `Theta/Phi/Measure` call-site membership —
; NEVER name-prefix). This is ALSO the Rule-7 copy-out correctness gate (DD-3
; (c′)): a body with a rotation could carry phase, which `cqrt_copy` (a basis-
; label copy) would dephase. The classifier fires the specialization message in
; the detection pre-pass and records the site in `plan6.Diagnosed`, so the
; carve-out does NOT also emit the generic `kMsgUnknownCallee`.
;
;
; 3qlq(prep_a2): HAND DECISION — the register `cq_phi` here was NEVER the subject.
; This fixture pins an uncompute / mux / measurement-ordering / specialization rule
; and used `%r = cq_phi_<sfx>(%x, θ)` only as "a gate on a handle".  D1 removes that
; spelling, so the gate is re-spelled `cq_theta_<sfx>` — the OTHER in-place rotation
; on the same rail, which is what the corpus uses everywhere else for the same job.
; MEASURED on the Inc-1 binary: the swap reproduces this fixture's ORIGINAL asserted
; diagnostic, so the CHECK lines are UNCHANGED and the property is pinned by exactly
; the text it was pinned by before.  (prep_a measured the same 16 files against the
; pre-3qlq ORACLE; this is the independent re-measurement on the SUBJECT.)
; ⚠ Note what the swap does NOT preserve: Rz is DIAGONAL and Ry is not, so a rule
; that turned on diagonality would move.  None of these 16 do — that is what the
; character-for-character reproduction of the diagnostic establishes.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %x) {
entry:
  %g = call i32 @cq_theta_si32(i32 %x, double 1.000000e-01)
  ret i32 %g
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: error{{.*}}cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted
; The generic unknown-callee message is NOT also emitted for this site.
; CHECK-NOT: cq taint escape
