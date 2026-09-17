; b1 — PROBE: the GUARD block lives INSIDE AN OUTER LOOP, so the promotion's
; `cqrt_alloc` is minted once PER OUTER TRIP.  (Z1)/(Z8) only require the header to
; have a single external predecessor and that predecessor's unique predecessor to
; end in a conditional branch; NOTHING requires the guard to be outside every
; enclosing loop, nor that its other successor exits the loop nest.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @main(i32 %n, i32 %k) {
entry:
  br label %ohead

ohead:                                            ; the OUTER loop header
  %j = phi i32 [ 0, %entry ], [ %jnext, %olatch ]
  %guard = icmp sgt i32 %n, 0
  br i1 %guard, label %ph, label %olatch

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
  br i1 %done, label %iexit, label %head, !llvm.loop !0

iexit:
  br label %olatch

olatch:
  %r = phi i32 [ 5, %ohead ], [ %anext, %iexit ]
  %mm = call i32 @cq_measure_si32(i32 %r)
  %jnext = add nuw nsw i32 %j, 1
  %odone = icmp eq i32 %jnext, %k
  br i1 %odone, label %oexit, label %ohead, !llvm.loop !2

oexit:
  ret i32 %mm
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
!2 = distinct !{!2, !1}
