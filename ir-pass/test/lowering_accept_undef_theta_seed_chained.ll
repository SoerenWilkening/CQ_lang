; lowering_accept_undef_theta_seed_chained.ll — ACCEPT (bd z9t1). A CHAINED
; theta standing on a NORMALIZED rail: the second rotation's arg-0 is an SSA
; handle, so the normalizer never looks at it, and the emitted stream below the
; seed is byte-for-byte what it was before the rule.
;
; THE POINT IS THE SOURCE/CHAINED SPLIT. `lowerRotations` decides
; `Chained = taint.Tainted.count(arg0)`: a SOURCE mints
; `cqrt_alloc_<W>(seed) + cqrt_ry_<W>`, a CHAINED one emits `cqrt_ry_<W>` on the
; handle it already has. The normalizer is SOURCE-ONLY BY CONSTRUCTION and not by
; a second spelling of that relation — `undef` is a `Constant`, a chained arg-0
; is an `Instruction`, and `valueCarriesUndef` is false for every non-Constant.
; So there is no width, no taint round and no fixpoint at which the two answers
; can disagree (the bd 9pum / L1 PREDICATE species asks exactly this question of
; any new fence that reads arg-0).
;
; This is `u3b.c` from `$PREV/diag_2026-09-14_probes/` reduced to its rotation
; chain (the DIAG measured it ACCEPT at 16 trace lines on the oracle, seeded
; `cqrt_alloc_i1(i1 undef)`; the only line that moves is the seed).
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; ONE alloc for the whole chain, seeded with the normalized zero, then the two
; rotations on the SAME handle:
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H]], double 5.000000e-01)
; CHECK:     call void @cqrt_ry_i1(i32 %[[H]], double -5.000000e-01)
; CHECK:     call i1 @cqrt_measure_i1(i32 %[[H]])
;
; RUN: %filecheck %s --check-prefix=ONEALLOC < %t.cqd0.ll
; ONEALLOC-COUNT-1: call i32 @cqrt_alloc_i1(
;
; RUN: %filecheck %s --check-prefix=NOUNDEF < %t.cqd0.ll
; NOUNDEF-NOT: i1 undef
; NOUNDEF-NOT: i1 poison

;
; *** THE WHOLE EMITTED STREAM, PINNED IN ORDER, WITH NOTHING ELSE ALLOWED. ***
; The two `--implicit-check-not` patterns carry a negative over the ENTIRE file
; between every pair of STREAM lines, so ANY extra emitted gate — an injected
; `cqrt_x` on a user register, a second `cqrt_ry`, a `cqrt_cswap`, a `cqrt_free`,
; a measurement the user did not write (Rule 5) — reddens this prefix wherever it
; is placed. MEASURED with `$SES/trackU/probes/impl/inject_u.py`, not asserted:
; strip this prefix and 11 of 17 mutations over two of these fixtures go MISSED
; (injected `cqrt_x`, extra `cqrt_free`, extra `cqrt_ry`, `cqrt_cswap`, swapped
; copy pair, extra measurement); with it, 0 MISSED of 67 over all nine. The
; patterns match CALL SITES only (`call {{.*}}@cqrt_`), so the module's trailing
; `declare` lines are untouched.
; RUN: %filecheck %s --check-prefix=STREAM \
; RUN:   --implicit-check-not='call {{.*}}@cqrt_' \
; RUN:   --implicit-check-not='call {{.*}}@cq_template_' < %t.cqd0.ll
; STREAM:      %h = call i32 @cqrt_alloc_i1(i1 false)
; STREAM:      call void @cqrt_ry_i1(i32 %h, double 5.000000e-01)
; STREAM:      call void @cqrt_ry_i1(i32 %h, double -5.000000e-01)
; STREAM:      %m1 = call i1 @cqrt_measure_i1(i32 %h)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %q0 = call i1 @cq_theta_i1(i1 undef, double 5.000000e-01)
  %q1 = call i1 @cq_theta_i1(i1 %q0, double -5.000000e-01)
  %m = call i1 @cq_measure_i1(i1 %q1)
  ret i1 %m
}
