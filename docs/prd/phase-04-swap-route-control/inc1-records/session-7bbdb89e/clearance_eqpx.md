# clearance_eqpx — the ONE Rule-13 CLEARANCE review of the eqpx fix (READ-ONLY on $SP/wt/eqpx)

SUBJECT: `$SP/wt/eqpx` branch `eqpx-fix` @ **e752877** (orchestrator correction: 727e8e1 + one record-file commit).
BINARIES: `main` = `$SP/bin/main-16b15b3/`, `orac` = `$SP0/wt/pre-3qlq`, `fix` = `$SP/wt/eqpx/build/ir-pass/`
(= `$SP/bin/eqpx-1333278/`). Work dir `$SP/progress/clearance_eqpx_work/` (`W=`).

## 2026-09-06 step 0 — read + subject currency  [DONE]
* Read WHOLE: BRIEF_common, BRIEF_clearance_eqpx, BRIEF_fix_eqpx, BRIEF_review_eqpx_r1, BRIEF_fix_eqpx_b,
  BRIEF_review_eqpx_r2, BRIEF_fix_eqpx_c; progress fix_eqpx.md, review_eqpx_r1.md, fix_eqpx_b.md,
  review_eqpx_r2.md, fix_eqpx_c.md. CLAUDE.md is in context.
* MEASURED in `$SP/wt/eqpx`: `git log --oneline -1` -> `e752877`; `git status --porcelain` -> EMPTY;
  `git diff --stat 727e8e1..e752877` -> ONE file, `inc1-records/session-7bbdb89e/fix_eqpx_c.md` (+215) — record only;
  `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` -> EMPTY;
  `cmp build/ir-pass/cq-opt $SP/bin/eqpx-1333278/cq-opt` -> IDENTICAL; `libCQPass.so` IDENTICAL;
  `git diff --stat main..HEAD -- tests/e2e runtime tools/opcode_table.yaml include` -> EMPTY;
  `git diff 1333278..HEAD -- ir-pass/src ir-pass/include` non-comment lines -> EMPTY.
* Orchestrator's full ctest log: `TIP=beb34e0`, `100% tests passed, 0 tests failed out of 367`, 350.23 s, `EXIT=0` (READ).
* NEXT: read investigate_eqpx.md + the code diff; then items 1-6 of the brief.

## 2026-09-06 step 1 — the ruling, by construction (brief item 1)  [DONE]
* `bd show test_C_libtooling-eqpx` NOTES, OWNER RULING 2026-09-06: "decline-only consumer tripwire (G2 alone re-asked at
  lowerOps for every InPlaceRailOps member not in PreLoopCommittedInPlaceOps; NOT the full fence; NOT the writer-side
  isa<Constant>)". Read the whole `git diff main..HEAD -- ir-pass/src ir-pass/include` (4 files: TaintPropagation.h,
  ArithLowering.cpp, LoopLowering.cpp, OpcodeLowering.cpp).
* Confirmed by construction: (i) the new block sits AFTER the (1b) `PreLoopCommittedInPlaceOps` block and BEFORE the M-C
  block in `lowerOps` Phase 1 (`OpcodeLowering.cpp:443-462`); (ii) it asks `inPlaceValueRailOperand(BO, taint)` — G2
  alone (`LoopLowering.cpp:143-155`: add/xor, <=64-bit int, EXACTLY one tainted operand) — never `inPlaceFenceHolds`;
  (iii) on failure: `diagnoseRailOpStale` = `DiagnosticInfoUnsupported(DS_Error)` with `I->getDebugLoc()` and the string
  `cq loop lowering: in-place rail op no longer provable at lowering`, then `continue` (not enqueued into `Work`, so
  never rewritten/erased — no fallback path exists in the block); (iv) no writer's fence is touched — the LoopLowering
  hunks are the helper `markInPlaceRailOp` (+40 lines at :156), four one-line call replacements, and one
  `InPlaceRailIdx.erase` beside the pre-existing rollback erase; (v) no `isa<Constant>` at any loop writer; (vi) no
  re-ask at the writers. Beyond the ruling: the INDEX form (`TaintSet::InPlaceRailIdx`, written in the helper,
  re-verified in the tripwire via `IdxDisagrees`, consumed in `rewriteInPlaceValueRail`) — disclosed by the implementer
  as OQ-1, argued in-source at `ArithLowering.cpp:328-378`.
* Rail identity at each writer verified: W4 passes `P`, which `inPlaceValueRailOperand` returned (so P IS an operand);
  W1/W2/W3 let the helper ask G2 at the marking statement — W1 marks at step (1) BEFORE any mint/RAUW (`:1735-1738`),
  W2 at ACCEPT before `Tainted.erase(P)` (`:2321` vs `:2355`), W3 at step (3) before step (4)'s phi erase (`:2719` vs
  `:2749`). If G2 were null there, no index is recorded and the tripwire/emitter fall back to G2-alone/`TL` (sound).
* `lowerOps` is called ONCE per TaintSet per run (`run` :536, `runOnFunction` :853 are separate entry points;
  `Specialization.cpp:969` passes a FRESH `cloneTaint`, and no clone pipeline calls `lowerLoops`), so the pointer-keyed
  `InPlaceRailIdx` is never read after its keys are erased in Phase 3.

## 2026-09-06 step 2 — nothing accepted got worse, nothing correct got refused (brief item 2)  [DONE]
* MY OWN corpus sweep `$W/corpus.sh` + `$W/corpus_cmp.py` (both binaries, all 1707 fixtures, uniform RUN):
  **pre-existing 1691: RCDIFF=0 · DIAGDIFF=0 · OUTDIFF=0**; the 16 new: RCDIFF=8 (accept->decline 8, decline->accept 0),
  the 8 being exactly `lowering_reject_inplace_rail_stale_*`. main accepts 849 / fix accepts 841.
  `immcheck.py` over all 841 fix accept modules: **841 x railInImm=0**; over main's 849: exactly the 8 new declines >=1.
* `git diff --stat main..HEAD -- tests/e2e runtime tools/opcode_table.yaml include` -> EMPTY.
* 43-reproducer census (`$W/census.sh`, 42 programs = 40 .c + 2 hand .ll; the two .ll are pre-linked and take NO extra
  TU) on main / fix / orac: **main vs fix: 18 MOVED (all to the mirrored decline: a1 a2 a3 c1c_m_xor_{add1,and,and_noregion,mul}
  hand_add_from_xor hand_xor_commuted n04 n05 n06 n08 n15 n16 n19 n20 n21) · 24 UNCHANGED · 17 both-accept, trace cmp
  17/17 byte-identical**; `immcheck` over the 17 fix accepts: 0 rail producers. orac vs main: 26 both-accept traces
  26/26 identical; orac reproduces railInImm>=1 on all 14 members it compiles (11 programs S1FAIL on the pre-3qlq header:
  the void `cq_phi` ones — the investigation's `n/a`). PRE-EXISTING confirmed by my own run.
* The lenses' 47 attack programs (`$W/attack.sh`, r1's a/ + b/, TUs by ext_f/ext_g/ext_h): main vs fix **13 MOVED**
  (x01 x02 x03 x04 x08 x11 x12 x14 x15 y05 y06 y07 y08, every one accept-with-imm>=1 on main -> the mirrored decline) +
  x09/x10 rc 134 `LLVM ERROR: Broken module found` (`Call parameter type does not match … cqrt_xorc_i8(i32 %h2, i32 %h_op)`)
  on main -> rc 1 decline on fix; **25 both-accept, traces 25/25 byte-identical**, 0 rail producers; the 20 `d*`
  boundary controls all ACCEPT/ACCEPT identical. Reproduces both lenses exactly.
* MY OWN 8 probes (`$W/my/`): TWO NEW MEMBERS — `p_k_cmp_zext_imm` (immediate `(y > 6)`, a compare of the 6.5 `%out`
  zext'd: main ACCEPT 24 lines imm=1 -> fix mirrored decline) and `p_n_variant_plus_out` (`r ^= (w + i)`, a loop-VARIANT
  immediate mixed with `%out`: main ACCEPT 24 imm=1 -> fix decline); controls `p_a` (immediate = an in-loop `cq_measure`
  result) ACCEPT/ACCEPT 11 lines identical, `p_s` (arm after the loop, constant imm) 20/20 identical, `p_t` (Argument imm
  beside an unused arm) 20/20 identical; `p_c` (immediate through an alloca written in the arm) declines
  `value-arm swap-route` on BOTH, `p_m` (4.4 select imm in a W1 break loop) declines `early break body…` on BOTH,
  `p_q` (arm condition reads the rail) declines `taint escape…classical-condition phi` on BOTH. **0 over-declines.**

## 2026-09-06 step 3 — the fence is a fence (brief item 3)  [DONE]
* My own mutant tree: `git archive e752877` -> `$W/mut` (no git mutation), configured + built; BASELINE `cq-opt` and
  `libCQPass.so` `cmp`-IDENTICAL to `$SP/bin/eqpx-1333278/` (the environment reproduces the subject exactly).
* **M1** = the tripwire block DELETED (20 lines, `OpcodeLowering.cpp:443-462`, real deletion not `false &&`), rebuilt
  (`BUILD_M1_EXIT=0`, saved `$SP/bin/clr-mut-M1/`). `lit ir-pass/test --filter inplace_rail` in MY build dir:
  **8 Passed / 8 Failed — the 8 Failed are EXACTLY the 8 declines**, each accepting rc 0 with railInImm 1 (six) or 2
  (the two W1 cells). Whole-corpus sweep M1 vs fix over 1707: **identical=1699, RCDIFF=8 (decline->accept 8 = the 8 new
  declines), DIAGDIFF=0, OUTDIFF=0** — nothing else moves.
* Stronger form, re-derived on the lenses' saved binaries with MY sweep: **m23** (`$SP/bin/eqpx-m23`, index re-verify +
  consume both off) vs fix: **identical=1707, 0/0/0** (inert when REMOVED); **ME** (`$SP/bin/r1-mut-ME`, index FLIPPED)
  vs fix: **identical=1683, RCDIFF=14 accept->decline, OUTDIFF=10 — 24 move** (live when WRONG). RULING: argued-inert,
  disclosed honestly, not decoration; not pinned by a red-green of its own.

## 2026-09-06 step 4 — the class is closed for the four writers; 8h7d.5 (brief item 4)  [DONE]
* `grep -n 'markInPlaceRailOp(' LoopLowering.cpp` -> callers `:1738 :2321 :2719 :3124` (+ the def); `InPlaceRailOps.insert`
  code sites -> **1** (the helper); `rewriteInPlaceValueRail(` call sites -> **1**. `railValueConsumerDisposition`
  (`LoopLowering.cpp:246`) is NOT in the diff. The only `InPlaceRailOps.erase` is the pre-existing rollback (`:3451`),
  now paired with `InPlaceRailIdx.erase` (`:3455`). No silent removal anywhere in the diff.
* Structural argument re-derived: the tripwire asks G2 at Phase 1, which is AFTER every taint-growth event in the
  pipeline (`:363`..`:535`, incl. E1 `:376`, E2 `:409`, QRAM, rotations); between Phase 1 and the Phase-2 rewrite the
  only `Tainted` mutations are `promote(repl, orig)` (4 defs) and `emitInPlaceReassign`'s RAUW to the proven handle —
  neither can taint an operand untainted at Phase 1 nor un-taint the rail. So a marked op reaches the emitter with
  exactly one tainted operand or not at all.

## 2026-09-06 step 5 — fixtures + drivers  [DONE]
* 8 declines: `RUN: not %cq-opt … 2>&1 | %filecheck`; 8 accepts: ONE `%t.cqd0.ll` + prefixes IMMCNT/NOROUTE/FCNT(/XCNT);
  `grep 'NOROUTE-COUNT'` over the 16 -> EMPTY; the commuted fixture's header says HAND IR (line 6).
* Injection matrix, MY copy of r2's `inject3.sh` (5 kinds x 2 positions x 8): **80 injections, 0 MISSED**, clean control
  green 8/8, each kind 16/16 caught.
* Stock `/usr/local/opt/llvm@19/bin/opt` vs `cq-opt` on the 8 declines: rc 1 both, stderr byte-identical (1 diagnostic +
  blank), stdout 0 bytes.
* ⚠ F-CL-1 (DOC): a module with TWO members in two functions prints exactly ONE `error:` line and exits rc 1 on BOTH
  drivers, and 866/866 declining fixtures on fix have exactly one `error:` line — the driver EXITS AT THE FIRST
  `DS_Error` (`cq_opt_main.cpp` installs no diagnostic handler; the LLVMContext default exits). So "lowerBreakReversePlay
  prints NOTHING / no second diagnostic" is true because that stage NEVER RUNS after the decline, not because it copes;
  the W1 fixtures' three `break reverse-play` CHECK-NOTs are as unreachable under this driver as the vacuous pair.

## 2026-09-06 step 6 — record truth (brief item 6)  [DONE]
* Counts by command in the subject: lit .ll **1707**; goldens **323**; `ctest -N` **367** / `^e2e-` **357** /
  `^e2e-slice-` **321**; twin matrix **259** rows + **29** quarantine cells; cswap goldens **1**.
* Read: `TaintPropagation.h` writer block (four by name+line, FIXED paragraph), `OpcodeLowering.cpp` (1b) past-tense +
  the tripwire's Rule-0 block, notes §2 ⭐ row (:984, FIXED), §3.12 FALSIFIED note (:1869, row kept), §3.16 whole,
  PRD §0 E13, `CLAUDE.md` eqpx clause + 1707 lit line, `ROADMAP.md` FIXED blockquote. §3.16's "WHAT IS NOT COVERED"
  says the fence is exactly as wide as G2 and names the M-C route as untouched; no sentence claims the class is closed
  beyond the four writers. Orchestrator's full-ctest log READ: TIP=beb34e0, 367/367, 350.23 s, EXIT=0 — the binary is
  cmp-identical at e752877.
* The session README (`inc1-records/session-7bbdb89e/README.md`) is the ORCHESTRATOR's and is stale (3 rows; no
  mention of fix_eqpx_b/c, review_r2, briefs/, citation_sweep/) — already flagged by fix_eqpx_c.

---

# ── HAND-BACK — clearance_eqpx (the Rule-13 CLEARANCE of the eqpx fix) ──

## VERDICT: **CLEAR-WITH-OWNER-QUESTIONS**

The branch may be committed to `main`. No over-accept, no introduced miscompile, no crash, no golden moved, no over-decline
found — every load-bearing claim re-derived by me from the tree and with programs on named binaries. The fix is exactly the
owner's ruling (a decline-only consumer tripwire re-asking G2 alone at `lowerOps` for every `InPlaceRailOps` member W4 did
not commit; not the full fence; not the writer-side `isa<Constant>`; no silent fallback; no re-ask at the writers), plus
ONE disclosed thing beyond the ruling's letter — the operand-INDEX form — which is honestly disclosed, measured inert when
removed and live when wrong, and is the one standing OWNER QUESTION (keep/drop; either answer is a 0-behaviour change on
the whole corpus, so it does not gate the landing). One DOC item of my own (F-CL-1) and one record item for the
orchestrator (the stale session README).

SUBJECT: `$SP/wt/eqpx` @ **e752877** (727e8e1 + one record-file commit, `git diff --stat 727e8e1..e752877` = ONE file under
`inc1-records/session-7bbdb89e/`); code tip 1333278; `cq-opt` AND `libCQPass.so` `cmp`-IDENTICAL to `$SP/bin/eqpx-1333278/`;
`git status --porcelain` EMPTY; currency EMPTY; `git diff 1333278..HEAD -- ir-pass/src ir-pass/include` non-comment EMPTY;
`git diff --stat main..HEAD -- tests/e2e runtime tools/opcode_table.yaml include` EMPTY.
BINARIES: `main` = `$SP/bin/main-16b15b3/`, `orac` = `$SP0/wt/pre-3qlq` (52d7764), `fix` = the subject build,
`M1` = `$SP/bin/clr-mut-M1/` (mine), `m23` = `$SP/bin/eqpx-m23/`, `ME` = `$SP/bin/r1-mut-ME/`.

## FINDINGS

### F-CL-1 — DOC (record truth): "no second diagnostic, no crash after the `continue`" is TRUE FOR A DIFFERENT REASON than the record gives
Reproducer: `$W/out/two_decl.ll` = `lowering_reject_inplace_rail_stale_w2_xor_derived.ll` with its `@slice` duplicated as
`@slice2` (two members in two functions). Binaries: `fix` cq-opt AND stock `/usr/local/opt/llvm@19/bin/opt` + `libCQPass.so`.
MEASURED: rc 1 and EXACTLY ONE `error:` line on both; on `M1` the same module ACCEPTS with `railInImm=2` (both members
lowered). And 866/866 declining fixtures in my fix sweep carry exactly one `error:` line. So the driver exits at the FIRST
`DS_Error` (`cq_opt_main.cpp` installs no diagnostic handler; the LLVMContext default exits on DS_Error, and stock `opt`
behaves identically here). Consequence: after the tripwire's `diagnose` the pass NEVER REACHES `lowerBreakReversePlay`;
§3.16's "THE W1 CRASH-RISK CELL", the two W1 fixture headers ("pinned by three CHECK-NOTs"), fix_eqpx.md row 11 and
review_r1 item 3 attribute the clean disposition to the stage, when the stage never runs. The three `break reverse-play`
negatives are live for FileCheck but unreachable under this driver — the same status as the vacuous pair F-E1-2 documented.
Grade **DOC**: no behaviour, no unitary; the observable contract (rc != 0, 0 bytes emitted) holds on both drivers. Fix: one
sentence in §3.16 and in the two W1 fixture headers ("the driver exits at the first DS_Error, so the post-`lowerOps` stage
is never reached; the negatives are a tripwire for a driver that continues").

### F-CL-2 — CLEAR (record growth): TWO MORE plain-C members, both declined by the fix; 0 over-declines in my own probes
`$W/my/p_k_cmp_zext_imm.c` (immediate `(y > 6)`, a compare of the 6.5 `%out` zext'd — a FLAG rail in the immediate slot):
`main` ACCEPT 24 lines **imm=1** -> `fix` the mirrored decline. `$W/my/p_n_variant_plus_out.c` (`r ^= (w + i)`, a
LOOP-VARIANT classical immediate mixed with `%out`): `main` ACCEPT 24 **imm=1** -> `fix` decline. Controls: `p_a` (immediate
= an in-loop `cq_measure` result) ACCEPT/ACCEPT 11 lines, trace byte-identical; `p_s` (arm AFTER the loop, constant imm)
20/20 identical; `p_t` (Argument imm beside an unused arm) 20/20 identical; `p_c` (imm through an alloca written in the arm),
`p_m` (4.4 select imm in a W1 break loop), `p_q` (arm condition reads the rail) decline with the SAME pre-existing string on
both. Grade **CLEAR** (strengthens the fix); worth a line in §3.16's member list.

### F-CL-3 — RECORD (orchestrator's): the session README is stale
`inc1-records/session-7bbdb89e/README.md` lists 3 rows and "three DOC/FIXTURE items closed"; the dir now holds
`fix_eqpx_b.md`, `fix_eqpx_c.md`, `review_eqpx_r2.md`, `briefs/`, `citation_sweep/`, and seven items were closed.
Already flagged by fix_eqpx_c; it is the orchestrator's file, to be written with the clearance record. Grade **RECORD**.

## THE BRIEF'S SIX ITEMS, RULED

| # | item | ruling |
|---|---|---|
| 1 | the fix is what the owner ruled | **YES, by construction** (step 1 above): G2 alone (`inPlaceValueRailOperand`), after (1b) and before M-C, `DS_Error`+`!dbg`, `continue`, no fallback branch exists, W4 excluded, no writer fence touched, no writer-side `isa<Constant>`, no writer re-ask. The INDEX form is beyond the ruling's letter, inside the investigation §6's proposal the ruling adopted, and its disclosure (OQ-1, in-source status paragraph, §3.16) is **honest** — it says "argued defence-in-depth, not a fence with a red-green of its own", which is exactly what I measured |
| 2 | nothing accepted got worse, nothing correct refused | **YES, re-run by me**: 1691 pre-existing fixtures 0/0/0; the 16 new = exactly 8 accept->decline; census 18 MOVED (all members) / 24 UNCHANGED / 17 both-accept traces identical / 0 rail producers; orac reproduces all 14 members it compiles; the lenses' 47 attacks 13 MOVED + x09/x10 rc 134->decline, 25 both-accept identical; my 8 probes 2 new members, 6 unchanged; `immcheck` 0 rail producers over all 841 fix accepts and over every accept of every census |
| 3 | the fence is a fence; the stronger form | **M1 (block deleted, built by me from `git archive e752877`, baseline cmp-identical): the 8 declines go RED (accept, railInImm 1/2), sweep vs fix identical=1699 / RCDIFF=8 = the 8 / 0 / 0 — nothing else moves.** Stronger form: **argued-inert** (m23 vs fix 1707/1707 identical; ME vs fix 24 move) — not decoration, not pinned |
| 4 | class closed for the four writers; 8h7d.5 | **YES**: 4 `markInPlaceRailOp(` callers, 1 `insert` site, 1 `rewriteInPlaceValueRail` call site; `railValueConsumerDisposition` not in the diff; the only erase is the pre-existing rollback, now paired; decline-only ⇒ the `InPlace` cell is unchanged for every module that lowers |
| 5 | every lens finding has a disposition | table below |
| 6 | record truth | counts reproduce by command (1707 / 323 / 367 / 357 / 321 / 259+29 / cswap 1); `TaintPropagation.h`, `OpcodeLowering.cpp`, notes §2 row + §3.16, PRD §0 E13, `CLAUDE.md`, `ROADMAP.md` say what the tree does; "WHAT IS NOT COVERED" bounds the fence at G2 and names the M-C route as untouched; no sentence claims closure beyond the four writers. One DOC slip (F-CL-1) |

## DISPOSITION OF EVERY LENS FINDING (brief item 5)

| finding | grade by lens | disposition | verified by me |
|---|---|---|---|
| F-E1-1 stale writer grep + 4 line numbers | DOC | FIXED (27b7800): `markInPlaceRailOp(` named in 3 places + names as durable key | `grep` -> 1 insert site, 4 callers `:1738 :2321 :2719 :3124`; the three blocks agree |
| F-E1-2 vacuous decline CHECK-NOTs | DOC | FIXED (27b7800): headers name the `not` inversion; pair kept as documentation | stdout 0 bytes on decline re-measured; M1 shows the RUN line pins it; plus F-CL-1's refinement |
| F-E1-3 accept controls under-assert (28/48 MISSED) | DOC/FIXTURE | FIXED (27b7800): FCNT/XCNT/NOROUTE pairs | my run of the 80-injection superset: **0 MISSED**, 16/16 per kind, clean control 8/8 |
| F-E1-4 15 more members incl. i8/i16 broken module + commuted `add` from C | CLEAR | recorded (§3.16, E13, CLAUDE.md, `eqpx_reproducers_r1/`) | 13 re-run by me -> all mirrored declines on fix; x09/x10 rc 134 on main (`Call parameter type does not match…`) -> rc 1 on fix |
| F-E1-5 0 over-declines / 20 boundary programs | CLEAR | recorded | all 20 ACCEPT/ACCEPT, traces 20/20 identical in my run |
| (A) stronger form inert | DOC-keep | in-source three-fact argument + honest status (beb34e0) | m23 0/1707, ME 24 moved — re-derived; **OWNER QUESTION 1 below** |
| (B) `n02`/`n03` loop collapse = `unrollConstTripLoops` U4 | CLEAR | recorded in §3.16 | analytic re-read of the ordering (:271 vs :363, same round-1 taint); n02/n03 accept identical on main/fix/orac in my census; not re-built as a mutant (NOT run) |
| F-E2-1 missing `tu_exth.c` + README rule | DOC | FIXED (3a519ae) | file present; d03/d05 need `ext_h` — my attack run supplied it and both ACCEPT 6 lines identical |
| F-E2-2 six stale `LoopLowering:<n>` citations (+4 the lens could not see) | DOC | FIXED by NAME (3a519ae), sweep committed | `OpcodeLowering.cpp` names `railValueConsumerDisposition` by name; 9 pre-existing misses left and listed |
| F-E2-3 strictimm partition 15->16 `add`, `@g` folded | DOC-trivial | FIXED | not re-counted (NOT run) |
| F-E2-4 CLAUDE.md antecedent | DOC-trivial | FIXED ("THE eqpx MEMBER — not the ⭐ clause…") | read in the CLAUDE.md diff |
| implementer OQ-2 (loop collapse) | — | adjudicated CLEAR by (B) | as above |
| fix_b OQ ((1b) template fixture's vacuous pair, on `main`) | — | OPEN, out of scope (owner/orchestrator) | **OWNER QUESTION 2** |

## OWNER QUESTIONS

### OWNER QUESTION 1 — keep or drop the operand-INDEX form (`TaintSet::InPlaceRailIdx` + `markInPlaceRailOp` + the consume)?
It goes beyond the ruling's LETTER ("G2 alone re-asked at lowerOps … decline") though it is inside the investigation §6
proposal the ruling adopted. MEASURED by me: removing both halves (m23) changes **0 of 1707** fixture outputs; a WRONG index
(ME) moves **24**, so it is consumed and live; nothing pins it with a red-green of its own. My recommendation: **KEEP** —
it retires the third independent computation of one predicate (the 8h7d.5 F-1/F-3 shape) and the in-source argument
states its status honestly. Either answer is safe to land now and to apply afterwards as a 0-behaviour change.

### OWNER QUESTION 2 — the pre-existing (1b) template fixture `control_phase_kickback_reject_preloop_commit_stale.ll` (on `main`) carries the same vacuous CHECK-NOT pair; wanted as a separate docs-only header note? (fix_eqpx_b's question, untouched by this branch and out of its scope.)

Nothing found contradicts a PRD §2 decision (D1–D7): no new `cqrt_*`/`cq_template_*` symbol, `runtime/`, `tools/opcode_table.yaml`,
`include/` untouched, 0 goldens regenerated, 0 slices added, no writer fence widened or narrowed.

## WHAT I RAN

| # | command | result |
|---|---|---|
| 1 | subject currency: `git log -1`, `git status --porcelain`, `git diff --stat 727e8e1..e752877`, `find … -newer build/ir-pass/cq-opt`, `cmp` cq-opt + libCQPass.so vs `$SP/bin/eqpx-1333278/` | `e752877`; EMPTY; 1 record file (+215); EMPTY; IDENTICAL both |
| 2 | `git diff 1333278..HEAD -- ir-pass/src ir-pass/include` non-comment filter; `git diff --stat main..HEAD -- tests/e2e runtime tools/opcode_table.yaml include` | EMPTY; EMPTY |
| 3 | the whole `git diff main..HEAD -- ir-pass/src ir-pass/include` read; `bd show test_C_libtooling-eqpx` read | ruling matched clause by clause (step 1) |
| 4 | `$W/corpus.sh` + `corpus_cmp.py` — main vs fix over all 1707 fixtures | pre-existing 1691: **0 RCDIFF · 0 DIAGDIFF · 0 OUTDIFF**; new 16: 8 accept->decline, 0 reverse |
| 5 | `immcheck.py` over all 841 fix accept modules / all 849 main accept modules | **841 x 0**; main: exactly the 8 new declines (railInImm 1 or 2) |
| 6 | `$W/census.sh` — 42 reproducers x {main, fix, orac} (+ the 2 hand .ll re-run without the extra TU) | main vs fix 18 MOVED / 24 UNCHANGED / 17 both-accept traces identical; orac: 26/26 both-accept traces identical to main, 14 members reproduce, 11 S1FAIL (void `cq_phi`) |
| 7 | `$W/attack.sh` — the lenses' 47 programs x {main, fix} | 13 MOVED + x09/x10 (rc 134 -> decline), 25 both-accept traces identical, 0 rail producers |
| 8 | `$W/my/` 8 probes of my own x {main, fix} | 2 new members declined, 3 accept/accept identical, 3 decline/decline same string |
| 9 | mutant tree: `git archive e752877` -> `$W/mut`, cmake configure + build | `BUILD0_EXIT=0`, baseline `cq-opt`/`libCQPass.so` **cmp-IDENTICAL** to the subject's |
| 10 | **M1** (tripwire block DELETED) rebuild; `lit ir-pass/test --filter inplace_rail` in `$W/mut/build`; immcheck on its 8 outputs | `BUILD_M1_EXIT=0`; **8 Passed / 8 Failed = the 8 declines**; each rc 0 with railInImm 1 or 2 |
| 11 | `$W/sweep.sh` M1 / m23 / ME over 1707 + `sweepcmp.py` vs the fix sweep | M1: identical 1699, RCDIFF 8 (= the 8), 0, 0; **m23: 1707 identical**; **ME: 24 move** (14 a->d + 10 OUTDIFF) |
| 12 | stock `opt` vs `cq-opt` on the 8 declines | rc 1 both, stderr byte-identical, stdout 0 bytes |
| 13 | two-member module (`two_decl.ll`) on fix cq-opt / stock opt / M1; `grep -c error:` over 866 fix decline errs | ONE error line + rc 1 on both drivers; M1 accepts railInImm=2; 0 of 866 have >=2 -> F-CL-1 |
| 14 | `$W/inject3.sh` (copy of r2's, 5 kinds x 2 positions x 8 accepts) on the subject | **80 injections, 0 MISSED**, clean control 8/8 |
| 15 | fixture inventory: RUN lines, `grep NOROUTE-COUNT` (EMPTY), HAND IR header line, W1 negatives | as recorded in step 5 |
| 16 | writer sites: `grep markInPlaceRailOp(` / `InPlaceRailOps.insert` / `rewriteInPlaceValueRail(`; `lowerOps(` call sites + enclosing functions; `Tainted.erase` sites; `promote` defs | 4 callers / 1 / 1; `run`:536, `runOnFunction`:853, `Specialization.cpp:969` (fresh cloneTaint); erase sites read; 4 promote defs |
| 17 | counts: `ls ir-pass/test/*.ll`, `ls tests/e2e/*.expected.log`, `ctest -N` (+ `^e2e-`, `^e2e-slice-`), twin matrix rows/cells, cswap goldens | 1707 / 323 / 367 / 357 / 321 / 259 + 29 / 1 |
| 18 | docs read: `TaintPropagation.h`, `OpcodeLowering.cpp` blocks, `ArithLowering.cpp:325-380`, `LoopLowering.cpp` four writers + helper + rollback + `commitOutOfLoopInPlaceOps`, notes §2 row / §3.12 note / §3.16 whole, PRD E13, `CLAUDE.md` + `ROADMAP.md` diffs, session README, the 5 briefs + 5 progress files + investigate_eqpx.md whole | see findings |
| 19 | the orchestrator's full ctest log | **READ, not run**: `TIP=beb34e0`, `100% tests passed, 0 tests failed out of 367`, 350.23 s, `EXIT=0` (binary cmp-identical at e752877) |

**NOT RUN — I make no claim about these:** the full `ctest` and `ctest -j6 -R '^e2e-'` (read from the orchestrator's log only;
I started no ctest in the subject tree); `lit` on the SUBJECT build tree (my lit ran in MY mutant build; the subject's 1707 /
1706 / 1 XFAIL is the implementer's and fix_b's figure); `e2e-loop-twin-matrix`, `frontend-lit`, `runtime`, `cq_opt_equivalence`,
the `--epic` golden multiset audit; a rebuild of the M-B / M-F mutants (M-B's 8-RED and M-F's U4 confirmation are the lenses',
attributed); a re-count of the `strictimm` partition (F-E2-3); any statevector/simulation reasoning (Rule 2 forbids it). I did
NOT edit, rebuild or `git`-mutate `$SP/wt/eqpx` or `/Users/sorenwilkening/Desktop/CQ_lang`, and created NO git worktree
(`git archive` only). No `git push`, no bd edit.

## Housekeeping
Work dir `$SP/progress/clearance_eqpx_work/` (`run.sh`, `p/`, `atk/`, `my/`, `mut/` (a plain `git archive` copy with a
build — NOT a registered worktree), `corpus/`, `sw_{M1,m23,ME}/`, `out/`, scripts `corpus.sh corpus_cmp.py census.sh
censuscmp.py attack.sh sweep.sh sweepcmp.py inject3.sh`). Logs: `$SP/progress/clearance_eqpx_{mut_build,corpus,census,
sweeps,attack}.log`. Mutant binary kept: `$SP/bin/clr-mut-M1/{cq-opt,libCQPass.so}`.
