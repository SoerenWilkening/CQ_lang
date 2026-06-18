; lowering_uncompute_compare_icmp.ll — Phase 5 WI-7 DECLINE (PRD §2.12 / §2.3;
; the Rule-13 clearance blocker). A DEAD, source-derived, tainted DATA-position
; integer compare (`icmp` — ordinary C `int w = (q < 5)`) reaching the whole-DAG
; uncompute spine.
;
; The compare lowers to a `cq_template_icmp_<pred>_<W>_hl` flag-handle producer,
; and the uncompute axis is deliberately binary + unary + cast ONLY — compares
; get NO `_unc` grid (tools/opcode_table.yaml). Pre-fix, `isInverseEmittable`
; (EmitInverse.cpp) accepted the compare (it excluded only `_controlled`/`_inv`/
; `_unc`, never the compare family), so the WI-5 un-invertible pre-scan never
; fired and `emitInverseCall` minted the NONEXISTENT symbol
; `cq_template_icmp_slt_i32_hl_unc`: `opt` exited 0 and `opt -verify` was clean
; (well-typed `void(i32,i32,i32)`), but the program FAILED TO LINK against the
; generated runtime — the exact verify-clean / FileCheck-clean / link-only class
; (WI-6 / DD-3) the spine was hardened against, and an over-accept (Prime
; Directive): accepting an unprovable shape and emitting a dangling symbol rather
; than declining LOUDLY. The forward path guards this same hazard in
; `CompareLowering`; the uncompute path now does too — a recovered compare gate
; routes to the existing `kMsgUninvertible` loud decline (over-decline is safe).
;
; The dead `zext` widen-flag terminal off the compare keeps a real
; `cq_template_*` lineage; the `zext` HAS a void `_unc`, the compare does NOT, so
; the decline is on the compare gate specifically (the prep `cqrt_ry` and the
; `zext` are both invertible).
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %c = icmp slt i32 %q, 5      ; tainted data-position compare -> flag (no _unc form)
  %w = zext i1 %c to i32       ; DEAD widened-flag terminal (zext has a _unc; the icmp does not)
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain contains an un-invertible primitive
