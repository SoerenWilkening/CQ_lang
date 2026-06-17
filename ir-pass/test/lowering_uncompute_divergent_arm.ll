; lowering_uncompute_divergent_arm.ll — Phase 5 WI-5 DECLINE (PRD §2.4 / §2.12;
; IMPLEMENTATION §4 WI-5; bd memory divergent-arm-uncompute-soundness-guard). The
; reverted-`543bd85` shape: a tainted DATA handle whose MUTATING gates span the
; exclusive arms of a classical branch — `entry` preps `%h` (ry once on every
; path), then arm-a applies `cq_phi(a)` [rz(a)] ONLY and arm-b applies
; `cq_phi(b)` [rz(b)] ONLY, joined by a DEAD merge φ.
;
; The single whole-DAG adjoint lands at the merge post-dominator. But `rz(a)` and
; `rz(b)` each run on only ONE exclusive path, so neither DOMINATES the merge — a
; single unconditional `rz(-a)·rz(-b)` at the merge would fire BOTH inverses on
; BOTH paths (the register corrupted, then `cqrt_free`'d = a verify-clean silent
; quantum miscompile). Pre-WI-5 the placement guard `!DT.dominates(gate, At)`
; SILENTLY skipped (register leaked, `opt` exit 0). WI-5 flips it to a
; source-located loud decline: per-arm reverse-play is PHASE 4's job
; (the swap-route emitter), not Phase-5 data uncompute — Phase 5 declines and
; defers (PRD §2.4 settles the open policy: option (b), loud-diagnose).
;
; Contrast lowering_uncompute_branch_botharms.ll (ACCEPT): there the only mutation
; (`ry`) is in the common dominator `entry` and the arms carry a NON-mutating
; live-range φ — so the merge adjoint is sound. The divergence here is in the
; MUTATING gates, which is exactly what is rejected.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)

define void @slice(i32 %x, i1 %c) {
entry:
  %h = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  br i1 %c, label %arma, label %armb
arma:
  %ha = call i32 @cq_phi_si32(i32 %h, double 1.000000e-01)   ; mutating gate, arm-a only
  br label %merge
armb:
  %hb = call i32 @cq_phi_si32(i32 %h, double 2.000000e-01)   ; mutating gate, arm-b only
  br label %merge
merge:
  %hp = phi i32 [ %ha, %arma ], [ %hb, %armb ]               ; DEAD live-range merge
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain spans divergent control-flow arms
