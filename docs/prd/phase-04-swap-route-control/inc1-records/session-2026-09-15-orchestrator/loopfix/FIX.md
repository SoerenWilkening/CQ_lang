# loop-group MERGE + FIX — bd `test_C_libtooling-emkg` (P1 over-accept), session 2026-09-15

Branch `loop-group-fix`. Track S′ `dephase-fence-r2` (`6882685b`) with Track T `inloop-pairing`
(`c0029f26`) merged, one conflict resolved, then the Rule-13 round-2 finding F-1 fixed with red-green.

| binary | `shasum -a 256` |
|---|---|
| ORACLE `main` `74eabd2c` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` |
| MERGED, PRE-FIX (`212a913a`) | `ce3f8f3ddf611acc77b1c5f2a791005aaed7958752e47a436ad7e84fe3610202` |
| MERGED + FIX (this work) | `9dd81edb9f949bb584d9dde333193a24e009110954103d014ebe01f5bacb0fff` |

Both `ce3f8f3d…` and `9dd81edb…` were rebuilt from a clean stash/unstash cycle and came back
**bit-identical**, so every "before" number below is a fact about a binary that can be reproduced,
not a memory of one.

---

## 1. The merge — one conflict, resolved by MEANING

`ir-pass/test/loop_leak_dephase_reject_noregion_live.ll` was the only content conflict (`LoopPlan.h`,
`LoopLowering.cpp` and three other fixtures auto-merged). Resolved per the reviewer's measured
merge-gate section (`review_r13_loop/REVIEW.md` §I-9): that module is `s1_live_shift`, which the
pairing turns into an **ACCEPT at 14 == twin 14**, so Track T's conversion wins and Track S′'s
decline-string edit in that file is dead text about a verdict the file no longer has.

Checked rather than assumed, for the other two doubly-edited files and S′'s string:

* `loop_leak_dephase_accept_pertrip_dead.ll` — auto-merged; T's `PAIR` conversion sits over S′'s body.
* `loop_leak_dephase_reject_region_derivedbase_live.ll` — auto-merged; keeps **S′'s new** string and
  still declines on the composed binary.
* S′'s new string survives in **5** fixtures (`grep -rln 'rolled body leaks a rail entangled'`); the
  retired spelling `rotated after the loop` appears **nowhere** in `ir-pass/`.

### 1a. ⚠ A FOURTH DOUBLY-AFFECTED CLASS THE REVIEW DID NOT CHECK — found at the merge

The reviewer verified that S′'s three `control_phase_kickback_mixed_*_leak_control.ll` string updates
still decline on the Track-T binary. **It did not check S′'s other two decline fixtures, and both are
retired by the composition.** Measured on four binaries:

```
loop_leak_dephase_reject_cmp_rail_data.ll    ORA ACCEPT | S′ DECLINE | T ACCEPT | merged ACCEPT
loop_leak_dephase_reject_inloop_rotation.ll  ORA ACCEPT | S′ DECLINE | T ACCEPT | merged ACCEPT
```

They were **already red on the pre-fix merged binary** — measured, not argued: a full `lit ir-pass/test`
on `ce3f8f3d…` returned exactly **5** failures, these two plus the three red-first fixtures of §3.
So they are a MERGE effect and not a regression from the fix, and the narrowing this fix makes cannot
produce one in that direction (see §2, the `new ⇒ old` implication).

**Both were re-derived rather than re-baselined**, because each file's own L8 retirement trigger named
bd `tu9q` by id as the end state that converts it — and both triggers were character-for-character
correct:

| program | ORACLE rolled vs twin | MERGED+FIX rolled vs twin |
|---|---|---|
| `c1_cmp_rail_data` | 10 vs 14 (DIVERGENT) | **14 vs 14, `diff` EMPTY, BYTE-IDENTICAL** |
| `c2_inloop_rotation` | 20 vs 24 (DIVERGENT) | **24 vs 24, gate MULTISET delta EMPTY** |

⚠ `c2` is **not** byte-identical and its fixture header says so in those words: `-O1` LICM-hoists the
loop-invariant `y & 1` to trace line 3 in the rolled spelling and CSEs the twin's two copies into one
at line 10. Every gate between those two positions acts on the per-trip register `u` and its own
ancilla — a support disjoint from `%h` — so the reorder commutes exactly; handle numbering follows the
reorder; and the `y & 1` rail is measure-owned and left allocated by BOTH forms. The claim is
**multiset-plus-commutation, and it is written that way** rather than as an identity, because
`CLAUDE.md` §5 records a shipped fixture family that read a stability measurement as a correctness one.

Both fixtures are converted to ACCEPTs **in place, not renamed** (bd `gahu`, `CLAUDE.md` L8 — a
`git mv`'d fixture can be resurrected by a merge), with the historical header kept verbatim under a
banner.

---

## 2. The fix — F-1, and it is not four lines

`declineDephasingUnmarkedLoopRails`' conjunct (1) asked *"is this loop's body marked?"* as an **ANY**
over **`L->blocks()`**, which includes every strictly-deeper subloop's blocks, while conjunct (3) and
`declineUnmarkedRolledIterLocal`'s conjunct 2 both ask over `L`'s **OWN** blocks. A marked INNER loop
therefore silenced the whole fence for its enclosing OUTER loop.

**The reviewer called it "four lines"; measured, it is not, and the difference matters** (Rule 11).
The *behavioural* delta at conjunct (1) is **two independent changes** — the subloop filter AND the
ANY→ALL polarity — and delivering them as one shared predicate (Rule 14) also rewrites the correct
site. The functional diff is: **a new 11-line predicate `bodyBlocksMarked(L, LI, taint)` in the
anonymous namespace, and two inline loops (8 lines and 10 lines) replaced by calls to it.** Net
`git diff --stat`: 163 insertions / 17 deletions on `LoopLowering.cpp`, of which **~150 insertions are
comment** — the argued blocks of §5.

The extracted predicate IS `declineUnmarkedRolledIterLocal`'s existing spelling, verbatim plus an
`Any` totality guard, so **that site's behaviour is unchanged** and it is documented in-source as the
reference reading.

**Why the narrowing cannot produce a decline→accept**, which is what licenses attributing the two §1a
reds to the merge: `ANY over all blocks` FALSE means no block is marked at all; with ≥1 own block
(`LI.getLoopFor(L->getHeader()) == L` is a `LoopInfo` invariant) `ALL over own blocks` is then also
FALSE. So `new ⇒ old`, the fence can only fire more often, and the corpus sweep confirms it: **0
D→A movers.**

---

## 3. Red-green (Rule 12) — and the fourth fixture came from the fix's own re-attack

Fixtures written FIRST, watched fail, then the fix. On `ce3f8f3d…` (pre-fix): 3 FAIL, 1 PASS. On
`9dd81edb…` (fixed): 4 PASS.

| fixture | verdict | route into conjunct (1) | rolled vs twin BEFORE |
|---|---|---|---|
| `loop_leak_dephase_reject_nested_marked_inner.ll` (`n2`) | DECLINE | bd `tu9q` ROOT-MINT ESCAPE | ACCEPT 30 vs twin 34 |
| `loop_leak_dephase_reject_nested_iterlocal_inner.ll` (`n1`) | DECLINE | `markIfIterationLocal` — **needs NEITHER track, reproduces on the ORACLE** | ACCEPT 38 vs twin 42 |
| `loop_leak_dephase_reject_nested_iic_inner.ll` (`n3`) | DECLINE | bd `tu9q` CLAUSE (ii-c) | ACCEPT 43 vs twin 48 |
| `loop_leak_dephase_reject_nested_depth3_middle_rail.ll` (`r1`) | DECLINE | **DEPTH 3**, middle loop's own rail | ACCEPT **72 vs twin 72** ⚠ |
| `loop_leak_dephase_accept_nested_outer_no_own_rail.ll` (`a9`) | **ACCEPT control** | outer has no own rail-minting op | 24, unmoved |

Three decline fixtures rather than the two the review specified, because the three markers are
**three independent doors** and each can be changed on its own; a fix pinned at one is pinned at none
of the others.

⚠ **The depth-3 cell is the one worth reading.** It was built as a Rule-13 re-attack to test whether
the narrowing OVER-declines on a three-level nest, and the first measurement read `ORACLE A:72 |
twin A:72` — which looks exactly like an over-decline this fix introduced. The MULTISET says
otherwise:

```
rolled                             twin
  12 cq_template_and_i32_hl          10 cq_template_and_i32_hl
  12 cq_template_lshr_i32_hl         10 cq_template_lshr_i32_hl
   8 cq_template_lshr_i32_hl_unc     10 cq_template_lshr_i32_hl_unc
   8 cqrt_free                       10 cqrt_free
```

Twelve mints, eight discharges: **four undischarged which-path copies of `y`** standing at
`cqrt_ry_i32(h0, 0.9)`. `12+12+8+8` and `10+10+10+10` are both 40, which is the entire reason the
totals agree. **A line-count equality is not a multiset equality, and for a nested loop it is not
even good evidence of one.** That sentence is in the fixture header.

**Decline-fixture validation is BINARY MUTATION, not IR-text `CHECK-NOT`** (Rule 12 hygiene (b) — a
`DS_Error` writes 0 bytes to stdout): all four fail on `ce3f8f3d…`, verified per file.
**Every fixture also pins the diagnostic's `file:line:col`**, so a lost `!dbg` (invisible to every
other gate in this tree) goes red here.

**Fixture hygiene (a)** — counts and negatives are in SEPARATE whole-file prefixes in every accept
fixture written or converted here, one counted symbol per prefix.

### Mutation matrix — MISSED 0

`trackT/probes/inject_T.py` reused verbatim (Rule 14) with `CQ_T_BUILD` repointed; it runs each
fixture's OWN RUN lines rather than a hand-built FileCheck, which is the defect that once produced
"45 MISSED against fixtures that catch everything". Self-attacked first: **no fixture argument exits
2**, as designed.

**57 mutations applied, MISSED 0, N/A 7** over 8 accept fixtures (the 4 new/converted plus the 4
pre-existing dephase accepts). All 7 N/A are `loop_leak_dephase_accept_inplace_volatile.ll`, whose
stream is in-place `cqrt_xorc` with no template rail, no `_unc` and no free — a pre-existing property
of that fixture, not of this change.

---

## 4. What I re-attacked (Rule 13) — 6 probes, 1 real find, 1 instrument caught lying

`CLAUDE.md`'s measured precedent is that a fix introduces new holes ("8 instances over 6 rounds on
one function, TWO OF THEM INTRODUCED BY A FIX"). Six attacks, all committed under `probes/`:

| probe | attacks | result |
|---|---|---|
| `r1_triple_nest_mid_rail` | over-decline at DEPTH 3 | **FOUND A FOURTH F-1 CUSTOMER**, not an over-decline — see §3. Now a fixture |
| `r2_outer_marked_inner_rail` | the OPPOSITE nesting: an ancestor's `markIfIterationLocal` covers a descendant's own blocks, so `bodyBlocksMarked` silences the fence for the INNER loop | ACCEPT **28 == twin 28 BYTE-IDENTICAL** — sound, and it is sound for a reason: a marked BLOCK means the spine discharges IN that block, i.e. per INNER trip |
| `r3_nested_cmp_rail_outer` | the COMPOSITION of this fix with Track S′'s conjunct-(3) widening: the outer's own rail is an `icmp` used as DATA, unreachable through a nest before | ORACLE ACCEPT 38 vs twin 42 → **DECLINE**. A composition nobody reviewed, in the SAFE direction |
| `r4_nested_inbody_interference` | the composition with S′'s dropped `L->contains` skip — interference INSIDE the outer body | declines earlier, `cq taint escape: tainted value muxed by a classical-condition phi`, on BOTH binaries. Not reachable; nothing found |
| `r5_sibling_loops_one_marked` | SIBLING loops — is the defect about CONTAINMENT or about "some marked block exists"? | containment: ACCEPT **28 == twin 28 BYTE-IDENTICAL**, unmoved by the fix |
| source enumeration | ANY-vs-ALL: can a loop's own blocks be PARTIALLY marked? | **No, and it is an enumeration**: `grep -n 'IterationLocalBlocks.insert'` finds exactly 2 writers; `markIfIterationLocal` inserts all of `L->blocks()` (covering every nested loop's own blocks completely), `markIfRailLocal` inserts `L`'s own blocks only. Neither can mark a proper subset. Written into the predicate with its retirement trigger |

⚠ **AND MY OWN CORPUS-SWEEP INSTRUMENT REPORTED A CLEAN PASS WHILE MEASURING NOTHING.** Its first
spelling was handed the binaries at a flat path and ran `$BD/ir-pass/cq-opt`, which did not exist:
**every one of 2050 rows on BOTH sides was exit 127**, identical, and it printed **"0 movers"**. It
was caught only because the rows carried a `<NO-DIAGNOSTIC-TEXT>` tag and I read them. `CLAUDE.md`
L10, live, in a tool I wrote in this session. The script now **refuses to emit a file** unless the
binary and plugin exist, no row is 127, and both verdicts actually occur — and the refusal is
self-attacked (a bad path exits 2). `probes/sweep.sh`.

---

## 5. The three owed source sentences (L7-with-a-twist — *a record correction not applied to the
source is not a correction*)

1. **Track S′'s retirement trigger FIRED and neither track read it.** `mintsOutOfPlaceTemplateRail`'s
   trigger names "a writer of `InPlaceRailOps` that runs AFTER this stage"; bd `tu9q` added exactly
   one (`declineRound2FalsifiedRailGrants` → `invariantRegisterRoots` → `commitOutOfLoopInPlaceOps` →
   `markInPlaceRailOp`). The re-derivation is now **in the source**, with its three reasons named
   — disjoint populations (`commitOutOfLoopInPlaceOps` is out-of-loop-only, conjunct (3) is
   own-blocks-only), a rollback that erases only that call's own new commitments, and a residual skew
   that points at declines — and the trigger is **re-aimed** at the case that would actually falsify
   it: a post-stage writer that can commit an **IN-LOOP** op.
2. **Clause (ii-c)'s argument restated on its correct ground.** Track T argued MULTIPLICITY (no `At`
   can land in a K-times body), which is a fact about two partitions' bookkeeping. The ground is
   **PHYSICS**: a MEASURED rail is not a coherent which-path record, so the Rule-8 hazard — which
   needs the rail ENTANGLED at the interference — does not arise. Recorded with its negative-control
   measurement (`warnLiveRecordRotations` silent on both halves of `x1_iic_bodyrail_interfered`,
   where it fires with count 1 and count 2 on the ORACLE), and with "keep both halves" spelled out.
3. **Track T's Rule-14 charge against `measureOwnedInvariantRail` DOES NOT STAND, and its premise is
   false.** Corrected as a dated ERRATUM at the site T wrote it (`trackT/IMPL_T2.md` §12(1)), with
   the original left in place. Verified independently here against the ORACLE COMMIT rather than a
   worktree: `git show 74eabd2c:ir-pass/src/LoopLowering.cpp | grep -n railValueConsumerDisposition`
   → definition at **:242**, call sites at :317, :996, :2255, :2685, plus `OpcodeLowering.cpp:768`.
   It is file-local (not in `LoopPlan.h`), which is the likely way a scoped grep missed it — **the
   lesson is the grep: "grepped" is not a measurement unless its scope is stated.** And the charge
   fails on the merits anyway: the two take different arguments, return different types and ask about
   different subjects. **DO NOT MERGE THE TWO PREDICATES.**

## 6. T-5 (`r1_break_loop`) — CLOSED, shipped with a transfer witness, NO refusal added

Re-measured on `9dd81edb…` rather than inherited: `r1_break_loop_un` declines at bd `3d8q` on the
ORACLE, S′, T **and** the merged binary; the split-body variant `t5b_break_split.c` declines at the
same fence on all of them. The transfer witness holds — `-O1` folds the `break` into one extra
disjunct on the LATCH so the body is a single block (mint/mint/`_unc`/free/measure/`br`), the
break-free twin `t5a_nobreak` is **24 == 24 byte-identical**, and
`diff r1_break_loop.trace t5a_nobreak.trace` is **EMPTY**.

Shipped as `ir-pass/test/loop_pairing_accept_break_latch_folded.ll`, which pins the ATOMICITY with a
`CHECK-NEXT` chain and carries the L8 retirement trigger naming bd `3d8q` by id. **No multi-exit
refusal was added** — it would be an over-decline on a claim nobody can substantiate either way
(Rule 17, owner 2026-09-11), and it would refuse a program there is a witness for. The header states
what is NOT claimed: multi-exit shapes are not exhausted, and "the reachable ones die at `3d8q` first"
is a measurement about today's binary, not a proof.

## 7. The instrument gap — FILED, not built

bd `test_C_libtooling-vsr6`. `tools/loop_twin_matrix.py`'s `cells_of_matrix()` is a
PREFIX × REGION × SUFFIX product over a **single** loop; "nest" in it means a nested CONTROL region,
never a nested loop. **None of its 338/359 cells can see any shape in this document.** Neither can
`free_pairing_check.py` (blind to template-minted rails by construction), and no shipped fixture had
the shape — the ORACLE accepted `n1` with nothing red. Seeded with the 6 rolled/unrolled pairs under
`probes/`. **Not built here** — Track I owns that instrument and is mid-session.

## 8. Still open

* **The re-derivation of §1a's two conversions was done by ME, the agent that merged them.** Rule 13
  says a core change is cleared by an INDEPENDENT reviewer; two decline fixtures becoming accepts is
  a core-behaviour change, and its clearance here is a measurement (`diff` empty / multiset empty),
  not a second opinion. **Owed: a Rule-13 opinion on the two conversions and on `r3`'s
  A×B composition** — the same species of gap the reviewer named for F × P (`CLAUDE.md` §4c).
* `cq-opt-equivalence-full` (S′ moved a decline string; 5 fixtures mirror it), `^e2e-`, the full
  `ctest -j6` and one `e2e-loop-twin-matrix` are **owed to the merge-and-gate agent** and were
  deliberately NOT run here (PROTOCOL reserves them).
* bd `gahu` now has three more `*_reject_*` files that are ACCEPTs and are deliberately un-renamed:
  `loop_leak_dephase_reject_noregion_live.ll`, `…_reject_cmp_rail_data.ll`,
  `…_reject_inloop_rotation.ll`.
* The two pre-existing `IterationLocalBlocks` exposures the reviewer listed in §I-5
  (`markIfIterationLocal`'s round-1 grant is not re-asked; the set is unscrubbed and read in the
  accept direction by `FreePoint`/`Uncomputation` after `lowerBreakReversePlay` creates blocks) are
  **untouched by this fix and must not be read as closed by it.**
