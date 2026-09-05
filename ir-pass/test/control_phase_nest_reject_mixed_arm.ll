; control_phase_nest_reject_mixed_arm.ll — DECLINE. THE MIXED NEST: an in-place
; `cq_theta` (Ry) in the OUTER arm beside the inner PHASE region (prep-b OQ-6,
; the migrated `slice_control_phase_nest_deep.c` — ⚠ NOT IN THIS TREE YET: the e2e slices for the register-free surface live on branch
; `3qlq-inc1-slices` (prep-b) and are merged before this epic's commit. MEASURED at this
; HEAD, 63 of the 66 `tests/e2e/*.c` that call `cq_phi` FAIL STAGE 1 against the
; register-free `CQ.h`, so `ir-pass-lit` is this branch's ONLY gate and every e2e claim
; below is a statement about that other branch (Rule-13 round-2 finding F-R2-4).
; That slice is prep-b's; this fixture does not depend on it.)
;
;     if (q == 5) { s = cq_theta(s, 0.7); if (r == 3) cq_phi(0.3); }
;
; P4 is the HOMOGENEOUS phase nest and this is not one, but the reason it must
; decline is stronger than scope: an Ry RELABELS a register. The whole P4
; argument for minting the inner flag at the OUTER branch is that NO gate in the
; region touches a register, so the inner compare reads the same basis the source
; compare reads. A `cq_theta` in `Mid` breaks exactly that premise — the flag
; would be minted BEFORE the Ry while the source compare runs AFTER it — and the
; failure is the stale-condition class: the wrong branch is marked, the strip
; does not return the flag to |0>, and the free becomes a hidden measurement.
;
; The message is `impure phase arm`, from the pre-existing homogeneity proof the
; region falls through to: P4's classifier returns NotApplicable on an outer arm
; holding anything but phase calls and the inner condition, and the ordinary
; `recoverRegion`/`recoverRegionTree` path then names the reason precisely.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, i32 %u1) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %s = call i32 @cq_theta_si32(i32 %u1, double 1.250000e-01)
  %c1 = icmp sgt i32 %q, 5
  br i1 %c1, label %mid, label %merge
mid:
  %s2 = call i32 @cq_theta_si32(i32 %s, double 7.000000e-01)
  %c2 = icmp slt i32 %q, 9
  br i1 %c2, label %inner, label %merge
inner:
  call void @cq_phi(double 7.500000e-01)
  br label %merge
merge:
  %p = phi i32 [ %s, %entry ], [ %s2, %mid ], [ %s2, %inner ]
  %m = call i32 @cq_measure_si32(i32 %q)
  %n = call i32 @cq_measure_si32(i32 %p)
  %t = add i32 %m, %n
  ret i32 %t
}

; CHECK: cq controlled lowering: impure phase arm under quantum control
