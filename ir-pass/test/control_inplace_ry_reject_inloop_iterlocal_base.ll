; control_inplace_ry_reject_inloop_iterlocal_base.ll — DECLINE (PRD §13.2 row
; L-b): the rotated register is ITERATION-LOCAL — minted inside the loop body, so
; its rail does NOT cross the back edge.
;
; THIS IS R7-loop CLAUSE (b), AND IT IS A SCOPING CLAUSE, NOT A SAFETY ONE.
; Increment 3 is the Ry arm on the loop's PERSISTENT register: `flatRegionRollableInLoop`
; admits the CFG, but no member of the rotated base's wire closure is a PHINode in
; the loop header, so the shape is refused with the loop string.
;
; IT IS ALSO MEASURABLY NOT TWIN-IDENTICAL, which is why declining it is correct
; rather than merely conservative: the merge escapes the region into a
; `cq_measure` inside the body, so `markIfRailLocal` refuses the iteration-local
; marking and the ROLLED form leaks the condition chain once per trip while the
; hand-unrolled twin discharges it. A DIFFERENT CIRCUIT — precisely what
; `tools/loop_twin_matrix.py` exists to catch. Widening it is a separate
; capability, not a relaxation of this one.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow inside a loop body under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %rl = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %rl, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %rl, %loop ]
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  ret i32 %mm
}
