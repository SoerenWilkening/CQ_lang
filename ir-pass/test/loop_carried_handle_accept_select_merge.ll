; loop_carried_handle_accept_select_merge.ll — bd `test_C_libtooling-zujr`, THE
; POSITIVE, and it is the owner's cascade with the rail BANK taken away so the
; capability is pinned on its own.
;
; `%a` is a LOOP-CARRIED HANDLE VARIABLE: a header phi whose ENTRY incoming is the
; classical literal `5` and whose LATCH incoming is a tainted-condition `select` —
; the 4.4 data select `clang -O1` if-converts `if (b) a -= 3;` into — whose emitter
; mints a FRESH `%out = cqrt_alloc_i32(0)` per activation.  So the register is
; re-minted every trip and the phi muxes two HANDLES under the loop's own
; CLASSICAL exit test (`icmp eq %i.next, 3`).  Exactly one incoming is live per
; trip and WHICH one is a classical fact, which is why this is a handle VARIABLE
; and not the no-cloning data mux `declineClassicalMuxes` refuses.
;
; THE ONE THING THE MODULE IS MISSING is the trip-1 register:
; `promoteLoopCarriedHandleSeeds` materialises `cqrt_alloc_i32(5)` in the
; PREHEADER (the owner's ruling (1) of 2026-09-17) and records the phi in
; `taint.PromotedCarriedHandlePhis`, which is the ONLY thing that guard accepts.
;
; ⚠ ITS ISOLATING CONTROLS ARE FOUR SEPARATE FILES, one per clause, and each is a
; ONE-EDIT mutation of THIS module:
;   loop_carried_handle_reject_accumulator.ll   (Z6) the latch incoming is a
;                                               template rail, not a merge `%out`
;   loop_carried_handle_reject_guarded.ll       (Z8) a zero-trip GUARD bypasses
;                                               the preheader the alloc lives in
;   loop_carried_handle_reject_narrow_width.ll  (Z3) an `i16` carried phi
;   loop_carried_handle_reject_tainted_seed.ll  (Z4) the seed is already a rail
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.ll
; RUN: %filecheck --check-prefix=CHECK --input-file=%t.ll %s
; RUN: %filecheck --check-prefix=NOREG --input-file=%t.ll %s

declare zeroext i1 @cq_theta_i1(i1 zeroext, double)
declare i32 @cq_measure_si32(i32)

define i32 @f() {
entry:
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %inext, %head ]
  %a = phi i32 [ 5, %entry ], [ %anext, %head ]
  %b = call zeroext i1 @cq_theta_i1(i1 false, double 5.000000e-01)
  %sub = add nsw i32 %a, -3
  %anext = select i1 %b, i32 %sub, i32 %a
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %head, !llvm.loop !0

exit:
  %m = call i32 @cq_measure_si32(i32 %anext)
  ret i32 %m
}

!0 = distinct !{!0, !1}
!1 = !{!"llvm.loop.unroll.disable"}

; THE TRIP-1 PROMOTION, in the preheader.
; CHECK: %cq.carried = call i32 @cqrt_alloc_i32(i32 5)
; THE HANDLE MUX.
; CHECK: %a = phi i32 [ %cq.carried, %entry ], [ %out{{[0-9]*}}, %head ]
; ONE ACTIVATION: the fresh bank rail, the CNOT-copied ancilla, the fresh `|0>`
; merge rail, two X-bracketed controlled copies, the ancilla back to |0> and freed.
; CHECK: %h = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; CHECK: %h_op = call i32 @cq_template_add_i32_hl(i32 %a, i32 -3)
; CHECK: %bf = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_cnot(i32 %h, i32 %bf)
; CHECK: %out{{[0-9]*}} = call i32 @cqrt_alloc_i32(i32 0)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %h_op, i32 %out
; CHECK: call void @cqrt_x(i32 %bf)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %bf, i32 %a, i32 %out
; CHECK: call void @cqrt_x(i32 %bf)
; CHECK: call void @cqrt_cnot(i32 %h, i32 %bf)
; CHECK: call void @cqrt_free(i32 %bf)
; CHECK: call i32 @cqrt_measure_i32(i32 %out
;
; THE REGISTERS ARE NEVER BRACKETED AND NEVER FREED — their own whole-file
; prefix, because a positive above a negative WINDOWS it (Rule 12 hygiene (a)).
; NOREG-NOT: cqrt_x(i32 %cq.carried)
; NOREG-NOT: cqrt_x(i32 %a)
; NOREG-NOT: cqrt_free(i32 %cq.carried)
; NOREG-NOT: cqrt_free(i32 %a)
; NOREG-NOT: cqrt_free(i32 %out
; NOREG-NOT: cqrt_free(i32 %h)
; NOREG-NOT: cqrt_free(i32 %h_op)
