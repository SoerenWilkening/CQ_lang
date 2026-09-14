# Session 2026-09-13 — the agent protocol every brief copies from (binding; owner addon)

Repo `/Users/sorenwilkening/Desktop/CQ_lang` (`main` 86c0d25, docs-only over the pass at e96f89c).
`LLVM=/usr/local/opt/llvm@19/bin` (NOT on PATH). Session dir (`$SES`):
`docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-13-orchestrator/`.

**ORACLE** (read-only, frozen for the whole session, rebuilt exactly once at the end by the orchestrator's
closing agent): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` sha256
`fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661`, `libCQPass.so`
`40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93`, built 2026-09-11 22:23 from e96f89c.
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
