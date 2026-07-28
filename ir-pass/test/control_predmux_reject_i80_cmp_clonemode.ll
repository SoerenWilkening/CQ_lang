; control_predmux_reject_i80_cmp_clonemode.ll — DECLINE (bd 3c6m.61): the SECOND
; scope fence on the Inc-7 widening, and the one the Rule-13 JUDGE had to find
; because a lens had graded this shape unreachable.
;
; `recoverRegion` runs in TWO contexts: the top-level region flatten and the
; `ClaimAll` Bennett-CLONE body flatten (threaded from Specialization.cpp). So a
; bare `AdmitI80Compare=true` at the E4 body walk is live in BOTH. Only the
; top-level context is this increment's target and only it has an i80 fixture
; family, so the flag is passed as `!ClaimAll` and clone mode keeps the old
; blanket exclusion.
;
; THIS IS THE JUDGE'S PROBE, VERBATIM, and it is a genuine red-green: it evades,
; simultaneously, all three fences an earlier comment claimed made clone mode
; unreachable — NO fp80 anywhere (an i32 parameter, so nothing is laundered from
; an fp80 handle), i80 reached through the in-grid `zext i32 -> i80` rather than
; a `bitcast f80->i80`, and a callee carrying its OWN tainted diamond. Measured
; against a plugin with the fence removed:
;     exit 0 · 4 `cq_template_icmp_eq_i80*` symbols · 1 Bennett clone
;     `define internal i32 @__cq_q_leaf_1(i32 %a)` carrying the compare and its
;     `_unc` adjoint — verify-clean, free-pairing 6/6, links and runs.
; The judge audited that emission and found it SOUND. So this is a SCOPE
; decision, not a correctness one: it is a new accept surface in the Phase-6
; clone + Bennett-wrap path rather than the reviewed select substrate, and
; Rule 12 wants its own probe family first (bd 3c6m.14.1).
;
; NB the callee is deliberately NOT `internal` and the merge is a plain
; 2-incoming phi with a constant incoming — with `internal` linkage plus a
; select in the arm, SpecializeReject declines BEFORE the clone is ever built
; and the fixture would pin nothing. The shape is load-bearing; do not "tidy" it.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @leaf(i32 %a) {
entry:
  %c = icmp sgt i32 %a, 5
  br i1 %c, label %arm, label %merge

arm:
  %z = zext i32 %a to i80                 ; in-grid widen — no fp80 involved
  %m = and i80 %z, 4294967295
  %eq = icmp eq i80 %m, 555               ; arm-resident, exactly one ConstantInt
  %w = zext i1 %eq to i32
  br label %merge

merge:
  %p = phi i32 [ %w, %arm ], [ 33, %entry ]
  ret i32 %p
}

define i32 @example(i32 %u) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u, double 5.000000e-01)
  %v = call i32 @leaf(i32 %q)
  %m = call i32 @cq_measure_si32(i32 %v)
  ret i32 %m
}

; CHECK: error{{.*}}: cq specialization: callee contains tainted control flow under quantum lift

; The discriminating line, and the reason this fixture is worth its weight: with
; the fence removed there is NO leave line at all here (the region is claimed and
; the clone is emitted). Its presence is the whole assertion.
; DBG: CQ_PREDMUX_DBG: leave @__cq_q_leaf_1 entry=entry merge=merge gate=E4-dataflow at:{{.*}}icmp eq i80
