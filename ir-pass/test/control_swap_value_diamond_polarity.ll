; control_swap_value_diamond_polarity.ll — ACCEPT spec, SUCCESSOR-SWAPPED value
; diamond (Rule 9 polarity probe), lowered by the CONTROLLED-COPY MERGE (bd
; test_C_libtooling-3qlq Inc 2).
;
; Same value diamond as control_swap_value_diamond.ll, but the chain arm is the
; FALSE successor: `br i1 %c, label %merge, label %arm`, with the merge phi's
; entry-incoming listed FIRST — exactly what `clang -O1` produces for an
; `if (u != k)`-style condition. A lowering that assumed "successor 0 is the
; taken arm" or "phi incoming 0 is the arm value" would merge the WRONG operand
; and miscompile (verify-clean).
;
; ⚠ POLARITY IS NOW EXPRESSED BY OPERAND SLOT, NOT BY AN X BRACKET COUNT. The
; retired route wrapped ALL FOUR cswaps in `cqrt_x` pairs; the controlled-copy
; merge builds `select %c, <true-edge value>, <false-edge value>` instead, so a
; negated arm simply swaps which value is copied first. The DISCRIMINATOR
; against control_swap_value_diamond.ll is therefore the copy ORDER below —
; %p first, the chain value second — and the `cqrt_x` count is IDENTICAL (2) in
; both files. Every CHECK is re-derived from the pass output.
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
  br i1 %c, label %merge, label %arm     ; SWAPPED: chain arm is the FALSE successor
arm:
  %v1 = mul i32 %p, 5
  %v2 = add i32 %v1, 15
  br label %merge
merge:
  %pm = phi i32 [ %p, %entry ], [ %v2, %arm ]   ; entry-incoming FIRST (edge order swapped)
  %m  = call i32 @cq_measure_si32(i32 %pm)
  ret i32 %m
}

; the hoisted arm chain, on the ORIGINAL %p (polarity-independent)
; CHECK:     %[[P:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %v0)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK:     call void @cqrt_addc_i32(i32 %[[V]], i32 15)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; THE POLARITY DISCRIMINATOR: the condition being TRUE selects the STRAIGHT-
; THROUGH %p here (the arm is the FALSE successor), so %p is the FIRST copy and
; the chain value rides the X bracket. In control_swap_value_diamond.ll the two
; are the other way round.
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
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
