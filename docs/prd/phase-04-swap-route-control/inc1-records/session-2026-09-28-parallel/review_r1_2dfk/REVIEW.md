# Review r1 — bd `test_C_libtooling-2dfk` (test-suite speed: tiers, stage cache, dedupe)

- **Subject**: branch `worktree-agent-ae7eff02a1262b05e` HEAD `12c91627`, base `d21a59b0`
  (commits `4bc32b56`, `402a5643`, `3c8cc3f6`, `da6cc584`, `4d1fb919`, `12c91627`).
  No pass source changed. `cq-opt` built from the subject in my private tree:
  sha-256 `45c895c2f50757a63f583889` (= the TRACK's figure).
- **Oracle**: not used. This is a harness change, so the question is "does a warm cache
  change a verdict", and the reference for each verdict is the same tree run with
  `CQ_E2E_NO_CACHE=1` (or with the run cache moved aside), not the frozen compiler.
- **Where**: private worktree `scratchpad/rev_r1_2dfk` at `12c91627` with its own
  Release build (`-j4`), cache `rev_r1_2dfk/build/tests/e2e/{.s1cache,.runcache}`. The
  implementer's tree and main's `build/` were not touched. Every mutation was reverted
  (`git status` clean after each).
- **Time**: about 60 min. Load 5–15 (1-min) throughout.

## Verdict: **NOT-CLEAR**

There is one P1, and it is exactly the failure mode the brief named: a warm cache
turns a test that must fail into a pass. The input that does it is an edit to the
**harness's own stage commands**. Rule 19 item 3 sends exactly that kind of edit to the
full gate, and the full gate on a warm build dir then replays the old results. Every
other input I perturbed (source, lib TU, golden, both archives, wrapper, checker,
lowering, expectation files) was keyed or compared correctly. The rest of the change
(tiers, env pass, duplicate removal, concurrency, `CQ_E2E_NO_CACHE`) holds. The P1 fix
is small and local (see F-r1-1).

## What I ran, literally

- `cmake -S . -B build …Release` + `cmake --build build -j4` in the private tree;
  `ctest -N` / `-L heavy` / `-LE heavy`; `ctest --show-only=json-v1` → env audit.
- `ctest -R '^e2e-slice-' -j4` cold (462/462, 237 s) to warm the caches, then the warm
  and no-cache runs listed per finding.
- `probes/dupcheck.py` (the 6 removed fixtures, from git, independently of the
  implementer's scanner).
- `probes/meta_mut_r1.sh` (6 key-component mutants + a null control against
  `e2e-stage-cache-selftest`).
- `probes/repro_F1.sh` (F-r1-1, end to end); `probes/kill_torn.sh` (40 random SIGKILLs);
  a 12-way concurrent cold run; the `\r` ModuleID pair (`probes/cr_a.ll`, `cr_b.ll`).
- **NOT run**: `e2e-loop-twin-matrix` (a cold run is 400+ s. Its diff touches only
  `build_side` and the `--dump-sides` aid, and the comparison code is unchanged, which I
  checked by reading); `taintset-scrub-guard*`; the full `ctest -j6`; `lit` beyond what
  ctest ran; `cq-opt-equivalence*`. I did not re-run the implementer's verdict-neutrality
  sweeps.

## Findings

### F-r1-1 — **P1, INTRODUCED** (one half PRE-EXISTING): the harness's own stage commands are in no cache key, so a warm cache masks a harness edit that must fail

**Soundness argument, restated.** "Every cached stage is a pure function of the bytes in
its key" (`cq_stage_cache.py` docstring). The key has three parts: the toolchain (clang
bytes and version, `include/` headers, wrapper, `ld -v`, `sw_vers`), the input (source
bytes, or the lowered module), and the archives. **The asserted, unmeasured step:** the
key assumes the **command applied to those inputs** is fixed. It is not. The command is
written out literally in `run_slice.sh`, `run_slice_multi.sh`, `stage_cache.sh` and
`cq_stage_cache.py`, and none of those files is hashed into any key:

| stage | where the command lives | how much of it is keyed |
|---|---|---|
| S1, `run_slice.sh` CQ TU | `run_slice.sh:53,62` | only through the **duplicate** flag spelling CMake passes to `s1_cache_key.py`. An edit to the script alone is not keyed (**PRE-EXISTING**, bd dgn5) |
| S1, `run_slice_multi.sh` CQ TU | `run_slice_multi.sh:67` | same key as `run_slice.sh`, so a third spelling that must stay identical (**INTRODUCED**: multi was uncached before) |
| S1, `run_slice_multi.sh` **lib TUs** | `run_slice_multi.sh:78` | a constant **tag** (`lib-no-CQ.h`). The flags are not keyed at all (**INTRODUCED**) |
| S3, bash | `stage_cache.sh:95-96` (`clang -c`, `$CQ_LD …`) | not keyed (**INTRODUCED**) |
| S3, python | `cq_stage_cache.py:248-253` | not keyed; only a hand-bumped `RUN_VERSION` (**INTRODUCED**) |

The TRACK's stage-1 row ("CQ_S1_BASE + **flags** + source PATH + source bytes") is true
for the python spelling and false for both bash runners.

**Measured** (warm cache, then the same edit with the cache off; full logs in
`probes/repro_F1.out`):

- **(a) The C18 tripwire.** Each classical lib TU carries
  `#ifdef cq_theta / #error "C18 violation: CQ.h was -include'd into a classical lib TU"`,
  and its header says it "fails LOUDLY at compile if the harness ever force-includes
  CQ.h into a lib TU". I added `-include CQ.h` to `run_slice_multi.sh`'s lib line.
  Over the 66 multi-TU entries: **`CQ_E2E_NO_CACHE=1` → 33 FAIL; warm → 64 pass**. The 2
  warm reds are 2 entries my warm-up had not populated, which failed correctly. So **31
  tests that must fail passed warm**. `repro_F1.sh`, 5-entry subset: WARM 5/5 pass,
  NO_CACHE 0/5.
- **(b) The bd szpr pin**, "deliberately NO -O flag … Do not add -O here". I added `-O2`
  to stage 3's `clang -c` in `stage_cache.sh`. Across all 462 `e2e-slice-*` entries:
  **warm → 462/462 pass (28 s); run cache moved aside → 5 FAIL**
  (`libm-real-coshl`, `libm-real-atan2l`, `spec-qram-read`,
  `spec-qram-read-under-control`, `spec-qrom-read-arm-escape`). This is the exact
  regression the pin exists to catch, and it is invisible on a warm cache.
- **(c)** Lib-TU flags changed to `-O0`: NO_CACHE → `specialize-2file` and
  `spec-scrub-dangling-key` FAIL (`cq specialization: callee contains a
  non-reversibilizable construct`); warm → 3/3 pass.
- **(d) PRE-EXISTING twin.** `run_slice.sh`'s own stage-1 flags changed to `-O0`:
  NO_CACHE → 2/2 FAIL; warm → 2/2 pass. This half predates 2dfk (dgn5). The 2dfk change
  copies the same shape into two more runners and into stage 3.

**Why P1 and not "a declared limit".** The TRACK declares that a hit does not re-witness
**the machine** (that this toolchain still links and runs on this box). It does not
declare, and its docstring denies, that a hit fails to witness **the harness**. Rule 19
item 3 exists because "a harness edit changes how every test runs, so no subset can
witness it", and its remedy is the full gate. On a warm build dir the full gate now
replays the pre-edit results for exactly these edits. `CQ_E2E_NO_CACHE=1` is the manual
escape, but nothing requires it and nothing would prompt anyone to use it.

**Related unpinned coupling.** Bash and python share one run-key namespace (selftest row
I asserts that the key TEXT is identical). Nothing asserts that the two spellings run
identical stage-3 COMMANDS. They do today (checked by reading). If one diverges, one
harness replays the other's traces.

**Fix direction (small).** Fold the runner scripts into the keys. Either hash
`run_slice*.sh` + `stage_cache.sh` + `cq_stage_cache.py` at test time (a few KB each,
one more `openssl dgst`), or hash them at configure time with `CONFIGURE_DEPENDS`, the
way the headers already are (same declared residual: ctest without a build). Put the
literal lib-TU flag string in the lib key instead of a tag. Add a selftest row that runs
a **perturbed copy** of the runner (stage-3 `-O2`, or lib `-include CQ.h`) against A's
warm cache and requires a miss and a red. Filed: **bd `test_C_libtooling-ffm0`** (P1,
discovered-from 2dfk). Repro: `bash probes/repro_F1.sh <private worktree>`.

### F-r1-2 — **P2, INTRODUCED** (instrument): `e2e-stage-cache-selftest` pins only two of the key's components

The implementer's meta-mutation M1–M5 is honest: 5 of 5 caught. But it deleted the
components the rows already perturb: the module (D/E) and the runtime archive (F). I
deleted each other component, **from both spellings where both exist**, so that
key-parity row I cannot catch it by construction (`probes/meta_mut_r1.sh`, each mutant
checked as planted):

| mutant | selftest |
|---|---|
| null | rc 0 |
| run key ignores **templates archive** | rc 0, **MISSED** |
| run key ignores **ld wrapper** | rc 0, **MISSED** |
| run key ignores **CQ_RUN_BASE** (toolchain) | rc 0, **MISSED** |
| 2b key ignores **checker bytes** | rc 0, **MISSED** |
| 2b key ignores **checker flags** | rc 0, **MISSED** |
| `run_slice.sh` S1 key ignores **source bytes** | rc 0, **MISSED** |

Output: `probes/meta_mut_r1.out`. Today's behaviour is correct. I perturbed each input
for real and it went red on a warm cache (see "Tested and not broken"). The gap is that
the next edit to drop one of these components would pass the selftest. Rows to add: F
for the templates archive; a wrapper-byte row; a checker-byte row and a checker-flag row
for 2b; a source-byte row for S1. Appended to bd `ffm0`.

### F-r1-3 — **P3, INTRODUCED, theoretical**: the ModuleID normalisation is not exact if line 1 contains a CR

`lowered_digest` and its bash twin drop everything up to the first `\n` whenever the
file starts with `; ModuleID = `. LLVM's lexer ends a `;` comment at `\r` as well as
`\n`, so text after a CR on line 1 is parsed as IR. `probes/cr_a.ll` and `cr_b.ll` have
the **same digest** (`96734bbd…`) and exit **0** and **7**. The only way to reach it is
a CR in `opt`'s input path (the `mktemp -d` or build dir), since `opt` prints the input
path into that line (it omits the line only for `\n`). So this is not reachable in
practice. The TRACK's "argued exact" should say "exact unless the input path contains a
CR", or the drop should refuse a line containing `\r`.

### F-r1-4 — **P3, PRE-EXISTING** (inherited by the new S1 callers; L7 in `s1_cache_key.py`)

- The S1 key does not cover the environment that steers clang (`SDKROOT`, `CPATH`,
  `C_INCLUDE_PATH`, `MACOSX_DEPLOYMENT_TARGET`, `DEVELOPER_DIR`), nor the macOS SDK
  headers. `s1_cache_key.py`'s docstring says SDK headers "cannot move without the clang
  bytes or version changing". That is **false on this box**: the SDK comes from the
  Command Line Tools, independently of Homebrew clang (the derived wrapper names
  `MacOSX26.sdk` / `26.4`). The run key inherits the wrapper at configure time. The S1
  key never sees the SDK.
- Headers included **relative to a source** (`#include "x.h"` outside `include/`) are
  not keyed. Measured: **0** such includes in `tests/e2e/*.c` and
  `tools/railbank_twin_pairs/*.c` today (all `#include "CQ.h"`, and 4 hits are
  comments), so this is latent.
- The whole toolchain half is configure-time only. A `brew upgrade llvm@19` or a CLT
  update with no reconfigure is served stale. The TRACK declares this ("what a hit does
  not re-witness"); I list it only because it now also covers stage 3/4.

### F-r1-5 — **P3, INTRODUCED, hygiene**

- The python run key hashes neither the path nor the bytes of the `clang` used for
  `clang -c`. It relies on `CQ_RUN_BASE` describing the configured clang.
  `railbank_register_twin_gate.py` uses `$CQ_LLVM_BIN/clang`, which can differ.
- `run_manifest` joins argv with `\n`, so `["a\narg:b"]` and `["a","b"]` produce the same
  key text. No argv contains a newline today.
- There is no eviction, so the cache grows without bound. A SIGKILL between `cp` and `mv`
  leaves a `<key>.<pid>.tmp` behind: 1 in 40 kills, never read.
- The merged prose in `control_swap_diamond.ll` describes a
  `cqrt_rz_i32_controlled` stream that no longer exists. It is correctly labelled as
  VERBATIM history, so no action is needed beyond noting it.

## Tested and not broken (coverage, not silence)

**Keyed inputs, each changed for real on a WARM cache → RED, reverted → green:**
- C source (`slice_theta_add_measure.c`, `x+1`→`x+2`): red.
- **Lib TU source** (`specialize_lib.c`, `a+3`→`a+4`): red.
- Golden (+1 line): red.
- **`runtime/cq_runtime.c`** trace format, target rebuilt: red.
- **`runtime/cq_templates.c`** `add_i32_hl` format, target rebuilt: red on the three
  `4jok` slices that call it. (`theta-add-measure` stayed green correctly: it emits
  `cqrt_addc_i32`, not that template. This is not a stale hit.)
- **`cq_link.sh`** without `-lSystem`: red, and green again once restored.
- **`free_pairing_check.py`** mutated to report a violation on every module: red on
  bash single- and multi-TU runners.
- Railbank matrix **expectation sidecar** perturbed (`deadcell` twin 1/16 drop list):
  red, `expected to drop exactly 1 identity line`.

**Replay semantics:**
- Bash records only exit-0 traces. A non-zero exit or a signal re-runs, and the status
  is re-raised after the diff. Read in `stage_cache.sh:103-112`.
- On a hit, `diff` runs under `set -e` (row C, plus my golden perturbation).
- Python `.nz` is recorded only for `returncode > 0`. Warm railbank runs replayed 6 `.nz`
  entries (deadcell's `slice(argc)` twins) with byte-identical summaries and 0 new
  entries.

**Concurrency:**
- 12 concurrent cold runs of one slice into one private cache: 12/12 rc 0, exactly one
  `.out` + one `.ok`, `.out` == golden.
- 40 random SIGKILLs of a cold run: **0 torn entries**, 5 complete ones, 1 `.tmp`
  leftover, and every following warm run passed.
- The cache is per build dir, so two worktrees never share it. Within one build dir the
  keys are content, so sharing across branches is sound (modulo F-r1-1's command half).

**`CQ_E2E_NO_CACHE=1`:**
- Bash: selftest G, plus F-r1-1's no-cache legs, where clang/link visibly ran and the
  verdicts changed.
- Python: 3 railbank matrices with the flag → **0** entries added (`.s1cache/file` 0→0,
  `.runcache/run` 481→481), rc 0.

**Env pass:**
- `ctest --show-only=json-v1`: **552/552** e2e entries carry all six `CQ_*` variables
  exactly once.
- The only non-`CQ_*` variable anywhere is `e2e-spec-scrub-dangling-key`'s
  `CQ_OPT_DEBUG_ALLOC=lifo`. `ctest -V` shows it reaching the test, and the test passes.
- No entry lost a variable. The per-entry `set_tests_properties` sites are 1699, 7327,
  7341 and 7371, and each is supplemented, not clobbered.

**Tiers:**
- `ctest -N` **571** = `-L heavy` **10** + `-LE heavy` **561**.
- The ten are exactly the intended entries. The only label in the tree is `heavy`.
- `add_test` diff base→subject: +1 (`e2e-stage-cache-selftest`), −0.
- A planted `^no-such-test$` pattern gives the configure WARNING, and reverting it
  restores 10.

**Duplicate removal** (`probes/dupcheck.py` → `dupcheck.out`):
- **6/6 pairs are exact**: module identical, and directive lines identical over RUN +
  every prefix named on a RUN line (`control_swap_diamond_derived` carries 33 directives
  across ACNT/FCNT/MDCNT/NOROUTE).
- Each kept file's module and directives are byte-identical base→subject.
- Every non-directive prose line of each removed file appears verbatim in its kept file
  (0 missing).
- No live reference in `ir-pass/ tests/ tools/ cmake/ runtime/ include/ CLAUDE.md
  ROADMAP.md` names a removed file outside the MERGED blocks. `ArmClassify.cpp:542`'s
  `..._stale_diag_alias_backward.ll` still resolves to
  `control_angle_select_reject_stale_diag_alias_backward.ll`.

**Selftest:**
- Null control green.
- The implementer's M1–M5 claim is consistent with my mutants: rows D/E/F really do see
  a module or runtime change, see F-r1-2.

## Composition

Other changes landing this session touch the lowering or the scrub guard, not the
harness. The one composition that matters is **any landing that edits a runner script**
while the cache is warm (F-r1-1). One example: a future track that "fixes" a stage-1
flag in `run_slice_multi.sh` and runs the batch gate on a warm `build/`. The gate would
pass on the old stage-1 IR.
