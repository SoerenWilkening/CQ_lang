# Track E2 FIX round — GATES (hash-keyed; `PROTOCOL.md`'s non-redundancy protocol)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date>`

**A gate result is a fact about a BINARY, not about a moment.** Every line below was either RUN by
this agent on the binary named, or CITED from `../trackE2/GATES.md` because the binary did not move.

## Binaries

| tag | `cq-opt` sha256 | `libCQPass.so` sha256 | what it is |
|---|---|---|---|
| ORACLE | `0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d` | `94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b` | `/Users/sorenwilkening/Desktop/CQ_lang/build`, frozen, read-only. **Verified by this agent** against `PROTOCOL.md` — MATCH. Never written to; used only to run probes and the new fixtures. |
| SUBJECT | `57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439` | `35fb4c26c1519cb185a5a1b683a93d0be4a95928f7035fc86c4619bd90ccf7ee` | Track E2's gated binary (`fve8-undef-measure` `8eed7a2d`). |
| **FIX** | `57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439` | `35fb4c26c1519cb185a5a1b683a93d0be4a95928f7035fc86c4619bd90ccf7ee` | this worktree WITH the fix. ⚠ **BIT-IDENTICAL to the SUBJECT** — the round is comments + fixtures + records, and that is measured (see the rebuild line below), not asserted. |

## Gates RUN by this agent

| gate | hash16 | result verbatim | who | when |
|---|---|---|---|---|
| ORACLE hash verify (`shasum -a 256`) | `0e280fc6` | both hashes MATCH `PROTOCOL.md` and `../trackE2/GATES.md` | fix | 2026-09-15 |
| build the worktree, BOTH targets (`cmake -S . -B build -DLLVM_DIR=… -DCMAKE_BUILD_TYPE=Release && cmake --build build -j2 --target CQPass cq-opt`) | `57e7420c` | `BUILD0_OK`; `cq-opt` `57e7420c50ddf802…`, `libCQPass.so` `35fb4c26c1519cb1…` | fix | 2026-09-15 |
| **rebuild AFTER the comment edits** (`cmake --build build -j2 --target CQPass cq-opt`) | `57e7420c` | exit 0; the log's only two `Building CXX` lines are `MeasureLowering.cpp.o` and `CQLoweringPass.cpp.o` (the header's includer), `libCQPass.so` relinked; **both hashes UNCHANGED ⇒ BIT-IDENTICAL to the gated SUBJECT** | fix | 2026-09-15 |
| `lit -v ir-pass/test --filter 'measure_undef\|taint_fold'` | `57e7420c` | `Passed: 5` of 5 selected — `lowering_reject_measure_undef_operand.ll`, `lowering_measure_taint_fold_control.ll`, `lowering_measure_undef_operand_after_taint_fold.ll`, `lowering_reject_measure_undef_global_init.ll`, `lowering_accept_measure_undef_zero.ll`. `Total Discovered Tests: 2043` (2041 + the 2 new) | fix | 2026-09-15 |
| the two NEW fixtures on the **ORACLE** (red-green) | `0e280fc6` | `lowering_measure_undef_operand_after_taint_fold.ll`: **exit=1, stdout 0 bytes**, `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value` — **RED there, on the exit code**. `lowering_measure_taint_fold_control.ll`: **exit=0**, 0 B stderr, and **all three of its prefixes GREEN on the oracle too** | fix | 2026-09-15 |
| control fixture's lowered module, ORACLE vs FIX | `0e280fc6` → `57e7420c` | `cmp` clean — **byte-identical under both binaries** (same input file, so `; ModuleID` is fixed) | fix | 2026-09-15 |
| **mutation validation of the new PAIR** (`probes/mutation_pair_check.sh build`) | `57e7420c` | `mutation pair check: 2 mutants, both CAUGHT, 0 MISSED; boundary controls green` — boundary 7/7 green; MUTANT of A: `CHECK` 1, `NOMEASURE` 1 (`COUNT`/`NOINTR` 0, correctly); MUTANT of B: `CHECK` 1, `COUNT` 1 | fix | 2026-09-15 |
| mutation-harness SELF-CHECK, no argument | `57e7420c` | exits **2** with `ERROR: no build dir given (a vacuous run is a HOLE, not a pass)` | fix | 2026-09-15 |
| ⚠ mutation-harness **self-inflicted L10**, recorded not hidden | `57e7420c` | the FIRST spelling reported **7/7 green including both mutants** because it read `$?` after an assignment inside `if … then CMD; lbl=…; fi`. Corrected: `$?` is read immediately after the command, plus a boundary control on every invocation | fix | 2026-09-15 |
| duplicate-body scan over `ir-pass/test/*.ll` (L8), with each group's CLAIMED VERDICT read off its RUN lines | `57e7420c` | **2043 fixtures, 9 duplicate-body groups, `mixed=0`** — no group mixes an ACCEPT with a DECLINE. Both new fixtures have **unique** body hashes (`23bd97a6…`, `794f1005…`). ⚠ This normalisation strips **every** `;` line, so it is COARSER than the merge gate's four normalisations and its 9 groups are not comparable to that gate's number; what it establishes is the mixed-verdict property and the uniqueness of the two additions | fix | 2026-09-15 |
| ⚠ scan harness **self-inflicted L10 #2**, recorded | `57e7420c` | the first spelling ran under **zsh**, where an unquoted `$files` does **not** word-split, so the inner loop ran ONCE per group with a multi-line filename, every `grep` missed, and it printed `verdicts=A` for **all nine groups** — including five that are `DD`. Re-run under `bash` with `while read -r`; the numbers above are the bash run's | fix | 2026-09-15 |
| **pre-existence re-measurement** (Rule 11; stage 1 `clang -Iinclude -include CQ.h -O1 -g`, stage 2 on both binaries, over `review_r13_e2/probes/src/y1,y1b,y2,y3`) | `0e280fc6` → `57e7420c` | ORACLE: `y1` (`q+u`) **exit 1** (290 B stderr); `y2` (`q*u`) and `y3` (`q&u`) **exit 0, 0 B stderr**, stream `cqrt_alloc_i32(0); cqrt_ry_i32(…,0.3)` — **no measure**; `y1b` (`= 0`) exit 0 with `cqrt_measure_i32`. FIX binary: `y1` joins `y2`/`y3` with the **identical** 2-gate stream; `y2`/`y3`/`y1b` unchanged. **The class pre-exists at HEAD, measured here** | fix | 2026-09-15 |

## Gates CITED (binary unchanged ⇒ `PROTOCOL.md` says cite, do not re-run)

All from `../trackE2/GATES.md` at `57e7420c`, the hash this worktree's binary still has:

* `ctest --test-dir build -R ir-pass-lit` — `Passed 104.02 sec`, `100% tests passed, 0 tests failed out of 1`.
  ⚠ **That run covered 2041 fixtures; this round ADDS 2** (both `lit --filter`-green above, both
  additive, neither renaming or editing an existing fixture's RUN lines). The next full
  `ir-pass-lit` — the merge-and-gate agent's — is the first one that wraps 2043.
* corpus sweep ORACLE-vs-SUBJECT — `4986 rows, 24 movers, ALL D→A; 0 A→D; 0 A→A with a moved stream;
  0 D→D with a moved string; 0 A→A with moved stderr`.
* the refinement measurement — `population 12 module(s), 12 BYTE-IDENTICAL, 0 DIVERGENCE(S), 0 SUBJ-DECLINE`
  (⚠ read it with `FIX.md` §1.1's instrument warning: it **cannot see** rival 2).
* the injection matrix over E2's two accepts — `42 mutations over 2 fixtures, 0 MISSED, 0 HOLE(s)`.
* the C-level twin `e2g`/`e2h` — traces byte-identical, `ea3c225a0aadc87e…`.

## NOT run by this agent, and owed elsewhere

* **full `ctest -j6`** — the merge-and-gate agent's, once per landing (PROTOCOL S1). Not run here.
* **`ctest -j6 -R '^e2e-'`** — not run. No slice, no golden, and the review measured the e2e layer
  immobile (409/409).
* **`ctest -R ir-pass-lit`** — deliberately NOT re-run: the binary is bit-identical to the gated one
  and the brief scopes it to "only if your binary is not bit-identical". The two new fixtures were
  run under `lit --filter`.
* **`cq-opt-equivalence-full`** — ⚠ **STILL OWED AT THE GROUP GATE.** E2 moved the population of the
  decline string `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs
  a defined value`. This round moved **no** string and **no** predicate, so the obligation is
  unchanged, not discharged.
* **corpus sweep on the fix** — not re-run: same binary, so `../trackE2/GATES.md`'s sweep line is a
  fact about this binary too.
* **duplicate-body fixture scan** — this round renames nothing (bd `gahu` / L8) and adds two
  fixtures whose bodies differ from each other by one token and from every other fixture in the
  tree.
