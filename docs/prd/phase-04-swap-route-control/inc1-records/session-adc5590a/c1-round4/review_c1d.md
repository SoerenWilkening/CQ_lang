# review_c1d — independent Rule-13 lens on the FOURTH C-1 round (the `hasOneUse` retirement under the tripwire)

Agent `review_c1d`. **READ-ONLY on every checkout and worktree**; all writes under
`$SP/progress/review_c1d_work/` and this file. No commit, no push, no bd.

## Binaries — every one named, every one verified before use

| name | tree | check |
|---|---|---|
| SUBJECT `fix` | `$SP/wt/c1d` @ **59f6a95** | `git status --porcelain` EMPTY; `find ir-pass/{src,include,tools} -newer build/ir-pass/cq-opt` → **EMPTY** (build current) |
| **PRE-FIX** `prefix` | `$SP/wt/fix-c1` @ c17c466 — **tree-identical to a3c1513** (`git rev-parse HEAD^{tree}` = `56ee2bb…` = `a3c1513^{tree}`) | build current (0 newer files); tripwire string present (1) |
| FIX-2 | `$SP/progress/fix_c1c_work/*.fix2` (638334c) | tripwire string **absent** (0) |
| **M2 — my own mutant**: the SUBJECT with the (1b) tripwire re-ask DELETED | `$W/mut_m2` (`git archive HEAD` of the subject + the 13-line block removed), configured + built by me | `strings … \| grep -c 'pre-loop in-place op no longer provable'` → **0** |
| LANDED `main` | `/Users/sorenwilkening/Desktop/CQ_lang` | **NO LONGER a3c1513 — see F-C1D-1** |

Harness `$W/{run.sh,cnt.sh,rg.sh,popsweep3.sh,popdiff2.sh,srchash.py}` (a copy of the session's,
re-pointed at my own `out/`; `bash -c` everywhere — `zsh` does not word-split, the methodology
trap `review_c1c` recorded). Controlled clean + known-bad before any conclusion:
`q5sel_preadd_{rolled,unrolled}` reproduces the finding on PRE-FIX (4/0 44 vs 4/4 52, `cmp`
DIVERGE 8) and is byte-identical on the SUBJECT.

---

# THE THREE CLAIMS THE ORCHESTRATOR ASKED ME TO ATTACK — all three hold

### (a) “`main` ALREADY declines the whole F-C1C-1 family with the tripwire string, so no new decline appears” — **VERIFIED**

Six programs, each run on PRE-FIX / SUBJECT / FIX-2:

| program | FIX-2 (no tripwire) | PRE-FIX a3c1513 | SUBJECT |
|---|---|---|---|
| `c1c_v3_chain_midmember_measured` | ACCEPT 40 | **DECLINE** `cq loop lowering: pre-loop in-place op no longer provable at lowering` | same DECLINE |
| `c1c_v4_chain_two_loops` | ACCEPT 72 | DECLINE (same string) | same |
| `c1c_v5_chain_later_theta` | ACCEPT 40 | DECLINE | same |
| `c1c_v6_chain_xor_stem` | ACCEPT 39 | DECLINE | same |
| `c1c_v7_chain_prerecord_ret` | ACCEPT 32 | DECLINE | same |
| `y1_preadd_chained_prerecord` | ACCEPT 39 | DECLINE | same |
| `c1c_v2` / `y2` / `y3` (controls) | ACCEPT | ACCEPT | ACCEPT, **trace byte-identical** |

and over my whole 615-program population: **0 ACCEPT→DECLINE, 0 DECLINE→ACCEPT, 0 decline
strings changed.** No new decline exists anywhere I could reach.

### (b) “`m11d` is refused by the M-C fence (G7 arm (e)) and is NOT bought back” — **VERIFIED, by a route that needs no instrumentation**

* On the SUBJECT the conjunct **does not exist**, and `c2_m11d_two_loops_no_preadd` is still not
  committed: rolled **6/3 (62 lines)** vs twin **6/6 (68)**, trace **byte-identical** to PRE-FIX.
  Therefore the refusal is `classifyInPlaceReassignment`, not `hasOneUse`. That is the claim.
* DISCRIMINATING CONTROL I wrote: `e1_m11d_loop1_reads_r` — the same two-loop program with loop 1
  reading `r` instead of `q`, so `P` has ONE use. **6/6 = 6/6 on BOTH binaries.** The second use of
  `P` is the whole difference; nothing else about the shape matters.
* ARM ATTRIBUTION corroborated from the emitted IR: `P`'s other user at the commit's program point
  is loop 1's still-unlowered tainted `and i32 %q, %5` (I read it in the pre-lowering module), which
  arm (e) refuses on sight. And the SAME op **is** converted in place later —
  `cqrt_addc_i32(h0, 3)` is in the trace, emitted by the M-C **LATE** round, whose plan sees loop 1's
  `%h_op3` already `_unc`'d **and** `cqrt_free`d before the site, i.e. arm **(d)**. Arm (e) before
  the discharge, arm (d) after: exactly the fix agent's reading.
* The OWNER QUESTION's refusal to widen arm (e) is right, and I would add one reason: the LATE round
  already performs that conversion soundly *after* the discharge exists, so widening the commit buys
  the body marking at the price of predicting a later stage — the class that has failed eight times.

### (c) “A THIRD population class exists (P's other use = a preceding region's own compare)” — **VERIFIED, and it is wider than reported**

| program | PRE-FIX | SUBJECT |
|---|---|---|
| `g1_region_then_preadd_{rolled,unrolled}` (theta root, preceding region, NO merge) | 3/0 (36) vs 3/3 (42) — **DIVERGE 6** | **3/3 = 3/3, `cmp` IDENTICAL 42 = 42** |
| `c2_m04_onward_then_preadd` (+ `tu_extf.c`, the 6.5 original) | 3/0 (43) | **3/3 (49)** |
| **`n4_merge_prior_region_preadd`** (MINE — a preceding region on a **merge out-rail**, i.e. arms (b)/(c)/(d) at once) | 4/0 (48) vs 4/4 (56) DIVERGE | **IDENTICAL 56 = 56** |
| **`m5_seq_regions_preadd`** (MINE — a merge whose scrutinee is another merge) | 4/0 (52) vs 4/4 (60) | **IDENTICAL 60 = 60** |
| **`m6_region_then_preadd_diffusion`** (MINE — the third class **with a post-loop diffusion**, which is what makes the leak a wrong unitary rather than a leak) | 3/0 (36) vs 3/3 (42) | **IDENTICAL 42 = 42** |

The record's own generalisation (“the population is every `P` whose other users are all SETTLED
PRIOR CONSUMERS”) is the right one; the three arms (b), (c), (d) are all reachable from plain C.

---

# THE ONE QUESTION: with `hasOneUse` gone, is the tripwire the ONLY net, and does it hold everywhere the conjunct used to?

### 1. The safety claim, re-measured on a mutant I built myself

I rebuilt the SUBJECT with the (1b) tripwire block deleted (**M2**). On M2:
* all six F-C1C-1 programs **ACCEPT**, and `y1` reproduces the round-2 wrong unitary **verbatim** —
  `cqrt_addc_i32(h0, 7)`, measures **`h0`, `h1`, `h0`**, 39 lines — and its trace is **byte-identical
  to FIX-2's**, i.e. the widening did not change the defect, only who catches it;
* the SUBJECT **DECLINES** all six.

So the net is the tripwire, and `hasOneUse` never was it (it is *true* for `y1`). **Independently
confirmed, not taken from the record.**

### 2. Does the widening ENLARGE the class the tripwire must catch? — measured NO

M2 (widened commit, no tripwire) vs SUBJECT over my **41-program** probe battery: **41 SAME,
0 MOVED** (status + decline message + trace byte-diff). Every op the widening newly commits is
*stable* between `lowerLoops` and `lowerOps`; the tripwire's live customer set is exactly the
F-C1C-1 class it already had.

### 3. Re-attacking F-C1C-1's class with the conjunct gone — 30+ new spellings, no hole

**“`P` has one SSA use, the WIRE has more after `lowerRotations`”** (the class the conjunct was
reaching for): the theta-chain members (v3–v7, y1) DECLINE; a chain through an in-place `add`
(`c1c_v2`) is byte-unchanged; a chain measured / returned / rotated / read by a second loop /
read by a later region's condition — every one **correctly refused** and **byte-unchanged** on both
binaries (`k1` measure-pre, `k2` ret-pre, `k4` theta-pre, `k5` second-loop-pre, `k6` chain-measured,
`n1`, `n3`, `s12` record-before-preadd): **0 in-place `cqrt_addc`/`cqrt_xorc` in any of them**, on
both binaries. G6 is doing the work and the widening does not touch it.

**The mirror — `P` with MANY SSA uses that are all WRITERS/settled** (the newly-committed set).
Every one is `rolled == unrolled BYTE-IDENTICAL` on the SUBJECT and DIVERGES on PRE-FIX:
`k3` (4.4 merge, the flagship, 44→52), `k7` (**two invariant registers**, 75→91),
`m1` (**MIXED loop: a carried rail AND an invariant merge rail with a preadd**, 51→59),
`m3`/`m6` (**post-loop diffusion**), `m4` (**K = 32: 32/0 → 32/32**, the O(K) claim),
`m5` (sequential regions), `n2` (**two preheader ops in sequence**), `n4` (prior region on the
merge rail), `n7` (**the `sub` stem**), `w1` (**i64**), `t2` (a QROM read of the merged register
after the loop), `t4` (a specialised call after the loop), `b4z` (the Phase-4 **value-arm route**
out-rail, from the Inc-2 corpus). Refused, byte-unchanged, and correctly so:
`n8` (`7 - m`, G2), `m2` (two in-place-shaped ops on one rail), `t1`/`t3` (a QROM read / a call
**before** the preadd — arm (d) needs the rail discharged, arm (e) refuses a call it cannot vouch
for), `w2` (`short` — the disclosed OQ-C2-2 `sext` class, still 4/0 on both).

**Clone (the `inBennettClone` question).** Not reachable, for three independent reasons I checked
one by one: cloning runs AFTER `lowerLoops`, so no marked instruction is ever inside a clone; the
clone's copies are fresh `Instruction*`; and `Specialization.cpp` contains **zero** references to
either set (`grep -c` → 0), so the module-wide `lowerOps(M, wd, cloneTaint, /*inBennettClone=*/true)`
runs with both sets EMPTY and cannot route anything to `rewriteInPlaceValueRail`. Empirically a
per-bit loop cannot be inside a clone at all: `t6_preadd_in_real_clone` declines
`cq specialization: callee contains a quantum primitive (cq_*)` on both binaries. The guard is
defensive and vacuous.

**Commit-then-rollback.** `u1_rollback_merge_preadd_plus_template` (a committable merge preadd
BESIDE a hoisted-template candidate that fails clause (ii), so the whole extension rolls back) and
`u2` (the theta-root twin): **byte-identical to PRE-FIX**, same number of in-place `cqrt_addc`
calls (1/1 and 0/0). The rollback erases both sets in lockstep; no spurious tripwire decline, no
disposition change.

**The first-DS_Error question.** Measured: on a tripwire decline `cq-opt` exits **rc=1** with
**0 bytes of stdout** and **no `-o` file created**. A `DiagnosticInfoUnsupported` anywhere means no
module is emitted at all, so nothing an accept-path mutation already did can escape. The diagnostic
string is mirrored character-for-character between `OpcodeLowering.cpp:81` and
`control_phase_kickback_reject_preloop_commit_stale.ll:57`, and that fixture is **RED** on FIX-2
(`OPT_RC=0`) and GREEN on PRE-FIX and SUBJECT.

### 4. The 8h7d.5 question, asked of the widening — the closure table reproduces, with two refinements

`grep -rn 'InPlaceRailOps|PreLoopCommittedInPlaceOps' ir-pass/{src,include}` — **code** reads live in
exactly four files: `LoopLowering.cpp` (9), `OpcodeLowering.cpp` (3), `ArithLowering.cpp` (1),
`TaintPropagation.h` (2, the declarations). `ArmClassify.cpp:327` and `WireWalk.cpp:457` are
**prose**. So the only between-stage consumers are `LoopLowering`'s own round-2 machinery
(round 1's commit at `CQLoweringPass.cpp:393` is visible to round 2's at `TaintPropagation.cpp:1649`).
Each moves in the safe direction:
* `collectRailGates` (`== InPlace`) — the gate set and the RailValues set only GROW ⇒ more staleness
  declines. Its SKIP set is the CHAIN, and the chain is built with `peelInPlaceStep(…,
  AsLowered=false)` — the SHAPE reading, which crosses a dtzb-shaped BO whether or not it is
  committed — so the widening **cannot shrink the skip set**. (That is the F-3 question the table
  does not ask; it is the one I most expected to find a hole in, and it is closed by the default
  argument of the peel.) Verified by reading all 20 `peelInPlace*` call sites: only **2** pass
  `AsLowered=true` (`:3176` clause (ii), `:3374` `markIfRailLocal::onRail`).
* the Rule-8 FAN-OUT guard — see F-C1D-3.
* the (1b) tripwire — more ops re-asked ⇒ more possible declines; **0 measured over 615 programs**.

### 5. The population, re-run

**615 programs** — the union of every `p/`/`p2/`/`p3/` of session `adc5590a` including the two
Inc-2 dirs the fix agent's 485 did not have (`clearance_inc2_work`, `fix_inc2_r2_work`) plus my own
~35 — each run through the full pipeline on PRE-FIX and SUBJECT, compared by class, by decline
message and by **byte-diff of the trace**:

**UNCHANGED = 595 · MOVED = 20 · ACCEPT→ACCEPT 365 · DECLINE→DECLINE 211 · ACCEPT→DECLINE 0 ·
DECLINE→ACCEPT 0 · decline-message changes 0.**

All 20 movers named, and every one gains `_unc` + `cqrt_free` pairs (none loses one):
`q5sel_preadd_rolled` 4/0→4/4 · `q4b_preadd_rolled` 4/0→4/4 · `q7_k32_rolled` 32/0→32/32 ·
`q5v_xor` 4/0→4/4 · `g1_region_then_preadd_rolled` 3/0→3/3 · **`b4z_value_then_postadd_loop_rolled`
4/0→4/4 (a NINTH member, from the Inc-2 corpus the 485-sweep did not include; its twin becomes
`cmp`-IDENTICAL at 65 lines)** · the 2 new matrix cells 2/0→2/2 · my 11 (`k3 k7 m1 m3 m4 m5 m6 n2 n4
n5 n7`) · and `c1c_a1_constexpr_imm`, **confirmed the artefact**: its lowered IR differs only in
`ModuleID` and its trace only in a `ptrtoint (@g_tab+12)` load address between two separately linked
binaries.

Q-R1-1 controls still leak, byte-identically on both binaries: `d2_hoisted_sext` 3/0,
`d3_hoisted_qq` 3/0, `n9_mixed_hoisted_template_leak` 3/0, `x2_preadd_keep` 3/0,
`z21_preadd_volatile_imm` 3/0, `r5_short_inv` 3/0.

### 6. Record truth — every count and claim reproduced by command

| claim | my measurement |
|---|---|
| fixtures 1673 → **1675** | `ls ir-pass/test/*.ll \| wc -l`: PRE-FIX 1673, SUBJECT 1675 ✓ |
| matrix rows 257 → **259**, quarantine **29** unchanged | `grep -c '^m_'`: 257 / 259; `quarantine.txt` **byte-identical**; both `*.register.txt` **byte-identical**; `comm` over the `^m_` rows: **0 pre-existing rows missing or changed**, exactly 2 new ✓ |
| “all **1144** pre-existing generated sources hash-identical” | **INDEPENDENTLY RE-DERIVED** (`$W/srchash.py` imports both `loop_twin_matrix.py` versions and SHA-256s every `sources()` output over both surfaces and both spellings): A=1144, B=1152, **0 missing, 0 changed, 8 new** ✓ |
| ctest 348 → **351**, `^e2e-` **341**, `^e2e-slice-` **310**, twin gates **21** | `ctest -N` on both builds ✓ |
| goldens 310 → **312** | `ls tests/e2e/*.expected.log \| wc -l` ✓ |
| the two new goldens “by the full pipeline, STRICT 2b” | **re-derived by me from the committed `.c`**: both **GOLDEN-MATCH**, `opt` rc=0, 2b `0 violation(s), 0 unproven`, and the two goldens are **byte-identical to each other** (52 = 52) — on PRE-FIX the rolled slice is **44** lines vs the twin's 52 ✓ |
| red-green, both new lit accepts | PRE-FIX `OPT_RC=0 CHECK=1 UCNT=1 FCNT=1` (**RED**, others 0); SUBJECT **all 8 prefixes 0** ✓ |
| round-3 tripwire fixture RED without the tripwire | FIX-2 `OPT_RC=0`, FileCheck fails; PRE-FIX and SUBJECT rc=1 with the exact string ✓ |
| PRD §0 E2 residual list true of the binary | (a) `z21` volatile-imm 3/0 unchanged · (b) the chained-theta class declines · (i) hoisted TEMPLATE rails (`d2`/`d3`/`n9`) leak unchanged · the `short` member `r5_short_inv` 3/0 unchanged (and my `w2_merge_preadd_i16` reproduces it on the merge axis) · (ii) untested by me · `m11d` stays on the list, re-attributed ✓ |
| full `ctest -j6` on the subject | **READ, not run** (`$SP/progress/orch_full_ctest_c1d.log`): **100% tests passed, 0 failed out of 351, 374.32 s, EXIT=0** |
| code shape | `git diff main HEAD -- ir-pass/src/LoopLowering.cpp`: ONE non-comment change (`if (!P \|\| !P->hasOneUse()) return;` → `if (!P) return;`); `git diff --stat main HEAD -- runtime tools/opcode_table.yaml include` **EMPTY** (owner D3) ✓ |

---

# FINDINGS

## F-C1D-1 — `DOC`, but act on it: **the PRE-FIX baseline named in the brief has MOVED, and the F-I2-1 defect is LIVE on the landed `main` today**

`/Users/sorenwilkening/Desktop/CQ_lang` is no longer a3c1513. It is **258d974** — *“feat(control):
3qlq Inc 2 — VALUE arms by the controlled-copy merge”* — with `build/ir-pass/cq-opt` rebuilt at
**07:45**, i.e. **while this review was running**. 366 of my first 615 `main` runs landed on the new
binary and were discarded; everything above uses `$SP/wt/fix-c1`, whose TREE HASH equals
`a3c1513^{tree}` and whose behaviour I re-validated against the finding (q5sel 4/0 44, g1 3/0 36,
y1 declines, m11d 6/3) before using it.

**What that measurement is worth**: it makes the fix agent's RECORD ITEM (*“Inc 2 adds a FOURTH
producer and the fix for it is ANALYTIC until the rebase”*) half-measurable now. On the **landed
`main` 258d974**:

| program | landed `main` rolled | its hand-unrolled twin | verdict |
|---|---|---|---|
| `q4b_preadd_{rolled,unrolled}` (now the **Inc-2 controlled-copy value merge**) | **4/0, 52 lines** | 4/4, 60 | **DIVERGE 8** |
| `q5sel_preadd_*` (4.4 select merge) | 4/0, 44 | 4/4, 52 | DIVERGE 8 |
| `g1_region_then_preadd_*` (third class) | 3/0, 36 | 3/3, 42 | DIVERGE 6 |
| `k3_merge_preadd_plain` (mine) | 4/0, 44 | 4/4, 52 | DIVERGE 8 |

So the O(K) which-path leak this round fixes is **on `main` right now**, in D4's own designated
idiom, at `opt` exit 0 / verify-clean / STRICT 2b `0 violation(s)`. The `c1-round4` rebase is not
housekeeping. Rebase surface, measured: `git diff --name-only a3c1513 258d974` ∩ `… a3c1513 HEAD`
= **`CLAUDE.md`, `ROADMAP.md`, `retire-swap-route-PRD.md`, `tests/e2e/CMakeLists.txt`** only —
`ir-pass/src/LoopLowering.cpp`, `tools/loop_twin_matrix.{py,expected.txt}` and every new golden are
untouched by Inc 2, so the CODE change applies clean and only prose/registration conflict.

## F-C1D-2 — `ITEM` (a rebase obligation the round could not have discharged, not a defect)

Inc 2's diff touches **`ir-pass/src/ArithLowering.cpp`** — the one fence round 4 now leans on
entirely. The change is **comment-only** (I read the whole diff), but what it adds is
**“CONSUMER 2”**: the Inc-2 value-arm controlled-copy merge is sound *only because* the G6/G7 pair
always refuses M-C on a chain HEAD, since `Q` always has a second user. Before this round,
`hasOneUse` was a **second, independent refusal on the COMMIT path** for anything whose parent has
≥2 users; it is now gone, so the commit path's protection for Consumer 2 is exactly G6/G7 — the
same as M-C's, no weaker, but no longer doubled.

I checked that the commit **cannot** reach an Inc-2 chain head: the head is a *user* of `Q`, never
an ancestor on the peel chain from a loop-invariant candidate, and a merge `%out`'s peel stops at
its own `cqrt_alloc` (not a `GateCalls` member). So the property holds by construction. But it is
**unpinned on the rebased tree**, and `ArithLowering.cpp`'s own new comment says to re-derive
`control_swap_value_ifelse_head_out_of_place.ll` before touching anything in this area. **The rebase
should re-run that fixture and the value-arm twin gates, and re-measure `q4b_preadd_*` there** (the
fix agent's own open item).

## F-C1D-3 — `ITEM`, doc precision on notes §3.14's 8h7d.5 closure table (two rows right for reasons one clause short, one row missing)

1. **The fan-out row** says “`Unproven` and `InPlace` are both `> OutOfPlace`, so the count is
   arithmetically unchanged”. That is complete only because a committed op can never have been
   `OutOfPlace`: `railValueConsumerDisposition` returns `OutOfPlace` exactly when
   `blockCanRepeat(BO->getParent())`, and `inPlaceFenceHolds`' **G5** refuses precisely that, so the
   commit cannot mark a repeatable-block op. Without G5 the widening *would* add an `InPlaceUser`
   and could mint a new `kMsgRailFanout` decline. (Measured: 0 fan-out flips over 615 programs;
   `m2_fanout_two_ops_same_rail` byte-unchanged.)
2. **The `WireWalk` row** is right, but not for the reason given (“the stage runs before
   `lowerLoops`, so the set is empty”) — which would be **false** for `declineLiftedStaleRecordOps`,
   the *second* `declineStaleRecordOps` call, at `CQLoweringPass.cpp:522`, i.e. AFTER the commit.
   The row survives for a stronger reason: **`WireWalk.cpp` has no code read of either set at all**
   (the `:457` hit is prose), so no caller of it can see a commitment.
3. **The row the table does not have** is the F-3 question itself: *when you widen the gate set, what
   OTHER set was computed over the same closure?* The answer is `staleRailRecordRead`'s **SKIP** set,
   which is the CHAIN, built with `peelInPlaceStep(…, AsLowered=false)` — the shape reading, which
   crosses a dtzb-shaped BO regardless of membership. So the widening grows the gate set and the
   record set (both decline-ward) and **cannot shrink the skip set**. Worth writing down, because it
   is exactly the omission that cost the 8h7d.5 epic a round.

## F-C1D-4 — `ITEM`, coverage (family-wide convention, pre-existing, covered one layer down)

The two new lit accepts do not pin a `cqrt_ry` COUNT, so an injected uncontrolled
`cqrt_ry_i32(%out, θ)` after the flag's free is caught by **0 of 8** prefixes. I ran an independent
11-injection battery on both new fixtures; the other ten are all caught by the right prefix
(drop `and_hl_unc` → CHECK+UCNT · extra `addc` → PCNT · extra `cswap` → NOROUTE · drop a free →
CHECK+FCNT · extra free → FCNT · drop `!cq.branchphase` → CHECK+MDCNT · `rz_i1`→`rz_i32` →
CHECK+ACNT+NOROUTE · extra `rz_i1` → CHECK+ACNT · extra `cqrt_x` → CHECK+XCNT · a tensored
`cqrt_rz_i32` on the rail → NOROUTE). The Ry gap is the **family convention** — 0 of 25
`control_phase_kickback_*` fixtures pin an Ry count, 1 of 1675 in the whole corpus — and the
capability's two e2e goldens pin their 3 `cqrt_ry_i32` lines byte-exactly, so the class is caught
at the layer that can see it. Recorded only because the fix agent's own 16-mutation injection
matrix has no `extra_ry` row and reports “0 MISSED”.

## Observation, NOT a finding — `s11_stale_record_on_merge_with_preadd`
`int mark = m; m = cq_theta(m,0.2); measure(mark); measure(m);` emits `ry(h4,.2); measure(h4);
measure(h4)` — the pre- and post-rotation names collapse onto one register. It is **byte-identical
on PRE-FIX and SUBJECT**, its rolled and unrolled spellings are **byte-identical on the SUBJECT**,
and the no-region/no-loop base case (`s11n`) behaves the same on both. That is the documented linear
rule of the register surface, not a defect of this round or of this path.

---

# WHAT I RAN

| gate | result |
|---|---|
| harness control (clean + known-bad) on 4 binaries | F-I2-1 reproduces on PRE-FIX (4/0 44 vs 4/4 52), byte-identical on SUBJECT |
| F-C1C-1 family × {FIX-2, PRE-FIX, SUBJECT} | 6 DECLINE on both shipped binaries, 6 ACCEPT-and-wrong on FIX-2, 3 controls identical |
| **M2 mutant built by me** (subject − tripwire) | all 6 accept; `y1` = `h0,h1,h0`, 39 lines, **byte-identical to FIX-2** |
| M2 vs SUBJECT over my 41-program battery | **41 SAME, 0 MOVED** — the widening adds no tripwire customer |
| ~35 new probe spellings (`k*, m*, n*, s*, t*, u*, w*, e*`) | tabulated above; every capability case `cmp`-IDENTICAL to its twin, every refusal byte-unchanged |
| **population, PRE-FIX vs SUBJECT, 615 programs** (status + decline message + trace byte-diff) | **595 UNCHANGED / 20 MOVED**, all 20 named; **0 ACCEPT→DECLINE, 0 DECLINE→ACCEPT, 0 message changes** |
| the same corpus on the **landed `main` 258d974** | F-I2-1 still diverges there (F-C1D-1) |
| red-green, 2 new fixtures × 2 binaries × 8 prefixes | RED on PRE-FIX (CHECK/UCNT/FCNT), GREEN on SUBJECT |
| round-3 decline fixture × 3 binaries | RED on FIX-2 only |
| tripwire exit behaviour | rc=1, **0 stdout bytes**, no `-o` file |
| injection battery, 11 mutations × 2 new fixtures | 10/11 caught by the right prefix; the 11th is F-C1D-4 |
| goldens re-derived from source on the subject build | both **GOLDEN-MATCH**, STRICT 2b `0 violation(s), 0 unproven`, twin byte-identical |
| generated-source hashes, both matrix versions | 1144 pre-existing: **0 missing, 0 changed**, 8 new |
| counts (fixtures / matrix / quarantine / ctest / goldens) | all reproduce exactly |
| closure grep over both sets + all 20 `peelInPlace*` call sites | 4 code files, 2 `AsLowered=true` sites |
| full `ctest -j6` on the subject | **READ, not run**: 351/351, 0 failed, EXIT=0 |
| **NOT run** | any `ctest`/`lit` in `$SP/wt/c1d/build` (the orchestrator's run was live and is read above) · `cq-opt-equivalence-full` · the twin matrix (read from the orchestrator's log: `e2e-loop-twin-matrix` **Passed, 374.29 s**) · `frontend-lit` · the runtime entries · PRD E2 residual (ii) |

---

# VERDICT

**CLEAR-WITH-ITEMS**

The retirement is a **narrowing of a proxy onto the real predicate**, and I could not break it. The
conjunct guarded nothing `classifyInPlaceReassignment`'s G6/G7 pair does not — I re-derived that
with programs rather than accepting it — and every one of the ~35 new spellings I wrote is either
`rolled == unrolled` byte-identically (the capability) or byte-unchanged from PRE-FIX (the refusal).
The safety argument is a measurement I reproduced on a mutant I built: delete the tripwire and the
F-C1C-1 class miscompiles again, byte-identically to the round-2 binary. Over 615 programs there are
**0 class flips in either direction and 0 decline-message changes**, and every one of the 20 movers
gains discharges rather than losing them. Every record count reproduces, including the 1144
generated-source hashes, which I re-derived independently rather than checking.

The items are: **F-C1D-1** — the baseline moved and the defect is live on the landed `main`, so the
rebase is a correctness obligation, not housekeeping (and it is mechanical: Inc 2 touches none of
this round's code files); **F-C1D-2** — Inc 2's ArithLowering comment names a second consumer of the
G6/G7 pair whose second net (`hasOneUse` on the commit path) this round removed, sound today but
unpinned on the rebased tree; **F-C1D-3** — three doc-level refinements to the 8h7d.5 closure table,
one of them the F-3 row the table omits; **F-C1D-4** — the injection matrix has no `extra_ry` row.
None of them is a wrong unitary and none blocks landing.
