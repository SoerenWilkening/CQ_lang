; control_angle_select_reject_stale_chained_theta.ll — DECLINE (S9): a SIBLING
; chained `cq_theta` on the base's rail, written after the gate (bd drbq Inc 2b).
;
;     r = cq_theta(r, q == 5 ? .9 : .3);   // the 2b gate
;     int z = cq_theta(r, .2);             // reads the PRE-gate SSA name `r`
;
; `%z` names a rotation whose arg-0 is the base's pre-gate SSA record. It is
; itself a rail member (a chained Ry lowers in place), so S9 asks it the ALIAS-HOP
; question — `cannotFollowGate`, i.e. "the gate cannot reach you" — and it fails,
; because `%z` executes strictly AFTER the gate on the same rail. Two sets and
; two questions: a member owes only that, a genuine read owes the full
; `provablyBefore`, and widening the member set must not widen the skip set (the
; bd 8h7d.5 round-3 discipline).
;
; (The wrap above is deliberate. It used to break as "TWO SETS, TWO / QUESTIONS:",
; putting an ALL-CAPS token followed by a colon at the start of a prose line —
; the shape bd `test_C_libtooling-45fd` was filed for, and inert only because no
; RUN line here declares a `QUESTIONS` prefix. Round-2 Rule-13 review, lens R2
; N11; a mechanical re-scan of all 68 files in this family finds no other.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control
; 3qlq: migrated from register cq_phi (dead declare erased)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %z = call i32 @cq_theta_si32(i32 %r, double 2.000000e-01)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %mz = call i32 @cq_measure_si32(i32 %z)
  %s = add i32 %mt, %mz
  ret i32 %s
}
