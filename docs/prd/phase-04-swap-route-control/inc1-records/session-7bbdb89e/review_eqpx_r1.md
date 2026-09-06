# review_eqpx_r1 — ADVERSARIAL LENS round 1 on the eqpx fix (READ-ONLY on $SP/wt/eqpx)

SUBJECT: `$SP/wt/eqpx` branch `eqpx-fix` @ **1333278**.
BINARIES: `main` = `$SP/bin/main-16b15b3/`, `orac` = `$SP0/wt/pre-3qlq`, `fix` = `$SP/wt/eqpx/build/ir-pass/`.
Work dir `$SP/progress/review_eqpx_r1_work/` (`W=`).

## 2026-09-06 step 0 — subject currency  [DONE]
* `git log --oneline -1` -> `1333278`; `git status --porcelain` -> **EMPTY**;
  `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` -> **EMPTY**. Binary is current.
* Read: BRIEF_common, BRIEF_review_eqpx_r1, BRIEF_fix_eqpx, fix_eqpx.md (whole, 314 lines).
* NEXT: read investigate_eqpx.md and the fix diff.

## 2026-09-06 step 1 — harness controlled + 43-program census REPRODUCED  [DONE]
* Harness copied to `$W/run.sh`, reproducers to `$W/p/`. Controls (MEASURED):
  `ctlA` main/fix -> `ACCEPT … lines=9 imm=0` both; `c1c_m_xor_and_noregion`+`tu_extf`
  -> main `ACCEPT … lines=21 imm=1`, fix `DECLINE rc=1 :: cq loop lowering: in-place rail
  op no longer provable at lowering`.
* Census `$SP/progress/r1_census_{main,fix,orac}.txt` (my own run, NOT the implementer's):
  **18 MOVED / 24 UNCHANGED**, the 18 being EXACTLY the `imm>=1` set on main; all 18 to the
  mirrored decline. Trace `cmp` over the 17 both-accept pairs: **17/17 byte-identical**;
  lowered module (modulo `ModuleID`/`source_filename`): **17/17 identical**.
  Independent of the implementer's numbers.
* Source read: the whole `git diff main -- ir-pass/src ir-pass/include`;
  `inPlaceValueRailOperand` :143; `markInPlaceRailOp` :159-188; the four writers'
  proof sites (W1 :1560-1600 `RailOps`, W2 :2100-2200 `railRoot` fixpoint,
  W3 :2560-2585 `RailMembers` via `peelInPlaceStep`, W4 :3095-3120 `P`);
  `lowerOps` Phase 1 :242-471 and Phase 2 :536-556; `CQLoweringPass.cpp` both entry points.
* ANALYTIC so far: every writer's marked BO had G2 non-null AT the marking statement
  (W1 `RailOps` / W2 `railRoot` / W3 `peelInPlaceStep` / W4 `P`), so `Rail` is never
  null in `markInPlaceRailOp` and the "no index recorded" branch is unreachable for the
  four writers. Every `cqrt_alloc`-minting stage before `lowerOps` inserts its Out into
  `taint.Tainted` (`grep -n 'Tainted.insert' ir-pass/src/{SelectMergeEmit,SwitchValueEmit,
  SwitchDataMuxEmit,ClassicalCallArmEmit,QramLowering,IOSinkLowering,RotationLowering}.cpp`),
  so a fresh rail can never look CLASSICAL to G2 at Phase 1.
* NEXT: attack programs (over-accept + over-decline), mutants, fixture integrity.

## 2026-09-06 step 2 — attacks, sweep, mutants  [DONE]
* **35 NEW attack programs** in `$W/a/` (20 over-decline `d01..d20`, 15 over-accept `x01..x15`).
  MEASURED main vs fix (`$SP/progress/r1_attack_{main,fix}.txt`):
  - **d01..d20: ACCEPT on BOTH, identical lines/imm, trace `cmp` 20/20 BYTE-IDENTICAL.**
    **ZERO over-declines found** (argument imm, volatile, global, select-of-consts, classical
    phi, classical call, zext, switch-folded, loop-variant `r^=i`, i8/i16/i64, break const+arg
    imm, two rails, in-region const+arg imm, unrolled twin, add-then-xor).
  - **9 NEW `main` members found (imm>=1), ALL declined by the fix**: `x01` `(short)y`,
    `x02` `(long long)y`, `x03` `(unsigned char)y`, `x04` `__builtin_bswap32(y)`,
    `x08` break-loop whose derived imm is ALSO in the break condition (imm=2),
    `x11` classical-`phi`-of-two-derived imms, `x12` TWO rail ops on one imm (imm=**2**),
    `x14` `(y>>1)&7`, `x15` a 4-hop derived chain.
  - **`x09` (i8) / `x10` (i16): on `main` they are NOT verify-clean — `LLVM ERROR: Broken
    module found` (rc 134, `cqrt_xorc_i8(i32 %h2, i32 %h_op)` vs the i8 immediate ABI).
    On `fix` both DECLINE cleanly.** A new, worse face of the same class.
  - `x05`/`x06`/`x07`/`x13` decline identically on both.
* **WHOLE-CORPUS SWEEP** (`$W/sweep2.sh`, both binaries over all 1707 fixtures):
  `fix` accepts=**841** declines=**866** nonstd rc=**0**; `main` accepts=**849** declines=**858**.
  Accept-set diff: **exactly the 8 new decline fixtures move accept→decline; 0 move
  decline→accept**; **OUTDIFF=0 over all 841 common accepts** (module byte-identical modulo
  `ModuleID`). Independent confirmation of RCDIFF/DIAGDIFF/OUTDIFF = 0/0/0.
* **`strictimm.py` (stricter than `immcheck.py`: EVERY non-Constant immediate, with its def)
  over all 841 `fix` accepts: 82 non-constant immediates, ZERO rail producers** — all are
  `sub i32 0, %k` counter negations, `add` counter steps, `load volatile`, `cqrt_measure_i32`
  results, and function Arguments. On `main` the same sweep reports the 8 rail-producer sites.
* **MUTANTS** (my own worktree `$W/mut` @1333278; baseline binary `cmp`-BYTE-IDENTICAL to the
  subject's, so the environment reproduces it exactly):
  - **M-A** tripwire disabled -> `lit --filter inplace_rail` **8 Passed / 8 Failed**, the 8
    Failed being EXACTLY the 8 declines, each emitting `railInImm` 1 or 2. The fixtures pin
    THIS predicate.
  - **M-B** SILENT out-of-place fallback instead of the decline -> the same **8 go RED**
    (`lit -s` 1698 Passed / 8 Failed); nothing else moves. A silent fallback IS caught — by
    the `RUN: not` inversion, NOT by the `CHECK-NOT`s (see F-E1-2).
  - **M-E** recorded index FLIPPED + the Phase-1 re-verify disabled -> **23 fixtures RED**,
    incl. 4 of the 8 new accept controls. So the index plumbing is LIVE and observable when
    WRONG, even though it is inert when merely removed.
  - **M-F** `unrollConstTripLoops` disabled -> `n01`/`n02`/`n03` DECLINE
    `cq loop lowering: loop-carried tainted value crosses iterations`. **ADJUDICATE (B)
    CONFIRMED**: the stage is the Lever-B static-K force-unroll pre-pass.
  Tree restored; `cmp` byte-identical to the fix binary again.
* **INJECTION MATRIX** over the 8 new accept fixtures, 3 injections x 2 positions = 48:
  **28 MISSED** (see F-E1-3).
* Focused e2e on the subject: `ctest -R '^e2e-slice-loop-break|perbit-loop|grover-loop|loop-phase-accum|twin-identical'`
  -> **35/35 Passed**. Counts re-measured: `ctest -N` 367 / `^e2e-` 357 / `^e2e-slice-` 321;
  goldens 323; lit files 1707; `git diff --stat main -- tests/ runtime/ tools/ include/` EMPTY.

## 2026-09-06 step 3 — second attack batch, W1 stderr audit, docs  [DONE]
* ⚠ HARNESS TRAP HIT AND FIXED: the first run of the `y*` batch was under **zsh**, which does
  not word-split, so the extra-TU argument arrived as one whitespace-prefixed string and four
  programs reported `clang: error: no input files`. Re-run under `bash -c` (BRIEF_common rule 3).
* 8 more attacks `$W/b/y01..y08`: `y01`/`y02`/`y03` (sparse `switch`, bare `%out` switch, two 6.5
  arms chained) DECLINE `cq controlled lowering: control flow under quantum control` on BOTH —
  **I could not produce a 4.5 switch data-mux member from plain C either** (same result the
  investigation records; structurally the fence is taint-based so both producers are covered).
  `y04` (const-global QROM-read immediate) ACCEPT/ACCEPT imm=0.
  **`y05`/`y06`/`y07`/`y08` are 4 NEW `main` members (imm=1), all declined by the fix** — incl.
  **`y07`, the COMMUTED `add` from PLAIN C** (`r = w + r`; `-O1` canonicalises it back, so it is
  the wrong-IMMEDIATE face, not the wrong-REGISTER one).
* **STDERR AUDIT, 23 declining programs on `fix`** (the 8 fixtures + 13 of my new members + n15/n16):
  **every one rc=1 with EXACTLY ONE stderr line and ZERO `LLVM ERROR`/`broken module`/`Assertion`/
  `Stack dump`.** Item 3 (W1 after the `continue`, with the post-`lowerOps` `lowerBreakReversePlay`
  still walking the module) is CONFIRMED: no crash, no second diagnostic, no partial emission.
* `grep -rn rewriteInPlaceValueRail ir-pass/src ir-pass/include` -> **ONE call site**,
  `OpcodeLowering.cpp:552`, reached only from `Work`; every `Work` member passed the tripwire.
  Item 2 answered: there is no second route.
* `lit -s ir-pass/test` on the SUBJECT: **1707 Discovered / 1706 Passed / 1 Expectedly Failed /
  0 unexpected**, 33.71 s. Counts: `ctest -N` 367 / `^e2e-` 357 / `^e2e-slice-` 321; goldens 323;
  `git status --porcelain` EMPTY; `git diff --stat main -- tests/ runtime/ tools/ include/` EMPTY.
* Docs read: `TaintPropagation.h` writer enumeration (CORRECT lines), `OpcodeLowering.cpp` (1b)
  comment (past tense), notes §2 star row + **§3.16** + §3.12's dated **FALSIFIED** note (row KEPT),
  PRD §0 **E13**, `CLAUDE.md` eqpx clause + the dated 1707 lit-count prefix, `ROADMAP.md` flip.
  ONE record-truth defect found — F-E1-1 below.

---

# ── HAND-BACK — review_eqpx_r1 (ADVERSARIAL LENS round 1) ──

## VERDICT: **CLEAR-WITH-ITEMS**

No over-accept. No introduced miscompile. No crash. No golden moved. Three DOC/FIXTURE items.

## FINDINGS

### F-E1-1 — DOC (record truth): a `grep` that no longer returns four, and four STALE line numbers, in the fix's own load-bearing comment blocks
The increment's stated purpose includes correcting the writer enumeration, and it corrected it in
ONE file while leaving a contradictory one in TWO others.
* `ir-pass/src/OpcodeLowering.cpp:377-386` (inside the new tripwire's Rule-0 block):
  *"FOR WHOM, by name and line (`grep -n 'InPlaceRailOps.insert(' ir-pass/src/LoopLowering.cpp`
  — FOUR sites, not three): W1 … `:1698`, W2 `:2281`, W3 `:2679`, W4 `:3084`"*.
* `ir-pass/src/LoopLowering.cpp:159-161` (`markInPlaceRailOp`'s own header): *"for all FOUR
  writers (`emitBreakForward` :1698, `tryCaseA`'s ACCEPT :2281, `collapseRailPhisIn` step (3)
  :2679, `commitOutOfLoopInPlaceOps` :3084)"*.
MEASURED on the subject tree (1333278): `grep -n 'InPlaceRailOps.insert(' ir-pass/src/LoopLowering.cpp`
-> **ONE** site, `:184`, inside the helper. The four writers are `grep -n 'markInPlaceRailOp('`
-> `:1729 :2312 :2710 :3115`. `sed -n '1698p;2281p;2679p;3084p'` shows those four lines are now a
`FusedCond` cast and three unrelated comment lines. `ir-pass/include/TaintPropagation.h:404-412`
has it RIGHT (post-fix lines AND names `markInPlaceRailOp(` as the command). Binaries: n/a (source).
Grade **DOC**. Fix: use `markInPlaceRailOp(` as the command and `:1729 :2312 :2710 :3115` in both
places, or drop the line numbers.

### F-E1-2 — DOC: the 8 decline fixtures' `CHECK-NOT`s are VACUOUS; the property is pinned by `RUN: not`, not by them
MEASURED: on a `DiagnosticInfoUnsupported(DS_Error)` decline `cq-opt` writes **0 bytes to stdout**
(`cq-opt … -S <fixture> >out 2>err` -> `rc=1`, `wc -c out` = **0**, `err` = one line). The RUN line
is `not %cq-opt … -S %s 2>&1 | %filecheck %s`, so FileCheck sees ONE stderr line and
`CHECK-NOT: cqrt_xorc_i32` / `CHECK-NOT: cq_template_xor_i32` can never fire.
The claimed property ("no silent out-of-place fallback") IS pinned, by the `not` inversion — MEASURED
with mutant **M-B** (`$SP/bin/r1-mut-MB`, the decline replaced by `InPlaceRailOps.erase(BO)` +
fall-through): the same **8 fixtures go RED** (`lit -s` 1698 Passed / 8 Failed) and nothing else moves.
PRE-EXISTING house style — the (1b) template `control_phase_kickback_reject_preloop_commit_stale.ll`
carries the identical vacuous pair. Grade **DOC**: the fixture headers should say which mechanism
does the work, so a later reader does not weaken the RUN line believing the CHECK-NOTs cover it.

### F-E1-3 — DOC/FIXTURE: injection matrix over the 8 new ACCEPT fixtures — 48 injections, **28 MISSED**
`$W/inject2.sh` (3 injections x 2 positions x 8 fixtures; clean control green everywhere).
Position-INDEPENDENT gaps (missed at BOTH head and tail):
* **an extra `cqrt_free(i32 %h)` is MISSED by ALL EIGHT fixtures — 16 of 16.** No accept fixture
  carries a `cqrt_free` count or negative, so a Rule-6 dirty free inside these accepts is invisible.
* `lowering_inplace_rail_k02_arg_imm_add_accept.ll`: an injected rail-immediate
  `call void @cqrt_xorc_i32(i32 %h, i32 %rail)` MISSED at both positions.
* `..._ctlA_const_imm_accept.ll` and `..._z36_inregion_add_accept.ll`: an extra out-of-place
  `cq_template_xor_i32` MISSED at both positions.
Structural cause (`grep '^; NOROUTE'`): only `ctlA` carries the rail-immediate negatives
`call void @cqrt_{xorc,addc}_i32(i32 %{{.*}}, i32 %{{.*}})`; `k01/k02/k03` carry only
`call i32 @cq_template_`; `n02/n03/n09/z36` carry neither. Grade **DOC/FIXTURE** — no wrong unitary,
but the accept controls under-assert the exact property the increment exists to protect. Fix: give
all 8 a whole-file `NOROUTE` pair for BOTH stems' rail-immediate form plus an `FCNT` free count.

### F-E1-4 — CLEAR (record growth): 15 MORE `main` members, two of them CRASHING, all declined by the fix
Beyond the 43-program census I built 43 new programs; **15 are new `main` members**, every one
DECLINED by the fix with the mirrored string, and none of them accepts on the fix.
Reproducers in `$W/a/` and `$W/b/`; binaries `main`=`$SP/bin/main-16b15b3`, `fix`=`$SP/wt/eqpx/build/ir-pass`.

| probe | immediate | main | fix |
|---|---|---|---|
| `a/x01_cast_short.c` | `(int)(short)y` | A lines=24 **imm=1** | DECLINE (mirrored) |
| `a/x02_cast_long.c` | `(int)((long long)y & 7)` | A 21 **imm=1** | DECLINE |
| `a/x03_cast_uchar.c` | `(unsigned char)y` | A 21 **imm=1** | DECLINE |
| `a/x04_bswap.c` | `__builtin_bswap32(y)` (curated intrinsic) | A 21 **imm=1** | DECLINE |
| `a/x08_break_imm_in_cond.c` | W1 break, derived imm ALSO in the break cond | A 223 **imm=2** | DECLINE |
| `a/x11_phi_imm.c` | classical `phi` of `y&7` / `y&3` | A 21 **imm=1** | DECLINE |
| `a/x12_two_ops_same_imm.c` | `r^w; r+w` — TWO rail ops, one imm | A 24 **imm=2** | DECLINE |
| `a/x14_shift_imm.c` | `(y>>1)&7` | A 24 **imm=1** | DECLINE |
| `a/x15_deep_derived.c` | 4-hop `((y*3+1)^2)&7` | A 29 **imm=1** | DECLINE |
| `b/y05_arm_then_two_loops.c` | one member loop + one clean loop | A 27 **imm=1** | DECLINE |
| `b/y06_imm_arg_and_out.c` | `(y&7) ^ n` (`%out` mixed with an Argument) | A 24 **imm=1** | DECLINE |
| `b/y07_add_commuted_derived.c` | **commuted `add` from PLAIN C** (`r = w + r`) | A 24 **imm=1** | DECLINE |
| `b/y08_nested_region_loop.c` | in-body region + 2 rail ops | A 53 **imm=1** | DECLINE |
| `a/x09_i8.c` | i8 rail, `(signed char)(y&7)` | **rc=134 `LLVM ERROR: Broken module found`** | DECLINE (rc 1) |
| `a/x10_i16.c` | i16 rail | **rc=134 `LLVM ERROR: Broken module found`** | DECLINE (rc 1) |

`x09`/`x10` are the class's WORSE face, not recorded anywhere: at i8/i16 the emitted
`cqrt_xorc_i8(i32 %h2, i32 %h_op)` does not even type-check against the i8 immediate ABI, so `main`
ABORTS in the verifier instead of silently miscompiling. `y07` retires half of the investigation's
"the commuted spelling is HAND-IR-ONLY" — the commuted **`add`** reaches it from plain C (as the
wrong-IMMEDIATE face; `-O1` still canonicalises the operand order, so the wrong-REGISTER half stays
hand-IR). Grade **CLEAR** (strengthens the fix); a record item for notes §3.16.

### F-E1-5 — CLEAR: ZERO over-declines over 20 purpose-built boundary programs + the census + the corpus
`$W/a/d01..d20` (Argument imm, `volatile` load, global, `select` of two constants, classical `phi`,
classical call result, `zext`ed classical, `switch`-folded classical, LOOP-VARIANT `r ^= i`,
i8/i16/i64 constants, W1 break with a constant AND with an Argument immediate, two independent
rails, in-region constant AND Argument immediate, the hand-unrolled twin, `add` then `xor`,
preheader-W4 constant): **all 20 ACCEPT on BOTH binaries with identical `lines`/`imm`, trace `cmp`
20/20 BYTE-IDENTICAL.** Plus the census's 24 unchanged programs (17 both-accept, traces and modules
17/17 identical) and the whole-corpus sweep below.

## MEASUREMENTS THAT MATTER

* **Whole-corpus sweep, both binaries over all 1707 lit fixtures** (`$W/sweep2.sh`):
  `fix` **accepts=841 declines=866 nonstd-rc=0**; `main` **accepts=849 declines=858 nonstd-rc=0**.
  Accept-set `comm`: **exactly the 8 new decline fixtures move accept -> decline; ZERO move
  decline -> accept**. **OUTDIFF = 0 over all 841 common accepts** (module byte-identical modulo
  `ModuleID`/`source_filename`). This independently reproduces the hand-back's 0/0/0 triple.
* **`strictimm.py`** (stricter than `immcheck.py` — reports EVERY non-Constant immediate with its
  definition, so a rail arriving via `phi`/Argument/`select` cannot hide): over all **841** `fix`
  accepts, **82** non-constant immediates and **ZERO** rail producers. Every one is classical:
  42 `sub i32 0, %k` break-counter negations, 15 `add` counter steps, 19 `load volatile`,
  3 `cqrt_measure_i32` results, 2 function Arguments, 1 `@g` load. On `main` the same sweep
  reports the 8 rail-producer sites (the 8 new fixtures).
* **43-program census, my own run**: 18 MOVED / 24 UNCHANGED, the 18 being exactly the `imm>=1` set,
  all to the mirrored decline; 17/17 both-accept traces and modules byte-identical.
* **`lit -s ir-pass/test`** on the subject: **1707 / 1706 Passed / 1 Expectedly Failed / 0 unexpected**.
* **Focused e2e** on the subject: `ctest -R '^e2e-slice-loop-break|^e2e-slice-control-phase-perbit-loop|
  ^e2e-phase-perbit-loop|^e2e-slice-control-grover-loop|^e2e-slice-loop-phase-accum'` -> **35/35 Passed**
  (incl. all four `slice_loop_break*` and the five perbit twin-identity gates).
* **STDERR audit**, 23 declining programs: rc=1, **exactly one** stderr line, **zero** fatals.
* Counts: `ctest -N` **367** / `^e2e-` **357** / `^e2e-slice-` **321**; goldens **323**;
  `ls ir-pass/test/*.ll` **1707**; `git status --porcelain` EMPTY;
  `git diff --stat main -- tests/ runtime/ tools/ include/` EMPTY. No new frozen symbol.

## MUTANTS (my own worktree `$W/mut` @1333278; its baseline `cq-opt` is `cmp`-BYTE-IDENTICAL to the subject's)

| mutant | change | result |
|---|---|---|
| **M-A** | the whole eqpx tripwire disabled | `lit --filter inplace_rail` **8 Passed / 8 Failed**, the 8 Failed EXACTLY the 8 declines, each emitting `railInImm` 1 or 2. The decline fixtures pin THIS predicate and nothing else. |
| **M-B** | SILENT out-of-place fallback instead of the decline | the same **8 go RED**; `lit -s` 1698 Passed / 8 Failed; nothing else moves. A silent fallback IS caught — by `RUN: not` (F-E1-2). |
| **M-E** | recorded index FLIPPED **+** the Phase-1 re-verify disabled | **23 fixtures RED**, incl. 4 of the 8 new accept controls. The index plumbing is LIVE and observable when WRONG. |
| **M-F** | `unrollConstTripLoops` disabled at BOTH entry points | `n01`/`n02`/`n03` DECLINE `cq loop lowering: loop-carried tainted value crosses iterations`. ADJUDICATE (B) confirmed. |

Tree restored after each; final `cmp` byte-identical to the fix binary.

## ADJUDICATION

### (A) The stronger form (`InPlaceRailIdx`) — **DOC: keep, argued defence-in-depth. I could not break it.**
I tried and failed to construct a Phase-2 event that flips which operand of a marked op is tainted.
Three MEASURED/structural facts, offered as the in-source argument the code currently lacks:
1. `rewriteInPlaceValueRail` has **exactly one call site** (`OpcodeLowering.cpp:552`), reached only
   from `Work`; every `Work` member passed the Phase-1 tripwire. There is no second route.
2. Every Phase-2 `Tainted` mutation is `promote(repl, orig)` (`ArithLowering.cpp:49-57`, mirrored in
   `CastLowering:40`, `CompareLowering:46`, `IntrinsicLowering:205`): it INSERTS a freshly created
   instruction and ERASES a value that was already tainted and has just been RAUW'd to it. So an
   operand UNTAINTED at Phase 1 is neither RAUW'd (RAUW only replaces uses of the tainted `orig`)
   nor inserted; and an operand TAINTED at Phase 1 is only ever replaced by another tainted value.
3. The one non-`promote` Phase-2 RAUW — `emitInPlaceReassign`'s `Site->replaceAllUsesWith(Handle)`
   — substitutes the rail handle, which G2 proved tainted.
Empirically: 43 attack programs covering every derivation route I could build (three CAST widths, a
curated intrinsic, a classical `phi`, a 4-hop chain, a second region, an Argument-mixed immediate,
a bare `%out`, a break loop, i8/i16/i64) — in **every** one the immediate is tainted at ROUND 2,
i.e. strictly BEFORE Phase 1, so **G2 alone** catches it and the index is never the thing that fires.
**But it is not decoration**: M-E shows a WRONG index reddens 23 fixtures, so the plumbing is
consumed and observable; "inert" means "agrees with `TL` on every program in the corpus".
Recommendation: **keep it**, and put argument (2)+(3) in-source at `ArithLowering.cpp:341`, which
today asserts the index is "a checked fact, not a prediction" without saying why `TL` and the index
cannot disagree.

### (B) The `n02`/`n03` loop collapse — **CONFIRMED, the orchestrator's candidate is right.**
The stage is **`unrollConstTripLoops`** (`ir-pass/src/LoopUnrollPrepass.cpp`, wired at
`CQLoweringPass.cpp:272` and mirrored in the second entry point), the Lever-B static-K force-unroll.
MEASURED with mutant **M-F**: disable it and `n01`/`n02`/`n03` DECLINE
`cq loop lowering: loop-carried tainted value crosses iterations` instead of accepting.
Gate **U4** is `loopHasInPlaceRailStructure` (`LoopLowering.cpp`): clause (a) asks
`inPlaceValueRailOperand` over the loop's BOs, clause (b) asks the header-phi in-place peel. In
`n02` the immediate `w = y & 7` derives from the **4.4 select merge**, which is tainted at ROUND 1,
so `r ^ w` is Q+Q, G2 is null, **both clauses are false and U4 admits the unroll**; LLVM's own
`UnrollLoop` simplification then folds `r^w^w^w` to `r^w`. Re-measured the parity myself on `fix`:
K=2 -> 0 `cq_template_xor_i32`, K=4 -> 0, K=5 -> 1, K=3 (the shipped `n02`) -> 1, and `n02`'s trace
is `cmp` **BYTE-IDENTICAL** to its hand-unrolled twin `$W/a/b_n02_unrolled.c`. Parity-correct
(xor involution), fewer leaked ancillas, never a dirty free. **PRE-EXISTING and not eqpx's.**
**The eqpx question asked of that stage — it can NEVER claim an eqpx-member loop, and the reason is
ORDERING**: the prepass runs at `:272` under the SAME ROUND-1 taint the loop writers read at `:363`,
so whenever a writer would mark (G2 non-null at round 1) U4 clause (a) is TRUE and the prepass
REFUSES; and whenever it unrolls, G2 was null at round 1, no writer marks, and the resulting
straight-line ops reach `lowerOps` as ORDINARY out-of-place Q+Q ops — MEASURED: `n01`/`n02`/`n03`
emit `cq_template_xor_i32` with `imm=0` on `main`, `fix` AND the oracle. Taint only grows, and
growth can only turn G2 from non-null to NULL, never the reverse, so the two claim sets are disjoint
in both directions. The prepass is **not** a fifth `InPlaceRailOps` writer (`grep` confirms 1 insert
site / 4 `markInPlaceRailOp` callers) and **not** an escape route past the tripwire.
Grade **CLEAR**; worth one sentence in notes §3.16 so the next reader does not re-derive it.

## OWNER QUESTIONS
None of my own. The implementer's OWNER QUESTION 1 is adjudicated above as **DOC — keep**; OWNER
QUESTION 2 is adjudicated as **CLEAR — named and measured** (`LoopUnrollPrepass`, gate U4).

## WHAT I RAN

| # | command | result |
|---|---|---|
| 1 | subject currency: `git log -1`, `git status --porcelain`, `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` | `1333278`, EMPTY, EMPTY |
| 2 | harness controls on `main` and `fix` (`ctlA`, `c1c_m_xor_and_noregion`+`tu_extf`) | `ACCEPT … lines=9 imm=0` both; `ACCEPT … lines=21 imm=1` (main) vs the mirrored DECLINE (fix) |
| 3 | 43-program census, `main` / `fix` / `orac` (`$W/census.sh`) | **18 MOVED / 24 UNCHANGED**, the 18 = the `imm>=1` set |
| 4 | trace `cmp` + module `diff` over the both-accept census programs | **17/17 byte-identical** each |
| 5 | 35 new attack programs `$W/a/` on both binaries | 20 over-decline controls ACCEPT/ACCEPT identical (traces 20/20 `cmp` identical); 9 new members + 2 broken-module cells declined by the fix |
| 6 | 8 more attacks `$W/b/` under `bash -c` | 4 new members declined by the fix; 3 switch shapes decline identically on both; 1 QROM accept identical |
| 7 | whole-corpus sweep, both binaries over 1707 fixtures (`$W/sweep2.sh`) | fix 841/866/0, main 849/858/0; **8 accept->decline, 0 decline->accept, OUTDIFF=0 over 841** |
| 8 | `strictimm.py` over all 841 `fix` accepts | 82 non-constant immediates, **0 rail producers** |
| 9 | `lit -s ir-pass/test` on the subject | **1707 / 1706 Passed / 1 XFAIL / 0 unexpected**, 33.71 s |
| 10 | `ctest -R '^e2e-slice-loop-break\|perbit-loop\|grover-loop\|loop-phase-accum\|twin-identical'` | **35/35 Passed**, 26.68 s |
| 11 | stdout-on-decline probe (`>out 2>err`) | rc=1, **stdout 0 bytes**, stderr 1 line -> F-E1-2 |
| 12 | injection matrix `$W/inject2.sh`, 8 accepts x 3 injections x 2 positions | **48 injections, 28 MISSED** -> F-E1-3 |
| 13 | stderr audit over 23 declining programs on `fix` | rc=1, 1 stderr line, 0 fatals each |
| 14 | mutants M-A / M-B / M-E / M-F (own worktree, baseline `cmp`-identical to the subject) | 8 RED / 8 RED / 23 RED / n01-n03 decline — see the table above |
| 15 | count re-measurement (`ctest -N`, `ls`, `git diff --stat`) | 367 / 357 / 321; goldens 323; lit 1707; tests/ runtime/ tools/ include/ diffs EMPTY |
| 16 | source read: the whole `git diff main -- ir-pass/src ir-pass/include`, the four writers' proof sites, `lowerOps` Phase 1+2, `promote`, `emitInPlaceReassign`, both `CQLoweringPass` entry points, `LoopUnrollPrepass` U1-U8, `loopHasInPlaceRailStructure` | see the analysis above |
| 17 | docs read: notes §2 star row, §3.12 FALSIFIED note, §3.16, PRD §0 E13, `CLAUDE.md`, `ROADMAP.md` | accurate except F-E1-1 |

**NOT RUN — I make no claim about these:** the FULL `ctest` (Rule 19 — the orchestrator's gate);
`ctest -j6 -R '^e2e-'` in full (357; I ran a 35-entry focused subset — the implementer reports
357/357 and `git status --porcelain tests/` EMPTY, which I did NOT independently re-run);
`e2e-loop-twin-matrix`; `frontend-lit`; the `runtime` entries; `cq_opt_equivalence`; the
`--epic` golden multiset audit; any statevector/simulation reasoning (Rule 2 forbids it);
and I did NOT rebuild, edit or `git`-mutate `$SP/wt/eqpx` or `/Users/sorenwilkening/Desktop/CQ_lang`.

## Housekeeping for the orchestrator
* I created ONE detached mutant worktree (sanctioned by my brief):
  `$SP/progress/review_eqpx_r1_work/mut` @ `1333278`. It is RESTORED to the subject's exact
  sources and its `cq-opt` is `cmp`-BYTE-IDENTICAL to the subject's. It is registered in the
  repo's `.git/worktrees`; remove with
  `git -C $SP/wt/eqpx worktree remove --force $SP/progress/review_eqpx_r1_work/mut` when done.
* Mutant binaries kept for reproduction: `$SP/bin/r1-mut-{MA,MB,ME,MF}/{cq-opt,libCQPass.so}`.
* Attack programs: `$SP/progress/review_eqpx_r1_work/{a,b}/` (43 files). Harness copy + scripts:
  `.../run.sh`, `census.sh`, `census_a.sh`, `sweep2.sh`, `strictimm.py`, `inject.sh`, `inject2.sh`.
* Raw logs: `$SP/progress/r1_{census_main,census_fix,census_orac,attack_main,attack_fix,
  sweep_fix,sweep_main,strict_fix}.txt` and `r1_mut_*_build.log`.
