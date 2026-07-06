; lowering_reject_bitcast_angle_control.ll — p119.7 DECLINE (Rule-13 clearance
; hardening: the CONTROL-REGION angle path). Companion to the straight-line
; lowering_reject_bitcast_angle.ll. Lifting the fp<->int bitcast decline must not
; let a bitcast-derived tainted `double` reach a rotation ARG-1 ANGLE inside a
; TAINTED-CONDITION arm either. Here a tainted i64 theta handle is reinterpreted
; (`bitcast i64 to double`) and fed as the angle of a `cq_phi` INSIDE the arm of a
; tainted-`icmp` diamond — owned by the control-region guard
; `ArmClassify::taintedAngleGate` (distinct from the straight-line
; `declineTaintedAngle`), which fires during control detection, BEFORE `lowerOps`
; lowers the bitcast. Declines `rotation angle under quantum control`; no bitcast
; template and no cswap/copy is minted. This locks the control-region angle fence
; against a future stage-reordering regression (the fence is load-bearing on the
; lowerRotations/detectControl-before-lowerOps ordering).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i64 @cq_theta_sll(i64, double)
declare i64 @cq_phi_sll(i64, double)
declare i64 @cq_measure_sll(i64)

define i64 @example(i64 %u0) {
entry:
  %q  = call i64 @cq_theta_sll(i64 %u0, double 5.000000e-01)
  %c  = icmp sgt i64 %q, 5                              ; tainted condition (control region)
  br i1 %c, label %arm, label %merge
arm:
  %ang = bitcast i64 %q to double                       ; int -> fp reinterpret
  %g   = call i64 @cq_phi_sll(i64 %q, double %ang)       ; tainted %ang in ARG-1 ANGLE, IN the arm
  br label %merge
merge:
  %qm  = phi i64 [ %q, %entry ], [ %g, %arm ]
  %m   = call i64 @cq_measure_sll(i64 %qm)
  ret i64 %m
}

; CHECK: error{{.*}}rotation angle under quantum control
; CHECK-NOT: cq_template_bitcast
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cqrt_copy
