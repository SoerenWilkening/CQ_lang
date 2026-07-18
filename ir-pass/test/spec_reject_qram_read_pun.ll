; spec_reject_qram_read_pun.ll — bd 20xt.4 Inc 1 (over-accept probe, the 38t2 pun
; class): a tainted-index load whose ACCESS type (`i64`) differs from the const
; global's CELL type (`double`) — a type-punned sub-/re-interpret read. Admitting it
; would resolve the qram cell width from the ORIGIN (`f64`) yet feed a differently-
; typed rail, a verify-clean WRONG-WIDTH gate stream. `qromReadShapeInScope` applies
; the SAME pun fence `matchQramAccess` does (`LI->getType() != CellTy`), so the read's
; address gep is not admitted and `scanBody` keeps the loud decline. `opt` exits
; non-zero.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

@T = internal unnamed_addr constant [4 x double] [double 1.500000e+00, double 2.500000e+00, double 3.500000e+00, double 4.500000e+00], align 16

declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define internal double @lookup(double %x) {
  %i = fptosi double %x to i32
  %m = and i32 %i, 3
  %idx = zext i32 %m to i64
  %p = getelementptr inbounds [4 x double], ptr @T, i64 0, i64 %idx
  %v = load i64, ptr %p, align 8            ; punned: i64 access of an f64 cell
  %vf = sitofp i64 %v to double
  %r = fadd double %vf, %x
  ret double %r
}

define double @example(double %u) {
  %q = call double @cq_theta_f64(double %u, double 5.000000e-01)
  %r = call double @lookup(double %q)
  %m = call double @cq_measure_f64(double %r)
  ret double %m
}

; CHECK: cq specialization: callee contains a non-reversibilizable construct under quantum lift (unsupported instruction)
