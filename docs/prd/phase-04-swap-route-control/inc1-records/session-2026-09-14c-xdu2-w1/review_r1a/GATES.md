# GATES — review r1a (Rule-13 round 1, track α)

Per PROTOCOL the reviewer runs NO build and NO suite. Its one gate obligation is the binary-hash check.

```
binary-hash-check | 0e280fc62a91cec2 | SUBJECT cq-opt sha256 0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  UNCHANGED before first probe and after last | review-r1a | 2026-09-14
binary-hash-check | 5c6f7490a81c7505 | ORACLE  cq-opt sha256 5c6f7490a81c75057fe73abcd6fa5a8e8026e0ccc810e961ff7197f62e515ba8  UNCHANGED before first probe and after last | review-r1a | 2026-09-14
per-probe-pipeline | 0e280fc62a91cec2 | 31 probes, ORACLE vs SUBJECT on one stage-1 file each: 0 DECLINE->ACCEPT | review-r1a | 2026-09-14
promoter-fire-sweep | 0e280fc62a91cec2 | 2039 rows over ir-pass/test/*.ll: promoter fires on exactly 10 files, all this increment's own | review-r1a | 2026-09-14
reject-fixture-attribution | 0e280fc62a91cec2 | 13 railbank_promote_reject_*: 11 take a Track-A rail-bank string, 1 (already_ssa) carve=[Bank] promo=0, 1 (classical_store) no decline | review-r1a | 2026-09-14
```

NOT run (and not owed): build, `lit`, `ctest`, `cq-opt-equivalence-full`, the full corpus sweep,
the injection matrix, the twin matrices.
