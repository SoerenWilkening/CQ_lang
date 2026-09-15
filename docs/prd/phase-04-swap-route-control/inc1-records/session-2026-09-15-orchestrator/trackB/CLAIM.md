# Track B — CLAIM: what bd `xdu2` / L-1a W1's SECOND HALF makes compile, and what it does not

One page, in the words owner ruling **E5** requires. Branch `railbank-accept`,
off `railbank-blockers` `9e11f524`. Subject `cq-opt`
`784c14fa05c16c501662b3814434dafb8ffb1cc2ed98a8d17986dc12a372b6ff`.
Every number here is measured; the commands are in `IMPL_B2.md` and `GATES.md`.

---

## The claim, in one sentence

> **The bank compiles; the owner's cascade needs (c3) + W3.**

Not *"the decline moved"*. The rail bank is a capability now — six program
shapes that declined at every N on `railbank-blockers` compile, link, run and
produce a gated golden trace — and the owner's own file still declines, at a wall
that is bank-independent and was never W1's.

---

## WHAT COMPILES

A **bounded rail BANK**: a local array whose cells each hold one quantum rail,
written once per trip of a classically-bounded loop and read back after it.

```c
bool b0[3];  int s = 0;
for (int i = 0; i < 3; ++i) b0[i] = cq_theta(b0[i], 0.5);
for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
```

`opt` exit 0, stderr empty, **9 trace lines**, STRICT stage 2b `0 violation(s),
0 unproven`. Gated end to end by six registered e2e slices and two `compare_files`
gates.

Measured across the accept surface, all six previously `cq taint escape: tainted
value stored to memory` at every N:

| shape | witness |
|---|---|
| `_Bool` cells, measure loop (**the canonical shape**) | `e2e-slice-railbank-bool-prep-measureloop` |
| `_Bool` cells, **constant-index** reads `b0[0]+b0[1]+b0[2]` | `e2e-slice-railbank-bool-prep-constidx-measures` |
| `int` cells, measure loop (**the width axis**) | `e2e-slice-railbank-int-cells-measureloop` |
| the bank **outside `main`** (the D1 spine door) | `e2e-slice-railbank-nonmain` |
| the bank **zero-initialised** (`= {0}`) | `e2e-slice-railbank-bool-prep-measureloop-zeroinit` |
| the bank at **N = 1000**, rolled | `railbank_accept_k1000.ll` — 83 lowered lines at N=3 **and** at N=1000 |

**Two byte-identity gates, not notes:**

* `e2e-railbank-uninit-zeroinit-twin-identical` — the uninitialised and written-`= {0}`
  spellings emit the SAME trace (sha `0eaaad13…`, **0 divergences** over 3 program
  pairs). This is R2, and it is what makes owner ruling **D1** a measurement rather
  than an assertion: D1 does **not** inherit bd `z9t1`'s justification, because
  `normalizeUndefRotationSeed` does not reach a MEMORY seed, so D1 rested on C6
  totality alone until now.
* `e2e-railbank-flat-twin-identical` — the bank's stream is **byte-identical** to
  three scalar `_Bool`s prepped and measured with no array anywhere. That is the
  byte-identity witness `SCOPE_L1a.md` §5 asked the capability to carry.

---

## WHAT DOES NOT COMPILE, AND WHOSE IT IS

**The owner's `example/grover/grover_oracle_uncompute.c` still DECLINES**, at
wall **3** of four:

```
cq controlled lowering: control flow inside a loop body under quantum control
```

* **Wall 1** (`tainted value stored to memory`) — **gone**, W1 piece 3.
* **Wall 2** (`value-arm swap-route`, anchored at the arm's `zext i1 %q to i8`) —
  **gone**, W1 piece 2's cast sink.
* **Wall 3** — `iterationLocalRollable`'s conjunct **(c3)**, **bd `8h7d.11`**. NOT
  W1's, and **bank-independent**: the same loop with a scalar `bool` and no array
  at all declines identically (`probes/b02`), while the same loop with the arm not
  feeding `a` accepts (`probes/b05`). The discriminator is the tainted
  loop-carried accumulator.
* **Wall 4** — `loop-carried tainted value crosses iterations`, **X1 / bd `ej5w` /
  W3**, behind wall 3.

⚠ **The four-wall table is still not exhaustive.** `LLVMContext::diagnose` EXITS on
the first `DS_Error`, so each row is only *"the first decline once the row above is
gone"*. This track now has a binary on which rows 1 and 2 are **genuinely** absent
rather than hand-removed — which is new — and it confirms row 3 and nothing beyond
it. **Whoever lands (c3) + W3 must run the sequence forward on the real subject
binary and REPORT ITS LENGTH, not assume four.**

The program is committed as `tests/e2e/slice_railbank_owner_cascade.c`, code body
**byte-identical** to the owner's file by the `sed -n '83,95p;129,131p'` recipe in
its own header (sha `bf3b96de…`), **unregistered and with no golden** because it
declines. **bd `zwtm` does NOT close here** — it closes when (c3) + W3 land and
that slice is registered.

---

## WHY THE THREE PIECES ARE ONE COMMIT

Because two of them without the third is a **silent miscompile with a measured
trace**, reproduced on this track's own base binary before the fix:

> piece 3 without piece 1 → `opt` exit 0, STRICT 2b `0 violation(s), 0 unproven`,
> a plausible **6-line** trace of three minted and rotated rails — and the
> program's **three written `cq_measure` calls emitting nothing at all**, because
> `MeasureLowering`'s classical split on an untainted operand emits no gate, no
> symbol and no trace line. **A golden byte-diff cannot see a measurement that was
> never emitted.**

And a second one, visible only **outside `main`** — where 76 of 80 sampled e2e
slices live: without the D1 spine door the compiler emitted `ry(+0.5); ry(−0.5);
cqrt_free` **per cell**, un-preparing and freeing the three qubits the user was
about to measure, at `opt` exit 0 with stage 2b reporting `1 verified, 0
violation(s), 0 unproven`.

---

## WHAT IS OWED, AND BY WHOM

* **The four Rule-13 rounds.** This track ran **none** — they are a reviewer's.
  `IMPL_B2.md` §12 hands them their named subjects, and says which one this track
  is least confident about (round 4: D6's five subtraction sites were measured
  unreachable for a bank rail and deliberately **not** widened).
* **`cq-opt-equivalence-full`** — owed at the group gate: this increment adds two
  decline strings and stops one arm declining, so it moves decline populations.
* **The full `ctest -j6`** — the merge-and-gate agent's, never this track's.
* **F-3 is a scope question, returned with a measurement, not a decision**: all
  three promoter clauses B2 / B5 / B4′ have **structurally unreachable** subjects
  (Track A's carve refuses every candidate first). No B clause was deleted; each
  fixture now states the shadowing and the widening that restores isolation.
* **Two injection mutants are MISSED and stay MISSED**, both with stated reasons:
  M2 (the `isRailBankAlloca` conjunct on the accept arm) has no constructible
  subject, and M10 (the type rewrite's half of the width fence) is refused by D5
  first. Both are kept — dropping either makes the compiler accept MORE — and
  reported rather than removed from the matrix.
* **Two over-declines are FILED, not fixed**: a `char`-cell bank whose stored
  value is narrowed (`b0[i] = (char) q`) declines because the rail-width
  derivation reads any cast, not only a widening one — **measured safe** (every
  reader is unadmitted, so the module declines rather than dropping a gate), and
  costed as a two-sided change needing its own Rule-13 round because half of it
  is a miscompile; and the `int`-cell bank with CONSTANT-INDEX reads, which
  `-O1` spells as byte-offset geps the carve refuses.
* ⚠ **One OVER-ACCEPT WAS SHIPPED AND FOUND BY THIS TRACK'S OWN REVIEW, NOT BY A
  GATE**: a bank cell measured at a width other than the rail's dropped the
  truncation gate the register spelling emits. Fenced, pinned by
  `railbank_reject_measure_width_pun.ll` and by mutant M9, and written up in
  `IMPL_B2.md` §11.0. **The Rule-13 rounds have not run; a green suite clears
  nothing here.**

---

## THE ONE SENTENCE NOT TO WRITE

Do not write *"the rail bank makes the owner's Grover cascade compile"*, and do
not write *"the decline moved"*. Write what E5 ruled:

> **the bank compiles; the owner's cascade needs (c3) + W3.**
