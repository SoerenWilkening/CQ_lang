# REVIEW r2 — bd `test_C_libtooling-2dfk` round 2 (bd `ffm0` fix): the test-harness stage cache

- **Subject**: `worktree-agent-ae7eff02a1262b05e` @ `62205665` (round-2 commits `bbce5793`,
  `7acf3583`, `62205665` on round 1 `12c91627`); diff `12c91627..62205665`.
- **Binaries used (implementer's build, READ-ONLY, no rebuild)**: `cq-opt`
  `45c895c2f50757a63f583889`, `libCQPass.so` `2d6493e852831ed8b1226629`,
  `libcq_runtime.a` `ebdaf5aa23df53e78ce892df`, `libcq_templates.a` `5424019da1e583b0a8924ebe`,
  `cq_link.sh` `f807be910de33b76b4686bf7`. No compiler code changed, so the frozen oracle is
  not relevant here and was not run.
- **How I ran it**: a private worktree `scratchpad/rev_r2_2dfk` @ `62205665` (removed at the
  end), NO private build. `probes/drv.py` replays the implementer's registered ctest
  commands + ENVIRONMENT (`ctest --show-only=json-v1` from their build), with the harness,
  tool, include and test-source paths redirected to my worktree and both caches redirected
  to a PRIVATE dir. Every edit was planted only in my worktree. Pool of 4.
- **Time**: ~35 min. Load 12–60 (1-min average) at the start, ~12 during the runs.
- **What I ran**: the probes listed below, plus `e2e-stage-cache-selftest` twice (ambient env
  and ambient `CQ_E2E_NO_CACHE=1`). **Not run**: lit, the full or fast tier, the loop twin
  matrix, the implementer's `meta_mut_r2.py` (I read its 36 definitions and its output
  instead).

## Verdict: `CLEAR-WITH-ITEMS`

The P1 is fixed. With a warm cache, r1's repro goes red for exactly the edits that go red
uncached. No harness-file edit I could find is masked. I found **no remaining stale PASS for a
change that also fails at the gate** (the gate is `cmake --build && ctest`). One stale PASS
remains in the **targeted inner loop** that Rule 19 prescribes for `include/CQ.h`
(F-r2-1, P2, bead filed). The other items are P3.

## 1. The fix, restated and checked

Round 2 adds the command to every key. Each stage-1, 2b and run key now carries four things:
- the harness digest HD, over the bytes of the four files where every cached command is
  written;
- the literal flag arrays the commands run with (`S1_FLAGS`, `CQ_FLAGS`, `LIB_FLAGS`,
  `CQ_S3_CC_FLAGS` / `S3_CC_FLAGS`);
- the bytes of the clang binary;
- ENVD, a digest over a listed set of environment variables.

I read `stage_cache.sh`, `cq_stage_cache.py`, both runners and the three python callers. The
flag arrays the commands execute are the same arrays that get keyed (one spelling each). The
lib-TU tag is gone. HD is computed at test time from `$HERE` (bash) and from `__file__`
(python). One claim is asserted rather than measured: "the four files are every file a
cached command is written in". I tested that claim in §2a.

**Check 1: r1's repro, re-run in my worktree** (`probes/repro_r2.sh` → `repro_r2.out`).
A null control ran first: a cold run of the 12 entries, then a warm run that wrote **0 new
cache files** and took 19 s → 4 s, so the warm run really hit.

| edit (planted, checked PLANTED) | WARM | `CQ_E2E_NO_CACHE=1` |
|---|---|---|
| (a) lib TUs get `-include CQ.h` (C18 tripwire), 5 multi-TU entries | **0/5** | 0/5 |
| (b) `CQ_S3_CC_FLAGS=(-O2 -c)` (bd szpr pin), 5 entries | **0/5** | 0/5 |
| restored, warm | 12/12 | — |

Round 1 measured 5/5 PASS warm for both (a) and (b). **Fixed.**

## 2. Findings

### F-r2-1 (P2) — an `include/CQ.h` edit made without a reconfigure is replayed warm as the old pass. PRE-EXISTING for `run_slice.sh`; INTRODUCED for the new stage-1 callers

bd **`test_C_libtooling-dbjh`** (filed by this review).

The headers under `include/` enter the stage-1 key only through `CQ_S1_BASE`, which CMake
computes at configure time. A header edit therefore does not move the key until the next
configure. The uncached stage 1 reads the edited header from disk; the warm stage 1 replays
the old IR.

`probes/cqh_r2.sh` → `cqh_r2.out`. The plant is semantic: `cq_theta`'s dispatch becomes
`)(x, (angle) * 2.0)`, so the header still compiles and every angle doubles. `CQ_S1_BASE` is
left as the last configure computed it. The entries are the r1 multi-TU set, two
`run_slice.sh` slices and `e2e-railbank-dynamic-admission-matrix` (python `stage1_file`).

| | WARM | `CQ_E2E_NO_CACHE=1` |
|---|---|---|
| CQ.h angles doubled, no reconfigure | **8/8 PASS** | 1/8 |

A `#error` plant gives the same split (`gaps_r2.out` (C): warm 7/7, no-cache 0/7).

- **Why P2 and not P1.**
  - The merge gate is protected. Any `cmake --build` re-checks the build system, and the
    build's `CMakeFiles/Makefile.cmake` lists `include/CQ.h` (the bd `fmt3`
    CONFIGURE_DEPENDS glob). So a build → reconfigure → new `CQ_S1_BASE` → cold stage 1.
  - `frontend-lit` is uncached and catches this particular plant:
    `cq_theta_nomerge.c` and `cq_ry_macro.c` fail when I run them by hand against the
    planted header.
  - It still meets the letter of "a stale PASS for a change that fails uncached". Rule 19's
    own table prescribes exactly this inner loop for `include/CQ.h`: `ctest -R frontend-lit`
    plus e2e, with no build step. Any CQ.h edit that `frontend-lit` does not pin is
    invisible to the whole e2e layer until someone builds.
- **Population.**
  - PRE-EXISTING for the 424 `run_slice.sh` entries (bd `dgn5`'s stage-1 cache; `fmt3`
    declared the residual).
  - INTRODUCED for the 42 `run_slice_multi.sh` entries. At `3c8cc3f6~1` they ran
    `"$CLANG" … "$CQSRC"` uncached every time, so they were the e2e layer's only witness of
    such an edit, and 2dfk removed that witness.
  - Also introduced for the python stage-1 callers (loop twin matrix, railbank matrices,
    register twin gate).
- **L7.** `tests/e2e/CMakeLists.txt` justifies the residual as *"the same contract as running
  ctest on an un-rebuilt plugin"*. That is **false**. An un-rebuilt plugin is equally stale
  cached and uncached. An edited header is read by every uncached stage 1, so only the cache
  masks it. `cq_stage_cache.py`'s docstring also files "the headers under include/" under
  *"the MACHINE"*, but CQ.h is project source, not machine state.
- **Remedy (cheap).** Hash the files under `$INC` at test time into the S1 key, in both
  spellings. `include/` holds a single 255-line file, so this costs one more `openssl dgst`
  per stage-1 call. Add a selftest row: edit the header, keep `CQ_S1_BASE` fixed, require a
  MISS and a RED. The alternative is to amend Rule 19's CQ.h row to require a build first,
  but the hash is simpler and total.

### F-r2-2 (P3) — ENVD's allowlist misses a clang-steering variable; measured stale PASS

This is the implementer's own ATTACK-FIRST #3, now measured (`probes/env_r2.sh` →
`env_r2.out`). Homebrew clang 19 reads `/usr/local/etc/clang/x86_64-apple-darwin25.cfg` on
every call, and that file is where `-isysroot <CLT SDK>` comes from.
`CLANG_NO_DEFAULT_CONFIG=1` (not in `KEY_ENV_VARS`) disables it.

| `CLANG_NO_DEFAULT_CONFIG=1` | WARM | `CQ_E2E_NO_CACHE=1` |
|---|---|---|
| `e2e-slice-control-abort` (`#include <stdlib.h>`), `e2e-railbank-dynamic-admission-matrix` | **2/2 PASS** | 0/2 (`'stdlib.h' file not found`) |

It is P3 because nobody sets that variable, it is a declared policy, and the effect reaches
the gate only if the gate's environment sets it. The same mechanism covers the `.cfg` file's
own bytes, which are never keyed per run. `-###` at configure time captures only their
effect.

- **Remedy, either of:**
  - key `clang -### <flags>` once per runner process (it records every driver decision that
    config files, `CPATH`, `SDKROOT` and so on make; it costs one driver spawn);
  - invert ENVD to a denylist (hash the whole environment minus known-volatile names). That
    gives more misses and never a stale hit.

### F-r2-3 (P3) — the stage-3/4 toolchain half is new, configure-time, and a build does NOT refresh it

This answers the brief's question (c). It is declared in both files' headers. Here is how it
splits against the pre-2dfk tree:
- **Stage 1, `run_slice.sh`:** configure-time staleness is PRE-EXISTING (`dgn5`). Before
  `ffm0` the key did not even hash the sysroot. It is now strictly better: the clang driver's
  bytes are hashed per run, and the SDK's `SDKSettings.json` at configure time.
- **Stage 1, `run_slice_multi.sh` and the python callers:** NEW; they were uncached before.
- **Stages 2b/3/4:** NEW; nothing was cached before. `ld -v`, `sw_vers`, the SDK and
  `libclang_rt.osx.a` are all configure-time only.

A `brew upgrade llvm@19` IS picked up by the next build: `Makefile.cmake` lists
`/usr/local/opt/llvm@19/lib/cmake/llvm/LLVMConfig.cmake`. **A Command Line Tools update, an
`xcode-select -s`, or a macOS update is NOT**: nothing in `Makefile.cmake` names them. So the
gate would replay stage 3/4 against the old `ld` / libSystem until someone reconfigures or
sets `CQ_E2E_NO_CACHE=1`. It is P3 because it is a machine event rather than a code change,
and it is declared.

- **Recommended:** the gate procedure should say "after a CLT/OS update: reconfigure or
  `CQ_E2E_NO_CACHE=1`". Alternatively, hash the resolved `ld` binary and the SDK's
  `SDKSettings.json` per runner process.

### F-r2-4 (P3) — `-include CQ.h` resolves from the working directory first, and the CWD is not keyed

`clang -I<inc> -include CQ.h` in a directory that holds a `CQ.h` uses **`./CQ.h`**. Measured:
`#error CWD-CQ.h-WAS-USED` fired with `-I…/include` present. The e2e CWD is
`build/tests/e2e`, which has no `CQ.h` today, so this is contrived. Still, a stray file there
would be used uncached and masked warm.

**Remedy**: `-include "$INC/CQ.h"` (absolute) in the literal flag arrays of both spellings.
That also removes the CWD dependency from the harness itself.

### F-r2-5 (P3) — the 2b key names the interpreter by PATH, not bytes

`$PY` is a pyenv path that embeds the version (`…/3.11.9/bin/python3`), so a version change
is a miss. An in-place interpreter change at the same path is not. Negligible; recorded for
completeness.

## 3. Brief checks, answered

1. **r1 repro**: C18 tripwire and stage-3 `-O2` are red warm. §1.
2. **(a) Other files a runner sources or execs.** I enumerated them:
   - `free_pairing_check.py` is keyed by bytes in the 2b key, and imports only the stdlib.
     Measured (`gaps_r2.out` (A)): a checker edit that rejects everything gives WARM 0/7 =
     NO_CACHE 0/7.
   - `cq_link.sh` is keyed by bytes (per test) and in `CQ_RUN_BASE`.
   - `derive_link_line.py` and `s1_cache_key.py` run only at configure time. They change no
     stage result until a reconfigure, and their outputs are keyed.
   - `llvm-link`, `cq-opt`, the `--forbid-qram` greps and the diff are never cached.
   - Test sources: the only `#include "…"` is `"CQ.h"` (the other matches are comments), so
     r1's "0 relative includes" holds.
   - Every one of the 466 runner entries passes the same INC (`<tree>/include`).
   - The python callers use a stage-1 hit read-only (`check_case` only `read_text()`s it;
     `rmtree` removes `work`, never the cache). Their argv, flags, clang and archives are
     explicit arguments, and the keys include them.

   **No unkeyed harness file found.** The gaps are header content (F-r2-1), the CWD
   (F-r2-4), env/config (F-r2-2) and the machine (F-r2-3).
   **(b)** Env steering `cq-opt` is fine (never cached); for the cached stages see F-r2-2.
   **(c)** See F-r2-3.
3. **Goldens are never cached.** `gaps_r2.out` (B): a golden edit with a warm cache fails
   (WARM 0/1 = NO_CACHE 0/1). The hit path is `diff -u - "$2" < <cached trace>` under
   `set -e`. §(D) is the converse: a CORRUPTED cached trace makes the warm run red and the
   no-cache run green. So the cache is trusted data with no integrity check, and it cannot
   turn a wrong trace green.
4. **`CQ_E2E_NO_CACHE=1`**:
   - Stage 1: F-r2-1's table (no-cache sees the header, warm does not).
   - Run cache: (D) (no-cache ignores a corrupted entry).
   - Writes: `nocache_writes_r2.out`, 8 entries in bash and python run against an EMPTY
     cache dir: **0 files written**, against 55 with the cache on.
   - Selftest explicit-env fix: `e2e-stage-cache-selftest` **passes with and without an
     ambient `CQ_E2E_NO_CACHE=1`** (54 s / 61 s).

## 4. What I tested and did not break

- Every harness-file edit class r1 named.
- A checker-source edit.
- A golden edit.
- A corrupted cache entry (warm red, no-cache green).
- NO_CACHE reads nothing and writes nothing.
- The python caller-side transforms (ATTACK #2): none found. The comparison, filters and
  drops all run after the cached call on explicit arguments.
- The meta-mutation set, by reading. `s1_flags_b` removes both the count and the flag
  records, and `run_s3` removes both the array and its count, so the flag components are
  really deleted.

**Instrument note (L10, on my own probe).** `gaps_r2.sh` (D) matched **two** cache entries
whose trace equals the golden, but restored only the last one. Its (E) row and final
"restored" row (6/7) are therefore **invalid**, an artefact of the leftover corruption. I
repaired the entry: 12/12 green warm afterwards. (E) was then re-measured properly as
`env_r2.sh`. The (E) no-cache 7/7 in `gaps_r2.out` is real: CQ.h includes only
`<stdbool.h>`/`<stdint.h>`, which resolve from clang's resource dir with no sysroot. That is
why `env_r2.sh` uses slices that include `<stdlib.h>`.

## Probes (all in `probes/`)

`drv.py` (driver), `env.sh`, `plant.py`, `repro_r2.sh/.out`, `gaps_r2.sh/.out` (A–E; E and
the final row are superseded, see above), `cqh_r2.sh/.out` (F-r2-1),
`env_r2.sh/.out` (F-r2-2), `nocache_writes_r2.sh/.out`.

Reproduce with `bash probes/<name>.sh`. This needs the implementer's build (for its ctest
json and binaries), and needs `drv.py`'s `MY` pointed at a checkout of `62205665`.
