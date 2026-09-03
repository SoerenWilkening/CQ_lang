; control_angle_select_reject_record_read_on_side_path.ll — DECLINE (S9), and it
; is an OVER-DECLINE that is kept ON PURPOSE (bd drbq Inc 2b).
;
;     if (cc) acc = cq_measure(r);            // a CLASSICAL branch, side path
;     r = cq_theta(r, q == 5 ? .9 : .3);      // the 2b gate, in the join block
;
; THE FIXTURE THAT FENCES S9's SKIP-SET ASYMMETRY. `%ms` is a genuine READ of a
; rail member (not an alias hop), so it owes the full `provablyBefore(ms, T)` —
; whose FIRST conjunct is dominance, and `side` does not dominate `main`. It
; declines. Relax that one user to the member-only obligation
; (`cannotFollowGate`, "the gate cannot reach you") and it ACCEPTS — measured by
; mutation, and this is the ONLY fixture in the family that moves.
;
; IT IS AN OVER-DECLINE AND THE HEADER SAYS SO. On every path where `%ms` runs it
; runs BEFORE the gate, so the source's record and the register agree; nothing is
; stale. It is kept because the SETS-AND-QUESTIONS discipline is the fence, not
; the individual verdict: `BaseWire` feeds three consumers (S8's intersection,
; S9's member enumeration, S9's skip set), and Inc-1 measured that widening the
; skip set on the member set's account turns a real decline into an accept. A
; member is an alias HOP and owes only "cannot fire after the gate"; everything
; else owes the shipped `provablyBefore`. Two sets, two questions — the bd 8h7d.5
; round-3 discipline, which this project's history says is exactly where the next
; hole lives.
;
; Narrowing S9 to accept this shape is a Rule-13 change, not a cleanup.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}stale rail record read past a controlled Ry under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1, i32 %cc) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %r = call i32 @cq_theta_si32(i32 %u1, double 3.000000e-01)
  %p = icmp eq i32 %cc, 0
  br i1 %p, label %side, label %main
side:
  %ms = call i32 @cq_measure_si32(i32 %r)
  br label %main
main:
  %acc = phi i32 [ %ms, %side ], [ 0, %entry ]
  %c = icmp eq i32 %q, 5
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %t = call i32 @cq_theta_si32(i32 %r, double %ang)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %x = add i32 %acc, %mt
  ret i32 %x
}
