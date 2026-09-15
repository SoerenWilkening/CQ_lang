# BFIX — GATES (hash-keyed, session 2026-09-15, fix agent)

`PROTOCOL.md`'s non-redundancy contract: **a gate result is a fact about a
BINARY, not about a moment.** Every line is

```
<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <YYYY-MM-DD HH:MM>
```

⚠ **A cited line whose hash does not match the binary on disk is a FINDING.**

## The binaries of this track

| label | `cq-opt` sha256 | `libCQPass.so` sha256 | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | `main` `74eabd2c`, READ-ONLY. Re-hashed on disk by this agent at open — matches `PROTOCOL.md`. |
| BASE | `b65549356168354626a7f09c748e35e43f9fba186ae7ede8dab6a31fd3aae2bf` | `1c7df31bf95268089ffb10775240339764f91bf4d5a53c6186c1178e06e6093a` | Track A `railbank-blockers` `9e11f524` (`/Users/sorenwilkening/Desktop/CQ_A`). Re-hashed — matches. |
| SUBJ_B | `784c14fa05c16c501662b3814434dafb8ffb1cc2ed98a8d17986dc12a372b6ff` | `a4e4f6781524c569e7112f5809c2813dd250d8a1b9e02571a4095d2719ba65c6` | Track B `railbank-accept` `3b982459` (`/Users/sorenwilkening/Desktop/CQ_B`) — **the reviewed binary, i.e. the BEFORE for the P1**. Re-hashed — matches. |
| BFIX-0 | `784c14fa05c16c501662b3814434dafb8ffb1cc2ed98a8d17986dc12a372b6ff` | `a4e4f6781524c569e7112f5809c2813dd250d8a1b9e02571a4095d2719ba65c6` | this worktree built from `3b982459` **before any edit** — **BIT-IDENTICAL to SUBJ_B**, which is what makes every "before" line below a fact about the reviewed compiler and not about a lookalike. |
| **BFIX** | `fd310f8037fb8f48e44aa69e453393dcde79eeda8294e58d5f7ac5b241e4a2f1` | `53d8d05523d295de01587a7984375ffc6543a8ccedf6288bf94c7849fdfdee18` | **the fix.** |

---

```
build BFIX-0 (cmake --build build -j2, BOTH targets) | 784c14fa | exit 0; BIT-IDENTICAL to Track B SUBJ (cq-opt and libCQPass.so both) | fix | 2026-09-15 09:19
both-binary discriminator (p03 bank s1)              | 784c14fa | cq-opt exit=0, opt+so exit=0, IDENTICAL IR                        | fix | 2026-09-15 09:19
RED: register-twin gate, 8 pairs                     | 784c14fa | 8 pair(s) checked, 3 VIOLATION(s) (p01, p05, p08), 0 TRACE-MISMATCH, 0 over-decline | fix | 2026-09-15 09:19
RED: probes f01/f02/f06/f07, 4-way                   | 784c14fa | f01 ACCEPT 7 lines / 2b `2 rail mint(s) … 0 violation(s), 0 unproven`; f02 DECLINE `rotation/measure operand predates a non-diagonal gate` @:6:10; f06 ACCEPT 7 lines; f07 ACCEPT — f06 trace == f07 ORACLE trace, `cmp` empty | fix | 2026-09-15 09:12
RED: owner-capability probes o01/o02/o04/o05         | 784c14fa | ACCEPT 9/9/13/9 lines, STRICT 2b 0 violation(s) each                 | fix | 2026-09-15 09:17
RED: owner inner loop o03 (deferred capability)      | 784c14fa | DECLINE `control flow inside a loop body under quantum control` @:15:15 (E5 wall 3, BANK-INDEPENDENT) | fix | 2026-09-15 09:17
build BFIX (cmake --build build -j2, BOTH targets)   | fd310f80 | exit 0, no errors                                                    | fix | 2026-09-15 09:23
both-binary discriminator (p03 bank s1)              | fd310f80 | cq-opt exit=0, opt+so exit=0, IDENTICAL IR *and* IDENTICAL stderr     | fix | 2026-09-15 09:23
GREEN: register-twin gate, 8 pairs                   | fd310f80 | 8 pair(s) checked, **0 VIOLATION(s)**, 0 TRACE-MISMATCH(es), 0 over-decline(s) | fix | 2026-09-15 09:24
GREEN: register-twin gate SELFTEST (layers A+B)      | fd310f80 | 20 mutant(s) exercised, **0 NOT caught** (12 verdict-table + 8 driver exit-code) | fix | 2026-09-15 09:25
lit --filter (the 3 new fixtures)                    | fd310f80 | 3/3 PASS                                                             | fix | 2026-09-15 09:24
BINARY-MUTATION validation of the RED fixture        | fd310f80 | `railbank_reject_measure_after_nondiagonal_on_parked_rail.ll`: ORACLE rc=1 WRONG STRING (`tainted value stored to memory`), BASE rc=1 same, SUBJ_B **rc=0 ACCEPTS** — the fixture FAILS on all three and passes only here. NON-VACUOUS. | fix | 2026-09-15 09:24
ctest -R 'ir-pass-lit|frontend-lit'                  | fd310f80 | 2/2 Passed (ir-pass-lit 59.80 s, frontend-lit 3.86 s)                 | fix | 2026-09-15 09:26
lit ir-pass/test (full, counts)                      | fd310f80 | **2057 passed, 1 XFAIL, 0 failed of 2058**; 67.05 s (Track B: 2054/1 of 2055 — +3 fixtures) | fix | 2026-09-15 09:26
probe set, 43 probes, FOUR-way                       | fd310f80 | **2 movers SUBJ_B→BFIX**, both the P1 shape (`f01`, `i02`), both ACCEPT→DECLINE with the fence's own string; 36 of 38 reviewer+owner probes byte-identical in verdict AND string | fix | 2026-09-15 09:25
trace byte-compare SUBJ_B vs BFIX                    | fd310f80 | 17 probes accepting on both, **0 trace divergences** (`cmp`)          | fix | 2026-09-15 09:25
RE-ATTACK f10..f15 (6 shapes, 4-way)                 | fd310f80 | 0 new holes: f10/f11 caught by the PRE-EXISTING in-loop-invariant leg on SUBJ_B too; f12 (register twin) declines everywhere; f13/f14/f15 unchanged from SUBJ_B | fix | 2026-09-15 09:28
ALL 40 pre-existing railbank fixtures, SUBJ_B vs BFIX | fd310f80 | **0 movers**: identical exit code AND byte-identical lowered IR (accepts) / byte-identical stderr (declines) for every `railbank_*.ll` + `lowering_railbank_*.ll` except the 3 added here | fix | 2026-09-15 09:35
ctest -R '^e2e-(slice-)?railbank' -j2                 | fd310f80 | **8/8 pass**, 7.00 s                                                  | fix | 2026-09-15 09:34
BYTE IDENTITY bank(BFIX) vs register twin(ORACLE)    | fd310f80 | `f06`(BFIX) == `f07`(ORACLE) `cmp` empty, equal sha256 `b60ae0ac5df0b30b6192…`; `d03`(BFIX) == `d04`(ORACLE) `cmp` empty. **The legitimate orderings reproduce, on the FIXED compiler, the stream the ORACLE emits for the array-free program.** | fix | 2026-09-15 09:34
register-twin gate WITH `$CQ_LD` (as ctest runs it)  | fd310f80 | same 8 verdicts, 0 VIOLATION; 29.4 s → 22.6 s under load               | fix | 2026-09-15 09:33
register-twin SELFTEST with `$CQ_LD`                 | fd310f80 | 20 mutant(s), 0 NOT caught                                            | fix | 2026-09-15 09:33
L8 duplicate-body fixture scan (2058 fixtures)       | fd310f80 | 9 duplicate-body groups, **0 with contradictory verdicts**, **0 groups containing a NEW fixture** | fix | 2026-09-15 09:32
injection-matrix ANCHOR dry-run (15 mutants)         | n/a      | every mutant anchor occurs **exactly once** in its file — 0 `EDIT-FAILED` holes before the matrix is trusted | fix | 2026-09-15 09:31
SELF-CAUGHT VACUOUS NEGATIVE (and the re-run)        | fd310f80 | `NOTS-NOT: 3 x i8` in BOTH new green fixtures was **VACUOUS** — they are `int`-cell banks and `3 x i8` occurs 0× in the IR body and 0× in the output. Replaced by `cq_theta_`/`cq_measure_` (10 and 7 body lines of INPUT, 0 of output). Both fixtures re-run: 2/2 PASS. | fix | 2026-09-15 09:35
tests/e2e/CMakeLists.txt post-union checks           | n/a      | 0 duplicate `add_test` names; 442 `add_test` (440 + 2); `get_property` sweep still LAST | fix | 2026-09-15 09:28
```

three-way corpus sweep ORACLE|BASE|BFIX, 5635 inputs | fd310f80 | `DONE inputs=5635 rows=5606`, exit 0. **BASE→BFIX: 0 A→D**, 0 A→A md5 divergence, 41 D→A, 78 D→D. ORACLE vs BASE differing rows: 1 (Track A's own, pre-existing). | fix | 2026-09-15 09:42
ISOLATING **THIS FIX's** delta: SUBJ_B vs BFIX join   | fd310f80 | joined my sweep's ORACLE\|BFIX against Track B's `corpus_784c14fa05c16c50.txt` ORACLE\|SUBJ_B on 5557 COMMON rows. **ORACLE column disagrees on 0 of 5557** (which is what makes the join sound), and **SUBJ_B→BFIX movers: 0**. The fix's entire corpus delta is the **49 rows that did not exist** in Track B's sweep — its own fixtures and probes. | fix | 2026-09-15 09:43
CLOSING PROTOCOL S3's KNOWN BLIND SPOT               | fd310f80 | the shared tag regex renders some declines as an EMPTY `D:`, so a decline→decline string move inside one is INVISIBLE to the join above. All **136** empty-tag rows re-run through BOTH binaries on the SAME stage-1 module and compared on **exit code + FULL stderr bytes**: **0 real movers**. The one flagged row is `trackB/probes/derived/B10_classcond_deadphi_crash.ll`, which **ABORTS (exit 134) on BOTH** with a byte-identical message (`PHI node operands are not the same type as the result! %cq.bank = phi i1 [ %h, … ]`); the only differing bytes are the binary's own path inside LLVM's `Program arguments:` line. Pre-existing and already attributed by Track B's own sweep row (*"1 pre-existing hand-derived ABORT on BOTH binaries"*). | fix | 2026-09-15 09:44
REPRODUCIBILITY of the comment-only corrections      | fd310f80 | two source comments were corrected AFTER the gated build (a false "only forward user is the store" clause and an unclosed paren). Rebuilt BOTH targets; the objects re-compiled (09:43:52 > source 09:36:49) and `cq-opt` hashes **`fd310f80…` and `libCQPass.so` `53d8d055…` — BIT-IDENTICAL**. So the source on disk is exactly what every gate line above was measured on. | fix | 2026-09-15 09:44

injection matrix, 7 mutants (M1,M2,M10,M11–M14)      | fd310f80 | **7 mutations, MISSED 4** — `probes/injection_matrix_fd310f8037fb8f48.txt`. **M11 (the memory hop removed) CAUGHT** by the new RED fixture AND by the new twin gate (3 VIOLATIONS: p01/p05/p08). **M14 (the store-side cast strip dropped) CAUGHT** by 12 lit fixtures — the Rule-14 coupling made observable, since `bankStoreRailValue` also carries the `!cq.railbank` width. **M1 CAUGHT**, and BOTH NEW GREEN FIXTURES are among its catchers, so they add coverage for Track B's own core miscompile. MISSED: M2 + M10 (Track B's two, unchanged and justified) and M12 + M13 (this fix's, both DECLINE/over-decline direction — see below). | fix | 2026-09-15 09:50
injection matrix ANCHOR/RESTORE integrity            | fd310f80 | 0 `EDIT-FAILED`, 0 `BUILD-FAILED`; the restore build reproduced `cq-opt` `fd310f80…` and `libCQPass.so` `53d8d055…` **BIT-IDENTICALLY**, and `git status` shows every `ir-pass/` file matching the index — the matrix left no residue. | fix | 2026-09-15 09:51

## The FOUR MISSED mutants, named and dispositioned (never a bare count)

* **M2** — the `!cq.railbank` mint conjunct at `declineTaintEscapes`' `Bank` arm.
  Track B's, unchanged. Its *justification* was corrected by this fix (item I-6):
  the conjunct is kept because **dropping it fails SILENTLY while keeping it fails
  LOUDLY in the over-decline direction**, NOT because no stage in the window can
  manufacture a bank shape — which was an enumeration of stages, and L5's losing
  move. Still MISSED, still deliberate.
* **M10** — the type rewrite's half of the width fence. Track B's, unchanged, and
  L3's shape: the second spelling of a fence whose first spelling (D5) refuses the
  input first. Kept and reported rather than deleted.
* **M12 — THIS FIX'S**: the constant-seed filter in `railBankParkedRails`.
  Direction is SAFE (dropping it manufactures an OVER-DECLINE from a
  module-wide uniqued literal, never an accept), and MISSED is the measurement of
  how load-bearing it is on today's corpus: the only shape that reaches it is a
  whole-object zero `store iN 0`, and the modules that carry one have no
  same-typed `cq_theta` for the uniqued constant to walk into. ⚠ An `llvm.memset`
  initializer never reaches the filter at all (it is a `CallInst`, and the walk
  only takes `StoreInst`), so the memset fixture cannot pin it either.
* **M13 — THIS FIX'S**: the storage-`trunc` arm of the hop. MISSED because a
  `_Bool`-cell **STALE** bank is **not constructible at the `-O1` floor** —
  measured, not assumed: `clang` turns an invariant `_Bool` park into an
  `llvm.memset` and the module dies at `tainted value consumed by an unknown
  callee` on all four binaries (`bfix/probes/f08`, `f09`). The arm is exercised by
  the accepting `_Bool` banks but they cannot DISTINGUISH its presence. Kept, in
  the DECLINE direction, pinned by this mutant and by nothing else.

## The corpus sweep's INPUT SET, stated because a sweep is only its corpus

`bfix/probes/corpus3.sh` is Track B's `corpus.sh` with a THIRD column (ORACLE |
BASE | SUBJ) and every one of its guards kept — the non-empty input list, the
row count within 10% of it, and the trailing `DONE` line, which it earned by
lying once. Inputs enumerated by `find`, **5635** (Track B's sweep: 5586); the
**+49** are this fix's 3 new `ir-pass/test` fixtures and 43 `bfix/probes/*.c` plus
the three probes the fixtures were cut from, so the sweep DOES sample the
capability's new surface — which is the thing the review says a sweep over an
older corpus cannot do.

⚠ `tools/railbank_twin_pairs/*.c` is deliberately NOT in the sweep (it is not
under `inc1-records`). Those 16 programs are the register-twin gate's own corpus
and are measured by that gate, in PAIRS — which is the only form in which they
mean anything.

## An OBSERVATION that is not mine to act on

A `cq-opt` process (**PID 84129**, cwd `/Users/sorenwilkening/Desktop/CQ_T`,
started **2026-09-15 00:04:34**) has been running `-passes=cq-lowering` on
`…/trackT/probes/adv/out/b1_mixed_nonlive.sub.s1.ll` for **492 minutes of CPU**
at ~99% of one core. That is a **NON-TERMINATING `cq-lowering` invocation** — a
hang, not a decline, and not a shape any gate in the tree scores. It is **Track
T's**, it was **not touched** (CLAUDE.md: never `pkill` by pattern), and it is
recorded here for two reasons: it is a possible compiler defect in its own
right, and it has been distorting every `uptime` on this box since midnight, so
**no timing figure measured today is comparable with one measured on a quiet
box** (CLAUDE.md's own warning, in the other direction).

## NOT RUN, and why

```
full ctest -j6            | — | NOT the fix agent's (PROTOCOL S1: the merge-and-gate agent is the ONLY full-ctest runner)
ctest -j6 -R '^e2e-'      | — | same
cq-opt-equivalence-full   | — | OWED AT THE GROUP-1 GATE, and this increment ADDS to that debt: Track B added two decline strings, and this fix moves a THIRD string's population (`rotation/measure operand predates a non-diagonal gate` now reaches memory-resident readers)
twin matrices             | — | not owed: no in-loop CONTROL code landed
```
