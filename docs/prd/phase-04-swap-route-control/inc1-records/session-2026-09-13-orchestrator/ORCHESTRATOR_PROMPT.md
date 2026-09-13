# Orchestrator prompt — the controlled-operation CASCADE (flat first, then the loop), parallel tracks, no redundant runs

Written 2026-09-13 at the close of the diagnosis session (`main` `86c0d25`, docs-only over the pass at
`e96f89c`). Owner's goal for this session, verbatim from the 2026-09-13 conversation: *"the grover script
might be implemented with a large loop, where MANY of those controlled operations are applied"* — and, from
2026-09-11, *"our end-goal is to not decline any code that will lead to a valid quantum circuit"*. An
over-decline of a valid circuit is a DEFECT to remove; the Prime Directive (never over-ACCEPT) is untouched.

You are the ORCHESTRATOR for CQ_lang (`/Users/sorenwilkening/Desktop/CQ_lang`). Hard constraints, all
owner-ruled, none negotiable:

* **Every agent you spawn is `model: "opus"`** ("you are only allowed to spawn opus agents", 2026-09-11).
* **You do not run builds, ctest, lit, the pipeline or corpus sweeps yourself.** You spawn an opus agent for
  every execution, including one-off measurements. You own: briefs, gates (deciding WHEN a gate runs and
  WHO runs it), the landing (squash commits on `main`), the records, the lab-report entry, the handoff, the
  owner conversation. `git` operations on `main` (worktree add/remove, squash, commit, push) are yours.
* **Read first:** `CLAUDE.md` (Prime Directive; Rules 1, 6, 7, 8, 12, 13, 14, 17, 19; CORRECTNESS RISK §1–§5;
  Build & Test; Session Completion), `bd prime`, this directory (`probes/`), the previous orchestrator record
  `../session-2026-09-11-orchestrator/{NEXT_SESSION_PROMPT,LANDING_PLAN,REVIEW_BRIEF_INTEGRATION,review_integration}.md`,
  and — as STYLE MODELS for every brief you write — `../session-l4x4/{SCOPE_l4x4,BRIEF_l4x4b,REVIEW_BRIEF_l4x4b_r1,IMPL_l4x4b,MERGE_l4x4_2}.md`
  and `../session-boi6/SCOPE_boi6.md`.
* **Never relink a binary under a running measurement; never `pkill` by pattern** (bd memory
  `never-relink-or-pkill-under-measurement`). The primary `build/` is the frozen ORACLE for the whole session
  (`cq-opt` sha256 `fbbe0820ef4b176a…`, `libCQPass.so` `40e9c7a51e8120bb…`, built from `e96f89c`) and is
  rebuilt EXACTLY ONCE, at the end (§6 step 5).
* **A merge can resurrect a `git mv`'d fixture** (memory `merge-resurrects-git-mv-fixture`): after every
  merge that renames fixtures, the merge-and-gate agent runs the duplicate-body scan (sha-256 over each
  fixture's non-comment lines).
* **`cmake --build build --target CQPass` alone is a FALSE-GREEN trap** — `%cq-opt` is a separate target
  from the same sources; always `cmake --build build -j8` or name BOTH (`--target CQPass cq-opt`).

---

## 0. State at start — MEASURED 2026-09-13, do not re-measure (sources in `probes/`)

**The owner's file** `example/grover/grover_oracle_uncompute.c` (git-excluded; snapshot
`probes/owner_file_2026-09-13.c`) is the 2026-09-11 file plus ONE line, `if (b1) a -= 3;` (line 99). It
now declines:

```
error: example/grover/grover_oracle_uncompute.c:99:9: in function main i32 (): cq controlled lowering: control flow under quantum control
```

`-O1` input (`probes/owner.main.O1.ll`): `a = 5` is a constant, so BOTH `a >= 3` guards are folded — the `b0`
prep is unconditional (`%1 = cq_theta_i1(false, .5)` at entry); the `b0` ARM and the `b1` PREP are FUSED
into one diamond `br i1 %1, label %4, label %2` (gate arm = the FALSE successor, Rule 9) whose merge
carries two phis: `%5 = phi i32 [5,%2],[2,%0]` (the `a`-mux — peelable, `MergePhiPeel` turns it into the
rail-conditioned select that the 2026-09-11 stream already emits) and **`%6 = phi i1 [%3,%2],[false,%0]`**
(the `b1` STATE-PREP merge — NOT peelable, P3 arm-defined incoming). Line 99 is if-converted into
**`%8 = select i1 %6, i32 %7, i32 %5`** — a 4.4 data select whose CONDITION IS THE PREP'S MERGE PHI.

**Firing site** (isolated by `lldb` breakpoint on `diagnoseUnderControl`, not by reading):
`SelectClassify.cpp:780-782`, GATE 2 of `classifySelectRegion` — `collectCondTree(%6)` returns false
because the only leaf kinds are a `CmpInst` and `isCondRailLeaf` (`SelectClassify.cpp:543`), which admits
ONLY a literal `cq_theta_i1` call; a `phi i1` is off-grammar. This is exactly `SCOPE_boi6.md` §0.1 probe
**`p20`** ("4.4 DATA select on a merge-φ bool, flat → DECLINE `control flow` @ the select") — bd `boi6`'s
SECOND half (D-B, the region-merge-φ rail), reached through the SELECT path.

**Variant table** (`probes/v{a..e}.c`, all through the ORACLE binary):

| variant | opt exit | first diagnostic / result |
|---|---|---|
| `va` — line 99 deleted (the 2026-09-11 shape) | 0 | 19 trace lines (`probes/va.trace`), STRICT 2b `6 rail mint(s) of which 5 left allocated, 1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` |
| `vb` — `if (b1 == 1) a -= 3;` | 1 | same string; `main` IR BYTE-IDENTICAL to the owner's |
| `vc` — `int c = a; if (b1) c = a - 3; a = c;` | 1 | same string; `main` IR BYTE-IDENTICAL to the owner's |
| `vd` — THREE bools (`b2` prep + arm, `b2` measured) | 1 | `vd.c:10:14: … state prep seed is proven equal to the condition register under quantum control` — fires from `classifyArms` on the **b0** prep; `-O1` hoists region 1's `a`-mux into the entry block as `select i1 %1, i32 2, i32 5`, so the diamonds re-shape |
| `ve` — `bool b[3]` in a `for` loop | 1 | `ve.c:7:26: … cq taint escape: tainted value stored to memory` |

**Reading.** (1) No source rewrite of line 99 helps — `-O1` erases every spelling to the same select.
(2) The wall is a LEAF-GRAMMAR gap + an ORDERING question: the select is classified in round 1 BEFORE the
prep region that defines `%6` is emitted; after `emitInPlaceRotationRegion` (state-prep kind, M-β) the phi
is RAUW'd to the HOISTED `cq_theta_i1` call — which `isCondRailLeaf` WOULD admit — and the r9e5 bool
data-select path would then take it. Whether "defer the select until its producing region has emitted" or
"admit the prep merge-φ as a rail leaf by CALLING the one owner of that question" is the right spelling is
Track M's first measurement, not a decision to make here. (3) With N ≥ 3 the next wall is the F2 family
(`rb9x` or a sibling — Track R measures which). (4) The LOOP form compiles in NO spelling today: an array
of bools is a taint escape, and a scalar-bool loop needs `wx8g` (in-loop bool prep), `boi6.a`
(loop-carried bool condition) and `3qlq.6` (in-loop VALUE arm — `a -= 3` is one once `a` is quantum), none
built.

Counts at `e96f89c` (re-measure by command before quoting): lit 1893 · goldens 355 · ctest 403 (`^e2e-`
393, `^e2e-slice-` 353, `twin-identical` 30) · twin matrix 259 + 29 quarantined.

Open worktrees `../CQ_trackA`, `../CQ_b6ap`, `../CQ_f2`, `../CQ_l4x4` are ALL LANDED (`7203d1c`, `3a3a2b9`,
`a9cc062`, `e96f89c`). Remove them first (`git worktree remove --force <path>`; `git branch -D` the four
branches), then create this session's worktrees.

---

## 1. Owner questions — ask in your FIRST message, then start every track that does not depend on an answer

1. **boi6 H-1** (`SCOPE_boi6.md` §3 H-1): `reverifyRailCondReads` skips a φ record, and after the in-loop
   collapse (`CQLoweringPass.cpp:394`) the `WeakTrackingVH` record follows the RAUW to the ROOT MINT, so the
   rung-(iii) stage at `:431` asks with a seed OUTSIDE the loop and a read INSIDE — there is no slot both
   after the round-2 fixpoint and before the collapse. Options: (a) ask rung (iii) BEFORE the collapse and
   record the verdict; (b) make the collapse re-ask; (c) add a slot. Recommend (a) — it is the same
   "record at the site, re-ask after the fixpoint" pattern L1 prescribes.
2. **The loop customer's spelling.** Which C is the target: (i) `bool b[N]` — every iteration a FRESH qubit
   (needs the 7.5 memory path for a tainted bool array; today `taint escape`), or (ii) a scalar `bool b`
   re-prepared each trip (a CHAINED rotation on ONE qubit — a different circuit; only the last `b` is
   measurable)? The owner's flat file is (i)'s semantics. Recommend (i) as the target and (ii) as the first
   rolled increment only if the owner confirms it is a circuit they want.
3. **`21mg`** — `cq_measure` of a value that never became quantum: lower to the classical value, no gate
   (the fix sketch on the bd)? Recommend yes; it is the owner's own edit that hit it.
4. **The phase-path merge-φ** (`SCOPE_boi6.md` §0.3, probe `p5`): admitting the φ as a rail leaf for a
   `cq_phi` consumer moves the decline to the wire fence (`condition predates a non-diagonal gate`, bd
   `drbq.7`). Track M builds the SELECT/VALUE consumers (the owner's file) and files the phase consumer under
   `drbq.7` unless the owner wants it in the same increment.

---

## 2. Tracks — run in PARALLEL, each in its own worktree + `build/`, each with its own opus agents

Concurrency cap on this box is 6 agents (memory `workflow-concurrency-queueing`; `min(16, cores-2)`).
Budget: **at most 4 tracks active**, **never more than ONE full-suite gate in flight** (a full `ctest -j6`
plus `ir-pass-lit`'s 12 lit workers saturate the box — a second one produces contention FAILURES that read
like regressions). Launch the track whose result GATES others first (Track M gates the customer; Track R's
customer is behind M).

| track | bd | customer | worktree / branch | what it builds | budget |
|---|---|---|---|---|---|
| **M** — the region-merge-φ rail leaf for the 4.4 DATA SELECT and the VALUE diamond consumers | `boi6` (D-B half), `p20` | `probes/owner_file_2026-09-13.c` MUST compile; `va` MUST stay byte-identical (19 lines) | `../CQ_mphi`, `mphi-rail-leaf` | scoping → impl → r1 → fix → (r2) → merge-and-gate | 2 review rounds min |
| **R** — F2's collider set excludes the peel's compare CLONES (rb9x) — and whatever `vd`'s b0-prep F2 decline actually is | `rb9x` | `probes/vd.c` MUST compile once M has landed (R measures its wall on M's binary too) | `../CQ_rb9x`, `rb9x-f2-clones` | scoping (first measurement: is `vd`'s decline rb9x's clone collider or a new F2 collider? name it by `CQ_CTRL_DBG=1` anchor) → impl → r1 → fix → merge-and-gate | 1–2 rounds |
| **C** — `cq_measure` of a classical value lowers to the value | `21mg` | the owner's 2026-09-11 22:18 edit (second region commented out) | `../CQ_21mg`, `classical-measure` | impl → r1 → merge-and-gate (MeasureLowering is the sole sink; SMALL) | 1 round |
| **L** — the LOOP form: SCOPE ONLY this session unless owner Q2 is answered early | `wx8g`, `boi6.a`, `3qlq.6`, the array/7.5 wall | a canonical `grover_cascade_loop.c` (both spellings from Q2), plus its hand-unrolled twin | read-only, no worktree | `SCOPE_loop.md`: every wall in order on the ORACLE, per spelling; the increment plan (which bd first, what each needs from the drbq Inc-3 in-loop machinery, the `_Bool` axis the twin matrix lacks); the two `p2`/`p9` H-10 pins as red-green fixtures ready to land | — |

Start order: **M-scope, R-scope, L-scope and C-impl in one message** (4 agents). When M-scope returns,
spawn M-impl; when R-scope returns, R-impl; C-review when C-impl returns. Reviews and fixes as they come.
Landings are SERIAL (§6): C or R may land before M if ready — the landing order is "whatever is cleared",
but M's customer is re-measured on every merged binary.

Shared file hotspots (expect conflicts at merge; resolve by READING both sides): `ArmClassify.cpp` (M rail
ladder + R F2 caller), `SelectClassify.cpp` (M), `MergePhiPeel.cpp` (R's comment rewrite),
`MeasureLowering.cpp` (C), `TaintPropagation.{h,cpp}` (M if it records a deferred select).

---

## 3. THE NON-REDUNDANCY PROTOCOL — every agent runs ONLY what can witness its own change

This is the owner's addon for this session and it is binding: *"each agent should only run tests relevant
for them. we want to avoid redundant runs. implementer and reviewer also don't have to run the tests each
time. avoid redundancy at each opportunity."* Rule 19 already says the full suite is a GATE, not a
heartbeat; this section says WHO runs each gate and HOW OFTEN, so no gate runs twice on the same binary.

### 3.1 The gate ledger — one `GATES.md` per track, binary-hash keyed

Every track's record dir carries `GATES.md`. Every gate line is
`<gate> | <binary sha256 first 16 of cq-opt> | <result verbatim> | <who> | <when>`.
**A gate result is a fact about a BINARY, not about a moment.** Before running any gate, an agent reads
`GATES.md`: if the binary hash is unchanged and the gate is already recorded, it does NOT re-run it — it
cites the line. After running a gate, it appends the line. `shasum -a 256 build/ir-pass/cq-opt` is the key;
the implementer records it after every rebuild. The reviewer and the merge agent READ this file first.

### 3.2 Who runs what — the ownership matrix

| gate | scoping agent | implementation agent | review agent | fix agent | merge-and-gate agent (one per landing) | orchestrator / session end |
|---|---|---|---|---|---|---|
| build the worktree (`cmake --build build -j8`, BOTH targets) | never (uses the ORACLE) | once per edit batch | **never** (uses the implementer's binary) | once after the fix | once after the merge | primary `build/` once at end |
| per-probe pipeline (stage 1+2; 3+4 only where a trace is needed) | yes — its whole job | yes, on its own probes | yes — its whole job (subject vs ORACLE) | only the finding's probes | the track's probe corpora, once, on the MERGED binary | owner's file once at end |
| `lit --filter <one fixture>` | no | every fixture it writes, as it writes it (1.5 s) | at most ONE spot-check of an implementer claim (Rule 11), never a layer | the fixtures it touches | no | no |
| one `e2e-slice-<name>` | no | every slice it adds (1.7 s) | no | the slices it touches | no | no |
| `ctest -R ir-pass-lit` (~60–105 s) | no | **ONCE, at hand-off** — not after every edit | no | ONCE at hand-off, only if the change touched pass source | yes (part of the full run — not separately) | no |
| `ctest -j6 -R '^e2e-'` | no | no (the full run at merge covers it) | no | no | yes (part of the full run) | no |
| **full `ctest -j6`** | no | **no** | **no** | **no** | **YES — exactly once per landing, on the merged tree** | once, on the rebuilt primary |
| `cq-opt-equivalence-full` | no | no | no | no | only if the diagnostic/analysis surface changed (a new/changed decline string or a new analysis site) | once at end if any landing changed that surface |
| corpus sweep ORACLE-vs-SUBJECT (`corpus.sh` pattern from `../session-2026-09-11-orchestrator/review_integration_probes/`, over `ir-pass/test/*.ll` + every session probe dir) | no | **ONCE at hand-off**, result file committed to `probes/corpus_<hash>.txt` | **reads** the implementer's file; re-runs ONLY the movers it wants to inspect | ONCE after the fix (the binary changed) | ONCE on the merged binary | no |
| twin matrices (`loop_twin_matrix.py` etc.) | no | only Track L, only if it lands in-loop code | no | no | via the full run's `e2e-loop-twin-matrix` entry only | no |
| injection (mutation) matrix over the new accept fixtures (Rule 12) | no | ONCE at hand-off, report MISSED | reads it; may add mutants as probes | re-run only the mutants that were MISSED | no | no |
| `gen_templates.py --check` | no | only if `opcode_table.yaml` changed (no track here should) | no | no | yes if any runtime/template file changed | no |
| duplicate-body fixture scan | no | no | no | no | after every merge that renames fixtures | no |

**Corollaries, spelled out so nobody "just runs it to be safe":**

* The IMPLEMENTER's inner loop is `lit --filter` and single slices. `ir-pass-lit` runs ONCE, at hand-off,
  and its result line goes in `GATES.md` with the hash. It does NOT run `^e2e-`, the full suite, the
  equivalence sweep or a twin matrix. Its IMPL report has a "§GATES" section that is a COPY of `GATES.md`.
* The REVIEWER runs NO suite and NO build. It takes the implementer's `GATES.md` as fact for the binary it
  names (checking the hash matches the binary on disk is its one obligation), spends its budget on
  adversarial probes and analytic/trace reasoning, and may re-run at most one fixture to test a claim it
  doubts. A reviewer that reports "I re-ran ir-pass-lit" has spent budget the owner said not to spend.
* The FIX agent rebuilds (hash changes), re-runs the finding's probes + the fixtures it touched, runs
  `ir-pass-lit` once if it touched pass source, re-runs the corpus sweep once (the hash changed, so the
  old sweep is not a fact about this binary), appends to `GATES.md`. Nothing else.
* The MERGE-AND-GATE agent is the ONLY place the full `ctest -j6` runs during the session, ONCE per
  landing on the merged tree (Rule 19 moments 1 and 5 are satisfied there, because that IS the tree being
  committed). If two tracks are cleared back-to-back, the second landing's merge-and-gate covers both —
  do NOT rebuild and re-gate the primary between landings.
* The `cq-opt-equivalence` ROUTINE entry (`--stride 8`) already runs inside every full `ctest`; the FULL
  sweep runs only when a decline string or analysis site changed, and only at merge-and-gate.
* Round-2 review after a fix: the fix agent's `GATES.md` lines + its corpus file are the round-2
  reviewer's inputs. It does not re-run them.
* Scoping agents build nothing and run no suite. They run the pipeline on their probes against the ORACLE
  only; a "what does the branch binary say" question is asked of the implementer, not re-measured.
* Two tracks never gate the same thing: R's scoping measures `vd` on the ORACLE and, once M's branch has a
  binary, asks the ORCHESTRATOR for M's hash + path and measures `vd` on THAT (one run) — it does not
  build M's branch itself.
* The primary `build/` is READ-ONLY for every agent until §6 step 5. Every A/B in flight depends on it.

### 3.3 What "report only what you ran" means under this protocol

A gate line an agent CITED (from `GATES.md`) is written as *"cited: ir-pass-lit 1893/0 @ fbbe0820 (impl,
14:02)"*; a gate line it RAN is written as *"ran: …"*. Never the bare "tests pass". A cited line whose hash
does not match the binary on disk is a FINDING (someone rebuilt without recording), not something to
silently re-run.

---

## 4. Per-track agent chain and brief contents

Every brief is written BY YOU, with: the bd id(s); the customer file(s) by path; `file:line` anchors and
the predicate VERBATIM (from the scoping record, not from memory); the worktree, branch and `build/` path;
the ORACLE path + hash; **the §3 protocol row for that agent, copied in**; "do not commit, do not push";
"never write outside your worktree"; "report only what you ran (§3.3)"; the record file it must write and
where (`<track>/SCOPE_*.md`, `BRIEF_*.md`, `IMPL_*.md`, `REVIEW_BRIEF_*_rN.md`, `review_*_rN.md`,
`FIX_BRIEF_*_RN.md`, `FIX_*_RN.md`, `MERGE_*.md`, `GATES.md`, `probes/`). Style models: §0 of this file.

1. **Scoping agent (read-only, measure-first).** Verdict table over ≥20 probes on the ORACLE (every C
   spelling the owner might write + the hand-IR twins), every relevant `file:line` with the predicate
   quoted, the target stream READ OFF an existing accept twin (for M: the r9e5 bool data select
   `cnot-copy` merge on a raw `cq_theta_i1` control — the owner's file's stream must be `va`'s 19 lines
   followed by ONE more CNOT-copy select merge controlled on `h1`), the hazards (L1 round-2 windows: which
   records — `markRailCondRead`, `!cq.branchphase`, `taint.CmpCondReads` — does this consumer owe, and
   where is it re-asked?), the fixture/slice plan, the cost. For M specifically: measure BOTH candidate
   spellings' feasibility — (a) leaf admission by calling the one owner (which owner? `railPhiRootMint`
   is the in-loop one; for a FLAT prep merge the owner is `emitInPlaceRotationRegion`'s M-β target — name
   it) and (b) deferral of a select whose condition is a same-round region's merge φ until that region
   has emitted (then the r9e5 path sees `cq_theta_i1`) — with Rule 1's "no third path" discharged by the
   post-detect `declineClassicalMuxes` guard (measure that a deferred-and-never-claimed select DOES hit it).
2. **Implementation agent.** Red-green (Rule 12): decline fixture with the mirrored string FIRST, watch
   it fail, then the minimum lowering; positive `CHECK` counts in their own whole-file prefix; an
   injection matrix over the new accepts with MISSED reported; the L1 record at EVERY new emission site;
   the corpus sweep once at hand-off; IMPL with §GATES. Reuse before reinvention (Rule 14) — M must not
   write a second spelling of the 4.4 merge; it hands the r9e5 path its condition.
3. **Review agent (Rule 13, adversarial, analytic).** Over-ACCEPT is the unforgivable bug; the brief ALSO
   grades over-DECLINE (owner ruling). Probe families: the control is a PREPPED register (controlled Ry
   on it) — does the select's CNOT-copy ancilla see the right basis on both `b0` branches? `b1` measured
   before / after the select; `b1` read as data; TWO selects on one prep output; a prep output feeding a
   `cq_phi` (must decline at the wire fence with `drbq.7`'s string, or be admitted deliberately); the
   deferral never resolving (must be LOUD); N=3 (`vd`) on the subject; `cq_invert` around it. Verdict
   BLOCK / CLEAR-WITH-ITEMS / CLEAR, findings ledger `F-<track>-rN-k` with a reproducer each.
4. **Fix agent** per finding, written brief, §3 row copied in.
5. **Merge-and-gate agent** per landing (§6).

---

## 5. Customers and witnesses

* **C1** `probes/owner_file_2026-09-13.c` — exit 0, empty stderr, STRICT 2b clean; the first 19 lines
  byte-identical to `probes/va.trace`, then the b1-controlled `a`-mux. Commit it as an e2e slice
  (`slice_control_cascade_two_bools.c`) with its golden.
* **C2** `probes/vd.c` (N=3) — after R (and M) land. Slice `slice_control_cascade_three_bools.c`.
* **C1's discriminators** that must stay byte-unchanged: `va` (19 lines), every `control_peel_*`,
  `control_inplace_ry_*rail*`, `control_select_*bool*` fixture; the r9e5 bool data-select slices.
* **Loop (Track L)**: `grover_cascade_loop.c` in both Q2 spellings + hand-unrolled twins, committed as
  DECLINE probes with retirement triggers in the header (L8), not as accepts.

---

## 6. Landing procedure (serial; one opus merge-and-gate agent per landing; the squash is yours)

In the track's worktree: `git merge main` (conflicts resolved by READING both sides; every `ir-pass/src`
conflict listed with the resolution and the reason) → `cmake --build build -j8` → **the FULL
`ctest --test-dir build -j6`** (this is the ONE full run for this landing) → `cq-opt-equivalence-full` iff
the diagnostic/analysis surface changed → the corpus sweep on the MERGED binary (this track's probe dirs +
every previous track's this session + `../session-*/probes` from 2026-09-11) with every mover explained
before the squash → duplicate-body scan if fixtures were renamed → C1 (and C2 once R is in) measured on
the merged binary → `MERGE_<track>_N.md` + `GATES.md` lines. Then you squash:
`git checkout main && git merge --squash <branch> && git commit` with the tip hash, verdicts, counts, record
paths, `Co-Authored-By` + `Claude-Session` trailers. Step 5, after the LAST landing: one agent rebuilds the
primary `build/` (both targets), runs the full `ctest -j6` once, `cq-opt-equivalence-full` once if owed,
re-measures every count by command, and runs the owner's file — the trace goes in this dir.

---

## 7. Session completion (CLAUDE.md, non-negotiable)

File follow-ups in bd (every over-decline found in passing is a bd issue with its measured string);
`bd close` landed increments; `bd remember` per landed increment and per lesson (write the §3 protocol's
measured effect — how many full runs this session vs the four-track session's, and any gate that was
cited-but-stale — as its own memory); CLAUDE.md status paragraphs (counts re-measured by command);
ROADMAP; PRD `retire-swap-route-PRD.md` §0/§15 rows; lab-report entry 005
(`docs/labreport/TEMPLATE.tex` → `sessions/005-2026-09-1N-cascade.tex`, ≤5 pages, `tools/labreport/build.py
--seal`, sources committed, never the PDF); `git pull --rebase && git push && git status` (must show
up-to-date); worktrees removed; `NEXT_SESSION_PROMPT.md` in this dir with the loop plan from Track L's
`SCOPE_loop.md` as its spine.
