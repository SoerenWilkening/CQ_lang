# FINAL INTEGRATION GATE — session 2026-09-15, branch `verify-integration`

Worktree `/Users/sorenwilkening/Desktop/CQ_VERIFY`, HEAD `7c19b234` (the union of six branches).
**Every line below is `ran:` unless marked `cited:`.** Nothing in this file is inherited from a track's
`GATES.md`; the one place a track number appears it is labelled as a cross-check, not as evidence.

## Binaries

| label | `cq-opt` sha256 | `libCQPass.so` sha256 |
|---|---|---|
| **SUBJECT** (merged, this gate) | `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3` | `3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d` |
| **ORACLE** `main` `74eabd2c` (read-only) | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` |

`ran:` **ORACLE hash re-verified at gate open AND at gate close — BOTH files, unmoved, character-for-character
identical to `PROTOCOL.md`'s corrected oracle block. Nobody rebuilt the oracle.**

`ran:` **the third false-green form (a `cq-opt` that segfaults while `libCQPass.so` from the same build works)
was discriminated before any gate**: `ir-pass/test/lowering_basic.ll` through `build/ir-pass/cq-opt` and through
`opt -load-pass-plugin build/ir-pass/libCQPass.so` — both exit 0, both 726 bytes, lowered IR identical modulo
`ModuleID`. ⚠ **My FIRST spelling of that check was VACUOUS** — the `clang` step failed on a bad path with stderr
suppressed, and the `diff` then compared two files that did not exist and printed a PASS. It is recorded here
rather than quietly re-run, because it is CLAUDE.md **L10** in the first instrument this gate built.

`ran:` `cmake --build build -j4 --target CQPass cq-opt` before the equivalence gate → `Built target` for both,
**hash unchanged** (`9bd01598…`). The tree was already built; **this gate changed no source and rebuilt nothing.**

---

## THE GATES

### 1. full `ctest --test-dir build -j6 --output-on-failure` — **RED (1 of 457)**

`ran:` @ `9bd01598` · **456/457 passed, 1 FAILED** · `Total Test time (real) = 583.82 sec` ·
load 5.99 at start, **peak 351** mid-run, 2.52 at end.

```
457/457 Test #318: e2e-loop-twin-matrix ...........................***Failed  334.27 sec
99% tests passed, 1 tests failed out of 457
```

⚠ **The load peak is MINE and not a competitor.** `ps -eo pid,ppid,%cpu,etime,comm` taken at load 274 showed
every top consumer to be this run's own `cq-opt` / `clang` / `FileCheck` out of `CQ_VERIFY`. In particular the
non-terminating `cq-opt` PID 84129 in `CQ_T` that two agents recorded earlier (492 CPU-minutes) **is gone** — it
does not appear in the process table. So the timing is dilated by `-j6` plus `ir-pass-lit`'s own 12 lit workers,
and by nothing else. **No red was re-run serially because there is only one red and it is deterministic and
attributed** (§4).

### 2. `cq-opt-equivalence-full` — **GREEN**

`ran:` @ `9bd01598` · `cq_opt_equivalence: compared 2082 fixtures, 0 mismatch(es)` · binary sha256 **unchanged
before and after**.

This is the gate the brief says is **owed three times over**, and it discharges all three at once, on the composed
binary: Track B's two new decline strings plus the arm that stopped declining, the rail-bank fix's third string
whose population now reaches memory-resident readers, and Track E2's narrowing of the undef-measure string.
**It had never been run for Group 1 in any form** (`trackE2`, `trackB` and `bfix` all record it as owed; the loop
group and the arm group each ran their own).

### 3. ONE corpus sweep vs the ORACLE, FULL-STDERR hashed — **GREEN, 0 unattributable**

`ran:` @ `9bd01598` vs `0e280fc6` · `sweep OK: rows=6165  rows-with-an-accept=3602  rows-with-a-decline=2733  exit127=0`

Corpus = `ir-pass/test/*.ll` (2082) + every session's `track*/probes` and `review_*_probes` (4112) = **6194 inputs,
6165 rows** (29 are `*_lib.c` link partners, skipped by design). **This closes ROUTING R3's residue by measurement
rather than inheriting its structural argument** — the previous sessions swept 2088 of 5455 and R3 records that the
argument for the residue's immobility subsequently LOST.

**The PROTOCOL S3 blind spot is closed by construction, not by a follow-up pass:** a decline row is
`D:<exit>:<sha256-12 of the FULL stderr>`, never the shared `corpus.sh` tag regex, so a decline→decline change
**inside** the `cq_measure_<sfx>` family — which that regex renders as an empty `D:` — is visible here. It is not
hypothetical: **7 rows moved with a BYTE-IDENTICAL diagnostic string** and are only visible this way (§ATTRIBUTION F-4).

⚠ **The sweep refuses to report a pass it has not earned**, and the refusal is self-attacked:
`ran:` a driver with the ORACLE path replaced by `/nonexistent` **exits 2** with `REFUSE: missing/non-exec …`.
It asserts, before emitting a file: both binaries and both plugins exist and are executable; the ORACLE sha256 is
the frozen one; the corpus list is non-empty; **no row is exit 126/127**; **both verdict classes occur**; and each
stage-1 module is **non-empty** (a 0-byte `.ll` ACCEPTs through the passthrough early-out). Those are the three
traps the brief names, plus the two the session already paid for.

### 4. `e2e-loop-twin-matrix` — **RED: 15 cells moved, ALL of them BANK cells, ALL attributed**

`ran:` inside gate 1 @ `9bd01598` · `FAILED (15)` · 359 cells — `163 ACCEPT-IDENTICAL · 1 ACCEPT-IDENTICAL-WARN ·
55 DECLINE-BOTH · 44 DECLINE-BOTH-DIFFERENT · 3 ROLLED-ONLY · 29 TRACE-DIVERGENCE · 64 UNROLLED-ONLY`.

**THE BISECT — and it needed NO rebuild.** `tools/loop_twin_matrix.py` takes `--opt` / `--plugin` explicitly, so
the merged 359-cell table can be run against the **read-only ORACLE binary**:

`ran:` `loop_twin_matrix.py --opt <ORACLE>/build/ir-pass/cq-opt --plugin <ORACLE>/build/ir-pass/libCQPass.so
--phi-surface void --jobs 4`, expected table = the MERGED one → **exit 0**,
`all cells match loop_twin_matrix.expected.txt; all 29 quarantined cells diverge with their pinned signature;
both boundary controls as pinned`, 359 cells `161 AI · 1 WARN · 62 DECLINE-BOTH · 40 DECLINE-BOTH-DIFFERENT ·
29 TRACE-DIVERGENCE · 66 UNROLLED-ONLY`.

**What that proves, and it is stronger than reverting a merge would have been:**
1. Track I's merged table is a **correct ORACLE-baseline pin** — 359/359, including all 21 new BANK cells and both
   boundary controls. The axis is sound; there is **no version skew** and **no instrument defect**.
2. The 15 moved cells are caused **entirely by the merged COMPILER**, not by the table.
3. The class deltas reconcile exactly: `AI +2 · DECLINE-BOTH −7 · DBD +4 · ROLLED-ONLY +3 · UNROLLED-ONLY −2` =
   **15 changes = the 15 failures.** Nothing else in the matrix moved.

**Every one of the 15 is a `k*` cell — Track I's BANK axis — and every one pinned
`cq taint escape: tainted value stored to memory`, the exact string Track B's rail bank retires.** Full table in
`ATTRIBUTION.md` §F-1.

**This red is the instrument behaving as DESIGNED, and Track I wrote that down in the instrument** — quoted
verbatim from `tools/loop_twin_matrix.py`:

> TODAY EVERY CELL HERE DECLINES, and that is the axis working rather than the axis waiting: `kflat` cells are
> `UNROLLED-ONLY` (the rolled bank dies at `cq taint escape: tainted value stored to memory` while the scalarised
> twin lowers) and `kloop` cells are `DECLINE-BOTH` on that same string. The verdict strings PIN THE DIAGNOSTIC
> CHARACTER-FOR-CHARACTER, **so the accept's arrival is a red that must be regenerated deliberately with a written
> reason (Rule 12)** — the same instrument posture the 59 `UNROLLED-ONLY` Ry cells had before drbq Inc 3 flipped them.

**That is an L8 retirement trigger and it has fired.** The regeneration it requires is **OWED WORK THAT NOBODY
DID** — Track I pinned the axis on a binary bit-identical to the ORACLE, Track B never ran the matrix, and no
group gate covered both. It is a **missing deliverable, not a compiler defect**. ⚠ **This gate did not regenerate
the table**: it is an implementer's change under Rule 12 (it needs the written reason per cell), `--regenerate`
carries the bd `gfsk` prose-deletion hazard, and a gate that rewrites its own baseline is not a gate.

### 5. L8 duplicate-body fixture scan — **GREEN**

`ran:` @ `9bd01598` · 2082 fixtures, **three normalisations**, each duplicate's CLAIMED VERDICT read off its own
`RUN:` lines:

```
[exact-noncomment]      duplicate-groups= 9  files-in-groups=18  MIXED-VERDICT-GROUPS=0
[whitespace-normalised] duplicate-groups=13  files-in-groups=27  MIXED-VERDICT-GROUPS=0
[ws+moduleid]           duplicate-groups=13  files-in-groups=27  MIXED-VERDICT-GROUPS=0
TOTAL MIXED-VERDICT GROUPS ACROSS ALL NORMALISATIONS: 0
```

`ran:` the resurrection check L8 actually exists for — `git log --diff-filter=R` and `git diff --name-status`
over `74eabd2c..HEAD` for `ir-pass/test` and `tests/e2e`: **0 renames, 0 deletions**, 43 fixtures added, 19 e2e
files added. No `git mv`'d fixture can have been resurrected by this merge because **no fixture was moved.**

### 6. The three post-union checks on `tests/e2e/CMakeLists.txt` — **GREEN (re-run, not cited)**

`ran:` @ `9bd01598`:
```
grep -o 'add_test(NAME [A-Za-z0-9_-]*' … | sort | uniq -d   -> EMPTY  (0 duplicates)
grep -c '^add_test(NAME' …                                  -> 447
tail -3 …                                                   -> get_property(_E2E_ALL_TESTS …) /
                                                               set_tests_properties(…)  == still LAST
```
`ran:` the 2-line discrepancy against `grep -c 'add_test(NAME'` = **449** is reconciled: both extra occurrences are
**commented-out history** (`:5519` and `:5576`, the two `round2_window` slices the bd `3d8q` conversion
unregistered), not registrations. `ctest -N` **457** = 447 e2e + 10 non-e2e. This **reconciles exactly** with the
independent per-branch prediction of 447 line-start / 449 total / 457 ctest.

---

## THE F-5 PROBE — the composition nobody had reviewed

`MERGE_FILINGS.md` F-5: Track E2's clause (1a) and the rail-bank D5 allow-list both land in `lowerMeasures`
branch (1), the `!taint.Tainted.count(Handle)` classical split — **the exact site the rail bank exists to keep bank
loads OUT of**, where an untainted bank load emits no gate, no symbol and no trace line, invisible to the golden
byte-diff. E2's round verified **one** direction only.

**VERDICT: CLEAN — and closed structurally, not just empirically.**

`ran:` **the structural closure, read in source and then grepped.** The taint rule that taints a bank load and the
D5 allow-list that adjudicates its readers call **the same function on the same argument**:

```
ir-pass/src/TaintPropagation.cpp:135   if (railBankOfPointer(LD->getPointerOperand()) && …
ir-pass/src/RailBankPromote.cpp:1199   AllocaInst *Bank = railBankOfPointer(LD->getPointerOperand());
```

So the set of loads that are TAINTED is **identical by construction** to the set D5 adjudicates: there is no bank
load that is admitted-but-untainted, hence **none can reach branch (1) at all**. In the other direction E2's clause
(1a) is `isa<UndefValue>(Handle)`, and a `LoadInst` is not a `Constant`, let alone an `UndefValue`. **The two
changes cannot reach each other's population.** Ordering inside a branch that `LLVMContext::diagnose` exits on is
therefore moot — but it was measured anyway (probe `f5f`).

`ran:` **six probes, ORACLE vs SUBJECT, traces linked and run** (`probes/f5/`):

| probe | what it composes | ORACLE | SUBJECT | outcome |
|---|---|---|---|---|
| `f5a` | canonical rail bank **+** an E2 `undef` classical measure | DECLINE `tainted value stored to memory` | **exit 0, 0 B stderr** | **all 3 `cqrt_measure_i1` present**, 9 trace lines; STRICT 2b `0 violation(s), 0 unproven` |
| `f5d` | `f5a`'s written-zero control (`int u = 0`) | DECLINE | exit 0 | trace **BYTE-IDENTICAL to `f5a`** — E2's refinement claim holds **with the rail bank present** |
| `f5b` | the `undef` measure placed FIRST, before the bank | DECLINE | exit 0 | bank's 3 measures intact |
| `f5e` | E2's **QUANTUM rival** (`cq_measure(q + u)`) inside a bank module | DECLINE | exit 0 | bank's 3 measures intact; the `q+u` measurement vanishes — the **disclosed** rival-2 behaviour, and it does **not** disturb the bank |
| `f5c` | a cell read through a **pointer phi across two banks** (an attack on `getUnderlyingObject`) | DECLINE | **DECLINE** | the blindness is not exploitable here; safe direction |
| `f5f` | an **unallowed** D5 reader **+** an `undef` measure in one module | DECLINE `…stored to memory` @`:9:39` | **DECLINE** `cq rail bank: unsupported reader of a rail-bank cell` @`:10:16` | D5 speaks first and is source-located; E2 does not preempt it |

⚠ **My first F-5 instrument was the wrong one and would have reported a finding that is not there.** Counting
static `@cqrt_measure_` CALL SITES in the lowered module gave `2` for a program with 3 written bank measures, which
reads exactly like a vanished measurement. It is wrong because the measure loop is **ROLLED** — one call site, three
dynamic executions — which is the same property the canonical slice's own golden depends on. **The trace is the
instrument; the call-site count is not.** Recorded because the wrong number was the alarming one.

---

## NOT RUN, AND WHY

* **The table regeneration for the 15 moved matrix cells.** Owed, deliberately not done here — §4. It is an
  implementer's Rule-12 change (a written reason per cell), it is the one operation that could destroy the baseline
  this gate just validated (bd `gfsk`: `--regenerate` silently ate 54 lines of ruling prose), and **a gate that
  rewrites its own expected table has stopped being a gate.**
* **A revert-and-rebuild bisect.** Not needed and strictly weaker: running the merged table against the read-only
  ORACLE binary (§4) isolates the cause with **no rebuild**, hence no risk of relinking under a measurement and no
  second binary to keep straight. Reverting `railbank-fix` would have attributed the same 15 cells with more moving
  parts and less certainty about the table itself.
* **Per-branch gates.** Forbidden by the brief and by PROTOCOL S1, and pointless here: the one red is a
  cross-branch interaction (Track I's axis × Track B's capability) that **no per-branch gate could see** — Track I's
  binary is bit-identical to the ORACLE and Track B never ran the matrix.
* **A Rule-13 opinion on any composition.** This is a GATE, not a review. The gate MEASURES; Rule 2 says a
  measurement is *necessary and not sufficient*. The four owed opinions are listed in `ATTRIBUTION.md` §OWED and
  none of them is discharged by this file.
* **`ctest -R '^e2e-'` and `ir-pass-lit` as separate runs.** Both ran **inside** the full `ctest -j6`; re-running
  them standalone would be a third measurement of the same binary, which PROTOCOL's non-redundancy rule forbids.
* **A simulation of any kind.** Owner decision 2026-06-10; there is no simulator and Rule 2 forbids treating one as
  the gate.
