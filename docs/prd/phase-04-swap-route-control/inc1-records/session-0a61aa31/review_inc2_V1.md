# review_inc2_V1 — Rule-13 ROUND 1 on Inc 2 (value arms by controlled-copy merge), lens V1: THE MECHANISM

Agent `review_inc2_V1`, READ-ONLY, 2026-09-05.
SUBJECT `$SP/wt/inc2` @ `8c526d9` (branch `3qlq-inc2`; its `build/` used as-is, never rebuilt, never edited).
ORACLE  `$SP/wt/pre-3qlq` @ `52d7764`.
All artifacts under `$SP/progress/review_inc2_V1/` (`run.sh` = the full pipeline driver; `probe/` = every program + both binaries' stage-1/2/2b/3/4 outputs).

## What I ran (only what I ran)
- **50 plain-C programs** (49 compiled; `e1_i128cond.c` is a `_Generic` front-end error, not a pass result) and **9 hand-written `.ll` modules**, EACH through stage 1 → 2 → **STRICT 2b** (`free_pairing_check.py`, no `--allow-unproven`) → 3 → 4 on **BOTH** binaries. Driver: `$SP/progress/review_inc2_V1/run.sh`.
- The **7 committed Inc-2 value slices** (`slice_control_value_{diamond,diamond_twin,ifelse,ifelse_twin,mixedops,mixedops_twin,derived}.c`) re-derived from source on both binaries and `cmp`'d against the committed goldens.
- The three `cmp` twin gates reproduced directly over the committed goldens (`cmake -E compare_files` equivalent).
- Source reading: `SwapRouteEmit.cpp` (`emitValueRegion`, new + oracle), `SelectMergeEmit.cpp`, `SelectClassify.{h,cpp}`, `ArmClassify.cpp` (`walkValueChain` / `valueArmIsPureChain` / §3c / `comparePredLowerable`), `ArithLowering.cpp` (M-C `classifyInPlaceReassignment` / `inPlaceFenceHolds` G3–G7 / `priorUseIsSettled` / `lowerLateReassignments`), `CompareLowering.cpp` (`qqSelectLeafWidth`, `compareFlagMintable`, `rewriteCompare` Q+Q width), `CastLowering.cpp`, `ControlledSymbols.cpp`, `CQLoweringPass.cpp` staging, `tools/opcode_table.yaml`, `runtime/cq_runtime.h`.
- I did **NOT** run `ctest` or `lit` (the subject's build tree is off-limits per the brief); every gate I report I re-derived by hand from source through the shipped pipeline, which is strictly stronger evidence than the gate.

**No CONFIRMED-MISCOMPILE found.** One confirmed unreviewed accept-class WIDENING (F-V1-1), three doc/fixture-truth findings, one missing-pin coupling, three CLEARs, and one pre-existing Rule-1 gap found in passing.

---

## F-V1-1 — CONFIRMED UNREVIEWED WIDENING: Inc 2 silently unlocks every DOWNSTREAM consumer of a value-arm merge, at every width (grade: OVER-ACCEPT-BY-WIDENING, not a miscompile)

**Claim under review.** The hand-back states the only side-effect widening was the Q+Q condition (closed by F-QQCOND), and that on the width axis "the two agree on every width a value arm can reach" (`copyControlledFn` vs `copyFn`, measured i8/i16/i64/i128).

**Measured: false.** Routing the diamond through `emitSelectRegion` also picks up `SelectMergeEmit.cpp:238`

    taint.HandleWidth[Out] = Abi;      // bd p119.6

which the retired `emitValueRegion` did **not** set (oracle `SwapRouteEmit.cpp` step 6 sets only `Tainted` / `ControlOwnedRails` / `BirthOrder`). `HandleWidth` is exactly the side-table a downstream **cast** (`OpcodeLowering.cpp:307`) and a downstream **Q+Q data compare** (`CompareLowering.cpp:436-441`) read to recover the logical width of a laundered i32 handle. With no entry, both decline `no template …`.

**Five plain-C reproducers, all ACCEPT on the subject / DECLINE on the oracle:**

| probe | program (6-op chain `R`) | ORACLE 52d7764 | SUBJECT 8c526d9 |
|---|---|---|---|
| `g1_i8_cast` | `signed char p; if(q>5){R(p)} int w=(int)p; measure(w)` | rc=1 `no template for opcode 'sext i32' in tainted context` | rc=0, **24 lines**, `cq_template_sext_i8_to_i32(h5)` |
| `g3_i64_cast` | `long long p; …; int w=(int)p` | rc=1 `no template for opcode 'trunc i32'` | rc=0, 24 lines |
| `g2_i8_qq` | `signed char p,r; …; int e=(p==r)` | rc=1 `no template for opcode 'icmp i1'` | rc=0, 29 lines, `cq_template_icmp_eq_i8(h6,h2)` |
| `g4_i16_qq` | `short p,r; …; int e=(p>r)` | rc=1 `no template for opcode 'icmp i1'` | rc=0, 29 lines |
| `s3_out_qq_i32` | **`int p,r; …; int e=(p==r)`** | rc=1 `no template for opcode 'icmp i1'` | rc=0, 29 lines, `cq_template_icmp_eq_i32(h6,h2)` |

`s3` is the load-bearing row: **the widening is not a sub-i32 artefact — it fires at i32, the flagship width**, because `rewriteCompare`'s Q+Q path requires a *recorded* width and never falls back to the SSA type.

**Is it sound?** As far as I can measure, yes: every emitted stream is a correct out-of-place template on the right width, STRICT stage 2b is clean (rc=0) on all five, and the traces read correctly line by line. It is a genuine capability gain (the value-diamond path inherits the p119.6 fix).

**Why it is still a finding.** (i) It is an accept-class widening shipped as an invisible side effect of a mechanism change — precisely the thing F-QQCOND was added, one function earlier, to *prevent* ("Routing the value diamond through the select emitter would therefore WIDEN the accept class as a side effect of a mechanism change, which is exactly the kind of unintended widening the Prime Directive refuses to ship unreviewed"). The same sentence applies verbatim here and was not applied. (ii) It is pinned by **zero** fixtures and **zero** slices, so nothing would notice if it regressed or if the width recorded were ever wrong. (iii) It falsifies two hand-back sentences that a later reader will rely on.

**Proposed disposition (owner's, not mine).** Either (a) keep it, and add one accept fixture + one e2e slice per consumer kind (a `sext` off an i8 merge; a Q+Q compare off an i32 merge) plus a hand-back correction; or (b) if the epic wants a strictly behaviour-preserving Inc 2, `emitValueRegion` must not inherit it — but note that suppressing it means deliberately re-introducing a known p119.6 defect, which I do not recommend.

**Pinning fixtures to add:** `ir-pass/test/control_swap_value_accept_i8_merge_cast.ll`, `…_accept_qq_compare_on_merge.ll` (both ACCEPT, with the width in the CHECK: `cq_template_sext_i8_to_i32` / `cq_template_icmp_eq_i32(`), + one e2e slice so the symbol is proved to link.
**File:line:** `ir-pass/src/SelectMergeEmit.cpp:238` (the inherited write) reached from `ir-pass/src/SwapRouteEmit.cpp:419` (`emitSelectRegion(S, wd, csyms, taint)`).

---

## F-V1-2 — MUTATE-THEN-DECLINE: `emitValueRegion` commits the hoist + select + RAUW + flatten BEFORE `emitSelectRegion`'s flag mint can fail (grade: DOC-OR-FIXTURE-TRUTH / hardening; NO reproducer at HEAD)

`emitValueRegion` pre-flights `R.ShareCondFlag`, the arm classes, base identity, the ABI width, `StaleDeclined` and the two new fences — then **mutates** (hoist, `SelectInst::Create`, RAUW of the merge φ, `flattenRegion`) — and only then calls `emitSelectRegion`, which can still `return` after diagnosing at `SelectMergeEmit.cpp:208`:

    Value *F = lowerCompareToFlag(Leaf, wd, taint, qqSelectLeafWidth(...), false, Sel);
    if (!F) return;   // already diagnosed (unsupported width / predicate) — loud.

The ORACLE minted the flag as emission **step 1**, before any other mutation, so its bail left the region intact.

The predicate half is covered at detection (`ArmClassify.cpp:2023` `comparePredLowerable`). The **width** half (`compareFlagMintable`, `CompareLowering.cpp:308` — `AbiWidth.empty() || AbiWidth == "i128"`) is **not** asked anywhere on this path. This tree already treats that exact gap as a bug in two sibling emitters, in this same file family:
- `ArmClassify.cpp:3423` (6.5 classical-call arm): *"the emitter calls `lowerCompareToFlag` only AFTER hoisting the call, so a post-hoist mint failure would be a mutate-then-decline. Mirror the `classifyArms` gates so a bad-condition classical-call diamond never reaches the emitter."*
- `AngleSelectEmit.cpp:233-234` step 0b re-asks **both** `comparePredLowerable` **and** `compareFlagMintable` in lockstep, added by the Inc-2b round-1 Rule-13 review for exactly this reason.

**I could not build a reproducer** and say so first: the only reachable `compareFlagMintable`-false-but-`comparePredLowerable`-true shape is an i128-typed condition, and that shape never reaches the control layer at all (see F-V1-9). So this is unreachable at HEAD, in the same class as the increment's own `StaleDeclined` defensive bail — which the increment nevertheless chose to pre-fence, one screen earlier, on the library-host argument. The asymmetry is the finding.

**Proposed fix:** `ir-pass/src/SwapRouteEmit.cpp`, in `emitValueRegion`'s pre-mutation block (beside F-QQCOND, ~line 355): `if (!comparePredLowerable(Cond) || !compareFlagMintable(Cond, taint)) { diagnoseUnderControl(Cond, "control flow"); return; }` — three lines, mirrors `AngleSelectEmit` step 0b, cannot narrow anything reachable.
**Pinning fixture:** none possible today; add the guard with a comment saying so (the `StaleDeclined` precedent) rather than an untestable fixture.

---

## F-V1-3 — the totality table's fp row is FALSE as written, and the fp safety net is never exercised (grade: DOC-OR-FIXTURE-TRUTH)

`$SP/progress/impl_inc2.md` step 7 states:

> `fadd/fsub/fmul/fdiv/frem` … **UNREACHABLE: `ArmClassify` declines an FP-typed merge as an ANGLE before the chain base is read, so no fp value arm reaches either emitter.**

**Measured — the conclusion holds, the reason does not.** `m1_fp_arm.c` (`double p; if (q>5) { 6 fp ops }`) **ACCEPTS on both binaries, byte-identically, 29 lines**, emitting `cqrt_copy_f64_controlled` — the kjd1 fp merge. Hand IR pins it further: `n1_fp_diamond.ll` (a real `br` diamond with a `phi double` merge) and `n4_fp_div_diamond.ll` (with an `fdiv` by a run-time divisor) both lower to the **controlled-copy merge with a residual `br label %merge` and an empty `merge:` block on BOTH binaries** — i.e. the `phi double` is lifted to a `select` *before* `detectControlRegions`, so the region never reaches `ArmClassify`'s value path or `emitValueRegion` at all. It is not "declined as an angle"; it is claimed by another stage.

Two consequences worth recording rather than the sentence as written:
1. `emitValueRegion`'s fp safety net — the pre-flight `csyms.copyControlledFn(Abi)`, which returns a null callee for any non-integer width (`ControlledSymbols.cpp:121`) and so would decline `control flow` — is **unreached and untested**. It is also the one place where the new pre-flight is *stricter* than the emitter it guards (`emitSelectRegion` would have used `copyControlledFpFn`), i.e. a latent NARROWING, not a widening. Safe direction, but nothing measures it.
2. The oracle's pre-flight used `wd.copyFn(Abi)`, which **does** resolve at f16/f32/f64/f80. So if the phi-lift ever narrows, the two binaries diverge (oracle would route an fp value arm; the subject declines). Also the safe direction, also unmeasured.

**Proposed fix:** correct the table row to "unreachable because the fp merge φ is lifted to a `select` before detection (measured `n1_fp_diamond.ll`); the `copyControlledFn` null pre-flight is the unreached backstop", and add `ir-pass/test/control_swap_value_reject_fp_arm.ll` **only if** a hand-IR shape can be found that survives the lift — otherwise say so explicitly.

---

## F-V1-4 — the shipped stream leaks an ENTANGLED chain-final rail per arm; the PRD says it is `_unc`'d and "freed clean" (grade: DOC-OR-FIXTURE-TRUTH, with a real change of leak CLASS)

PRD §3 ("Value arm by controlled copy") and §7.1 both describe the replacement stream as ending `… copy_controlled(f, p, out); x(f); **6 _unc**; strip; free f`, and §3 says in terms: "`t` uncomputed by `_unc` (a function of the unchanged `p`) … `t`, `f` freed clean". The BRIEF repeats it ("chain `_unc`; strip; free").

**Measured, subject, `slice_control_value_diamond.expected.log` (23 lines):** the `_unc`s that appear are the **interior** partition's, discharging `h2` *before* the merge; the chain FINAL `h3 = R(p)` is **never uncomputed and never freed** — `cqrt_free` appears exactly twice (h2, the flag h4). Same in every one of my 30+ accepting probes: `EXACTLY ONE free per region beyond the interior partition's, and it is the flag`. `slice_control_value_ifelse` leaks **two** finals (h3, h5). The impl's own §V3 note ("WHY LEAVING d_i ALLOCATED IS SOUND") extends to V1/V2 in one sentence and the two fixtures' comments say it, but the PRD and the brief were not corrected.

**Physics — I agree it is sound, and here is the argument stated once.** `t = R(p)` is a deterministic function of `p`, and `p` is kept live (keep-source-live), so tracing out `t` leaves the reduced state on `(q, p, out)` exactly what it would be without `t`. Rule 6 tolerates a never-freed rail.

**But the leak CLASS changed and that is not written down anywhere.** The oracle's leaked intermediates were `_unc`-**zeroed** (disentangled, information-free); the subject's chain final is a **live, entangled** rail. The two are not the same kind of debt: the moment anything in the pipeline decides that `p` itself may be discharged, the entangled `t` becomes the sole record and the argument above collapses. (I probed for that: `p` is never freed in any shape I could build — its consumer count is always ≥2, the chain head plus either the second controlled copy (V1) or the sibling chain head (V2), so `ChainWalk::forwardConsumerCount`'s fan-out bail always fires; this is the invariant bd memory `select-merge-no-chainwalk-exemption` was written to protect and it still holds. But it now holds for the value-diamond path too, and nothing records that.)

**Proposed fix:** correct PRD §3/§7.1 to the stream that ships; add one sentence to `emitValueRegion`'s header naming the entangled-final leak, its soundness argument, and its dependence on `p` never being freed (cross-referencing `select-merge-no-chainwalk-exemption`); file the "discharge the chain final" improvement beside PRD §9's "freeing the value-arm SOURCE".

---

## F-V1-5 — §3c / M-C under the hoist: CLEAR — but the if/else merge's "two distinct copy sources" property is now underwritten by M-C's G6/G7 pair alone, with no pin (grade: CLEAR-WITH-MISSING-PIN)

**The hazard, stated exactly.** `lowerOps`' M-C converts a tainted `add`/`sub`/`xor` into an in-place `cqrt_addc`/`cqrt_xorc` and RAUWs the result to the **parent's** handle. If M-C ever fired on the chain HEAD (whose parent is `Q`), then for a **diamond** the second copy `copy_controlled(f, Q, out)` would read a relabelled `Q` (`out = f?R(p):R(p)` — the arm lost, a wrong unitary), and for an **if/else** with BOTH heads converted the two copy sources would collapse to the same register (`out = f?Q:Q`). Neither is visible to `opt -verify`, to the golden diff, or to `free_pairing_check.py` (nothing is freed dirty).

**Measured: it never fires, on every shape I could construct.**

| probe | shape | chain head emitted |
|---|---|---|
| `a2_diamond_addhead` (C) | diamond, head `p+4` | `cq_template_add_i32_hl(h1, 4) -> h2` — **out of place** |
| `h2_onelink_add.ll` | 1-link diamond, head `add p,5` | `cq_template_add_i32_hl(%h1, 5)` — out of place |
| `a1_ifelse_addhead` (C) | if/else, arm-2 head `p+4`, arm-1 rails FULLY interior-discharged before it | `cq_template_add_i32_hl(h1, 4) -> h5` — out of place |
| `h3_ifelse_addhead.ll` | if/else, `mul` head + `add` head | both out of place |
| `slice_control_value_mixedops` | `sub/and/or/shl/xor/mul` | `shl` head out of place; `addc`/`xorc` in place on the FRESH rails only |

The structural reason (read out of `ArithLowering.cpp:643-690`): every chain head reads `Q`, and `Q` always has a **second** user — the second controlled copy (V1) or the sibling arm's head (V2). For the earlier head, **G6** (`provablyBefore(UI, Site, DT)`) refuses because the later user is after it; for the later head, **G7** refuses because the earlier head is a rail-minting producer that is not yet discharged in the IR (arm (d)) and, measured, is not admitted by the plan (arm (d2)). So *at least one* of the two heads is always refused, which is enough — the collision needs BOTH.

**Why it is still worth a finding.** Inc 2 has made a load-bearing correctness property of the value merge (the two copy sources denote distinct physical registers — `SelectClassify`'s **gate 6**, which the diamond path does not run) depend on a fence in a *different* subsystem, written for a *different* customer, and whose own source says of itself:

> "SAY 'PAIR', NOT 'G6', AND SAY WHY IT IS A WEAK TRIPWIRE. Measured by mutation on that fixture: disabling G6 ALONE leaves it green (G7 refuses the same use), disabling G7 alone leaves it green … If you relax EITHER of these to admit a site with a later read, re-derive `collectRailGates`' off-chain-BO rule BEFORE relaxing anything here — the test suite will not do it for you." (`ArithLowering.cpp:669-687`)

The M-C comment now has a **second** out-of-file consumer and does not know it, and the G7 comment explicitly contemplates a future widening (`At == bo`) that would move the if/else case.

**Proposed fix (cheap, no behaviour):** (a) add the value merge to that comment's out-of-file-consumer list; (b) add an Inc-2 accept fixture whose whole point is the disposition — `control_swap_value_ifelse_inplace_head_out_of_place.ll`, an if/else with `add`-headed chains, with `; CHECK: cq_template_add_i32_hl(` **and** a whole-file `NOROUTE-NOT: cqrt_addc_i32(i32 %h1` — so that relaxing G6/G7 reddens an Inc-2 fixture rather than silently changing the merge.

---

## F-V1-6 — speculation totality: CLEAR (red-green measured), with one correction to the recorded rationale

**Measured red-green, plain C, both binaries:**

| probe | ORACLE | SUBJECT |
|---|---|---|
| `c2_div_runtime` `p / n`, run-time classical `n` | rc=0 **ACCEPTS** (28 lines) | rc=1 `cq controlled lowering: value arm op that cannot run unconditionally under quantum control` |
| `c3_srem_runtime` `p % n` | rc=0 ACCEPTS | rc=1 same string |
| `n3_int_div_diamond.ll` `sdiv %p, %n` (2-op hand-IR diamond) | rc=0 | rc=1 same string |
| `c1_div_guard` `p / 3` | rc=0 (28) | rc=0 (26) — the discriminator holds |
| `c5_udiv_const` `p / 3u` | rc=0 | rc=0 |
| `c4_shift_runtime` `p << n`, run-time `n` | rc=0 (28) | rc=0 (26) — unchanged, OWNER QUESTION 2 |
| `d9_qq_link` `p + r`, both tainted | rc=1 `value-arm swap-route` | identical |
| `s7_shift_tainted` `p << s`, `s` tainted | rc=1 `value-arm swap-route` | identical |

So: a **quantum** divisor/shift-amount can never reach the hoist (Q+Q links decline at classification, both binaries), a **classical possibly-zero** divisor is now fenced, and a proven-non-zero constant still lowers. The fence is `isSafeToSpeculativelyExecute` with no context instruction, i.e. LLVM's conservative form — it can only over-decline. I agree with the choice (Rule 14) and with the "runtime cannot answer this" honesty: `runtime/cq_templates.c` bodies do `h = cqrt_alloc_handle(); printf(...); return h;` and compute nothing, so totality is an ABI-semantics statement for a Phase-9 backend, not a runtime property. Every out-of-place template is `out ^= f(x)` on a fresh `|0⟩` rail, which is a permutation for **any total** `f`; the only non-total `f` in the admitted stem set is integer division at a zero (or `INT_MIN/-1`) divisor, and that is exactly what the fence removes.

**The correction.** The rationale as recorded reads: *"the pre-3qlq route also ran the chain UNCONTROLLED (on a `|0>` rail, i.e. `0 sdiv n`)"*. That is the **classical-trace** reading of the route and it is misleading as a physics statement: `cqrt_cswap(f, p, rail)` leaves the rail in a **superposition** of `p0` and `0` correlated with the flag, so the route's chain gate had to be defined on `p0`'s whole range too. The conclusion the impl draws (the hazard is not created by the hoist; the fence narrows; narrowing is safe) is **right and is strengthened** by the corrected reading — but the sentence as written could later be quoted to argue that the inactive-branch input used to be zero and that the fence is therefore over-strict. It is not. Please restate it.

**One unexercised arm, recorded so nobody assumes it is covered:** the `INT_MIN / -1` half of `isSafeToSpeculativelyExecute`'s SDiv rule. `m2_div_neg1.c` (`p / -1`) **accepts** on the subject — because `clang -O1` folds it to `sub i32 0, %p` (`cq_template_sub_i32_lh(0, h1)` in the trace), so no `sdiv` ever reaches the fence. No C program I could write exercises that arm; a hand-IR decline fixture would.

---

## F-V1-7 — the three twin gates, on BOTH binaries: CLEAR

Re-derived independently (not by running ctest):

| pair | subject trace | twin trace on SUBJECT | twin trace on ORACLE | committed golden |
|---|---|---|---|---|
| `value_diamond` (6-op) | 23 | 23, **identical** | 23, **identical to the SUBJECT's** | identical |
| `value_ifelse` | 33 | 33, identical | 33, identical | identical |
| `value_mixedops` | 24 | 24, identical | 24, identical | identical |

The load-bearing column is the third: **each twin's trace is byte-identical between the oracle and the subject**, so the oracle did not move under Inc 2 and the byte-identity witness is valid rather than circular. `cmp` over the committed goldens reproduces all three ctest gates as PASS. `slice_control_value_derived`'s committed golden also reproduces exactly (24 lines) — and it correctly ships **without** a gate, since its select twin declines `control flow` on both binaries (verified: `j1t_rz_before_twin`).

I added a fourth pair the increment does not have and it also holds: **negated polarity**. `m3_polarity_ne.c` (`if (q != 5)`, which `-O1` canonicalises to `icmp eq` + swapped successors, `ArmNegated`) is **byte-identical (23 lines) to its pre-hoisted select twin on the subject**, and the twin is identical on both binaries. That is the only measurement that pins `emitValueRegion`'s Rule-9 polarity choice (`TrueVal = Q` when `Arms[0].Negated`) against an independent oracle; `control_swap_value_diamond_polarity.ll` pins the emitted symbols but not the *equivalence*. **Recommend promoting `m3` to a 4th slice+gate** (`slice_control_value_polarity{,_twin}.c`) — it is free and it is the one arm of the emitter that a swapped operand pair would silently corrupt.

---

## F-V1-8 — uncompute / whole-DAG-spine interaction: CLEAR over 12 measured shapes

All on both binaries, all STRICT stage 2b rc=0. **Mechanically audited: across all 38 accepting SUBJECT traces I produced, every single `cqrt_free` names either a rail a `_unc` returned to |0> on the lines immediately above it, or a compare-minted flag stripped by its own `…_hl_unc` — zero unproven frees, and no free of a merge out-rail, a chain final, or a source anywhere** (script re-run at the end of the session; 38 traces scanned, 0 hits).

| probe | shape | SUBJECT | ORACLE | note |
|---|---|---|---|---|
| `d1_out_dead` | merge result unused | accept 5 | accept 5 | **identical**; region DCE'd on both |
| `d2_out_ret` / `s5_chainfinal_ret` | merge `ret`urned | accept 4 | accept 4 | identical |
| `d3_p_also_measured` | `measure(out) + measure(p)` | accept 24 | accept 29 | both measure `out` then the untouched source |
| `d4_seq_two_regions` | two value diamonds on one `p` (hcrg order) | accept 41 | accept 51 | region 2's chain correctly bases at region 1's `%out` |
| `s4_out_second_cond` | region 2's *condition* reads region 1's `out` | accept 41 | accept 51 | correct |
| `t1/t2` value↔phase interleaved | source order preserved | accept 28 | accept 33 | phase region's `rz_controlled` stays in source position |
| `t4_ifelse_seq` | if/else then diamond | accept 51 | accept 77 | correct |
| `d6_inloop` | value arm in a bounded loop | decline `condition predates a non-diagonal gate` | identical | loop decline kept |
| `d5_nested` | depth-2 nest | decline `control flow` | identical | |
| `d7/d8/d10` §3c (`cond` is the base / alias / derived) | decline `arm rewrites a condition operand` | identical | | 
| `d11_sharecond`, `t3_value_then_select` | condition read as data | decline `condition used outside the branch` | identical | |
| `k2_derived_mulbase_twin` | derived base kept live across the merge | accept 24 | accept 24 **identical** | the derived base is left allocated, never discharged before the copy |

The specific order hazard I went looking for — an interior discharge of the copy SOURCE scheduled **before** the controlled copy that reads it — does not occur: `lowerLateReassignments`/`uncompute` run after control emission and place every adjoint at a post-dominating point, and in `k2` the derived base `h2 = mul(h1,3)` is left allocated precisely because the copy is a live consumer.

**One structural note for the record:** the hoist can only move a chain link *later* within `Pred` (it lands immediately before the terminator), never earlier, so it can never be scheduled above a gate already emitted into `Pred` by a preceding region. That is what makes the t1/t2 source-order results hold, and it is worth one line in the emitter header.

---

## F-V1-9 — PRE-EXISTING (not Inc 2's): a tainted `i128` branch condition is neither claimed nor declined by the control layer (grade: file it)

`f1_i128cond.ll` (value arm) and `f2_i128cond_phase.ll` (phase arm) — a tainted `icmp sgt i128` used as a branch condition — produce, on **both** binaries, **only**

    error: … no template for opcode 'icmp i1' in tainted context

and **no `cq controlled lowering:` diagnostic at all**. `opt` exits 1 for an unrelated reason (the same compare failing to lower in DATA position), so nothing wrong is emitted, but a tainted `br` reached the end of the pass without being claimed or declined — which Rule 1 says cannot happen ("`ControlDetect` either hands the region to the swap-route emitter or declines it loudly; there is no third path"). Identical on `52d7764`, so it long pre-dates this epic and is **outside Inc 2's scope**; I report it because it is the reason F-V1-2's reproducer does not exist, and because if the i128 condition width is ever admitted, F-V1-2 becomes live in the same change.

---

## Verdict

**VERDICT: CLEAR OF SILENT MISCOMPILE, WITH ONE UNREVIEWED WIDENING TO DISPOSE OF AND FOUR TRUTH/PIN REPAIRS.** Across 50 plain-C programs and 9 hand-IR modules run end-to-end on both binaries, I found **no wrong unitary, no dirty free, no mutate-then-decline reachable at HEAD, and no stage-2b failure**; the three twin gates hold on both binaries and a fourth (negated polarity) that the increment does not ship also holds byte-for-byte. The mechanism — hoist + `select` + the Rule-13-cleared 4.4 merge — is what the twins say it is, the speculation fence is a real red-green narrowing, the §3c/M-C hazard the brief flagged as most likely does not fire in any shape I could build, and the value path's `cqrt_cswap` census is exactly as claimed (zero value-path sites; `AbortParkEmit` + the two PHASE routes remain, and the hand-back correctly declines to claim "AbortParkEmit only"). What must not ship unaddressed is **F-V1-1**: an accept-class widening at *every* width, reachable from five plain-C programs, unpinned by any test, and asserted absent in the hand-back — the same category of side effect the increment's own F-QQCOND exists to refuse. **F-V1-2** (3-line pre-flight, sibling-emitter precedent) and **F-V1-5** (one fixture + one comment, so a future M-C relaxation cannot silently break the if/else merge) are cheap and should ride with it; **F-V1-3/F-V1-4** are corrections to statements a later reader would otherwise rely on. Budget a round 2: this file's neighbours are 4-for-4 on the first round finding a confirmed miscompile, and the one class I could not fully exercise here — an fp value arm reaching `emitValueRegion`, and the `INT_MIN/-1` arm of the totality fence — is exactly where an unmeasured backstop is sitting.
