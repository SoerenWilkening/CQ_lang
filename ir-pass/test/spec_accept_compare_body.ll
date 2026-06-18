; spec_accept_compare_body.ll — Phase 6.1 WI-1.6: a clone body that combines
; COMPARISON RESULTS AS DATA (`return (a > 5) + (a > 10)`, tainted `a`). The
; clone lowers the two `icmp sgt` flags + their `zext` widens + the `add` to
; forward `cq_template_*` calls, and the Bennett reverse emits each adjoint as a
; void `_unc` — including the compare `cq_template_icmp_sgt_i32_hl_unc`, which
; recomputes-and-XORs the flag rail to |0> from the STILL-LIVE root `%a` (a
; permutation, never a phase — no dephasing). This DEPENDS on the WI-0 compare
; `_unc` grid (§6.0): pre-WI-0 a recovered compare gate was an un-invertible
; primitive and this body would have loud-declined. A compare driving CONTROL
; FLOW is a separate path (swap-route, before `lowerOps`) — declined for 6.1.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @bucket(i32 %a) {
entry:
  %c1 = icmp sgt i32 %a, 5
  %z1 = zext i1 %c1 to i32
  %c2 = icmp sgt i32 %a, 10
  %z2 = zext i1 %c2 to i32
  %s = add i32 %z1, %z2
  ret i32 %s
}

define void @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @bucket(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret void
}

; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_bucket_1(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     define internal i32 @__cq_q_bucket_1(i32 %a)
; Forward: two compare flags, two widens, one add.
; CHECK:     %[[CMP1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 5)
; CHECK:     %[[CAST1:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP1]])
; CHECK:     %[[CMP2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 10)
; CHECK:     %[[CAST2:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP2]])
; CHECK:     %[[OP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32(i32 %[[CAST1]], i32 %[[CAST2]])
; Copy-out BEFORE the reverse.
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32(i32 %[[OP]], i32 %[[OUT]])
; Reverse (LIFO): add, then widen+compare for arg 10, then widen+compare for arg 5.
; The compare `_unc` reads the still-live root %a.
; CHECK:     call void @cq_template_add_i32_unc(i32 %[[OP]], i32 %[[CAST1]], i32 %[[CAST2]])
; CHECK:     call void @cq_template_zext_i1_to_i32_unc(i32 %[[CAST2]], i32 %[[CMP2]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[CMP2]], i32 %a, i32 10)
; CHECK:     call void @cq_template_zext_i1_to_i32_unc(i32 %[[CAST1]], i32 %[[CMP1]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[CMP1]], i32 %a, i32 5)
; CHECK:     ret i32 %[[OUT]]
;
; The compare adjoint is the void `_unc`, never the fresh-minting `_inv`.
; CHECK-NOT: cq_template_icmp_sgt_i32_hl_inv
