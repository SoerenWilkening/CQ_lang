; control_swap_select_operand_measured.ll — ACCEPT probe (test_C_libtooling-2aqe):
; a tainted-condition integer-data `select` whose tainted value operand `%q` is ALSO
; measured directly downstream (`%md = cq_measure(%q)`). GATE 5's coherent-operand
; walk (`hasCoherentDownstreamUse`, SelectClassify.cpp) finds NO downstream rotation
; on `%q`'s wire — only a recognized measurement sink, which OWNS the handle — so the
; operand is not a coherent carrier and the select ACCEPTS via the controlled-XOR copy
; merge.
;
; This pins the GATE-5 measure-allowance ACCEPT under the EXACT-MEMBERSHIP check
; (`taint.MeasureCalls`, hardened from a `starts_with("cq_measure_")` prefix match that
; also matched the dead `cqrt_measure_` runtime prefix). The operand is always tainted,
; so a spoof `cq_measure_evil` is already pre-filtered by `declineTaintEscapes` — the
; exact check is consistency + defense-in-depth. A mis-wired membership set would
; mistakenly treat the measured operand as coherent and DECLINE — caught here.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %cq-opt -passes=verify -disable-output - < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CNT < %t.cqd0.ll
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s --check-prefix=ACC
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %u0, i32 %x) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, i32 %q, i32 %x
  %m   = call i32 @cq_measure_si32(i32 %sel)
  %md  = call i32 @cq_measure_si32(i32 %q)   ; OWNED: the value operand is measured
  ret i32 %md
}

; flag mint, |0> rail, two controlled copies (¬flag x-bracketed), strip, free:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; the merged result AND the directly-measured operand are both measured:
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[Q]])

; exactly TWO controlled copies, ONE flag free (no spurious uncompute of the live rail):
; CNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CNT-NOT:     call void @cqrt_copy_i32_controlled(
; CNT-COUNT-1: call void @cqrt_free(
; CNT-NOT:     call void @cqrt_free(

; ACCEPTS (no decline):
; ACC-NOT: under quantum control
