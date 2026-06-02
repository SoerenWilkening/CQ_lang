; lowering_control_multigate_i32.ll — Family A (WP7), the keystone. A tainted
; `if (u > 5) { u = gate(u); v = gate(v); }` arriving from real `clang -O1` as a
; `br`-diamond whose merge carries TWO `φ` — one per gated handle (`u` and `v`).
; Phase-4 core dissolved only the FIRST merge `φ` (`region.Merge =
; &MergeBB->front()`), leaving the second to be spliced mid-block by CFG
; linearization → `PHI nodes not grouped at top of basic block` (a broken
; module). WP7 dissolves EVERY merge `φ` by its `region.Pred`-edge incoming
; value, so BOTH gate handles lower controlled and BOTH `φ` vanish.
;
; Host-agnostic: explicit i32 throughout. Real `-O1` of the two-gate arm keeps
; two `cq_phi` in the guarded block and two `[modified, original]` merge `φ`.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; The tainted `icmp` lowers as the one control flag; BOTH gate bodies lower to
; `cqrt_rz_i32_controlled` on that flag (the second `φ` is no longer leaked).
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: br i1
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %v0) {
entry:
  %u = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %v = call i32 @cq_theta_si32(i32 %v0, double 5.000000e-01)
  %c = icmp sgt i32 %u, 5
  br i1 %c, label %then, label %merge
then:
  %ru = call i32 @cq_phi_si32(i32 %u, double 0.25)   ; gate body 1 (u)
  %rv = call i32 @cq_phi_si32(i32 %v, double 0.75)   ; gate body 2 (v)
  br label %merge
merge:
  %u2 = phi i32 [ %ru, %then ], [ %u, %entry ]       ; [modified, original] (u)
  %v2 = phi i32 [ %rv, %then ], [ %v, %entry ]       ; [modified, original] (v)
  %mu = call i32 @cq_measure_si32(i32 %u2)
  %mv = call i32 @cq_measure_si32(i32 %v2)
  %r = add nsw i32 %mu, %mv
  ret i32 %r
}
