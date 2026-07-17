; spec_accept_diamond_qq_cond.ll — ACCEPT (bd adia, 3c6m.55 Lever C): a
; Phase-6 lifted diamond whose branch CONDITION is a quantum-quantum compare
; (`icmp %b, %c`, both params tainted). The clone select flag mint is no
; longer HL-only: `mintCondNetwork` mints the QQ compare template
; `cq_template_icmp_sgt_i32(h, h)` (the frozen 7.1 Q+Q family; NO new
; symbol) via the shared `qqSelectLeafWidth` gate, and the Bennett wrap
; reverses it through the void `_unc` twin. The openlibm floorl mantissa
; test under `expl` specialization is exactly this shape.
;
; Formerly spec_reject_diamond_qq_cond.ll (the pre-adia HL-only fence).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b, i32 %c) {
entry:
  %cc = icmp sgt i32 %b, %c
  br i1 %cc, label %then, label %else
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

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %u1, double 7.000000e-01)
  %r  = call i32 @helper(i32 %q, i32 %q2)
  %m  = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; The retargeted site + the Bennett-wrapped clone with QQ flag mints.
; CHECK: call i32 @__cq_q_helper_11(i32 %{{.*}}, i32 %{{.*}})
; CHECK: define internal i32 @__cq_q_helper_11(i32 %b, i32 %c)
; Forward: the per-select QQ flag mint (each flattened mux mints its own).
; CHECK: %[[F1:.*]] = call i32 @cq_template_icmp_sgt_i32(i32 %b, i32 %c)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %[[F1]],
; CHECK: %[[F2:.*]] = call i32 @cq_template_icmp_sgt_i32(i32 %b, i32 %c)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %[[F2]],
; Copy-out, then the exact-LIFO Bennett reverse plays the QQ void `_unc`
; twins (borrowed inputs preserved) and frees every scratch rail proven-|0>.
; CHECK: call void @cqrt_copy_i32(i32 %{{.*}}, i32 %[[OUT:.*]])
; CHECK: call void @cq_template_icmp_sgt_i32_unc(i32 %[[F2]], i32 %b, i32 %c)
; CHECK: call void @cq_template_icmp_sgt_i32_unc(i32 %[[F1]], i32 %b, i32 %c)
; CHECK: call void @cqrt_free(i32 %[[F1]])
; CHECK: ret i32 %[[OUT]]
