; control_predmux_reject_selectform_purecallee_nested.ll — DECLINE
; (bd 3c6m.14.2). ARM: the deleted pure-callee disjunct, at DEPTH.
;
; The outer callee `@leaf` is clean by every clause anyone would write: one call
; and one `mul`, no flags, no undef, no inherent-poison op. Only the INNER callee
; carries the variable shift. `isSpeculatablePureCalleeBodyImpl` recurses through
; inner calls, so the PURITY half passes transitively and the old shielded-cone
; admission accepted the whole thing.
;
; WHY THIS FILE SURVIVED THE CHANGE OF DIRECTION, with its meaning rewritten. In
; the first draft — a definedness proof over the callee body — this pinned the
; RECURSION arm: a proof that checked only the outer body would have answered
; "defined" and the fix would have been one call-frame deep. bd 3c6m.14.2 instead
; DELETED the admission, so the reason is now simpler and stronger: no user
; callee is admitted in a shielded cone at any depth, clean or not. The file is
; kept because depth is exactly where a re-widening would be tempting — the plain
; -O1 `expl -> floorl` / `coshl -> expl` chain that motivated the original
; pure-callee work (bd adia Lever C) IS a clean outer body over an inner one, and
; a future agent will reach for "surely a two-level pure chain is fine". It is
; not fine HERE, in a poison-shielded condition cone. It remains fine at S1, in an
; ARM, which is the surface that shape actually uses
; (lowering_predmux_speccall_flatten.ll).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass \
; RUN:   -passes=cq-lowering -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG
; CHECK: error{{.*}}cq controlled lowering: control flow under quantum control

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner(i32 %a) {
  %x = shl i32 %a, %a           ; the poison lives one frame down
  ret i32 %x
}

define i32 @leaf(i32 %a) {
e:
  %i = call i32 @inner(i32 %a)  ; outer body is clean on its own terms
  %y = mul i32 %i, 3
  ret i32 %y
}

define i32 @probe(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %a = icmp sgt i32 %q, 3
  %r = call i32 @leaf(i32 %q)
  %b = icmp sgt i32 %r, 0
  %sc = select i1 %a, i1 %b, i1 false
  br i1 %sc, label %arm, label %merge

arm:
  %k = add i32 %q, 7
  %k2 = mul i32 %q, 3
  br label %merge

merge:
  %p = phi i32 [ %k, %arm ], [ %q, %entry ]
  %p2 = phi i32 [ %k2, %arm ], [ %q, %entry ]
  %s2 = add i32 %p, %p2
  %m2 = call i32 @cq_measure_si32(i32 %s2)
  ret i32 %m2
}

; DBG: leave @probe entry=entry merge=merge gate=E6-condtree
