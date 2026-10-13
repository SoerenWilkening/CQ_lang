; control_angle_select_reject_poison_arm.ll — DECLINE (S1, the ARM-VALUE fence):
; the TRUE arm is `poison`, and the FALSE arm is an ordinary angle.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lenses L5-1 and L7-F6). This is
; the sibling of `control_angle_select_reject_undef_arm.ll` and it fails ONE STEP
; EARLIER in the fold: `fsub poison, 0.3` folds to `poison`, so the emitted stream
; carried a RAW `double poison` in the CONTROLLED gate's angle slot —
;
;     ry(h, 0.3) ; ry_controlled(f, h, poison)
;
; — a value the source never named, in an operand the backend will realize as
; whatever the `-O0` stage-3 link decides. Both the value and the disposition are
; wrong: on the FALSE edge the source asked for exactly `Ry(0.3)` and got it, and
; on the TRUE edge it asked for a rotation whose angle is undefined behaviour, so
; the compiler must not choose one for it.
;
; TWO ARMS OF THE SAME FENCE, DELIBERATELY SEPARATE FIXTURES: `undef` in the
; FALSE arm folds to a concrete NaN (the other file); `poison` in the TRUE arm
; stays poison. Same clause, two different downstream artefacts, so a mutation
; that repaired only the NaN half would keep one of them green.
;
; `PoisonValue` is a subclass of `UndefValue`, so `valueCarriesUndef` covers both
; with ONE predicate and there is no second spelling to drift (Rule 14).
;
; SINCE bd dm7f.6 (X-bracket Ry stem) the fold above is history: the poison
; TRUE arm would reach the f = 1 controlled gate verbatim, still a raw `double
; poison` in a gate slot. The decline (`angleSelectArmsDefined`) is unchanged.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 2.500000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double poison, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
