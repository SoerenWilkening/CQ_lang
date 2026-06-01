; Classical-arm `select` reduction (WP4) with RUNTIME-VARIABLE arms.
; `if (q>k) y = a; else y = b;` over runtime classical args `%a`/`%b` arrives
; as `select i1 %c, %a, %b`. It reduces identically to the constant case (the
; `_hl` slot has always been a classical-operand slot) — the ONLY difference is
; `%d = A−B` is a real host `sub` rather than a folded literal. The reduction is
; `y = B + flag·(A−B)`: alloc a handle at the false arm B (= %b), then a
; controlled add of the runtime delta %d gated by the flag (arg 0).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     %d = sub i32 %a, %b
; CHECK:     call i32 @cqrt_alloc_i32(i32 %b)
; CHECK:     call i32 @cq_template_add_i32_hl_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %d)
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
define i32 @example(i32 %a, i32 %b) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 0
  %r = select i1 %c, i32 %a, i32 %b      ; [classical, classical], runtime arms
  ret i32 %r
}
