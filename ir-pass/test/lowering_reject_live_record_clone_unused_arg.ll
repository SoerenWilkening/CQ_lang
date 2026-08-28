; lowering_reject_live_record_clone_unused_arg.ll — DECLINE: a Phase-6 clone call
; is a value-preserving HOP only for the arguments the clone actually READS. An
; argument the callee ignores does not reach the clone's result, so measuring that
; result observes nothing about it (M-A, bd test_C_libtooling-6uqc; round 2 of the
; Increment-3 Rule-13 round, 2026-08-28).
;
; SOURCE (the reviewer's h21 witness — but read the IR-ONLY note below before
; treating this as its lowering):
;     __attribute__((noinline)) static int inner(int x, int y){ (void)x; return y+3; }
;     int a = cq_theta(u0, 0.5);
;     int p = cq_theta(u0 + 1, 0.25);    // a SECOND wire
;     int w = a * 2;                     // THE WIRE
;     int c = a * k;                     // the DEAD sibling record
;     w = cq_theta(w, 0.5);              // T
;     int r = inner(c, p);               // `c` is IGNORED by inner
;     return cq_measure(r) + cq_measure(w) + cq_measure(a) + cq_measure(p);
;
; WHAT STANDS AT THE GATE. `%h_op2` (`c`) — allocated, entangled with the wire
; (both are basis functions of `%h`), never discharged before `T`. `%h` is measured
; after the gate and is exempt; `%h1` is a second, unrelated wire; the clone's
; `cqq.out` return is minted after the gate (clause-6 skip).
;
; WHY IT DECLINES. `%h_op2`'s only post-gate use is `@__cq_q_inner_11(%h_op2, %h1)`,
; and the clone's parameter `%x` IS UNREAD in the callee body: the result is
; `y + 3`, a function of the OTHER argument alone. So `cqrt_measure(%r)` observes
; `%h1`, not `%h_op2`, and nothing anywhere in the module observes `c`. Under the
; ruled clause 3 the record does not exempt, and the gate declines.
;
; WHY THIS WAS AN OVER-ACCEPT. `isCloneCallHop` answers "does this call forward a
; value?", never "does it forward THIS one", and the observing-sink walk hopped on
; the first question. MEASURED: pre-round-2 tree `opt` exit 0 — accepted, with the
; sibling standing dephasing at the `Ry` and no observation of it anywhere. Post-fix
; `opt` exit 1.
;
; IR-ONLY, AND SAY SO PLAINLY. `clang -O1` runs DAE and DROPS a parameter no callee
; body reads, taking the dead argument — and then the dead sibling `c` itself — with
; it: the C above lowers to `@__cq_q_inner_1(%h1)` with no `%h_op2` in the module at
; all, and ACCEPTS both before and after this fix (measured, both trees, as
; h21_clone_unused_arg). So this exact SSA does not arrive from that C text today.
; It is not a lesser pin for that. The ruling direction is the one the F1 and F2
; rulings already took, both of which were likewise decided ON CONSTRUCTED PROBES:
; a register nothing observes buys nothing by being accepted, the decline is the
; safe direction, and a construct that survives DAE tomorrow (a callee whose use of
; the parameter is itself dead, a `noinline`+`optnone` body, a hand-written .ll)
; must not find an open hole waiting for it.
;
; FAIL DIRECTION OF THE FIX. The callee is resolved by an explicit
; `dyn_cast<Function>` on the CALLED OPERAND (the bd xy9n lesson: `getCalledFunction`
; is null for a `GlobalAlias` and every name test then fails open). An unresolvable
; callee — alias, bitcast, indirect — gets NO hop, i.e. the DECLINE direction, and
; so does an argument past a varargs boundary or a body-less declaration.
;
; NOT APPLIED TO CLAUSE 1. The record-collection walks still cross a clone call on
; every argument: over-crossing there only ADDS records, which over-DECLINES, and
; tightening it would be a scope change with no safety argument behind it. This
; fixture pins clause 3 only.
;
; DISCRIMINATION: make `inner` read `%x` and the module LOWERS — that is
; lowering_live_record_sibling_clone_arg_measured_accept.ll, whose single-parameter
; clone genuinely forwards its argument to the measured result.
;
; `mul` is the vehicle at both hops (information-losing => never M-C-converted in
; place), so the sibling really is a separate rail and not a second name for the
; wire.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @main() {
  %q  = call i32 @cq_theta_si32(i32 1, double 5.000000e-01)
  %w  = mul i32 %q, 2                                          ; THE WIRE
  %c  = mul i32 %q, 3                                          ; DEAD sibling record
  %p  = call i32 @cq_theta_si32(i32 2, double 2.500000e-01)    ; a second wire
  %q2 = call i32 @cq_theta_si32(i32 %w, double 5.000000e-01)   ; T
  %r  = call fastcc i32 @inner(i32 %c, i32 %p)                 ; %c is IGNORED by inner
  %m  = call i32 @cq_measure_si32(i32 %r)
  %m1 = call i32 @cq_measure_si32(i32 %q2)
  %m2 = call i32 @cq_measure_si32(i32 %q)
  %m3 = call i32 @cq_measure_si32(i32 %p)
  %a  = add nsw i32 %m, %m1
  %b  = add nsw i32 %a, %m2
  %d  = add nsw i32 %b, %m3
  ret i32 %d
}

define internal fastcc i32 @inner(i32 %x, i32 %y) {
  %a = add nsw i32 %y, 3                                       ; %x UNUSED
  ret i32 %a
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
