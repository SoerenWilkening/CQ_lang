; Both-arms-handle `select` mux (mux.2) — condition tainted and BOTH value arms
; tainted i32 handles. `-O1` spells `y = (q>0) ? f(q) : g(q);` (both arms depend
; on the quantum `q`) as `select i1 %c, i32 %a, i32 %b` where %a and %b are both
; tainted expressions. The mixed reduction (mux.1) cannot apply — `cqrt_alloc`
; seeds from a CLASSICAL value and here neither arm is classical — and an arm may
; be live elsewhere, so a consuming/in-place strategy is unsafe. Instead copy
; ADDITIVELY into a fresh ancilla, leaving both source handles untouched:
;
;   q > 0   -> cq_template_icmp_sgt_i32_hl(h, 0)              -> flag  (compute)
;   9 - q   -> cq_template_sub_i32_lh(9, h)                   -> hp    (true arm)
;   q + 5   -> cq_template_add_i32_hl(h, 5)                   -> hq    (false arm)
;   (?:)    -> cqrt_alloc_i32(0)                              -> regOut (fresh ancilla)
;           -> cq_template_add_i32_controlled(flag, regOut, hp)   ; regOut += flag·hp
;           -> cqrt_x(flag)                                       ; ¬flag
;           -> cq_template_add_i32_controlled(flag, regOut, hq)   ; regOut += ¬flag·hq
;           -> cqrt_x(flag)                                       ; restore flag
;           -> cq_template_icmp_sgt_i32_hl_inv(h, 0)              (uncompute)
; Result = flag·hp + ¬flag·hq = flag ? hp : hq. Both hp and hq remain referenced
; as the controlled add's b_handle operand (preserved for their other uses).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; The two tainted arm ops lower to their data templates (hp / hq), then the
; both-handle reduction: alloc(0) + a controlled add of hp + the ¬flag cqrt_x
; bracket around a controlled add of hq. Loose SSA patterns (the handle names are
; pass-minted); the load-bearing facts are the alloc(0) seed, the two QQ
; controlled adds with BOTH arm handles as the read addend, and the cqrt_x pair.
; CHECK:     %[[HP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_sub_i32_lh(i32 9, i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     %[[HQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %{{[a-zA-Z0-9_.]+}}, i32 5)
; CHECK:     call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call i32 @cq_template_add_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[HP]])
; CHECK:     call void @cqrt_x(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call i32 @cq_template_add_i32_controlled(i32 %{{[a-zA-Z0-9_.]+}}, i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[HQ]])
; CHECK:     call void @cqrt_x(i32 %{{[a-zA-Z0-9_.]+}})
; CHECK-NOT: select i1
declare i32 @cq_theta_si32(i32, double)
define i32 @example() {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 0
  %a = sub i32 9, %q                      ; tainted true arm  (hp -> sub_i32_lh)
  %b = add i32 %q, 5                      ; tainted false arm (hq -> add_i32_hl)
  %r = select i1 %c, i32 %a, i32 %b       ; both arms tainted handles
  ret i32 %r
}
