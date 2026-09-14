# Track T — `GATES.md` (hash-keyed; PROTOCOL's non-redundancy rule)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

A gate result is a fact about a BINARY, not about a moment. A cited line whose hash
does not match the binary on disk is a FINDING.

## Binaries

| tag | `cq-opt` sha256 (first 16) | what it is |
|---|---|---|
| ORACLE | `0e280fc62a91cec2` | `main` `74eabd2c`, `/Users/sorenwilkening/Desktop/CQ_lang/build` — READ-ONLY, never rebuilt by this track. Verified at session open and again at every use. |
| S1 | `b942977e0833ae84` | + the round-1 ROOT-MINT escape at `markIfIterationLocal`'s slot, + the L1 record and re-ask (stale-roots spelling) |
| S2 | `9337c21095d0afdb` | + `invariantRegisterRootsImpl` clause (ii-c), the MEASURE-OWNED invariant rail |
| S3 | (below) | + the re-ask RE-DERIVES its roots under FINAL taint by calling `invariantRegisterRoots` (closes an over-decline S1/S2 had) |

Full `libCQPass.so` / `cq-opt` sha256, for the record:
```
ORACLE  cq-opt       0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d
ORACLE  libCQPass.so 94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b
S1      cq-opt       b942977e0833ae8459453e78052b39df0be899414230f77075950a399770e9bd
S1      libCQPass.so 0e9af5f998bbc68474510b7578283a96170fbbb57368764e3e59fe802cd114f5
S2      cq-opt       9337c21095d0afdba8bff8598ff5ba7511a8838c507397ae9742da0ed3ff6656
S2      libCQPass.so 8142d82041855d3f11c72a8c9f2a6854843d6d342537c029fad491283891550c
```

## Gate lines

```
build the worktree (cmake --build build -j8, BOTH targets) | b942977e0833ae84 | exit=0, 2 warnings, both PRE-EXISTING in RegionTreeDetect.cpp (OuterNeg/InnerNeg unused) | impl | 2026-09-15
per-probe pipeline (18 probes, s1/s2/s3/t1/t2/t3/w2h/w2h3/w2k + twins) | 0e280fc62a91cec2 | ORACLE baseline recorded in probes/out/*.ora.* | impl | 2026-09-15
per-probe pipeline (same 18) | b942977e0833ae84 | s1 DECLINE->ACCEPT 14==14 BYTE-IDENTICAL; t2 9->13==13 BYTE-IDENTICAL; t3 DECLINE->ACCEPT 20; s3 UNMOVED 22==22; s2/t1 still DECLINE; w2k/w2h/w2h3 UNMOVED (leak) | impl | 2026-09-15
lit ir-pass/test --filter loop | b942977e0833ae84 | 2 failed of 2039 discovered: loop_leak_dephase_reject_noregion_live.ll (its own L8 retirement trigger, expected), lowering_uncompute_interior_leak_loop_rail.ll (bd 6uqc leak probe, expected) | impl | 2026-09-15
build the worktree | 9337c21095d0afdb | exit=0, same 2 pre-existing warnings | impl | 2026-09-15
per-probe pipeline (18 probes + 18 adversarial) | 9337c21095d0afdb | w2k 16->20==20, w2h 30->38==38, w2h3 44->48==48 (gate SYMBOL MULTISET identical to twin in all three); a1 16==16 IDENTICAL; a2 18==18 IDENTICAL; a6 9==9 IDENTICAL unmoved; a7 36==36 IDENTICAL; a8 9==9 IDENTICAL unmoved; a9 24 vs 20 (twin CSE artefact, T-2); a3/a4/a5 DECLINE unmoved; b1/b2 ACCEPT-and-leak unmoved | impl | 2026-09-15
lit ir-pass/test (whole, unfiltered) | 9337c21095d0afdb | Failed: 1 of 2039 — loop_leak_dephase_accept_pertrip_dead.ll (its own L8 retirement trigger: "If a _unc or a cqrt_free ever appears here, either bd tu9q landed ... or something started freeing a dirty rail") | impl | 2026-09-15
lit ir-pass/test --filter loop_leak_dephase_reject_noregion_live | 9337c21095d0afdb | PASS (converted to ACCEPT) | impl | 2026-09-15
lit ir-pass/test --filter interior_leak_loop_rail | 9337c21095d0afdb | PASS (converted to ACCEPT) | impl | 2026-09-15
lit ir-pass/test --filter pertrip_dead | 9337c21095d0afdb | PASS (LEAK prefix retired to PAIR) | impl | 2026-09-15
lit ir-pass/test --filter loop_pairing_reject | 9337c21095d0afdb | PASS 2/2 (the two new (ii-c) boundary fixtures) | impl | 2026-09-15
L1 reachability, hand-written l1_round2_grow_65arm.ll | 9337c21095d0afdb | ORACLE prints bd s82e's string; SUBJECT prints "cq loop lowering: round-1 iteration-local marking falsified by round-2 taint" — the window is REACHABLE (finding T-1) | impl | 2026-09-15
```
