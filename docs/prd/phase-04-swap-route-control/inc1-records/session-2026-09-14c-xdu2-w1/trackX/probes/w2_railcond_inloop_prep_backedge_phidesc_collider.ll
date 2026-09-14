; w2 — the BARE-`_Bool` RAIL condition spelling of w1.  This is bd wx8g's
; HEADLINE capability (the RailCond && Region.InLoop carve-out it retired), and
; it is the spelling the shipped tripwire pair does NOT cover: both shipped
; tripwires use a COMPARE condition and were therefore never behind that fence.
; EXPECT: DECLINE at F2 (the back-edge phi %v escapes the exclusion set).
define i32 @example(i32 %u0) {
entry:
  %b = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %zero = and i32 %q, 0
  br label %loop
loop:
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %t = phi i32 [ 0, %entry ], [ %tn, %merge ]
  %v = phi i32 [ 7, %entry ], [ %carry, %merge ]
  br i1 %b, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 7, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 7, %loop ]
  %mask = and i32 %rm, %zero
  %carry = or i32 %mask, 7
  %mm = call i32 @cq_measure_si32(i32 %rm)
  %tn = add i32 %t, %mm
  %inext = add i32 %i, 1
  %done = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %mb = call i1 @cq_measure_i1(i1 %b)
  %zb = zext i1 %mb to i32
  %r = add i32 %tn, %zb
  ret i32 %r
}
declare i1 @cq_theta_i1(i1, double)
declare i32 @cq_theta_si32(i32, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_measure_si32(i32)
