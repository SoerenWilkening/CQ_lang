# Track A — GATES (hash-keyed, PROTOCOL §"The non-redundancy protocol")

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`

A gate result is a fact about a BINARY. Cite a line only if the hash matches the binary on disk.

## Binaries

| role | sha256 `cq-opt` | sha256 `libCQPass.so` | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | frozen, read-only, `main` `74eabd2c` |
| baseline (mine) | `0e280fc62a91cec2…` | `94602c7896e7a7ee…` | ⚠ a clean build of this worktree at `74eabd2c` is **BIT-IDENTICAL to the ORACLE** |
| SUBJECT | `b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf` | `1c7df31bf95268089ffb10775240339764f91bf4d5a53c6186c1178e06e6093a` | de8n + n74d + F-2 + F-4 |
| mutant (n74d, unfixed) | `4516c7617f409ca4…` | — | C6 in-loop-read deleted **+** B4′ reverted |
| mutant (n74d, fixed) | `95fda6f10d3fa874…` | — | C6 in-loop-read deleted only |

## Gate lines

```
build worktree (BOTH targets, -j8)          | 0e280fc6 | Built target CQPass, cq-opt; bit-identical to ORACLE | impl | 2026-09-14 23:37
build worktree (BOTH targets, -j8)          | b6554935 | Built target CQPass, cq-opt                          | impl | 2026-09-15 00:12
per-probe pipeline, 16 probes, O vs S       | b6554935 | 5 verdict moves, all [Bank]->[BankRaw], 0 DECLINE->ACCEPT | impl | 2026-09-15 00:20
lit --filter bankraw_cond_store             | b6554935 | 1/1 Passed                                           | impl | 2026-09-15 00:31
lit --filter bankraw_inloop_read            | b6554935 | 1/1 Passed                                           | impl | 2026-09-15 00:36
lit --filter anchor_unpromoted              | b6554935 | 1/1 Passed                                           | impl | 2026-09-15 00:39
lit --filter inloop_hoisted_read            | b6554935 | 1/1 Passed                                           | impl | 2026-09-15 00:44
lit --filter bankraw_toptest                | b6554935 | 1/1 Passed                                           | impl | 2026-09-15 01:25
red half: FileCheck-on-ORACLE, cond_store   | 0e280fc6 | exit 1 (oracle prints [Bank]) — RED as required      | impl | 2026-09-15 00:33
red half: FileCheck-on-ORACLE, inloop_read  | 0e280fc6 | exit 1 — RED as required                             | impl | 2026-09-15 02:02
red half: FileCheck-on-ORACLE, toptest_exit | 0e280fc6 | exit 1 — RED as required                             | impl | 2026-09-15 02:02
red half: FileCheck-on-ORACLE, unpromoted   | 0e280fc6 | exit 0 — GREEN BY DESIGN (no-movement control; mutant M12 validates) | impl | 2026-09-15 02:02
promoter-output differential, 2043 fixtures | b6554935 | rows=2043 fires O=10 S=10 movers=0; dump sha256 EQUAL on all 10 | impl | 2026-09-15 00:56
corpus sweep O-vs-S, 5582 modules           | b6554935 | rows=5582 verdict-movers=0 stderr-byte-movers=0 accepts=3058 declines=2522 clangerr=2 | impl | 2026-09-15 01:50
injection matrix, 12 mutants                | b6554935 | CAUGHT 9, MISSED 3 (M8/M9/M10, each with a written reason); M3 MISSED->CAUGHT after adding a fixture | impl | 2026-09-15 01:30
n74d mutant, UNFIXED                        | 4516c761 | promo=2; store MOVED past the read (source order inverted) | impl | 2026-09-15 01:38
n74d mutant, FIXED                          | 95fda6f1 | promo=0; module byte-untouched, source order preserved | impl | 2026-09-15 01:43
lit --filter railbank (full family)          | b6554935 | 46 Passed (41 shipped + 5 new)                       | impl | 2026-09-15 01:47
ctest -R ir-pass-lit                        | b6554935 | 1/1 Test #8 Passed 64.43 sec, over 2044 fixtures      | impl | 2026-09-15 02:00
owner's program, O vs S                     | b6554935 | IDENTICAL: exit 1, kMsgStore, carve=[Bank] cells=3, promo=1 | impl | 2026-09-15 01:57
```

## Gates NOT run, and why (PROTOCOL's matrix — the implementer does not own these)

| gate | why not |
|---|---|
| full `ctest -j6` | merge-and-gate agent only, **one per landing** |
| `ctest -j6 -R '^e2e-'` | same; and this track adds no slice — every module on this path still declines, so there is no golden |
| `cq-opt-equivalence-full` | merge agent's call. The input it needs is measured: **0 stderr-byte movers over 5582 rows**, so no decline string and no analysis site moved observably |
| twin matrices | no in-loop lowering code landed |
| duplicate-body fixture scan | no fixture was renamed or moved (5 added, 0 `git mv`) |
| `vacuity.py` over the new accept batch | ⚠ **COULD NOT RUN** — it hardcodes `/Users/sorenwilkening/Desktop/CQ_mphi/build/ir-pass/cq-opt` and dies `FileNotFoundError` in any other worktree. Second defect on that instrument beside bd `jdec`. The stronger check (each fixture's exact RUN-line FileCheck against the ORACLE) was taken instead — see the four `red half:` lines |

## Load note (orchestrator instruction, 2026-09-15)

Builds from `2026-09-15 01:20` onward used **`-j2`** per the orchestrator's message (box at load
average 328→393). No gate on this track was abandoned for load; the corpus sweep was run in **7
foreground chunks** rather than as one background job, for the reason in `IMPL_A.md` §8(a) — a sweep
that outlives the binary it started on reports movers that are not there.
