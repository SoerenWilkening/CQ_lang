; HAND IR (r903 probe w6) — w1's shape with the IN-PLACE parent spelled `sub`
; instead of `xor`. M-C lowers `sub %q, 9` IN PLACE (addc with -9), so the rail
; identity is preserved and the loop collapse can claim the phi; but
; `WireWalk::collectWireValues`' forward walk crosses ONLY Add and Xor, so the
; SIBLING theta on that same rail is invisible to `thetaOnPathTo` and therefore
; to `phiTracksWire`.
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  %q0 = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  br label %loop

loop:
  %q = phi i32 [ %q0, %entry ], [ %a, %body ]
  %acc = phi i32 [ 0, %entry ], [ %acc1, %body ]
  %i = phi i32 [ 0, %entry ], [ %i1, %body ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %body

arm:
  call void @cq_phi(double 3.000000e-01)
  br label %body

body:
  %t = sub i32 %q, 9
  %a = call i32 @cq_theta_si32(i32 %t, double 1.000000e-01)
  %z = call i32 @cq_theta_si32(i32 %t, double 9.000000e-01)
  %mz = add i32 %z, 0
  %acc1 = add nsw i32 %acc, %mz
  %i1 = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %i1, 3
  br i1 %done, label %exit, label %loop

exit:
  %mq = call i32 @cq_measure_si32(i32 %a)
  %r = add nsw i32 %acc1, %mq
  ret i32 %r
}
