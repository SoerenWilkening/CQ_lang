; lowering_control_or_i32.ll — WP5 compound `||` (PRD §2.5, IMPLEMENTATION
; §5.3). A tainted `if (q > k1 || q < k2) y = gate(y);` arrives from real
; `clang -O1` as the short-circuit OR idiom `select i1 %fa, i1 true, i1 %fb`
; feeding a `br`-diamond + `φ`. Like `&&` it combines two flags into one wire,
; but via De Morgan (`a||b = ¬(¬a ∧ ¬b)`): X-bracket the inputs and output
; around one `cqrt_toffoli` into a fresh `cqrt_alloc_i1(0)` ancilla. The
; X-bracket on fa/fb RESTORES them (so the sub-flags stay clean for their own
; uncompute); the single X on f turns the AND into the OR. The uncompute is the
; exact mirror image of the compute (§1.5): the reversed X-bracket + the
; `cqrt_toffoli_inv`, then each sub-flag's compare `_inv`. No `br i1`, `phi`,
; `select i1` survives; the alloc + X-bracket balance (verify-clean).
;
; Host-agnostic: explicit i32 throughout.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; The two sub-compares lower to HL flags (the compound's inputs):
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 100)
; Fresh combined-flag ancilla, then the De Morgan compute: X(fa); X(fb);
; toffoli(fa,fb,f); X(f); X(fa); X(fb) (§2.5). The ordered CHECK lines pin it.
; CHECK:     call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_x(i32 %[[FA:[a-zA-Z0-9_.]+]])
; CHECK:     call void @cqrt_x(i32 %[[FB:[a-zA-Z0-9_.]+]])
; CHECK:     call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[F:[a-zA-Z0-9_.]+]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_x(i32 %[[FA]])
; CHECK:     call void @cqrt_x(i32 %[[FB]])
; The gate body, single-controlled by the ONE combined flag (§1.2):
; CHECK:     call void @cqrt_rz_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, double {{.*}})
; Uncompute — the mirror image, in reverse: X(fb); X(fa); X(f); toffoli_inv;
; X(fb); X(fa); then the two compare `_inv`s (§1.5):
; CHECK:     call void @cqrt_x(i32 %[[FB]])
; CHECK:     call void @cqrt_x(i32 %[[FA]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_toffoli_inv(i32 %[[FA]], i32 %[[FB]], i32 %[[F]])
; CHECK:     call void @cqrt_x(i32 %[[FB]])
; CHECK:     call void @cqrt_x(i32 %[[FA]])
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 100)
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
;
; CHECK-NOT: br i1
; CHECK-NOT: = phi
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
define i32 @example(i32 %y0) {
entry:
  %y = call i32 @cq_theta_si32(i32 %y0, double 5.000000e-01)
  %fa = icmp sgt i32 %y, 5
  %fb = icmp slt i32 %y, 100
  %or = select i1 %fa, i1 true, i1 %fb
  br i1 %or, label %then, label %merge
then:
  %ry = call i32 @cq_phi_si32(i32 %y, double 0.25)
  br label %merge
merge:
  %r = phi i32 [ %ry, %then ], [ %y, %entry ]
  ret i32 %r
}
