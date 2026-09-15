# Track M (scoping) — GATES

Per `PROTOCOL.md`: a gate result is a fact about a BINARY. Hash column = first 16 of
`shasum -a 256 build/ir-pass/cq-opt`. **This track is SCOPING: it built nothing, relinked
nothing, and ran no `ctest`, no `lit`, and no suite.** Its only gate is the per-probe
pipeline against the read-only ORACLE, which its brief authorises.

```
gate | hash16 | result verbatim | who | when
```

| gate | hash16 | result | who | when |
|---|---|---|---|---|
| `shasum -a 256 build/ir-pass/{cq-opt,libCQPass.so}` | `0e280fc62a91cec2` | matches `PROTOCOL.md` ORACLE block exactly (`…9c6d` / `94602c78…507b`) | trackM-scoping | 2026-09-15 |
| per-probe pipeline, 8 `m14*` probes | `0e280fc62a91cec2` | A5 / D / D / D / D / D / A12 / A3 — reproduces `IMPL_D.md` §14.7 exactly | trackM-scoping | 2026-09-15 |
| per-probe pipeline, 12 `e2*` probes | `0e280fc62a91cec2` | 6 D (all on the clause-4 string), 6 A | trackM-scoping | 2026-09-15 |
| per-probe pipeline, 20 `e3*` probes | `0e280fc62a91cec2` | 7 twin A; e3h D, e3i D, e3j A5, e3k D, e3l A3, e3m A8, e3n A3, e3o D, e3p A3, e3q D, e3r A6, e3s A3, e3t A3 | trackM-scoping | 2026-09-15 |
| per-probe pipeline, 5 relabelled `m14*` stage-1 modules | `0e280fc62a91cec2` | **5 of 5 ACCEPT**; `m14a.relabel` lowered body + trace BYTE-IDENTICAL to the `e3a` C twin | trackM-scoping | 2026-09-15 |
| `probes/post_measure_trace_scan.py --selftest` | (no plugin) | SELFTEST PASSED (6 cases, 2 known positives, 4 known negatives) | trackM-scoping | 2026-09-15 |
| `probes/post_measure_trace_scan.py tests/e2e` | (no plugin) | **0 of 383 committed goldens hold a post-measure handle re-use** | trackM-scoping | 2026-09-15 |
| `probes/post_measure_ir_scan.py --selftest` | (no plugin) | SELFTEST PASSED (7 modules, 5 known positives, 2 known negatives) — ⚠ FAILED 7/7 on its first spelling (`#dbg_` records counted as uses) | trackM-scoping | 2026-09-15 |
| `probes/post_measure_ir_scan.py 'ir-pass/test/*.ll'` | (no plugin) | 2039 modules scanned: **DEFINITE 23 use(s) in 22 module(s)**; POSSIBLE(upper bound) 873 use(s) in 608 module(s) | trackM-scoping | 2026-09-15 |
| ORIG-vs-RELABELLED over the 22 DEFINITE fixtures | `0e280fc62a91cec2` | **15 D→A, 1 A→D (`control_angle_select_ry_alias_pre_gate`), 2 D→D string-move, 1 D→D unchanged, 3 A→A STREAM-MOVED, 0 A→A identical — 21 movers of 22** | trackM-scoping | 2026-09-15 |
| relabel of the 5 classical-measure fixtures | `0e280fc62a91cec2` | 0 lines rewritten in all 5; IDENTICAL after lowering | trackM-scoping | 2026-09-15 |
| `grep -c '^; RUN: not ' ` over the 22 | (no plugin) | 18 of 22 are negative fixtures | trackM-scoping | 2026-09-15 |
| `ls tests/e2e/*.expected.log \| wc -l` / `grep -c '^add_test(NAME'` / `ls ir-pass/test/*.ll \| wc -l` | (n/a) | 383 / 432 / 2039 | trackM-scoping | 2026-09-15 |

**NOT run, by brief:** any build, `ctest` at any layer, `lit`, the corpus sweep, the
equivalence sweep, the twin matrices, any injection matrix.
