# loopgate — GATES.md (hash-keyed; PROTOCOL non-redundancy)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>`

## Binaries

| label | `cq-opt` sha256 | `libCQPass.so` sha256 | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | `main` `74eabd2c` (verified by `shasum` at gate open, unchanged) |
| S′ | `15f6a75a50faba7a2c99a969497044ca6211293ea00ad6388510c6cc17bff96d` | — | `dephase-fence-r2` (`/Users/sorenwilkening/Desktop/CQ_S/build`) |
| D | `dd5887fc2852612cf471ac0f90b5e2fd973f070dd369e3aee1b477dcaee06dc9` | — | `bbu0-warn-reorder` (`/Users/sorenwilkening/Desktop/CQ_D/build`) |
| FIX | `9dd81edb9f949bb584d9dde333193a24e009110954103d014ebe01f5bacb0fff` | `700b47976704c6dad32ca3aa5e110e048062e68117384968f5f1951675fa1659` | `loop-group-fix` (`/Users/sorenwilkening/Desktop/CQ_LOOPFIX/build`) — **the Track-D-free control** |
| **MERGED** | **`f2ee2eb69f1cdf9b70df9e33d1c169870c0b533e8753230741a648d9f101170b`** | **`7e5ec2d764789959e5647fcc337e4473aa041e39aa8293b31c23953bb875e1db`** | **this gate: `loop-group-fix` + `bbu0-warn-reorder`** |

## Gate lines — `ran:` unless marked `cited:`

build the worktree (`cmake --build build -j2`, BOTH targets) | f2ee2eb69f1cdf9b | CQPass + cq-opt built clean; both-binary discriminator (Track T's third false-green form) run on one module: `cq-opt` and `opt -load-pass-plugin libCQPass.so` agree, exit 1 and the same diagnostic byte for byte | gate | 2026-09-15 08:25
**full `ctest --test-dir build -j6 --output-on-failure`** | f2ee2eb69f1cdf9b | **100% tests passed, 0 tests failed out of 446. Total Test time (real) = 2458.29 sec.** Load: 3.99 at start, peaked 53.69 mid-run (other agents), 14.92 at end — NOT a quiet box | gate | 2026-09-15 08:26–09:07
`e2e-loop-twin-matrix` (inside the full run — the OWED single run) | f2ee2eb69f1cdf9b | Test #318 **Passed 2087.81 sec**. Script AND both tables byte-identical to `main` ⇒ **338 cells (309 expected + 29 quarantine), NO axis skew**, 0 cells moved | gate | 2026-09-15 09:07
`cq-opt-equivalence-full` | f2ee2eb69f1cdf9b | **cq_opt_equivalence: compared 2051 fixtures, 0 mismatch(es)**; binary sha256 unchanged before/after (no relink) | gate | 2026-09-15 09:16
corpus sweep, ORACLE `0e280fc6` | 0e280fc62a91cec2 | sweep OK: 4220 rows, accepts=2529 declines=1691, 127=0 | gate | 2026-09-15 09:13
corpus sweep, FIX `9dd81edb` (Track-D-free control) | 9dd81edb9f949bb5 | sweep OK: 4220 rows, accepts=2529 declines=1691, 127=0 | gate | 2026-09-15 09:20
corpus sweep, MERGED | f2ee2eb69f1cdf9b | sweep OK: 4220 rows, accepts=2529 declines=1691, 127=0 | gate | 2026-09-15 09:20
**Track D env-unset identity (FIX vs MERGED)** | f2ee2eb69f1cdf9b | **the two sweep files are BYTE-IDENTICAL, sha256 `73224a38ba5c1ff2878ef0efd48a0669…` — 0 movers over 4220 rows, same lowered-IR hash on all 2529 accepts and same FULL-STDERR hash on all 1691 declines** | gate | 2026-09-15 09:20
corpus attribution ORACLE vs MERGED | f2ee2eb69f1cdf9b | **90 movers: 35 D→A (T) · 31 A→A (T) · 20 D→D string (S′) · 2 D→D R2-grant (T) · 2 A→D (emkg). UNATTRIBUTED 0** | gate | 2026-09-15 09:22
`A→A` stream adjudication | f2ee2eb69f1cdf9b | **PAIRING-ONLY deltas 31, OTHER (FINDING candidates) 0**; the 4 empty-delta rows are a `declare` ORDER change only — instructions byte-identical | gate | 2026-09-15 09:30
L8 duplicate-body fixture scan | f2ee2eb69f1cdf9b | scanned 2051 fixtures, **9 duplicate-body groups, 0 with CONTRADICTORY verdicts**; 1 file with an empty non-comment body (`lowering_predmux_purecallee_deep_chain.ll`, generates its module at RUN time, identical on `main`) | gate | 2026-09-15 08:55
S1 three post-union checks on `tests/e2e/CMakeLists.txt` | f2ee2eb69f1cdf9b | **0 duplicate `add_test` names; count reconciles 432 (main) + 4 (Track T `534ea73a`) = 436; `get_property`/`set_tests_properties` sweep still LAST** | gate | 2026-09-15 08:50
re-derivation: `c1_cmp_rail_data` | f2ee2eb69f1cdf9b | rolled **14 == twin 14**, multiset delta EMPTY, **TRACE BYTE-IDENTICAL** — the fix agent's claim HOLDS on this binary | gate | 2026-09-15 08:24
re-derivation: `c2_inloop_rotation` | f2ee2eb69f1cdf9b | rolled **24 == twin 24**, **multiset delta EMPTY**, positional difference only (the LICM-hoisted `y & 1` at trace line 3 rolled / line 10 twin, disjoint support) — multiset-plus-commutation, as its header claims, HOLDS | gate | 2026-09-15 08:24
n1/n2/n3/r1 declines + a9 control | f2ee2eb69f1cdf9b | n1/n2/n3/r1 all **DECLINE** at the fence; twins **42 / 34 / 48 / 72**; `a9` accept control **24** — matches the brief and the fix record exactly | gate | 2026-09-15 08:25
relocated `DEFER` pin, binary mutation | f2ee2eb69f1cdf9b | on FIX `9dd81edb` (no Track D) `FileCheck --check-prefix=DEFER` **exit 1, "expected string not found"**; on MERGED **exit 0**; `lit --filter loop_leak_dephase_reject_region_derivedbase_live` **PASS** | gate | 2026-09-15 08:35
adversarial probe **G1** (the gate's own) | f2ee2eb69f1cdf9b | `g1_twofn_kb_rotated.c` **DECLINES on all five binaries**; on MERGED source-located to `kb` at `:23:39` — the leaking half | gate | 2026-09-15 09:35
ORACLE unmoved at gate close | 0e280fc62a91cec2 | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` — identical to the PROTOCOL block; nobody rebuilt it | gate | 2026-09-15 09:40

## CITED, not re-run (PROTOCOL non-redundancy)

cited: `ir-pass-lit` 1/1 Passed 82.56 s (2051 fixtures, 1 XFAIL) @ 9dd81edb (loopfix, 2026-09-15) — **subsumed by this gate's full `ctest`, which ran it on `f2ee2eb6`**
cited: injection matrix 57 mutations, MISSED 0, N/A 7 @ 9dd81edb (loopfix)
cited: Track D BASE-vs-SUBJECT sweep, 5289 rows, MOVERS 0, env unset @ dd5887fc (trackD) — **independently re-established here at the merged hash, §"Track D env-unset identity"**
cited: Track D's number — SILENT 0 of 12 (minimum scope) / 0 of 14 (full corpus), `marker=1` on every row, five ORACLE controls `1·1·2·1·2` @ d4bf79c1 (trackD). Carried with both caveats in `TRACKD_NUMBER.md`

## NOT run, and why

* **per-track gates.** PROTOCOL S1: one combined gate per disjoint-file GROUP. A red group gate is
  the interaction a per-track gate would hide, and the prescribed response is to bisect by reverting
  one branch's merge in this worktree — not to fall back to per-track runs. The gate was green, so
  no bisect was needed.
* **a second full `ctest`.** One per landing; never two in flight on this box.
* **`ir-pass-lit` on its own.** It is inside the full run at this binary.
* **the `angle_select_twin_matrix` / `inplace_twin_matrix` / `golden_multiset_audit` instruments.**
  Not ctest gates (bd `drbq.9`, pending an owner cost decision) and not in this group's brief.
* **a rebuild of the ORACLE.** Read-only for the whole session; hash re-verified at open and close.
* **Track I's BANK axis.** `twinmatrix-bank-axis` is **not in this group**. This worktree has neither
  half of it — script and tables both byte-identical to `main` — so the 21 `MISSING` / `NEW CELL`
  version-skew rows the brief warns about **cannot arise here**, and the 338-cell result is a
  like-for-like comparison. Track I measured **0 MOVED over 676 pre-existing cell/surface pairs**, so
  any pre-existing cell that moved under this gate would have been this group's; **none did.**
* **`pkill`.** Never by pattern. ⚠ Noted rather than acted on: PID **84129**, a `cq-opt` from another
  worktree stuck **9 h 02 m** on
  `trackT/probes/adv/out/b1_mixed_nonlive.sub.s1.ll`, was alive throughout this gate and is still
  alive. It is not mine, it was not killed, and it contributed to the load figures above. **A
  possible pass HANG on that module is worth someone's attention** — it is not in this group's
  corpus rows as a hang because the sweep reads `b1_mixed_nonlive.sub.s1.ll` fine on both binaries
  (row present, verdict recorded), so whatever hung it was not reproduced here.

## ERRATUM against this gate's OWN instrument (CLAUDE.md L10)

`sweep_gate.sh`'s first spelling printed **`skipped-empty=8`**. That was a LIE OF LABEL: the counter
computed its denominator with `find … inc1-records -name '*.ll'` — **without** the `-path '*probes*'`
filter the sweep itself uses — so it reported *1 genuinely-empty + 7 out-of-scope* as `8`. Measured:
exactly **1** module is 0-byte (`session-2026-09-14c-xdu2-w1/review_r1a/probes/h0_empty.ll`, itself a
deliberate vacuity probe). **The sweep data was never affected** — it iterates the filtered,
non-empty list — and that is not an argument: the counter was corrected **in the source**
(L7-with-a-twist) and the sweep re-run, coming back **byte-identical** to the committed file. The
label moved; not one row did.
G1 twin control | f2ee2eb69f1cdf9b | `g1_twofn_kb_rotated_un.c` **ACCEPTS, 31 trace lines** — the flat spelling performs the discharge the rolled form loses, so G1's decline is a genuine rolled-vs-flat divergence and not a decline of convenience | gate | 2026-09-15 09:45
