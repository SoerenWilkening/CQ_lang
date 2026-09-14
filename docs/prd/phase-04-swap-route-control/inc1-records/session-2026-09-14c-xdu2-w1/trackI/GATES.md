# Track I — GATES

`PROTOCOL.md` format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <date time>`.

⚠ **ADAPTATION, stated rather than assumed.** Track I builds nothing and edits no pass source; both of
its gates are **pure python over lowered IR**. A gate result is a fact about an ARTEFACT, so the hash
column carries the artefact the gate actually depended on:

* rows measuring the **checker** carry `tools/free_pairing_check.py`'s own sha256 (first 16) — the
  binary equivalent for a python gate, and the thing that would make a cited line stale;
* rows measuring **lowered IR** carry the **frozen ORACLE** `build/ir-pass/cq-opt` sha256 (first 16),
  `5c6f7490a81c7505`, verified with `shasum -a 256` before use. `libCQPass.so` on that tree is
  `5276f7ab7416b36b`.

⚠ `PROTOCOL.md`'s own header names the PREVIOUS session's oracle
(`f7b65d8ccd7bc472…`). The binary on disk and the one `BRIEF_I.md` names is `5c6f7490…`. The briefs
are right; the copied protocol header is stale. **Do not "STOP and report" a rebuild that did not
happen** — see `IMPL_I.md` §6(b).

Artefact hashes used below:

| artefact | sha256 (first 16) |
|---|---|
| `build/ir-pass/cq-opt` (frozen ORACLE, read-only, primary checkout) | `5c6f7490a81c7505` |
| `tools/free_pairing_check.py` at `HEAD` (`c8007c37`) — the BEFORE | `98b83e8171d6815b` |
| `tools/free_pairing_check.py`, subject (FINAL) | `bf8c61e9de037220` |
| `tools/free_pairing_check_test.py`, subject (FINAL) | `9ff63319aa909720` |

---

| gate | artefact | result verbatim | who | when |
|---|---|---|---|---|
| `python3 tools/free_pairing_check_test.py` (= ctest `e2e-free-pairing-selftest`, `tests/e2e/CMakeLists.txt:4122-4123`) — BASELINE | `98b83e8171d6815b` | `free_pairing_check_test: 26 positive fixture(s), 2 free-order pair(s), 1 cost bound(s), 69 named mutant(s), 5 Case-A negative(s), 313 proof-targeted mutant(s) (2 exempt by rule), 0 failure(s)` — exit 0 | trackI | 2026-09-14 17:02 |
| `python3 tools/free_pairing_check_test.py` — SUBJECT | `9ff63319aa909720` | `free_pairing_check_test: 30 positive fixture(s), 2 free-order pair(s), 1 cost bound(s), 69 named mutant(s), 10 memory mutant(s)/refusal(s), 5 Case-A negative(s), 315 proof-targeted mutant(s) (4 exempt by rule), 0 failure(s)` — exit 0 | trackI | 2026-09-14 18:29 |
| `python3 $SES/trackI/probes/armkill.py` — the arm-kill demonstration | `bf8c61e9de037220` | `armkill: 10 mutation(s), 0 SURVIVED, 1 exempt with a written reason, 0 malformed (a survivor is a HOLE, not a pass)` — exit 0; per-arm catches L1→3, L2→2, L3→4, rail_defs-fold→1, marker-read→10, global-marker→1, resolve_object→1, over-fire-all-loads→1, over-fire-drop-measure→4 | trackI | 2026-09-14 18:29 |
| bd `21re` SUBJECTS, pre-fix (`python3 tools/free_pairing_check.py --explain probes/p{1,2}*.ll`) | `98b83e8171d6815b` / oracle `5c6f7490a81c7505` | `p1: OK @slice line 29 [%r] via A1-classical-immediate` exit 0; `p2: OK @slice line 32 [%o] via A2-reduces-to-identity` exit 0 | trackI | 2026-09-14 17:18 |
| bd `21re` SUBJECTS, post-fix (same command) | `bf8c61e9de037220` | `p1` exit 1 `A1-imm-not-classical`; `p2` exit 1 `L3-bank-rail-in-a-modelled-rail-slot`; `p5` exit 1 `L1-rail-stored-to-unmarked-memory`; `p6` exit 1 `L2-undecidable-load-provenance`; `p3`/`p4` exit 0 `1 verified` UNCHANGED | trackI | 2026-09-14 18:05 |
| **corpus 368 before-vs-after (subprocess: exit code + summary line)** — every single-file `tests/e2e/*.c` lowered by the ORACLE (`clang -O1 -emit-llvm -S`, no `-g`, then `cq-opt`), both checkers run with `--allow-unproven` | `98b83e8171d6815b` vs subject / oracle `5c6f7490a81c7505` | `368 rows / 368 rows`, `diff` empty — **IDENTICAL: 0 rows moved**. Sweep census: `lowered=368 declined=21 stage1fail=20`. ⚠ This row was measured against an INTERMEDIATE checker (`0cf25b28…`, docstring-only difference); the authoritative zero-regression row is the next one, re-run against the FINAL file | trackI | 2026-09-14 18:22 |
| **corpus 368 before-vs-after (in-process: mint/leak/sites/verified/violations/unproven + the SET of finding codes)** — the finer instrument; a finding whose CODE moved but whose counts did not is invisible to the row above | `98b83e8171d6815b` vs `bf8c61e9de037220` / oracle `5c6f7490a81c7505` | `368 / 368`, `diff` empty — **IDENTICAL — 0 rows moved (FINAL file)**. Rows committed at `probes/corpus368_{before_98b83e81,after}.txt`; re-runnable with `probes/sweep_s2.sh` + `probes/fastsweep.py` | trackI | 2026-09-14 18:28 |
| L-1a design target unchanged: `python3 tools/free_pairing_check.py $SESP/trackL/probes/TARGET_rolled_stage2{,_mloop}.ll` | `bf8c61e9de037220` | both `1 file(s), 4 rail mint(s) of which 3 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`, exit 0 — **byte-identical to the pre-fix result** | trackI | 2026-09-14 18:20 |
| cost: largest module (`slice_libm_real_lgamma.s2.ll`, 15 420 lines) | `98b83e8171d6815b` vs `bf8c61e9de037220` | `1,68s user` before, `1,68s user` after — no measurable change | trackI | 2026-09-14 18:12 |
| downstream consumer unbroken: `census_common.parse_lowered` (the only other in-tree caller of `fpc.parse_module`) | `bf8c61e9de037220` | `parse_lowered OK, returns <class 'tuple'> 2` | trackI | 2026-09-14 18:18 |
| witness probe: `w1_flat_prep_only.c` through the full pipeline (stage 1 → ORACLE → 2b → link → run) | oracle `5c6f7490a81c7505` | ACCEPT, 55 lowered lines; 2b `6 rail mint(s) of which 6 left allocated, 0 cqrt_free site(s): 0 verified`; trace = 3×(`cqrt_alloc_i1(0)`,`cqrt_ry_i1(h,0x1p-1)`) + 3×`cqrt_measure_i1` | trackI | 2026-09-14 18:00 |
| witness probe: `w1_bank_prep_only.c` / `..._k1000.c` stage-1 K-independence | oracle `5c6f7490a81c7505` | both **114 stage-1 lines**, both carry `llvm.loop.unroll.disable`; both DECLINE `cq taint escape: tainted value stored to memory` | trackI | 2026-09-14 18:00 |
| Rule-11 re-measure of `SCOPE_L1a` §7/§9: `a_flat_n2`, `a_flat_n3`, `L13_flat_n2_opaque_noinline` | oracle `5c6f7490a81c7505` | `a_flat_n2` **ACCEPT** (76 lines); `a_flat_n3` **ACCEPT** (98 lines) — ⚠ SCOPE_L1a records this as a DECLINE and is **STALE**; `L13` DECLINE `cq controlled lowering: control flow under quantum control` — unchanged | trackI | 2026-09-14 18:16 |

---

## NOT RUN, and why (Rule 19 — report only what you ran)

Per `BRIEF_I.md`'s gate row and `PROTOCOL.md`'s matrix, Track I ran **none** of:

* `cmake --build build` — no build exists in this worktree and none was needed. Every lowered module
  came from the frozen ORACLE in the primary checkout, which was **read, never written**.
* the full `ctest -j6`, `ctest -R '^e2e-'`, `ctest -R ir-pass-lit` — Track I touches no pass source,
  no fixture under `ir-pass/test/`, and no `.expected.log`.
* `cq-opt-equivalence-full` — no diagnostic string and no analysis site in the pass moved.
* the twin matrices — no in-loop code landed.
* `ctest -R 'e2e-free-pairing-selftest'` **as a ctest entry** — it needs a configured build dir; the
  entry is `"${_E2E_PYTHON}" "${CMAKE_SOURCE_DIR}/tools/free_pairing_check_test.py"` verbatim
  (`tests/e2e/CMakeLists.txt:4122-4123`) and was run directly as `python3
  tools/free_pairing_check_test.py`. **Say it that way, not "ctest green".**
* the multi-file e2e slices (`run_slice_multi.sh`) are not in the 368 — they produce no single
  stage-2 module through `sweep_s2.sh` and are counted among the 20 stage-1 failures.
