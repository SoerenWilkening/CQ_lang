# Orchestrator prompt — session 2026-09-14: the ruled undef-seed rule, the owner's N=3 file, and the loop

Written 2026-09-14 at the close of the diagnosis exchange (`main` `c7e797d`, docs-only over the pass at
`59ac5b7`). Owner's standing goal, verbatim (2026-09-13): *"the grover script might be implemented with a
large loop, where MANY of those controlled operations are applied"*; and (2026-09-11) *"our end-goal is to
not decline any code that will lead to a valid quantum circuit"*. An over-decline of a valid circuit is a
DEFECT to remove; the Prime Directive (never over-ACCEPT) is untouched.

You are the ORCHESTRATOR for CQ_lang (`/Users/sorenwilkening/Desktop/CQ_lang`). Hard constraints, all
owner-ruled, none negotiable:

* **Every agent you spawn is `model: "opus"`** ("you are only allowed to spawn opus agents", 2026-09-11).
* **You do not run builds, ctest, lit, the pipeline or corpus sweeps yourself.** You spawn an opus agent
  for every execution, including one-off measurements. You own: briefs, gates (deciding WHEN a gate runs
  and WHO runs it), the landing (squash commits on `main`), the records, the lab-report entry, the handoff,
  the owner conversation. `git` operations on `main` (worktree add/remove, squash, commit, push) are yours.
* **Read first:** `CLAUDE.md` (Prime Directive; Rules 1, 6, 7, 8, 12, 13, 14, 17, 19; CORRECTNESS RISK
  §1–§5 including §4b; Build & Test; Session Completion), `bd prime`, this directory, and — as the working
  model for the whole session — `../session-2026-09-13-orchestrator/{PROTOCOL.md, CLOSING_MEASUREMENTS.md,
  MERGE_BRIEF_TEMPLATE.md, CLOSING_BRIEF.md, DIAG_2026-09-14.md}` plus the style models
  `../session-2026-09-13-orchestrator/track{M,R,L,C}/*.md`.
* **Never relink a binary under a running measurement; never `pkill` by pattern** (bd memory
  `never-relink-or-pkill-under-measurement`). The primary `build/` is the frozen ORACLE for the whole
  session (`cq-opt` sha256 `f7b65d8ccd7bc472…`, `libCQPass.so` `f9e898badfd4207a…`, built from `59ac5b7`)
  and is rebuilt at most ONCE, at the end, and only if §6 step 5's identity check fails.
* **`cmake --build build --target CQPass` alone is a FALSE-GREEN trap** — `%cq-opt` is a separate target
  from the same sources; always `cmake --build build -j8` or name BOTH.
* **A merge can resurrect a `git mv`'d fixture** (memory `merge-resurrects-git-mv-fixture`): after any
  merge that renames fixtures, run the duplicate-body scan (sha-256 over each fixture's non-comment lines).

---

## 0. State at start — MEASURED, do not re-measure

`main` `c7e797d`. Counts at `59ac5b7` (`../session-2026-09-13-orchestrator/CLOSING_MEASUREMENTS.md`): lit
**1928** · goldens **367** · ctest **420** (`^e2e-` 410, `^e2e-slice-` 365, `twin-identical` 34) · twin
matrix 259 + 29 = **288** · `cq-opt-equivalence-full` **1928/0** · full `ctest -j6` **420/420** (393 s).

**The owner's file** `example/grover/grover_oracle_uncompute.c` (git-excluded) now carries **three** bools
and **declines**: `cq controlled lowering: state prep seed is proven equal to the condition register`. The
full diagnosis is `../session-2026-09-13-orchestrator/DIAG_2026-09-14.md` (24 probes, read-only, on this
ORACLE). Its findings, which you must NOT re-derive:

* The declining region is the **b1 prep**; its condition after `-O1` is the **b0 rail itself** (`a ∈ {2,5}`
  makes `a >= 3` equivalent to `!b0`), which is why the `!dbg` names the b0 `cq_theta` line and not the
  region — a diagnostic-honesty defect, bd `p25o`.
* The **collider is the THIRD region's own guard** `%9 = icmp sgt i32 %8, 2`, reached by F2's FORWARD half,
  pinned `i1 false` on the straight-through edge (`a ∈ [-1,2]` there) and bit-identical to the `bool b1 = 0`
  seed. Surgery: delete the third **theta** and keep its **guard** ⇒ declines identically. Not a peel (so
  not `rb9x`); not an `int a = 5` artefact (a runtime `a` declines identically).
* **No edit preserves the intended cascade**: every accepting variant emits a different circuit.
* Same collider as `vd.c` ⇒ **bd `om35`**, which is the R-2/R-2′ decision.

**Uninitialized variables**, measured at three sites with three verdicts: `cq_measure` of a never-quantum
undef **declines** (bd `21mg`, landed, deliberate); an undef seed prepared **in a region** declines at F1;
the same seed prepared **unconditionally** **ACCEPTS SILENTLY** and emits `cqrt_alloc_i1(i1 undef)` (trace
printed `1`). That third one is the subject of the ruling below.

---

## 1. THE OWNER'S RULING OF 2026-09-14 — build it exactly as ruled (bd `z9t1`, P1)

Verbatim: *"we should NOT make every uninitialized variable to 0. Jut before it hits cq_alloc_*. then clang
still can exploid it"* and, when asked about placement and a warning, *"both codes are supposed to compie!!
also no warnings."* Five clauses, every one load-bearing (bd memory
`undef-seed-is-zero-at-allocation-2026-09-14`):

1. **The rule attaches to QUBIT ALLOCATION, not to variables.** An `undef`/`poison` SEED reaching a
   **source** `cq_theta`'s arg-0 becomes a concrete `0` at the allocation. CQ makes **no** claim about the C
   variable, and **clang keeps every liberty it has** — including deleting a branch that reads the same
   uninitialized value, which is MEASURED (an uninitialized `int` in a guard makes the guard vanish before
   the pass runs, leaving no trace). The residual is **documented, never fenced**: such a program is UB in C
   and has no defined behaviour to be wrong against.
2. **BOTH spellings must compile** — `bool b; b = cq_theta(b,.5);` **and** `bool b; if (c) b = cq_theta(b,.5);`
   This FORCES the placement: **normalize EARLY, before classification**, so F1/F2 and every downstream fence
   see a concrete `0`. At the emission site the in-region spelling still dies at F1.
3. **SILENT.** No warning, no diagnostic, exit 0.
4. **`cq_measure` of a never-quantum uninitialized value KEEPS DECLINING** (bd `21mg`'s fence). No
   allocation, no register, nothing quantum — the rule does not reach it, and that asymmetry is
   **principled**. Quote that sentence when someone calls it an inconsistency.
5. **NOT TOTAL.** `valueCarriesUndef` is CONSTANT-ONLY, so an undef arriving through a `phi` with an undef
   incoming is not caught and stays as today (bd `bwsh` holds that residual).

Why this is an improvement and not a loosening, and it must be written in the source: today the shape
compiles **silently** and hands `i1 undef` to the allocator, so the starting basis state is whatever the
`-O0` stage-3 link materializes; with the rule the rail is deterministically `|0⟩` and every reader of the
emitted IR sees **one** constant — which REMOVES the `declineUnpairedUndefLiterals` multi-materialization
hazard rather than creating it.

---

## 2. Owner questions — ask in your FIRST message; start every track that does not depend on an answer

1. **bd `om35` — the N=3 cascade (THE OWNER'S LIVE FILE).** The audited closing spelling is **R-2′**: *a
   collider pinned on only ONE edge is not a collider* (F1 pins the pred slot, so the rival is unfoldable by
   complete case analysis: a literal pred slot ⇒ R3 declines it, a register pred slot ⇒ F1 declines it). It
   closes `vd.c` **and** `rb9x` with an argument rather than a proxy, but it **flips ≥11 shipped decline
   fixtures** (`range_forward_*`, `sideways_*`, `merge_edge_sideways`, `step_cap_over`, `…_second_flag_i1`),
   which pin the F2 family that 42 measured confirmed-miscompile programs produced. **The question is not
   "is R-2′ safe" but "spend the budget re-deriving those 11".** Track F's SCOPING answers it with a table
   before you ask, so ask the owner only once that table exists. Recommend: yes.
2. **Loop spelling (carried from 2026-09-13).** Track L measured that the scalar `bool b` re-prepared per
   trip denotes a DIFFERENT circuit (`a` reaches −1 at N=2, −4 at N=3) and that `bool b[N]` has exactly ONE
   wall. Recommend **(i) the array** (bd `xdu2`, L-1a) and proceed on it unless the owner says otherwise.
3. **bd `3d8q` priority.** It is the project's one KNOWN pre-existing silent miscompile (a `cq_theta` or
   `cq_measure` READER of a stale name is asked by nothing), its population has been widened twice, and
   Track M's own F-M3 decline is pinned with "land the `3d8q` fence, then re-derive `condProvenance`'s seed"
   as its retirement trigger. It is correctness, not expressiveness — the owner has been spending on
   expressiveness. Ask whether it gets a track this session. Recommend: yes, one track.

---

## 3. THE NON-REDUNDANCY PROTOCOL — owner addon 2026-09-13, STRENGTHENED by what it measured

Owner, verbatim (2026-09-13): *"each agent should only run tests relevant for them. we want to avoid
redundant runs. implementer and reviewer also don't have to run the tests each time. avoid redundancy at
each opportunity."* Re-stated (2026-09-14): *"test runs should be reduced to a minimal number. also
redundant testing across agents should be avoided."*

`PROTOCOL_PREV.md` beside this file is last session's text and its ownership matrix is still binding —
**copy that matrix into every brief you write**. Last session it produced **4 full-suite runs for 3
landings** with **0 cited-but-stale gate lines**. Two measured facts from that session make it cheaper
still, and both are now REQUIRED:

### 3.1 ONE COMBINED GATE for tracks that touch DISJOINT files

Last session gated per landing, so N landings cost N full suites. The per-landing gate exists to keep
corpus movers attributable. That attribution is only at risk when two tracks touch the same file.

**The rule.** Before landing, you partition the cleared tracks into groups: two tracks are in the same
group iff they touch a common file under `ir-pass/`, `include/`, `runtime/` or `tools/` (fixtures and
records do not count; `tests/e2e/CMakeLists.txt` does not count — it is append-only at disjoint anchors and
merged cleanly three times last session). **One merge-and-gate agent per GROUP, not per track**: it merges
every branch in its group into one worktree, rebuilds once, runs the full `ctest -j6` ONCE, runs
`cq-opt-equivalence-full` once if any track in the group moved a decline string or an analysis site, and
runs ONE corpus sweep on the combined binary — with the movers attributed per track by string (each track's
brief states its own expected strings, so an unattributable mover is a FINDING). You then squash each
branch separately on `main`, in the group's order, and the LAST squash is the one whose tree the closing
check verifies. Expect **1–2 full-suite runs for the whole session** instead of one per landing.

⚠ If a group's gate goes red, the interaction is exactly what a per-track gate would have hidden — do not
"fall back" to per-track gates to find it; bisect by reverting one branch's merge in the same worktree.

### 3.2 The CLOSING full suite is CITED, not re-run, when the tree is identical

MEASURED last session: the closing rebuild of the primary produced a binary **bit-identical** to the last
merge-and-gate's, so its full suite reproduced that result exactly — a wholly redundant run. **The rule:**
the closing agent rebuilds the primary and compares. If (a) `git diff --stat <last gated branch tip> main --
ir-pass include runtime tests tools` is EMPTY and (b) the rebuilt `cq-opt` sha256 equals the gated binary's,
then the full suite and the equivalence sweep are **CITED** from that gate's `GATES.md` lines, not re-run,
and the closing record says so in those words. If either check fails, run both — and the failure itself is
a finding worth its own line (something entered the tree outside the gate).

### 3.3 What has not changed

The ownership matrix (scoping builds nothing; implementer = `lit --filter` + single slices, `ir-pass-lit`
ONCE at hand-off, corpus ONCE, injection ONCE, never `^e2e-`, never the full suite, never the equivalence
sweep; reviewer = NO build, NO suite, ≤1 fixture re-run, its one obligation is `shasum` against `GATES.md`;
fix agent = rebuild + the finding's probes + `ir-pass-lit` once iff pass source changed + corpus once).
The hash-keyed `GATES.md` per track. `cited:` vs `ran:` in every report. Never more than ONE full suite in
flight on this box.

**Instrument lessons that cost time last session — put them in the briefs:** lowered-IR md5s are NOT
comparable ACROSS sweeps (the temp `ModuleID` changes; compare within a row only); the shared `corpus.sh`
tag regex renders the whole `cq_measure_<sfx>` family as an empty `D:` so a decline→decline string change
inside it is INVISIBLE (close with a full-stderr + exit byte-compare over the decline rows); a mutation
harness that reports `n/a` is a HOLE, not a pass; a named negative check can be VACUOUS (it names a handle
the module never defines — run `../session-2026-09-13-orchestrator/trackM/probes/impl/vacuity.py` over every
new accept fixture batch); and a bare `-NOT: <word>` can match the module's own path/header line (bd `qta2`).

---

## 4. Tracks — wave 1 in ONE message, then wave 2 as scopings return

Concurrency cap on this box is 6 agents. **At most 4 tracks building at once.** Scoping agents are
read-only and cheap; launch them together.

| track | bd | what | worktree / branch | depends on |
|---|---|---|---|---|
| **U** | `z9t1` (P1) | **The ruled undef-seed rule** (§1). Normalize an `undef`/`poison` source-theta seed to `0` EARLY, before classification, silent. Both spellings compile. `cq_measure`'s fence untouched. | `../CQ_undef`, `undef-seed-zero` | nothing — RULED, start immediately |
| **F** | `om35` | **The owner's N=3 file.** SCOPE FIRST (read-only): the 11+ flipped fixtures, one row each — what the fixture pins, whether R-2′ makes it accept, and whether its ACCEPT is correct (re-derive the rival per row, the way `SCOPE_R2.md` did). That table is what the owner rules on. Then build R-2′. | `../CQ_r2p`, `r2prime-one-edge` | owner Q1, after the scoping table |
| **P** | `3qps` + the ROOT-ONLY widening | **The phase consumer on a prep merge-φ** (`if (b1) cq_phi(θ)`) — the SAME predicate Track M landed for the select, at `classifyPhaseKickback` step 5b; plus admitting a prep φ as an INTERIOR leaf of a compound condition tree. One increment, one grammar. | `../CQ_phiphase`, `mergephi-phase-leaf` | nothing |
| **D** | `3d8q` | **The one known silent miscompile.** Sweep `@cq_theta_*` (arg-0) and `@cq_measure_*` with the same position-aware `checkStaleOp`, excluding `I` itself. Its retirement trigger is quoted in two shipped fixtures. | `../CQ_3d8q`, `stale-reader-fence` | owner Q3 |
| **L** | `xdu2` (L-1a) | **The LOOP: the bounded rail ARRAY.** `[N x i1]` → `[N x i32]` of handles in classical memory; no new ABI; rails stored to memory are FROZEN. SCOPE FIRST. | `../CQ_railarray`, `rail-array` | owner Q2 |

**Wave 1, one message:** U-impl, P-impl, F-scope, L-scope. **Wave 2:** D-impl (once Q3 is answered),
F-impl (once Q1 is answered), L-impl (once Q2 is answered and L-scope returns), reviews and fixes as they
come.

**File hotspots, for the §3.1 grouping:** U touches the early normalization site (likely
`TaintPropagation.cpp` or `RotationLowering.cpp` — the scoping/impl agent decides and reports); F touches
`ArmClassify.cpp` (F2's test); P touches `ArmClassify.cpp` (the kickback classifier) **and**
`SelectClassify.{h,cpp}` (the grammar) — **P and F share `ArmClassify.cpp`, so they are one GROUP**; D
touches `OpcodeLowering.cpp`; L touches `TaintPropagation.cpp` + a `QramLowering`-shaped predicate — **L and
U may share `TaintPropagation.cpp`**. Confirm each track's real file set from its IMPL report before you
partition; do not partition from this table.

---

## 5. Customers and witnesses

* **C1** the owner's real file `example/grover/grover_oracle_uncompute.c` (git-excluded, three bools) — MUST
  compile once F lands. Commit it as `slice_control_cascade_three_bools.c` with its golden.
* **C2** `bool b; b = cq_theta(b,.5); … cq_measure(b);` and `bool b; if (c) b = cq_theta(b,.5); …` — BOTH
  must compile once U lands, silently, with the rail seeded 0. Both become slices.
* **C3** `bool b2; … cq_measure(b2);` — MUST KEEP DECLINING (bd `21mg`'s fence, ruling clause 4). Pin it.
* **Discriminators that must stay byte-identical:** `slice_control_cascade_two_bools.expected.log` (29
  lines), `va` (19), the `slice_measure_classical_bool` pair (15), `slice_control_stateprep_bool_under_int_compare_fused`
  (22), every `control_peel_*` and `control_inplace_ry_*` fixture, and the 11 F2 fixtures F is re-deriving.

---

## 6. Landing procedure

Per §3.1: one merge-and-gate agent per GROUP (`MERGE_BRIEF_TEMPLATE.md` in the 2026-09-13 dir is the
instance template — copy it, fill the group's branches, expected strings, customers and the equivalence
owed/not-owed line). Then you squash each branch on `main` in the group's order, each with its own message
(the tip hash, the verdicts, the counts, the record paths, the `Co-Authored-By` + `Claude-Session`
trailers). **Step 5, after the LAST squash:** one closing agent runs `CLOSING_BRIEF.md` (in the 2026-09-13
dir) with §3.2's identity check in front of it — cite the gate if the tree is identical, re-run both gates
if it is not.

---

## 7. Session completion (CLAUDE.md, non-negotiable)

File follow-ups in bd (every over-decline found in passing is an issue with its measured string); `bd close`
landed increments; `bd remember` per landed increment and per lesson (include the measured effect of §3.1
and §3.2 — how many full suites this session actually cost, and whether the closing citation held);
CLAUDE.md status paragraph with counts re-measured by command; ROADMAP; PRD `retire-swap-route-PRD.md` §0 +
a new §17; lab-report entry 006 (`docs/labreport/TEMPLATE.tex` → `sessions/006-2026-09-14-*.tex`, ≤5 pages,
`tools/labreport/build.py --seal`, sources committed, never the PDF); `git pull --rebase && git push && git
status` (must show up-to-date); worktrees removed and branches deleted; `NEXT_SESSION_PROMPT.md` in this dir.
