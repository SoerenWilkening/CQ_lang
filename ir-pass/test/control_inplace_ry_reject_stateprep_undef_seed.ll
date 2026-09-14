; control_inplace_ry_reject_stateprep_undef_seed.ll — ⚠ **ACCEPT SINCE bd z9t1
; (owner ruling 2026-09-14). THE `reject` IN THE FILE NAME IS HISTORY.** The
; rename is deliberately NOT done in this commit: a `git mv` can be resurrected
; by a merge, leaving one module under two names with contradictory verdicts and
; invisible to every review that ran before the merge (lesson L8). It is filed as
; its own rename-only change.
;
; WHAT IT USED TO PIN, and why that subject no longer exists. Written 2026-09-05
; (round-1 Rule-13 review, lens L1 finding F-L1-2, probe `p/d01_undef_seed.ll`)
; to pin F1's FIRST sub-clause — the state-prep seed must be a `ConstantInt` or
; `ConstantFP`, and an `UndefValue` is neither. The z9t1 normalizer now rewrites a
; whole-value `undef`/`poison` SEED to a concrete zero at COLLECTION time
; (`normalizeUndefRotationSeed`, called from `collectAndSeed`), so clause 1 can no
; longer be reached through an `UndefValue` at all and this module is the ruled
; customer rather than an off-pattern input.
;
; *** THE CLAUSE-1 PIN MOVED, IT WAS NOT DROPPED ***:
; `control_inplace_ry_reject_stateprep_constexpr_undef_seed.ll` reaches the same
; clause through the OTHER reason its comment names (a `ConstantExpr` is a
; link-time constant this compiler cannot read), and doubles as the negative half
; of the normalizer's red-green pair. Relax clause 1 to `isa<Constant>` and THAT
; file goes red; this one no longer can.
;
; WHY THE ACCEPT IS THE RIGHT CIRCUIT, not merely a permitted one. The source
; shape is `int r; if (q == 5) r = cq_theta(r, 0.9);` — an uninitialized object
; prepared under quantum control. Both of its reads (the seed and the merge phi's
; straight-through incoming) are `undef`, both are normalized to the same
; `i32 0`, and the emitted stream is the drbq `StatePrep` kind: a FRESH |0> rail
; plus one `cqrt_ry_i32_controlled` under the minted compare flag. Nothing is
; cloned, nothing is measured that the user did not write, and the flag is
; stripped and freed at |0>.
;
; AND IT REMOVES A LITERAL-INTEGRITY HAZARD RATHER THAN CREATING ONE. The old
; header argued that relaxing clause 1 would emit `cqrt_alloc_i32(i32 undef)` —
; a literal `undef` in a gate slot, which the `-O0` stage 3 may materialise
; differently at each read (bd xy9n). That argument is UNAFFECTED and still
; correct: the normalizer is why no such slot is emitted here. The seed is `i32
; 0` in the alloc, and the NOUNDEF prefix below is what holds that.
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
; The seed slot carries no literal undef/poison. Typed patterns in their own
; whole-file prefix (Rule 12 hygiene (a); a bare `-NOT: undef` would match this
; file's own `; ModuleID` line — bd qta2):
; RUN: %filecheck %s --check-prefix=NOUNDEF < %t.cqd0.ll
; NOUNDEF-NOT: i32 undef
; NOUNDEF-NOT: i32 poison
;
; The prepared rail is NEVER freed — `Ry(0.9)|0> != |0>`, so Rule 6 leaves it
; allocated rather than measuring it. Its own NOT-only prefix so the scan covers
; the WHOLE file rather than only the tail below the last positive match.
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
  %rt = call i32 @cq_theta_si32(i32 undef, double 9.000000e-01)
  br label %merge
merge:
  %rm = phi i32 [ %rt, %arm ], [ undef, %entry ]
  %mq = call i32 @cq_measure_si32(i32 %q)
  %mr = call i32 @cq_measure_si32(i32 %rm)
  ret i32 %mq
}
