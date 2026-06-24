; lowering_fcmp_false_negative.ll — RESIDUAL DECLINE probe (8rvn, Phase 7.1
; iw81.4 §4.4, decline-matrix D9). After 8rvn broadens the fcmp set to the full
; ordered/unordered comparison family (14 of LLVM's 16 fp predicates), the ONLY
; two predicates left OUT are the degenerate `true`/`false` (always-1/always-0;
; no comparison, never emitted by Clang). They have NO generated template, so a
; tainted data-position `fcmp false` must STILL loud-decline — never
; `getOrInsertFunction` a phantom `cq_template_fcmp_false_*` symbol (the ziov4
; hazard: an unresolved extern would pass `opt`/`opt -verify` clean and only
; LINK-FAIL at Stage 3, a verify-clean miscompile). `compareInScope` mirrors the
; YAML exactly, so `false` (and `true`) ride the same loud `diagnoseNoTemplate`
; decline as an unsupported width or a Q+Q data compare.
;
; This is the standing residual that proves the predicate-scope gate did not
; degrade to "accept everything" when 8rvn enlarged the set.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}no template{{.*}}
; The out-of-set predicate must NOT be lowered to ANY fcmp template symbol:
; CHECK-NOT: cq_template_fcmp_false
; CHECK-NOT: cq_template_fcmp_true

declare float @cq_theta_f32(float, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %a = call float @cq_theta_f32(float 2.0, double 5.000000e-01)
  ; Tainted handle compared with the OUT-OF-SET degenerate predicate `false`.
  %c = fcmp false float %a, 1.0
  %m = call i1 @cq_measure_i1(i1 %c)
  ret i1 %m
}
