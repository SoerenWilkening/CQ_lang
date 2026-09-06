; control_phase_switch_reject_default_edge.ll — DECLINE. A tainted-scrutinee
; phase `switch` whose DEFAULT EDGE does not go straight to the merge (the 4.5 C5
; shape).
;
; ⚠ RENAMED AND RETITLED BY Rule-13 ROUND-2 FINDING F-R2-6. It shipped as
; `..._default_body.ll`, claiming to pin "a NON-EMPTY default arm" — and it does
; not. MEASURED, by mutating the module: DELETING the named cause (the
; `call void @cq_phi(double 9.000000e-01)` from `%def`, leaving `def: br label
; %merge`) still DECLINES, with the identical message; only re-pointing the
; default EDGE at `%merge` and deleting the block makes it ACCEPT. So the
; discriminator is the EDGE, which the paragraph below already stated correctly
; while the name and the first line said something else. The accept fixture
; agrees — `control_phase_switch_kickback.ll`'s switch is
; `switch i32 %q, label %merge [...]`.
;
; The consequence worth carrying: an EMPTY-BUT-DISTINCT default block declines
; too, and that is an OVER-DECLINE — safe, and not reachable from plain C
; (SimplifyCFG folds an empty default straight onto the merge), which is why it
; gets this sentence rather than a fixture of its own that would be the same
; discriminator under a second name (the Inc-4 "DER lesson").
;
; The accept shape requires the default edge to go STRAIGHT to the merge. A
; default BODY fires on `¬(f_0 ∨ … ∨ f_{n-1})`, which needs an OR network over
; every case flag plus a negation bracket — buildable with the machinery already
; here (`CondTreeEmit`'s OR node), but a second network per region with its own
; teardown order and no probe family. The 4.5 ladder declined C5 for the same
; reason and this keeps that disposition rather than quietly widening it.
; (Prose deliberately does not spell the lit directive token verbatim — lit
; scans EVERY line for it, so quoting it in a comment mints a bogus run line.)
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s

declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  switch i32 %q, label %def [
    i32 0, label %a0
    i32 1, label %a1
  ]
a0:
  call void @cq_phi(double 1.000000e-01)
  br label %merge
a1:
  call void @cq_phi(double 2.000000e-01)
  br label %merge
def:
  call void @cq_phi(double 9.000000e-01)
  br label %merge
merge:
  %m = call i32 @cq_measure_si32(i32 %q)
  ret i32 %m
}

; CHECK: cq controlled lowering: control flow under quantum control
