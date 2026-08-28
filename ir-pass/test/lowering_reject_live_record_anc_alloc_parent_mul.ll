; lowering_reject_live_record_anc_alloc_parent_mul.ll — DECLINE: the ANCESTOR
; half of clause 1, in its smallest form — a dead `cqrt_alloc_*`-minted PARENT
; (M-A Increment 3, bd test_C_libtooling-6uqc; bd test_C_libtooling-nepx's `h0`
; class, reached through a NON-M-C op).
;
; SOURCE (`clang -O1` emits exactly the SSA below):
;     a = cq_theta(a, 0.5);       // source theta: mints the wire
;     int d = a * 3;              // OUT-OF-PLACE — mul is information-losing,
;                                 // so M-C never converts it: a FRESH rail
;     d = cq_theta(d, -0.5);      // T — chained, in-place Ry on the mul rail
;     return cq_measure(d);
;
; WHAT IS STANDING AT THE GATE. `cq_template_mul_i32_hl(%h, 3)` mints `%h_op`
; and KEEPS `%h` — the source rail — allocated and holding |a>. At the chained
; `cqrt_ry_i32(%h_op, -0.5)` the state is sum_a c_a |a>_h |3a>_h_op: `%h` is a
; basis record of the wire's value, `%h_op`'s reduced state is diagonal, and the
; Ry cannot interfere amplitudes across `a`. That is bd nepx's own argument with
; the record on the ANCESTOR side of the producer edge.
;
; WHY INCREMENT 1 MISSED IT, precisely. `collectDescendantRecords` walked FORWARD
; from the wire only, and `%h` is BACKWARD of it: `%h_op`'s producer, not its
; product. Nothing downstream of `%h_op` exists at all here, so the Inc-1 walk
; returned an empty record set and the module lowered.
;
; MEASURED AT HEAD (pre-Inc-3): `opt` exit 0, two `cqrt_ry_i32` emitted, zero
; diagnostics — the over-accept this fixture closes.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @slice(i32 %u0) {
entry:
  %q  = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %d  = mul i32 %q, 3                                          ; fresh rail; %h stays live
  %q2 = call i32 @cq_theta_si32(i32 %d, double -5.000000e-01)  ; T — chained Ry on the mul rail
  %m  = call i32 @cq_measure_si32(i32 %q2)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
