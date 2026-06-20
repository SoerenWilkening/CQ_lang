# Phase 7.1 PRD — Opcode-surface completion (DRAFT)

> **Status:** DRAFT, written at the start of Phase 7.1 (2026-06-19) to
> memorialize the design decisions resolved in PRD-discovery discussion. Does
> not duplicate [`ROADMAP.md`](../../../ROADMAP.md) §"Phase 7 — 7.1" or the spec
> docs; captures the 7.1-specific decisions, deliverables, and done criteria.
> One PRD covers **all five** 7.1 items (owner decision 2026-06-19).

---

## 0. Invariant recap (not new — the ground 7.1 stands on)

- **Over-declining is safe; over-accepting is a silent miscompile** (Prime
  Directive). Every new accept-predicate here ships with a decline fixture +
  adversarial probe (Rule 12).
- **Verify-clean ≠ correct** (Rule 2). The two hazards in 7.1 — a wrong
  `_<W>_qq` compare symbol and a wrong `_BitInt` mask — are both **verify-clean**
  with **no downstream backstop**. They are cleared by analytic/trace reasoning
  + golden e2e diff, not by `opt -verify`.
- **Taint is the only Q/C boundary** (Rule 3). Wide-int and intrinsic additions
  change *which widths/operations* taint flows through; they do **not** add a new
  taint source. `@cq_theta` remains the sole source, `@cq_measure` the sole sink.
- **Handles are always `i32`; signedness is stripped** (Rule 15). Width lives in
  the *symbol suffix*, not the SSA handle type. Edit the YAML, never the
  generated `cq_templates.{h,c}`.
- **`emit_inverse` is a closed adjoint dispatch table** (ROADMAP §Phase 7,
  "feature → spine"). Every new reversible construct in 7.1 registers its **own**
  adjoint rule into that spine so the live Phase-5 whole-DAG uncompute can
  reverse it at scope exit — independent of Phase 8.

---

## 1. Scope

7.1 widens the **accepted-C subset** the IR pass lowers by closing five
currently-declined-but-reversible gaps. Irreversibility enters a program through
source-chosen *operations*, never through an arithmetic opcode or an integer
width — so the genuinely-un-executable set this phase leaves behind is small and
principled, not incidental.

**The five items, split by the one axis that matters — frozen-ABI impact:**

| # | Item | New frozen ABI? | Freeze-gating? |
|---|------|-----------------|----------------|
| 1 | Q+Q data-position compare (`q1 < q2` as data) | No (`_qq` templates exist) | No |
| 2 | `freeze` on a tainted value (passthrough) | No | No |
| 3 | N-ary classical-condition merge | No | No |
| 4 | Wide / intermediate widths (`__int128`, `_BitInt(N)`, `_Float16`) | **Yes** | **Yes** |
| 5 | Curated reversible `llvm.*` idiom intrinsics | **Yes** | **Yes** |

Items 1–3 are disposable pass-logic. Items 4–5 add **permanent frozen symbols**
and therefore must be locked **before** the Phase-11 freeze and cleared by
independent Rule-13 review.

---

## 2. Design decisions

### 2.1 One PRD, all five items (owner decision)
The roadmap's "one PRD per increment" governs: 7.1 is a single PRD. The ABI vs
no-ABI fault line is tracked *within* this document (the table above + the
per-item Rule-13 gating in §4), not by splitting into separate PRDs.

### 2.2 Q+Q data compare — thread the proven control-path width discipline
The `_qq` compare templates already exist; the data path declines Q+Q today only
because it lacks the operand width. **Decision:** thread the Phase-4
`HandleWidth` side-table (captured by SSA identity **before** rotation lowering
RAUWs operands to `i32` handles) into the data-path compare. **Scope detail that
must not be missed:** `HandleWidth` is populated for *theta* handles only, so a
**derived** operand (`q1+q2 < q3`, whose operand is an arith/cast result) has no
entry — `ArithLowering` / `CastLowering` must **also** record their output width
into `HandleWidth` when they mint a handle (each knows it from its own result
type; pure bookkeeping, **no new ABI**). The compare's `i1` result is precisely
why this side-table is needed (arith recovers its width from its own result
type; a compare cannot). **Mirror the control-path discipline exactly** — a
stale/wrong-operand width selects the wrong `_<W>_qq` symbol, which is
verify-clean.

### 2.3 `freeze` — basis-level taint passthrough, decline-fixture-first
`freeze` on a tainted value is a basis-level identity: taint propagates through
unchanged, no gate emitted. **Decision (Rule 12, decline-first):** write the
negative fixture first. The load-bearing guard: `freeze` must **not** become a
laundering path that re-admits an **Escaped** value (one that left via `ret` /
`cq_invert_*` / store) back into the taint domain. `freeze` propagates taint it
*already has*; it never *creates* it and never *re-acquires* it.

### 2.4 N-ary classical-condition merge — generalize the one-register lift
Generalize the existing one-register merge-φ lift in `declineClassicalMuxes`
from 2-way to **N-way** classical-condition incoming. **Decision:** the
FP-vs-data guard is preserved verbatim — an FP merge φ is a rotation **angle**,
not data, tested with `isFPOrFPVectorTy()` (never `isFloatingPointTy`, which
misses `<2 x double>`; never keyed on `abiWidthFromType()` non-empty, which f64
satisfies yet is an angle — the f64 silent-miscompile family). N-ary widens the
*arity*, not the FP/data classification.

### 2.5 Wide / intermediate widths — frozen set and `_BitInt` policy (owner decisions)
- **Frozen width set grows by two:** add `i128` (domain int) and `f16` (domain
  fp) to the widths map. New frozen total: `{i1,i8,i16,i32,i64,i128}` ∪
  `{f16,f32,f64}`. This expands int arith/bitwise, fp arith, `icmp`/`fcmp`, the
  cast pair matrix (every width ↔ i128; f16 ↔ {f32,f64}; cross-domain f16↔ints,
  i128↔fps), and the measure family — **all frozen, all permanent.**
- **`_BitInt(N)` → round-up-to-ABI-width + high-bit mask** (owner decision). A
  non-power-of-2 `_BitInt(24)` lowers via the next ABI width (`i32`) with the
  lowering **masking the high bits** to preserve `_BitInt`'s wraparound/overflow
  semantics (`add nsw` on a logical `i24` ≠ on `i32`). The mask is **load-bearing
  correctness**, not cleanup — an unmasked round-up is a verify-clean overflow
  miscompile.
- **Wide ints are first-class taint values, seedable at ABI widths** (owner
  decisions 2026-06-19, two parts):
  - **Sources grow the `CQ.h` `_Generic` surface** (full-source decision): add
    `cq_theta`/`cq_phi`/`cq_measure` entries for `__int128` / `unsigned __int128`,
    `_Float16`, and `_BitInt` **at the ABI widths only**. Because `CQ.h` is the
    frozen frontend (freezes at Phase 11), these entries must land **now**.
  - **Direct sources are enumerated at ABI widths only** (source-width decision).
    C's `_Generic` matches concrete types and **cannot** catch arbitrary
    `_BitInt(N)`. So a non-power-of-2 `_BitInt(24)` is supported as an
    **intermediate** (appears mid-computation via cast/arith, round+mask) but is
    **not directly seedable** — `cq_theta` on a `_BitInt(24)` is a frontend
    `_Generic` no-association **compile error** (an acceptable, source-located
    loud decline at the C frontend, before the pass runs).

### 2.6 Curated reversible `llvm.*` idiom intrinsics — membership and mechanism
`clang -O1` **synthesizes** `@llvm.*` calls for ordinary integer C idioms
(`a<b?a:b` → `@llvm.smin`, `abs()` → `@llvm.abs`, `__builtin_popcount` →
`@llvm.ctpop`, …). A tainted one currently false-declines at
`declineTaintEscapes` `kMsgUnknownCallee`, yet these are **pure total functions,
hence reversibilizable** (`bd memories llvm-idiom-intrinsics-reversible`).
**Decision:** a **curated reversible-intrinsic table** (sibling of
`tools/opcode_table.yaml`), and a carve-out of the listed names from
`declineTaintEscapes`. Two mechanism classes:
- **Class 1 — bijections** (`bswap`, `bitreverse`, `fshl`/`fshr` rotate): lower
  **in-place**, 7.1-cheap. Each registers a real adjoint into `emit_inverse`
  (`bswap`/`bitreverse` are involutions = self-adjoint; `fshl(x,n)`⁻¹ = rotate
  back).
- **Class 2 — non-injective but pure** (`smin`/`smax`/`umin`/`umax`, `abs`,
  `ctpop`, `ctlz`/`cttz`, the saturating `*.sat` family): reuse **exactly** the
  Phase-5 compare/`_unc` **Bennett recompute-from-live-sources** model already
  shipped — no new uncompute mechanism, only new table rows.

**OUT of 7.1 (deferred, both addable pre-freeze later if wanted):**
- **`*.with.overflow`** (`uadd`/`usub`/`smul`.with.overflow): drags in
  **`extractvalue` aggregate-result routing** — a distinct, heavier mechanism.
  Deferred (owner decision: full set **minus** `*.with.overflow`).
- **fp transcendentals** (`@llvm.sqrt`/`sin`/…): a **separate** Phase-6 Path-1
  curated **libm substitution** problem, not an idiom intrinsic. Not this phase.

**Curation guard:** an intrinsic enters the table **only** if it is a proven pure
total function with an analytically-derived adjoint. A side-effecting or
partial-domain intrinsic is a loud decline, never a table row.

---

## 3. Deliverables

1. **Q+Q data compare:** `HandleWidth` threaded into data-path compare;
   `ArithLowering`/`CastLowering` record output width on handle mint. Positive
   lit fixture (`q1<q2`, derived `q1+q2<q3`) + negative decline fixture.
2. **`freeze`:** passthrough lowering + negative laundering-decline fixture
   (written first).
3. **N-ary merge:** N-way generalization of the merge-φ lift, FP-vs-data guard
   preserved; positive + FP-angle decline fixtures.
4. **Wide widths (YAML + frontend, frozen):**
   - `tools/opcode_table.yaml`: `i128`, `f16` widths + their arith/bitwise/
     compare/cast/measure rows; regenerate `cq_templates.{h,c}`;
     `gen_templates.py --check` drift clean.
   - `CQ.h`: `_Generic` source entries for `__int128`/`unsigned __int128`,
     `_Float16`, and ABI-width `_BitInt` (frontend-lit must show they survive
     `clang -O1`).
   - `_BitInt(N)` round-up + **high-bit mask** in `WidthDispatch`/lowering.
5. **Curated intrinsic table (frozen):** the reversible-intrinsic table file +
   carve-out from `declineTaintEscapes`; Class-1 adjoints registered in
   `emit_inverse`; Class-2 reuses the `_unc` Bennett model. Per-intrinsic
   positive fixture + the `*.with.overflow` / transcendental decline fixtures.
6. **≥1 e2e golden smoke** (Rule 16) exercising, at minimum: a Q+Q data compare,
   an `i128` computation, a `_BitInt(N)` round+mask, and an `llvm.*` idiom
   (e.g. `abs`/`smin`) — `opt -verify` clean, golden trace diff clean.

---

## 4. Done criteria

- Programs using Q+Q data compares, `freeze`, N-ary classical merges, wide/
  intermediate integers + `_Float16`, and the curated `llvm.*` idioms lower to
  the expected `cqrt_*` / `cq_template_*` sequences — `opt -verify` clean,
  golden e2e trace diffs clean.
- Every off-pattern shape declines **loudly** with a source-located diagnostic:
  `*.with.overflow`, fp transcendentals, arbitrary-N `_BitInt` **source** seed,
  vector/aggregate operands, a `freeze` re-laundering an Escaped value.
- `gen_templates.py --check` SHA-256 drift clean after YAML regen.
- Each lit accept-predicate has a mirrored negative `RUN: not … | FileCheck`
  (Rule 12).
- **The two freeze-gating items (wide widths, intrinsic table) are cleared by
  independent adversarial Rule-13 review** — a green suite alone does not clear
  them, because both carry verify-clean silent-miscompile hazards (§6) and both
  add permanent frozen symbols.

---

## 5. Out of scope (declines, or other phases)

- `*.with.overflow` intrinsics and fp transcendentals (deferred / Phase-6
  Path-1).
- Arbitrary-N `_BitInt(N)` as a **direct** taint source (frontend `_Generic`
  decline; intermediate use is supported).
- Vector / aggregate tainted operands.
- All other 7.x items: controlled `return` / `abort`-`exit` (7.2), bounded loops
  (7.3), `break` (7.4), QRAM (7.5), reversible I/O (7.6).
- Any change to the runtime *simulation* posture (still trace-only) or to the
  control-flow surface (7.1 adds no control shapes).

---

## 6. Risks (the verify-clean ones first)

1. **Wrong `_<W>_qq` compare symbol** from a stale/wrong operand width — silent
   miscompile, no backstop. Mitigation: mirror the proven control-path width
   discipline; capture width by SSA identity before any RAUW; fixture the derived
   operand case explicitly.
2. **`_BitInt(N)` mask error** — an unmasked or wrongly-masked round-up changes
   overflow/wraparound (`add nsw` on logical `i24` vs `i32`) — verify-clean.
   Mitigation: mask is a first-class lowering step with its own fixtures, not
   cleanup.
3. **Mis-curated intrinsic** — an intrinsic added as "pure" that has a side
   effect or partial domain, or a wrong adjoint, is a silent miscompile.
   Mitigation: per-intrinsic analytic adjoint proof in the Rule-13 clearance; the
   table is curated, never pattern-matched.
4. **Permanent frozen-surface error** — every new width/intrinsic symbol is
   frozen at Phase 11. An omission is a permanent v1 expressiveness gap; a wrong
   symbol is a permanent wrong ABI. Mitigation: the §4 Rule-13 gate on items 4–5.
5. **`freeze` laundering** an Escaped value back into taint — Mitigation: the
   §2.3 escaped-source guard + decline-first fixture.

---

## 7. Increments (each red → green → clear, Rule 12/13)

Suggested order — no-ABI items first (low risk, unblock fixtures), frozen-ABI
items last (heaviest review):

1. Q+Q data compare (no ABI).
2. `freeze` passthrough (no ABI).
3. N-ary classical merge (no ABI).
4. Wide widths — YAML `i128`/`f16` + `CQ.h` sources + `_BitInt` round+mask
   (**frozen; Rule-13 clearance**).
5. Curated `llvm.*` intrinsic table (**frozen; Rule-13 clearance**).

> Items 1–5 may interleave at the fixture level, but **4 and 5 must each clear
> independent adversarial review before commit** and must land **before** the
> Phase-11 freeze.
