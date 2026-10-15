; control_swap_select_f64.ll — ACCEPT: the fp-DATA `select` un-staging positive
; (§16.4 Option B; fp-data-select-PRD §5, issue test_C_libtooling-kjd1). A
; tainted-condition f64 select whose result is MEASURED (data, not an angle) now
; lowers as the 4.4 controlled-XOR copy merge over the NEW frozen-designate
; `cqrt_copy_f64_controlled` primitive, minted by the select-local
; `ControlledSymbols::copyControlledFpFn` (NEVER the shared `copyControlledFn`,
; whose integer-only null IS the live fp classifier for the 6.5 classical-call
; arm — the minter-null-is-a-classifier hazard).
;
; This is the FIRST accepted fcmp-minted select merge: the condition is
; `fcmp ogt double`, so the flag mint/strip is `cq_template_fcmp_ogt_f64_hl` /
; `_inv` (CompareLowering fp predicates), not the icmp family. The angle fence
; holds by the §2 three-legged mechanism: gate 3 proved `%sel` reaches no
; rotation arg-1 along any value-preserving carrier, the escape guards own the
; memory/call routes, and `declineTaintedAngle` backstops every value-changing
; re-realization. The classical false operand `%x` is materialized via
; `cqrt_alloc_f64` (the established 4.4 copy-merge carve-out, now fp: legitimate
; BECAUSE gate 3 already proved the select is data — the rail is a copy SOURCE,
; never an arg-1).
;
; The ORDERED six-step CHECK is the §16.3 bracket-order contract (the cqrt_x
; pair encloses ONLY the second copy — a mis-bracket has the identical symbol
; multiset); CHECK-NOT pins that no INTEGER copy symbol is minted for an fp
; merge (the width tags the symbol name only; handles stay i32, Rule 15).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
declare double @cq_theta_f64(double, double)
declare double @cq_measure_f64(double)

define double @example(double %u0, double %x) {
entry:
  %q   = call double @cq_theta_f64(double %u0, double 5.000000e-01)
  %c   = fcmp ogt double %q, 5.000000e-01          ; tainted fcmp condition
  %sel = select i1 %c, double %q, double %x        ; f64 DATA mux (theta-derived vs classical)
  %m   = call double @cq_measure_f64(double %sel)  ; data sink (NOT an angle)
  ret double %m
}

; all-f64 stream; handles i32, classical operands at their real f64 width:
; CHECK:     %[[Q:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double %u0)
; CHECK:     call void @cqrt_ry_f64(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_fcmp_ogt_f64_hl(i32 %[[Q]], double 5.000000e-01)
; CHECK:     %[[OUT:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_f64(double 0.000000e+00)
; CHECK:     call void @cqrt_copy_f64_controlled(i32 %[[F]], i32 %[[Q]], i32 %[[OUT]])
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cqrt_xorc_f64_controlled(i32 %[[F]], i32 %[[OUT]], double %x)
; CHECK:     call void @cqrt_x(i32 %[[F]])
; CHECK:     call void @cq_template_fcmp_ogt_f64_hl_unc(i32 %[[F]], i32 %[[Q]], double 5.000000e-01)
; CHECK:     call void @cqrt_free(i32 %[[F]])
; CHECK:     call double @cqrt_measure_f64(i32 %[[OUT]])
; the fp merge mints NO integer copy and NO uncontrolled fp copy (no consumer):
; CHECK-NOT: cqrt_copy_i
; CHECK-NOT: call void @cqrt_copy_f64(
