# Session 2026-09-18 — the agent protocol (binding; carried from 2026-09-15 with TWO corrections at the top and ONE new section §6.1)

> ⚠ **THIS FILE'S ORACLE BLOCK HAS BEEN CORRECTED FOR THIS SESSION.** Its two predecessors each
> shipped their predecessor's hashes and had to be corrected at the point of use. The lesson, which
> is now a standing instruction to whoever copies this file next: **a protocol copied verbatim
> carries its predecessor's measurements with it, and a measurement is a fact about a moment.**
> Correct the oracle block at the TOP, before any track reads it.

Repo `/Users/sorenwilkening/Desktop/Projects/CQ_lang` (⚠ MOVED on 2026-09-17 — every older PROTOCOL names `~/Desktop/CQ_lang`; the primary `build/` was reconfigured in place), `main` `cff8f7ac` (pass source unchanged since `95949550`).
`LLVM=/usr/local/opt/llvm@19/bin` (NOT on PATH).
`SES  = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-18-orchestrator/`
`PREV = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/`
`THIS = docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-17-socratic/`

## ORACLE — read-only, frozen for the whole session

Re-verified by the orchestrator at session open, 2026-09-17 11:30, against `main` `cff8f7ac` (measured 2026-09-17 10:26 on `79bd7af9`; pass source == `95949550`):

```
9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3  build/ir-pass/cq-opt
3e3dc35d471aae6b53067ffc374745f8cd9f148870a1879d971c8bdab831695d  build/ir-pass/libCQPass.so
```

⚠ Before the 2026-09-17 rebuild the primary `cq-opt` had been the 2026-09-14 oracle (`0e280fc6…`) for
three landings; any decline the owner measured by hand before 2026-09-17 10:26 may have been measured on it.

`shasum -a 256` it before you use it; if it differs, STOP and report — someone rebuilt the oracle.
⚠ A stale `cq-opt` makes a **fixed** program look broken by hand and a **broken** pass look green in
lit. The hash is the cheap discriminator; use it before believing any decline.

## Per-probe pipeline (from a repo root; `BUILD` = the build dir of the binary you are measuring)

```
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S <probe>.c -o s1.ll
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S s1.ll -o s2.ll; echo "opt exit=$?"
python3 tools/free_pairing_check.py s2.ll                                                        # accepts only (STRICT stage 2b)
"$LLVM/clang" s2.ll "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o a && ./a  # accepts only; link order load-bearing
CQ_CTRL_DBG=1 "$BUILD/ir-pass/cq-opt" ... 2>&1 | head                                            # to name the firing site/anchor of a decline
```

`cq-opt` and stock `opt -load-pass-plugin` are byte-equivalent (gated); use `cq-opt` (0.12 s vs 0.24 s).

## The non-redundancy protocol

**A gate result is a fact about a BINARY, not about a moment.** Every track dir carries `GATES.md`;
every line is

```
<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
```

Before running any gate, read `GATES.md`: if the binary hash is unchanged and the gate is recorded,
do NOT re-run it — cite the line. After running one, append the line. The implementer records the
hash after every rebuild. Report a cited gate as `cited: ir-pass-lit 2039/0 @ 0e280fc6 (impl, 14:02)`
and a run one as `ran: …`. **Never the bare "tests pass."** A cited line whose hash does not match the
binary on disk is a FINDING.

| gate | scoping | implementation | review | fix | merge-and-gate |
|---|---|---|---|---|---|
| build the worktree (`cmake --build build -j8`, BOTH targets) | never (ORACLE only) | once per edit batch | **never** | once after the fix | once after the merge |
| per-probe pipeline | yes — the whole job | own probes | yes — subject vs ORACLE | the finding's probes | the track corpora once, MERGED binary |
| `lit --filter <one fixture>` (1.5 s) | no | each fixture as written | ≤1 spot-check (Rule 11) | touched fixtures | no |
| one `ctest -R '^e2e-slice-<name>$'` (1.7 s) | no | each slice as added | no | touched slices | no |
| `ctest -R ir-pass-lit` (~60–105 s) | no | **ONCE at hand-off** | no | ONCE at hand-off iff pass source touched | inside the full run |
| `ctest -j6 -R '^e2e-'` | no | no | no | no | inside the full run |
| **full `ctest -j6`** | no | **no** | **no** | **no** | **YES — once per landing** |
| `cq-opt-equivalence-full` | no | no | no | no | iff a decline string / analysis site changed |
| corpus sweep ORACLE-vs-SUBJECT | no | ONCE at hand-off → `probes/corpus_<hash16>.txt` | reads it; re-runs only movers it inspects | ONCE after the fix | ONCE on the merged binary |
| injection (mutation) matrix over new accepts | no | ONCE at hand-off, MISSED reported | reads it | only the MISSED mutants | no |
| twin matrices | no | only if in-loop code lands | no | no | via the full run only |
| duplicate-body fixture scan | no | no | no | no | after any merge that renames fixtures |

Corollaries: the implementer's inner loop is `lit --filter` + single slices — NOT `^e2e-`, NOT the
full suite, NOT the equivalence sweep. The reviewer runs NO build and NO suite (its one obligation is
checking the `GATES.md` hash against the binary on disk). The fix agent rebuilds (hash changes),
re-runs only what the finding names, `ir-pass-lit` once iff pass source changed, corpus once. The
merge-and-gate agent is the ONLY full-`ctest` runner during the session. **Never more than ONE
full-suite gate in flight on this box.**

## Non-negotiables for every agent

* `model: opus`. **Do not commit, do not push.** Leave your work as committed-on-your-branch only if
  your brief says so; otherwise leave the worktree dirty and report. Never write outside your worktree.
* Never write under `ir-pass/`, `include/`, `runtime/`, `tests/`, `tools/` of a checkout that is not
  yours. Records go in `$SES/track<X>/` **inside your worktree** (scoping agents: in the main
  checkout's `$SES/track<X>/`).
* The primary `build/` at `/Users/sorenwilkening/Desktop/Projects/CQ_lang/build` is **READ-ONLY**. Never relink
  a binary under a running measurement; **never `pkill` by pattern** — the safe form is to record the PID at
  launch and kill THAT, or `pkill -f '<absolute path to YOUR worktree>'` (2026-09-15 F-1: a pattern kill
  deleted another track's gate).
* **BUILD CAP (2026-09-15 R13): at most ~3 concurrently BUILDING tracks on this box, each at `-j2`–`-j4`,
  BOTH targets.** Scoping and review agents do not build and do not count. Record an unfinished gate as an
  ABSENCE, never a green or a red; re-run any red serially before calling it a regression.
* **bd writes only from the MAIN checkout.** `.beads/` is per-checkout; a `bd` write from a worktree creates
  a DB the main checkout never sees. Tracks REPORT bead changes in their records; the orchestrator (or a
  Wave-0 agent in the main checkout) applies them. ⚠ `bd update --notes` REPLACES notes; always `--append-notes`.
* `cmake --build build --target CQPass` ALONE is a **FALSE-GREEN trap** — `cq-opt` is a separate target
  from the same sources. Always `cmake --build build -j8`, or name BOTH `CQPass` and `cq-opt`.
* **Rule 12** — red-green. Write the fixture first (positive CHECK **plus** a `RUN: not …` negative
  mirroring the diagnostic character-for-character), watch it fail, implement minimally.
* **Rule 13** — a core-lowering change is not cleared by a green suite. Budget the rounds; the measured
  hit rate says the next round finds something.
* **Rule 17** — do not substitute a decline for the lowering you were asked to build. If it proves
  genuinely hard, STOP and bring the question back through the orchestrator to the owner.
* **Rule 19** — report only what you ran, with the command shown. Measured numbers, never estimates.
* Over-declining an **input** is safe; over-accepting is the unforgivable bug; and — owner ruling
  2026-09-11 — an over-decline of a valid circuit is a **DEFECT to file (bd)**, not a safety margin.
* Corpus sweep recipe: `$PREV/../session-2026-09-11-orchestrator/review_integration_probes/corpus.sh`
  (a row = exit code, diagnostic string, md5 of the lowered IR when accepting; both binaries on the
  same stage-1 file). Corpora: `ir-pass/test/*.ll` + every session dir's `track*/probes` and
  `review_*_probes/`.

## S1 — ONE COMBINED GATE per DISJOINT-FILE GROUP

Two tracks are in the same GROUP iff they touch a common file under `ir-pass/`, `include/`,
`runtime/` or `tools/`. Fixtures and records do not count.

⚠ **`tests/e2e/CMakeLists.txt` is NOT append-only at disjoint anchors** (measured erratum,
2026-09-14). It has ONE anchor for new slices — the tail, immediately above the `get_property(...)` /
`set_tests_properties(...)` sweep that must stay LAST. Every slice-adding track appends at the same
place. **Expect a tail conflict per slice-adding branch beyond the first**; resolve by UNION in merge
order; then run the three post-union checks:

```
grep -o 'add_test(NAME [A-Za-z0-9_-]*' tests/e2e/CMakeLists.txt | sort | uniq -d   # MUST be empty
grep -c '^add_test(NAME' tests/e2e/CMakeLists.txt                                  # count reconciles
tail -3 tests/e2e/CMakeLists.txt                                                   # sweep still LAST
```

It does NOT affect GROUP membership — a conflict here is a mechanical union, never a semantic
disagreement, so it must not split a group.

One merge-and-gate agent per GROUP: merge every branch of the group into one worktree, rebuild once,
run the full `ctest -j6` ONCE, run `cq-opt-equivalence-full` once iff any track moved a decline string
or an analysis site, and run ONE corpus sweep on the combined binary with movers attributed per track
BY STRING (each track's brief states its own expected strings; an unattributable mover is a FINDING).

⚠ A red group gate is exactly the interaction a per-track gate would have hidden. Do NOT fall back to
per-track gates to find it — bisect by reverting one branch's merge in the same worktree.

## S2 — the CLOSING full suite is CITED, not re-run, when the tree is identical

If (a) `git diff --stat <last gated branch tip> main -- ir-pass include runtime tests tools` is EMPTY
and (b) the rebuilt `cq-opt` sha256 equals the gated binary's, then the full suite and the equivalence
sweep are **CITED** from that gate's `GATES.md` lines, not re-run, and the closing record says so in
those words. If either check fails, run both — and the failure is itself a finding.

## S3 — instrument lessons that cost time in previous sessions

* Lowered-IR md5s are **NOT comparable ACROSS sweeps** (the temp `ModuleID` changes); compare within a row.
* The shared `corpus.sh` tag regex renders the whole `cq_measure_<sfx>` family as an empty `D:`, so a
  decline→decline string change inside it is **INVISIBLE** — close it with a full-stderr + exit
  byte-compare over the decline rows.
* A mutation harness that reports `n/a` is a **HOLE**, not a pass.
* A named negative check can be **VACUOUS** (it names a handle the module never defines) — run
  `python3 tools/negative_vacuity_check.py <fixtures…>` over every new accept-fixture batch. It FAILS (rc 2)
  when a non-empty batch yields zero directives (bd `jdec`, landed 2026-09-15; verified by Wave 0-A on
  `9bd01598`: 166 directives evaluated over a real 25-fixture batch). ⚠ The 2026-09-13 `trackM/probes/impl/
  vacuity.py` this line used to name is DEAD (hardcoded to a worktree that no longer exists) — do not run it.
* A bare `-NOT: <word>` can match the module's own path/header line (bd `qta2`).
* **A 0-byte `.ll` module ACCEPTS** through the passthrough early-out. Check your probe is non-empty
  before scoring it ACCEPT (bd memory `empty-module-accepts-vacuity-trap`).


## §6.1 — NO REDUNDANT TESTS ACROSS PARALLEL AGENTS (owner instruction 2026-09-17, binding)

The 2026-09-15 protocol says *cite, don't re-run* for a gate recorded at the same hash. This extends it to
**concurrency**: **no two agents run the same test at the same time, and no agent runs a test whose result
another agent is producing.** Mechanism, enforced at spawn and followed by every agent:

* **Every gate has exactly ONE owner per binary hash**, named in the brief. The gate matrix above is the
  default assignment: the implementer owns `lit --filter` and single slices on its own fixtures, plus ONE
  `ir-pass-lit` at hand-off; the reviewer owns nothing that spawns a suite; the group's merge-and-gate agent
  owns the full `ctest -j6`, the equivalence sweep, the twin matrices and the corpus sweep. **Two tracks in
  one group share ONE merge-and-gate agent, so the group's suite runs once.**
* **Announce before you run.** Before starting any gate longer than a single fixture (`ir-pass-lit`, any
  `ctest -R` over more than one entry, a corpus sweep, a matrix), append
  `IN-FLIGHT | <gate> | <hash16> | <who> | <HH:MM>` to `$SES/GATES_INFLIGHT.md` (ONE shared file in the
  MAIN checkout, append-only, one line per gate). When it finishes, append a `DONE | <gate> | <hash16> |
  <who> | <HH:MM> | <result>` line there AND the result line in your own `GATES.md`. An agent that finds a
  matching IN-FLIGHT line at its own hash **waits and cites**; it does not start a second run.
* **Same hash ⇒ same result.** A gate recorded in ANY track's `GATES.md` (this session's or `$THIS/GATES.md`)
  at the binary hash on your disk is cited, never re-run — including across groups.
* **Different hash ⇒ your own inner loop only.** A rebuild changes the hash and licenses only the gates the
  matrix assigns to your role; it never licenses a full suite.
* **The full `ctest -j6` runs at most ONCE per group landing, at most ONE at a time on the box, and at most
  once per binary hash, period.**
* **Report the redundancy check.** Every hand-off report states, for each gate it cites, whose line it
  cited, and for each gate it ran, that no IN-FLIGHT line existed for it at that hash when it started. A
  gate run twice at one hash is a protocol FINDING for `$SES/MERGE_FILINGS.md`, not a footnote.

Gates already recorded on the ORACLE `9bd01598` — cite, never re-run: `$THIS/GATES.md` (the socratic
session's per-probe lines: s1/s2/s3/w2k/n1-n3/b7*/b10/b11/w2h*/s4 and the owner's program + twin).
