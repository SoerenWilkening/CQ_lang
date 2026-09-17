; d1 — PROBE: does the `taint.HandleWidth[phi]` record actually reach a consumer?
; The author's stated customer is a Q+Q compare via `qqSelectLeafWidth`, but ALL
; control emission runs BEFORE `promoteLoopCarriedHandleSeeds`, so no retyped phi
; can ever reach it.  The REACHABLE consumer is `lowerOps`' up-front cast capture
; (`OpcodeLowering.cpp:997`, `taint.HandleWidth.lookup(Cast->getOperand(0))`).
; With the record the symbol must be `cq_template_sext_i16_to_i32`; without it,
; `getSrcTy()` reads the laundered i32 and it would be `..._i32_to_i32`.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
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
  %ext = sext i16 %a to i32
  %m = call i32 @cq_measure_si32(i32 %ext)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
