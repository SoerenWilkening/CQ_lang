; control_inplace_ry_reject_inloop_cond_register.ll — DECLINE (PRD §13.2 row R4):
; an in-loop Ry arm on the CONDITION register's OWN wire.
;
; R4 IS A WIRE-SET QUESTION, POSITION-FREE, AND THE LOOP DOES NOT TOUCH IT. The
; flag strip `icmp_..._unc` recomputes the predicate on the condition's registers
; and XORs it back; that returns the flag to |0> only if those registers still hold
; the basis the forward mint read. Rz is diagonal, so a PHASE arm may rotate a
; condition register freely; an in-place Ry RELABELS it, and then neither the arm
; selection nor the strip is a function of the source's condition. Per activation
; the failure is per activation — there is nothing about a loop to prove here.
;
; THE PRINTED STRING IS **NOT** R4's OWN, AND THAT IS PRE-EXISTING, NOT AN Inc-3
; REGRESSION. `classifyArms`' `declineArm` lambda re-spells every later decline as
; the wire-gate message whenever `condWireDisposition` returned
; `ProvenPostRegion` — which the arm's own `cq_theta` on the condition wire always
; is. MEASURED IDENTICAL on the FLAT sibling `control_inplace_ry_reject_cond_register.ll`,
; which prints the same string for the same reason. The PRD §13.2 table predicted
; `rotation arm on a condition wire` here and is corrected in place; §13.11 worry 2
; is exactly this hazard, and this fixture is where a reader meets it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition predates a non-diagonal gate under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q0 = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %q = phi i32 [ %q0, %entry ], [ %qm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %qt = call i32 @cq_theta_si32(i32 %q, double 9.000000e-01)
  br label %merge
merge:
  %qm = phi i32 [ %qt, %arm ], [ %q, %loop ]
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
