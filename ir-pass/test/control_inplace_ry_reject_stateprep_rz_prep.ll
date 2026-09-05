; control_inplace_ry_reject_stateprep_rz_prep.ll — DECLINE: `cq_phi(CONST, θ)` in
; the arm — the Rz "state prep" THAT DOES NOT EXIST (probe `p10`, from C).
;
; ⚠ STATE PREP IS Ry-ONLY, AND THE REASON IS RULE 3 RATHER THAN SCOPING: `cq_phi`
; on a classical operand PROPAGATES NO TAINT AND IS DELETED AT LOWERING — it
; never allocates. So there is no Rz state prep to be symmetric with, the "phase
; twin" of this increment does not exist, and the §12.1 stem table and the §13.4
; RAUW-target row gain NO NEW ROW (the Ry row already says
; link / never adjoint / frozen / relabelling gate / RAUW-to-`T`, and state prep
; needs all five verbatim).
;
; It has a second consequence that is easy to miss and is recorded here because
; this is the fixture a reader reaches for: `tools/inplace_twin_matrix.py`'s
; SHIPPED five-axis method — emit the same cell twice with `cq_theta` and
; `cq_phi` in the arm and compare — CANNOT witness this increment, because the
; `cq_phi` spelling of a state prep is a DELETED GATE, not an oracle. That is why
; the `--stateprep` pool uses the CHAINED twin plus a reduction instead (PRD
; §14.7/§14.8).
;
; Measured IDENTICAL on the pre-Inc-4 oracle.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 0)
  %s = add i32 %mq, %mr
  ret i32 %s
}
