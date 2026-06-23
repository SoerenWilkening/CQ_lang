; lowering_reject_qram_fp_cell.ll — DECLINE (Phase 7.5 Inc 1): a tainted-index READ
; of a const table whose ELEMENT is floating-point (`double`). An fp cell is the
; f64/angle silent-miscompile family — a QRAM cell must be basis-encoded integer
; data (Toffoli-copy correct, Rule 7), never an in-place phase answer. Gated on the
; element width having a reversible copy ({i1,i8,i16,i32,i64}); double is excluded.
; This is a PERMANENT decline (PRD-7.5 §2.10, §5).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
@tblf = internal unnamed_addr constant [4 x double] [double 1.0, double 2.0, double 3.0, double 4.0]
declare i32 @cq_theta_si32(i32, double)

; The loaded value is left dead (ret void) so the read reaches the QRAM element-
; width gate rather than the pre-existing non-i32 `ret` guard.
define void @qrom_read_fp(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %i = sext i32 %q to i64
  %g = getelementptr inbounds [4 x double], ptr @tblf, i64 0, i64 %i
  %v = load double, ptr %g
  ret void
}

; CHECK: error{{.*}}cq QRAM read: array element is not a reversible integer cell
