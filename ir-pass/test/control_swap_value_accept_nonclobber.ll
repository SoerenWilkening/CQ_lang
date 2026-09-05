; control_swap_value_accept_nonclobber.ll — ACCEPT: single-link value arm on a
; NON-condition register (the §3c contrast witness), lowered by the
; CONTROLLED-COPY MERGE (bd test_C_libtooling-3qlq Inc 2).
;
; Contrast partner of control_swap_reject_clobber.ll and
; control_swap_value_reject_clobber_active.ll: the arm value-changes a quantum
; variable %p that the condition does NOT read (the condition reads %q). The
; diamond's straight-through (Pred-edge) incoming is %p, which is NOT in the
; condition's taint provenance — `if(q>5){p=p+3}` ACCEPTS while the §3c clobber
; `if(q>5){q=q+3}` permanently rejects. A wrong §3c reject here would be a
; false positive conflating "rewrites a NON-condition var" with the §3c bind.
;
; ⚠ THE §3c DECLINE IS UNCHANGED BY Inc 2 AND IS STILL LOAD-BEARING. Under the
; retired route the clobber hazard was that the route swapped the condition's
; own register; under the hoist it is that the chain runs UNCONDITIONALLY on the
; original register, so an arm that rewrote a condition operand would make the
; `icmp_inv` strip read a different basis value than the mint did. Same decline,
; different mechanism — see retire-swap-route-PRD §7.3.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=FCNT < %t.cqd0.ll
; CCNT added by the Inc-2 round-1 review (finding F-V2-6): without it a
; DUPLICATED merge copy — `out` XORed twice, i.e. the identity on that branch —
; passed this file.
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
  %p1 = add i32 %p, 3        ; value op on a NON-condition quantum var (%p, not %q)
  br label %merge
merge:
  %pm = phi i32 [ %p1, %arm ], [ %p, %entry ]
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
; the hoisted single-link chain on the NON-condition register %p
; CHECK-NEXT: %[[V:[a-zA-Z0-9_.]+]] = call i32 @cq_template_add_i32_hl(i32 %[[P]], i32 3)
; CHECK-NEXT: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q]], i32 5)
; CHECK-NEXT: %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[V]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[P]], i32 %[[OUT]])
; CHECK-NEXT: call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
; CHECK-NEXT: %[[M:[a-zA-Z0-9_.]+]] = call i32 @cqrt_measure_i32(i32 %[[OUT]])

; the §3c string must never fire on a non-condition-register write, and no route
; survives anywhere.
; NOROUTE-NOT: arm rewrites a condition operand
; NOROUTE-NOT: under quantum control
; NOROUTE-NOT: cqrt_cswap
; NOROUTE-NOT: call void @cqrt_copy_i32(
; NOROUTE-NOT: phi i32

; EXACTLY ONE free — the flag. %out and the source %p are never freed.
; FCNT-COUNT-1: call void @cqrt_free(
; FCNT-NOT:     call void @cqrt_free(
; EXACTLY TWO controlled copies — the whole merge.
; CCNT-COUNT-2: call void @cqrt_copy_i32_controlled(
; CCNT-NOT:     call void @cqrt_copy_i32_controlled(
