# Probes — session 2026-09-20

Scratch, recorded so a later session can re-run them rather than re-derive them.
Harnesses take an optional build-dir argument so the same probe runs on the
ORACLE and the SUBJECT: `run.sh <probe.c|.ll> [buildroot]`.

⚠ **`peelsweep.sh` AND `corpusab.sh` BOTH HAD TO BE FIXED BEFORE THEY TOLD THE
TRUTH, AND THE BUG WAS THE SAME ONE.** In a shell pipeline `rc=$?` captures the
LAST stage's status: `peelsweep.sh`'s first spelling did
`B=$(cq-opt … | grep -v '^CQ_ZUJR_PEEL:'; echo "rc=$?")`, so `rc` was **grep's**,
and `grep -v` returns 1 when it filters every line away. It reported **2065
movers of 2106**. Run `peelsweep.sh NOSUCHTAG` — a tag nothing uses — as a
boundary control on every invocation; it MUST report 0 movers.

⚠ **A 0-BYTE `.ll` ACCEPTS** through the pass's passthrough early-out, and a
0-LINE TRACE is the same trap one stage later. `h1d_guarded_iterlocal.c` scored
ACCEPT on both binaries with **0 trace lines** (uninitialised `bool t` — `-O1`
deleted the loop); `o1_rolled.c`/`o1_unr.c` scored "twin identical" at **0 bytes
each** (`_Bool a = 5` makes `a >= 3` tautologically false — clang even warns).
Neither is evidence of anything. `run.sh` checks the module is non-empty; the
TRACE check is on you.

## The families

| prefix | what it measures |
|---|---|
| `w1_ w8_ w16_ w32_ w64_` | the clean WIDTH AXIS — one program, five carried types, the condition NOT reading the carried variable so width is the only axis |
| `n0_ n1_ n2_ n3_` | the owner's cascade at `int` / `_Bool` / `short` / `long long`. ⚠ `n1_bool` declines on BOTH binaries at a DIFFERENT wall (`_Bool` as the region's own CONDITION, bd `r903`/`fg9k`/`boi6`) — not bd `11qv`'s |
| `o1_ o8_ o16_ o32_ o64_` (`_rolled`/`_unr`) | the owner's cascade rolled vs hand-unrolled at each width. The 50-vs-45 divergence is the DOCUMENTED one (CLAUDE.md §4e); trip 3 is identical gate for gate. ⚠ `o1` is VACUOUS — see above |
| `qq16 qq16b qq32 qq32b` | the Q+Q compare width hazard. All decline identically at both widths on both binaries, which is why bd `11qv`'s `HandleWidth` record is recorded as DEFENSIVE rather than as a fixed bug |
| `lit8` | isolates the bd `ix2v` narrow-literal ABI rendering — loop-free, no carried handle, **reproduces on the ORACLE** |
| `h1_ h1c_ h1d_ h1e_ h1f_ h1g_ h1h_` | bd `h1ip`. `h1`/`h1c` hit the rail-bank injectivity wall (a runtime trip count has no static index proof); `h1e` is the shape that works; `h1f` exercises ZERO / ONE / TWO trips on one binary; `h1g`/`h1h` are the owed rolled-vs-unrolled probes with a trailing non-diagonal gate |
