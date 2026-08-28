; lowering_reject_live_record_qram_load.ll — DECLINE: the record is a Phase-7.5
; `cqrt_qram_load_<W>` rail (M-A, bd test_C_libtooling-6uqc).
;
; Clause 1 of the ruled predicate names TWO producer families —
; `cq_template_*` AND `cqrt_qram_load_*` — and this is the only fixture that
; pins the second one. A tainted-index read of a const-global table
; (the 7.5 Inc-1 accept shape) mints `%u`, a Toffoli-copy-out rail holding a
; basis function of the wire. `%u2` is measured before the gate and is
; therefore EXEMPT (clause 4); `%u` itself has no user after the gate and is
; never uncomputed or freed, so it is a live entangled record when the chained
; `cqrt_ry` on the index wire fires.
;
; THE DISCRIMINATION IS MEASURED, not asserted: measuring `%u` DIRECTLY (i.e.
; deleting `%u2`) makes the same program lower with `opt` exit 0 — that shape is
; the accept fixture lowering_live_record_measured_before_theta.ll.
;
; VEHICLE-OP NOTE (M-C Increment 2a). The terminal record used to be built with
; `add`. M-C now lowers a dead-parent `q + c` IN PLACE (`cqrt_addc_<W>`), which
; would COLLAPSE the two rails this fixture needs into one: the interior record
; and the terminal record would become the same register, the measurement would
; land on the interior record itself, and clause 4 would exempt it — the module
; would ACCEPT for a reason that has nothing to do with what this file pins. The
; vehicle is therefore `mul`, which is information-LOSING and so is deliberately
; outside the dtzb in-place bijection family (`inPlaceValueRailOperand`) at every
; batch. The STRUCTURE under test — a dead interior record standing at the gate —
; is unchanged.
;
; INDEX-SPELLING NOTE (M-A Increment 3, and it is load-bearing for the PAIR).
; The index used to be `%idx = and i32 %q, 3`, lowered OUT OF PLACE, which left
; `%h` (the `cqrt_alloc_i32` rail) standing as a dead ANCESTOR of the index wire.
; Increment 3 counts ancestors, so this fixture AND its accept twin would both
; have declined on that ancestor and the pair would have stopped discriminating
; the interior rail it exists to discriminate. The index is now
; `%idx = add nsw i32 %q, 1`, which M-C converts to `cqrt_addc_i32(%h, 1)`: the
; index wire IS the alloc rail, there is no ancestor, and the ONLY thing standing
; at the gate is the interior QROM rail `%u`. The `@tbl` const-global QROM read is
; unchanged.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@tbl = private constant [4 x i32] [i32 7, i32 8, i32 9, i32 10]

define i32 @slice(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = add nsw i32 %q, 1                                       ; IN PLACE: wire == alloc rail
  %ie  = zext nneg i32 %idx to i64
  %pi  = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %ie
  %u   = load i32, ptr %pi, align 4                              ; -> cqrt_qram_load_i32, DEAD at the gate
  %u2  = mul i32 %u, 3                                           ; measured => exempt
  %m   = call i32 @cq_measure_si32(i32 %u2)
  %q2  = call i32 @cq_theta_si32(i32 %idx, double 2.500000e-01)  ; chained, in-place Ry on the index wire
  %m2  = call i32 @cq_measure_si32(i32 %q2)
  %r   = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
