# FIX record — bd `test_C_libtooling-b6ap` (the multi-phi merge peel), round-2 items

Answers `review_b6ap_r2.md` (verdict **CLEAR-WITH-ITEMS**) per `FIX_BRIEF_b6ap_R2.md`.
Worktree `/Users/sorenwilkening/Desktop/CQ_b6ap`, branch `merge-phi-peel`, its own
`build/` (both targets rebuilt after every source edit — never `--target CQPass`
alone). ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}`
(`main` `0c7380c`, read-only — never rebuilt, never written to). **Nothing committed,
nothing pushed.** Probes are the reviewer's own, in `review_b6ap_r2_probes/`.

| item | grade | disposition |
|---|---|---|
| **F-B6R2-1** the FIFTH taint-delta consumer | OVER-DECLINE (hand IR) | **FIXED** — `foldIdentityBitcasts` is now call 1 of `adjudicateTaintDelta`; 2 fixtures |
| **M-D** `declineStaleRecordOps` has a customer | resolved | **PINNED** — 1 decline fixture; the mutant now moves exactly it |
| **F-B6R2-2** the peel widens bd `3d8q`'s population | ARGUED | **DOC** — IMPL §7 Q11 + 3 probes + README; no code |
| **P10 / D-3** the narrow `StoreInst` spelling | DOC | **DOC** — retirement trigger written at the clause |
| **D-1** what `delta` is actually used for | DOC | **DOC** — `TaintPropagation.h` |
| **D-2** `skipRuntimeCalls=true` at the round-1 sites | DOC | **DOC** — `TaintPropagation.h` |
| the round-3 question (the DELETED φ) | — | **ASKED AND MEASURED** — IMPL §2d, 194 erasures audited; 0 dangling; 2 retirement triggers |

---

## F-B6R2-1 — `foldIdentityBitcasts` is a FIFTH taint-delta consumer — FIXED

### What was wrong

`foldIdentityBitcasts` (`CQLoweringPass.cpp:167` / `:795`) folds a same-width
int↔int `bitcast` to its operand **only when the bitcast is already in
`taint.Tainted`**, and it is the **sole handler for that opcode** — its own header
says the fold-eligibility test mirrors `castInScope`'s accept, so a tainted bitcast
it does not fold has no template. The peel taints such a bitcast ~280 lines later.

Reproduced before touching anything (probe `BC1_identity_bitcast`, hand IR: a 3-φ
merge, two peelable, `%bc = bitcast i32 %mux to i32`):

| module | ORACLE `0c7380c` | SUBJECT b7d646c |
|---|---|---|
| FUSED (φ) | `control flow under quantum control` | **`no template for opcode 'bitcast i32' in tainted context`** |
| HAND-PEELED twin | **exit 0** | **exit 0** |

So the pre-fix binary lowered the hand peel of this module and declined the module
the peel is supposed to make identical to it — the increment's stated contract
("produce the module the hand peel already is"), falsified in the SAFE direction.

⚠ "SUBJECT b7d646c" in that table is a MEASUREMENT, not an inference: the binary in
`CQ_b6ap/build/ir-pass/` at the start of this session was built at 17:34 from the
checkpoint tree with `git status --porcelain` clean apart from the round-2 review's
own untracked files, so the first `./ab.sh BC1_identity_bitcast` of the session IS
the b7d646c column. (`ab.sh`/`twin.sh` rewrite a probe's `.s.*` outputs, so the six
`*.s.err` files re-run since carry THIS binary's stderr, not the reviewer's; the
other 49 still hold the reviewer's and are byte-identical to this binary's — §Probe
corpora.)

### The change

| file | what |
|---|---|
| `ir-pass/src/TaintPropagation.cpp` (`adjudicateTaintDelta`) | `foldIdentityBitcasts(M, taint, &live)` added as **call 1**, ahead of the four; the delta is copied into a local `live` set first (below) |
| `ir-pass/src/TaintPropagation.cpp` (`foldIdentityBitcasts`) | new `SmallPtrSetImpl<Value *> *Scrub` parameter; a folded (freed) bitcast is erased from it beside `taint.Tainted` / `taint.HandleWidth` |
| `ir-pass/include/TaintPropagation.h` | the declaration + the finding + why `Scrub` has **no default argument** (the `MergePhiPeel.h` `Delta` precedent — every caller states its disposition) |
| `ir-pass/src/CQLoweringPass.cpp:167`, `:795` | both entry points pass `/*Scrub=*/nullptr` with the written reason (this slot holds no delta) |

**WHY FIRST, and not appended after the four.** It is the same reason the stage is
wired first in both entry points: a standing identity node blinds the bespoke
provenance/lineage walks the four run — and one of those walks (the stale-record
chained-theta hop) is literally call 5. Folding after them would leave each looking
at an opaque node it must special-case, which is the whole defect `bd iw81.1`
existed to remove.

**WHY IT IS FREE — monotone and idempotent, stated in the header.** The fold only
RAUWs `result === operand` and erases a no-op: it adds no taint, emits no gate, and
can move no accept/decline by itself. Over a LARGER `Tainted` it folds a SUPERSET of
what the `:167` run folded, and a second run over an unchanged delta finds nothing
left to fold. `adjudicateTaintDelta`'s `if (delta.empty()) return;` still contains it
entirely, which is what keeps the 1776-fixture corpus byte-identical.

**⚠ THE ONE REAL HAZARD IN THIS FIX, AND IT IS THE ROUND-3 QUESTION'S OWN CLASS.**
The fold ERASES instructions, and `delta` is a `Value *` set that
`replanReseedSpecialization` and `detectSpecializations` read as a direct-argument
membership test. A folded bitcast that is itself in the delta — which is exactly the
`BC1` shape, since `%bc` is tainted only BY the peel — would leave a **freed pointer
as a live key**: the bd `drbq` Inc-1 defect verbatim. So the fold is handed a LOCAL
COPY to scrub, and the copy is what the two spec calls consume. No coverage is lost:
a tainted bitcast's OPERAND is tainted too (the walk reaches the operand first) and
the RAUW makes every consumer read that operand, which stays in the delta.

### Measurements

```
./ab.sh   BC1_identity_bitcast   ->  ORACLE exit 1 `control flow` | SUBJECT exit 0, 32 trace lines
                                     stage 2b: 8 rail mints, 8 left allocated, 3 frees: 3 verified,
                                     0 violation(s), 0 unproven
./twin.sh BC1_identity_bitcast   ->  SUBJECT(fused) vs ORACLE(hand-peeled twin):
                                     TRACE BYTE-IDENTICAL (32 lines)
```

The emitted witness is `call void @cqrt_addc_i32(i32 %out, i32 3)` — the `add` reads
the 4.4 merge OUT-RAIL directly, which is what "the identity is folded" means.

**Fixtures — 2** (`ir-pass/test/`):

| fixture | kind | pins |
|---|---|---|
| `control_peel_identity_bitcast.ll` | **ACCEPT** + `XCNT`/`FCNT`/`ACNT`/`UCNT`/`CPCNT`/`RYCNT`/`NOBC`/`NOROUTE` | the fifth call (mutant M-E). RED on `main` 0c7380c (`control flow`) and on b7d646c (`no template for opcode 'bitcast i32'`) |
| `control_peel_reject_vector_bitcast.ll` | DECLINE `no template for opcode 'bitcast <2 x i16>' in tainted context` | the BOUNDARY, one token from the accept: the fifth call REUSES the unchanged eligibility test (both sides scalar int, equal width). A mutant relaxing the fold to "any tainted bitcast" takes this module from a loud decline to a silent rewrite |

⚠ The accept's `NOBC` block is `-NOT: = bitcast` / `-NOT: cq_template_bitcast`, **not**
`-NOT: bitcast`: `%s` is the fixture's own path, so the `source_filename` line
contains the word and the blunt negative would be vacuously RED. Measured, not
guessed — it was red on the first run. An **fp↔int** bitcast is deliberately NOT the
boundary partner: it is not folded either, but it has a `cq_template_bitcast_i32_to_f32`
row and LOWERS, so it would pin nothing (measured: exit 0 on the subject).

---

## M-D — `declineStaleRecordOps` over the delta HAS a customer — PINNED

The round-1 fix recorded (open question 1) that mutant M-D moved nothing, and gave a
structural argument for why the clause might be unreachable. **The argument was
wrong**; the reviewer built the customer from plain C (`S02_stale_mux_record.c`).
The staleness is CREATED by the peel: at `declineStaleRecordOps`' slot `%m` is a
CLASSICAL `phi`, so `s = m + 1` is a classical `add` that is not even in
`inLowerOpsScope`; the peel makes `%m` a tainted `select`, which flips
`cq_theta(m, .2)` from a SOURCE mint to a CHAINED in-place Ry on the mux rail, and
the `add` becomes a read of that rail's pre-rotation record.

```
./ab.sh S02_stale_mux_record -> ORACLE  exit 1  `control flow under quantum control`
                                SUBJECT exit 1  `cq opcode lowering: operand predates a non-diagonal gate`
```

**Fixture — 1:** `control_peel_reject_stale_mux_record.ll` (the `-O1` module
transcribed verbatim). Its header states that it is the ONLY customer of call 5 and
carries the mutant.

**Mutant M-D, re-measured on this tree** (delete `declineStaleRecordOps` from
`adjudicateTaintDelta`, rebuild BOTH targets, full lit, restore, rebuild):

```
lit ir-pass/test  ->  Passed: 1812  Expectedly Failed: 1  Failed: 1
Failed Tests (1):  CQ IR-pass :: control_peel_reject_stale_mux_record.ll
cq-opt on that fixture under the mutant -> exit 0  (a SILENT accept; only the
    pre-existing `non-diagonal gate over a live derived record` WARNING prints)
grep -c MUTANT ir-pass/src/TaintPropagation.cpp  ->  0   (after restore)
```

**Mutant M-E** (delete the new fifth call) was measured the same way:

```
lit ir-pass/test  ->  Passed: 1812  Expectedly Failed: 1  Failed: 1
Failed Tests (1):  CQ IR-pass :: control_peel_identity_bitcast.ll
```

Each mutant reddens **exactly one** fixture and nothing else. All five calls of
`adjudicateTaintDelta` now have a pinning fixture (IMPL §2e).

---

## F-B6R2-2 — the peel widens bd `3d8q`'s population — DOC, no code

`S03` (two SIBLING chained thetas on ONE peeled mux rail, both measured) accepts at
exit 0, 2b clean, emitting `ry(h8,.2); ry(h8,.6); measure(h8); measure(h8)` — `r1`
measured as `Ry(.6)Ry(.2)|m⟩` where the source names `Ry(.2)|m⟩`. **It is not the
peel's**, measured: `S04` is the same defect with NO PEEL anywhere and reproduces on
the ORACLE (exit 0, 8 lines, one register). That is CLAUDE.md's open P1 bd
`test_C_libtooling-3d8q` — the pass-wide stale-record guard sweeps PURE ops only, so
a `cq_theta` / `cq_measure` READER of a stale name is never asked.

What IS this increment's is the POPULATION: a 4.4 merge OUT-RAIL is now a shared
parent, so `3d8q`'s customer set grows with the peel, and its fix will have to cover
a rail nobody wrote in the source. Written up in **IMPL §7 Q11**; `S02`/`S03`/`S04`
copied into `probes/` with a README table pointing at `3d8q`. **No code.**

---

## P10 / D-3, D-1, D-2 — DOC

* **P10's retirement trigger** (`MergePhiPeel.cpp`, at the clause): the narrow
  `StoreInst`/atomic spelling is sufficient NOT because the set of write-shaped
  instructions is small — `memset`/`memcpy`/a writer call are all `CallInst`s and
  pass it — but because **the only owner in the tree that ACCEPTS an arm which
  writes is the 7.5 guarded store, and `guardedShadowStoreShape` takes a
  `StoreInst *`** (`QramLowering.h`). Every other write-arm shape has no classifier
  and dies at `control flow` whether peeled or not (measured, all four: `M02`–`M05`).
  **Trigger: the day any classifier accepts a `MemIntrinsic` or writer-call arm, P10
  must widen with it.**
* **D-1** (`TaintPropagation.h`, `adjudicateTaintDelta`): only calls 2 and 3 read
  `delta`, and only as a DIRECT-ARGUMENT membership test; calls 4 and 5 take no delta
  and re-scan the whole module. That is what makes completeness cheap — a consumer
  cannot be missed by being far from a seed, only by not being tainted — and a future
  delta-DRIVEN call would invalidate the argument and owe its own proof.
* **D-2** (`TaintPropagation.h`, `propagateFromSeeds`): `skipRuntimeCalls=true` is
  vacuous at the two round-1 peel sites today, and the argument is now written: the
  only stages above the peel that emit are `lowerControlledIOSinks` (which
  loud-declines every ≥2-φ merge with an I/O-sink arm, probe `I01`) and `lowerLoops`
  (three CONSTANT-argument `cqrt_alloc_*`). It stops being vacuous the day a stage
  that emits runtime calls over tainted operands is added above the peel.

---

## The round-3 question — the DELETED φ, asked with a probe family

The review's item 7 named the successor question and said outright that it had
checked it **by reading, not by running**. This round ran it. Method, full table and
every row's reason are **IMPL §2d**; the headline:

* a temporary audit build asked, AT THE ERASE LINE, whether the dying φ is a member
  of EVERY container in `ir-pass/include` that can hold a `Value *` /
  `Instruction *` / `PHINode *` (the headers grepped for `SmallPtrSet<`, `DenseMap<`,
  `DenseSet<`, `std::set<`, `WeakTrackingVH`, `SmallVector<…Value`), plus
  `Phi->user_empty()`;
* run over **all 1814 fixtures** (31 erasures in 16 files) and **all 501 probe
  modules** under `inc1-records/**` (163 erasures in 85 files — every committed
  probe corpus plus the round-2 reviewer's own);
* **194 erasures — the ONLY container ever hit is `Tainted` (6), which the peel
  erases on the line before the deletion; `user_empty()` held 194/194** (the RAUW
  runs first, so no LLVM `Use` dangles either);
* the instrumentation was removed and both targets rebuilt
  (`grep -c PEELAUDIT ir-pass/src/MergePhiPeel.cpp` → **0**).

**No dangling key.** Two rows are safe only by a DECISION that a follow-on wants to
change, and both now carry a retirement trigger **in the source**:

1. **`TaintSet::BreakRegions` holds RAW `llvm::PHINode *`** (`LoopBreakRegion::
   EscapePhi`, `::CounterPhi`), is written by `lowerLoops` BEFORE the peel and read by
   `lowerBreakReversePlay` AFTER it. What keeps it safe is **P9 + P1**, not a type:
   `CounterPhi` is the loop header φ (in-loop ⇒ P9) and `EscapePhi`'s merge
   predecessor is the in-loop exiting branch (in-loop ⇒ P9; its arm does not
   unconditionally reach the merge ⇒ P1). MEASURED: 17 fixtures and the 4
   `slice_loop_break*` e2e slices reach the peel with `BreakRegions` non-empty
   (`n=1`) and **not one peels a φ** — zero files in either corpus have both. Written
   at P9: **if P9 is ever narrowed to admit an in-loop site (IMPL §7 Q2), the peel
   must first scrub or re-derive these φ pointers.**
2. **`LiftedConsumers`** can hold a φ by type (it collects the lifted φ's USERS) and
   is empty at both peel sites only because `declineClassicalMuxes` runs AFTER them.
   Trigger written in the table: if that stage ever moves above the peel, the peel
   must scrub it.

⚠ **The INSERTION half is NOT covered by this audit** and is said so rather than
implied: the peel also inserts a compare clone and a `select`, and the review checked
`condDataUseDisposition` / `f2SeedPinnedByLiveRegister` / `reverifyRailCondReads` by
reading. This round adds no measurement there.

**The fix's OWN instance of the same class, found by asking the question of itself.**
Adding call 1 turns a sequence that was pure analysis into one that ERASES an
instruction at a NEW program point. The `delta` is precisely a `Value *` set that two
of the later calls read — so a folded bitcast that is in the delta (the `BC1` shape
exactly) would have left a FREED POINTER as a live key. That is why the fold takes a
`Scrub` set and why `adjudicateTaintDelta` hands it a local copy. The wider version
of the question — *what else could name the bitcast it deletes?* — is answered at the
call site from ONE property: **the fold only ever erases a TAINTED value**, and every
live structure is either scrubbed by the fold, or holds only emitter-created calls, or
holds only classical values, or is typed so a `BitCastInst` cannot enter it, or is
empty at that point. Written in the source beside the call.

---

## Probe corpora — all three, re-run on the final binary, every verdict compared

`review_b6ap_r2_probes/sweep.sh` (the reviewer's own runner) over all three
directories, ORACLE vs SUBJECT, **150 verdicts**:

| corpus | entries | vs the recorded run |
|---|---|---|
| `review_b6ap_r1_probes` | 38 | **BYTE-IDENTICAL to `sweep_r1probes.txt`** (the reviewer's recorded sweep), `diff` empty |
| `probes` (the implementer's) | 50 | **identical to `sweep_implprobes.txt` (47) plus exactly the 3 rows I added** — `S02`/`S03`/`S04`, copied in from the review corpus |
| `review_b6ap_r2_probes` | 62 | every row matches the review's §1/§2/§4/§5/§8 tables **except `BC1`**, which is the fix: `no template for opcode 'bitcast i32'` → **ACCEPT** |

Cross-checked a second way, against the artefacts rather than the prose: 49 of the
55 `*.s.err` files the reviewer left on disk are **byte-identical to this binary's
stderr**; the other 6 are the ones re-run since (BC1 + its twin, BC2, RL1, RL2, S02),
and each matches the review's own table. **No unexplained verdict move anywhere.**

⚠ **One correction to the review's write-up, not to its measurements.** Its §2a table
labels `K04` twice — once as "a `store` through a GEP whose index is the mux →
`stored to memory`" (that is `K05_gep_store`) and once as "a Phase-6 candidate
reached two hops → ACCEPT". `K04_two_hop_call` is neither: it declines
`cq I/O output sink: tainted argument is not a lowerable integer scalar`, which is
**what the reviewer's own committed `K04_two_hop_call.s.err` says**. Loud on both
binaries, unmoved by this fix (the module contains no bitcast). The row's CLAIM — a
two-hop / transitive Phase-6 candidate accepts twin-identically — is carried by
`R05_nested_helper`, which does.

## Gates
Run in the brief's order, on the SUBJECT build. ⚠ **EVERY WALL-CLOCK FIGURE HERE IS
A LOADED ONE** and is not comparable to CLAUDE.md's quiet-box band: two sibling
worktrees (`CQ_l4x4`, `CQ_trackA`) ran their own e2e suites for the whole of this
session — **THREE `loop_twin_matrix.py` processes were visible in `ps` at once** and
the 1-minute load average peaked at **275**. Nothing was relinked under a running
measurement; nothing was killed by pattern; no other worktree was written to.

```
# 1. targeted lit, while iterating
lit ir-pass/test --filter 'control_peel'   -> 38/38 PASS  (35 pre-existing + 3 new)

# 2. ir-pass-lit (the whole 1814-fixture corpus)
ctest --test-dir build -R ir-pass-lit      -> Passed, 127.40 s, 1/1

# 3. e2e + the tests/ tree
ctest --test-dir build -j6 -R '^e2e-' --output-on-failure
                                           -> 100% tests passed, 0 failed out of 379
                                              Total Test time (real) = 1300.00 s
                                              (e2e-loop-twin-matrix alone: 1299.95 s)
git status --porcelain tests/              -> EMPTY  (0 lines: no slice, no golden,
                                              no CMakeLists change — this round adds
                                              no e2e artefact at all)

# 4. corpus diff, ORACLE (main 0c7380c) vs SUBJECT, over EVERY fixture — exit code,
#    stderr AND lowered text on each
=== 1814 fixtures compared: 13 RCDIFF, 23 DIAGDIFF, 0 OUTDIFF ===
    ... and the 36 mover lines are 23 DISTINCT FILES, every one of them
    `control_peel_*` — this increment's own family. Over the **1776 pre-existing
    fixtures: 0 RCDIFF, 0 DIAGDIFF, 0 OUTDIFF.**

#    ⚠ A CONSISTENCY CHECK WORTH MORE THAN THE ZEROES: the 23 moving files are
#    EXACTLY the 23 the audit measured the peel FIRING on (`diff` of the two lists
#    is empty). Every other fixture leaves `Delta` empty, so `adjudicateTaintDelta`
#    returns at its first line — the 0/0/0 is by construction, and those 23 are the
#    complete list of fixtures ANY change to the five calls can move.

# 5. probe corpora — see the section above: r1 BYTE-IDENTICAL to the reviewer's
#    recorded sweep, impl = reviewer's + exactly the 3 rows added, r2 = the review's
#    tables with BC1 as the ONLY move (the fix). 150 verdicts.

# 6. the non-e2e ctest layer
ctest --test-dir build -j2 -R 'runtime|frontend-lit|cq-opt-equivalence'
                                           -> 100% tests passed, 0 failed out of 10
                                              Total Test time (real) = 26.94 s

# 7. after the final COMMENT-ONLY source edits, BOTH targets rebuilt and the peel
#    layer re-run, so the shipped source and the gated binary are the same tree
cmake --build build -j8                    -> 0 errors
lit ir-pass/test --filter 'control_peel'   -> 38/38 PASS

# 8. FULL SUITE, once
ctest --test-dir build -j6 --output-on-failure
     -> 100% tests passed, 0 tests failed out of 389
        Total Test time (real) = 1107.00 sec   (19:22:32 -> 19:40:59)
        389/389 Test #318: e2e-loop-twin-matrix ... Passed 1106.96 sec
        335/389 Test   #8: ir-pass-lit ........... Passed   59.79 sec
         47/389 Test   #9: cq-opt-equivalence .... Passed   16.21 sec
    ⚠ ir-pass-lit and cq-opt-equivalence inside this run are the POST-rebuild
    measurements, so the shipped source and the gated binary are the same tree.

# 9. equivalence, the FULL stride-1 sweep (this round changes the pass's ANALYSIS
#    surface — a fifth call — so the sampled entry is not enough)
python3 tools/cq_opt_equivalence.py --opt <stock opt> --cq-opt build/ir-pass/cq-opt
        --plugin build/ir-pass/libCQPass.so --fixtures ir-pass/test --stride 1
     -> cq_opt_equivalence: compared 1814 fixtures, 0 mismatch(es)   (RC=0)
    (run directly rather than through `--target cq-opt-equivalence-full`, which
     DEPENDS on `cq-opt`/`CQPass` — invoking the script avoids any chance of a
     relink while a measurement is in flight. Identical command line.)
```

**MOVERS, the complete list.** Against `main` `0c7380c`: the 23 `control_peel_*`
fixtures the peel fires on (0 of the 1776 pre-existing). Against the ROUND-1 fix
tree b7d646c: **ONE** — `BC1` / `control_peel_identity_bitcast.ll`, hand IR,
`no template for opcode 'bitcast i32'` → ACCEPT, byte-identical to the ORACLE's
lowering of its hand-peeled twin. Mutants M-D and M-E each redden exactly one
fixture and nothing else, which is the same statement from the other side.

**Counts.** `ir-pass/test/*.ll` 1811 → **1814** (+3). `tests/e2e/*.expected.log`
**343, unchanged**. `ctest -N` **389, unchanged**. `runtime/`,
`tools/opcode_table.yaml`, `include/` **untouched**. No new frozen symbol, no new
diagnostic string, no golden regenerated.

---

## Open questions after this round

1. **The INSERTION half of the round-3 question is still only read, not run.** The
   audit covers the DELETED φ. The compare CLONE and the `select` the peel inserts
   were checked by the round-2 reviewer by reading (`condDataUseDisposition`,
   `f2SeedPinnedByLiveRegister`, `reverifyRailCondReads`) and by me not at all. If
   there is a round 3, that is the half to instrument the same way.
2. **Two retirement triggers are now load-bearing and neither is enforced by a
   test** — `BreakRegions`' raw `PHINode *` (safe only while P9 refuses in-loop
   sites) and `LiftedConsumers` (safe only while `declineClassicalMuxes` runs after
   the peel). Both are written at the code that depends on them; a mechanical
   tripwire for either would be a real improvement and I did not build one.
3. **P10 stays deliberately wider than the hazard** (any `StoreInst`/atomic in an
   arm), with the reason and the retirement trigger now recorded. Unchanged from
   round 1: the narrow `guardedShadowStoreShape` spelling is what a widening would
   use, and it needs a `LoopInfo` + a QRAM dependency inside an accept-only
   normaliser.
4. **`S03` (bd `3d8q`) accepts and emits a wrong register on the peeled mux rail.**
   PRE-EXISTING, reproduces with no peel (`S04`, on the ORACLE), and this increment
   ADDS CUSTOMERS to it. Not fixed here by instruction; recorded on the issue.
5. **The review's `K04` row is mislabelled** (§Probe corpora). Its claim is carried
   by `R05`; the file itself declines an I/O string on both binaries.
