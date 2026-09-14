# Track P′ × Track F′ — what my accepts gain and lose because of F′, measured three ways

**This file is the input to bd `test_C_libtooling-hlhh`'s owed Rule-13 round, and it is the reason
Track P′ was based on `f2-phidesc-precision` rather than on `main`.** It does **not** discharge that
bead: everything below was found by MEASUREMENT by the agent that wrote one of the two changes, and
CLAUDE.md's standing lesson from the 2026-09-14 group gate is exact — *"A composition is not cleared
by clearing its parts"*, and neither is it cleared by its author measuring it.

## 0. The three binaries, and why the BASE one was copied

| role | commit | `cq-opt` sha256 (first 16) |
|---|---|---|
| **ORACLE** | `main` `74eabd2c` | `0e280fc62a91cec2` |
| **BASE** | `3637fdd2` — Track F′, bd `hrts`/`l3i1`/`dpau` | `8cda04ca3f32bd73` |
| **SUBJECT** | `prep-leaf-grammar` — BASE **+** this track | `7916923f56fb36af` |

The BASE binary was **not rebuilt**: it is Track F′'s own, taken from `CQ_F` after two checks —
`CQ_F` is checked out at exactly `3637fdd2` and `diff -rq` over `ir-pass`, `include`, `runtime`,
`tools` against my branch point printed **nothing**; and its sha256 matches the SUBJECT hash Track F′
recorded in its `GATES.md` and that bd `hlhh` cites. See `GATES.md` for the gate lines.

## 1. The attribution rule, and its ONE limit stated up front

Every corpus row carries all three cells, so attribution is read off the row:

| pattern | reading |
|---|---|
| `ORACLE != BASE == SUBJECT` | **F′'s** mover, inherited — not mine |
| `ORACLE == BASE != SUBJECT` | **MINE** |
| `ORACLE != BASE != SUBJECT` | both touched it — inspect individually |
| `ORACLE == SUBJECT != BASE` | a REVERSION — must not happen; a FINDING if it does |

⚠ **THE LIMIT, AND IT IS NOT COSMETIC.** `ORACLE == BASE` means F′'s edit did not change that
module's *verdict on top of `main`*. It does **not** prove F′'s predicate behaves identically at
every point — only that nothing downstream of it noticed. So "MINE" is an inference, not a proof, and
the honest way to close it is a **fourth binary** (`main` + P′ alone), which this track did not build
because the box was at load average 214–353 and a fourth full build was not affordable. Wherever that
matters below it is said in those words. The inference is strong for this pair because F′'s edit is
confined to `collectStatePrepPhiDescendants` inside F2, which gates whether a PREP region is accepted
— and a prep whose acceptance is unchanged is a prep my leaf grammar sees identically.

## 2. The deliberately constructed composition — and it is not an accept

bd `hlhh` states the mechanism precisely and it is worth keeping in its own words:

> *`preppedRailPhiRegionIdx` admits a phi as a rail leaf IFF its region is already in the plan as a
> BranchRegion with ClassArm/ClassArmFalse == InPlaceRotation and a non-empty Shadow — i.e. iff
> classifyArms ACCEPTED that state prep. TRACK F′ MAKES classifyArms ACCEPT STATE PREPS IT USED TO
> DECLINE AT F2. … P′ widens WHAT A LEAF MAY BE, F′ widens WHICH REGIONS PRODUCE A LEAF AT ALL. A
> program that neither branch accepts alone may accept with both.*

So I built one. `probes/fxp1_composed_crossblock_nondominated_phi.ll` is **Track F′'s own recovered
accept** — `trackF/probes/acc1_dead_nondominated_phi.ll`, the state prep whose only F2 witness reaches
the seed through a DEAD, NON-DOMINATED join φ — transcribed to `i1` so its merge φ is in my leaf
grammar (`isCondRailPhiShape`: a 2-incoming `i1` φ), with **one empty block** inserted between the
prep's merge and the phase kickback's branch so the leaf is cross-block.

```
                                                     fxp1 (gap)        fxp1c (no gap)   fxp2 (no F2 witness)
ORACLE   main                                        D  F2             D  F2            **134**
BASE     + F′                                        D  my fence       **134**          **134**
SUBJECT  + F′ + P′                                   **134**           **134**          **134**
```

`D F2`  = `cq controlled lowering: state prep seed is proven equal to the condition register under quantum control`
`D my fence` = `cq controlled lowering: condition predates a non-diagonal gate under quantum control`
`134` = `PHI node operands are not the same type as the result!   %p = phi i1 [ %h_op, … ], [ false, %Y ]`
followed by `LLVM ERROR: Broken module found, compilation aborted!` from `VerifierPass`.

**Read the third column first.** `fxp2` is `fxp1c` with `%u = and i1 %MB, %q` replaced by
`%u = xor i1 %MB, true` — the same dead φ, the same tainted `i1` pure op, but no value provably equal
to the seed on either edge, so F2 has no witness on ANY binary and the prep is accepted everywhere.
**It exits 134 on the ORACLE.** The defect is therefore **PRE-EXISTING on `main`** and owes nothing to
either track:

> A **DEAD** `i1` φ whose incoming is a **tainted `i1` pure op** survives `declineClassicalMuxes`'
> liveness filter (a dead mux is not live, so the guard `continue`s); `lowerOps` then RAUWs the op to
> its `i32` template handle (`%h_op = cq_template_xor_i1_hl(...)`); the dead `i1` φ now has an `i32`
> incoming and `VerifierPass` calls `report_fatal_error`.

**What the two tracks do is ADD CUSTOMERS to it**, which is exactly the distinction CLAUDE.md insists
on — *"'pre-existing' is true of the defect and FALSE of its population"*:

* **F′ adds customers**: `fxp1c` goes from a clean, source-located F2 decline on the ORACLE to exit
  134 on BASE. A program `main` refuses cleanly is now emitted, and crashes.
* **P′ adds customers**: `fxp1` goes from a clean fence decline on BASE to exit 134 on SUBJECT. Same
  sentence, one track over.

**It is LOUD** — exit non-zero, nothing emitted, so it is not the Prime Directive's unforgivable bug.
It is nevertheless a Rule-1 *"no third path"* violation with **no source location**: the user gets an
LLVM crash dump and a `PLEASE submit a bug report to Homebrew` line instead of a `!dbg`-anchored
diagnostic.

⚠ **REACHABILITY, stated honestly and with F′'s own caveat borrowed verbatim.** All three modules are
hand-written IR. `clang -O1` deletes a dead φ, so **no C spelling is demonstrated**. Track F′ recorded
the identical limit for `acc1` — *"An IR-level ACCEPT is recovered; a C-level one is not yet
demonstrated"* — and the same words apply here, one verdict over. A hand-written `.ll` is a
legitimate compiler input (the entire `ir-pass/test` corpus is one), and the `ir-pass` layer is where
the crash would be seen first.

**Filed, not fixed.** Removing it means narrowing `declineClassicalMuxes`' liveness filter, which is a
DECLINE-direction change over a fixture population neither track measured. It belongs with whoever
owns that guard.

## 3. The corpus: every mover, attributed

Instrument: `probes/corpus_sweep3.py` → `probes/corpus_7916923f.txt`. One row per module,
`<relpath>|<ORACLE>|<BASE>|<SUBJECT>`; accepts carry an md5 of the lowered IR with `ModuleID` /
`source_filename` stripped (compared only WITHIN a row — PROTOCOL S3), declines carry the **FULL
stderr**, never a tag regex, and a 0-byte module scores `EMPTY` rather than `ACCEPT`.

**COMPLETE: 3953 rows × 3 binaries** — all 2047 shipped `ir-pass/test` fixtures plus every
`track*/probes` and `review_*_probes` module in every session directory, all three binaries on the
same input. (3943 in the main run; the 10 probes this track added *after* the sweep's glob were swept
in a supplementary pass and appended — see the run note below.)

| classification | count |
|---|---|
| identical on all three | **3933** |
| **F′-only** (`ORACLE != BASE == SUBJECT`) | **8** |
| **MINE** (`ORACLE == BASE != SUBJECT`) | **10** |
| **BOTH** (all three differ) | **1** |
| REVERSION (`ORACLE == SUBJECT != BASE`) | **0** |
| `EMPTY` (0-byte module — the passthrough vacuity trap, deliberately not scored as an accept) | 1 |

**Every one of the 19 movers is named, and none is unattributed.**

**The 8 F′-only rows are exactly the 7 Track F′ reported plus one this track constructed** — 2 shipped
fixtures (`control_inplace_ry_reject_stateprep_acyclic_nondominated_phi.ll`,
`control_inplace_ry_stateprep_acyclic_nondominated_phi_accept.ll`), 4 probes from earlier sessions
(`trackF/{fix,review}_r2_probes/r20_…`, `trackX/probes/c2_inloop_acyclic_bypass_nondominated_phi{,_live}.ll`),
F′'s own `acc1_dead_nondominated_phi.ll`, and `fxp1c_nogap_control.ll` from §2. **None of them moves
again under my change**, i.e. this track inherits F′'s accepts and disturbs none of them.

**The 10 MINE rows, all `condition predates a non-diagonal gate` → ACCEPT:**

| module | what it is |
|---|---|
| `ir-pass/test/control_phase_kickback_reject_mergephi_cross_block.ll` | the shipped fixture, converted |
| `ir-pass/test/control_phase_kickback_mergephi_two_leaves_cross_block.ll` | new fixture, bd `hn29`(2) ≡ `leyd` |
| `ir-pass/test/control_phase_kickback_mergephi_inloop_outside_prep.ll` | new fixture, bd `52og` |
| `…/session-2026-09-14-orchestrator/trackP/probes/p19.ll` | bd `hn29`'s own φ-ROOT probe |
| `…/trackP/review_r1_probes/r18_phi_and_phi_two_diamonds.s1.ll` | the round-1 reviewer's independent re-measurement of bd `hn29`(2) — same program as `p20`/`fp_x3`, now lowering with the toffoli-ancilla stream and STRICT 2b `4 mints / 3 left allocated / 1 free: 1 verified, 0 violation(s), 0 unproven` |
| `…/trackP/review_r1_probes/r21_inloop_phi_kickback.s1.ll` | bd `52og`'s own probe |
| `…/trackP/probes/{a1_clean_gap2,a2_two_prep_phi_leaves,a3_inloop_outside_prep}.ll` | this track's three hand-IR accepts |
| `…/trackP/probes/d5_bare_xor_in_gap.ll` | the V12 residual — see `IMPL_P.md` §6 |

**The 1 BOTH row is `fxp1`, §2's deliberate construction.** There is no unattributable mover.

⚠ **AN INSTRUMENT CORRECTION MADE ON THIS SWEEP, and it would have produced three false movers.**
PROTOCOL S3 says to compare decline rows by FULL stderr rather than by a tag regex. For an
`LLVM ERROR` row that backfires: LLVM's crash dump embeds `Program arguments: <binary path>`, which
**differs per role by construction**, so all three exit-134 rows read as movers under a naive
full-stderr compare — `fxp2`, whose three cells are semantically identical, was tagged `BOTH`. The
classifier normalises `Stack dump…` and `Program arguments:…` away before comparing. **Full-stderr is
still right; it just has to be the stderr and not the process's own argv.**

⚠ **A SECOND INSTRUMENT NOTE, recorded because it nearly cost coverage.** `corpus_sweep3.py` globs the
probe directories **once, at launch**. Ten of this track's probes were written after that point and
were silently absent from the first run — not skipped loudly, just not there. They were swept
separately and appended, and the union is what the table above counts. A sweep that enumerates its
inputs at start time and runs for twenty minutes is a sweep whose corpus is a snapshot; say which
snapshot.

## 4. What my accepts GAIN from F′ — measured answer: nothing yet, and here is what that means

Not one of this track's accepts required F′. Every one of them
(`a1`, `a2`, `a3`, `pA1`, `pA2b`, `pA3`, `d5`, and the three fixture accepts) is `ORACLE == BASE`
before the change — the same decline string on both — and moves only at SUBJECT.

That is the expected shape rather than a surprise, and the reason is structural: F′ enlarges the set
of PREPS `classifyArms` accepts, while the three beads are all about WHERE the φ of an
**already-accepted** prep may be read from. The two widenings compose **only** on a program that needs
both, and the only such program anyone has constructed is `fxp1` — which lands on the pre-existing
defect of §2 instead of on an accept.

⚠ **So the honest statement is "no composed ACCEPT was found", not "there is none".** The surface is
sampled by a corpus and by one hand construction; it is not enumerated. That is bd
`test_C_libtooling-oej0`'s standing complaint about composition testing generally, and this track does
not close it.

## 5. What my accepts LOSE to F′ — nothing measured

No row anywhere in the sweep is `ORACLE == SUBJECT != BASE` (a reversion), and no accept of mine
declines on SUBJECT that accepts on BASE. See §3.

## 6. What an independent Rule-13 round on the composition should do

1. **Build the fourth binary** (`main` + P′ alone) and re-run `probes/corpus_sweep3.py` with it in the
   BASE slot. That converts every "MINE" inference in §1 into a measurement, and it is the single
   highest-value thing this track could not afford.
2. **Attack §2 from C.** If any `-O1` output retains a dead `i1` φ over a tainted pure op — a
   `volatile`-adjacent idiom, a `[[maybe_unused]]`, an unreachable-but-not-deleted join — the
   pre-existing defect becomes user-reachable and its priority changes.
3. **Widen the construction.** `fxp1` is ONE composed shape. The others worth building: a prep F′
   newly accepts whose φ is an INTERIOR leaf of a condition TREE read cross-block (F′ × P′ × bd
   `4aiu`); and the same inside a bounded loop (F′ × P′ × bd `wx8g`), which is the three-way
   composition bd `oej0` says nobody has ever constructed.
4. **Ask whether F′'s slot test can see a φ this track newly admits.** F′'s
   `availableAtAnF2Slot(I, PredSlot, ArmSlots, DT)` is asked of every user of the merge φ. P′ does not
   add users, but it DOES add regions whose `Merge` is a φ that F2 will subsequently reason about in
   a *later* region's classification. Whether a P′-created accept can change a *subsequent* F2
   verdict is the one interaction neither track's record addresses, and it is not answered here.
