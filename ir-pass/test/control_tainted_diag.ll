; control_tainted_diag.ll — transitional guard for the `swap-route-control` branch.
;
; The old controlled-op lowering was removed so the RSSA swap-route control
; emitter can be built without it. Until that emitter lands, a tainted-condition
; `br i1` (a quantum-controlled region) must DIAGNOSE loudly ("… under quantum
; control") and fail (non-zero exit) — it must NEVER silently pass through as
; classical control over quantum state (a verify-clean silent miscompile). The
; diagnostic is emitted by `detectControlRegions` in ControlDetect.cpp (the arm
; rotates the CLASSICAL arg %y0, so it fails accept-criterion 3 — quantum base).
;
; A classical-condition branch stays byte-untouched (detection keys strictly on
; condition taint) — covered by the passthrough fixtures, not here.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i32 %y0) {
entry:
  %q = call i32 @cq_theta_si32(i32 3, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %y1 = call i32 @cq_phi_si32(i32 %y0, double 2.500000e-01)
  br label %merge
merge:
  %y = phi i32 [ %y1, %arm ], [ %y0, %entry ]
  %m = call i32 @cq_measure_si32(i32 %y)
  ret i32 %m
}
