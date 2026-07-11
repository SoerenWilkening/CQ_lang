; lowering_reject_qram_read_under_control_nonconst.ll — DECLINE, over-accept BOUNDARY probe
; (bd 3c6m.13). A tainted-index read UNDER tainted control whose table is a NON-constant
; (mutable) global. This is NOT a QROM read (QROM = read-only const table), so the precise
; `const-global table read under tainted control` signpost must NOT fire here — it falls to
; the generic escape decline. Pins that the new diagnostic is scoped to CONST globals only
; (matchQramAccess requires isConstant()+hasInitializer() for a Global origin, so a mutable
; global yields nullopt → NotQram → generic). Over-declining is fine; MIS-naming would be a
; false signpost.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK:     error{{.*}}cq taint escape: tainted value reaches an unsupported instruction
; CHECK-NOT: const-global table read under tainted control
@mut = internal unnamed_addr global [2 x double] [double 1.000000e+00, double 2.000000e+00]
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @nonconst_read(double %u0) {
entry:
  %q = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %bits = bitcast double %q to i64
  %sx = lshr i64 %bits, 63
  %cmp = fcmp olt double %q, 0.000000e+00
  br i1 %cmp, label %arm, label %merge
arm:
  %g = getelementptr inbounds [2 x double], ptr @mut, i64 0, i64 %sx
  %v = load double, ptr %g, align 8
  %hi = fsub double %q, %v
  br label %merge
merge:
  %r = phi double [ %hi, %arm ], [ %q, %entry ]
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}
