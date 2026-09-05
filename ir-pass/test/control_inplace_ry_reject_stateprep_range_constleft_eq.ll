; control_inplace_ry_reject_stateprep_range_constleft_eq.ll — DECLINE (F2), the
; flagship-decline shape with the LITERAL ON THE LEFT. It pins the position-free
; `{ ConstantInt k, tainted operand H }` SELECTION — F2's `K0 && !K1` branch —
; which is a DIFFERENT half of that code from the predicate swap.
;
; ⚠ SAY WHAT IT DOES NOT PIN, because that is the honest half (round-2 Rule-13
; review, lens R1 finding F-R1-5). `getSwappedPredicate(eq) == eq`, so an
; equality on the left CANNOT discriminate the swap: delete the swap line and
; this file stays green. The file that reddens is
; `..._range_constleft_ugt.ll`, and the two ship together for that reason.
; Delete the `K0 && !K1` branch instead and THIS file reddens: `K` stays null,
; the whole F2 block is skipped, and the module ACCEPTS with a fresh rail
; prepared to a value the compare has already proven `%q` equal to.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}state prep seed is proven equal to the condition register under quantum control
; CHECK-NOT: cqrt_ry_i32_controlled

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 5, %q
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 5, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 5, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %s  = add i32 %mq, %mr
  ret i32 %s
}
