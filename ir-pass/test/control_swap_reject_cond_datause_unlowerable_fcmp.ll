; control_swap_reject_cond_datause_unlowerable_fcmp.ll — DECLINE probe
; (test_C_libtooling-jvun, the cond-data-use detect-before-mutate half): a
; tainted control compare reused as DATA, where the data lineage carries an
; OUT-OF-SCOPE fcmp predicate — must decline PRE-mutation (Rule 9).
;
; `%c = icmp sgt q, 5` feeds the `br` (control) AND, as data, `%f = uitofp %c to
; float` (IN SCOPE) then `%g = fcmp false float %f, 0.0` (OUT OF SCOPE: `false`
; has no template). The lineage escapes via `ret`, so `condDataUseDisposition`
; USED to walk %c→%f(cast,ok)→%g(compare, NO predicate gate)→ShareOk → the flat
; path set ShareCondFlag, `emitRegion` ROUTED (cqrt_cswap) + `flattenRegion`
; erased the diamond, and THEN `lowerOps` minted the non-existent
; `cq_template_fcmp_false_f32_hl` with NO diagnostic at all (exit 0, link-fail at
; Stage 3) — a mutate-then-silent-miscompile worse than the loud cast case.
;
; jvun gates the compare predicate in `condDataUseDisposition` (the same
; `compareInScope` the data path now consults): an out-of-scope predicate on the
; lineage yields `Unlowerable` and declines HERE, in detection, before any
; route/flatten. Over-declining is always safe (Prime Directive). After 8rvn
; (Phase 7.1 iw81.4 §4.4) broadened the fcmp set to the full ordered/unordered
; comparison family, the degenerate `true`/`false` are the only out-of-set fcmp
; predicates left — so `false` is the standing residual for this call site.
;
; ADVERSARIAL POSTCONDITION: the loud pre-mutation diagnostic fires AND no route
; (`cqrt_cswap`) nor bogus fcmp symbol is ever emitted — proving detect-before-
; mutate.
;
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}condition data use has no template under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cq_template_fcmp_false
declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_phi_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0, double %a) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp sgt i32 %q, 5
  %f = uitofp i1 %c to float         ; IN-SCOPE cast on the lineage
  %g = fcmp false float %f, 0.0      ; OUT-OF-SCOPE fcmp predicate (no template)
  %z = zext i1 %g to i32
  br i1 %c, label %arm, label %merge
arm:
  %q1 = call i32 @cq_phi_si32(i32 %q, double %a)
  br label %merge
merge:
  %qm = phi i32 [ %q1, %arm ], [ %q, %entry ]
  %m  = call i32 @cq_measure_si32(i32 %qm)
  %r  = add i32 %m, %z               ; keep %z live — escapes via ret
  ret i32 %r
}
