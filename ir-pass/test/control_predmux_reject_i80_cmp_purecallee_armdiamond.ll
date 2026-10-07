; control_predmux_reject_i80_cmp_purecallee_armdiamond.ll — DECLINE
; (bd 3c6m.14.1): the CONTAINMENT fixture, and the one that makes the clone-mode
; decision defensible rather than merely convenient.
;
; THE ARGUMENT IT PINS. bd 3c6m.14.1 widened E4's CALL admission in BOTH
; contexts — top-level and `ClaimAll` clone mode — on the ground that the
; callee's i80 compare never enters the caller's flattened program (only the CALL
; moves, and nothing splices a callee body into a caller AFTER a claim — a
; Rule-13 lens rejected the shorter "the pass does no inlining", since
; `lowerByRefInline` DOES splice; what holds is the ORDERING, it runs before the
; PredMux fixpoint), so the caller's context is causally
; unrelated to how that compare is lowered, and the obligation is discharged
; where the compare LIVES. That argument is worth nothing unless something
; actually bites there. This is the something.
;
; `@inner` is byte-identical to the accepted clone-call sibling's `@inner`
; EXCEPT that its i80 compare has been moved inside a tainted diamond of the
; callee's own. Everything upstream still succeeds — the pure-callee proof
; passes (a body may branch; acyclic + br/ret + all-speculatable is the rule),
; the call is admitted, the outer region claims. Then `@inner` is specialized,
; PredMux runs over the clone body with `ClaimAll=true`, and the bare-compare
; fence at the E4 REGION-BODY walk — `AdmitI80Compare = !ClaimAll`, untouched by
; 3c6m.14.1 — refuses it. `opt` exits non-zero and NOTHING is lowered.
;
; So the boundary is: a compare the callee's own clone can lower straight-line is
; admitted; one that would have to be speculated into a clone-mode select program
; is not — the same line that declines
; control_predmux_reject_i80_cmp_clonemode.ll, reached by outlining instead of
; inlining. The two fences agree; they are not evadable by refactoring.
;
; NOTE THIS FIXTURE'S DBG LINE NAMES THE CLONE (`@__cq_q_inner_1`), NOT THE
; SOURCE FUNCTION. That is the whole assertion — it says the decline came from
; the callee's clone-mode flatten, not from the caller giving up. Pre-change the
; SAME module also declined, but with a DIFFERENT trace: `pure-callee inner fails
; at: icmp` then `leave @__cq_q_mid_1 ... at: call i32 @inner`. Same message,
; different origin — so the DBG prefix here is genuinely discriminating.
;
; bd p3kd.7.8: the clone now runs main's stage list. The clone-mode PredMux keeps
; this fence (`AdmitI80Compare = !ClaimAll`), so the region still leaves at E4 (the
; DBG line, unchanged) and main's control chain then refuses it (`value-arm
; swap-route`) before the clone backstop is asked. Main compiles the same body
; inlined into the caller (measured): the divergence is exactly this scope fence,
; which waits on its own probe family (bd 3c6m.14.1), not a new decline.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; RUN: env CQ_PREDMUX_DBG=1 not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering \
; RUN:   -S %s -o /dev/null 2>&1 | %filecheck %s --check-prefix=DBG

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @inner(i32 %a) {
e:
  %c = icmp sgt i32 %a, 7
  br i1 %c, label %arm, label %m

arm:                                      ; the compare is INSIDE the callee's arm
  %z = zext i32 %a to i80
  %n = and i80 %z, 4294967295
  %eq = icmp eq i80 %n, 555
  %w = zext i1 %eq to i32
  br label %m

m:
  %p = phi i32 [ %w, %arm ], [ 9, %e ]
  ret i32 %p
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

; CHECK: error{{.*}}in function __cq_q_inner_1 {{.*}}: cq controlled lowering: value-arm swap-route under quantum control

; The discriminating line: the decline is raised by the CALLEE'S OWN clone-mode
; flatten, at the compare itself — not by the caller declining the call.
; DBG: CQ_PREDMUX_DBG: leave @__cq_q_inner_1 entry=e merge=m gate=E4-dataflow at:{{.*}}icmp eq i80 %n, 555
