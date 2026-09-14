# Session 2026-09-14 — the agent protocol every brief copies from (binding; owner addon, STRENGTHENED)

Repo `/Users/sorenwilkening/Desktop/CQ_lang` (`main` 607b6fe4, docs-only over the pass at 59ac5b7).
`LLVM=/usr/local/opt/llvm@19/bin` (NOT on PATH). Session dir (`$SES`):
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-14-orchestrator/`.  Last session's dir (`$PREV`):
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/`.

**ORACLE** (read-only, frozen for the whole session, rebuilt exactly once at the end by the orchestrator's
closing agent): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` sha256
`f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc`, `libCQPass.so`
`f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d`, built from 59ac5b7.
`shasum -a 256` it before you use it; if it differs, STOP and report — someone rebuilt the oracle.

Per-probe pipeline (from a repo root; `BUILD` = the build dir of the binary you are measuring):

```
"$LLVM/clang" -Iinclude -include CQ.h -O1 -g -emit-llvm -S <probe>.c -o s1.ll
"$BUILD/ir-pass/cq-opt" -load-pass-plugin "$BUILD/ir-pass/libCQPass.so" -passes=cq-lowering -S s1.ll -o s2.ll; echo "opt exit=$?"
python3 tools/free_pairing_check.py s2.ll                                                        # accepts only (STRICT stage 2b)
"$LLVM/clang" s2.ll "$BUILD/runtime/libcq_templates.a" "$BUILD/runtime/libcq_runtime.a" -o a && ./a  # accepts only; link order load-bearing
CQ_CTRL_DBG=1 "$BUILD/ir-pass/cq-opt" ... 2>&1 | head                                            # to name the firing site/anchor of a decline
```

`cq-opt` and stock `opt -load-pass-plugin` are byte-equivalent (gated); use `cq-opt` (0.12 s vs 0.24 s).

## The non-redundancy protocol (owner: "each agent should only run tests relevant for them … avoid redundancy at each opportunity")

**A gate result is a fact about a BINARY, not about a moment.** Every track dir carries `GATES.md`; every line is

```
<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
```

Before running any gate, read `GATES.md`: if the binary hash is unchanged and the gate is recorded, do NOT
re-run it — cite the line. After running one, append the line. The implementer records the hash after every
rebuild. Report a cited gate as `cited: ir-pass-lit 1893/0 @ fbbe0820 (impl, 14:02)` and a run one as `ran: …`.
Never the bare "tests pass". A cited line whose hash does not match the binary on disk is a FINDING.

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
| twin matrices | no | no (Track L only, if it lands in-loop code) | no | no | via the full run only |
| duplicate-body fixture scan | no | no | no | no | after any merge that renames fixtures |

Corollaries: the implementer's inner loop is `lit --filter` + single slices — NOT `^e2e-`, NOT the full suite,
NOT the equivalence sweep. The reviewer runs NO build and NO suite (its one obligation is checking the
`GATES.md` hash against the binary on disk). The fix agent rebuilds (hash changes), re-runs only what the
finding names, `ir-pass-lit` once iff pass source changed, corpus once. The merge-and-gate agent is the ONLY
full-`ctest` runner during the session. Never more than ONE full-suite gate in flight on this box.

## Non-negotiables for every agent

* `model: opus`. Do not commit, do not push. Never write outside your worktree (records go in
  `$SES/track<X>/` INSIDE your worktree, or — for scoping agents — in the main checkout's `$SES/track<X>/`).
* Never write under `ir-pass/`, `include/`, `runtime/`, `tests/`, `tools/` of a checkout that is not yours.
* The primary `build/` is READ-ONLY. Never relink a binary under a running measurement; never `pkill` by
  pattern (bd memory `never-relink-or-pkill-under-measurement`).
* `cmake --build build --target CQPass` ALONE is a FALSE-GREEN trap — `cq-opt` is a separate target from the
  same sources. Always `cmake --build build -j8` or name BOTH.
* Report only what you ran (Rule 19). Measured numbers with the command shown. Over-declining an input is
  safe; over-accepting is the unforgivable bug; and — owner ruling 2026-09-11 — an over-decline of a valid
  circuit is a DEFECT to file (bd), not a safety margin.
* Corpus sweep recipe: `$SES/../session-2026-09-11-orchestrator/review_integration_probes/corpus.sh` (a row =
  exit code, diagnostic string, md5 of the lowered IR when accepting; both binaries on the same stage-1 file).
  Corpora: `ir-pass/test/*.ll` + every `$SES/track*/probes` + `$SES/probes` + the 2026-09-11 session dirs'
  `probes/` and `review_*_probes/` (`session-9pum`, `session-b6ap`, `session-f2-i1`, `session-l4x4`,
  `session-boi6`, `session-r903`, `session-2026-09-11-orchestrator`).

---

## STRENGTHENING for 2026-09-14 (owner: "test runs should be reduced to a minimal number")

Last session the matrix above produced **4 full-suite runs for 3 landings** and **0 cited-but-stale gate
lines**. Two measured facts make it cheaper still; both are now REQUIRED.

### S1 — ONE COMBINED GATE per DISJOINT-FILE GROUP

Two tracks are in the same GROUP iff they touch a common file under `ir-pass/`, `include/`, `runtime/` or
`tools/`. Fixtures, records and `tests/e2e/CMakeLists.txt` do NOT count (append-only at disjoint anchors;
merged cleanly three times last session).

> ⚠ **ERRATUM, MEASURED AT THE MERGE GATE OF 2026-09-14 — THE PARENTHESIS ABOVE IS WRONG ABOUT
> `tests/e2e/CMakeLists.txt`, AND IT IS KEPT ONLY SO THE CORRECTION HAS SOMETHING TO POINT AT.**
> The file is **NOT** "append-only at disjoint anchors". It has ONE anchor for new slices — the tail,
> immediately above the `get_property(_E2E_ALL_TESTS ...)` / `set_tests_properties(...)` block that the
> file itself requires to stay LAST ("it must stay the LAST statement in this file for that sweep to be
> complete"). Every track that adds a slice therefore appends at the SAME place. Measured: Tracks U, P
> and W all did, and the six-branch merge hit **two content conflicts** in this one file (at Track P,
> then again at Track W). "Merged cleanly three times last session" was true and is not evidence — last
> session had three landings of which fewer than two added slices at once.
>
> **What does NOT change:** the file still does not affect GROUP membership. A conflict here is a
> mechanical union, never a semantic disagreement, so it must not split a group.
>
> **What the next merge agent should do instead of being surprised:** expect a tail conflict per
> slice-adding branch beyond the first; resolve by UNION in merge order; and then run the check that
> makes the union safe — which this gate ran and which should be standard:
> ```
> grep -o 'add_test(NAME [A-Za-z0-9_-]*' tests/e2e/CMakeLists.txt | sort | uniq -d   # MUST be empty
> grep -c '^add_test(NAME' tests/e2e/CMakeLists.txt                                  # count reconciles
> tail -3 tests/e2e/CMakeLists.txt                                                   # sweep still LAST
> ```
> (2026-09-14 merge gate: **0 duplicate names, 434 registrations, sweep still last** — 432 after the two
> `round2-window` removals of that same gate.) **One merge-and-gate agent per GROUP, not per track**: merge every
branch of the group into one worktree, rebuild once, run the full `ctest -j6` ONCE, run
`cq-opt-equivalence-full` once iff any track in the group moved a decline string or an analysis site, and run
ONE corpus sweep on the combined binary with the movers attributed per track BY STRING (each track's brief
states its own expected strings; an unattributable mover is a FINDING). The orchestrator then squashes each
branch separately on `main`, in the group's order.

⚠ A red group gate is exactly the interaction a per-track gate would have hidden. Do NOT fall back to
per-track gates to find it — bisect by reverting one branch's merge in the same worktree.

### S2 — the CLOSING full suite is CITED, not re-run, when the tree is identical

MEASURED last session: the closing rebuild of the primary produced a binary **bit-identical** to the last
merge-and-gate's, so its full suite reproduced that result exactly. The closing agent rebuilds the primary
and compares. If (a) `git diff --stat <last gated branch tip> main -- ir-pass include runtime tests tools`
is EMPTY and (b) the rebuilt `cq-opt` sha256 equals the gated binary's, then the full suite and the
equivalence sweep are **CITED** from that gate's `GATES.md` lines, not re-run, and the closing record says so
in those words. If either check fails, run both — and the failure is itself a finding (something entered the
tree outside the gate).

### S3 — instrument lessons that cost time last session

* Lowered-IR md5s are **NOT comparable ACROSS sweeps** (the temp `ModuleID` changes); compare within a row.
* The shared `corpus.sh` tag regex renders the whole `cq_measure_<sfx>` family as an empty `D:`, so a
  decline→decline string change inside it is **INVISIBLE** — close it with a full-stderr + exit byte-compare
  over the decline rows.
* A mutation harness that reports `n/a` is a **HOLE**, not a pass.
* A named negative check can be **VACUOUS** (it names a handle the module never defines) — run
  `$PREV/trackM/probes/impl/vacuity.py` over every new accept-fixture batch.
* A bare `-NOT: <word>` can match the module's own path/header line (bd `qta2`).
* `cmake --build build --target CQPass` ALONE is a **FALSE-GREEN trap**; always `-j8` the whole tree or name
  BOTH `CQPass` and `cq-opt`.
