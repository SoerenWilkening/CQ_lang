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
;
; 3qlq(prep_a2): the asserted diagnostic was RE-SPELLED on the Inc-1 binary.
; The construct this fixture pins is unchanged; the CLAUSE that refuses it
; MOVED — this is a real disposition change, not a widening, and the new
; string does not contain the old one.
; OLD: rotation angle under quantum control
; NEW: cq rotation lowering: unsupported quantum-derived rotation angle
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %f = sitofp i32 %q to double                    ; TAINTED angle producer
  call void @cq_phi(double %f)  ; derived base, tainted angle
  %c = icmp sgt i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: error{{.*}}cq rotation lowering: unsupported quantum-derived rotation angle
