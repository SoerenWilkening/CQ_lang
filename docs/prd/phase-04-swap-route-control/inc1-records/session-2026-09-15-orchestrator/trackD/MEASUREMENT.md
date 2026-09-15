# Track D — THE MEASUREMENT (bd `test_C_libtooling-bbu0`; owner ruling **E6 = (D)**)

> **This file is the deliverable.** Owner ruling E6 put option (D) ahead of A/B/C because it
> is *"the only one that turns the gap from an argument into a number"*, and **A/B/C are ruled
> next session on what is written here.** Nothing in this file is a recommendation. No
> predicate was adjusted to move any figure in it.

---

## 0. The question, and why it needed an instrument at all

> *Is `RotationLowering::warnLiveRecordRotations` ever **SILENT** on a module that
> `LoopLowering::declineDephasingUnmarkedLoopRails` **DECLINES**?*

On any shipped binary the answer is unobtainable, not merely unknown: the fence is called at
`CQLoweringPass.cpp:772`, the warn stage at `:864`, and `LLVMContext::diagnose` **EXITS on
the first `DS_Error`** (bd `br4a`). **Every "0 warnings" row over a declining module is 0 BY
PREEMPTION, NOT BY SILENCE** — including every such row in Track S′'s table
(`QUESTION_bbu0.md` §1, the `†` rows).

The instrument (`IMPL_D2.md` §1) defers the fence's decline past the warn stage under
`CQ_BBU0_DEFER_DEPHASE_FENCE=1`. Because the fence is **pure analysis that mutates no IR and
no `taint` set**, the deferred pipeline is byte-for-byte the pipeline a build with the fence
**deleted** would run — so the warn stage sees exactly the circuit the fence exists to refuse.

---

## 1. THE POPULATION — derived, not listed

```
$ POP_SCOPE=<scope> probes/fence_pop.sh <BASE cq-opt> <out>
```
BASE `cq-opt` **`15f6a75a50faba7a2c99a969497044ca6211293ea00ad6388510c6cc17bff96d`**
(= `dephase-fence-r2` `6882685b`, Track S′'s tip — **bit-identical to S′'s own recorded
SUBJECT(final)**, so it is provably the binary S′ gated).

### 1.1 The brief's minimum scope — `ir-pass/test/*.ll` + this session's probe corpora

| bucket | rows |
|---|---|
| **FENCE** — the fence's literal in stderr | **17** |
| ACCEPT (`opt` exit 0) | 1047 |
| OTHERDECLINE (a different `DS_Error`) | 1030 |
| VACUOUS (no `@cq_{theta,phi,measure}_` — would ACCEPT through the passthrough early-out) | 6 |
| **scanned** | **2100** |

⚠ **17 ROWS ARE 12 DISTINCT PROGRAMS.** Five of Track S′'s probes are committed **twice** —
as `<name>.c` and as the `<name>.s1.ll` the same `clang -O1 -g` produced — and the scan takes
both. That the two halves of each pair agree on every row is a **consistency check on the
harness**, not five more members; the counting below is on the **12 programs** and says so
wherever it matters.

| # | program | provenance |
|---|---|---|
| 1 | `ir-pass/test/loop_leak_dephase_reject_noregion_live.ll` | the 14c fence's own shipped reject |
| 2 | `ir-pass/test/loop_leak_dephase_reject_region_derivedbase_live.ll` | ditto |
| 3 | `ir-pass/test/loop_leak_dephase_reject_inloop_rotation.ll` | Track S′, bd `c767` (P1, closed 2026-09-15) |
| 4 | `ir-pass/test/loop_leak_dephase_reject_cmp_rail_data.ll` | Track S′, bd `7845` (P1, closed 2026-09-15) |
| 5 | `ir-pass/test/control_phase_kickback_mixed_hoisted_template_leak_control.ll` | bd `s82e`'s three converted declines |
| 6 | `ir-pass/test/control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll` | ditto |
| 7 | `ir-pass/test/control_phase_kickback_mixed_short_sext_leak_control.ll` | ditto |
| 8 | `trackS/probes/s1_live_shift` | S′ probe (`.c` + `.s1.ll`) |
| 9 | `trackS/probes/s2_live_derived_region` | S′ probe (`.c` + `.s1.ll`) |
| 10 | `trackS/probes/b7b_w2k_interfered` | bd `c767`'s subject (`.c` + `.s1.ll`) |
| 11 | `trackS/probes/b7c_w2h_interfered` | bd `c767`'s subject (`.c` + `.s1.ll`) |
| 12 | `trackS/probes/b11_cmp_rail_data` | bd `7845`'s subject (`.c` + `.s1.ll`) |

**The 7 fixtures are exactly the 7 that mirror the fence's literal** (`grep -l` over
`ir-pass/test/*.ll`), which is an independent check that the scan found the whole fixture
half rather than a subset of it.

### 1.2 ⚠ THE MINIMUM SCOPE WAS NOT THE WHOLE POPULATION — the full corpus adds two SHAPES

The brief's minimum was run first because it is the population the ruling is about, but it was
**not** treated as complete. The BASE-vs-SUBJECT corpus sweep of §3 carries a **FENCE column of
its own**, over `ir-pass/test/*.ll` **plus every session's** `track*/probes` and `*_probes`
directories, so the wider population comes out of the gate that proves nothing moved — the two
numbers **cannot** be derived from different corpora.

| scope | FENCE rows | distinct programs by content |
|---|---|---|
| brief's minimum | 17 | 12 |
| **full corpus (5289 rows swept)** | **21** | **14** |

The extra rows are mostly the SAME programs committed again under
`session-2026-09-14c-xdu2-w1/` (round 1β's copies of `s1`/`s2`/`b7b`/`b7c`/`b11`), which is
why 21 rows collapse to 14 contents. ⚠ **But two are genuinely NEW SHAPES that the minimum
scope would have missed**, and they are exactly the reason a "minimum" is a floor and not an
answer:

```
…/session-2026-09-14c-xdu2-w1/review_r1b/probes/b3_ctrl_ry_after.c     WARNED warn=1 marker=1 fence=1 exit=1
…/session-2026-09-14c-xdu2-w1/review_r1b/probes/b8_angle_select_after.c WARNED warn=2 marker=1 fence=1 exit=1
```

a controlled-Ry-after shape and an **angle-select**-after shape — neither of which is
represented among the 12. **Both warn.** Every figure in §2 is reported at BOTH scopes below,
and neither scope produced a `SILENT` row.

---

## 2. THE NUMBER

```
$ OPT="…/opt -load-pass-plugin …/libCQPass.so" probes/bbu0_measure.sh <population> <out> <artifacts>
$ probes/summarise.sh <out>
rows: 17
WARNED             17
SILENT              0
PREEMPTED           0
CRASH               0
INSTRUMENT-BROKEN   0
CONTROL-BROKEN      0
CLANGERR            0
distinct PROGRAMS  12
non-WARNED rows in full: (none)
```

SUBJECT `libCQPass.so` **`d4bf79c1473ea26d368fd2cce26a7ec69ccb8c9a8e16628e8a9c4932fa4e9345`**
(`bbu0-warn-reorder`, the instrument).

and at the **full-corpus** scope (§1.2), the same script over 21 rows / 14 distinct programs:

```
rows: 21
WARNED             21
SILENT              0
PREEMPTED           0
CRASH               0
INSTRUMENT-BROKEN   0
CONTROL-BROKEN      0
CLANGERR            0
```

> ### **`warnLiveRecordRotations` is SILENT on ZERO of the programs `declineDephasingUnmarkedLoopRails` declines — 0 of 12 at the brief's minimum scope, 0 of 14 over the whole corpus.**
> It fires on **every one**, at counts 1 or 2 per program, **and the fence still declines every
> one** (`fence=1`, `exit=1` on every row — no verdict became an accept under the gate).

**Every bucket is printed, including the zeros.** A bucket absent from a summary reads as
*"did not happen"*; a bucket printed with a 0 reads as *"was looked for and did not happen"*.
Only the second is a measurement.

**The zeros that are not the headline but carry their own weight:**

* **`marker=1` on all 17 rows.** The marker is emitted by `emitDeferredDephasingDecline`,
  which runs **after** the warn stage — so every row is proof that the warn stage **executed**.
  **Not one figure here is 0-by-preemption**, which is the entire defect Track S′'s table had
  to live with.
* **`PREEMPTED = 0`** — a second, separate fact: **no module in this population acquires a
  different first diagnostic when the fence's decline is moved to the late slot.** So on the
  measured population the *unconditional* form of spelling (i) would cost **zero string
  moves**. (It is still shipped env-gated: zero measured cost over 12 programs is not a proof
  over the class, and §5.1 bounds what this population is.)
* **`CONTROL-BROKEN = 0`** — every row was re-checked with the variable **unset** before being
  gated, and every one still produced the fence's decline. The control is per-row, not global.

### 2.1 The five ORACLE controls — the instrument is validated, not merely argued

Section 1.1's 12 programs split on the frozen session ORACLE
`0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` (= `main` `74eabd2c`,
before Track S′'s widening):

| on the ORACLE | programs | ORACLE warn count | SUBJECT **gated** warn count |
|---|---|---|---|
| **ACCEPT** — no fence in the way, the circuit is emitted | `b7b_w2k_interfered`, `b7c_w2h_interfered`, `b11_cmp_rail_data`, `loop_leak_dephase_reject_inloop_rotation`, `loop_leak_dephase_reject_cmp_rail_data` | 1 · 1 · 2 · 1 · 2 | **1 · 1 · 2 · 1 · 2** |
| **DECLINE** at the fence (old literal, *"…rotated after the loop"*) | `s1_live_shift`, `s2_live_derived_region`, the three `control_phase_kickback_mixed_*_leak_control`, `loop_leak_dephase_reject_noregion_live`, `loop_leak_dephase_reject_region_derivedbase_live` | **0 — BY PREEMPTION** | **1 or 2 — MEASURED** |

⚠ **Read the first row twice. On five programs the ORACLE runs the warn stage with NO fence
in front of it at all, and its warn count is IDENTICAL to what the deferred instrument
reports.** That is an **empirical** check that deferring the decline does not perturb what the
warn stage sees — five independent controls, against the "pure analysis ⇒ fence-deleted
pipeline" argument of `IMPL_D2.md` §1.1, which would otherwise be the only ground.

⚠ **And the second row is `QUESTION_bbu0.md` §3 answered.** Those seven are exactly the `†`
rows — *0 warnings, by preemption, not by silence*. With the preemption removed, **all seven
warn.**

### 2.2 What this does NOT say

It does **not** say the warning subsumes the fence, and the measured superset relation is
**not** new evidence for that: `DECISIONS.md` E6 already records **why** the populations nest
— *divergence ⇒ hazard, hazard ⇏ divergence* — and this measurement tests only the first
implication, on 12 programs. It does not touch the second (the byte-identical twin pair that
warns and does not diverge), which is the half that costs option **B** its 5 accepting slices.
**A/B/C remain open, and this track rules none of them.**

---

## 3. The NO-VERDICT-MOVED gate — **0 movers over 5289 rows**

```
$ probes/corpus_D.sh <out> <BASE cq-opt> <worktree>     # env UNSET on both binaries
rows swept (excl. DONE)        5289
BASE-accept                    2324
BASE-decline                   2412
VACUOUS (no cq_* intrinsic)     551
CLANGERR                          2
MOVERS (BASE row != SUBJECT row)  0
```

Corpus: `ir-pass/test/*.ll` **plus every session's** `track*/probes` and `*_probes`. A row
carries the **exit code, the md5 of the lowered IR when accepting, and a SHA-256 of the FULL
STDERR** — Track S′'s three instrument corrections kept verbatim, and the stderr hash is the
one that matters here: the shared `corpus.sh` tag regex renders a whole diagnostic family as
an empty tag, so a **decline→decline string move would be INVISIBLE** to the inherited
instrument (PROTOCOL S3). Both binaries read the **same stage-1 file** per row, so md5s are
compared within a row only.

**Nothing moved. Not a verdict, not a message, not a lowered-IR hash.** That is the expected
result and it is worth stating why it was still run rather than argued: the diff is **237
insertions and 0 deletions**, and the only change to an existing control path is a guard in
front of the shipped `diagnose`, `false` unless the variable is set — but "expected" is what
every silent miscompile in this project's history also looked like, and the gate is cheap.

⚠ **This gate says the instrument is invisible when it is OFF. It says nothing about the
fence's correctness**, which is Track S′'s subject and still owes a Rule-13 round of its own.

---

## 4. How to reproduce every figure above

```
# 1. the population (BASE binary)
probes/fence_pop.sh <BASE cq-opt> <out>            # POP_SCOPE=full widens the probe half
# 2. the measurement (SUBJECT binary; the gate is inside the script)
probes/bbu0_measure.sh <population> <out> <artifact-dir>
probes/summarise.sh <out>
# 3. the no-verdict-moved gate (BASE vs SUBJECT, env UNSET)
probes/corpus_D.sh <out> <BASE cq-opt> <worktree>
```

Every gate line, with the binary hash it is a fact about, is in `GATES.md`.

---

## 5. Caveats — every one of them narrows what the number may be quoted for

1. **The population is "what the BASE binary declines at this fence", nothing wider.** It is
   derived by `probes/fence_pop.sh` on every run, never hand-listed, so the denominator
   cannot drift from the rows. ⚠ **RETIREMENT TRIGGER:** the population moves whenever the
   fence moves — bd `tu9q` is filed as the fence's **end state** (it makes these programs
   compile), and Track S′ widened the fence twice on 2026-09-15. **Re-run `fence_pop.sh`;
   never carry this denominator forward.**

### 5.1 ⚠ FOURTEEN PROGRAMS IS A SMALL POPULATION, AND IT IS SMALL FOR A REASON THAT MATTERS

**The measured population is, essentially, the set of programs somebody built to exercise this
fence.** Seven are its own fixtures; the rest are the probes Track S′, round 1β and bd `s82e`
wrote to hunt it. `LoopPlan.h` says in so many words that *"nothing measures how many members
the class has"*, that a **cast/`fneg`-minted instance has NO WITNESS EITHER WAY**, and that a
**cross-function** spelling is invisible to every instrument in the tree (bd `1yeu`). So:

> **"0 of 14" is a fact about 14 programs. It is NOT "the warning is never silent where the
> fence speaks."** The right reading is: *nobody has yet exhibited a program on which the
> fence speaks and the warning is silent — and now, for the first time, that sentence is a
> MEASUREMENT rather than an artefact of preemption.*

⚠ And §1.2 is the live demonstration that the population is **discovered, not known**: widening
the corpus from the brief's minimum to the whole tree added **two shapes nobody had counted**
(a controlled-Ry-after and an angle-select-after). Both warned — but the lesson is that the
denominator moved when the search did, which is exactly why the population is derived by a
script on every run and why the retirement trigger below is not decoration.

⚠ The candidate Track S′ named for the other direction is **untouched by this measurement and
stays open**: the warning's record set is **EMPTY for a rail minted inside a region by
`cqrt_alloc`** (`RecordSet::push` clause 5 — the documented reason it is silent on all 42
confirmed miscompiles of the drbq Inc-4 F2 class). **No member of this population has that
shape**, so nothing here tests it. A program that is *both* an F2-class region rail *and*
reaches this fence through `taintedAncestryReaches` is still exactly where a counter-example
would live. **Not reproduced, not claimed unreachable** — S′'s discipline, carried.
2. **A `PREEMPTED` row is UNDECIDABLE, not silent.** It means some other `DS_Error` spoke
   before `:864` in the deferred run, so the warn stage still never ran. Counting it as
   `SILENT` would be the exact instrument failure this harness was built to avoid.
3. **`PREEMPTED` is also the measured cost of shipping the deferral UNCONDITIONALLY** — each
   such row is a module whose diagnostic string would move if the fence were simply relocated
   to the late slot. It is reported for that second reason as well.
4. **Every instrument in this tree is ONE FUNCTION PER MODULE** (bd
   `test_C_libtooling-1yeu`). A cross-function instance of either predicate is invisible to
   this measurement exactly as it is to all the others.
5. **Neither predicate is a dephasing detector, and this number is not coverage.** The
   warning is silent on all **42** confirmed miscompiles of the drbq Inc-4 F2 class **by its
   own header** (their rails are minted inside the region by `cqrt_alloc`, so `RecordSet::push`
   clause 5 empties the record set); the fence is narrower still. A zero here says the
   warning is not silent **on this population** — it says nothing about either predicate's
   completeness.
6. **The circuits the warn stage inspects here will never be emitted.** They are the modules
   the fence refuses. The measurement answers *"if the fence were not there, would the
   warning report this?"* — it must never be read as *"these programs compile"*.
7. **This is a measurement, not a Rule-13 clearance.** The instrument is a core-lowering-file
   change and a green suite does not clear it (Rule 13); what it has is the no-verdict-moved
   corpus gate in §3 and the fixture pin, which are necessary and not sufficient.
