; control_swap_reject_switch_datamux_spoof_sink.ll — SPOOFED-SINK reject (4.5 WI-4;
; re-routed by dugh): an all-ConstantInt DATA-MUX whose merge result is consumed by
; an opaque extern whose name merely STARTS WITH `cq_measure_` but is NOT a
; recognized intrinsic sink.
;
; THE HAZARD: `cq_measure_evil` must NEVER be mistaken for an owning measurement sink
; (that would leak the live superposed rail %out to a classical function as a raw i32
; handle). Under dugh the exact-membership sink test lives in the escape net, not a
; detection-time gate: `repropagateControlMerges` re-seeds a second propagation from
; the emitted `%out`, so the `cq_measure_evil` call reads a now-tainted value and —
; being absent from the recognized `@cq_measure_<sfx>` sinks and every carve — is
; correctly declined as an UNKNOWN CALLEE (`kMsgUnknownCallee`), refusing to leak the
; rail. (A real `@cq_measure_<sfx>` sink stops propagation and is owned by
; `lowerMeasures`; only the spoof falls through to the unknown-callee decline.)
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}tainted value consumed by an unknown callee
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
