You are the ORCHESTRATOR (Fable). You do not implement or review yourself; you spawn opus agents (Agent tool, model
"opus"), write briefs, judge output, keep the owner informed. Fable is permitted for ONE clearance review per increment.
Concurrency cap 6. Report only what you ran. Over-declining is safe; over-accepting is the one unforgivable bug. NO new
runtime symbol, ever (owner D3). Stop and ask the owner on any contradiction of a PRD §2 decision.

## Task: FIX bd `test_C_libtooling-eqpx` (P1) — owner ruling 2026-09-06: fix now, as a decline-only consumer tripwire
PRE-EXISTING silent miscompile (on the pre-3qlq oracle 52d7764 too): an in-loop in-place `xor`/`add` whose "classical
immediate" becomes TAINTED after the loop writer marked it (a 6.5 classical-call `%out`, a 4.5 data-mux `%out`, or anything
derived from one) is emitted as `cqrt_xorc_i32(h, <handle id>)` / `cqrt_addc_i32(h, <handle id>)` — a quantum rail in the
ABI's classical-immediate slot; `opt` exit 0, verify-clean, STRICT 2b blind. Read-only investigation (session 82e6b530):
`docs/prd/phase-04-swap-route-control/inc1-records/session-82e6b530/investigate_eqpx.md` + `eqpx_reproducers/` (43 programs
+ `immcheck.py`, the immediate-slot detector). Its findings, all measured on four binaries:
- FOUR `InPlaceRailOps` writers (`grep 'InPlaceRailOps.insert' ir-pass/src/LoopLowering.cpp` = 4): W1 `emitBreakForward`
  (7.4 break, :1698 — UNLISTED in `TaintPropagation.h:377` and notes §2's ⭐ row, and a measured member), W2 `tryCaseA`
  ACCEPT (:2281 = "round 1's railRoot marking", ONE site), W3 `collapseRailPhisIn` step (3) (:2679), W4
  `commitOutOfLoopInPlaceOps` (:2972 — already fenced by round 3: `isa<Constant>(Imm)` + the (1b) tripwire at
  `OpcodeLowering.cpp:325-333`). W1–W3 prove the RAIL, none proves the immediate stays classical.
- The ADD stem is correct only BY ACCIDENT (`clang -O1` closed-forms `r += w` and deletes/sinks the loop; xor has no SCEV
  form); one extra body op makes add a member (a1/a2/a3/n08). `sub` is safe by `inPlaceValueRailOperand`'s opcode gate.
- A BARE `%out` reaches it with no derivation (`ClassicalCallArmEmit.cpp:209` / `SwitchDataMuxEmit.cpp:144` taint `%out`
  at emission, pipeline :376, before repropagate :409). Commuted hand-IR mutates the WRONG register.
- Blast radius: 0/319 goldens carry the signature, 0/4134 session-2 lowered modules beyond the 10 known reproducers.

## The fix (spec from the investigation; Rule 17 — build this, do not decline the target shape)
A SECOND predicate in `OpcodeLowering.cpp` Phase 1, immediately after the existing (1b) block (~:333) and before the
M-C block (~:340): for every `taint.InPlaceRailOps` member NOT in `PreLoopCommittedInPlaceOps`, re-ask G2 ALONE under
FINAL taint — `inPlaceValueRailOperand(BO, taint) != nullptr` (`LoopLowering.cpp:143`; export it or include `LoopPlan.h`)
— and decline loudly `cq loop lowering: in-place rail op no longer provable at lowering`. It must NOT be the existing
tripwire widened: `inPlaceFenceHolds`' G5 loop test (`ArithLowering.cpp:~646`) is not gated by `IgnoreSelfMarking`, so
the full fence refuses 100% of in-loop sites. NO silent fallback to out-of-place (the marking already licensed
`IterationLocalBlocks`, the erased rail phi, `ClaimedRailRoots`, and for W1 the whole break transform +
`lowerBreakReversePlay`; bd memory `fix-that-predicts-a-later-stage-must-reverify-there`). Stronger form worth doing:
record the proven rail-operand INDEX at the writer (never a `Value *` — the drbq Inc-1 dangling defect) and have
`rewriteInPlaceValueRail` (`ArithLowering.cpp:~328`) consume it instead of re-picking from a `Tainted` that `promote()`
mutates during Phase 2. 8h7d.5 question, answered up front: a decline-only widening does not narrow
`railValueConsumerDisposition`'s `InPlace` cell (the Rule-8 fan-out guard + `collectRailGates`); a silent REMOVAL would
reopen 8h7d.5 F-1. Do NOT ship the writer-side `isa<Constant>(Imm)` analogue: it costs three measured capabilities
(`k01`/`k02`/`k03` — Argument and volatile-load immediates dtzb deliberately accepts).
Red-green (Rule 12), on main's binary (RED = accepts with a handle in the immediate slot) vs the fix (GREEN = the
mirrored decline): 8 declines — W2 xor-derived (`c1c_m_xor_and_noregion` + `tu_extf.c`), W2 bare-`%out` (`n04`), W2 add
(`a1`), W3 xor (`c1c_m_xor_*` in-body region), W3 add (`n08`), W1 xor (`n16` — ALSO the crash-risk fixture: W1 has a
post-`lowerOps` stage), W1 bare-`%out` (`n15`), the commuted hand IR (`hand_xor_commuted.ll`) — and 7 accept controls
byte-unchanged: `ctlA`, `k01`/`k03` (the two that separate "G2 alone" from `isa<Constant>`), `k02`, `n09`/`n10`,
`n02`/`n03` (4.4 select / Inc-2 value merge are NOT producers — tainted at round 1), `z36`. 0 new goldens, 0 golden
churn — that invariance is the gate. Record-truth fixes in the same increment: `TaintPropagation.h:377` + notes §2's ⭐
writer row (four writers; `emitBreakForward` added; `tryCaseA`/`railRoot` one site), notes §3.12's ADD row (falsified),
the bd description (one writer, one stem, one producer path short). Budget: one implementation round + TWO adversarial
opus lenses + ONE Fable clearance + full `ctest -j6` + ONE squash commit + push + `bd close eqpx` + `bd remember`.

## Read first
1. `bd prime`; `bd show test_C_libtooling-eqpx` (the ruling is in its notes), `bd show test_C_libtooling-3qlq`.
2. `inc1-records/session-82e6b530/` — README, `investigate_eqpx.md`, `eqpx_reproducers/`, `briefs/BRIEF_common.md`
   (the template — update its paths/hashes; this session's scratchpad may be gone), `rebase_c1d.md`, `review_c1e.md`.
3. `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §2 (the ⭐ once-only-stage table, ~line 962), §3.11 (F-C1B-1: the same class through
   W4 and how round 3 fenced it), §3.12 (eqpx), §3.14–§3.15; PRD §0 E2/E10; CLAUDE.md (Prime Directive; Rules 12, 13, 17, 19).
4. bd memories: `3qlq-c1-round4-landed-2026-09-06`, `fix-that-predicts-a-later-stage-must-reverify-there`,
   `once-only-stage-round2-false-premise`, `rolled-idiom-needs-body-gate-or-invariant-root`, `drbq-inc4-review-pattern`,
   `api-session-limit-kills-agents-relaunch-from-progress`.

## State (main = origin/main = the docs commit after 16b15b3; the last code commit is 16b15b3)
- Inc 0+1 (a3c1513), Inc 2 (258d974) and C-1 round 4 (16b15b3, bd 7yd0 CLOSED) are LANDED; the swap route is fully
  retired. Full ctest 367/367 at 16b15b3; main rebuilt and current (verify `find ir-pass/{src,include,tools} -newer
  build/ir-pass/cq-opt` is EMPTY). Counts: lit 1691, ctest 367 (e2e 357 / slices 321 / twin gates 26), goldens 323,
  matrix 259+29.
- ORACLE = commit 52d7764 (rebuild it in a scratchpad worktree if `/private/tmp` was cleaned: cmake configure +
  `cmake --build build -j8`, BOTH CQPass and cq-opt). Save each round's binary before rebuilding (red-green needs it).
- Open after eqpx (owner's call, in this order): 3qlq.13 (C-1 residuals incl. review_c1e F-C1E-2: a preheader op whose
  PARENT has a second unlowered tainted user), 3qlq.14, 3qlq.9, .10, .11, .12, 67n5, OQ-11/12/13/22/23; then increments
  3qlq.4 (bare tainted i1, one lens), 3qlq.8 (i128 phase half), follow-ons .5 (UNSOUND BY DEFAULT), .6, .7.

## Workflow that worked — repeat it
Oracle worktree first → briefs in the scratchpad from BRIEF_common.md (full context in every brief: bd ids, PRD §,
file:line anchors, strings verbatim, anti-stall rules; every agent keeps a progress file) → implementer → ONE narrow lens
per round → fix → lens → clearance (Fable, one) → full ctest → ONE squash commit → push → bd close → bd remember → session
record under `inc1-records/session-<id>/` + a NEXT_SESSION_PROMPT. If a lens finds a confirmed miscompile INTRODUCED by a
fix, the next round is a NARROWING only; a third such round means stop and ask the owner.
