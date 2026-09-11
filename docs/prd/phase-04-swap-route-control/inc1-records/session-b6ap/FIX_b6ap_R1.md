# FIX record — bd `test_C_libtooling-b6ap` (the multi-phi merge peel), round-1 BLOCK

> ⚠ **ERRATA, 2026-09-11, from the Rule-13 ROUND-2 review (`review_b6ap_r2.md`,
> CLEAR-WITH-ITEMS) — this record is left as written and corrected here, not
> rewritten.** Two of its claims are superseded by `FIX_b6ap_R2.md`:
>
> 1. **"the four-call sequence" / "Why all FOUR calls" — IT IS FIVE.**
>    `foldIdentityBitcasts` is a FIFTH stage that consumes taint to make a decision
>    about a value (it folds ONLY an already-tainted same-width int<->int `bitcast`
>    and is the SOLE handler for that opcode), and it was not in this fix's
>    enumeration. A bitcast the peel taints later was left standing and died at
>    `no template for opcode 'bitcast i32' in tainted context` while the hand-peeled
>    twin lowered at exit 0 on both binaries (finding **F-B6R2-1**, an OVER-decline,
>    hand-IR only). It is now call 1 of `adjudicateTaintDelta`, ahead of the four
>    below. The per-stage table in "Position: candidate (b) chosen" is likewise one
>    row short; the complete 15-row walk is `IMPL_b6ap.md` §2c.
> 2. **Open question 1 — "`declineStaleRecordOps` over the peel delta has no
>    measured customer (mutant M-D)" — IS ANSWERED, in the affirmative.** The
>    structural argument given below is WRONG: the missing case is not an op that
>    reads a stale record *and* the mux, but an op whose staleness the peel CREATES
>    by flipping a `cq_theta` from a SOURCE mint to a CHAINED rotation on the mux
>    rail (probe `S02`, plain C at `-O1`). The call stays, and it now has a fixture
>    (`control_peel_reject_stale_mux_record.ll`); see `IMPL_b6ap.md` §2e.
>
> Everything else in this record stands as measured.

Answers `review_b6ap_r1.md` (verdict **BLOCK**) per `FIX_BRIEF_b6ap_R1.md`. Worktree
`/Users/sorenwilkening/Desktop/CQ_b6ap`, branch `merge-phi-peel`, its own `build/`.
ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}`
(`main` `0c7380c`, read-only — never rebuilt, never written to). Nothing committed or
pushed. Probes and `ab.sh` are the reviewer's own, in `review_b6ap_r1_probes/`.

---

## F-B6-1 — CONFIRMED SILENT MISCOMPILE (the BLOCKER) — FIXED

### What was wrong

`peelIndependentMergePhis` makes a previously **classical** merge φ into a **quantum**
`select`, and it does so at `CQLoweringPass.cpp:416` / `:887` — ~90 lines after the
three stages that adjudicate *consumers of tainted values* have already run as
pure-analysis pre-passes (`detectSpecializations` :321, `declineTaintEscapes` :330,
`declineStaleRecordOps` :337). Every value the peel makes quantum is a value they never
saw. This is CLAUDE.md's standing lesson — *"a stage that runs ONCE has a round-2-FALSE
premise"* — for a stage that **grows taint** rather than one that runs once, and the
in-tree precedent for the obligation is `repropagateControlMerges`, which re-runs those
same guards for its own delta.

### The change

| file | what |
|---|---|
| `ir-pass/include/TaintPropagation.h` | NEW decl `adjudicateTaintDelta(M, wd, taint, plan6, delta)`; `propagateFromSeeds` gains an optional `Delta` out-param |
| `ir-pass/src/TaintPropagation.cpp:1573` | NEW `adjudicateTaintDelta` — the four-call sequence LIFTED VERBATIM out of `repropagateControlMerges` (`replanReseedSpecialization` → `detectSpecializations(&reseed)` → `declineTaintEscapes` → `declineStaleRecordOps`), so there is exactly ONE spelling of it (Rule 14) |
| `ir-pass/src/TaintPropagation.cpp` (in `repropagateControlMerges`) | its own four calls REPLACED by `adjudicateTaintDelta(M, wd, taint, plan6, reseed)` — behaviour byte-unchanged (same functions, same order, same args) |
| `ir-pass/src/TaintPropagation.cpp` (`propagateFromSeeds`) | fills `Delta` = `Seeds ∪ (Tainted − beforeTaint)`; the snapshot is taken **only** when `Delta != nullptr && !Seeds.empty()`, so a module that peels nothing pays nothing |
| `ir-pass/include/MergePhiPeel.h`, `ir-pass/src/MergePhiPeel.cpp` | `peelIndependentMergePhis(M, taint, Delta)` (NO default — see below); the header now states the CALLER'S OBLIGATION. The stage stays **ACCEPT-ONLY and still never diagnoses** — what it hands back is a delta; the loud owners are the pre-existing guards |
| `ir-pass/src/CQLoweringPass.cpp:441-444` and `:919-922` | both round-1 call sites: `SmallPtrSet<Value*,32> PeelDelta; peelIndependentMergePhis(M, taint, &PeelDelta); adjudicateTaintDelta(M, wd, taint, plan6, PeelDelta);` — twin-pipeline parity |

**`Delta` has NO DEFAULT ARGUMENT, deliberately.** SCOPE §8's instruction was to
*"prefer whichever spelling makes the peel impossible to skip"*, citing the
`markBranchPhaseGate` / `markRailCondRead` lesson — a call a later author can forget
re-opens the window with no diagnostic anywhere. That now applies to the peel's own
obligation too, so the compiler forces every caller to state its disposition: adjudicate,
or pass `/*Delta=*/nullptr` with the written argument for why its caller already does.

**The ROUND-2 call site is the one `nullptr`, by inclusion rather than by omission, and it
is MEASURED not assumed.** `peelIndependentMergePhis` inside `detectAndLowerOnwardControl`
(`TaintPropagation.cpp:1421`) is reached only from `repropagateControlMerges`
(`grep -rn 'detectAndLowerOnwardControl' ir-pass/src ir-pass/include` → **one** call
site, `:1663`), below its `UntaintedMergeRails.empty()` early return; that function
snapshots `beforeTaint` at ENTRY, so the round-2 peel's whole growth lands in
`reseed = UntaintedMergeRails ∪ (Tainted − beforeTaint)` and is adjudicated by the very
`adjudicateTaintDelta` call this fix factored out. Written at the call site.

### Position: candidate (b) chosen — KEEP THE SLOT, RE-ASK THE GUARDS

The brief asked for both candidates to be measured against the stage table and for the
argument to be written down. **(a) — move the peel above `detectSpecializations` — is
refused, and not for want of trying: the peel NEEDS nothing from the stages in between
(it builds its own `DominatorTree`, and P9 is the reducibility-independent
`regionEntryInLoop` walk, not `LoopInfo`). It is refused because of what it would
BREAK.** Per-stage, asked in writing (the NOTES §2 table method):

| stage between `:250` (PredMux fixpoint) and `:416` | may the peel run ABOVE it? | why — MEASURED, not argued |
|---|---|---|
| `unrollConstTripLoops` (`:273`) | **NO** | it re-runs `flattenPredMuxRegions` internally (`while (unrollConstTripLoops) { propagate; while (flattenPredMuxRegions) … }`), so a peel above it is a peel above PredMux |
| `recognizeCtlzIdiomLoops` (`:302`) | **NO** | same shape, same nested PredMux fixpoint |
| …and the reason that matters for both | | PredMux's own W-witness is **literally `NumMergePhis >= 2`** (`PredMuxFlatten.cpp:2646`: `Claim = NestedTainted \|\| ClaimableRead \|\| NumMergePhis >= 2 \|\| (NumMergePhis == 1 && SolePhiIncomings > 2) \|\| FpSolePhiMux \|\| IntConstFallthroughMux \|\| StrandedCondPhi`). Peeling first turns a 2-φ merge into a 1-φ one and therefore **moves a PredMux verdict** — in either direction, since W5/W7 then apply where the ≥2 witness did. That is exactly the hazard the shipped slot comment already names |
| `detectSpecializations` (`:321`) | yes — this is the point of (a) | |
| `declineTaintEscapes` (`:330`) | yes | |
| `declineStaleRecordOps` (`:337`) | yes | |
| `lowerControlledIOSinks` (`:349`) | **NO** | its merge gate is `MergeOk = C.Merge->hasNPredecessors(2) && (NumPhis == 0 \|\| ValuePhi)` (`IOSinkLowering.cpp:609`), and `ValuePhi` is only ever set when `NumPhis == 1` (`:594`). A 2-φ merge with an I/O-sink arm is therefore REFUSED today; peel one φ above this stage and it becomes claimable — a **brand-new 7.6 accept nothing has measured**. It also retires the peel's own containment argument, which cites this stage's verdict as *already final* |
| `lowerLoops` (`:365`) | **NO** | the peel's P9 refuses in-loop sites precisely so as not to widen two axes at once in the neighbourhood CLAUDE.md records as *eight findings over six adversarial rounds on one function*. Moving the peel above `lowerLoops` puts new tainted `select`s and cloned compares in front of `staleRailRecordRead`/`tryCaseA` — unmeasured, and the opposite of P9's stated posture |

**So (a) would trade one once-only premise for three new cross-subsystem interactions,
two of which measurably move an accept class.** (b) removes the premise where it lives:
after the peel, the guards are re-asked over exactly the values the peel created, using
the functions that own those questions. Cost: one pure-analysis re-scan, and **zero**
when nothing was peeled (`delta.empty()` ⇒ immediate return, which is what keeps the
1776-fixture corpus byte-identical).

### Why all FOUR calls, and not just the escape net

Building the fix found a **sixth** reproducer class, not among the reviewer's five, and
it is the one the escape net alone cannot reach.

`k01_clone_stalemask.c` (plain C, `-O1`): `helper(a, m)` where `a` is tainted at ROUND 1.
The site is therefore **already** a proven Phase-6 candidate in `plan6.Pending` with the
frozen mask `{Q,C}` — and a site in `Pending` is **CARVED** by `declineTaintEscapes`
(`shouldSpecialize`). Re-running the escape net changes nothing; the driver clones a body
that reads the 4.4 merge OUT-RAIL as an `_hl` **classical literal**. MEASURED under
mutant **M-A** (delete `replanReseedSpecialization` from `adjudicateTaintDelta`, rebuild):

```
cq_template_add_i32_hl(h1, 4)      <- the rail's runtime HANDLE TAG, opt exit 0   [M-A]
cq_template_add_i32(h4, h1)        <- the correct bare Q+Q twin                   [fixed]
```

That is the bd `afmv` verify-clean wrong unitary. Pinned by
`control_peel_clone_stale_mask.ll` (whose `NOHL` prefix is the single line that flips).

The four calls are pinned by **three different** probes, measured one mutation at a time:

| mutant | what breaks | pinned by |
|---|---|---|
| **M-A** drop `replanReseedSpecialization` | `k01` emits `add_i32_hl(h1, 4)` at exit 0 | `control_peel_clone_stale_mask.ll` |
| **M-B** drop `detectSpecializations(&delta)` | `r20` OVER-declines `tainted value consumed by an unknown callee` (its hand peel ACCEPTS on the oracle) | `control_peel_clone_measured.ll` |
| **M-C** drop `declineTaintEscapes` | `r04`, `r11`, `r02`, `r07` all return to **exit 0** with the handle-tag escape | the four `..._reject_escape_*` fixtures |
| **M-D** drop `declineStaleRecordOps` | **no measured customer** — see the open question below | — |

### Verdicts, all six reproducers (`./ab.sh`, ORACLE vs SUBJECT)

| probe | consumer | ORACLE | before the fix | AFTER |
|---|---|---|---|---|
| `r04_escape_store` | `g_probe = m` | `control flow` | exit 0, prints `4` | **`cq taint escape: tainted value stored to memory`** |
| `r11_escape_ptrstore` | `arr[1] = m` | `control flow` | exit 0, prints `4` | **same string** |
| `r02_escape_sink` | `cq_sink_probe(m)` | `control flow` | exit 0, rail to an unknown callee | **`cq taint escape: tainted value consumed by an unknown callee`** |
| `r07_escape_clone2` | `g_probe = helper(m)` | `control flow` | exit 0, prints `g=5` | **`cq taint escape: tainted value stored to memory`** |
| `r20_clone_measured` | `cq_measure(helper(m))` | `control flow` | exit 0, **measured an unrelated rail** (21 lines) | **exit 0, CORRECT (26 lines)** — see below |
| `k01_clone_stalemask` (NEW) | `cq_measure(helper(a, m))` | `control flow` | (M-A) `add_i32_hl(h1, 4)` | **exit 0, CORRECT Q+Q** |

Each of the four escape strings is **character-for-character the string the ORACLE gives
that program's HAND-PEELED twin** (`r05`, `r03`, `r08`), which is the brief's criterion.

**`r20` is an ACCEPT, deliberately, and it is the increment's own contract being met.**
The brief anticipated *"`r20` → the specialisation/escape string of `r23`'s oracle run"* —
but `r23` (the hand-peeled twin of exactly this module) **lowers correctly on the ORACLE
at exit 0**, so no such string exists, and a decline here would be an over-decline that
breaks the contract *"produce the module the hand peel already is"*. MEASURED after the
fix, and it is the strongest witness in this record:

```
diff r23_clone_handpeel.o.ll  r20_clone_measured.s.ll     -> IR BYTE-IDENTICAL
diff r23_clone_handpeel.o.trace r20_clone_measured.s.trace -> TRACES BYTE-IDENTICAL
```

i.e. the SUBJECT's lowering of the fused program is byte-identical to the ORACLE's
lowering of its hand-peeled twin. **This is the only ACCEPT the F-B6-1 fix adds**; every
other mover is a decline (accept-monotonicity is preserved in the direction that matters
— the five miscompiling exit-0 programs all stop lowering or start lowering correctly).

---

## F-B6-2 — the guarded-store leak — FENCED (decline-keeping)

### What was wrong

The peel's `>= 2`-φ containment gate argues that every site it touches *declines loudly
today*, and one of its bullets is *"`classifyGuardedStoreArm` LOUD-declines on any merge
φ at all"*. True — and **insufficient**, because that decline keys on the very φ the peel
DELETES. Peel both and the 7.5 guarded Shadow store region flips DECLINE → ACCEPT, with
the **entire reversal spine gone**: no `cqrt_qram_load_i32_unc`, no
`cqrt_qram_store_i32_controlled_unc`, no strip or free of the path-predicate flag, no
`cqrt_ry` inverse (probe `g01`: exit 0, 35 trace lines, 2b `10 rail mint(s), 10 left
allocated, 0 violation(s)` — a leak is Rule-6's safe direction and 2b is blind to it).

**The transferable lesson, written into the containment gate:** containment needs the site
to keep declining **AFTER** the peel, not merely to decline before it.

### The change

`ir-pass/src/MergePhiPeel.cpp` — new clause **P10**, `armWritesMemory(ArmBB)`, asked of
both merge predecessors that are not `Pred` itself (a diamond has one arm; an if/else has
two). A site whose arm contains a `StoreInst` / `AtomicRMWInst` / `AtomicCmpXchgInst` is
**not peeled**, so `g01` keeps `cq controlled lowering: guarded store with a merge value`.

**Spelling, and why not the narrow one.** The brief offered `classifyGuardedStoreArm`'s
own recogniser (`guardedShadowStoreShape`, `QramLowering.h`). Refused, on two counts: it
needs a `LoopInfo` and a QRAM dependency inside an accept-only normaliser that today
knows nothing about memory; and it is **narrower than the hazard** — it would fence the
one member that was probed and still peel a merge whose arm holds some other write. The
property that made `g01` dangerous is *the arm writes memory*; that is the clause.

**NOT `mayHaveSideEffects()` / `mayWriteToMemory()`**: a `@cq_theta` CALL answers `true`
to both (opaque declaration), and an arm `cq_theta` is the peel's commonest member — that
spelling would silently delete the whole capability. Measured by construction and stated
in the source comment.

### Measurements

| probe | ORACLE | before P10 | AFTER |
|---|---|---|---|
| `g01_guarded_store_2phi` | `guarded store with a merge value` | **exit 0**, 35 lines, reversal absent | **`guarded store with a merge value`** (same string) |
| `g02_guarded_ctrl` (control) | exit 0, 26 lines, full reversal | exit 0, 26 lines | **exit 0, traces BYTE-IDENTICAL to the oracle's** |

`g02` is also committed as a lit fixture whose `cq-opt` output is byte-identical on both
binaries, so **P10 is a discriminator, not a blanket refusal** of the guarded-store shape.

---

## DOC items

**D1's reason — CORRECTED, not merely reworded.** The review MEASURED `d01_tail_onephi`
(one φ, the shipped `phaseAngleTail` path) against `d02_tail_twophi` (the same angle φ
plus a data mux, so the peel fires): **same unitary** (relative phase `c=1 → 2.2`,
`c=0 → 0.1` in both) and **no `cqrt_alloc_f64` anywhere in either** — a peeled angle
select goes to `classifyAngleSelect`, which is an ANGLE consumer. So peeling an angle-tail
φ is **not** the f64/angle wire-crossing; the sound reason for the `>=2` gate is that on a
ONE-φ merge the stage cannot tell the region's own φ from an independent mux. Applied in
three places: `ir-pass/src/MergePhiPeel.cpp` (the `NumPhis < 2` gate comment),
`ir-pass/test/control_peel_angle_tail_unchanged_control.ll` (header), and
`IMPL_b6ap.md` §2 D1 + §7 Q1 (a dated ⚠ correction block, the earlier claim withdrawn in
place rather than deleted).

**P3b + `freeze`.** One line added to the predicate's comment: a `freeze` IS peeled and
that is correct — it is an `Instruction`, not an `UndefValue`, and the argument is the
PROPERTY not the type test (`freeze` is **single-valued by definition**, exactly what
`LiteralIntegrity` guard 1 counts, so it cannot exhibit the two-slots-two-values hazard).
Two fixtures, one token apart: `control_peel_freeze_incoming.ll` (ACCEPT, with an exact
`FRZCNT-COUNT-1` so the literal provably reaches ONE gate slot) and
`control_peel_reject_poison_incoming.ll` (DECLINE `control flow`). Also noted on IMPL's
P3b row.

**Matrix rows — the reviewer's ruling KEPT (`UNROLLED-ONLY`, all five), caveat added.**
`tools/loop_twin_matrix.expected.txt`'s header block now carries §6's caveat in full: the
peel is a **second, non-obvious customer-generator for the angle-select path**, whose
accept class is narrower than the data path's (CONSTANT arms for the Ry stem, one
consumer, the `2^-40` rounding fence); every boundary the reviewer probed declines loudly
through the peel (`f02`, `f03`, `f05`, `f07`), so the generator is fenced today — but a
future widening of `classifyAngleSelect` now has a customer source that appears in none of
its own files, fixtures or `-O1` C twins. The five rows are named as that widening's
tripwire: **re-derive, never regenerate.**

---

## Fixtures added — 10 (corpus 1801 → **1811**)

| fixture | kind | pins |
|---|---|---|
| `control_peel_reject_escape_store.ll` | DECLINE `tainted value stored to memory` | F-B6-1, global store (`r04`) |
| `control_peel_reject_escape_ptrstore.ll` | DECLINE, same string | F-B6-1, array gep store (`r11`) |
| `control_peel_reject_escape_unknown_callee.ll` | DECLINE `tainted value consumed by an unknown callee` | F-B6-1, declaration-only consumer (`r02`) — a DIFFERENT clause of the re-asked guard |
| `control_peel_reject_escape_clone_store.ll` | DECLINE `tainted value stored to memory` | F-B6-1, the two re-asked stages COMPOSING (`r07`): 9paa detection accepts, the escape net declines the stored result |
| `control_peel_clone_measured.ll` | **ACCEPT** + `SPEC` prefix | F-B6-1, the `detectSpecializations(&delta)` call (mutant M-B); byte-identity with the hand-peeled twin |
| `control_peel_clone_stale_mask.ll` | **ACCEPT** + `SPEC` + `NOHL` | F-B6-1, the `replanReseedSpecialization` call (mutant M-A) — the afmv stale-mask class |
| `control_peel_reject_guarded_store.ll` | DECLINE `guarded store with a merge value` | F-B6-2 / P10 |
| `control_peel_guarded_store_ctrl_unchanged.ll` | **ACCEPT CONTROL**, byte-identical both binaries | F-B6-2, P10 is a discriminator not a blanket refusal; asserts the full 7.5 reversal spine |
| `control_peel_freeze_incoming.ll` | **ACCEPT** + `FRZCNT` | P3b DOC — `freeze` peels, one literal, one gate slot |
| `control_peel_reject_poison_incoming.ll` | DECLINE `control flow` | P3b DOC — the poison half, one token from the accept |

8 of the 10 are RED on `main` `0c7380c` (`control flow under quantum control`). The two
guarded-store fixtures are green on the oracle **by design** — one asserts a decline string
that must NOT move, the other asserts byte-identity — and each says so in its header.
Every decline fixture carries the standard note that its IR-text negatives would be
vacuous (a `DS_Error` writes 0 bytes to stdout) and that the `not` inversion plus the
mirrored string is what pins it.

---

## Gates

Run in the brief's order, on the SUBJECT build (both targets rebuilt after every source
edit — `cmake --build build -j8`, never `--target CQPass` alone). ⚠ **Two other agents were
running `ctest -j6 -R '^e2e-'` concurrently in `CQ_trackA` and `CQ_l4x4` for the whole of the
e2e gate** (measured with `ps` — three e2e suites at `-j6` on a 6-core box), so every wall
time below is a LOADED figure and is not comparable to the quiet-box band. Nothing was
relinked under a running measurement and nothing was killed by pattern.

```
# 1. targeted lit
lit ir-pass/test --filter 'control_peel'      -> 35/35 PASS, 4.90 s

# 2. ir-pass-lit (twice: after the F-B6-1/F-B6-2 fixes, and again on the final binary
#    after the no-default-argument change)
ctest --test-dir build -R ir-pass-lit         -> Passed, 90.25 s  (first)
ctest --test-dir build -R ir-pass-lit         -> Passed, 102.27 s (final binary)
lit -s ir-pass/test                           -> 1811 Discovered · 1810 Passed
                                                 · 1 Expectedly Failed · 0 unexpected
ls ir-pass/test/*.ll | wc -l                  -> 1811   (1776 main + 25 hand-back + 10 new)
git status --porcelain ir-pass/test | grep '^ M'  -> (empty: NO pre-existing fixture modified)

# 3. e2e
ctest --test-dir build -j6 -R '^e2e-'         -> 100% tests passed, 0 failed out of 379
                                                 Total Test time (real) = 1057.03 s
                                                 (e2e-loop-twin-matrix alone: 1056.99 s)
git status --porcelain tests/ | grep -v '^??' -> ' M tests/e2e/CMakeLists.txt'
                                                 (the hand-back slice registration only —
                                                  ZERO goldens modified)

# 4. FULL SUITE, once, at the end (the Rule-19 gate moment: a Rule-13 lowering-core
#    change AND a moved accept/decline predicate)
ctest --test-dir build -j6 --output-on-failure
     -> 100% tests passed, 0 tests failed out of 389
        Total Test time (real) = 1317.79 s      (LOADED — see the note above)

# 5. after the final (COMMENT-ONLY) source edits, both targets rebuilt and the lit
#    layer re-run, so the shipped source and the gated binary are the same tree
cmake --build build -j8                       -> 0 errors
ctest --test-dir build -R ir-pass-lit         -> Passed, 135.63 s

# 6. equivalence: strings MOVED (five programs gained new loud declines), so the
#    full sweep, not the stride-8 ctest sample
cmake --build build --target cq-opt-equivalence-full
     -> cq_opt_equivalence: compared 1811 fixtures, 0 mismatch(es)
```

**Corpus diff, ORACLE vs SUBJECT, over the 1776 pre-existing fixtures** (the 35
`control_peel_*.ll` are the increment and are excluded), comparing exit code, stderr AND
lowered text on every one:

```
=== 1776 fixtures compared: 0 RCDIFF, 0 DIAGDIFF, 0 OUTDIFF ===
```

and that is **true by construction, not by luck**: `adjudicateTaintDelta` opens with
`if (delta.empty()) return;`, and `propagateFromSeeds` returns before touching anything
when `Seeds` is empty — so a module the peel does not fire on never enters any of the four
re-asked stages and cannot take a different path. The 0/0/0 is the measurement that the
containment argument holds.

**Accept-monotonicity of the F-B6-1 fix**, stated precisely because the brief asked for it:
the fix adds exactly **two** accepts, `r20` and `k01`, and each is byte-identical to its
own hand-peeled twin — i.e. the fix does not widen the accept class, it makes two programs
that were already being *lowered* (wrongly, at exit 0) lower *correctly*. Every other
mover is exit 0 → loud decline. **Five programs that produced a wrong unitary at `opt` exit
0 now produce none.**

### Probe verdicts, re-run on the FINAL binary (`./ab.sh`, ORACLE vs SUBJECT)

The five reproducers, `k01`, and the two guarded-store probes are tabled above. The
reviewer's boundary family was re-run in full; **every verdict matches `review_b6ap_r1.md`
except two, and both moves are the fix working**:

| probe | reviewer recorded | now | why |
|---|---|---|---|
| `f02_angle_and_data` | DECLINE `rotation angle` | DECLINE `cq taint escape: tainted value stored to memory` | still loud, still the same disposition — the re-asked escape net now owns it, and it runs EARLIER than the angle fence. The wire is not crossed either way |
| `x03_freeze_incoming` | ACCEPT (peeled, sound) | DECLINE `…stored to memory` | the reviewer built `x03` on `r04`'s module, whose mux consumer is a STORE — i.e. an F-B6-1 reproducer wearing a `freeze`. The `freeze` property it was written to demonstrate is now pinned by `control_peel_freeze_incoming.ll`, whose consumer is a `cq_measure` |

⚠ **Worth carrying: the F-B6-1 fix can move a decline STRING within the decline class.**
It never turns a decline into an accept (the only new accepts are `r20`/`k01`, both
byte-identical to their hand-peeled twins), but it inserts three guards ahead of the
region path, so a program that used to reach the angle/select fences may now be owned by
the escape net. `f02` is the measured instance. IMPL §3's "4 DECLINES whose STRING MOVES"
table is about a different hop (peel fires → deeper fence) and is unaffected — all four
still hold, `ir-pass-lit` green.

⚠ **The angle boundary was the thing most at risk from this fix, and it held — MEASURED,
not assumed.** A peeled ANGLE select is tainted (it is a user of the tainted condition;
that was already true at hand-back), and the fix puts `declineTaintEscapes` in front of it
for the first time. If that guard did not tolerate a tainted value in a rotation-angle
slot, every peeled-angle accept would have broken — `f01`, `f04`, `f06`, the fixture
`control_peel_angle_tail_datamux.ll`, and the five `loop_twin_matrix` cells. Re-measured on
the final binary, the emitted streams are exactly the ones the reviewer recorded:

```
f01 (Rz stem, kickback pair):  x(h3); rz_i1(h3,0.1); x(h3); rz_i1(h3,0.7)
f04 (Ry stem, by difference):  ry_i32(h2,0.1); ry_i32_controlled(h4,h2,0.6)
grep -l cqrt_alloc_f64 f0*.s.ll  ->  (none)
```

Unchanged and re-confirmed: `f01`, `f03`, `f04`, `f05`, `f06`, `f07`, `d01`, `d02`, `s01`,
`n01`, `u01`–`u06`, `x01`, `x02`, `w03`, `m01`, and all four hand-peeled twins (`r03`,
`r05`, `r08`, `r23`). `r16`/`r17` — the `-O1`-built-select controls that prove the hole was
the PEEL's, not `-O1`'s — still decline identically on both binaries. `r09`/`r10` keep
declining loudly on deeper strings (`tainted value returned at non-i32 width`, `cq I/O
output sink: tainted argument is not a lowerable integer scalar`).

---

## What a round-2 reviewer should attack first

1. **`detectSpecializations` at its third program point** (open question 3 below) — the
   only genuinely new interaction this fix creates.
2. **The decline-string moves** — `f02` showed the escape net can now take ownership of a
   program the angle/select fences used to own. Are there shapes where the EARLIER owner
   gives a *worse* (less specific, or wrongly-located) message?
3. **P10's breadth** — it is deliberately wider than the probed member. Is there a peelable
   shape with a benign `StoreInst` in an arm that this now over-declines? (I could find
   none; every value-arm classifier requires a pure chain.)

---

## Open questions for round 2

1. **`declineStaleRecordOps` over the peel delta has no measured customer (mutant M-D).**
   It is in `adjudicateTaintDelta` because that function IS the round-2 sequence and
   splitting it would be a second spelling (Rule 14); dropping it could only ever remove
   declines. I could not construct a reachable member and I say why rather than fabricate
   a fixture: the guard asks *"is a tainted pure op scheduled past a non-diagonal wire
   gate?"*, and an op tainted **only** through the peeled select reads the fresh 4.4 merge
   out-rail, which no in-place gate relabels; an op that also reads a rotated register's
   record is tainted at `:337` already. Round 2 should either find a member or record the
   clause as structurally unreachable.
2. **Should the 7.5 reversal run for a merge-valued guarded store?** P10 keeps the
   existing decline and does not answer this. If the answer is yes, it is
   `classifyGuardedStoreArm`'s row and its own round — not a relaxation of P10.
3. **`detectSpecializations` now runs at a THIRD program point** (`:416` / `:917`, between
   `lowerLoops` and `detectControlRegions`). bd 9paa's own comment gives *"the CFG is fully
   settled"* as a reason for its round-2 slot; at the round-1 peel site the CFG is **not**
   settled (regions are unlowered), the same as the original `:321` call. I argued the 9paa
   hazard (a pre-lowering merge φ entering `Pending`) is out of reach — the peel's delta
   cannot contain the region's own merge φ, since the select is inserted *after* the φ in
   the merge block and so can never be one of its incomings — but that is an argument, not
   a probe family. Worth one round.
4. **The reviewer's §7 items 2 and 6 are untouched by this fix** and carry forward: the
   classify-vs-emit taint window on a select ARM (one probe with a genuinely opaque 6.5
   callee), and the `Instruction::clone` metadata question (the clone copies `nsw`/`nuw`/
   `exact`/fast-math and the `!dbg` — none of it checked against what a source-written
   compare at that position would carry).
5. **"Assume a fifth thing" applied to THIS fix.** The question that found F-B6-1 was
   *the taint edge is right; what did the new taint REACH?* Its successor for round 2 is:
   **the peel now causes stages to run that otherwise would not** (a Phase-6 clone is
   minted at `:416` that no `:321` run planned). What does `specialize` at `:595` assume
   about when its plan was built?
