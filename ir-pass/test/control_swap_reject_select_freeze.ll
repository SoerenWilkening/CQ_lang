; control_swap_reject_select_freeze.ll — DECLINE: a freeze-mediated angle select
; is caught by the GATE-3 angle fence (the §3.2 carrier walk), NOT the blunt
; escape guard (4.4 WI-1 boundary probe; flipped by Phase-7.1 Increment B). Pins
; that the §3.2 angle walk's carrier set now CROSSES `freeze`.
;
; `(%qd>5) ? 0.25f : 0.75f` whose result is `freeze`d and `fpext`'d into a
; `cq_phi` arg-1 is a genuine angle-leak shape. BEFORE Increment B, `freeze` was
; not in `declineTaintEscapes`'s benign-user whitelist, so `freeze %sel` (a
; tainted value) was declined LOUDLY at the escape guard as `kMsgOther` and the
; angle walk never had to cross it. Increment B makes the escape guard SKIP an
; FP-typed tainted `freeze` (value-preserving carrier) so it rides the GATE-3
; fence instead — and `selReachesRotationArg1` now adds `isa<FreezeInst>` to its
; carrier set, so the walk reaches the `cq_phi` arg-1 (the angle slot) and
; declines `rotation angle` (the f64/angle miscompile family — Rule 3). There is
; NO downstream backstop for the angle once the escape guard skips the freeze, so
; the GATE-3 catch is load-bearing, not cosmetic.
;
; (If a future change ever STOPPED crossing `freeze` in the carrier walk, this
; fixture would flip from the GATE-3 brand to a silent data-merge accept — the
; FP-angle leak. Regression guard for the carrier extension, per Rule 12.)
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: rotation angle under quantum control
; NEW: cq controlled lowering: rotation angle under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: rotation angle under quantum control
; CHECK-NOT: cq taint escape
; CHECK-NOT: cqrt_copy
; CHECK-NOT: cqrt_alloc
; 3qlq: migrated from register cq_phi (mixed sites: see the migration report)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c   = icmp sgt i32 %q, 5
  %sel = select i1 %c, float 2.500000e-01, float 7.500000e-01
  %f   = freeze float %sel                       ; FP carrier -> rides GATE-3 fence
  %w   = fpext float %f to double
  call void @cq_phi(double %w)
  %m   = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}
