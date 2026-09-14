# Twin-matrix adjudication — merge gate 2026-09-14, BEFORE the regeneration

Binary `cq-opt 5c6f7490a81c7505…` (bit-identical before and after the e2e conversion — no pass source
was touched, so every measurement here is a fact about the gated binary). 338 cells, **41 moved**.
TRACE-DIVERGENCE stayed at **29 against 29 quarantined** and both boundary controls held
(`q_armoncond` TRACE-DIVERGENCE, `q_noregion` ACCEPT-IDENTICAL), so nothing in this table is blessing
a hard failure. Legend, from the table's own header: `UNROLLED-ONLY` = the **unrolled side lowers and
the ROLLED side declines** with the recorded message.

**This table is written BEFORE `--regenerate` is run** (Rule 12: regeneration is a written act).

---

## G1 — Track D, the stale-reader ruling. **18 cells, DECLINE-direction.**

| n | transition | cells |
|---|---|---|
| 17 | `UNROLLED-ONLY (rail record read past an in-place gate on the same rail)` → `DECLINE-BOTH-DIFFERENT` (rolled keeps that message; **the FLAT side moves ACCEPT → DECLINE** on D's new string) | `m_{add,none,ry}_{der,eq}_ry_{pre,post}mark` (12), `m_none_o{der,eq}_{add,none}_rpostmark_rypost` (4), `m_none_pbitd_none_rpremark_rypost` |
| 1 | **`ACCEPT-IDENTICAL` → `DECLINE-BOTH`** (D's new string on both sides) | `m_none_pbitd_none_premark_rypost` |

**Why the new verdict is correct, in terms of the unitary.** Every cell in this group carries the
RECORD axis, i.e. a `mark = a;` that binds a second NAME to a register which is then rotated:

```c
    mark = a;                               /* binds the name `mark` */
    if (a == 5) { a = cq_phi(a, M_PI); }
    a = cq_theta(a, -0.5);                  /* the register MOVES; the name `a` is consumed */
    return cq_measure(a) + cq_measure(mark);  /* <-- reads a name the wire has moved past */
```
`cq_measure(mark)` measures the **rotated** register while naming the pre-rotation state, so the
result is attributed to a state the register no longer holds. That is `docs/frontend.md` §3.2's linear
rule — a rotation consumes the old name — and it is exactly the P1 stale-reader class bd `3d8q` was
opened to close, here on a `cq_measure` reader rather than a `cq_theta` one. **Declining it is the
owner's ruling of 2026-09-14 applied to the reader side**; the previous ACCEPT emitted a measurement
of the wrong state, silently.

The one `ACCEPT-IDENTICAL → DECLINE-BOTH` cell is the same defect committed by **both** spellings
(`mark = a;` in the body, `a = cq_theta(a, 0.9);` after the loop, `cq_measure(mark)` at the end) —
which is why it was *identical* and why it is now *both*. A cell that agreed with itself while both
halves were wrong is precisely what `ACCEPT-IDENTICAL` cannot see; only the fence can.

**Direction: decline. Nothing that used to be a correct circuit stopped compiling.**

---

## G2 — Track W, clause (c): the ITERATION-LOCAL rolled rail. **5 cells, ACCEPT-direction.**

`UNROLLED-ONLY (control flow inside a loop body)` → **`ACCEPT-IDENTICAL`**:
`m_none_bilry_none_none_binv`, `m_none_nbilry_none_none_binv`, `m_none_bilprep_none_none_binv`,
`m_none_dilry_none_none_binv`, `m_none_bil2_none_none_binv`.

```c
    for (int i = 0; i < 2; ++i) {
        int r = cq_theta(7, 0.25);          /* a FRESH rail every trip */
        if (b) { r = cq_theta(r, 0.9); }    /* the arm, under a _Bool rail */
        s += cq_measure(r);
    }
```
**Why correct.** The rolled form mints one rail per activation and fires one
`cqrt_ry_<W>_controlled` on it, which is the same gate sequence — in the same order, on
correspondingly fresh rails — that the hand-unrolled twin emits. `ACCEPT-IDENTICAL` is not an
assertion of that: it is the **byte-diff of the two runtime traces**, so the equality of the two
circuits is measured, not argued. The previous verdict was a disposition MISMATCH (the flat spelling
of the same program already lowered), i.e. an over-decline the owner's 2026-09-11 ruling calls a
defect; bd `wx8g` removes it.

---

## G3 — Track W, the in-loop bare-`_Bool` controlled-Ry ARM (the l4x4.c carve-out retirement). **9 cells, ACCEPT-direction.**

`UNROLLED-ONLY (control flow inside a loop body)` → **`ACCEPT-IDENTICAL`**: `m_addpre_bry_none_none_binv`,
`m_none_bry_none_none_binv`, `m_none_bry_none_none_bcar`, `m_none_bry_none_bpremark_binv`,
`m_none_bry_none_bpremark_bcar`, `m_none_bry_ry_none_binv`, `m_none_nbry_none_none_binv`,
`m_none_nbry_none_none_bcar`, `m_ry_bry_none_none_binv`.

⚠ **These nine are a GAP IN THE PREDICTION, not a surprise in the compiler.** Track T's prediction
table (`trackT/IMPL_T.md` §8 and the same block in `loop_twin_matrix.py`) was written for the SECOND
pass's ten `il*` cells and never covered the FIRST pass's `*bry*` axis (`c12a2afe`), even though that
axis is bd `wx8g`'s headline capability. The correction belongs in the header, and it is made there.

**Why correct.** `if (b) { r = cq_theta(r, 0.9); }` with `b` a `_Bool` rail is the shipped l4x4.b
in-place controlled-Ry arm, now rolled: per activation the emitter fires
`cqrt_ry_<W>_controlled(h_b, h_r, θ)` in place, `b` is read ONLY as a control (never
`cqrt_x`-bracketed, never freed) and the rotated register is FROZEN — `Ry(θ)|0⟩ ≠ |0⟩`, so Rule 6
leaves it allocated. The rolled and unrolled traces are byte-identical, which is the verdict.

---

## G4 — Track W, the same retirement on the STATE-PREP branch. **8 cells, DECLINE → DECLINE.**

`DECLINE-BOTH-DIFFERENT (rolled: control flow inside a loop body ∥ flat: state prep merged with a
quantum register)` → **`DECLINE-BOTH (state prep merged with a quantum register)`**:
`m_none_bprep_none_none_{binv,bcar}`, `m_none_bprep_none_bpremark_{binv,bcar}`,
`m_none_bprep_ry_none_binv`, `m_none_nbprep_none_none_{binv,bcar}`, `m_ry_bprep_none_none_binv`.

**Why correct.** No circuit is emitted on either side before or after, so there is no unitary to be
wrong — what changed is *which fence answers*. The loop is no longer the discriminator; the prep's own
F1 fence is, and it gives the SAME verdict the flat spelling always gave. A cell whose two halves
declined for two different reasons now declines for one, which is strictly more informative and is the
shape the table calls `DECLINE-BOTH`.

---

## G5 — `m_none_ddilry_none_none_binv`. **1 cell, ACCEPT-direction, against an explicit prediction.**

`UNROLLED-ONLY (condition predates a non-diagonal gate)` → **`ACCEPT-IDENTICAL`**.

The prediction said **UNMOVED**, and added: *"if it flips, the reason is NOT clause (c) and must be
found."* **Found, and it is Track W alone** — measured across all seven binaries:

```
ORACLE f7b65d8c · U a5773be1 · F 96fdd3a9 · P 283e3b33 · D 4394b349   rolled DECLINE(2c) · flat ACCEPT
W      40edde36  (Track W's ROUND-2-CLEARED binary)                   rolled ACCEPT      · flat ACCEPT
W      d47297cf  (Track W final, post-clearance edits)                rolled ACCEPT      · flat ACCEPT
MERGED 5c6f7490                                                       rolled ACCEPT      · flat ACCEPT
```
It is in the **cleared** code, not in the three unreviewed post-clearance edits (independently
confirmed: a 2385-module sweep of `40edde36` against `d47297cf` gives 0 verdict differences and one
GAINED source location).

**THE PREDICTION'S STATED GROUND IS SIMPLY WRONG, and that is the finding — L7 in its exact shape: a
wrong reason that reached a right prediction.** The ground given was *"its rolled side declines at
gate 2c, not at the loop fence: the post-loop diffusion `a = cq_theta(a, 0.9)` is a non-diagonal gate
on the CONDITION's own wire, so gate 2c refuses it BEFORE the loop clause is ever reached."* If that
were the operative refusal it would refuse the FLAT spelling too — and the flat spelling **accepted on
the ORACLE**, all along. So 2c was never what stopped the rolled side; the loop carve-out was, and
lifting the carve-out lifted it.

**Why the new verdict is benign.** Rolled and flat traces are **byte-identical at 28 lines** and STRICT
stage 2b is clean on both (`2 mint(s)/2 free(s) verified` rolled, `3/4 verified` flat). The rolled form
now emits the circuit the flat form already emitted and that the ORACLE already accepted, so this is a
capability gain that brings the rolled spelling up to its twin — **not** a new class of accepted
program. No gate-2c ruling is required to go green; what was required was the corrected sentence, and
it is now in `EXPECTED_HEADER`.

---

## G6 — NOT in the 41: the **three `il*`×`bcar` cells that did NOT flip.** A SURVIVING OVER-DECLINE, filed.

Track T predicted eight loop-message rows would flip; **five did.** These three did not, and they are
still `UNROLLED-ONLY / control flow inside a loop body` — re-measured directly at the merge gate:

```
m_none_bilry_none_none_bcar    rolled DECLINE(control flow inside a loop body) · flat ACCEPT
m_none_nbilry_none_none_bcar   rolled DECLINE(same)                            · flat ACCEPT
m_none_bilprep_none_none_bcar  rolled DECLINE(same)                            · flat ACCEPT
```
**The blocker is the COMBINATION, and the matrix isolates it.** `bcar` re-rotates the CONDITION rail
inside the body (`b = cq_theta(b, 0.25);` at the top of each trip), so the condition register is
loop-carried and moves every activation. `wx8g`'s clause (c) covers the iteration-local **target**
rail; a condition rail rotated in-body is a different question. The isolation is measured, not
guessed: `m_none_bry_none_none_bcar` — the same carried condition WITHOUT an iteration-local target —
**did** flip. So what survives is exactly *iteration-local target rail × in-body-rotated condition
rail*.

This is a **filing, not a blocker**: the direction is safe (over-decline), the flat spelling of each
program still lowers, and per the owner's 2026-09-11 ruling an over-decline is a defect to remove
rather than a safety margin. Probes committed as
`merge_gate_probes/m_none_{bilry,nbilry,bilprep}_none_none_bcar_{rolled,flat}.c`.

---

## The regeneration

Permitted here because G1 is a ruled capability change and G2–G5 are a cleared one, and it is a
**written act**: this table is the writing. It is performed with `--regenerate`, which rebuilds the
file as `EXPECTED_HEADER` + rows — so the header's now-historical PREDICTION block is first rewritten
in place, in `tools/loop_twin_matrix.py`, into a MEASURED block carrying G5's corrected reason and
G6's filing. **Header survival is then re-verified mechanically**, because Track T measured this
instrument eating 54 lines of Rule-13 ruling prose once already.

**Nothing was regenerated to turn a red green**: the two e2e slices were converted (their goldens
DELETED, not rewritten) and the decline pinned in lit instead.
