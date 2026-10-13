; control_angle_select_reject_undef_arm.ll — DECLINE (S1, the ARM-VALUE fence):
; one select arm is `undef`.
;
; ROUND-1 RULE-13 REVIEW FINDING (bd drbq Inc 2b, lenses L5-1 and L7-F6). Nothing
; in S1-S10 inspected the VALUES of A and B, only their TYPE and their TAINT. So
; `select i1 %c, double 0.9, double undef` ACCEPTED, and the emitter's
; `CreateFSub(0.9, undef)` was CONSTANT-FOLDED BY IRBUILDER into a concrete
; quiet NaN (`0x7FF8000000000000`), giving
;
;     ry(h, undef) ; ry_controlled(f, h, NaN)
;
; ON THE TRUE EDGE THE SOURCE ASKED FOR `Ry(0.9)` — A FULLY DEFINED ANGLE — and no
; refinement of `undef` makes `Ry(undef)·Ry(NaN) = Ry(0.9)`. The DEFINED arm is
; destroyed by the UNDEFINED one, which is the opposite of what `undef`'s
; refinement semantics permit: `undef` may be refined to any value, and none of
; them repairs a NaN in the OTHER edge's angle.
;
; WHY `LiteralIntegrity` IS SILENT AND MUST NOT BE QUOTED HERE: guard 1
; (`declineUnpairedUndefLiterals`) fires when ONE undef literal reaches TWO
; emitted gate slots. Here exactly one slot holds `undef` (the twin's angle); the
; other holds the FOLDED NaN, which is an ordinary `ConstantFP`. The count is 1
; and the guard is correct to stay quiet. `double 0.9, double poison` and
; `undef, undef` DO trip it (two slots) — which is exactly why the asymmetry hid
; this: the neighbouring cells were loud.
;
; THE FIX: S1 asks `valueCarriesUndef` (the SHARED predicate from
; `LiteralIntegrity.h`, Rule 14 — not a bare `isa<UndefValue>`, so a ConstantExpr
; carrying undef is caught too) of BOTH arms and returns `NotApplicable`, so the
; caller's pre-existing `rotation angle` decline fires unchanged. No new string.
; `PoisonValue` is a subclass of `UndefValue`, so one predicate covers both.
;
; ORACLE DISPOSITION: the pre-2b binary declined this `rotation angle` too (it
; declined every angle select), so the fix RESTORES the pre-2b disposition.
;
; SINCE bd dm7f.6 (X-bracket Ry stem) the derivation above is history; the undef
; arm would land verbatim in the f = 0 gate slot, a literal undef in a gate
; operand (the bd xy9n class). The clause is now `angleSelectArmsDefined` (same
; `valueCarriesUndef`); a LITERAL undef is the hand-IR-only class this fixture
; keeps refused.
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
  %ang = select i1 %c, double 9.000000e-01, double undef
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %t)
  %s = add i32 %mq, %mr
  ret i32 %s
}
