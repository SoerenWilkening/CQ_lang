; lowering_control_gate_br_i32.ll — WP3 headline shape (IMPLEMENTATION §6,
; PRD §2.2/§2.6/§2.10/§2.11). A tainted `if (q > k) y = gate(y);` arriving
; from real `clang -O1` as a `br`-diamond + `φ[modified, original]` lowers to
; a controlled rotation: the tainted `icmp` condition lowers as the control
; FLAG (`cq_template_icmp_sgt_i32_hl`), the in-shadow gate body `cq_phi`
; lowers to `cqrt_rz_i32_controlled(flag, h, θ)`, the merge `φ` dissolves to
; the in-place handle `y`, the diamond linearizes to a single block, and the
; flag is uncomputed by the compare template's `_inv` twin (§1.5). No `br i1`,
; no `phi`, no `br i32` ever; the second RUN line is the standing `verify`
; guard for the cross-type flag RAUW (§1.6).
;
; Host-agnostic: explicit i32 throughout (no `long`/host-width types — the
; Darwin-LP64 `long` gotcha does not apply).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; Next line is the flag uncompute (§1.5): the `_inv` twin of the forward
; compare template. The whole rest of a directive line is the match pattern,
; so the human annotation lives here on its own comment line, not inline.
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK-NOT: br i1
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example(i32 %y0) {
entry:
  %y = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %c = icmp sgt i32 %y, 5
  br i1 %c, label %then, label %merge
then:
  %ry = call i32 @cq_phi_si32(i32 %y, double 0.25)   ; in-shadow gate body
  br label %merge
merge:
  %r = phi i32 [ %ry, %then ], [ %y, %entry ]        ; [modified, original]
  ret i32 %r
}
