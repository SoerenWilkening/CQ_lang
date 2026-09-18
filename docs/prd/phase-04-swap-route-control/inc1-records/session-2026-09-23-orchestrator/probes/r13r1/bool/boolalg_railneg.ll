; A BARE-RAIL region whose arm is on the FALSE successor, with an i1 merge phi
; whose incomings are all in the STRICT substrate grammar => the BoolAlg path.
; EP(arm->merge) is `xor %rail, true`, and the BoolAlg `and(EP, %c)` is NOT
; covered by increment 2's select-site fold.
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %rail = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c = icmp sgt i32 %q, 1
  br i1 %rail, label %merge, label %arm
arm:
  br label %merge
merge:
  %p  = phi i1  [ %c, %arm ], [ false, %entry ]
  %a4 = phi i32 [ 2, %arm ], [ 5, %entry ]
  %b5 = phi i32 [ 2, %arm ], [ 6, %entry ]
  %c6 = phi i32 [ 2, %arm ], [ 7, %entry ]
  %sel = select i1 %p, i32 %a4, i32 %b5
  %m1 = call i32 @cq_measure_si32(i32 %sel)
  %m2 = call i32 @cq_measure_si32(i32 %c6)
  %mb = call i1 @cq_measure_i1(i1 %rail)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
