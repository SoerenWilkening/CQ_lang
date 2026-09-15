# ATTRIBUTION — final integration gate, session 2026-09-15

SUBJECT `9bd01598…` vs ORACLE `0e280fc6…`. **One sweep, 6194 inputs, 6165 rows, decline verdicts hashed over
FULL STDERR.** Raw rows: `corpus_9bd01598.txt`; per-mover re-measured diagnostics: `corpus_attribution_raw.txt`;
instruments: `instruments/`.

```
rows=6165
IDENTICAL 5805 · D->A 169 · D->D(string) 124 · A->A(stream) 58 · A->D 5 · CLANGERR 2 · EMPTY 2
MOVERS = 356        UNATTRIBUTABLE = 0
```

⚠ **An unattributable mover is a FINDING. There are none.** Every row below is re-measured on both binaries by
re-running the pass and reading the diagnostic, not by trusting the sweep's hash.

---

## D→A — 169 rows, by the ORACLE string they leave

| n | ORACLE string | track | cross-check |
|---|---|---|---|
| 57 | `cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop` | **Track T** (bd `tu9q`) — the pairing discharges the rail, so the fence has no customer | loopgate measured 35 over its 4220-row corpus |
| 42 | `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value` | **Track E2** (bd `fve8`) — owner ruling E2, clause (1a) | E2 measured 24 over 4986 rows |
| 41 | `cq taint escape: tainted value stored to memory` | **Track B** (bd `xdu2` W1 second half) — the rail bank compiles | B measured 27 / 5557; BFIX's 3-way measured **41** |
| 21 | `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | **Track P′** (bd `hn29`/`leyd`/`52og`) — the 2c per-leaf window | P′ measured 10 MINE over 3953 |
| 7 | `cq controlled lowering: state prep seed is proven equal to the condition register…` (F2) | **Track F′** (bd `hrts`/`l3i1`/`dpau`) — the φ-descendant dominance precision | F′ measured 2 over 3933 |
| 1 | `cq controlled lowering: control flow inside a loop body under quantum control` | **Track B/T** — a bank program that now reaches the loop layer | — |

Every count here is **≥** the owning track's own figure because this corpus is larger than any track's
(6165 rows against 3933–5606). **No track under-reported a direction**; the ratios are consistent throughout.

## D→D — 124 rows, by string transition

| n | transition | track |
|---|---|---|
| 35 | `…stored to memory` → `control flow inside a loop body under quantum control` | **Track B**, E5 **wall 3** (`iterationLocalRollable` (c3) — *not* W1) |
| 30 | `…rail entangled with a register rotated after the loop` → `…with a rotated register` | **Track S′** (bd `c767`/`7845`/`2g52`) — the decline-string rename |
| 18 | `…stored to memory` → `cq rail bank: unsupported reader of a rail-bank cell` | **Track B** — the new D5 allow-list string |
| 7 | `…stored to memory` → `…stored to memory` (**same string, different `!dbg`**) | **Track B** — see **F-4** |
| 6 | `…stored to memory` → `loop-carried tainted value crosses iterations` | **Track B**, E5 **wall 4** (X1 / bd `ej5w` / W3) |
| 5 | `…stored to memory` → `tainted value muxed by a classical-condition phi` | **Track B** |
| 5 | `…stored to memory` → `rotation/measure operand predates a non-diagonal gate` | **BFIX** — the rail-bank stale-reader seed reaching memory-resident readers |
| 3 | F2 → `tainted value muxed by a classical-condition phi` | **Track F′** |
| 2 | `…stored to memory` → `…rail entangled with a rotated register` | **Track B × Track S′** composition |
| 2 | `…stored to memory` → `condition predates a non-diagonal gate` | **Track B × Track P′/2c** composition |
| 2 | `…rotated after the loop` → `round-1 iteration-local marking falsified by round-2 taint` | **Track T** (T measured exactly 2) |
| 2 | **F2 → exit −6 (SIGABRT)** | **Track F′** — see **F-2**, the one real finding |
| 2 | exit −6 → exit −6 | pre-existing bd `y65i`; unmoved |
| 1 each | → `returned at non-i32 width` · → `consumed by an unknown callee` · → `rotation arm shares the condition flag` · → `control flow under quantum control` | **Track B** |
| 1 | F2 → `cq uncompute: dead chain would free a measured register` | **Track F′** |

## A→D — 5 rows, every one the same string, every one SAFE-direction

All five: ACCEPT → `cq loop lowering: rolled body leaks a rail entangled with a rotated register`.
**Track S′'s fence via the bd `emkg` narrowing** (`bodyBlocksMarked`: the subloop filter + the ANY→ALL polarity).

```
loopfix/probes/n1_nested_marked_inner.c            (reproduces on the ORACLE — needs neither S′ nor T)
loopfix/probes/r1_triple_nest_mid_rail.c           (DEPTH 3, middle loop's own rail)
loopfix/probes/r3_nested_cmp_rail_outer.c          (the S′ × emkg composition)
ir-pass/test/loop_leak_dephase_reject_nested_depth3_middle_rail.ll
ir-pass/test/loop_leak_dephase_reject_nested_iterlocal_inner.ll
```

Both shipped fixtures are `*_reject_*` files that **expect** this decline, and `loopfix/FIX.md` §3 carries the
multiset behind each (the depth-3 cell's `12+12+8+8` vs `10+10+10+10` — equal totals, **four undischarged
which-path copies**). The fix's own `new ⇒ old` implication makes a decline→accept impossible in this direction,
and the sweep agrees: **0 D→A on that string from emkg.**

## A→A — 58 rows, every delta adjudicated

`ran:` `instruments/aa_adjudicate.py` re-lowers each mover on both binaries and diffs the `cqrt_*` /
`cq_template_*` call multiset:

```
  54  PAIRING-ONLY (+_unc / +cqrt_free only)
   4  NO-CALL-DELTA (declare order only; instructions byte-identical)
   0  *** FORWARD GATE REMOVED ***
   0  *** NON-DISCHARGE ADDED ***
```

**Track T's pairing capability**, and nothing else. **No accepted circuit's forward gate stream moved anywhere in
6165 modules.** This is the class that would carry a silent miscompile, and it is empty in both dangerous
directions. (The loopgate adjudicated its 31 the same way with the same result, including the same 4 declare-order
rows; this is a larger corpus reaching the same verdict, not a re-citation.)

---

# FINDINGS

## F-1 — **the RED: 15 twin-matrix cells moved; the baseline regeneration is OWED and was never done**

Not a compiler defect. All 15 are `k*` BANK cells; all 15 pinned `cq taint escape: tainted value stored to memory`.
The merged table is a **correct ORACLE pin** (359/359 under the ORACLE binary, exit 0), so the movement is the
merged compiler's, and it is **Track B's rail bank compiling what the axis was built to watch decline**.

| cell | pinned → got | reading |
|---|---|---|
| `m_none_kprep_none_none_kflat` | `UNROLLED-ONLY` → **`ACCEPT-IDENTICAL`** | the capability working, **witness W-B**: the rolled bank emits byte-for-byte what the SROA-scalarised cascade emits |
| `m_none_k2b_none_none_kflat` | `UNROLLED-ONLY` → **`ACCEPT-IDENTICAL`** | same, at the C6-totality over-sized bank |
| `m_none_kprep_none_none_kloop` | `DECLINE-BOTH` → **`ROLLED-ONLY`** | **F-3** |
| `m_none_k2b_none_none_kloop` | `DECLINE-BOTH` → **`ROLLED-ONLY`** | **F-3** |
| `m_none_kiprep_none_none_kloop` | `DECLINE-BOTH` → **`ROLLED-ONLY`** | **F-3** |
| `m_none_karith/kcond/kicond/kread_…_kloop` (4) | `DECLINE-BOTH` → `DECLINE-BOTH-DIFFERENT` | still declining, one side at a LATER wall (walls 3/4, 2c) |
| `m_none_kcond_…_kflat` | `DECLINE-BOTH-DIFFERENT` → `DECLINE-BOTH-DIFFERENT` | rolled side's string moved to 2c |
| `m_add_kprep` · `m_none_karith` · `m_none_kprep_ry` · `m_none_kread` · `m_ry_kprep` (5, all `kflat`) | `UNROLLED-ONLY` → `UNROLLED-ONLY` | rolled side's string moved to a later wall |

**Owner: Track I (the table) with Track B (the reason).** Each of the 15 needs a written reason under Rule 12 —
which is precisely what `--regenerate` alone does not produce.

## F-2 — ⚠ **`fxp1` and `fxp1c` move from a LOUD DECLINE to a BROKEN-MODULE ABORT, and the population of a known crash GREW**

```
trackP/probes/fxp1_composed_crossblock_nondominated_phi.ll   F2 decline -> exit -6
trackP/probes/fxp1c_nogap_control.ll                         F2 decline -> exit -6
```
`ran:` on the SUBJECT:
```
PHI node operands are not the same type as the result!
  %p = phi i1 [ %h_op, %gapX ], [ false, %Y ]
LLVM ERROR: Broken module found, compilation aborted!
```
`ran:` the INPUT modules **verify clean** (`opt -passes=verify` exit 0). So **the PASS produces the malformed
`phi`** — an `i1` phi that took an `i32` handle after RAUW — and `opt`'s in-process verifier aborts.

**Track P′ recorded this and attributed it to pre-existing bd `y65i`.** That is true of `fxp2`, which crashes on
the ORACLE too. It is **not** true of `fxp1`/`fxp1c`: on the ORACLE those two are **stopped by the F2 decline**, and
Track F′'s narrowing removes the thing that was masking the crash. CLAUDE.md's own words apply verbatim —
*"'pre-existing' is true of the defect and FALSE of its population — the increment that exposed them adds customers
to a known defective path."*

**Direction: LOUD, therefore not a Prime-Directive violation.** The compiler aborts non-zero; nothing silently
miscompiles.

**Bounded by measurement over ALL 6165 rows, movers and non-movers alike** — ⚠ my first spelling of this bound
scanned only the mover list and mis-counted, and is corrected here rather than quietly re-run:

```
modules where EITHER binary aborts (exit 134): 4   — all .ll, 0 .c
  B10_classcond_deadphi_crash.ll   ORA=134  SUB=134   (pre-existing; Track B named it)
  fxp2_deadphi_i1_template_noF2.ll ORA=134  SUB=134   (pre-existing; P′ named it)
  fxp1_composed_crossblock_…ll     ORA=1    SUB=134   <-- NEW
  fxp1c_nogap_control.ll           ORA=1    SUB=134   <-- NEW
modules that abort on the SUBJECT and not on the ORACLE: exactly 2 (the two above)
```

So **no program reachable from `clang -O1` anywhere in the corpus hits it**, and the new population is exactly two
hand-written `.ll` probes. That is a bound **on this corpus**, **not** a proof of unreachability, and it must not be
written up as one.

**Recommendation: file against bd `y65i` with `fxp1`/`fxp1c` named as new customers. Not a landing blocker** — a
crash is loud, no C program reaches it, and it replaces a decline rather than an accept.

## F-3 — **a NEW `ROLLED-ONLY` class (3 cells): the rolled bank compiles where its hand-unrolled twin declines**

`ran:` reproduced from plain C in two files (`probes/rolledonly/`), so it is not a matrix artefact:

```
ro_rolled.c    (write loop rolled)      -> exit 0, ACCEPT
ro_unrolled.c  (write loop hand-unrolled, everything else identical)
               -> exit 1  cq taint escape: tainted value stored to memory   @ ro_unrolled.c:4:11
```

**Cause, read in source:** the rail-bank carve requires the parking store to be in a loop — `railBankCarveVerdict`
sits behind `if (!LInfo->empty())` and the verdict's own `LI.getLoopFor(SI->getParent())` conjunct — so a
loop-free spelling can **never** produce a `Bank`. The asymmetry is structural to the capability, not a bug in it.

**Direction: an OVER-DECLINE on the unrolled side** — per the owner's 2026-09-11 ruling *"an over-decline is a
defect to remove, not a free safety margin"*, so it is filed, not celebrated.

⚠ **The part that matters more than the over-decline is the WITNESS GAP.** For these three cells the matrix's
usual claim — rolled == unrolled, byte-identical — is **unavailable**, because one side does not compile. The
capability is still witnessed elsewhere (the two `kflat` cells that went `ACCEPT-IDENTICAL`, and the shipped green
`e2e-railbank-flat-twin-identical` gate, both making witness W-B's *"bank == scalar cascade"* claim), but **not by
these cells**. CLAUDE.md: *an instrument is only ever blind in the shape nobody has pointed it at yet.*

## F-4 — 7 decline rows moved with a **byte-identical diagnostic string**, visible only to full-stderr hashing

All seven are two-bank / three-bank programs. `ran:` on `f9_two_banks.c` the string is identical and the **source
location moves**: ORACLE `f9_two_banks.c:3:50` → SUBJECT `f9_two_banks.c:4:50`. The first bank is now a recognised
`Bank` that the capability accepts, so the **second** store is the first to decline. **A `!dbg` is present on both
sides; none is lost.** Benign, correct, Track B.

Recorded because the shared `corpus.sh` tag regex would have scored all seven as *no change* — this is PROTOCOL
S3's known blind spot, closed by construction rather than by a follow-up pass, and it had live customers.

---

# OWED — reviews, not code (this gate discharges NONE of them)

A gate measures. Rule 2: a measurement is **necessary and not sufficient**. Carried forward unchanged:

1. **`MERGE_FILINGS.md` F-5** — a **Rule-13 opinion** on E2 × D5 in `lowerMeasures` branch (1). This gate's probes
   and the shared-predicate argument say the composition is clean; **that is a measurement and an argument, not a
   second opinion.**
2. **ROUTING R6** — a Rule-13 reviewer whose subject is the **composition**: Group 1 (A×B) and Group 3 (F′×P′).
3. **`loopfix/FIX.md` §8 / loopgate "GREEN AND NOT CLEARED"** — the two merge-derived fixture conversions
   (`loop_leak_dephase_reject_{cmp_rail_data,inloop_rotation}.ll`), `r3`'s composition, and the four programs where
   S′ refuses and T accepts. **Cleared by the agent that merged them; the loop gate's own re-measurement was
   "a third measurement, not a second opinion."**
4. **ROUTING R12** — owner ruling **E6 option (D)** (reorder the warn stage before the dephasing fence) is
   **RULED but NOT BUILT and has no home.** Per R12's own instruction, the closing record must say so in those
   words rather than leave the ruling looking discharged.
5. **The F-1 table regeneration** — 15 cells, a written reason each (Rule 12).
