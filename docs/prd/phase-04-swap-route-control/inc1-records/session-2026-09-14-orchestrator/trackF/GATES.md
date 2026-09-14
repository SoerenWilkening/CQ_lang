# Track F (SCOPING, READ-ONLY) — GATES

Format (PROTOCOL.md): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
Track F runs **no build and no suite** (PROTOCOL matrix, row "scoping"). Its only gate is the
per-probe pipeline on the frozen ORACLE.

ORACLE verified before first use:
```
shasum -a 256 build/ir-pass/cq-opt        f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  == BRIEF
shasum -a 256 build/ir-pass/libCQPass.so  f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  == BRIEF
```

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| oracle hash check | f7b65d8ccd7bc472 | both hashes == BRIEF | trackF-scope | 2026-09-14 |
| per-probe pipeline, F2 corpus baseline (32 fixtures naming the string) | f7b65d8ccd7bc472 | 29 DECLINE F2 · 3 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST S (seed -> wild) x 26 valid | f7b65d8ccd7bc472 | 22 ACCEPT (PIN) · 4 F2 (TRUNCATED) | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST A (seed -> other-edge value) x 11 valid (1 mis-substitution repaired as A2) | f7b65d8ccd7bc472 | 10 F2 · 1 ACCEPT (fcmp_oeq_derived) | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST B (collider neutralised) x 25 (1 repaired as B2) | f7b65d8ccd7bc472 | 25 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, TEST W (move the pinning edge's fact) x 19 (16 fixtures + 3 customers) | f7b65d8ccd7bc472 | 19 ACCEPT => ONE-EDGE, 0 exceptions | trackF-scope | 2026-09-14 |
| per-probe pipeline, BOTH-EDGE positive controls C1/C2 + their W | f7b65d8ccd7bc472 | 4 F2 (W does NOT flip them) — the instrument discriminates | trackF-scope | 2026-09-14 |
| per-probe pipeline, RIVAL audit x 25 | f7b65d8ccd7bc472 | 20 `control flow` (R3) · 5 `state prep merged with a quantum register` (F1) · 0 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, BOTHSLOT in-place reading x 20 | f7b65d8ccd7bc472 | 18 R6 · 2 R4 · 0 ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, R3 isolation pair (off-wire base) | f7b65d8ccd7bc472 | literal pred slot -> `control flow`; register pred slot -> ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, customers (owner file / vd.c / w2.c) | f7b65d8ccd7bc472 | 3 DECLINE F2; TEST W on each -> ACCEPT; sole-collider S1 -> ACCEPT | trackF-scope | 2026-09-14 |
| per-probe pipeline, C probes be1/be2 (is a both-edge pin reachable from C?) | f7b65d8ccd7bc472 | 2 ACCEPT — `-O1` deleted the collider in both | trackF-scope | 2026-09-14 |
| per-probe pipeline, HOLE-1 quartet (fp anchor) | f7b65d8ccd7bc472 | subject F2 · its TEST-W twin **still F2** · BOTHSLOT_nomeasure **ACCEPT exit 0** | trackF-scope | 2026-09-14 |
| mechanical: does any fixture collider descend from the region's merge phi? | f7b65d8ccd7bc472 | 32/32 NO (all three customers: YES) | trackF-scope | 2026-09-14 |

Probe files: `trackF/probes/` (147 .ll modules + 5 .c + 3 generator scripts + run1.sh).
Generators are re-runnable and re-check nothing about the tree: `gen_pin.py`, `gen_pin2.py`, `gen_rival.py`.
