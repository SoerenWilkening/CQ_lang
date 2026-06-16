; control_swap_reject_switch_datamux_spoof_sink.ll — DECLINE (4.5 WI-4): an
; all-ConstantInt DATA-MUX whose merge result is consumed by an opaque extern whose
; name merely STARTS WITH `cq_measure_` but is NOT a recognized intrinsic sink.
;
; THE HAZARD: `proveSwitchDataMux` requires the (UNTAINTED) data-mux merge result to
; be consumed only by a measurement sink or a `ret`. That sink test MUST be
; exact-membership (`TaintSet::MeasureCalls`, the recognized `@cq_measure_<sfx>` call
; sites), NOT a `starts_with("cq_measure_")` prefix match — a prefix check on the
; ACCEPT side is spoofable: `cq_measure_evil` is an UNKNOWN opaque callee everywhere
; else in the pipeline (declineTaintEscapes / isMeasureSink both use exact membership),
; yet a prefix check would mistake it for an owning sink and ACCEPT, leaking the live
; superposed rail %out to a classical function as a raw i32 handle (a verify-clean
; over-accept). Unlike the tainted-scrutinee allowlists, the untainted data-mux merge
; is never escape-guard pre-filtered, so the gate must do the exact check itself.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}control flow under quantum control
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_evil(i32)
define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %merge [ i32 0, label %a0
                                i32 1, label %a1 ]
a0:
  br label %merge
a1:
  br label %merge
merge:
  %rm = phi i32 [ 3, %entry ], [ 7, %a0 ], [ 9, %a1 ]
  %m = call i32 @cq_measure_evil(i32 %rm)
  ret i32 %m
}
