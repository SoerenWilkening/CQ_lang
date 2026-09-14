# Merge-and-gate brief — TEMPLATE (one instance per landing; the orchestrator fills the <angle> fields)

Model: opus. Worktree `<WORKTREE>`, branch `<BRANCH>` (cleared: `<review verdicts>`), merging **`main` at
`<MAIN_HASH>`** (which carries `<previous landings this session>`). Protocol: `../PROTOCOL.md`, row
"merge-and-gate" — you are the ONLY agent that runs the full `ctest -j6` this landing, exactly ONCE, on the
MERGED tree; never more than one full suite in flight on this box (the orchestrator guarantees the other
tracks are not gating right now). Do not commit the squash (the orchestrator's); DO commit the MERGE itself
in the worktree if `git merge main` produces a merge commit (conflicts resolved by READING both sides —
every `ir-pass/src` conflict listed in the record with the resolution and the reason; never take one side
wholesale). Never write outside `<WORKTREE>`. Never relink under a running measurement; never `pkill` by
pattern. Report only what you ran.

## Steps, in order

1. `git -C <WORKTREE> status --porcelain` — record it. `git merge main` (resolve; list conflicts).
2. `cmake --build build -j8` (BOTH targets). `shasum -a 256 build/ir-pass/cq-opt` → `GATES.md` (hash-keyed;
   cite the implementer's/fix agent's lines for the PRE-merge binary, run nothing twice on one hash).
3. **The full `ctest --test-dir build -j6 --output-on-failure`** — ONCE. Exact pass line + wall time. A `-j`
   failure is re-run SERIALLY (`-R '^<name>$'`) before it is called a regression (contention causes false
   FAILURES, never false passes).
4. `cmake --build build --target cq-opt-equivalence-full` **iff** this landing changed a decline string or
   an analysis site (`<YES/NO — orchestrator fills>`).
5. Corpus sweep ORACLE-vs-MERGED over: `ir-pass/test/*.ll`, `$SES/probes`, every `$SES/track*/probes` (incl.
   `probes/impl`, `probes/r2`, review probes), and the 2026-09-11 dirs `../session-{9pum,b6ap,f2-i1,l4x4,
   boi6,r903,2026-09-11-orchestrator}/{probes,review_*_probes}` — recipe
   `../session-2026-09-11-orchestrator/review_integration_probes/corpus.sh`. EVERY mover explained before the
   squash: DECLINE→ACCEPT only on this landing's own strings (list each); 0 ACCEPT→DECLINE; 0 both-accept
   circuit changes; every accepting mover re-lowered through STRICT stage 2b.
6. Duplicate-body fixture scan (sha-256 over each fixture's non-comment lines) **iff** fixtures were
   `git mv`'d on either side (a merge can resurrect a renamed fixture — bd memory
   `merge-resurrects-git-mv-fixture`); list every same-body group and dispose of any merge artefact.
7. Customers on the MERGED binary: **C1** `$SES/probes/owner_file_2026-09-13.c` (expected: `<verdict/lines>`),
   `$SES/probes/va.c` (MUST be 19 lines byte-identical to `probes/va.trace`), **C2** `$SES/probes/vd.c`
   (expected: `<verdict>`), the C customer `trackC/probes/owner_2026-09-11_2218.c` (expected `<…>`).
8. `<LANDING-SPECIFIC ITEMS — orchestrator fills; e.g. install trackL/ready/ H-10 pins: copy the two .ll
   into ir-pass/test/, the two .c + .expected.log into tests/e2e/, append CMakeLists.lines.txt after
   e2e-phase-bool-loop-twin-identical, run `lit --filter carried_theta_first` and the three ctest entries and
   the injection matrix the ready/README.md names — BEFORE step 3 so the full run covers them>`.
9. Counts by command: `ls ir-pass/test/*.ll | wc -l`; `ls tests/e2e/*.expected.log | wc -l`;
   `ctest --test-dir build -N | tail -1`; `-N -R '^e2e-'`; `-N -R '^e2e-slice-'`; `-N -R twin-identical`;
   `grep -c '^add_test' tests/e2e/CMakeLists.txt`.
10. Record `MERGE_<TRACK>_<N>.md` in the track dir (style: `../session-l4x4/MERGE_l4x4_2.md` — §0 findings,
    §1 conflicts, §2 resurrections, §3 corpora, §4 customers, §5 gates verbatim, §6 counts, §7 what you did
    not do) + `GATES.md` lines. `git -C <WORKTREE> log --oneline -1` (the tip the squash message cites).

Final message ≤30 lines: the tip hash, conflicts (count + files), the full-ctest pass line + time,
equivalence (ran/cited/not owed), movers (count by string, 0 regressions stated), customers' verdicts and
line counts, counts, the record path.
