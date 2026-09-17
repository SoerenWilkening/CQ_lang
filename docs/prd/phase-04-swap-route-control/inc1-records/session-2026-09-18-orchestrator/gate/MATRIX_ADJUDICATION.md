# `e2e-loop-twin-matrix` — ADJUDICATION of every moved cell

**Run:** inside the group-gate full `ctest -j6`, SUBJECT `96d74fe6008133b8`.
`462/462 Test #318: e2e-loop-twin-matrix ***Failed 424.44 sec`.
**382 cells — 183 ACCEPT-IDENTICAL, 79 DECLINE, 120 other; 37 quarantined, 4 boundary controls.**

```
ACCEPT-IDENTICAL 182 · ACCEPT-IDENTICAL-WARN 1 · DECLINE-BOTH 37 ·
DECLINE-BOTH-DIFFERENT 42 · HARNESS-ERROR 24 · ROLLED-ONLY 3 ·
TRACE-DIVERGENCE 46 · UNROLLED-ONLY 47
control q_armoncond HARNESS-ERROR · q_nestinline / q_nestinlineplain / q_noregion ACCEPT-IDENTICAL
```

**FAILED (95) report entries = 56 DISTINCT CELLS** (most cells are reported twice: once for the
failure and once as a verdict change). Every one is adjudicated below.

> ## ⚠ THE VERDICT FIRST: THE MATRIX IS RED AND **CANNOT BE REGENERATED TO GREEN**, AND I DID NOT TRY TO FAKE IT
>
> Not for a load reason. Three independent blockers, each a **deliberate refusal in the instrument's
> own contract**:
> 1. **24 cells + 1 pinned boundary control return `HARNESS-ERROR`.** A `HARNESS-ERROR` is not a
>    verdict; there is nothing for `--regenerate` to record. No regeneration can green them.
> 2. **A pinned BOUNDARY CONTROL moved** (`q_armoncond`, pinned `TRACE-DIVERGENCE`, got
>    `HARNESS-ERROR`). Source, `check_controls`: *"`--regenerate` does NOT rewrite these — moving a
>    control is a human decision with a measurement attached."* And `main`: `blocking = … + qfails +
>    ctlfails; if blocking: print("REGENERATION REFUSED TO HIDE %d HARD FAILURE(S) … is UNCHANGED")`.
> 3. **15 cells newly diverge and are NOT quarantined.** `EXPECTED_HEADER` forbids recording
>    `TRACE-DIVERGENCE` as an expected verdict (*"a table entry that says 'this pair may differ'
>    retires the one gate in the tree that can see the F-4 class"*), and the quarantine tool
>    **"can neither add nor remove a cell — adding one is a human decision with a bd issue attached."**
>
> **That refusal is the contract working.** Forcing it green would require exactly the three things
> the instrument is built to stop.

---

## A. 24 cells + 1 control → `HARNESS-ERROR`: the INSTRUMENT met Group 1's P2, and the instrument loses

**Cause, identical on all 25 and quoted from the harness:**
`rolled side: stage 2b (free_pairing_check, STRICT) failed: … UNPROVEN U3-extern-rail … handle is
written in this stream but minted outside it`.

`loop_twin_matrix.py:2156` states the policy deliberately:

> *Stage 2b — STRICT. A cell that needs `--allow-unproven` is not a cell this gate can speak for, and
> saying so loudly is the point.*

**Every one of these cells reports `0 violation(s)` and `0 … left dirty`.** The rails ARE discharged;
`free_pairing_check.py` analyses per straight-line STREAM and Group 1's P2 places the discharge at the
**loop exit**, a different stream from the mint — so `UNPROVEN` is the *structural* answer, not a
finding about the circuit. `trackT2/IMPL_T3.md` §6.3 predicted this in writing and measured it
(`1 verified, 0 violation(s), 3 unproven` rolled vs `5 verified, 0 unproven` twin); this gate
reproduces it on 24 more cells and on a boundary control.

| cells |
|---|
| `m_none_der_{none,none_bodyread,none_postmark,none_premark,rz}` · `m_rz_der_{none,rz}` |
| `m_none_oder_none_none_{none,addpost,rypost,rypre,rzpost}` · `m_none_oder_none_rpostmark_none` |
| `m_none_rder_none_none_{none,addpost,rypost,rypre,rzpost}` |
| `m_none_range_{none,rz}` · `m_rz_range_{none,rz}` · `m_none_rrange_none_none_{none,rypost}` |
| **control** `q_armoncond` |

**Direction: this is a capability gain wearing an instrument failure's clothes.** The right fix is a
decision, not a patch, and **it is Track V's file to change (R14), not mine.** The options, costed:

* **(a)** run the rolled side's 2b with `--allow-unproven` — mirrors the reason CLAUDE.md already
  blesses for the four `loop-break` slices and that Group 1 used for its own e2e slice; **cost:** the
  matrix stops witnessing genuine dirty-rail regressions on those cells, which is precisely the F-4
  class it exists for. **Not obviously right.**
* **(b)** teach `free_pairing_check.py` a cross-stream model so a loop-exit discharge can be
  *verified*; **cost:** a real increment on a Rule-6 instrument, with its own Rule-13 round.
* **(c)** leave it red; **cost:** Rule 19 verbatim — *"a gate expected to be red is a gate people stop
  reading, and the 16th divergence lands in a run everybody already knows is red."*

**Recommendation (labelled as such, not a ruling): (b), with (a) as an explicitly time-boxed
stop-gap recorded in the quarantine header.** Under (a) or (c) the matrix cannot speak for 24 cells,
including **all six of the cells that watch class A**.

### A.1 ⚠ The "QUARANTINE STALE — REMOVE IT" message on the six class-A cells is an ARTIFACT. Do not act on it.

The six `m_none_oder_none_*` cells printed **`QUARANTINE STALE — REMOVE IT.`** That message fires when
a quarantined cell's verdict is not `TRACE-DIVERGENCE` — and their verdict is `HARNESS-ERROR`, because
stage 2b aborted **before the traces were ever compared**. It is not evidence that the divergence is
gone.

**I measured what the harness could not**, by generating each cell's two halves through
`loop_twin_matrix.sources(...)` and running the pair with stage 2b informational instead of fatal
(`gate/probes/cellprobe.py`):

| cell | rolled/unrolled lines | multiset | byte-identical | rolled 2b | fresh diff signature |
|---|---|---|---|---|---|
| `m_none_oder_none_none_none` | **27 == 27** | **EQUAL** | no | `4 template rail mint(s) of which 0 left dirty` | `edbcfc8b1220486e` |
| `m_none_oder_none_none_addpost` | **29 == 29** | **EQUAL** | no | `0 left dirty` | `9131e3d52bbe9b4c` |
| `m_none_oder_none_none_rypost` | **29 == 29** | **EQUAL** | no | `0 left dirty` | `117f0f19902d9672` |
| `m_none_oder_none_none_rypre` | **29 == 29** | **EQUAL** | no | `0 left dirty` | `e58056996a9e7ded` |
| `m_none_oder_none_none_rzpost` | **27 == 27** | **EQUAL** | no | `0 left dirty` | `edbcfc8b1220486e` |
| `m_none_oder_none_rpostmark_none` | **28 == 28** | **EQUAL** | no | `0 left dirty` | `edbcfc8b1220486e` |

On the ORACLE these were **25 vs 27** with `cq_template_sqrt_f64_unc` **0 vs 1** — the rolled side left
the top rail `h4 = sqrt((double)a + 3.0)` permanently allocated, *"a perfect WHICH-PATH RECORD
entangled with the condition register"* (quarantine header, class A). **Now `sqrt_f64_unc` is present
on BOTH sides and the counts match.**

> **bd `1m5p` (class A) is FIXED IN SUBSTANCE by Group 1's P2**, and the cells **STILL DIVERGE
> POSITIONALLY** — one `cqrt_free(h6)` crosses the `cq_template_sqrt_f64_unc(h4, h3)` pair, on a rail
> DISJOINT from it, so the two commute and the unitary is identical.

**This is character-for-character what `trackT2/QUARANTINE_HANDOFF.md` §1 forecast** — *"27 == 27,
`sqrt_f64_unc` 1 vs 1 … ⚠ THEY DO NOT LEAVE QUARANTINE … the divergence is POSITIONAL only"* — and the
forecast is now a measurement.

**Disposition: RE-PIN, do not remove.** The correct action is `--refresh-quarantine` with the four new
signatures above and the class-A `owner:` line rewritten from *"ROLLED IS THE DEFICIENT SIDE"* to
*"rolled is no longer deficient; the residue is positional"* — **but `--refresh-quarantine` refuses
while `q_armoncond` has moved, and refuses again while the cells return `HARNESS-ERROR`.** So A.1 is
blocked behind A. ⚠ **Acting on the printed instruction and deleting these six blocks would retire the
only six cells that watch class A, on the very run in which class A changed.**

### A.2 A second-order instrument finding, worth a bead on its own

The stale-quarantine check and the harness-error check are **not ordered defensively**: a cell that
errors is reported as "quarantine stale" in the same breath, and the two messages contradict each
other. A cell whose verdict could not be computed should be reported as *unmeasured*, never as
*no longer diverging*. This is the L10 species — an instrument reporting a conclusion it did not
measure — and it is the one direction that matters, because "stale → REMOVE IT" is an instruction to
delete a gate.

---

## B. 15 cells → NEW, UNQUARANTINED `TRACE-DIVERGENCE`: **Track D's P4 widening, and exactly what `MERGE_FILINGS.md` F-10 said no gate of D's could see**

Every one of the 15 was `UNROLLED-ONLY` on the ORACLE with the rolled side declining
**`cq controlled lowering: condition predates a non-diagonal gate under quantum control`** — Track D's
own P4 string. D's widening makes the rolled side compile; the two halves then differ.

```
m_none_eq_none   m_none_eq_none_bodyread  m_none_eq_none_postmark  m_none_eq_none_premark
m_none_eq_rz     m_none_eq0_none          m_none_eq0_rz            m_none_gt_none
m_none_gt_rz     m_rz_eq_none             m_rz_eq_rz               m_rz_eq0_none
m_rz_eq0_rz      m_rz_gt_none             m_rz_gt_rz
```

**The attribution is MEASURED, not inferred** (`gate/probes/cellora.py`, 3 cells sampled — the rolled
and unrolled halves run on BOTH binaries):

| cell | ROLLED on ORACLE | ROLLED on COMBINED | UNROLLED on ORACLE |
|---|---|---|---|
| `m_none_eq_none` | **DECLINE** `condition predates a non-diagonal gate` | **ACCEPT** | ACCEPT |
| `m_none_gt_rz` | **DECLINE**, same string | **ACCEPT** | ACCEPT |
| `m_rz_eq0_none` | **DECLINE**, same string | **ACCEPT** | ACCEPT |

That is the `UNROLLED-ONLY → TRACE-DIVERGENCE` transition exactly, and the door is **Track D's P4
widening** — the rolled side could not compile before it and can now.

**Measured mechanism (4 of 15 probed directly; uniform across the sample):**

| cell | rolled | unrolled | multiset | signature |
|---|---|---|---|---|
| `m_none_eq_none` | 11 | 8 | differs | `a70745d8b5defa38` |
| `m_none_gt_none` | 11 | 8 | differs | `baa9feb7b9d496b5` |
| `m_none_eq0_none` | 11 | 8 | differs | `4cb084b8b6ee4b49` |
| `m_none_eq_rz` | 11 | 12 | differs | `14ce13d04bde79ca` |

`m_none_eq_none`, in full — the ROLLED side mints a **fresh flag per trip**:

```
rolled                                  unrolled
  icmp_eq(h0,5) -> h1                     icmp_eq(h0,5) -> h1
  rz_i1(h1, PI)                           rz_i1(h1, PI)
                                          rz_i1(h1, PI)      <- both phases on ONE flag
  icmp_eq_unc(h1,h0,5); free(h1)          icmp_eq_unc(h1,h0,5); free(h1)
  icmp_eq(h0,5) -> h2                   
  rz_i1(h2, PI)                         
  icmp_eq_unc(h2,h0,5); free(h2)        
  measure(h0)                             measure(h0)
```

**Analytic reading (no simulation — Rule 2):** the flag is `f = (a == 5)` in both, and `cqrt_rz_i1` is
**diagonal**. Rolled applies `Rz(PI)` once on each of two independently minted, identically prepared
flags; unrolled applies `Rz(PI)` twice on one flag that `-O1` CSE'd from the two identical compares.
Both accumulate the same conditional phase `2*PI` on the `a == 5` branch, and each flag is stripped
by its own `_unc` and freed at `|0>`. **The unitaries agree; the rail STRUCTURE does not.** The
rolled form is the more conservative of the two (it never assumes the predicate is stable across
trips).

> ⚠ **THIS IS AN ARGUMENT, NOT A CLEARANCE, AND I AM NOT THE AGENT WHO MAY GRANT ONE.** It is a
> per-cell unitary reading by the merge agent on 4 of 15 cells. The remaining 11 are unprobed and
> share only a *name pattern*. Rule 13 needs an independent reviewer, and the quarantine's own rule
> is that adding a cell is *"a human decision with a bd issue attached."*

**Disposition: FILE, do not bless.** This is the concrete instance of `MERGE_FILINGS.md` F-10's
prediction — *"an accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled probe
with a trailing non-diagonal gate on every register the condition reads"* — and the twin matrix is the
instrument that found it, having been routed to this gate by R14 for exactly this reason. Track D's
lit, corpus and injection matrix are all structurally blind to it.

---

## C. 11 cells `DECLINE-BOTH` → `ACCEPT-IDENTICAL`: the unambiguous win

```
m_none_req_none_none_{none,addpost,rypost,rypre,rzpost}
m_none_req0_none_none_{none,rypost}
m_none_rne_none_none_{none,rypost}
m_none_ryrz_none_none_{none,rypost}
```

Both halves previously declined; both now compile and their traces are **byte-identical**. This is the
best outcome a cell can have and needs no quarantine, no argument and no follow-up: it is an
over-decline removed in the direction the owner's 2026-09-11 ruling asks for, with the rolled/unrolled
identity as its witness.

## D. 5 cells: decline-string changes only (both sides still DECLINE)

| cell | was | now |
|---|---|---|
| `m_none_kcond_none_none_kflat` | `condition predates a non-diagonal gate` | `control flow inside a loop body` |
| `m_none_kcond_none_none_kloop` | same | same |
| `m_none_kicond_none_none_kloop` | same | same |
| `m_none_rzry_none_none_none` | `control flow inside a loop body` | `→ UNROLLED-ONLY` |
| `m_none_rzry_none_none_rypost` | same | `→ UNROLLED-ONLY` |

The first three remain `DECLINE-BOTH-DIFFERENT`: the module still declines on both sides, at an
earlier fence. Safe direction, no circuit emitted either way. The last two move to `UNROLLED-ONLY`
(rolled still declines, unrolled now compiles) — an asymmetry in the **decline** direction, which is
Prime-Directive-safe but is an over-decline candidate on the rolled side.

---

## E. What did NOT move, and both answers matter

* **Track V's 8 NESTED cells (classes D and E, bd `3n29` / F-9) — ALL EIGHT UNMOVED.**
  `m_none_l2b_*`, `m_none_l2c_*`, `m_none_l2n_none_none_l2ic`, `m_none_l2nd_none_none_l2ic` appear
  nowhere in the FAILED report, so each still diverges with its **pinned signature intact**.
  **This is the answer F-9 routed to this gate: 0 of the 8 move.** Group 1's P2 loop-exit discharge
  does **not** reach the nested-loop class — consistent with class D's own root cause (*"the rolled
  OUTER loop never discharges its own per-trip rail when an inner loop is present"*), which is a
  different placement problem from the one P2 solves.
* **The 6 class-B `oder` cells (`m_none_oder_add_*`, bd `a3z7`) — UNMOVED**, signatures intact.
  `QUARANTINE_HANDOFF.md` §1 warned that fixing class A underneath them might move their digests;
  **measured, it did not.** All twelve `oder` cells were re-measured as that file required; six moved
  (§A.1) and six did not.
* **3 of the 4 boundary controls** (`q_noregion`, `q_nestinline`, `q_nestinlineplain`) are
  `ACCEPT-IDENTICAL` as pinned. Only `q_armoncond` moved, and it moved to `HARNESS-ERROR` for §A's
  reason, not for a reason about the class story it bounds.

---

## F. Net

| bucket | cells | direction | action |
|---|---|---|---|
| A — `HARNESS-ERROR`, stage-2b STRICT vs loop-exit discharge | 24 + 1 control | instrument cannot speak; circuits measured clean (`0 violation`, `0 dirty`) | **owner/Track V decision** |
| A.1 — class A `oder`, re-measured by hand | (6 of the 24) | **bd `1m5p` FIXED in substance**; positional residue | **RE-PIN, do not remove** — blocked behind A |
| B — new unquarantined divergence | 15 | Track D P4 widening; unitary argument holds on the 4 probed | **FILE + Rule-13 round** |
| C — `DECLINE-BOTH` → `ACCEPT-IDENTICAL` | 11 | pure win, byte-identical | none |
| D — decline-string / one-sided decline | 5 | safe | 2 over-decline candidates |
| E — nested (D/E), class-B `oder`, 3 controls | 0 moved | stable | F-9 answered: 0 of 8 |

**The matrix ends this gate RED, deliberately and with every cell accounted for.** Nothing was
regenerated, nothing was re-pinned, no quarantine block was added or deleted, and
`tools/loop_twin_matrix.expected.txt` / `.quarantine.txt` are **byte-unchanged** on this branch.

---

# PASS 2 — SUBJECT `07d937842bfb5135`. The matrix is STILL RED, and the reasons have CHANGED COMPLETELY

`462/462 … 318 - e2e-loop-twin-matrix (Failed)` inside a **458/459 in 1059.19 s** suite.
**382 cells — 183 ACCEPT-IDENTICAL, 79 DECLINE, 120 other; 37 quarantined, 4 boundary controls.**

```
ACCEPT-IDENTICAL 182 · ACCEPT-IDENTICAL-WARN 1 · DECLINE-BOTH 37 ·
DECLINE-BOTH-DIFFERENT 42 · ROLLED-ONLY 3 · TRACE-DIVERGENCE 70 · UNROLLED-ONLY 47
control q_armoncond TRACE-DIVERGENCE · q_nestinline / q_nestinlineplain / q_noregion ACCEPT-IDENTICAL
```

## ⚠ THE TWO HEADLINES, AND THE FIRST IS AN INSTRUMENT REPAIR

**1. `HARNESS-ERROR` is GONE: 24 → 0, and `QUARANTINE STALE` is GONE: 6 → 0.** Track C's (T4) rule
proves the loop-exit discharge, so the 24 cells that could not be *spoken for* in pass 1 now carry
real verdicts, and the pass-1 artefact (six cells told to "REMOVE IT" because the 2b abort preempted
their trace comparison) **cannot arise from this cause any more**. Filing G-7 is resolved at the cause.

**2. bd `1m5p` CLASS A IS FIXED, AND THE INSTRUMENT NOW SAYS SO ITSELF.** In pass 1 I had to
hand-measure past the abort to claim it. Pass 2's own report, all six cells:

| cell | rolled | unrolled |
|---|---|---|
| `m_none_oder_none_none_none` | **(5, 5, 7) over 27 lines** | **(5, 5, 7) over 27 lines** |
| `…_addpost` / `…_rypost` / `…_rypre` | (5, 5, 7) over 29 | (5, 5, 7) over 29 |
| `…_rzpost` | (5, 5, 7) over 27 | (5, 5, 7) over 27 |
| `…_rpostmark_none` | (5, 5, 7) over 28 | (5, 5, 7) over 28 |

The quarantine header records the ORACLE as `(4, 4, N)` against `(6, 6, N)` with *"ROLLED IS THE
DEFICIENT SIDE"*. **Counts are now EQUAL on every one.** The residue is the single positional
`cqrt_free(h6)` crossing `cq_template_sqrt_f64_unc(h4, h3)` — disjoint rails, commuting, same unitary.

## What is red now, by the matrix's OWN messages (not my parser's labels)

| message | count | what it needs |
|---|---|---|
| `verdict changed` | **49** | `--regenerate` |
| `ROLLED AND UNROLLED TRACES DIFFER` | **39** (incl. the 6 below, which print both) ⇒ **33 genuinely unquarantined** | 33 NEW quarantine blocks — *a human decision with a bd issue attached*, which the tool cannot author |
| `QUARANTINED SIGNATURE CHANGED` | **6** — exactly the class-A `oder` cells | `--refresh-quarantine` with a written reason |
| `BOUNDARY CONTROL still diverges but DIFFERENTLY` | **1** — `q_armoncond` | the O1 re-pin |

⚠ **MY PARSER MISLABELLED THE SIX.** It reported them as `(not quarantined)` because it keyed on the
first message; the matrix prints a *second* line, `QUARANTINED SIGNATURE CHANGED — this is a red, not
a refresh`, which is the real verdict. Acting on my parser would have authored six NEW blocks for
cells that already have blocks and need only a refresh. Recorded as an instrument defect of mine.

The 33 new cells by region token: `eq` 7 · `der` 7 · `rder` 5 · `range` 4 · `gt` 4 · `eq0` 4 ·
`rrange` 2. **Two mechanism groups**, both already argued:
* `eq`/`gt`/`eq0` (15) — **Track D's P4**, the per-trip flag mint vs `-O1` CSE (PASS2_PREP C-1/C-2).
* `der`/`rder`/`range`/`rrange` (18) — the cells that were HARNESS-ERROR in pass 1. They are the
  class-A shape: **Group 1's P2 loop-exit discharge**, counts now equal, positional residue.

## (B) `q_armoncond` — THE RE-PIN IS JUSTIFIED, AND MY OWN TRIGGER FIRED ON A FALSE COMPARISON

`PASS2_PREP` (B) said: *"If the pass-2 signature differs from `3fa9d45cd851c1b3`, re-derive the
argument before pinning — a third signature would mean Group 1's fix moved it again."* The matrix
reported `d81485c481c5ad07`, so I re-derived. **The conclusion is that the trigger misfired, and the
reason is worth more than the trigger:**

Re-measured at the pass-2 hash (`gate/probes/ctlprobe.py`): **24 == 24 lines, MULTISET-EQUAL, the
SAME first differing line and the SAME `cqrt_free(h5)` position as pass 1, and my tool's signature is
`3fa9d45cd851c1b3` — BYTE-IDENTICAL TO PASS 1.** The divergence did **not** move between pass 1 and
pass 2.

⚠ **`3fa9d45cd851c1b3` was never comparable to the quarantine's pins.** It is *my* tool's sha over
*its* unified-diff rendering (`difflib`, `n=1`); the matrix computes its own over its own rendering.
Two numbers that both call themselves "sha256 of the unified diff" are **not** the same key. I wrote
"none of these may be pinned" and was right — and then used one as a comparison key anyway, which was
the error. Same species as PROTOCOL S3's *"md5s are NOT comparable ACROSS sweeps"*.

**So the adjudication stands unchanged** (track = Group 1's P2 by string; verdict `TRACE-DIVERGENCE`
unchanged; per-trip argument = one `cqrt_free(h5)` crossing instructions on disjoint rails, `h5`
proven-`|0⟩` by its own `_unc` on both sides), and the authoritative value to pin is **the matrix's
`d81485c481c5ad07`**, never mine. Both halves now also run STRICT 2b clean: rolled `8 verified,
0 violation(s), 0 unproven`; unrolled `10 verified, 0 unproven`.

## Verdict: the matrix is handed off RED, deliberately

Greening it is **one large deliberate operation**, not a command: 33 hand-authored quarantine blocks
(each needing a bd id and a per-trip argument — the tool *"can neither add nor remove a cell"*), a
`--refresh-quarantine` for the six class-A cells, the `q_armoncond` re-pin, a `--regenerate` for the
49 verdict changes, and a ~10-minute re-run to confirm. **I did not perform it**, and
`tools/loop_twin_matrix.expected.txt` / `.quarantine.txt` are **byte-unchanged on this branch** — as
they were after pass 1. The arguments needed for all of it are written above and in
`PASS2_PREP.md`; what is missing is the authoring, not the reasoning.
