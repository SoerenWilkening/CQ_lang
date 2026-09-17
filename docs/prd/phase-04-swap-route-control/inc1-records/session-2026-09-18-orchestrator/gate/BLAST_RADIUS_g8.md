# BLAST RADIUS of `review_r13_group1` F-1 (the g8 shape) — PASS 1, SUBJECT `96d74fe6008133b8`

**The question (coordinator):** *"That number decides whether F-1 was probe-only or already shipping
in a golden; nobody has it."*

> # THE ANSWER: **NOT probe-only. The SHAPE already ships, in 2 registered goldens.**
> **But the DOOR does not.** Both halves are load-bearing and neither may be quoted without the other.

---

## 1. What was swept, and what "the shape" means mechanically

Candidates: **every `tests/e2e/slice_*.c` (386)** plus **every committed probe `.c` under
`docs/prd/**/probes` (2340+)**, each compiled `clang -O1 -g`, lowered by the **combined** binary,
stage-2b censused, and — only where `left dirty > 0` — linked and run for its trace.

A file is scored **G8-SHAPE** iff, in its own trace:

1. a **TEMPLATE** rail is minted from a register `S` (`cq_template_<op>(S, …) -> R`), **and**
2. `R` is **never** `_unc`'d and **never** freed (it is one of stage 2b's `left dirty`), **and**
3. a **NON-DIAGONAL** gate runs on `S` **later** — `cqrt_ry_<w>(S, …)`, or
   `cqrt_ry_<w>_controlled(_, S, …)` where **arg 1 is the target**.

That is Rule 8 verbatim: a live which-path record of `S` is still entangled when the interference
happens on `S`.

⚠ **THE DETECTOR WAS WRONG THE FIRST TIME AND SILENTLY REPORTED A PASS.** Its first version called
`free_pairing_check.py` with **`-q`**, which **suppresses the census line on a clean exit** — so every
module parsed as `0 dirty` and scored **CLEAN**. Run at scale it would have reported **zero hits** and
this document would have said *"F-1 is probe-only"*. It was caught only because it was validated
against a **known positive** before use (L10: *"an instrument's failure mode is to report a pass, so
the only instrument worth citing is one that has been made to fail on purpose"*). The fixed version
also refuses to default a **missing** census to clean — that is now its own `NOCENSUS` verdict.

**Validation before use, five known cases, all correct:**

| case | expected | got |
|---|---|---|
| `g8_arm_use_derived_owned_rot` | POSITIVE | **G8-SHAPE**, naming `ashr->h1 copies h0; later cqrt_ry_i32 on h0` |
| `g8a_arm_measured_directly_control` | clean (one-token delta) | CLEAN, `0 dirty` of 3 |
| `g8k_arm_use_derived_unmarked_control` | declines | DECLINE |
| `dD1` (discharged by Group 1's P2 at this gate) | clean | CLEAN, `0 dirty` of 2 |
| `dD5` (ditto) | clean | CLEAN, `0 dirty` of 2 |

## 2. The shipped-slice result — COMPLETE, and it is the number that was asked for

**383 of 386 scored** (3 skipped: `*_lib.c` / `lib*.c` halves swept with their caller).

| verdict | slices |
|---|---|
| CLEAN (`0 left dirty`) | **223** |
| **DIRTY-NO-TRAILING-GATE** (dirty rails, no interference after) | **152** |
| DECLINE | 6 |
| **G8-SHAPE** | **2** |

### The 2 hits — both **YES, already-shipping registered goldens**

| file | dirty count | trailing gate | already-shipping golden? |
|---|---|---|---|
| `tests/e2e/slice_control_inplace_ry_loop_leak.c` | **1** of 2 template mints | `cq_template_mul_i32_hl -> h3` copies `h2`; later **`cqrt_ry_i32_controlled` targeting `h2`** (trace line 9), again at line 16 | **YES** — `slice_control_inplace_ry_loop_leak.expected.log`, `add_test(NAME e2e-slice-control-inplace-ry-loop-leak)` |
| `tests/e2e/slice_control_inplace_ry_loop_leak_unrolled.c` | **2** of 4 | identical mechanism, both repetitions | **YES** — golden + `add_test(NAME e2e-slice-control-inplace-ry-loop-leak-unrolled)`, plus `e2e-inplace-ry-loop-leak-twin-identical` |

**The shipping golden, in full, with the hazard marked:**

```
cqrt_alloc_i32(7) -> h2
cqrt_ry_i32(h2, 0x1p-2)
cq_template_mul_i32_hl(h2, 7) -> h3          <- undischarged RECORD of h2
cqrt_tape_write_i32(t0, h3) -> h4            <- second undischarged rail
cq_template_icmp_eq_i32_hl(h1, 5) -> h5
cqrt_ry_i32_controlled(h5, h2, 0x1.ccc…p-1)  <- NON-DIAGONAL gate on h2, h3 still live
…                                             (the whole group repeats for h6/h7)
cqrt_measure_i32(h1) -> 0
cqrt_measure_i32(h2) -> 0                    <- h2 IS the observable
```

`h3` and `h6` are coherent records of `h2`'s basis label; a non-diagonal gate then runs on `h2`; and
`h2` is measured. **Structurally identical to `g8`.**

### ⚠ 2a. These two slices carry, in their own headers, the sentence CLAUDE.md §5 has ALREADY RULED FALSE

`slice_control_inplace_ry_loop_leak.c` says:

> *"IT IS RULE-6 CORRECT AND IT IS NOT A REGRESSION. Every leaked rail is LEFT ALLOCATED; none is
> freed dirty."*

Its program is:

```c
r = cq_theta(r, 0.25);
for (int i = 0; i < 2; ++i) {
    int s = r * 7;                                  /* the undischarged record of r */
    if (q == 5) { r = cq_theta(r, 0.9); }           /* NON-DIAGONAL gate on r */
    …
}
return cq_measure(q) + cq_measure(r);               /* r IS measured */
```

CLAUDE.md §5's **Q-R1-1 CORRECTION** already governs exactly this: *"**Where the same register is
rotated by a NON-DIAGONAL gate after the loop and then measured, it is a wrong unitary** — the
leftover which-path rails dephase the rotation (Rule 8), and the ACCEPT was the defect,"* and it names
three shipped fixtures that *"were in the second half and said so in their own headers without drawing
the conclusion,"* whose Rule-6 sentence *"is false for those programs."*

**These two slices are a fourth and fifth instance of that same false justification, in shipping
goldens, and the correction was never propagated to them.** That is the L7-with-a-twist species the
project has now paid for repeatedly: *a record correction that is not applied where the claim lives is
not a correction.*

### ⚠ 2b. All three gates over these two slices are GREEN, and the twin gate is green *because both halves leak*

From this gate's own full-suite log:

```
331/462 Test #336: e2e-inplace-ry-loop-leak-twin-identical ...... Passed  0.10 sec
334/462 Test #329: e2e-slice-control-inplace-ry-loop-leak ....... Passed 20.88 sec
335/462 Test #330: e2e-slice-control-inplace-ry-loop-leak-unrolled Passed 20.89 sec
```

The golden byte-diff passes because the golden **records the leaking stream**; STRICT stage 2b passes
because it reports `0 violation(s)` (nothing is freed dirty); and `twin-identical` passes because the
rolled and unrolled halves leak **the same rails in the same order**. That last one is the trap
CLAUDE.md names in as many words: *"a cell whose two halves agreed because BOTH were wrong is
precisely what `ACCEPT-IDENTICAL` cannot see; only a fence can."* The slice header even says so
itself — *"AND THE TWIN LEAKS THE SAME RAILS FOR THE SAME REASON, which is the point of the pair."*

**So there is no gate in the tree that would go red if this hazard were a miscompile.** That is why
the blast-radius number had to be measured rather than inferred from a green suite.

## 3. The half that says NOT-shipping: the DOOR

F-1's door is specific — **a MARKED multi-block body whose ARM mints an INTERIOR rail**, with
`markedBodyRailsHaveInBodyDischargePoint` returning `true` (`g8k` proves the marking is the door;
`g8a` proves "interior" is the discriminant). The two shipping hits reach the same hazard through a
**different** door: the drbq Increment-1 **structural FREEZE** (a rail carrying a controlled rotation
is `NotClosed`, never reverse-played), which is a filed, deliberately-witnessed leak with its own
slice pair and its own O(K) measurement.

So, precisely:

* **The HAZARD CLASS (bd `s82e` / Rule 8 dephasing) is already shipping in goldens** — 2 of 383.
* **F-1's specific MECHANISM is, in the shipped-slice set, probe-only** — no slice reaches the
  marked-multi-block-body door.
* **Therefore "F-1 is probe-only" is FALSE as a statement about the hazard and TRUE as a statement
  about the door.** Quoting either half alone misleads in opposite directions.

## 4. Context that keeps the 2 from being read as alarming, and the 152 from being read as safe

**152 of 383 shipped slices carry dirty template rails with NO trailing non-diagonal gate.** Dirty
rails are ordinary and mostly benign — the libm slices reach **228** (`slice_libm_real_acoshl.c`),
213, 204, 197… They are Rule-6 accepted leaks in the qubits-not-scarce regime and nothing interferes
with them afterwards. **The trailing gate is the entire discriminant**, which is why the count that
matters is 2 and not 154.

⚠ But note what that also means: **the population one line of C away from the hazard is 152, not 2.**
The quarantine header already says this about class D — *"Rule-6 formally safe today … the rails are
still entangled which-path records, so this is the Rule-8 hazard **one line of C away**."*

## 5. Scope and honesty limits of this sweep

* **Shipped-slice set: COMPLETE** (383/386 scored, 3 structurally skipped). This is the set that
  answers the coordinator's question, because only these have goldens.
* **Probe set: 227 of ~2449 scored, then DELIBERATELY STOPPED — recorded as an ABSENCE, never as a
  zero.** I stopped it (task `bkgwiuf3r`; the one orphan worker killed **by recorded PID 66488**, not
  by pattern) when the box went to **load 187→218** under another agent's build, because the corpus
  sweep is a required gate on my critical path and the probe half is supplementary. Partial tally of
  the 227: `CLEAN 100 · DECLINE 92 · DIRTY-NO-TRAILING-GATE 32 · RUNERR 1 · LINKERR 1 · CLANGERR 1`,
  **0 further G8-SHAPE**. A probe has no golden, so **no probe hit could change the "already
  shipping" answer**; it could only widen the known reproducer set. The remaining ~2222 probe files
  are UNMEASURED and must not be reported as clean.
* `.ll` fixtures under `ir-pass/test/` are **out of scope by the coordinator's spec** (`.c` only).
  CLAUDE.md §5 names three `control_phase_kickback_mixed_*_leak_control.ll` fixtures in this class;
  they were not re-scored here.
* The detector is a **trace-shape** test, not a proof. It cannot see whether `cqrt_tape_write_i32`
  has measurement-like semantics that would collapse `h3` (a 7.6 output-tape question); if it does,
  the two hits weaken. **Stage 2b independently counts both rails as `left dirty`**, so the detector
  and the shipped checker agree on the premise.
