# review_c1b — independent Rule-13 lens on the SECOND C-1 fix round (F-C1-1 / F-C1-2)

Agent `review_c1b`, READ-ONLY on every checkout. All my writes are under
`$SP/progress/review_c1b_work/` and this file.

SUBJECT   = `$SP/wt/fix-c1` @ **638334c** (build measured current:
            `find ir-pass/src ir-pass/include ir-pass/tools -newer build/ir-pass/cq-opt` -> EMPTY).
            I never edited or rebuilt it; `git status --porcelain` EMPTY at start and at end.
FIX-1     = `$SP/progress/fix_c1b_work/{cq-opt.fix1,libCQPass.so.fix1}` (the round-1 binary, 3ec40c9).
PRE-FIX   = `/Users/sorenwilkening/Desktop/CQ_lang` @ 542d588 (never rebuilt by me).
ORACLE    = `$SP0/wt/pre-3qlq` @ 52d7764 (used only for the harness control).
INSTRUMENTED COPY = `$SP/progress/review_c1b_work/dbgtree` — MY OWN `git archive HEAD` extract of
            the subject with six `getenv("CQ_DBG")`-gated `errs()` prints in `LoopLowering.cpp`
            (dispatch, `collapseRailPhisIn` collapse size, the commit pass's accept/refuse, the
            `invariantRegisterRoots` wrapper result + rollback size, `markIfRailLocal`'s marking).
            Used for ground truth and for the mutation cycles. The subject worktree was never
            touched.

## Log

- step 0: read `BRIEF_common`, `BRIEF_review_c1b`, `BRIEF_fix_c1`, `BRIEF_fix_c1b`,
  `progress/fix_c1.md`, `progress/review_c1.md` and `progress/fix_c1b.md` IN FULL; then the
  diff `git diff ba01d8d HEAD -- ir-pass/src ir-pass/include` (510 lines, 6 files) and notes
  §3 incl. §3.10, §2's ⭐ table, plus `ArithLowering.cpp`'s `classifyInPlaceReassignment` /
  `inPlaceFenceHolds` (G1–G7), `OpcodeLowering.cpp:263/:350`, `LoopLowering.cpp` 150–340
  (`peelInPlaceStep` / `railValueConsumerDisposition`), 2280–2300, 2690–2700, 2837–3240,
  3232–3460, and the taint-set headers.
- step 1: HARNESS CONTROLLED with a clean and a known-bad run on all four binaries —
  `p/ctl_good.c` ACCEPT 4 lines on subj/fix1/fix/orac; `p/ctl_bad.c` DECLINE
  `cq rotation lowering: unsupported quantum-derived rotation angle` on all four.
- step 2: BOTH FINDINGS' FIXES REPRODUCE INDEPENDENTLY (`sweep1.sh`,
  `$SP/progress/review_c1b_sweep1.log`), rolled `cq_template_{and,lshr}_*_hl` mints / `_hl_unc`:

  | program | 542d588 | FIX-1 | SUBJECT | twin on SUBJECT |
  |---|---|---|---|---|
  | r2 preheader `q=q+7`  | 3/0 | 3/0 | **3/3** | **IDENTICAL** (38=38) |
  | r71 preheader `q^=9`  | 3/0 | 3/0 | **3/3** | DIVERGE(54) — the disclosed unfaithful twin |
  | x1 same, NO carried r | 3/0 | 3/0 | **3/3** | **IDENTICAL** (32=32) |
  | r33 onward-only       | 3/0 | 3/0 | **3/3** | **IDENTICAL** (46=46) |
  | r35 onward+diffusion  | 3/0 | 3/0 | **3/3** | **IDENTICAL** (47=47) |
  | r40 onward + r1 region| 3/0 | 3/0 | **3/3** | twin DECLINES on all three (OQ-C1-3) |
  | x2 leak control       | 3/0 | 3/0 | 3/0 BYTE-UNCHANGED | DIVERGE(8) |
  | x3 dead in-body gate  | 3/0 | 3/0 | 3/0 BYTE-UNCHANGED | — |
- step 3 (GROUND TRUTH, instrumented copy). `d1i`: Collapsed, IRR TRUE, marked.
  `r2`: `COMMIT %4 = add nsw i32 %2, 7` -> IRR TRUE roots=2 marked=1 -> MARKED 1 block.
  `r33`: NO round-1 offer at all (trigger empty), `round2=1`, `R2=0` (NotClaimed),
  `claimed=1` (from `tryCaseA`) -> IRR TRUE -> MARKED. `r40`: round-1 offer Collapsed, IRR TRUE
  but **no** `MARKED` line (the `!AnyLocal` bail), then `round2=1` -> `R2=0`, no `COLLAPSING`
  line (no double mutation) -> MARKED. `x2`: `COMMIT-REFUSE oneuse=0 mc=0` -> IRR FALSE.
  `x3`: `claimed=0` -> IRR FALSE (the dead-gate control is refused by the ABSENCE of a claim,
  not by a phi test). Both `ClaimedRailRoots` writers are reached by real programs
  (`tryCaseA` for r33, `collapseRailPhisIn` step (4) for r40/d1i).
- step 4 (MY OWN PROBE BATTERY — **47 new `p/z*.c` + 4 `p/s*.c`**, plus 2 second-TU libs),
  each run on 542d588 / FIX-1 / SUBJECT. See FINDINGS and the tables below.
- step 5 (POPULATION, the full 124-program `poplist.txt` on FIX-1 and on the SUBJECT,
  `popsweep.sh`, byte-diff of every rolled trace): **95 BYTE-UNCHANGED, 6 MOVED**, and the 6
  are exactly `r2 / r71 / x1 / r33 / r35 / r40`. No other status or decline string moved.
  The Q-R1-1 controls `n9`, `d2`, `d3`, `n4`, `r5`, `n10` are all BYTE-UNCHANGED and all
  still 3/0. Corrected §3.5 rows re-measured width-agnostically: `d2` **3/0 | 3/3**,
  `n4` **3/0 | 3/3** — F-C1-4's correction is TRUE.
- step 6 (STRICT stage 2b): **133 accept runs on the SUBJECT, 133 with
  `0 violation(s), 0 unproven`** — including the four programs of finding F-C1B-1, which is
  the point: 2b is structurally blind to it.
- step 7 (RED-GREEN by hand, `rg.sh` = `cq-opt` + `FileCheck` per prefix, three binaries):
  reproduces exactly. 3 accepts RED on 542d588 AND on FIX-1 (CHECK=1 FCNT=1 **UCNT=1**),
  all prefixes 0 on the SUBJECT; 3 leak controls all-0 on all three.
- step 8 (MUTATION VALIDATION, on MY instrumented copy only, 7 build+check cycles,
  `mutate.py`/`mutrun.sh`, log `$SP/progress/review_c1b_mutate.log`):
  RESTORE all green · **M1** -> preadd accept RED (CHECK/FCNT/UCNT) · **M2** -> the
  out-of-place LEAK CONTROL RED (CHECK/PCNT/FCNT/UCNT) · **M3** -> onward accept RED *and*
  r1open accept RED · **M4** -> onward accept RED and r1open RED · **M5** -> r1open accept
  RED only · RESTORE all green. All five halves are load-bearing; claims reproduce.
- step 9 (MATRIX, re-derived by me with `dump_sources.py` against `ba01d8d`'s and `HEAD`'s
  scripts): base **1136** rows / head **1144**; `comm -23` **0 missing, 0 changed**; **8 new**
  rows = 2 cells x 2 surfaces x 2 spellings. `cells_of_matrix()` **284 -> 286**.
  `expected.txt` `^m_` rows **255 -> 257**, 0 pre-existing rows changed, header diff EMPTY,
  the 2 new rows both `ACCEPT-IDENTICAL`; `quarantine.txt` byte-unchanged at 29 cells.
- step 10 (COUNTS, by command in the subject worktree): `ls ir-pass/test/*.ll | wc -l` **1666**;
  `ctest -N` **348** total / **338** `^e2e-` / **308** `^e2e-slice-`;
  `grep -c '^m_' tools/loop_twin_matrix.expected.txt` **257**;
  `grep -c '^cell ' tools/loop_twin_matrix.quarantine.txt` **29**; the two new golden pairs are
  byte-identical (preadd 38=38, onward 47=47).
- step 11: READ (not run) `$SP/progress/orch_full_ctest_c1b.log` — **348/348 passed, EXIT=0,
  352.89 s**.

---

# FINDINGS

## F-C1B-1 — `CONFIRMED-MISCOMPILE`, introduced by THIS round. The commit is taken under ROUND-1 taint and honoured unconditionally at `lowerOps`; a "classical immediate" that becomes TAINTED at round 2 is then emitted as the classical operand of an in-place gate.

```c
/* review_c1b_work/p/z23_preadd_r2derived_imm.c  (+ p/tu_extf.c: int ext_f(int a){return a+100;}) */
int ext_f(int a);
int slice(int u){ int q=cq_theta(u,0.5); int r=cq_theta(u,0.3);
  int y=5; if (q>5) y=ext_f(7);   /* 6.5 classical-call arm -> %out, TAINTED at emission     */
  int w = y * 3;                  /* DERIVED from %out: UNTAINTED until repropagateControlMerges */
  int a = cq_theta(u,0.7);
  a = a + w;                      /* exactly ONE tainted operand at ROUND 1 -> dtzb shape    */
  for(int i=0;i<3;i++){ if((a>>i)&1) cq_phi(0.2); r=cq_theta(r,0.1); }
  return cq_measure(a)+cq_measure(r)+cq_measure(y); }
```

MEASURED (`./run.sh p/z23_preadd_r2derived_imm.c <bin> p/tu_extf.c`), trace lines 15/18:

| binary | emitted | disposition |
|---|---|---|
| 542d588 | `cq_template_mul_i32_hl(h3,3) -> h6` ; **`cq_template_add_i32(h7, h6) -> h8`** ; `mul_i32_hl_unc(h6,…)` ; `free(h6)` | CORRECT Q+Q add, mul rail discharged |
| FIX-1   | identical to 542d588 (47 lines, byte-identical) | CORRECT |
| **SUBJECT 638334c** | `cq_template_mul_i32_hl(h3,3) -> h6` ; **`cqrt_addc_i32(h7, 6)`** ; no `mul…_unc`, no `free(h6)` | **WRONG** |

The lowered IR is `call void @cqrt_addc_i32(i32 %h4, i32 %h_op)` where
`%h_op = call i32 @cq_template_mul_i32_hl(i32 %out, i32 3)` — a **quantum rail handle in the
ABI's classical-immediate slot**. The runtime prints it as the bare decimal `6`, which is
`h6`'s handle id, so the emitted circuit computes `a + 6` where the source says
`a + 3*y` with `y` a superposed 6.5 out-rail; the `3*y` rail is additionally left allocated
and entangled with nothing ever uncomputing it, and `cq_measure(a)` then measures a register
that was never entangled with `y` at all. `opt` exit **0**, verify-clean, and **STRICT stage
2b `0 violation(s), 0 unproven`** (the A1 immediate check runs per-rail at a `cqrt_free`, and
`h4` is measured rather than freed, so the write set is never examined). This is the exact
definition this project uses for a verify-clean silent miscompile.

**The commuted spelling is worse — the gate mutates the WRONG RAIL.** `p/z26_…add1.c`
(`int w = y + 1;`) emits `call void @cqrt_addc_i32(i32 %h_op, i32 %h4)` /
`cqrt_addc_i32(h6, 7)`: with BOTH operands tainted, `rewriteInPlaceValueRail`'s
`TL = Tainted.count(L)` picks the LEFT operand as the rail, so the derived `y+1` register is
mutated by the constant `7` (`h4`'s id) and the per-bit condition is then read off `h6` —
`cq_template_and_i32_hl(h6, 1)` — instead of off `a`'s rail at all.

**POPULATION — 4 plain-C programs, both in-place stems, three derived shapes, all
SUBJECT-only** (`railInImmSlot` = a `cqrt_{addc,xorc}_i32(%h…, %h…)` in the lowered IR):

| program | derived `w` | preheader op | 542d588 | FIX-1 | SUBJECT |
|---|---|---|---|---|---|
| `z23_preadd_r2derived_imm`   | `y * 3` | `a = a + w` | 0 | 0 | **1** (`addc(h7, 6)`) |
| `z26_preadd_r2derived_add1`  | `y + 1` | `a = a + w` | 0 | 0 | **1** (`addc(h6, 7)`, operands swapped) |
| `z27_prexor_r2derived`       | `y * 3` | `a = a ^ w` | 0 | 0 | **1** (`xorc(h7, 6)`) |
| `z29_preadd_r2derived_and`   | `y & 7` | `a = a + w` | 0 | 0 | **1** (`addc(h7, 6)`) |

All four go 47 -> 51 trace lines on the subject and are 2b-clean. The hand-unrolled twin of
z23 DECLINES `control flow under quantum control` on all three binaries (the OQ-C1-3 / b2u
class), so there is no twin witness — the witness is the FIX-1-vs-subject byte diff plus the
lowered IR.

**ROOT CAUSE, measured with the instrumented build:**
```
[DBG] loop hdr= Touched=1 NewlyTouched=1 round2=0        <- the ROUND-1 collapse call
[DBG] R2=2 localRoots=1 claimed=1
[DBG] COMMIT   %7 = add nsw i32 %6, %5                   <- committed under ROUND-1 taint
[DBG] IRR TRUE roots=2 marked=1
```
`commitOutOfLoopInPlaceOps` asks `inPlaceValueRailOperand` (G2's "exactly one tainted
operand") and `classifyInPlaceReassignment` at the ROUND-1 `collapseFlattenedLoopRails` call
(`CQLoweringPass.cpp:393`), then writes the answer into `taint.InPlaceRailOps` as a
**commitment**. `repropagateControlMerges` (`:409`) then runs the dugh onward round and
`taint.Tainted` GROWS: `%out` was tainted at emission (`ClassicalCallArmEmit.cpp:209`) but
everything DERIVED from it becomes tainted only at round 2. At `lowerOps` (`:536`) the
marking makes `OpcodeLowering:263` skip M-C classification entirely and `:350` route the op
to `rewriteInPlaceValueRail` — which never re-asks the shape. Unmarked, M-C would have
answered `inPlaceValueRailOperand == null` (two tainted operands) and fallen back to
`rewriteBinary`, which is exactly what FIX-1 and 542d588 emit.

**WHAT THE ROUND SAID ABOUT THIS, AND WHY IT IS THE 8h7d.5 LESSON AGAIN.** Notes §3.10 and
the `commitOutOfLoopInPlaceOps` header both identify the staleness window and then close only
HALF of it: *"`P->hasOneUse()` closes that window STRUCTURALLY … the only use of `P` is this
op's operand, and no later stage invents a read of a value that has none"*, and OQ-C1-5 calls
the prediction *"unfalsifiable by construction"*. That reasoning is about **G6/G7** (a later
READ of the parent). The commit also predicts **G2**, the SHAPE — "the other operand is
classical" — and nothing guards it. Widen a set, ask what OTHER predicate was computed over
the same closure: `hasOneUse` was asked of `P`, and the answer that went stale was about
`Imm`. Notes §2's ⭐ once-only-stage table asks exactly the right question — *"does this stage
compute something a LATER stage consumes, over a premise round 2 falsifies?"* — and this
round added a NEW such stage without giving it a row.

**SCOPE / NOT PRE-EXISTING.** The other three `InPlaceRailOps` writers
(`LoopLowering.cpp:1698`, `tryCaseA:2281`, `collapseRailPhisIn:2675`) run inside `lowerLoops`,
earlier still, so they have the same shape of exposure; I probed it
(`p/z36_bodyadd_r2derived_imm.c`, an in-BODY `r = r + w` with the same round-2-derived `w`)
and it does **not** reproduce on any of the three binaries — the class as measured is
introduced by `commitOutOfLoopInPlaceOps`.

**SUGGESTED DIRECTIONS (owner's call, not mine).** (a) The monotone one-line narrowing:
require `isa<Constant>(Imm)` at commit time — a compile-time constant can never become
tainted. Measured to keep every shipped customer (`r2`'s `7`, `r71`'s `9`, `x1`'s `7`,
`z7`'s `-7`, and r33/r35/r40, which have no preheader op) and to refuse all four
reproducers; its only cost is that `p/z21_preadd_volatile_imm.c` (a volatile-load immediate,
a NEW accept of this round) returns to today's leak — the Prime-Directive direction.
(b) OQ-C1-5's own alternative: re-ask the fence in `lowerOps` for exactly the ops this path
marked and DECLINE loudly if it no longer holds. Note a plain fallback to out-of-place is NOT
sound there, because the body marking that the commit licensed would already stand.

## F-C1B-2 — `LATENT OVER-ACCEPT` (no reachable wrong circuit found). `taint.ClaimedRailRoots` is MODULE-WIDE, but the property clause (0) skips on is PER-LOOP — and the control that is supposed to pin it cannot see this.

Notes §3.10 and the `ClaimedRailRoots` header both state the invariant: *"NOT INFERRED FROM
THE ABSENCE OF A HEADER PHI, deliberately: an in-place gate whose result is DEAD in the body
(`int t = cq_theta(r,.1);`) mints no phi and carries no claim, and admitting it would grant
the marking on a rail nothing proved. Pinned by `p/x3_deadgate_body.c`, which still leaks."*

`x3` still leaks — I re-measured it, 3/0 and BYTE-UNCHANGED on all three binaries. But it
leaks only because **no OTHER loop in that module claimed `r`'s root**. The set is keyed on
the ROOT VALUE and lives in `TaintSet`, so a claim made for loop A satisfies clause (0) for
loop B, where clause (iii)'s per-loop question (is there an in-loop in-place gate on this
root?) is never asked. MEASURED (`p/z32_claim_across_loops_nomeas.c`: loop A carries `r` and
is claimed by `tryCaseA`; loop B has an onward per-bit region and a DEAD `cq_theta(r,0.2)` in
its body):

```
[DBG] loop hdr= Touched=1 NewlyTouched=1 round2=1
[DBG] R2=0 localRoots=0 claimed=1          <- the claim comes from LOOP A
[DBG] IRR TRUE roots=2 marked=0
[DBG] markIfRailLocal MARKED 1 blocks      <- loop B MARKED on a rail loop B never proved
```
This is exactly the grant the header says must not happen. I could **not** turn it into a
wrong emitted circuit: all four spellings I built decline at a LATER loud fence on all three
binaries — `z31`/`z33` `cq loop lowering: rail record read past an in-place gate on the same
rail`, `z32`/`z35` `cq uncompute: tainted handle live range crosses a loop backedge`, `z34`
`cq taint escape: tainted value muxed by a classical-condition phi`. So I grade it LATENT and
report it as a soundness-argument gap, not a miscompile: **the pin does not bound the
property it is cited for**, and a one-loop reproducer cannot detect a module-wide set. If the
set stays module-wide it wants either a per-loop key or a fixture whose module contains a
second, claiming loop.

## F-C1B-3 — `CLEAR`. F-C1-1's fix, adversarially: every out-of-place M-C shape refuses or is unchanged, and there is no K-adjoints-of-one-gate multiplicity.

Question 1(a) of the brief, each program run on all three binaries:

| probe | shape | 542d588 | FIX-1 | SUBJECT | verdict |
|---|---|---|---|---|---|
| `x2_preadd_keep` | pre-op value read AFTER the loop | 3/0 | 3/0 | 3/0 **BYTE-UNCHANGED** | refused (leak control) |
| `z2_preadd_keep_inloop` | pre-op value read INSIDE the loop (second per-bit region on the alias) | 6/0 | 6/0 | 6/0 **BYTE-UNCHANGED** | refused |
| `z3_preadd_chain_midread` | two preheader ops, MIDDLE value measured | 3/0 | 3/0 | 3/0 **BYTE-UNCHANGED** | refused |
| `z8_preadd_fanout` | pre-op value feeds a second preheader op (`int s=q^1;`) | 3/0 | 3/0 | 3/0 **BYTE-UNCHANGED** | refused (`hasOneUse`) |
| `z4_preadd_arg_imm` | immediate is a formal ARGUMENT (G4) | 3/0 | 3/0 | 3/0 **BYTE-UNCHANGED** | refused; over-decline, safe |
| `z20_rollback_two_inv` | one committable + one non-committable invariant register | 6/0 | 6/0 | 6/0 **BYTE-UNCHANGED**; DBG `COMMIT` then `COMMIT-REFUSE` then `IRR FALSE rollback=1` | **rollback works** |
| `z7_presub_inv` | `q = q - 7` (`-O1` canonicalises to `add …, -7`) | 3/0 | 3/0 | **3/3 IDENTICAL** | new accept |
| `z5_prexoradd_chain` | `q ^= 9; q += 7;` | 3/0 | 3/0 | **3/3** | new accept, 1 `xorc` + 1 `addc`, both once |
| `z6_preadd_on_carried` | preheader op on the CARRIED register | 3/0 | **3/3** | **3/3 BYTE-UNCHANGED vs FIX-1** | unmoved |
| `z17_preadd_k1` | K=1 | 1/1 IDENT | 1/1 IDENT | 1/1 IDENT, **BYTE-UNCHANGED** | unmoved |
| `z18_preadd_measured_in_body` | invariant register `cq_measure`d in the body x3 | 3/0 | 3/0 | **3/3 IDENTICAL** | new accept |
| `z19_preadd_inv_bodyadd_carried` | + in-body `r ^= 9` | 3/0 | 3/0 | **3/3** | new accept |
| `z21_preadd_volatile_imm` | immediate is a volatile load | 3/0 | 3/0 | **3/3 IDENTICAL** | new accept (see F-C1B-1(a)) |
| `s1`,`s2` | preheader op + a rail RECORD of the carried register | DECLINE | DECLINE | DECLINE, same string | unmoved |
| `s3`,`s4` | preheader op + an alias/record read after the loop | ACCEPT | ACCEPT | ACCEPT, diff = **exactly the 3 `_unc`+`free` pairs** | intended |

**No multiplicity defect.** In every accepting probe the preheader in-place gate appears
EXACTLY ONCE in the trace and no adjoint of it appears anywhere
(`cqrt_addc_i32(h0, 7)` x1, `cqrt_xorc_i32(h0, 9)` x1, `cqrt_addc_i32(h0, -7)` x1, …), and the
lowered IR places it in the preheader only. `d1w` at K=32 is **32 mints / 32 `_unc`** on FIX-1
AND on the subject — a K-vs-1 pairing defect would read 32 against 1.

**Question 1(b), the 8h7d.5 question for `InPlaceRailOps`.** `declineStaleRecordOps` runs at
`CQLoweringPass.cpp:335`, BEFORE `lowerLoops` — it cannot see the new markings. `WireWalk`
deliberately does not cross an in-place value self-update at all
(`WireWalk.cpp:451-475`), so it is insensitive. `ArmClassify`'s rail closure crosses
`add`/`sub`/`xor` UNCONDITIONALLY and its own comment says it "subsumes
`taint.InPlaceRailOps`", so the round-2 `detectControlRegions` cannot change answer either.
`collectRailGates`/`staleRailRecordRead` DO read the set and run again at round 2; more gates
means more staleness declines (the decline direction), and measured: `s1`/`s2` decline
identically on all three, `n3`/`d12`/`r60`/`n11`/`n12` are byte-unchanged in the 95, and the
whole population shows **0 status changes outside the 6 intended ones**. No decline
disappeared and no accept appeared.

## F-C1B-4 — `CLEAR`. F-C1-2's fix, adversarially.

**(2a) the "already-claimed" fact.** Two writers, GREP-verified: `tryCaseA` (LoopLowering.cpp
:2297, over `railRoot`) and `collapseRailPhisIn` step (4) (:2701, over `Collapse`); ONE reader,
clause (0) at :3111. Both writers are exercised by real programs (r33 via `tryCaseA`,
r40/d1i via step (4) — DBG-confirmed). The dead-result in-body gate is NOT treated as claimed
(`x3`: `claimed=0`, IRR FALSE, still 3/0 byte-unchanged). A rail claimed at round 1 whose
chain is EXTENDED at round 2 (`z9`, a post-loop `r = cq_theta(r,0.4)` on the onward mixed
loop) is served: 3/0 -> **3/3 IDENTICAL** (47=47). Two carried rails beside an onward
invariant (`z10`): `claimed=2`, 3/0 -> **3/3 IDENTICAL** (52=52). The one gap I found in this
half is F-C1B-2 above.

**(2b) the round-2 re-offer.** Measured with the instrumented build:
* a round-1-collapsed loop with NO onward region (`z14_r1only_no_onward`) is offered exactly
  ONCE (`round2=0`) and its trace is **BYTE-IDENTICAL to FIX-1's** — the re-offer is a no-op
  there, as required;
* an onward region in a loop with NO round-1 region (`r33`, `z9`, `z10`) — one offer, at
  round 2, `R2=0`, no `COLLAPSING` line, marked;
* both orders of "round-1 region + onward region in ONE body" (`r40`, and `z12_onward_then_r1`
  with the order swapped) get TWO offers; the round-2 one returns `NotClaimed` **without
  mutating** (no `COLLAPSING` line), which is the "no double mutation" claim, measured;
* two onward regions in one body (`z11`) and a preheader op on the onward register (`z22`)
  DECLINE on all three binaries (`control flow under quantum control` /
  `value-arm swap-route under quantum control`) — pre-existing, unmoved;
* an onward region in a NESTED loop (`z13`) DECLINES on all three,
  `cq loop lowering: loop-carried tainted value crosses iterations`.

## F-C1B-5 — `DOC`. Three small record slips.

1. `CLAUDE.md:1756` says the lit corpus moved *"1660 -> 1665"*; the tree is at **1666** and
   `CLAUDE.md:1895` says 1666. The `short`/`sext` control landed in the last commit (638334c)
   after that sentence was written.
2. `RETIRE_SWAP_ROUTE_INC1_NOTES.md:967` (§2's ⭐ table preamble) says *"zero by the
   1665-fixture suite"* — same one-off.
3. `progress/fix_c1b.md`'s hand-back says the matrix gained *"16 new (4 cells x 2 surfaces x 2
   spellings)"*; that is the PRE-`xorpre`-drop state. The shipped state is **8 new rows / 2
   cells**, which is what notes §3.10 says and what I re-measured. Nothing else in the record
   is affected; every other number I checked reproduces (see step 9/step 10).

## Not findings, recorded so the next round does not re-derive them

* `p/z25_preadd_selmerge_derived.c` — the SINGLE-TU spelling of F-C1B-1 using a 4.4 select
  merge (`int y = (q>5) ? 11 : 5;`) instead of the 6.5 arm — does **not** reproduce (47 lines,
  unchanged on all three). The measured reproducers all need the two-TU classical-call arm.
* `p/z24_preadd_r2region_imm.c` (the immediate is a ROUND-2-emitted region's own `%out`)
  declines `control flow under quantum control` on all three.
* `p/z30_carried_preadd_r2derived.c` (the preheader op on the CARRIED register with the same
  round-2-derived immediate) declines `cq uncompute: dead chain would free a measured
  register` on all three.

---

# WHAT I RAN (only this)

| gate | result |
|---|---|
| harness control, 4 binaries | `ctl_good` ACCEPT 4 lines on subj/fix1/fix/orac; `ctl_bad` DECLINE, identical string on all four |
| my probe battery | **47 new `p/z*.c` + 4 `p/s*.c`** + 2 second-TU libs, on 542d588 / FIX-1 / SUBJECT |
| population re-run, FIX-1 vs SUBJECT | 124 programs: **95 rolled traces BYTE-UNCHANGED, 6 MOVED** (r2, r71, x1, r33, r35, r40); 0 other status or string changes |
| Q-R1-1 controls | `n9`,`d2`,`d3`,`n4`,`r5`,`n10` all BYTE-UNCHANGED, all still 3/0 |
| STRICT stage 2b | **133 of 133** accept runs on the SUBJECT `0 violation(s), 0 unproven` (including the 4 miscompiling ones) |
| red-green by hand, 3 binaries | 3 accepts RED on 542d588 AND FIX-1 (CHECK/FCNT/**UCNT**), GREEN on the subject; 3 leak controls green on all three |
| mutation validation (my own copy) | RESTORE green · M1 RED · M2 RED · M3 RED · M4 RED · M5 RED · RESTORE green — 7 build+check cycles |
| matrix generated sources, re-derived | 1136 -> 1144: **0 missing, 0 changed**, 8 new; cells 284 -> 286; expected rows 255 -> 257, all pre-existing byte-identical; quarantine byte-unchanged (29) |
| counts, by command | lit 1666 · ctest 348 / 338 / 308 · goldens 38=38 and 47=47 |
| instrumented ground truth | my own `git archive HEAD` copy under `review_c1b_work/dbgtree`, built 8 times; `$SP/wt/fix-c1` never touched or rebuilt (`git status` clean, HEAD 638334c at start and end) |
| read, not run | `$SP/progress/orch_full_ctest_c1b.log` — **348/348 passed, EXIT=0, 352.89 s** |
| NOT run | any `ctest` in `$SP/wt/fix-c1/build`; the full suite; `cq-opt-equivalence-full`; the twin matrix itself; the injection matrix |

# VERDICT

FINDINGS
