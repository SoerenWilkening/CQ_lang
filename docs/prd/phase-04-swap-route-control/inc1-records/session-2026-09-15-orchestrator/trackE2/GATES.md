# Track E2 — GATES (hash-keyed; `PROTOCOL.md`'s non-redundancy protocol)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`

**A gate result is a fact about a BINARY, not about a moment.** Before running a gate, read this
file: if the hash is unchanged and the gate is recorded, CITE the line instead of re-running it.

## Binaries

| tag | `cq-opt` sha256 | `libCQPass.so` sha256 | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | `/Users/sorenwilkening/Desktop/CQ_lang/build`, frozen, read-only. Verified by this track at session start against `PROTOCOL.md` — MATCH. |
| BASELINE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | this worktree, `main` `74eabd2c`, BEFORE the E2 edit. ⚠ **BIT-IDENTICAL to the ORACLE**, which is itself a result: the RED measurements below were taken on a binary provably equal to the frozen one. |
| SUBJECT | `57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439` | `35fb4c26c1519cb185a5a1b683a93d0be4a95928f7035fc86c4619bd90ccf7ee` | this worktree WITH the E2 edit. |
| COUNTERFACTUAL | `94225756f5da18522dfac9ca6cfcd5722cae13e5cc0a8671e4702c8804c47bf4` | (not recorded; discarded) | ⚠ **NEVER COMMITTED.** The SUBJECT with ONE token changed — `RAUW(Handle)` instead of `RAUW(getNullValue(Measure->getType()))` — built only to MEASURE Track M's finding (2) rather than inherit it, then reverted. |

## Gates

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| ORACLE hash verify (`shasum -a 256`) | `0e280fc6` | both hashes MATCH `PROTOCOL.md` | impl | 2026-09-15 |
| build the worktree (`cmake --build build -j8`, BOTH targets) | `0e280fc6` | `BUILD0_OK`; `cq-opt` and `libCQPass.so` BIT-IDENTICAL to the ORACLE | impl | 2026-09-15 |
| E2 probe pipeline ×12 on the ORACLE (`probes/e2.sh … oracle`) | `0e280fc6` | 12 rows; all 12 reproduce Track M's table exactly (e2a/c/e/g/i/j/k **D** on the undef string; e2b/d/f/h/l **A**) | impl | 2026-09-15 |
| **RED** `lit -v ir-pass/test --filter 'measure_undef'` | `0e280fc6` | `Passed: 1, Failed: 2` — both accept fixtures FAIL on the exit code with `cq_measure_<sfx> operand is an undef/poison literal…`; the residual decline fixture PASSES | impl | 2026-09-15 |
| build the worktree WITH the edit (`cmake --build build -j8`) | `57e7420c` | built; `cq-opt` `57e7420c50ddf802…`, `libCQPass.so` `35fb4c26c1519cb1…` | impl | 2026-09-15 |
| **GREEN** `lit -v ir-pass/test --filter 'measure_undef'` | `57e7420c` | `Passed: 3` (`lowering_reject_measure_undef_operand.ll`, `lowering_reject_measure_undef_global_init.ll`, `lowering_accept_measure_undef_zero.ll`) | impl | 2026-09-15 |
| injection (mutation) matrix over the two new/inverted ACCEPTS | `57e7420c` | `injection matrix: 42 mutations over 2 fixtures, 0 MISSED, 0 HOLE(s)` (15 over the inverted fixture, 27 over the new one) | impl | 2026-09-15 |
| injection-matrix SELF-CHECK, no argument | `57e7420c` | exits **2** with `ERROR: no fixture given…` — it cannot print `0 mutations, 0 MISSED` | impl | 2026-09-15 |
| mutation validation of the RESIDUAL decline fixture (fixture-hygiene defect (c)) | `57e7420c` | base GREEN; mutant M1 (`{i32 1, i32 2}`) and mutant M2 (operand → whole-value `i32 undef`) each make the fixture's own RUN pipeline exit **1** — the subject EXISTS and is exactly the residual | impl | 2026-09-15 |
| **THE REFINEMENT MEASUREMENT** — fixtures + hand-IR probes + every C probe's stage-1 (`probes/refinement_check.py`, output committed as `probes/refinement_57e7420c.txt`) | `57e7420c` | `refinement: population 12 module(s) (6 outside the population), 12 BYTE-IDENTICAL, 0 DIVERGENCE(S), 0 SUBJ-DECLINE` | impl | 2026-09-15 |
| refinement-check SELF-CHECK, no argument | `57e7420c` | exits **2** with `ERROR: no module given…` | impl | 2026-09-15 |
| C-level twin, `e2g`(undef) SUBJECT vs `e2h`(written `= 0`) ORACLE | `57e7420c` | **traces byte-identical**, equal sha-256 `ea3c225a0aadc87e…`; lowered-IR instruction stream identical, differing only in `!dbg`/`DIFile` metadata (two different source files) | impl | 2026-09-15 |
| E2 probe pipeline ×16 on the SUBJECT | `57e7420c` | 6 rows move **D→A** (e2a, e2c, e2e, e2g, e2i, e2j); **4 rows stay D** on the unchanged string (e2k, e2m, e2o, e2p — every one with a `GlobalValue` in the operand's constant chain); e2n **A** (parser-folded); 5 controls unchanged **A** | impl | 2026-09-15 |
| ADVERSARIAL probe pipeline ×8, ORACLE then SUBJECT (`e2q`…`e2x`) | `0e280fc6` → `57e7420c` | 3 pairs move **D→A** with traces **byte-identical** to their written-zero twins (seed slot `ea3c225a0aadc87e`, angle slot `ad3599abb0a97556`, branch-condition `ea3c225a0aadc87e`); `e2w`/`e2x` **D→D unchanged** on `value-arm swap-route under quantum control` | impl | 2026-09-15 |
| **COUNTERFACTUAL** refinement check, `RAUW(Handle)` build (`probes/refinement_counterfactual_94225756.txt`) | `94225756` | `refinement: population 12 module(s) (6 outside the population), 0 BYTE-IDENTICAL, 12 DIVERGENCE(S), 0 SUBJ-DECLINE` — Track M's finding (2) reproduced and STRONGER than stated: the byte-identity claim is FALSE on **every** member, not merely on some | impl | 2026-09-15 |
| RESTORE the subject source + rebuild (`cmake --build build -j2`) | `57e7420c` | `cq-opt` `57e7420c…`, `libCQPass.so` `35fb4c26…` — **BIT-IDENTICAL to the gated SUBJECT**, so every gate line above stands; re-confirmed by `lit --filter 'measure_undef'` `Passed: 3` | impl | 2026-09-15 |
| corpus sweep ORACLE-vs-SUBJECT (`probes/corpus_E2.sh` → `probes/corpus_57e7420c50ddf802.txt`, read by `probes/analyze_corpus.sh` → `probes/corpus_analysis_57e7420c.txt`) | `57e7420c` | **4986 rows** (2041 fixtures + 2945 probe modules; 259 VACUOUS, 2 CLANGERR) — **24 movers, ALL `D→A`; 0 `A→D`; 0 `A→A` with a moved stream; 0 `D→D` with a moved string; 0 `A→A` with moved stderr.** Completeness PROVEN by set equality against the candidate list (`corpus_…NOTE.md`), not by a `DONE` line — the trailer was lost to a self-inflicted mid-run edit of the script. Attribution CLOSED by re-measuring all 24 movers individually with full stderr: `24 cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value`; all 24 SUBJECT stderr hashes are `e3b0c442` = the **empty file** (0 bytes, no warning) | impl | 2026-09-15 |
| `ctest --test-dir build -R ir-pass-lit` (ONCE at hand-off) | `57e7420c` | `1/1 Test #8: ir-pass-lit ...... Passed 104.02 sec` / `100% tests passed, 0 tests failed out of 1`. It wraps every `ir-pass/test/*.ll`; `ls ir-pass/test/*.ll \| wc -l` = **2041** on this tree, measured (⚠ not the 1994 CLAUDE.md records at `66428ddc` — re-measure, never quote; two of the 2041 are E2's new fixtures). ⚠ Run at load average **~268**, i.e. heavily contended — contention causes false FAILURES, never false passes, so a GREEN here is trustworthy as-is | impl | 2026-09-15 |

## NOT run by this track, and owed elsewhere

* **full `ctest -j6`** — the merge-and-gate agent's, once per landing (PROTOCOL S1). Not run here.
* **`ctest -j6 -R '^e2e-'`** — not run here. E2 adds no slice and no golden.
* **`cq-opt-equivalence-full`** — ⚠ **OWED AT THE GROUP GATE.** E2 **moves a decline string's
  population**: the string `cq_measure_<sfx> operand is an undef/poison literal; a classical
  measurement needs a defined value` keeps a strictly narrower customer set. PROTOCOL's matrix says
  the sweep is owed `iff a decline string / analysis site changed`, and one did.
* **twin matrices** — no in-loop code lands; not applicable.
* **duplicate-body fixture scan** — owed by the merge agent after any merge that renames fixtures.
  ⚠ E2 deliberately **renames nothing** (bd `gahu` / L8: a `git mv`'d fixture can be resurrected by
  a merge), so E2 contributes no rename to that scan.
