; control_swap_select_shared_root_two_selects.ll — ACCEPT (3c6m.12
; design-review probe): ONE compound condition feeding TWO accepted selects
; (clang -O1 CSEs the `||`). Each select is an independent region whose
; emission memo is PER-REGION (`FlagOf` is local to `emitSelectRegion`), so
; the network mints TWICE — two independent realizations, each with its own
; balanced strip — and the shared `or`/compares survive the FIRST region's
; cascade (still used by the second) and are erased by the SECOND's. Two full
; mint/strip cycles is the sound (if unoptimized) contract; sharing rails
; ACROSS regions would entangle their strips.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %x, i32 %y) {
entry:
  %q    = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c1   = icmp sgt i32 %q, 5
  %c2   = icmp slt i32 %q, 100
  %c    = or i1 %c1, %c2
  %sel1 = select i1 %c, i32 %q, i32 %x
  %sel2 = select i1 %c, i32 %q, i32 %y
  %m1   = call i32 @cq_measure_si32(i32 %sel1)
  %m2   = call i32 @cq_measure_si32(i32 %sel2)
  ret i32 %m1
}

; first region — full network + merge + full strip:
; CHECK:     %[[F1A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl
; CHECK:     %[[F2A:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl
; CHECK:     %[[GA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[F1A]], i32 %[[F2A]], i32 %[[GA]])
; CHECK:     %[[OUT1:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[GA]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT1]])
; CHECK:     call void @cqrt_free(i32 %[[GA]])
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl_inv
; CHECK:     call void @cqrt_free(i32 %[[F2A]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv
; CHECK:     call void @cqrt_free(i32 %[[F1A]])
; second region — an INDEPENDENT re-mint (fresh flags, fresh ancilla):
; CHECK:     %[[F1B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl
; CHECK:     %[[F2B:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_slt_i32_hl
; CHECK:     %[[GB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_toffoli(i32 %[[F1B]], i32 %[[F2B]], i32 %[[GB]])
; CHECK:     %[[OUT2:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[GB]], i32 %{{[a-zA-Z0-9_.]+}}, i32 %[[OUT2]])
; CHECK:     call void @cqrt_free(i32 %[[GB]])
; CHECK:     call i32 @cq_template_icmp_slt_i32_hl_inv
; CHECK:     call void @cqrt_free(i32 %[[F2B]])
; CHECK:     call i32 @cq_template_icmp_sgt_i32_hl_inv
; CHECK:     call void @cqrt_free(i32 %[[F1B]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT1]])
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT2]])
; CHECK-NOT: select i1
; CHECK-NOT: cq_template_or_i1
