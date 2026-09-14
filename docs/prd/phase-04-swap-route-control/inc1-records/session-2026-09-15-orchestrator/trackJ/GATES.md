# GATES — Track J (instruments), session 2026-09-15

Format (PROTOCOL): `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

⚠ **This worktree's `cq-opt` is BIT-IDENTICAL to the session ORACLE** — `0e280fc62a91cec2…`
— because Track J edits no pass source. Verified at build, after the `-j2` rebuild, and again
at hand-off. The ORACLE itself was never rebuilt or written to.

⚠ **LOAD.** Per the orchestrator's 2026-09-15 note, load is recorded with every gate and
**an unfinished gate is an ABSENCE, not a green.** One gate was stopped as an absence and is
recorded as such below. The box reached load **394** during this session; it was **3.5–13**
for every gate that produced a number.

---

## Build

```
build the worktree (cmake --build build -j8) | 0e280fc62a91cec2 | exit 0; cq-opt sha256 == ORACLE, libCQPass.so sha256 == ORACLE | J | 2026-09-14 23:5x (load ~1, before the spike)
rebuild after the CMakeLists edit (cmake --build build -j2) | 0e280fc62a91cec2 | exit 0, "Built target …" only; cq-opt sha256 UNCHANGED | J | 2026-09-15 00:52 (load 3.65)
```

## ctest — the entries that wrap this track's tools

```
ctest -R 'free-pairing|selftest|census-sync|keepset|vacuity' | 0e280fc62a91cec2 | 100% tests passed, 0 tests failed out of 6 (runtime_link_smoke_selftest 2.54s, runtime_core_abi_link_selftest 0.54s, e2e-free-pairing-selftest 0.67s, e2e-loop-twin-quarantine-selftest 0.29s, e2e-keepset-vendor-check 0.89s, e2e-negative-vacuity-selftest 5.01s) | J | 2026-09-15 00:52 (load 3.55)
ctest -R 'census-slice-sync|fixture-guard-liveness' | 0e280fc62a91cec2 | 100% tests passed, 0 tests failed out of 2 | J | 2026-09-15 00:53 (load ~4)
ctest -R '^e2e-slice-(control-cascade-three-bools|libm-real-log1pl)$' | 0e280fc62a91cec2 | 100% tests passed, 0 tests failed out of 2 | J | 2026-09-15 00:53 (load ~4)
ctest -R '^e2e-slice-loop-break' | 0e280fc62a91cec2 | 100% tests passed, 0 tests failed out of 4 (the four --allow-unproven slices) | J | 2026-09-15 00:54 (load ~4)
```

**NOT RUN, by the protocol matrix: the full `ctest -j6`, `^e2e-`, and `cq-opt-equivalence-full`.**
The merge-and-gate agent is the only full-suite runner. **This track moved no decline string
and no analysis site** (nothing under `ir-pass/`), so the equivalence sweep is not owed on
its account.

## Instrument selftests

```
python3 tools/free_pairing_check_test.py | 0e280fc62a91cec2 | 30 positive fixture(s), 2 free-order pair(s), 1 cost bound(s), 77 named mutant(s), 10 memory mutant(s)/refusal(s), 5 Case-A negative(s), 19 census case(s), 315 proof-targeted mutant(s) (4 exempt by rule), 0 failure(s) | J | 2026-09-15 00:4x (load ~13)
python3 tools/negative_vacuity_check_test.py | 0e280fc62a91cec2 | 6 hole case(s), 4 positive(s), 10 mutant(s)/control(s), 0 failure(s) | J | 2026-09-15 00:4x (load ~13)
python3 probes/killtest_free_pairing.py | 0e280fc62a91cec2 | BASELINE green; 14 mutations, 14 RED, "KILL TESTS THAT DID NOT GO RED: none" | J | 2026-09-15 00:5x (load ~4)
```

## Measurements (facts about the ORACLE binary)

```
blast radius, old vs new free_pairing_check over 368 lowered e2e modules | 0e280fc62a91cec2 | EXIT-CODE MOVERS (verdict-surface change): 0 ; alloc-census movers (rixk reachability): 162 | J | 2026-09-15 00:0x (load ~1; see the note below)
negative_vacuity_check over ir-pass/test/*.ll | 0e280fc62a91cec2 | 2039 fixture(s), 6734 directive(s) evaluated, 0 VACUOUS, 18 decline-stdout note(s), 33 latent header collision(s), 1033 declining module(s), 0 unparsed, 1 not-modelled (compiler input is not %s), 466 front-end-intrinsic exemption(s), 749 unreachable-symbol note(s), 155 on an unmodelled stream, 2393 resolved by the universe, 0 undecidable, universe 1005 module(s) — exit 0 | J | 2026-09-15 00:49 (load 4.37)
census_of over the 368 lowered e2e modules | 0e280fc62a91cec2 | alloc rail mint sites 29969 (left allocated 3787); template rail mint sites 37662 (left dirty 5048, in 154 modules); call-graph-unresolved modules 0 | J | 2026-09-15 00:3x (load ~10)
census_03_orphan_rails.py (INDEPENDENT cross-check, trace layer) | n/a (reads goldens, not the binary) | goldens scanned 383; template/qram rails never DISCHARGED 5046 in 155 goldens | J | 2026-09-15 00:1x (load ~1)
fp_m28 / fp_x5b on the ORACLE | 0e280fc62a91cec2 | m28: opt 0, 29 lines, "8 rail mint(s) of which 6 left allocated, 1 template rail mint(s) of which 1 left dirty, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven"; x5b: opt 0, 28 lines, same 2b line; trace diff = the prep spelling ONLY, downstream BYTE-IDENTICAL | J | 2026-09-15 00:2x (load ~10)
slice_control_select_{bool,cmp}_round2_window.c after the F-6 fix | 0e280fc62a91cec2 | clang -fsyntax-only clean (both); both still decline with "cq opcode lowering: rotation/measure operand predates a non-diagonal gate" | J | 2026-09-15 00:3x (load ~10)
```

⚠ **ON THE BLAST-RADIUS MEASUREMENT AND LOAD.** The orchestrator's note is right that a
blast radius taken under contention and reported as a fact is this track's own failure mode.
Stated precisely: **this sweep is load-insensitive by construction.** It is a pure-Python
comparison of two versions of `free_pairing_check.py` over 368 **pre-lowered** `.ll` files —
it spawns no compiler, measures no time, and is a deterministic function of its inputs. It
**completed**, with a full count of all 368 modules, at a load of roughly 1. It is
reproducible by anyone from the committed checker and `git show HEAD:tools/free_pairing_check.py`.
The one thing load could have done — truncate it — did not happen, and the count is the proof.

---

## ABSENCES (a gate that did not finish is not a green)

```
negative_vacuity_check over ir-pass/test/*.ll, FIRST attempt | 0e280fc62a91cec2 | STOPPED after ~20 min with no output, started at load 394 (nice 19) | J | 2026-09-15 00:27–00:42
```
⚠ It was stopped deliberately (by task id, never `pkill` by pattern) for a **second** reason
that outranks the load: **the tool changed under it**, so its result would have been a fact
about a binary and a tool that no longer existed. It is recorded as an absence, and the
definitive run above replaces it. Two earlier corpus runs of intermediate versions
(`vac2`/`vac3`/`vac4`) are superseded and **must not be cited** — their numbers (1118 / 1116
VACUOUS) are the fabricated-finding classes described in `MUTANTS.md` §4, not findings.

---

## Not run, and why

* **Full `ctest -j6`** — merge-and-gate's, once per landing (PROTOCOL matrix).
* **`cq-opt-equivalence-full`** — owed only if a decline string or analysis site moved. None did.
* **The twin matrices** — owed only if in-loop code lands. None did. ⚠ `tools/loop_twin_matrix.py`
  is TRACK I's file and was not touched.
* **An injection matrix** — owed over NEW ACCEPT FIXTURES. This track added no `.ll` fixture to
  `ir-pass/test`; its subjects are Python instruments, and their equivalent is the kill-test
  table above.
