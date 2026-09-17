; c1 — PROBE (P4): a NARROW (i16) carried handle phi whose only extra user is a
; hand-written `cqrt_*` call.  (P4) admits any callee whose name starts with
; `cqrt_` on the stated ground that "their own lowering stage rewrites the operand
; to the i32 handle" — but NOTHING rewrites an already-`cqrt_*` call.  If the
; promotion retypes the phi under it, the module ends the pass verifier-invalid.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i16 @cq_measure_si16(i16)
declare void @cqrt_sink_i16(i16)

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
  call void @cqrt_sink_i16(i16 %a)
  %m = call i16 @cq_measure_si16(i16 %anext)
  %z = zext i16 %m to i32
  ret i32 %z
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
