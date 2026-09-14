# Merge-and-gate GATES — session 2026-09-14c, ONE group, five branches

PROTOCOL format: `<gate> | <sha256 cq-opt, first 16> | <result verbatim> | <who> | <when>`.
A gate result is a fact about a BINARY. Every line below was RUN by this agent on the binary named
in its own hash column; nothing here is cited from a track.

**ORACLE** (read-only, never built into): `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt`
`5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8`, `libCQPass.so`
`5276f7ab7416b36b3ceeb8ae0c9b2de3df6833906ec97c6671dfda336d488be4` — verified before first use.

Three binaries exist in this worktree's history and only the THIRD is cited for any final gate:

| # | `cq-opt` sha256 | what it is |
|---|---|---|
| 1 | *(never linked)* | A + B with Track B's shim still present — **the link FAILED, which is the point** |
| 2 | `7720e6c57b33c82aef00e05e8a76893c76f27496e9640d59c79a13f6307d5033` | A + B, shim deleted, promoter wired to Track A's real verdict |
| 3 | **`0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d`** | **A + B + S + X + I — the GATED binary.** `libCQPass.so` `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` |

⚠ A fourth, TEMPORARY **audit** binary (`9885fceec1ab6f2aafc4a9d4aa308ba7cf6ebd395e2dc8ba7a272b8d8c97f441`)
carried Track B's shim under the renamed symbol `railBankCarveVerdictShimAudit` plus a
`CQ_RAILBANK_AB` differential in the exported wrapper. It was built ONLY for the A×B measurement in
`MERGE_REPORT.md` §2, reverted in the same session, and `grep -c "RailBankCarveAudit|CQ_RAILBANK_AB|ShimAudit"`
over `ir-pass/src/*.cpp` + `ir-pass/CMakeLists.txt` is **0** on the gated tree. It is cited for
nothing but that measurement.

```
oracle-hash-verify | 5c6f7490a81c7505 | both hashes match MERGE_BRIEF §ORACLE | merge-and-gate | 2026-09-14
cmake configure + build, A+B WITH the shim present | (none) | LINK FAILED, deliberately: `duplicate symbol 'cq::railBankCarveVerdict(llvm::StoreInst const*, cq::TaintSet const&, llvm::DominatorTree&, llvm::LoopInfo&, llvm::ScalarEvolution&, char const*&, cq::RailBankShape*)'` in RailBankCarveShim.cpp.o and QramLowering.cpp.o — reported for BOTH libCQPass.so and cq-opt. Track B's fail-loud property HOLDS | merge-and-gate | 2026-09-14
cmake --build build -j8, A+B shim deleted + rewired | 7720e6c57b33c82a | 0 errors; cq-opt 7720e6c57b33c82aef00e05e8a76893c76f27496e9640d59c79a13f6307d5033, libCQPass.so 5d0cce241a522ac89577b17b8ac751dd6cb6d37ad29b04b4f27acdf8fe03c75b | merge-and-gate | 2026-09-14
lit ir-pass/test --filter railbank (BEFORE re-pinning) | 7720e6c57b33c82a | 41 discovered, 30 PASS, **11 FAIL** — every one a Track-B refuse fixture pinning `cq taint escape: tainted value stored to memory` where Track A's carve now owns the string. The A×B composition, invisible to either branch alone | merge-and-gate | 2026-09-14
lit ir-pass/test --filter railbank (AFTER re-pinning the 11) | 7720e6c57b33c82a | 41 discovered, **41 PASS**, 1.39 s | merge-and-gate | 2026-09-14
A×B DIFFERENTIAL, real verdict vs shim verdict at every call site | 9885fcee (AUDIT, not shipped) | 130 carve-call rows over 2039 fixtures + 71 C probes: **63 `AB_SAME Bank` (verdict AND all 7 RailBankShape fields equal), 47 `AB_SAME Reject*/NotBank`, 20 `AB_DIFF`, 0 shape mismatches on Bank, and ZERO rows where real=Bank with shim!=Bank.** Every disagreement is the REAL classifier being stricter | merge-and-gate | 2026-09-14
cmake --build build -j8, ALL FIVE branches | 0e280fc62a91cec2 | 0 errors; cq-opt 0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d, libCQPass.so 94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b | merge-and-gate | 2026-09-14
**FULL `ctest --test-dir build -j6 --output-on-failure`** | 0e280fc62a91cec2 | **100% tests passed, 0 tests failed out of 442.** Total Test time (real) = 689.58 sec (a COLD stage-1 cache in a fresh build dir — not comparable with the 130-230 s warm band) | merge-and-gate | 2026-09-14
cmake --build build --target cq-opt-equivalence-full (OWED — A and S each moved a decline string AND an analysis site) | 0e280fc62a91cec2 | `cq_opt_equivalence: compared 2039 fixtures, 0 mismatch(es)`, exit 0 | merge-and-gate | 2026-09-14
FULL corpus sweep ORACLE-vs-MERGED (ROUTING R3 closed BY MEASUREMENT) | 0e280fc62a91cec2 | **6311 rows** = 2039 `ir-pass/test/*.ll` + 1823 `docs/**/*.ll` + 2040 `docs/**/*.c` + 409 `tests/e2e/*.c`, both binaries on the SAME stage-1 module per row, compared by exit code + **full-stderr sha256** + lowered-IR md5 within the row. **6236 SAME · 38 STRMOVE · 14 VERDICTMOVE · 23 CLANGERR · 0 IRDIFF · 0 DECLINE→ACCEPT · 0 unattributable** | merge-and-gate | 2026-09-14
!dbg accounting over the sweep | 0e280fc62a91cec2 | 2661 rows where either side declines; **0 LOST source locations, 0 GAINED** among the 2647 where BOTH decline | merge-and-gate | 2026-09-14
SAFETY PIN — the owner's untracked example/grover/grover_oracle_uncompute.c (bd k4fw, copied in) | 0e280fc62a91cec2 | ORACLE and MERGED both exit 1 with `cq taint escape: tainted value stored to memory` at the SAME `!dbg` (`:92:19`). ⚠ And measured under CQ_RAILBANK_DBG=1: Track A's carve says **Bank cells=3 cell=i8** and Track B's promoter **FIRES** (one `%cq.bank` phi, one store at the latch) — the staging constraint holds THROUGH a live promotion | merge-and-gate | 2026-09-14
duplicate-body fixture scan (sha256 over non-comment lines, verdict read off the RUN lines) | 0e280fc62a91cec2 | **2039 fixtures, 9 duplicate-body groups (all PRE-EXISTING — the same 9 Track A measured at 2015), 0 groups with CONTRADICTORY verdicts**, no `*railbank*` fixture duplicates anything | merge-and-gate | 2026-09-14
L8 rename/resurrection check | 0e280fc62a91cec2 | `git diff --name-status -M fa621f06 HEAD`: **0 renames, 0 deletions** anywhere in the tree. Track S's three conversions and Track X's two tripwires are `M` (in place) | merge-and-gate | 2026-09-14
tests/e2e/CMakeLists.txt union checks | 0e280fc62a91cec2 | **0 duplicate `add_test` names; 432 registrations; the `get_property`/`set_tests_properties` sweep is still LAST**; and `git diff fa621f06 HEAD -- tests/e2e/CMakeLists.txt` is **EMPTY** — no branch added a slice, so PROTOCOL's tail-conflict ERRATUM did not arise | merge-and-gate | 2026-09-14
twin-matrix cells requested by Track S §10, generated on the MERGED binary (NEVER `--regenerate`) | 0e280fc62a91cec2 | `m_noregion_invread_dead` TRACE-DIVERGENCE 16/20 (tool digest `07ae35c484747c29`); `m_noregion_invread_live` **UNROLLED-ONLY** (rolled declines, unrolled accepts 14) — ⚠ NOT the `DECLINE-BOTH` Track S predicted; `m_region_derivedbase_live` **UNROLLED-ONLY** (rolled declines, unrolled accepts 25) — same correction; `m_region_rootmint_live` **ACCEPT-IDENTICAL 22 == 22** (the positive control HOLDS). Adjudication in writing: `MERGE_REPORT.md` §7 | merge-and-gate | 2026-09-14
counts on the merged tree (re-measured, not copied) | 0e280fc62a91cec2 | ctest **442** · `^e2e-` **432** · `^e2e-slice-` **381** · `twin-identical` **40** · `ls ir-pass/test/*.ll` **2039** · `ls tests/e2e/*.expected.log` **383** · twin matrix 309 + 29 = **338** cells | merge-and-gate | 2026-09-14
```

## What this agent did NOT run, and why (Rule 19)

* **No per-track gate was re-run to find anything.** The group gate was green on the first full run, so
  the bisect-by-reverting procedure (`MERGE_BRIEF` §4.2) was never needed and was never used.
* **No injection/mutation matrix.** It is the implementation row's gate, it mutates the BINARY, and
  re-running Track B's would cost ~22 rebuilds. ⚠ This is not free — `MERGE_FILINGS.md` F-3 records
  that three of Track B's mutants no longer measure what they measured, and files it.
* **No `--regenerate`, no `--refresh-quarantine`** on any matrix or baseline file (bd `gfsk`).
* **Nothing was pushed, `main` was not touched, and the primary `build/` was never written.**
