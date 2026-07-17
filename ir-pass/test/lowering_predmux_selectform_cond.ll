; lowering_predmux_selectform_cond.ll — ACCEPT (bd adia, 3c6m.55 Lever C):
; PredMux admits clang -O1's POISON-SHIELDED short-circuit condition form —
; `select i1 %a, i1 %b, false` (a && b, the coshl exponent-ladder compound
; `ex < K || (ex == K && mx < M)` lowering) — as an E6 condition tree. The
; flatten canonicalizes it to a plain `and` (the shielded operand's cone is
; poison-flag-stripped first, so the rewrite is basis-state-equivalent) and
; the emitted predicates stay inside the cleared and/or-over-compare-leaves
; flag-mint grammar. The merge phi also carries a DUPLICATE incoming value
; (%q on both non-taken edges) — the chain builder folds the degenerate
; same-arm select (select(EP,x,x) = x) instead of minting an unlowerable
; identity mux.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 5
  %b = icmp slt i32 %q, 100
  %c1 = select i1 %a, i1 %b, i1 false
  br i1 %c1, label %outer, label %merge
outer:
  %c2 = icmp sgt i32 %q, 10
  br i1 %c2, label %inner, label %outmerge
inner:
  %v = add i32 %q, 3
  br label %outmerge
outmerge:
  %p1 = phi i32 [ %v, %inner ], [ %q, %outer ]
  br label %merge
merge:
  %p2 = phi i32 [ %p1, %outmerge ], [ %q, %entry ]
  %m = call i32 @cq_measure_si32(i32 %p2)
  ret i32 %m
}
; The compound flag network mints over the canonicalized and/or tree (a
; toffoli ∧-node network — never a select-of-i1 combinator), pinning BOTH
; leaves — the guard %a AND the SHIELDED %b (a regressed canonicalize that
; dropped the shielded cone would emit only one) — conjoined onto one |0>
; ancilla; the arm value merges through controlled copies; no decline fires.
; CHECK: %[[FA:.*]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[H:.*]], i32 5)
; CHECK: %[[FB:.*]] = call i32 @cq_template_icmp_slt_i32_hl(i32 %[[H]], i32 100)
; CHECK: call void @cqrt_toffoli(i32 %[[FA]], i32 %[[FB]], i32 %[[G:.*]])
; CHECK: call void @cqrt_copy_i32_controlled(
; CHECK: call i32 @cqrt_measure_i32(
