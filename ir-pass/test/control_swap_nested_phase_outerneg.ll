; control_swap_nested_phase_outerneg.ll — ACCEPT spec (§5g polarity probe): outer arm is the FALSE successor (inner positive).
;
; The §0 depth-2 phase nest with the OUTER gate arm negated. clang -O1 swaps a branch's successors for an
; ordering condition (Rule 9), making the gate arm the FALSE successor; detection
; resolves arms by merge-phi incoming IDENTITY (never successor order) and the
; emitter routes the negated level on ¬flag via a self-inverse cqrt_x bracket
; around BOTH route-in and route-back (the adjoint of the split). The flag-strip
; is polarity-independent (Rz preserves q's basis).
;
; WI-3 lands NestedRouteEmit — recognized as the accept shape, now LOWERS to
; the per-polarity routed stream (XFAIL removed at WI-3 XPASS).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %merge, label %mid
mid:
  %g  = call i32 @cq_phi_si32(i32 %q, double %b)
  %c2 = icmp slt i32 %g, 9
  br i1 %c2, label %arm, label %merge
arm:
  %h  = call i32 @cq_phi_si32(i32 %g, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q, %entry ], [ %g, %mid ], [ %h, %arm ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}
; Structural markers (the full per-polarity stream is fleshed out in WI-3).
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{.*}}, i32 5)
; CHECK:     call void @cqrt_cswap(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{.*}})
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: phi i32
