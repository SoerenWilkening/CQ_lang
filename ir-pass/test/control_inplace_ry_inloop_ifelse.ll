; control_inplace_ry_inloop_ifelse.ll — ACCEPT: the in-loop control-in-place Ry
; arm in the TWO-BLOCK IF/ELSE form, one rotation per arm on ONE register (bd
; test_C_libtooling-drbq Inc 3).
;
; HAND IR ON PURPOSE, and this is the same asymmetry Increment 1 records for the
; flat case (PRD §13.2 row L-i). From C, `clang -O1`'s SimplifyCFG merges
; `if (c) r = R(r, A); else r = R(r, B);` into ONE call with a `select` on the
; ANGLE, so the C spelling is an ANGLE SELECT (drbq Inc 2b) — and an angle select
; on any cycle stays DECLINED (`classifyAngleSelect` S7, PRD §13.6). The genuine
; two-block `BranchRegion` below is reachable only from hand-written IR, and it IS
; in the accept class.
;
; THE CHAIN RULE IS THE ASSERTION HERE (M-β, PRD §13.4). Both arms hoist into the
; pred in emission order, and the SECOND gate's arg-0 is set to the FIRST gate's
; RESULT — so the two rotations are ONE in-place sequence on ONE rail rather than
; two independent readers of the base. Without the chain the loop-carried header φ
; would have two in-place `cq_theta` users and `collapseRailPhisIn` step (2) would
; fire the Rule-8 `loop-carried rail has multiple in-place consumers`.
;
; The false arm rides the self-inverse `cqrt_x(f)` bracket, so the emitted order is
; `T_t`, then `x; T_f; x`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; CHECK: loop:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R:[a-zA-Z0-9_.]+]], double 9.0
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 3.0
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
;
; NOROUTE-NOT: call void @cqrt_cswap

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %armt, label %armf
armt:
  %gt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
armf:
  %gf = call i32 @cq_theta_si32(i32 %r, double 3.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %gt, %armt ], [ %gf, %armf ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
