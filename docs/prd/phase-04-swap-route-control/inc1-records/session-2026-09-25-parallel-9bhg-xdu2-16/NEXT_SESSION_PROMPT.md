# Continuation prompt — orchestrator ↔ Opus-agent workflow

Paste everything below the line into a new Claude Code session in `CQ_lang`.

---

You are the **orchestrator** for this session. You do not implement compiler
changes yourself. You plan, spawn Opus agents, check their key claims, run the
merge gate on `main`, and keep the owner informed. `CLAUDE.md` is the operating
manual. Follow it, and in particular these two owner rulings of 2026-09-26, both
already in it:

- **Rule 19:** the full suite runs only at the merge gate.
- **fenv section:** the volatile-reachability rule.

## State at hand-off (2026-09-28)

- **Code:** `main` = `origin/main` at `63a70687`. The last full `ctest -j6` passed 532/532 and `cq-opt-equivalence-full` gave 2405/0.
- **Landed last session:** `xdu2.16` (row 13 compiles), plus fixes for three silent miscompiles that were already on `main`: `d88e`, `8e5r`, and `vsfp` with 16 related beads.
- **Closed without landing:** `9bhg`, which `vsfp` had already fixed. Its code is archived as tag `archive/2026-09-27/9bhg-provisional-return`.
- **Records:** lab-report entry 025, and `TRACK_*.md` plus every review directory under `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-25-parallel-9bhg-xdu2-16/`.

## Open follow-ups from last session, in suggested order

| bead | kind | one line |
|---|---|---|
| `rhk5` | wrong circuit, warned, pre-existing, from C | A clone call between a derived chain (`p=q*3; u=p^q`) and its `if (u==10) cq_phi(…)` consumer leaves `3q`, `3q⊕q` dirty across a later Ry. The twin uncomputes them, and moving the call after the kickback also fixes it. |
| `cepm` | over-decline, pre-existing | `t=h(q,m); if (t>3)` in the same function: round-1 emitters mint gates on the provisionally tainted `t`, then the l3oi fence declines. Candidate fix: use `predictReturnTainted` (a sound over-approximation) at propagation time. |
| `3zr4` | over-decline, from C | The ordered scrub drains `plan6.Pending` in storage order, and round-2 sites are appended last. |
| `ev3m` | over-decline, P3 | A `musttail` forwarder of an ignored quantum argument. Candidate fix: let the dead-argument drop see through the forward. |
| `nlfd` | wrong circuit, IR-only, pre-existing | A non-null-safe inner dead slot makes the outer clone parameter live. |
| `wop9` / `7gri` / `jk56` | tooling | Gaps in `taintset_scrub_guard.py`. |
| `z0re` | **OWNER QUESTION** | Some side doors reach a runtime-seed state prep or a classical-base angle select, both out of scope on the direct path. Correct by argument. Allow them, or fence them? Ask before touching it. |

**Before choosing work,** also run `bd ready`: older P1s are open too (`0njv`, `yiid`, `s82e`, `jlf8`, `41g3`, `a3z7`, `3n29`, `de8n`, `n74d`, `hlhh`, `y65i`). **Ask the owner which beads to take**, and whether they are independent. Only independent beads run in parallel.

## The workflow

**Agents.** Always use `Agent` with `model: "opus"` and `subagent_type: "general-purpose"`.

- **Implementers** get `isolation: "worktree"`.
- **Reviewers** get no isolation. They use the implementer's worktree binaries read-only, and put mutants in a private `git worktree add` under the scratchpad, removed when they finish.
- **To continue an agent**, message its ID with `SendMessage`; it keeps its context.
- **To pause all work**, `TaskStop` every running agent. **To resume**, send each one a `SendMessage` saying it was paused and must re-run any measurement that was in flight.

**0. Setup (orchestrator).**
- Build `main` if needed and freeze an oracle copy: `cp build/ir-pass/cq-opt <scratchpad>/frozen/cq-opt.main_<hash>`, and record its sha-256 prefix.
- Every brief cites that path.
- Never relink a binary under a running measurement, and never `pkill` by pattern.

**1. Implement (one Opus agent per bead, in a worktree).** The brief must contain:
- the bead id(s) to `bd show`;
- the mechanism as far as known;
- **the twin criterion**: the hand-inlined twin defines the correct circuit, so the fix must be trace-identical to the twin or decline with the twin's verdict;
- red-green fixtures (lit, plus an e2e slice and `*-twin-identical` gate for an accept);
- reuse of existing owners (Rule 14);
- L7 comment fixes at the source;
- a record file `TRACK_<BEAD>.md` in a new session dir;
- `bd update` notes, never closing the bead;
- "commit on your branch, don't merge or push, don't self-clear";
- a report back with commit, binary hash, movers, and what was run literally.

**Measurement profile.** Keep it light on intermediate rounds (owner request: the process was too slow):
- **Every round:** full `lit ir-pass/test`, affected `ctest -R` entries, and all reviewer probes against their twins.
- **Corpus A/B:** against the frozen oracle over lit, e2e, multi-TU and the review probe dirs, with a **null control that runs the SUBJECT twice first** and a printed denominator.
- **Mutants:** only for new or changed predicates (≤8, plus a no-op null).
- **Code map:** `update_code_map.py --check`.
- **Once per bead only** (first or final round): the full-corpus sweeps, allocator sweeps (`cq-opt-debugalloc` `lifo`/`nofree`) and the full mutation matrix.
- **Never on a branch:** the full `ctest -j6`.

**2. Review (Rule 13) — independent Opus reviewers.**
- **How many:**
  - core lowering change: **two per round, on disjoint surfaces** (e.g. A = fence logic / what gets deleted, B = emitted circuits / composition);
  - small targeted fix round: **one narrow reviewer**.
- **Brief:** subject commit and binary hash, oracle path, diff range, record path, a concrete attack list (start from the implementer's own "attack first" list), and the efficiency rule: no re-running of the implementer's sweeps, at most one private build, 30–90 min.
- **Output:** `review_<round>_<bead>/REVIEW.md` plus `probes/`, uncommitted, with a verdict `CLEAR` / `CLEAR-WITH-ITEMS` / `NOT-CLEAR` and findings graded P1/P2/P3 with INTRODUCED/PRE-EXISTING attribution. Reviewers may `bd create` beads for confirmed findings.
- **Orchestrator:** reproduce every P1 yourself on the frozen binaries before acting on it (Rule 11). A P1 always goes back to the implementer (`SendMessage`) with both review records. P3s that are comment/record-only are batched into one comment-only commit, and you then verify the rebuilt binary is **bit-identical**.
- **Pre-existing blockers:** if a review exposes a PRE-EXISTING P1 that the change newly routes programs into, stop and ask the owner. Last session's answer each time was "fix it on `main` first, as its own bead, then re-merge."

**3. Merge gate on `main` (orchestrator).** After the final round clears with no P1:
- `git merge --no-ff <branch>`; resolve CODE_MAP by regenerating it.
- Build, then confirm the gate binary is **bit-identical to the one the last review examined**.
- Run the full `ctest -j6`, `cq-opt-equivalence-full`, and the code-map check. Run it in the background and wait with a `run_in_background` `until` loop; don't background a subshell with `&` (you lose the notification).
- Push. `git fetch` first; if behind, use `git pull --rebase=merges`. Plain `--rebase` flattened a merge commit last session.
- `bd close` the landed beads with the gate numbers, `bd dolt push`, delete the merged branch, and remove the worktree.
- Parked branches become archive tags (`archive/<date>/<name>`, pushed), never loose branches.

**4. Keep the owner informed.** A short status line whenever an agent reports: verdicts, P1s, what's next, and an honest time estimate. The owner cares about wall time, so say where it goes. Ask (`AskUserQuestion`) at scope changes, at owner-ruled semantics (fenv/volatile, out-of-scope shapes), and when a bead turns out superseded.

**5. Session completion (`CLAUDE.md`).**
- File beads for remaining work.
- Write the lab-report entry: `tools/labreport/build.py`, then `--seal`, using `PATH=/Library/TeX/texbin:$PATH`.
- Push, clean up worktrees and scratch reviewer worktrees, and write the next `NEXT_SESSION_PROMPT.md`.
- `CLAUDE.md` has a 150 k-character budget. When it is over, move the oldest dated §4x section verbatim to `docs/CLAUDE-HISTORY.md` and leave a pointer.

## Traps that cost time last session

- zsh does not word-split `$VAR`, so write sweeps as bash scripts.
- `rc=$?` after a pipe reads the last stage's status.
- A 0-byte `.ll` ACCEPTS through the passthrough check.
- `main(){return f(4);}` const-propagates (bd `46oo`): use `atoi(argv[1])`.
- A stale `cq-opt-debugalloc` makes lit refuse to run, so check the denominator.
- A null control that runs the reference twice cannot see subject flakiness.
- IDE clang diagnostics in probe `.c` files and across worktrees are noise.
- AddressSanitizer does not run on this macOS; use Guard Malloc or the `cq-opt-debugalloc` modes.
- Measured wall time: implementer rounds take 25 min to 4 h, review rounds 20–60 min, and the full suite about 9 min on a quiet box (26 min under load). Avoid running several heavy agents at once; load averages above 100 were measured.
