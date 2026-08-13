; lowering_qram_read_fp64.ll — ACCEPT (bd 38t2): a tainted-index READ of a const table
; whose ELEMENT is `double`. An fp cell is a faithful reversible bit-pattern cell (bd
; [38t2-fp-cell-commits-to-basis-sound]), NOT the old f64/angle decline — it lowers to
; `cqrt_qram_alloc_f64` + `cqrt_qram_load_f64` exactly as the integer QROM read
; (lowering_qram_read_const_global_i32.ll) does, only the width tags the symbol. The
; loaded value is MEASURED (a collapse sink — measurement immunity), so the read is
; sound and does not trip the coherent-return fence. (Was lowering_reject_qram_fp_cell.ll,
; which PERMANENTLY declined a double cell — 38t2 lifts that fence for cells while the
; angle fence stays: see lowering_reject_math_result_as_fp_cell_angle.ll.)
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
@tblf = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @qrom_read_fp(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qi = fptosi double %q to i32
  %i = sext i32 %qi to i64
  %g = getelementptr inbounds [4 x double], ptr @tblf, i64 0, i64 %i
  %v = load double, ptr %g
  %m = call double @cq_measure_f64(double %v)
  ret double %m
}

; CHECK:     %[[ARR:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_alloc_f64(i32 4)
; CHECK:     %[[V:[a-zA-Z0-9_.]+]] = call i32 @cqrt_qram_load_f64(i32 %[[ARR]], i32 %{{[a-zA-Z0-9_.]+}})
; CHECK:     call double @cqrt_measure_f64(i32 %[[V]])
; CHECK-NOT: not a reversible cell
; CHECK-NOT: cq taint escape
