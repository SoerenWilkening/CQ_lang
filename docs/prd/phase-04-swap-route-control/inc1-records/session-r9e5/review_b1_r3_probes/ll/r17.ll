; r17 — AREA 4/5: the `e07` shape (sibling AFTER the select) put inside a
; classically-bounded LOOP, in the round-2 window. The back edge means trip k+1's
; control read fires on a register trip k's `.9` already moved, so the DT prong's
; "provably after EVERY execution of the read point" must be FALSE and this must
; DECLINE. If it accepts, the re-ask's positional premise does not survive the
; flatten/roll.
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
define i32 @f(i32 %a) #0 { %s = add i32 %a, 100  ret i32 %s }
define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c0 = icmp sgt i32 %q, 3
  br i1 %c0, label %arm, label %merge
arm:
  %r = call i32 @f(i32 4)
  br label %merge
merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  br label %body
body:
  %i = phi i32 [ 0, %merge ], [ %i1, %body ]
  %acc = phi i32 [ 0, %merge ], [ %acc1, %body ]
  %a = select i1 %b, i32 2, i32 5
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  %m = call i32 @cq_measure_si32(i32 %a)
  %acc1 = add i32 %acc, %m
  %i1 = add i32 %i, 1
  %cc = icmp slt i32 %i1, 3
  br i1 %cc, label %body, label %exit
exit:
  %t = add i32 %acc1, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
