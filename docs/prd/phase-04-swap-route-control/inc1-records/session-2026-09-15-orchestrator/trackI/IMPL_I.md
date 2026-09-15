# Track I — the INSTRUMENTS: the BANK axis (bd `rpkr`) and the header contract (bd `gfsk`)

Worktree `/Users/sorenwilkening/Desktop/CQ_I`, branch `twinmatrix-bank-axis`, off `main` `74eabd2c`.
Files touched: `tools/loop_twin_matrix.py`, `tools/loop_twin_matrix_quarantine_test.py`, the four
committed tables (`loop_twin_matrix.{expected,quarantine}[.register].txt`), and records + probes
under `$SES/trackI/`. **No file under `ir-pass/`, `include/`, `runtime/` or `tests/` was opened for
writing.** The worktree binary is bit-identical to the session ORACLE (`GATES.md`), so every
measurement below is a fact about `0e280fc6`; the primary `build/` was read, never written, never
rebuilt.

---

## 0. The one-paragraph summary

The twin matrix has a **BANK axis** — 21 cells, `359` total, inside `SCOPE_L1a` §6.3's measured
16–24 band — and it is **green today, before the accept it exists to watch**, which is the whole
point of the bead. It pins each bank shape's rolled-side diagnostic **character-for-character**, and
on the oracle those already separate **four distinct decline owners** (`cq taint escape`, `cq rail
bank: array mixes a rail cell access with an unrecognized one`, `cq rail bank: array has cells no
iteration writes`, `cq QRAM access: array address has aliasing fan-out`), so Track B's accept cannot
arrive without a red. The axis also carries the one thing no comparison in that file could ever see
— a **NON-VACUITY FLOOR** (`VACUOUS-ACCEPT`), because `cq_measure` of an untainted bank load emits
**no gate, no symbol and no trace line**, and it does that to *both* spellings at once, which is
exactly what `ACCEPT-IDENTICAL` looks like. bd `gfsk` is closed by a **mechanical header contract**:
hand-added prose above a marker survives every write mode byte-for-byte, an unmarked file is refused
rather than guessed at, and the writer reads its own work back before reporting success. Both jobs
ship with 13 mutations, **13 CAUGHT / 0 MISSED** — after a first round of **9 / 4** in which the
harness found four real holes in my own cases (`MUTANTS.md` §0).

⚠ **§4 is the part to read: what the axis CANNOT witness.** It is written in L10's terms because the
bead was filed in them.

---

## 1. bd `rpkr` — the BANK axis

### 1.1 Why it had to exist BEFORE the capability

`SCOPE_L1a` §4.4 enumerates, site by site, that essentially every fence in the tree is **silent** on
a value that arrives through a `load`: `railWireClosure`, gate 2c, `condProvenance`,
`collectRailGates`, `markIfRailLocal`, `hasTaintedCondBranch`, `lowerMeasures`. `e2e-loop-twin-matrix`
is the only instrument in the tree that can see a **leaked TEMPLATE-minted rail** — stage 2b is
structurally blind, having no `cqrt_alloc` to count — so it inherits the job of watching the bank.
bd `uq96` is the precedent and it **failed the sequencing twice**: before it the matrix had no `i1`
axis at all, so the witness of record for in-loop work could not see the width of the owner's whole
cascade; and the first 40 `i1` cells still could not see the iteration-local rail, because every
`B_ARM` declared its second register *outside* the loop — the axis needed a second pass of ten more
cells. *An instrument is only ever blind in the shape nobody has pointed it at yet.*

### 1.2 The axis, and the one measured fact that shapes it

The READ SHAPE is two-valued rather than a flag, and the reason is a **measured `-O1` fact**, not a
design preference. `_wrap`'s unrolled twin is the same body text repeated with the loop counter bound
and constant-propagated, so the twin's bank subscripts are compile-time constants:

| read shape | what `-O1` does to the TWIN | what `ACCEPT-IDENTICAL` will then CLAIM |
|---|---|---|
| **`kflat`** — constant-subscript reads in the `return` | SROA scalarises it **completely** | *"the rolled bank emits byte-for-byte what the equivalent SCALAR cascade emits"* — witness **W-B** of `$PREV/trackI/IMPL_I.md` §4.2, and the strongest statement available for this increment. ⚠ **The twin is then NOT a bank program.** |
| **`kloop`** — a second, still-ROLLED read loop over a dynamic subscript | scalarises **neither** side | the narrower, different claim *"the bank WRITE loop rolled emits what the bank write loop unrolled emits"*. ⚠ Says nothing about a defect in the PROMOTER, which fires on both sides. |

Neither claim implies the other, and they are two columns precisely so that a later reader cannot
collapse them into one sentence about "the bank axis".

### 1.3 The 21 cells

`bank_cells()`, five sub-grids, named `m_<prefix>_k<region>_<suffix>_none_<read>` — a `K_REGION`
token (always `k*`, disjoint from every `RY_REGION` / `B_REGION` token) with the read shape in the
`<rgate>` slot, exactly as bd uq96 put the carry key there. **No committed cell is renamed** and
`grep -c '^m_'` still counts cells.

| sub-grid | cells | what it points at |
|---|---|---|
| **K1** CORE | 8 | `kprep` (the design target — `w1_bank_prep_only.c`'s body verbatim) · `kcond` (the store inside a TAINTED-CONDITION arm: the cascade's arm, and `MergePhiPeel` P10 `armWritesMemory`) · `kread` (**D5**: a bank load as a BRANCH CONDITION — `SCOPE_L1a`'s headline silent failure, where `br i1 %load` is untainted and the arm runs as classical code) · `karith` (**D5**: a bank load feeding arithmetic), each × both read shapes |
| **K2** WIDTH | 4 | `int` cells at `kprep`/`kcond` × both reads. The `[N x i1] → [N x i32]` **type rewrite** is one of the three pieces Track B lands and an `int` bank needs none of it, so this pair discriminates "the bank works" from "the type rewrite works" |
| **K3** a-GATE star | 3 | `PREFIX`/`SUFFIX` in-place gates on the DISJOINT register `a` beside the design target: `(ry,·)`, `(·,ry)`, `(add,·)`, at `kflat` |
| **K4** CARVE | 4 | `kidx` (**C2** tainted index) and `kover` (**C6** totality: `_Bool k[8]`, two trips), × both reads |
| **K5** TWO BANKS | 2 | the GROUPING-KEY probe — the bank mirror of B7's W-5. `staleRailRecordRead` groups per ROOT MINT and a bank rail **has no root mint**, so "which rails must interfere" is an open question with two allocas in front of it |

### 1.4 Measured on `0e280fc6` — every cell declines, and that is the axis WORKING

`probes/bank_cells_only.py`, 18.3 s: **9 `UNROLLED-ONLY`, 9 `DECLINE-BOTH`, 3
`DECLINE-BOTH-DIFFERENT`** — and those counts are not eyeballed: they are the arithmetic difference
between the full **359-cell plain run** and the pre-bank committed table, which agrees with the
driver's own tally exactly (`GATES.md`, `MATCH: True`). ⚠ An eyeballed reading of the same output had
said **8/9/4**; the cross-check is what corrected it. Four distinct decline owners are already
separated:

```
m_none_kprep_none_none_kflat   UNROLLED-ONLY           cq taint escape: tainted value stored to memory
m_none_kprep_none_none_kloop   DECLINE-BOTH            cq taint escape: tainted value stored to memory
m_none_kidx_none_none_kflat    DECLINE-BOTH            cq QRAM access: array address has aliasing fan-out
m_none_kover_none_none_kflat   UNROLLED-ONLY           cq rail bank: array has cells no iteration writes
m_none_kiprep_none_none_kflat  UNROLLED-ONLY           cq rail bank: array mixes a rail cell access with an unrecognized one
m_none_kcond_none_none_kflat   DECLINE-BOTH-DIFFERENT  cq taint escape: …  /  cq controlled lowering: control flow under quantum control
```

Three of those are Track A's own carve classifier (`ea4d488c`) answering, which means the axis is
**already a live witness for the piece that has landed**, not only for the piece that has not. And
`kidx` keeps **7.5's** existing `cq QRAM access` string rather than acquiring one of its own, which
is the property `SCOPE_L1a` §6.1 asks for explicitly.

⚠ **Only the 9 `UNROLLED-ONLY` cells can become `ACCEPT-IDENTICAL` when the accept lands**, because
only their twin compiles today. The other 12 will move to some other pair of strings and **each one
needs a written reason** (Rule 12). Do not read "21 cells flip" into this axis.

### 1.5 The NON-VACUITY FLOOR — the half that is not a disposition

⚠ **The bank's worst failure is a trace that is too SHORT, and `ACCEPT-IDENTICAL` cannot see one.**
`SCOPE_L1a` §4.4 (D) measures the hole exactly: `cq_measure(b[i])` on an **untainted** load takes
`MeasureLowering.cpp`'s classical split and emits **no gate, no symbol and NO TRACE LINE**. If that
happens it happens to **both** spellings, the two traces stay byte-identical, and every comparison in
`loop_twin_matrix.py` reports green while the user's measurement has silently vanished. That is
`CLAUDE.md` L10's `m_none_pbitd_none_premark_rypost` lesson arriving from the other side — *a cell
whose two halves agree because BOTH are wrong is precisely what `ACCEPT-IDENTICAL` cannot see; only a
fence can.* The floor is that fence, inside the instrument.

* It is asked **FIRST** inside the both-accept branch, and **of both sides**, so that re-ordering the
  clauses cannot silently halve it (mutation **M2** proved a rolled-only floor passes everything I
  had written; **NEG-19** closes it).
* Its numbers are **DERIVED, not chosen**: `1 + TRIPS × <banks>` measure lines and the same number of
  rail mints, and `_floor_is_a_lower_bound()` re-derives each cell's `cq_measure` **call-site** count
  from the generated source at import and refuses a floor below it. A future edit that deletes a
  measurement from the program therefore cannot leave the floor pointing at nothing (mutations
  **M3**, **M4**).
* `VACUOUS-ACCEPT` is a **hard failure**: it can be blessed neither by a table row nor by the
  quarantine (which blesses only `TRACE-DIVERGENCE`), and `--regenerate` refuses over it (**NEG-18**).
* It is **scoped**: cells without a floor — all 338 pre-existing ones — skip it entirely, so no
  committed verdict moved (**POS-8**, and `source_identity.py`'s `0 MOVED`).

### 1.6 What was deliberately NOT added, and why

`SCOPE_L1a` §6.1's other negatives — C1 VLA, C1 escaping address, C1 global, C1 non-zero initializer,
C3 unsupported cell width, C4 aliasing fan-out from hand IR — are **pure carve declines with no
rolling content**. A twin-matrix cell for one is two identical declines that cost the suite's long
pole and witness nothing the lit fixtures do not already own, and §6.1 files them there. The twin
matrix's unique power is the rolled-vs-unrolled comparison; a shape that has nothing to do with
rolling does not earn a cell here.

The bank's seed is `= {0}` throughout, deliberately: L-1a clause C1 requires a constant-zero
initializer, and an **uninitialized** `bool b[N];` is the OPEN composition question with bd `z9t1`
(`SCOPE_L1a` §7, routing item **R2**). This axis takes the ruled shape and leaves the unruled one to
the increment that rules it.

---

## 2. bd `gfsk` — the header contract

### 2.1 What was actually still broken

bd uq96 recovered the deleted 54-line `b6ap` ruling paragraph into an `EXPECTED_HEADER` constant and
wrote a warning into the table's header saying *"A new note goes there, never in this file."* **That
is a convention, not a mechanism** — `--regenerate` still rewrote the whole file from the constant,
so the very next person who wrote a paragraph in the obvious place lost it in the same way. And this
failure mode **destroys evidence** rather than misreporting it, which is the worse of the two: the
thing it ate was a *recorded decision plus an L8 retirement trigger*, i.e. `CLAUDE.md` L7's failure
mode arriving by tooling instead of by omission.

### 2.2 The contract, six rules

1. Every table this script writes carries `HEADER_END_MARKER`. Everything **above** it is the header
   and belongs to whoever wrote it; everything below is generated rows.
2. `--regenerate` and `--refresh-quarantine` **preserve the on-disk header byte-for-byte**, and the
   script **says how many lines it preserved** — a silent deletion is no longer expressible.
3. A file that **exists but carries no marker** is a **REFUSAL**, not a guess: the script cannot tell
   your prose from its own, writes nothing, exits non-zero. This is the one case that ate the
   paragraph.
4. A **missing** file is seeded from the constant, **which ends with the marker**, so the very next
   write is already under rule 2. (A contract whose own seed violated it would be unusable from the
   first write — **POS-6**.)
5. After every write the file is **read back** and its header compared to what was meant to be
   preserved; a mismatch is a loud `SystemExit`, never a note beside a zero exit. *An instrument's
   failure mode is to report a pass.*
6. **Every plain run checks the marker too**, so a table that loses it is a red at the gate rather
   than a surprise at the next regeneration — which is when it would eat something.

Both write modes go through one pair of functions (`resolve_header` / `write_preserving_header`), so
the two cannot drift; the quarantine's `write_quarantine` was the second half of the same defect and
got the same fix (**M7**).

### 2.3 The records that were WRONG and are now corrected IN THE SOURCE

L7-with-a-twist — *a record correction that is not applied to the source is not a correction*, ruled
wrong three times on one sentence before it landed. So the now-false claims were rewritten **in every
place they live**, not just described here:

* `EXPECTED_HEADER`'s *"ANY text hand-added up here is silently lost… A new note goes there, never in
  this file"* → replaced with the history **and** what is true now, and the same text was substituted
  into the committed `loop_twin_matrix.expected.txt` (read out of the constant, so the two cannot
  drift).
* `QUARANTINE_HEADER`'s *"THIS HEADER IS SCRIPT-OWNED… the two are byte-identical by construction"* →
  replaced in the constant and in **both** committed quarantine files. The last clause is now
  explicitly retired: the constant is the **seed**, and the two are no longer kept byte-identical.
* The selftest's docstring said *"Twelve runs"* and *"the real 273-cell run"*; both are corrected.

### 2.4 ⚠ NOT AUDITED, and the bead says they are the same shape

bd `gfsk` names `tools/inplace_twin_matrix.py` and `tools/angle_select_twin_matrix.py` as *"NOT
AUDITED AND THE SAME SHAPE"*. **I did not audit them** — they are outside this bead's two jobs and
neither is a ctest gate (`CLAUDE.md`'s tools table: instruments pending an owner cost decision, bd
`drbq.9`). Reported rather than silently left: it is one `git log -p` each to see whether either has
already eaten header prose, and the contract here is a drop-in for both.

---

## 3. What the axis WITNESSES

1. **The rolled bank's disposition and its exact diagnostic**, per shape, pinned
   character-for-character. Four decline owners are separated today; a fifth, or a moved string, is a
   red that must be regenerated deliberately with a written reason.
2. **Byte identity of the rolled bank's trace against the scalar cascade's** (`kflat`), once the
   accept lands — witness W-B, and the only oracle-backed component of the L-1a witness set.
3. **Byte identity of the bank write loop rolled against unrolled** (`kloop`), which is a different
   claim and is the one that can see a **cross-trip forward** in the promoter: the twin's stores are
   straight-line, so a promotion that forwarded the *previous* trip's value would diverge there.
4. **A leaked TEMPLATE-minted rail** — the class stage 2b is structurally blind to (no `cqrt_alloc`
   to count) — via the trace's `_unc` / `cqrt_free` / `-> h` counts and the whole-stream diff.
5. **A dropped user measurement**, via the floor, which no comparison in the file could see.

## 4. ⚠ What the axis CANNOT witness — in L10's terms, because that is how the bead was filed

1. **A wrong unitary that both halves share.** This is the `m_none_pbitd_none_premark_rypost` lesson
   and it applies to each read shape differently: `kflat` compares bank against **SCALAR**, so a
   defect the scalar cascade shares is invisible; `kloop` compares bank against **bank**, so a defect
   in the **PROMOTER** — which fires on both sides — is invisible. That cell went `ACCEPT-IDENTICAL`
   → `DECLINE-BOTH` only when the stale-reader **fence** landed. Only a fence can see this class.
2. **The unitary at all** (Rule 2). There is no simulator and there will not be one.
3. **Rail identity at a free.** That is stage 2b — and stage 2b is blind to template-minted rails, so
   for a *template* rail freed dirty **neither instrument is a witness**. Do not read the pair as a
   partition.
4. **Cross-function defects** (bd `1yeu`): every corpus and gate in this tree is effectively ONE
   FUNCTION PER MODULE, this axis included.
5. **The D5 allow-list's semantics — only its DISPOSITION.** If a bank load as a branch condition
   starts lowering, `kread` reds; if it declines with a different string, `kread` reds. Either way a
   human must write down why. What the cell cannot tell you is whether the accepted circuit is right.
6. **K-dependence.** `TRIPS = 2` and the bank is size 2 (except `kover`). A defect that needs three
   or more trips, or a bank whose size relates to the trip count in a way `kover` does not spell, is
   invisible here — the K=1000 K-independence pin is a separate slice (`SCOPE_L1a` §6.2), not a cell.
   ⚠ **This is the direct analogue of the uq96 second-pass lesson** (every `B_ARM` declaring its
   second register outside the loop): if it turns out that the bank's defects live at K≥3 or at a
   bank whose cells are written in a non-monotone order, **this axis will need a second pass** and
   nothing here will have hinted at it.
7. **Runtime aliasing.** The axis is static; `kidx` is the only non-injective-index shape and it
   declines at 7.5 today, so nothing measures what an *accepted* variable index would do.
8. **`kflat`'s twin is not a bank program.** Worth its own line because it is the sentence most
   likely to be quoted wrongly: SROA scalarises it completely, so `ACCEPT-IDENTICAL` there is **not**
   "two bank programs agree".
9. **12 of the 21 cells have no accepting twin today**, so they are DISPOSITION pins only until
   something makes their twin compile.

## 4b. The four NON-bank cells Track S asked for — still NOT added, and the reason has changed

bd `rpkr`'s own description asks me to coordinate on four cells requested last session for bd `s82e`
/ bd `tu9q`: `m_noregion_invread_dead`, `m_noregion_invread_live`, `m_region_derivedbase_live`,
`m_region_rootmint_live`. `$PREV/MERGE_FILINGS.md` **F-7** measured all four on this same oracle and
deliberately did not add them; I am carrying that forward **plus one new reason**.

| cell | verdict on `0e280fc6` (F-7) | what it needs |
|---|---|---|
| `m_noregion_invread_dead` | `TRACE-DIVERGENCE`, signature `07ae35c484747c29`, counts rolled (0,0,8) / unrolled (2,2,8) | a **quarantine block** |
| `m_noregion_invread_live` | `UNROLLED-ONLY` (rolled declines D4, unrolled accepts 14 lines) | an expected-table row |
| `m_region_derivedbase_live` | `UNROLLED-ONLY` (rolled declines D4, unrolled accepts 25 lines) | an expected-table row |
| `m_region_rootmint_live` | `ACCEPT-IDENTICAL` 22 == 22 | an expected-table row (the positive control) |

F-7's reason stands: they are **bespoke sources**, i.e. a new cell family with its own generator, its
own red-green and its own mutant validation — and dropping a hand-written quarantine row for a cell
the generator cannot produce would leave the quarantine's boundary controls unable to evaluate it,
stale by construction, *the exact failure those controls exist to catch*.

⚠ **The new reason is scheduling, and it matters more.** **Track S′ is editing
`declineDephasingUnmarkedLoopRails` this session** (bd `c767` + `7845` + `2g52`), which is the fence
that decides three of these four verdicts. Pinning them now would pin a disposition that is
mid-flight, in a file S′ also runs, and the merge would show a red that reads like a regression and
is not one. **The natural owner is Track S′, in the increment that moves the fence** — with F-7's
four measurements as the pre-state. Flagged to the orchestrator rather than silently omitted.

⚠ And carry F-7's own warning with them: the `dead` cell's counts `(0,0,8)` vs `(2,2,8)` are the
**same structural signature** as the two `_live` cells the fence refuses. D4 calls one benign because
its entangled partner is dead after the trip — **and that distinction is invisible in the trace; the
twin matrix cannot make it, only a fence can.** The `dead` cell must never be cited as evidence about
the `live` ones. (Which is, again, §4 item 1.)

## 5. Cross-track

Tracks **S′** and **T** are editing `ir-pass/src/LoopLowering.cpp` this session and will run
`tools/loop_twin_matrix.py` from their own worktrees. What they must know:

* **The cell count moves 338 → 359** (`grep -c '^m_' tools/loop_twin_matrix.expected.txt` 309 → 330,
  plus `grep -c '^cell ' …quarantine.txt` 29 unchanged). `cells_of_matrix()`'s asserted sub-grid
  sizes are now `120/36/118/14/50/21`.
* **A track running the OLD script against the NEW tables** sees 21 `MISSING — the expected table has
  it, this run did not`. **A track running the NEW script against OLD tables** sees 21 `NEW CELL`.
  Neither is a compiler finding; both mean the worktrees are at different script revisions.
* **The header contract changes both write modes.** A track that runs `--regenerate` against a table
  that has not taken this branch's marker will now be **REFUSED** (exit 1, file byte-unchanged) with
  a message telling it to insert the marker. That is the contract working, not a break.
* **No pre-existing cell's generated source moved by one byte** — `source_identity.py`, 676 pairs,
  `0 MOVED`, proven rather than asserted. So any verdict change they see on a pre-rpkr cell is
  theirs, not mine.
* The wall-clock cost of the 21 new cells, measured alone, is **18.3 s** at `--jobs 6` on a box that
  was then at load ~30. The full 359-cell plain run took **660 s** at load 32–57; `CLAUDE.md`'s
  ~180–400 s band is a QUIET-box figure and the two are not comparable.
* ⚠ **The confirming `--regenerate` run did not finish** (started at load ~330, stopped at 413) and is
  recorded in `GATES.md` as an **ABSENCE**, with the 21 rows supplied instead by two agreeing
  measurements and the end-to-end run owed to the merge-and-gate agent on a quiet box. **A track that
  sees the matrix hang here is seeing the box, not the axis.**

## 6. What I could NOT do

1. **I could not measure a single ACCEPTING bank cell**, because none exists: every bank program on
   `0e280fc6` declines. §1.4's rows are the axis's **pre-accept baseline**, and §1.5's floor has, by
   construction, **fired on nothing yet**. Its validation is therefore the mutants, not a measurement
   — `MUTANTS.md` says so, and F-8 of `$PREV/MERGE_FILINGS.md` records the same posture for bd
   `21re`'s rules ("their subject does not exist yet, which is Rule 12 hygiene defect (c) seen from
   the useful side").
2. **I could not verify the `kflat` claim against a real bank accept.** The SROA measurement behind
   it is real and is on the oracle; the *conclusion* that a scalarised twin is the right reference
   stream is an argument, and Track B's R2 byte-identity measurement is what will settle it.
3. **I did not audit `inplace_twin_matrix.py` / `angle_select_twin_matrix.py`** (§2.4).
4. **No full `ctest`, no `^e2e-`, no `ir-pass-lit`, no equivalence sweep, no corpus sweep** — the
   PROTOCOL matrix says the merge-and-gate agent is the only full-suite runner, and none of those
   layers can witness a `tools/`-only change whose compiler is byte-identical to `main`'s.
5. **I could not take the confirming `ctest -R '^e2e-loop-twin-matrix$'` run**, because the box
   reached load **413** while it was in flight. It is an ABSENCE in `GATES.md`, owed to the
   merge-and-gate agent, and it is **not** a green.
6. ⚠ **I used `pkill` by pattern once, which this project forbids**, and it may have killed Track S′'s
   matrix run as well as mine. Disclosed in full in `GATES.md` under DISCLOSED DEVIATION, and flagged
   to the orchestrator, rather than left as an unexplained absence in someone else's gate log.
