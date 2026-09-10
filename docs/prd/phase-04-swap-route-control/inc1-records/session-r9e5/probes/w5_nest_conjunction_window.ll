; w5 — the 4.3 depth-2 NEST in the round-2 taint window, with the OUTER level's
; condition the `%out`-derived rail and the outer arm carrying NO phase gates —
; so the ONLY read of the user's register is the CONJUNCTION toffoli
; (`emitCondNode(Conj, …)` in `SwapRouteEmit`, which calls the node emitter
; DIRECTLY rather than through `emitCondNetwork`). On f8d29e8 it ACCEPTS at rc=0,
; STRICT stage 2b `3 verified, 0 violation(s)`, emitting
;     ry_i1(%h_cast,.5); ry_i1(%h_cast,.9);
;     toffoli(%h_cast, %h_cmp2, %g); rz_i1(%g,.7),!cq.branchphase; toffoli(…)
; — the conjunction read on a register the SIBLING moved. After the fix it
; DECLINES `condition predates a non-diagonal gate`.
;
; THIS PROBE IS WHY THE RECORDING LIVES IN `emitCondNode` AND NOT IN
; `emitCondNetwork`'s node loop: the first spelling of the fix recorded in the
; loop, and this site — a level ROOT that is a rail, read by a node the NEST
; builds by hand — would have been missed with no diagnostic anywhere. Shipped as
; `control_phase_nest_reject_rail_round2_sibling_theta.ll`.
declare void @cq_phi(double)
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
  br label %second
second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br i1 %b, label %mid, label %join
mid:
  %ci = icmp sgt i32 %q, 7
  br i1 %ci, label %inner, label %join
inner:
  call void @cq_phi(double 7.000000e-01)
  br label %join
join:
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}
attributes #0 = { nounwind willreturn memory(none) }
