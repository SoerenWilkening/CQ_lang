# Phase 7.1 Increment E — Curated Intrinsic Adjoint Proofs & Clearance (FROZEN)

> The curation guard (Prime Directive): an intrinsic enters `tools/intrinsic_table.yaml`
> ONLY with a written, analytically-derived adjoint proof. This file is that
> record + the Rule-13 clearance for the freeze-gating reversible-intrinsic ABI.
> Recorded 2026-06-20.

## Mechanism (R-E): additive producer → reuse the `_unc` spine, zero new code

Every curated intrinsic lowers to a `cq_template_<op>_<W>[…]` **additive producer**
(fresh out rail, sources preserved) — mirroring `ArithLowering::rewriteUnary/
rewriteBinary` exactly. The emitted symbol uses the SAME `cq_template_` prefix as
the opcode templates, so the whole-DAG uncompute spine reverses it with **zero new
uncompute code**: `DagTraversal::isTemplateProducer`/`isDataProducer` recover it,
`EmitInverse`'s `_unc` branch emits `<sym>_unc(out, forward-operands…)`, and the
`Uncomputation` invertibility pre-scan accepts the `cq_template_` prefix. The
generic `_unc(out, srcs…)` zeros the out rail by recomputing `f(sources)` and
XORing — **it never recovers the input**.

**The load-bearing fence is SOURCE-LIVENESS** (Rule 8): the `_unc` recompute is
valid only while every source operand is still live and unmodified. The spine
keeps sources live through their own `_unc` (proven: `slice_intrinsic_ctpop` golden
and `lowering_intrinsic_ctpop_sources_live.ll` — the `_unc` reads the live source,
which is uncomputed+freed ONLY AFTER its `_unc`). A non-linear lineage (a source
with fan-out) is **safely skipped** (rail left allocated, never dirty-freed —
`lowering_intrinsic_smin_fanout_skip.ll`), not miscompiled.

## Per-intrinsic adjoint proofs

### Class 1 — bijections (fwd / inv / unc)

| op | widths | reversibility | adjoint proof |
|----|--------|---------------|---------------|
| `bswap` | i16,i32,i64 | self_inverse | Byte-order reversal is an **involution**: reversing the byte sequence twice restores it, so `bswap(bswap(x)) = x`, hence `bswap⁻¹ = bswap`. A bijection on the W-bit space. `_inv` re-applies `bswap`; `_unc` recomputes `bswap(src)` and XORs the rail to 0. (No i8 — `llvm.bswap` requires a 16-bit-multiple width.) |
| `bitreverse` | i8,i16,i32,i64 | self_inverse | Bit-order reversal is an **involution**: `bitreverse(bitreverse(x)) = x`. Bijection. `_inv` = re-apply; `_unc` = recompute+XOR. Valid at i8 (no width constraint). |
| `fshl` | i8,i16,i32,i64 | rotate_back | In the **rotation form only** (arg0==arg1, constant n): `fshl(x,x,n) = rotl(x,n)`, a cyclic bit permutation, hence a **bijection**. Inverse: `rotl(x,n)⁻¹ = rotl(x, W−n) = rotr(x,n) = fshr(x,x,n)`. `_inv` rotates back; `_unc` recomputes+XORs. The general `x≠y` funnel shift (concatenate two distinct operands) is NOT a single-register bijection → declined. A dynamic (non-constant) amount → declined. |
| `fshr` | i8,i16,i32,i64 | rotate_back | Symmetric to `fshl`: `fshr(x,x,n) = rotr(x,n)`, inverse `rotl(x,n)`. |

### Class 2 — non-injective but pure TOTAL (fwd / unc; NO inv)

These are not invertible (many inputs → one output), so they carry **no `_inv`**.
They are reversibilizable PRECISELY because `_unc` recomputes `f(sources)` from the
still-live sources — never recovering the input. Each is a **pure total function**
(defined for every input, no side effect):

| op | widths | totality / purity |
|----|--------|-------------------|
| `smin`/`smax`/`umin`/`umax` | i8..i64 | Total: defined for every (a,b) pair; pure. Commutative (carry qq+hl, no lh). |
| `abs` | i8..i64 | Total **as lowered**: the trailing i1 poison flag (`abs(INT_MIN,nsw=1)` is poison) is a CONSTANT immarg DROPPED at lowering, so the lowered op is the total `abs` (INT_MIN ↦ INT_MIN). Poison-on-edge is a valid refinement of the source UB. Pure. |
| `ctpop` | i8..i64 | Total (population count, defined for all inputs); pure. |
| `ctlz`/`cttz` | i8..i64 | Total **as lowered**: the i1 is-zero-undef flag is a CONSTANT immarg DROPPED, so the lowered op is total (`ctlz(0)=W`). Pure. |
| `uadd_sat`/`sadd_sat` | i8..i64 | Total: saturating arithmetic clamps at the type boundary, defined for all inputs; pure. Commutative (a⊕b = b⊕a). |
| `usub_sat`/`ssub_sat` | i8..i64 | Total (saturating); pure. NON-commutative (a−b ≠ b−a) → carry the lh shape. |

## Excluded → decline loudly (kMsgUnknownCallee)

- `*.with.overflow` (`uadd`/`usub`/`smul`.with.overflow): returns a `{iN,i1}`
  aggregate; extracting it needs `extractvalue` routing — a separate, heavier
  mechanism. Fence: `lowering_reject_intrinsic_overflow_uadd.ll`.
- fp transcendentals (`llvm.sqrt`/`sin`/…): a separate Phase-6 Path-1 curated
  libm-substitution problem. Fence: `lowering_reject_intrinsic_transcendental_sqrt.ll`.
- general `x≠y` funnel shift: not a single-register bijection. Fence:
  `lowering_reject_intrinsic_funnel_fshl_general.ll`.
- Any curated id at a non-table width (i1, the deferred i128, fp, vector; bswap.i8).

**Membership is by EXACT `Intrinsic::ID`** (`IntrinsicLowering::intrinsicStem`) —
NEVER a `starts_with("llvm.")` name match (the `cq_theta_evil` hazard).

## Frozen sibling symbol surface (PERMANENT at Phase 11)

`tools/intrinsic_table.yaml` → `runtime/cq_intrinsic_templates.{h,c}` (own
yaml-sha256 banner), compiled into `libcq_templates.a`. **413** symbols (the 1732
opcode-table count is UNTOUCHED). Increment-E integer idioms = **221**: Class-1 45
(bswap 9 + bitreverse 12 + fshl 12 + fshr 12) + Class-2 unary 32 (ctpop/ctlz/cttz/
abs × 4w × {fwd,unc}) + min/max 64 + add.sat 32 + sub.sat 48. iw81.4.b fp-math
family = **192**: unary 132 (22 fns × 3w × {fwd,unc}) + fmin/fmax 24 (2 × 3w ×
{fwd_qq,fwd_hl,unc_qq,unc_hl}) + pow/copysign 36 (2 × 3w × +{fwd_lh,unc_lh}).
Derived assertion in `gen_templates_test.py`.

## Rule-13 findings & resolutions (6 adversarial lenses)

2 lenses CLEAR (adjoint correctness, source-liveness/free-count, lowering
correctness — 3 CLEAR total), 2 BLOCK (same root cause), 1 clear-with-fixes.

- **BLOCKER (FIXED) — stale-record bypass.** The curated intrinsics were added to
  `lowerOps` Phase-1/2 but NOT to `inLowerOpsScope`, so `declineStaleRecordOps`
  skipped them: a curated `smin`/`ctpop`/… whose handle predates a chained
  `cq_theta` re-rotation lowered verify-clean (reading the post-Ry basis while the
  SSA operand denotes the pre-Ry record) where the add-shaped program declines —
  a verify-clean silent miscompile. **Fix:** `inLowerOpsScope` now returns true
  for `isCuratedReversibleIntrinsic(CI)`, so `checkStaleOp` walks each tainted
  handle operand's wire identically to add/mul/cast. Verified: the stale `smin`
  now declines `operand predates a non-diagonal gate` exactly like stale `add`.
  Fence: `lowering_reject_stale_record_intrinsic_smin.ll`.
- **MAJOR (DEFERRED) — curated intrinsic inside a specialized clone declines.**
  `SpecializeReject::scanBody` does not whitelist curated intrinsics, so a
  classical helper containing `__builtin_popcount`/`smin`/… called under quantum
  control declines specialization as a "non-reversibilizable nested call." This
  is a **safe over-decline** (Prime Directive — NOT a miscompile) and adds no
  frozen symbol (the intrinsic templates are frozen regardless of whether
  specialization uses them), so it is deferred to a tracked pre-freeze follow-up
  rather than expanding a core file at frozen-increment time. The symmetric accept
  (mirroring the f16-in-specialization acceptance of Increment D) is the
  follow-up's job.
- **MINORS resolved:** added the two missing decline fences
  (`_fshl_dynamic_amount`, `_ctpop_i1_nonwidth`) and positive coverage for the
  previously-uncovered ops (`fshr`, `ctlz`, `umax`, `uadd_sat`). The `promote`
  bookkeeping is duplicated from `ArithLowering` — this MATCHES the existing 3-way
  duplication (Arith/Cast/Compare each carry their own static `promote`); a shared
  extraction is a pre-existing cleanup, not an E regression.
- **`_inv` dormant-reserve (minor/nit, NO ACTION):** the 15 Class-1 `_inv` twins
  (bswap/bitreverse self-inverse, fshl/fshr rotate-back) are FROZEN but currently
  unreachable — the whole-DAG uncompute spine only forms the `_unc` suffix; the
  `_inv` path is reachable only via `cq_invert` (Phase 8, XFAIL). This is the
  INTENDED Phase-8 frozen surface (Class-1 carries fwd+inv+unc by design), not
  dead code to "clean up." The rotate `_inv` (amount W−n) is the only intrinsic
  `_inv` with non-trivial argument semantics — the Phase-8 work must prove it.

## Gates (all green)

31/31 ctest · 14 new intrinsic lit fixtures (positives per shape class + 3
exclusion fences + 2 R-E source-liveness + fan-out safe-skip) · `--check` drift 0
for BOTH surfaces · `gen_templates_test.py` (sibling count 221, opcode 1732,
decl/def pairing, sibling SHA banner) · `runtime_header_compile` (`-Wpedantic
-Werror`, sibling header) · e2e `slice_intrinsic_bswap` + `slice_intrinsic_ctpop`
link + golden (Class-1 `_unc`, Class-2 recompute-from-live-source).
