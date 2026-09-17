; control_swap_reject_value_inloop_mixed_evidence.ll — bd test_C_libtooling-x5fp.
;
; THE MIXED-EVIDENCE TRIPWIRE, and the second of the two fixtures that keep the
; per-activation narrowing honest (the first is
; control_swap_reject_value_inloop_dtzb_same_rail.ll, which pins the rail
; conjunct). It is
; control_swap_reject_value_inloop_backedge_clobber.ll with ONE operand changed
; — the compare's FIRST operand is `%r` instead of `%q` — so the condition reads
; the routed register BOTH directly, in this activation, AND around the back
; edge through the classical carrier `%a`.
;
; The narrowing asks whether the clobber evidence is ABSENT from the
; in-activation cone, never whether a back-edge path merely EXISTS. Here `%r` is
; an operand of the compare itself, so it is in that cone and the PERMANENT
; string must survive. A version of this predicate that keyed on "is there a
; back edge anywhere in the provenance?" would flip this file, which is exactly
; what the fixture is for.
;
; UNMOVED, measured 2026-09-18 on both binaries: ORACLE `cq-opt` sha256
; 9bd01598…, SUBJECT 677472eb… — `arm rewrites a condition operand` on each.
;
; ⚠ RETIREMENT TRIGGER (L8): this file's partner pair becomes an ACCEPT when bd
; `test_C_libtooling-3qlq.6` / bd `1dbk` item 1 lands. THIS file must NOT. If it
; ever accepts, the narrowing has been widened past "absent from the
; in-activation cone" and is an over-accept.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}arm rewrites a condition operand under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
entry:
  br label %hdr

hdr:
  %i = phi i32 [ 0, %entry ], [ %inext, %latch ]
  %a = phi i32 [ 0, %entry ], [ %m, %latch ]
  %q = call i32 @cq_theta_si32(i32 9, double 3.000000e-01)
  %r = call i32 @cq_theta_si32(i32 7, double 2.000000e-01)
  %c = icmp sgt i32 %r, %a
  br i1 %c, label %arm, label %merge

arm:
  %r1 = add nsw i32 %r, 3
  br label %merge

merge:
  %rm = phi i32 [ %r1, %arm ], [ %r, %hdr ]
  %m = call i32 @cq_measure_si32(i32 %rm)
  br label %latch

latch:
  %inext = add nuw nsw i32 %i, 1
  %done = icmp eq i32 %inext, 3
  br i1 %done, label %exit, label %hdr

exit:
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %e = add nsw i32 %m, %m2
  ret i32 %e
}
