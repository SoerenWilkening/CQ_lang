; loop_carried_handle_reject_narrow_width.ll — bd `test_C_libtooling-zujr`, the
; (Z3) ISOLATING CONTROL for `loop_carried_handle_accept_select_merge.ll`.
;
; ONE EDIT from the positive: the carried phi is `i16`.
;
; ⚠ THIS IS A CRASH FENCE, NOT A TASTE PREFERENCE.  `cqrt_alloc_<W>` RETURNS
; `i32` at EVERY width (Rule 15: *"a runtime handle is ALWAYS `i32` regardless of
; width"*), and so does every merge `%out` — so a promoted `i16` phi would mux two
; `i32` values through a phi of the wrong type.  MEASURED on a build that skipped
; this test: `report_fatal_error`, a hard abort, on the `short a` spelling of the
; owner's cascade.  `lowerRotations` gets away with the same mismatch only because
; *"that mismatch is transient and laundered by erasure of the tainted users"* —
; and a phi is the one tainted user that is NOT erased.
;
; ⚠ L8 RETIREMENT TRIGGER: a `mutateType(i32)` on the phi at the promotion (the
; `RailBankPromote.cpp` idiom, which does exactly that to a bank load) would widen
; this to every ABI width.  It is an ACCEPT-direction change to a value every
; later stage reads and owes its own Rule-13 round; it is FILED, not smuggled in.
; The day it lands, this file becomes an ACCEPT.  Re-derive it then; do NOT
; delete it.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 \
; RUN:   | %filecheck %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i16 @cq_measure_si16(i16)

define i32 @f() {
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
  %m = call i16 @cq_measure_si16(i16 %anext)
  %mz = sext i16 %m to i32
  ret i32 %mz
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; CHECK: cq loop lowering: loop-carried tainted value crosses iterations
