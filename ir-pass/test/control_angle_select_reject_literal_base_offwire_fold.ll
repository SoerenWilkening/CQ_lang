; control_angle_select_reject_literal_base_offwire_fold.ll — DECLINE (S3, a LITERAL
; untainted base; bd test_C_libtooling-drbq.13). THE COUNTER-EXAMPLE that keeps the
; literal base out of bd z0re's widening, which admits only a RUNTIME base.
;
;     int t = q / 4; int r;
;     if (t == 5) { r = t; cq_theta(&r, .9); } else { r = 5; cq_theta(&r, .3); }  // probe a1, from C
;     return cq_measure(r) + cq_measure(t);
;
; MEASURED at clang -O1 (this body is its stage-1 IR, minimised): IPSCCP pins `t`
; to 5 on the true edge and rewrites the true arm's `@cq_theta_si32(t, .9)` to
; `@cq_theta_si32(5, .9)`; SimplifyCFG then sinks the two now-arg-0-identical thetas into
; ONE theta reading an angle select; InstCombine rewrites the compare SIDEWAYS off
; `t` (`(q & -4) == 20`). `t = sdiv q, 4` is STILL LIVE and measured. The source
; rotated `t` IN PLACE on the `t == 5` branch; the module is an angle select on the
; LITERAL base 5. Admitting a literal base would prepare a FRESH |5⟩ and leave `t`
; unrotated — the F-R1-1 class of F2's header, OFF the condition's wire (the
; compare reads `and q, -4`, a sibling of `t`), so NOT the owner-ruled α trade.
;
; The FLAT DIAMOND prep refuses the identical hazard at F2 (probe `a8`: `int r = 5;
; if (t == 5) { r = t; cq_theta(&r, .9); }` declines `state prep seed is proven equal to
; the condition register`), because there the pin is on the REGION'S own edge.
; ⚠ CORRECTED (Rule-13 r1A F-r1A-2, L7): an earlier spelling of this paragraph
; read as "the diamond is safe". It is not in general — bd `fmt3` (PRE-EXISTING P1)
; is this very fold NESTED inside a diamond prep: the pinning branch is an INNER
; one `-O1` deletes, and F2, anchored on the OUTER region's edges, misses it
; (r1A probe `a6` accepts on BOTH binaries; its flat twin `a6f` declines). F2 is
; an EDGE analysis (`LazyValueInfo::getConstantRangeOnEdge`), a select has no
; edge, and LLVM 19 exposes LVI's condition analysis only through a branch edge or
; a select-OPERAND use — so the literal angle-select base stays declined, with the
; string it has always had (OWNER RULING 2026-09-28 on bd drbq.13: the literal
; base STAYS DECLINED).
;
; A RUNTIME base cannot be the image of this CONSTANT fold (IPSCCP substitutes only
; constants, and SimplifyCFG sinks a call only when at most ONE operand needs a φ,
; so arg-0 must already agree in both arms — probes a3/a4 keep the if/else unsunk),
; which is why `control_angle_select_ry_runtime_base.ll` ACCEPTS. (The RELATIONAL
; fold of bd zt0b can put a runtime value into an arg-0; its diamond-prep image is a
; module indistinguishable from a legitimate program — `…_runtime_seed_postfold*.ll`
; — closed at the C level for DIRECT calls by bd fmt3 option B, `nomerge` on
; `cq_theta_*`; still open through a function pointer, bd `4e4p`.)
;
; ⚠ SINCE bd fmt3 OPTION B LANDED (2026-09-29) THIS if/else C spelling no longer folds:
; `nomerge` keeps the two thetas apart, no angle select forms, and the if/else
; declines where the pass sees it — measured, drbq.13's `a1.c` (fmt3 `d13a1.c`)
; now declines `if/else state prep allocates two rails`. The literal-base decline itself stays reachable from
; PLAIN C through the TERNARY spelling `int r = 6; cq_theta(&r, c ? .75 : .25)` (Rule-13 r2
; probe `t3`/`t3nm`: `rotation angle` with and without `nomerge`), so this file pins
; a plain-C decline, not only what S3 owes a hand-IR front end. (⚠ CORRECTED, r2
; F-r2-1: an earlier spelling said "hand-IR / non-C front end" only.)
;
; ⚠ WHAT THIS FILE PINS NOW (bd test_C_libtooling-dm7f.54 round-1 review, L7 —
; read this before the history above). Since the delegated ruling
; `ruling-dm7f54-literal-base-and-ifelse-prep-2026-10-15` a literal Ry angle-select
; base IS admitted when the consumer carries `nomerge` AT THE CALL SITE and no
; value is proven equal to the seed at the consumer
; (`angleSelectLiteralSeedAdmissible` + `angleSelectLiteralSeedPinned`). This module
; has NO call-site `nomerge`, so it pins the NO-NOMERGE case: the module may be
; the SimplifyCFG-sink image the paragraphs above measured, and it keeps the
; drbq.13 string. (It would NOT be refused by the pin check — `%t = sdiv %q, 4`
; is not pinned at this consumer, which has no dominating edge; the sink erased
; it — so the no-nomerge clause is the ONLY fence for it.) The R10 accept/decline
; pair for the attribute alone is `control_angle_select_ry_fresh_icmp_int.ll` /
; `..._reject_fresh_icmp_int_no_nomerge.ll`; the function-pointer route is
; `..._reject_literal_seed_fnptr.ll`. ⚠ L9: the admitted population inherits bd
; uw5u (`int m = (t == 5) ? t : 5;` folds to the literal with no merge and no
; edge), already open for the plain `cq_theta(&m, θ)` on the same literal.
; RUN: not %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s 2>&1 | %filecheck %s
; CHECK: error{{.*}}rotation angle under quantum control

declare i32 @cq_theta_si32(i32, double)
declare i32 @cq_measure_si32(i32)

define i32 @example(i32 %m) {
entry:
  %q = call i32 @cq_theta_si32(i32 %m, double 5.000000e-01)
  %a = and i32 %q, -4
  %c = icmp eq i32 %a, 20
  %ang = select i1 %c, double 9.000000e-01, double 3.000000e-01
  %r = call i32 @cq_theta_si32(i32 5, double %ang)
  %t = sdiv i32 %q, 4
  %mr = call i32 @cq_measure_si32(i32 %r)
  %mt = call i32 @cq_measure_si32(i32 %t)
  %s = add nsw i32 %mt, %mr
  ret i32 %s
}
