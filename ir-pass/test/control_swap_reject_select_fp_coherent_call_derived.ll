; control_swap_reject_select_fp_coherent_call_derived.ll — DECLINE (kjd1
; Rule-13 implementation clearance, angle-fence-lens MAJOR; probe p9): the
; select operand %q feeds a CURATED hardware call (`sqrt`) whose result gets a
; downstream cq_phi (Rz) on its wire — the channel-B dephasing family through a
; CALL-shaped producer. The pre-fix forward coherence walk `continue`d on every
; non-sink, non-rotation CallInst user WITHOUT walking its result (the "a
; surviving tainted call user is benign here" rationale, stale since the 7.1/
; libm curated carves let call producers survive the escape guard), so this
; accepted and lowered verify-clean while the instruction twin (fmul instead of
; sqrt) declined. The fixed walk pushes a surviving call's tainted result — a
; curated producer continues the coherence lineage exactly like an arithmetic
; instruction. Natural in the PRD's own motivating branchless-libm workload.
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
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_copy
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)
declare double @llvm.sqrt.f64(double)

define double @example(double %u0) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c   = fcmp ogt double %q, 5.000000e-01
  %sel = select i1 %c, double %q, double 1.000000e+00
  %d   = call double @llvm.sqrt.f64(double %q)                    ; curated call producer (p119: was cbrt)
  %qd  = call double @cq_theta_f64(double %d, double 3.000000e-01) ; Rz ON the derived wire
  %m   = call double @cq_measure_f64(double %sel)
  %m2  = call double @cq_measure_f64(double %qd)
  ret double %m
}
