# bd `test_C_libtooling-woa0` — the cross-claim RE-ASK, measured

```
ORACLE   fe5805a41df2e173   git 18d18728, no patch, rebuilt in `wt-oracle-woa0`
                            ⚠ BIT-IDENTICAL to the hash the incoming brief recorded —
                            an unplanned BUILD NULL CONTROL that happened to fire
SUBJECT  15adcac40d4455a7   ORACLE + this change (`libCQPass.so bab2a8b70c57c6b0`)
INSTR    ec14ef9caa628f28   SUBJECT + a commit log, `wt-woa0-INSTR-COMMITLOG`
MUTANTS  edc6b21389e6dd9f   SUBJECT + three env-gated mutations, `wt-woa0-MUTANTS`
```

Every worktree is named for what it is. Every sweep got its own `mktemp -d`. No two
sweeps ran against a shared path, and nothing was relinked under a running
measurement (the session's builds and its measurements are strictly interleaved,
never overlapped).

---

## 1. WHAT WAS WRONG — reproduced before anything was written

Round 3's `x3_outer_declines_then_claims.ll`, re-run on the shipping M4 binary
(`fe5805a41df2e173`, sha-checked first):

```
rc=1, 279 B stderr, 2 DBG leaves:
  leave @probe entry=entry merge=Bm gate=E6-condtree at:  br i1 %rp, …   <- outer refused
  leave @probe entry=Bt   merge=A  gate=W-witness
  (no leave for entry=A      -> region A CLAIMED)
  (no leave on the 2nd pass  -> the outer region CLAIMED TOO)
error: cq controlled lowering: control flow under quantum control
```

The decline is real and it is the WRONG OWNER: `collectCondTree` refusing the
`xor`-of-`select` that `convertPhis` left behind — round 2's *"a downstream
accident, not a fence"*, verbatim.

## 2. WHAT LANDED

CLAUDE.md L1's standing cure, applied literally, in four pieces:

| piece | where | what |
|---|---|---|
| RECORD | `isSupportedCondTree`'s M4 conjunct, via `PhiCondScope::RailLeaves` | every rail φ E6 ADMITS as a condition-tree leaf |
| COMMIT | `flattenPredMuxRegions`, immediately before `RegionFlattener::run()` | the region's leaves enter the caller's `PredMuxRailPhiRecord` **only once the claim is final** (the `BoolAlgPhis` precedent: a later `leave` discards the whole `R`) |
| OBSERVE | `RegionFlattener::convertPhis`, right after `BoolAlg` is settled | the **fact** that a recorded φ is being SELECT-CHAINED |
| RE-ASK | `declineConvertedRailPhiLeaves`, after the fixpoint **in both entry points** + inside `lowerCloneControl` | one loud, source-located `DiagnosticInfoUnsupported` |

Two decisions carry the whole design and both are written at the source:

* **It OBSERVES, it does not PREDICT.** The fence fires on the conversion, not on a
  re-derivation of where the φ lives. That is why it can neither over-decline a φ
  that survives nor miss one that does not — and it is why it also covers bd
  `test_C_libtooling-0fly`'s `{R.Merge}` cell for free, without asking a placement
  question at all.
* **The `!BoolAlg` conjunct is load-bearing, not caution.** `isStructuralRailPhi`
  also matches an all-constant 2-incoming `i1` φ, which converts by BOOLEAN ALGEBRA
  into an in-grammar and/or tree. Flagging that would re-create the exact 2-cell
  A→D the M4 reviewer's first spelling produced.

`WeakVH`, not `PHINode *`: a recorded φ can be erased by a path that is not
`convertPhis`, and LLVM reuses freed `Instruction` memory, so a raw pointer would
match a fresh φ at the same address. `WeakVH` nulls on deletion and does not follow
RAUW, which is exactly the pair of properties needed here.

## 3. THE PROBE MATRIX — verdict PRESERVED on every cell; only the OWNER moves

ORACLE vs SUBJECT, seven probes (round 3's three + four φ-incoming variants of mine):

| probe | φ incomings at the inner region's entry | ORACLE | SUBJECT | emitted IR |
|---|---|---|---|---|
| `x3_outer_declines_then_claims` | `[%rail, false]` | rc=1 `control flow…` | rc=1 **the new string** | n/a |
| `w_b_railrail` | `[%rail1, %rail2]` | rc=1 `control flow…` | rc=1 **the new string** | n/a |
| `w_c_truerail` | `[true, %rail]` | rc=1 `control flow…` | rc=1 **the new string** | n/a |
| `w_e_railtrue_swapped` | `[false, %rail]` | rc=1 `control flow…` | rc=1 **the new string** | n/a |
| `x1_entryphi_converted_later` | `[%rail, false]`, block order forced | rc=1 `control flow…` | rc=1 **the new string** | n/a |
| `w_d_allconst` | `[true, false]` | **rc=0** | **rc=0** | **IDENTICAL** |
| `x2_naturalorder` | `[%rail, false]`, natural block order | **rc=0** | **rc=0** | **IDENTICAL** |

**Not one verdict moved.** Five string moves, all from the downstream accident to
the named fence; two accepts untouched and byte-identical. That is the shape this
change was supposed to have: it converts an accident into a fence and nothing else.

⚠ `w_d_allconst` is a WEAK negative control and says so here rather than in a
review record. Its region never claims at all (an entry-block all-constant φ is not
tainted after the flatten, so E6-classicalbr leaves), so **it does not exercise the
`!BoolAlg` conjunct** — it only shows the change is inert on it. The conjunct's real
witness is the mutant in §6.

## 4. THE OWNER'S PROGRAM — byte-identical, and it is a LIVE CUSTOMER of the record

```
example/grover/grover_oracle_uncompute.c   ORACLE rc=0 / 0 B   SUBJECT rc=0 / 0 B   BYTE-IDENTICAL (124 lowered lines)
tests/e2e/slice_grover_oracle_uncompute.c  ORACLE rc=0 / 0 B   SUBJECT rc=0 / 0 B   BYTE-IDENTICAL (130 lowered lines)
```

⚠ **AND IT IS NOT AN INERT PASS-BY.** The commit log (§5) shows the owner's program
COMMITTING its rail φ — `%cq.bank1`, the `_Bool` bank cell — into the record on both
files. So the fence is live over the single most important accept in the tree, sees
the φ, and correctly does not fire. A byte-identity that came from the record never
being populated would have been worth nothing; this one is not that.

## 5. THE COMMIT CENSUS — the corpus A/B is NOT vacuous, measured rather than hoped

A clean sweep over a population that does not contain the shape measures nothing;
this project has filed that twice (round 2 §6, increment 4 round 1). So the record's
population was measured directly, with an instrumented binary
(`INSTR ec14ef9caa628f28`) whose controls all ran first:

| control | result |
|---|---|
| INSTR ≡ SUBJECT with the env **unset**, 7 probes (rc, stderr, emitted IR) | **0 divergent of 7** |
| NULL — `env -u CQ_WOA0_COMMITLOG` on `x3` | **0 events** (⚠ `env -u`, never `VAR=`: `getenv` reports an empty string as PRESENT — round 3 paid for that one) |
| NULL 2 — a module with no φ | **0 events** |
| POSITIVE — env set on `x3` | **1 event**, the expected commit |

```
COMMIT EVENTS over all 2156 fixtures: 4, in 4 modules
  control_predmux_accept_rail_phi_cond                       phiblk=join entry=join
  control_predmux_reject_rail_phi_cond                       phiblk=join entry=join
  control_predmux_reject_rail_phi_false_edge                 phiblk=join entry=join
  control_predmux_reject_rail_phi_converted_by_later_claim   phiblk=A    entry=A     <- the new fixture
plus, outside the fixture corpus:
  slice_grover_oracle_uncompute / grover_oracle_uncompute     phi=%cq.bank1
```

Two things follow and both matter. (a) The record commits in **3 shipped modules
plus the owner's program** and trips the fence in **none** of them — so §7's clean
A/B is a real zero, not an empty one. (b) **Every commit in the tree is the
ENTRY-φ cell.** The `!InRegion` disjunct — bd `test_C_libtooling-0fly`'s
`{R.Merge}` over-admission — has **no commit customer anywhere**, which independently
reproduces round 3's finding from the other side.

## 6. MUTATION, BOTH DIRECTIONS — and it found a MISSING FIXTURE, not just a pin

Three mutations, all env-gated into ONE binary so the null control is the same
build: `CQ_WOA0_MUT_NORECORD` (drop the E6 record), `CQ_WOA0_MUT_NOCOMMIT` (drop
the claim-time commit), `CQ_WOA0_MUT_NOBOOLALG` (drop the `!BoolAlg` conjunct).

| control | result |
|---|---|
| MUT with all three **unset** vs SUBJECT — 7 probes + the 4 census fixtures | **0 divergent of 11** |
| MUT with all three **unset** vs SUBJECT — whole corpus | **0 movers of 2156** |

⚠ The first spelling of that control printed `divergent=0 of 1` and I nearly took
it: under **zsh** an unquoted `$FILES` is one word, so the loop ran once. It was
caught only because the harness prints the DENOMINATOR. *A control that reports a
pass without reporting how many things it checked is not a control* — and this is
the same class as round 3's `export -f` bashism, one shell feature over.

**Non-vacuity of the decline fixture, by RUNNING FileCheck rather than re-reading
the prefixes:**

| binary | `opt` rc | the plain prefix | the DBG prefix |
|---|---|---|---|
| SUBJECT | 1 | **PASS** | **PASS** |
| `NORECORD` | 1 | **FAIL** | **FAIL** |
| `NOCOMMIT` | 1 | **FAIL** | **FAIL** |
| `NOBOOLALG` | 1 | PASS | PASS |

So the RECORD and the COMMIT are each independently load-bearing, and the fixture
is red without either. Note what the table also says: **`opt` still exits 1 in
every row** — the module declines on all four binaries and only the OWNER moves.
A fixture that pinned the exit code alone would be green on all four.

### ⚠ THE `!BoolAlg` CONJUNCT WAS UNPINNED, AND THAT IS WHY THIS SECTION EXISTS

`NOBOOLALG` changes nothing in any of the seven probes, and a **whole-corpus A/B
against it reports 0 movers of 2156**. A predicate with an empty corpus population
is the bd `test_C_libtooling-e1gr` class, and the project's precedent (increment 3
round 2 on `regionStrictlyInsideLoopBody`) is to keep it under L3 and record the
measurement instead of the rationale.

**I did not stop there, and the witness exists.** It took two attempts and the
first one is worth recording because it failed the way this project's probes keep
failing:

* **attempt 1** — a recorded all-constant φ at region A's entry, with an outer
  region B whose merge IS that block. The commit log confirmed the φ WAS recorded,
  and then B left at `gate=W-witness`: one merge φ with two incomings satisfies no
  claim witness, so `convertPhis` never ran. **The probe contained the record but
  not the conversion** — bd `test_C_libtooling-46oo`'s class, caught by reading the
  DBG trace rather than the verdict.
* **attempt 2** — the same module with a SECOND φ in that block, so B's claim
  witness fires. Measured:

| binary | rc | |
|---|---|---|
| ORACLE (pre-woa0) | **0** | and its lowered module is BYTE-IDENTICAL to SUBJECT's, 101 lines |
| SUBJECT | **0** | the boolean-algebra conversion of a recorded φ is correctly not a violation |
| `NOBOOLALG` | **1** | `… rail phi converted by a later flatten` — **an A→D** |

That module is now committed as
`ir-pass/test/control_predmux_accept_recorded_railphi_boolalg_converted.ll`, with
exact per-family gate counts (not prefixed positives — the increment-2 round-1
"at least N" lesson) and mutation-validated in both directions. ⚠ Its `NEG` prefix
**passes on the mutant too**, because a declining `opt` writes 0 bytes to stdout and
a `CHECK-NOT` over nothing is vacuous (Rule 12 hygiene (b)); the exact COUNTS are
what carry that file, and its header says so.

**The general lesson, and it is the one I would carry forward:** the mutation
matrix was not confirmation — it was the only thing in this session that found a
missing fixture. Two of three mutants pinned what I expected; the third said "this
conjunct is unpinned", and chasing that produced a shipped accept fixture for a
cell no corpus sweep could ever have shown me.

## 7. WHOLE-CORPUS A/B

Null control run FIRST, positive control second, neither inferred from the other.

| sweep | n | result |
|---|---|---|
| NULL (SUBJECT vs SUBJECT) | 2156 | **0 movers** |
| POSITIVE (ORACLE vs SUBJECT over 4 modules: 1 known mover, 3 known non-movers) | 4 | **1 mover, the known one; the 3 non-movers silent** |
| **ORACLE vs SUBJECT** | **2156** | **1 mover** |

```
control_predmux_reject_rail_phi_converted_by_later_claim :: STR
  A[cq controlled lowering: control flow under quantum control]
  B[cq controlled lowering: emitted predicate tree's rail phi converted by a later flatten]
```

**A→D = 0 · D→A = 0 · crash-flips = 0 · IR/stream moves = 0 · decline-string moves = 1,
and the one mover is the increment's own new fixture.**

⚠ The harness compares exit code, normalised stderr and the emitted IR. It does
**not** evaluate any fixture's `RUN`/`CHECK` directives — so "1 mover of 2156" means
*no module's verdict, message or emitted module changed*, and it is **not** "lit is
green". Both are measured, separately, in §8.

## 8. GATES

| gate | result |
|---|---|
| `lit ir-pass/test` | **2157 discovered, 2156 passed, 1 XFAIL**, 85.57 s, quoted with its load (8.2 at start, 262 at end — lit forks 12 workers internally; not a quiet-box figure) |
| full `ctest -j6` | **479/479 in 795.22 s**, ⚠ load **248 → 13** — started while this session's own `lit` run (12 internal workers) was still decaying, so NOT comparable with a quiet-box figure. Every row GREEN; a pass under contention is still a pass, and a RED row would have owed a serial re-run before being believed |
| stage 2b on the owner's slice | unchanged — the lowered module is byte-identical, so the checker reads the same module it read before |

Counts at the close (re-measured, not copied): ctest **479** · `^e2e-` **469** · `^e2e-slice-`
**410** · `twin-identical` **45** · fixtures **2157** · goldens **412** · twin matrix **382** cells.
`cq-opt 15adcac40d4455a7f2d9f785`, `libCQPass.so bab2a8b70c57c6b036c859f8`.

**Fixtures 2155 → 2157** (one decline, one accept). **Goldens unchanged at 412**:
this increment adds no accept SHAPE that runs, so there is no new e2e slice to add
— and rather than invent one, the e2e witness of record is
`e2e-slice-grover-oracle-uncompute`, which §4 and §5 together show is a LIVE
customer of the new record and byte-identical across the change.

### The G-13 standing probe — RUN, AND IT DID NOT REACH THIS FENCE

The standing obligation is a rolled-vs-unrolled pair with a trailing non-diagonal
gate on every register the condition reads. Built from the owner's program, both
spellings, on both binaries:

| probe | ORACLE | SUBJECT | |
|---|---|---|---|
| `rolled_trailing` / `unrolled_trailing` (trailing `cq_theta` on `Z` **and** `b0[0]`) | rc=1 | rc=1 | **stderr byte-identical**; rolled dies at `cq taint escape: tainted value stored to memory` |
| `rolled_trailing_z` / `unrolled_trailing_z` (trailing `cq_theta` on `Z` only) | rc=1 | rc=1 | **stderr byte-identical**, both at `control flow under quantum control` |

⚠ **REPORTED AS WHAT IT IS: A NON-DIVERGENCE MEASURED AT THE WRONG WALL.** Both
pairs decline at fences that are not this change's, on both binaries, so the probe
shows no divergence but does **not** exercise the record. That is bd
`test_C_libtooling-46oo`'s class — a probe that does not contain the shape its name
claims — and the honest reading is "G-13 ran and found nothing, and it could not
have found anything here", not "G-13 cleared it". The obligation's real target is an
accept-direction widening of a condition fence; this change is decline-direction and
adds no accept, which is why the pair lands short.

## 9. ⚠ WHAT THIS DOES **NOT** DO — read this before quoting §3

* **It does not make M4's conjunct total.** The conjunct is still a point-in-time
  property and nothing re-asks *it*; what is now total is the OUTCOME. Both source
  comments that used to say "true only within one pass" now say exactly this, at
  both sites, because a correction not applied to the source is not a correction.
* **It is a FENCE, not the fix.** The composition it declines is REALIZABLE — a
  classical join feeding a quantum control — so by the 2026-09-11 owner ruling this
  is compiler structure and the decline is a defect to remove, not a wall. The route
  that removes it is bd `test_C_libtooling-41g3`'s: RECORD the φ so `convertPhis`
  cannot select-chain it at all. For a rail φ the boolean-algebra path yields
  `and(EP, %rail)`, which IS in `collectCondTree`'s grammar because a rail leaf is —
  so the removal looks cheap from here, and "looks cheap" is not a measurement.
* **It does not prove the composition could never have been a wrong unitary.** Round
  3 argued that analytically and did not prove it exhaustively; neither did I. What
  changed is that the outcome no longer depends on the argument.
* **The `{R.Merge}` cell (bd `0fly`) is now covered by the OBSERVATION but its
  dominance argument is still unwritten.** Covered ≠ closed: this change makes a
  conversion of that cell a loud decline instead of whatever `collectCondTree`
  happened to do, but 0fly asks for the E3-derived argument to be written down or
  fenced at the conjunct, and the conjunct is unchanged.
* **No simulation, no statevector** (Rule 2). Every claim here is a verdict, a
  string, a byte-diff or an event count.
* **No `+Asserts` build.** The tree still cannot have one — four committed ACCEPT
  fixtures abort a Debug `cq-opt` — which is the structural reason the
  unchecked-`cast<>` family in this very file has no gate, and 5a's P1 came from
  that family. My change adds one more unchecked `cast<PHINode>` context (round 3's
  F-R3-6 already filed the existing one); it is sound only because
  `isStructuralRailPhi` opens `dyn_cast_or_null` in a DIFFERENT translation unit.
* **No independent Rule-13 round.** This change is a new fence in the Rule-13
  lowering core and a green suite does not clear it. Budget two rounds.
* **A duplicate-body scan over all 2157 fixtures** (sha-256 of each file's
  non-comment lines, the L8 post-merge discipline) reports **9 identical-body
  groups, NONE of them involving this session's two files**. ⚠ Nine is more than
  the five bd `fn1q` recorded over 2149 — pre-existing, not measured further here,
  and not this change's.

---

## ⚠ ERRATA — 2026-09-27, from Rule-13 rounds A and B (bd `test_C_libtooling-u460`)

The original text above is left VERBATIM; these are the corrections, dated, in the
convention this project uses for a sealed record. Both rounds are at
`../session-2026-09-27-orchestrator/REVIEW_R13_R{A,B}_WOA0.md`.

**E1 — §1's mechanism is measurably FALSE (`F-RB-3`).** *"`collectCondTree` refusing
the `xor`-of-`select` that `convertPhis` left behind"* names a node that does not
exist: there is **no `xor` anywhere in the post-flatten module**, on either binary,
for the committed decline fixture or its incoming-order-swapped twin —
`convertPhis`' *"¬c IS AN ARM SWAP, NOT AN `xor` NODE"* fold sees to that. The
downstream owner is **`SelectClassify`'s DATA-SELECT grammar** refusing a `select i1`
condition, which it does because that grammar does not carry `AllowLogicalSelect`.
The six sites carrying the `xor` wording inherited it from round 3's F-R3-1, which
describes a different module; the four mutable ones are corrected at the source.

**E2 — §3's probe matrix has ZERO cells in the quadrant where the over-decline lives
(`F-RA-6`).** §3 correctly flags `w_d_allconst` as a weak negative control. It
presents `x2_naturalorder` as an ordinary unchanged accept, and **the two are weak
identically**: measured on `INSTR`, *both* accepting probes commit **0**. So the
matrix contains no cell in which **the record is populated AND the module accepts**,
and the over-decline surface was therefore unmeasured. §7's whole-corpus A/B cannot
supply one either — 5 commit modules in 2157 and none converts. *A clean `A→D = 0`
measured over a population with no members of the class is not evidence about the
class*, which is this record's own standing caveat (§5), not applied to the row that
needed it. What that cost is bd `test_C_libtooling-707a`.

**E3 — §5's census number is stale by one (`F-RA-8`).** *"4, in 4 modules"* was taken
over 2156 fixtures, i.e. **before this increment's own accept fixture landed**.
Re-measured on the same `INSTR` binary over all **2157**: **5 modules**, the fifth
being `control_predmux_accept_recorded_railphi_boolalg_converted.ll`
(`phiblk=J phi=%cphi entry=J`). ⚠ **Both of §5's real claims survive** — every commit
is the ENTRY-φ cell, and the `!InRegion` disjunct has no commit customer anywhere —
but the number as printed is not reproducible at HEAD. Say **5 of 2157**.

**E4 — §9's *"no `+Asserts` build; the tree still cannot have one"* is retired.**
Round B built one and swept the corpus: **2157 swept, 4 aborts**, exactly round 3's
four, and **woa0 adds none**. It is a four-fixture bill, not a structural
impossibility — bd `test_C_libtooling-r4f6`.

**E5 — §9's *"no independent Rule-13 round"* is discharged.** Two ran, concurrently
on a frozen subject, both `CLEAR-WITH-ITEMS` with **0 P1**. They converged
independently on one P2 that §3's matrix could not see (E2 above).

**NOT corrected, because they were re-measured and held:** the ORACLE/SUBJECT hashes,
the 7-probe verdict table (§3), the owner's program byte-identity and its live
customership of the record (§4), §6's mutation matrix and its missing-fixture lesson,
§7's `1 mover of 2157`, and §8's gate figures. Round A reproduced §7 independently
(null control first) and round B reproduced it again; round A also swept a layer this
record did not — **all 403 compilable `tests/e2e/slice_*.c`, 0 movers**.
