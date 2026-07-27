; lowering_uncompute_lshr_i32_hl.ll — witness restoration for the `_hl` (handle-
; LEFT, literal-RIGHT) logical-right-shift ADJOINT, bd `gowy`.
;
; WHY THIS FIXTURE EXISTS. Commit dbab515 ("tkju") DELETED NO FILES — do not go
; looking for removed slices. `git show --name-status --format='' dbab515` is 1 A
; + 75 M, ZERO D, and `tests/e2e` holds the same 249 `.c` slices at dbab515^ and
; at dbab515. What the commit did was DE-VENDOR 52 slices IN PLACE: it stripped
; the fictional SOFTWARE bodies they had vendored for Rule-18 HARDWARE keeps, and
; REGENERATED their goldens. The slices survive; what disappeared are golden trace
; LINES. For `cq_template_lshr_i32_hl_unc` those lines were its ONLY witness: at
; dbab515^ the sole tracked TEXTUAL occurrence outside `runtime/` was
; `tests/e2e/slice_libm_real_coshl.expected.log`, which carried 7 of them and was
; rewritten +7025/-19415 by the regeneration, leaving 0 (that slice's `.c` is
; still on disk today). `git grep` also hits stale BINARIES under
; `scratchpad_g387/` — those are build droppings, not witnesses. Note the
; asymmetry left behind: the FORWARD `cq_template_lshr_i32_hl` is still witnessed
; by 41 surviving `slice_libm_real_*` goldens (the exponent-field extractions in
; scalbn/logf/acosh/…), while its void ADJOINT twin lost every witness in the repo
; and now exists only as a generated stub in `runtime/cq_templates.c`. That is
; exactly backwards from where the risk is: the uncompute spine is where this
; project's verify-clean silent miscompiles live (Rule 13), so the adjoint is the
; half that must be pinned. This is a cheap ir-pass lit fixture, not an e2e slice;
; per bd `gowy` and Rule 12 no accept-predicate is added here, so a POSITIVE
; fixture is sufficient (no decline probe).
;
; THE SHAPE. `q = cq_theta; d = q >> 3` — a dead, source-derived tainted `lshr`
; with the tainted handle on the LEFT and the classical shift count on the RIGHT,
; i.e. the `_hl` template shape. Its mirror lives in the sibling fixture
; `lowering_uncompute_lshr_i32_lh.ll` (`lit >> q`). The PAIR is the point: the
; DD-3 slot mapping must be SHAPE-AWARE, because the void `_unc` emitter is
; shape-AGNOSTIC by construction (EmitInverse.cpp: prepend `out`, then copy the
; forward operands in their ORIGINAL order). So `_hl(h, lit)` must adjoint to
; `_hl_unc(out, h, lit)` while `_lh(lit, h)` must adjoint to `_lh_unc(out, lit, h)`
; — the classical literal STAYS in its forward slot and the handle STAYS in its
; forward slot. Swapping the two is `opt -verify` clean and is a WRONG UNITARY
; (shifting BY the register instead of shifting the register), which is precisely
; the class of bug a golden trace can print plausibly and never catch.
;
; THE PHYSICS BEING PINNED.
;   * `lshr` is NOT injective as a classical map — the 3 shifted-out low bits are
;     destroyed. That does not make it un-uncomputable: the OUT-OF-PLACE Bennett
;     compute `|q, 0⟩ → |q, q>>3⟩` is a permutation on the JOINT register, and the
;     `_unc` is its self-inverse recompute-and-XOR, driving the out rail back to
;     |0⟩ *from the still-live source*. The discarded low bits never have to be
;     stashed anywhere because they are still sitting in %h — which is exactly why
;     SOURCE LIVENESS at the adjoint step is load-bearing, not incidental.
;   * Whole-DAG LIFO, leaf-first, is what guarantees that liveness: the leaf `%d`
;     is reversed FIRST, while its source %h is still allocated; only then is the
;     root un-rotated and freed. Free the root first and the adjoint would be
;     unrealizable (it would have to read a rail the hardware already reset).
;   * The adjoint is the VOID `_unc`, never the fresh-minting `_inv` — an `_inv`
;     here would allocate a NEW rail and leave the dead one dirty and entangled
;     instead of zeroing it in place.
;   * Rule 6 rail hygiene — and the two rails are licensed DIFFERENTLY, which is
;     worth stating precisely rather than in the loose house idiom. The DERIVED
;     rail %d really does reach |0⟩: its own void `_unc` recompute-and-XORs it to
;     zero from the still-live source, and only THEN is `cqrt_free(%d)` emitted.
;     The ROOT %h does NOT return to |0⟩ and was never there — `cqrt_alloc_i32(%x)`
;     initialises it to the alloc-time CLASSICAL BASIS STATE |x⟩, so `ry(-θ)`
;     restores |x⟩, not |0⟩. What licenses `cqrt_free(%h)` is that the rail is
;     provably DISENTANGLED and in a KNOWN CLASSICAL state — its write history
;     reduces to identity, the same clause `tools/free_pairing_check.py` applies
;     at e2e stage 2b. Either way: no dirty free, so no hidden measurement.
;   * ADJACENCY IS PART OF THAT PROOF, which is why the reversal CHECKs below are
;     CHECK-NEXT and not plain CHECK. "Freed at |0⟩" is a claim about the rail's
;     state AT THE FREE SITE, so one extra non-diagonal gate spliced between an
;     adjoint and its `cqrt_free` re-dirties the rail and turns that free back
;     into a hidden measurement that collapses q. An ordered run of plain CHECKs
;     pins relative order only and admits exactly those mutants — measured, not
;     assumed: `cqrt_x(%h)` before the `_unc`, `cqrt_x(%d)` between the `_unc` and
;     its free, and a spurious `cqrt_free(%h)` ahead of `ry(-θ)` were ALL accepted
;     by the plain-CHECK draft of this file, and all three are `opt -verify`
;     clean. Nothing else covers this at the lit layer: `free_pairing_check.py`
;     is an e2e stage-2b gate over linked slices and never runs on lit fixtures.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
;
; Forward (theta -> alloc + ry, then the `_hl` shift: handle slot 0, literal slot 1):
; CHECK:     %[[H:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:     call void @cqrt_ry_i32(i32 %[[H]], double 2.500000e-01)
; CHECK:     %[[D:[a-zA-Z0-9_.]+]] = call i32 @cq_template_lshr_i32_hl(i32 %[[H]], i32 3)
; NOTHING may be freed between the forward compute and its adjoint — a free
; spliced in ahead of the `_unc` is an adjoint reading a rail the hardware has
; already reset, i.e. the exact negation of the "still-live source" claim above.
; This scoped CHECK-NOT names that hazard explicitly; the CHECK-NEXT on the next
; directive independently subsumes it (belt and braces — the named guard survives
; even if the adjacency line is ever loosened).
; CHECK-NOT: cqrt_free
; Reversed adjoint (LIFO, leaf-first): the void `_unc(out=%d, src=%h, lit=3)` —
; `out` prepended, forward operands in ORIGINAL `_hl` order, reading the STILL-LIVE
; root %h; then the now-proven-|0> rail free, then un-rotate + free the root at its
; alloc-time classical |x>. Handle identity is captured, not just symbol presence:
; the adjoint must read THAT rail in THAT slot. CHECK-NEXT throughout, because the
; real emission is contiguous and the Rule-6 claim is about the rail's state AT the
; free site — nothing may be interleaved into this run.
; CHECK-NEXT: call void @cq_template_lshr_i32_hl_unc(i32 %[[D]], i32 %[[H]], i32 3)
; CHECK-NEXT: call void @cqrt_free(i32 %[[D]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[H]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[H]])
;
; The adjoint is the VOID `_unc`, never a fresh-minting `_inv`; the intrinsic is gone.
; CHECK-NOT: cq_template_lshr_i32_hl_inv
; CHECK-NOT: cq_template_lshr_i32_inv
; CHECK-NOT: cq_theta_
;
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x) {
entry:
  %q = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %d = lshr i32 %q, 3                            ; q >> lit => _hl, dead terminal
  ret void
}
