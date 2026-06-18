; lowering_uncompute_compare_fcmp.ll — Phase 5 WI-7 DECLINE (PRD §2.12 / §2.3;
; the Rule-13 clearance blocker, floating-point sibling of
; lowering_uncompute_compare_icmp.ll). A DEAD, source-derived, tainted
; DATA-position floating compare (`fcmp` — ordinary C `int w = (q < 5.0)`)
; reaching the whole-DAG uncompute spine.
;
; Same defect and same fix as the `icmp` sibling: the compare lowers to a
; `cq_template_fcmp_<pred>_<W>_hl` flag-handle producer, the uncompute axis has
; NO compare `_unc` grid (tools/opcode_table.yaml), and pre-fix the spine minted
; the nonexistent `cq_template_fcmp_olt_f64_hl_unc` (verify-clean, FileCheck-clean,
; link-only — reproduced on the live build). The compare gate now routes to the
; existing `kMsgUninvertible` loud decline (over-decline is safe; Prime Directive).
; The `fptosi` cast down to the i1-ish flag is a separate invertible gate; the
; decline is on the `fcmp` specifically.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
declare double @cq_theta_f64(double, double)

define void @slice(double %x) {
entry:
  %q = call double @cq_theta_f64(double %x, double 2.500000e-01)
  %c = fcmp olt double %q, 5.000000e+00  ; tainted data-position fp compare -> flag (no _unc form)
  %w = zext i1 %c to i32                  ; DEAD widened-flag terminal off the compare lineage
  ret void
}

; CHECK: error{{.*}}cq uncompute: dead chain contains an un-invertible primitive
