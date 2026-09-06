# review_c1c — independent Rule-13 lens on the THIRD C-1 fix round (F-C1B-1 / F-C1B-2 / F-C1C-1)

Agent `review_c1c`, READ-ONLY on every checkout. All writes under
`$SP/progress/review_c1c_work/` and this file.

SUBJECT  = `$SP/wt/fix-c1` @ **dec2019** (`git status --porcelain` EMPTY; build measured current:
           `find ir-pass/src ir-pass/include ir-pass/tools -newer build/ir-pass/cq-opt` -> EMPTY;
           `strings build/ir-pass/cq-opt | grep -c 'pre-loop in-place op no longer provable at lowering'` -> 1).
FIX-2    = `$SP/progress/fix_c1c_work/{cq-opt.fix2,libCQPass.so.fix2}` (638334c; the same grep -> 0).
FIX-1    = `$SP/progress/fix_c1b_work/*.fix1` (3ec40c9).
PRE-FIX  = `/Users/sorenwilkening/Desktop/CQ_lang` @ 542d588 (never rebuilt by me).
ORACLE   = `$SP0/wt/pre-3qlq` @ 52d7764.
Harness  = `$W/run.sh` (review_c1b's, W re-pointed at my dir), 5 cases subj/fix1/fix2/fix/orac.

## Log
- step 0: read BRIEF_common, BRIEF_review_c1c, BRIEF_fix_c1c, progress/review_c1b.md,
  progress/fix_c1c.md IN FULL; the round-3 code diff `git diff 638334c HEAD -- ir-pass/src
  ir-pass/include` (5 code files, +223/-13) and the 7 new fixtures; `ArithLowering.cpp`
  `inPlaceFenceHolds` G3-G7 + `classifyInPlaceReassignment` G1/G2 +
  `inPlaceValueRailOperand`/`inPlaceReassignRailOperand`; `OpcodeLowering.cpp` lowerOps Phase 1;
  `CQLoweringPass.cpp` 320-560 (the stage order).
- step 1: HARNESS CONTROLLED on 4 binaries — `ctl_good` ACCEPT 4 lines on subj/fix1/fix2/fix/orac;
  `ctl_bad` DECLINE `cq rotation lowering: unsupported quantum-derived rotation angle` on all.
- step 2: F-C1B-1 CLOSED, re-measured myself on 4 binaries (`./run.sh p/<z>.c <bin> p/tu_extf.c`):
  z23 / z26 / z27 / z29 = 47 lines on 542d588, FIX-1 and the SUBJECT (traces BYTE-IDENTICAL,
  `cmp -s`, both directions), 51 lines with `railInImmSlot=1` on FIX-2. `grep -c
  'cqrt_addc_i32\|cqrt_xorc_i32' out/z23.*.s2.ll` -> 0 on the subject, 2 on FIX-2.
- step 3: ATTACK on the `isa<Constant>` fence — 6 plain-C + 3 hand-IR probes (`p/c1c_a*`). None
  puts a handle in the immediate slot on the subject; details in FINDINGS/§attack table.
- step 4: the tripwire's placement/exit measured directly: `cq-opt ... -S <decline fixture>` ->
  rc=1, **0 bytes of stdout**, and with `-o` the output file is NOT created. No path emits a
  module after the re-ask says "changed".
- step 5: diagnostic string mirrored character-for-character (source `OpcodeLowering.cpp:81` vs
  fixture `control_phase_kickback_reject_preloop_commit_stale.ll:57`) — verified by a python
  regex extraction of both.
- step 6: the (1b) scope control — `d1i`, `d1iu`, `d10`, `d10u`, `n1`, `z6`, `z6u` all ACCEPT and
  BYTE-IDENTICAL between FIX-2 and the subject. A body marking does not trip the tripwire.
- step 7: red-green per fixture, per prefix, on 4 binaries (`rg.sh`) — reproduces the fix
  agent's table EXACTLY (4 narrowing fixtures RED on FIX-2 only; the DECLINE RED on
  542d588+FIX-1+FIX-2; `..._chained_root_inloop` RED on the two pre-round-2 binaries;
  `..._claim_across_loops_accept_control` green everywhere).
- step 8: F-C1C-1's class ONE OPERATOR AWAY — 6 new plain-C probes (`p/c1c_v*`). FIVE are NEW
  CONFIRMED FIX-2 MISCOMPILES that the subject DECLINES with the tripwire string; one (`v2`) is
  correctly unchanged everywhere. See F-C1C-A below.
- step 9: (1a)'s monotonicity argument VERIFIED INDEPENDENTLY — `grep -rn 'Tainted\.insert('
  ir-pass/src` -> 37 lines, 2 of which are PROSE, so **35 code sites**; the declared type of
  every one is `CallInst *` / `Instruction *` / `Argument *` (checked one by one). `Tainted.erase(`
  -> 30. A `Constant` is in none of them.
- step 10: F-C1B-2 — the re-key measured on w3/w4/z32 + 7 new probes (`p/c1c_b*`).
- step 11: THE OTHER THREE `InPlaceRailOps` WRITERS — probed for the SAME staleness class.
  **REPRODUCES, and PRE-DATES the whole epic** (present on the pre-3qlq ORACLE 52d7764). See
  F-C1C-B below. NOT introduced by round 3 and NOT in its scope.
- step 12: counts by command in the subject worktree: `ls ir-pass/test/*.ll | wc -l` **1673**;
  `grep -c '^m_' tools/loop_twin_matrix.expected.txt` **257**;
  `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` **29**. READ (not run)
  `$SP/progress/orch_full_ctest_c1c.log` — **100% tests passed, 0 failed out of 348, 344.81 s,
  EXIT=0**.
- step 13: POPULATION, FIX-2 vs SUBJECT, my own 299-program corpus (271 inherited from
  fix_c1c's `p/` + 28 of mine), status normalised + trace byte-compared (`popdiff.sh`):
  **UNCHANGED = 286, MOVED = 13**, of which 1 (`c1c_a1`) is a harness artifact of MY OWN probe
  (its lowered IR is byte-identical modulo `ModuleID`; only the printed value of a
  `ptrtoint (ptr @g_tab+12 to i32)` differs, i.e. two separately linked binaries' load
  addresses). The 12 genuine moves are ALL in the refuse direction. **FIX2-DECLINE ->
  SUBJECT-ACCEPT: 0 programs. No decline string changed.**
- step 14: STRICT 2b over every accepting SUBJECT run: **215 accepts, 213
  `0 violation(s), 0 unproven`, 2 `0 violation(s), 4 unproven`, 0 violations** — the two are
  `f0_break_plain` / `f3_break_global_phase_before`, the `--allow-unproven` dtzb family.

---
# FINDINGS

## F-C1C-A — `CLEAR`. F-C1B-1 is closed, and the (1b) tripwire generalises: FIVE MORE plain-C members of the F-C1C-1 class, all WRONG on the round-2 binary, all loudly declined by the subject.

**F-C1B-1, re-measured by me on four binaries** (`./run.sh p/<z>.c <bin> p/tu_extf.c`;
`railInImmSlot` = `grep -cE 'call void @cqrt_(addc|xorc)_i32\(i32 %[A-Za-z0-9_.]+, i32 %'`):

| program | 542d588 | FIX-1 | **FIX-2** | **SUBJECT** |
|---|---|---|---|---|
| `z23_preadd_r2derived_imm` | 47 lines, 0 | 47, 0 | **51, 1** | **47, 0 — `cmp -s` IDENTICAL to FIX-1 and to 542d588** |
| `z26_preadd_r2derived_add1` | 47, 0 | 47, 0 | **51, 1** | **47, 0 — IDENTICAL to both** |
| `z27_prexor_r2derived` | 47, 0 | 47, 0 | **51, 1** | **47, 0 — IDENTICAL to both** |
| `z29_preadd_r2derived_and` | 47, 0 | 47, 0 | **51, 1** | **47, 0 — IDENTICAL to both** |

`grep -c 'cqrt_addc_i32\|cqrt_xorc_i32' out/z23.<bin>.s2.ll` -> **0** on the subject, **2** on
FIX-2. No `cqrt_{addc,xorc}` whose operand is a handle appears anywhere in the subject's
lowered IR for any of the four.

**The orchestrator asked me to attack the fix agent's own F-C1C-1 claim "one operator away".
It holds — and the class is FIVE PROGRAMS WIDER than the one `y1` the fix agent found.**
Each is plain C, `clang -O1`, single TU; each is a CONFIRMED wrong unitary on FIX-2 and a
LOUD DECLINE (`cq loop lowering: pre-loop in-place op no longer provable at lowering`) on the
subject:

| probe | the operator that moved | 542d588 / FIX-1 | **FIX-2** | SUBJECT |
|---|---|---|---|---|
| `c1c_v3_chain_midmember_measured` | a 3-deep theta chain, the MIDDLE member measured | `add_i32_hl(h0,7) -> h2`, measures `h0 h1 **h2**`, 34 lines | **`cqrt_addc_i32(h0,7)`, measures `h0 h1 h0`, 40 lines — WRONG** | DECLINE |
| `c1c_v5_chain_later_theta` | the later read is a **GATE** (`cq_theta(q,.9)`), not a measure | 34 lines, measures `…h2` | **40 lines, measures `…h0` — WRONG** | DECLINE |
| `c1c_v6_chain_xor_stem` | the **XOR** stem (`a = q2 ^ 9`) | `xor_i32_hl(h0,9) -> h2`, 33 lines | **`cqrt_xorc_i32(h0,9)`, measures `…h0`, 39 lines — WRONG** | DECLINE |
| `c1c_v4_chain_two_loops` | the chain split across **TWO** rolled loops | 60 lines, measures `h0 h1 h2 **h3**` | **72 lines, measures `h0 h1 h2 h0` — WRONG** | DECLINE |
| `c1c_v7_chain_prerecord_ret` | the later read is a **`ret`** of the pre-op name | 32 lines, loop reads `h2`, returns `h0` | **32 lines, everything on `h0`, the `ret` returns the MUTATED register — WRONG** | DECLINE |
| `c1c_v2_chain_through_inplace_add` | the wire shared through an in-place `add`, not a theta | 32 lines | 32 lines | **32 lines, UNCHANGED on all four** |

`v2` is the control that shows the tripwire does not over-fire: the wire union there is created
by `lowerOps` Phase 2 itself, and it is harmless because the later read of `q` is exactly what
forces M-C to lower `q+3` OUT of place, so the committed op lands on a fresh rail. `v7` is
worth singling out: FIX-2 emits the SAME NUMBER OF TRACE LINES as 542d588 (32) and is still
wrong — a line-count diff would have missed it; only the byte diff sees it.

**The tripwire's other properties, measured:**
* it exits before ANY output. `cq-opt … -S <the decline fixture>` -> **rc=1, 0 bytes of
  stdout**; with `-o <f>` the file is **not created**. There is no path where the re-ask says
  "changed" and a module is still emitted.
* the string is mirrored character-for-character (`OpcodeLowering.cpp:81` vs
  `control_phase_kickback_reject_preloop_commit_stale.ll:57`, extracted and compared by regex).
* **it is asked ONLY of the ops this stage committed.** `d1i`, `d1iu`, `d10`, `d10u`, `n1`,
  `z6`, `z6u` — every body-marking control the brief names — ACCEPT and are **byte-identical**
  between FIX-2 and the subject. The scoping is also structurally forced: re-asking M-C's fence
  about an IN-LOOP marking would hit G5's own loop clause and fire every time.
* red-green per fixture, per prefix, on FOUR binaries reproduces the fix agent's table exactly
  (see WHAT I RAN).

**I did NOT run the mutation cycles** (they need a rebuild of a scratch copy). For the two
halves that shipped, the four-binary red-green is a stronger discriminator and I ran it: FIX-2
**is** the "(1b) removed" binary for `control_phase_kickback_reject_preloop_commit_stale.ll`
(its immediate is the `Constant` `7`, which (1a) admits, so (1b) is the only net that can
fire), and it measures `OPT_RC=0` — RED — there.

## F-C1C-B — `CONFIRMED-MISCOMPILE`, **PRE-EXISTING** (reproduces on the pre-3qlq ORACLE 52d7764, on 542d588, FIX-1, FIX-2 **and** the subject). NOT introduced by round 3, NOT in its scope — but it FALSIFIES the record's scope sentence for the class round 3 just fenced.

Round 3 fences ONE of the four `InPlaceRailOps` writers. The record justifies leaving the
other three alone (`TaintPropagation.h`, `OpcodeLowering.cpp:300`, notes §3.11):
*"the other three writers mark a rail they PROVED with their own fences"* — and review_c1b's
own scope paragraph asserts *"the class as measured is introduced by
`commitOutOfLoopInPlaceOps`"*, on the strength of one negative probe (`z36`).

**That sentence is false. The identical defect is reachable through the LOOP writers, for the
`xor` stem, from plain C.** Minimal reproducer (`p/c1c_m_xor_and_noregion.c`, 2 TU):

```c
int ext_f(int a);                            /* second TU: return a + 100; */
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);              /* 6.5 arm -> %out; DERIVED values are
  int w = y & 7;                                tainted only at repropagateControlMerges */
  for(int i=0;i<3;i++){ r = r ^ w; }         /* in-BODY rail op, marked by tryCaseA      */
  return cq_measure(r)+cq_measure(y)+cq_measure(q); }
```

MEASURED trace (identical on ORACLE `$SP0/wt/pre-3qlq`, 542d588, FIX-1, FIX-2, SUBJECT — 21
lines, `opt` exit 0, **STRICT 2b `5 rail mint(s) of which 5 left allocated … 0 violation(s), 0
unproven`**):

```
cq_template_and_i32_hl(h3, 7) -> h6      <- w = y & 7 : a QUANTUM rail off the 6.5 out-rail h3
cqrt_xorc_i32(h1, 6)                     <- r ^= 6  : the bare decimal 6 IS h6's HANDLE ID
cqrt_xorc_i32(h1, 6)
cqrt_xorc_i32(h1, 6)
cqrt_measure_i32(h1) -> 0                <- measures a register never entangled with y
```

Lowered IR: `call void @cqrt_xorc_i32(i32 %h2, i32 %h_op)` with
`%h_op = call i32 @cq_template_and_i32_hl(i32 %out, i32 7)`. `h6` is never `_unc`'d and never
freed. This is F-C1B-1's defect **verbatim**, one writer over.

Population, all measured on the subject (and identical on 542d588 and the oracle where the
surface allows):

| probe | in-body op | derived immediate | region in the body? | handle in the immediate slot |
|---|---|---|---|---|
| `c1c_m_xor_and_noregion` | `r ^= w` | `y & 7` | no (round-1 `tryCaseA`) | **YES** |
| `c1c_m_xor_and` / `c1c_w2_bodyxor_r2derived` | `r ^= w` | `y & 7` | yes (round-2 `collapseRailPhisIn`) | **YES** |
| `c1c_m_xor_mul` | `r ^= w` | `y * 3` | yes | **YES** |
| `c1c_m_xor_add1` | `r ^= w` | `y + 1` | yes | **YES** |
| `c1c_w2o_..._oldsurface` | `r ^= w` | `y & 7` | yes, register-form `cq_phi` | **YES on the pre-3qlq ORACLE** |
| `c1c_m_add_{and,mul,add1}`, `c1c_m_add_and_noregion`, `z36`, `c1c_w1` | `r += w` | any | either | no — the correct Q+Q `cq_template_add_i32(h3, h_op5)` |

So it is an **`xor`-stem-only** asymmetry, and the `add` stem is what `z36` happened to probe.

**Root cause, and it is the same one word for word.** `rewriteInPlaceValueRail`
(`ArithLowering.cpp`) picks the rail with `bool TL = taint.Tainted.count(L)` and passes the
OTHER operand as the classical immediate, under a comment that says *"the recognizer proved
this (one tainted operand), so the selection is unambiguous"*. By `lowerOps` BOTH operands are
tainted, because the loop writers ran at `lowerLoops` (`:363`) / `collapseFlattenedLoopRails`
(`:393`) and `repropagateControlMerges` (`:409`) taints the `%out` derivation afterwards.

**Disposition.** Out of round 3's scope: it pre-dates the whole 3qlq epic, so it can neither
block this round nor be charged to it. But two record sentences must be corrected, because a
future round will read them as a bound: review_c1b's *"the class as measured is introduced by
`commitOutOfLoopInPlaceOps`"* and §3.11's/`OpcodeLowering.cpp:300`'s implication that the other
three writers' own fences settle the question. **Their fences prove the RAIL; none of them
proves the IMMEDIATE stays classical.** The natural fix is the same shape as (1b) — re-ask
G2's "exactly one tainted operand" at `lowerOps` for every `InPlaceRailOps` member (not the
whole fence, which G5 would always refuse for an in-loop site) and decline loudly — but
designing it is not a review round's call. **OWNER QUESTION / new bd issue.**

## F-C1C-C — `CLEAR`. F-C1B-2's per-loop key is a pure narrowing, it costs no legitimate cross-loop customer, and I found the construct the brief asked for.

* **The observable pin reproduces independently.** `w3_claim_across_loops_measured_gate`
  (rolled `and|lshr _hl` mints / `_unc`): 542d588 **3/0** · FIX-1 **3/0** · **FIX-2 3/3** ·
  **SUBJECT 3/0, and the subject's trace is byte-identical to 542d588's and FIX-1's.** The
  re-key REVERTS a widening round 2 introduced by accident; it is not a new over-decline.
* **`z32` has no trace-level pin at all** — it DECLINES with
  `cq uncompute: tainted handle live range crosses a loop backedge`, the SAME string, on all
  FOUR binaries. The brief's expectation ("`z32` unmarked, leak-control byte-identical to
  FIX-1") cannot be checked from a trace; the fix agent's instrumented `claimedHERE=0` and the
  `w3` pin are the real evidence, and `w3` is the one I could re-derive myself.
* **The construct the brief asks for — the same root claimed in loop A and legitimately read
  invariant in loop B with NO gate in B — is `p/c1c_b4_claimA_readB_measure_only.c`, and it is
  served by clause (ii), not clause (0): 3/3 and BYTE-IDENTICAL on all four binaries.** (Three
  earlier spellings I built, `c1c_b1/b2/b3`, all decline `cq taint escape: tainted value muxed
  by a classical-condition phi` identically on all four — loop A's zero-trip merge phi — so
  they discriminate nothing; `c1c_b1u`, the hand-unrolled b1, accepts 3/3 identically on all
  four. `c1c_b5` likewise declines identically on all four.)
* **The control holds:** `w4_claim_across_loops_two_invariants` is 3/3 and byte-identical on
  all four binaries, so the key is not a blanket refusal.
* **Every shipped customer keeps its discharge**, FIX-2 vs SUBJECT, traces IDENTICAL:
  `r33` 3/3 · `r35` 3/3 · `r40` 3/3 · `z9_r1claim_chain_ext_r2` 3/3 · `z10_two_carried_onward`
  3/3 · `r2_preadd_inv` 3/3 · `x1_preadd_noR` 3/3 · `d1_mixed_invariant_perbit_carried_r` 3/3 ·
  `y2_preadd_chained_nopreread` 3/3.
* **The key can only ever narrow, by construction:**
  `ClaimedRailRoots.count({Root, H})` is a subset of round 2's `count(Root)` for every `H`, so
  clause (0) fires strictly less often. Nothing else reads the set (`grep`: 2 writers, 1
  reader).
* **The "loop later DELETED/unrolled -> dangling key" hazard is UNREACHABLE at HEAD, measured
  by call order**: `LoopUnrollPrepass` and `recognizeCtlzIdiomLoops` run at
  `CQLoweringPass.cpp` ~:260 and :300, i.e. **before** `lowerLoops` (:363) writes the first
  claim, and no stage between the writers and the round-2 reader (:393) deletes a loop. Both
  entry points have the same order.
* **The "header is the pred of a flattened region" case IS the shipped shape, not an edge
  case**: at `clang -O1` the rotated per-bit loop's header IS the region's `Pred` (it carries
  the induction phi, the `and`/`icmp` and the conditional `br`), and `RegionFlatten` erases the
  ARM and the MERGE and splices into that header. Every `r33`/`r40`/`d1i`-shaped customer above
  therefore exercises it, and they all keep 3/3.

## F-C1C-D — `CLEAR`. The `isa<Constant>(Imm)` fence, attacked.

I could not get a handle into the immediate slot through (1a) on the subject by any of these.
All are `./run.sh` on 542d588 / FIX-2 / SUBJECT.

| attack | result on the SUBJECT | note |
|---|---|---|
| `ConstantExpr` immediate (`q + (int)(long)&g_tab[3]`) | ACCEPT, `cqrt_addc_i32(%h, ptrtoint (…))` — a genuine link-time CLASSICAL constant; correct | **byte-identical lowered IR on 542d588 and FIX-2** — M-C emits it on its own, so (1a) admitting it costs nothing new. ⚠ the trace value is a load address, so such a program's golden would not be link-stable; no golden in the tree does this |
| `Constant` that is a global address / `ptrtoint` | same as above | |
| `undef` immediate (hand-IR) | ACCEPT, ONE `cqrt_addc_i32(%h, i32 undef)` slot, no adjoint | **identical on 542d588 and FIX-2**; `declineUnpairedUndefLiterals` needs TWO slots, correctly inert |
| `poison` immediate (hand-IR) | same | same |
| vector constant | unreachable — G2's `Ty->isIntegerTy()` refuses before the fence, and `cq_theta` has no vector prototype | argued from source, not fabricated |
| `i64` immediate | ACCEPT, `cqrt_addc_i64(i32 %h, i64 7)` | in-grid |
| `i8` immediate | ACCEPT, unchanged on all binaries | |
| the op written as `and` / `or` | not committable — `inPlaceValueRailOperand` admits `Add`/`Xor` ONLY; the discharge these programs gain comes from `invariantRegisterRoots`, not from a commit, and is identical on FIX-2 and the subject | |
| the op written as `sub` (`q - volatile`) | not committable — `inPlaceValueRailOperand` returns null for `Sub` (only `inPlaceReassignRailOperand` widens to `sub`, and the commit does not call it). Lowered by M-C at `lowerOps` **byte-identically on all three binaries** | an over-decline at the commit, inherited |
| `P` becoming a different wire at round 2 (parent = a 6.5 arm's merge value) | `c1c_p1` DECLINES `value-arm swap-route under quantum control` on all four; `c1c_p2` ACCEPTs identically on all four | |
| the op's RESULT gaining a round-2 user | **structurally not a hazard**: G6/G7 walk `P->users()`, and the op's result IS the mutated rail, so a new reader of it reads the value the source names. A reader of the PRE-op value is a user of `P` and IS walked |
| the op moved INTO a loop by the flatten | no reproducer; and it does not have to be argued — the tripwire re-asks G5 (`LoopInfo` **and** `blockCanRepeat`) under a **freshly built** `DominatorTree`/`LoopInfo` at `lowerOps` | |

**(1a)'s monotonicity argument verified independently, not taken on trust.**
`grep -rn 'Tainted\.insert(' ir-pass/src` -> **37 lines, of which 2 are PROSE** (a comment in
`DagTraversal.cpp:127` and the fence's own comment at `LoopLowering.cpp:2922`), so **35 code
sites**. I read the declared type at every one: `CallInst *` (28), `Instruction *` (5, all
`dyn_cast<Instruction>`-guarded), `Argument *` (2, clone-local sets only). A `ConstantExpr`
additionally cannot be a **user** of an `Instruction`, so the forward worklist can never reach
one. `Tainted.erase(` -> **30**, matching the table. The claim holds.

## F-C1C-E — `DOC`. Two record slips in this round's own write-up.

1. **The population number omits `w3`.** `progress/fix_c1c.md` step 6 and notes §3.11's
   headline both say *"the round-2 binary and this one differ on **6 programs and no others**"*
   over a 262-program corpus. The fix agent's own `out/` directory contains
   `w3_claim_across_loops_measured_gate.fix2.status` = **51 lines** and `.fix.status` = **45
   lines** — a seventh moved program, which its OWN step 6b reports. The cause is timing: its
   `allsweep` finished at 02:53 (`fix_c1c_allsweep.log`) and `w3`/`w4` were created at 02:59,
   so `popdiff` never saw them. My own re-run over a 299-program corpus that DOES contain them
   gives **286 unchanged / 13 moved**, and `w3` is one of the 13, by design. The sentence
   should read "6 in the F-C1B-1 / (1a) / F-C1C-1 scope, **plus `w3` by design** (the F-C1B-2
   revert)". Nothing about the fix changes; the bound does.
2. **The `35 sites` figure is right, the command quoted next to it is not.**
   `grep -rn 'Tainted\.insert(' ir-pass/src` returns **37 lines**; two are prose. Quote it as
   "35 code sites, 37 grep hits of which 2 are comments" — the project's own rule is that a
   count travels with the command that produced it.

## F-C1C-F — `DOC`, one line. The header-block key's in-source argument covers the MISS direction and not the RECYCLE direction; the notes cover both, the code comment does not.

`TaintPropagation.h`'s new paragraph says *"a mis-key can only ever REFUSE"*, which is true of
an unmatched claim. The paragraph directly ABOVE it — round 2's own retirement trigger — records
the opposite direction for the ROOT half (*"a recycled address matching a live peel root would
SKIP a candidate that must be judged — the over-accept direction"*), and notes §3.11's closing
sentence does extend it to the header (*"it is still an address, and a stage that erases a
`cq_theta` or a loop header … would still want a `WeakTrackingVH`"*). The header comment is the
one a future reader will meet first and it stops one sentence short. Worth noting because the
BLOCK half's precondition is arguably ALREADY met at HEAD in a way the root half's is not:
`RegionFlatten` erases arm/merge/cond blocks at `:376`, between the writers and the round-2
reader at `:393`. I could not construct a spurious match (in every shipped shape the erased
blocks are the region's ARM and MERGE, never a loop HEADER, and every measured customer keeps
`claimedHERE=1`), so this is an argument-completeness note, not a defect — and the key is
strictly narrower than the module-wide set it replaces either way.

## F-C1C-G — `CLEAR`. Pure narrowing, measured three ways.

My corpus is **299 classified programs** (fix_c1c's `p/` = round-1 §3.5 + review_c1's 60 +
fix_c1b's + review_c1b's 51 + fix_c1c's = 267 after the `tu_*`/`*_lib` skip, **plus 32 `.c` of
my own**; my 3 further probes are hand-IR `.ll` and are measured separately). Status normalised (binary token deleted)
AND every trace byte-compared.

| comparison | UNCHANGED | MOVED | ACCEPT->DECLINE flips | **DECLINE->ACCEPT flips** |
|---|---|---|---|---|
| **FIX-2 -> SUBJECT** | **286** | 13 (12 real + 1 artifact) | **6** | **0** |
| FIX-1 -> SUBJECT | 269 | 30 | 6 | **0** |
| 542d588 -> SUBJECT | 227 | 72 | 6 | **0** |

**The six ACCEPT->DECLINE are THE SAME SIX against all three binaries** — `y1` and my five
`c1c_v*` — every one carrying the (1b) string, and every one a program FIX-2 compiled to a
WRONG unitary. **No decline string anywhere in the corpus changed.** The 12 real FIX-2->SUBJECT
moves are exactly: the 4 F-C1B-1 reproducers (back to 542d588's stream), `w3` (the F-C1B-2
revert, back to 542d588's stream), `z21` (the disclosed (1a) cost, back to 542d588's stream),
and the 6 new declines. The 13th, `c1c_a1`, is a harness artifact of my own probe (identical
lowered IR; only a `ptrtoint` load address printed differently by two separately linked
binaries). The bigger FIX-1/542d588 move counts are rounds 1+2's CAPABILITY, not this round's.

**No multiplicity defect on the surviving accepts** (subject traces): `r2` 1 gate / 0 adjoints ·
`x1` 1/0 · `z7` 1/0 · `z5` 2/0 · `z18` 1/0 · `z19` 4/0 (1 preheader + 3 in-body, the loop's own
marking) · `y2` 1/0; `d1w` at K=32 is **32 mints / 32 `_unc`**.

---

# WHAT I RAN (only this)

| gate | result |
|---|---|
| harness control, 5 cases | `ctl_good` ACCEPT 4 lines on subj/fix1/fix2/fix/orac; `ctl_bad` DECLINE, identical string on all |
| build currency of the SUBJECT | `git status --porcelain` EMPTY at HEAD `dec2019`; `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` EMPTY; the new diagnostic string present in `cq-opt` (1) and absent from `cq-opt.fix2` (0). I never edited, rebuilt or ran `ctest` in that worktree |
| my probe battery | **35 new programs** (`ls p/c1c_*`) — 9 `c1c_a*` (the `isa<Constant>` attack; 6 `.c` + 3 hand-IR `.ll`, one of which link-fails by construction), 6 `c1c_v*` (the F-C1C-1 class one operator away), 6 `c1c_b*` (the per-loop key), 4 `c1c_w*` + 8 `c1c_m_*` (the other three writers), 2 `c1c_p*` — each on 542d588 / FIX-1 / FIX-2 / SUBJECT (and 2 on the pre-3qlq ORACLE) |
| population, 3 comparisons x 299 programs | table above; **0 DECLINE->ACCEPT in any of the three** |
| red-green, 7 fixtures x 4 binaries x every RUN prefix (`rg.sh`) | reproduces the fix agent's table exactly |
| tripwire exit behaviour | rc=1, **0 stdout bytes**, no `-o` file written |
| diagnostic string mirroring | character-for-character (regex-extracted from both files) |
| (1a) monotonicity argument | 35 code sites (37 grep lines, 2 prose), every declared type `CallInst`/`Instruction`/`Argument`; `Tainted.erase(` = 30 |
| STRICT stage 2b, SUBJECT | **215 accepting runs: 213 `0 violation(s), 0 unproven`, 2 `0 violation(s), 4 unproven`, 0 violations** (the two are the `--allow-unproven` dtzb break family, `f0_break_plain` / `f3_break_global_phase_before`) |
| counts, by command | `ls ir-pass/test/*.ll` **1673** · `grep -c '^m_' …expected.txt` **257** · `grep -c '^cell ' …quarantine.txt` **29** |
| read, NOT run | `$SP/progress/orch_full_ctest_c1c.log` — **100% tests passed, 0 failed out of 348, 344.81 s, EXIT=0** |
| **NOT run** | any `ctest`/`lit` in `$SP/wt/fix-c1/build` (the orchestrator's run was live) · the mutation cycles (they need a rebuild; the four-binary red-green is the stronger discriminator and I ran that instead) · the twin matrix · the injection matrix · `cq-opt-equivalence-full` |

⚠ One methodology note against myself: my first class-flip scan was written for `bash` and run
under `zsh`, where an unquoted `$pair` is not word-split — it silently reported **0 flips for
every comparison**. I noticed because `y1` is known to flip, re-ran it as a `bash` script, and
the numbers above are the re-run. Recorded because a scan that answers "0" for the wrong reason
is exactly the kind of green this project does not accept.

---

# VERDICT

**CLEAR-WITH-ITEMS**

Round 3 is a **pure narrowing** and it closes F-C1B-1 and F-C1B-2 completely as far as I could
attack them. Measured: 0 DECLINE->ACCEPT against any of the three earlier binaries over 299
programs; the only class flips are 6 ACCEPT->DECLINE, all of them programs FIX-2 miscompiled;
every shipped customer keeps its discharge byte-identically; no handle reaches an in-place
immediate slot through the committed path under any of eleven attacks on `isa<Constant>`; the
tripwire fires on five further plain-C members of the F-C1C-1 class that the fix agent did not
find, and does not fire on any body marking.

The items, none of which is round 3's to fix:
* **F-C1C-B — a PRE-EXISTING confirmed silent miscompile of the identical class through the
  LOOP writers** (`cqrt_xorc_i32(h1, 6)` with `6` the handle id of a live quantum rail; plain C,
  2 TU, `opt` exit 0, verify-clean, STRICT 2b `0 violation(s)`), reproducing unchanged on the
  **pre-3qlq oracle 52d7764**. It does not block this round, and it makes two sentences in the
  record wrong. **Owner / new bd issue.**
* **F-C1C-E — two record slips** (the "6 MOVED and no others" population omits `w3`; the
  `35 sites` command returns 37 lines).
* **F-C1C-F — one sentence of argument-completeness** in the `ClaimedRailRoots` header.

