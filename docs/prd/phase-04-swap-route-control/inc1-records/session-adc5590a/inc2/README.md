# inc1-records/session-adc5590a/inc2 — Inc 2's rebase, round 2 and clearance (2026-09-06)

Inc 2 (bd `test_C_libtooling-3qlq.3`, value arms by the controlled-copy merge) was implemented and round-1 reviewed in
session 1 on branch `3qlq-inc2` (base dfb8e83). This directory records session 2's part:

* `rebase_inc2.md` — the rebase onto the landed Inc 1 (a3c1513): the conflict table (two real conflicts of seven
  overlapping files), three intent repairs, every layered gate re-run.
* `review_inc2_r2.md` — the round-2 lens (Inc 2's mechanism CLEAR; F-I2-1 = a PRE-EXISTING leak on main, bd `7yd0`,
  fixed as C-1 round 4; F-I2-2 the reviewer flag resolved in the increment's favour; F-I2-7 = bd base-from-cond).
* `fix_inc2_r2.md` — the round-2 fix (record + fixtures only; binary byte-identical).
* `clearance_inc2.md` — the clearance whose verdict decided the landing. **VERDICT:
  `CLEAR-WITH-OWNER-QUESTIONS`** (2026-09-06, READ-ONLY on every checkout; subject binary
  `cmp`-identical to the round-2 baseline, so every round-2 measurement transferred). **No
  different unitary found** over 83 plain-C programs run on all three binaries (subject,
  `main` a3c1513 = INC-1-ONLY, and the pre-3qlq oracle 52d7764) through stage 1 → 2 →
  STRICT 2b → 3 → 4: **10 diamond/twin pairs byte-identical on the subject with every twin
  byte-identical across all three binaries** (so the witness is the pre-Inc-2 compiler's own
  stream, not a self-comparison), rolled == unrolled for a value merge feeding a per-bit
  kickback loop, the basis-state evaluator OK on all 27 traces whose mechanism changed, and
  **0 dirty frees** — 232 frees over 71 traces, every one preceded by a `*_unc` of that rail,
  and **0** frees of a chain final, a source `p`, a delta or a merge out-rail. Pinning:
  **17 accepts × 7 mutations, 0 NOT CAUGHT**; census over 1687 fixtures 829 accept / 858
  decline with `#cqrt_rz_i1 == #!cq.branchphase` everywhere and **0** non-`i1` Rz calls;
  fxdiff over the 1673 fixtures common to `main` **0 RCDIFF / 0 DIAGDIFF / 8 OUTDIFF**;
  orchestrator's full run **361/361, 531.88 s**. **The swap route is fully retired**:
  `emitRoute` has ONE call site (`AbortParkEmit.cpp:396`) and 1 of 319 goldens contains a
  `cqrt_cswap`. **On that verdict Inc 2 LANDED on `main` 2026-09-06 as ONE squash commit**
  (hash filled by the orchestrator: the squash of branch `3qlq-inc2`, whose tip is recorded
  in the landing commit message; `git log main -1` shows the hash). What it leaves open is
  **two new owner questions plus the standing ones and two record items**: OQ-C3-1 (a value
  diamond followed by a rotation on its result declines `operand predates a non-diagonal
  gate` while the pre-hoisted `select` twin accepts) and OQ-C3-2 (`int p = q*3; if (q>5)
  R6(p);` declines `non-routable value multiplexer` because instcombine folds the derivation
  into the chain head) — **both PRE-EXISTING, both measured identical on all three binaries,
  both in the safe over-decline direction, and both folded into bd
  `test_C_libtooling-3qlq.14`**; standing OQ-11/12/13/22/23; bd `test_C_libtooling-7yd0`
  (C-1 round 4, the PRE-EXISTING in-loop leak of PRD **E11** — in flight on branch
  `c1-round4`, NOT landed at the time of this landing) and bd `3qlq.8`; and record items
  **R-1** / **R-2**, applied as PRD §0 **E1a** / **E1b**.
* `briefs/`, `COMMIT_MSG_inc2.md`, `full_ctest_summaries.txt`.

Narrative record: `RETIRE_SWAP_ROUTE_INC2_NOTES.md` (§1 round 1, §2/§3 the rebase, §4 round 2, §5 the clearance) and
the PRD §0 ERRATA (E1, E11) + §7 STATUS.
