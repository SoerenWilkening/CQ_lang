# Track 9BHG — bd `test_C_libtooling-9bhg`: a function that returns a specialization-classical call result

Session 2026-09-25, parallel session (bd `xdu2.16` runs in another worktree; this
track does not touch `LoopLowering.cpp`). Worktree branch
`worktree-agent-a50057998e957b90e`, based on `983f9361`.

Binaries (sha-256 prefixes):
- ORACLE `983f9361`: `cq-opt` `438c77bf45c02e3e`. The worktree's own first build
  was bit-identical to it (a build null control that fired).
- preE `aad63450` (before bd 3jru/l3oi): `cq-opt` `63e2f0bbd3708c92`, built from a
  `git archive` in the scratchpad. It is the "pre-3jru compiler" every header cites.
- SUBJECT (final): `cq-opt` `8b837d1f79574156`, `libCQPass.so` `3dc6bc062a834b60`.
  Two earlier subjects appear below: `6b8bebc793940ec5` (before the early-skip
  premise conjunct) and `98b921fb96136cbd` (before the old-site pointer scrub,
  §3 item 6). Every final number in §5 and §9 is on `8b837d1f`.

Probes, the mutation harness and the sweep scripts are in `probes/` next to this
file. ~~No Rule-13 round has run on this change.~~ **Two rounds ran on `30529716`,
both NOT-CLEAR, each on a pre-existing P1 that 9bhg exposes to more programs:**
- `review_r1A_9bhg/`: bd `d88e`, FIXED on `main`;
- `review_r1B_9bhg/`: bd `8e5r`, fix pending.

Both rounds found 9bhg's own logic sound and its route deviation justified. §10 is
the post-merge state.

## 0. ERRATA (2026-09-26, from rounds r1A/r1B — read before §1)

The commit message of `30529716` cannot change, so this section corrects it and the
record.

- **"an over-decline of programs aad63450 compiled correctly" (commit message) is
  TRUE OF THE CALLER ONLY** (r1A F-9A-2).
  - preE is not a correctness oracle. It MISCOMPILES `l09C`/`l10C` in the
    provisional function's OWN body: the one-register lift runs on the
    conservative taint, `specialize()` then scrubs its base, and the user's
    `cq_measure` vanishes (bd `d88e`). `30529716` reproduced that byte for byte.
  - Matching preE's stream is STABILITY across binaries, not correctness. That is
    the `*_leak_control` trap in CLAUDE.md §5.
  - With `main` (d88e) merged, `l09C`/`l10C` DECLINE with their hand-inlined twin's
    stderr, byte-identical (§10).
- **§1's "byte-identical to preE (16 of 16), which compiled them correctly".** The 16
  streams are correct, but that was established by reading them, and on the merged
  tree by twin comparison (§10). The preE identity is not the evidence.
- **§2's last row ("accept, preE's stream") and its prose ("the window's stages see
  the caller exactly as preE did")** hold for the CALLER. They do not hold for the
  provisional function's own body. Every window stage still runs there on the
  conservative taint:
  - the over-accept face is bd `d88e`, fixed on `main`;
  - the over-decline face is bd `cepm`.
- **"before anything lowers" (§2 prose, `CondLiteral.{h,cpp}`) and "before any
  lowering stage" (§4 S1) are FALSE** (r1A F-9A-4). By the late ask:
  - round-1 and round-2 control emission have ALREADY emitted gates, including a
    `_hl` literal taken from a provisional call result;
  - so have `lowerIOSinks`, `lowerQramReads`, `lowerShadowMemory` and the clone
    lowering inside `specialize()`.

  What IS true: it runs before `lowerRotations`, `lowerOps`, `lowerMeasures` and
  `uncompute`, and before any output is written. Its `DS_Error` exits the process
  (bd `br4a`), so nothing emitted earlier reaches the output. Corrected at the
  source in the same change as this erratum.
- **"I did not construct a case where that aliasing miscompiles" (§1, §3 item 6,
  §7 item 6).** r1B F-9B-1 CONSTRUCTED it.
  - `k65` is pre-existing, miscompiled on the oracle 28/30 runs.
  - `w12`, `w9` and `w15` are 9bhg's population: the oracle declines them, and the
    subject miscompiles them in 7–11 of 12 runs.
  - The fix is bd `8e5r`. Per the coordinator, the source comment's "closed here at
    its source" and the `retargetSite` old-site scrub stay untouched until the
    8e5r merge, which will delete that scrub (r1B F-EB-9).
- **§5 M18 is a FLAKY KILL, not a miss** (r1B F-9B-3): killed 3/5 under the system
  allocator and 5/5 under a deterministic LIFO allocator. The fp3 fixture is a
  flaky pin. "Did not recur on the mutant build" was one unlucky run, not a build
  difference.
- **§5's mutation table missed two unpinned conjuncts** (r1A F-9A-3). MRED is the
  drain's re-decision of deferred functions after a crossing batch. MNOREASK is
  the early slot's predicate re-ask. Both are MISSED, and both move a slot or an
  owner only, because the late ask is total (added to §5).
- **`probes/ab_sweep.py --null` ran the REFERENCE twice**, although its docstring
  said the SUBJECT (r1B F-9B-5). With a subject whose verdicts vary from run to run
  (F-9B-1), a reference-only null control cannot see that. Fixed: it now runs BOTH
  twice and refuses to report if either differs. Every sweep in §5 that cited
  "null 0" measured the reference's stability only. The §10 battery runs every
  binary twice.

## 1. Headline

- **The over-decline is removed for the whole class, not only for its first
  exhibit.** A function returning `t = h(q, m)`, where `h`'s clone proves the
  classical `k + 1`, compiles again, and so do its callers that BRANCH on it,
  SELECT on it, STORE it, PRINT it, pass it to ANOTHER defined function, use it as
  a LOOP bound, or chain it through a second function. Every one of those accepted
  probes is **byte-identical to preE** (16 of 16). ⚠ That is STABILITY, not the
  correctness evidence (§0): preE also miscompiles `l09C`.
- **The route is NOT the bead's literal route, and §2 says why.** The bead said:
  make `scrubForwardCone` cross returns, then move the 3jru refusal after the scrub.
  That route leaves the conservative taint IN THE CALLER through control emission,
  so `if (f(m) > n)` in `main` has its flag minted on the call result as a HANDLE in
  round 1. The scrub then either misses it (bd l3oi one boundary out, a silent
  miscompile) or, if the scrub crosses returns and feeds l3oi's record, declines it
  at l3oi's fence — an over-decline of a program preE got right. This change instead
  never lets SPECIALIZATION-PROVISIONAL taint cross a return, and re-asks the 3jru
  refusal after `specialize()`, TOTALLY.
- **The ordered scrub landed too** (the bead's second half): `specialize()` scrubs
  each top-level site as it resolves and recomputes each later site's mask before
  building it. bd l3oi F-R7-1's reproducers `ya` (`u = g(t)`) and `yb`
  (`u = g2(t, q)`) now ACCEPT with the correct stream. `yc` (`if (g(t) > 3)`) still
  declines at l3oi's fence: its gate is minted in round 1 (§6).
- **What still declines, and must:** a provisional return whose clone proves it
  QUANTUM (`h(a, k) = a + k`) is refused by the late re-ask with the 3jru string —
  the 3jru miscompile (preE deleted `cq_measure(f(m))`, measured) stays closed.
- ⚠ **The new late re-ask exposed a PRE-EXISTING dangling key, and it is fixed at
  its source (§3 item 6).**
  - `specialize()` REBUILDS a top-level call whose clone has an fp return (the
    call is ERASED), and it never removed the old pointer from `taint.Tainted`.
    The inner-call path in `buildClone` always did.
  - On subject `98b921fb` a LATER clone's `ret` value was allocated at the freed
    address. The re-ask read it as "tainted" and refused a correct module
    (probe `fp3`).
  - The oracle never asked anything of a clone's return after `specialize()`, so
    the key had no observable consumer there. `lowerOps(M, …, taint)` reads the
    same set by pointer, and I did not construct a case where that aliasing
    miscompiles. ⚠ **r1B F-9B-1 did** (§0, bd `8e5r`).
  - The witness depends on the allocator. ~~The M18 mutant build does NOT reproduce
    it (§5).~~ It is flaky from run to run, not a property of the build: M18 is
    killed 3/5 (§0, r1B F-9B-3).

## 2. Why not the bead's route (the L1 analysis)

bd 3jru's closure put taint on a call result whenever the callee's `ret` was tainted.
For a return whose only taint source is a Phase-6 specialization site, that taint is
an ASSUMPTION ("the clone returns a register") that `specialize()` checks only after
both control-detection rounds, every re-ask, and every guard. Four ways to handle
the window, measured or argued:

| route | caller during the window | verdict classical | verdict quantum |
|---|---|---|---|
| 983f9361 (3jru) | tainted | refused early (OVER-DECLINE, this bead) | refused early |
| move refusal only (mutant **M1**) | tainted, gates minted on the handle | **SILENT MISCOMPILE** (`mul_i32_hl(r, n)` over a classical call result — the M1 kills in §5) | refused late |
| bead route: scrub crosses returns + move (ARGUED, not built) | tainted, gates minted on the handle | decline at l3oi's fence for any caller whose round-1 emitters read it (a branch or select on it; also an IO/QRAM/Shadow lowering of it), and the store/mux guards' declines on the conservative taint — over-declines of what preE got right. Plain arithmetic is lowered after the scrub and would be fine | refused late |
| **this change** | classical (as preE) | accept; the CALLER's stream is preE's (⚠ the provisional function's OWN body is not covered by this row — §0, bd `d88e`) | refused late |

The last row is sound FOR THE CALLER. The classical reading in the window is right
exactly when the verdict is classical. When the verdict is quantum, the whole module
is refused before `lowerRotations`, `lowerOps`, `lowerMeasures` and `uncompute`, and
before any output is written (⚠ NOT "before anything lowers": control emission and
the IO/QRAM/Shadow and clone lowerings have already run — §0).
`LLVMContext::diagnose` exits on the first `DS_Error` (bd `br4a`), so nothing the
window's stages did with the classical reading reaches the output. The window's
stages see the CALLER exactly as preE did. ⚠ **They do NOT see the provisional
function's own body that way**: there every window stage still acts on the
conservative taint. The one-register lift is the stage found doing so (r1A F-9A-1,
bd `d88e`, fixed on `main` by a record-and-re-ask; merged here, §10). A full
enumeration of such rewrite stages is owed by `d88e`'s record (TRACK_D88E §10.3).

## 3. Mechanism

1. **`collectScrubCone`** (`TaintPropagation.{h,cpp}`) is `scrubForwardCone`'s walk,
   made PURE: from the roots, admit a tainted user iff it is not a keep root and
   every one of its tainted operands is already admitted (the least fixpoint).
   `scrubForwardCone` (`Specialization.cpp`) now applies it; the walk is the same
   LIFO over the same users, so members and record order are unchanged (the corpus
   A/B's 0 stream movers is the measurement).
2. **`returnTaintIsSpecProvisional(F)`**: `F` returns ≥1 tainted value and EVERY
   tainted return value is in the scrub cone of `F`'s potential specialization sites
   (tainted direct calls to a DEFINED function with ≥1 tainted argument), with the
   `cq_theta` results as the only keep roots. It is COUNTERFACTUAL: "would the return
   be classical if every such clone proved classical?".
3. **`propagateWorklist`** no longer crosses a return when its `ret` is tainted.
   It collects the functions whose `ret` it tainted, and when the worklist is empty
   it asks the predicate. A non-provisional function crosses exactly as bd 3jru made
   it; the worklist drains again, and undecided functions are re-asked after each
   crossing batch.
4. **`declineQuantumReturnCalls(M, taint, SkipSpecProvisional)`** is asked twice
   per entry point:
   - EARLY (skip = true): the old slot. A function is skipped only if it is
     provisional AND none of its used direct call sites is in `Tainted`. The second
     conjunct CHECKS the skip's premise ("its callers never saw this taint")
     rather than assuming it (M16, §5). The predicate is re-asked here, not trusted
     from the drain, because a later drain can give an already-tainted return
     value an independent source without revisiting it (`r65`: a provisional `t`
     plus a 6.5 `%out`, refused here). ⚠ Refused HERE, but not ONLY here: under
     r1A's MNOREASK mutant `r65` is refused by the late ask with the same string.
     The re-ask fixes the SLOT and the OWNER, not the verdict (§0, F-9A-3).
   - LATE (skip = false): right after `specialize()` and the l3oi fence, before the
     stale-reader backstop, `lowerRotations` and `lowerMeasures`. TOTAL. Since the
     `main` merge (§10) it runs after bd d88e's lift re-ask and the 2qyz re-sweep
     as well.
5. **The ordered scrub** (`specialize()`): each site's scrub runs when it resolves
   (`TaintedSources` grows as genuine sites resolve), and each site's mask is
   recomputed first:
   - unchanged: the old build;
   - 0 and the site untainted: an ordinary classical call, not cloned;
   - changed and non-zero: `classifyCandidate` again, then build;
   - 0 but still tainted: not constructed; keeps the old mask, so the l3oi fence
     declines.

   The immediate `taint.Tainted.insert(Site)` for a `ReturnTainted` site is
   LOAD-BEARING. Its comment said "robustness; usually already present", and
   that was FALSE even before this change: mutant M17 fails 12 fp/QRAM
   specialization fixtures, because every later stage reads the REBUILT call's
   taint. The ordered scrub adds one reader, the next site's recomputed mask.
   Corrected at the source (L7).
   - Probe `fp2` (`lpoly(lpoly(q))`, f80) is byte-identical to the oracle and
     to preE.
   - Probe `fp3` (`lmix(lpoly(q), q2)`) is identical too; it is the new fixture
     `spec_accept_fp_rebuilt_site_second_clone.ll`.
6. **The old-site pointer scrub** (`specialize()`). When `resolveSite` rebuilt the
   call, the old pointer is erased from `Tainted`, `BirthOrder`, `HandleWidth`
   and `StaleDeclined`, and `plan.Pending[i].Site` is updated. This is the
   top-level twin of `buildClone`'s inner migration. No `BirthOrder` is ever
   assigned to a Phase-6 call site (measured by grep: only minted rails and
   rail-bank seeds get one), so nothing migrates and no uncompute order can move.

## 4. Soundness argument — what a reviewer must break

- **S1 (the one that matters): the late re-ask is total and is reached.** It asks
  `functionReturnsTainted` of EVERY defined function at final taint, with no skip,
  in both entry points (`CQLoweringPass.cpp` `run` and the `runOnFunction` shim),
  immediately after `declineScrubbedHandleReads` and before `lowerRotations`,
  `lowerOps`, `lowerMeasures` and `uncompute`. ⚠ "Before any lowering stage" stood
  here and was FALSE (§0, r1A F-9A-4): control emission, the IO/QRAM/Shadow
  lowerings and the clone lowering run earlier. A
  provisional function is refused there unless the actual scrub removed ALL its
  return taint, and the actual scrub removes taint only from the cone of a clone
  whose `ReturnTainted` verdict is false.
- **S2: imprecision in the predicate moves a slot or an owner, never a verdict.**
  - Called provisional wrongly: the late ask refuses it.
  - Called non-provisional wrongly: it crosses and the early ask refuses it.

  The root set over-approximates `Pending` on purpose (`CallBase`, sites the
  specializer later declines).
- **S3: "non-provisional" is stable under taint growth.** A non-provisional return
  has a taint path from a source outside the cone (a theta keep root, a fresh rail,
  a crossed call with classical args), and on that path every member keeps an
  operand outside the cone, so it is never admitted. What growth can do is give a
  PROVISIONAL return an independent source, and the early slot's re-ask handles
  that (`r65`).
  - ⚠ **One direction is ARGUED, not constructed.** Growth could make a node on a
    non-provisional return's independent path into a NEW root: a crossed call
    `G(x)` whose `x` is tainted only in round 2. Then the early slot would call the
    function provisional although its callers are already tainted.
  - That needs `G`'s own `ret` to be tainted, i.e. `G`'s body holds a quantum
    source, and `scanBody` rejects such a callee transitively (`callee contains a
    quantum primitive`) at detection, before the early slot.
  - Whatever the argument's fate, the early skip now also requires that no used
    direct call site of the function is tainted. So even this case is refused
    EARLY (the conjunct is unpinnable today: M16 MISSED, no subject).
- **S4: the scrub still does not cross returns, and needs nothing there.** A
  provisional return never reached its callers. A non-provisional one crossed and
  was refused early, before `specialize()` runs.
- **S5: l3oi is untouched in its own function.** Its record and fence are
  unchanged, and the mask test in the clone-reader clause is now LOAD-BEARING rather
  than round 7's "equivalent" M50. `yb`'s clone `__cq_q_g2_10(t, q)` has the
  scrubbed `t` in an UNMASKED slot (mutant **M14**, §5).

L1's stage question, asked of this change:
- **Does anything computed between propagation and the late slot consume "the
  caller's call result is classical" over a premise the clones' verdict falsifies?**
  Yes, all of it does. And none of it survives when the premise is false, because
  the late slot declines the module.
- **Does the change GROW taint?** No. It grows it LESS than 983f9361 (no crossing
  for provisional returns).
- **Does it SHRINK taint at a new site?** The ordered scrub runs the same scrub at an
  earlier point inside `specialize()`. Nothing outside `specialize()` runs between
  the new and the old point, and the l3oi re-ask still comes after all of them.

## 5. Measurements (commands in `probes/`, raw outputs in `probes/results/`)

**Reproducers.** The bead's round-7 `rt1.s1.ll`/`rt2.s1.ll` could not be found:
the reviewer's scratchpad no longer exists, and no record names them. I
RECONSTRUCTED them from the bead's text as two-TU modules (`probes/rt1.c`,
`rt2.c`, lib `lib.c`, built by `gen.sh`). On the oracle both decline with the 3jru
string; on preE both exit 0 with a correct stream. They are the first two
fixtures below.

**Fixtures (Rule 12), red→green.**

| fixture | verdict | oracle 983f9361 | this change | what pins it |
|---|---|---|---|---|
| `taint_accept_spec_classical_return` (rt1) | ACCEPT | red (3jru decline) | green | M3 |
| `taint_accept_spec_classical_return_arith` (rt2) | ACCEPT | red | green | M1, M3 |
| `taint_accept_spec_classical_return_branch` (rt3) | ACCEPT | red | green | M1, M3 |
| `taint_accept_spec_classical_return_clone_arg` (ob1) | ACCEPT | red | green | M1, M3 |
| `taint_reject_scrubbed_handle_clone_arg` (ya, REWRITTEN) | ACCEPT | red (l3oi decline) | green | M8, M9 |
| `taint_reject_scrubbed_handle_clone_arg_mixed` (yb, REWRITTEN) | ACCEPT | red | green | M8, M14 |
| `taint_reject_spec_quantum_return_measure` (rq1) | DECLINE | green (early) | green (LATE) | M4 |
| `taint_reject_spec_quantum_return_branch` (rq2) | DECLINE | green (early) | green (LATE) | M4 |
| `taint_reject_quantum_return_mixed_spec` (rx1) | DECLINE | green | green | M13 |
| `taint_reject_quantum_return_spec_seeded_theta` (rs1) | DECLINE, store-escape owner | green | green | M2, M5, M12 |
| `taint_reject_quantum_return_mixed_rets` (rm2, hand IR) | DECLINE, store-escape owner | green | green | M2, M6 |
| `taint_reject_scrubbed_handle_clone_arg_layout` (yo, hand IR) | DECLINE | green | green | M15 |
| `spec_accept_fp_rebuilt_site_second_clone` (fp3) | ACCEPT | green | green (red on `98b921fb`) | M17; M18 FLAKY (3/5, r1B F-9B-3) |

- The 6 accepts are red on the oracle (`lit --filter`, measured before any source
  change). The 6 declines are declines on both binaries; their red is their
  mutant, since each goes red when the code it pins is removed (the "what pins
  it" column).
- The two REWRITTEN fixtures keep their `reject` names. A `git mv` can be
  resurrected by a merge (L8; bd `gahu`'s precedent), and their headers say so.
- **e2e:** `e2e-spec-classical-return` (new, `run_slice_multi.sh`). The oracle
  declines the module. The subject's 7-line trace is byte-identical to preE's,
  stage 2b STRICT reports `0 violation(s), 0 unproven`, and
  `cqrt_addc_i32(h0, 4)` shows the returned classical `4` as a LITERAL.

**lit** (`cd build && lit ir-pass/test`, final binary `8b837d1f`): **2288
discovered, 2287 passed, 1 XFAIL.**

**Corpus A/B** (`probes/ab_sweep.py ORACLE SUBJECT LIST --null`). The script runs
the null control (ORACLE vs itself over the WHOLE list) first and refuses to
report if it is non-zero. For each module it compares the exit code, the sha-256
of the lowered IR, and the first `error:` line.

| set | denominator | null control | movers |
|---|---|---|---|
| `ir-pass/test/*.ll` | 2288 | 0 of 2288 | **6, all D→A, all this change's own accept fixtures** (rows 1–6 above); 0 A→D, 0 DIAG, 0 STREAM — so the fp3 fixture is identical on both |
| `run_slice_multi.sh` registrations (llvm-linked) | 22 | 0 of 22 | 0 |
| `tests/e2e/*.c` standalone (default CASE; 18 of 450 need `-D`/other TUs and were not swept) | 432 | 0 of 432 | 0 |

**No pre-existing fixture moved, not even its diagnostic string.** The 6 intended
D→A movers are the positive control.

**Probe battery** (`probes/final_sweeps3.sh`: 31 two-TU probes on preE / ORACLE /
FINAL SUBJECT; sources in `probes/`; raw output `results/final_sweeps3.txt`).
- **Accepted:** rt1–3, ob1–9, rfc (address-taken, classical), rloop (the result as
  a loop bound), rsel (it selects between register arms), ya, yb, fp2, fp3.
  - 16 of them are **byte-identical to preE**: rt1–3, ob1–8, rfc, rloop, rsel,
    fp2, fp3. preE compiled all 16 correctly, and fp2/fp3 are also identical to
    the ORACLE.
  - Every subject stream the pointer scrub could have moved is identical between
    `98b921fb` and `8b837d1f`, i.e. every probe `98b921fb` accepted.
  - ob9, ya and yb differ from preE because preE MISCOMPILED them (F-R7-1). Their
    new streams were read by hand: a classical `g(t)` call, and
    `__cq_q_g2_10(t, q)` with `t` in the literal slot.
- **Declined:**
  - rq1–3 and rfq (QUANTUM verdict) decline with the 3jru string at the late
    slot. preE compiled all four wrongly: it dropped the measure, or branched on
    the handle id.
  - rx1, rp1 (a tainted-branch merge), r65 and r65c (a 6.5 `%out` source) decline
    with the 3jru string.
  - rs1 and rm2 decline with the store-escape string.
  - yc and yo decline with the l3oi string.
- **Stage 2b** (`tools/free_pairing_check.py`) on all 19 accepted streams of the
  final subject: 0 violations, 0 unproven.

**Mutation matrix** (`probes/mutate.py`). For each mutant: a textual source patch,
a rebuild of `cq-opt`, and the FULL lit suite (denominator 2287), then a restore.
The restored build was checked bit-identical to the subject after each batch.

| mutant | removes | result |
|---|---|---|
| N0 | nothing (a dead `size() > 1e9` conjunct that changes the binary) — NULL | 0 of 2287 (run twice) |
| M1 | drain never defers (= "move the refusal, keep the conservative closure") | KILLED (3: the arith/branch/clone_arg accepts — under M1 `main` lowers `mul_i32_hl` over a classical call result, the silent miscompile) |
| M2 | drain always defers | KILLED (7: five pre-existing 3jru fixtures + both ownership fixtures) |
| M3 | early slot does not skip provisional | KILLED (4) |
| M4 | the LATE slot, both entry points | KILLED (2: rq1, rq2 — silent 3jru miscompile under it); re-run on the final source: KILLED (2) |
| M5 | predicate: theta not a keep root | KILLED (1: spec_seeded_theta) |
| M6 | predicate: SOME tainted return in cone instead of EVERY | KILLED (1: mixed_rets) |
| M7 | predicate: roots need no tainted argument | KILLED (1: chain_store) |
| M8 | ordered scrub: no mask recomputation | KILLED (2) |
| M9 | ordered scrub: no mask-0 skip | KILLED (1) |
| M10 | ordered scrub: no re-classification of a changed mask | **MISSED** — no subject. A SHRUNK mask only removes step (A)'s i32-handle obligations, and a GROWN one (taint growth between detection and `specialize()` without a 0vvq re-plan) was not constructed. Kept as the loud side of a mask change. |
| M11 | ordered scrub: genuine sites not added as keep roots at resolution | **MISSED** — equivalent given l3oi's fence. It matters only when a genuine site resolved EARLIER reads a later site's result, i.e. a layout-reversed use. That site's clone was then built with the later-scrubbed value in a MASKED slot, so the fence fires anyway (`..._layout.ll`, M15). |
| M12 | scrub cone ignores keep roots | KILLED (2, incl. pre-existing `spec_reseed_theta_source`) |
| M13 | scrub cone ignores "other tainted operand" | KILLED (1: mixed_spec). ⚠ **Before this change this conjunct of `scrubForwardCone` was pinned by NO fixture:** the only kill is this change's own fixture, through the predicate and the scrub together. |
| M14 | l3oi fence: mask check off (every clone slot a reader) | KILLED (1: clone_arg_mixed). Round 7's "equivalent" M50 is no longer equivalent. |
| M15 | l3oi fence: clone-reader clause off | KILLED (1: clone_arg_layout) |
| M16 | early skip: the "no tainted caller" conjunct | **MISSED** — no subject, by S3's argument (§4). Kept deliberately, because it CHECKS the skip's own premise. |
| M17 | `specialize()`: no re-insert of a `ReturnTainted` site | KILLED (12: 11 pre-existing fp/QRAM spec fixtures + fp3) — the old "robustness" comment was false |
| M18 | `specialize()`: no old-site pointer scrub | ~~MISSED — the address reuse did not recur on the mutant build~~ **FLAKY KILL** (r1B F-9B-3: killed 3/5 under the system allocator, 5/5 under LIFO reuse). My single run was an unlucky draw, not a build difference. The fp3 fixture is a FLAKY pin; a deterministic one needs a live-key check, which is bd `8e5r`'s scope |
| MRED | the drain's re-decision of deferred functions after a crossing batch (r1A F-9A-3) | **MISSED** (r1A: 0 of 2288 lit, 0 of 179 probes). Slot/owner-only: a deferred function never re-decided is re-asked at the early slot |
| MNOREASK | the early slot's re-ask of the predicate; skip on the "no tainted caller" conjunct alone (r1A F-9A-3) | **MISSED** (same denominators). Slot/owner-only: a function the early slot skips is refused at the late slot. ⚠ So §3's "necessary" for the re-ask was over-strong: under MNOREASK `r65` is still refused, with the same string, one slot later |

- M1–M16 ran on subject `98b921fb` sources (null 0 of 2287).
- N0, M4, M17 and M18 re-ran on the FINAL sources (null 0 of 2288; the positive
  control M4 still KILLED 2).
- Totals as first reported: 18 mutants plus the null, 14 KILLED, 4 MISSED. ⚠
  **Corrected (§0):** 20 mutants plus the null. M1–M18 are mine; MRED and
  MNOREASK are r1A's.
  - 14 KILLED deterministically.
  - 1 FLAKY kill (M18).
  - 5 MISSED: M10, M11, M16, MRED and MNOREASK. Each MISSED one moves a slot or an
    owner only, or is argued equivalent given l3oi's fence.
  - No mutant was INVALID.
- After every batch the restored build was bit-identical to the subject
  (`6b8bebc7`, `98b921fb`, `8b837d1f`).

## 6. Residuals and what I did NOT attack

- **The same-function l3oi residual stays an over-decline.** `t = h(q, m); if
  (t > 3)` (xam), `if (g(t) > 3)` (yc), and `f`'s own control on its spec result
  still decline at l3oi's fence. Their gate is minted in round 1 from the
  conservative taint, and only a verdict available BEFORE control emission removes
  it. `predictReturnTainted(callee, mask) == false` is a sound "classical" verdict
  at detection time (see its header), so it may be the route. Filed as a follow-on
  (§8), not attempted.
- **Layout order.** `Pending` is in layout order, so a use laid out before its
  definition's block is built from a stale mask and declines at l3oi's fence
  (`taint_reject_scrubbed_handle_clone_arg_layout.ll`, hand IR). An RPO order would
  recover it. `-O1` does not emit this layout for any probe I built. Filed (§8).
- **Not attacked:**
  - `invoke` sites;
  - a provisional return through a loop-carried φ (the least-fixpoint cone keeps
    it out, which is the safe direction, but no probe);
  - `+Asserts`;
  - a `cq_invert_*` escape of a provisional value.
  - Also no composition with bd `xdu2.16` (the parallel track), because its branch
    is not in this tree.
- **Argued impossible, not constructed:** a provisional function that is ALSO a
  Phase-6 candidate at another call site. A provisional return is tainted, so the
  function's body holds a quantum source transitively (Rule 3: `cq_theta` is the
  SOLE source). `scanBody` recurses into nested defined callees and rejects any
  rotation it finds (`SpecializeReject.cpp`, "Calls: a quantum primitive
  (rejects) … or a nested classical call — recurse into its body").

## 7. What a Rule-13 reviewer should attack first

1. **S1, the totality of the LATE re-ask.**
   - Find a path from propagation to lowering that reaches `lowerRotations`,
     `lowerOps` or `lowerMeasures` without passing
     `declineQuantumReturnCalls(..., false)`. Remember the `runOnFunction` shim.
   - Or find a stage in the window that makes a provisional function's return
     UNtainted by a route other than a clone's classical verdict. `Tainted.erase`
     sites were enumerated as "delete-or-RAUW" by TRACK_E §6g; one that RAUWs a
     tainted `ret` operand to an untainted value would break S1.
2. **The window with a QUANTUM verdict.** Callers read the call result classically
   between propagation and the late slot. The claim is that nothing they do
   escapes, because the module is declined.
   - Attack a CRASH in that window: exit 134 would replace a clean decline.
   - Attack a stage that aborts, or a stage that emits the module (none should).
3. **S3.** Construct a function whose return crossed at one drain and is
   provisional at the early slot. The new conjunct should refuse it early anyway.
   If it does not, that is a finding.
4. **The ordered scrub in `specialize()`:**
   - a site whose mask GROWS at recomputation (M10 has no subject);
   - a `retargetSite` REBUILD (fp return) feeding a later site (fp2 and fp3 are
     identical to the oracle, and they are the only probes);
   - two genuine sites where one reads the other's result in layout-reversed
     order (M11 is argued equivalent given the fence).
5. **The counterfactual cone's roots.** They are `CallBase` to a DEFINED callee
   with a tainted argument. They do not include a tainted-arg call to a
   DECLARATION: an IO sink, a QRAM load (not a call), a curated intrinsic. A
   return whose only non-theta source is such a call is therefore
   NON-provisional, crosses, and is refused early. That is safe; find the case
   where it is not.
6. **Dangling keys in `taint.Tainted` (the class §3 item 6 closes one member of).**
   The late re-ask reads `Tainted` by pointer for the `ret` of EVERY function,
   including the clones `specialize()` just created, whose instructions are fresh
   allocations. Any tainted MODULE instruction erased before `specialize()`
   without a `Tainted` scrub can alias a clone value.
   - At the re-ask, an alias costs an over-decline (the safe direction).
   - At `lowerOps(M, …, taint)`, which also walks clone bodies and asks the same
     set, an alias could lower a clone instruction as a module-tainted op.
   - TRACK_E §6g enumerated `Tainted.erase` sites. The REVERSE question (every
     erase of a tainted instruction scrubs `Tainted`) has not been enumerated;
     `retargetSite` was one that did not. Same family as bd `vpde`.

## 8. Beads

- bd `test_C_libtooling-9bhg`: left OPEN for the orchestrator's Rule-13 rounds;
  notes updated.
- NEW bd `test_C_libtooling-cepm` (P2): the same-function l3oi residual (§6), with
  the `predictReturnTainted` route.
- NEW bd `test_C_libtooling-s07e` (P3): the layout-order residual of the ordered
  scrub (§6), with the RPO route and the `_layout.ll` retirement trigger.
- NEW bd `test_C_libtooling-j8sk` (P2): the dangling-`Tainted`-key class (§7 item
  6). One member is fixed here; the reverse enumeration is owed.

## 9. Gates run on the FINAL subject (`cq-opt` `8b837d1f`)

| gate | command | result |
|---|---|---|
| lit | `cd build && lit ir-pass/test` | 2288 discovered, 2287 passed, 1 XFAIL |
| full ctest | `ctest --test-dir build -j6 --output-on-failure` | **494/494 passed**, 1482.34 s wall (`results/ctest_full.txt`) |
| cq-opt equivalence | `cmake --build build --target cq-opt-equivalence-full` | 2288 fixtures, 0 mismatches |
| code map | `python3 tools/update_code_map.py --check` | clean (regenerated for 2 new functions and line counts) |
| e2e | `ctest --test-dir build -R '^e2e-spec-classical-return$'` | passed (also inside the full run) |

⚠ The full ctest is quoted WITH ITS LOAD. The parallel track's own `ctest -j6`
ran in another worktree at the same time, and the 1/5/15-minute load averages
were 11.7/81.3/116.0 mid-run and 4.3/12.4/54.0 at the end. The wall time is not
comparable with a quiet-box figure. Every row passed, and a pass under contention
is still a pass.

A first full ctest was started on subject `98b921fb` and deliberately STOPPED at
143 of 494 (all passed) when the §3 item-6 finding made that binary obsolete. It
is not cited as a gate.

## 10. After the Rule-13 rounds: `main` (d88e + xdu2.16) merged, 2026-09-26

Both rounds on `30529716` were NOT-CLEAR on pre-existing P1s that 9bhg exposes
(r1A → bd `d88e`, r1B → bd `8e5r`). Neither round faulted 9bhg's own logic (§0).
bd `d88e` landed on `main` (`ba80bda1`, which also carries bd `xdu2.16`).
bd `8e5r` is still in review on its own branch, and this branch does NOT merge it.

**Commits** (merged, not rebased; `30529716` is intact):
- the review records;
- the merge `e4adabad`;
- the review-item dispositions plus the slot-order pin;
- this section.

The merge had one textual conflict, `CODE_MAP.md`, resolved by regeneration.

**Binary.** The merged `cq-opt` is `242f8b61530623e9` (`libCQPass.so`
`ea806919a6c16a91`). It is BIT-IDENTICAL to the "composed with 9bhg" build that
TRACK_D88E §7 measured independently. The later comment-only edits rebuild to the
same hash.

**The post-`specialize()` slot ORDER, the same in `run()` and the `runOnFunction`
shim:**

1. `declineFalsifiedMergePhiLifts` (d88e — the lift's premise, a REWRITE);
2. `declineLiftedStaleRecordOps` (2qyz, moved here by d88e);
3. `declineScrubbedHandleReads` (l3oi — an EMISSION read a scrubbed value);
4. `declineQuantumReturnCalls(…, /*SkipSpecProvisional=*/false)` (9bhg, the TOTAL
   late ask);
5. `declineRecordedStaleQuantumReaders` (3d8q backstop, still last);
6. then `lowerRotations`, `lowerOps`, `lowerMeasures`, `uncompute`.

Why this order is right: the first `DS_Error` exits (bd `br4a`), so the order
decides which owner speaks, and each owner is placed where the hand-inlined twin
agrees.
- **(1) before (4).** Take a function with a lift over a spec-CLASSICAL base that
  also RETURNS a spec-QUANTUM value. In its twin the base is classical from
  propagation onward, so `declineClassicalMuxes` speaks long before any 3jru ask.
  Placing (1) first reproduces that. Probe `ordM` (fixture
  `taint_reject_quantum_return_lift_owner_order.ll`) measures it: stderr is
  byte-identical to its twin on the merged binary, and it is RED on
  9bhg-alone, `main` and the oracle, each of which prints the 3jru string.
  - Mutant MORD (the late ask moved above (1), in both entry points) is KILLED by
    that fixture and by nothing else: 1 of 2317 lit.
  - No fixture pinned this order before, because neither owner existed on one
    binary.
  - Null control first: 0 of 2317.
  - The no-lift control `ordN` still reaches (4).
- **(3) before (4).** A handle read of a scrubbed value keeps its more specific
  owner. This is unchanged from `30529716`.
- **(1) and (2) before (3).** d88e's own pins
  (`…_spec_scrubbed_base_{owner,pure_consumer,l3oi_owner}.ll`), all green on the
  merged binary.
- **(5) last.** Unchanged.

**r1A's full battery, rebuilt on the merged tree**
(`probes/merge9/battery.py`, output in `probes/results/merge9_battery.txt`):
- Modules: 327 = 224 r1A sources + 72 hand-inlined twins (d88e's own `mktwins.sh`
  rule; `s09`/`s13` are not derivable) + my 31 probes.
- **Null controls first: `sub` (`8b837d1f`), `main` (`e587c191`) and `merged` each
  ran TWICE over all 327. 0 of 327 differ, for all three.** None of these modules is
  in r1B's alias families; those need bd `8e5r`.
- **Every former miscompile now declines with its twin's verdict AND byte-identical
  stderr (DECL-SAME):** `l01C l07C l08C l09C l10C l13C l18C l22C`. On `sub` all
  eight were silent accepts that DELETED the user's `cq_measure` (measure census:
  1 → 0). `l25C` moved from DECL-DIFF to DECL-SAME.
- **Movers merged vs `sub`: 9 of 327.** 8 A→D, exactly the eight above; 1
  decline-string move, `l25C`. My own 31 probes: 0 movers.
- **Movers merged vs `main`: 64 of 327.** 35 D→A and 29 decline-string moves. Every
  string move is decline→decline; the owner moved because the early 3jru refusal no
  longer fires. Every D→A accept is justified:
  - `x10C`: twin ACC-SAME.
  - `s05C`, `w02C w03C w05C w06C w08C w12C…w20C`: twin ACC-DIFF, and in all 15 pairs
    the ONLY difference is that the twin uncomputes and frees the dead register `q`
    (`ry(h,−θ)`, `cqrt_free`). In the 2-TU program `q` is the classical clone's
    borrowed argument and is left allocated (Rule 6's accepted leak). This was
    checked mechanically (`accdiff_class.py`: DEAD-REG-ONLY for 15 of 15). `l20` is
    the only other ACC-DIFF pair, d88e's known stage-1 folding difference, and it is
    the same on all three binaries.
  - `rt1`: byte-identical to preE.
  - `s13C`: read by hand. `u = h(q, t)` with `t` classical is cloned
    `__cq_q_h_01(q, t)`, so `f13` returns `(m+1)+1`. preE differs because it built
    the F-R7-1 shape, with `t` as a handle.
  - My own 17 accepts: byte-identical to `sub`, i.e. §5's streams.
- **Twin parity:** 38 of 72 pairs twin-identical on merged, against 29 on `sub` and
  29 on `main`. Every remaining VERDICT-DIFF is either C-declines/T-accepts (an
  over-decline in the provisional function's own body: bd `cepm`'s class; `l19`,
  `s01`, `s02`, `s14`, `x01…x07`, `x09`, `x11`) or d88e's known out-of-scope pair
  `l12`/`l17` (bd `z0re`). Each is the same on all three binaries.
- **Measure census on every merged ACCEPT (88 modules):** only four lower fewer
  `cqrt_measure` than their source has `cq_measure`. Each is a bd 21mg
  never-quantum measure: `l21C` (twin ACC-SAME), `l21T`, `own_ob2` (preE-identical),
  and `own_ya` (`g(t)` with `t` classical). ⚠ The first census regex undercounted
  `call zeroext i1 @cq_measure_i1(` and flagged `l17`/`w16` falsely. It was fixed
  before any row above was read.

**Corpus A/B** (`probes/merge9/ab_both.sh`; the FIXED `ab_sweep.py --null` runs
both binaries twice):

| pair | denominator | null REF | null SUBJECT | movers |
|---|---|---|---|---|
| merged vs `main` | 2317 | 0 | 0 | 7: 9bhg's 6 D→A fixtures + the order fixture (DIAG) |
| merged vs `sub` | 2317 | 0 | 0 | 21: `main`'s own d88e fixtures (11 A→D, 3 DIAG) and xdu2.16 fixtures (6 D→A), + the order fixture |

**Gates run (merged binary):**
- `lit -s ir-pass/test`: 2317 discovered, 2316 passed, 1 XFAIL.
- The 9bhg and d88e families (`--filter 'quantum_return|scrubbed_handle|spec_classical_return|spec_quantum_return|fp_rebuilt_site|spec_scrubbed_base|spec_quantum_base|lift'`):
  80 of 80 passed.
- e2e: `e2e-spec-classical-return` and d88e's four `spec-lift` entries, 5 of 5.
- `update_code_map.py --check`: clean.
- **Full `ctest` was NOT run on the merged tree.** Per the coordinator it runs
  after the 8e5r merge.

**Still wrong or open (not closed by this merge):**
- bd `8e5r` (r1B F-9B-1): the dangling-key alias still miscompiles 9bhg's r1B
  population (`w12`/`w9`/`w15` in r1B's alias families, from run to run) on this
  tree. The branch must not land before 8e5r.
- F-9B-2: 9bhg's headline accept `v12` is refused spuriously when the allocator
  reuses the key. Same root.
- bd `cepm`: the over-decline face in the provisional function's own body.
- bd `z0re` (`l12`/`l17`): unchanged.
