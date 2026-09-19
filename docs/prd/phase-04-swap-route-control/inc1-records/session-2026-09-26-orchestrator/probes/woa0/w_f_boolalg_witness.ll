; w_f — ATTEMPT at a witness for the `!BoolAlg` conjunct: a φ RECORDED at region
; A's claim (it sits at A's ENTRY) and then converted by a LATER claim through the
; BOOLEAN-ALGEBRA path, which must NOT be a violation.
; Block order is deliberate: A's entry `J` is textually BEFORE region B's entry
; `head`, so the driver tries A first.
declare i32 @cq_theta_si32(i32, double)
declare i1  @cq_theta_i1(i1, double)
declare i32 @cq_measure_si32(i32)
declare i1  @cq_measure_i1(i1)

define i32 @probe(i32 %u) {
pre:
  %q  = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %b  = call i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %c  = icmp sgt i32 %q, 9
  br label %head
J:
  %cphi = phi i1 [ true, %P1 ], [ false, %P2 ]
  %dphi = phi i32 [ 1, %P1 ], [ 2, %P2 ]
  %c3 = icmp sgt i32 %q, %dphi
  %t  = and i1 %cphi, %c3
  br i1 %t, label %Aarm, label %Am
Aarm:
  br label %Am
Am:
  %v  = phi i32 [ 2, %Aarm ], [ 5, %J ]
  %v2 = phi i32 [ 3, %Aarm ], [ 6, %J ]
  br label %Bm
head:
  br i1 %c, label %P1, label %P2
P1:
  br label %J
P2:
  br label %J
Bm:
  %m1 = call i32 @cq_measure_si32(i32 %v)
  %m2 = call i32 @cq_measure_si32(i32 %v2)
  %mb = call i1 @cq_measure_i1(i1 %b)
  %z  = zext i1 %mb to i32
  %s  = add i32 %m1, %m2
  %s2 = add i32 %s, %z
  ret i32 %s2
}
