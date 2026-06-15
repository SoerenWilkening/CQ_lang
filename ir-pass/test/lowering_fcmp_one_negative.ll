; lowering_fcmp_one_negative.ll — DECLINE probe (test_C_libtooling-jvun): a
; tainted data-position fcmp with an OUT-OF-SCOPE predicate must be diagnosed
; LOUDLY, never silently lowered to a non-existent template symbol.
;
; The runtime ships only 6 fcmp predicates ({oeq,une,olt,ogt,ole,oge}; YAML
; `predicates.fcmp`). `fcmp one` (ordered-not-equal) has NO template. Before
; jvun, `rewriteCompare`→`lowerCompareImpl` computed the predicate name + width
; and `WidthDispatch::compareTemplateFn` did an UNCONDITIONAL
; `getOrInsertFunction(cq_template_fcmp_one_f32_hl)` — a symbol that does not
; exist. `opt` exited 0, `opt -verify` was clean, and the program LINK-FAILED at
; Stage 3: a verify-clean miscompile (Rule 1 fail-loud violated). jvun adds the
; `compareInScope(op,pred)` predicate-scope gate, so this now declines loudly
; (and leaves the well-typed i1 compare standing — verify-clean), exactly like
; the unsupported-width / Q+Q bails.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}no template{{.*}}
; The out-of-scope predicate must NOT be lowered to ANY fcmp template symbol:
; CHECK-NOT: cq_template_fcmp_one
declare float @cq_theta_f32(float, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  ; Tainted handle compared with an OUT-OF-SCOPE fcmp predicate (`one`).
  %c = fcmp one float %a, 1.0
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
