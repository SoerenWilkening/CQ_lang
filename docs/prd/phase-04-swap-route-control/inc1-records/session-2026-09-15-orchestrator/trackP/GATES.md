# Track P′ — GATES (hash-keyed; PROTOCOL.md "a gate result is a fact about a BINARY")

Format: `<gate> | <sha256 of the measured cq-opt, first 16> | <result verbatim> | <who> | <date time>`

## Binaries — THREE, because this track is not based on `main`

| role | commit | `cq-opt` sha256 | note |
|---|---|---|---|
| **ORACLE** (`/Users/sorenwilkening/Desktop/CQ_lang/build`, read-only) | `main` `74eabd2c` | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | verified by `shasum -a 256` at track open; matches PROTOCOL.md's corrected oracle block and the brief |
| **BASE** (a copy in this session's scratchpad) | `3637fdd2` (Track F′) | `8cda04ca3f32bd735f9be2fd8dd468c4d8916e739c4dcbcfe303641cef44dd16` | **not rebuilt — COPIED**, see the source-identity gate below |
| **SUBJECT** (`/Users/sorenwilkening/Desktop/CQ_P/build`) | `prep-leaf-grammar` | *(recorded below per build)* | |

`libCQPass.so`: ORACLE `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b`,
BASE `10c2ae8d8f2a12c8b3b4426c56d56aee2ab2b5327add7182421d24c2db5ee2c4`.

⚠ **WHY THE BASE BINARY WAS COPIED RATHER THAN BUILT, AND WHY THAT IS A MEASUREMENT
AND NOT A SHORTCUT.** The brief asks for three-way rows so F′'s movers can be told
from mine. Building `3637fdd2` here would have cost a second full build on a box at
load average 214–353. Instead the binary was taken from Track F′'s own worktree and
its provenance was **checked twice**: (a) `CQ_F` is checked out at exactly
`3637fdd2`, my base commit, and `diff -rq` over `ir-pass`, `include`, `runtime`,
`tools` between `CQ_F` and `CQ_P` at my branch point printed **nothing** — no source
file differs; (b) its `cq-opt` sha256 is `8cda04ca3f32bd73…`, character-for-character
the SUBJECT hash Track F′ recorded in its own `GATES.md` and the hash bd
`test_C_libtooling-hlhh` cites. A hash plus a source-identity diff is strictly more
evidence than a rebuild would have been, because a rebuild proves only that *my*
toolchain reproduces it.

## Gate lines

```
source-identity: CQ_F vs CQ_P @ branch point  | 8cda04ca3f32bd73 | diff -rq over ir-pass/include/runtime/tools: NO OUTPUT -- no source file differs; CQ_F HEAD = 3637fdd2 = my base | impl | 2026-09-15 00:20
oracle hash check (shasum -a 256)             | 0e280fc62a91cec2 | cq-opt and libCQPass.so both match PROTOCOL.md's corrected oracle block exactly | impl | 2026-09-15 00:16
```

### RED state — the three beads, measured on ORACLE **and** BASE before any edit

```
per-probe pA1 (bd hn29 case 2 == bd leyd)     | 0e280fc6 / 8cda04ca | BOTH DECLINE exit=1 'condition predates a non-diagonal gate', anchor pA1.c:12:12 (the && select) | impl | 2026-09-15 00:21
per-probe pA2 (bd hn29 case 1, as written)    | 0e280fc6 / 8cda04ca | BOTH ACCEPT exit=0, 64 lines -- -O1 FUSES the two same-condition kickbacks into ONE diamond, so the bead's case (1) is NOT reachable in that spelling. A Rule-11 correction, not a fix. | impl | 2026-09-15 00:21
per-probe pA2b (bd hn29 case 1, unfused)      | 0e280fc6 / 8cda04ca | BOTH DECLINE exit=1 'condition predates a non-diagonal gate', anchor pA2b.c:11:9 -- the shape reproduces once a DIFFERENT-condition region sits between the two readers | impl | 2026-09-15 00:22
per-probe pA3 (bd 52og)                       | 0e280fc6 / 8cda04ca | BOTH DECLINE exit=1 'condition predates a non-diagonal gate', anchor pA3.c:9:13. (The bead recorded the ORACLE string as 'branch phase on a bare i1 condition'; it was measured against the PRE-3qps oracle. Disposition unchanged.) | impl | 2026-09-15 00:21
per-probe a1/a2/a3 (hand-IR accept candidates) | 0e280fc6 / 8cda04ca | ALL THREE DECLINE on BOTH 'condition predates a non-diagonal gate' | impl | 2026-09-15 00:25
per-probe d1/d2 (hand-IR fence candidates)    | 0e280fc6 / 8cda04ca | BOTH DECLINE on BOTH -- the fence's red state, so a post-change decline is not vacuous | impl | 2026-09-15 00:22
per-probe shipped cross-block fixture         | 0e280fc6 / 8cda04ca | control_phase_kickback_reject_mergephi_cross_block.ll DECLINEs on BOTH; its in-Pred sibling control_phase_kickback_mergephi_rail.ll ACCEPTs 19 lines on BOTH | impl | 2026-09-15 00:22
```

(Rows appended below as they are run.)

### GREEN state — the SUBJECT binary

SUBJECT `cq-opt` = `7916923f56fb36af90dfd05efe0b8c45317db5dc30d4d90ec56f8ffadba56e72`,
`libCQPass.so` = `b8ec28927c3beff425554b75adca6474e928af535b6d78cbf8110390227ea8e7`.

⚠ Build hygiene, checked rather than assumed (the FALSE-GREEN trap): `cmake --build build -j4`
without a `--target`, so BOTH `CQPass` and `cq-opt` are built; every `.o` of a file I edited is
NEWER than its source (`ArmClassify.cpp` 00:25:53 → `.o` 00:27:30/00:27:35; `SwapRouteEmit.cpp`
00:23:02 → `.o` 00:26:05/00:26:22); and an immediately-following `cmake --build build -j4` compiled
**0** translation units, i.e. the tree is fully up to date with the sources on disk.

```
build (cmake --build build -j4, BOTH targets, no --target) | 7916923f56fb36af | exit 0; 21 TUs recompiled; 0 errors; re-run compiles 0 TUs; every edited .o newer than its source | impl | 2026-09-15 00:27
per-probe: 16-probe family, THREE-WAY (ORACLE/BASE/SUBJECT) | 7916923f56fb36af | 7 ACCEPTs recovered (pA1, pA2b, pA3, a1, a2, a3, d5), 4 fences still DECLINE (d1, d2, d3, d4), 2 unmoved controls (pA2, c5); full table in IMPL_P.md section 4 | impl | 2026-09-15 00:38
stage 2b STRICT on all 7 new accepts                        | 7916923f56fb36af | 0 violation(s), 0 unproven on every one; counts in IMPL_P.md section 4b | impl | 2026-09-15 00:39
linked + ran the 3 C-level accepts                          | 7916923f56fb36af | pA1 14 trace lines (toffoli/rz/toffoli/free, h0-h2 controls only); pA2b 9 lines in SOURCE order; pA3 9 lines with the rz fired 3x | impl | 2026-09-15 00:39
bd 52og rolled-vs-unrolled twin                             | 7916923f56fb36af | traces BYTE-IDENTICAL (diff empty) vs the hand-unrolled three-cq_phi twin | impl | 2026-09-15 00:40
bd 52og K-independence (plain C, no -g)                     | 7916923f56fb36af | 44 lowered lines at K=3 and 44 at K=1000 | impl | 2026-09-15 00:41
lit --filter (the 7 files of this family)                   | 7916923f56fb36af | Passed 7, Failed 0 | impl | 2026-09-15 00:44
ctest -R ir-pass-lit                                        | 7916923f56fb36af | 1/1 Passed, 79.05 s over 2047 fixtures. SECOND, INDEPENDENT FLIP MEASUREMENT: every shipped fixture still matches its own CHECKs, so the only shipped expectation that moved is the ONE this track converted deliberately | impl | 2026-09-15 00:45
injection matrix over the 3 new ACCEPT fixtures             | 7916923f56fb36af | 51 mutations, MISSED 0, N/A 6 (all six n/a-shape). The FIRST run reported MISSED 1 + one harness HOLE; both were fixed rather than explained -- see IMPL_P.md section 5 | impl | 2026-09-15 00:52
injection matrix, empty-argv control                        | 7916923f56fb36af | exits 1 with a refusal; does NOT print a green-looking line | impl | 2026-09-15 00:52
shared vacuity.py (PROTOCOL S3)                             | 7916923f56fb36af | NOT CITED -- bd jdec: hardcoded to a dead worktree and matches only handle-form negatives; even repaired it prints `checked 0`, which S3 calls a HOLE not a pass. The injection matrix covers the same property with teeth | impl | 2026-09-15 00:52
```

### Hand-off gates (the same binary; the fixture set is the FINAL one)

⚠ The `ir-pass-lit` and injection-matrix rows above were run BEFORE three fixture edits that the
mutation gate forced (the `PHICNT` prefix, the latch fixture's off-wire rebuild, and one header
correction). **Both were re-run on the final fixture set against the same binary**, and the rows below
supersede them — a gate result is a fact about a binary, but a fixture edit still invalidates the
citation for that fixture.

```
source mutation S-M1 (drop the back-edge clause)   | 7916923f56fb36af | inloop_latch_theta FAILS (Failed 1); the three accepts unmoved (Passed 6). FIRST RUN DID NOT FLIP IT -- a real finding: the fixture then used an ON-WIRE latch theta that the wire walk refuses unaided, so it was rebuilt around an OFF-WIRE operand. See IMPL_P.md 5b | impl | 2026-09-15 01:05
source mutation S-M2 (the cross-block walk returns false) | 7916923f56fb36af | cross_block_OFFWIRE_theta FAILS (Failed 1); cross_block_theta on-wire PASSES (doubly covered by the wire walk -- measured, not assumed); inloop_latch_theta FAILS | impl | 2026-09-15 01:05
source mutation S-M3 (neuter the PhaseKickback edge) | 7916923f56fb36af | reject_mergephi_cross_block FAILS; mergephi_inloop_outside_prep FAILS; two_leaves_cross_block PASSES -- its hcrg chain supplies the order, which is bd hn29's premise being true of one shape and false of two | impl | 2026-09-15 01:05
source mutation RESTORE + hash check               | 7916923f56fb36af | rebuilt after restoring both sources: cq-opt sha256 == the subject hash, BIT-IDENTICAL. Every row keyed on 7916923f is therefore a fact about the SHIPPED source | impl | 2026-09-15 01:06
ctest -R ir-pass-lit (FINAL fixture set)           | 7916923f56fb36af | 1/1 Passed, 62.52 s over 2047 fixtures. The ONLY shipped expectation that moved in this landing is the ONE fixture this track converted deliberately | impl | 2026-09-15 01:12
injection matrix (FINAL fixture set)               | 7916923f56fb36af | 51 mutations, MISSED 0, N/A 6 (all six n/a-shape) | impl | 2026-09-15 01:14
corpus sweep THREE-WAY, COMPLETE                   | 7916923f56fb36af | 3953 rows x 3 binaries (2047 shipped fixtures + every session probe corpus). 3933 identical; 8 F'-only; 10 MINE; 1 BOTH (the deliberate composition fxp1); 0 REVERSION; 1 EMPTY (0-byte). ZERO unattributed movers. Rows: probes/corpus_7916923f.txt; classification and the two instrument corrections in COMPOSITION.md section 3 | impl | 2026-09-15 01:10
per-probe: Rule-13 self-review vectors v1/v2/v3/v4 | 7916923f56fb36af | v1 cross-block COMPARE leaf behind a phi leaf: 'control flow' identically on all three (step 5a refuses it before step 6 exists); v2 theta in the kickback's own arm: 'control flow' on all three; v3 theta in a classically-guarded side block of the loop body: declines on all three (on SUBJECT through the new walk); v4 the off-wire latch theta, now the shipped fixture | impl | 2026-09-15 01:08
per-probe: the F' x P' composition (fxp1/fxp1c/fxp2) | 7916923f56fb36af | fxp2 exits 134 on the ORACLE TOO -- the broken-module defect is PRE-EXISTING on main; F' and P' each ADD CUSTOMERS to it (fxp1c: clean F2 decline -> 134 on BASE; fxp1: clean fence decline -> 134 on SUBJECT). Filed, not fixed. COMPOSITION.md section 2 | impl | 2026-09-15 00:58
```

⚠ **NOT RUN, and recorded as ABSENCES rather than passes** (PROTOCOL's matrix forbids them to an
implementer): the full `ctest -j6`, `ctest -R '^e2e-'`, and `cq-opt-equivalence-full`. This landing
**does move an analysis site and a decline population**, so the merge-and-gate agent owes
`cq-opt-equivalence-full` as well as the full suite.
