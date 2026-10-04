; control_inplace_ry_reject_flat_cond_pre_measure.ll — DECLINE (FLAT), and it is
; an OVER-decline. Half of a deliberately PAIRED witness: this file and
; `control_inplace_ry_inloop_cond_pre_measure.ll` are the SAME relation between a
; record read and a region, once acyclic and once inside the rolled loop, and they
; land on OPPOSITE sides. Read them together or neither is informative.
;
;     if (cc) { d = cq_measure(r); }        <-- a read of the PRE-region name, on
;     if (q > 5) cq_theta(&r, 0.9);          a CONDITIONAL path before the region
;
; R6 asks every user of every member of the rotated base's wire closure a
; question. FLAT, that question is `provablyBefore(U, BI, DT)`, which is
; DOMINANCE ∧ UNREACHABILITY. Here `%d` sits in a conditionally-executed block: it
; does NOT dominate `BI`, though `BI` plainly cannot reach it. So the DOMINANCE
; conjunct is the operative one and the file declines.
;
; ⚠ IT IS SOUND TO ACCEPT AND WE REFUSE ANYWAY (bd drbq Inc 3, round-1 lens L1
; Q2, measured on BOTH binaries — this is NOT an Increment-3 movement). On every
; trace where `%d` executes it has already executed before the region's stream
; begins, so it reads the register the source names. Dominance answers "did `U`
; DEFINITELY execute", which is a question R6 has never needed: what R6 must
; refuse is a read that can fire AFTER the hoisted controlled Ry. The
; PER-ACTIVATION certificate the in-loop twin uses drops exactly that conjunct
; and accepts this relation — see the twin.
;
; SO WHY IS THE FLAT SPELLING KEPT? Because `provablyBefore ⇒ certificate`: the
; certificate is strictly WEAKER, so replacing the flat predicate with it would
; be a WIDENING of the acyclic accept class, and a widening owes its own
; adversarial round (Rule 13). Increment 3 deliberately left every acyclic
; disposition byte-identical — that is what makes its whole-corpus sweep a
; witness rather than a regeneration. This file is the pin that makes the day
; someone widens it a DELIBERATE day: it must be RE-CLASSIFIED as an accept and
; re-argued, never silently flipped.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry
; CHECK-NOT: cqrt_ry_i32_controlled
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i1 %cc) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r  = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br i1 %cc, label %side, label %join
side:
  %d = call i32 @cq_measure_si32(i32 %r)
  br label %join
join:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ %r, %join ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
