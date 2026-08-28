; lowering_reject_live_record_anc_two_hop.ll — DECLINE: the ancestor closure is
; TRANSITIVE (M-A Increment 3, bd test_C_libtooling-6uqc).
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     a = cq_theta(a, 0.5);
;     int p = a * 3;              // ancestor, ONE producer hop up
;     int b = p * 5;              // the wire
;     b = cq_theta(b, 0.5);       // T — chained, in-place Ry on `b`'s rail
;     return cq_measure(b);
;
; THE PIN THAT THE ONE-HOP FIXTURE DOES NOT GIVE: two rails stand at the gate,
; `%h_op` (one hop up, template-minted) and `%h` (two hops up, alloc-minted), and
; BOTH are dead — neither is read again, uncomputed or freed. A backward walk
; that stopped at the immediate producer would still leave `%h` live, so this
; file is the ancestor mirror of lowering_reject_live_record_two_hop.ll's
; descendant transitivity claim.
;
; `mul` is the vehicle at BOTH hops on purpose: it is information-losing and so
; is outside the dtzb in-place bijection family (`inPlaceValueRailOperand`) at
; every M-C batch, which is what keeps two distinct rails in the stream. With
; `add` both hops would convert to `cqrt_addc_i32` and the program would become
; the one-rail shape this fixture is not about.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0 — the over-accept this closes.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %a  = mul i32 %q, 3                                          ; ancestor, hop 1
  %b  = mul i32 %a, 5                                          ; the wire
  %q2 = call i32 @cq_theta_si32(i32 %b, double 5.000000e-01)   ; T
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
