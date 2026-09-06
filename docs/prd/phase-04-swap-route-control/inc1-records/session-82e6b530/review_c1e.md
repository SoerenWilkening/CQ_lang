# review_c1e — independent Rule-13 lens on the REBASED C-1 round 4 (branch c1-round4 @ aa9d702)

Agent: review_c1e. READ-ONLY on every checkout/worktree. Started 2026-09-06.

## Log
- 12:10 step 0: read BRIEF_common, BRIEF_review_c1e, CLAUDE.md (in context). Created work dir.
- 12:2x step 1 (brief item 1): CODE DIFF. `git diff main HEAD -- ir-pass/src` on subject aa9d702:
  ONLY `LoopLowering.cpp` (+110/-12) and `ArithLowering.cpp` (+10/-0). Mechanical non-comment filter
  (`git diff main HEAD -- ir-pass/src | grep -E '^\+[^+]' | grep -vE '^\+\s*//'`) gives EXACTLY:
    +    if (!P)
    +      return;  // not the dtzb shape — stop, ...
  removed: `if (!P || !P->hasOneUse()) return;` (+ its comment). ArithLowering: 0 non-comment lines.
  `git diff --stat main HEAD -- runtime tools/opcode_table.yaml include` EMPTY (owner D3 held). ✓
- 12:2x step 2: HARNESS CONTROL (clean + known-bad), 3 binaries, full pipeline:
  | binary | q5sel rolled/unrolled | q4b rolled/unrolled |
  | main 258d974 | 4/0 44 vs 4/4 52 — DIVERGE 8 | 4/0 52 vs 4/4 60 — DIVERGE 8 |
  | pre (59f6a95, pre-rebase) | 4/4 52 == 52 IDENTICAL | 4/4 65 == 65 IDENTICAL (pre-Inc-2 route) |
  | subj (aa9d702) | 4/4 52 == 52 IDENTICAL | 4/4 60 == 60 IDENTICAL |
  AND subject's ROLLED trace == main's own UNROLLED twin, byte-for-byte, for BOTH pairs.
  Harness is controlled. Build currency: `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` EMPTY.
- 12:3x step 3: ORCHESTRATOR FULL CTEST (READ, not run): `$SP/progress/orch_full_ctest_c1e.log`
  tail = "100% tests passed, 0 tests failed out of 367 / Total Test time (real) = 385.89 sec / EXIT=0".
- 12:3x HARNESS BUG FOUND AND FIXED IN MY OWN SWEEP (recorded because it is the class the brief warns of):
  macOS /bin/bash is 3.2 — `declare -A` is not supported and `CQ[main]=x` writes INDEX 0, so all three
  "binaries" silently resolved to the LAST assignment (subj) and every program reported identical hashes.
  Caught by the known-bad control (q5sel must DIVERGE on main). Replaced with a `case` statement; the
  control then reproduced (main 44 vs 52, subj 52 == 52).
- 12:5x step 4 (brief item 2+3a): POPULATION SWEEP, 3 binaries, MY OWN dedupe.
  Population: every `p/`, `p2/`, `p3/` under `$SP1/progress/*_work/` (13 dirs) PLUS the committed
  `inc1-records/c1-round4/` and `inc2-records/` reproducers = 2175 source files scanned, 1535 exact
  content duplicates, 1 name collision renamed → **640 unique programs**; 30 S1FAIL (oracle-era
  register-form `cq_phi` sources) → **610 compared on all three binaries**.
  Method: stage 1 ONCE (CQ.h is byte-identical across main/branch — `git diff main HEAD -- include`
  EMPTY), then stage 2 on {main 258d974, pre-rebase 59f6a95, subject aa9d702}; SHA-256 of the lowered
  IR + rc + first diagnostic; link+run only where the hashes differ.
  | partition | count |
  | identical on all three | 526 |
  | (a) subject == pre-rebase, != main (round-4's own capability) | 24 |
  | (b) subject == main, != pre-rebase (Inc 2's own movers) | 58 |
  | (c) subject differs from BOTH | **2** — `q4b_preadd_rolled`, `b4z_value_then_postadd_loop_rolled`, i.e. EXACTLY the Inc-2 value-arm merge x preheader-preadd capability the brief predicted |
  | **DECLINE(main) -> ACCEPT(subject)** | **0** |
  | ACCEPT(main) -> DECLINE(subject) | 0 |
  | decline-message changes (main vs subject) | 0 |
  Category (b) corroborated: 54 of 58 have `cqrt_cswap` in the PRE-REBASE trace and NONE in the
  subject's (the Inc-2 route retirement); of the other 4, `a5_invert` is an Inc-2 mover with no cswap
  either side, `b6b`/`b6d` DECLINE only on pre-rebase (an Inc-2 capability already on main), and
  `f1_i128cond` declines on all three. In EVERY case subject == main byte-for-byte, so round 4 changed
  nothing for them.
  All 26 movers (a)+(c) GAIN `_unc`/`cqrt_free` pairs and lose NONE (measured per program). The one
  apparent exception, `u1_rollback_merge_preadd_plus_template`, has a trace byte-IDENTICAL to main's
  and a lowered-IR diff of exactly 4 lines: the ORDER of two `declare` lines
  (`declare void @cqrt_ry_i32(i32, double)` moved 2 lines) — a declaration-minting-order artefact,
  no gate moved. That is the documented rollback path behaving as a no-op.
- 13:0x step 5 (brief item 3b): LIT CORPUS SWEEP — every one of the SUBJECT's **1690** `ir-pass/test/*.ll`
  through `main` 258d974 and the SUBJECT (rc + first diagnostic + SHA-256 of the lowered IR):
  **0 RCDIFF · 0 DIAGDIFF · 3 OUTDIFF**. The 3 OUTDIFFs are exactly round 4's three new accepts
  (`control_phase_kickback_mixed_{merge_out_rail_preadd,preheader_addc_after_region,value_merge_preadd}_inloop`),
  and each GAINS one `cq_template_*_unc` and one `cqrt_free` with an UNCHANGED `cqrt_addc/xorc` count
  (2->3, 2->3, 3->4 uncs; 8-line IR diff each). **0 DECLINE->ACCEPT anywhere.**
  ⚠ Second harness bug caught by my own control: BSD `mktemp /tmp/x.XXXXXX.ll` requires the X's LAST,
  so the first run produced empty `-o` paths; rerun with a deterministic per-(fixture,binary) path.
- 13:0x step 6 (brief item 5): INJECTION MATRIX re-run by me (44 accepts x 17 mutations, accept list
  re-derived with `grep -L 'RUN: not' control_phase_kickback_*.ll` and byte-IDENTICAL to the rebase
  agent's): **0 MISSED on every column, 0 DIRTY, `clean` PASS on all 44**; `extra_ry` caught by
  **RYCNT on 26** and **CHECK on 18** — reproduces the rebase record exactly.
  INDEPENDENT 3-POSITION Ry injection (`$W/ry3.py`) into the q4b fixture + the two round-4 fixtures,
  positions {after the flag free, between the mint and the `rz_i1`, after the last `_unc`}:
  **9 of 9 caught** by a named prefix (RYCNT and/or CHECK), 0 MISSED.
  `grep -n 'NOROUTE-COUNT' ir-pass/test/control_phase_kickback_*.ll` → **EMPTY** (no positive COUNT
  folded into a NOROUTE prefix; the windowing recurrence is absent).
- 13:0x step 7 (brief item 6): RECORD TRUTH, all reproduced by command on the subject worktree —
  fixtures **1690**, `ctest -N` **367**, `^e2e-` **357**, `^e2e-slice-` **321**, twin gates **26**,
  goldens **323**, matrix **259** rows + **29** quarantine cells, sub-grid F4 present (10 hits in
  `loop_twin_matrix.py`), goldens with `cqrt_cswap` **1**, non-`i1` `cqrt_rz` in goldens **0**,
  duplicate `session-adc5590a/fix_c1d.md` GONE.
  All FOUR new goldens re-derived from their committed `.c` on the subject build: all **GOLDEN-MATCH**,
  STRICT 2b `0 violation(s), 0 unproven`, and BOTH pairs rolled == unrolled byte-identical (52=52, 60=60).
  F-C1D-3's three refinements VERIFIED on the tree: `peelInPlace*` = 24 hits, 4 prose, 2 decl/defn =
  **18 code call sites, 2 at `AsLowered=true`** (`LoopLowering.cpp:3214`, `:3413`); `WireWalk` has
  **1** hit and it is PROSE (`WireWalk.cpp:457`) — zero code reads; `declineLiftedStaleRecordOps` is at
  `CQLoweringPass.cpp:522` and `:848`, both AFTER the commit at `:363`/`:393`/`:811`.
  Status flips: all four live "in flight" occurrences read "was in flight ... and is NOW LANDED".
- 13:2x step 8 (brief item 4+7): THE ATTACK BATTERY — 24 new plain-C programs (`$W/a/`, rolled+unrolled
  twins), each run on {main 258d974, pre-rebase 59f6a95, subject aa9d702} through the FULL pipeline.
  CAPABILITY (main rolled DIVERGES from its twin; subject rolled == unrolled BYTE-IDENTICAL):
    a5 second value diamond before the loop · a6 IF/ELSE value arm (V2) · a12 post-loop diffusion ·
    a14 mixed (invariant merge + carried ancilla) · a18 chain-final alive + preadd on %out ·
    a20 source `p` measured after · a21 condition register measured after ·
    **a22 dtzb-shaped chain HEAD (`p+3`)** · **a23 IF/ELSE with BOTH heads dtzb** ·
    a24 dtzb head + chain-final alive.  a7 (value SWITCH, V3) 4/0 -> 4/4 (its unrolled twin declines
    `control flow`, so no byte-identity witness — the disclosed OQ-C1D-3 class).
    a19 (4.5 switch DATA-MUX + preadd) IDENT on all three (main already handled it).
  In EVERY accepted attack the arm input `Q` (= `p`) carries **0** in-place `cqrt_addc`/`cqrt_xorc`
  and the two `cqrt_copy_i32_controlled` read DISTINCT registers.
  STILL LEAKS, byte-identical to `main` (F-C1E-2): a1, a2, a3, a4/a17, a9, a11.
- 13:3x step 9: THE G6/G7 MUTATION TEST (I built the mutant myself). `$W/mut_g67` = `git archive` of
  the subject with `inPlaceFenceHolds`' G6 and G7 `return false` made unreachable; fresh cmake,
  `MUT-BUILD-RC=0`, `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` EMPTY.
  Mutant VALIDATED: `control_swap_value_ifelse_head_out_of_place.ll` goes **RED: CHECK,NOROUTE** on it
  and its two controlled copies collapse onto ONE register (`copy(f,%h1,%out)` twice) — the documented
  CONSUMER-2 miscompile, reproduced.
  ⭐ **`control_phase_kickback_mixed_value_merge_preadd_inloop.ll` stays GREEN on that mutant**, and the
  q4b program's emitted copies are byte-unchanged (`h3,h1` on subject AND mutant). Cause, measured:
  in that module `%2` (= `p`) has exactly ONE chain user, `%5 = mul i32 %2, 5` (`-O1` reassociates
  `(p+3)*5` -> `p*5+15`), and `inPlaceValueRailOperand` admits only add/xor, so G2's SHAPE half refuses
  it whatever G6/G7 say. My a22/a23/a24 DO discriminate: all three collapse both copies onto `h1` on
  the mutant and are byte-identical twins on the subject. => F-C1E-1.
- 13:3x step 10: GLOBAL IMMEDIATE-SLOT AUDIT (the F-C1B-1 / eqpx class) over all 640 population
  programs + the 28 attack programs, on the SUBJECT: every `cqrt_addc_*`/`cqrt_xorc_*` whose arg-1 is
  an SSA value. Checker controlled on a hand-made bad module (fires). **7 hits, and ZERO of them new**:
  4 are `cqrt_xorc_i32(%hN, %h_op)` with `%h_op = cq_template_and_i32_hl(%out, 7)` — a QUANTUM RAIL
  HANDLE in the classical-immediate slot, i.e. the DISCLOSED, PRE-EXISTING bd `test_C_libtooling-eqpx`
  (byte-identical on `main` 258d974; `c1c_m_xor_and_noregion` reproduces on the pre-3qlq ORACLE too);
  3 are classical run-time immediates (`%cq_negimm = sub i32 0, <volatile load>`, `%2 = load i32 @C`),
  i.e. false positives of my regex, also byte-identical on main.
- 13:3x step 11: STRICT stage 2b over all 26 movers on the subject: **0 not clean**
  (`0 violation(s), 0 unproven` on every one).
- 13:3x step 12: conflict-table + shape truth. `git diff --name-only a3c1513 main --
  ir-pass/src/LoopLowering.cpp tools/loop_twin_matrix.{py,expected.txt} RETIRE_SWAP_ROUTE_INC1_NOTES.md`
  EMPTY (the three must-not-conflict files were untouched by main) · overlap = exactly the 5 files the
  record names · `git log --oneline main..HEAD` = **17**, tip `aa9d702`, `git status --porcelain` EMPTY ·
  `tests/e2e/CMakeLists.txt` kept BOTH blocks (29 `control_value_` lines, 4 `e2e-value-*-twin-identical`
  ctest entries #28-#31, plus both merge-preadd pairs and their two `cmp` gates).

---

# FINDINGS

## F-C1E-1 — `DOC` (coverage): the fixture cited as MEASURING F-C1D-2's argument cannot discriminate the pair it is cited for
`ir-pass/test/control_phase_kickback_mixed_value_merge_preadd_inloop.ll` is cited twice in source as
the MEASUREMENT behind "the commit cannot reach an Inc-2 chain head" — at `LoopLowering.cpp`
(`commitOutOfLoopInPlaceOps`: "MEASURED rather than argued, on the rebased tree: … `HCNT` prefix
asserts that the Inc-2 chain HEAD is emitted OUT of place") and at `ArithLowering.cpp:709` ("whose
`HCNT` prefix pins the head OUT of place on the very shape that made the commit fire on the `%out`
rail beside it"), in the same comment that names G6/G7 as "NOW THE SOLE NET ON THE COMMIT PATH".
MEASURED: on a binary with BOTH G6 and G7 disabled the fixture is **GREEN** and the program's emitted
stream is byte-unchanged. `-O1` reassociates `(p+3)*5` into `p*5 + 15`, so `p`'s ONLY chain user in
that module is `%5 = mul i32 %2, 5`; `inPlaceValueRailOperand` admits `add`/`xor` only, so **G2's
shape half refuses the head whatever G6/G7 answer** and both `HCNT-NOT` lines are unfalsifiable by a
relaxation of the pair they are cited for.
NOT a miscompile: the property HOLDS. Three new dtzb-headed programs — `a22` (`if (q>3){r=p+3;r=r^9;}`),
`a23` (IF/ELSE with `p+3` and `p+5`), `a24` (chain-final also alive) — are rolled == unrolled
BYTE-IDENTICAL on the subject with 0 in-place `addc`/`xorc` on `p`'s rail and DISTINCT copy sources,
and all three collapse BOTH `cqrt_copy_i32_controlled` onto ONE register on the mutant. And the
property is separately pinned in the tree by `control_swap_value_ifelse_head_out_of_place.ll`, which
goes **RED: CHECK,NOROUTE** on the mutant — the fixture `ArithLowering.cpp` already names for
CONSUMER 2. So the net is real; the NEW fixture's contribution to it is decorative.
Reproducers: `$W/a/a2{2,3,4}_*_{rolled,unrolled}.c`; mutant `$W/mut_g67`; harness `$W/rg_mut.py`.

## F-C1E-2 — `LEAK`, PRE-EXISTING (byte-identical to `main` 258d974) and DISCLOSED: the preheader in-place op whose PARENT has a second unlowered tainted user keeps the O(K) which-path leak
Six plain-C spellings, all ACCEPT, all rolled != unrolled on the SUBJECT and all byte-identical to
`main`: `a1` (dtzb head read by the loop, 4/0 44 vs 4/4 52), `a2` (preadd on the value arm's SOURCE
`p`, 4/0 45 vs 4/4 53), `a3` (preadd on the arm's CHAIN-FINAL), `a4`/`a17` (merge `%out` feeding TWO
loops — 8/0 on main, 8/4 on the subject: the FIRST loop now discharges, the second cannot),
`a9` (the pre-op value measured after the loop — a CORRECT G6 refusal, the `x2_preadd_keep` control),
`a11` (4.4 select, dtzb head read by the loop). Mechanism measured from the traces: G7 arm (e) (an
unlowered tainted `mul`/`and` user of `P`) or G6 (the merge's copies are emitted AFTER the pre-op, so
`provablyBefore` fails). This is the disclosed OQ-C1D-1 / PRD §0 E2 residual class, one shape over.
**I could not turn any of them into a wrong unitary**: the diffusion variant of `a2`
(`$W/a/a16_source_p_preadd_diffusion_*`) DECLINES loudly — `cq controlled lowering: control flow under
quantum control` — on all three binaries. Round 4 neither introduced nor widened this; on `a17` it
strictly improves it (0 -> 4 discharges).

## F-C1E-3 — `DOC`, methodology: four of my own attack twins are UNFAITHFUL, not defects
`p ^ c` and `p + c` with c's low bits clear let `-O1` distribute the bit test onto the PRE-op register
in the UNROLLED spelling ONLY, so the two sources stop being the same program (measured in the traces:
`cq_template_and_i32_hl(h4, 1)` reads the PRE-op rail on the unrolled side while the rolled side reads
the post-op one). Members: `a8` (`^6`), `a10` (`+7; ^6`), `a15` (`+7; +5` -> `add %out, 12`),
`a17`. This is the documented OQ-27 / `m_xor_range` quarantine class and CLAUDE.md's own `addpost`
precedent. Recorded so a later round does not file them as compiler defects; `q4b`'s `+7` is immune
because 7 has all low bits set.

## F-C1E-4 — `DOC`: the rebase record's "0 hits" grep is self-invalidated
`rebase_c1d.md` states `grep -rn 'session-adc5590a/fix_c1d.md' --include='*.md' .` -> **0 hits**.
MEASURED on the subject: **5 hits**, all prose (the notes' §3.15 paragraph, `BRIEF_rebase_c1d.md`, and
three lines of the committed record itself — including the sentence asserting 0). The DELETION is
correct (`ls .../session-adc5590a/fix_c1d.md` -> No such file) and no live cross-reference points at a
missing path; only the claim is stale, because the file that makes it is itself committed under `.md`.

## CLEAR
* **Code shape** — `git diff main HEAD -- ir-pass/src` is `LoopLowering.cpp` + `ArithLowering.cpp`;
  mechanically filtered, exactly ONE non-comment change (`if (!P || !P->hasOneUse()) return;` ->
  `if (!P) return;`) and ZERO in `ArithLowering.cpp`.
  `git diff --stat main HEAD -- runtime tools/opcode_table.yaml include` EMPTY (owner D3).
* **No over-accept anywhere I could reach** — 0 DECLINE->ACCEPT over 610 population programs and over
  all 1690 lit fixtures; 0 decline-message changes; the only three lit OUTDIFFs are round 4's own
  accepts and each is a pure discharge (+1 `_unc`, +1 `cqrt_free`, `addc/xorc` unchanged).
* **No new immediate-slot defect** — 4 real hits over 668 programs, all bd `eqpx`, all byte-identical
  to `main`, one reproducing on the pre-3qlq ORACLE.
* **No new writer or reader of the three sets** — Inc 2's five files reference them **0** times;
  the census is the same 4 code files and 2 `AsLowered=true` sites (`LoopLowering.cpp:3214`, `:3413`).
  Inc 2's `emitValueRegion` hoist DOES create preheader ops the commit now sees — that is exactly the
  q4b capability — and the commit's backward peel provably stops at `%out`'s own `cqrt_alloc`,
  which a22/a23/a24 confirm by measurement.
* **Record truth** — every count reproduces by command; all four new goldens re-derive GOLDEN-MATCH
  with STRICT 2b `0 violation(s), 0 unproven` and both pairs byte-identical; F-C1D-3's three
  refinements are true of the tree; the conflict table is exact; all four live "in flight" sentences
  read "was in flight … NOW LANDED".

# VERDICT: CLEAR-WITH-ITEMS

---

# WHAT I RAN

| # | gate | result |
|---|---|---|
| 0 | harness control (clean + known-bad) on 3 binaries | main `q5sel` 4/0 44 vs 4/4 52 DIVERGE 8, `q4b` 4/0 52 vs 4/4 60 DIVERGE 8; subject BOTH IDENTICAL and byte-equal to **main's own unrolled twin** |
| 0b | build currency, subject | `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` EMPTY; `git status --porcelain` EMPTY; tip `aa9d702`, 17 commits over `main` b99b853 |
| 1 | code diff | ONE non-comment line pair in `LoopLowering.cpp`, 0 in `ArithLowering.cpp`; `runtime`/`tools/opcode_table.yaml`/`include` EMPTY |
| 2 | population sweep, **640 unique programs** (2175 files scanned, 1535 content dups), 610 comparable, 3 binaries | 526 identical on all three · (a) 24 subject==pre-rebase · (b) 58 subject==main (54/58 lose a `cqrt_cswap`) · **(c) 2** = `q4b_preadd_rolled`, `b4z_value_then_postadd_loop_rolled` (the predicted capability) · **0 DECLINE->ACCEPT · 0 ACCEPT->DECLINE · 0 message changes** |
| 3 | all 26 movers, discharge direction | every one GAINS `_unc`+`free`, none loses; `u1_rollback…` trace byte-identical to main (IR differs by 2 moved `declare` lines only) |
| 4 | STRICT stage 2b over the 26 movers | **0 not clean** |
| 5 | lit corpus, **1690** fixtures x {main 258d974, subject} | **0 RCDIFF · 0 DIAGDIFF · 3 OUTDIFF**, the 3 being round 4's own accepts, each +1 `_unc` +1 `free` |
| 6 | injection matrix, 44 accepts x 17 mutations (accept list re-derived, identical to the record's) | **0 MISSED / 0 DIRTY**, `clean` PASS x44; `extra_ry` caught by RYCNT 26 / CHECK 18 |
| 7 | INDEPENDENT 3-position uncontrolled-Ry injection into the 3 round-4 fixtures | **9/9 caught** by a named prefix |
| 8 | `grep -n NOROUTE-COUNT ir-pass/test/control_phase_kickback_*.ll` | **EMPTY** |
| 9 | 24 new attack programs x 3 binaries, full pipeline | 10 CAPABILITY (rolled==unrolled on the subject, DIVERGE on main), 6 pre-existing leaks (F-C1E-2), 4 unfaithful twins (F-C1E-3), 1 boundary control identical everywhere, 1 declines everywhere |
| 10 | **G6/G7-disabled mutant built by me** (`$W/mut_g67`, RC=0, currency EMPTY) | validated (`control_swap_value_ifelse_head_out_of_place.ll` RED, copies collapse onto one register); the round's own `..._value_merge_preadd_inloop.ll` stays **GREEN** => F-C1E-1; a22/a23/a24 all collapse on it |
| 11 | global immediate-slot audit over 668 programs (checker controlled on a bad module) | 7 SSA immediates: 4 = bd `eqpx` rail handles (byte-identical on main, one on the ORACLE), 3 = classical run-time immediates (regex false positives) |
| 12 | the four new goldens re-derived from their `.c` on the subject build | all **GOLDEN-MATCH**, STRICT 2b `0 violation(s), 0 unproven`, both pairs byte-identical (52=52, 60=60) |
| 13 | record truth by command | fixtures 1690 · `ctest -N` 367 · `^e2e-` 357 · `^e2e-slice-` 321 · twin gates 26 · goldens 323 · matrix 259+29 · F4 present · goldens with cswap 1 · non-i1 rz 0 · dup `fix_c1d.md` gone · 4 `e2e-value-*-twin-identical` ctest entries kept |
| 14 | F-C1D-3's three refinements | `peelInPlace*` 24 hits / 4 prose / 2 decl-defn = 18 sites, **2** at `AsLowered=true` (`:3214`, `:3413`) · `WireWalk` 1 hit, PROSE · `declineLiftedStaleRecordOps` at `:522`/`:848`, after the commit at `:363`/`:393`/`:811` |
| 15 | Inc-2 files vs the three sets | `SwapRouteEmit/SelectClassify/SwitchValueEmit/EmitInverse/Specialization` reference them **0** times |
| 16 | conflict table | `a3c1513..main` touches NONE of `LoopLowering.cpp`, `tools/loop_twin_matrix.*`, `RETIRE_SWAP_ROUTE_INC1_NOTES.md`; overlap = exactly the 5 named files |
| 17 | full `ctest` | **READ, not run** (`$SP/progress/orch_full_ctest_c1e.log`): 100% passed, 0 failed of **367**, 385.89 s, EXIT=0 |
| NOT run | any `lit`/`ctest` execution in the subject build tree (the orchestrator's run was live; and `lit --filter` beside `ctest -R ir-pass-lit` in one build tree is the rebase agent's own recorded false-red), `cq-opt-equivalence-full`, `frontend-lit`, the runtime entries, the twin matrix | |

### Methodology notes (two harness bugs I hit and caught with controls)
1. macOS `/bin/bash` is 3.2: `declare -A` is unsupported and `CQ[main]=x` writes INDEX 0, so all three
   "binaries" silently resolved to one. Caught by the known-bad control before any conclusion.
2. BSD `mktemp` needs the `X`s LAST: `mktemp /tmp/x.XXXXXX.ll` fails and yields an empty `-o` path.
   Caught by the red-green control on the first lit-sweep fixture.
Both are the class BRIEF_common warns about; neither reached a reported number.

### Addendum to F-C1E-1 (measured after the finding was written)
The round-4 **e2e** pair is blind to the same mutation: `slice_control_phase_perbit_loop_value_merge_preadd`
AND `slice_control_phase_perbit_loop_merge_preadd`, rebuilt through the FULL pipeline on the
G6/G7-disabled mutant, both **GOLDEN-MATCH** their committed `.expected.log`. So neither the lit
fixture nor its golden can witness a relaxation of the pair the in-source argument calls "the sole
net on the commit path". The one artefact in the tree that CAN is
`ir-pass/test/control_swap_value_ifelse_head_out_of_place.ll` (RED on the mutant).
