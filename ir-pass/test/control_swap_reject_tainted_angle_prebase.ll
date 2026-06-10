; control_swap_reject_tainted_angle_prebase.ll — DECLINE: the DERIVED BASE's own
; angle is quantum-derived.
;
; `%qd = cq_phi(%q, sitofp(%q))` — the pre-region rotation that would become the
; routed base carries a TAINTED angle (the sitofp of the handle's own value).
; The arm gates' angles are classical, so only the base check in
; taintedAngleGate catches this. Declining here turns what used to be a
; broken-module abort (rotation lowering cross-type-RAUWs the f64 angle to an
; i32 handle inside an emitted call that is never erased — LLVM ERROR, exit 134)
; into a clean, source-located decline. The straight-line variant of the same
; hole (no control flow at all) still aborts loudly and is tracked separately.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %f = sitofp i32 %q to double                    ; TAINTED angle producer
  %qd = call i32 @cq_phi_si32(i32 %q, double %f)  ; derived base, tainted angle
  %c = icmp sgt i32 %qd, 5
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %qd, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %qd, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  ret i32 %m
}

; CHECK: error{{.*}}rotation angle under quantum control
