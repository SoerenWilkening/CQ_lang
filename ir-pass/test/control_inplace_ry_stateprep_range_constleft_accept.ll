; control_inplace_ry_stateprep_range_constleft_accept.ll — ACCEPT. The ACCEPT
; CONTROL for `..._reject_stateprep_range_constleft_ugt.ll`: the same
; literal-on-the-left shape whose swapped relation pins NOTHING, so the swap is
; pinned as a DISCRIMINATOR rather than as a blanket over-decline (round-2
; Rule-13 review, lens R1 finding F-R1-5; probe `p/hl03_constleft_accept.ll`).
;
; `icmp ugt i32 6, %t` over `%t = and %q, 6` means `t < 6`, and `%t`'s range is
; the six-element `[0,7)` hull of `{0,2,4,6}`. The true edge is `[0,6)` and the
; false edge is `{6}` — neither is the seed `0`, so F2 is silent BY VALUE. The
; region lowers exactly as the constant-on-the-right accepts do, and
; `CompareLowering` emits the swapped `cq_template_icmp_ult_i32_hl(%h_op, 6)`
; with the HANDLE first, which is its own pre-existing convention and not
; something F2 did.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=ACNT    < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT    < %t.cqd0.ll

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %t = and i32 %q, 6
  %c = icmp ugt i32 6, %t
  br i1 %c, label %merge, label %arm
arm:
  %rt = call i32 @cq_theta_si32(i32 0, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ 0, %entry ]
  %mr = call i32 @cq_measure_si32(i32 %rm)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s  = add i32 %mr, %mt
  ret i32 %s
}

; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i32_hl(i32 %[[Q]], i32 6)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ult_i32_hl(i32 %[[A]], i32 6)
; the arm is the FALSE successor, so the gate is `cqrt_x`-bracketed.
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_ult_i32_hl_unc(i32 %[[F]], i32 %[[A]], i32 6)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R]])
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[A]])

; ---------------------------------------------------------------------------
; NOROUTE is PURE-NEGATIVE and WHOLE-FILE (round-1 F-L7-1); every count lives in
; its own prefix. The handle names are the LOWERED module's, read from the pass
; output rather than typed (F-L7-2).
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: cqrt_copy
; NOROUTE-NOT: _controlled_inv
; NOROUTE-NOT: _controlled_unc
; NOROUTE-NOT: = phi
; NOROUTE-NOT: cq_theta
; NOROUTE-NOT: cq_phi_
; THE FREEZE, whole-file: no `cqrt_free` may name the PREPPED rail `%h1`.
; NOROUTE-NOT: call void @cqrt_free(i32 %h1)
; …and the arm gate must not become UNCONDITIONAL (mutation M7).
; NOROUTE-NOT: call void @cqrt_ry_i32(i32 %h1, double 9.000000e-01)

; ACNT-COUNT-2: call i32 @cqrt_alloc_
; ACNT-NOT:     call i32 @cqrt_alloc_
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
