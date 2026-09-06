# review_r2_R1 — Rule-13 ROUND 2, lens R1: the round-1 FIXES, adversarially
Read-only. SUBJECT = main checkout `/Users/sorenwilkening/Desktop/CQ_lang` @ **c4bd888**
(`build/ir-pass/{cq-opt,libCQPass.so}`, untouched). ROUND-1 SUBJECT = `$SP/wt/r1-subject` @
**fa96336** (built). ORACLE = `$SP/wt/pre-3qlq` @ **52d7764**. Every program below went
through stage 1 (`clang -O1`) → 2 (`cq-opt`) → **STRICT** 2b (`free_pairing_check.py`, no
`--allow-unproven`) → 3 (link, templates before runtime) → 4 (trace) on every binary where a
spelling exists. Harnesses: `$SP/progress/review_r2_R1/{run.sh,multi.sh,mdsweep.sh}`;
reproducers `$SP/progress/review_r2_R1/p/`; artifacts `.../out/`.

---

## F-R1-1 — CONFIRMED. The 8h7d.5/F-L5-1 rolled≠unrolled signature, on a population the round-1 fixes CREATED: an in-loop kickback over an ONWARD `%out` register leaks one entangled which-path rail per activation.

**One line.** `for (i…) if ((y>>i)&1) cq_phi(θ);` where `y` is an ONWARD 6.5
classical-call-arm rail compiles at `opt` exit 0 with **zero** `cq_template_and_i32_hl_unc`,
while the hand-unrolled spelling of the same source discharges all K — the exact signature
round 1 graded CONFIRMED MISCOMPILE as F-L7-2 / F-L5-1, in a shape that **declines on the
round-1 subject** and therefore arrived with the F-L3-1 reorder.

**Reproducer** (2 TU, both shipped-harness spellings; single linked `.ll` also committed):
`p/o_onward_inloop.c` + `p/j1_lib.c`, and `$SP/progress/review_r2_R1/repro_onward_inloop.ll`
```c
int ext_f(int a);
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5; if (q > 5) y = ext_f(7);              /* 6.5 classical-call arm -> %out */
    for (int i = 0; i < 3; ++i)
        if (((y >> i) & 1)) cq_phi(0.25);            /* D4's per-bit idiom, ROLLED     */
    return cq_measure(y);
}
```
It is a GENUINE rolled loop, not an unrolled one — stage-1 IR carries
`br i1 %17, label %7, label %9, !llvm.loop !6` (`out/o_onward_inloop.main.cq.ll`).

**Measured.**

| binary | disposition |
|---|---|
| SUBJECT (c4bd888) | rc 0, **34 trace lines**, `and_i32_hl` × 3, `and_i32_hl_unc` × **0**, 3 rails leaked, STRICT 2b `8 rail mint(s) of which 8 left allocated … 0 violation(s), 0 unproven` |
| SUBJECT, hand-unrolled twin `p/o_onward_inloop_unrolled.c` | rc 0, **40 trace lines**, all 3 discharge, STRICT 2b `4 left allocated … 7 verified, 0 violation(s)` |
| ROUND-1 SUBJECT (fa96336) | rc 1 — `cq controlled lowering: control flow under quantum control` |
| ORACLE | no spelling; the closest old-surface twin `p/o_onward_inloop_old.c` declines `cq taint escape: tainted value muxed by a classical-condition phi` |

`diff out/o_onward_inloop.main.trace out/o_onward_inloop_unrolled.main.trace` is **exactly**
three inserted pairs and nothing else:
```
> cq_template_and_i32_hl_unc(h5, h2, 1)   > cqrt_free(h5)
> cq_template_and_i32_hl_unc(h7, h2, 2)   > cqrt_free(h7)
> cq_template_and_i32_hl_unc(h9, h2, 4)   > cqrt_free(h9)
```

**THE DISCRIMINATING CONTROL, and it is what makes the root cause a measurement.**
`p/o_onward_inloop_ctrl.c` is the SAME module with ONE change — the loop reads the
`cq_theta` **root** `q` instead of the onward rail `y`. It emits **3** `and_i32_hl_unc` and
frees every rail (41 lines). So the divergence is not "onward regions" and not "loops": it
is *which register the loop-invariant condition reads*.

**Why it is not a Rule-6-safe leak** (round 1's own argument, made concrete here rather than
analytically). Each leaked rail holds one BIT of `y` — a which-path record — and this idiom
exists to be a phase oracle whose next step interferes different `x` (Rule 8: *"a permutation
that leaves a rail dirty AND entangled still dephases under later interference"*).
`p/o_onward_inloop_interf.c` adds the interference step (`y = cq_theta(y, 0.9);` after the
loop) and compiles at rc 0 with **`cqrt_ry_i32(h2, 0x1.ccc…p-1)` executing while all three
records of `h2`'s bits are live and unfreed** (35 lines, STRICT 2b clean). Rolled and
unrolled are different unitaries.

**Root cause — a STAGE-ORDER gap, NOT the root-mint clause the notes name.** Two independent
reasons, both structural, and the second is the one Q-R1-1 does not mention:
1. `LoopLowering::invariantRegisterRoots` clause (ii) (`ir-pass/src/LoopLowering.cpp:2877`,
   the F-L7-2 fix) admits only a COLLECTED `cq_theta` with a classical arg 0. An onward
   `%out` is a `phi i32 [%ext_f_result, …], [5, …]` — not a `CallInst` at all.
2. **More decisively:** `collapseFlattenedLoopRails` — the ONLY caller of
   `invariantRegisterRoots` and `markIfRailLocal` — is invoked **once**, at
   `ir-pass/src/CQLoweringPass.cpp:393`, which is *before* `repropagateControlMerges`
   (line 409). An ONWARD region is claimed and flattened by round 2 inside
   `detectAndLowerOnwardControl` (`TaintPropagation.cpp:1550`), and that function never
   calls the rail collapse. At round 1 the register `y` is not even TAINTED (that is what
   "onward" means), so `invariantRegisterRoots` returns `false` on an EMPTY `Cands` set
   before clause (ii) is reached. **So no widening of clause (ii) can fix this: the marking
   stage has already run when the region is claimed.**
   This is F-L3-1's own shape one level up — *a stage standing where a one-round pipeline
   put it, whose premise (`markIfRailLocal` will run after this flatten) is false at round 2*.

**Relation to OWNER QUESTION Q-R1-1.** The residual CLASS is disclosed
(`RETIRE_SWAP_ROUTE_INC1_NOTES.md`, "A HOISTED loop-invariant TEMPLATE rail read by the
body's condition (`int p = q * 3;`)"), and I re-measured that canonical member at HEAD —
`p/q1_hoisted_temp.c` vs `p/q1_hoisted_temp_unrolled.c`, the same three missing pairs. What
is NOT disclosed: (a) this second population, (b) that its cause is stage ORDER rather than
the root-mint clause, and (c) that Q-R1-1's stated cost — *"hand-unrolling works, and so
does using the root register itself"* — **has no second half here**: `y` is not derived from
`q`, it is the merge of a classical call result with a constant, so "use the root register"
names a different register and a different program.

**Proposed fix location.** Either `ir-pass/src/CQLoweringPass.cpp:393` (call
`collapseFlattenedLoopRails` a second time after `repropagateControlMerges`, with round-2
taint on the round-2 CFG — the same repair F-L3-1 made for `deleteGlobalPhases`), or, on the
Prime Directive, decline a region whose entry is in a loop when it is claimed at round 2:
`flatRegionRollableInLoop`'s licence (`ControlDetect.cpp`) rests on a marking stage that has
already run. `LoopLowering.cpp:2877` clause (ii) is a *second-order* item and cannot carry
this on its own.

**Pinning fixtures.** `control_phase_kickback_reject_onward_inloop.ll` (or an ACCEPT with a
`UCNT-COUNT-3` on `cq_template_and_i32_hl_unc` if the capability fix ships) from
`$SP/progress/review_r2_R1/repro_onward_inloop.ll`, plus the twin
`repro_onward_inloop_unrolled.ll`; and an e2e `cmp` twin gate over the two `.c` spellings
(the only layer that can see a leaked TEMPLATE-minted rail — stage 2b reports
`0 violation(s)` on both, as its own header says it must).

---

## F-R1-2 — OVER-DECLINE (plain C, introduced by the F-L5-6 fix), plus the DOC claim that says it cannot happen.

**One line.** After the F-L5-6 phase-carrier widening, a program whose ONLY `cq_phi` is an
**UNCONTROLLED** one — a GLOBAL phase that owner decision **D2 deletes** — declines
`cq controlled lowering: phase-class value escaping under quantum control`, purely because
the statement sits downstream of an unrelated tainted branch.

**Reproducers** (`p/g_abort_uncond_phase.c`, `p/g_abort_phase_before.c`, `p/g_abort_nophase.c`):
```c
void abort(void);
int slice(int u) { int q = cq_theta(u, 0.5);
  if (q == 5) abort();          /* 7.2 abort park                                  */
  cq_phi(0.75);                 /* UNCONTROLLED  ->  a GLOBAL phase, D2 deletes it */
  return cq_measure(q); }
```

| program | SUBJECT | ROUND-1 SUBJECT |
|---|---|---|
| `g_abort_uncond_phase.c` | **rc 1** `phase-class value escaping under quantum control` | **rc 0**, 8 trace lines |
| `g_abort_nophase.c` (same, phase deleted by hand) | rc 0, 8 lines | rc 0, 8 lines |
| `g_abort_phase_before.c` (**the same statement one line EARLIER**, above the tainted `br`) | **rc 0**, 8 lines | rc 0, 8 lines |

`diff out/g_abort_uncond_phase.r1s.trace out/g_abort_nophase.r1s.trace` is **EMPTY** — i.e.
on the round-1 subject the global phase is deleted exactly as D2 says, and the two programs
are the same circuit. At HEAD one of them compiles and the other does not, and the only
difference is a statement the compiler is required to delete.

**Analytic argument.** `TaintPropagation.cpp:1640 functionCarriesBranchPhase` iterates
`taint.PhaseCalls` and asks `reachedThroughTaintedBranch(CI->getParent(), taint)` — a
backward CFG walk documented at `:1608` as *"whether ANY tainted branch sits anywhere on ANY
path reaching `BB`, not whether `BB` is on a specific arm of one."* That crudeness is sound
at `deleteGlobalPhases`' slot, where every tainted `br` has already been claimed-and-erased
or declined; the three carriers ask it **before `lowerControlRegions`**, when every tainted
`br` is still standing. So the predicate answers "reached from" where the header
(`TaintPropagation.h:592`) promises "CONTROL-DEPENDENT ON", and explicitly excludes exactly
this case: *"An UNCONTROLLED `cq_phi` is a global phase and carries nothing (D2 deletes it),
so only a branch phase counts."* Measured, a global phase counts too. Post-dominance is the
missing half: a block that BOTH successors of the tainted branch reach is not control-
dependent on it.

**The latency claim is measurably false.** `fix_r1.md` grades F-L5-6 *"FIXED (coarse,
over-declining; LATENT — unreachable at HEAD)"* and the notes say *"LATENT at this HEAD — no
plain-C program reaches any of the three fences (each is held shut by an earlier shape
fence), which is what L5 measured too."* The `return` and `break` carriers are indeed shut
(`p/g_ret_uncond_phase.c` and `p/g_break_uncond_phase.c` decline identically on BOTH binaries,
at `value-arm swap-route` and `loop under quantum control`), but the **abort park is not**.
The fence has a measured plain-C cost, and the write-up says it has none.

**Grade.** OVER-DECLINE (safe direction — no wrong unitary) **+ DOC-OR-FIXTURE-TRUTH** on the
"LATENT/unreachable" claim in both `fix_r1.md` and `RETIRE_SWAP_ROUTE_INC1_NOTES.md`.

**Firing site**, for the record: `ir-pass/src/AbortParkEmit.cpp:321` (`lineageCarriesPhase(Q)`
over the live remainder registers, via `AbortParkEmit.cpp:147`'s
`functionCarriesBranchPhase` clause). The message is verbatim
`error: <unknown>:0:0: in function slice i32 (i32): cq controlled lowering: phase-class value escaping under quantum control`.

**Proposed fix location.** `ir-pass/src/TaintPropagation.cpp:1640` — skip a phase call whose
block post-dominates the tainted branch's block (a `PostDominatorTree` query, or the cheaper
"reached from BOTH successors" test), which is precisely the "control-dependent" the header
already claims. Failing that, correct the header and the two write-ups and pin the cost.

**Pinning fixtures.** an ACCEPT `control_phase_kickback_abort_global_phase.ll` (the
`g_abort_uncond_phase` module) beside the existing `control_swap_abort_park*.ll`, and a
DECLINE for the genuine subject (a real branch phase reaching the same park), so the fence
is a discriminator rather than a blanket.

---

## F-R1-3 — DOC-OR-FIXTURE-TRUTH. "There are three emission sites today" is now FIVE, in the one comment whose whole job is to enumerate them.

`ir-pass/include/ChainWalk.h:122` — *"STAMP IT AT EVERY EMISSION SITE. There are three today
— `SwapRouteEmit::emitPhaseKickbackRegion`'s arm loop and its merge-tail loop, and
`AngleSelectEmit`'s Rz stem. A fourth emitter that mints a kickback gate and forgets this
call re-opens F-L7-1 with no diagnostic anywhere."* `RETIRE_SWAP_ROUTE_INC1_NOTES.md:64`
repeats it (*"Recorded at all THREE emission sites"*).

MEASURED — `grep -rn 'CreateCall(Rz' ir-pass/src` gives **five** expressions, and every one
is stamped: `SwapRouteEmit.cpp:1539` (arm loop), `:1569` (merge tail), **`:1774`
(`emitPhaseKickbackNestRegion`, P4)**, `AngleSelectEmit.cpp:179`/`:181` (one site, two
gates), **`SwitchRouteEmit.cpp:169→179` (P5)**. The two new ones are exactly the pair the
Inc-1b merge caught, and the comment that exists to make a *sixth* omission visible still
says three. This is the low-severity half of a real hazard: the enumeration is the fence.

**The fix itself holds corpus-wide.** `mdsweep.sh` ran all 1582 `ir-pass/test/*.ll` through
the subject binary:
```
ACCEPTED=633   MDMISMATCH=0   NONI1FILES=0   CSWAPFILES=12
```
i.e. on every one of the 633 fixtures the pass lowers, `#(call void @cqrt_rz_i1() ==
#(!cq.branchphase)`, and there is **no non-`i1` `cqrt_rz` anywhere in the corpus** (part B's
claim, independently confirmed). Also re-confirmed on all 40+ plain-C probes in `p/`.

**Fix location.** `ir-pass/include/ChainWalk.h:122` and `RETIRE_SWAP_ROUTE_INC1_NOTES.md:64`.
**Pinning.** the three shipped `MDCNT`/`MDTAG` fixtures already pin per-site counts; what is
missing is only the prose.

*(Aside, measured while sweeping and belonging to lens R2's checklist rather than mine: the
brief's premise "`cqrt_cswap` is minted by AbortParkEmit only" is FALSE. 12 fixtures emit it
— 4 `control_swap_abort_park*`, and 8 value-arm/method-B ones: `control_swap_value_diamond`,
`..._diamond_polarity`, `..._ifelse`, `..._accept_nonclobber`, `control_swap_switch_value`,
`lowering_switch_value_nonI32_cast`, `lowering_uncompute_interior_leak_region_valuearm_chain`,
`lowering_uncompute_interior_leak_unrecorded_route`. That is the 4.2 method-B route, which is
legitimate; the premise, not the code, is what is wrong.)*

---

## F-R1-4 — DOC-OR-FIXTURE-TRUTH. The F-L7-1 closure table is short by one row, and the missing row is a `cqrt_rz_` NAME test that ADMITS the kickback gate.

The notes' *"WHAT ELSE IS COMPUTED OVER THAT CLOSURE"* table — written expressly to satisfy
the 8h7d.5 "when you narrow a set, ask what else was computed over it" discipline — lists
`Uncomputation::preservesBorrowedParent` **clause (1b)** and marks it "unchanged". It does
not list **clause (1)** (`ir-pass/src/Uncomputation.cpp:591-597`):
```cpp
if (N.starts_with("cqrt_rz_") && !N.ends_with("_controlled") &&
    M->arg_size() == 2 && M->getArgOperand(0) == P)
  return true;                       // "a DIAGONAL rotation … basis label untouched"
```
A kickback gate is **exactly** `cqrt_rz_i1(Flag, θ)` — prefix `cqrt_rz_`, not `_controlled`,
arity 2, handle at arg 0 — so this row admits it, by NAME, in the same increment in which
`isInPlaceGateOn` was taught to refuse it by MEMBERSHIP. That is "two predicates, one gate,
different answers", the shape `ChainWalk.cpp`'s own `railOf`/`isAbiQramStore` comments cite
bd `uow0` for.

**It is REACHED, not hypothetical.** `p/u8_share_tail.c` (`int f = (q>5); if (q>5)
{cq_phi(.25); cq_phi(.75);} else {cq_phi(.125);} return cq_measure(q+f);`) discharges the
`zext` rail with the FLAG as borrowed parent while that flag carries three `cqrt_rz_i1`
gates plus a `cqrt_x` bracket: `zext(h1)->h2; add(h0,h2)->h3; zext_unc(h2,h1); free(h2)`
(13 lines, STRICT 2b clean, byte-identical on both binaries).

**The verdict `true` is SOUND and I am not asking for it to change** — the gate really is
diagonal, so `P`'s basis label is untouched and clause (d) holds pointwise, which is the same
argument clause (1b) spells out at 25 lines for the controlled twin. What is wrong is that
the enumeration claims to be complete and is not, and the row it omits is the one that
answers the OPPOSITE way from the fix. If anyone later narrows clause (1) "for symmetry" they
will silently reintroduce the nine-module regression clause (1b)'s comment records.

**Fix location.** the closure table in `RETIRE_SWAP_ROUTE_INC1_NOTES.md` (§ F-L7-1), plus a
one-line note at `ir-pass/src/Uncomputation.cpp:591` saying that this row deliberately admits
a recorded branch-phase gate and why (diagonal ⇒ label preserved ⇒ the `_unc`'s recomputation
of `f(P)` is unaffected), so the next reader does not "fix" it.
**Pinning.** `u8_share_tail`'s module as an accept fixture with a `UCNT` on
`cq_template_zext_i1_to_i32_unc` — today nothing in the corpus pins that discharge.

---

## F-R1-5 — DOC-OR-FIXTURE-TRUTH. Reason (3) for choosing metadata over a `TaintSet` set is unreachable at HEAD, by the round's OWN other fix.

`ChainWalk.h:116` gives as the third reason: *"Metadata survives `CloneFunctionInto`
(Phase-6 specialization), where a pointer set silently would not: the clone's gate would fall
OUT of the set and become adjointable again."* MEASURED, no clone can ever contain a kickback
gate, because F-L3-3's own fix (adding `taint.PhaseCalls` to `SpecializeReject` /
`SpecializeDetect`) makes a callee containing ANY `cq_phi` a loud reject:

| probe | SUBJECT | ROUND-1 SUBJECT |
|---|---|---|
| `p/d1_clone_branchphase.c` (branch phase in the callee) | rc 1 `cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted` | rc 1 (`… non-reversibilizable construct … (nested call)`) |
| `p/d2_clone_globalphase.c` (global phase in the callee) | rc 1, same string | rc 1, same wrong-ground string |
| `p/d3_clone_nophase.c` | rc 1 `callee contains tainted control flow under quantum lift` | identical |

Reasons **(1)** (19 call sites in 6 files, three with no `TaintSet` in scope) and **(2)** (a
`Value*` set keyed at emission is the drbq Inc-1 dangling-set defect verbatim) are measured
and stand on their own, and the storage choice is fine. Reason (3) should be stated as a
*property the record has* rather than as a hazard it avoids, or the sentence should name the
fence that makes it moot — otherwise it will be quoted as a live argument.

**Fix location.** `ir-pass/include/ChainWalk.h:113-118`.

---

## F-R1-6 — OVER-DECLINE (pre-existing disposition, ground corrected by F-L3-3). A D2 GLOBAL phase inside a specialization candidate is refused instead of deleted.

`p/d2_clone_globalphase.c` — `static int h(int x){ cq_phi(PI); return x+1; }` called with a
tainted argument. D2 says an uncontrolled `cq_phi` is a global phase and is DELETED, after
which `h` is `return x+1`, a clean lift. It declines, because `detectSpecializations`
(`CQLoweringPass.cpp:319`) runs long before `deleteGlobalPhases` (`:469`). The DISPOSITION is
unchanged from fa96336 and matches the oracle on the old spelling (`p/d2_old.c` → the same
string), so **this is not a regression and not F-L3-3's doing** — F-L3-3 only moved it onto
the right ground. It is recorded because it is the one D2-designated shape that never gets
D2's treatment, and because the P7-position argument in `CQLoweringPass.cpp:410-467` discusses
`detectSpecializations` at round 2 without noting that at round 1 it pre-empts D2 entirely.
Owner-scale item, not a fix-agent one.

---

## CLEAR — re-attacked and found sound (with what was measured)

1. **The `!cq.branchphase` record, corpus-wide.** 633 accepted fixtures, MDMISMATCH=0; 5/5
   emission sites stamped; 0 non-`i1` `cqrt_rz` anywhere.
2. **Metadata survival across the utilities that could drop it.** `grep` over `ir-pass/src`
   finds no `dropUnknownNonDebugMetadata`/`dropUnknownMetadata` anywhere; the two
   `Instruction::clone()` sites (`BreakReversePlay.cpp:514`, `ByRefInline.cpp:263`) copy
   metadata by construction; `CloneFunctionInto` is unreachable for a kickback gate (F-R1-5);
   RAUW touches operands, not metadata. No probe produced an unmarked gate.
3. **`lowerBreakReversePlay`.** `BreakReversePlay.cpp:739/744` pre-scan every discovered rail
   gate with `isInverseEmittable` and DECLINE (`kMsgBreakUninvertible`) on a refusal — so a
   recorded kickback gate can only produce a loud decline, never a reverse-play cancellation.
4. **The other consumers of the three narrowed predicates, one by one.**
   `railOf` (ChainWalk.cpp:692) → null, derived from `isInPlaceGateOn`, correct;
   `isTerminalHandle` (:730) → false ⇒ leak, safe;
   `isInteriorConsumer` (:750) / `isInteriorTerminalHandle` I3/I4 (:892) → false ⇒ leak, safe;
   `DagTraversal` step 1 (:104) / step 3 (:235,:416) → `NotClosed`, the mechanism itself;
   `Uncomputation` moved-anchor scan (:510) → the gate is diagonal so there is no clause-(d)
   question to answer; `borrow` (:902) → the gate's only other operand is a `double` constant,
   so no borrow is lost; `Anchorable` (:1429) and the component link (:1508) → the flag is
   excluded from `Cand` by I3 one level up;
   `ArithLowering::priorUseIsSettled` (:515) → arm (a) no longer claims it and **arm (c)
   does** (void, `cqrt_`-prefixed, not a qram store), same verdict `true`, so M-C's decision
   does not move — the file's own per-stem table should gain the row;
   `preservesBorrowedParent` (1b) → untouched, different spelling (arg 1, arity 3);
   `preservesBorrowedParent` (1) → **see F-R1-4**;
   `tools/free_pairing_check.py` `classify()` → `cqrt_rz` stays transparent, measured
   (STRICT 2b `0 violation(s)` on every accepting probe, and it never fails "unclassified").
5. **`deleteGlobalPhases`' new position, the round-2 interactions the fix agent named.**
   onward + ShareCondFlag (`p/o_onward_sharecond.c`, rc 0, 17 lines), onward ×2 regions
   (`p/o_onward_two.c`, 21 lines, both phases emitted, both flags stripped+freed), onward +
   angle select (L3's `repro_t1`, **4** `cqrt_rz_i1`, **0** `cqrt_copy_f64_controlled`, 4/4
   marked — was 0/5 on fa96336), onward value arm (`repro_n1`, now rc 1 `impure value arm`,
   was rc 0), onward kickback (`repro_j1`, now rc 0 with 2 marked gates, was rc 1). Onward +
   in-loop is **F-R1-1**.
6. **The reverse direction: a genuinely classical-control phase is still DELETED, not
   declined.** `p/g_classguard.c` (`if (volatile g) cq_phi(θ)` after a claimed region, 7
   lines), `p/g_classloop.c` (a classical `for` loop of phases, 7 lines),
   `p/g_uncond_after.c` (unconditional, 7 lines) — all rc 0 and all byte-identical to the
   no-phase circuit. The single exception is **F-R1-2**.
7. **Tainted angles.** decline in all three positions: flat (`rotation angle under quantum
   control`), under an ONWARD region (same string, i.e. the round-2 slot did not weaken it),
   and uncontrolled (`cq rotation lowering: unsupported quantum-derived rotation angle`).
8. **The retired-family decline and its ordering.** `resolveSources` runs inside the FIRST
   `propagate`, before any claim, and LLVM's default diagnostic handler `exit(1)`s on the
   first `DS_Error` (`ir-pass/tools/cq_opt_main.cpp` installs no handler and tracks no error
   state — so F-L3-5's "exits at the first `DS_Error` and never writes `-o`" is confirmed
   from the source, and `declineSurvivingIntrinsicCalls`' `return` after `diagnose` is
   defensive dead code). Measured: decl-only retired symbol → rc 0 and the decl is SWEPT
   (0 `cq_phi` in the output, matching the `!use_empty` narrowing's stated measurement);
   a retired-family address-take → `retired register-form cq_phi_si32; use the register-free
   void cq_phi`; a NEW-surface address-take → `front-end intrinsic cq_phi has its address
   taken; only a direct call is supported`.
9. **`taint.PhaseCalls` scrubbing.** All four emitters scrub before erasing
   (`SwapRouteEmit.cpp:1612` flat, `:1855` nest, `SwitchRouteEmit.cpp:80`,
   `AngleSelectEmit.cpp:201`), which matters MORE after the P7 reorder because round-2
   `detectSpecializations` reads that vector (`SpecializeDetect.cpp:43`,
   `SpecializeReject.cpp:70`) after round-1 erasures. No dangling entry found.
10. **`invariantRegisterRoots` / per-bit byte-identity.** rolled vs hand-unrolled traces are
    IDENTICAL at K=2 (21 lines), K=4 (39), K=4 with a body `cq_theta` (43), and two
    registers × two regions per trip (78). K=32 diverges **only** because `clang -O1` folds
    `(q>>31)&1` to `icmp sgt q,-1` in the unrolled spelling — both circuits discharge every
    rail; that is a frontend canonicalization, not a lowering divergence.
11. **Part B — P3 (compound trees).** `&&`, `||`, folded nest, `(a&&b)&&c`, `(a||b)&&c` all
    accept with an exact-LIFO teardown: node undo → node ancilla free → leaf `_unc` strips in
    reverse mint order → leaf rail frees. OR is `cnot;cnot;toffoli` forward and its exact
    mirror back (`g = a⊕b⊕ab = a∨b`, self-inverse). STRICT 2b clean on all. The `&&` and the
    folded-nest traces are **BYTE-IDENTICAL** (17 lines). Declines, all loud: a leaf shared
    between two trees (`condition used outside the branch`), a classical leaf (`control
    flow`), a tree beside a sequential Ry arm or a second tree (`condition data use neither
    escaped nor measured` / `condition used outside the branch`).
12. **Part B — P4 (the genuine nest).** `if(q>5){cq_phi(.25); if(q<9) cq_phi(.75);}` emits
    the outer phase on `f1`, one `cqrt_toffoli` conjunction, the inner phase on `g`, exact
    LIFO undo, three frees; the two-register nest and the empty-outer nest likewise. Declines:
    a trailing phase after the inner nest, depth 3, a mixed nest (`impure phase arm`), an
    inner `if/else`.
13. **Part B — P5 (the phase switch), five hand-IR mutations.** `default == a case block`
    ACCEPTS and the emitted circuit is CORRECT (`rz_i1(f,.2)` on `q==1`, `x;rz_i1(f,.1);x` on
    `q!=1`); two case values sharing one block, an arm branching to another arm, an extra
    merge predecessor, and a `cq_theta` on the scrutinee inside an arm all DECLINE `control
    flow`. No mutation produced an accept with a wrong unitary.
14. **ShareCondFlag opacity re-probed on the new surfaces.** two kickbacks on one shared flag
    (`p/r1_c_twokick.c`: SUBJECT 8 lines with **0** negative-angle gates; fa96336 12 lines
    with `rz_i1(h1,-0x1.8p-1)` and `rz_i1(h1,-0x1p-2)`, i.e. the F-L7-1 defect reproduces on
    the round-1 binary and is gone here); a shared flag under the merge-tail φ (`u8`, both
    polarities, identical on both binaries); a shared flag in a rolled loop
    (`p/r1_e_inloop.c`, SUBJECT 47 lines vs fa96336 39 — the four `lshr` rails now discharge,
    0 negative-angle gates on either); a shared flag whose data use is a `select`, a clone
    argument, or a tape write — all loud declines.

---

## VERDICT — R1: **NOT CLEAR.**
**One CONFIRMED rolled≠unrolled divergence (F-R1-1)** — plain C through the shipped 2-TU
onward harness, `opt` exit 0, verify-clean, STRICT stage-2b `0 violation(s)`, three entangled
which-path rails leaked per activation, and a discriminating control that isolates the cause
to a stage that runs once at round 1 while the region is claimed at round 2. It declines on
the round-1 subject, so it is a population the round-1 fixes created, and its root cause is
NOT the one OWNER QUESTION Q-R1-1 names. **One OVER-DECLINE (F-R1-2)** in which a statement
the compiler is required to delete makes a compiling program stop compiling, together with a
"LATENT / unreachable at HEAD" claim that is measurably false. **Four DOC-OR-FIXTURE-TRUTH
items (F-R1-3…F-R1-6)**, of which F-R1-3 (the emission-site enumeration, now 3-stated /
5-actual) and F-R1-4 (a `cqrt_rz_` name row that admits the gate the fix refuses, omitted
from the closure table whose purpose is completeness) are the two that could cost a future
increment. The fix set's CORE claim — that no emitted kickback gate is ever adjointed —
holds: 633 accepted fixtures and 40+ plain-C probes, MDMISMATCH 0, zero negative-angle
`cqrt_rz_i1` anywhere.
