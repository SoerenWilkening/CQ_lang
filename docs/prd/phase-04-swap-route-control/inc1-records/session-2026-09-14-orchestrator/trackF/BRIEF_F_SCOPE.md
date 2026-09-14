# Track F — SCOPING brief (READ-ONLY): what R-2′ costs, fixture by fixture (bd `om35`)

**You build NOTHING and you edit NOTHING.** You work in the MAIN checkout
`/Users/sorenwilkening/Desktop/CQ_lang` against the frozen ORACLE, and you write **only** into
`$SES/trackF/` (`$SES` = `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`).
Never write under `ir-pass/ include/ runtime/ tests/ tools/ example/`. `$PREV` =
`…/session-2026-09-13-orchestrator/`.

**ORACLE, hash it before first use and STOP if it differs:**
`build/ir-pass/cq-opt` = `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`,
`build/ir-pass/libCQPass.so` = `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`.
Never rebuild it, never relink under a measurement, never `pkill` by pattern.

**READ FIRST:** `$SES/PROTOCOL.md`, `CLAUDE.md` (Prime Directive; Rules 2, 9, 11, 12, 13, 17;
CORRECTNESS RISK §2 the F1/F2 fences and §3 L5 — *a syntactic answer to a semantic question loses*),
`bd show om35` (description **and** both NOTES blocks), `$PREV/trackR/SCOPE_R.md` §1.2/§2/§3a–§3d/§4/§6,
`$PREV/trackR/SCOPE_R2.md` (the 24-probe rival audit, 14 rows, 0 holes, **stated ground wrong**), and
`$PREV/DIAG_2026-09-14.md` §Q1 (the owner's live N=3 file, the collider, the three surgeries).

---

## 1. The question the owner has to answer, and what you must put in front of them

R-2′ is: **"a pinned value that is pinned on only ONE edge is not a collider."** Its argument is complete
case analysis, not a proxy: F1 pins the pred slot, so the in-place-rotation rival is unfoldable — a **literal**
pred slot ⇒ R3 declines it; a **register** pred slot ⇒ F1 declines it. It closes the owner's live N=3 file
(`example/grover/grover_oracle_uncompute.c`) **and** `vd.c` **and** bd `rb9x`'s residual with an argument
rather than a proxy.

Its cost: it **flips ≥11 shipped DECLINE fixtures to ACCEPT** — `range_forward_*`, `sideways_*`,
`merge_edge_sideways`, `step_cap_over`, `control_inplace_ry_reject_stateprep_second_flag_i1.ll` and whatever
else the enumeration finds. Those fixtures pin the F2 family that **42 measured confirmed-miscompile
programs** produced over four adversarial rounds (`CLAUDE.md` L5: F2 lost four rounds running).

**The owner's question is NOT "is R-2′ safe". It is "is it worth the budget to re-derive those 11+".**
You produce the table that lets them answer. Do not recommend in the abstract — recommend from the table.

## 2. Deliverable — `$SES/trackF/SCOPE_F.md`

### 2a. The ENUMERATION (measure it; do not quote a count)

Find **every** fixture and slice in the tree whose verdict R-2′ changes. Method: identify the exact predicate
site R-2′ would add a conjunct to (F2's **TEST**, `ArmClassify.cpp` — the same place `rb9x`'s
`taint.PeelClones` conjunct sits, **never** at the LVI anchor: at the anchor all 40 F2 fixtures flip), then
determine per fixture whether its pinned collider is one-edge or both-edge. You may reason from the IR you
extract with the ORACLE (`-S` the lowered module, `CQ_CTRL_DBG=1` for the firing site and the pinned value);
you may NOT patch the pass to find out. If a row cannot be decided without building, say so and mark it
UNDECIDED-WITHOUT-BUILD rather than guessing.

### 2b. The TABLE — one row per flipped fixture, four columns

| fixture | what it PINS (the program class, in one sentence — not the CHECK text) | does R-2′ make it ACCEPT? | **is that ACCEPT CORRECT?** |

Column 4 is the whole point and it is the expensive one: **re-derive the rival per row** the way
`$PREV/trackR/SCOPE_R2.md` did for its 14 rows — name which predicate would refuse the rival reading
(R3 `ArmClassify.cpp:4102-4103`, R6 `:4420`, `:3257`, F1, gate 2c), with the file:line, and say whether that
refusal survives R-2′. A row you cannot close is a **HOLE** and must be labelled HOLE in capitals — a hole
is the finding, not a failure.

⚠ `SCOPE_R2.md` measured that R-2's **stated** ground was wrong (`condWireDisposition`'s 2c fires in 0 of 24
probes; the rivals die at R3/R6/:3257 instead). **Do not inherit that ground for R-2′.** Derive R-2′'s ground
from what you measure, and if the ground differs from the bead's text, say so in those words.

### 2c. Three more things the table needs beside it

* **The one-edge pin must be shown to be a REAL property, not a spelling.** `DIAG_2026-09-14.md` S1 (one
  constant `2`→`1`) and `v6b` are the controls for the owner's file; find the equivalent control for at least
  three of the flipped fixtures.
* **`w2.c`'s lesson**: the class is not an IPSCCP artefact — the runtime-`a` cascade declines identically, so
  R-2′'s one-edge argument must hold for a **range**-derived pin, not only a constant-derived one. Say
  explicitly whether it does.
* **RETIREMENT TRIGGERS** (L8): write the file:line conditions under which R-2′ becomes an OVER-ACCEPT, in
  the form a future agent can check mechanically. `om35`'s NOTES already name candidates
  (`:4102-4103`, `:4420`, `:3257`); confirm or correct them by measurement.

### 2d. The recommendation, in three lines

BUILD / DON'T BUILD / BUILD-NARROWED, with the budget in rounds and the count of rows in column 4 that are
CORRECT vs HOLE. If the answer is BUILD-NARROWED, spell the narrowing as a predicate.

---

## 3. Gates

Scoping runs **no** build and **no** suite (PROTOCOL matrix). Your instrument is the per-probe pipeline on
the ORACLE:
```
LLVM=/usr/local/opt/llvm@19/bin
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S p.c -o s1.ll
build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S s1.ll -o s2.ll; echo "exit=$?"
CQ_CTRL_DBG=1 build/ir-pass/cq-opt ... 2>&1 | head
```
Probes go in `$SES/trackF/probes/`. Record a `GATES.md` line for anything you do run, hash-keyed.

Report to the orchestrator: the row counts (flipped / correct / HOLE), the recommendation, and the
**one paragraph the owner will actually read** — what R-2′ buys (their file compiles) against what it costs
(N fixtures re-derived, M of them holes).
