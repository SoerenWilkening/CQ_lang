; lowering_control_classical_select.ll — WP6 classical-condition passthrough
; (PRD §0/§2.3, IMPLEMENTATION §1.3, §6). A `select i1` whose condition is NOT
; tainted is NOT a quantum control — it is left BYTE-UNTOUCHED. Detection keys
; strictly on taint of the condition (`ControlDetection`: `if
; (!taint.Tainted.count(Sel->getCondition())) continue;`), so no region is
; built and no controlled symbol is emitted; this fixture is the NEGATIVE pin
; (NO code change — it documents that the §1.3 condition-taint gate already does
; the right thing).
;
; The module IS quantum (a separate theta→measure slice on `%q`), so the pass
; does NOT take its no-quantum early-out — this genuinely exercises the
; "tainted module, but THIS select's condition is classical → untouched" path,
; not the trivial empty-module path. The classical `select i1 %classical, …`
; therefore survives verbatim while the unrelated theta lowers.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
; CHECK:     select i1
; CHECK-NOT: cq_template
; CHECK-NOT: cqrt_rz_i32_controlled
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)
define i32 @example(i1 %classical) {
entry:
  %q = call i32 @cq_theta_si32(i32 7, double 0.5)   ; unrelated quantum slice
  %m = call i32 @cq_measure_si32(i32 %q)            ; (keeps the module tainted)
  %r = select i1 %classical, i32 10, i32 20         ; condition NOT tainted → untouched
  ret i32 %r
}
