# Track I — MUTANTS: the instrument, made to fail on purpose

bd `test_C_libtooling-rpkr` (the BANK axis) · bd `test_C_libtooling-gfsk` (the header contract) ·
session 2026-09-15 · binary `0e280fc6` (bit-identical to the ORACLE).

Harness: `probes/mutate_instrument.py`. Each mutation removes ONE fix inside a COPY of the tree, runs
`tools/loop_twin_matrix_quarantine_test.py` there, and scores `CAUGHT` only when the run exits
non-zero **and** the cases that name the mutation are the ones that go red. "Something else failed"
is not a catch.

```
python3 docs/prd/.../trackI/probes/mutate_instrument.py
control: unmutated selftest is GREEN (loop_twin_matrix_quarantine_test: 52 case(s), 0 failure(s))
…
mutate_instrument: 13 mutation(s), 13 CAUGHT, 0 MISSED
```

## 0. ⚠ The first run was `9 CAUGHT, 4 MISSED`, and that is the part worth reading

A 27-case selftest going to 51 green cases is **equally consistent with 24 cases that assert
nothing** — which is why `CLAUDE.md` L10 says the only instrument worth citing is one that has been
made to fail on purpose, and why its ⚠ block records six measured instances that landed in one
session, every one found by the agent that owned the instrument and none by a green suite. Four of
this increment's own cases were in that state and the harness is what found them:

| MISSED on round 1 | the hole | closed by |
|---|---|---|
| **M2** the floor asked of the ROLLED side only | every negative I had written was rolled-thin (`_THIN_M, _FAT`) or thin-on-both. A twin that is thin on the **UNROLLED** side alone was tested by nothing, so the natural half-measure passed | **NEG-19** `only the UNROLLED side is thin` |
| **M5** the bank cells dropped from `cells_of_matrix()` | every case installs its own cell list, so `bank_cells()` could be complete, `BANK_FLOOR` perfect, and the axis never run. That is bd `rpkr`'s own sentence — *no existing cell can see a rail bank* — recreated by deleting one token | `case_floor_covers_the_axis` now asserts every bank name is **in `cells_of_matrix()`**, using the real function captured before any stubbing |
| **M3** `BANK_FLOOR = {}` | caught, but at **import** (`_floor_is_a_lower_bound` raises `KeyError`) rather than by a case, so the harness's case-id needle matched nothing and scored it MISSED | the expectation now names the exception. The catch is real and *stronger* than a case — the module cannot load — and recording it as such beats tidying it into a case |
| **M4** every floor lowered to `(1, 1)` | same: caught at import by the derivation check (`floor 1 < 3 cq_measure call sites`) | same |

M3 and M4 are the reason the floor's numbers are **derived from the generated source** rather than
chosen: `_floor_is_a_lower_bound()` re-derives each cell's `cq_measure` call-site count at import and
refuses a floor below it, so a future edit that deletes a measurement from the program cannot leave
the floor behind pointing at nothing.

## 1. The mutation table (final: 13 / 13 CAUGHT)

### bd `rpkr` — the BANK axis's non-vacuity floor

| # | what it breaks | caught by |
|---|---|---|
| **M1** `floor = None` in `verdict()` | the floor check is deleted: a bank pair whose two traces **both** lost the user's measurements goes back to `ACCEPT-IDENTICAL` | NEG-15, NEG-16, NEG-17, NEG-18 |
| **M2** the floor asked of the ROLLED side only | the natural half-measure, defeated by a thin UNROLLED twin | NEG-19 |
| **M3** `BANK_FLOOR = {}` | every bank cell unguarded — the `checked 0` hole in this instrument's clothes | import: `KeyError: 'm_none_kprep_none_none_kflat'` |
| **M4** every floor lowered to `(1, 1)` | satisfiable by a trace that has already dropped both bank measurements | import: `floor 1 < 3 cq_measure call sites` |
| **M5** `cells = base + rec + ry + f + b` | the axis exists in the file and never runs | `case_floor_covers_the_axis`: `21 bank cell(s) are defined but NOT in cells_of_matrix()` |

### bd `gfsk` — the header contract

| # | what it breaks | caught by |
|---|---|---|
| **M6** `--regenerate` writes `EXPECTED_HEADER` over the file | **THE ORIGINAL DEFECT, restored**: every hand-added line deleted, success reported | POS-4 |
| **M7** the same in `write_quarantine` | the other write mode, which had the same shape and needed the same fix | POS-5 |
| **M8** an unmarked file is SEEDED instead of refused | the comfortable-looking choice, and the one that destroys the evidence | NEG-10, NEG-11 |
| **M9** the post-write read-back deleted | the writer reports its own success without checking it — L10's failure mode verbatim | the `write_preserving_header, made to fail twice` guard |
| **M10** the marker check dropped from PLAIN runs | the gate stays green while the next write mode is already armed | NEG-12, NEG-13 |
| **M11** the marker stripped from a COMMITTED table | the state every table in this tree was in until 2026-09-15 | `the four COMMITTED tables carry the marker` |

### the harness's own scaffolding

| # | what it breaks | caught by |
|---|---|---|
| **M12** the empty-matrix guard removed | a matrix with no cells reports a tidy pass — the `0 mutations, MISSED 0` hole | `an EMPTY matrix exits 2, never 0` |
| **M13** `install_bank` stops restoring `cell_name` | ⚠ **MEASURED FOR REAL DURING THIS INCREMENT, not invented.** `install()` replaces `M.cell_name` with an identity stub; without the restore, `BANK_FLOOR.get("none")` is `None` and **four floor cases went green against a fence that was never consulted** | NEG-15, NEG-17 |

M13 is in the table because it happened: the four floor cases were written, run, and reported green
*before* the stub leak was noticed. A selftest whose scaffolding disarms the thing it tests is the
same defect class as the injection matrix that ran `FileCheck --check-prefix` and dropped the RUN
line's `--implicit-check-not` flags — **a harness that runs a weaker command than the gate measures
itself, not the gate.**

## 2. The harness's own anti-holes

Written in because three of L10's six instances were harnesses that reported a pass on no input:

* **zero mutations exits 2**, never 0 (`n/a`, `checked 0` and `0 mutations` are holes);
* **an anchor that is not found exactly once exits non-zero** rather than scoring MISSED — a drifted
  anchor measures the harness, not the fix;
* **the unmutated copy is run FIRST** as a positive control and the whole run is refused if it is not
  green, because a selftest that is already red "catches" every mutation for the wrong reason;
* **every mutation must change the file** — a no-op replacement is refused;
* the copy is a **mirror of the tree**, not of `tools/` alone. The first run gave the selftest a
  truncated tree, `case_real_header` and `case_committed_tables_are_marked` failed under *every*
  mutation, and every mutation would have scored CAUGHT for a reason that had nothing to do with it.
  That is the *45 MISSED against fixtures that catch everything* failure with its sign flipped, and
  it was hit here on the first run.

## 3. What the mutants do NOT establish

They establish that each fix is **load-bearing for the selftest**. They do not establish that the
selftest's *synthetic traces* resemble what the compiler emits — the module docstring says so in
writing, and the real 359-cell run is what measures. And nothing here is a statement about a unitary
(Rule 2).
