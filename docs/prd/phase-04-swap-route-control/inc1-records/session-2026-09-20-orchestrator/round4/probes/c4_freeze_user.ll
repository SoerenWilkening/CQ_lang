; c4 — PROBE (P4): a `freeze` user of the narrow carried phi.  `freeze` is not a
; BinaryOperator / CmpInst / CastInst / curated call, so `lowerOps` never enqueues
; it; if it is TAINTED, (P4)'s first clause admits it and the retype goes ahead.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i16 @cq_measure_si16(i16)

define i32 @main(i32 %n) {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i16 [ 5, %entry ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i16 %a, -3
  %anext = select i1 %b, i16 %sub, i16 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %fr = freeze i16 %a
  %m = call i16 @cq_measure_si16(i16 %fr)
  %z = zext i16 %m to i32
  ret i32 %z
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
