; f1: TARGET 1 -- a genuinely MULTI-EXIT loop around the carried handle, hand
; written so `-O1` cannot fold the two exits into a `umin`.  The exit phi muxes
; the HEADER phi (taken on the early exit, i.e. BEFORE this trip's merge) with
; the merge `%out` (taken on the normal exit).  Both are handles, so (Z8) passes.
; Asks: does the promotion's preheader alloc pair with the per-trip `%out` rails
; on EVERY exit path?
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %x) {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %a = phi i32 [ 5, %entry ], [ %anext, %latch ]
  %early = icmp eq i32 %i, %x
  br i1 %early, label %exit, label %body

body:
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %e = phi i32 [ %a, %head ], [ %anext, %latch ]
  %m = call i32 @cq_measure_si32(i32 %e)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
