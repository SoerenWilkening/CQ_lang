# Track U — GATES (hash-keyed; PROTOCOL.md §non-redundancy)

A gate result is a fact about a BINARY, not about a moment. Before running any gate, read this
file: if the binary hash is unchanged and the gate is recorded, CITE the line instead of re-running.

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

## Binaries

| | sha256 (cq-opt) | sha256 (libCQPass.so) | note |
|---|---|---|---|
| ORACLE (read-only, `/Users/sorenwilkening/Desktop/CQ_lang/build`) | `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` | `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d` | re-hashed 2026-09-14 10:02, == PROTOCOL.md |
| SUBJECT baseline (worktree at `undef-seed-zero` base, NO source change) | `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` | `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d` | **BIT-IDENTICAL to the oracle** — the worktree reproduces it exactly, so every "before" row below is the oracle's |
| SUBJECT (bd z9t1 implemented) | `a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff` | `957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194` | built 10:11:37, unchanged since |

## Gate lines

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| `cmake --build build -j8` (BOTH targets) | f7b65d8ccd7bc472 | exit 0; cq-opt + libCQPass.so bit-identical to the ORACLE | impl | 2026-09-14 10:02 |
| `lit ir-pass/test --filter 'undef_theta_seed\|constexpr_undef_seed\|poison_theta_seed'` (RED step, pre-change binary) | f7b65d8ccd7bc472 | `Passed: 2  Failed: 5` — the 5 new accepts red, the 2 controls green | impl | 2026-09-14 10:09 |
| `cmake --build build -j8` after the change | a5773be142835fb8 | exit 0, 2 pre-existing `-Wunused-parameter` warnings in untouched functions | impl | 2026-09-14 10:11 |
| `lit --filter 'undef_theta_seed\|poison_theta_seed\|stateprep_undef\|stateprep_poison\|undef_incoming\|undef_literal\|measure_undef'` | a5773be142835fb8 | `Passed: 18  Failed: 3` → after the 3 fixture rewrites, `Passed: 11  Failed: 0` on the same filter set | impl | 2026-09-14 10:19 |
| `lit --filter 'predmux_reject_selectform_rotation'` | a5773be142835fb8 | `Passed: 5` (5 of 5) | impl | 2026-09-14 10:26 |
| `ctest -R '^e2e-slice-undef-seed\|^e2e-undef-seed'` | a5773be142835fb8 | `100% tests passed, 0 tests failed out of 4` | impl | 2026-09-14 10:41 |
| `ctest -R '^e2e-slice-measure-classical\|^e2e-measure-classical-bool-twin-identical'` | a5773be142835fb8 | `100% tests passed, 0 tests failed out of 8` (the bd 21mg pair, unchanged) | impl | 2026-09-14 10:22 |
| `ctest -R '^e2e-slice-control-cascade\|^e2e-cascade'` | a5773be142835fb8 | `100% tests passed, 0 tests failed out of 9` (goldens byte-identical, 29 and 19 lines) | impl | 2026-09-14 10:23 |
| per-probe pipeline, DIAG probes u1–u5/u3b/u4b | a5773be142835fb8 | u1 D (21mg, unchanged) · u2 **D→A 19 lines** · u3 A 15 (seed `undef`→`false`) · u3b A 16 · u4 D (unchanged) · u4b A 3 (unchanged) · u5 **D→A 29 lines**; all STRICT 2b `0 violation(s), 0 unproven` | impl | 2026-09-14 10:37 |
| owner file `example/grover/grover_oracle_uncompute.c` (read-only from the main checkout) | f7b65d8ccd7bc472 **and** a5773be142835fb8 | both `exit=1`, stderr 193 bytes on both, same string (`state prep seed is proven equal to the condition register` — bd om35, unrelated to Track U) | impl | 2026-09-14 10:45 |
| vacuity scan (`probes/impl/vacuity.py`) over the 9 accept fixtures | a5773be142835fb8 | `checked 2 named negatives across 9 accept fixtures: 0 VACUOUS` | impl | 2026-09-14 10:31 |
| injection (mutation) matrix (`probes/impl/inject_u.py`, 10 mutations × 9 accepts) | a5773be142835fb8 | `TOTAL applied 67   MISSED 0   N/A 23` | impl | 2026-09-14 10:52 |
| corpus sweep ORACLE-vs-SUBJECT (`probes/corpus_u.sh`) — **PARTIAL, deliberately stopped** | f7b65d8ccd7bc472 vs a5773be142835fb8 | **2793 rows** (every probe corpus PROTOCOL lists + `ir-pass/test` fixtures 1–1581 of 1928): **7 movers, 1 CLANGERR** (`U0_uncommented.c`, identical on both binaries). Movers = the 4 DIAG customers (u2, u3, u3b, u5) + 3 fixtures; all attributed, see `IMPL_U.md` §6 | impl | 2026-09-14 |
| corpus sweep, TAIL (`probes/corpus_tail_undef_a5773be1.txt`) | f7b65d8ccd7bc472 vs a5773be142835fb8 | **98 rows / 0 movers** — every one of fixtures 1582–1928 that contains an `undef`/`poison` token anywhere (a strict superset of the rule's only trigger) | impl | 2026-09-14 |
| ~~completeness of the unswept remainder (grep, not a sweep)~~ **CORRECTED, F-U1-4(a)** — it was a PARSE, and the row's own parenthesis was the false half; superseded by the whole-corpus census below | — | **0 of the 782 fixtures after index 1154 carries a whole-value `undef`/`poison` `cq_theta` seed** — and `normalizeUndefRotationSeed` returns false without mutating anything unless one is present, so those rows cannot move | impl | 2026-09-14 |
| e2e stage-1 scan, all 391 `tests/e2e/*.c` (clang only, no pass, no ctest) | n/a (stage 1) | the ONLY slices whose `-O1` IR hands a whole-value `undef`/`poison` to a `cq_theta` seed are the **three added by this change**; **0** slices anywhere carry an `undef`/`poison` ANGLE. No shipped e2e golden can move | impl | 2026-09-14 |
| `ctest -R ir-pass-lit` (hand-off, ONCE) | a5773be142835fb8 | `1/1 Test #8: ir-pass-lit ...... Passed 225.31 sec` / `100% tests passed, 0 tests failed out of 1` (lit discovers **1936** fixtures: 1928 + 8 new) | impl | 2026-09-14 |
| rebuild after the comment-only source edits | a5773be142835fb8 | **BIT-IDENTICAL** to the pre-edit binary (`cq-opt` a5773be1…, `libCQPass.so` 957d2e14…), so every line above matches the binary on disk | impl | 2026-09-14 |

## NOT run by this agent (PROTOCOL matrix — implementer may not)

`ctest -j6 -R '^e2e-'` · the full `ctest -j6` · `cq-opt-equivalence-full` · the twin matrices.
⚠ **`cq-opt-equivalence-full` IS OWED by the group gate**: this change adds no diagnostic, but it
MOVES analysis sites (three shipped decline fixtures become accepts), which is the matrix's
"decline string / analysis site changed" trigger.

---

## FIX round (review round 1) — agent: fix, 2026-09-14

**The binary did not change.** F-U1-1's conjunct was implemented, gated, and then REVERTED on the
coordinator's hold (owner ruling pending). What remains is comment-only, mechanically checked:

```
git diff -U0 ir-pass/ | grep -E '^[+-]' | grep -v '^[+-][+-]' | grep -vE '^[+-]\s*//' | grep -vE '^[+-]\s*$'
  (no output)
```

| | sha256 (cq-opt) | sha256 (libCQPass.so) | note |
|---|---|---|---|
| SUBJECT after the FIX round's rebuild | `a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff` | `957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194` | **BIT-IDENTICAL to the round's subject** — so every `a5773be1` line above still matches the binary on disk |
| (withdrawn) build WITH the F-U1-1 conjunct, kept for the record only | `dedb3d53836771f4c66a4b70526ae17cffc215e412835e470e10f83f34e0f2e3` | `ba5a712f557a1685b5966442129f72cbcceb8b8073062b3b0dc6c680e6ee57e2` | reverted; not in any commit |

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| ORACLE hash re-verification (first act) | — | `f7b65d8ccd7bc472…` / `f9e898badfd4207a…` — both match `PROTOCOL.md`; oracle untouched | fix | 2026-09-14 |
| `cmake --build build -j8` (BOTH targets) WITH the conjunct | dedb3d53836771f4 | exit 0, 2 pre-existing `-Wunused-parameter` warnings in untouched functions | fix | 2026-09-14 |
| `cmake --build build -j8` (BOTH targets) after the REVERT | a5773be142835fb8 | exit 0; **bit-identical to the round's subject binary** | fix | 2026-09-14 |
| F-U1-1 probes, per-probe pipeline, BOTH binaries | f7b65d8ccd7bc472 vs a5773be142835fb8 | `r14` O exit 1/246 B vs S exit 0/0 B · `r15` O 1/244 vs S 0/0 · `r21` O 1/248 vs S 0/0 · `r22` O 1/248 vs S 0/0 · `r17`+`r03` **IR IDENTICAL** on both | fix | 2026-09-14 |
| the same probes on the WITHDRAWN conjunct build | f7b65d8ccd7bc472 vs dedb3d53836771f4 | `r14`/`r15`/`r21` restored to DECLINE with **byte-identical full stderr** (`af462b4782c3` / `9de28ea1bb49` / `1f7b5b1eb9e1`); `r22` still accepts (non-local, no local conjunct sees it); `r17`/`r03` still IR IDENTICAL; u1-u5 unchanged (u2/u5 still ACCEPT, u5 trace 29 lines byte-identical to `slice_control_cascade_two_bools.expected.log`, STRICT 2b `8 rail mint(s) … 2 verified, 0 violation(s), 0 unproven`). ⚠ the two withdrawn FIXTURE FILES were NOT FileCheck'd on this build — only the C probes they transcribe | fix | 2026-09-14 |
| **(2a)** genuine PAIRING hazard after z9t1 | f7b65d8ccd7bc472 vs a5773be142835fb8 | `lowering_reject_undef_literal_paired_rz_angle.ll` DECLINES on both, full-stderr sha **`6aae90a25c28` both**; `a2_pairing_survives_with_undef_seed.ll` (same module, seed ALSO undef so z9t1 fires) DECLINES on both, sha **`d2151e0b0c8d` both** → **the pairing break still fires** | fix | 2026-09-14 |
| **(2b)** surviving slot count in r14 | a5773be142835fb8 | 3 emitted calls; **exactly 1** undef-bearing slot (`cqrt_ry_f64(i32 %h, double undef)`); no adjoint (rail is measured) | fix | 2026-09-14 |
| **(2c)** where the blessed single undef sits | — (file read) | ORIGIN = a select arm (`select i1 %c, double undef, double %q`) ✓; DESTINATION = an **ALLOCATOR value operand** `%selop = call i32 @cqrt_alloc_f64(double undef)`, **not** a rotation angle. Plus: `slice_libm_ld80_nexttoward.expected.log:368` already commits `cqrt_alloc_f64(0x1.100000002p-1038)` | fix | 2026-09-14 |
| **(2d)** determinism of the r14 circuit | a5773be142835fb8 | 2 independent links (exe sha `dc3219cb9736f19e`, `f188e1def2bceba2`) × 3 runs = **6/6 identical**, angle `0x1.100000002p-1038` every time — the same value as the committed nexttoward golden line 368 | fix | 2026-09-14 |
| F-U1-4(a) theta-operand census, parser, whole corpus | — (stage 0, text parse) | **1936 fixtures**: SEED-undef only **11** · ANGLE-undef only **3** · BOTH **0** · PARSE-SKIP **2** (the two `*_constexpr_*_seed.ll`) | fix | 2026-09-14 |
| F-U1-4(b) `*_lib.c` closure | — (text) | `tests/e2e/*.c` = **394**; `*_lib.c` = **22**; containing the token `cq_theta` = **18** (reviewer said 21); **actual calls = 0** — 17 `#ifdef cq_theta` tripwires + 1 comment. Scan covered **372**, not "all 391" | fix | 2026-09-14 |
| `ir-pass/test/*.ll` count | a5773be142835fb8 | **1936** — unchanged; the two F-U1-1 decline fixtures were withdrawn to `fix_r1_probes/pending_ruling/` | fix | 2026-09-14 |

### CITED, not re-run (PROTOCOL: a gate result is a fact about a BINARY)

The rebuild is bit-identical to `a5773be142835fb8`, so these rows above still describe the binary on
disk and re-running them would measure the same binary twice:

* `cited: ir-pass-lit Passed 225.31 s, 1/1, lit discovers 1936 @ a5773be1 (impl, row 36)`
* `cited: corpus sweep 2793 rows / 7 movers @ f7b65d8c-vs-a5773be1 (impl, row 32) — ⚠ PARTIAL as recorded`
* `cited: corpus tail 98 rows / 0 movers @ f7b65d8c-vs-a5773be1 (impl, row 33)`
* `cited: injection matrix applied 67 / MISSED 0 / N/A 23 @ a5773be1 (impl, row 31)`
* `cited: vacuity scan 0 VACUOUS @ a5773be1 (impl, row 30)`

⚠ Had the F-U1-1 conjunct landed, **every one of those was owed afresh** — the binary would have been
`dedb3d53…`. If the owner rules to restore the decline, none of the five may be cited for it.

### NOT run by this agent (PROTOCOL matrix — fix agent may not)

`ctest -j6 -R '^e2e-'` · the full `ctest -j6` · `cq-opt-equivalence-full` · the twin matrices.
No suite layer of any kind was executed this round: every verdict above is a per-probe two-binary
measurement, a text parse, or a file read.

---

## FIX round (review rounds 2 + 3, PROSE ONLY) — agent: fix-r3, 2026-09-14

**The binary did not change.** This round landed record corrections, source *comments* and fixture
*headers* only: F-U2-2 (which had never landed) folded with F-U3-2, the F-U3-3 disclosure paragraph,
the F-U3-4 one-shot amendment with three retirement triggers, and the two-164 number hazard. **F-U3-1
and F-U1-1 are untouched, pending the owner's ruling.** Full record: `FIX_U_R3.md`.

```
git diff -U0 ir-pass/ | grep -E '^[+-]' | grep -v '^[+-][+-]' | grep -vE '^[+-]\s*//' | grep -vE '^[+-]\s*$'
  (no output)
```

| | sha256 (cq-opt) | sha256 (libCQPass.so) | note |
|---|---|---|---|
| SUBJECT after the fix-r3 rebuild | `a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff` | `957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194` | **BIT-IDENTICAL to the round's subject** — every `a5773be1` line above still matches the binary on disk |

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| `cmake --build build -j8` (BOTH targets) after the comment-only edits | a5773be142835fb8 | exit 0, 2 pre-existing `-Wunused-parameter` warnings in untouched functions; bit-identical to the subject | fix-r3 | 2026-09-14 |
| `lit ir-pass/test --filter 'control_peel_reject_undef_incoming\|control_peel_reject_poison_incoming\|control_accept_undef_theta_seed_stateprep'` | a5773be142835fb8 | `Passed: 3` of 3 (1936 discovered, 1933 excluded), 10.10 s — the three fixtures whose HEADERS this round edited | fix-r3 | 2026-09-14 |
| census re-derivation from round 3's `review_r3_probes/census_main.json` | — (text parse, no pass run) | 711 modules · 895 phis · 698 injectable incomings · 4 already-undef · **972 carried thetas** · **164** carried by >1 phi · **37** phis with ≥2 non-theta incomings — all six reproduce round 3 exactly | fix-r3 | 2026-09-14 |
| F-U3-4 limb greps, re-run independently (+2 spellings round 3 did not cover) | — (source read) | `setIncomingValue` **1** · `addIncoming` **3** / `removeIncomingValue` **2**, none able to put an undef on a theta-carrying phi · `UndefValue::get`/`PoisonValue::get` **0** · `PHINode::Create`/`CreatePHI` **2**, both structurally excluded | fix-r3 | 2026-09-14 |

### CITED, not re-run (a gate result is a fact about a BINARY)

`ir-pass-lit` (row 36) · corpus sweep (row 32, ⚠ PARTIAL as recorded) · corpus tail (row 33) ·
injection matrix (row 31) · vacuity scan (row 30) · review round 3's 711-module phi sweep. The
rebuild is bit-identical, so re-running any of them would measure the same binary twice.

### NOT run by this agent (brief: no corpus sweep, no suite, no full ctest)

`ctest -j6 -R '^e2e-'` · the full `ctest -j6` · `cq-opt-equivalence-full` · the twin matrices · any
corpus sweep. ⚠ **`cq-opt-equivalence-full` is still OWED by the group gate** for the original
increment (three shipped declines became accepts); this round adds no new obligation.
