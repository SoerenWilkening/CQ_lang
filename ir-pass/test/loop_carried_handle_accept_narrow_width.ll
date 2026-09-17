; loop_carried_handle_accept_narrow_width.ll — bd `test_C_libtooling-11qv`, the
; NARROW-WIDTH loop-carried handle variable.
;
; ONE EDIT from `loop_carried_handle_accept_select_merge.ll`: the carried phi is
; `i16` instead of `i32`.  ⚠ THIS FILE WAS `loop_carried_handle_reject_narrow_width.ll`
; UNTIL 2026-09-20 and it is RE-DERIVED, NOT REPLACED — its own L8 trigger said
; *"the day a `mutateType(i32)` at the promotion lands, this file becomes an
; ACCEPT.  Re-derive it then; do NOT delete it."*  That trigger was
; character-for-character correct about the VERDICT.
;
; WHAT THE OLD FENCE WAS, because deleting the reason would be worse than
; deleting the file.  `cqrt_alloc_<W>` RETURNS `i32` at EVERY width (Rule 15: *"a
; runtime handle is ALWAYS `i32` regardless of width"*), and so does every merge
; `%out` — so a promoted `i16` phi muxed two `i32` values through a phi of the
; wrong type.  A build that merely DELETED clause (Z3) emitted `PHI node operands
; are not the same type as the result!` and `opt` ABORTED with exit 134, MEASURED
; (bd `zujr`'s conjunct mutant matrix).  The fence is retired only because the
; promotion now performs the retype the fence existed to make unnecessary.
;
; WHAT MAKES THE RETYPE SAFE, in the two places it has to be true:
;   * the phi's USERS are laundered by erasure — `lowerOps` rewrites the tainted
;     `add nsw i16 %a, -3` into `cq_template_add_i16_hl(i32 %a, i16 -3)` and
;     `lowerMeasures` rewrites the measure — which is the same laundering
;     `RotationLowering` already relies on for its own cross-type RAUW.  Gate
;     (P4) refuses a user that is NOT rewritten (a second phi is the shape that
;     occurs), and refusing is a SKIP, so such a module declines at
;     `declineClassicalMuxes` one stage later.
;   * the WIDTH is not lost: the promotion records `taint.HandleWidth[phi] =
;     "i16"`, the side-table `logicalOperandWidth` consults BEFORE the (now
;     laundered `i32`) LLVM type.  Without that record a Q+Q compare over two
;     retyped `i16` phis would recover `i32` and mint an `i32` template symbol
;     for two `i16` registers — verify-clean and wrong, which is the class
;     `CompareLowering.cpp` refuses in writing (*"NEVER default empty -> i32"*).
;
; ⚠ THE WIDTH SUFFIXES BELOW ARE THE POINT OF THE FIXTURE, not decoration.  Every
; one of them is `i16` while the phi and every handle are `i32`; an `i32` suffix
; anywhere here would be the wrong-width silent miscompile.
;
; ⚠ L8 RETIREMENT TRIGGER: this file moves when the promotion's user gate (P4),
; the `HandleWidth` record, or clause (Z3)'s width test changes.  RE-DERIVE it
; then — do not delete it, and do not predict which string it lands on: a trigger
; that names the next wall is only ever a LOWER BOUND (bd `zujr`, eleven fixtures,
; every trigger wrong about the wall).
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s \
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

; The TRIP-1 REGISTER, minted in the preheader at the carried variable's own ABI
; width, from its own classical seed.
; CHECK: entry:
; CHECK-NEXT: %cq.carried = call i32 @cqrt_alloc_i16(i16 5)

; THE RETYPED PHI — `i32` (the handle ABI) with BOTH incomings `i32`.  This line
; is what clause (Z3) used to refuse and what gate (P4) now licenses.
; CHECK: %a = phi i32 [ %cq.carried, %entry ], [ %out, %head ]

; The arm chain and the merge, at the LOGICAL width, on `i32` handles.
; CHECK: %h_op = call i32 @cq_template_add_i16_hl(i32 %a, i16 -3)
; CHECK: %out = call i32 @cqrt_alloc_i16(i16 0)
; CHECK: call void @cqrt_copy_i16_controlled(i32 %bf, i32 %h_op, i32 %out)
; CHECK: call void @cqrt_x(i32 %bf)
; CHECK: call void @cqrt_copy_i16_controlled(i32 %bf, i32 %a, i32 %out)

; The ancilla returns to `x ^ x = 0` and its free is a proven-|0> one.
; CHECK: call void @cqrt_cnot(i32 %h, i32 %bf)
; CHECK: call void @cqrt_free(i32 %bf)

; The measure reads the LOGICAL width off an `i32` handle.
; CHECK: %m1 = call i16 @cqrt_measure_i16(i32 %out)
