; control_swap_value_ifelse.ll — ACCEPT spec, symmetric TWO-ARM value if/else,
; lowered by the CONTROLLED-COPY MERGE (bd test_C_libtooling-3qlq Inc 2,
; retire-swap-route-PRD §7.2 shape V2).
;
; `if (q > 5) p = p+3; else p = p*7;` — BOTH arms carry a pure value chain over
; the same base %p (base-identity, proven by classifyArms). BOTH chains are now
; HOISTED into the pred and run unconditionally; the merge is
; `out ^= f . R1(p)` then, X-bracketed, `out ^= (not f) . R2(p)`.
;
; ⚠ THIS FIXTURE PINNED THE RETIRED SWAP ROUTE UNTIL 3qlq Inc 2 (two work rails,
; eight cswaps, an uncontrolled copy-out and two reverse-plays). Every CHECK is
; re-derived from the pass output, never hand-edited.
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
  br i1 %c, label %then, label %else
then:
  %vt = add i32 %p, 3
  br label %merge
else:
  %ve = mul i32 %p, 7
  br label %merge
merge:
  %pm = phi i32 [ %vt, %then ], [ %ve, %else ]
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; THE WHOLE REGION STREAM, CONTIGUOUS. `CHECK-NEXT` adjacency from the first
; alloc to the measure is the contract here, not decoration (bd
; test_C_libtooling-3qlq Inc 2, Rule-13 round-1 review finding F-V2-5): the
; re-derivation that first shipped this file used bare positional directives
; throughout, and a stray gate spliced between two pinned lines — a
; `cqrt_ry_i32` immediately before the first controlled copy — then passed
; EVERY prefix. Symbol ORDER cannot see an insertion; adjacency can.
; CHECK:      %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[Q]], double 5.000000e-01)
; CHECK-NEXT: %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[P]], double 2.500000e-01)
; both hoisted chains, on the ORIGINAL %p, in arm order (TRUE arm first). Both
; heads are OUT OF PLACE — the property the merge's two-distinct-copy-sources
; argument rests on (round-1 F-V1-5; the tripwire fixture is
; control_swap_value_ifelse_head_out_of_place.ll).
; CHECK-NEXT: %[[VT:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 3)
; CHECK-NEXT: %[[VF:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 7)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; the TRUE arm on the flag, the FALSE arm on the X bracket — %p itself is
; copied NOWHERE (unlike the diamond: an if/else has no straight-through edge)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[VT]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[VF]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

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
