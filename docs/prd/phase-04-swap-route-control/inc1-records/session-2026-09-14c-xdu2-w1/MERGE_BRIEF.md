# MERGE-AND-GATE brief — session 2026-09-14c, ONE group, five branches

Worktree `/Users/sorenwilkening/Desktop/CQ_merge`, branch `merge-2026-09-14c` (off `main`).
`$SES` = `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14c-xdu2-w1/`.

**READ FIRST:** `$SES/PROTOCOL.md` (**binding — and note its corrected ORACLE block at the top**),
`$SES/DECISIONS.md` (**four owner rulings, D4 re-rules D2**), `$SES/ROUTING.md` (**four obligations
handed back by tracks; R3 is YOURS**), `CLAUDE.md` (Prime Directive; Rules 1, 2, 11, 12, 13, 14, 17,
**19**; CORRECTNESS RISK §3 **L1/L2/L8/L10**), then each track's `IMPL_*.md` and `GATES.md`.

**ORACLE** (frozen, read-only): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` sha256
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`, `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4`. That build dir is **READ-ONLY**.

---

## 1. The group, and why it is ONE

Measured file overlap under `ir-pass/`, `include/`, `runtime/`, `tools/`:

| branch | tip | files outside `ir-pass/test/` |
|---|---|---|
| **A** `railbank-carve` | `44ba3345` | `QramLowering.{h,cpp}`, `TaintPropagation.cpp` |
| **B** `railbank-promoter` | `6a999d1a` | `RailBankCarve.h`, `RailBankPromote.{h,cpp}`, **`RailBankCarveShim.cpp`**, `CQLoweringPass.cpp`, `MergePhiPeel.cpp` |
| **S** `s82e-raillocal-proof` | `8aa159b7` | `LoopPlan.h`, `TaintPropagation.h`, `ArmClassify.cpp`, `CQLoweringPass.cpp`, `LoopLowering.cpp` |
| **X** `x5-rederivation` | `c4c6ef77` | `ArmClassify.cpp` |
| **I** `railbank-instruments` | `20174549` | `tools/free_pairing_check{,_test}.py` |

A↔B through the shim, B↔S through `CQLoweringPass.cpp`, S↔X through `ArmClassify.cpp`. **I is
disjoint** and joins only so the box runs **ONE** full suite (PROTOCOL: never more than one in flight).

**Merge order: A → B → S → X → I.** A first because B's real dependency is A's symbol.

## 2. ⚠ THE INTEGRATION THAT IS NOT A FORMALITY — Track B ships a SHIM of Track A's predicate

Track B could not see Track A's branch, so it implemented **the published contract** in
`ir-pass/src/RailBankCarveShim.cpp` + `ir-pass/include/RailBankCarve.h`, and states it is **built so
that leaving it in is a duplicate-symbol LINK ERROR** — deliberately fail-loud.

**Your job, in this order:**
1. Merge A, then B. **Confirm the link error actually fires.** If the build succeeds with both present,
   that is a **FINDING**: the fail-loud property Track B claims does not hold, and something is picking
   one definition silently.
2. **Delete the shim** (`RailBankCarveShim.cpp` and, if it only exists to declare the shim,
   `RailBankCarve.h`) and point Track B's single call site at Track A's real
   `railBankCarveVerdict` / `RailBankShape` from `QramLowering.h`.
3. ⚠ **RE-MEASURE Track B's §3, §7 and §9 against the REAL classifier** — Track B says so itself and
   flags it as the thing it could not do. Its accept/refuse fixture verdicts, its corpus sweep and its
   `!dbg` claims were all taken against the shim.
4. **Report every place the real predicate and the shim DISAGREE**, including "nowhere". Track B names
   three divergence candidates to check explicitly:
   * the **RAW vs PROMOTED** shape (both tracks reached the `hasOneUse` correction independently —
     the strongest available evidence that they agree, and still not a measurement);
   * the **outermost-loop conjunct** (`Loop::getParentLoop() == nullptr`), which Track A added after
     its own self-attack and Track B deliberately did **not** duplicate. Track B's mutant **M12
     measured that deleting it makes the promoter fire** — so this conjunct is load-bearing across the
     seam, and it is exactly the kind of thing a per-track gate cannot see;
   * *"the classified store is the only store in the bank"*, which leaves Track B's **multi-store
     `SSAUpdater` path unexercised**.

⚠ **This is the F × P lesson applied before the fact, not after: A COMPOSITION IS NOT CLEARED BY
CLEARING ITS PARTS.** Track A cleared a binary on which B's promoter does not exist; Track B cleared a
binary on which A's classifier does not exist. The A×B composition has been reviewed by **nobody**.
Say so plainly in `MERGE_REPORT.md`, and treat any behaviour that appears only with both present as a
first-class finding rather than an integration detail.

## 3. The safety property that outranks every gate

**No program may go DECLINE → ACCEPT.** The staging constraint (`DECISIONS.md`, `BRIEF_A.md` §0) is a
**correctness requirement**: the taint rule, the type rewrite and the D5 allow-list are deferred, so an
accepted bank would be a silent miscompile — `cq_measure(b[i])` on an untainted load takes
`MeasureLowering.cpp:151`'s classical split and emits **no gate, no symbol, no trace line**, invisible
to the golden byte-diff.

**Pin it explicitly on the merged binary**, beyond the sweep: the owner's
`/Users/sorenwilkening/Desktop/CQ_lang/example/grover/grover_oracle_uncompute.c` (⚠ **untracked** —
bd `k4fw`; it lives only in the primary checkout, so copy it in, do not expect it in your worktree)
must still decline `cq taint escape: tainted value stored to memory`. The orchestrator verified this on
Track A's binary; verify it on the merged one.

**Expected movers, by track, BY STRING** (PROTOCOL §S1 — an unattributable mover is a FINDING):
* **A** — ~27 rows, `kMsgStore` → a per-clause string. All `DECLINE→DECLINE`.
* **B** — **0 movers expected** (it reported 4725 rows, 0 movers against the shim).
* **S** — 7 rows: 4 its own red-green pair, and **3 pre-existing `*_leak_control.ll` fixtures that go
  ACCEPT → DECLINE**. Those three are *expected and correct* — see §6.
* **X** — **0** (binary bit-identical to the ORACLE; comments and fixture headers only).
* **I** — **0** (no pass source).

## 4. Gates you own — you are the ONLY full-suite runner

1. `cmake --build build -j8` (⚠ **never `--target CQPass` alone**), record `shasum -a 256
   build/ir-pass/cq-opt` in `$SES/GATES.md` after **every** rebuild.
2. **Full `ctest --test-dir build -j6 --output-on-failure` — ONCE.** ⚠ A red group gate is exactly the
   interaction a per-track gate would have hidden. **Do NOT fall back to per-track gates to find it** —
   bisect by reverting one branch's merge in the same worktree.
3. **`cq-opt-equivalence-full` — OWED, not optional.** Both A and S moved a decline string **and** an
   analysis site; that is the PROTOCOL's stated trigger, and both tracks flagged it.
4. **ONE corpus sweep on the merged binary.** ⚠ **ROUTING R3 is yours to close**: Track A's sweep
   covered **2088 of 5455** modules and argued the residue's immobility **structurally**, labelling it
   a gap. Track B swept 4725. **Sweep the full corpus and close it by measurement** — a structural
   argument about immobility is precisely what L5 says loses.
5. **Duplicate-body fixture scan (L8)** — sha-256 over each fixture's non-comment lines, and **read
   each duplicate's CLAIMED VERDICT off its RUN lines, flagging groups that MIX them**. ~45 fixtures
   were added this session across three branches. ⚠ A merge can **resurrect a `git mv`'d fixture**;
   Track S converted three fixtures in place (no rename) — confirm no rename slipped in.
6. **`tests/e2e/CMakeLists.txt`**: PROTOCOL's ERRATUM says it is **NOT** append-only at disjoint
   anchors. If any branch added a slice, expect a tail conflict per slice-adding branch beyond the
   first; resolve by **UNION in merge order**, then run the three checks: `0` duplicate `add_test`
   names, the registration count reconciles, and the `get_property` sweep is **still LAST**.
7. **Twin matrix** runs inside the full suite. ⚠ Track S requests **four cells**, and **two changed
   with its decline**: `m_noregion_invread_live` and `m_region_derivedbase_live` are now
   **DECLINE-BOTH-SIDES**; `m_noregion_invread_dead` (blessed benign divergence) and
   `m_region_rootmint_live` (positive control) are unchanged. Generate them **against the merged
   binary** and adjudicate **in writing** — ⚠ **never `--regenerate`** (bd `gfsk`: it silently ate 54
   lines of Rule-13 ruling prose under a success message).

## 5. Instrument warnings that cost real time THIS session

* ⚠ **Never relink under a running measurement.** Track A did it **twice**, the second time from a
  *comment-only* rebuild, and got a **false `VERDICTMOVE` row** out of it. Never `pkill` by pattern.
* ⚠ **bd `1yeu` from the inside**: `-O1` inlines `@slice` into `@main`, so each module carries **two
  copies** and a mutation deleted *from `@slice`* can be satisfied by the `@main` copy. **The second
  function is a decoy, not a spare.** Track S's matrix reported 7-of-7 MISSED for this among other
  causes; Track B's reported MISSED=7 in round 1.
* ⚠ **bd `rixk` (filed this session)**: stage 2b's census counts **static `cqrt_alloc` sites across
  inlined copies**, so it **over**-counts as well as under-counts — 11 lines of C, loop-free, report
  `6 rail mint(s)` for a trace that allocates **3**. Do not read a 2b census line as a rail count.
  ⚠ The figures `CLAUDE.md` §4c cites are **unaffected and are the regression test**:
  `slice_control_cascade_three_bools` reports `9 rail mint(s)` against a golden carrying exactly 9.
* ⚠ **A 0-byte `.ll` ACCEPTS** through the passthrough early-out. Check your generated modules are
  non-empty.
* ⚠ **Lowered-IR md5s are NOT comparable ACROSS sweeps** (the temp `ModuleID` changes); compare within
  a row. The shared `corpus.sh` tag regex renders the whole `cq_measure_<sfx>` family as an empty
  `D:` — close it with a **full-stderr + exit byte-compare** over the decline rows, as Track B did.
* ⚠ **`LLVMContext::diagnose` EXITS on the first `DS_Error`** (bd `br4a`) — which is why Track B
  measured `MergePhiPeel` as never reached on bank modules.

## 6. Three things you must NOT "fix"

1. **The three `*_leak_control.ll` ACCEPT → DECLINE rows are the increment, not a regression.** Their
   own headers recorded `3/0 rolled and 3/3 unrolled` and then called the leak *"the PRIME-DIRECTIVE
   disposition … the safe direction (Rule 6)"* — false for those programs (Rule 8). `CLAUDE.md` §5 is
   already corrected on `main`. **Do not restore their old `CHECK` prefixes**; they pinned the leaking
   stream.
2. **Track B's φ is at the cell type `i8` where `-O1`'s target is `i1`.** Measured and stated, not
   glossed; reaching `i1` needs InstCombine's phi-of-cast fold. The seed side is byte-identical. This
   is a recorded residual, not a defect to chase at the gate.
3. **`isRailBankAlloca` / `railStoredToRailBank` are deliberately NOT shipped** (no caller this session
   = Rule 12 hygiene defect (c)). Do not add them.

## 7. Deliverables

`$SES/{MERGE_REPORT.md, MERGE_FILINGS.md, GATES.md}`:
* the merge order, every conflict and how it was resolved;
* **the shim removal and the A×B re-measurement**, with the three divergence candidates answered;
* the full-suite result, the equivalence sweep, the closed full-corpus sweep (R3), the duplicate-body
  scan, the twin-matrix adjudication;
* **`!dbg` accounting** — 0 lost locations was the 2026-09-14 gate's standard;
* every mover attributed by track **by string**, and every unattributable one as a FINDING;
* anything that appears **only** with two or more branches present, called out as a composition finding.

Commit the merge on `merge-2026-09-14c`. **Do not push. Do not touch `main`** — the orchestrator
squashes each branch onto `main` in group order afterwards. **Rule 19: report only what you ran.**
