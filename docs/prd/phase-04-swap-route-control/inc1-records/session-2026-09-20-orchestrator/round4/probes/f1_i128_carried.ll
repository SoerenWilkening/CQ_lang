; f1 — PROBE: (Z3) no longer says `isIntegerTy(32)`; it says `isIntegerTy()` plus a
; non-empty `abiWidthFromType`.  `abiWidthFromType` maps i80 -> "i80" and i128 ->
; "i128" (OpcodeSupport.cpp:236-249), and `WidthDispatch::allocFn` resolves BOTH
; (typeForAbiWidth knows them) even though the runtime ships NO `cqrt_alloc_i128`
; / `cqrt_alloc_i80`.  If (P1) does not block it, the promotion mints a PHANTOM
; symbol.
declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i128 @cq_measure_si32(i128)

define i128 @main() {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i128 [ 5, %entry ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i128 %a, -3
  %anext = select i1 %b, i128 %sub, i128 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %m = call i128 @cq_measure_si32(i128 %anext)
  ret i128 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}
