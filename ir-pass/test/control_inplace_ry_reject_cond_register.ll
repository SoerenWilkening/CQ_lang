; control_inplace_ry_reject_cond_register.ll — DECLINE: the arm's Ry lands on the
; CONDITION's own register (PRD shape S2; owner Q5, bd test_C_libtooling-drbq).
;
;     if (q > 5) q = cq_theta(q, .9);
;
; PHYSICS, not shape: the flag is stripped by recomputing `q > 5` and XORing it
; back onto the flag rail, which is valid only while `q`'s COMPUTATIONAL BASIS is
; what the forward mint read. Rz is diagonal, so a PHASE arm may rotate the
; condition register freely (control_swap_diamond.ll accepts exactly that). An Ry
; RELABELS it: after the gate the flag is no longer a function of `q`'s basis and
; cannot be stripped, and the arm selection itself is read off a state the gate
; has already changed. Owner ruling 2026-09-02: this stays declined FOR THETA and
; keeps accepting for phi.
;
; It declines on the PRE-EXISTING stale-condition wire guard
; (`ArmClassify::condWireDisposition`), which sees a non-diagonal gate on the
; condition's provenance wire and never reaches the rotation-arm clause — so this
; fixture also pins that the new clause did not weaken it. The `q == 5` spelling
; of the same source never even gets here: `clang -O1` const-folds the arm's `q`
; to the literal 5, making it a classical-seed theta (state prep, Inc 4).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
