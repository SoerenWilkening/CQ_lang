; spec_accept_diamond_body.ll — Phase 6 / issue 5po2 (2nd increment, I1): a
; tainted acyclic single-exit VALUE DIAMOND inside a specialization-lifted callee
; — the `br` shape the clone path now lifts (beyond the 1st-increment
; straight-line `select`). `helper` is a two-phi single-level diamond
; (`if(b>5){a=b+1;c=b+2}else{a=b+3;c=b+4}; return a^c`) — a PredMux-CLAIMABLE
; value region (NumMergePhis>=2, PredMuxFlatten.cpp:405). A plain depth-1
; single-phi 2-incoming diamond is deliberately left to the SwapRoute value path
; and is out of this increment; a multi-EXIT early-return diamond stays declined
; (the I2 increment, see spec_reject_diamond_multiexit.ll).
;
; The clone `@__cq_q_helper_1` runs a scoped PredMux flatten over the
; rotation-free body → simple two-arm `select(icmp, derived, derived)` muxes (no
; toffoli at this depth) → the generalized two-arm integer `lowerCloneSelect`
; (flag kept LIVE) → the existing Bennett wrap copies out + reverses the forward
; stream + frees scratch. No phase arm is possible (a clone body is
; rotation-free), so this is always a value/method-B merge.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %c1 = icmp sgt i32 %b, 5
  br i1 %c1, label %then, label %else
then:
  %a1 = add i32 %b, 1
  %d1 = add i32 %b, 2
  br label %merge
else:
  %a2 = add i32 %b, 3
  %d2 = add i32 %b, 4
  br label %merge
merge:
  %pa = phi i32 [ %a1, %then ], [ %a2, %else ]
  %pd = phi i32 [ %d1, %then ], [ %d2, %else ]
  %r  = xor i32 %pa, %pd
  ret i32 %r
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %p = call i32 @cq_phi_si32(i32 %r, double 3.140000e+00)
  %m = call i32 @cq_measure_si32(i32 %p)
  ret i32 %m
}

; The call retargets to the mangled clone; phase + measure land on its result.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_rz_i32(i32 %[[R]], double 3.140000e+00)
;
; Clone: the flattened diamond is a single straight-line block (no br/phi/select
; survives). The two merge phis lower to two controlled-XOR muxes (flag kept
; LIVE), an `xor` recombines them, the result copies out to the escaping rail,
; and the Bennett reverse plays every `_unc` (LIFO) before freeing each scratch
; rail at |0> — returning the basis copy.
; CHECK:     define internal i32 @__cq_q_helper_1(i32 %b)
; the four speculated arm values:
; CHECK:     call i32 @cq_template_add_i32_hl(i32 %b, i32 3)
; mux 1 (phi %pa): flag · copy T · ¬flag bracket · copy F:
; CHECK:     %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK:     %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[S1]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[S1]])
; CHECK:     call void @cqrt_x(i32 %[[F1]])
; mux 2 (phi %pd):
; CHECK:     %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK:     %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[S2]])
; recombine + copy-out:
; CHECK:     %[[XOR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[S1]], i32 %[[S2]])
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[XOR]], i32 %[[OUT]])
; Bennett reverse (LIFO): recombine first, both flags stripped by their _unc:
; CHECK:     call void @cq_template_xor_i32_unc(i32 %[[XOR]], i32 %[[S1]], i32 %[[S2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %b, i32 5)
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %b, i32 5)
; every scratch rail freed at |0>, then the basis copy returns:
; CHECK:     call void @cqrt_free
; CHECK:     ret i32 %[[OUT]]
; CHECK-NOT: under quantum lift
; CHECK-NOT: under quantum control
; CHECK-NOT: br i1
; CHECK-NOT: = phi
; CHECK-NOT: = select
