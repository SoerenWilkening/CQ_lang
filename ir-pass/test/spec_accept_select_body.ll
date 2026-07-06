; spec_accept_select_body.ll — Phase 6 / issue 5po2: a tainted `select` INSIDE a
; specialization-lifted callee. The ONE in-body control shape the clone path
; lowers (everything else still declines `InBodyControl`). `helper(b) = (b<5)?b:0`
; — the canonical `clang -O1` lowering of `int a=0; if(b<5) a+=b; return a` — is
; lifted into the reversible clone `@__cq_q_helper_1` as a 4.4 controlled-XOR copy
; `out = flag ? b : 0`, then Bennett-wrapped: copy-out → self-inverse reverse
; (the controlled copy re-applied zeroes the out rail, the compare `_unc` zeroes
; the flag) → free both scratch rails → return the escaping basis copy. The flag
; is kept LIVE across the body (no local strip); the Bennett reverse plays its
; adjoint. See EmitInverse (`cqrt_copy_<W>_controlled` = self-inverse) +
; SpecializeReject::isLiftableSelect + Specialization::lowerCloneSelect.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %t = icmp slt i32 %b, 5
  %s = select i1 %t, i32 %b, i32 0
  ret i32 %s
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %p = call i32 @cq_phi_si32(i32 %r, double 3.140000e+00)
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; Caller: theta → alloc+ry; the call retargets to the mangled clone; phase +
; measure land on the clone's tainted result.
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %[[H]])
; CHECK:     call void @cqrt_rz_i32(i32 %[[R]], double 3.140000e+00)
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[R]])
;
; Clone: the reversible select embedding, in order (§5a-style ordered check).
; CHECK:     define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK:     %[[FLAG:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %b, i32 5)
; CHECK:     %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %b, i32 %[[SEL]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[SEL]], i32 %[[OUT]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[FLAG]], i32 %b, i32 %[[SEL]])
; CHECK:     call void @cq_template_icmp_slt_i32_hl_unc(i32 %[[FLAG]], i32 %b, i32 5)
; CHECK:     call void @cqrt_free(i32 %[[FLAG]])
; CHECK:     call void @cqrt_free(i32 %[[SEL]])
; CHECK:     ret i32 %[[OUT]]
;
; No decline, no leftover raw select, no in-body-control error.
; CHECK-NOT: under quantum lift
; CHECK-NOT: under quantum control
; CHECK-NOT: = select
