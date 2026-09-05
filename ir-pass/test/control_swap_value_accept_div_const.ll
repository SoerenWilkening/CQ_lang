; control_swap_value_accept_div_const.ll — ACCEPT: the DISCRIMINATOR for the
; Inc-2 speculation-totality fence (bd test_C_libtooling-3qlq Inc 2).
;
; `if (q > 5) { p = p*5; p = p/3; }` — the same division opcode family that
; control_swap_value_reject_speculation.ll declines, but with a NON-ZERO CONSTANT
; divisor, which `isSafeToSpeculativelyExecute` admits. Without this file the
; fence would be indistinguishable from "decline every div/rem in a value arm",
; and the next reader would have no way to tell which of the two it is.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; Exact counts, one symbol per prefix (a positive COUNT windows every negative
; after it — the bd drbq Inc-4 lens), added by the Inc-2 round-1 review: without
; them a DUPLICATED merge copy (`out` XORed twice = the identity on that branch)
; and a DROPPED chain `_unc`/rail free both passed this file (finding F-V2-6).
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
  %v2 = udiv i32 %v1, 3             ; non-zero CONSTANT divisor — speculatable
  br label %merge
merge:
  %pm = phi i32 [ %v2, %arm ], [ %p, %entry ]
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
; the hoisted chain, division included: `p*5` then `/3` by a NON-ZERO CONSTANT,
; which `isSafeToSpeculativelyExecute` admits — the discriminator that says the
; totality fence is not "decline every div in a value arm".
; CHECK-NEXT: %[[T:[a-zA-Z0-9_.]+]] = call i32 @cq_template_mul_i32_hl(i32 %[[P]], i32 5)
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_udiv_i32_hl(i32 %[[T]], i32 3)
; the chain INTERMEDIATE is `_unc`'d and freed by the whole-DAG spine. Both
; lines are pinned, and adjacently: dropping either one was invisible to this
; fixture before the round-1 review (finding F-V2-6).
; CHECK-NEXT: call void @cq_template_mul_i32_hl_unc(i32 %[[T]], i32 %[[P]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[T]])
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; ⚠ THE STRIP, PINNED IMMEDIATELY BEFORE THE FREE. This file used to pin the
; free alone, so `M9 drop the flag strip` — a DIRTY FREE, i.e. a hidden
; measurement that collapses q (Rule 6) — passed every prefix (measured,
; round-1 review F-V2-6). It is the most physically meaningful line here.
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: under quantum control
; NOROUTE-NOT: phi i32

; EXACTLY TWO frees: the chain intermediate `p*5` and the flag. `%out`, the
; source `%p` and the chain FINAL (`p*5/3`) are left ALLOCATED (Rule 6 tolerates
; a leaked rail; a free of any of them would be a hidden measurement).
; FCNT-COUNT-2: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY TWO controlled copies — the whole merge.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
