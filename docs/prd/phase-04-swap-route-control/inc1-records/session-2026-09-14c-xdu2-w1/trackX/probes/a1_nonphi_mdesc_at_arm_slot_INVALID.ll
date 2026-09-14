; a1 — the CONSTRUCTION ATTEMPT behind "is a phi the only opcode whose operand
; need merely dominate its incoming EDGE?".  Here a NON-phi M-descendant (%bad,
; an `add` in the merge block) is spelled at F2's ARM slot (the theta's arg-0).
; If LLVM accepted this, the availability invariant would be false for `add`.
; EXPECT: opt -passes=verify REJECTS — "Instruction does not dominate all uses!"
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %t = call i32 @cq_theta_si32(i32 %bad, double 9.000000e-01)
  br label %merge
merge:
  %m = phi i32 [ %t, %arm ], [ 7, %entry ]
  %bad = add i32 %m, 0
  %mm = call i32 @cq_measure_si32(i32 %m)
  ret i32 %mm
}
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
