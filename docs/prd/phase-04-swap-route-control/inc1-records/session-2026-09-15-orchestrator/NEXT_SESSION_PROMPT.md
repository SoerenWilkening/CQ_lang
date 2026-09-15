# Session 2026-09-15 — orchestrator prompt

You are the **orchestrator**. You delegate to **opus subagents in git worktrees**; you do not build,
run suites, or edit pass source yourself. Same workflow as sessions 2026-09-13 / -14 / -14c.

Read first, in this order: `CLAUDE.md` (operating manual), `ROADMAP.md` (status of record),
`$PREV/PROTOCOL.md`, `$PREV/ROUTING.md`, `$PREV/DECISIONS.md`, `$PREV/MERGE_FILINGS.md`,
`$PREV/CLOSING_REPORT.md`, where

```
SES  = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/
PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/
LLVM = /usr/local/opt/llvm@19/bin        # NOT on PATH
```

---

## 0. THE HEADLINE — the owner's loop script must compile

This is the session's purpose. Everything else is either a blocker on it, a fence it must not
break, or parallel debt the owner asked to clear in the same session.

**The program.** `example/grover/grover_oracle_uncompute.c`. ⚠ **`example/` is in
`.git/info/exclude`, so this file is NOT in the repository** (bd `zwtm`) — it is reproduced here
verbatim as measured on 2026-09-14, and it is the only copy a fresh checkout will have:

```c
#include "CQ.h"
#include <math.h>

int main(void) {
    int a = 5;
    bool b0[3];

    for (int i = 0; i < 3; ++i) {
        if (a >= 3){
            b0[i] = cq_theta(b0[i], 0.5);
        }
        if (b0[i]) a -= 3;
    }

    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);
}
```

**Measured at HEAD `74eabd2c` (this session's oracle):** `cq taint escape: tainted value stored to
memory`, exit 1. That decline is **deliberate and currently load-bearing** — see §1.

**Done means:** `opt` exit 0, stderr 0 bytes, STRICT stage 2b clean (`free_pairing_check.py` with
no `--allow-unproven`), a trace, a committed e2e slice + golden, and a Rule-13 clearance. Not
"the decline moved".

⚠ **Rule 17 applies to this task by name.** If the lowering proves hard, bring the question to the
owner — do NOT ship a narrower decline and call it progress. Equally, per the owner's 2026-09-11
ruling, do not treat any over-decline you meet on the way as a free safety margin.

---

## 1. Why the headline is BLOCKED, and by exactly what

Session 2026-09-14c landed **only the first half** of bd `xdu2` (L-1a W1): the rail-bank **carve
classifier** (C1–C4, C2' injectivity, C6 totality) and the **per-activation promoter** (C5). The
`Bank` verdict still falls through to the store-escape decline **on purpose**:

> without the taint rule, the type rewrite and the D5 allow-list, an accepted bank is a **silent
> miscompile** — `cq_measure(b0[i])` on an untainted load takes `MeasureLowering.cpp:151`'s
> classical split and emits **no gate, no symbol, no trace line**, which the golden byte-diff
> structurally cannot see.

So the second half is the work, and **two P1s are filed as blocking for it specifically**:

* **bd `de8n`** — `Bank` does **not** imply PROMOTED, and the L8 trigger makes `Bank` the ACCEPT. An
  unpromoted `Bank` reaches the type rewrite with a **partially available second load**, which
  `SCOPE_L1a` §0 H3 proves would read handle 0 — a live rail.
* **bd `n74d`** — the clause licensing the **store move** tests the **GEP's block, not the LOAD's**.
  `-O1` LICM hoists the invariant address to the preheader and leaves the load in the loop, so the
  clause's own fixture **pins a spelling `-O1` never produces**.

⚠ **ERRATUM to carry forward:** commit `ea4d488c`'s message names the first of these **bd `8a3p`**.
**No such issue exists.** It is **bd `de8n`**. Do not re-file it under the phantom id.

And one instrument is a **hard prerequisite, not a nicety**:

* **bd `rpkr`** — `e2e-loop-twin-matrix` needs a **BANK axis before L-1a's accept lands**. No
  existing cell can see a rail bank. This is the same lesson as bd `uq96`'s `i1` axis last session:
  *an instrument is only ever blind in the shape nobody has pointed it at yet*, and the witness has
  to exist before the capability, not after.

---

## 2. Routing items INHERITED — read `$PREV/ROUTING.md` in full; these four are live

* **R1** — D3's measurement question came back **"unmeasurable today"**, which is **not "no"**. Any
  Rule-13 round told "measure whether the cascade reaches `staleRailRecordRead`" must be told, in
  these words, that *the refusal's subject does not exist until the accept lands*. A reviewer who
  reports "it does not reach it" states something **true of the binary and false of the capability**.
* **R2 — OWED IN THIS SESSION.** D1's disclosure (the uninitialized bank composed with bd `z9t1`)
  **states a claim whose witness is future**. `z9t1`'s `normalizeUndefRotationSeed` does **not** reach
  a MEMORY seed, so D1 does not inherit `z9t1`'s 164-module, 0-divergence refinement measurement; it
  rests on C6 totality alone. **The byte-identity measurement must be taken in the same increment
  that lands the accept** — with it, not after. Any divergence returns D1 to the owner.
* **R3** — last session's corpus sweep covered **2088 of 5455** modules and argued the residue
  **structurally**. The merge-and-gate agent's single combined sweep should **close** the residue,
  not inherit the argument (L5: a syntactic answer to a semantic question loses).
* **R4** — `SCOPE_L1a.md` §5/§7's premise is **stale** (`a_flat_n3.c` accepts now, after bd `om35`).
  The conclusion still holds **for a different reason** than the document gives. Fix the document
  before quoting it; two different reasons for one conclusion is how a stale premise survives.

---

## 3. The tracks — dependencies are real, "parallel" is not uniform

Spawn every agent as **`model: opus`** (owner ruling 2026-09-11), each in its **own git worktree**,
each writing records only to `$SES/track<X>/` inside that worktree.

Group membership = "touches a common file under `ir-pass/`, `include/`, `runtime/`, `tools/`".
**One merge-and-gate agent per GROUP, not per track** (PROTOCOL §S1).

### GROUP 1 — the headline. Sequenced, not parallel.

| track | work | depends on |
|---|---|---|
| **A** — blockers | bd `de8n` + bd `n74d`. Fix the carve/promote classifier so `Bank` implies promoted and the store-move clause tests the LOAD's block. Red-green per Rule 12. | — |
| **B** — the accept | L-1a W1 **second half**: the taint rule, the type rewrite, the D5 allow-list. Land the R2 byte-identity measurement **with** the accept. Add the e2e slice + golden for the owner's program. | **A** (B built against a shim last session and the integration commit deleted it — do not repeat that) |
| **I** — witness | bd `rpkr`, the BANK axis for `e2e-loop-twin-matrix`. `tools/` only, so it is a **different group** — but it must be **green before B's accept is cleared**. | — (runs parallel to A) |

⚠ Track B's scoping agent must re-read `SCOPE_L1a` §5/§7 **through R4** before quoting it.

### GROUP 2 — the dephasing fence. Fully parallel to Group 1.

Track **S'**: bd `c767` + bd `7845` + bd `2g52`, all in `declineDephasingUnmarkedLoopRails`.
Round 1b's verdict on last session's fence was that its benign/divergent separation **"holds by
accident on the three programs it was built from."** Two P1 silent miscompiles survive it:

* `c767` — conjunct (2) inspects rotations **outside** the loop only, so bd `s82e`'s own
  D4-ruled-BENIGN exhibits become divergent with **one added in-loop line** (20 vs 24, 34 vs 42).
* `7845` — conjunct (3) scans `BinaryOperator` **only**, and its stated rationale is **false** for a
  compare used as DATA. Five lines of C, no control flow, 10 rolled vs 14 unrolled. A
  **single-conjunct miss**.
* `2g52` — the **over-decline the same fence introduced**: a constant-trip loop with a volatile
  in-place op goes ACCEPT(7) → DECLINE, and its rolled trace is byte-identical to the unrolled twin's.

Carry **bd `bbu0`** into this track as a question, not a fix: the tree's `warnLiveRecordRotations` is
**strictly more complete** than this fence on the dephasing class, is a WARNING by owner ruling bd
`lyyf`, and fires on 5 of 366 accepting slices. Decide whether the class belongs at that site instead
of at a second, narrower one — and take it to the owner rather than ruling it (L7).

### GROUP 3 — in-loop rail pairing. ⚠ May collide with Group 1; check before spawning.

Track **T**: bd `tu9q` (the rolled form must emit the per-trip `_unc` + `cqrt_free` the flat form
already emits — 10 vs 14 and 19 vs 25, with a 22==22 positive control) and the bd `s82e` residual,
plus bd `1m5p` if it falls out. Touches `Uncomputation` / `FreePoint` / `LoopLowering`.

**If Track B also touches `LoopLowering.cpp`, T and B are ONE GROUP** — verify by file, not by
assumption, before deciding the gate topology.

### GROUP 4 — over-declines. Parallel; these are DEFECTS per the owner's 2026-09-11 ruling.

Track **F'**: the F2 phi-descendant precision cluster — bd `hrts`, bd `l3i1`, bd `dpau` (make
`collectStatePrepPhiDescendants`' dominance guard member-vs-slots and opcode-agnostic). ⚠ The X5
re-derivation landed last session **retired the cyclic/acyclic framing** of `hrts`/`l3i1` — read
bd `om35`'s X5 record before re-deriving from the bead text.

Track **P'**: the prep merge-φ leaf-grammar cluster — bd `hn29` (a prep leaf defined outside the
kickback's own Pred block), bd `leyd` (two prep merge phis as the two leaves of one kickback tree),
bd `52og` (**the in-loop phi PHASE kickback over an outside prep declines while the in-loop phi DATA
SELECT over the same prep is a shipped ACCEPT** — an asymmetry between two consumers of one leaf
grammar, and **it is the shape a rolled Grover phase kickback on a bool-controlled prep takes**, so it
is adjacent to the headline).

Also available here if capacity allows: bd `onq1`, bd `1ro3`, bd `35t0`.

### GROUP 5 — instruments. `tools/` only, fully parallel.

Track **J**: bd `gzgs` (the committed F×P value witness `m28` is **vacuous on its own reachable
support**; `fp_x5b` is the non-vacuous twin), bd `gfsk` (`--regenerate` silently deleted 54 lines of
Rule-13 ruling prose and reported success), bd `jdec` (the vacuity script reports `checked 0` instead
of failing), bd `rixk`, bd `19vy`, bd `1739`.

⚠ Every one of these is an instance of *an instrument's failure mode is to report a pass*. Each fix
ships with a **mutant validation**, or it is not a fix.

Carry **bd `1yeu`** as a scoping item only: every corpus and gate in the tree is effectively **one
function per module**, so a cross-function defect is invisible to all of them — two over-ACCEPTs
found 2026-09-14 passed 1937 lit fixtures, 15 e2e entries, a complete corpus sweep, a 0-MISSED
injection matrix and 328 twin cells for that single reason. Scope the fix; do not attempt it
alongside the headline.

---

## 4. OWED FROM LAST SESSION — reviews, not code

* **The A × B composition has NO Rule-13 opinion** (`$PREV/MERGE_FILINGS.md` F-1). This is the same
  gap as the F × P composition the session before. **A composition is not cleared by clearing its
  parts** — Track A's reviewer saw a binary without B, and B's saw one without A. Spawn a reviewer
  whose subject is the **composition**, on the merged binary.

## 5. OWNER QUESTIONS — surface these EARLY, in one batch, so they do not block the close

Do not rule these yourself (L7 — an agent-authored justification hardens into a ruling if nobody rules):

* **bd `dnqo`** — should an `undef`/`poison` **rotation angle** be a loud decline? Today one undef in a
  single emitted gate slot is deliberately blessed, and a theta whose ANGLE is undef emits
  `cqrt_ry_<W>(h, undef)` that links, runs, and prints a garbage angle.
* **bd `fve8`** — bd `z9t1`'s phi clause **disarms ruling clause 4 upstream of the sink**: `cq_measure`
  of an undef declines by the ruling, but the clause deletes the undef before `MeasureLowering` sees
  it. 4 of 710 rows go oracle-exit-1 → subject-exit-0 with 0 bytes of stderr.
* **bd `yiid`** (P1, unruled boundary) — `cq_measure` is **not modelled as a wire event at all**, so
  reading a name AFTER measuring it compiles in every spelling. Reading (b) is costed at 2 goldens,
  0 shipped accepts, no ABI, no new symbol (`IMPL_D.md` §14).
* **bd `zwtm`** — the owner's canonical customer program is **not in the repository**. Ask whether
  `example/` should be un-excluded, so that "the owner's file compiles" becomes a checkable claim.

---

## 6. Protocol — binding, copy into `$SES/PROTOCOL.md` with its corrections applied

Copy `$PREV/PROTOCOL.md`. ⚠ **It carries its predecessor's oracle hashes and its own header says so.**
*A protocol copied verbatim carries its predecessor's measurements with it, and a measurement is a
fact about a moment.* Correct the oracle block **at the top, before any track reads it**, not at the
point of use.

**ORACLE for this session — measured 2026-09-14 20:28 at `main` `74eabd2c`, re-verify before use:**

```
build/ir-pass/cq-opt      0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d
build/ir-pass/libCQPass.so 94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b
```

`shasum -a 256` it before you use it; if it differs, STOP and report — someone rebuilt the oracle.
⚠ A stale `cq-opt` makes a **fixed** program look broken by hand and a **broken** pass look green in
lit. The hash is the cheap discriminator; use it before believing any decline.

Carry forward, unchanged and binding:

* **Hash-keyed `GATES.md` per track.** A gate result is a fact about a BINARY. Cite, don't re-run;
  a cited line whose hash does not match the binary on disk is a FINDING. Report `cited:` / `ran:`,
  never a bare "tests pass".
* **The gate matrix** (`$PREV/PROTOCOL.md`): the implementer's inner loop is `lit --filter` + single
  slices. The reviewer runs **no build and no suite**. The **merge-and-gate agent is the only full
  `ctest` runner**. Never more than one full-suite gate in flight on this box.
* **`cmake --build build --target CQPass` ALONE is a FALSE-GREEN trap.** Always `-j8`, or name BOTH
  `CQPass` **and** `cq-opt`.
* The primary `build/` is **READ-ONLY**. Never relink under a running measurement; never `pkill` by
  pattern.
* **`tests/e2e/CMakeLists.txt` is NOT append-only at disjoint anchors** (measured erratum, 2026-09-14).
  Expect a tail conflict per slice-adding branch beyond the first; resolve by UNION in merge order,
  then run the three post-union checks (0 duplicate `add_test` names, count reconciles, sweep still
  last).
* After any merge that renames fixtures, run the **duplicate-body scan** — and have it read each
  duplicate's CLAIMED VERDICT off its RUN lines, flagging groups that MIX them (L8: a merge can
  resurrect a `git mv`'d fixture).
* **Rule 13 budget the rounds up front.** The measured hit rate says the next round finds something;
  last session's round 1b is why `ea4d488c` claims less than its work suggests. Plan ≥2 rounds on
  Group 1 and on Group 2.
* **Rule 19.** Report only what you ran, with the command shown.

---

## 7. Close

Standard Session Completion from `CLAUDE.md`: file issues for everything unresolved, run the group
gates, update bd, **append the lab-report entry** (`docs/labreport/`, ≤5 pages, `--seal`), then
`git pull --rebase && git push` and verify `git status` shows up to date. Work is not complete until
the push succeeds.

Write `$SES/CLOSING_REPORT.md`, `$SES/DECISIONS.md`, `$SES/GATES.md`, `$SES/ROUTING.md` and
`$SES/MERGE_FILINGS.md` as last session did. **A routing item that reaches the closing record
unrouted is a defect in the orchestration, not in the track that raised it.**
