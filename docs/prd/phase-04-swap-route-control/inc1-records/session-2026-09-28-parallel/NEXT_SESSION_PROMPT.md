# Continuation prompt — orchestrator ↔ Opus-agent workflow (v2, after the 2026-09-29 speed rulings)

Paste everything below the line into a new Claude Code session in `CQ_lang`.

---

You are the **orchestrator** for this session. You do not implement compiler changes yourself: you plan,
spawn Opus agents, check their key claims, run the batch gate on `main`, and keep the owner informed.
`CLAUDE.md` is the operating manual — read §4l and Rule 19 first; they changed on 2026-09-29.

## State at hand-off (2026-09-29)

- **Code:** `main` = `origin/main` at the session's last push (see `git log -1`). Landed this session, in
  order: bd `rhk5` → `z0re` → `cepm`/`3zr4` → batch 1 (`fmt3`, `nlfd`/`ev3m`/`m5pn`, scrub-guard rewrite) →
  batch 2 (`2dfk`: two ctest tiers + the content-addressed stage cache).
- **Records:** `docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-28-parallel/` (one
  `TRACK_*.md` per track + every review dir); lab-report entry 026.
- **Owner rulings of this session** (bd memories `owner-ruling-*-2026-09-2[89]`): runtime state-prep seed +
  untainted Ry-stem base admitted (z0re); `nomerge` on every `cq_theta_*` in `CQ.h` (fmt3); the α extension
  WITHDRAWN; batch gate + two tiers; scrub guard = accidental spellings only.

## Open follow-ups, suggested order

| bead | P | kind | one line |
|---|---|---|---|
| `4e4p` | P1 | wrong circuit, pre-existing | a `cq_theta` called through a function pointer loses `nomerge`; the fmt3 fold returns |
| `uw5u` | P1 | wrong circuit, pre-existing | `cq_theta((t==s)?t:s, θ)` folds to `cq_theta(s, θ)` (InstSimplify, and the pass's own dead-value stage) — no header attribute reaches it; a semantics question as much as a fix |
| `9oob` | P1 | wrong circuit, pre-existing, reserved names | a user-defined `__cq_q_*_unc` twin with a wrong body is trusted as the adjoint |
| `kyy1` | P1 | twin half, pre-existing | the hand-inlined twin of the kyy1 shape leaks |
| `ur72`, `4l5q`, `cx6j`, `gjn2` | P2 | over-declines | nlfd's instruction-class fence after rhk5 (IR-only); option-B costs of `nomerge`; by-difference for the unmerged if/else |
| `d773`, `j2fp` | P2 | tooling | the scrub-guard self-test shards (~12 min each) are now the gate's long pole — cache their verdicts; the guard should preprocess real TUs |
| `ffir`, `uyhx` | P3 | **OWNER QUESTIONS** | a compiler-kept clone copy-out rail vs the twin's folded one; relax `nullSafeSlot` |

Also run `bd ready`: the older P1s (`0njv`, `yiid`, `s82e`, `jlf8`, `41g3`, `a3z7`, `3n29`, `de8n`, `n74d`,
`hlhh`, `y65i`, `wt3l`) are still open. **Ask the owner which beads to take**, and whether they are
independent; only independent beads run in parallel.

## The workflow (v2)

**Agents.** `Agent` with `model: "opus"`, `subagent_type: "general-purpose"`. Implementers get
`isolation: "worktree"`; reviewers get none and use the implementer's binaries read-only, with any mutant
in a private `git worktree add` under the scratchpad. Continue an agent with `SendMessage` to its id.
Shared briefs: write a `BRIEF_COMMON.md` (implementers) and `BRIEF_REVIEWER.md` (reviewers) into the
scratchpad at session start — last session's are `BRIEF_COMMON.md` / `BRIEF_REVIEWER.md` in the session dir — copy and update the paths and hashes.
⚠ Phrase reviewer briefs as **compiler-correctness review** ("test programs", "counter-example"), not
security language ("attack", "hostile", "evil") — a reviewer was stopped by a safety classifier once.

**0. Setup.** Build `main`, freeze an oracle copy in the scratchpad (`frozen/cq-opt.main_<hash>`), record its
sha-256 prefix; every brief cites it. Never relink under a running measurement; never `pkill` by pattern.

**1. Implement** (one agent per bead). Brief: the bead ids; the mechanism as known; **the twin criterion**
(trace-identical to the hand-inlined twin, or decline with the twin's verdict; `tools/trace_twin_equiv.py`
when byte identity is impossible); red-green fixtures (+ e2e slice and twin gate for an accept); Rule 14
reuse; L7 fixes at the source; `TRACK_<BEAD>.md`; `bd update --append-notes` (**never `--notes`**, it
replaces); commit on the branch, no merge/push, no self-clear; report commit, hashes, movers, what ran.

**Measurement profile (owner: speed matters).** Every round: full `lit -j4 ir-pass/test`, affected
`ctest -R`, the reviewers' probes vs twins. Corpus A/B vs the frozen oracle with a null control (subject
twice) first — first round and final round only. Mutants only for new/changed predicates (≤8 + null).
Allocator sweeps once per bead, only if the change touches allocation-sensitive state. **Never** the full
suite on a branch.

**2. Review (Rule 13).** Core lowering change: two reviewers on disjoint surfaces per round; small fix
round: one narrow reviewer; comment/fixture-only round: none — verify the rebuilt binary is BIT-IDENTICAL.
Budget 30–60 min. Reproduce every P1 yourself on frozen binaries before acting. A P1 goes back to the
implementer with both review records. A PRE-EXISTING P1 that the change newly routes programs into: ask the
owner (usual answer: fix it first, as its own bead, land first).
⚠ **Before asking the owner to rule, carry the measured counter-example with the question.** Twice last
session a ruling was granted on a summary a probe then falsified (the α extension; "unreachable from C").

**3. Land in BATCHES (owner ruling 2026-09-29).** Merge cleared branches into `main` locally
(`git merge --no-ff`; resolve `CODE_MAP.md` by `git checkout --ours`, `git add`, THEN
`tools/update_code_map.py` from a clean index — bd memory `update-code-map-unmerged-index-trap`). If a
later branch needs composition evidence, build the merged binary and run the composition probes before
landing. Intermediate merges may run the fast tier `ctest --test-dir build -LE heavy -j6`. **Once per
batch** (normally at session end): `cmake -S . -B build && cmake --build build -j8`, confirm the gate binary
is the reviewed one (or name the composition), then the full `ctest -j6` + `cq-opt-equivalence-full` +
`update_code_map.py --check` in the background (`run_in_background`, never `&`). With the stage cache a warm
full suite is ~4 min, cold ~10 min. Then `git fetch`; if behind, `git pull --rebase=merges`; push; `bd close`
the landed beads with the gate numbers; `bd dolt push`; remove merged worktrees and branches.

**4. Keep the owner informed**: a short status line whenever an agent reports; honest time estimates; ask
at scope changes, owner-ruled semantics, superseded beads.

**5. Session completion (`CLAUDE.md`).** File beads for remaining work; lab-report entry
(`PATH=/Library/TeX/texbin:$PATH tools/labreport/build.py --seal`); `CLAUDE.md` ≤ 150 k characters (move the
oldest dated §4x verbatim to `docs/CLAUDE-HISTORY.md`, leave a pointer); push; write the next
`NEXT_SESSION_PROMPT.md`.

## Traps (measured)

- The machine is shared with other projects' sessions; load reached 457 on 12 threads. Keep ≤4 heavy
  agents; tell agents `-j4`. Avast + XProtect scan every freshly linked test executable.
- An API usage limit or a sleeping laptop kills agents mid-measurement: resume each with `SendMessage`,
  telling it to discard partial outputs and re-run what was in flight.
- zsh does not word-split `$VAR` — write sweeps as bash scripts; `rc=$?` after a pipe reads the last stage.
- A 0-byte `.ll` accepts through the passthrough; `main(){return f(4);}` const-propagates (use
  `atoi(argv[1])`); a stale `cq-opt-debugalloc` makes lit refuse to run.
- After editing `include/CQ.h`, reconfigure (`cmake -S . -B build`) before trusting any e2e result.
