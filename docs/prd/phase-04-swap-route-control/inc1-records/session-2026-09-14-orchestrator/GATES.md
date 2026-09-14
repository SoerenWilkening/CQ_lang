# Session-level GATES.md — 2026-09-14

Format (PROTOCOL.md): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
A gate result is a fact about a BINARY, not about a moment. A cited line whose hash does not match the binary
on disk is a FINDING.

ORACLE (frozen, main checkout `build/`, from `59ac5b7`):
`cq-opt` f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc ·
`libCQPass.so` f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d

Carried from `$PREV/CLOSING_MEASUREMENTS.md` at `59ac5b7` (cite, do not re-run):

```
full ctest -j6           | f7b65d8ccd7bc472 | 420/420, 393.20 s                    | 2026-09-13 close | 2026-09-13
cq-opt-equivalence-full  | f7b65d8ccd7bc472 | 1928/0                               | 2026-09-13 close | 2026-09-13
counts                   | f7b65d8ccd7bc472 | lit 1928 · goldens 367 · ctest 420 (^e2e- 410, ^e2e-slice- 365, twin-identical 34) · twin cells 259+29=288 | 2026-09-13 close | 2026-09-13
```

## This session

### Track U (bd `z9t1`) — branch `undef-seed-zero`, tip `8865f7d5`, subject `cq-opt` `a5773be142835fb8`

```
ir-pass-lit              | a5773be142835fb8 | 100% tests passed, 0 failed out of 1 (1936 fixtures), 225.31 s | U impl  | 2026-09-14
lit RED step (pre-change)| f7b65d8ccd7bc472 | 5 new accepts RED, 2 controls green                            | U impl  | 2026-09-14
e2e slices (undef-seed)  | a5773be142835fb8 | 4/4                                                            | U impl  | 2026-09-14
e2e slices (measure-cls) | a5773be142835fb8 | 8/8, goldens byte-identical                                    | U impl  | 2026-09-14
e2e slices (cascade)     | a5773be142835fb8 | 9/9, goldens byte-identical (29 and 19)                        | U impl  | 2026-09-14
injection matrix         | a5773be142835fb8 | 10 mutations x 9 accepts: applied 67, MISSED 0, N/A 23         | U impl  | 2026-09-14
vacuity scan             | a5773be142835fb8 | 0 VACUOUS                                                      | U impl  | 2026-09-14
corpus sweep (PARTIAL)   | a5773be142835fb8 | 2793 rows, 7 movers, 1 CLANGERR (identical both binaries)      | U impl  | 2026-09-14
corpus tail sweep        | a5773be142835fb8 | 98 rows, 0 movers                                              | U impl  | 2026-09-14
e2e stage-1 scan         | (clang only)     | 391 slices: only the 3 new ones carry the trigger; 0 undef angles | U impl | 2026-09-14
```

⚠ **OWED BY THE GROUP GATE for Track U:** `cq-opt-equivalence-full` — no decline string moved, but analysis
sites did. ⚠ The corpus sweep was stopped by exact PID under load 300–440 and closed by a reasoned tail
argument, not by completion; the round-1 reviewer is auditing that closure.
