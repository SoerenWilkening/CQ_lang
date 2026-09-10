; control_phase_kickback_reject_rail_round2_sibling_theta.ll — DECLINE (bd
; test_C_libtooling-r9e5 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1 — THE KICKBACK
; CONSUMER of the same defect). The round-2 taint window reached through the flat
; register-free BRANCH PHASE instead of the 4.4 data select: `%y` is the 6.5
; classical-call-arm `%out`, `%x = trunc %y` is CLASSICAL when
; `classifyPhaseKickback`'s step 5b asks the §13.3 ladder (round-1 taint) and
; TAINTED when `lowerRotations` decides chained-vs-source, so `%b` and its
; SIBLING `%b3` ride ONE rail and the kickback gate fires on a register the
; sibling moved.
;
; ⚠ THE EXTRA BLOCK IS LOAD-BEARING, and it is why the reviewer's probe `e09`
; could not establish this consumer: with the `br i1 %b` in the ROUND-1 region's
; own merge block the region declines `control flow` upstream of the ladder, on
; both binaries and with or without the sibling (MEASURED — probes `w1`/`w2`
; under `inc1-records/session-r9e5/probes/`, with `w3`/`w4` the reachable pair
; this fixture and its accept twin are transcribed from). One `br label %second`
; past it and the window is reachable.
;
; RED ON f8d29e8 (the round-1-fix checkpoint): rc=0, verify-clean, STRICT stage
; 2b `1 verified, 0 violation(s)`, emitting
;
;   %h_cast = call i32 @cq_template_trunc_i32_to_i1(i32 %out)
;   call void @cqrt_ry_i1(i32 %h_cast, double 5.000000e-01)   <- %b
;   call void @cqrt_ry_i1(i32 %h_cast, double 9.000000e-01)   <- %b3, SAME RAIL
;   call void @cqrt_rz_i1(i32 %h_cast, double 0x3FE6666666666666), !cq.branchphase
;
; — the branch phase applied to the |1> component of `Ry(0.9)Ry(0.5)|x>` while
; the branch condition names `Ry(0.5)|x>`. `reverifyRailCondReads` records the
; FIRST `cqrt_rz_i1` on the register (`emitKickbackGroup`, `CtlIsRail`) and
; re-asks rung (iii) there with FINAL taint.
;
; The ACCEPT twin — this module with `%b3` deleted — is
; `control_phase_kickback_rail_round2_window_accept.ll`, byte-identical on both
; binaries: the fix is a RE-VERIFICATION, not a refusal of the window.
;
; ⚠ A `DS_Error` decline writes 0 bytes to stdout, so every IR-text negative a
; decline fixture could carry is VACUOUS; what pins "no silent lowering" here is
; the `not` inversion on the RUN line (exit non-zero) plus the string, mirrored
; character-for-character below.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i32 @f(i32 %a) #0 {
  %s = add i32 %a, 100
  ret i32 %s
}

define i32 @main() {
entry:
  %q = call i32 @cq_theta_si32(i32 0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 3
  br i1 %c, label %arm, label %merge

arm:
  %r = call i32 @f(i32 4)
  br label %merge

merge:
  %y = phi i32 [ %r, %arm ], [ 5, %entry ]
  %keep = call i32 @cq_measure_si32(i32 %y)
  br label %second

second:
  %x = trunc i32 %y to i1
  %b = call i1 @cq_theta_i1(i1 %x, double 5.000000e-01)
  %b3 = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br i1 %b, label %ph, label %join

ph:
  call void @cq_phi(double 7.000000e-01)
  br label %join

join:
  %mm = call i1 @cq_measure_i1(i1 %b3)
  %zz = zext i1 %mm to i32
  %t = add i32 %zz, %keep
  ret i32 %t
}

attributes #0 = { nounwind willreturn memory(none) }

; CHECK: cq controlled lowering: condition predates a non-diagonal gate under quantum control
