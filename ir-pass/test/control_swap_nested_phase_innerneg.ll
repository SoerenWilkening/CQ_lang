; control_swap_nested_phase_innerneg.ll — ACCEPT spec (§5g polarity probe): inner arm is the FALSE successor (outer positive).
;
; The §0 depth-2 phase nest with the INNER gate arm negated. clang -O1 swaps a branch's successors for an
; ordering condition (Rule 9), making the gate arm the FALSE successor; detection
; resolves arms by merge-phi incoming IDENTITY (never successor order) and the
; emitter routes the negated level on ¬flag via a self-inverse cqrt_x bracket
; around BOTH route-in and route-back (the adjoint of the split). The flag-strip
; is polarity-independent (Rz preserves q's basis).
;
; WI-3 lands NestedRouteEmit — recognized as the accept shape, now LOWERS to
; the per-polarity routed stream (XFAIL removed at WI-3 XPASS).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, double %a, double %b) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  call void @cq_phi(double %b)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %merge, label %arm
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
; Structural markers (the full per-polarity stream is fleshed out in WI-3).
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{.*}}, i32 5)
; CHECK:     call void @cqrt_cswap(i32 %{{.*}}, i32 %{{.*}}, i32 %{{.*}})
; CHECK:     call i32 @cqrt_measure_i32(i32 %{{.*}})
; CHECK-NOT: _controlled
; CHECK-NOT: cqrt_toffoli
; CHECK-NOT: phi i32
