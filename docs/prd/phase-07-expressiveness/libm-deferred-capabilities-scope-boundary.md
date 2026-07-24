# libm campaign — deferred-capability scope boundary (v1)

**Date:** 2026-07-24 · **Branch:** `3c6m.14-control-l6` · **Status:** scope-boundary
doc of record (no pass change). **Pickup owner for the deep work:** bd `8h7d`
(loop campaign) + `8h7d.1` (trig deep-end) + `iw81.13` (QRAM-in-loop).

This is the single authoritative list of the libm cells that are **parked
behind a not-yet-built capability**, why each is parked, the capability that
would un-park it, and the pickup ticket. It exists so a future agent has one
place to resume from instead of reconstructing the boundary from census buckets.

**Companion docs:** `SCOPING-payne-hanek-trig-reduction.md` (the trig trio in
depth) · `p119-libm-coverage-honesty/PRD.md` (Rule 18) · the exhaustive per-cell
census lives in `tools/library_coverage/full_surface/ld80_census_O1.json` +
`FULL_DEPTH_CENSUS.md` — this doc is the capability-level map over it.

---

## 0. The honesty rule for this boundary (read first)

**Defer by BUCKETING, never by DELETING.** A parked cell stays in the census
**denominator**; it moves into an explicit "deferred — out of v1 scope" bucket.
Removing parked cells from the measurement is exactly the mechanism that produced
the retired 165/174 overclaim (the coverage ratio improves only because the hard
cases stopped being counted). Keep the **two numbers** (injection-covered /
total, and VERIFIED / total — see `libm-scoreboard-two-numbers`). Declaring a
capability out of the current milestone is a legitimate owner scope call; erasing
its cells from the denominator is not.

---

## 1. Near-term RECLASSIFICATION (not a defer) — the fmod family via `frem`

> **⛔ CORRECTION 2026-07-24 (owner, bd `3c6m.56`): `fmod` is NOT reclassified.**
> The reclassification recommended below was **rejected** after a Bennett.jl
> check. The keep criterion is not "in-grid IR construct" alone — it is "in-grid
> IR construct **that Bennett.jl backs with a reversible gate sequence**." `fmod`
> folds to the in-grid `frem` **opcode** (recognizer condition holds), but
> **Bennett ships no `frem`/`fmod` gate sequence** (its only `frem` token is an
> error-string entry in `src/extract/errors.jl`; the full SoftFloat surface in
> `src/softfloat/softfloat.jl` has `soft_fadd/fsub/fmul/fdiv/fma/fsqrt/fneg` +
> rounders + transcendentals but **no** remainder). Native `frem` is a CQ
> recognizer parity-*inversion* (the pass recognizes an opcode Bennett declines),
> tracked as a separate follow-up. So the `floor.f80` analogy **fails for fmod**:
> `floor` **is** Bennett-backed (`soft_floor`), `frem` is **not**. `fmod`/`fmodf`/
> `fmodl` therefore **stay declining library cells** (census `unknown callee` /
> `loop`), NOT keeps, NOT added to the keep-set, NO goldens. The rounders in §1a
> **do** clear the Bennett gate (`soft_round`/`soft_trunc`) and are verified.
> Everything below in §1 is the pre-correction analysis, kept for the record.

**Finding (measured this session, all three widths):** `fmod`/`fmodf`/`fmodl`
are **opcode-keeps in disguise**. With builtins on (the natural user
compilation) clang folds `fmod(x,y)` directly to the **`frem` IR opcode** —
verified for `double`, `float`, AND `x86_fp80`. `frem` is in the template grid
(`opcode_table.yaml:204`, widths f16/f32/f64/f80, full variant set), so a tainted
`fmod` lowers **clean** at every width and operand mix:

| probe (builtins on) | IR | cq-lowering |
|---|---|---|
| `fmod(q, 0.5)` | `frem double` | `cq_template_frem_f64_hl` ✓ |
| `fmodf(q, 0.5f)` | `frem float` | `cq_template_frem_f32_hl` ✓ |
| `fmodl(q, 0.5L)` | `frem x86_fp80` | `cq_template_frem_f80_hl` ✓ |
| `fmod(qa, qb)` (both tainted) | `frem double` | `cq_template_frem_f64` (qq) ✓ |

The census declines them **only** because its Rule-18 `-fno-builtin` posture
forces injection of `e_fmod.c`'s bit-reduction loop (verified: the correct 2-arg
injected probe declines `loop under quantum control`, e_fmod.c:56, 35 blocks).

**This is the exact `floor.f80` precedent.** `floorl` is an asm-level libcall
(`callq _floorl`) yet is a **keep** because cq-lowering rewrites `@llvm.floor.f80`
→ `cq_template_floor_f80` **before codegen**. `fmod` is the same shape one level
over: an asm-level libcall that CQ intercepts as an **IR opcode** (`frem`) before
codegen. The operative keep/cut test is "in-grid IR construct before codegen,"
not "no libcall in final asm."

**Recommendation (SUPERSEDED — see the correction banner atop §1):** the original
recommendation was to reclassify `fmod`/`fmodf`/`fmodl` as `frem`-keeps. This was
**rejected** (bd `3c6m.56`): `frem` fails the Bennett-gate (no `soft_frem`/
`soft_fmod` in Bennett.jl), so `fmod` stays declined and is **not** added to the
keep-set. The `frem` recognizer is a pre-existing CQ parity-*inversion*, handled
by a separate frem-inversion follow-up, not by reclassifying `fmod` as covered.

### 1a. The same doctrine — the long-double rounders (measured 2026-07-24)

`fmod` is one instance of a broader rule: *when clang folds a libm name to an
in-grid IR construct (a `frem` opcode, OR a `@llvm.*` intrinsic CQ has a
template for), that is a keep even though it is an asm-level libcall.* CQ
recognizes all six round-family intrinsics (`IntrinsicLowering.cpp:70-75`) and
ships curated **f80** templates for all six (`runtime/cq_intrinsic_templates.c`).
Two-sided measurement (builtins-on keep path vs. the census `-fno-builtin`
injection; authoritative `wprobe`):

| rounder (f80) | keep path (builtins-on) | census now (`-fno-builtin`) | delta |
|---|---|---|---|
| `floorl` / `ceill` / `roundl` | `@llvm.<fn>.f80` → template ✓ | **COMPILES** (injected `s_<fn>l.c` body lowers) | none — already covered |
| `rintl` / `nearbyintl` | `@llvm.<fn>.f80` → template ✓ | **declines** `nested control flow` (injected `s_rintl.c`) | **+2 — pure doctrine** |
| `truncl` | `@llvm.trunc.f80` → template ✓ | **declines** `unknown callee` (no `s_truncl.bc` — corpus gap) | **+1 — doctrine (or close the corpus gap)** |

So the **doctrine** — corrected to the Bennett-gated form — is worth **+3 cells**,
**all rounders**: `rintl`/`nearbyintl`/`truncl`.f80 (Bennett-backed via
`soft_round`/`soft_trunc`, `src/softfloat/fround.jl`; e2e-verified by
`tests/e2e/slice_libm_keep_{rintl,nearbyintl,truncl}.c`, bd `3c6m.56`).

> **f80-width precision (be honest):** Bennett's `soft_round`/`soft_trunc` are its
> **f64** SoftFloatLib (`UInt64` bit patterns; `llvm.round`/`roundeven` `_ir_error`
> for non-f64 widths). The keep claim is that Bennett ships the round-to-nearest-
> even / toward-zero **algorithm**; the `.f80` variant is that same algorithm
> **widened** — CQ's standing width parity-inversion (Rule 15; the same f64→f80
> widening that already underlies **every** CQ f80 soft-float leaf, per
> `consult-bennett-jl-always`). This is categorically different from `fmod`/`frem`,
> where Bennett has **no** remainder algorithm at **any** width — nothing to widen.
> So the Bennett gate is satisfied at the algorithm level for the rounders and
> fails outright for `frem`. The
`fmod`×3 that the pre-correction §1 counted **do NOT** contribute — `frem` fails
the Bennett gate (see the §1 correction banner), so they stay declined. `floorl`/
`ceill`/`roundl`.f80 already lower via injection (no scoreboard delta, but they
are equally Bennett-backed and template-path-robust). The **f64/f32** `floor`/
`ceil`/`trunc`/`round`/`rint` are already legitimate **hardware** keeps (SSE4.1
`roundsd`); this delta is purely the **f80 l-suffix** rounder variants, which are
libcalls at codegen but `@llvm.<fn>.f80` intrinsics CQ intercepts and Bennett
backs. All 3 are pure-doctrine (census already skips their base names as keeps;
the goldens promote COMPILES-by-recognition → VERIFIED).

**Scope of the exception — measured, does NOT generalize:**

| candidate | builtins-on IR | verdict |
|---|---|---|
| `fmod`/`fmodf`/`fmodl` | `frem` (in grid) | **decline** — recognizer holds but **Bennett has no `frem`/`fmod` gate sequence** → fails the backend-realizable gate; NOT a keep (§1 correction) |
| `remainder`/`remainderf`/`remainderl` | `call @remainder*` | decline — no frem-equivalent (IEEE remainder ≠ C fmod rounding) |
| `remquo`/`remquof`/`remquol` | `call @remquo*` | decline — also returns quotient bits; no opcode |
| `nextafter*` / `nexttoward*` / `logb*` | `call @…` | decline — no cheap opcode fold |
| `acosf`/`acoshf`/`asinhf`/`hypotf`/`atanhl`/`log1pl`/`logl` | `@llvm.<fn>` (retired) or `call` | decline — transcendental, Rule-18 retired name-recognition |
| `powf` | `@llvm.pow.f32` | decline — the `powf(q,0.5)→sqrt` fold is a **0.5-exponent artifact**; general `powf(q,0.3)` → `@llvm.pow` → declines |

No cell in the whole loop/unknown-callee bucket is a keep: `fmod` looked like a
disguise (folds to the in-grid `frem` opcode) but fails the Bennett gate, so it
stays declined with the rest.

---

## 2. Deferred capability tiers (parked cells)

### Tier A — data-dependent-trip loops (the deep capability; pickup `8h7d.1`)

The trip count or exit predicate is a function of a tainted value; the static max
bound is only UB-derivable (SCEV returns "Unpredictable" on the exact `-O1`
shapes). Needs bounded **peel + predication** with UB-derived max-trip inference +
loop-carried tainted state (see `SCOPING-payne-hanek-trig-reduction.md` for the
full 5-layer stack behind the trig cells).

| cells | shape | first diagnostic |
|---|---|---|
| `sin`/`cos`/`tan` {f32,f64,f80} (9) | Payne–Hanek `__kernel_rem_pio2` | `kMsgStore` (tx fill) → loop stack |
| `lgammal`/`tgammal`.f80 | inner `sinl` reduction (same kernel) | non-reversibilizable under lift |
| `remainder`/`remquo` {f,,l} (6) | fix-point bit-alignment loop | `loop under quantum control` |
| `fmod`/`fmodf`/`fmodl` | bit-reduction loop (injection) / `frem` (builtins-on) | **declines** — recognizer holds but no Bennett `frem` gate (§1 correction) |

Bennett.jl parity: Bennett **rejects this source too** (nested loops + goto; its
data-dependent loops need a user-supplied K + a *simulate-time* convergence
witness CQ cannot have). Its trig coverage comes from **substituting** a
branchless SoftFloatLib kernel (Float64-only). CQ's declines are parity-correct.

### Tier B — loop-carried (cross-iteration dirty rail); pickup `8h7d`

A loop-carried tainted value crosses the back-edge; the 799w Case-A/B core
declines with `loop-carried tainted value crosses iteration`. These are additive
widenings of the shipped loop core, not the Tier-A research capability.

| cells | note |
|---|---|
| `acosf`/`acoshf`/`asinhf`/`hypotf`/`powf`.f32 (5) | 8h7d census first-blockers |
| `atanhl`/`log1pl`/`logbl`/`logl`.f80 (4) | ld80 loop-carried bucket |
| f64/f32 siblings of the above | masked behind INNER-CALL/SHADOW; re-census after Tier-A |

**Caveat (measure before counting):** some f32 "loop-carried" first-blockers are
the injected *software* body of a keep-set primitive (e.g. an injected `sqrtf`
loop). Under the ship-model keep-set those may evaporate — per-cell inspection
needed before treating them as genuinely loop-gated.

### Tier C — genuinely out of any near-term model

- **Full-range `remainder`/`remquo`** — no branchless equivalent; dynamic
  alignment over the whole exponent range (bound ~2046 at f64, ~16382 at f80)
  makes even Tier-A peel+predicate impractical.
- **`nextafter*`/`nexttoward*`** — volatile-runtime `t=x*x` idiom + by-value
  ULP step; separate Shadow/volatile axis (`3c6m.51` store bucket), not loops.
- **`powl`** — inner `powil` `while(n)` with a **quantum** trip; boundable by
  bit-width but still needs per-iteration predication (Tier-A adjacent).

---

## 3. The near-term ALTERNATIVE that is NOT deferred — branchless leaves

For the trig/gamma family, the owner-approved **branchless-leaf** category
(`20xt.8`, `branchless-f80-leaf-recipe`) gives users a compiling quantum program
**today** without the loop capability: `branchless/{sin,cos,tan}.c` (f64) and
`branchless/{sinl,cosl}.c` (f80) exist and are e2e-verified; the lgammal hybrid
is VERIFIED. The **one gap is `tanl`** (filed `20xt.9`).

Honesty constraint (unchanged): a branchless/hybrid slice is a **disjoint
scoreboard category** — the real-openlibm census cell **stays declined** (no
census delta), and hybrid goldens are never quoted alongside real-openlibm
goldens. This is coverage of the *user-facing function*, not of the *openlibm
body*.

---

## 4. What to do now (recommended, in order)

1. ~~Reclassify the fmod family as `frem`-keeps~~ **DONE + corrected (bd `3c6m.56`,
   2026-07-24):** the **round family** `rintl`/`nearbyintl`/`truncl`.f80 was
   verified as Bennett-backed keeps (+3 VERIFIED via `tests/e2e/slice_libm_keep_*`);
   the **fmod family was REJECTED** (Bennett has no `frem`/`fmod` gate sequence —
   §1 correction banner). No keep-set/census change (rounders already keeps; fmod
   stays declined). The native `frem` recognizer parity-inversion is a separate
   follow-up (`3c6m.57`).
2. **Bucket** the Tier-A/B cells as "deferred — out of v1 scope" in the census
   (keep them in the denominator; §0). No number is deleted.
3. **Build the branchless `tanl` leaf** (`20xt.9`) to complete the trig trio in
   the hybrid category.
4. **Leave Tier-A for a phase decision** (`8h7d.1`) — it is roadmap-resequencing
   scale (bounded peel + predication), payoff 11+ census cells, and the adversarial
   verdict is that no bounded increment compiles any Tier-A cell before it lands.

## 5. Pickup pointers

- `8h7d` (loop campaign, DEFERRED) · `8h7d.1` (trig/Payne–Hanek deep-end) ·
  `iw81.13` (QRAM-in-loop) · `20xt.9` (branchless tanl) · `iw81.16` (const-index
  value-Shadow parity) · `3c6m.56` (**round-family keeps DONE**, fmod REJECTED —
  Bennett-gated, §1 correction) · `3c6m.57` (native `frem` parity-inversion review).
- Memories: `payne-hanek-trig-scoping-2026-07-24`, `predmux-l6-inc4-recensus`,
  `ld80-o1-recensus-3c6m51`, `libm-scoreboard-two-numbers`,
  `branchless-f80-leaf-recipe`, `consult-bennett-jl-always`.
- Census JSON: `tools/library_coverage/full_surface/ld80_census_O1.json`.
