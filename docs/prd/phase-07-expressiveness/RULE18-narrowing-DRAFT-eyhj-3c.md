# DRAFT ONLY — proposed replacement for CLAUDE.md Rule 18's 2026-07-28 paragraph

**bd `eyhj` acceptance item 3c. NOT APPLIED. `CLAUDE.md` is untouched.** Whether
Rule 18's text is amended is the owner's call and is not assumed here.

**Why this needs a decision at all:** the 2026-08-21 GO ruling (bd `eyhj`) narrowed a
rule whose text is currently unqualified. Rule 18 says *"the test is the **trip count**
alone"*. Read literally today, that sentence forbids the very capability the owner has
just approved — and it is quotable, load-bearing prose that has already been cited to
decide four census cells. Leaving it is the same failure mode `CLAUDE.md` records for
the `fenv` prose: a sentence hardening by repetition into a de-facto ruling.

---

## What changes

**Scope of the edit:** one sentence is modified and two paragraphs are inserted. The
`logbl.f80` worked example is **kept** — it keeps its answer and *changes its ground*.
The two corollaries that follow it (the CONSTRUCT-vs-injection distinction, and
parity-not-physics) are **untouched**, as is everything about the keep-set, `fmod`, and
the CQ-PROVIDED amendment.

### REMOVE (one sentence, at `CLAUDE.md:327-328`)

> It still declines. So the test is the **trip count** alone, never the cleanliness of
> the loop body.

### REPLACE WITH

> It still declines — and the cleanliness of the loop body never enters the test.
>
> **NARROWED by owner ruling 2026-08-21 (bd `eyhj`) — and the narrowing is to a
> DERIVATION, never a parameter.** The 2026-07-28 test was "the **trip count** alone".
> That is now one clause short. **A quantum-dependent trip count is ADMISSIBLE when the
> compiler PROVES a quantum-independent upper bound `B` from the IR in front of it and
> emits the loop ROLLED at classical trip count `B`, with the body predicated on a
> quantum still-running flag. Failure to derive `B` is a loud decline.** What remains
> out is a trip count with **no derivable bound** — which is where `logbl.f80` itself
> lands, so the worked example above keeps its verdict and *changes its ground*: it
> declines because SCEV reports `CouldNotCompute` on both its loops under every
> pipeline and its rotated body genuinely does not terminate on 2 of 2³² inputs,
> **not** because its trip count is quantum. It is accordingly recorded as
> `scope: deferred-capability` (bd `ywws`), **not** `decided-decline`. Note this does
> not weaken condition (2): a derived `B` makes the emitted circuit a **fixed-trip**
> `B`-iteration circuit, i.e. the same shape as Bennett's 64-iteration restoring
> divider, which the existing line already admits ("a bounded, statically-known trip
> count stays in scope"). *That reading is analytic — `/private/tmp/Bennett.jl` does
> not exist, so condition (i) is currently **unmeasurable** for this family and must
> not be asserted as checked.*
>
> **Why a DERIVATION and not a cheaper `K` — this is the whole safety argument.** A
> parameter can be wrong and still compile; a derivation that fails to derive stops the
> compiler, so an undersized bound becomes **UNREACHABLE** rather than **undetected**.
> That asymmetry is load-bearing because **neither shipped gate can see an undersized
> bound**: the golden byte-diff records a gate stream self-consistent under whatever
> predicate was chosen, and `free_pairing_check.py` witnesses rail *pairing*, which
> stays clean. An undersized bound is a verify-clean silent miscompile, definitionally.
> So a user-supplied `K`, a `name → K` database, a flag that *supplies* `K`, and an
> **offline-measured** `K` are all refused on that one ground — the last specifically
> because a classical run samples the **guard-admitted** domain while the emitted
> circuit runs the **unguarded** one (PredMux removes every guard: measured `br i1`
> 5→0, 4→0, `switch` 1→0), so more samples do not converge on the right answer. A flag
> that merely *raises* an already-derived sound bound is wasteful, not unsound, and is
> not what is at issue. **A derived bound needs seven conditions, every one a measured
> over-accept hole:** constant ∧ non-negative ∧ small ∧ reachability-**total** ∧
> `1 ≤ shift-amount ≤ W-1`, with the constant-max BTC read as an **APInt at its own
> width** — `isa<SCEVConstant>` alone over-accepts **30 of the 49** loops it takes
> (worst bound: 4 294 967 295 trips), and `getSmallConstantMaxTripCount` returns
> `4294967295` on some vacuous bounds and `0` on others, so neither return value
> distinguishes vacuity in either direction. **Measured payoff, stated so the rule is
> never read as bigger than it is: TWO cells** (`ilogb.f64`, `ilogbf.f32`; 98 → 100).
> The `fmod`/`remainder`/`remquo` nine and the Payne–Hanek nine are **unmoved** — bd
> `19v3` measured the whole census surface, not one family. Recorded in bd
> [`narrowed-quantum-trip-rule-2026-08-21`]; population memo
> `docs/prd/phase-07-expressiveness/SPIKE-19v3-loop-bound-population.md`.

---

## What deliberately does NOT change, and why

| text | verdict |
|---|---|
| *"A construct whose realization depends on an **unverifiable parameter** does not satisfy condition (2): it is a parity inversion and it declines."* | **KEEP VERBATIM.** This is the *ground* of the narrowing, not a casualty of it. Bennett's K is still refused. |
| *"it applies to **every** data-dependent-trip library body (the `fmod`/`remainder`/`remquo` family, Payne–Hanek `rem_pio2`, and any future one)"* | **KEEP.** The *test* still applies to all of them, and measured (bd `19v3`) all 18 of those cells still decline. |
| the `logbl.f80` back-edge-excision measurement | **KEEP.** Still true, still the best case for the other reading, still declines. |
| the two corollaries (CONSTRUCT-vs-injection; parity-not-physics) | **KEEP.** Untouched by this ruling. |
| *"the `.f80` rounder variants are that same algorithm **widened**"*, the keep-set, `fmod`-is-not-a-keep, the CQ-PROVIDED amendment | **KEEP.** Out of scope. |

## The one wording risk worth flagging before you accept it

"Failure to derive `B` is a loud decline" is the *only* thing standing between this
narrowing and an over-accept, and Rule 18 is prose, not a fence. The fence has to be
built in `LoopLowering.cpp` under Rule 12 red-green **and** Rule 13, with the seven
conditions above as its decline partition. If the text is amended before that fence
exists, the rule permits a lowering the compiler cannot yet safely emit. **Recommend
amending only when the implementing increment lands, or amending now with the
implementation left explicitly unbuilt** — the census already carries the narrowing
either way (`ilogb.f64`/`ilogbf.f32` are `lever-gap`, not `decided-decline`), so
nothing is blocked by deferring the `CLAUDE.md` edit.
