; control_predmux_accept_i80_cmp_purecallee_clonecall.ll — ACCEPT (bd 3c6m.14.1).
;
; SURFACE S2 — E4's CALL admission running in CLONE mode (`ClaimAll`, threaded
; from Specialization.cpp's lowerCloneControl). This is the back door the ticket
; told us to MEASURE rather than reason about, and measuring is what this fixture
; is: `recoverRegion` runs in two contexts, but the CALL-admission line has no
; `ClaimAll` gate at all — unlike the bare-compare line one screen below it — so
; widening the pure-callee proof reaches clone mode whether or not anyone
; intended it. It was measured reachable on a pinned pre-change plugin BEFORE the
; change was designed: this exact module printed
;   CQ_PREDMUX_DBG: pure-callee inner fails at:   %eq = icmp eq i80 %m, 555
;   CQ_PREDMUX_DBG: leave @__cq_q_mid_1 entry=entry merge=merge gate=E4-dataflow
;   error: ... cq specialization: callee contains tainted control flow under quantum lift
; i.e. the only thing standing between clone mode and this shape was the proof.
;
; IT IS DELIBERATELY WIDENED, NOT FENCED, and the reason is visible in the output
; below: `@__cq_q_mid_1` — the clone whose region is being flattened — contains
; the CALL and nothing else from `@inner`. The i80 compare is in
; `@__cq_q_inner_1`, the transitively-specialized inner clone, straight-line.
; So the outer walk's top-level/clone context is causally unrelated to how that
; compare is lowered, and a `!ClaimAll` here would have been a fence with no
; correctness content. What DOES still bite is the fence where the compare lives:
; see control_predmux_reject_i80_cmp_purecallee_armdiamond.ll.
;
; This does NOT lift the bare-compare clone-mode fence.
; control_predmux_reject_i80_cmp_clonemode.ll — whose `@leaf` is this same
; function with the compare INLINE in a tainted arm instead of outlined — still
; declines, with a byte-identical message and DBG leave line. That pair is the
; boundary evidence for the decision, and neither half may be edited alone.
;
; The shape is the judge's Inc-7 probe with the compare outlined: an i32
; parameter (no fp80 anywhere), i80 reached through the in-grid `zext i32 -> i80`
; rather than a `bitcast f80->i80`, and a callee carrying its own tainted diamond.
; NB `@inner`/`@mid` are external for consistency with the clonemode fixture this
; one is paired against. Unlike there, that is NOT load-bearing here: a Rule-13
; lens checked, and this module still splits correctly with `internal` on both
; defines. (The clonemode fixture's constraint is `internal` PLUS a select in the
; arm; this module has no select in the arm.) Do not copy its NB forward as if it
; applied.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: env CQ_PREDMUX_DBG=1 %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG --allow-empty

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner(i32 %a) {
e:
  %z = zext i32 %a to i80                 ; in-grid widen — no fp80 involved
  %m = and i80 %z, 4294967295
  %eq = icmp eq i80 %m, 555               ; exactly one ConstantInt ⇒ provably _hl
  %w = zext i1 %eq to i32
  ret i32 %w
}

define i32 @mid(i32 %a) {
entry:
  %c = icmp sgt i32 %a, 5
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @inner(i32 %a)
  br label %merge

merge:
  %p = phi i32 [ %r, %arm ], [ 33, %entry ]
  ret i32 %p
}

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %v = call i32 @mid(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; ---------------------------------------------------------------------------
; The OUTER clone. Its region flattened (no `br i1`, no `phi` — asserted
; positionally by CHECK-NOT between the label and the return, not by an
; --implicit-check-not that the untouched classical `@mid` above would trip).
; The call was speculated to the top of the clone; the diamond became a
; controlled-copy merge. THE COMPARE IS NOT HERE.
; ---------------------------------------------------------------------------
; CHECK-LABEL: define internal i32 @__cq_q_mid_1(i32 %a)
; CHECK-NEXT:  entry:
; CHECK-NEXT:    %[[R:[a-zA-Z0-9_.]+]] = call i32 @__cq_q_inner_1(i32 %a)
; CHECK-NEXT:    %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %a, i32 5)
; CHECK-NEXT:    %[[SEL:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK-NEXT:    call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[R]], i32 %[[SEL]])
; CHECK-NEXT:    call void @cqrt_x(i32 %[[F]])
; CHECK-NEXT:    %[[C33:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 33)
; CHECK-NEXT:    call void @cqrt_copy_i32_controlled(i32 %[[F]], i32 %[[C33]], i32 %[[SEL]])
; CHECK-NOT:     br i1
; CHECK-NOT:     phi
; CHECK:         call void @__cq_q_inner_1_unc(i32 %[[R]], i32 %a)
; CHECK:         ret i32

; ---------------------------------------------------------------------------
; The INNER clone — where the i80 compare landed, straight-line, on the frozen
; §6.0 grid. The mask is load-bearing (the compare must read the MASKED word).
; ---------------------------------------------------------------------------
; CHECK-LABEL: define internal i32 @__cq_q_inner_1(i32 %a)
; CHECK:         %[[Z:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i32_to_i80(i32 %a)
; CHECK:         %[[M:[a-zA-Z0-9_.]+]] = call i32 @cq_template_and_i80_hl(i32 %[[Z]], i80 4294967295)
; CHECK:         %[[EQ:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i80_hl(i32 %[[M]], i80 555)
; CHECK:         call void @cq_template_icmp_eq_i80_hl_unc(i32 %[[EQ]], i32 %[[M]], i80 555)
; CHECK:         call void @cq_template_and_i80_hl_unc(i32 %[[M]], i32 %[[Z]], i80 4294967295)
; CHECK:         call void @cqrt_free(i32 %[[EQ]])

; The Bennett uncompute twin recomputes the SAME chain from the SAME operands.
; CHECK-LABEL: define internal void @__cq_q_inner_1_unc(i32 %out, i32 %a)
; CHECK:         call i32 @cq_template_icmp_eq_i80_hl(i32 %{{[a-zA-Z0-9_.]+}}, i80 555)

; Red-green: on the pre-change plugin BOTH of these lines were printed. Their
; absence is the assertion (and it splits — see the header transcript).
; DBG-NOT: pure-callee inner fails
; DBG-NOT: leave @__cq_q_mid_1
