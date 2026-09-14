# Track S — the OPEN P1: `markIfRailLocal`'s silent refusal (bd `s82e`)

Worktree `/Users/sorenwilkening/Desktop/CQ_s82e`, branch `s82e-raillocal-proof` (off `main` `6db48142`).
Records: `$SES/trackS/` **in your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/`;
`$SESP` = `…/session-2026-09-14-orchestrator/`; `$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md` (**binding**), `$SES/DECISIONS.md` **D2 (the owner ruling that
scopes you, and the two dispositions it explicitly REJECTED)**, `CLAUDE.md` (Prime Directive; Rules 1,
2, **5**, **6**, **8**, 11, 12, **13**, 14, **17**, 19; CORRECTNESS RISK §3 **L1/L2/L3/L10**),
`bd show s82e` (**⚠ its own text recommends the DECLINE the owner just rejected — D2 supersedes it**),
`bd show wx8g`, `$SESP/trackW/REVIEW_W_R2.md` (finding **F-W2-3**, which is this bead).

**Why you are on the critical path:** the owner's order for the whole capability is
**W1 (`xdu2`) → `s82e` → W2 (`wx8g`'s `Rollable` clause) → W3 (`ej5w`)**, under the 2026-09-14 Q3
ruling *correctness over expressiveness*. W3 lands directly on you. You are **fully independent of the
rail bank** — no coordination with Tracks A/B beyond not touching their files.

---

## 1. The site, read in source (verify it yourself — Rule 11)

`markIfRailLocal`, `ir-pass/src/LoopLowering.cpp:3492`. The clause is at **`:3547-3566`**:

```cpp
      for (Value *Op : I.operands())
        if (taint.Tainted.count(Op)) {
          auto *OpI = dyn_cast<Instruction>(Op);
          if (!OpI) return;
          if (!L->contains(OpI->getParent()) && !onRail(Op))
            return;   // an accumulating loop-invariant tainted input.
```

**`return;` — a SILENT refusal.** Nothing is marked, `AnyLocal` never becomes true for that path, the
region is **emitted anyway**, and the per-activation uncompute and free are left unpaired.

⚠ **The comment that follows it, `:3554-3565`, is the thing you must argue with, not around.** It says
the clause is *"LOAD-BEARING FOR A UNITARY, NOT A LEAK"*: `Uncomputation.cpp`'s §4/§2.9 pair asks each
endpoint separately whether it repeats, never whether the two repeat **EQUALLY**, so a recovered gate in
the PREHEADER (does not repeat) with `At` in a body marked here (repeats K times) *"would emit K
adjoints against ONE forward gate."* And: *"Widening it — even 'just' to admit a hoisted loop-invariant
temp — makes it reachable, and **no shipped test would go red**. Re-derive the multiplicity there
first."*

**So the clause trades a MULTIPLICITY MISCOMPILE for a LEAK, and the refusal is right about the thing
it names.** The bead's finding is about what happens *after* it refuses.

## 2. What the owner ruled, and the fork you must watch for

`$SES/DECISIONS.md` **D2 — PROVE IT**, on the orchestrator's reading put to the owner:

> those rails are entangled, so freeing them would be a hidden measurement and **"left allocated" is
> CORRECT** (Rule 6's accepted qubit leak in the qubits-not-scarce regime) — the defect is that
> `markIfRailLocal` gets there by a **silent refusal rather than a proof**.

**REJECTED, explicitly:** *DECLINE loudly* (it would decline the rolled cascade the owner asked for —
an over-decline by the 2026-09-11 ruling, and W3 would land on it) and *DISCHARGE / free them*
(freeing an entangled which-path rail is the Rule-6/Rule-8 hidden measurement).

⚠ **THE RULING HAS A PREMISE AND YOU MUST TEST IT FIRST.** The bead's measurement is a **trace
divergence between the rolled form and its hand-unrolled twin** — 16 vs 20 lines on
`w2k_noregion_invread.c`, 30 vs 38 on the in-loop PHASE region, 44 vs 48 on the in-loop 4.4 SELECT.
Two readings:

* **(R-leak)** the two forms denote the **same unitary**, and the rolled form merely leaves more rails
  allocated. Then D2's premise holds, "left allocated" is correct, and your job is to make the
  disposition **explicit and proven** instead of silent.
* **(R-diverge)** the two forms denote **DIFFERENT unitaries** — the unrolled one discharges gates the
  rolled one does not, and the entangled garbage the rolled one leaves **dephases under later
  interference** (`CLAUDE.md` Rule 8: *"a permutation that leaves a rail dirty **and entangled** still
  dephases under later interference"*). Then D2's premise is **FALSIFIED** and this is a genuine silent
  miscompile, not an accepted leak.

**Determine which, analytically and per program, BEFORE you write a fix, and report it to the
orchestrator the moment you know.** If it is (R-diverge), **STOP and come back** — the disposition is
an owner decision again, not yours. No statevector simulations (owner decision 2026-06-10); this is
analytic/trace reasoning, the way every other correctness question in this project is settled.

## 3. If it is (R-leak): what "PROVE" has to mean

Not a comment. A **checked property**, in the `declineSurvivingIntrinsicCalls` spirit — `CLAUDE.md`
Rule 1: that function *"makes the pass's postcondition a **checked, LOUD** property rather than a
comment; **not an `assert`**, because Release builds have assertions off and Release is what every gate
here runs."*

The shape to aim for: the clause stops being a bare `return;` and becomes a **classified disposition**
— *the marking is refused because the multiplicity pairing is unbuildable, AND the rails thereby left
allocated are proven-entangled, so leaving them allocated is the Rule-6 accepted leak* — with the
second conjunct actually **tested**, and anything that fails the test declining **loudly** rather than
falling through. A refusal that cannot prove its own consequence is exactly the silence the P1 names.

**Rule 17 governs.** The task is to remove the silence, not to replace it with a blanket decline; a
blanket decline is the disposition the owner rejected. If the proof proves genuinely unbuildable, bring
the question back rather than shipping the refusal with a nicer comment.

## 4. The witness, and the instrument caveat that matters most here

⚠ **The rolled-vs-hand-unrolled trace pair is the ONLY instrument in the tree that sees this class.**
Say so in every record you write.

* **stage 2b `free_pairing_check.py` reports `0 violation(s)` on every one of these programs** —
  it counts `cqrt_alloc` **SITES**, so a rolled per-trip alloc reads as **one** rail when the circuit
  mints K, and it is structurally blind to template-minted rails (no `cqrt_alloc` to count).
  **Do NOT cite 2b as clearance.**
* `e2e-loop-twin-matrix` (338 cells since bd `uq96` gave it an `i1` axis) **is** the tree's rolled-vs-
  unrolled instrument. ⚠ **You do not run it** (PROTOCOL: the merge-and-gate agent does, inside the full
  suite). If your increment needs new cells, **name them in `IMPL_S.md`** with a written reason and the
  merge agent generates them.
* ⚠ **`tools/loop_twin_matrix.quarantine.txt`** pins blessed divergences by
  `(verdict, SHA-256 of the exact unified diff)` and **fails if the signature moves, if the cell stops
  diverging, or if it appears in both files**. If your fix moves a quarantined cell, that is expected
  and must be adjudicated in writing, never `--regenerate`d away. ⚠ bd `gfsk`: `--regenerate` once
  silently ate **54 lines of Rule-13 ruling prose** from a baseline header and reported success.
* ⚠ **L10 / the 2026-09-14 lesson, six measured instances in one session:** *an instrument's failure
  mode is to report a PASS, so the only instrument worth citing is one that has been made to fail on
  purpose.* Whatever you build to witness this, **make it fail on purpose first** and report that you
  did.
* ⚠ **bd `1yeu` — a STRUCTURAL instrument gap:** every corpus and gate in the tree is effectively **ONE
  FUNCTION PER MODULE**, so a cross-function defect is invisible to all of them (two over-ACCEPTs found
  2026-09-14 passed 1937 lit fixtures, 15 e2e entries, a complete corpus sweep, a 0-MISSED injection
  matrix and 328 twin cells for that single reason). If your subject has a cross-function spelling,
  nothing in the tree will tell you.

## 5. L1 / L2 / L3 — answer in writing in `IMPL_S.md`

* **L1.** `markIfRailLocal` is reached from the loop layer; `collapseFlattenedLoopRails` runs **after the
  whole round-2 fixpoint** (`TaintPropagation.cpp:1861-1875`, and note its recorded caveat that the
  `runOnFunction` shim does **not** call the ROUND-1 `collapseFlattenedLoopRails` at all — a
  pre-existing twin-pipeline divergence from bd `8h7d.5`, **not yours to repair**, but yours to not
  widen). State where your change sits relative to the fixpoint and whether it is re-asked in **both**
  entry points.
* **L2.** `markIfRailLocal` shares closures with `markIfIterationLocal` (`:2411-2414`) and `tryBreak`
  (`:1975-1978`) — the **tainted-index memory triple**, all three scanning `I.operands()`. ⚠ `$SESP/trackL/SCOPE_L1a.md`
  §4.4(B) records the load-bearing asymmetry: for `store i32 %h, ptr %gep` the operand list is
  `{value, pointer}` so the tainted value **is caught by accident**; for a `load` the only operand is
  the pointer, so the load side **never fires**. **Do not "tidy" these to scan the pointer operand
  only** — that makes all three blind in both directions. Also on the same closure:
  `collectRailGates`'s `Gates` **and** `OnRailOut` (`:905-914`, `:975-976`), the `MemberSet` skip set
  (`:1045`) and step-5's `Skip` (`:2806-2807`) — which `LoopPlan.h:220-224` says must stay **different**.
* **L3 and its MIRROR.** If you add a caller to any shared predicate (`peelInPlaceBase`,
  `invariantRegisterRoots`, `taintedExit`, `onRail`), **read its retirement trigger and state which
  direction you are using it in.** The 2026-09-14 P1 (`IMPL_D.md` §15.4) is exactly a third *granting*
  caller arriving at a predicate whose "NOT EXPLOITABLE" argument did not reach it.
* ⚠ **The bead names a scope correction that must land with you:** bd `wx8g`'s record says its re-ask
  covers *"every grant"*; it must say **"every R7-LOOP grant"**, because this class is
  **region-independent** and the R7 slice is a strict subset. Fix that record.

## 6. Rule 12 and Rule 13

Red-green, fixtures first. At minimum: the three bead programs as pinned subjects
(`w2k_noregion_invread` and the PHASE / 4.4-SELECT spellings — get them from `$SESP/trackW/review_r2_probes/`);
a positive pinning the proven disposition; a decline fixture for every precondition your proof relies
on, each mirroring its string character-for-character. Hygiene: counts in their own whole-file prefix;
a `DS_Error` decline writes 0 bytes to stdout so IR-text `CHECK-NOT`s are vacuous; a bare `-NOT: <word>`
can match the module's own path line (bd `qta2`); `$PREV/trackM/probes/impl/vacuity.py` over the accept
batch; a 0-byte `.ll` **ACCEPTS** through the passthrough early-out.

**Rule 13: 3 rounds, stated up front.** The 2026-09-14 Track W round-2 reviewer nominated this as
*"where the next verify-clean silent miscompile already sits"* — budget accordingly. `IMPL_S.md` hands
the reviewer a written **ATTACK SURFACE**: the (R-leak)/(R-diverge) determination with its reasoning,
every predicate touched, the L1/L2/L3 answers, and the three programs most likely to be the next hole.

## 7. Gates you own — PROTOCOL §matrix, do not exceed it

Configure + build once per edit batch; **NEVER `--target CQPass` alone**. Record
`shasum -a 256 build/ir-pass/cq-opt` in `$SES/trackS/GATES.md` after every rebuild. Inner loop =
`lit --filter` + single slices. **ONCE at hand-off:** `ctest -R ir-pass-lit`, one ORACLE-vs-SUBJECT
corpus sweep → `$SES/trackS/probes/corpus_<hash16>.txt`, one injection matrix with MISSED reported.
**NEVER** the full suite, `^e2e-`, the equivalence sweep, or the twin matrix.

⚠ **ORACLE** (frozen, read-only): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` sha256
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`, `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`. Verify before your first probe.
The primary `build/` is READ-ONLY; never relink under a running measurement; never `pkill` by pattern.

⚠ **Expected corpus movers: state them in `IMPL_S.md` BEFORE you sweep**, then attribute every actual
mover. An unattributable mover is a FINDING.

## 8. Deliverables

`$SES/trackS/{IMPL_S.md, GATES.md, probes/}`: the (R-leak)/(R-diverge) determination **first and
separately**, the disposition as shipped, the L1/L2/L3 answers, the witness with its "made to fail on
purpose" record, any twin-matrix cells you need generated (named, with reasons), the `wx8g` record
correction, the fixture table, corpus movers, mutation MISSED, and the attack surface.

Commit on your branch (**no push, never touch `main`, never write outside your worktree**), message
`fix(loop): bd s82e — …` with the two `CLAUDE.md` trailers. Report back: branch tip, binary hash, gate
lines, and **anything you could not do**. **Rule 19: report only what you ran.**
