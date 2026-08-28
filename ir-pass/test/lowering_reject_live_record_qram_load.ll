; lowering_reject_live_record_qram_load.ll — DECLINE: the record is a Phase-7.5
; `cqrt_qram_load_<W>` rail (M-A Increment 1, bd test_C_libtooling-6uqc).
;
; Clause 1 of the ruled predicate names TWO producer families —
; `cq_template_*` AND `cqrt_qram_load_*` — and this is the only fixture that
; pins the second one. A tainted-index read of a const-global table
; (`tbl[a & 3]`, the 7.5 Inc-1 accept shape) mints `%u`, a Toffoli-copy-out rail
; holding a basis function of the wire. `%u2` is measured before the gate and is
; therefore EXEMPT (clause 4); `%u` itself has no user after the gate and is
; never uncomputed or freed, so it is a live entangled record when the chained
; `cqrt_ry` on the index wire fires.
;
; THE DISCRIMINATION IS MEASURED, not asserted: measuring `%u` DIRECTLY (i.e.
; deleting `%u2` and taping the load result itself) makes the same program lower
; with `opt` exit 0 — that shape is the accept fixture
; lowering_live_record_measured_before_theta.ll.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@tbl = private constant [4 x i32] [i32 7, i32 8, i32 9, i32 10]

define i32 @slice(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = and i32 %q, 3
  %ie  = zext nneg i32 %idx to i64
  %pi  = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %ie
  %u   = load i32, ptr %pi, align 4                              ; -> cqrt_qram_load_i32, DEAD at the gate
  %u2  = add i32 %u, 1                                           ; measured => exempt
  %m   = call i32 @cq_measure_si32(i32 %u2)
  %q2  = call i32 @cq_theta_si32(i32 %idx, double 2.500000e-01)  ; chained, in-place Ry on the index wire
  %m2  = call i32 @cq_measure_si32(i32 %q2)
  %r   = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK: error{{.*}}cq rotation lowering: non-diagonal gate over a live derived record
