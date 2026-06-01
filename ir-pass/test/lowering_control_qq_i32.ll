; lowering_control_qq_i32.ll — WP6 Q+Q control condition (PRD §2.4, §5.2,
; IMPLEMENTATION §6). A tainted `if (q1 < q2)` arriving from `clang -O1` as a
; `br`-diamond + `φ[modified, original]` whose condition is `icmp slt i32 %h1,
; %h2` (BOTH operands tainted handles). Phase 3 BAILED on Q+Q compares — the
; logical width is unrecoverable from two i32-laundered handles. WP6 recovers it
; from the `HandleWidth` side-table (recorded at the rotation mint, §5.6) and
; passes it as `qqWidth`, so the control flag is the HH template
; `cq_template_icmp_slt_i32(h1, h2)` (no `_hl`). The in-shadow gate body lowers
; controlled, the merge `φ` dissolves to the in-place handle, the diamond
; linearizes, and the flag is uncomputed by the QQ `_inv` twin
; `cq_template_icmp_slt_i32_inv(h1, h2)` (§1.5). No `br i1`, no `phi` survive.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_icmp_slt_i32(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; Next line is the flag uncompute (§1.5): the QQ `_inv` twin of the forward
; HH compare template (compares the carry `inv_qq`).
; CHECK:     call i32 @cq_template_icmp_slt_i32_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: br i1
; CHECK-NOT: = phi
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example() {
entry:
  %q1 = call i32 @cq_theta_si32(i32 1, double 0.5)
  %q2 = call i32 @cq_theta_si32(i32 2, double 0.5)
  %c  = icmp slt i32 %q1, %q2
  br i1 %c, label %t, label %m
t:
  %ry = call i32 @cq_phi_si32(i32 %q1, double 0.25)
  br label %m
m:
  %r = phi i32 [ %ry, %t ], [ %q1, %entry ]
  ret i32 %r
}
