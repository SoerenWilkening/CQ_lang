# SCOPING — L3 data-dependent-trip loops, via the fmod/remainder/remquo family

**Date:** 2026-07-27 · **Branch:** `3c6m.14-control-l6` · **Status:** scoping memo of
record (investigation only — **no pass change in this increment**).
**Tracker:** bd `8h7d.1` (the Payne–Hanek L3 sibling), `tegx` (corpus), `3c6m.59`
(by-ref probe convention), `3c6m.62` (2-arg probe convention).
**Companion memo:** `SCOPING-payne-hanek-trig-reduction.md` — the *other* 9-cell L3
family. Read both before scoping any loop work.

> **VERDICT: do not build a quantum-trip loop capability. Keep all 9 cells
> declined. Do not resequence the roadmap.** The payoff of the best design we
> could construct is **zero cells**, measured — not "expensive", *zero*.

> **ADDENDUM 2026-07-28 — the line sharpened on the one cell this memo did not
> cover.** `logbl.f80` was the only census cell where the §5.1 ruling's terms were
> genuinely ambiguous, and it is the *best case* for reading them narrowly:
> measured, back-edge excision makes it lower **completely** (`opt` exit 0,
> verify-clean, zero residual `@cq_*`, **no deeper layer at all** — unlike the
> nine cells here, it has no L2/L4/L5 stack), and its loop-carried values are
> purely **classical** (a counter and a shift register), so no dirty rail crosses
> the back edge, Rules 6/8 are untouched, and §6 item 1 — the shift-until-normalized
> bound SCEV cannot see — is *structurally absent*. Only its **trip count** is
> quantum-dependent. **Owner ruling: still out.** The test is the trip count
> alone, never the cleanliness of the loop body. Written into CLAUDE.md Rule 18.
> **Consequence beyond this memo:** bd `8h7d` now owns **zero** census cells and
> is a pure capability tracker. Recorded in bd
> [`libm-census-scope-axis-2026-07-28`].
>
> The same pass found that this memo's §5.1 extension to Payne–Hanek, while
> correct in outcome, rests on a **weaker leg** than the `fmod` family does — see
> §2 Leg A below and bd [`bennett-grounding-asymmetry-2026-07-28`]. Bennett *does*
> ship a concrete branchless Payne–Hanek (`src/softfloat/fsin.jl:468`,
> re-verified at rev `e15ea23`); what it cannot realize is openlibm's **source
> form**. For `fmod` there is no algorithm at any width. Both decline; only one of
> them is doubly grounded, and the trig nine have a shipped parity answer (the
> authored branchless leaf) that `fmod` does not.

Method: real openlibm injection at the `-O1` ship floor over a **verified-complete**
251-`.bc` corpus, the committed plugin (never rebuilt during analysis), a Bennett.jl
consult at `9c1b77e`, and a four-lens adversarial refutation round. Artifacts under
`tools/library_coverage/full_surface/`; per-cell IR cached during the session.

---

## 0. Corrections to the record (read these first)

Four recorded claims are **refuted by measurement** this session. The campaign's
bucket counts have now been wrong five times; treat every published number as a
hypothesis until re-measured (Rule 11).

1. **The corpus was stale AND the retraction of that fact was itself wrong.** The
   2026-07-27 tkju note claimed `ld80/e_fmodl.c`, `ld80/s_remquol.c`,
   `ld80/s_truncl.c` "all three compile with rc=0 and ZERO errors". Re-measured at
   the same corpus rev `82e90ae`, same host, those exact flags: **rc=1 with 5, 1 and
   2 errors** respectively. They need BSD `<machine/ieee.h>`, which openlibm ships
   nowhere — `e_fmodl.c` even has its own `#include` commented out at :14 while
   still declaring `struct ieee_ext bits;` at :58. Fixed durably by the in-tree
   `shim/machine/ieee.h` (+ two validation programs). See bd
   `census-corpus-ieee-shim-tegx`.
2. **The family taxonomy was wrong.** Recorded: "7 loop-carried + the 2 f80 on a
   tainted store (Shadow)". Measured on the corrected corpus: **all 9 cells are
   loop-carried declines.** There are no memory-store cells in this family.
   `full_census_O1.json` updated (2 cells: `remquol.f80`, `remainderl.f80`).
   **Scoreboard UNMOVED at 95/123 injection-covered, 94 verified** — a corpus fix
   moves no cell across compile/decline, it only tells the truth about *why*.
3. **"fmod/remainder/remquo rides the already-scoped bounded-loop lever `8h7d`"
   is wrong** (commit `12c26a4`'s message). The trip count is a difference of
   IEEE *exponents* of the tainted argument — quantum-data-dependent, i.e. L3,
   the same capability class as `rem_pio2`. This memo supersedes that clause.
4. **Every recorded per-cell diagnostic is a FIRST BLOCKER ONLY.** `opt`
   terminates on the first `DS_Error`, so a cell's recorded bucket names one
   layer of several. Measured: `fmod.f64`'s reported site is *not* the
   `while(n--)` fix-point loop at `e_fmod.c:96` but the subnormal-`ilogb` loop at
   `e_fmod.c:56`, which precedes it in loop preorder.

---

## 1. The measured blocker stack — four loop classes, not one

Established by **back-edge excision** on copies (delete the back edge, drop the
corresponding header-phi incomings, `opt -passes=verify` clean on every output) plus
`print<loops>` / `print<scalar-evolution>` on the cached cell IR.

| Layer | Site | Static bound available **today**? |
|---|---|---|
| **L1/L2** — subnormal `ilogb` loops | `e_fmod.c:54,56` (+ `:63,65` when arg1 is quantum) | **YES** — SCEV constant max `i32 32`, and the bound is *quantum-independent* (an i32 width fact) |
| **L3** — the fix-point `while(n--)` | `e_fmod.c:96` / `s_remquo.c:106` | **NO sound one** — see §3 |
| **L3a** — the in-body `return Zero[...]` | `e_fmod.c:101-102` (+ f32/f80 siblings; `remainder`/`remainderf` inherit via `e_remainder.c:55`) | multi-exit; **5 of 9 cells** |
| **L4** — the normalize `while(hx<0x00100000)` | `e_fmod.c:112`, `e_fmodf.c:91`, `ld80/e_fmodl.c:128` | **NO — SCEV `Unpredictable`, 9/9 cells** |

**Below the loops, the family is already fully covered.** Excising the loops makes
`fmod.f64` and `remainder.f64` lower **completely** — `opt` exit 0, verify-clean,
zero residual `@cq_*` intrinsics. The QROM reads of `Zero[]`, `llvm.fshl.i32`, the
subnormal shift diamonds, the word surgery, and `remainder`'s own tail all lower on
shipped machinery. That is the genuinely encouraging finding, and it is why this
family looked like a beachhead.

**But the stack does not stall *below* the loops — it stalls *inside* them.**

Verified independently for this memo, all 9 cells:

```
fmod.f64 4   fmodf.f32 2   fmodl.f80 2      <- count of loops whose SCEV
remquo.f64 3 remquof.f32 1 remquol.f80 1       backedge-taken count is
remainder.f64 4 remainderf.f32 2 remainderl.f80 1   "Unpredictable"
```

Every cell has at least one loop that SCEV cannot bound at all.

---

## 2. Bennett.jl parity — a parity inversion, on the decisive leg

Consulted at `9c1b77e`, source-verified (hand-traced; **UNVERIFIED by execution** —
no Julia on this host).

**Leg A (decisive, requires no interpretation): Bennett does not implement this
function family at any width.** `src/softfloat/` holds 33 files, **zero** matching
`rem|mod`; `README.md:152` lists `frem` under *Out of scope*;
`Bennett-VISION-PRD.md:257` ("Soft remainder via soft_fdiv") is a **planned** row
whose shipped column reads `None`. Bennett does not solve `fmod` by a different
algorithm — **it does not solve it at all.**

**Leg B (was "arguable" — SETTLED by owner decision 2026-07-27, see §5.1: a
K-parameterized unroller does NOT satisfy condition (2)): Bennett's
data-dependent-loop mechanism is not a gate sequence.** It is a **K-parameterized unroller** — `for _iter in 1:K`
(`cfg.jl:219`), back edge removed, refusing to run without a user-supplied K
(`driver.jl:80-83`) — with **zero static trip-count inference anywhere in `src/`**,
whose only correctness witness is a convergence wire read at **simulate time**
(`simulator.jl:215-223`, `diagnostics.jl:258-264`) over *random probe inputs*, and
which `reversible_compile` **never invokes**. Under Rule 18 condition (2) — "Bennett
ships a reversible gate sequence for that construct" — a family of circuits indexed
by an unverifiable parameter **does not qualify**. The counter-argument
considered (that Rule 18's keep/cut line governs named-call keeps, and a
source-injected loop is stock IR whose individual peeled templates Bennett does back)
was put to the owner and **rejected**: condition (2) asks whether Bennett can realize
*the construct*, and a circuit family indexed by an unverifiable parameter cannot be
realized without the simulate-time witness CQ has foregone. **So this family declines
on BOTH legs**, and the rule now pre-decides every other data-dependent-trip body.

**Bennett's actual answer to this problem class is a fixed-trip branchless kernel.**
`src/divider.jl:22-36` `_soft_udiv_compile` / `_soft_urem_compile` is a restoring
division with a **statically fixed 64-iteration loop** and `ifelse` predication —
no data-dependent trip count anywhere. That is the shape Bennett can realize.

**Corrections to the prior Bennett notes:** (a) the claim "`remquo` ACCEPTS, `fmod`
REJECTS (`IRRet` in loop body)" does not survive — `lower_loop!` mis-derives
`exit_label` to a *body* block for `fmod`'s shape and pre-seeds it into `seen`, so
the early-`return` block is never enqueued; Bennett rejects `fmod` for a
header-branch reason, not the in-body return. (b) `Bennett.jl:140` is only the
`CompileOptions` *field*; the mechanism (full unroll + MUX-freeze of loop-carried
phis) is `cfg.jl:152-412`. Neither correction changes the verdict, because Leg A
is independent of both.

---

## 3. The crux — what substitutes for the simulate-time convergence witness?

**Nothing does. No option we could construct prevents a silent miscompile.**

The strongest idea the design phase produced was structurally right: **delete the
parameter.** Bennett needs a simulate-time check only because its K is a *user
input*; if CQ *derives* K, then "under-sized K" becomes **unreachable** rather than
undetected — a parameter can be wrong, a derivation that fails to derive becomes a
loud decline. That argument is sound **in form**. It fails **in substance**, on
three measured grounds:

**(a) The proposed derivation is unsound as written.**
`SE.getSignedRange(getSymbolicMaxBackedgeTakenCount(L)).getSignedMax()` reads an
**unsigned** backedge-taken count as **signed**: on the f32 cell the BTC range prints
`U/S: [-127,129)` → the formula yields 128, while LLVM's own answer on the *same*
SCEV is `constant max backedge-taken count is i32 -2` = 4294967294. **`-2` is the
sound unsigned answer; 128 is the discarded half.** It is additionally **off by
one** — it returns a backedge-taken count where a peel needs a *trip* count
(BTC + 1), so the claimed safety margin at f64 is exactly 0, not +1.

**(b) The cited in-tree precedent refutes the proposal rather than supporting it.**
`qromIndexKnownInBounds` (`QramLowering.cpp:684-687`) uses poison-free known-bits, an
explicit `isNonNegative()` check, and an **unsigned** compare. The proposal uses
`nsw`/`nuw`-derived SCEV ranges and a signed max with no non-negativity check —
the opposite discipline wearing the precedent's name.

**(c) Even a *correct* K does not close the gap, because 5 of 9 cells are
multi-exit.** Measured (`print<loops>`): `fmod.f64`'s fix-point loop is
`%.preheader16.i<header>, %68<exiting>, %76<latch><exiting>` — **the header is not
an exiting block and there are two exits to two distinct targets.** The header's
branch condition is the trial-subtract sign test `hz<0`, *the quotient bit*, which
oscillates every iteration. "MUX-freeze on the loop's own exit compare" is therefore
**undefined-to-wrong** for exactly the cells that need it, and Bennett's
`cfg.jl:190-191` (which derives `exit_label` solely from the header branch) has no
multi-exit handling to copy. Against this *wrong-exit-model* class CQ would be
strictly **weaker** than Bennett: Bennett's K+1 convergence pass re-resolves the exit
condition on the frozen state and errors; CQ has no analogue, and **neither shipped
gate can see it** — the golden byte-diff records a gate stream that is self-consistent
under whatever predicate was chosen, and `free_pairing_check.py` witnesses rail
pairing, which stays clean under a wrong freeze predicate.

**Option (B) — user-supplied K plus a trap wire or a residual-nonzero flag — is
rejected unconditionally.** A trap wire is forbidden by Rule 5 (the compiler never
emits a measurement the user did not write; `cqrt_measure_<W>` is minted at exactly
one site, `WidthDispatch.cpp:373-379`, from a user `cq_measure`) and is self-defeating
anyway (the convergence bit is entangled — reading it collapses the answer). A kept
unread flag is branch-correlated residue that dephases. It is the cheapest option and
the only one whose accept path rests on an input the compiler cannot check; that
combination is precisely the unforgivable failure mode.

**Two attractive shortcuts that do NOT work, recorded so they are not re-proposed:**

- **"The mantissa is fixed-width, so the loop is bounded by ~53/64 iterations."**
  **False.** `fmod` computes an *exact* remainder, so all ~(ex−ey) quotient bits
  must be produced; a 64-step mantissa pass reduces the exponent gap by at most 64,
  so it needs `ceil(2097/64) ≈ 33` outer passes and **the outer trip count is still
  data-dependent.** The governing quantity is the **exponent difference**, not the
  mantissa width. (This is why Bennett's fixed-64 divider does not generalize: it
  produces a W-bit *rounded* quotient with a sticky bit, not an exact remainder.)
- **`fmod` via modular exponentiation** (`x mod y` through ~23 modmuls). The algebra
  is right, but the cost claim is not: Beauregard/VBE-class reversible modular
  multipliers assume a **classical constant** modulus and multiplier — that is what
  makes the reduction a fixed sequence of constant-adders. Here the modulus, the
  multiplicand *and* the exponent are all quantum. Neither CQ nor Bennett has a
  quantum-modulus reversible multiplier.

---

## 4. Recommendation

**Scale: roadmap-scale research with a currently-negative payoff. Do not start it.**

**Do now — zero code:**

1. **Keep all 9 cells declining** at `LoopLowering.cpp:969` (`kMsgBreakMultiSite`)
   and `:1161` (`diagnoseUnderControl(TE, "loop")`). This is **Rule-18-correct**
   (parity inversion, §2 Leg A), **not a Rule-17 punt**: we did not set out to build
   quantum-trip loops, and the shape lies outside every accept surface CQ ships. The
   Rule-17 obligation is to not decline *the thing we set out to build*; here the
   measured answer is that the thing itself is unbuildable soundly today.
2. **Do NOT weaken `PRD-7.3.md` §2.6 or `LoopLowering.cpp:207-209`.** The design
   phase proposed rewriting the "permanent decline" rationale as measurably wrong;
   that action item is **struck** — the counterexample requires a static bound, and
   §1 shows none exists for 9/9 cells. Both the conclusion *and* its stated reason
   survive for this family. Appending the measured evidence is fine.
3. **Record the durable facts in `bd remember`** so the next agent does not
   re-derive them wrongly (done this session).

**Do not do:** any variant of option (B); an "f32-first" peel scope (§5 note on
`e_fmodf.c:57`); a hand-authored branchless leaf *as census coverage* (by the
campaign's own honesty rule a hybrid leaf leaves the census cell **declined**).

**Cell payoff of building the best design: zero.** Cost of not building it: nine
cells stay honestly declined — the status quo. **Nothing becomes harder by waiting:**
the capability is freeze-orthogonal (a peel emits only already-frozen symbols), so it
can be revisited after Phase 11 at no penalty.

**Governing prior.** CLAUDE.md records 13 over-accept holes across three adversarial
Rule-13 rounds on loop work, three of them found *after* the epic was closed as
cleared. A peel recognizer resting on poison-derived SCEV ranges, applied to
multi-exit loops, under superposition (where *every* basis state runs, including
classically-UB ones), fits that profile exactly. This exercise was the fourth such
round, and it hit: **five independent defects in a design that had already been
through a measurement phase and a design phase.**

---

## 5. Open questions — decisions for the owner

1. ~~**Rule 18 condition (2), strict reading:** does "Bennett ships a reversible gate
   sequence for that construct" cover a **K-parameterized unroller with no static
   bound inference and no compile-time witness**?~~ **ANSWERED — owner decision
   2026-07-27: NO.** Condition (2) means a *concrete* gate sequence; a construct
   whose realization depends on an unverifiable parameter is a parity inversion and
   declines. Written into the Rule-18 text in `CLAUDE.md`. **Consequences, which
   reach past this family:** §2 Leg B now stands on its own alongside Leg A, so the
   decline here is doubly grounded; and the same rule pre-decides **every** other
   data-dependent-trip library body — Payne–Hanek `rem_pio2` (bd `8h7d.1`) included,
   whose 9 cells are therefore now blocked on parity, not only on cost. The line
   stays coherent because Bennett's **fixed**-trip branchless kernels *are* concrete
   gate sequences (`src/divider.jl:22-36`), so a statically-known bounded trip count
   remains in scope; only a quantum-dependent one is out.
2. **Does the record get amended?** Recommendation: *append* evidence to PRD-7.3
   §2.6, leave the "permanent decline" language intact.
3. **Does the f80 width get an explicit parity exemption?** Even under a hypothetical
   working peel, K ≈ 32828 is unrealizable. If the standing width-parity principle
   admits no partial-width capability, this family is permanently out regardless of
   any future bound analysis — which *closes* the question rather than parking it.
4. **Is the in-tree `shim/machine/ieee.h` accepted**, and does the rebuilt corpus
   recipe stand as the reproduction of record?

---

## 6. What would change this answer

Ranked by how decisively each flips it:

1. **A sound static bound for the normalize loop** (`e_fmod.c:112`). Its real bound
   *is* a mantissa-width fact (≤ 23/52/63 shifts, since `hx|lx ≠ 0` on entry), but
   SCEV cannot see it — the addend `lx>>31` is data-dependent, so the recurrence is
   not an AddRec. A domain-specific "shift-until-normalized" recognizer would remove
   the blocker. **Without this, nothing else matters: the peel is unemittable in
   9/9 cells.**
2. **A sound K derivation** — *unsigned* max of the BTC range, `+1` for trip count,
   an explicit non-negativity/reachability check in the `QramLowering.cpp:687` style,
   and a validated multi-exit upper-bound argument.
3. **Defined and proven freeze semantics for multi-exit loops** — the disjunction of
   all exit conditions, made *sticky*. Bennett has none to copy. Without it the five
   fmod-shaped cells stay out even if (1) and (2) land.
4. **A pass-level fix for the compile-time wall** (measured: 15 s at K=256,
   unfinished at 20 min at K=1024; gate counts are linear, compile time is not).
   Gates testability, not correctness.
5. **Bennett shipping `soft_frem`** (currently a `WORKLOG.md` NEXT item). That flips
   §2 Leg A — at which point the right lowering is very likely **not** a peel of
   openlibm's loop at all, but the fixed-trip kernel.

---

## 7. Honesty notes (Rule 2 / Rule 11)

- **Nothing here was linked or run as a program.** No option in this memo reached
  `opt` exit 0 on a real cell; "compiles" would not be "verified" even if it had.
- The Bennett `cfg.jl` traces are **hand-traces against real IR, not executions**
  (no Julia on this host).
- The f32 "true max trips = 24" is exhaustive over all 2³¹ non-negative bit patterns
  against `y=0.5f`; the f64 "≈53" is 4M random + a structured grid, **not**
  exhaustive.
- **Two census-convention caveats limit what these cells measure at all**, and both
  bear on any future attempt: the 2-arg convention pins `arg1` to the literal `0.5`
  (bd `3c6m.62`), so `iy` const-folds and the measured bounds are *not* the
  both-operands-quantum bounds; and the by-ref convention never reads the out-param
  (bd `3c6m.59`), so in `remquo.f64`'s cell the `quo` pointer is literally `undef`
  — **the census cell does not compile `remquo`, it compiles a function from which
  the quotient half has been deleted.** Any future beachhead claim on `remquo` must
  be re-measured against a live out-param first.
- The f32 general (both-operands-quantum) case has **no bound at all** for a reason
  unrelated to the above: `e_fmodf.c:52` uses `i>0` but **`:57` uses `i>=0`** — an
  `i>=0` shift loop does not terminate at `i==0`, so SCEV cannot bound it. That kills
  "f32 first" as a scoping option independently of everything else.
