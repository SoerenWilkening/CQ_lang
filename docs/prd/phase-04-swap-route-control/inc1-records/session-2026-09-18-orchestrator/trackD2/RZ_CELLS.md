# `m_rz_eq_rz` / `m_rz_eq0_rz` / `m_rz_gt_rz` — the Rz-stem × Rz-arm corner of the 15 cells Track D2's P4 widening admitted

**VERDICT: (a) — SAME UNITARY.** The rolled side drops nothing observable and the flat side
over-emits nothing wrong. The divergence is entirely `-O1`'s **DIAMOND FUSION WITH ANGLE PHIS** on
the flat side, which converts source-level GLOBAL phases into a conditional angle-select pair whose
**net relative phase is exactly zero**. Neither (b) nor (c).

Answered per the coordinator's instruction, with the argument written before any disposition.
Sources regenerated READ-ONLY via `tools/loop_twin_matrix.py`'s `sources(..., surface="void")`
(`probes/rz_cells/gen_rz.py`); the matrix itself was NOT run and `tools/loop_twin_matrix.*` were NOT
edited (Track V owns them).

---

## 1. The three binaries, and the measurement that settles (c) before any argument

`probes/rz_cells/*.c`, run through `$SES/PROTOCOL.md`'s per-probe pipeline on all three binaries.
**md5 = md5 of the lowered IR with the `ModuleID` line stripped.**

| cell | half | ORACLE `9bd01598…` | SUBJECT `5ee9d144…` (D2) | COMBINED `96d74fe6…` |
|---|---|---|---|---|
| `m_rz_eq_rz` | rolled | **DECLINE** `condition predates a non-diagonal gate` | ACCEPT `38c471b1…` | ACCEPT `38c471b1…` |
| | unrolled | ACCEPT **`e170885e…`** | ACCEPT **`e170885e…`** | ACCEPT **`e170885e…`** |
| `m_rz_eq0_rz` | rolled | **DECLINE**, same string | ACCEPT `72bad013…` | ACCEPT `72bad013…` |
| | unrolled | ACCEPT **`93b158bc…`** | ACCEPT **`93b158bc…`** | ACCEPT **`93b158bc…`** |
| `m_rz_gt_rz` | rolled | **DECLINE**, same string | ACCEPT `8aac9785…` | ACCEPT `8aac9785…` |
| | unrolled | ACCEPT **`234c3824…`** | ACCEPT **`234c3824…`** | ACCEPT **`234c3824…`** |

⚠ **This table disposes of (c) by measurement, not by argument.** Every `.unrolled` md5 is
**BYTE-IDENTICAL on all three binaries**. The flat side is **untouched** — by this landing and by the
combined merge. If it were an over-emission it would be a pre-existing one that neither Track D2 nor
Group 1 created or can be asked to have created. (It is not one; §4.)

⚠ And the rolled md5s are **identical on SUBJECT and COMBINED**, so this shape has **no interaction
with Group 1** — the divergence is D2's admission and nothing else's.

---

## 2. The source, and what `-O1` does to each half — READ FROM THE IR, not assumed (Rule 11)

`m_rz_eq_rz` (the other two differ ONLY in the compare: `eq 0` and `sgt 5`):

```c
int a = cq_theta(a, 0.5);
for (int i = 0; i < 2; ++i) {          /* rolled */
    cq_phi(0.125);                     /* P: UNCONTROLLED */
    if (a == 5) { cq_phi(M_PI); }      /* R: the kickback */
    cq_phi(-0.125);                    /* S: UNCONTROLLED */
}
return cq_measure(a);
```

⚠ **`P` and `S` are UNCONTROLLED `cq_phi`. By Rule 3 they are GLOBAL PHASES and are DELETED.** That
is not an omission by either side; it is the specified lowering, and it is what makes the two sides
comparable at all.

### ROLLED stage-1 (`probes/rz_cells/m_rz_eq_rz.rolled.s1.ll`)

```llvm
  %2 = icmp eq i32 %1, 5          ; LICM-hoisted to the ENTRY block  <- D2's P4 customer
5:                                ; loop header  = the region's Pred
  tail call void @cq_phi(0.125)   ; P — uncontrolled, in the header
  br i1 %2, label %7, label %8
7:  tail call void @cq_phi(PI)    ; R — the ONLY controlled phase
8:  tail call void @cq_phi(-0.125); S — uncontrolled, in the latch
```

One region per trip; `P`/`S` stay uncontrolled. **This is the shape bd `drbq.12` admits**, and it is
why the rolled half declined on the oracle.

### UNROLLED stage-1 (`probes/rz_cells/m_rz_eq_rz.unrolled.s1.ll`) — `-O1` FUSES THE TWO DIAMONDS

```llvm
  tail call void @cq_phi(0.125)                    ; P1 — entry, uncontrolled
  %2 = icmp eq i32 %1, 5
  br i1 %2, label %3, label %4
3:  tail call void @cq_phi(PI)                     ; R1
    tail call void @cq_phi(-0.125)                 ; S1   <- sunk INTO the arm
    br label %4
4:  %5 = phi double [ 0.125, %3 ], [ -0.125, %0 ]  ; <- ANGLE phi
    %6 = phi double [ PI,    %3 ], [  0.125, %0 ]  ; <- ANGLE phi
    tail call void @cq_phi(%5)
    tail call void @cq_phi(%6)
    tail call void @cq_phi(-0.125)                 ; S2 — uncontrolled
```

**There is ONE diamond left, and the SECOND region has been folded into two ANGLE phis on the merge.**
The rewrite is faithful — it preserves the per-path call sequence exactly:

* **`a == 5`:** `0.125, PI, −0.125` (entry+arm) then `%5 = 0.125, %6 = PI`, then `−0.125`
  ⇒ `0.125, PI, −0.125, 0.125, PI, −0.125` = **the source's six calls, in order** ✓
* **`a != 5`:** `0.125` then `%5 = −0.125, %6 = 0.125`, then `−0.125`
  ⇒ `0.125, −0.125, 0.125, −0.125` = **the source's four calls, in order** ✓

⚠ **That fold is the whole finding.** A slot that held a GLOBAL phase in the source now holds a
*different angle on each edge* — so what the source wrote as unobservable becomes, to the pass, a
legitimate **Rz-stem angle select** (`AngleSelectEmit`: *"a KICKBACK PAIR … no subtraction, so
run-time arms are admissible here"*). The pass lowers it correctly. It is not the pass's job, and
not `-O1`'s, to know the two angles were globals.

---

## 3. The two streams, per path, with the arithmetic

Convention read off CLAUDE.md, not assumed: `cqrt_rz_i1(f, θ)` contributes **+θ** to the relative
phase Δ between the `f = 1` and `f = 0` components; and
`cqrt_x(f); cqrt_rz_i1(f, θ); cqrt_x(f)` contributes **−θ**, because
`X·P(θ)·X = e^{iθ}·P(−θ)` — *"a global phase, which is already discarded."*

### ROLLED — 11 trace lines, 2 flag groups

```
alloc_i32(0)->h0 ; ry_i32(h0,0.5)
icmp_eq(h0,5)->h1 ; rz_i1(h1, PI) ; icmp_eq_unc(h1,h0,5) ; free(h1)      Δ₁ = PI
icmp_eq(h0,5)->h2 ; rz_i1(h2, PI) ; icmp_eq_unc(h2,h0,5) ; free(h2)      Δ₂ = PI
measure(h0)
```
`P`/`S` deleted (uncontrolled). **Δ_rolled = 2·PI.** STRICT 2b `1 rail mint / 1 left allocated,
1 template rail mint / 0 left dirty, 2 free sites: 2 verified, 0 violations`.

### UNROLLED — 22 trace lines, 3 flag groups

```
alloc_i32(0)->h0 ; ry_i32(h0,0.5)
G1  icmp->h1 ; rz(h1, PI) ; rz(h1, −0.125)            ; unc ; free   Δ₁ = PI − 0.125
G2  icmp->h2 ; x ; rz(h2, −0.125) ; x ; rz(h2, +0.125); unc ; free   Δ₂ = −(−0.125) + 0.125 = +0.25
G3  icmp->h3 ; x ; rz(h3, +0.125) ; x ; rz(h3, PI)    ; unc ; free   Δ₃ = −(+0.125) + PI = PI − 0.125
measure(h0)
```
STRICT 2b `1 rail mint / 1 left allocated, 3 template rail mints / 0 left dirty, 3 free sites:
3 verified, 0 violations`.

**Δ_unrolled = (PI − 0.125) + 0.25 + (PI − 0.125) = 2·PI + 0 = 2·PI.**

### Every gate accounted for, and the ±0.125 sub-sum is EXACTLY ZERO

| source call | rolled | unrolled |
|---|---|---|
| `P1 = +0.125` (entry) | deleted, uncontrolled | deleted, uncontrolled |
| `R1 = PI` (arm) | G1 `rz(h1,PI)` | G1 `rz(h1,PI)` |
| `S1 = −0.125` | deleted, uncontrolled | **G1 `rz(h1,−0.125)`** — `-O1` sank it INTO the arm |
| `P2 = +0.125` / `S1` on the ¬f path | deleted | **G2**, the angle phi `%5` = [+0.125 ∥ −0.125] |
| `R2 = PI` / `P2` on the ¬f path | G2 `rz(h2,PI)` | **G3**, the angle phi `%6` = [PI ∥ +0.125] |
| `S2 = −0.125` (merge) | deleted | deleted, uncontrolled |

±0.125 contributions to Δ on the unrolled side: `−0.125` (G1) `+0.25` (G2) `−0.125` (G3) = **0**.

**That zero is not a coincidence and is the crux of the argument.** `-O1`'s fold preserves the
per-path call SEQUENCE (§2), so the per-path TOTAL phase is preserved. The two sides therefore differ
only in **which portion of that total is expressed as a deleted global phase versus an emitted flag
phase** — and a quantity that is equal on both paths is by definition a global phase, i.e. Δ = 0 for
it. Per path, explicitly:

| path | source total | rolled emitted | unrolled emitted |
|---|---|---|---|
| `a == 5` | `0.125 + PI − 0.125 + 0.125 + PI − 0.125` = 2·PI | 2·PI | `PI − 0.125 + 0.125 + PI` = 2·PI |
| `a != 5` | `0.125 − 0.125 + 0.125 − 0.125` = 0 | 0 | `−0.125 + 0.125` = 0 |

**Both circuits implement `diag(1, e^{i·2·PI})` on the `(a != 5, a == 5)` split. Same unitary.**

⚠ **THE ARGUMENT DOES NOT DEPEND ON THESE PARTICULAR ANGLES, AND THAT IS MEASURED RATHER THAN
ASSERTED.** The matrix's `rz` axis happens to use `+0.125` / `−0.125`, which sum to zero on their own
— so "the extras cancel" could be read as an arithmetic accident of the cell. It is not.
`probes/rz_cells/nc_{rolled,unrolled}.c` are the same program with a **NON-CANCELLING** pair,
prefix `+0.125` and suffix `+0.3`. Measured on the SUBJECT:

```
nc_rolled    : rz(h1, PI) | rz(h2, PI)                                    Δ = 2·PI
nc_unrolled  : G1 rz(h1,PI), rz(h1,+0.3)                    Δ₁ = PI + 0.3
               G2 x rz(h2,+0.3) x, rz(h2,+0.125)            Δ₂ = −0.3 + 0.125 = −0.175
               G3 x rz(h3,+0.125) x, rz(h3,PI)              Δ₃ = −0.125 + PI
                                            Δ = 2·PI + (0.3 − 0.175 − 0.125) = 2·PI
```

Per path: unrolled emits `2·PI + 0.425` on `a == 5` and `0.425` on `a != 5` — the source's own totals
are `2·PI + 0.85` and `0.85`, and the difference `0.425` is EQUAL ON BOTH PATHS because it is exactly
the two deleted globals `P1 = 0.125` and `S2 = 0.3`. A quantity equal on both paths is a global phase.
**Δ = 2·PI on both sides with angles that cancel and with angles that do not.**

Nor does it depend on `2·PI ≡ 0`: the per-path totals agree **exactly**, not modulo 2π.

⚠ **Nor is it confined to the double-sided corner.** The one-sided controls behave identically and
are in `probes/rz_cells/`: `m_rz_eq_none` unrolled emits `rz(PI), rz(+0.125), rz(PI), x rz(+0.125) x`
on ONE CSE'd flag ⇒ Δ = PI + 0.125 + PI − 0.125 = 2·PI; `m_none_eq_rz` unrolled emits
`rz(PI), rz(−0.125), rz(PI), x rz(−0.125) x` ⇒ Δ = 2·PI. Both equal their rolled halves. So the
family is one mechanism, not three special cases.

---

## 4. Why it is (a) and not (b) or (c) — each ruled out by name

* **NOT (b) "the ROLLED side DROPS rotations."** What the rolled side does not emit is exactly the
  UNCONTROLLED `cq_phi(±0.125)` calls, and Rule 3 requires them to be deleted: *"uncontrolled or
  classically controlled it is a global phase and is DELETED."* Δ_rolled = Δ_unrolled = 2·PI, so
  nothing observable is lost. **The rolled side is the MORE canonical of the two** — it is what the
  source says, with the globals gone; the flat side additionally carries `-O1`'s fold as real gates.
  ⚠ Stated as a falsifiable claim rather than a reassurance: if the rolled side had dropped a
  *controlled* phase, Δ_rolled would be `PI` or `0`, not `2·PI`. It is `2·PI`.
* **NOT (c) "the FLAT side is wrong."** It is a faithful lowering of the stage-1 IR (§2's per-path
  sequence check), its extra gates are phase-neutral (§3), its rails are clean (3/3 verified,
  0 dirty), and it is **byte-identical on all three binaries** (§1) — pre-existing and untouched.
* **(a) holds, and the residue is STRUCTURAL: rail COUNT and rail STRUCTURE.** 3 flag rails vs 2.
  Every one is minted by an `icmp`, phased by DIAGONAL gates only, stripped by its own `_unc` and
  freed at `|0⟩`. ⚠ `h0` — the USER's register — is **never** `cqrt_x`-bracketed and **never** freed
  on either side: every `cqrt_x` in the flat stream is on the FLAG ancillas `h2`/`h3` (Rule 7).

⚠ **This is the S3 CLASS but not the S3 FOLD, and the distinction is why these three needed a
separate look.** Owner ruling S3 (2026-09-17) blesses *"the rolled form emits a real compare + strip
on every trip … while `-O1` folds the flat twin's"* — that is the **flag-CSE** fold, which is the 12.
These three are a **different `-O1` transformation**: DIAMOND FUSION with ANGLE PHIS, which does not
merely re-use a flag but **turns a global phase into a conditional one**. Same conclusion, different
mechanism, so it earns its own row and its own argument rather than being waved through under S3.

---

## 5. Disposition — QUARANTINE-READY, and what I can and cannot produce

**These three (and their `_none`-suffixed siblings in the same 15) are a blessed, phase-neutral
divergence. They should be QUARANTINED, not "fixed" and not removed.** The per-trip / per-path
unitary argument owner ruling S3 requires is §3 above.

⚠ **I cannot write the quarantine row and deliberately did not try.** `tools/loop_twin_matrix.*` are
Track V's exclusively (ROUTING R14) and a row is pinned by *"(verdict, SHA-256 of the exact unified
diff)"* — a signature only a matrix RUN produces, and I was instructed not to run it. The row must be
minted by the merge-and-gate agent with `--refresh-quarantine` on the combined binary. What this file
supplies is the two things the quarantine cannot generate for itself:

* **`class:`** `-O1` DIAMOND FUSION WITH ANGLE PHIS turns a source-level GLOBAL `cq_phi` into a
  conditional angle-select pair on the flat side; the rolled side keeps it uncontrolled and deletes
  it (Rule 3). Net relative phase of the extra gates: **exactly 0**, verified per path.
* **`owner:`** *"rolled is not deficient. Δ_rolled = Δ_unrolled = 2·PI, per path, exactly. The
  divergence is rail COUNT and rail STRUCTURE (3 flags vs 2), all diagonal, all stripped, all freed
  at |0⟩; `h0` untouched on both sides."*

⚠ **RETIREMENT TRIGGER for this blessing, and it is the one a future reader should test first:** the
argument rests on `cqrt_rz_i1` being **DIAGONAL** and on `X·P(θ)·X ≡ P(−θ)` up to a global phase. The
day a phase arm emits anything NON-diagonal on a flag, or the day `cqrt_x` appears on `h0` rather
than on an ancilla, **Δ stops being additive and this whole file must be re-derived from the
streams** — not re-read. CLAUDE.md records three earlier phase-arm generations that put a tensored Rz
on the user register and made every shipped Grover golden the identity; that is the direction this
blessing would fail in.

⚠ **What this file is NOT.** It is an analytic per-path reading by the implementing track (Rule 2: no
simulation, and *"a green suite alone does not clear a core change"*). It is **not** an independent
Rule-13 clearance, and the quarantine's own rule is that adding a cell is *"a human decision with a
bd issue attached."* The gate's own `MATRIX_ADJUDICATION.md` §B says the same of its 4-cell sample:
*"THIS IS AN ARGUMENT, NOT A CLEARANCE, AND I AM NOT THE AGENT WHO MAY GRANT ONE."* I have raised its
sample from 4 of 15 to 6 of 15 (three Rz corner + three controls) and read the stage-1 IR behind
them; the remaining 9 share the mechanism by name and are **not** individually measured here.

---

## 6. NO COMMIT TO THE PASS SOURCE

Verdict (a) needs **no fence**, so there is nothing to land in `ir-pass/`. The branch tip is
unchanged at `460ecefe` except for this record and its probes. `git diff … -- ir-pass/src` stays
EMPTY and `cq-opt` stays `5ee9d14420c3533a…`, so every gate cited at that hash remains citable and no
suite re-run is licensed.

### §bd — text for the orchestrator (bd writes only from the MAIN checkout)

```
bd create --title "Quarantine row owed: the Rz-stem x Rz-arm twin cells (m_rz_{eq,eq0,gt}_rz and their _none siblings) diverge rolled-vs-unrolled by a PHASE-NEUTRAL -O1 diamond fusion" --type task --priority 3 --labels control-in-place,loop,instrument --description "Admitted by bd drbq.12's P4 widening (the rolled half declined 'condition predates a non-diagonal gate' on the ORACLE and now compiles). Adjudicated (a) SAME UNITARY in trackD2/RZ_CELLS.md with a per-path argument: the matrix's rz prefix/suffix are UNCONTROLLED cq_phi, i.e. GLOBAL phases the rolled side deletes per Rule 3; on the flat side -O1 FUSES the two diamonds into one with two ANGLE PHIS, so a slot that held a global phase now holds a different angle on each edge and the pass correctly lowers it as an Rz-stem angle-select kickback pair. The rewrite preserves the per-path call SEQUENCE, so the per-path TOTAL phase is preserved and the extra gates contribute EXACTLY 0 to the relative phase: rolled Delta = unrolled Delta = 2*PI on the a==5 branch, 0 elsewhere, verified per path and re-derived with non-cancelling angles. Residue is rail COUNT/STRUCTURE only (3 flags vs 2), all diagonal, all stripped, all freed at |0>, h0 never bracketed and never freed on either side. MEASURED: every .unrolled md5 is BYTE-IDENTICAL on ORACLE 9bd01598, SUBJECT 5ee9d144 and COMBINED 96d74fe6, so the flat side is pre-existing and untouched; the rolled md5s are identical on SUBJECT and COMBINED, so there is no Group-1 interaction. This is the S3 CLASS but a DIFFERENT FOLD from the 12 flag-CSE cells - diamond fusion with angle phis, not flag CSE - so it needs its own quarantine row. The row's signature can only be minted by a matrix run (--refresh-quarantine) by the merge-and-gate agent; trackD2 did not run or edit the matrix (ROUTING R14). Probes, both stage-1 IRs and the per-path tables: trackD2/probes/rz_cells/ and trackD2/RZ_CELLS.md. NOT an independent Rule-13 clearance; 6 of the 15 cells measured, 9 share the mechanism by name only."
```
