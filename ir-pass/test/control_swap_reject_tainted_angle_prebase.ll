; control_swap_reject_tainted_angle_prebase.ll — DECLINE: a pre-region phase's
; angle is quantum-derived.
;
; `cq_phi((double)q); if (q > 5) cq_phi(a);` — the pre-region phase's angle is
; TAINTED (the sitofp of the handle's own value); the arm's angle is classical.
; RotationLowering's quantum-derived-angle guard declines it, source-located
; (Rule 3). Pre-3qlq this was the derived routed base `%qd = cq_phi(%q,
; sitofp(%q))`, caught by taintedAngleGate's base check; before that check it was
; a broken-module abort (LLVM ERROR, exit 134).
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
