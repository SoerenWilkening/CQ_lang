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
; emission/flatten. The decline is loud, so it is never silent, but it is an
; over-decline to remove (R1): `fcmp false` is the constant 0 and needs no
; template. No bd issue tracks it as of 2026-10-05. After 8rvn
; (Phase 7.1 iw81.4 §4.4) broadened the fcmp set to the full ordered/unordered
; comparison family, the degenerate `true`/`false` are the only out-of-set fcmp
; predicates left — so `false` is the standing residual for this call site.
;
; ADVERSARIAL POSTCONDITION: the loud pre-mutation diagnostic fires AND no route
; (`cqrt_cswap`) nor bogus fcmp symbol is ever emitted — proving detect-before-
; mutate.
;
;
; 3qlq(prep_a2): the asserted diagnostic was WIDENED to the whole DS_Error
; text on the Inc-1 binary.  The refusing CLAUSE is UNCHANGED — the new
; string ENDS WITH the old one — and this is Rule 12's
; character-for-character mirror rather than a disposition change: a
; suffix-only assertion would still match if some OTHER subsystem grew a
; message with the same tail.
; OLD: condition data use has no template under quantum control
; NEW: cq controlled lowering: condition data use has no template under quantum control
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}cq controlled lowering: condition data use has no template under quantum control
; CHECK-NOT: cqrt_cswap
; CHECK-NOT: cq_template_fcmp_false
; 3qlq: migrated from register cq_phi (tainted arm -> void call, merge phi dissolved)
declare void @cq_phi(double)
declare i32 @cq_theta_si32(i32, double)
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
  call void @cq_phi(double %a)
  br label %merge
merge:
  %m  = call i32 @cq_measure_si32(i32 %q)
  %r  = add i32 %m, %z               ; keep %z live — escapes via ret
  ret i32 %r
}
