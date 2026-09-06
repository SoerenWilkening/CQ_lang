# review_inc2_r2 — Rule-13 ROUND 2 on Inc 2 (value arms by controlled-copy merge), post-rebase

Agent `review_inc2_r2`, READ-ONLY, 2026-09-06.
SUBJECT = `$SP0/wt/inc2` @ `6ee3ea3` (Inc 2 rebased onto a3c1513; build stamped 05:33, verified NEWER
than every source under ir-pass/include/runtime).
INC-1-ONLY = `/Users/sorenwilkening/Desktop/CQ_lang` @ `a3c1513` (build 05:20, verified current).
ORACLE = `$SP0/wt/pre-3qlq` @ `52d7764` (build 13:39 2026-09-05).
Harness `$W/run.sh` (stage 1 -> 2 -> 2b STRICT -> 3 -> 4), artifacts `$W/p` (programs) `$W/out` (all stages).

## step 0 — setup + control
- Read BRIEF_common, BRIEF_review_inc2_r2, BRIEF_review_inc2_r1, impl_inc2.md, fix_inc2_r1.md,
  review_inc2_V1.md, review_inc2_V2.md, RETIRE_SWAP_ROUTE_INC2_NOTES.md (§1, §1.11, §2, §3),
  rebase_inc2.md, SelectClassify.cpp (all six gates).
- CONTROL (`ctrl_diamond.c`, the flagship 6-op value diamond) on all three: subj ACCEPT 23 lines,
  inc1 ACCEPT 28, orac ACCEPT 28. Harness discriminates.

## step 1 — Q2 fxdiff sweep (1673 common fixtures, INC-1-ONLY vs SUBJECT)
`xargs -P6 -n25 $W/fxdiff.sh < $W/fx/common_paths.txt` (log `$SP/progress/review_inc2_r2_fxdiff.log`):
**0 RCDIFF · 0 DIAGDIFF · 8 OUTDIFF.** 7 of the 8 are fixtures Inc 2 MODIFIED and re-derived; the 8th,
`lowering_switch_value_nonI32_cast.ll`, is NOT in `git diff --name-status a3c1513 HEAD -- ir-pass/test`
(finding F-I2-3).

## step 2 — Q1 the reviewer flag, re-asked
- `q1_derived` (chained-theta base, the shipped slice shape) ACCEPT subj 24 / inc1 29 / orac 29.
  `q1_derived_twin` (pre-hoisted select) DECLINE `control flow` on ALL THREE. Rebase claim REPRODUCED.
- `q1_plain` / `q1_plain_twin` both ACCEPT everywhere; the twin is 23 lines on all three = the subject's
  diamond. So the refusal is specific to the CHAINED theta.
- WHICH GATE: `CQ_CTRL_DBG=1` names the select; by reading SelectClassify.cpp the refusal is gate 5's
  `hasCoherentDownstreamUse`, on the CHAIN-RESULT operand: `rotationAncestry(Op)` is seeded at `Op`
  and only walks when `Op` is ITSELF a rotation call, so for a derived operand the exemption is empty
  and the base's OWN producing theta (`%3 = theta(%2,.9)`, a rotation user of `%2` which the
  lineage-wide seeding reaches) is flagged as an off-ancestry rotation. `isPhiCall` is DEAD post-Inc-1
  (`isCallToPrefix(V,"cq_phi_")`; the shipped call is `@cq_phi` with no suffix), so gate 5's PHASE half
  and gate 6's diagonal-alias closure have no subject at all.
- The genuine hazard gate 5's seeding was built for (kjd1 `..._fp_theta_fork.ll`, a SUPERSEDED record)
  IS caught on the diamond path by the pass-wide `declineStaleRecordOps`: `q1f_fork_{diamond,twin,after}`
  all DECLINE `cq opcode lowering: operand predates a non-diagonal gate` on all three binaries.
- Enumeration (diamond vs pre-hoisted select twin, all three binaries): fp base (`q1e_fp`) both accept
  29 lines and are byte-identical — the `phi double` is claimed by PredMuxFlatten before detection
  (F-V1-3 reproduced); compare-derived base folds to selects at -O1; alias (`int a=p`) both accept and
  are byte-identical; `p` entangled with `q` (`q1e_ent`) DECLINES `non-routable value multiplexer` on
  ALL THREE while its select twin ACCEPTS on all three (the OPPOSITE asymmetry, pre-existing).
- NEW class, KICKBACK-PHASED register: `q1k_disjoint_phase_then_value` ACCEPT subj 27 / inc1 32, and is
  BYTE-IDENTICAL to its pre-hoisted select twin on the subject. Reverse order also accepts (27/32); its
  twin differs only in gate ORDER, and that order difference is `clang -O1`'s (measured in the stage-1
  IR), not the pass's.

## step 3 — Q3 value/kickback interplay (all measured subj + inc1)
| probe | subj | inc1 |
|---|---|---|
| `q3a_kb_on_p_then_value` (kickback COND reads the value register) | ACCEPT 27 | ACCEPT 32 |
| `q3a_value_then_kb_on_p` (kickback cond reads the MERGED p) | ACCEPT 27, flag minted off the OUT rail | ACCEPT 32, same |
| `q3g_kvk` / `q3g_vkv` (3 sequential regions, both orders) | ACCEPT 31 / 45, SOURCE ORDER PRESERVED | ACCEPT 36 / 55 |
| `q3c_and_diamond` + `q3c_and_twin` (compound `&&`) | DECLINE `control flow` | DECLINE (same) |
| `q3e_kb_in_value_arm` | DECLINE `impure value arm` | identical |
| `q3f_value_in_nest` | DECLINE `mixed phase/value arm` | identical |
| `q3d_switch_mixed` (value cases + a kickback case) | DECLINE `control flow` | identical |
| `q3h_switch_kb_scrutinee` / `q3h_switch_then_kb` | DECLINE `control flow` / `condition data use neither escaped nor measured` | identical |

## step 4 — Q4 the dirty chain-final meets the C-1 machinery
- `q4a_{rolled,unrolled}` (per-bit kickback loop reading the VALUE-MERGE out rail): **BYTE-IDENTICAL** on
  subj and on inc1; all 8 per-bit rails `_unc`'d + freed; the chain final h3 never touched.
- `q4a_carried_{rolled,unrolled}` (+ a carried `r = cq_theta(r,.1)`): **BYTE-IDENTICAL** on both.
- `q4c` (`out = cq_theta(out,.1)` carried in the body): DECLINE `operand predates a non-diagonal gate`, both.
- `q4d_value_in_loop`, `q4d_mixed_in_loop`: DECLINE `condition predates a non-diagonal gate`, both.
- ⚠ `q4b_preadd_{rolled,unrolled}` (ONE extra line, `p = p + 7;` between the merge and the loop):
  **DIVERGE, 52 vs 60 lines, on BOTH binaries** — see finding F-I2-1.

## step 5 — F-I2-1 isolation
| probe | preheader op | subj | inc1 |
|---|---|---|---|
| `q5ctl_theta_preadd` (THETA root, no merge) | `+7` in place | IDENTICAL 40/40 | IDENTICAL |
| `q5v_none` (4.4 SELECT merge, no op) | — | IDENTICAL | IDENTICAL |
| `q5sel_preadd` (4.4 SELECT merge) | `+7` -> `cqrt_addc_i32(h4,7)` IN PLACE | **44 vs 52** | **44 vs 52** |
| `q5v_xor` | `^7` in place | **44 vs 52** | **44 vs 52** |
| `q5v_mul` | `*3` OUT of place (template rail) | **44 vs 52** (= the known Q-R1-1) | same |
| `q5v_add2` | folds; the loop reads the merge directly | IDENTICAL | IDENTICAL |
| `q4b` (Inc-2 VALUE merge) | `+7` in place | **52 vs 60** | **57 vs 65** |
| `q5w_mux` (4.5 data-mux) | folds into the case constants | IDENTICAL | IDENTICAL |
| `q7_k32` (K=32) | `+7` in place | rolled 32 mints / **0** `_unc`; unrolled 31/31 | same |

## step 6 — Q2 the rebase, re-verified independently
- cswap CENSUS over the OUTPUT of all 1685 subject fixtures (`$SP/progress/review_inc2_r2_census.log`,
  828 accept / 857 decline): `@cqrt_cswap` in **6** outputs — `control_swap_abort_park{,_exit,_negated,_trap}`,
  `control_phase_kickback_abort_global_phase` (all AbortParkEmit) and
  `lowering_uncompute_interior_leak_unrecorded_route` (2 of its 3 cswaps are HAND-WRITTEN in its INPUT).
  ZERO value-path cswaps. `grep -rn 'emitRoute(' ir-pass/src ir-pass/include` = 3 lines (def, decl,
  `AbortParkEmit.cpp:396`).
- `#cqrt_rz_i1 == #!cq.branchphase` in **every** accepting fixture; totals **263 = 263**; 160 fixtures
  emit an Rz. 135 marked fixtures re-lowered and scanned: **0** marks off a `call void @cqrt_rz_i1(`.
  All 16 value/switch-value fixtures: `bp=0`, `rz_i1=0`.
- FOUR twin gates re-derived BY HAND through the full pipeline (no ctest in the subject build):
  `e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical` all PASS; 11 Inc-2 slices reproduce
  their committed goldens BYTE-FOR-BYTE with STRICT stage-2b rc=0.
- INJECTION MATRIX re-run on the rebased binary (`inject.py`, 15 accepts x 7 mutations):
  **15/15 controls clean, 0 NOT CAUGHT**, rc=0 (`$SP/progress/review_inc2_r2_inject.log`).
- RED-GREEN of the 12 subject-only fixtures against the INC-1-ONLY binary: every accept FAILS there
  (5 by rc=1 `no template`, 3 by CHECK), both speculation declines ACCEPT there (rc=0), and the
  i128/qq declines exit 1 on both but with `no template for opcode 'icmp i1' in tainted context`
  instead of the control-dialect string, so their `RUN: not | FileCheck` still discriminates.

## step 7 — why nothing caught F-I2-1 (measured)
- `ls ir-pass/test | grep -i preheader` -> SIX `control_phase_kickback_mixed_preheader_*.ll`, every one on
  a **theta** root. `grep -rln 'ii-b\|merge out-rail\|MergeOutRail' ir-pass/test/*.ll` -> the (ii-b)
  merge-out-rail root is pinned by `control_phase_kickback_inloop_merge_rail.ll`, which has **no
  preheader op**. `tools/loop_twin_matrix.expected.txt`'s sub-grid F3 (the PREHEADER in-place axis) has
  exactly TWO cells, `m_addpre_pbit_none_none_rypost` and `m_addpre_pbitd_none_none_rypost`, both on a
  theta root. **The PRODUCT (merge-out-rail root x preheader in-place op) exists in no fixture and no
  matrix cell.** The orchestrator's full `ctest -j6` on the rebased tree is 361/361 green.

---

# FINDINGS

## F-I2-1 — a preheader IN-PLACE dtzb op on a CONTROL-OWNED MERGE OUT-RAIL defeats `invariantRegisterRoots` clause (ii-b): the rolled per-bit kickback loop leaks O(K) entangled which-path rails that the hand-unrolled twin discharges
**Grade: LEAK — rolled != unrolled, i.e. the class the C-1 record itself grades as DIFFERENT UNITARIES
(bd 3qlq Inc 1 round-1 F-L7-2 / round-2 F-R1-1). PRE-EXISTING ON THE LANDED `main` a3c1513; NOT
introduced by Inc 2. Inc 2 adds a FOURTH producer of the rail and therefore adds customers.**

### The reproducer, 13 lines of plain C, NO Inc-2 feature in it
`$W/p/q5sel_preadd_rolled.c` / `..._unrolled.c`:
```c
int slice(void){ int q=3,p=7,r=9; q=cq_theta(q,0.5); p=cq_theta(p,0.25); r=cq_theta(r,0.3);
  int m = (q>5) ? p : r;                 /* 4.4 tainted-condition SELECT merge -> %out */
  m = m + 7;                             /* preheader dtzb op on the merge out-rail    */
  for (int i=0;i<4;i++) if ((m>>i)&1) cq_phi(0.7);   /* D4's designated per-bit idiom  */
  return cq_measure(m); }
```
MEASURED, full pipeline, STRICT stage 2b rc=0 everywhere, `opt` exit 0 everywhere:

| binary | rolled | hand-unrolled |
|---|---|---|
| SUBJECT `$SP0/wt/inc2` 6ee3ea3 | **44 lines, 4 `cq_template_and_i32_hl` mints, 0 `_unc`, 0 frees of them** | 52 lines, 4 mints, **4 `_unc` + 4 frees** |
| INC-1-ONLY `main` a3c1513 | **44 lines, 4 mints, 0 `_unc`** | 52 lines, 4/4 |
| ORACLE 52d7764 | not expressible (`void cq_phi` does not exist there) | — |

At K=32 (`$W/p/q7_k32_*.c`): rolled **32 mints / 0 `_unc`**, unrolled 31/31, 240 vs 301 trace lines,
identical on both binaries. The leak is O(K).

Each leaked rail holds ONE BIT of the merged register — an entangled which-path record — and the idiom
it leaks in is precisely the one owner decision D4 designates as the way to write a register-wide Z.
`free_pairing_check.py` is structurally blind to it (a template-minted rail has no `cqrt_alloc` to
count) and reports **0 violations** on the broken circuit; the golden byte-diff cannot see it either.

### It is the MERGE-OUT-RAIL ROOT, not the loop and not the preheader op, and here is the discrimination
| variant | preheader op as EMITTED | rolled vs unrolled |
|---|---|---|
| THETA root, `m = m + 7` (`q5ctl_*`) | `cqrt_addc_i32` IN PLACE | **IDENTICAL** — the C-1 `commitOutOfLoopInPlaceOps` customer works |
| 4.4 SELECT merge, NO preheader op (`q5v_none`) | — | **IDENTICAL** — clause (ii-b) works |
| 4.4 SELECT merge + `m+7` (`q5sel_preadd`) | `cqrt_addc_i32(h4,7)` IN PLACE | **DIVERGE** |
| 4.4 SELECT merge + `m^7` (`q5v_xor`) | `cqrt_xorc` IN PLACE | **DIVERGE** |
| 4.4 SELECT merge + `m*3` (`q5v_mul`) | `cq_template_mul_i32_hl` OUT of place | DIVERGE — but this is the KNOWN owner question Q-R1-1 (hoisted loop-invariant TEMPLATE rail), a different cause |
| 4.4 SELECT merge + `m+7; m+9` (`q5v_add2`) | `-O1` folds to `+16`; the low 4 bits are unchanged so the loop reads the merge DIRECTLY | **IDENTICAL** |
| **Inc-2 VALUE-arm merge + `p+7`** (`q4b`) | `cqrt_addc_i32(h5,7)` IN PLACE | **DIVERGE** 52 vs 60 (subj) / 57 vs 65 (inc1) |
| 4.5 switch DATA-MUX + `m+7` (`q5w_mux`) | folds into the case constants — the class is unreachable for an all-constant-arm merge | IDENTICAL |

So the population is: **merges whose `%out` holds a NON-CONSTANT value, followed by a dtzb op that M-C
converts IN PLACE, followed by a rolled in-loop kickback region.** MEASURED for two producers — the 4.4
select merge and (new) Inc 2's value-arm merge. The 6.5 classical-call arm is the third by the same
structural argument (its `%out` is a `cqrt_alloc_<W>` in `ControlOwnedRails`, written by controlled
copies before it is read) but I did NOT measure it: my `q5o_call_*` probe declined
`value-arm swap-route` rather than lowering as a 6.5 arm, so treat that row as ANALYTIC. The 4.5
data-mux is measured OUT of the population — its arms are all `ConstantInt` by C1, so `-O1` folds any
classical op on the merge into the case constants and no preheader op survives (`q5w_mux`, IDENTICAL).

### Root cause (ANALYTIC from source, consistent with every measurement above; NOT instrumented)
`LoopLowering.cpp:2950 commitOutOfLoopInPlaceOps` refuses at its stability conjunct
```cpp
Value *P = inPlaceValueRailOperand(BO, taint);
if (!P || !P->hasOneUse()) return;   // unproven — stop, and let the peel stop here too
```
For this shape `P` is the merge out-rail, which **structurally cannot have one use**: the emitters write
it with TWO `cqrt_copy_<W>_controlled` calls before anything reads it (Inc 2's value merge, the 4.4
select merge and the 4.5 data-mux all do). The commit therefore returns without marking; then
`peelInPlaceBase(V, AsLowered=true)` stops at the UN-committed `add`; `dyn_cast<CallInst>(Root)` fails;
`invariantRegisterRootsImpl` returns false; `markIfRailLocal` is never called; the body's per-bit rails
are not iteration-local and the spine skips them. Meanwhile `lowerOps`' M-C independently converts that
same op IN PLACE — `cqrt_addc_i32(h4, 7)` IS in the emitted trace — which is exactly the
"peel refuses / M-C converts" mismatch `commitOutOfLoopInPlaceOps` was written to eliminate.
`hasOneUse()` cannot distinguish a PRIOR WRITER from a LATER READER; M-C's own G6/G7 pair can, and
does.

**This is the 8h7d.5 lesson a further time, in the file that documents it:** C-1 round 2 widened the
ROOT set (clause (ii-b), "a control-owned merge out-rail may be an invariant root") and did not re-ask
`commitOutOfLoopInPlaceOps`'s question, which is computed over the SAME closure (the peel path). Its own
comment even predicts the shape of the miss — *"Widening it ... makes it reachable, and no shipped test
would go red."* No shipped test went red: the full `ctest -j6` on the rebased tree is **361/361**.

### Why nothing covers it
The tree has both halves and never their product: six `control_phase_kickback_mixed_preheader_*.ll`
fixtures (all THETA roots), one `control_phase_kickback_inloop_merge_rail.ll` (merge-out-rail root, NO
preheader op), and exactly two loop-twin-matrix F3 cells `m_addpre_pbit{,d}_none_none_rypost` (theta
roots).

### Proposed disposition (NOT mine to decide — it touches a Rule-13 core fence on LANDED main)
Two directions, both needing their own red-green + a lens:
(a) teach the commit's stability conjunct the difference between a prior writer and a later reader for a
`ControlOwnedRails` + `cqrt_alloc_`-produced `P` (the same two-part test clause (ii-b) already uses),
leaning on the existing (1b) `PreLoopCommittedInPlaceOps` tripwire, which turns a stale answer into a
LOUD decline rather than a wrong unitary; or (b) leave the commit alone and let clause (ii)'s peel cross
an op that `classifyInPlaceReassignment` accepts, asked by that ONE spelling.
Pinning: one lit fixture per merge kind + the missing loop-twin-matrix cells (merge-out-rail x F3).

## F-I2-2 — Q1, THE INCREMENT'S OWN REVIEWER FLAG: the derived-base asymmetry is REAL, and on this evidence the value diamond's ACCEPT is SOUND; the 4.4 refusal is a SEEDING ARTIFACT
**Grade: CLEAR (with one DOC item).**

REPRODUCED, exactly as the rebase agent measured: `q1_derived` (a pre-region chained `p = cq_theta(p,0.9)`
before a 6-op value arm) ACCEPTS on all three binaries (subj 24 / inc1 29 / orac 29 lines) while its
pre-hoisted select twin `q1_derived_twin` DECLINES `cq controlled lowering: control flow under quantum
control` on all three. `q1_plain` / `q1_plain_twin` (no chaining) both accept everywhere, and the twin is
23 lines = the subject's diamond. So the class survives Inc 1 with `cq_theta` as the derivation.

**WHICH gate, and why it is an artifact.** Reading `SelectClassify.cpp`, the refusal is gate 5's
`hasCoherentDownstreamUse`, and the flagged rotation is the base's OWN producing theta. `rotationAncestry(Op)`
is seeded at `Op` and only walks when `Op` **is itself** a rotation call; the select's operand here is the
CHAIN RESULT, so `Ancestry = {chain result}` and the exemption is empty, while the lineage-wide seeding
(added by the kjd1 clearance) reaches the base's ancestor `%2` whose rotation user `%3 = theta(%2,.9)` is
then "off-ancestry". The gate's own comment says the exemption exists to keep
`select(c, theta(theta(q)), x)` — MEASURED, that shape does accept; what does not is the same base one
arithmetic hop away.

**The genuine hazard the seeding was built for is caught on the DIAMOND path.** The kjd1 fork shape
(a SUPERSEDED record: `int a = p; int p1 = cq_theta(p,0.9); if (c) a = R(a);`) DECLINES
`cq opcode lowering: operand predates a non-diagonal gate` on **all three binaries**, in all three
orderings I could build (`q1f_fork_diamond`, `q1f_fork_twin`, `q1f_fork_after`) — the pass-wide
`declineStaleRecordOps` is the backstop the `br`-value path has and the select-classifier duplicates
conservatively.

**The unitary argument, stated once.** After the flatten the region is
`|q,p,t=R(p),0> -> |q,p,t, c(q)?t:p>`: two controlled-XOR copies into a FRESH |0> ancilla, with the flag
minted and stripped by an exact inverse pair that touches nothing between. That is a PERMUTATION, hence
LINEAR, hence correct for an arbitrary input superposition — amplitudes and relative phases ride the
branch they belong to. Nothing in it reads the operands' rotation lineage, which is why the 4.4 gate is
documented as CONSERVATIVE and not as a proven miscompile. I could not construct a counterexample.

DOC item: gate 5's comment claims the ancestry exemption "keeps the sanctioned chained-prep accept"; it
does so only when the operand IS the rotation call. Worth saying, because the sentence is what a future
reader would use to decide the gate is exact.

## F-I2-3 — an EIGHTH fixture output moved under Inc 2 and was NOT re-derived; its header documents the RETIRED route in the present tense
**Grade: DOC-OR-FIXTURE-TRUTH (the F-V2-1 class, a sixth site).**

The 1673-fixture fxdiff sweep found **8 OUTDIFF** between INC-1-ONLY and the SUBJECT. Seven are in
`git diff --name-status a3c1513 HEAD -- ir-pass/test`. The eighth,
`ir-pass/test/lowering_switch_value_nonI32_cast.ll`, is not: its output changes from
`icmp_eq mint; alloc i64; cswap; add_i64_hl; cswap; ... copy_i64; cswap; add_unc; cswap; cswap; free`
to `alloc i64; copy_i64 (preload); add_i64_hl; xor_i64 (delta); add_unc; free; icmp mint;
copy_i64_controlled; ...`, and its header still says *"The value arms lower (**routed** cqrt_copy_i64 +
**reverse-play**)"*. Its three directives (`CHECK: cq_template_trunc_i64_to_i32`, two `CHECK-NOT`) are
about the bd p119.8 width recording and are blind to the mechanism, so it stayed green through the
rewrite. The p119.8 property itself still holds (the trunc lowers), so this is prose + coverage, not
behaviour.

Fix: rewrite the header to the preload + XOR-delta recipe (the `control_swap_switch_value.ll` header is
already correct and reusable), and either re-derive its CHECKs or say in the file why it deliberately
pins only the cast.

## F-I2-4 — post-Inc-1 `isPhiCall` is DEAD, so `SelectClassify` gate 5's PHASE half and gate 6's alias closure have NO SUBJECT, and both still document a register `cq_phi`
**Grade: DOC / latent (an Inc-1 LANDED consequence; Inc 2 makes the emitter reachable through a second
door, which is why it belongs in this round).**

`SelectClassify.cpp:67 bool isPhiCall(const Value *V) { return isCallToPrefix(V, "cq_phi_"); }` — and the
shipped intrinsic is `@cq_phi` with NO suffix. So `operandCarriesPhase` can never return true, and
`operandsAlias` degenerates to `A == B` (its `diagonalAliasHit` walk, `ArmClassify.cpp:275`, follows only
`isPhiCall` arg-0 chains). SEVEN identical definitions of the predicate exist across the pass, in seven files
(MEASURED: `grep -rn 'bool isPhiCall' ir-pass/src` -> 7 lines, 7 files).

No live hazard found: the `cq_theta`-shaped alias `int t = cq_theta(q,0.9); p = (q>5) ? t : q;` — which
post-lowering RAUWs both operands to ONE handle — DECLINES `condition predates a non-diagonal gate` on
all three binaries, at gate **2c**, not gate 6. But two Rule-13-cleared fences are now vacuous, their
comments describe an operand that cannot exist, and gate 5's WI-3 dephasing paragraph is the load-bearing
justification a future widening would be argued against.

## F-I2-5 — a KICKBACK-PHASED register copied through `cqrt_copy_<W>_controlled` is SOUND
**Grade: CLEAR.**

`q1k_disjoint_phase_then_value.c` (`if (q==5) cq_phi(PI); if (q>3) p = R(p);`) ACCEPTS: subj 27 lines,
inc1 32; the emitted stream is the kickback quadruple (`icmp_eq mint; rz_i1(f,PI); icmp_eq_unc; free`)
followed by the merge, and it is **BYTE-IDENTICAL to its pre-hoisted select twin on the subject**. The
reverse order also accepts (27/32) with the flag minted off the MERGE OUT rail (`icmp_eq(h5,5)`), which
is the correct register; its twin differs only in gate ORDER and that ordering is `clang -O1`'s (measured
in the stage-1 IR: the twin sinks the chain past the phase block), not the pass's.

Physics: the kickback leaves `q` in `sum_x a_x e^{i*theta*[c(x)]}|x>` — relative phases in the
COMPUTATIONAL basis. The merge is a permutation into a fresh |0> ancilla, so it is linear and the phases
ride their branches; a basis copy loses a phase only if the phase is *between* branches with the SAME
label, which a per-branch kickback never produces. Nothing measured contradicts this.

## F-I2-6 — the brief's compound-condition byte-identity item has no subject
**Grade: NOTE.** `if (q>3 && r<12) {6-op chain}` and its `?:` twin BOTH decline `control flow` on subj and
inc1 (`-O1` short-circuits `&&` into two branches, which the value path refuses). So `CondTreeEmit` is
NOT shared with the value merge today, and the byte-identity comparison the brief asks for cannot be run.

## F-I2-7 — the OPPOSITE asymmetry: a value register derived from the condition register declines on the diamond path and ACCEPTS through the select front door
**Grade: OVER-DECLINE (pre-existing, identical on ALL THREE binaries — filed, not Inc 2's).**
`q1e_ent.c` (`int p = q + 11; if (q>3) p = R(p);`) DECLINES `cq controlled lowering: non-routable value
multiplexer under quantum control` on subj, inc1 AND orac, while `q1e_ent_twin.c` (the pre-hoisted select)
ACCEPTS 22 lines on all three. Worth recording beside the reviewer flag, because the two asymmetries point
in opposite directions and only one of them is written down.

## F-I2-8 — Q2, the rebase itself: CLEAR
0 RCDIFF / 0 DIAGDIFF over 1673 common fixtures; 8 OUTDIFF (7 re-derived + F-I2-3). ZERO value-path
`cqrt_cswap`; `emitRoute` has ONE call site (`AbortParkEmit.cpp:396`). `#cqrt_rz_i1 ==
#!cq.branchphase` per fixture, 263 = 263, and 0 of 135 marked fixtures carries a mark off an
`cqrt_rz_i1` call; all 16 value/switch fixtures have `bp=0`. Four twin gates PASS by hand; 11 slices
reproduce their goldens byte-for-byte at STRICT 2b rc=0; injection matrix 15/15 clean, 0 NOT CAUGHT;
red-green of the 12 subject-only fixtures against INC-1-ONLY holds (with the two i128/qq declines
discriminating by STRING, not by rc).

## F-I2-9 — §1.11 item 2 (the `ArithLowering` G6/G7 weak tripwire) under the C-1 `InPlaceRailOps` writers: CLEAR
`commitOutOfLoopInPlaceOps` is a NEW writer of `taint.InPlaceRailOps` and it runs at the ROUND-2 site
(`collapseFlattenedLoopRails`, `CQLoweringPass.cpp:393`) i.e. AFTER `lowerControlRegions` has hoisted the
value arm's chain — so the seam is real. It cannot reach a chain link: the commit walks BACKWARD from a
loop CANDIDATE through `peelInPlaceStep`, and a hoisted chain link is only ever on the peel path of the
chain FINAL, whose sole user is a void `cqrt_copy_<W>_controlled` in the pred and therefore never a
candidate; and its own `P->hasOneUse()` conjunct would refuse anyway, since the base `p` always has >= 2
users in every shipped accept shape. MEASURED with the hardest case I could build — an ALL-dtzb 6-link
chain (`q5g_alldtzb_flat.c`): the head still emits OUT of place (`cq_template_add_i32_hl(h1,3) -> h2`) and
every later link converts in place on the FRESH rail h2, so the two copy sources are h2 and h1, DISTINCT.
Its rolled/unrolled pair is BYTE-IDENTICAL on both binaries.

## F-I2-10 — Q3/Q4 mixed shapes and the loop fence: CLEAR
Every mixed shape declines with the string the increment claims, identically on subj and inc1: a kickback
inside a value arm (`impure value arm`), a value arm inside a kickback nest (`mixed phase/value arm`), a
switch with value cases + a kickback case (`control flow`), a value diamond in a loop and a mixed loop
(`condition predates a non-diagonal gate`), a value-merge rail CARRIED in a loop (`operand predates a
non-diagonal gate`). Three sequential regions in both orders (`q3g_kvk`, `q3g_vkv`) preserve SOURCE ORDER
and base region 2 correctly on region 1's `%out`. Q4(a) — the per-bit kickback loop reading the VALUE
merge out-rail, with and without a carried register — is rolled==unrolled BYTE-IDENTICAL on both
binaries, all 8 (resp. 8) per-bit rails discharged, and the dirty chain final is never `_unc`'d, never
freed and never read.

---

# VERDICT

**FINDINGS — one LEAK (F-I2-1, rolled != unrolled, O(K), PRE-EXISTING on the LANDED `main` and NOT
introduced by Inc 2, which however adds a fourth producer of the rail it needs), plus one fixture-truth
and two doc items. Inc 2's own mechanism is CLEAR on everything this round could reach: the reviewer flag
resolves in the increment's favour with an argument and a backstop, the kickback/value interplay is sound
and byte-identical to its twin, every mixed shape declines, and the rebase is verified independently
(0 disposition changes over 1673 fixtures, 0 value-path cswaps, per-fixture `rz_i1`/`branchphase` parity,
four twin gates, 15/15 injection matrix).**

---

# HAND-BACK

## 1. What shipped
NOTHING — this is a READ-ONLY review. No checkout or worktree was written to; no commit, no push, no bd.
Everything I produced is under `$SP/progress/review_inc2_r2_work/`:
* `run.sh` — the 3-binary driver (stage 1 -> 2 -> 2b STRICT -> 3 -> 4), `subj`/`inc1`/`orac`.
* `fxdiff.sh`, `census.sh`, `inject.py` (copied from `$SP/progress/rebase_inc2_work/`).
* `p/` — 69 plain-C programs (incl. twins). `out/` — every stage-1/2/2b/3/4 artifact for every program x binary.
* Logs: `$SP/progress/review_inc2_r2_{fxdiff,census,inject}.log`.
Key reproducers: `p/q5sel_preadd_{rolled,unrolled}.c` (F-I2-1, 13 lines, no Inc-2 feature),
`p/q4b_preadd_{rolled,unrolled}.c` (F-I2-1 through Inc 2's own merge), `p/q7_k32_*.c` (O(K) scaling),
`p/q1_derived{,_twin}.c` + `p/q1f_fork_*.c` (F-I2-2), `p/q1k_disjoint_*.c` (F-I2-5),
`p/q5g_alldtzb_*.c` (F-I2-9).

## 2. What I ran (only what I ran)
* **79 distinct programs** (68 of my own — `p/` holds 69 files, one of which is a helper TU — plus the 11 committed Inc-2 slices), **170 program x binary runs**, through stage 1 -> 2 -> **STRICT 2b** -> 3 -> 4 on the SUBJECT and the
  INC-1-ONLY binaries, and on the ORACLE wherever the program compiles under the pre-3qlq header.
  STRICT `free_pairing_check.py` rc=0 on every accepting lowering (no `--allow-unproven` anywhere).
* **fxdiff sweep, 1673 common fixtures x 2 binaries** (rc + first control diagnostic + full stdout):
  0 RCDIFF, 0 DIAGDIFF, 8 OUTDIFF.
* **census sweep, all 1685 subject fixtures**: 828 accept / 857 decline; cswap, `cqrt_rz_i1` and
  `!cq.branchphase` counted per output.
* **135 marked fixtures re-lowered** and every `!cq.branchphase` line checked to sit on a
  `call void @cqrt_rz_i1(`.
* **Four twin gates + 11 Inc-2 slices re-derived BY HAND** through the full pipeline and `cmp`'d against
  the committed goldens (I did NOT run `ctest` in the subject build, per the brief).
* **Injection matrix** (`inject.py`, 15 accepts x 7 mutations): 15/15 controls clean, 0 NOT CAUGHT.
* **Red-green of the 12 subject-only fixtures** against the INC-1-ONLY binary.
* Source reading: `SelectClassify.cpp` (all six gates), `SwapRouteEmit.cpp` (`emitValueRegion`),
  `LoopLowering.cpp` (`commitOutOfLoopInPlaceOps`, `invariantRegisterRootsImpl` incl. (ii-b)/(iii-b),
  `collapseFlattenedLoopRails`, `markIfRailLocal`), `ArmClassify.cpp` (`diagonalAliasHit`,
  `rotationAncestry`), `CQLoweringPass.cpp` (the stage order).
* I did NOT run `lit`, `ctest`, `frontend-lit`, the runtime entries, or the loop-twin matrix.

## 3. Findings that are NOT mine to decide
### OWNER QUESTION 1 — F-I2-1's disposition
It is a rolled != unrolled divergence in a Rule-13 core fence on **LANDED `main`** (a3c1513), reachable
from 13 lines of plain C that contain no Inc-2 feature, invisible to STRICT stage 2b and to a 361/361
green `ctest`. Fixing it means changing `commitOutOfLoopInPlaceOps`'s stability conjunct or clause (ii)'s
peel — both Rule-13 core, both needing their own red-green and lens. Deciding whether that lands on the
Inc-2 branch, on `main` as its own commit, or as a new bd child is the orchestrator's/owner's, not mine.
Inc 2's own relationship to it is only that it ADDS a producer of the rail (`q4b` measures that).
### OWNER QUESTION 2 — F-I2-4's disposition
`isPhiCall` (7 identical definitions) tests a prefix no shipped call carries, so two Rule-13-cleared 4.4
gates are vacuous and their comments describe an operand that cannot exist. Retiring or re-spelling them
touches Inc-1 landed code; whether that is 3qlq work, an OQ, or a follow-on is not mine.
### Standing, unchanged
Inc 2's own three OQs (Q+Q *condition* capability; the run-time classical SHIFT AMOUNT; the
`value-arm swap-route` string naming a retired mechanism), OQ-22 (the F-V1-1 HandleWidth widening,
KEPT+PINNED and still red-green post-rebase), OQ-23 (V2's basis-state evaluator), bd 3qlq.8 (the PHASE
half of the i128 Rule-1 gap), and Q-R1-1 (the hoisted loop-invariant TEMPLATE rail, which `q5v_mul`
re-measures).

## 4. What is left
* F-I2-1: a fix + its red-green (one lit fixture per merge kind and the missing loop-twin-matrix cells,
  merge-out-rail root x the F3 preheader axis), then a lens.
* F-I2-3: the `lowering_switch_value_nonI32_cast.ll` header (and, if wanted, its CHECKs).
* F-I2-2's DOC item (gate 5's ancestry-exemption sentence) and F-I2-6/F-I2-7 as records.
* A round 3 is warranted on the C-1 machinery specifically, not on Inc 2's emitter: this round's only
  LEAK came from the ROOT-SET widening, and the file's own comment predicted the shape of the miss.
