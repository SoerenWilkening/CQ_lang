; m1: a HEADER-EXITING (non-rotated) carried-handle loop whose trip count is a
; RUNTIME argument with NO static upper bound.  The exit is the header's own test,
; so the exit value needs no exit phi and (Z8) is vacuous; the ZERO-trip path reads
; the promoted preheader handle.  Asks whether an UNBOUNDED classical trip count
; is admitted (the emitted circuit then has no compile-time gate count).
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @f(i32 %n) {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %body ]
  %a = phi i32 [ 5, %entry ], [ %anext, %body ]
  %done = icmp eq i32 %i, %n
  br i1 %done, label %exit, label %body

body:
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  %inext = add nuw nsw i32 %i, 1
  br label %head, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %a)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
