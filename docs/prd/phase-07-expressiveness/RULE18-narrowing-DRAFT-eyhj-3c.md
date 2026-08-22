# DRAFT — proposed replacement for CLAUDE.md Rule 18's 2026-07-28 paragraph

> ## ⚖ RULED 2026-08-22 (bd `qck7`) — **A MODIFIED VERSION WAS APPLIED, NOT THIS ONE**
>
> **Owner ruling: "Modified: minimal, licenses nothing."** `CLAUDE.md` **is now amended**
> at the sentence this draft targets. **Do not apply the text below** — read it as the
> record of what was *proposed on 2026-08-21*, and `CLAUDE.md` itself as what was
> *ruled*. §"What changes" below is superseded; §"What deliberately does NOT change"
> was honoured with **one recorded exception** (below).
>
> **WHY A MODIFIED VERSION, and it is arithmetic, not taste.** This draft was written
> **before** bd `ww4c` landed (`dc8f6c6`, 2026-08-22). Three of its claims went stale
> the moment it did, each measured at HEAD:
>
> | draft claim | at HEAD |
> |---|---|
> | *"Measured payoff … **TWO cells** (`ilogb.f64`, `ilogbf.f32`; 98 → 100)"* | **STALE.** `ww4c`'s `llvm.ctlz` idiom recognizer banked **both** (`full_census_O1.json`: `status: COMPILES`). The **narrowing's** marginal payoff is **ZERO cells**. |
> | *"the census already carries the narrowing (`ilogb.f64`/`ilogbf.f32` are `lever-gap`, not `decided-decline`)"* | **STALE.** `lever-gap` went 4 → 2 at `dc8f6c6`; neither cell is a scope entry any more. |
> | table row *"the two corollaries \| **KEEP.** Untouched by this ruling."* | **FALSE.** Corollary 2 says *"the census records it as `scope: decided-decline`"* — which is exactly what changed for `ilogbl.f80`/`logbl.f80` (now `deferred-capability`, bd `ywws`). The table missed its own collision. |
>
> **THE ONE DEPARTURE FROM THE "DOES NOT CHANGE" TABLE, recorded rather than silent:**
> corollary 2 received a **minimal parenthetical** — *"or, once a later ruling changes
> that ground, `deferred-capability`"* — so the doctrine sentence stops mis-scoping the
> very pair the ruling re-grounded. Everything else in that table was honoured verbatim:
> Bennett's user-`K` refusal, the every-data-dependent-body clause, the `logbl.f80`
> back-edge-excision measurement, corollary 1, the keep-set, `fmod`-is-not-a-keep, the
> `.f80`-widened line, and the CQ-PROVIDED amendment are **untouched**.
>
> **THE FLAGGED WORDING RISK WAS HONOURED, NOT ACCEPTED.** This draft's closing section
> warned that *"amending the text before that fence exists licenses a lowering the
> compiler cannot yet safely emit"*, and recommended amending only alongside the
> implementing increment. That increment (**bd `m57l`**) is **DEFERRED with no
> customer** — `ww4c` took its two cells by dissolving the loop instead. So the applied
> text is written to **license nothing**: it carries a blockquote reading *"DO NOT QUOTE
> THIS AS A CAPABILITY — NOTHING IMPLEMENTS IT"*, states that `LoopLowering.cpp`'s Q1
> decline is intact and unconditional, that no bound derivation for a quantum-trip loop
> exists anywhere in the pass, that **every quantum-dependent trip count still declines
> today**, and that building the fence is Rule-12 red-green **plus** Rule 13.
>
> **TWO PRECISION DEFECTS IN THE TEXT BELOW, found by the same audit — do not quote
> either without its qualifier.** (1) *"SCEV reports `CouldNotCompute` … under **every
> pipeline**"* is a universal quantifier over an unmeasured set; what was measured is
> **12 `opt` pipelines** (incl. `default<O2>`/`<O3>`) plus the post-`promoteFp80Union`
> module (`full_surface/README.md:73`), and the raw sweep artifacts are **not
> committed**. The applied `CLAUDE.md` text says "12 measured pipelines". (2) The
> *"PredMux removes every guard: measured `br i1` 5→0, 4→0, `switch` 1→0"* figures
> reproduce exactly at HEAD, but **only on the back-edge-EXCISED variants** — the
> unmodified cells decline before lowering and have no lowered output at all, so the
> instrument must be named whenever the numbers are. The applied `CLAUDE.md` text drops
> the numbers and keeps only the qualitative claim.
>
> **WHAT TIPPED IT AWAY FROM "leave parked"** (the standing recommendation at
> `DECISION-m57l-vs-ww4c.md` §5.5 and `PRD-ww4c-ctlz-idiom.md:122`): that park was
> conditioned — *"parked **while `ww4c` is the chosen path**"* — and `ww4c` has now
> landed and closed. Meanwhile the un-amended text left **two committed authorities
> contradicting each other on Rule 18's own worked example**: `CLAUDE.md` grounded
> `logbl.f80`'s decline in the trip count, while `full_surface/full_census.py:334` says
> *"the 2026-07-28 ruling no longer grounds ANY of these four"* and the cell's own
> `scope_ref` says *"NOT decided-decline: the 2026-07-28 parity ruling is NO LONGER the
> ground"*. The amendment resolves that contradiction **without** licensing a lowering.

**bd `eyhj` acceptance item 3c.** Whether Rule 18's text was amended was the owner's
call and was not assumed here; it was put to the owner on 2026-08-22 and ruled above.

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

### REMOVE (one sentence, spanning `CLAUDE.md:326-327`)

*Starts mid-326, after "only the trip count is quantum."; ends mid-327, before "**Two
corollaries". The corollaries are KEPT — do not let a mechanical application swallow them.*

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
> not what is at issue. **A derived bound needs five conditions, every one a measured
> over-accept hole:** constant ∧ non-negative ∧ small ∧ reachability-**total** ∧
> `1 ≤ shift-amount ≤ W-1`, with the constant-max BTC read as an **APInt at its own
> width** *(a reading refinement of C2/C3, not a sixth condition)* — `isa<SCEVConstant>`
> alone over-accepts **30 of the 49** loops it takes
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
| *"it applies to **every** data-dependent-trip library body (the `fmod`/`remainder`/`remquo` family, Payne–Hanek `rem_pio2`, and any future one)"* | **KEEP.** The *test* still applies to every one of those **bodies**, and this narrowing moves **none** of them. Stated as cells, not bodies, so it is not mis-quoted: of the 18, **12 decline** (the `fmod` nine + `sinf`/`cosf`/`tanf`.f32) and **6 already COMPILE** — `sin`/`cos`/`tan` at f64 and f80 are **CQ-PROVIDED**, so upstream's un-injectable body is not injected at all and their `decided-decline` lives on as `upstream_scope`. Either way the count this ruling changes is **zero**. |
| the `logbl.f80` back-edge-excision measurement | **KEEP.** Still true, still the best case for the other reading, still declines. |
| the two corollaries (CONSTRUCT-vs-injection; parity-not-physics) | **KEEP.** Untouched by this ruling. |
| *"the `.f80` rounder variants are that same algorithm **widened**"*, the keep-set, `fmod`-is-not-a-keep, the CQ-PROVIDED amendment | **KEEP.** Out of scope. |

## The one wording risk worth flagging before you accept it

"Failure to derive `B` is a loud decline" is the *only* thing standing between this
narrowing and an over-accept, and Rule 18 is prose, not a fence. The fence has to be
built in `LoopLowering.cpp` under Rule 12 red-green **and** Rule 13, with the five
conditions above as its decline partition. If the text is amended before that fence
exists, the rule permits a lowering the compiler cannot yet safely emit. **Recommend
amending only when the implementing increment lands, or amending now with the
implementation left explicitly unbuilt** — the census already carries the narrowing
either way (`ilogb.f64`/`ilogbf.f32` are `lever-gap`, not `decided-decline`), so
nothing is blocked by deferring the `CLAUDE.md` edit.
