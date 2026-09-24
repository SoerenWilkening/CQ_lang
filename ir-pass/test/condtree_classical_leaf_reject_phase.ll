; condtree_classical_leaf_reject_phase.ll — DECLINE (bd test_C_libtooling-xdu2.13).
;
; `if (q && m == n) cq_phi(0.5)` — the SAME mixed tree at the register-free
; BRANCH PHASE (`ArmClassify::classifyPhaseKickback`). The kickback does not take
; a literal in this increment, so it keeps its `control flow` decline, byte-for-
; byte the pre-xdu2.13 string. RETIREMENT TRIGGER: when the kickback routes the
; literal through `emitCondNetwork`, this becomes an ACCEPT whose stream is the
; mint `gl = cq_template_and_i1_hl(f, %c)`, `cqrt_rz_i1(gl, 0.5)`, the `_unc`,
; the free — re-derive it then; do not delete it. matrix CASE 7.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s
; CHECK: cq controlled lowering: control flow under quantum control

define i32 @slice(i32 %n, i32 %m) {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 2.500000e-01)
  %t = icmp ne i32 %q, 0
  %c = icmp eq i32 %m, %n
  %a = and i1 %c, %t
  br i1 %a, label %arm, label %merge
arm:
  call void @cq_phi(double 5.000000e-01)
  br label %merge
merge:
  %r = call i32 @cq_measure_si32(i32 %q)
  ret i32 %r
}
declare void @cq_phi(double)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
