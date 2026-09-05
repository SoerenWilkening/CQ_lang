; control_swap_value_diamond.ll — ACCEPT spec, linear-HL-chain VALUE diamond
; lowered by the CONTROLLED-COPY MERGE (bd test_C_libtooling-3qlq Inc 2,
; retire-swap-route-PRD §7; symbol order IS the contract).
;
; `if (q > 5) { p = p*5; p = p+15; }` — a pure linear value chain over the
; straight-through %p, disjoint from the condition's provenance.
;
; ⚠ THIS FIXTURE PINNED THE RETIRED SWAP ROUTE UNTIL 3qlq Inc 2. The old stream
; was `mint -> alloc rail -> cswap route-in -> chain on the rail -> cswap
; route-back -> alloc out -> cqrt_copy_i32(p,out) -> cswap -> chain _unc ->
; cswap -> free rail -> strip -> free flag` (4 cswap = 4W Toffoli + 8W CNOT and
; one W-bit work rail). The stream below is the replacement: the arm's chain is
; HOISTED into the pred and runs UNCONDITIONALLY on the ORIGINAL %p (which the
; route also did, on a |0> rail), and the merge is the 4.4 controlled-XOR copy
; pair. Every CHECK is re-derived from the pass output, never hand-edited.
;
; The stream: chain on %p (ordinary tainted arithmetic, lowered by `lowerOps` —
; note `cqrt_addc_i32` for the second link, the M-C IN-PLACE conversion, which
; fires on the FRESH intermediate rail and NEVER on %p because %p has a later
; reader) -> flag mint -> |0> %out -> copy_controlled(f, armvalue, out) ->
; cqrt_x -> copy_controlled(f, p, out) -> cqrt_x -> icmp_inv strip -> ONE free.
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; Whole-file PURE-NEGATIVE scan (bd drbq Inc-4 lens: a positive COUNT directive
; inside a prefix WINDOWS every negative after it, so the negatives live alone).
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact counts, one symbol per prefix for the same windowing reason.
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=CCNT < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %v0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %p = call i32 @cq_theta_si32(i32 %v0, double 2.500000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; the hoisted arm chain, on the ORIGINAL %p, lowered by lowerOps
; CHECK:     %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK:     call void @cqrt_addc_i32(i32 %[[V]], i32 15)
; 1: mint the flag from the tainted compare
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; 2: the |0> merge out-rail (the ONLY alloc(0) — no work rail exists any more)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; 3: out ^= f . armvalue
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; 4: out ^= (not f) . p — the bracket encloses ONLY the second copy (the §16.3
;    hazard: an x before BOTH copies has the same symbol multiset and writes
;    both values on one basis branch)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; 5: strip the boolean + reclaim the flag
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; the merge phi RAUWs to %out — the measure reads the merged answer
; CHECK:     call i32 @cqrt_measure_i32(i32 %[[OUT]])

; No route survives anywhere in the module: the swap route is RETIRED for value
; arms (bd test_C_libtooling-3qlq Inc 2), there is no work rail, and no
; uncontrolled basis copy — the merge is the two CONTROLLED copies alone.
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i32(
; NOROUTE-NOT: phi i32
; NOROUTE-NOT: call i32 @cq_theta
; NOROUTE-NOT: call i32 @cq_phi
; NOROUTE-NOT: cqrt_free(i32 %out)

; EXACTLY ONE free in the whole module — the flag. `%out`, the source `%p` and
; the hoisted chain's final rail are all left ALLOCATED (keep-source-live: a
; free of any of them is a hidden measurement, Rule 6/8).
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY TWO controlled copies — the whole merge.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
