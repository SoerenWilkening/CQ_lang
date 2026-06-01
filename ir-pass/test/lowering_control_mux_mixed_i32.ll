; Mixed-arm `select` mux (mux.1) — ONE tainted arm, one classical arm. `-O1`
; spells `y = (q>0) ? f(q) : C;` (the true arm is a tainted expression, the
; false arm a classical constant) as `select i1 %c, i32 %t, i32 -3`. Unlike
; the WP4 [classical,classical] reduction (a host `sub` + `_hl_controlled`),
; the difference here straddles a quantum handle, so it is built with the
; UNCONTROLLED data template `sub_i32_hl(Qhandle, Cclassical)` and the add is
; the Shape::QQ controlled form `cq_template_add_i32_controlled` (both addends
; handles — bare `_controlled`, no `_hl` infix).
;
; Convention pinned (the primary CONSTRUCTION): Q is the TRUE arm and ctrl is
; the flag itself, so `C + flag·(Q−C) = flag ? Q : C` matches `select %c, Q, C`
; — no `cqrt_x` flag bracket (that is only the Q-as-FALSE-arm variant).
; Reduction:
;   q > 0   -> cq_template_icmp_sgt_i32_hl(h, 0)          -> flag   (compute)
;   12 - q  -> cq_template_sub_i32_lh(9, h)               -> Q      (tainted arm)
;   (?:)    -> cq_template_sub_i32_hl(Q, -3)              -> delta  (Q − C)
;           -> cqrt_alloc_i32(-3)                         -> regC   (classical arm)
;           -> cq_template_add_i32_controlled(flag, regC, delta)    (Shape::QQ)
;           -> cq_template_icmp_sgt_i32_hl_inv(h, 0)               (uncompute)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     call i32 @cq_template_sub_i32_lh(i32 9, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_sub_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 -3)
; CHECK:     call i32 @cqrt_alloc_i32(i32 -3)
; CHECK:     call i32 @cq_template_add_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: select i1
; CHECK-NOT: cqrt_x
declare i32 @cq_theta_si32(i32, double)
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 0
  %t = sub i32 9, %q                      ; tainted true arm (-> sub_i32_lh)
  %r = select i1 %c, i32 %t, i32 -3       ; mixed: true tainted, false classical
  ret i32 %r
}
