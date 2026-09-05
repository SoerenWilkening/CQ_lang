; control_inplace_ry_inloop_cond_pre_measure.ll — ACCEPT (ROLLED, in-loop). The
; other half of the paired witness begun in
; `control_inplace_ry_reject_flat_cond_pre_measure.ll`: the SAME relation between
; a record read and a region, moved inside the rolled loop, where R6's
; PER-ACTIVATION certificate (`recordLivePerActivation`, PRD §13.3) replaces the
; flat pair and ACCEPTS it.
;
;     for (i = 0; i < 4; ++i) {
;         if (cc) { d = cq_measure(r); }        <-- read of the PRE-region name
;         if (q > 5) r = cq_theta(r, 0.9);      <-- the in-place Ry arm
;     }
;
; WHY THIS IS THE RIGHT ANSWER, not a relaxation that got lucky (bd drbq Inc 3,
; round-1 lens L1 Q2 — the emitted stream was read and verified: `cqrt_measure`
; in `%side` fires ONCE PER TRIP, before that trip's `cqrt_ry_i32_controlled`).
; The certificate is `D` REFRESHES ∧ every CFG path `BI → p(U)` re-executes `D`.
; Here `D` is the loop-carried header φ `%r`, which tracks the wire (its latch
; incoming is the region's merge, so re-executing it re-reads the moved
; register), and every path from the region's branch back to `%d` goes through
; the latch and the header — i.e. through `D`. So on each activation `%d` reads
; the register as it stands at the TOP of that trip, which is exactly the name
; the source wrote.
;
; ⚠ THE DIVERGENCE FROM THE FLAT TWIN IS LIVE AND MEASURED, AND ITS DIRECTION IS
; THE SAFE ONE. `provablyBefore ⇒ certificate` and `cannotFollowGate ⇒
; certificate`: the certificate is analytically WEAKER than both flat predicates,
; so everything the flat path accepts the in-loop path accepts, and this file is
; a shape the flat path additionally refuses. That is not an accident of two
; spellings drifting — the flat pair is a deliberately STRONGER LEGACY spelling,
; kept byte-for-byte so that no acyclic disposition moved in this increment, and
; the dominance conjunct it carries is one R6 never actually needed (see the
; twin's header). Widening the flat side to the certificate is a real widening of
; the acyclic accept class and owes its own adversarial round (Rule 13); bd
; [[sibling-predicate-spelling-is-the-hole]] is precisely about one sibling being
; spelled differently from the rest, so the pair is committed rather than the
; asymmetry being left undocumented.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
; RUN: %filecheck %s --check-prefix=NOROUTE < %t.cqd0.ll
;
; CHECK-LABEL: define i32 @example
; the pre-region read, ONCE, in its own conditional block inside the loop:
; CHECK: side:
; CHECK-NEXT: call i32 @cqrt_measure_i32(i32 %[[R:[a-zA-Z0-9_.]+]])
; and then the region's per-activation stream, rolled:
; CHECK: %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_sgt_i32_hl(i32 %[[Q:[a-zA-Z0-9_.]+]], i32 5)
; CHECK-NEXT: call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.0
; CHECK-NEXT: call void @cq_template_icmp_sgt_i32_hl_unc(i32 %[[F]], i32 %[[Q]], i32 5)
; CHECK-NEXT: call void @cqrt_free(i32 %[[F]])
;
; NOROUTE-NOT: call void @cqrt_cswap
; NOROUTE-NOT: @cq_theta_
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i1 %cc) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r0 = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  br label %loop
loop:
  %r = phi i32 [ %r0, %entry ], [ %rm, %merge ]
  %i = phi i32 [ 0, %entry ], [ %inext, %merge ]
  br i1 %cc, label %side, label %J
side:
  %d = call i32 @cq_measure_si32(i32 %r)
  br label %J
J:
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 %r, double 9.000000e-01)
  br label %merge
merge:
  %rm    = phi i32 [ %rt, %arm ], [ %r, %J ]
  %inext = add i32 %i, 1
  %done  = icmp sgt i32 %inext, 3
  br i1 %done, label %exit, label %loop
exit:
  %m = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %m
}
