# Wave 0-B — closing tracker-stale beads by MEASUREMENT (session 2026-09-18)

Agent: wave0-B. Main checkout, `/Users/sorenwilkening/Desktop/Projects/CQ_lang`, `main` `cff8f7ac`.
Built nothing. Edited no source, no fixture, no test. Wrote only under `$SES/wave0/` and to `bd`.

**ORACLE verified first, before any measurement** (PROTOCOL.md, and CLAUDE.md's own
"the hash is the cheap discriminator"):

```
$ shasum -a 256 build/ir-pass/cq-opt
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt
```

Identical to the PROTOCOL oracle block. Every measurement below is a fact about THAT binary.
Gate lines in `GATES_B.md`. Probes in `wave0/probes/`.

---

## Summary

| bead | verdict | evidence |
|---|---|---|
| `fve8` (P2, OPEN) | **CLOSED** | E2's three obligations re-measured: direct spelling accepts, byte-identical to the written-zero twin, decline string keeps its one ruled customer |
| `kqqv` (P2, IN_PROGRESS) | **VERIFIED FIXED — close REFUSED by bd** (blocked by `drln`); note appended | fix `2a25ca94` is an ancestor of main, `trackCondCone(V)` at `PredMuxFlatten.cpp:3353`, 6/6 fixtures PASS |
| `drln` (P1, OPEN) | **STAYS OPEN**, note appended | 5 of 6 items + all 4 should-fixes discharged in `134e625c`; **C2 is not**, and the source says so at `PredMuxFlatten.cpp:3772-3783` |
| `hlhh` (P1, OPEN) | **STAYS OPEN**, note appended | (1) the slot-test round is discharged; (2) the composition round ran, and ITS OWN output `c1`/`c2` is the residue — "cleared by measurement, by no review" |
| `8h7d.6` (P2, OPEN) — **found by the sweep** | **CLOSED** | the template-rail census landed in `95949550`; measured live at `2 template rail mint(s) of which 1 left dirty` on the headline slice |
| `58tc` (P2, OPEN) — **found by the sweep** | **STAYS OPEN**, note appended | severity changed decline→warning; the bead's own witness is now vacuous; the claim is still measurably live; **two source comments claim to close it and the measurement says otherwise** |

**Closed: 2. Verified-but-blocked: 1. Notes appended, left open: 3.**

---

## 1. `test_C_libtooling-fve8` — CLOSED

**What it owed** (owner ruling E2, `$PREV/DECISIONS.md`): `cq_measure` of an `undef`/`poison`
operand measures the type's concrete zero in EVERY spelling, the direct one included. Because it
retires part of the owner's own 2026-09-14 `z9t1` clause 4, it is a CODE change with a red-green
obligation: (a) the shipped decline fixture inverted, (b) a check on the decline string's
remaining customers, (c) the refinement argument MEASURED, never asserted.

**Landing.** Branch `fve8-fix`, merge `c663dd62`. ⚠ `git merge-base --is-ancestor c663dd62 main`
returns **NO** — the session was squashed, and the work is inside `95949550`. The implementation
is at `MeasureLowering.cpp` `lowerMeasures` branch **(1a)**, with the surviving-residual rationale
on `kMsgUndefOperand` at `:150-208`.

**(a) The fixture was INVERTED IN PLACE, not renamed** (L8 — a `git mv` can be resurrected by a
merge, which is bd `gahu`'s standing reason):

```
$ grep -n '^; RUN' ir-pass/test/lowering_reject_measure_undef_operand.ll
44: ; RUN: %cq-opt ... -passes=cq-lowering -S %s > %t.cqd0.ll
45: ; RUN: %filecheck %s < %t.cqd0.ll
...
```
No `not`. The historical `_reject_` name now pins an ACCEPT, and the new
`lowering_accept_measure_undef_zero.ll` names it as "the inverted twin ... (historical name, now an
ACCEPT)".

**(b) The decline string KEEPS exactly one customer** — which is what Track M's scoping finding (1)
predicted and the OPPOSITE of what the ruling's brief item (b) assumed:

```
$ grep -l 'operand is an undef/poison literal' ir-pass/test/*.ll | ... count 'RUN: not'
lowering_measure_undef_operand_after_taint_fold.ll   0
lowering_reject_measure_undef_global_init.ll         2   <- the surviving DECLINE
lowering_reject_measure_undef_operand.ll             0
```
Only the **whole-value `isa<UndefValue>`** spelling was retired; the `GlobalValue`-initializer
residual still declines.

**(c) The refinement, MEASURED.** Probes `fve8_direct.c` / `fve8_zero.c`:

```
$ diff fve8_direct.nog.body.ll fve8_zero.nog.body.ll
BYTE-IDENTICAL
```
(`-O1`, no `-g`, `ModuleID` + `source_filename` stripped; both reduce to `define i32 @main() { ret
i32 0 }` — a classical measure emits no symbol, no gate and no trace line, bd `21mg`.) Under `-g`
the only delta is the extra `#dbg_value`/`DILocation` the `= 0` declaration itself carries.

**Fixtures.** `lit --filter` on all three: 3 run, 3 Passed, 0 Failed.

**E9 / F-E2-1 (the vanishing QUANTUM measurement) — ruled ACCEPT + DISCLOSE, and the disclosure
exists.** `MeasureLowering.cpp:297` names `F-E2-1`; `:379-386` name the pre-existing `q * u` /
`q & u` spellings that already ship this circuit at HEAD; `:472-500` carry the rivals and the
retirement trigger. Reproduced:

| probe | exit | stderr | trace | `cqrt_measure`? |
|---|---|---|---|---|
| `int u; int q=cq_theta(0,0.3); return cq_measure(q+u);` | 0 | **0 bytes** | 2 lines | **absent** |
| the written-zero twin | 0 | 0 bytes | 3 lines | present |

Exactly the ruled behaviour, disclosed and deliberately not diagnosed (owner: *"both codes are
supposed to compie!! also no warnings."*). **The disclosure is not missing — no finding here.**

---

## 2. `test_C_libtooling-kqqv` — VERIFIED FIXED; `bd close` REFUSED

```
$ git merge-base --is-ancestor 2a25ca94 main && echo YES
YES
$ grep -n 'trackCondCone' ir-pass/src/PredMuxFlatten.cpp
3353:    trackCondCone(V);                    <- the fix, at canonicalizePred's entry
```

The bead's own orchestrator-reproduced witness — a NON-ROOT poison-shielded short-circuit select
(`%inner = select i1 %b, i1 %c, i1 false` feeding `%sc = and i1 %a, %inner`) with the gate arm on
the TRUE successor — **shipped as a fixture in the same commit**,
`control_predmux_accept_nonroot_shield_no_orphan.ll`, an ACCEPT fixture whose content is a NEGATIVE.

```
$ cd build && lit -v ir-pass/test --filter '<the six fixtures 2a25ca94 touched>'
-- Testing: 6 of 2082 tests, 6 workers --
PASS x6 ... Testing Time: 6.09s ... Passed: 6 (0.29%)
```

```
$ bd close test_C_libtooling-kqqv --reason "..."
cannot close blocked issue: test_C_libtooling-kqqv is blocked by [test_C_libtooling-drln]
```

**Wave 0-B did not `--force`.** The block is semantically defensible, not stale: `drln`'s open item
C2 is a coverage regression that **this very landing created** (see §3). The full verification is
appended to the bead so a reader of `bd list` is not left thinking an open P2 silent-leak BUG is
still shipping — it is not.

---

## 3. `test_C_libtooling-drln` — STAYS OPEN (1 of 6 items undischarged)

`git merge-base --is-ancestor 134e625c main` = **YES**. Each item re-verified in the HEAD source
by grep, not inherited:

| item | verdict | evidence at HEAD |
|---|---|---|
| **B1** false closure claim | DISCHARGED | `'refuses a shield under an xor entirely'` and `'EVERY node of the cone it consumes is tracked'` both return **zero** hits in `ir-pass/src`. `PredMuxFlatten.cpp:3318-3341` carries the narrowed claim and files the xor-TRUE-shield leak as PRE-EXISTING, "not fixed under cover of this one" |
| **B2** provenance | DISCHARGED | `:3234-3241` — "THE CAPITALIZED DIRECTIVE ... WAS NEVER SHIPPED", with qesi's actual RETRACTION quoted |
| **B3** ledger three→four | DISCHARGED | `:3487-3503` says FOUR producers and names `run()`'s `track(BI->getCondition())` as the fourth |
| **S1** unit | DISCHARGED | relabelled COPIES, 2 sites |
| **S2** itemization → 16 | DISCHARGED | fixture `:69` restores the `1 src` + `2 ld80` split for `nextafterl`/`nexttoward` |
| **S3** 86 vs 101 | DISCHARGED | `:3795-3799` states 86 as the `Idx=0`-ONLY count and spells out that one-polarity-only is 101 |
| **S4** "28 spellings" / "or POSSIBLE" | DISCHARGED | fixture `:79-84` restates as re-runnable; *"read that as 'none found', not as 'none exists'"* |
| **C1** central design claim unpinned | DISCHARGED **in the corrected direction** | the fixture shipped (6646 bytes) and its header opens *"IT DOES NOT KILL THE MUTANTS IT WAS COMMISSIONED TO KILL, AND THAT IS A MEASURED FINDING ABOUT THE DESIGN CLAIM"* — the prescription was wrong and the ~25 capitalized lines now rest on correctness-by-construction |
| **C3** unfailable CHECK-NOTs | DISCHARGED | `control_predmux_reject_xor_shielded_select_operand.ll:81` mirrors `cq controlled lowering: value-arm swap-route under quantum control` character-for-character; `:71` relabels the three CHECK-NOTs as documentation |
| **C2** un-pinned neighbour | **NOT DISCHARGED** | see below |

**C2, in the source's own words** (`PredMuxFlatten.cpp:3772-3783`):

> `*** BUT ONE CALLER'S WITNESS STOPPED WITNESSING WHEN THE OTHER LANDED, AND THE FIXTURE THAT
> SHOULD CATCH THAT DOES NOT EXIST YET (bd drln C2). *** ... Restoring the pin is owed and is
> tracked on bd drln.`

Measured absence confirmed: no `Idx=1`-only witness exists anywhere in `ir-pass/test/*.ll`.

**B1's DESIGN CALL** (should `trackCondCone` descend `SelectInst`) is a CAPABILITY question by the
round's own words — the claim is narrowed either way — and it touches the fence bd `j5i7` guards
(open, P3). Not a blocker.

**Recommendation to the orchestrator/owner** (a tracker call, not a measurement, so Wave 0-B did
not make it): split C2 into its own test-debt bead alongside `1yeu` / `f8eu` / `gahu`, or break the
`drln → kqqv` block explicitly. Either lets both close.

---

## 4. `test_C_libtooling-hlhh` — STAYS OPEN (item 2 has a live successor)

**Item (1), the independent Rule-13 round on the slot test: DISCHARGED.**
`$PREV/review_r13_armclassify/REVIEW.md`, verdict `CLEAR-WITH-ITEMS`, independent agent, subject =
the COMPOSED binary `7916923f56fb36af`. §6 *"F′ — `availableAtAnF2Slot` in the GRANTING direction
(brief item 3)"* **re-derives A5 rather than reading it** and shows the new member set is a strict
superset on reachable code, by two arguments (non-φ users by SSA transitivity; a φ the old proxy
inserted cannot be slot-available without contradicting `Pred` strictly dominating `MergeBB`). It
covers the bead's suggested lenses (a) and (c) and adds R-5 (the L1 round-2 item) and R-6. All six
items landed at the ARM group gate (`$PREV/armgate/FIXES.md` R-1..R-6 + `GATE.md`), which
additionally **ran** the source-mutation gate F′ never shipped (R-3, four mutants over the
predicate's two clauses).
Tripwire fixtures: **cited, not re-run** (§6.1) from `$THIS/GATES.md` line 11 — 6 passed / 0 failed
at this very hash.
⚠ Carry §9 with any citation: no build, no suite, and it did NOT attack a multi-latch/irreducible
loop body against the back-edge clause, the 512-block budget's decline path, or a
round-2-only-tainted theta in the gap.

**Item (2), the F′ × P′ composition: REVIEWED — and that review CREATED the residue.**
The round's subject WAS the composed binary, so the bead's question as written is answered. Its
answer is **R-2, a FINDING**: the composed ACCEPT surface is **not empty**, falsifying
`COMPOSITION.md` §4 by construction. Mechanism, one line of the pipeline: every F2 decline is FATAL
to the module (`DS_Error` → `LLVMContext::diagnose` EXITS, bd `br4a`), so F′ can only turn a DEAD
module into a LIVE one ⇒ **every F′ × P′ composition is MODULE-level, not shape-level**, and both
tracks searched only the shape-level surface.

⚠ **The residue, in the gate's own words** (`$PREV/armgate/FIXES.md` R-2): *"This gate did NOT
re-derive `c1`/`c2`. It records them and states their clearance status: **cleared by measurement, by
no review**."* Both are clean by the project's strongest witness (byte-identical twins 27 = 27 and
29 = 29 trace lines; `c2` K-independent at 99 lines for K = 3 and K = 1000; STRICT 2b clean) — which
is **exactly** the evidence Rule 2 calls necessary and not sufficient.

The residue was **rehomed, not dropped**: the process half onto bd `oej0` (appended 2026-09-15), the
REVIEW half onto CLAUDE.md §5's "Owed as a REVIEW" line, which **at HEAD still names it**. Closing
`hlhh` today would leave that sentence with no bead behind it, so Wave 0-B left it open and said
precisely what it now carries: **an independent Rule-13 round on `c1`/`c2` themselves** — a second
round on the two accepts the first round produced.

---

## 5. THE SWEEP

Method (per brief): `bd list --status open | grep -iE "loop|rail|fence|matrix|instrument|vacu|census"`
plus `bd list --status in_progress`, minus the do-not-close set and the Wave 0-A cluster
(`rpkr`, `gfsk`, `rixk`, `19vy`, `1739`, `jdec`, `gzgs`) ⇒ **57 beads**. For each,
`git log --oneline main --grep="<id>"`, then a second pass for commits SCOPED to the id
(`fix(<id>)` / `feat(<id>)`) and a third for close/land/discharge language, then a fourth over
in-source mentions (`grep -rn "bd <id>" ir-pass/src ir-pass/include tools`).

**17 beads have no main commit at all**: `1ro3 1yeu 3hf1 3qlq.12 3qlq.6 b7ai boj5 drbq.15 f8eu f8ov
hlhh hqor juck onq1 qxkl r9ws yldg`.

**Only two beads have a commit scoped to them by name**, and both were already in hand:

```
3c6m.49 :: 469cfb64 feat(3c6m.49): full-surface libm injection census — real openlibm = 2/120 compile
kqqv    :: 2a25ca94 fix(kqqv): canonicalizePred stranded a non-root shield — one entry-walk closes the orphan class
```

`3c6m.49` is a **live campaign tracker** (its title carries a moving number, "2/120 at the
2026-07-11 anchor, 97/123 today"); the commit CREATED the census, it did not close the bead.

The close/land/discharge scan returned 22 rows; **every one is a commit that FILED the bead, that
closed a DIFFERENT bead, or that merely mentions it**. Spot-checked and left open, correctly:
`r903` (`7203d1c1` landed only part **(b)**; CLAUDE.md §2 still names `r903` as the discriminator for
the `trunc`/`zext`/phi/argument `i1` residuals), `boi6` (its own notes: D-B landed `59ac5b7`, **D-A
the loop-carried header φ remains**), `iwr7` (`PredMuxFlatten.cpp:3491` — *"STILL SHIPPING"*),
`thqy`, `ut09`, `54ur`, `fg9k`, `xqgx`, `8h7d.1`, `3qlq.9`, `67n5`.

### Sweep table (rows with any signal; the other 41 are "mentioned only / no signal")

| id | main commits found | disposition |
|---|---|---|
| `8h7d.6` | `95949550` (by `git log -S 'tmpl_minted'`) | **CLOSED — landed, verified by measurement** (§5a) |
| `58tc` | `RotationLowering.cpp:1868` claims `8h7d.5` closes it | **NOTE, left open — the claim is measurably false** (§5b) |
| `kqqv` | `2a25ca94` (fix), `134e625c` (round) | verified fixed; close refused (blocked) |
| `drln` | `134e625c` | 5 of 6 discharged; C2 open |
| `3c6m.49` | `469cfb64`, `0e0455b5`, `db4d29b2` | campaign tracker, not a landing — left open |
| `r903` | `7203d1c1` + 4 docs | part (b) only — left open |
| `boi6` | `59ac5b7` + 5 | D-B landed, D-A open — left open, already noted on the bead |
| `iwr7` | `2a25ca94`, `134e625c`, +1 | source says STILL SHIPPING — left open |
| `3c6m.59` `3c6m.62` `3c6m.64` `3lro` `sj30` | various `chore(beads)` / `chore(census)` | the commits that FILED them — left open |
| `3qlq.9` `3qlq.12` `3qlq.13` `67n5` `1dbk` `drbq.*` `e5ha` `w71q` `xtmk` `8hce` `jj3o` `ogwt` `vomf` `yc3a` `rhwb` `c6yw` `ixhy` `j31l` `iw81.13` `67s8` `8h7d.1` `8h7d.8` `ut09` `thqy` `54ur` `fg9k` `xqgx` `1yeu` | mention only | left open, no note owed |

### 5a. `8h7d.6` — CLOSED (the sweep's real find)

The bead: *"free_pairing_check leak census counts `cqrt_alloc` mints only — template-minted rails
are invisible"*, with three WORK items. All three are on main, landed in `95949550`
(`git log -S 'tmpl_minted' -- tools/free_pairing_check.py` names exactly that commit):

1. **Census widened** — `Census = namedtuple(..., ['minted','leaked','tmpl_minted','tmpl_dirty',
   'unresolved_callgraph'])`; `left_dirty` reuses `census_03_orphan_rails.py`'s UNDISCHARGED
   definition **verbatim** (Rule 14). `cqrt_qram_load_<W>` counted; `cqrt_tape_write_<W>` excluded
   **by name** (`_TAPE_MINT`) because the 7.6 tape is kept by design — visible, not silent.
2. **Separate line** — `free_pairing_check.py:2830-2831`.
3. **Mutant in the selftest** — `tools/free_pairing_check_test.py` gained layers 2e/2f on this
   bead's own reasoning (`:2039-2042`: *"a mutant layer keyed on finding codes scores a census that
   reports twice the truth as a pass ... an instrument's failure mode is to report a pass"*), with
   cases pinning both `0 template rail mint(s) of which 0 left dirty` and `1 ... 1 left dirty`.

**Measured live on the exact module the source names** — the owner's headline slice, whose
`h6 = cq_template_add_i32_hl(h2, -3)` is minted, never reversed, never freed, never measured:

```
$ python3 tools/free_pairing_check.py <lowered slice_control_cascade_three_bools>
free_pairing_check: 1 file(s), 9 rail mint(s) of which 7 left allocated,
  2 template rail mint(s) of which 1 left dirty, 3 cqrt_free site(s):
  3 verified, 0 violation(s), 0 unproven
```

The number that was **zero by construction** is 1. The alloc half is unchanged from CLAUDE.md §4c's
recorded STRICT 2b line for that slice (9 / 7 / 3 verified / 0 / 0), so the bead's "no slice should
FAIL" condition holds.

⚠ **Attribution, so the record is straight:** the source comment at `:2519` credits this to
*"bd 19vy / bd 1739 hole 1"*, not to `8h7d.6` — **the same defect was carried under three ids**.
`8h7d.6` closes on its OWN work being done; whether `1739`'s SECOND half (the forward/`_unc` LITERAL
DIVERGENCE hole) also landed is **not decided here** and belongs to Wave 0-A, which owns
`1739`/`19vy`/`rixk`.

⚠ **Downstream:** bd `boj5` ("5048 left-dirty TEMPLATE-MINTED rails are now visible to stage 2b for
the first time") stays OPEN and is the adjudication this bead explicitly deferred.

### 5b. `58tc` — NOTE, left open, and it CONTRADICTS THE RECORD

Three measured corrections, and two of them make the bead look closed when it is not.

**(i) The severity changed: this is no longer an over-decline.** The diagnostic is now a **WARNING**
(owner ruling bd `lyyf`), so every program in the class lowers at exit 0. The bead's title and
**CLAUDE.md §5's "Over-declines" list** are stale in that word. The shipped fixture was inverted in
place and says so on line 1: `lowering_reject_live_record_post_gate_record_loop.ll — WARNING (was
DECLINE)`.

**(ii) The bead's own witness no longer witnesses anything — and not because it was fixed.** Ran the
description's program verbatim in three spellings:

| spelling | rolled? | exit | stderr |
|---|---|---|---|
| `K=3` (as written) | **no — `clang -O1` fully UNROLLS it**, so it never tested the back edge | 0 | **0 bytes** |
| `K=100` | yes | 0 | 0 bytes |
| runtime trip count `n` | yes | 0 | 0 bytes |

Lowered module **K-independent** at 73 lines for K = 100 and K = 1000; the rolled `n=3` trace is
**raw byte-identical** to the unrolled K=3 trace, 18 = 18 lines; STRICT 2b clean. It is silent
because the program contains **no post-gate derived record at all** — `w = q*2` is minted *before*
the chained theta and is that theta's own target.

**(iii) The claim is still live.** Add the one line the class needs (`int z = q*3;` after the gate):

| probe | stderr |
|---|---|
| `z` never observed | **WARNS** (441 B, 2 warnings) |
| `z` OBSERVED in body (`cq_measure(z)`) | **WARNS** (437 B) |
| `z`, `q` and `w` **all** observed in body | **STILL WARNS** (445 B) |

The third is decisive and is this bead's sentence restated: an in-body observation does not exempt a
record inside a loop body.

⚠ **AND THE SOURCE CLAIMS OTHERWISE, IN TWO PLACES.** `RotationLowering.cpp:1868` opens
`recordAbsentAt` with *"bd `test_C_libtooling-8h7d.5` (**closing bd 58tc**)"*, and clause 3 at
`:1951-1953` says *"PER ACTIVATION, same barrier and same reason as clauses 2/4 above (bd 8h7d.5 /
58tc)"*. The per-activation machinery **is** there (`provablyBeforePerActivation` replaced the bare
`provablyBefore` in clauses 2, 3 and 4), yet probe (iii) shows the exemption does not happen. Either
the citation is over-claimed or the residual has a second cause. **Wave 0-B did not root-cause it
and does not guess** (brief: a bead you cannot settle gets a note). The shipped fixture's own HONEST
SCOPE paragraph still states the bead verbatim and promises it *"becomes the isolating witness for
free"* once clause 3 is loop-aware — **that promise has not been collected**. This is an L7-shaped
record defect: a source comment asserting a bead is closed, unmeasured, hardening by repetition.
Adjacent to bd `bbu0` (is `warnLiveRecordRotations` the site the class should be DECLINED at?) and
should be decided with it.

---

## 6. Protocol compliance (§6.1, redundancy)

* **Cited, not run:** the six slot-test tripwire fixtures — `$THIS/GATES.md` line 11, `claude`,
  2026-09-17 10:50, at hash `9bd01598d574b344`. No second run started.
* **Announced before running:** the only gate longer than a single fixture was the kqqv 6-fixture
  `lit --filter` batch. `IN-FLIGHT` appended to `$SES/GATES_INFLIGHT.md` at 11:42, `DONE` appended
  with the result. No matching IN-FLIGHT line existed for it at that hash when it started.
* **Deferred to avoid collision:** `e2e-free-pairing-selftest` and
  `e2e-loop-twin-quarantine-selftest` were IN-FLIGHT under wave0-A at this hash exactly when Wave
  0-B needed evidence about `free_pairing_check.py`. Wave 0-B did **not** start a second run and
  took its evidence from the per-probe pipeline instead.
* **No gate was run twice at this hash by this agent.** No `--force` on any bd operation.
