# investigate_eqpx — READ-ONLY investigation of bd test_C_libtooling-eqpx (P1)

2026-09-06 step 0: read BRIEF_common.md, BRIEF_investigate_eqpx.md, `bd show test_C_libtooling-eqpx`.
Work dir $SP/progress/investigate_eqpx_work/. READ-ONLY: no checkout/worktree/fixture/bd edits.

## step 1 (2026-09-06) — harness controlled + defect signature on 4 binaries
Harness `$W/run.sh <file.c> <main|prefix|orac|c1d> [extra TU]` (copy of `$SP1/progress/review_c1d_work/run.sh`,
`W=` re-pointed; `main` uses the FROZEN copy `$SP/bin/main-258d974/{cq-opt,libCQPass.so,libcq_*.a}`).
CONTROL (clean): `ctlA_clean_xor_const.c` (same loop, immediate `7`) -> `ACCEPT main 2b=0 lines=9`,
trace has `cqrt_xorc_i32(h1, 7)` x3 with 7 a real constant. GOOD.
KNOWN-BAD: `c1c_m_xor_and_noregion.c` + `tu_extf.c` -> ACCEPT on ALL FOUR, 21 lines, `cmp` byte-identical:
  main 258d974 == prefix (fix-c1/c17c466) == orac (52d7764) == c1d (59f6a95).
  line 15 `cq_template_and_i32_hl(h3, 7) -> h6` ; lines 16-18 `cqrt_xorc_i32(h1, 6)` <- bare 6 == h6's HANDLE ID.
  h6 never `_unc`'d, never freed. STRICT 2b: `5 rail mint(s) of which 5 left allocated, 1 cqrt_free site(s):
  1 verified, 0 violation(s), 0 unproven`.  DEFECT SIGNATURE CONFIRMED, PRE-EXISTING.

## step 2 (2026-09-06) — the ADD/XOR asymmetry LOCATED: it is `clang -O1`, not the pass
Measured, not argued:
* `m_add_and_noregion.c` (the reproducer with `r=r^w` -> `r=r+w`): stage-1 `@slice` has **NO LOOP**.
  `-O1`'s IndVarSimplify exit-value rewrite closed-forms the affine add-recurrence:
  `%10 = mul nuw nsw i32 %9, 3 ; %11 = add i32 %3, %10` and LoopDeletion removes the loop.
  So the `add` is never an in-loop rail op and no `InPlaceRailOps` writer ever sees it.
  Trace: `cq_template_mul_i32_hl(h6,3) -> h7 ; cq_template_add_i32(h1,h7) -> h8` + both `_unc` + frees. CORRECT.
* `c1c_m_add_and.c` (the SAME with an in-body region): the loop SURVIVES (it holds the region) but
  `-O1` still SINKS the whole `r += w` recurrence into the exit block (`%13 = add i32 %3, %12` in block `%10`).
  CORRECT for the same reason.
* XOR has no SCEV recurrence, so the loop keeps `%19 = xor i32 %18, %9` in the body.
* **HAND-IR SEPARATION (one opcode).** `p/hand_add_from_xor.ll` = the XOR reproducer's OWN stage-1 module with
  `%19 = xor i32 %18, %9` -> `%19 = add i32 %18, %9`, nothing else. Result on ALL FOUR binaries:
  ACCEPT, 21 lines, byte-identical, `call void @cqrt_addc_i32(i32 %h2, i32 %h_op)` with
  `%h_op = call i32 @cq_template_and_i32_hl(i32 %out, i32 7)` -> trace `cqrt_addc_i32(h1, 6)`.
* **FOUR PLAIN-C ADD MEMBERS** that defeat the exit-value rewrite with ONE extra body op:
  `a1_add_gate_in_body` (`r=r+w; r=cq_theta(r,.1);`), `a2_add_two_offsets` (`r=r+w; r=r^1;`),
  `a3_add_xor_mixed` (`r=r^3; r=r+w;`), `n08_add_region_gate_in_body` (same, with an in-body region).
  All four ACCEPT with `cqrt_addc_i32(h?, <handle id>)` on all four binaries.
=> The ADD stem is correct **BY ACCIDENT** (a frontend transform removes the shape), NOT by any fence that
   reasons about the immediate. The record's "no `add` spelling we tried reaches it" is falsified.

## step 3 (2026-09-06) — census across 4 binaries, refined detector, W1 reachability
Detector rewritten as `$W/immcheck.py` (IR-level, CONSERVATIVE): a `cqrt_{addc,xorc}_<W>(h, imm)` counts
only when `imm` is an SSA value DEFINED BY `@cqrt_alloc_*` or `@cq_template_*`. The first (shell) version
over-reported the 7.4 break machinery's own classical `sub i32 0, %k` immediates — corrected.
35 programs x 4 binaries; every ACCEPT trace byte-identical main == prefix == orac == c1d (`cmp`).
NEW measured facts beyond the record:
* **W1 `emitBreakForward` (LoopLowering.cpp:1698) is a FOURTH reachable writer** — `n15/n16` ACCEPT with
  `cqrt_xorc_i32(h6, 5)` where 5 == `cq_template_and_i32_hl(h2,7) -> h5`. Its own immediate test (`:1547-1549`)
  checks DOMINANCE only, never classicality.
* **The immediate need NOT be derived**: `n04`/`n16` use the BARE 6.5 `%out`. That taint arrives at
  `lowerControlRegions` (`ClassicalCallArmEmit.cpp:209` (`UntaintedMergeRails` at `:219`), pipeline `:376`), one stage EARLIER than
  `repropagateControlMerges` (`:409`). TWO growth events in the window, not one.
* Producers measured: 6.5 classical-call arm YES; 4.5 switch data-mux — `-O1` folds both my switches to
  `select`, so it arrives as the 4.4 select merge, whose `%out` is tainted at ROUND 1 -> NOT a member
  (`n01/n02` imm=0); Inc-2 value merge NOT a member (`n03`, tainted at round 1).
* The COMMUTED (wrong-REGISTER) variant exists — hand-IR `hand_xor_commuted.ll`: `cqrt_xorc_i32(h6, 1)` and
  `cqrt_measure_i32(h6)` (the source's `cq_measure(r)` measures the `and` rail; `r`'s register never touched).
  Plain-C spellings (`n19`,`n20`,`n21`) all canonicalize back at LLVM 19 -O1 -> HAND-IR-ONLY as measured.
* `sub` is safe BY A FENCE: `inPlaceValueRailOperand` (LoopLowering.cpp:145-146) admits add/xor ONLY.
* Blast radius: 0 of the tree's 319 goldens (19 numeric-collision suspects, all 19 adjudicated to real source
  constants). Over the whole session-2 lowered corpus (4134 `.s2.ll`), 10 distinct programs ever show a rail in
  an immediate slot: the 6 eqpx reproducers + the 4 F-C1B-1 `z*` (round-2-binary-only, fixed on main).
* CAPABILITY CONTROLS for the fix's cost: `k01` (Argument immediate), `k02`, `k03` (volatile-load immediate)
  all ACCEPT today through the loop writers with a NON-Constant classical immediate.

# ── HAND-BACK — investigate_eqpx (READ-ONLY; nothing edited, nothing committed) ──

Binaries, all named: **main** = `$SP/bin/main-258d974/{cq-opt,libCQPass.so}` (frozen copy of the
`main`-258d974 build) · **prefix** = `$SP1/wt/fix-c1` (c17c466 = the Inc-1-landed / pre-Inc-2 tree) ·
**orac** = `$SP0/wt/pre-3qlq` (52d7764) · **c1d** = `$SP1/wt/c1d` (59f6a95, the unlanded round-4 branch).
Harness `$SP/progress/investigate_eqpx_work/run.sh` (copy of `$SP1/progress/review_c1d_work/run.sh`,
`W=`/case table re-pointed), controlled first with a clean program (`ctlA_clean_xor_const.c`, ACCEPT 9
lines, `cqrt_xorc_i32(h1, 7)` with a real 7) and with the known-bad reproducer. 43 programs
(41 `.c` + 2 hand `.ll`), 4 binaries. Detector `immcheck.py` (IR-level, conservative).

## 1. The defect signature on three (four) binaries

Reproducer `c1c_m_xor_and_noregion.c` + `tu_extf.c` (`int ext_f(int a){return a+100;}`), 2 TU via `llvm-link`.

| binary | status | trace | signature |
|---|---|---|---|
| main 258d974 | ACCEPT, `opt` rc 0, verify-clean, STRICT 2b `5 rail mint(s) … 0 violation(s), 0 unproven` | 21 lines | `cq_template_and_i32_hl(h3, 7) -> h6` then `cqrt_xorc_i32(h1, 6)` x3 |
| prefix c17c466 (pre-Inc-2) | ACCEPT, same 2b | 21 lines, `cmp` byte-identical to main | same |
| orac 52d7764 (pre-3qlq) | ACCEPT, same 2b | 21 lines, `cmp` byte-identical to main | same |
| c1d 59f6a95 (round 4) | ACCEPT, same 2b | 21 lines, `cmp` byte-identical to main | same |

Lowered IR (identical on all four): `%out = call i32 @cqrt_alloc_i32(i32 0)` ;
`%h_op = call i32 @cq_template_and_i32_hl(i32 %out, i32 7)` ;
`call void @cqrt_xorc_i32(i32 %h2, i32 %h_op)` — **a quantum rail handle in the ABI's
classical-immediate slot**, printed by the trace runtime as the bare decimal `6` = `h6`'s handle id.
`h6` is never `_unc`'d and never freed. **Arithmetically:** `y ∈ {5, ext_f(7)=107}`, `w = y&7 ∈ {5,3}`,
so the source computes `r^w^w^w = r^w ∈ {r^5, r^3}` *correlated with y*; the circuit computes `r^6`,
a value the source never produces on either branch, on a register never entangled with `y`
(`cqrt_measure_i32(h1)` at line 19 measures it). Plus the leaked `h6` which-path record.
**Witness that it is a wrong unitary and not a convention:** the hand-unrolled twin
`u01_xor_and_unrolled.c` ACCEPTs on main AND orac and emits the CORRECT out-of-place
`cq_template_xor_i32(h1, h6) -> h7` + `and_i32_hl_unc` + `free(h6)` — rolled ≠ unrolled, and
unrolled is right. (Not a byte-identity twin: `-O1` folds `r^w^w^w` to one xor.)

STRICT stage 2b is structurally blind for the reason it always is in this family: rule (A1) examines
the immediate slot **per rail at a `cqrt_free`**, and `h1` is MEASURED, not freed, so its write set is
never looked at.

## 2. The ADD/XOR asymmetry — LOCATED, and it is `clang -O1`, not the pass

**The cause is `-O1`'s IndVarSimplify exit-value rewrite of the affine add-recurrence, not any fence.**
Neither G2/G4/G5/G6/G7 nor the dtzb opcode set nor `rewriteInPlaceValueRail`'s `TL = Tainted.count(L)`
differs between the stems: both writers ask the SAME predicate, `inPlaceValueRailOperand`
(`LoopLowering.cpp:143-155`), whose opcode gate is `Op != Add && Op != Xor -> nullptr` — add and xor
are admitted identically.

Evidence, in order of strength:

* **One-opcode hand-IR separation.** `p/hand_add_from_xor.ll` is the XOR reproducer's OWN stage-1
  module with `%19 = xor i32 %18, %9` changed to `%19 = add i32 %18, %9`, nothing else.
  Result on ALL FOUR binaries: ACCEPT, 21 lines, byte-identical,
  `call void @cqrt_addc_i32(i32 %h2, i32 %h_op)` -> trace `cqrt_addc_i32(h1, 6)`.
  **The pass treats the two stems identically.**
* **What `-O1` does instead.** For `r += w` in a bounded loop, stage-1 `@slice` has **no loop at all**:
  `%10 = mul nuw nsw i32 %9, 3 ; %11 = add i32 %3, %10` — the recurrence is closed-formed and
  LoopDeletion removes the loop, so the `add` is never an in-loop rail op and no writer sees it.
  With an in-body region (`c1c_m_add_and.c`) the loop SURVIVES (it holds the region) but the whole
  `r += w` recurrence is still SUNK into the exit block (`%13 = add i32 %3, %12` in block `%10`).
  XOR has no SCEV recurrence, so `%19 = xor i32 %18, %9` stays in the body.
* **Four plain-C ADD members**, each defeating the exit-value rewrite with ONE extra body op —
  `a1_add_gate_in_body` (`r=r+w; r=cq_theta(r,.1);`), `a2_add_two_offsets` (`r=r+w; r=r^1;`),
  `a3_add_xor_mixed` (`r=r^3; r=r+w;`), `n08_add_region_gate_in_body` (the same with an in-body
  region, i.e. through writer W3). All four ACCEPT with `cqrt_addc_i32(h?, <handle id>)` on all four
  binaries.

**So the ADD stem is correct BY ACCIDENT** — a frontend transform removes the shape from the pass's
view — **not by any fence that reasons about the immediate.** §3.12's table row
"`c1c_m_add_*` -> no" and its caveat "no `add` spelling we tried reaches it" are now falsified by
five spellings (four plain C + one hand IR). **`sub`, by contrast, is safe BY A FENCE:**
`inPlaceValueRailOperand`'s opcode gate excludes it, and a plain-C in-loop `r -= w` declines loudly
(`n07_sub_gate_in_body`: `cq loop lowering: loop-carried tainted value crosses iterations`, all four).

**Bonus, and worse:** the COMMUTED spelling mutates the WRONG REGISTER, exactly as F-C1B-1's did.
Hand IR `p/hand_xor_commuted.ll` (`%19 = xor i32 %9, %18`) emits `cqrt_xorc_i32(h6, 1)` x3 and
`cqrt_measure_i32(h6)` — the source's `cq_measure(r)` measures the `and` rail, and `r`'s register is
never touched or measured. Three plain-C spellings (`n19`, `n20`, `n21`) all canonicalize the phi back
to the LHS at LLVM 19 `-O1`, so the wrong-REGISTER half is **HAND-IR-ONLY as measured**; the
wrong-IMMEDIATE half is plain-C reachable.

## 3. The four `InPlaceRailOps` writers (all line numbers on 258d974)

MEASURED: `grep -rn 'InPlaceRailOps.insert(' ir-pass/src` -> exactly **4** sites.

| # | writer | `file:line` (insert) | runs at | its own fence | proves "the OTHER operand stays classical"? | reachable? |
|---|---|---|---|---|---|---|
| W1 | `emitBreakForward` (7.4 break, via `tryBreak`) | `LoopLowering.cpp:1697-1698` | `lowerLoops`, `CQLoweringPass.cpp:363` | E1–E15: rail-chain shape via `inPlaceValueRailOperand` (`:1543`), fan-out/linear lineage (`:1559-1570`), escape==rail (E13), mint-read (E15). Its ONE immediate test (`:1547-1549`) is `DT.dominates(ImmI, ExitMerge)` — **position, for the reverse-play; never classicality** | **NO** | **YES — `n15`, `n16`, all 4 binaries** |
| W2 | `tryCaseA` ACCEPT ("round 1's `railRoot` marking" — the SAME site) | `LoopLowering.cpp:2277-2281` | `lowerLoops`, `:363` | L1 quantum exit, L2 in-body tainted control, the `railRoot` fixpoint (`:2110`, `inPlaceValueRailOperand`), CLOSURE, and `staleRailRecordRead` (`:2264`) | **NO** | **YES — the flagship (`c1c_m_xor_and_noregion`, `n04`, `n05`, `n06`, `a1/a2/a3`), all 4 binaries** |
| W3 | `collapseRailPhisIn` step (3) | `LoopLowering.cpp:2677-2679` | `collapseFlattenedLoopRails`, `:393` **and again** inside `repropagateControlMerges` (`TaintPropagation.cpp:1649`) | fan-out guard (`:2623`, `kMsgRailFanout`), step (2b) `staleRailRecordRead` (`:2653`), `railPhiRootMint` clause (0) | **NO** | **YES — `c1c_m_xor_{and,mul,add1}`, `n08`, all 4 binaries** |
| W4 | `commitOutOfLoopInPlaceOps` (pre-loop / preheader) | `LoopLowering.cpp:2972` | via `invariantRegisterRoots` from `collapseFlattenedLoopRails` (`:393`, and the onward call) | **FENCED by round 3**: (1a) monotone `isa<Constant>(Imm)` at `LoopLowering.cpp:2968` + `P->hasOneUse()` + the whole M-C fence; (1b) LOUD tripwire re-asking that fence at `lowerOps` (`OpcodeLowering.cpp:325-333`, `"cq loop lowering: pre-loop in-place op no longer provable at lowering"`) | **YES** (an `isa<Constant>` can never become tainted; the argument is checked, not assumed) | **NO — `n09`, `n10`, `z23/z26/z27/z29` all imm=0 on main** |

**Record-truth item (not a decision).** `TaintPropagation.h:377` and `RETIRE_SWAP_ROUTE_INC1_NOTES.md`
§2's ⭐ row (~line 984) both enumerate the other writers as *"round 1's `railRoot` marking,
`tryCaseA`'s ACCEPT, `collapseRailPhisIn` step (3)"*. The first two are **ONE site** (`:2281`, whose
loop body iterates `railRoot`), and the genuinely unlisted third is **`emitBreakForward` (`:1698`,
the 7.4 break path)** — which this investigation measured to be a reachable member. The record names a
writer that does not exist separately and omits one that does.

**Consumer, for completeness.** `OpcodeLowering.cpp:428` dispatches
`taint.InPlaceRailOps.count(BO) || InPlaceReassign.count(BO)` to `rewriteInPlaceValueRail`
(`ArithLowering.cpp:307-331`), which re-derives the operand pick a SECOND time at Phase 2 with
`bool TL = taint.Tainted.count(L)` (`:328`) — under a `Tainted` that `promote()` (`:49-57`) is
mutating as Phase 2 runs.

**Why the taint moves, precisely.** Pipeline order: `lowerLoops` `:363` (W1, W2) ->
`detectControlRegions`/`lowerControlRegions` `:376` -> `collapseFlattenedLoopRails` `:393` (W3, W4) ->
`repropagateControlMerges` `:409` -> `lowerRotations`/`lowerOps` `:535/:536`. There are **TWO**
taint-growth events in that window, not the one the bd issue names:
* **E1, `:376`** — `ClassicalCallArmEmit.cpp:209` (`UntaintedMergeRails` at `:219`) / `SwitchDataMuxEmit.cpp:144` (`UntaintedMergeRails` at `:151`) do
  `taint.Tainted.insert(Out)` at emission, so the BARE merge value becomes a quantum handle. This is
  after W1/W2 and before W3/W4. Measured members: `n04`, `n16` (no derivation at all).
* **E2, `:409`** — `repropagateControlMerges` (gated on `taint.UntaintedMergeRails`, whose only two
  writers are those same two emitters) taints everything DERIVED from `%out`. Members: all the
  `y&7` / `y*3` / `y+1` spellings.

## 4. Reachability census (43 programs; `A/<lines>/imm<n>` = ACCEPT / trace lines / rail-in-immediate sites)

`orac n/a` = the program uses the register-free `void cq_phi(double)` and does not compile on the
pre-3qlq header; the session-2 lens already showed the old-surface twin
(`c1c_w2o_bodyxor_r2derived_oldsurface`) reproduces on the oracle.
**Every ACCEPT's trace is `cmp` byte-identical across main / prefix / orac / c1d.**

| probe | writer | stem | immediate | region in body | main | prefix | orac | c1d | verdict |
|---|---|---|---|---|---|---|---|---|---|
| `c1c_m_xor_and_noregion` | W2 | xor | `y&7` (6.5) | no | A/21/**1** | A/21/**1** | A/21/**1** | A/21/**1** | **MEMBER** |
| `n05_xor_mul_noregion` | W2 | xor | `y*3` | no | A/21/**1** | A/21/**1** | A/21/**1** | A/21/**1** | **MEMBER** |
| `n06_xor_add1_noregion` | W2 | xor | `y+1` | no | A/21/**1** | A/21/**1** | A/21/**1** | A/21/**1** | **MEMBER** |
| `n04_bare_out_xor_noregion` | W2 | xor | **bare `%out`** | no | A/20/**1** | A/20/**1** | A/20/**1** | A/20/**1** | **MEMBER (new class)** |
| `a1_add_gate_in_body` | W2 | **add** | `y&7` | no | A/24/**1** | A/24/**1** | A/24/**1** | A/24/**1** | **MEMBER (new stem)** |
| `a2_add_two_offsets` | W2 | **add** | `y&7` | no | A/24/**1** | A/24/**1** | A/24/**1** | A/24/**1** | **MEMBER (new stem)** |
| `a3_add_xor_mixed` | W2 | **add** | `y&7` | no | A/24/**1** | A/24/**1** | A/24/**1** | A/24/**1** | **MEMBER (new stem)** |
| `hand_add_from_xor` (hand IR) | W2 | **add** | `y&7` | no | A/21/**1** | A/21/**1** | A/21/**1** | A/21/**1** | **MEMBER — the one-opcode separation** |
| `hand_xor_commuted` (hand IR) | W2 | xor | `y&7` | no | A/21/**1** | — | A/21/**1** | — | **MEMBER, wrong REGISTER** |
| `c1c_m_xor_and` | W3 | xor | `y&7` | yes | A/50/**1** | A/50/**1** | n/a | A/50/**1** | **MEMBER** |
| `c1c_m_xor_mul` | W3 | xor | `y*3` | yes | A/50/**1** | A/50/**1** | n/a | A/50/**1** | **MEMBER** |
| `c1c_m_xor_add1` | W3 | xor | `y+1` | yes | A/50/**1** | A/50/**1** | n/a | A/50/**1** | **MEMBER** |
| `n08_add_region_gate_in_body` | W3 | **add** | `y&7` | yes | A/53/**1** | A/53/**1** | n/a | A/53/**1** | **MEMBER (new stem)** |
| `n15_break_w1_xor_r2derived` | **W1** | xor | `y&7` | break loop | A/223/**2** | A/223/**2** | A/223/**2** | A/223/**2** | **MEMBER (new writer)** |
| `n16_break_w1_xor_bareout` | **W1** | xor | **bare `%out`** | break loop | A/222/**2** | A/222/**2** | A/222/**2** | A/222/**2** | **MEMBER (new writer)** |
| `n19/n20/n21` commuted plain C | W2 | xor | `y&7`/`y+1` | no | A/**1** | — | — | — | MEMBER (wrong immediate; `-O1` canonicalizes the operand order back) |
| `m_add_and_noregion` | — | add | `y&7` | no | A/24/0 | A/24/0 | A/24/0 | A/24/0 | correct (SCEV closed form, out-of-place Q+Q) |
| `c1c_m_add_and` | — | add | `y&7` | yes | A/53/0 | A/53/0 | n/a | A/53/0 | correct (recurrence sunk to the exit block) |
| `c1c_w1_bodyadd_r2derived`, `z36` | — | add | `y&7`/`y*3` | yes | A/50,47/0 | A/0 | n/a | A/0 | correct (same) |
| `m_sub_and_noregion` | — | sub | `y&7` | no | A/24/0 | A/24/0 | A/24/0 | A/24/0 | correct |
| `n07_sub_gate_in_body` | — | sub | `y&7` | no | **DECLINE** `cq loop lowering: loop-carried tainted value crosses iterations` | same | same | same | fenced (dtzb admits add/xor only) |
| `n01_switch_datamux_xor_noregion` | — | xor | `y&7` (switch) | no | A/30/0 | A/30/0 | A/30/0 | A/30/0 | correct — `-O1` folds the switch to `select`, so it is the **4.4 select merge**, tainted at ROUND 1 |
| `n02_select_merge_xor_noregion` | — | xor | `y&7` (4.4) | no | A/21/0 | A/21/0 | A/21/0 | A/21/0 | correct (tainted at round 1) |
| `n03_valuemerge_xor_noregion` | — | xor | `y&7` (Inc-2 value merge) | no | A/21/0 | A/21/0 | A/21/0 | A/21/0 | correct (tainted at round 1) |
| `n18_switch5_xor_noregion` | — | xor | 5-case switch | no | **DECLINE** `cq controlled lowering: control flow under quantum control` | same | same | same | declines |
| `n11_switch_datamux_xor_region`, `n17_bare_out_xor_region` | — | xor | — | yes | **DECLINE** `cq loop lowering: loop-carried tainted value crosses iterations` | same | same | same | safe direction (already tainted when W3 looks) |
| `n12/n13_break_*_r2derived` | — | xor/add | `y&7` | break | **DECLINE** `cq loop lowering: early break body is not a provable rolled single-rail loop` | same | same | same | declines |
| `n14_xor_i64_noregion` | — | xor | `y&7` (i64) | no | **DECLINE** `cq controlled lowering: value-arm swap-route under quantum control` | same | same | same | declines |
| `n09_preheader_xor_r2derived`, `n10_preheader_add_r2derived` | W4 | xor/add | `y&7` | preheader | A/47/0 | A/47/0 | n/a | A/47/0 | **correct — round 3's (1a) fence holds** |
| `ctlA_clean_xor_const` | W2 | xor | `7` (Constant) | no | A/9/0 | A/9/0 | A/9/0 | A/9/0 | ACCEPT control |
| `k01_xor_arg_imm` | W2 | xor | **Argument** | no | A/6/0 | — | — | — | ACCEPT control — `cqrt_xorc_i32(%h, %1)`, a NON-Constant CLASSICAL immediate |
| `k02_add_arg_imm` | W2 | add | **Argument** | no | A/9/0 | — | — | — | ACCEPT control |
| `k03_xor_volatile_imm` | W2 | xor | **volatile load** | no | A/6/0 | — | — | — | ACCEPT control |
| `u01_xor_and_unrolled`, `u02_bare_out_xor_unrolled` | — | xor | `y&7` / bare | unrolled | A/21,18/0 | — | A/0 | — | the CORRECT twin (out-of-place Q+Q) |

**Producers.** The defect needs a merge whose value is CLASSICAL at the writer and QUANTUM at
`lowerOps`. That is exactly `taint.UntaintedMergeRails`, whose only writers are
`ClassicalCallArmEmit.cpp:209` (`UntaintedMergeRails` at `:219`) (6.5 classical-call arm) and `SwitchDataMuxEmit.cpp:151` (4.5 switch
data-mux). The 4.4 select merge and the Inc-2 value merge are **NOT** producers — measured, `n02`/`n03`
imm=0 — because their result is already tainted at round 1. Both of my plain-C switches were folded to
`select` by `-O1`, so I did **not** produce a 4.5 data-mux member from plain C; I do not claim one
either way (unmeasured).

## 5. Blast radius of deferral

* **Is there a round-1-only spelling? NO.** The op must have exactly one tainted operand when the
  writer asks (`inPlaceValueRailOperand`'s `TL == TR -> nullptr`, `LoopLowering.cpp:151-153`) and two
  when `rewriteInPlaceValueRail` picks (`ArithLowering.cpp:328`). Taint only grows, so a member
  REQUIRES a growth event strictly between the two — and the only ones in that window are E1 (`:376`,
  the merge `%out` itself) and E2 (`:409`, its derivations). Both come from the same two emitters.
  So the population is exactly: **a 6.5 classical-call arm or a 4.5 switch data-mux whose `%out`, or
  any value derived from it, is the immediate of an in-loop in-place `add`/`xor` claimed by W1, W2 or
  W3.**
* **The tree's goldens: ZERO members.** A member's emitted gate necessarily prints as
  `cqrt_{addc,xorc}_<W>(hN, M)` with `M` the id of a handle minted earlier in the same trace, so a
  scan for that numeric collision is a sound SUPERSET. Over all **319** `tests/e2e/*.expected.log`
  (`tracecheck.py`) it flags **19** goldens; reading each source, all 19 are real constants —
  `p = p ^ 2` / `p = p ^ 1` (7 `slice_control_value_*`), `q = q ^ 5` and the break idx bookkeeping
  (4 `slice_loop_break*`), `q += off` with `off = 3` (2 grover), `int s = r + 1` (2 derived-base),
  `(hu>>23)-127` (2 libm). **0 members. The defect is in no shipped golden.**
* **The session-2 population: 10 programs, all already known.** `immcheck.py` over every lowered
  module session 2 left on disk — **4134** `*_work/out/*.s2.ll` across 13 work dirs (from ~2011 `.c`
  probe files) — reports a rail in an immediate slot for exactly **10 distinct programs**:
  the 6 eqpx reproducers (`c1c_m_xor_and_noregion`, `c1c_m_xor_and`, `c1c_m_xor_mul`,
  `c1c_m_xor_add1`, `c1c_w2_bodyxor_r2derived`, `c1c_w2o_bodyxor_r2derived_oldsurface` — on EVERY
  binary tag including `orac`) and the 4 F-C1B-1 `z*` programs (`z23`, `z26`, `z27`, `z29` — on the
  `fix`/`fix2` round-2 tags ONLY, i.e. the class round 3 fixed).
* **What stays reachable if deferred:** any program of the shape above. It is not exotic — the
  flagship is 6 lines of plain C, it needs no `cq_phi` and no region in the loop, and `n04` shows the
  immediate can be the merge value itself. It is invisible to `opt -verify`, to the golden byte-diff
  (no golden has it), and to STRICT stage 2b, and it has been on `main` since before this epic.

## 6. The proposed fix, made concrete (NOT implemented)

**Site.** `ir-pass/src/OpcodeLowering.cpp`, Phase 1, in the `isa<BinaryOperator> || isa<UnaryOperator>`
branch, **immediately after** the existing (1b) `PreLoopCommittedInPlaceOps` block that ends at
`:333`, and **before** the M-C block at `:340`.

**It must be a SECOND predicate at the SAME site, not the existing tripwire widened.**
`inPlaceFenceHolds`' G5 second disjunct —
`if (LI.getLoopFor(Site->getParent()) || blockCanRepeat(Site->getParent())) return false;`
(`ArithLowering.cpp:646-648`) — is **not** gated by `IgnoreSelfMarking` (only the `InPlaceRailOps`
self-marking disjunct at `:644-646` is), and every W1/W2/W3 member is inside a loop by construction.
Re-asking the whole fence would therefore decline **100 %** of them, shipped ones included. So the
widened re-ask is **G2 alone** — `inPlaceValueRailOperand(BO, taint) != nullptr`, the same exported
predicate the writers used (`LoopPlan.h:332`; `OpcodeLowering.cpp` would gain
`#include "LoopPlan.h"`, which it does not have today) — under FINAL taint:

```
if (auto *BO = dyn_cast<BinaryOperator>(&I);
    BO && !inBennettClone && taint.InPlaceRailOps.count(BO) &&
    !taint.PreLoopCommittedInPlaceOps.count(BO))          // W4 already has its own, stronger re-ask
  if (!inPlaceValueRailOperand(BO, taint)) { diagnoseRailOpStale(BO); continue; }
```

**Diagnostic string**, mirroring the existing grammar character-for-character
(`"cq loop lowering: pre-loop in-place op no longer provable at lowering"`):
> `cq loop lowering: in-place rail op no longer provable at lowering`

**Why a silent fallback to out-of-place is NOT sound** (the bd memory
`fix-that-predicts-a-later-stage-must-reverify-there`, and §3.11's (1b) argument verbatim): the
writer's marking is what LICENSED the rest of the loop transformation, and that permission already
stands in the module — `markIfIterationLocal`'s `taint.IterationLocalBlocks`, the collapsed rail phi
(irreversibly erased), `taint.ClaimedRailRoots`, and for W1 the whole forward break transform plus the
post-lowering `lowerBreakReversePlay` stage that will re-emit this op's adjoint. Lowering this one op
out of place into a fresh per-iteration rail leaves every one of those on a premise that no longer
holds — the X1 cross-iteration dirty rail the marking exists to prevent. Lowering nothing and exiting
non-zero is the only disposition that keeps them consistent (Rule 1 — no third path).

**The 8h7d.5 question — "when you widen a set, ask what OTHER set was computed over the same closure".**
`taint.InPlaceRailOps` is read at **six** places besides the Phase-2 dispatch:
`railValueConsumerDisposition` (`LoopLowering.cpp:206`, the `InPlace` cell),
`inPlaceFenceHolds` G5 first disjunct (`ArithLowering.cpp:644`), `commitOutOfLoopInPlaceOps`'
already-committed skip (`:2958`), the rollback (`:3299`), and the `LoopPlan.h` peel rules.
The load-bearing one is **`railValueConsumerDisposition`**, because its `InPlace` cell feeds
(a) the Rule-8 fan-out guard (which counts `Unproven`) and (b) `collectRailGates`' forward extension —
the 8h7d.5 F-1/F-3 rail-gate/rail-record machinery. A **decline-only** widening does not narrow that
set and therefore changes nothing for accepting programs; but a *silent removal from the set* would
make `collectRailGates` stop following the op, so a rail record read past it would be judged FRESH
when it is STALE — **reopening 8h7d.5 F-1**. That is a second, independent reason the disposition must
be a decline.
The other half of the same question, and the one this proposal should also answer: **G2's operand pick
is computed TWICE** — once by the writer, once again by `rewriteInPlaceValueRail`
(`ArithLowering.cpp:328`) at Phase 2, from a `Tainted` that `promote()` (`:51-52`) is mutating as
Phase 2 runs. Adding a Phase-1 re-ask without making the emitter CONSUME that answer leaves three
computations of one predicate at three program points — the exact shape of F-1/F-3. The stronger form
records the proven rail **operand INDEX** (`DenseMap<Instruction*, unsigned>`; an INDEX, never a
`Value *` — a pointer keyed at one stage and read at another is the bd `drbq` Inc-1 dangling defect,
and RAUW replaces operands in place without reordering them) and has `rewriteInPlaceValueRail` use it
instead of re-deriving `TL`.

**Red-green fixture list** (each RED on 258d974 — it accepts today with a rail in the immediate slot —
and GREEN as a loud decline after; the `RUN: not … | FileCheck` mirrors the string character-for-character):

*DECLINE, one per reachable (writer × stem × immediate-class) cell — 8:*
1. W2 · xor · derived (`c1c_m_xor_and_noregion` stage-1) — the flagship.
2. W2 · xor · **bare `%out`** (`n04`) — pins that E1 at `:376`, not only E2 at `:409`, moves the answer.
3. W2 · **add** (`hand_add_from_xor.ll`, or `a1` from plain C) — pins that the stem is not the fence.
4. W3 · xor · derived (`c1c_m_xor_and`).
5. W3 · **add** (`n08`).
6. W1 · xor · derived (`n15`) — **also the crash-risk fixture**: W1 has a post-`lowerOps` stage
   (`lowerBreakReversePlay`), and a Phase-1 `continue` leaves the marked op un-lowered in a module that
   stage still walks. If it needs `taint.StaleDeclined`-style suppression, this fixture is what shows it.
7. W1 · xor · bare `%out` (`n16`).
8. the COMMUTED wrong-REGISTER variant (`hand_xor_commuted.ll`) — hand IR, and its header must say so.

*ACCEPT controls — without these a blanket refusal of every marked op passes the decline half — 7:*
`ctlA_clean_xor_const` (Constant immediate) · **`k01_xor_arg_imm`** and **`k03_xor_volatile_imm`** (the
two that separate "G2 alone" from "`isa<Constant>(Imm)`") · `k02_add_arg_imm` · `n09`/`n10` (W4,
unchanged, its own tripwire still owns them) · `n02`/`n03` (a 4.4 select / Inc-2 value merge in the
module — the discriminator that the fence is about TAINT, not about "there is a merge here") ·
`z36` / `c1c_w1_bodyadd_r2derived` (in-region add, unchanged).
*e2e:* **no new golden is required and no existing golden may move** — that invariance is the gate
(measured above: 0 of 319 goldens carries the signature). Optionally one accept slice for `k01`.

**Over-decline cost of THIS fix: ZERO measured programs.** G2 under final taint returns non-null
whenever the op still has exactly one tainted operand — which is every correct program, including the
three with a non-Constant CLASSICAL immediate (`k01` Argument, `k02` Argument, `k03` volatile load; all
ACCEPT today, all still G2-true). Measured proxy: `railInImm == 0` on every one of the 319 goldens,
on all 26 correct accepts of my census, and on all 4134 session-2 lowered modules except the 10 known
members. The only programs that would newly decline are the members, which are wrong today — the
Prime-Directive direction, not an over-decline. *(The capability genuinely lost is the shape itself:
an in-loop rail op against a 6.5/4.5 merge value has no correct ROLLED lowering today — its correct
form is the out-of-place Q+Q per iteration, which is the X1 cross-iteration decline — so a loud
decline is the honest disposition, and the hand-unrolled spelling still compiles correctly.)*

**Contrast — the writer-side monotone analogue (`isa<Constant>(Imm)` at W1/W2/W3, round 3's (1a)
applied to the loop writers) COSTS REAL CAPABILITY:** `k01`, `k02`, `k03` all ACCEPT today with an
Argument / volatile-load immediate, and `emitBreakForward`'s own comment
(`LoopLowering.cpp:1530-1537`) says dtzb DELIBERATELY accepts any untainted immediate including a
loop-variant one, refusing only what fails the reverse-play dominance test. Three measured losses
against zero for the consumer-side re-ask. Do not ship (1a) at the loop writers.

**The ALTERNATIVE the brief asks about — re-ask G2 at the WRITER, i.e. re-run the loop writers'
marking after `repropagateControlMerges`. It is the once-only-stage mistake again, for three reasons:**
1. **The writers MUTATE.** `tryCaseA` and `collapseRailPhisIn` collapse and ERASE rail phis;
   `emitBreakForward` performs the whole forward break transform. "Re-running" them after `:409` is
   not a re-ask — the facts they derived from are gone. Making it a real re-ask means splitting each
   writer into a fact half and a mutation half: a large refactor of the Rule-13 core, i.e. exactly the
   surface where 8 findings landed in 6 rounds.
2. **It only moves the window, it does not close it.** `repropagateControlMerges` itself calls
   `detectAndLowerOnwardControl`, which mints NEW `%out2` rails and taints more (that is why
   `collapseFlattenedLoopRails` is already called a second time from `TaintPropagation.cpp:1649`);
   and after ANY writer position `lowerRotations` (`:535`) and Phase-2 `promote()` still mutate
   `Tainted` before `rewriteInPlaceValueRail` reads it. The only program point at which the answer
   cannot go stale is the consumer.
3. **It is the shape the bd memory names.** "A stage that PREDICTS a later stage's decision must have
   a MONOTONE commit-time fence PLUS a LOUD tripwire at the consumer that re-asks the SAME predicate
   under final state." A second writer round is a better prediction, not a re-verification. Shipping
   it *instead of* the consumer tripwire would be the once-only-stage class a sixth time. (A second
   writer round *in addition to* the tripwire is defensible as a capability-preserving optimisation —
   it would re-accept some programs the tripwire declines — but it is a separate, later increment and
   must never be the fence.)

**Estimated size.** `OpcodeLowering.cpp` (+1 diagnostic helper, ~12 code lines, one `#include`, a
Rule-0-sized comment block); `TaintPropagation.h` (correct the writer enumeration; optionally
`InPlaceRailIdx` for the stronger form); `ArithLowering.{h,cpp}` (~15 lines) only if the operand-index
plumbing is taken; **15 lit fixtures** (8 decline + 7 accept controls); **0 new goldens, 0 golden
churn** (that is the gate); `retire-swap-route-PRD.md` §0 + `RETIRE_SWAP_ROUTE_INC1_NOTES.md` (a new
§ recording the three record-truth corrections below). One implementation round + **two adversarial
rounds + a clearance** — the C-1 history on this exact function is 8 findings over 6 rounds, two of
them introduced by a fix; budget accordingly.

## Record-truth items (facts, not decisions — for whoever writes the landing docs)
1. **The writer enumeration is wrong in two places.** `TaintPropagation.h:377` and notes §2's ⭐ row
   (~line 984) list "round 1's `railRoot` marking, `tryCaseA`'s ACCEPT, `collapseRailPhisIn` step (3)".
   The first two are ONE site (`LoopLowering.cpp:2281`); the unlisted one is `emitBreakForward`
   (`:1698`), and it is a MEASURED member (`n15`, `n16`).
2. **"DERIVED from a `%out`" over-narrows the class.** The bare `%out` reaches it (`n04`, `n16`), and
   that taint arrives at `lowerControlRegions` (`:376`), one stage earlier than
   `repropagateControlMerges` (`:409`). Two growth events in the window, not one.
3. **§3.12's ADD row is falsified.** Four plain-C add spellings plus a one-opcode hand-IR mutation
   reach it. The row's own caveat ("read 'no add spelling we tried reaches it'") was right to hedge;
   the hedge is now spent, and the located cause is `-O1`'s exit-value rewrite, not any fence.

## OWNER QUESTION
None. Nothing found contradicts a PRD §2 owner decision (D1–D7); no new `cqrt_*`/`cq_template_*`
symbol is implied by any option above. The one decision outstanding is the brief's own: fix now vs
defer, addressed in the recommendation below.

## Recommendation (one paragraph)
**Fix now, and fix it as a decline-only consumer tripwire.** The change is small and one-directional:
one predicate at one existing site in `OpcodeLowering.cpp` (~12 code lines, one include, one
diagnostic string), 15 lit fixtures, zero new runtime symbols, zero new goldens and — measured — zero
golden churn and zero correct programs newly declined; it strictly turns four confirmed
silent-miscompile classes into loud declines and touches nothing else. What argues against deferring
is that this investigation **grew the disclosed population three ways in one afternoon** — a fourth
writer (`emitBreakForward`), a whole stem the record recorded as unreachable (`add`, four plain-C
spellings, correct today only because `-O1` happens to closed-form the recurrence), and a producer
path needing no derivation at all (the bare `%out`, tainted one pipeline stage earlier than the bd
issue says) — which is the signature of a class whose bound nobody has yet established, and the
record's *previous* bound on it was the sentence round 3 measured false. The counter-argument for
deferral is real but weak: nothing shipped is affected (0 of 319 goldens, 0 of the 4134-module
session-2 corpus beyond the 10 known reproducers), so this is latent rather than active, and the fix
lands in `LoopLowering`/`ArithLowering`/`OpcodeLowering` — the exact function that has produced 8
findings over 6 adversarial rounds, two of them introduced by a fix, so it cannot be done cheaply
(budget two adversarial rounds and a clearance, not one). **If it is deferred, the thing that stays
reachable is a six-line plain-C program — a `if(q>k) y=f(...)` classical-call arm (or a switch
data-mux) whose merged value is XORed or added into a register inside any bounded loop — that
compiles at `opt` exit 0, verify-clean, STRICT stage-2b clean, prints a plausible trace, and computes
a different unitary; and the deferral note must be amended with the three record-truth items above,
because as written the record under-states the class by one writer, one stem and one producer path.**

## step 4 (2026-09-06) — citations re-verified on 258d974
`grep`-verified: 4 `InPlaceRailOps.insert(` sites (LoopLowering.cpp 1698 / 2281 / 2679 / 2972);
G5 loop test `ArithLowering.cpp:646-648` (NOT gated by `IgnoreSelfMarking`, whose only clause is `:643-645`);
`taint.Tainted.insert(Out)` at `ClassicalCallArmEmit.cpp:209` / `SwitchDataMuxEmit.cpp:144`,
`UntaintedMergeRails.insert(Out)` at `:219` / `:151` (the ONLY two writers of that set);
`staleRailRecordRead` call sites `:2264` (W2) and `:2653` (W3); `kMsgRailFanout` `:2193` / `:2623`;
`rewriteInPlaceValueRail`'s second operand pick `ArithLowering.cpp:328`; Phase-2 dispatch
`OpcodeLowering.cpp:428`; `collapseFlattenedLoopRails` called from `CQLoweringPass.cpp:393` AND
`TaintPropagation.cpp:1649`; `inPlaceValueRailOperand` declared `LoopPlan.h:332`, `OpcodeLowering.cpp`
does NOT include `LoopPlan.h` today. READ-ONLY: no checkout, worktree, fixture, golden or bd issue edited.
