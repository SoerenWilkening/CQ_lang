; lowering_accept_undef_theta_seed_zero.ll — ACCEPT (bd z9t1, owner ruling
; 2026-09-14). THE `undef` SPELLING of the normalized rotation seed.
;
; RULED, verbatim: "we should NOT make every uninitialized variable to 0. Jut
; before it hits cq_alloc_*. then clang still can exploid it" / "both codes are
; supposed to compie!! also no warnings."
;
; So the rule attaches to the QUBIT ALLOCATION, not to the C variable: an
; `undef`/`poison` SEED reaching a SOURCE `@cq_theta_<sfx>`'s arg-0 becomes a
; concrete zero of that type, SILENTLY (no warning, no diagnostic, exit 0), and
; CQ makes no claim at all about the variable — `clang` keeps every liberty it
; already had, including deleting a branch that reads the same uninitialized
; value (measured: DIAG_2026-09-14.md Q2 row iv).
;
; WHY THIS IS A TIGHTENING AND NOT A LOOSENING. Before this rule the same module
; compiled SILENTLY and handed `i1 undef` straight to `cqrt_alloc_i1`, so which
; basis state the rail started in was whatever the `-O0` stage-3 link
; materialised — the trace printed `cqrt_alloc_i1(1)`, a value the program never
; wrote. Now the rail is deterministically |0> and every reader of the emitted
; module sees ONE constant, which REMOVES the `declineUnpairedUndefLiterals`
; multi-materialisation hazard rather than creating it.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     call i32 @cqrt_alloc_i1(i1 false)
; CHECK:     call void @cqrt_ry_i1(
; CHECK:     call i1 @cqrt_measure_i1(
;
; The seed slot must carry NO literal undef/poison anywhere in the emitted
; module. Its OWN whole-file prefix (Rule 12 hygiene (a): a positive CHECK above
; a negative windows it), and the patterns are TYPED — a bare `-NOT: undef`
; matches this file's own `; ModuleID = '...undef...'` header line (bd qta2).
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
; STREAM:      %m1 = call i1 @cqrt_measure_i1(i32 %h)

target datalayout = "e-m:o-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx"

declare i1 @cq_theta_i1(i1, double)
declare i1 @cq_measure_i1(i1)

define i1 @example() {
entry:
  %q = call i1 @cq_theta_i1(i1 undef, double 5.000000e-01)
  %m = call i1 @cq_measure_i1(i1 %q)
  ret i1 %m
}
