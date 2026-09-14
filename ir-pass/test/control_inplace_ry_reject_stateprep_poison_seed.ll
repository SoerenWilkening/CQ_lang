; control_inplace_ry_reject_stateprep_poison_seed.ll — ⚠ **ACCEPT SINCE bd z9t1
; (owner ruling 2026-09-14). THE `reject` IN THE FILE NAME IS HISTORY.** The
; `poison` sibling of `control_inplace_ry_reject_stateprep_undef_seed.ll`; read
; that file's header for the full account of what moved and why the clause-1 pin
; is now `..._stateprep_constexpr_undef_seed.ll`. The rename is deferred to a
; rename-only change (lesson L8: a `git mv` can be resurrected by a merge).
;
; *** WHAT THIS FILE UNIQUELY PINS, and it is the reason it is not redundant with
; its `undef` twin: ONE PREDICATE COVERS BOTH SPELLINGS. *** `PoisonValue`
; derives from `UndefValue`, so the single `isa<UndefValue>` in
; `normalizeUndefRotationSeed` — and the single `valueCarriesUndef` gate in front
; of it — must catch `poison` everywhere it catches `undef`, at the SEED and at
; the phi incoming alike. The emitted stream below is BYTE-IDENTICAL to the twin's
; (measured 2026-09-14, `diff` of the two lowered modules is empty apart from the
; module header), which is the strongest form that claim can take: two source
; spellings, one circuit.
;
; Narrow the predicate to `isa<UndefValue>(V) && !isa<PoisonValue>(V)` — the
; obvious "be conservative about poison" mutation — and this file goes red while
; its twin stays green.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s > %t.cqd0.ll
; RUN: %filecheck %s < %t.cqd0.ll
;
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %u0)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 5.000000e-01)
; CHECK:     %[[F:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_eq_i32_hl(i32 %[[H]], i32 5)
; CHECK:     %[[R:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 0)
; CHECK:     call void @cqrt_ry_i32_controlled(i32 %[[F]], i32 %[[R]], double 9.000000e-01)
; CHECK:     call void @cq_template_icmp_eq_i32_hl_unc(i32 %[[F]], i32 %[[H]], i32 5)
; CHECK:     call void @cqrt_free(i32 %[[F]])
;
; RUN: %filecheck %s --check-prefix=NOUNDEF < %t.cqd0.ll
; NOUNDEF-NOT: i32 undef
; NOUNDEF-NOT: i32 poison
;
; RUN: %filecheck %s --check-prefix=NOPREPFREE < %t.cqd0.ll
; NOPREPFREE-NOT: cqrt_free(i32 %h1)

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
; STREAM:      %h = call i32 @cqrt_alloc_i32(i32 %u0)
; STREAM:      call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
; STREAM:      %h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
; STREAM:      %h1 = call i32 @cqrt_alloc_i32(i32 0)
; STREAM:      call void @cqrt_ry_i32_controlled(i32 %h_cmp, i32 %h1, double 9.000000e-01)
; STREAM:      call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
; STREAM:      call void @cqrt_free(i32 %h_cmp)
; STREAM:      %m = call i32 @cqrt_measure_i32(i32 %h)
; STREAM:      %m2 = call i32 @cqrt_measure_i32(i32 %h1)

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %u0) {
entry:
  %q = call i32 @cq_theta_si32(i32 %u0, double 5.000000e-01)
  %c = icmp eq i32 %q, 5
  br i1 %c, label %arm, label %merge
arm:
  %rt = call i32 @cq_theta_si32(i32 poison, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ poison, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mq
}
