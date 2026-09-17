# Wave 0-A — closing seven instrument beads BY MEASUREMENT on the ORACLE

**Session 2026-09-18 (orchestrated). Agent: wave0-A. Main checkout. No build, no source edit, no commit, no push.**

ORACLE verified before any measurement:

```
$ shasum -a 256 build/ir-pass/cq-opt
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt
```

matches `$SES/PROTOCOL.md`'s block. `git merge-base --is-ancestor 95949550 main` -> YES;
`7448fa2900e7040f` = *"fix(instruments): bd rixk, 19vy, 1739, jdec, gzgs"*,
`2095ab442f40e270` = *"feat(instrument): bd rpkr the BANK axis (338 -> 359 cells) + bd gfsk the header contract"*,
`e90248a363c749db` = *"test(instrument): bd rpkr x bd xdu2 — the deliberate Rule-12 regeneration of the 15 moved BANK cells"*.

Every gate line is in `GATES_A.md`, hash-keyed. Nothing below is cited from another track; wave0-A ran all of it.

---

## 1. `test_C_libtooling-rpkr` — the BANK axis — **CLOSED**

```
$ grep -c '^m_'    tools/loop_twin_matrix.expected.txt      -> 330
$ grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt    ->  29     (total 359)
$ python3 -c "... bank_cells() ..."                         ->  21 cells
$ python3 -c "... cells_of_matrix() ..."                    -> 359 cells
```

All 21 bank-cell names carry the five-segment form and all 21 appear in the committed expected
table (0 in the quarantine). The sub-grid assertion inside `cells_of_matrix()` is
`(120, 36, 118, 14, 50, 21)` and it did not fire.

**Single-cell runs against the ORACLE** (no `--filter` CLI exists, so the module was imported and
`run_cell`/`verdict` called on one cell at a time — this is NOT the ~11-minute `e2e-loop-twin-matrix`
gate, which stays the merge-and-gate agent's):

| cell | measured | committed |
|---|---|---|
| `m_none_kprep_none_none_kflat` | `ACCEPT-IDENTICAL` | `ACCEPT-IDENTICAL` |
| `m_none_k2b_none_none_kflat` | `ACCEPT-IDENTICAL` | `ACCEPT-IDENTICAL` |
| `m_none_kiprep_none_none_kflat` | `UNROLLED-ONLY cq rail bank: array mixes a rail cell access with an unrecognized one` | same |
| `m_none_kidx_none_none_kflat` | `DECLINE-BOTH cq QRAM access: array address has aliasing fan-out` | same |

4/4, `report=None` on each (no harness break, no divergence).

Two of the quarantine selftest's own guards cover the axis's stated holes and both pass:
`[guard] BANK_FLOOR covers the whole bank axis` and `[guard] an EMPTY matrix exits 2, never 0`
(the latter is the *"dropping the bank cells from `cells_of_matrix()` was caught by nothing"*
mutant the bead's notes call out, now wired in).

⚠ **NOT WHAT THE BEAD'S NOTES SAY.** The notes record *"MEASURED ON THE ORACLE 0e280fc6: EVERY bank
cell declines — 9 UNROLLED-ONLY / 9 DECLINE-BOTH / 3 DECLINE-BOTH-DIFFERENT"*. On the committed table
today **2 of the 21 are `ACCEPT-IDENTICAL` and 3 are `ROLLED-ONLY`** — the rail-bank accept (bd `xdu2`
/ L-1a) landed in the same session and commit `e90248a3` deliberately regenerated the 15 moved cells.
The notes describe the axis at the moment it was built, not at HEAD. That is a record-vs-HEAD drift,
not a defect.

## 2. `test_C_libtooling-gfsk` — the `--regenerate` header contract — **CLOSED**

The marker is `HEADER_END_MARKER`, three `# ====` lines, and it is present in **all four** committed
tables (`expected.txt:459`, `quarantine.txt:175`, `expected.register.txt:229`,
`quarantine.register.txt:126`).

Measured on **copies in the scratchpad** (the real tables were never written; `sha256` of
`tools/loop_twin_matrix.expected.txt` is `29358b2437ef3d3f80bbbe5f591b22da9c6afa19c89ab4b1ff56273632aa2326`
and the probe did not touch it):

* **marker stripped** -> `resolve_header` returns `header=None` + a REFUSAL beginning
  `REFUSED: <path> has no END-OF-HEADER marker, so this run cannot tell your prose from the script's
  — and it will not guess.`, and the file's sha256 is **identical before and after** (`38d5da071f7c24ce`).
  `main()` prints that refusal and `return 1`.
* **marker + hand prose** -> `preserved 462 header line(s) of copy_marked.txt byte-for-byte`;
  after `write_preserving_header` the hand-added line is still there and the generated body was replaced.
* **missing file** -> seeded, and the seed **carries the marker** (contract rule 4).

End-to-end, `--regenerate` exit 1 on an unmarked table is pinned by the instrument's own gate rather
than by an 11-minute matrix run:

```
$ ctest --test-dir build -R '^e2e-loop-twin-quarantine-selftest$'   -> Passed 2.42 sec
$ python3 tools/loop_twin_matrix_quarantine_test.py                 -> 52 case(s), 0 failure(s)
```

with, on **both** `register` and `void` surfaces: `NEG-10 --regenerate, expected table has NO marker`,
`NEG-11 --refresh-quarantine, quarantine has NO marker`, `NEG-12 a PLAIN run over a table with NO
marker`, `NEG-13`, `POS-4 --regenerate PRESERVES hand-added prose`, `POS-5`, `POS-6 SEEDS a table that
does not exist`, plus `[guard] write_preserving_header, made to fail twice` and
`[guard] the four COMMITTED tables carry the marker`.

## 3. `test_C_libtooling-rixk` — the census counted static sites across inlined copies — **CLOSED**

The bead's own 11-line loop-free probe, through the per-probe pipeline on the ORACLE:

```
$ grep -c 'call i32 @cqrt_alloc' s2.ll                              -> 6      (static sites, unchanged)
$ python3 tools/free_pairing_check.py s2.ll
free_pairing_check: 1 file(s), 3 rail mint(s) of which 3 left allocated, 0 template rail mint(s) of which 0 left dirty, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven
$ ./a | grep -c cqrt_alloc                                          -> 3
```

**6 -> 3, and 3 == the trace.** The bead's documented contract (*"The bead's probe goes 6 -> 3"*) is met
exactly. The pre-fix checker (`git show 95949550^:tools/free_pairing_check.py`) on the identical
`s2.ll` still says `6 rail mint(s) of which 6 left allocated`, so the delta is the fix and not the binary.

**The regression pin the bead names holds byte-for-byte.**
`tests/e2e/slice_control_cascade_three_bools.c` -> `9 rail mint(s) of which 7 left allocated, …,
3 cqrt_free site(s): 3 verified, 0 violation(s), 0 unproven`, against a golden carrying exactly 9
`cqrt_alloc` and 3 `cqrt_free` lines. Pre-fix and post-fix agree on every one of those numbers.

Nineteen named `CENSUS_CASES` in `free_pairing_check_test.py` pin the rule directly —
`rixk-inlined-dead-body (3,3)`, `rixk-control-callee-called (3,3)`, `rixk-inlined-AND-called (6,6)`,
`rixk-address-taken-is-live (6,6)`, `rixk-indirect-counts-all (6,6, unresolved=True)`,
`rixk-no-main-both-entries`, `rixk-cycle-with-no-entry`, `rixk-no-main-cycle-counted` — and
`ctest -R '^e2e-free-pairing-selftest$'` Passed in 10.34 s (`19 census case(s)`, `0 failure(s)`).

## 4. `test_C_libtooling-19vy` — 2b blind to the F x P value arm's leaked TEMPLATE rail — **CLOSED**

The census line now carries a template segment that did not exist before:

| module | PRE-FIX (`95949550^`) | HEAD |
|---|---|---|
| `j_gzgs_x5b_LIVE_merge` (the F x P value arm) | `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified` | `… 6 left allocated, **1 template rail mint(s) of which 1 left dirty**, 2 … verified` |
| `slice_control_cascade_three_bools` (owner's headline slice) | `9/7, 3 verified` | `9/7, **2 template rail mint(s) of which 1 left dirty**, 3 verified` |
| trackT `s3_live_rootmint_region` / `_un` | `2 rail mint(s)`, no template segment | `1 rail mint(s)`, **`2` / `4` template rail mint(s), 0 left dirty** |

The rail the bead names is visible in the trace at line 17: `cq_template_add_i32_hl(h3, -3) -> h6`
— minted, never `_unc`'d, never freed, never measured. It is now **counted and reported** (reported,
never failed on — deliberate; see the checker's own §(2) note and bd `s82e`).

## 5. `test_C_libtooling-1739` — blind to TEMPLATE mints and to forward/`_unc` literal divergence — **CLOSED, with one correction to the filing**

**Hole 1 (template mints):** closed, same evidence as §4.

**Hole 2 (literal divergence):** closed for the `undef`/`poison` spelling, which is the half that was
genuinely open:

```
$ python3 tools/free_pairing_check.py …/j1739_undef_pairing.ll
… UNPROVEN T1-undef-literal-pairing @f line 15 [%c]: rail minted at line 13 by
`%c = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 undef)` is paired with the _unc at line 14
ONLY BY OPERAND TEXT … 0 verified, 0 violation(s), 1 unproven
```

against the pre-fix checker on the same file: `1 verified, 0 violation(s), 0 unproven`, rc=0.
`j1739_undef_a2_bracket.ll` moves the same way (`A-undef-literal-pairing`), and the three real-literal
controls still verify clean, so the fix did not simply refuse every pair.

⚠ **THE FILED SPELLING OF HOLE 2 DOES NOT REPRODUCE, AND THE FIX IS NARROWER THAN THE TITLE.**
The bead says *"The checker matches rail HANDLES and never compares the LITERAL operands, so a
structurally perfect pair with divergent values reads as verified"*, with the example
`icmp_sgt_i32_hl(h0, 73896)` forward against `_unc(h4, h0, 1401299752)`. wave0-A built that module
(`divergent_literal.ll`) and **both the pre-fix and the HEAD checker refuse it**:
`UNPROVEN T1-no-reversal … (1 intervening write(s) …)`, rc=1. The literal comparison was already
there. What was open — and what `7448fa29` closes — is that a textual match is not a **value** match
when the text is `undef`, which is what the fix's own source header states. The bead's reproduction
was over *"the hg8s pairing probes"*, and **no `hg8s` probe exists anywhere in the tree**, so the
original claim cannot be re-checked against its own artifact. Recorded in the close reason.

## 6. `test_C_libtooling-jdec` — the vacuity script reported `checked 0` instead of failing — **CLOSED**

Replaced by `tools/negative_vacuity_check.py` (+ `_test.py`, + ctest `e2e-negative-vacuity-selftest`).
Three measured directions:

```
$ python3 tools/negative_vacuity_check.py                    # no argument
negative_vacuity_check: no fixtures given — nothing was checked, which is a HOLE, not a pass     rc=2

$ python3 tools/negative_vacuity_check.py <5 fixtures with NO '-NOT:' directive>
negative_vacuity_check: ZERO directives were evaluated over a non-empty batch — the matcher selected
nothing, which is a HOLE, not a pass (bd test_C_libtooling-jdec)
negative_vacuity_check: 5 fixture(s), 0 directive(s) evaluated, 0 VACUOUS, …  [cq-opt 9bd01598d574b344]   rc=2

$ python3 tools/negative_vacuity_check.py <25 real fixtures carrying '-NOT:'>
negative_vacuity_check: 25 fixture(s), 166 directive(s) evaluated, 0 VACUOUS, 0 decline-stdout note(s),
7 latent header collision(s), 9 declining module(s), 0 unparsed, 0 not-modelled …, 9 front-end-intrinsic
exemption(s), 31 unreachable-symbol note(s), …, 48 resolved by the universe, …, universe 16 module(s)
[cq-opt 9bd01598d574b344]                                                                          rc=0
```

The prefix-agnostism half is measured too: the findings it printed name `NOROUTE-NOT:` directives, not
the `(NOX|NOFREE)-NOT: … (i32 %handle)` form the dead script matched. The binary's sha256 is printed
with every verdict. The tool has **no hard-coded build path** (the one `/Users/` hit is a comment about
the defect). `ctest -R '^e2e-negative-vacuity-selftest$'` Passed 22.65 s; the selftest itself reports
`6 hole case(s), 4 positive(s), 10 mutant(s)/control(s), 0 failure(s)`.

The dead script confirmed dead from the main checkout:
`FileNotFoundError: [Errno 2] No such file or directory: '/Users/sorenwilkening/Desktop/CQ_mphi/build/ir-pass/cq-opt'`.

⚠ **THE BEAD'S LAST OPEN SENTENCE IS STILL TRUE AND IT IS TRUE OF *THIS* SESSION'S PROTOCOL.**
`$SES/PROTOCOL.md` §S3 still instructs every track to run
`$PREV/../session-2026-09-13-orchestrator/trackM/probes/impl/vacuity.py` and still describes the
defect as unfixed (*"⚠ That script is itself bd `jdec` … Track J is fixing it"*). The fix landed on
2026-09-15; the protocol copied forward on 2026-09-17 did not. This is the file's own top-of-file
lesson (*"a protocol copied verbatim carries its predecessor's measurements with it"*) recurring one
section lower down. Filed as a note on the bead and reported to the orchestrator; wave0-A did not edit
`PROTOCOL.md` (not its file).

## 7. `test_C_libtooling-gzgs` — m28 is a vacuous VALUE witness — **CLOSED, with a residual noted**

Both halves reproduced on the ORACLE, and **both traces are byte-identical to the traces committed
with the fix** (which were taken on the 2026-09-14 oracle `0e280fc6`, so this is a cross-binary
re-measurement, not a re-read):

```
j_gzgs_m28_VACUOUS_merge : opt exit 0, 29 trace lines, 8 rail mint(s) of which 6 left allocated,
                           1 template rail mint(s) of which 1 left dirty, 2 free sites: 2 verified, 0/0
j_gzgs_x5b_LIVE_merge    : opt exit 0, 28 trace lines, same census line
diff <m28 lines 6..29> <x5b lines 5..28>  ->  EMPTY   (downstream byte-identical)
```

The structural facts the vacuity argument rests on are all present in the m28 trace exactly where the
header says: lines 4-5 `cqrt_ry_i1(h1,0.5); cqrt_ry_i1_controlled(h0,h1,-0x1p-1)` (the negated-control
prep), line 19 `cqrt_toffoli(h0,h1,h7)`, lines 21/23 the two `cqrt_copy_i32_controlled` that are the
merge, and line 17 `cq_template_add_i32_hl(h3,-3) -> h6` (the §4 residual). x5b's sole difference is
one `cqrt_ry_i1_controlled(h0,h1,0x1p-1)` in place of the ry + negated pair.

`j_gzgs_m28_VACUOUS_merge.c` carries a 20-line header stating, in its own words, that the fourth region
*"is the IDENTITY on its whole reachable support, so it CANNOT witness the F x P composition's merge"*
and *"Cite it for THAT and never for the unitary."* The live twin sits beside it — the bead's
*"replace/**accompany**"* in the accompany reading.

⚠ **TWO RESIDUALS, both deliberate and both now recorded on the bead:**

1. **No `fp_x5b`-derived witness exists in `ir-pass/test/` or `tests/e2e/`.**
   `grep -rln 'gzgs|fp_x5b|x5b|m28'` over both directories returns **nothing**. This is a written
   decision, not an omission — the probe header says *"NOT PROMOTED TO AN e2e SLICE, deliberately …
   the F x P composition still has NO RULE-13 OPINION"*, and `CLAUDE.md` §5 already carries that
   Rule-13 opinion as **owed**. There is therefore no `lit --filter` to run for this bead.
2. **The correction landed in a new COPY, not in the cited files.** `MERGE_FILINGS.md` §2 and
   `MERGE_REPORT.md` §5b cite `fp_m28.c`; that file
   (`session-2026-09-14c-xdu2-w1/trackX/probes/fp_m28.c`, 299 bytes) and the original
   `session-2026-09-13-orchestrator/trackM/probes/m28.c` carry **zero** occurrences of
   `gzgs`/`vacuous`/`VACUOUS` and no pointer to the live twin. A reader following the citation lands
   on an unmarked file. This is `CLAUDE.md` L7-with-a-twist in its mildest form (the correction exists,
   it just is not where the citation points). Those are sealed session records, so wave0-A did not
   edit them; it is reported instead.

---

## Method note (Rule 19)

Everything above is a command wave0-A ran on the binary whose sha256 is `9bd01598d574b344…`. No layer
was reported that was not executed. `ir-pass-lit`, `^e2e-`, the full `ctest`, the equivalence sweep,
the corpus sweep and `e2e-loop-twin-matrix` were **NOT** run and are not claimed. Per §6.1 the three
`ctest` entries were announced in `$SES/GATES_INFLIGHT.md` before starting and their results appended
after; no matching IN-FLIGHT line existed for any of them at hash `9bd01598` when they were started.

---

## Addendum — CLAUDE.md's "Counts" line is stale at HEAD (measured, not quoted)

`CLAUDE.md` records its counts "measured 2026-09-15 at the ARM group gate" and tells the reader to
re-measure rather than quote. wave0-A re-measured them (all read-only; `ctest -N` runs nothing):

| item | command | CLAUDE.md | HEAD `cff8f7ac` |
|---|---|---|---|
| ctest entries | `ctest --test-dir build -N` | 442 | **457** |
| `^e2e-` | `ctest -N \| grep -cE 'Test +#[0-9]+: e2e-'` | 432 | **447** |
| `^e2e-slice-` | same, `e2e-slice-` | 381 | **390** |
| `twin-identical` | same, `twin-identical` | 40 | **43** |
| fixtures | `ls ir-pass/test/*.ll \| wc -l` | 2047 | **2082** |
| goldens | `ls tests/e2e/*.expected.log \| wc -l` | 383 | **392** |
| twin-matrix cells | `grep -c '^m_' … + grep -c '^cell ' …` | 338 | **359** |

Every move is in the growth direction and is accounted for by the 2026-09-15 landings the ARM-group
measurement predates. Not a defect; handed over so the next `CLAUDE.md` touch has fresh numbers.

**One string-level drift worth naming.** `CLAUDE.md` §4c (line 1104) quotes the owner's headline
slice's stage-2b line as `9 rail mint(s) of which 7 left allocated, 3 cqrt_free site(s): 3 verified,
0 violation(s), 0 unproven`. Every **number** in that quote is still exact — bd `rixk`'s regression
pin held, as its close reason records — but the **printed line** at HEAD now inserts
`2 template rail mint(s) of which 1 left dirty` between the two halves, because of bd `19vy`/`1739`
hole 1. A future reader byte-comparing that quote against a fresh run will see a mismatch that is a
capability gain, not a regression. Deliberately NOT edited by wave0-A (`CLAUDE.md` is not its file).
