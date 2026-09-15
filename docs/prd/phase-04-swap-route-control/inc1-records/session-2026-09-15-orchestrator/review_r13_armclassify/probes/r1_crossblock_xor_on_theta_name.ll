; Reviewer probe (bd hlhh round): cross-block phi kickback with a dtzb xor in the GAP
; whose operand is the ARM THETA NAME %t (a wire name of the condition rail), not the phi.
; %t has NO data use after the xor, so M-C's G6 "no data use AFTER the site" ground —
; the ground V12 leans on — does not obviously refuse the in-place conversion here.
declare void @cq_phi(double)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example(i1 %u0) {
entry:
  %b0 = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  br i1 %b0, label %arm, label %merge
arm:
  %t = call i1 @cq_theta_i1(i1 false, double 2.500000e-01)
  br label %merge
merge:
  %b1 = phi i1 [ %t, %arm ], [ false, %entry ]
  br label %gap1
gap1:
  %x = xor i1 %t, true
  br label %gap2
gap2:
  br i1 %b1, label %ph, label %done
ph:
  call void @cq_phi(double 9.000000e-01)
  br label %done
done:
  %m = call i1 @cq_measure_i1(i1 %x)
  ret i1 %m
}
