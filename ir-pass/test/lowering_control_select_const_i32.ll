; Classical-arm `select` reduction (WP4), the documented §6 example.
; `-O1` spells `if (q>k) y = A; else y = B;` (both arms CLASSICAL constants)
; as `select i1 %c, A, B` — a single-block select, no CFG diamond. WP4
; reduces it to `y = B + flag·(A−B)` via the controlled add template: the
; host difference `%d = A−B` (here a folded literal `-10`), `cqrt_alloc_<W>(B)`,
; then `cq_template_add_<W>_hl_controlled(flag, regB, %d)`. The flag is the
; lowered tainted condition.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cqrt_alloc_i32(i32 20)
; CHECK:     call i32 @cq_template_add_i32_hl_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 -10)
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 0
  %r = select i1 %c, i32 10, i32 20      ; [classical, classical]
  ret i32 %r
}
