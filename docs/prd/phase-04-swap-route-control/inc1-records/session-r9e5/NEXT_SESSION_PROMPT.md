# Next session — orchestrator prompt (written 2026-09-11 at the close of session `01NHxGVinGBKbb499HFCuwhT`)

You are the ORCHESTRATOR for this session of CQ_lang (`/Users/sorenwilkening/Desktop/CQ_lang`, `main`
at f7e9556 or later). You do not implement, review or fix code yourself: you spawn **opus** agents
for implementation, for independent Rule-13 review, and for fix rounds (`model: "opus"` on every
Agent call; a Fable agent is permitted for at most ONE clearance review per increment, and only when
the change can free a rail or alter a unitary silently). You may spawn agents IN PARALLEL for
independent work. You own the brief for every agent (bd ids, exact file:line anchors, predicates
verbatim, the pipeline commands, what NOT to touch), the gates (`ctest -j6` full before any commit
touching the Rule-13 core; `cq-opt-equivalence-full` after any diagnostic-surface change), the
landing (one squash commit per increment on `main`, branch tip recorded in the message), the lab-report
entry, the handoff, and the owner conversation. Read `CLAUDE.md` first — the Prime Directive, Rules
1/2/12/13/17/19, the CORRECTNESS-RISK paragraphs "INCREMENT 1b" and "INCREMENT 1b-B.1", and
Session Completion — then `bd prime`, and
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §13–§14.

## Step 0 — orient (you, no agents; 10 minutes)

1. `git log --oneline -5`; `bd ready`; `bd show test_C_libtooling-{54ur,fg9k,r10v,9pum,3d8q,l4x4,boi6,r903}`.
2. Re-run the owner's file: `./tools/show_pipeline.sh example/grover/grover_oracle_uncompute.c`
   (git-excluded; the owner may have adjusted it again). Its committed snapshot from the last close
   is `../session-3qlq4/user_file_as_of_2026-09-10_close.c` and it COMPILES on `main` (15 lines,
   stage-2b clean, `tests/e2e/slice_control_select_bool.c`). If the live file declines, name the wall
   against the list at the end of this prompt BEFORE anything else, and tell the owner.
3. Build once (`cmake --build build -j8`, both targets) and run `ctest -R 'select-bool|phase-bool'`
   so you know the tree is green before agents touch it.

## Step 1 — THE DISCUSSION WITH THE OWNER (before any implementation)

The owner does not have the full picture of the three pre-existing holes found on the way to 1b-B.1.
Present them plainly, in one message, and WAIT for a decision. Do not start an implementation agent on
any of the three until the owner answers. The facts (all measured; cite the files, do not re-derive):

**What they have in common.** The 4.4 tainted-condition `select` — `int a = (q > 5) ? x : y;`, the
most common control shape `clang -O1` produces — is classified by `classifySelectRegion`
(`ir-pass/src/SelectClassify.cpp`) with a ladder that was written in Phase 4.4 and never got the two
rungs every OTHER control consumer has since: (ii) "has the condition register been MEASURED before
the read on some path?" and (iii) "does a NON-DIAGONAL gate move the condition's wire between its
definition and the read?", asked at the RIGHT TIME (final taint). The rail (`bool`) path got both in
1b-B.1 (PRD §14.3, §14.8); the `br` kickback path has had them since Inc 1b / drbq. The COMPARE
select is now the least-fenced control consumer in the pass, and all three holes are that one fact
seen from three sides. Each is a verify-clean, stage-2b-clean, `opt`-exit-0 wrong unitary on `main`
TODAY, from plain C:

| bd | the program (plain C, `-O1`) | what is emitted | why nothing catches it | fix sketch | cost |
|---|---|---|---|---|---|
| **`r10v`** (P1) | `int b = cq_theta(0,.5); for (i<3) { int a = (b == 1) ? i : 5; acc += cq_measure(a) + cq_measure(b); }` — a loop-VARIANT arm keeps the select in the body; `b` is measured after it in the same block (`session-r9e5/probes/m2_inloop_select_measure_after_compare_twin.c`) | trip ≥2 mints `icmp_eq_i32_hl(h_b,1)` from a register trip 1 COLLAPSED: a post-measure control (Rule 6's loud-reject class) | the compare select has NO measured-before rung at all (gate 2c asks only the wire question); `declineStaleRecordOps` excludes select-condition compares | mirror §14.3 rung 2 for each compare leaf's TAINTED operand wire: a `cq_measure` user reachable-before the select ⇒ `condition measured before the control route` (`isPotentiallyReachable`, the same spelling as `railMeasuredBeforeReadPoint`) | ~30 lines in `SelectClassify.cpp`; a Rule-12 family (flat measure-after must stay an accept; side path; loop; two selects); one Rule-13 round |
| **`9pum`** (P1) | two TUs: `int q=cq_theta(3,.5); int y=5; if (q>5) y=ext_f(7); int b=cq_theta(y,.25); int b3=cq_theta(y,.9); int a=(b==1)?2:5;` (`review_b1_r2_probes/multi/e13_{caller,lib}.c`) | `ry(h,.25); ry(h,.9); icmp_eq(h,1)` — the flag minted from the post-`.9` register while the source compares the post-`.25` one | the wire question is asked at ROUND-1 taint (`y` is classical then — a 6.5 `%out` derivative, tainted only when `repropagateControlMerges` re-seeds), while `lowerRotations` decides "same rail" at FINAL taint; the RAIL half of this window is F-B1R2-1, FIXED in 1b-B.1 by `reverifyRailCondReads` | extend `TaintSet::RailCondReads` to COMPARE SEEDS: record each leaf's `condProvenance` set + its mint template call as the read point, and re-ask the position-free `findNonDiagonalWireGate` under final taint in the same stage (the record's shape was chosen for exactly this — PRD §14.8) | ~40 lines (`CondTreeEmit` record + the `reverifyRailCondReads` loop); a family of two-TU programs (the onward-classified compare must stay green; a round-2-tainted sibling AFTER the select must stay an accept); one round |
| **`3d8q`** (P1, from entry 002) | `int b = cq_theta(q,.5); int c = cq_theta(q,.9); return cq_measure(b) + cq_measure(c);` (and `review_b1_r1_probes/c/r42`: `measure(b0); b = cq_theta(b0,.3)` with no control at all) | lowers as one chain: `measure(b)` reads the post-`.9` register | the pass-wide stale-record guard (`declineStaleRecordOps`) sweeps PURE ops only, so a `cq_theta` or `cq_measure` READER of a stale name is never asked | sweep theta arg-0 / measure readers with `checkStaleOp`, excluding the reader itself (the reviewer's sketch is in the issue) | a different guard (`OpcodeLowering.cpp`); ~40 lines; its own family and round |

**Give the owner the decision menu with your recommendation first:**
1. *(Recommended)* one "compare-select fence parity" increment: `9pum` + `r10v` together (both live in
   `classifySelectRegion` and the re-verification stage; one probe family, one or two Rule-13
   rounds), then `3d8q` as its own small increment right after. Rationale: three P1 wrong-unitary
   holes on the most common control shape, each with a measured plain-C reproducer, and the fences
   already exist one consumer over — this is parity work, not design work.
2. `9pum` + `r10v` now, `3d8q` held (different guard, different file).
3. Hold all three and proceed to the `bool` increments (`54ur`, `fg9k`) — the holes are pre-existing
   and the `bool` path is fenced; the owner should know the compare path is not.

Secondary questions to put in the same message (short):
* **H-3** (`SCOPE_B2.md` §3.2): after a VALUE region, a chained `Ry` on the register (the S†) declines
  at P1 (`SawValueArm`); the 6.5 path has no P1 wrapper and would accept it. `54ur` must implement
  ONE answer — admit (argue from the state vector: the strip is `cnot(h_b, bf)` reading the same
  wire the copies read) or decline (consistency with P1). Ask which.
* The **CNOT-identity** form (`¬b·F = F ⊕ b·F`: fewer gates, no ancilla, one uncontrolled copy) is
  recorded as an option (`BRIEF_B1.md` §1, PRD §14.2); the shipped form was chosen for the smaller
  predicate surface. No action unless the owner wants gate count.
* `AllowLogicalSelect` for DATA selects (`b && q == 5` as a data condition declines `control flow`) —
  OQ-B1-4, a separate small widening if wanted.

## Step 2 — after the decision: the parallel plan

Spawn agents with full briefs (model them on `inc1-records/session-r9e5/BRIEF_B1.md`,
`REVIEW_BRIEF_B1.md`, `FIX_BRIEF_B1_R2.md`; every agent gets: bd ids, file:line anchors, the pipeline
commands from `CLAUDE.md` Build & Test, the saved pre-change binary for A/B, the probe corpora to
re-run, what not to touch, "do not commit", "report only what you ran"). Create a record directory
`inc1-records/session-<bd>/` per increment.

**Parallelism rules.** Scoping, probing and REVIEW agents are read-only on `build/` and may run in
parallel with anything. Two IMPLEMENTATION agents must NOT share `build/`: give each its own git
worktree and build dir (`git worktree add ../CQ_<name> -b <branch>`; there `cmake -S . -B build
-DLLVM_DIR=$(brew --prefix llvm@19)/lib/cmake/llvm -DCMAKE_BUILD_TYPE=Release && cmake --build build
-j8`, ~3 min), and land them SEQUENTIALLY, each with a full `ctest -j6` on the merged tree.
Concurrent `Workflow` calls share one agent cap — launch the gating work first.

Tracks, in dependency order:
* **Track A — compare-select parity** (`9pum` + `r10v`, then `3d8q`), if approved in Step 1. Impl
  agent → round 1 review (opus) → fix → round 2 → land. Budget the adversarial rounds up front: the
  last increment took THREE rounds and every one found something.
* **Track B — `54ur`, 1b-B.2a, the 6.5 classical-call arm on a `bool`** (needs the H-3 answer).
  `SCOPE_B2.md` §2.1 is the design: replace `ClassicalCallArmEmit`'s `lowerCompareToFlag` mint/strip
  pair with `emitCondNetwork(..., AllowQQLeaves=false, CopyRailRoot=true)` / `stripCondNetwork`
  (byte-identical for a bare compare — VERIFY on the `slice_control_classical_call*` goldens;
  `AllowQQLeaves=true` would silently widen 6.5 to Q+Q conditions, do NOT), admit a rail root in
  `classifyClassicalCallArm` with the §14.3 ladder (tainted; measured-before at the branch; the wire
  question; no `HasDataUse`/`ShareCondFlag`), and set `RailLadderProven`. Plain-C reproducer: a
  `noinline` pure callee with a run-time argument. Independent of Track A in files EXCEPT the shared
  `reverifyRailCondReads`/`RailCondReads` — run it in its own worktree and land after A.
* **Track C — `fg9k`, 1b-B.2b, the unfolded value diamond on a `bool`** (after B; ≥5-op arms and
  hand IR only — from plain C the short value arm IS a select and lowers now). `SCOPE_B2.md` §1.1/§2.2
  has the `CmpInst` sites with line numbers, the four arm classes that MUST keep declining (1b-C's),
  and hazards H-1..H-9. `emitValueRegion` builds its own `SelectRegion` — it must go through the rail
  ladder and set `RailLadderProven`, or `emitSelectRegion` refuses it (by design).
* **Track D — scoping only, in parallel from the start** (read-only opus agents): `l4x4` (1b-C: the
  in-place Ry / state prep / Ry angle select on a `bool` — note F2's `i1`-seed collision, entry 002
  Q6), `boi6` (1b-D: loop-carried and merge-phi `bool`), `r903` (negated nest level, NOT-carrying
  leaves, derived `i1`, the `thetaOnPathTo` parity gap). Each produces a `SCOPE_<id>.md` in the
  measure-first style of `SCOPE_B2.md` §0.1; build nothing.

## The wall list (for Step 0 item 2 and for every reviewer)

* `bare i1 register condition` — a `bool` driving an UNFOLDED value diamond (`fg9k`), a classical-call
  arm (`54ur`), an in-place Ry / state prep / Ry angle select (`l4x4`).
* `branch phase on a bare i1 condition` — a loop-CARRIED or merge-phi `bool` (`boi6`); negated nest
  level / NOT-carrying leaf / derived `i1` (`r903`).
* `condition measured before the control route` — the rail, or any name on its wire, is measured
  before the read on some path (intended; PRD §14.3 rung 2, §14.7, §14.8).
* `condition predates a non-diagonal gate` — a chained/sibling theta on the rail's wire before the
  read or in the loop body (intended; a theta AFTER the read is admitted, the S†). Since 1b-B.1 this
  is also raised AFTER emission by `reverifyRailCondReads` when round-2 taint reveals a sibling.
* `state prep seed is proven equal to the condition register` — a `bool` STATE PREP under control
  (entry 002 Q6) or a dead prep arm (Q4).

## Instruments (re-run before widening anything on these paths)

`inc1-records/session-r9e5/probes/` (44 C programs, README with verdicts), the three review corpora
`review_b1_r{1,2,3}_probes/` (each with a runner and its `VERDICTS_*.txt`),
`inc1-records/session-3qlq4/probes/`; `ctest -R 'select-bool|phase-bool|twin-identical'`,
`e2e-loop-twin-matrix`, `cq-opt-equivalence-full`. A corpus-diff harness (pre vs post binary over
every fixture: rc + stdout + stderr) is described in `IMPL_B1.md` §5 — re-create it in your
scratchpad on day one; it is the strongest single statement every landing makes.

## Session completion (non-negotiable, `CLAUDE.md`)

File follow-ups in bd; full `ctest -j6` before any core commit; one squash commit per increment on
`main`; `bd remember` every lesson; lab-report entry 004 (`docs/labreport/TEMPLATE.tex`, ≤5 pages,
`tools/labreport/build.py --seal`, commit the sources, never the PDF); `git pull --rebase && git push`
and `git status` up to date; write the next `NEXT_SESSION_PROMPT.md` in the session's record dir.
