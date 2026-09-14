# Next session — bd `xdu2` (L-1a), the bounded rail ARRAY: W1 of the owner's ROLLED loop cascade

You are the **orchestrator**. Read `CLAUDE.md` first, then `bd prime`. Work the
orchestrator ↔ parallel-opus-agents workflow of the last two sessions: the binding
agent contract is
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/PROTOCOL.md`
— **copy it into every brief verbatim** and carry its 2026-09-14 strengthening
(the gate table, the hash-keyed `GATES.md`, the one-group merge rule, at most ONE
corpus sweep in flight). `model: opus` for **every** agent (owner ruling
2026-09-11). The orchestrator delegates builds and runs to agents and runs none
itself.

`main` at `6d1de106`, clean and pushed. `build/` holds the gated binary — `cq-opt`
`5c6f7490a81c7505…`, `libCQPass.so` `5276f7ab7416b36b…`. Full suite **442/442**,
equivalence **1993/0**, lit **1994**, goldens **383**, twin cells **338**.

⚠ **`shasum -a 256 build/ir-pass/cq-opt` before believing any decline.** A stale
build is indistinguishable from a regression from outside, and it cost time in each
of the last two sessions (memory `stale-build-looks-exactly-like-a-regression`).
⚠ `cmake --build build --target CQPass` **alone** is a false-green trap; always
`-j8` or name **both** `CQPass` and `cq-opt`.

---

## 1. What the owner asked for, and the decisions already taken

The owner rewrote `example/grover/grover_oracle_uncompute.c` as a **rolled loop**:

```c
int a = 5;  bool b0[3];
for (int i = 0; i < 3; ++i) {
    if (a >= 3) { b0[i] = cq_theta(b0[i], 0.5); }
    if (b0[i]) a -= 3;
}
return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);
```

It declines `cq taint escape: tainted value stored to memory`. **Owner rulings from
the design session, all recorded — do not re-litigate them:**

* **It must work ROLLED.** Unrolling is not the answer. The owner's words: *"I dont
  want to unroll … in the end this should be compileable as it leads to a valid
  algorithm."* ⚠ A `#pragma clang loop unroll(full)` workaround exists and is
  MEASURED (memory `loop-rail-array-pragma-unroll-workaround`) — it is a stopgap for
  the owner, **not** a deliverable, and extending `LoopUnrollPrepass`'s U2/U2b fence
  was considered and **rejected**.
* **PER-TRIP alloc, not preallocation** (memory `railbank-pertrip-vs-prealloc-decision`,
  which carries both reasons and the retirement-trigger citation). The rejected rival
  would have hoisted all N rails into a prologue, made the in-loop theta CHAINED,
  dissolved the store and made C6/C2′ trivial. It lost on (1) generality — prealloc
  needs a LOOP-INVARIANT SEED, since `cqrt_alloc_<W>(SEED)` carries the seed, so it is
  an optimization ON TOP of per-trip alloc rather than an alternative; and (2) blast
  radius — it makes the LOAD load-bearing for the memory-blind fences and thereby trips
  `ArmClassify.cpp:1282-1289`'s I-3 retirement trigger, forcing a from-scratch
  re-derivation of the F2 narrowing the owner's own three-bool file depends on, with a
  divergence the fixture corpus would **not** notice.
* **Order for the whole capability:** W1 (`xdu2`, this session) → bd `s82e` → W2 (the
  `Rollable` clause) → W3 (`ej5w`). Per the owner's 2026-09-14 Q3 ruling, *correctness
  over expressiveness*.

## 2. Read these before writing a brief

* **`…/session-2026-09-14-orchestrator/trackL/SCOPE_L1a.md`** — 505 lines, 20 probes,
  the design of record: seven accept clauses as `file:line` predicate sites, the
  six-door freeze enumeration (§4.4), the round-2 answer (§3), the instrument verdicts
  (§5), the corrected cost (§6), and §8's four clauses it could **not** turn into
  predicates. It supersedes bd `xdu2`'s own description, which it measures FALSE in
  three places.
* **`…/trackL/probes/TARGET_rolled_stage2.ll`** and **`…_mloop.ll`** — the stage-2
  target, hand-written to the design this session, `opt -passes=verify` clean, linked
  against the real runtime and **run**: 50 trace lines, three byte-identical per-trip
  blocks, handles chaining `h0→h5→h10→h15`. The `_mloop` variant proves a **rolled**
  measure loop reading the bank at a loop-variant index works. ⚠ This is evidence the
  target SHAPE is realizable and self-consistent — **not** that the unitary is right
  (Rule 2; the runtime is trace-only, `measure` returns 0). Do not let a reviewer cite
  it as clearance; the project's headline lesson is that every shipped Grover golden was
  the identity and no trace could see it.
* bd notes on `xdu2` (re-measured post-merge this session: the three-wall chain HOLDS on
  the current binary — W1 `a_loop_n3`; W2 `L1_promoted_nostore` → `control flow inside a
  loop body`, which **`wx8g` landed and does NOT clear**, a bank rail having no header φ;
  W3 `L3_uncond_prep_value`/`L6_good_prep_value_arm` → `loop-carried tainted value
  crosses iterations`). ⚠ ERRATUM already filed: `a_flat_n3` moved decline→ACCEPT when
  `om35` landed, so SCOPE_L1a §0 H2's "a_flat_n3 declines om35" is history.

## 3. Ask the owner these FIRST — three are blocking, two are carried over

1. **Uninitialized `bool b0[3]`** — the owner's file has no `= {0}`, and C1's
   constant-zero-memset clause would refuse it. Composing with bd `z9t1`'s undef-seed
   rule is a deliberate decision (SCOPE_L1a §7, Track U). **Blocking for C1.**
2. **bd `s82e` (P1, open)** — the rolled value arm leaves entangled which-path rails.
   In the validated target: 16 handles minted, 6 freed, **6 genuinely left over**
   (`h0 h5 h10` superseded `a`, `h3 h8 h13` the `a-3` temporaries), and stage 2b reports
   `0 violation(s)` because it counts alloc SITES. Orchestrator's reading, to put to the
   owner: those rails are entangled, so freeing them would be a hidden measurement and
   **"left allocated" is CORRECT** — the defect is that `markIfRailLocal` gets there by a
   silent refusal rather than a proof. Decide: proof, discharge, or decline.
3. **The `staleRailRecordRead` grouping key** — `b[0]` and `b[1]` are distinct rails
   sharing one alloca; one cell across trips is one rail. Nothing in the tree expresses
   that. `(alloca, index SCEV)` is SCOPE_L1a §8.2's **unmeasured** proposal.
4. **Carried from 2026-09-14:** bd `z9t1`'s two dispositions (bd `dnqo`, bd `fve8`) and
   bd `yiid` (is a measurement a BARRIER or a RELABEL) — see the previous
   `NEXT_SESSION_PROMPT.md` §"Waiting on the owner".

## 4. Suggested track split (4 parallel, then review → fix → one merge gate)

Sequence the dependency through **signatures, not waiting**: Track A publishes the
predicate's header signature in its first hour; B and C code against it.

| track | bead | scope | depends on |
|---|---|---|---|
| **A — the accept predicate** | `xdu2` | the carve verdict beside `qramCarveVerdict`, in the **QRAM TU** so it can call file-local `walkPtrOrigin`/`matchAddressGep`/`isDirectOriginPtr` without exporting them. Clauses C1–C4 + **C2′ injectivity** + **C6 totality**. Rule-12 red-green: ~12 decline fixtures, one per clause, each mirroring its diagnostic character-for-character. ⚠ C2′ must read the constant-max BTC as an **APInt at its own width** and carry the reachability-total conjunct — Rule 18 records `getSmallConstantMaxTripCount` returning `4294967295` on some vacuous bounds and `0` on others | — |
| **B — the promoter (C5)** | `xdu2` | the per-activation SSA forwarding normaliser, in the `-O1`-repair fixpoint at `CQLoweringPass.cpp:217-314` (so **no `adjudicateTaintDelta` is owed** — that idiom re-runs `propagate` from scratch). Model on `MergePhiPeel.cpp`. Target shape is `L1_promoted_store.c`'s `-O1` output — **stock clang emits it**, so it is not a hand construction. CALLS Track A's predicate; never re-derives it (Rule 14, the drbq Inc-3 (b′) precedent) | A's signature |
| **S — bd `s82e`** | `s82e` | the P1 that W3 lands on, fully independent of the bank. Root: a `markIfRailLocal` clause that REFUSES SILENTLY instead of declining. Its own adversarial round — last session's Track W round-2 reviewer nominated this as where the next silent miscompile already sits | — |
| **I — the instruments** | `21re` + new | two jobs. (a) `free_pairing_check.py:1259 provably_not_a_rail` rests on a docstring premise L-1a **falsifies** (`:1292` — "a tainted store is a loud decline … so a load result is not a rail"); the checker must learn the bank or the increment must keep the premise true. (b) **the witness**: rolled-vs-unrolled byte identity is **NOT available** for this program (50 vs 44 lines — `-O1` folds trip 0 in the unrolled spelling and cannot in the rolled one, SCOPE_L1a §0 H2), so design the replacement — K-independence of the lowered IR measured **without `-g`**, plus a per-trip multiset argument, labelled an INTERNAL-CONSISTENCY gate | — |

**Deliberately NOT this session:** the taint rule + D5 allow-list + the type rewrite.
They are the piece with the round-2 window, they need A and B landed, and the type
rewrite's slot (**after `lowerOps`, before `lowerMeasures`**) must ship with bd `21mg`'s
retirement trigger written into the source: *moving it above `repropagateControlMerges`
passes an `i32` HANDLE through the measure path as data.*

⚠ **D5 is the whole risk and must be stated in every brief that touches it.** A `load`
is invisible to `railOf`, `Freeable`, `Owned`, `Borrowed`, `D.Rails`, `D.FrozenRails`,
`CondRails`, `BaseWire`, `Gates`, `OnRailOut`, `ChainsByRoot` and `ClaimedRailRoots` —
SCOPE_L1a calls it *"the one door with no fence anywhere"*. The failure mode is not a
crash: `cq_measure(b[i])` on an **untainted** load takes `MeasureLowering.cpp:151`'s
classical split and emits **no gate, no symbol, no trace line**, and the golden
byte-diff cannot see a measurement that was never emitted. Hence a **positive
allow-list** (measure, further bank store) whose complement declines loudly — never a
deny-list.

## 5. Budget and posture

**Four Rule-13 rounds, not three** (SCOPE_L1a §6.5): L-1a gives the C-1 in-loop
entangled-rail family its **first memory-resident subject** and touches the
`collectRailGates` walk whose F-1/F-3 pair were confirmed silent miscompiles. Scope
round 1 to §4's fence enumeration alone. Budget the rounds up front — the measured hit
rate says the next round finds something.

Cost, calibrated by `git --numstat` against the four most recent comparable landings:
**~700–1100 pass-source lines, ~22 fixtures, +5 goldens / +7 ctest, 16–24 matrix cells**
for L-1a alone. bd `xdu2`'s own ~150–220 is low by ~4×.

Rule 17 governs: a decline is not the development escape hatch. If a clause proves
genuinely ambiguous, bring the question back to the owner rather than shipping a
decline-only stub.

## 6. Still owed from 2026-09-14, and it is a trigger that FIRED

**The X5 re-derivation.** Track F's φ-descendant narrowing names bd `wx8g` BY NAME as
the only reason its back-edge shape is unreachable — and `wx8g` landed in the same merge.
Three probes (committed in `merge_gate_probes/`) move from `control flow inside a loop
body` on the oracle to F1-decline / ACCEPT / ACCEPT on the merged binary. Nothing
over-accepts and both tripwire fixtures held, but the premise is FALSE and the argument
text in `ArmClassify.cpp` is **stale and must not be cited as it stands**. Do this before
widening anything near F2 — and note L-1a's Track A/B work sits close to it.

Also owed: a **Rule-13 opinion on the F × P composition** — two accepts that exist only
with both increments present, cleared by measurement and by no review
(`MERGE_FILINGS.md` §1–§2).
