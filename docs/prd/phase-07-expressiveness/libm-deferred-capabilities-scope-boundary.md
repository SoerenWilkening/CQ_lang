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

**Recommendation:** reclassify `fmod`/`fmodf`/`fmodl` as **`frem`-keeps** (Rule-18
keep-set addition; owner doctrine call — bd `3c6m.56`). Payoff: **+3 cells**, no new
capability (the `frem` template already exists and lowers). Follow-up = 3 e2e
goldens (builtins-on, real user shape) to promote COMPILES → VERIFIED, plus the
census measuring the fmod family builtins-on rather than injected.

**Scope of the exception — measured, does NOT generalize:**

| candidate | builtins-on IR | verdict |
|---|---|---|
| `fmod`/`fmodf`/`fmodl` | `frem` | **KEEP** (in grid) |
| `remainder`/`remainderf`/`remainderl` | `call @remainder*` | decline — no frem-equivalent (IEEE remainder ≠ C fmod rounding) |
| `remquo`/`remquof`/`remquol` | `call @remquo*` | decline — also returns quotient bits; no opcode |
| `nextafter*` / `nexttoward*` / `logb*` | `call @…` | decline — no cheap opcode fold |
| `acosf`/`acoshf`/`asinhf`/`hypotf`/`atanhl`/`log1pl`/`logl` | `@llvm.<fn>` (retired) or `call` | decline — transcendental, Rule-18 retired name-recognition |
| `powf` | `@llvm.pow.f32` | decline — the `powf(q,0.5)→sqrt` fold is a **0.5-exponent artifact**; general `powf(q,0.3)` → `@llvm.pow` → declines |

`fmod` is the **only** disguise in the whole loop/unknown-callee bucket.

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
| `fmod`/`fmodf`/`fmodl` **under injection** | bit-reduction loop | see §1 — **reclassify, don't defer** |

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

1. **Reclassify the fmod family** as `frem`-keeps (§1) — owner doctrine ratify +
   3 e2e goldens + census/keep-set update. +3 VERIFIED, no capability.
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
  value-Shadow parity) · `3c6m.56` (fmod frem-keep doctrine, §1).
- Memories: `payne-hanek-trig-scoping-2026-07-24`, `predmux-l6-inc4-recensus`,
  `ld80-o1-recensus-3c6m51`, `libm-scoreboard-two-numbers`,
  `branchless-f80-leaf-recipe`, `consult-bennett-jl-always`.
- Census JSON: `tools/library_coverage/full_surface/ld80_census_O1.json`.
