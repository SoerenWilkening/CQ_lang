; spec_accept_diamond_nested_compound.ll — Phase 6 / issue 5po2 I2: a DEPTH-2
; NESTED value diamond `helper(b) = c1 ? (c2 ? b+2 : b+1) : b+3` now LIFTS. PredMux
; flattens it to a `select` whose inner condition is a COMPOUND boolean `c1 ∧ ¬c2`
; (a `cqrt_toffoli` conjunction of two `cq_template_icmp` leaf flags);
; `lowerCloneSelect` mints that condition NETWORK forward-only (leaf flags LIVE +
; the toffoli), gates the 4.4 controlled-XOR muxes on the root flag, and the
; Bennett wrap plays the single LIFO reverse — copy⁻¹, the self-inverse
; `cqrt_toffoli`, then the leaf `icmp _unc`s — before freeing every proven-|0⟩ rail
; (the i1 ancilla included). This was the I1 decline fixture
; `spec_reject_diamond_nested_compound.ll`, flipped to accept when I2 added the
; compound-condition network mint. All arms are derived (no materialization).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @helper(i32 %b) {
entry:
  %r0 = add i32 %b, 3
  %c1 = icmp sgt i32 %b, 5
  br i1 %c1, label %outer, label %merge
outer:
  %r1 = add i32 %b, 1
  %c2 = icmp slt i32 %b, 9
  br i1 %c2, label %inner, label %merge
inner:
  %r2 = add i32 %b, 2
  br label %merge
merge:
  %rm = phi i32 [ %r0, %entry ], [ %r1, %outer ], [ %r2, %inner ]
  ret i32 %rm
}

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @helper(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %r)
  ret i32 %m
}

; CHECK: define internal i32 @__cq_q_helper_1(i32 %b)
; the compound inner condition `c1 ∧ ¬c2` mints two leaf flags + a toffoli onto a
; |0> i1 ancilla, forward-only (kept LIVE — no local strip):
; CHECK: %h_cmp = call i32 @cq_template_icmp_sgt_i32_hl(i32 %b, i32 5)
; CHECK: %h_cmp1 = call i32 @cq_template_icmp_sge_i32_hl(i32 %b, i32 9)
; CHECK: %cqq.g = call i32 @cqrt_alloc_i1(i1 false)
; CHECK: call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %cqq.g)
; CHECK: call void @cqrt_copy_i32_controlled(i32 %cqq.g,
; the single Bennett reverse plays the self-inverse toffoli + leaf `_unc`s:
; CHECK: call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %cqq.g)
; CHECK: call void @cq_template_icmp_sge_i32_hl_unc(i32 %h_cmp1, i32 %b, i32 9)
; CHECK: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp, i32 %b, i32 5)
; the i1 ancilla is a proven-|0> rail, freed:
; CHECK: call void @cqrt_free(i32 %cqq.g)
; CHECK: ret i32 %cqq.out
