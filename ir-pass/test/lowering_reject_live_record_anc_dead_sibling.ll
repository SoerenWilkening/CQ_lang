; lowering_reject_live_record_anc_dead_sibling.ll — DECLINE, and this fixture
; PINS THE SIBLING DECISION (M-A Increment 3, bd test_C_libtooling-6uqc;
; owner-approved default 2026-08-28). Nothing else in the suite turns on it.
;
; SOURCE (`clang -O1` emits this SSA up to strength reduction — a `* 2` arrives as
; `shl nsw …, 1`, which lowers out of place exactly like the `mul` spelled here):
;     a = cq_theta(a, 0.5);
;     int w = a * 2;             // THE WIRE
;     int b = a * 3;             // a SIBLING of the wire, off the same parent
;     int c = b * 7;             // ...whose own product is measured
;     int mc = cq_measure(c);    //    => c is EXEMPT (clause 4)
;     w = cq_theta(w, 0.5);      // T — chained, in-place Ry on the wire
;     int m  = cq_measure(w);
;     int m0 = cq_measure(a);    //    => the ANCESTOR is LIVE (clause 3) — EXEMPT
;     return m + m0 + mc;
;
; WHY THIS ONE NEEDS THE SIBLING CLOSURE AND NOTHING ELSE DOES. Walk the two
; halves separately and the module ACCEPTS:
;   * ANCESTORS of the wire = {`%h`}. `%h` is measured AFTER the gate, so it is
;     LIVE user data and the ruling EXEMPTS it (clause 3 — a live record's
;     dephasing is source semantics).
;   * DESCENDANTS of the wire = {}. Nothing is computed from `%h_op`.
; The rail that is actually standing dead at the gate is `%h_op1` — `b`, a
; DESCENDANT OF THE EXEMPT ANCESTOR. It is entangled with the wire (both are
; basis functions of `%h`), it is never read after the gate, and it is never
; uncomputed or freed. The ruling's clause 1 says "entangled with W —
; TRANSITIVELY, ancestors AND descendants", and the transitive closure is what
; reaches it: seed the descendant walk from every ancestor, not only from W.
;
; DISCRIMINATION, and it is one instruction wide: delete `%b`/`%c`/`%mc` and this
; module becomes lowering_live_record_anc_observed_after_theta_accept.ll, which
; LOWERS. That pair is what makes the sibling claim testable rather than asserted.
;
; `mul` is the vehicle at every hop (information-losing ⇒ never M-C-converted),
; so the sibling really is a separate rail and not a second name for the wire.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0 — the over-accept this closes.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul i32 %q, 2                                          ; THE WIRE
  %b  = mul i32 %q, 3                                          ; DEAD SIBLING
  %c  = mul i32 %b, 7                                          ; measured => exempt
  %mc = call i32 @cq_measure_si32(i32 %c)
  %q2 = call i32 @cq_theta_si32(i32 %a, double 5.000000e-01)   ; T
  %m  = call i32 @cq_measure_si32(i32 %q2)
  %m0 = call i32 @cq_measure_si32(i32 %q)                      ; ancestor LIVE => exempt
  %r0 = add nsw i32 %m, %m0
  %r  = add nsw i32 %r0, %mc
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
