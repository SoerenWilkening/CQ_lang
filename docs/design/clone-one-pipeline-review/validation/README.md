# Scoped validation record

The branch green selected the 39 live `.ll` paths from
`git diff --name-only main.. -- ir-pass/test` at the original main base `1db881bd`.
Two deleted predecessors are listed for provenance and were not selected. The
first anchored filter matched zero tests; the corrected filter matches the
suite-prefixed lit names. `green-lit.log` is the resulting 39/39 run.

`green-ctest-names.json` records the exact 51 distinct names: 12 regenerated
e2e goldens plus 48 multi-TU slices, with nine overlaps. `green-ctest.log` records
51/51. Both green runs used `-j6`; no passing selection was rerun during review.

Mutation commands ran `lit ir-pass/test --filter <killing-fixture>.ll$ -j1 -v`
from build, after each mutated binary was built. The no-op passed; each of the
three real mutants failed its killing fixture. `mutation-results.json` and the
four fixture logs record MISSED 0/3. Mutated sources were restored byte-for-byte
and all four targets rebuilt before review.

Continuation test invocations: one actual green lit, one scoped green ctest,
one zero-test selection error, one no-op lit and three real-mutant lit runs.
The earlier red/config attempts and separate 3c6m.73 mutation counts remain in
the bd issue's historical notes. Later batch verification is recorded in lab 048.

The full census at main `92e9f0ec` (a local merge commit that `git pull --rebase` flattened; it is in no branch. Its tree equals 874b822b, review 2026-10-08) accepted 362/483 probes, completing 86/180
scalar cells. It saved accepted IR with `--evidence-dir /tmp/p3kd78-census-evidence`.
The ten new acceptances and remaining first diagnostics are in `census-audit.json`.
`census-audit.py` reads saved IR; it never invokes lowering. It attributes clone
parameters using the original signatures from `build/libm/cq_libm.bc`, disassembled
to `/tmp/p3kd78-libm-bundle.ll`. The baseline JSON is `1db881bd`'s census, saved
to `/tmp/p3kd78-census-before.json`.

The audit covers 247 clone bodies/twins across 73 accepted FP-bearing probes,
265 borrowed FP parameters and 318 direct copies from those parameters. It found
zero wrong copy widths and zero parameter frees among 29,943 clone frees.
All 362 accepted probes also passed the census's structural free checker. These
checks cover the recorded width/free defects; they do not establish numerical
semantics for every accepted library function.
