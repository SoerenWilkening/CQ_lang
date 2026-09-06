; control_inplace_ry_reject_stateprep_sharecond.ll — DECLINE (R7, the ziov
; SHARED condition flag): the compare feeds a DATA use as well as the branch.
;
; On the ziov path `emitRegion` SKIPS the strip+free because a downstream data
; lineage owns the flag — which leaves the flag a LIVE record of the pre-region
; condition past the region. Nothing proves that composes with an arm that
; relabels a register in place, and Inc 1 was not cleared for it. Inc 4 inherits
; the refusal unchanged: R7 is asked BEFORE the state-prep block.
;
; MEASURED ON THE PRE-INC-4 ORACLE: `control flow` (the arm was not a rotation
; arm there, so R7 was never reached). The string moved because the CLAUSE moved;
; the verdict did not.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation arm shares the condition flag under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %f = zext i1 %c to i32
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %rm)
  %mf = call i32 @cq_measure_si32(i32 %f)
  %s  = add i32 %m, %mf
  ret i32 %s
}
