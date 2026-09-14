# Track X — the two OWED items from 2026-09-14: the X5 re-derivation, and a Rule-13 opinion on the F × P composition

Worktree `/Users/sorenwilkening/Desktop/CQ_x5`, branch `x5-rederivation` (off `main` `6db48142`).
Records: `$SES/trackX/` **in your worktree**. `$SES` =
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/`;
`$SESP` = `…/session-2026-09-14-orchestrator/`; `$PREV` = `…/session-2026-09-13-orchestrator/`.

**READ FIRST:** `$SES/PROTOCOL.md` (**binding**), `CLAUDE.md` **§4c in full** — especially the
φ-DESCENDANT block carried verbatim, the paragraph immediately after it beginning *"THAT RETIREMENT
TRIGGER HAS ALREADY FIRED, AND THE RE-DERIVATION IS OWED, NOT DONE"*, and the *"What the group gate
found that no single track could"* bullets — plus Rules **2**, **11**, **13**, **17**, 19 and
CORRECTNESS RISK §3 **L3 and its MIRROR**, **L7 and its TWIST**, **L8**.
Then `$SESP/MERGE_FILINGS.md` §1–§3, `$SESP/MERGE_REPORT.md` §5, `$SESP/trackF/IMPL_F.md` §2,
`$SESP/trackF/CLAUDE_MD_EDITS.md` §1, `bd show om35`, `bd show hrts`, `bd show l3i1`, `bd show wx8g`,
`bd show 3qps`, `bd show 4aiu`.

**These are the two items `CLAUDE.md` records as OWED, and one of them is owed as a REVIEW rather than
as code.** You are the only track working on them. **You touch `ir-pass/src/ArmClassify.cpp` and
nothing else under `ir-pass/`** — no other track this session touches that file, so you are your own
PROTOCOL §S1 group. ⚠ Tracks A and B are working *near* F2 (the rail-bank carve); if your re-derivation
turns up anything that bears on a memory-resident wire, **tell the orchestrator immediately** — Track A's
brief already forbids teaching `railWireClosure` a memory hop, and your finding could tighten or loosen
that.

---

## Job 1 — the X5 RE-DERIVATION (the trigger that fired in its own merge)

### What happened, stated exactly

Track F's φ-descendant narrowing (bd `om35`, `30317792`) closes with a **RETIREMENT TRIGGER naming bd
`wx8g` BY NAME**:

> ⚠ **RETIREMENT TRIGGER: bd `wx8g`, by name.** Every in-loop state prep is stopped before F2 today
> (`control flow inside a loop body`), and that open over-decline is the **only** reason the back-edge
> shape is unreachable rather than merely narrowed — in-loop regions **do** reach `classifyArms`, so the
> loop is not a blanket fence. The day `wx8g` lands, re-derive the narrowing against the shapes it
> admits, and **do not assume the φ case is the only cyclic one.** The fixture pair
> `control_inplace_ry_reject_stateprep_backedge_{phi,nonphi}desc_collider.ll` is the tripwire.

**`wx8g` landed in the SAME merge** (`a2b86139`). What the group gate could measure, it measured
(`$SESP/MERGE_FILINGS.md` §1, probes committed under `$SESP/merge_gate_probes/x5{a,b,c}_*.c`):

* both named tripwire fixtures **HELD** — still decline at F2, byte-identical `CQ_CTRL_DBG` anchor to
  the oracle, `lit --filter backedge` **4/4**;
* but the trigger's **premise is now FALSE**: three probes built from the shapes `wx8g` admits go from
  `control flow inside a loop body` on the oracle to, on the merged binary, an **F1 decline with a
  source-located `!dbg`** (`x5a`, the available back-edge collider itself) and **two ACCEPTs with STRICT
  2b clean** (`x5b`, `x5c`);
* the skip is therefore **LIVE rather than vacuous**;
* and the trigger's own second sentence — *"do not assume the φ case is the only cyclic one"* — is
  **exactly the part three probes cannot discharge**.

⚠ **`CLAUDE.md` states the consequence in the only words that matter: "The argument text in
`ArmClassify.cpp` is STALE and must not be cited as it stands."** Fixing a record correction **in the
record but not in the source** is the L7-with-a-twist defect that was measured three times on one
sentence (bd `z9t1`) — *"a record correction that is not applied to the SOURCE is not a correction."*
**Your fix lands in the source comment in the same change as your write-up, or you have not fixed it.**

### What "re-derive" means here — and what it is NOT

It is **not** a licence to widen anything. The narrowing (`collectStatePrepPhiDescendants`, the
φ-DESCENDANT exclusion at F2's **TEST**) is shipped, owner-ruled (2026-09-14 **Q1**, chosen over R-2′
because it flips **zero** shipped decline fixtures where R-2′ flips **25**, 13 of which say CONFIRMED
MISCOMPILE in their own headers), and closes three customers. **Your default is that it stands and the
ARGUMENT gets rewritten to be true.** Rule 17 in reverse: do not turn a review into a rewrite.

The obligations, in order:

1. **Re-derive the narrowing against the shapes `wx8g` ADMITS.** The three committed probes are a
   starting point, not the answer. `wx8g`'s capability is: an in-place controlled **Ry** arm or
   controlled **state prep** on a bare `_Bool` **inside** a classically-bounded loop, plus an
   **iteration-local** rolled rail for every condition kind (bd `wx8g`, `a2b86139`; `CLAUDE.md`
   CORRECTNESS RISK §1, last row). **Enumerate systematically**; three probes are three points.
2. **Discharge — or explicitly fail to discharge, in writing — "the φ case is the only cyclic one."**
   The narrowing's theorem holds only for an **ACYCLIC user chain**, and the enforcement is
   `collectStatePrepPhiDescendants` **skipping a φ user that `M`'s block does not dominate**. Ask: is a
   φ the only opcode whose operand need merely dominate its incoming EDGE? What else in LLVM 19 can
   both use `M` and be available at the arm-theta arg-0 or the merge-φ pred-edge slot? **If you cannot
   bound it, say what is skipped and why the compiler could not have folded it either** (L5 — *a
   syntactic answer to a semantic question loses*; F2 lost four rounds running to exactly this).
3. **Address bd `hrts` and bd `l3i1`**, which are open filings on this very skip: *the dominance skip is
   broader than its stated rationale and has **ACYCLIC customers**, so the retirement trigger naming
   only `wx8g` describes the **CYCLIC half**.* Either reconcile the rationale with the skip's actual
   population, or state precisely what the second half is and file it costed.
4. **Rewrite the source argument** in `ArmClassify.cpp` so it is TRUE at HEAD, with a **new** retirement
   trigger that names what would make it wrong — not what has already happened. ⚠ Keep the two bullets
   `CLAUDE.md` §4c marks with ⚠ intact in substance: *never compress this to "`V` sits after the join"*
   (that is the dominance conjunct which stays **REFUSED IN WRITING**, and it is false because `-O1`
   **sinks**); and the exclusion is a **NARROWING of the EXCLUSION set**, opposite object and opposite
   direction from the refused conjunct.
5. **Do not touch the tripwire fixtures** except to update their headers to the new, true argument —
   they HELD, and an L8 header that was character-for-character correct is the project's best evidence
   that retirement triggers work. ⚠ And **do not `git mv` a fixture**: L8 records that a merge can
   **resurrect** a `git mv`'d fixture, leaving one module under two names with contradictory verdicts.

⚠ **`f2SeedPinnedByLiveRegister`'s OTHER retirement trigger, `ArmClassify.cpp:1283-1295`**, is in the
same neighbourhood: *"if `railWireClosure` as called here and R4's `CondRails` ever DIVERGE … this
narrowing must be RE-DERIVED FROM SCRATCH."* **Check whether your work touches it**; if it does, say so
loudly — that is the narrowing the owner's own three-bool file depends on.

---

## Job 2 — a Rule-13 OPINION on the F × P composition

`$SESP/MERGE_FILINGS.md` §1–§2 and `CLAUDE.md` §4c: of 290 corpus movers at the 2026-09-14 group gate,
**8 are reproduced by no single-track binary**, and three of those are **one shape** — *a condition TREE
whose leaves are preps' merge φs*: `if (b1 && b0) cq_phi(0.3)` and `if (b1 && b0) a -= 3;`.

* Track F alone clears F2 and then hits the **leaf-grammar wall**.
* Track P alone admits the leaf and then hits **F2**.
* **Only together do they accept.**

Both are STRICT-2b clean with well-formed streams — the kickback sits on a `cqrt_toffoli` of the two
rail leaves, `h0`/`h1` read only as controls, ancillas returned to `|0⟩` before their free. ⚠ **And that
is exactly the evidence Rule 2 calls NECESSARY AND NOT SUFFICIENT.** Track F's Rule-13 rounds saw a
binary on which these decline, and so did Track P's. **`CLAUDE.md` states the principle: "A composition
is not cleared by clearing its parts."**

**Deliver an adversarial Rule-13 opinion on these two accepts**, in the form the project's review
records use: analytic/trace-level reasoning, **no statevector simulations** (owner decision 2026-06-10),
against the ORACLE binary for the counterfactuals. Specifically:

* Is the emitted unitary right for `if (b1 && b0) cq_phi(0.3)` — **read the stream, do not read the
  exit code**. ⚠ The project's headline lesson: *every shipped Grover golden was the IDENTITY*, the
  traces were self-consistent, the byte-diff proves only that every symbol resolves and
  signature-matches, and there is no simulator.
* Is it right for the VALUE spelling `if (b1 && b0) a -= 3;`?
* Which fences did **each** track's rounds see standing that the composition removes? Name them by
  `file:line`. That set is where a composition defect would live.
* Are there **other** F × P compositions the gate did not construct? The gate found these by sweeping a
  corpus; a corpus finds what is in it.
* ⚠ **bd `1yeu`**: every corpus and gate in the tree is effectively **ONE FUNCTION PER MODULE** — a
  cross-function composition is invisible to all of them.

**Verdict format:** CLEAR / CLEAR-WITH-ITEMS / FINDING, with each item a `bd`-fileable paragraph. If you
find a real defect, **file it and tell the orchestrator immediately** — do not bundle it into a closing
report.

---

## Gates you own — PROTOCOL §matrix, plus one exception

You are mostly a **reviewer**, and the PROTOCOL's review row says: **no build, no suite**. But Job 1
edits a source comment and may add or amend fixture headers, so you get the **implementation** row for
that edit only: configure + build once per edit batch (`cmake --build build -j8`; **NEVER `--target
CQPass` alone**), `lit --filter` on the fixtures you touch, and `ctest -R ir-pass-lit` **ONCE at
hand-off** iff you changed anything under `ir-pass/`. Record `shasum -a 256 build/ir-pass/cq-opt` in
`$SES/trackX/GATES.md` after every rebuild. **NEVER** the full suite, `^e2e-`, the equivalence sweep, or
the twin matrix.

⚠ **ORACLE** (frozen, read-only): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` sha256
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`, `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`. **`shasum -a 256` it before
believing any decline** — a stale build is indistinguishable from a regression from outside and it cost
time in each of the last two sessions. The primary `build/` is READ-ONLY; never relink under a running
measurement; never `pkill` by pattern.

⚠ **If you change no code, you change no corpus row** — say so rather than sweeping. If you do change
the comment only, the binary is byte-identical and **every gate line is CITABLE, not re-runnable**
(PROTOCOL §S2's logic).

## Deliverables

`$SES/trackX/{X5_REDERIVATION.md, REVIEW_FxP.md, GATES.md, probes/}`:

* **`X5_REDERIVATION.md`** — the systematic enumeration over `wx8g`'s admitted shapes with each probe's
  ORACLE-vs-HEAD verdict; the discharge (or explicit non-discharge) of *"the φ case is the only cyclic
  one"*; the `hrts` / `l3i1` reconciliation; the **new** source argument as it now reads in
  `ArmClassify.cpp`, with its new retirement trigger; and the tripwire fixtures' status.
* **`REVIEW_FxP.md`** — the verdict, the per-track fence inventory, the other compositions you looked
  for, and each item as a fileable paragraph.

Commit on your branch (**no push, never touch `main`, never write outside your worktree**), message
`docs(control): bd om35 — X5 re-derivation …` with the two `CLAUDE.md` trailers. Report back: branch
tip, binary hash if you built, the verdicts, and **anything you could not do**. **Rule 19: report only
what you ran.**
