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
; bd p3kd.7.8: `lowerCloneSelect` is gone; main's stage list lowers each flattened
; mux by the 4.4 `SelectMergeEmit` controlled-copy merge, and the Bennett wrap elides
; each merge's trailing `cqrt_x` strip (the flag is left negated in the forward and
; restored by the mirror's replayed `cqrt_x`). Hand trace, |b>: S1 = [b>5]·(b+1) ⊕
; ¬[b>5]·(b+3), S2 likewise with b+2/b+4, XOR = S1^S2 copied out; the exact mirror
; returns XOR, S2, F2, S1, F1 and the four arm rails to |0> before their frees. The
; whole clone body is pinned by CHECK-NEXT, which is what proves no br/phi/select
; survives (the former trailing CHECK-NOTs scanned only the declarations after `ret`,
; and the decline-text ones read stdout, where no diagnostic goes; a loud decline
; fails the RUN line itself).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (uncontrolled -> deleted (D2))
declare i32 @cq_theta_si32(i32, double)
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
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The call retargets to the mangled clone; phase + measure land on its result.
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_helper_1(i32 %{{[a-zA-Z0-9_.]+}})
;
; Clone: the flattened diamond is a single straight-line block. The four arm
; values are speculated, each merge phi lowers to one controlled-copy mux (flag ·
; copy T · `cqrt_x` · copy F; strip elided), an `xor` recombines them, the result
; copies out, the exact mirror replays the stream, and every |0> rail is freed.
; CHECK-LABEL: define internal i32 @__cq_q_helper_1(i32 %b)
; CHECK-NEXT:  entry:
; CHECK-NEXT:  %[[A2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 3)
; CHECK-NEXT:  %[[D2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 4)
; CHECK-NEXT:  %[[A1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 1)
; CHECK-NEXT:  %[[D1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %b, i32 2)
; mux 1 (phi %pa):
; CHECK-NEXT:  %[[F1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT:  %[[S1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[A1]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[A2]], i32 %[[S1]])
; mux 2 (phi %pd):
; CHECK-NEXT:  %[[F2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK-NEXT:  %[[S2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[D1]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[D2]], i32 %[[S2]])
; recombine + copy-out:
; CHECK-NEXT:  %[[XOR:[a-zA-Z0-9_.]+]] = call i32 @cq_template_xor_i32(i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT:  %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:  call void @cqrt_copy_i32(i32 %[[XOR]], i32 %[[OUT]])
; Bennett mirror (LIFO):
; CHECK-NEXT:  call void @cq_template_xor_i32_unc(i32 %[[XOR]], i32 %[[S1]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[D2]], i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F2]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F2]], i32 %[[D1]], i32 %[[S2]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F2]], i32 %b, i32 5)
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[A2]], i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_x(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_copy_i32_controlled(i32 %[[F1]], i32 %[[A1]], i32 %[[S1]])
; CHECK-NEXT:  call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F1]], i32 %b, i32 5)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D1]], i32 %b, i32 2)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[A1]], i32 %b, i32 1)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[D2]], i32 %b, i32 4)
; CHECK-NEXT:  call void @cq_template_add_i32_hl_unc(i32 %[[A2]], i32 %b, i32 3)
; every scratch rail freed at |0>, then the basis copy returns:
; CHECK-NEXT:  call void @cqrt_free(i32 %[[A2]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D2]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[A1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[D1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S1]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[F2]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[S2]])
; CHECK-NEXT:  call void @cqrt_free(i32 %[[XOR]])
; CHECK-NEXT:  ret i32 %[[OUT]]
; CHECK-NEXT:  }
