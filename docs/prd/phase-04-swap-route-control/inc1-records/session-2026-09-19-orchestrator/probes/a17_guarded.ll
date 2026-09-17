; A17 — the carried handle in a ROTATED loop with a zero-trip GUARD (the shape a
; RUNTIME trip bound produces). The exit phi muxes the classical seed with %out.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)
define i32 @f(i32 %n) {
entry:
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %exit
ph:
  br label %head
head:
  %i = phi i32 [ 0, %ph ], [ %inext, %head ]
  %a = phi i32 [ 5, %ph ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, %n
  br i1 %done, label %exit, label %head
exit:
  %r = phi i32 [ 5, %entry ], [ %anext, %head ]
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}
