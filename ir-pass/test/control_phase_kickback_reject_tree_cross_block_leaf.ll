; control_phase_kickback_reject_tree_cross_block_leaf.ll — DECLINE. A compound
; branch-phase condition with a leaf defined in a DIFFERENT block from the branch.
;
; The stale-condition guard has two prongs: a position-FREE wire walk (no window,
; declines any off-ancestry theta on a leaf's provenance) and a POSITIONAL scan
; from each leaf forward to the branch. The positional prong is only a BOUNDED
; window when the leaf lives in the region's `Pred`; a cross-block leaf cannot be
; scanned, so it declines conservatively — the same disposition
; `RegionTreeDetect::staleCond` takes for the same reason.
;
; ⚠ IT IS AN OVER-DECLINE AND A KNOWN ONE. The 4.4 select LIFTED the equivalent
; blanket cross-block decline (bd 9ymx, owner decision 2026-07-03) once it
; established that the position-free prong has no window and the positional one
; only ever adds other-wire conservatism. That argument transfers here, but
; transferring it is a change to a Rule-13 positional fence and belongs to a
; round with its own probe family — not to the increment that introduced the
; tree.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i1 %g) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %ca = icmp eq i32 %q, 5
  br label %pred
pred:
  %cb = icmp eq i32 %r, 3
  %c = select i1 %ca, i1 %cb, i1 false
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double 3.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %r)
  %s = add i32 %m, %n
  ret i32 %s
}

; CHECK: cq controlled lowering: control flow under quantum control
