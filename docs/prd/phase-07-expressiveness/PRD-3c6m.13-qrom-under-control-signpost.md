# PRD — bd 3c6m.13: libm L5 QROM const-global read widening → **empirically re-scoped** to a precise under-control signpost decline

**Status:** written at start (Rule 16). **Branch:** `3c6m.13-qrom-under-control-signpost`.
**Date:** 2026-07-11. **Author:** agent (owner away at decision point; proceeded on
best judgment per the Prime Directive + Rule 17, see §2).

---

## 1. The empirical finding (Rule 11 — measured, not assumed)

The ticket (and bd memory `libm-full-surface-empirical-decline-2026-07-11`) mapped the
18-cell **"unsupported instruction"** decline bucket (exp/exp2/cosh/sinh/erf/erfc/fmod/
remainder + f32 variants) to the **L5 QROM const-global read** lever, on the theory that
`ln2HI[xsb]` / `Zero[sx]` / `tbl[i0]` are tainted-index const-table reads whose accept-shape
is too narrow. Widening it was expected to "clear the 18-cell cluster" and flip exp/fmod to
COMPILES.

**Measured (real openlibm bodies, census pipeline `internalize,always-inline,globaldce,
default<O2>,scalarizer,instcombine,dce`, then `cq-lowering`):**

| | Baseline (real pass) | With QROM-under-control accepted (throwaway probe) |
|---|---|---|
| exp exp2 cosh sinh erf erfc (+f32) | `unsupported instruction` (the QROM read) | **`nested control flow under quantum control`** (L6) |
| fmod remainder | `unsupported instruction` | **`unknown callee`** (inner call) |
| fmodf remainderf | `unsupported instruction` | **`loop under quantum control`** (7.3) |
| **COMPILES** | 0 | **0** |

**Conclusion.** The QROM read is a **symptom, not the blocker.** It is merely the
*first-tripped* tainted instruction because `declineTaintEscapes` (CQLoweringPass step ~4)
runs **before** `detectControlRegions` (step ~6). Accepting the under-control read produces
**zero** new compiles — it only reclassifies the decline to the true, deeper blocker:
**nested tainted control flow (L6 = bd 3c6m.14)**, inner calls (L2), or loops (7.3).

**The "0 compiles" is robust, not a pass-order artifact** (independent design-review lens,
traced `ArmClassify`): even a *hand-crafted DEPTH-1* diamond `if(q<k) r=tbl[q];` — with the
read hypothetically hoisted past `declineTaintEscapes` — still declines at **detection** for
an *independent structural* reason: the load-result merge incoming has no accept path
(`walkValueChain` breaks on a `LoadInst`; the value-mux-of-a-copy-out routes to the
`value-arm swap-route` decline). De-nesting a transcendental body would **not** unlock the
QROM widen — routing a copy-out data-mux is an L6-coupled reversal-integration problem, never
a QROM accept-shape gap. (The `select` spelling `(q<k)?tbl[q]:0` evaluates both operands, so
the read is straight-line and *already lowers*; only the `br`-diamond spelling puts the read
under control, and that spelling declines at the value-mux regardless.)

Two corroborating facts:
* **Straight-line** const-global reads (int **and** fp/double via 38t2) **already lower today**
  (`lowering_qram_read_fp64.ll`). There is no genuine straight-line accept-shape gap.
* exp2's `tbl[i0]` is **not** straight-line in this corpus — it sits in a conditionally-reached
  join block (block 30, two arm predecessors). The p119 "straight-line" note was a
  corpus-config artifact; the read is under tainted control just like exp/fmod.

This **corrects** the census memory's bucket→lever map: the 18-cell bucket maps to **L6
(3c6m.14)**, not L5. It reinforces the owner's P3→P2 reprioritization of L6.

## 2. Why NOT widen the accept-shape (Prime Directive + Rule 17)

Accepting a const-global read **under tainted control** and hoisting it to unconditional is:
1. **A non-win** — 0 compiles across the whole target cluster (§1).
2. **An over-accept hazard** — it hoists a memory read out of a tainted-control arm and relies
   on `detectControlRegions` to *keep declining* the surrounding region. That safety is
   fragile: it couples QROM-accept to control-accept. The moment L6 lands and
   `detectControlRegions` accepts a region containing such a hoisted read **without integrating
   the read's control/reversal**, it is a silent miscompile. Coupling the QROM read to the
   control lowering is **L6's** job, not a standalone L5 accept-shape widen.

Per **Rule 17**, the intent (compile the cluster via QROM widening) is demonstrably
unachievable via QROM widening; the honest move is to bring the finding to the owner and, in
the interim, deliver the safe signpost + documentation rather than an over-accept stub. The
owner was away at the decision point; this PRD records the best-judgment path (the safe one).

## 3. Deliverable (this ticket) — a precise under-control signpost DECLINE

**A decline→decline signposting refinement only. No accept-shape change. No new frozen ABI.**

A tainted-index **load** whose base resolves (`walkPtrOrigin`) to a **constant global array**
`[N x E]` of an otherwise-QROM-eligible cell — i.e. the exact shape that **would** be an
accepted QROM read if it were straight-line — but that sits **under tainted control**
(`instUnderTaintedControl`), currently declines with the **misleading** generic
`kMsgOther` ("tainted value reaches an unsupported instruction"). That message implies a
*missing opcode* and sent the census itself down the wrong lever (opcode→L5). Replace it, for
this precise shape, with a **pattern-naming** diagnostic (the Bennett signpost model,
[[pointer-boundary-linearity-bennett]]):

```
kMsgQromUnderControl =
  "cq QRAM access: const-global table read under tainted control (needs nested-control lowering)"
```

Scope (all via the **shared** `matchQramAccess`, so carve/emit cannot diverge):
* Fires iff `matchQramAccess(LI, allowTaintedControl=true)` yields a **Global** (const,
  initialized) origin, its cell width is emitter-lowerable (`widthHasQramCell` — the **width
  gate** added after the design review; an i128/fp128 const read declines on WIDTH even
  straight-line, so the "needs nested-control" signpost would be a FALSE promise for it), and
  the call site is under tainted control (guaranteed by the enclosing carve branch).
* Fires on **both** the address gep (gep-under-control path) and the load (load-under-control
  path) of `classifyQramCarve`, mirroring the existing double-diagnosis (both were `kMsgOther`).
* **Loads only.** A const global cannot be stored; the store paths are untouched.
* **Does not fire** on: straight-line const-global reads (they still LOWER — no over-decline);
  i128/fp128 const reads under control (width gate → generic `kMsgOther`); a const read under
  **classical** control in a loop (`kMsgQramLoop`, unaffected — verified
  `lowering_reject_qram_in_loop.ll`).
* **Under tainted control the origin-naming matrix is unreachable** (it lives after the
  under-control early-return in `classifyQramCarve`). Empirically confirmed (Rule 11): a
  **non-const** global read under control → generic `kMsgOther`; an **aliased** (`>1`-use) gep
  under control → generic `kMsgOther`; `kMsgQramProvenance` / `kMsgQramAlias` fire only on the
  **straight-line** fall-through. The new signpost fires *only* for the const-global,
  supported-width, under-control shape; every other under-control access keeps its current
  generic decline (no over-decline, no mis-naming). A const read that is BOTH under tainted
  control AND in a loop is double-blocked → `matchQramAccess` nullopt (loop) → generic
  `kMsgOther` (an acknowledged edge; the target loop cells fmodf/remainderf are under
  *classical* control so they still hit `kMsgQramLoop`).

**Behavioral delta:** exactly one existing decline message changes — the jumptable
(`control_swap_reject_switch_jumptable.ll`), which is the identical shape (`[4 x i32]` const read
under `if(q<4)`). Its CHECK + comment are updated to the precise message; it still declines
(intent preserved). **No accept is created or broken** (an under-control const read never
lowered).

## 4. Correctness argument (why over-declining here is safe)

`opt -verify` clean ≠ correct unitary, but this change **creates no lowering** — it only
renames a decline. The one hazard class (over-decline breaking a real accept) cannot occur: a
const-global read under tainted control **does not lower today** (it declines `NotQram`→generic),
so re-declining it with a sharper message removes no capability. Over-declining is always safe
(Prime Directive); the sole risk would be *under*-declining (accepting), which this change never
does.

## 5. Done criteria

* **Red-green lit fixtures** (Rule 12), char-for-char mirrored diagnostics:
  * `lowering_reject_qram_read_under_control.ll` — const `[N x double]` read in a tainted
    if-diamond arm → `kMsgQromUnderControl` (NEW positive-for-decline).
  * `control_swap_reject_switch_jumptable.ll` — CHECK updated to `kMsgQromUnderControl`
    (same shape; still declines).
  * Over-accept / boundary probes (all verified empirically, Rule 11):
    `lowering_reject_qram_read_under_control_nonconst.ll` — **non-const** global under control
    → generic `kMsgOther` **and** `CHECK-NOT` the new msg (pins const-only scoping);
    `lowering_reject_qram_read_under_control_wide.ll` — **i128** const read under control →
    generic `kMsgOther` **and** `CHECK-NOT` the new msg (pins the **width gate**);
    `lowering_reject_qram_read_under_control_cohescape.ll` — const read under control whose value
    **coherently returns** (non-`main`) → generic `kMsgOther` **and** `CHECK-NOT` the new msg
    (pins the **coherent-escape gate**, Rule-13 defect); straight-line const reads still LOWER
    (`lowering_qram_read_*` untouched, re-run green); the iw81.7 guarded Shadow store still
    `DeferControl`s (existing `lowering_qram_guarded_store*` fixtures re-run green — the new check
    is placed AFTER the store-defer short-circuit).
* **Full `ctest` green**; `gen_templates.py --check` clean (no ABI touched).
* **No e2e link golden** — a decline does not link; the done-layer for a decline is the lit
  fixtures (documented divergence from the usual "≥1 e2e" criterion, which applies to lowering
  wins).
* **Rule-13 independent adversarial clearance** (core-adjacent decline path) before commit.
  Round 1 (5 refute lenses) FOUND a real defect (2 lenses, same root cause): a const-global
  read under control whose value **coherently escapes** to a non-`main` `ret` mis-fired the
  signpost — control is NOT its sole blocker (the no-cloning fence `kMsgQramCohEscape` kills it
  even straight-line). FIX: the helper now also excludes `non-main && coherentlyEscapesToReturn`
  (it must replicate **every** straight-line-accept gate `lowerQramReads` applies — coherent
  escape + width — so "would lower if hoisted straight-line" is literally true). Probe
  `lowering_reject_qram_read_under_control_cohescape.ll` pins it (→ generic, not the signpost).
  Round 2 (focused re-clearance) re-verifies the fix against the rebuilt pass.
* bd memory recording the finding + census (`INJECTION-CENSUS.md`) correction + honest ticket
  close pointing at L6 (3c6m.14).

## 6. Out of scope / follow-ons

* The genuine "QROM read inside a controlled arm" capability (hoist read-only const-global reads
  out of tainted arms before detection, integrated with the control lowering + reversal) is
  **L6-flavored** with over-accept hazards and **no** libm payoff at depth-1 (all cluster cells
  are nested/loop/inner-call). Deferred to / folded into **3c6m.14 (L6)**.
* Owner decision still open (asked, away): whether to close 3c6m.13 as subsumed by L6, build the
  speculative hoist capability, or pivot straight to L6. This PRD lands the safe interim.
* **Read-level accuracy (Rule-13 round-2 NIT, no correctness risk).** The signpost asserts the
  *read* would lower if hoisted straight-line, blocked solely by control — which stays true even
  when the loaded *value* has an **orthogonal downstream blocker** (used as a quantum-derived
  rotation angle, stored to memory, or passed to an unknown callee): those gates are on *separate*
  instructions that run AFTER `lowerQramReads` accepts the read, so the read genuinely satisfies
  the helper's contract. Either way the program declines loudly (no accept). The wording is about
  the *read*, not a promise the whole function compiles post-L6.
