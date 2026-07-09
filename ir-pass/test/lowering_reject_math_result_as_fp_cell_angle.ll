; lowering_reject_math_result_as_fp_cell_angle.ll — DECLINE (bd 38t2): the MANDATORY
; angle-fence probe. 38t2 lifts the fp width fence for memory CELLS (data), but a cell
; value used as a rotation ANGLE must STILL decline. Here `%v = tblf[q]` (an fp cell
; load) feeds the arg-1 ANGLE slot of `cq_phi_f64` — a quantum-derived rotation angle
; has no fixed unitary. The value is MEASURED (not coherently returned) so the
; coherent-return fence does NOT pre-empt; the decline is `declineTaintedAngle`.
;
; This pins the fp-angle-fence ORDERING invariant (memory fp-angle-fence-ordering-
; invariant): `lowerShadowMemory`/`lowerQramReads` run BEFORE `lowerRotations` and
; RAUW the cell load to a tainted i32 handle — but `declineTaintedAngle` keys on
; `taint.Tainted.count(arg-1)`, and the qram load result IS inserted into Tainted, so
; the fence still fires on the RAUW'd handle. Lifting the CELL fence (widthHasQramCell)
; did NOT open the ANGLE path (the f64 silent-miscompile family stays closed).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tblf = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0]
declare double @cq_theta_f64(double, double)
declare double @cq_phi_f64(double, double)
declare double @cq_measure_f64(double)

define double @angle_from_cell(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %qi = fptosi double %q to i32
  %i = sext i32 %qi to i64
  %g = getelementptr inbounds [4 x double], ptr @tblf, i64 0, i64 %i
  %v = load double, ptr %g                              ; fp cell load
  %r = call double @cq_phi_f64(double %u0, double %v)   ; %v used as the ANGLE (arg-1)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
