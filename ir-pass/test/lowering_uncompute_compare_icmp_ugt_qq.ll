; lowering_uncompute_compare_icmp_ugt_qq.ll — witness restoration for the Q+Q
; UNSIGNED integer data-compare and its void uncompute twin (bd `gowy`).
;
; WHY THIS FILE EXISTS. Commit dbab515 (`tkju`) DE-VENDORED 52 e2e slices IN
; PLACE — it deleted nothing. `git show --name-status --format='' dbab515` is
; `1 A` + `75 M`, ZERO `D`, and `tests/e2e/*.c` numbers 249 both before and
; after; every slice still exists and is still tested today. What dbab515 did
; was STRIP the fictional openlibm SOFTWARE bodies those `.c` files had vendored
; for Rule-18 HARDWARE keeps, then REGENERATE their goldens. The casualty was
; therefore not a file but a set of `cq_template_*` trace LINES that the
; regenerated `.expected.log` files no longer contain — and for this fixture's
; two symbols the loss is exact and re-measurable:
;   git grep -o -E 'cq_template_icmp_ugt_i32\('     <rev> -- tests/e2e/
;     dbab515^ -> 48    dbab515 -> 0    HEAD -> 0
;   git grep -o -E 'cq_template_icmp_ugt_i32_unc\(' <rev> -- tests/e2e/
;     dbab515^ -> 28    dbab515 -> 0    HEAD -> 0
; The three goldens that had carried the bare QQ form are
; slice_libm_real_{coshl,lroundl,llroundl}.expected.log — all three still
; present, all three now tracing the de-vendored hardware-keep route instead.
; (The `_hl` shape is untouched: still ~1.9k golden hits at HEAD. It is
; specifically the bare QQ witness that went to zero, which is why THIS shape
; is the one that needed restoring.) Twenty `cq_template_*` symbols were left
; generated-but-unwitnessed this way: present in runtime/cq_templates.c,
; referenced by no golden and no lit fixture. Fourteen of the twenty are
; `_unc`/`_inv` ADJOINT twins — i.e. the uncompute spine, which is precisely
; where this project's verify-clean silent miscompiles live (Rule 13). This
; fixture re-pins two of them, in the cheap ir-pass layer rather than by
; re-vendoring a body into an e2e slice (which is the defect dbab515 removed):
;   * cq_template_icmp_ugt_i32       (forward QQ flag producer)
;   * cq_template_icmp_ugt_i32_unc   (its void, in-place adjoint)
; No accept-predicate is added or widened here, so per Rule 12 a POSITIVE fixture
; is sufficient — there is no new decline edge to probe.
;
; RELATIONSHIP TO lowering_uncompute_compare_icmp.ll. That fixture is the WI-0
; original and carries the full rationale for why a dead compare-as-data flag is
; reversible at all; read it first, this one is deliberately a delta and does not
; restate it. Two axes differ, and neither can be witnessed by the other:
;   * SHAPE: `_hl` (handle + classical literal) there, bare QQ (BOTH operands are
;     rails) here. The `_unc` emitter's prepend rule is shape-agnostic, but of
;     the two shapes contrasted here only the QQ adjoint holds TWO live source
;     rails simultaneously.
;   * PREDICATE: signed `slt` there, UNSIGNED `ugt` here. Signedness lives in the
;     OPCODE (`icmp ugt` vs `icmp sgt`), and the pass strips it from the HANDLE
;     type — a runtime handle is always `i32` regardless of width or signedness
;     (Rule 15) — but it is NOT stripped from the SYMBOL name. `ugt` and `sgt`
;     are genuinely distinct templates computing genuinely different predicates
;     on the same bit pattern (0xFFFFFFFF > 1 unsigned, < 1 signed), so a green
;     `sgt` fixture is zero evidence about `ugt`. Hence a separate witness.
;
; THE PHYSICS BEING PINNED. `q1 = cq_theta(x); q2 = cq_theta(y); w = (q1 > q2)`
; with `w` dead. The compare is not a branch — it is DATA. Embedded reversibly it
; is the permutation |a,b,c> -> |a,b, c XOR (a >u b)>, self-inverse, with the two
; operand rails left untouched. Four facts must hold, and a violation of any one
; of them is verify-clean and trace-plausible:
;   1. DD-3 SLOT ORDER. The void adjoint is `_unc(out, a, b)`: the forward RESULT
;      is PREPENDED, then the forward operands follow in their ORIGINAL order
;      (EmitInverse.cpp). A swapped pair here silently recomputes `b >u a`, i.e.
;      `ult` — a different unitary, XORed into the rail, which therefore does NOT
;      return to |0>. Transposition is expressible in any non-commutative QQ
;      shape; what makes it worth pinning HERE is that the `_hl` sibling cannot
;      express it at all (one slot is a literal), so the `_hl` witness carries no
;      evidence about slot order.
;   2. LIFO, LEAF-FIRST. Reversal walks the dead DAG in reverse program order:
;      the `zext` widen-flag leaf is undone BEFORE the compare it consumes.
;   3. SOURCE LIVENESS AT EACH ADJOINT STEP. `zext_..._unc` reads the compare rail
;      while it is still allocated; `icmp_ugt_i32_unc` reads BOTH roots while they
;      are still allocated — the roots are un-rotated and freed only afterwards.
;      Whole-DAG LIFO is what guarantees this; an adjoint reading an already-freed
;      rail is a use-after-free that `opt -verify` cannot see.
;   4. FREE ONLY A PROVEN-CLEAN RAIL (Rule 6), and free it IMMEDIATELY. The two
;      classes of rail here reach different — both provable — states, and the
;      distinction is load-bearing rather than pedantic:
;        - DERIVED rails (cast, flag) genuinely reach |0>: each was minted at |0>
;          and XORed into by exactly one forward template, so its own void `_unc`
;          XORs the identical value back out. Free is then a no-op reset.
;        - ROOT rails do NOT reach |0>. `cqrt_alloc_i32(%x)` seeds the root in the
;          CLASSICAL BASIS STATE |x>, and `ry(-theta)` restores THAT state, not
;          |0>. What licenses the root free is that it is provably DISENTANGLED
;          and in a known classical state — the compare left both operand rails
;          untouched, so no superposition survives for a reset to collapse.
;      "Immediately" is the other half of Rule 6 and is why the reversal tail
;      below is pinned with CHECK-NEXT rather than plain CHECK. A stray gate
;      slipped between an adjoint and its `cqrt_free` RE-DIRTIES the rail the
;      adjoint just cleaned, turning that free into a hidden measurement that
;      collapses `q`; a `cqrt_free` slipped in the other direction, just BEFORE
;      an adjoint, is simultaneously a dirty free and a use-after-free of a
;      source the adjoint is about to read. Both mutants are additive — they
;      insert a line without disturbing any existing one — so a plain CHECK,
;      which permits arbitrary text between matches, cannot see either. Nothing
;      else covers this at the lit layer: `tools/free_pairing_check.py` is an
;      e2e stage-2b gate and never runs on lit fixtures.
; The adjoint is the VOID `_unc` (in-place XOR-out), never the fresh-minting
; `_inv`; an `_inv` here would allocate a second rail instead of clearing the one
; we are about to free, leaving a dirty entangled rail behind.
;
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %filecheck %s
; RUN: %cq-opt -load-pass-plugin %cq-pass -passes=cq-lowering -S %s | %cq-opt -passes=verify -disable-output -
declare i32 @cq_theta_si32(i32, double)

define void @slice(i32 %x, i32 %y) {
entry:
  %q1 = call i32 @cq_theta_si32(i32 %x, double 2.500000e-01)
  %q2 = call i32 @cq_theta_si32(i32 %y, double 5.000000e-01)
  %c  = icmp ugt i32 %q1, %q2   ; Q+Q UNSIGNED data-position compare -> flag rail
  %w  = zext i1 %c to i32       ; DEAD widened-flag terminal off the compare lineage
  ret void
}

; Forward: two independent theta roots (alloc + ry each), the QQ unsigned compare
; over BOTH handles, then the zext widen. Both compare operands are rails, so the
; symbol is the bare `..._i32` QQ form — no `_hl`/`_lh` suffix. These six stay
; plain CHECK deliberately: what the forward stream must guarantee is ORDER (a
; data dependence), not adjacency, so pinning gaps here would buy nothing and
; would make the fixture brittle to a benign future insertion.
; CHECK:      %[[HA:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %x)
; CHECK:      call void @cqrt_ry_i32(i32 %[[HA]], double 2.500000e-01)
; CHECK:      %[[HB:[a-zA-Z0-9_.]+]] = call i32 @cqrt_alloc_i32(i32 %y)
; CHECK:      call void @cqrt_ry_i32(i32 %[[HB]], double 5.000000e-01)
; CHECK:      %[[CMP:[a-zA-Z0-9_.]+]] = call i32 @cq_template_icmp_ugt_i32(i32 %[[HA]], i32 %[[HB]])
; CHECK:      %[[CAST:[a-zA-Z0-9_.]+]] = call i32 @cq_template_zext_i1_to_i32(i32 %[[CMP]])
;
; Reversed adjoint (LIFO, leaf-first) — and from here to the last free the chain
; is CHECK-NEXT throughout, verified contiguous in the real lowered output (all
; eight reversal lines are emitted back to back, immediately after the forward
; stream). That makes the block a gap-free window: no gate may be inserted
; between an adjoint and the `cqrt_free` it licenses (re-dirtied rail -> hidden
; measurement), and no free may be hoisted ahead of an adjoint that still reads
; that rail (fact #3's use-after-free). Both are additive mutants that the plain
; CHECK form waved through.
;
; zext_unc(out=%w, src=%c) runs FIRST, off the still-live flag rail; the cast
; rail is at |0> the moment it returns, hence the immediately following free.
; CHECK-NEXT: call void @cq_template_zext_i1_to_i32_unc(i32 %[[CAST]], i32 %[[CMP]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[CAST]])
;
; The compare adjoint: DD-3 slots (out=%c PREPENDED, then %q1, %q2 in the SAME
; order as the forward call), reading BOTH still-live roots. All three operands
; are i32 handles (Rule 15). Transposing %[[HA]]/%[[HB]] would compute `ult` and
; leave the flag rail dirty — the capture vars pin identity AND position, which
; is the entire point of this fixture.
; CHECK-NEXT: call void @cq_template_icmp_ugt_i32_unc(i32 %[[CMP]], i32 %[[HA]], i32 %[[HB]])
; CHECK-NEXT: call void @cqrt_free(i32 %[[CMP]])
;
; Roots un-rotated and freed last, in LIFO order (%q2 before %q1). Each free is
; adjacent to its own negated `ry`, so the rail is back in its alloc-time
; classical basis state — disentangled and known, per fact #4 — when it is reset.
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HB]], double -5.000000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HB]])
; CHECK-NEXT: call void @cqrt_ry_i32(i32 %[[HA]], double -2.500000e-01)
; CHECK-NEXT: call void @cqrt_free(i32 %[[HA]])
;
; Every adjoint above is the void `_unc`; no fresh-minting `_inv` twin is emitted
; or declared, and the theta intrinsic is fully lowered away. These trailing
; guards span [last match -> EOF], which is the `ret void` / `}` / declare block —
; and that IS the region that witnesses them: the pass ERASES the now-unused
; `declare i32 @cq_theta_si32` (absent from the lowered module), and the declare
; block mirrors exactly the emitted symbol set, so a wrongly-emitted `_inv` would
; drag its own `declare` into this window.
; CHECK-NOT: cq_template_icmp_ugt_i32_inv
; CHECK-NOT: cq_template_icmp_ugt_i32_hl
; CHECK-NOT: cq_template_zext_i1_to_i32_inv
; CHECK-NOT: cq_theta_
