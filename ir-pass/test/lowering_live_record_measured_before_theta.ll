; lowering_live_record_measured_before_theta.ll — ACCEPT: clause 4, the COLLAPSE
; exemption (M-A Increment 1, bd test_C_libtooling-6uqc).
;
; The DISCRIMINATION TWIN of lowering_reject_live_record_qram_load.ll: identical
; program except that the `cqrt_qram_load_i32` rail is measured DIRECTLY instead
; of through an intervening `add`. Measuring it before the gate classicalizes
; the record — there is no coherence left in it to dephase the wire with — so
; the chained `cqrt_ry` on the index wire lowers.
;
; Read the two fixtures together: they are the same six instructions, and the
; only difference is whether one dead interior rail exists between the load and
; the measurement. That is exactly the granularity the ruled predicate claims,
; and this pair is what makes the claim testable rather than asserted.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
@tbl = private constant [4 x i32] [i32 7, i32 8, i32 9, i32 10]

define i32 @slice(i32 %u0) {
entry:
  %q   = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %idx = and i32 %q, 3
  %ie  = zext nneg i32 %idx to i64
  %pi  = getelementptr inbounds [4 x i32], ptr @tbl, i64 0, i64 %ie
  %u   = load i32, ptr %pi, align 4                              ; the qram-load record
  %m   = call i32 @cq_measure_si32(i32 %u)                       ; COLLAPSED before the gate
  %q2  = call i32 @cq_theta_si32(i32 %idx, double 2.500000e-01)  ; chained, in-place Ry — LOWERS
  %m2  = call i32 @cq_measure_si32(i32 %q2)
  %r   = add nsw i32 %m2, %m
  ret i32 %r
}

; CHECK:      %[[IDX:.*]] = call i32 @cq_template_and_i32_hl(
; CHECK:      %[[U:.*]] = call i32 @cqrt_qram_load_i32(
; CHECK:      call i32 @cqrt_measure_i32(i32 %[[U]])
; CHECK:      call void @cqrt_ry_i32(i32 %[[IDX]], double 2.500000e-01)
