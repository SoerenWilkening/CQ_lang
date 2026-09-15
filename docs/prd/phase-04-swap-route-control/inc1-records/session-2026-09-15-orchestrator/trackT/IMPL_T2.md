# Track T — bd `test_C_libtooling-tu9q`: THE IN-LOOP PAIRING

Session 2026-09-15. Worktree `/Users/sorenwilkening/Desktop/CQ_T`, branch `inloop-pairing`,
based on `main` `74eabd2c`. ORACLE `cq-opt` `0e280fc62a91cec2…` (verified at session open and at
every use; never rebuilt).

---

## §0 — THE CLAIM, IN ONE PARAGRAPH

**The rolled form now emits the per-trip `_unc` + `cqrt_free` that the FLAT form already emitted,
for every loop whose invariant tainted reads are provably never given a discharge point.** bd
`tu9q`'s headline probe `s1_live_shift.c` goes from a LOUD DECLINE on the ORACLE to an ACCEPT whose
14-line trace is **BYTE-IDENTICAL** to its hand-unrolled twin's. Four programs that ACCEPTED-AND-LEAKED
on the ORACLE now discharge and match their twin's line count exactly (13=13, 20=20, 38=38, 48=48).
The positive control `s3_live_rootmint_region` is **UNMOVED** at 22 == 22.

**What is NOT built:** the half where the loop-invariant read is a hoisted **TEMPLATE** rail read as
DATA (`int p = y * 3;` — `s2_live_derived_region.c`, and bd `test_C_libtooling-1m5p`). It still
declines, deliberately, and §6 says exactly what it would take. **That is a Rule-17 report, not a
punt:** the remaining half needs a capability the whole-DAG spine does not have (a loop-EXIT recovery
point for a preheader-minted rail) and the real multiplicity test `Uncomputation.cpp:982-1000`
specifies — a second increment with its own Rule-13 budget, and one that would be a *wrong unitary*
if shipped without both halves. It is brought back rather than stubbed.

---

## §1 — WHAT LANDED (five changes, all in `ir-pass/`)

### (1) `markIfIterationLocal` returns `bool` — `LoopLowering.cpp`

`void` → `bool`, `true` iff it MARKED. The caller had no way to tell "marked" from "refused" without
re-deriving the predicate or counting `IterationLocalBlocks` members — a count that is ambiguous the
moment a nested loop's blocks are already present from an outer one. Read by exactly ONE caller, for
exactly ONE purpose (see (2)).

### (2) THE ROUND-1 ROOT-MINT ESCAPE — `lowerLoops`, `LoopLowering.cpp`

```
if (tryCaseA(...)) continue;
if (markIfIterationLocal(L, taint, LI)) continue;
SmallPtrSet<Value *, 4> Roots;
if (invariantRegisterRoots(L, taint, wd, DT, LI, GateCalls, Roots, nullptr) &&
    markIfRailLocal(L, taint, LI, GateCalls, Roots))
  recordRound1RailGrant(L, taint, Roots);
```

**This is Rule 14, not a new predicate.** `markIfRailLocal` already has the escape (`onRail` over a
`Roots` set) and `invariantRegisterRoots` already owns the proof that a root mint is sound to put in
that set. **Both were built for the ROUND-2 region path**, and `collapseFlattenedLoopRails` opens
`if (taint.InLoopFlattenedPreds.empty()) return;` — a map filled ONLY by an in-loop region flatten —
so for a loop with **no tainted control flow at all** neither ever ran. `CLAUDE.md` L2 verbatim: 3qlq
Inc 1 widened one of the two sibling clauses and left the other. This call site is that omission,
closed by CALLING the widened sibling.

**It is PROVABLY ADDITIVE, and the `markIfIterationLocal` call is asked FIRST rather than replaced.**
`invariantRegisterRoots` returns false on an empty `Cands` — the set of tainted values defined
outside `L` and read inside it — and `Cands` is built from the IDENTICAL quantifier
`markIfIterationLocal`'s refusing clause scans (`for BB in L->blocks(), for I in BB, for Op in
I.operands(): tainted && !L->contains(Op's block)`). So:

| case | before | after |
|---|---|---|
| `Cands` empty | `markIfIterationLocal` decides | unchanged — the new path is not reached |
| `Cands` non-empty, IRR true | `markIfIterationLocal` provably refuses (its operand clause) | `markIfRailLocal` asked |
| `Cands` non-empty, IRR false | `markIfIterationLocal` provably refuses | unchanged — it refuses again |

The set of loops whose marking CHANGES is therefore exactly: *refused by the operand clause, and
every outside-`L` tainted read is a proven root.* Nothing else can move.

**THE MULTIPLICITY PRICE IS PAID BY THE SAME ARGUMENT, NOT A NEW ONE.** `Uncomputation.cpp`'s §4/§2.9
pair asks each endpoint separately whether it repeats and never whether the two repeat EQUALLY, so a
recovered gate in the PREHEADER (once) with `At` in a marked body (K times) would emit **K adjoints
against ONE forward gate** — a wrong unitary. `invariantRegisterRootsImpl` clause (ii) admits ONLY a
root mint or a Phase-4 merge out-rail, and BOTH lower to `cqrt_alloc_<W>`, which
`ChainWalk::isInteriorTerminalHandle` clause (I1) excludes from the M-B interior partition OUTRIGHT —
so neither can ever BE that preheader gate.

### (3) `railLocalQualifies` EXTRACTED from `markIfRailLocal` — `LoopLowering.cpp`

The refusal half is now its own function, so the L1 re-ask asks the SAME clauses by **calling** it
(Rule 14 — the drbq Inc-3 (b′) defect is a SECOND SPELLING of a predicate the tree already owned).
`markIfRailLocal` is the marking half and returns `bool`. `!AnyLocal` stays OUTSIDE the refusal
predicate: a body with no iteration-local temp emits the SAME stream marked or unmarked, so reading
it as a refusal would decline correct programs — the distinction
`bodyHasSpineDischargeCandidate` already makes for `declineUnmarkedRolledIterLocal`, where
pretending otherwise cost four of them.

### (4) CLAUSE (ii-c) — THE MEASURE-OWNED INVARIANT RAIL — `invariantRegisterRootsImpl`

`-O1` **LICM hoists** a loop-invariant `y & 1` into the preheader, so the body of `w2k` / `w2h` /
`w2h3` reads a hoisted **TEMPLATE** rail, not the register — the `z_preheader_rail8` case that
function's own header records as refused — and refusing it took the discharge of the body's genuinely
iteration-local chain down with it.

`measureOwnedInvariantRail(V)` is true iff **every** user of `V` is a `cq_measure`. Such a rail is
owned by the measurement in BOTH spellings, and **two independent mechanisms say no `At` can ever be
placed for it** — both read in source, not assumed:

* `ChainWalk::isInteriorTerminalHandle` clause (I3) requires EVERY user to satisfy
  `isInteriorConsumer`, and a measure call is none of its three admitted shapes (an in-place gate, a
  template producer, a recorded flag strip) ⇒ never in the M-B INTERIOR partition;
* `FreePoint::computeFreePoint` returns `FreePointKind::Measured` the moment it sees a measure sink
  ⇒ no adjoint and no free from the WHOLE-DAG partition either.

So the preheader forward gate whose `At` lands in a K-times body is unbuildable with this spelling
too — by a DIFFERENT mechanism from the alloc-minted one, and stated separately for that reason.

⚠ **It is deliberately NOT `railIsInterior`** (the `declineDephasingUnmarkedLoopRails` helper), even
though the two agree on every program in the tree today. They ask different questions with different
SAFE DIRECTIONS: `railIsInterior` asks *"would the hand-unrolled twin discharge this rail?"* and
`continue`s past a non-`Instruction` user; this asks *"is this rail PROVABLY never given an `At`?"*,
where an unclassifiable user is an absence of proof and must REFUSE. Folding them would need a
direction parameter, which is how a shared predicate acquires a caller its argument does not reach
(`CLAUDE.md` L3's mirror, which cost a P1 on 2026-09-14). **RETIREMENT TRIGGER written at the
definition:** if `railIsInterior` grows a measure-independent clause, re-derive this one against it.

### (5) THE L1 RE-ASK — `taint.Round1RailGrants` + `declineRound2FalsifiedRailGrants`

`lowerLoops` runs at **ROUND-1 taint** (`CQLoweringPass.cpp:455` vs `repropagateControlMerges` at
`:571`), and **every clause of `railLocalQualifies` is a REFUSAL over tainted values** while round-2
taint is a strict SUPERSET. That is `CLAUDE.md` L1's **PREDICATE species** exactly, and its cure is
the pattern: RECORD at the site that asks, RE-ASK after the fixpoint, in BOTH entry points, decline
LOUDLY.

* **Record**: `TaintSet::Round1RailGrant { const BasicBlock *Header; SmallVector<WeakTrackingVH,2> Roots; }`.
  The header is a `BasicBlock *`, **never a `Loop *`** — `LoopInfo` owns its `Loop` objects and
  destroys them per function, the dangling defect that shipped a silent miscompile in
  `declineUnmarkedRolledIterLocal` (F-W1-1, 2026-09-14). The roots are `WeakTrackingVH`; a NULLED root
  is a REFUSAL, never a silent skip.
* **Re-ask**: `declineRound2FalsifiedRailGrants(M, taint, wd)`, called in **both** entry points
  immediately after `declineDephasingUnmarkedLoopRails` — below the round-2 fixpoint (the whole point)
  and above `lowerRotations` (which RAUWs the recorded roots to `i32` handles, after which the
  pre-lowering peel vocabulary no longer matches). Placed LAST in the decline chain so it only ever
  speaks where nothing else did.
* **It declines; it does not WITHDRAW.** Silently erasing the blocks would be the worst of both: the
  marking has already licensed `commitOutOfLoopInPlaceOps`' dtzb commitments (whose `lowerOps`
  tripwire assumes the body marking "already stands"), and a rail the spine planned to discharge
  in-body would revert to a leak with **no diagnostic**. Rule 1: loud, or nothing.
* **It RE-DERIVES its roots under FINAL taint** by calling `invariantRegisterRoots` and unioning, and
  that is a CORRECTION found by measurement, not by design: the first spelling re-asked with the
  ROUND-1 roots alone and **OVER-DECLINED** (§4, finding T-1).

**Diagnostic**: `cq loop lowering: round-1 iteration-local marking falsified by round-2 taint`.

---

## §2 — THE MEASUREMENTS

⚠ **READ §13 FIRST.** Every number below the "clean binary" line was taken on
`cq-opt` **`f972906e961c7e55`**, built after `rm -rf build/ir-pass/CMakeFiles/cq-opt.dir` +
reconfigure + rebuild. Numbers taken on the incrementally-built binaries are NOT quoted as facts
about the shipped one.

ORACLE: `cq-opt` `0e280fc62a91cec2…` (`main` `74eabd2c`), verified by `shasum -a 256` at session open
and at every use, never rebuilt.

### (a) THE HEADLINE — measured on the CLEAN binary, through the e2e layer (the only one that LINKS)

| slice | ORACLE | CLEAN BINARY | STRICT stage 2b |
|---|---|---|---|
| `slice_loop_pairing_rootmint` (= `s1_live_shift`) | **LOUD DECLINE** (bd `s82e`) | **ACCEPT, 14 trace lines** | `2 rail mint(s) of which 2 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` |
| `slice_loop_pairing_rootmint_unrolled` (the twin) | ACCEPT, 14 | ACCEPT, 14 | `… 4 cqrt_free site(s): 4 verified, 0 violation(s), 0 unproven` |
| **`diff` of the two goldens** | — | **BYTE-IDENTICAL** | gated by `e2e-loop-pairing-rootmint-twin-identical` |
| `slice_loop_pairing_measure_owned` (= `w2k`, clause (ii-c)) | ACCEPT, 16 (LEAKING) | **ACCEPT, 20** | `4 rail mint(s) of which 4 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven` |

`ran: ctest -R '^e2e-(slice-)?loop-pairing' → 4/4 Passed, 13.01 s` on `f972906e961c7e55`.

⚠ **2b IS NOT THE WITNESS FOR THIS CLASS AND NEVER WAS**, and the `0 violation(s)` above must not be
read as clearance: it counts `cqrt_alloc` SITES, and every rail this increment is about is
TEMPLATE-minted, so it reported `0 violation(s)` on the LEAKING form too. What 2b witnesses here is
that no `cqrt_alloc`-minted rail is freed dirty. **The witness for the pairing is the
rolled-vs-hand-unrolled trace pair**, and the only *committed* one is the twin-identical gate above.

### (b) VERDICTS on the CLEAN binary, whole probe set

`ran:` the per-probe pipeline over all 30 probes + the 2 hand-written L1 modules,
`f972906e961c7e55`:

| probe | ORACLE | CLEAN | what it establishes |
|---|---|---|---|
| `s1_live_shift` | DECLINE | **ACCEPT** | the bead's headline probe |
| `s2_live_derived_region` | DECLINE | DECLINE (bd `s82e` string) | §6 — the hoisted-template half is NOT built |
| `s3_live_rootmint_region` | ACCEPT | ACCEPT | the positive control, UNMOVED |
| `t2_nonlive_shift` | ACCEPT (leaking) | **ACCEPT** | the benign half also stops leaking |
| `t3_cmp_rail_data` | DECLINE | **ACCEPT** | an `icmp` interior rail |
| `w2h` / `w2h3` / `w2k` | ACCEPT (leaking) | **ACCEPT** | D4's own three "benign" exhibits |
| `a1` Ry on a body rail | DECLINE | **ACCEPT** | round 1 |
| `a2` fan-out 2 | DECLINE | **ACCEPT** | round 1 |
| `a6` K=1 · `a8` escaping temp | ACCEPT | ACCEPT | UNMOVED |
| `a7` two invariant registers | DECLINE | **ACCEPT** | a multi-root `Roots` set |
| `a9` nested loop | DECLINE | **ACCEPT** | the INNER loop is marked, the outer refused — see T-2 |
| `a3` mixed · `a4` read-after | DECLINE | DECLINE | the (ii)/(ii-c) boundaries HOLD |
| `a5` in-place on the invariant | DECLINE | DECLINE (`cq taint escape: tainted value muxed by a classical-condition phi`) | a different owner, unmoved |
| `b1` · `b2` (the boundary controls) | ACCEPT-and-leak | ACCEPT-and-leak | UNMOVED — pinned as two new fixtures |
| **`x1_xorc_inplace_in_body`** | ACCEPT | **ACCEPT, and `grep -c 'cqrt_free\|_unc'` = 0** | Track S′'s hazard: §12(3) |
| `x2_xorc_plus_outofplace` | — | DECLINE (`cq taint escape: …classical-condition phi`) | same |
| **`l1_round2_grow_65arm.ll`** | DECLINE (bd `s82e`) | **ACCEPT** | finding T-1: the re-ask re-derives and does not over-decline |
| **`l2_round2_grow_derived.ll`** | DECLINE (bd `s82e`) | **DECLINE — `cq loop lowering: round-1 iteration-local marking falsified by round-2 taint`** | the L1 window is REACHABLE and the new fence fires on it |

### (c) TRACE-LEVEL identity, rolled vs hand-unrolled

⚠ **The provenance of each row is stated, because §13 makes it matter.** The trace-identity re-run on
the CLEAN binary was still in flight when the box reached load average **319** with host time visibly
dilated; it completed the first six pairs and is handed over for the rest. Rows marked **[S2]** were
measured on the incrementally-built `9337c21095d0afdb` and their **VERDICT** (not the line count) was
re-confirmed on the clean binary by the §2(b) sweep.

**Measured on the CLEAN binary `f972906e961c7e55` — ALL NINE MAIN PAIRS, and every number equals the
S2 one exactly:**

| pair | rolled | unrolled | identity |
|---|---|---|---|
| `s1_live_shift` | **14** (was a DECLINE) | 14 | **BYTE-IDENTICAL** — and it is the committed e2e gate |
| `s2_live_derived_region` | DECLINE | 25 | the hoisted-template half, §6 |
| `s3_live_rootmint_region` | 22 | 22 | BYTE-IDENTICAL — the positive control, **UNMOVED** |
| `t1_round2_falsify` | DECLINE | 28 | `-O1` taints the `select` at round 1, so no grant is made |
| `t2_nonlive_shift` | **13** (was 9, leaking) | 13 | **BYTE-IDENTICAL** |
| `t3_cmp_rail_data` | **20** (was a DECLINE) | 20 | equal count; `-O1` folds `(y>>k)==1` to `(y & -2)==2` only in the CONSTANT-shift spelling, so the forward opcode differs **in stage 1** |
| `w2h_phase_inloop_invread` | **38** (was 30, leaking) | 38 | equal count + identical gate-symbol MULTISET; the hoist-vs-CSE position difference below |
| `w2h3_select_iterlocal_invread` | **48** (was 44, leaking) | 48 | same |
| `w2k_noregion_invread` | **20** (was 16, leaking) | 20 | same; also has its own committed e2e golden |

The three `w2*` divergences are a STAGE-1 fact: `-O1` HOISTS the invariant `y & 1` in the rolled
spelling and CSEs it mid-function in the unrolled one, so one gate sits at a different point in the
two streams **before the pass runs**. The gate-symbol multiset is identical (measured with
`diff <(sed 's/(.*//' … | sort | uniq -c) …` — **0 differences on all three**) and the two orderings
are the same unitary, because that gate writes a fresh rail while the per-trip chain touches only its
own: disjoint rails commute.

**THE ADVERSARIAL PAIRS — the clean-binary re-run COMPLETED**, after this record's first close, and
**every one of the 20 pairs reproduces its earlier number exactly.** (The run took hours of wall
clock: the box sat at load average **161–391** with host time dilated roughly 75×.)

BYTE-IDENTICAL on the clean binary: `a1` 16 == 16, `a2` 18 == 18, `a6` 9 == 9 (unmoved), `a7`
36 == 36, `a8` 9 == 9 (unmoved), `r3` 24 == 24, `r5` 28 == 28 (unmoved, and its lowered IR is
md5-IDENTICAL to the ORACLE's on BOTH halves).

Declines that must decline, all unmoved: `a3`, `a4`, `a5`, `r4` (tainted-index memory), `x2`.

Divergences, each adjudicated rather than blessed: `a9` 24 vs 20 (T-2, a twin the optimiser CSEs);
`b1` 13 vs 19 and `b2` 14 vs 18 — the pre-existing leak clause (ii-c) correctly refuses, and the
ORACLE measures **the same 13/19 and 14/18**, which is the entire point of those two controls;
`x1` 13 == 13 with the order differing and **0 `_unc` / 0 `cqrt_free` in the lowered IR**;
`r2` 24 vs 30 (T-6, the gap isolated entirely to the non-qualifying function).

### (d) THE REGRESSION SURFACE, whole-suite

`ran: lit ir-pass/test` (unfiltered, 2039 discovered) on the S2 binary: **1 failure**, and it was
`loop_leak_dephase_accept_pertrip_dead.ll` firing its OWN L8 retirement trigger. Together with the two
converted earlier, the total blast radius across the whole fixture suite is **3 files, all expected,
all in the capability's direction**:

| fixture | was | is |
|---|---|---|
| `loop_leak_dephase_reject_noregion_live.ll` | DECLINE (bd `s82e`) | **ACCEPT**, stream = the 14-line twin's, rolled |
| `lowering_uncompute_interior_leak_loop_rail.ll` | ACCEPT pinning a LEAK (bd `6uqc`) | **ACCEPT pinning the in-body pairing** |
| `loop_leak_dephase_accept_pertrip_dead.ll` | ACCEPT, `LEAK-NOT` on every `_unc`/`cqrt_free` | ACCEPT, the prefix retired to `PAIR` |

Four fixtures ADDED: two (ii-c) boundary accepts (§3), the L1 negative
(`loop_pairing_reject_round2_falsified.ll`), and — at the e2e layer — three slices + one
twin-identical gate.

---

## §3 — THE BOUNDARY, PINNED WITHOUT ANOTHER FENCE'S STRING

Two accept fixtures pin clause (ii-c)'s boundary **positively** and, deliberately, with **no
post-loop rotation** — so no fence's diagnostic is involved and they cannot move when bd `s82e`'s
conjuncts are widened (bd `c767` / bd `7845` / bd `2g52` are live work on the SAME function this
session; *a boundary pinned by someone else's diagnostic is a boundary that moves when they edit
it*):

| fixture | shape | what it pins |
|---|---|---|
| `loop_pairing_reject_root_hoisted_template_data.ll` | a measure-owned hoisted rail BESIDE a hoisted `p = y*3` read as DATA | clause (ii) still refuses a template rail; the body stays UNMARKED; `LEAK-NOT` on every `_unc` and `cqrt_free`. **If a `_unc` appears here, (ii-c) over-widened and the multiplicity miscompile is LIVE** — with `opt` exit 0, verify-clean and 2b `0 violation(s)`, and nothing else in the tree red. |
| `loop_pairing_reject_root_invariant_read_after_loop.ll` | the invariant rail is `cq_measure`d IN the loop AND read as DATA after it | the **"EVERY user"** quantifier. A predicate asking *"SOME user is a measure"*, or inspecting only users INSIDE the loop, would admit this rail — which is precisely the over-accept direction, because the post-loop data user is what makes it interior. |

Both are ACCEPTs (the module compiles) whose `LEAK` prefix is a whole-file negative in its **own
prefix** — a positive `CHECK-COUNT` inside an ordered block WINDOWS every negative after it (Rule 12
fixture-hygiene defect (a)) — and the negatives are spelled `call void @cq_template_{{.*}}_unc`
rather than a bare `-NOT: _unc`, because a bare word can match the module's own path/header line
(bd `qta2`).

---

## §5 — CROSS-TRACK: THE INTERACTION WITH TRACK S′ (`declineDephasingUnmarkedLoopRails`)

**The question the brief asks — for each program this pairing makes compile correctly, does S′'s
fence still decline it? — has a structural answer, and it is NO.**

That fence's **conjunct (1) is "THE BODY MUST BE UNMARKED"**, and it `continue`s to the next loop
before conjuncts (2) and (3) are evaluated at all:

```
bool Marked = false;
for (BasicBlock *BB : L->blocks())
  if (taint.IterationLocalBlocks.count(BB)) { Marked = true; break; }
if (Marked) continue;                       // <-- every tu9q customer exits here
```

Every program this track moves from DECLINE (or from ACCEPT-AND-LEAK) to a correct ACCEPT is moved by
**marking its body**, so it leaves that fence at conjunct (1). S′ is widening conjuncts **(2)**
(bd `c767` — the interfering rotation INSIDE the body) and **(3)** (bd `7845` — the `BinaryOperator`
opcode proxy) and adding a conjunct for bd `2g52` (`!InPlaceRailOps.count`). **None of those is
reached for a marked body.** A capability landing behind a fence that refuses its own customers is
the failure mode the brief names; this one does not have it.

**Three couplings I am declaring rather than assuming, because they are the ways that answer could
become false:**

* **C-1 — if S′ edits conjunct (1)**, the answer changes and must be re-derived. Nothing in bd `c767`
  / `7845` / `2g52` as written touches it, but that is a reading of three bead texts, not a
  measurement of S′'s branch.
* **C-2 — `railIsInterior`.** S′ owns it (it is `declineDephasingUnmarkedLoopRails`' helper) and bd
  `7845`'s pre-specified fix is at the `isa<BinaryOperator>` filter *beside* it. This track does
  **not** call it — clause (ii-c) has its own `measureOwnedInvariantRail` with a written argument for
  why the two questions differ (§1(4)) — so a change to `railIsInterior` cannot silently change this
  track's accept set. That independence is deliberate and it is the reason the duplication is
  defensible.
* **C-3 — bd `2g52` is an over-decline S′ is REMOVING, and this track removes a different slice of
  the same fence's population by a different route.** Both directions are safe (each turns a DECLINE
  into an ACCEPT); they can compose only additively. A merged binary should be measured on both
  tracks' probe corpora — a mover neither track's binary reproduces alone is the F×P composition
  finding of 2026-09-14 repeating, and it is a FINDING, not a pass.

**Two fixtures of mine are pinned by S′'s string and will move if S′ moves it**, stated here so a red
is diagnosed in seconds rather than bisected: `loop_leak_dephase_reject_region_derivedbase_live.ll`
(unchanged verdict, header updated) and — indirectly — the `a3` / `a4` adversarial probes, which are
records rather than fixtures for exactly this reason.

**I did not edit S′'s worktree, did not read its branch, and do not assume its landing.**

---

## §6 — WHAT IS **NOT** BUILT, AND WHAT IT WOULD TAKE (Rule 17)

**The hoisted loop-invariant TEMPLATE rail read as DATA** — `s2_live_derived_region.c` (`int p = y *
3;`), bd `test_C_libtooling-1m5p`, and the three `control_phase_kickback_mixed_*_leak_control.ll`
shapes. It still declines. This is brought back as a question, not stubbed:

**Why admitting it as a Root is NOT enough, measured rather than argued.** With the body marked,
`%p`'s consumers are all in the body, so `dagInsertPoint` — the nearest common POST-dominator of the
anchors — lands **in the body**. The interior partition's per-candidate skip
(`canRepeat(&BB) && !IterationLocalBlocks.count(&BB)`) does not exclude `%p`, because `%p`'s own
block is the PREHEADER and a preheader does not repeat; and §2.9's final-`At` fence passes because a
marked body is its affirmative exception. So `%p` would get **K adjoints against ONE forward
`cq_template_mul_i32_hl`** — the exact pairing `Uncomputation.cpp:982-1000` describes and says
"nothing here refuses". The rolled form would then be a WRONG UNITARY where today it is a decline.

**The two things it needs, both of which are real work in the Rule-13 core:**

1. **The real multiplicity test** at `Uncomputation.cpp`'s §4 and §2.9 — *"same enclosing marked
   body, or equal trip multiplicity"*, in the source's own words. The cheapest sound spelling is a
   per-block MARKED-LOOP-HEADER map beside `IterationLocalBlocks` (`markedHeaderOf(G->getParent()) ==
   markedHeaderOf(At->getParent())`, both nullable), which refuses the preheader-`G` / body-`At`
   pairing in one direction and the body-`G` / exit-`At` pairing in the other. ⚠ It is **UNREACHABLE
   TODAY** — this track's clause (ii)/(ii-c) admissions are both structurally excluded from receiving
   an `At` (§1) — so it cannot be written red-green and was deliberately NOT added here. A fence with
   no reachable customer and no failing fixture is a prediction, not a test.
2. **A loop-EXIT recovery point for a preheader-minted rail.** The correct rolled circuit discharges
   `%p` ONCE after the loop (matching its once-executed forward gate), with the body's per-trip rails
   discharged per trip. `dagInsertPoint` cannot produce that today: it post-dominates the anchors and
   the anchors are in the body. The rule would be *"if every recovered gate of the group is OUTSIDE
   the loop containing the natural `At`, hoist `At` to that loop's exit"*, which is sound here
   (`%p` is dead at the exit, its borrowed parent `y` is ungated inside `L` by clause (iii), and the
   body's rails have already been returned to |0⟩) but is new placement logic in `FreePoint` /
   `DagTraversal`.

**Measured cost of NOT building it:** the rolled form of `s2` would emit 23 trace lines against its
twin's 25 even with the Root admitted — still divergent, because `%p` itself would leak. **Half a fix
here is a wrong unitary, not a smaller capability**, which is why it is one increment or none.

**Owner question carried up** (the orchestrator's to route): the hoisted-template half is a second
Rule-13 increment of comparable size to this one. Is it wanted now, or does the interim decline stand?

---

## §7 — THE bd `s82e` POPULATION SPLIT, AS THE BRIEF ASKS IT

bd `s82e`'s population, stated as *which programs this track moves and which stay a Rule-6 accepted
leak*:

### (a) MOVED — DECLINE → correct ACCEPT (the divergent half the D4 interim fence refused)

Every program whose loop-invariant tainted reads are **all** root mints or measure-owned rails.
Measured members: `s1_live_shift` (the bead's headline probe, and the shape
`loop_leak_dephase_reject_noregion_live.ll` pinned), `t3_cmp_rail_data`, `a1_ry_on_body_rail`,
`a2_fanout_body_rail`, `a7_two_registers`, `a9_nested_loop`. Each is now discharged in-body,
per trip, `_unc` before `cqrt_free`.

### (b) MOVED — ACCEPT-AND-LEAK → correct ACCEPT (the "benign" half — and it was NOT benign, it was UNWITNESSED)

`w2k_noregion_invread`, `w2h_phase_inloop_invread`, `w2h3_select_iterlocal_invread` — **D4's own three
benign exhibits** — plus `t2_nonlive_shift`. These accepted on the ORACLE and leaked; they now
discharge, and their rolled gate-symbol multiset equals their hand-unrolled twin's exactly.

⚠ **This is the part of the split worth reading twice.** D4 ruled those three benign because *"their
joint garbage never reaches the retained subsystem"*, and the closing ERRATUM already corrected that
to *"a true statement about THOSE THREE PROGRAMS and not about the shape any conjunct tests — two of
the three cross the line under a one-line edit"* (bd `c767`). **This track makes the correction moot
for them**: they no longer leak at all, so there is no garbage to argue about, and bd `c767`'s
customers built from them (`w2k` + `u = cq_theta(u,.9)`, `w2h` + the same) lose their leak by the
same route. It does **not** close bd `c767` — the fence still misses the class wherever the body is
unmarked for some other reason — and this record must not be read as closing it.

### (c) STAYS A RULE-6 ACCEPTED LEAK, correctly

* **A superseded VALUE rail** — D2's own cited `h0/h5/h10` (the old `a` replaced by a merge output)
  and `h3/h8/h13` (the `a-3` temporaries). It cannot be uncomputed without destroying the answer that
  replaced it. Untouched by this track and correctly left allocated.
* **An `Ry`-carrying rail**: the per-trip `u` in `w2k`/`w2h`/`w2h3` (`Ry(θ)|0⟩ ≠ |0⟩`) and the user's
  register. Left allocated in BOTH spellings, before and after.
* **A MEASURE-OWNED rail** — clause (ii-c)'s own subject. The measurement owns it; neither partition
  ever frees it; both spellings leave it allocated. Admitting it as a Root changed its disposition by
  exactly nothing.

### (d) STILL DECLINES — the hoisted TEMPLATE rail read as DATA

`s2_live_derived_region`, bd `1m5p`, and the three `control_phase_kickback_mixed_*_leak_control.ll`
shapes. §6. **This is the honest residue of the bead**, and it is a decline rather than a leak
because bd `s82e` ships the interim fence for it.

---

## §4 — RULE-13: THE ROUNDS, WHAT EACH ATTACKED, AND WHAT THEY FOUND

Budgeted **two rounds up front** (the measured hit rate says the next round finds something), both
run by this agent as adversarial probe families rather than as a re-read of the diff. Every probe is
committed under `trackT/probes/adv/`.

### ROUND 1 — the ACCEPT boundary and the spine's behaviour inside a newly-marked body

What it attacked: *"the marking is the easy half; the hard half is what the spine then does with a
body it was never granted before."* Nine probes, each with a hand-unrolled twin:

| probe | attacks | ORACLE | SUBJECT | verdict |
|---|---|---|---|---|
| `a1_ry_on_body_rail` | a body rail carrying an `Ry` (`preservesBasisUnderRecord` FALSE) — could the spine discharge something it must not? | DECLINE | ACCEPT 16 | **16 == 16 BYTE-IDENTICAL** |
| `a2_fanout_body_rail` | fan-out 2 on a body rail — the Rule-8 linear-lineage guard | DECLINE | ACCEPT 18 | **18 == 18 BYTE-IDENTICAL** |
| `a3_mixed_invariant_rails` | a measure-owned rail BESIDE a template rail read as data | DECLINE | DECLINE | boundary HELD |
| `a4_invariant_measured_and_read_after` | the "EVERY user" quantifier of (ii-c) | DECLINE | DECLINE | boundary HELD |
| `a5_inplace_on_invariant` | an in-place dtzb mutation of the invariant register (makes it loop-CARRIED) | DECLINE | DECLINE | different owner, unmoved |
| `a6_k1` | trip count 1 — the degenerate rolled form | ACCEPT 9 | ACCEPT 9 | UNMOVED, 9 == 9 IDENTICAL |
| `a7_two_registers` | a MULTI-ROOT `Roots` set (two invariant registers, both re-rotated after) | DECLINE | ACCEPT 36 | **36 == 36 BYTE-IDENTICAL** |
| `a8_escaping_temp` | a body temp whose value is live at the exit — the escape clause | ACCEPT 9 | ACCEPT 9 | UNMOVED, 9 == 9 IDENTICAL |
| `a9_nested_loop` | a quantum SUBLOOP — gates run N times per outer trip | DECLINE | ACCEPT 24 | see **T-2** |

**T-2 (round 1, INVESTIGATED, NOT A DEFECT — and the instrument was the thing at fault).**
`a9_nested_loop` reports rolled 24 vs unrolled 20, which reads as a divergence. It is not: the OUTER
loop is refused (`railLocalQualifies`' subloop clause finds tainted content in a block whose
`LI.getLoopFor` is not `L`) and the INNER loop is marked on its own, which is correct — each inner
trip mints and discharges its own rail, 1:1. The 4 extra lines are an artefact of **my twin**: the
outer/inner shifts are `1,2,2,3`, and `-O1` **CSEs the two identical `(y>>2)&1` chains in the
hand-unrolled spelling into one** (its trace shows `cqrt_measure_i32(h4)` twice on the same rail),
while the rolled form computes a separate rail per trip. Both are Bennett-clean — every rail gets
`_unc` then `cqrt_free`, nothing dirty is freed — and measuring two perfectly-correlated copies of
one bit has the same distribution as measuring one copy twice. ⚠ **Recorded as a lesson, not a pass:
a twin whose two halves are not `-O1`-equivalent measures the optimiser, not the lowering** — which
is the same shape as `CLAUDE.md` L10's "an instrument's failure mode is to report a pass", arriving
from the other side (here it reported a FAILURE that was not one).

### ROUND 2 — the stages and records this grant touches that round 1 did not

What it attacks: *"L2 — when you widen a set, ask what OTHER set was computed over the same closure",
and the record's own lifetime.* Five probes (`trackT/probes/adv/r*.c`), plus the two hand-written
round-2-growth modules:

| probe | attacks |
|---|---|
| `r1_break_loop` | `tryBreak` runs FIRST in `lowerLoops` and `continue`s — the new offer must never see a loop it claimed |
| `r2_two_functions` | bd `test_C_libtooling-1yeu`, the ONE-FUNCTION-PER-MODULE instrument gap, head-on: two kernels, one qualifying and one not |
| `r3_two_loops_one_register` | the grant record's KEY — two loops reading one root mint. A module-scoped key lets one loop's grant satisfy the other's re-ask (the F-C1B-2 / F-W1-1 shape) |
| `r4_qram_body` | tainted-index MEMORY in the body (L3) |
| `r5_switch_in_body` | a tainted-condition REGION still standing at round 1 (L2) |
| `l1_round2_grow_65arm.ll` | THE L1 WINDOW: a 6.5 classical-call arm outside the loop whose merged result is read inside it |
| `l2_round2_grow_derived.ll` | the same, but the body reads a value DERIVED from the `%out` rail |

**T-1 (round 2, FOUND AND FIXED — the re-ask over-declined).** The first spelling of
`declineRound2FalsifiedRailGrants` re-asked `railLocalQualifies` with the **ROUND-1 roots alone**, and
that is a DIFFERENT QUESTION from the one L1 asks. Measured on `l1_round2_grow_65arm.ll`: the merge
phi of a 6.5 classical-call arm is UNTAINTED at round 1 (its incomings are a classical call result
and a constant), so the round-1 grant is made without it; after `repropagateControlMerges` the body
reads the emitter's `%out` rail, which `invariantRegisterRootsImpl` clause (ii-b) **ADMITS** as a
merge out-rail — the grant is still justified, just by a root the round-1 record could not name. The
round-2 region path reaches the same conclusion by the same call and only fails to run here because
`collapseFlattenedLoopRails` opens `if (taint.InLoopFlattenedPreds.empty()) return;` and this region
is not IN a loop. **Fix: the re-ask RE-DERIVES its roots under FINAL taint by CALLING
`invariantRegisterRoots` and unioning** — grant-only, so a false return adds nothing and its
`InPlaceRailOps` commitments are rolled back; a true return's commitments are idempotent with round
1's and re-verified by `lowerOps`' own tripwire. **It still marks nothing** —
`declineDephasingUnmarkedLoopRails` runs just above and reads `IterationLocalBlocks`, and a stage
below it that could ADD a marking would make that fence read a set that is still moving, which is the
RETIREMENT TRIGGER its own header states.

**ROUND-2 RESULTS, measured on the CLEAN binary after the record's first close — the twin run
completed and reached the `r*` probes.** Both binaries, ORACLE vs subject, with the lowered-IR md5
compared within each row:

| probe | ORACLE | subject | twin | reading |
|---|---|---|---|---|
| `r1_break_loop` | DECLINE | **ACCEPT 24** | ⚠ **no witness** | see T-5 |
| `r2_two_functions` | DECLINE | **ACCEPT 24** | 24 vs 30 DIVERGE | see T-6 — this is the RIGHT answer |
| `r3_two_loops_one_register` | DECLINE | **ACCEPT 24** | **24 == 24 IDENTICAL** | the per-loop grant KEY works: two loops on one root mint, both marked, neither satisfying the other's re-ask |
| `r4_qram_body` | DECLINE | DECLINE | — | (L3) tainted-index memory still refuses; **lowered IR of the twin md5-IDENTICAL to the ORACLE's** |
| `r5_switch_in_body` | ACCEPT | ACCEPT | **28 == 28 IDENTICAL** | (L2) a tainted region still standing at round 1 still refuses; **lowered IR md5-IDENTICAL to the ORACLE's, both halves** |
| `x1_xorc_inplace_in_body` | ACCEPT | ACCEPT 13 | 13 == 13, order differs | Track S′'s hazard: equal counts and **0 `_unc` / 0 `cqrt_free` in the lowered IR** |
| `x2_xorc_plus_outofplace` | — | DECLINE | — | a different owner (`cq taint escape: …classical-condition phi`) |

**T-6 (round 2, the bd `test_C_libtooling-1yeu` probe, ADJUDICATED CLEAN).** `r2_two_functions` puts a
QUALIFYING kernel (`ka`: root mint, re-rotated after the loop) and a NON-qualifying one (`kb`: the
hoisted template rail `p = y * 3`) in ONE translation unit, which is the cross-function shape every
corpus and gate in the tree is structurally blind to. Read off the traces line by line: **lines 1–14
(`ka`) are BYTE-IDENTICAL in both spellings** — the pairing fires, `lshr_unc` + `cqrt_free` per trip —
and the **entire** 6-line gap is in `kb` (the unrolled twin discharges `h9`, `h7` and the `mul` rail
`h6`; the rolled form leaks all three). That is precisely the un-built hoisted-template half of §6,
**isolated to the function that has it**, with no contamination in either direction. A per-function
state leak in the grant record would have shown here as a moved `ka`; it does not.

⚠ **T-5 (round 2, AN ACCEPT WITH NO TWIN WITNESS — FILED, NOT CLEARED).** `r1_break_loop` (a 7.4
`break` loop whose exit condition is CLASSICAL, beside an invariant root mint) moves DECLINE →
ACCEPT 24. `tryBreak` does not claim it — the exiting condition is classical — so it falls through to
the new offer and is marked. The emitted stream is well-formed (four per-trip groups, each
`lshr` → `and` → `lshr_unc` → `free` → `measure`, then the diffusion and the final measure; STRICT 2b
`0 violation(s), 0 unproven`), and the structural argument is that `Uncomputation`'s
`PDT.dominates(At->getParent(), G->getParent())` is what protects a multi-exit body — a discharge
point the `break` could skip while the forward gate ran fails post-dominance and the group **leaks
instead** of half-reversing.

**But that is an argument, and the instrument that decides this class cannot be pointed at it**: the
hand-unrolled spelling of a `break` loop is a nested-if cascade, which declines at a DIFFERENT owner
(`cq opcode lowering: rotation/measure operand predates a non-diagonal gate`, bd `3d8q`'s fence) on
BOTH binaries — so there is no twin to compare against. **CLAUDE.md Rule 2 says analytic reasoning
plus a green stream is NECESSARY AND NOT SUFFICIENT**, and the trace cannot help either: every
`cqrt_measure` returns 0 in the trace runtime, so `s` never exceeds 1 and the `break` path is never
taken in the recorded run. ⚠ **Recorded as an ACCEPT THIS TRACK DID NOT WITNESS.** Two ways to close
it, neither done here: write a twin whose unrolled form does not trip the stale-reader fence, or
refuse a multi-exit loop at the new offer until one exists. I did NOT add the refusal, because it
would be an over-decline on a Prime-Directive argument I cannot substantiate either — but a reviewer
who disagrees should say so, and this is the single item in this increment where a second opinion
would change what ships.

> ✅ **T-5 IS CLOSED — 2026-09-15, Rule-13 round 2 (`review_r13_loop/REVIEW.md` §I-1) and the
> loop-group merge+fix landing. THE SECOND OPINION THIS PARAGRAPH ASKED FOR ARRIVED, AND IT FOUND A
> WITNESS RATHER THAN A DEFECT.** The disposition is **SHIP, WITH THE WITNESS RECORDED — and NO
> multi-exit refusal**, which is the call this track made and the reviewer independently endorsed
> (Rule 17, owner 2026-09-11: an over-decline on an unsubstantiable claim is a defect, not a margin).
>
> **Both halves of "no twin" were confirmed, not taken on trust.** `r1_break_loop_un` declines with
> `cq opcode lowering: operand predates a non-diagonal gate` on the ORACLE, on Track S′, on Track T
> AND on the merged binary; a split-body variant built specifically so `-O1` cannot if-convert it
> (`loopfix/probes/t5b_break_split.c`) declines at the **same** fence on all of them.
>
> **THE TRANSFER WITNESS, re-measured at the merge on `9dd81edb9f949bb5`:** `-O1` folds the `break`
> into one extra disjunct on the **latch**, so the body is a SINGLE basic block — mint, mint, `_unc`,
> `cqrt_free`, `measure`, then `br i1 %8` — which makes the per-trip group atomic and 1:1 *by
> construction*, and means the `break` can only ever stop the sequence at a group boundary. The
> break-free twin of the same body (`loopfix/probes/t5a_nobreak.c`, the `if (s > 1) break;` deleted)
> **does** have a usable hand-unrolled twin and is **24 == 24, `diff` EMPTY, BYTE-IDENTICAL** — and
> `diff r1_break_loop.trace t5a_nobreak.trace` is **EMPTY** too. So this program's emitted stream IS
> the stream of a program that is byte-identical to its own hand-unrolled twin.
>
> ⚠ **It is a witness OF THE SAME KIND obtained by DECOMPOSITION, and it is not a twin.** Multi-exit
> shapes are still not exhausted, and "the reachable ones die at bd `3d8q` first" remains **a
> measurement about today's binary, not a proof** — both sentences are carried verbatim into the
> fixture header rather than left here.
>
> **The cell is now PINNED**, which it was not when this paragraph was written:
> `ir-pass/test/loop_pairing_accept_break_latch_folded.ll`, with the atomicity pinned by a
> `CHECK-NEXT` chain (so a `-O1` that stopped folding the break would go red) and an **L8 retirement
> trigger naming bd `test_C_libtooling-3d8q` by id**: when that fence stops refusing the nested-`if`
> cascade, a real twin becomes constructible — build it and re-derive the cell.

**T-4 (round 2, FOUND BY THE MUTATION MATRIX IN MY OWN FIXTURE, FIXED).** The first run of
`probes/inject_T.py` scored **MISSED 1**: the `inject_unc_free` mutant against
`loop_leak_dephase_accept_pertrip_dead.ll`. The cause is Rule 12's fixture-hygiene defect **(a)**
verbatim — I had put the `CHECK-COUNT` directive ABOVE the negatives in ONE prefix, and a positive
count WINDOWS every negative after it, so an injected `_unc` + `cqrt_free` landing BEFORE the second
match was scanned by **0 of the 7 negatives**. ⚠ **That file's own header quotes the rule three
paragraphs above the line that broke it**, which is the finding worth carrying: knowing the lesson is
not the same as not making the mistake, and the only thing that caught it was a harness that runs the
fixture's own RUN lines against a mutated module. Fixed by splitting counts and negatives into two
whole-file prefixes in all THREE converted fixtures (not just the one that failed — the same shape was
latent in the other two), and re-run: **30 mutations applied, MISSED 0, N/A 10**. ⚠ A second, smaller
trap fell out of the fix: writing the literal text `PAIR-COUNT-2` **in prose** makes FileCheck parse it
as a directive (`error: invalid count in -COUNT specification on prefix 'PAIR'`). Never spell a live
prefix's directive in a comment.

⚠ **The finding's real content is not the over-decline, it is that `l1_round2_grow_65arm.ll` PROVES
the L1 window is REACHABLE.** On S1/S2 the module printed the new diagnostic where the ORACLE printed
bd `s82e`'s — i.e. a round-1 grant really was falsified by round-2 taint, on a constructible program.
Without the re-ask the grant would have stood silently. A fence written for an L1 window nobody can
reach is a prediction; this one has a witness.

---

## §8 — bd `test_C_libtooling-1m5p`: DOES NOT FALL OUT, AND HERE IS WHY

bd `1m5p` is *"an in-loop region whose DERIVED condition is loop-INVARIANT (LICM-hoisted chain)
leaves the top template rail ENTANGLED and allocated on the ROLLED side while the flat twin
discharges all three."* That is **the same family as `s2_live_derived_region`** — the top rail is a
hoisted TEMPLATE rail read as DATA by the body's condition — and §6 is its answer: admitting it as a
root without the multiplicity test and the loop-exit recovery point converts a leak into an
**over-reversed rail**. It is **not** closed by this increment, and I did not force it.

The brief said *"do not force it"*, and the reason to say so explicitly is that it LOOKS adjacent:
the marking machinery is the same, the fix site is the same function, and `s2` differs from `s1` by
one line of C. The difference is in `Uncomputation`, not in `LoopLowering`.

---

## §9 — F-7's FOUR TWIN CELLS: SCOPED, MOVED, AND **STILL NOT ADDED** — with the reason updated

The 2026-09-14c merge gate measured four cells and handed them on. This increment moves two of them,
and one of the corrections attached to them stops being true:

| cell | verdict on ORACLE `0e280fc6` (F-7) | verdict on this branch | note |
|---|---|---|---|
| `m_noregion_invread_dead` (`w2k`) | TRACE-DIVERGENCE 16/20, signature `07ae35c484747c29` | 20/20, still DIVERGE **but a different divergence** | see below |
| `m_noregion_invread_live` (`s1`) | `UNROLLED-ONLY` | **`ACCEPT-IDENTICAL` 14 == 14** | the cell that would have caught the class, now the cell that proves it is fixed |
| `m_region_derivedbase_live` (`s2`) | `UNROLLED-ONLY` | `UNROLLED-ONLY` — unmoved | §6 / §8 |
| `m_region_rootmint_live` (`s3`) | `ACCEPT-IDENTICAL` 22 == 22 | unmoved | the positive control |

⚠ **F-7's correction (b) must be re-stated, because this increment falsifies its premise.** It read:
*"the `dead` cell's counts (0,0,8) vs (2,2,8) are the SAME structural signature as the `_live` cells
the fence now refuses … that distinction is invisible in the trace; the twin matrix cannot make it,
only a fence can."* On this branch **both halves of the `dead` cell discharge** — the counts agree —
and its residual divergence is **positional only**: `-O1` HOISTS the invariant `y & 1` in the rolled
spelling and CSEs it mid-function in the unrolled one, so one gate sits at a different point in the
two streams **before the pass runs**. The gate SYMBOL MULTISET is identical (measured), and the two
orderings are the same unitary because `cq_template_and_i32_hl(h0,1)` writes a fresh rail while the
per-trip chain touches only its own — disjoint rails commute. So the `dead` cell is no longer *"the
same signature as the `_live` ones"*; it is a **stage-1 artefact**, and its old quarantine signature
`07ae35c484747c29` is STALE and must not be transcribed.

**They are STILL NOT ADDED, and the reason has changed.** F-7's reason was cost (`cells_of_matrix()`
is a closed axis product with asserted sub-grid sizes; a bespoke family needs its own generator,
red-green and mutant validation). Two reasons now stand in front of that:

1. **A stronger witness already ships with this increment.** `e2e-loop-pairing-rootmint-twin-identical`
   is a `compare_files` gate over two committed goldens at the only layer that LINKS, in the shipped
   instrument set, alongside the 40 existing `*-twin-identical` entries — and it is the *same*
   assertion `m_noregion_invread_live` would make, with none of the generator work.
2. ⚠ **Track I is editing `tools/loop_twin_matrix.py` in this same session.** Adding a cell family to
   a closed axis product with asserted sub-grid sizes, in a file another track is changing, is a
   guaranteed conflict in the one instrument whose `--regenerate` has already eaten 54 lines of
   ruling prose once (bd `test_C_libtooling-gfsk`).

**What the adding increment still needs, carried forward:** a generator for the four bespoke sources,
an expected-table row each for the three non-divergent cells, and — for the `dead` cell — either a
quarantine block with a FRESHLY MEASURED signature or, better, a twin whose two halves are
`-O1`-equivalent so the cell can be `ACCEPT-IDENTICAL` instead of blessed-divergent. **A blessed
divergence nobody can explain is a gate people stop reading** (L10).

---

## §10 — OPEN, FILED, AND OWED

**Open with the orchestrator / the owner:**

1. **The hoisted-template half (§6)** — a second Rule-13 increment of comparable size. It is what
   retires `s2_live_derived_region`, bd `1m5p`, the three `control_phase_kickback_mixed_*_leak_
   control.ll` shapes and the residue of bd `s82e`'s interim fence. *Is it wanted now?*

**Filed (new), for whoever routes beads:**

2. **The real multiplicity test is still ABSENT and still unreachable.** `Uncomputation.cpp:982-1000`
   says in its own words what it needs — *"a real multiplicity test (same enclosing marked body, or
   equal trip multiplicity), not a re-reading of these two"* — and this increment **does not build
   it** and **does not make it reachable** (§1(2), §1(4): both admitted root spellings are
   structurally excluded from ever receiving an `At`). It is a precondition of the hoisted-template
   half, not of this one. ⚠ **A future widening of clause (ii) that does not build it first is a
   silent miscompile with no red test**, which is exactly what that comment predicts.
3. **`taint.IterationLocalBlocks` is a raw `BasicBlock *` set that nothing scrubs**, and this
   increment adds customers to it. The re-ask closes the half it can see — a grant whose header was
   erased declines LOUDLY (§1(5), step (0)) — but the set itself still holds stale addresses for any
   OTHER marking whose blocks were erased, and a freed address is reused by the next allocation. This
   is pre-existing (the source says so at `declineUnmarkedRolledIterLocal`'s marking scan) and is NOT
   made worse in kind, only in population.

**Owed as a REVIEW, not as code:**

4. ⚠ **`r1_break_loop` — an ACCEPT THIS TRACK DID NOT WITNESS (T-5).** A classical-exit 7.4 `break`
   loop beside an invariant root mint moves DECLINE → ACCEPT, the stream is well-formed and 2b is
   clean, and the structural argument (multi-exit is protected by `Uncomputation`'s post-dominance
   clause, which degrades to a LEAK) is sound as far as it goes — but the hand-unrolled twin declines
   at a different owner on both binaries, so **the one instrument that decides this class cannot be
   pointed at it**. This is the single item where a second opinion would change what ships.

5. **A Rule-13 opinion on the composition with Track S′.** §5 argues structurally that this track's
   customers exit `declineDephasingUnmarkedLoopRails` at conjunct (1) and never meet S′'s widened
   conjuncts. That argument was made against the SHIPPED fence, not against S′'s branch, which I did
   not read. **A composition is not cleared by clearing its parts** — that is the F×P finding of
   2026-09-14, and it applies here by construction: two tracks, one function, opposite edits.

---

## §11 — THE STREAM-CHANGE SURFACE I DELIBERATELY ACCEPTED, STATED BEFORE THE SWEEP

`invariantRegisterRoots` is **not** a pure predicate: `invariantRegisterRootsImpl` opens by calling
`commitOutOfLoopInPlaceOps` on every candidate, which marks a PREHEADER dtzb `add`/`xor` self-update
`InPlaceRailOps` + `PreLoopCommittedInPlaceOps`. On FAILURE `invariantRegisterRoots` rolls both back,
so a refused loop leaves `taint` byte-identical; on SUCCESS the commitments stand, and `lowerOps`
emits the in-place `cqrt_{addc,xorc}_<W>` instead of the out-of-place `cq_template_<op>_<W>_hl`.

**Calling it from `lowerLoops` therefore makes those commitments at ROUND 1 for loops that never had
them made at round 1 before**, including loops where it returns TRUE but `markIfRailLocal` then
declines to mark (`!AnyLocal`). Three things make that acceptable and one of them is a measurement:

1. It is the **same call the round-2 site already makes**, with the same success/rollback discipline;
   it is not a new contract.
2. `lowerOps` **RE-VERIFIES every pre-loop in-place marking under FINAL taint** and a changed answer
   is a LOUD decline, never a silent fallback (the (1b) tripwire). So the failure mode is a decline,
   not a miscompile.
3. **The corpus sweep is what decides whether it moved anything**, and it covers `ir-pass/test/*.ll`,
   every session probe dir, AND `tests/e2e/*.c` — the last on purpose, because a lowering change that
   moves a shipped e2e stream must not first be seen at the merge gate (§ `GATES.md`).

⚠ **If the sweep shows an `A→A` md5 move on a module with a preheader dtzb chain, that is this
surface and not the marking** — the two are separable by looking for `cqrt_addc`/`cqrt_xorc` in the
lowered IR, and they must not be reported as one number.

---

## §12 — TRACK S′'s THREE POINTS, ANSWERED (orchestrator message, 2026-09-15)

### (1) `mintsOutOfPlaceTemplateRail` — **I do not have that predicate and must not grow one**

S′ built *"will `lowerOps` mint an out-of-place rail here?"* and asked that Track T call it rather than
re-spell it. **This track never asks that question.** It adds exactly ONE predicate,
`measureOwnedInvariantRail(V)`, whose question is *"is every USER of this value a `cq_measure`?"* —
a user-disposition test on a VALUE, not a mint test on an OP. The reason the two cannot be folded is
the same reason the pairing is safe at all (§1(2), §1(4)):

> **This increment never decides WHAT to discharge.** It removes a POSITIONAL refusal
> (`canRepeat(&BB) && !IterationLocalBlocks.count(&BB)`) for a body it has proved runs its forward
> stream and its adjoint stream once per trip each. Every "is this a rail I must pair" question is
> still asked by the unchanged owners — `ChainWalk::isInteriorTerminalHandle`,
> `FreePoint::computeFreePoint`, `Uncomputation::recoverDataDag`. Not one line of `Uncomputation.cpp`,
> `ChainWalk.cpp`, `FreePoint.cpp` or `DagTraversal.cpp` is touched (`git diff --stat` shows it).

**So there is no second spelling to fold, and the merge needs no rename.** ⚠ **One thing the merge
agent SHOULD check**, because I could not read S′'s branch: S′'s predicate is said to call
`railValueConsumerDisposition`, which does **not exist on `main`** (grepped) and is therefore new on
that branch. **If `railValueConsumerDisposition` answers "what does this rail value's consumer do —
measure / interior / …", then `measureOwnedInvariantRail` IS a special case of it and should be
re-expressed as a call to it.** That is a genuine Rule-14 obligation and I am flagging it rather than
guessing at a body I cannot see. It does not change the accept set either way — only which function
owns the sentence.

> ⚠⚠ **ERRATUM, 2026-09-15, loop-group merge+fix agent — THE PARAGRAPH ABOVE RESTS ON A FALSE
> PREMISE AND THE RULE-14 CHARGE IT RAISES DOES NOT STAND.** The premise is left in place above
> because deleting it would hide what was believed; this block is the correction, and it is landed
> here as well as in the review file because *a record correction that is not applied at the site is
> not a correction* (`CLAUDE.md` L7-with-a-twist).
>
> **`railValueConsumerDisposition` DOES exist on `main`, and it predates both branches.** Measured
> twice — once by the Rule-13 reviewer (`review_r13_loop/REVIEW.md` §I-3) and once independently at
> the merge, by this agent, against the ORACLE commit `74eabd2c` rather than against a worktree:
>
> ```
> git show 74eabd2c:ir-pass/src/LoopLowering.cpp   | grep -n railValueConsumerDisposition
>   242:RailValueUse railValueConsumerDisposition(        <- the definition
>   317:  996:  2255:  2685:                              <- four call sites
> git show 74eabd2c:ir-pass/src/OpcodeLowering.cpp | grep -n railValueConsumerDisposition
>   768:  // `railValueConsumerDisposition` (`LoopLowering.cpp`, by NAME), whose
> ```
>
> It is **not** declared in `LoopPlan.h` — it is file-local to `LoopLowering.cpp` — which is the most
> likely way a header-scoped or path-scoped `grep` missed it. ⚠ **The lesson is the grep, not the
> conclusion:** "grepped" is not a measurement unless the scope of the grep is stated with it
> (Rule 11 / Rule 19 — *report only what you ran*).
>
> **And the charge fails on the merits even if the premise had held**, so it is not merely unproven:
> `railValueConsumerDisposition` answers *"will this `BinaryOperator` be lowered as an IN-PLACE
> mutation of rail value `V`'s handle?"* — a question about an **OP's lowering disposition**, taking
> a `BinaryOperator *` and a rail `Value *`. `measureOwnedInvariantRail` answers *"is EVERY user of
> this value a `cq_measure`?"* — a question about a **VALUE's user set**, taking one `Value *`. They
> share no argument, no return type and no subject. `measureOwnedInvariantRail` is **not** a special
> case of it. **DO NOT MERGE THE TWO PREDICATES.**
>
> The near-neighbour the reviewer did check is `railIsInterior`, and that charge fails too, for the
> reason `measureOwnedInvariantRail`'s own header already gives in the source: the two have
> **OPPOSITE SAFE DIRECTIONS** on a non-`Instruction` user (`railIsInterior` `continue`s past one;
> this one REFUSES), so folding them would need a direction parameter — which is exactly how a shared
> predicate acquires a caller its argument does not reach (`CLAUDE.md` L3-mirror). The retirement
> trigger Track T wrote at that site is the right disposition and stands.

### (2) The interaction reading — **I AGREE, with one correction of scope**

S′: *"`tu9q` REPLACES this decline, it does not narrow it."* Agreed for the population this increment
reaches, and §5 gives the mechanism: every customer exits `declineDephasingUnmarkedLoopRails` at
**conjunct (1)** (`the body must be UNMARKED`) before conjuncts (2)/(3) are evaluated at all. ⚠ **The
correction: it replaces the decline for the ROOT-MINT and MEASURE-OWNED half only.** The hoisted
TEMPLATE-rail-read-as-data half (§6, §8, bd `1m5p`) still needs the fence, and needs it for the two
programs `loop_leak_dephase_reject_region_derivedbase_live.ll` and `s2_live_derived_region` pin. So
S′'s fence is not retired by this increment; its population is **reduced**, and what remains is
exactly what §6 says the next increment buys.

### (3) THE `cqrt_xorc` HAZARD — **the pairing cannot reach it, by TWO independent arguments**

S′'s hazard: *"treating a `cqrt_xorc_i32` as a rail would make the pairing emit an `_unc` +
`cqrt_free` for a rail that was never allocated"* — a Rule-6 violation by construction.

**(a) STRUCTURAL — an in-place relabel is not a rail VALUE, so no partition can select it.**
A dtzb in-place op lowers to `cqrt_{addc,xorc}_<W>(handle, imm)`, a **VOID** call: it produces no
`Value` at all, so it cannot be a candidate `Handle`. `ChainWalk::isInteriorTerminalHandle` opens
`dyn_cast<CallInst>(Handle)` and then requires `isTemplateProducer(H)` **and** a `cq_template_`-
prefixed callee — `cqrt_xorc_i32` is neither. The rail it RELABELS is the alloc-minted register,
which clause **(I1)** excludes from the interior partition outright. So there is nothing for an `At`
to be placed on, before any question of marking arises.

**(b) UNREACHABLE — a body this grant marks cannot contain one.** A dtzb in-place op on an SSA
register makes that register **loop-CARRIED**, i.e. it mints a tainted header phi. Two owners stand in
front of that, in order: `tryCaseA` claims such a loop (Case A) and `lowerLoops` `continue`s **before**
the new offer is reached; and if it does not claim, `railLocalQualifies` refuses at its
`TI && isa<PHINode>(I) && BB == Header` clause (*"an unclaimed loop-carried rail — no collapse ran"*).
Either way the round-1 root-mint grant is never made for a body containing one.

**WITNESSES, because (b) is an argument and arguments are what this project measures instead of
trusting:** `a5_inplace_on_invariant` (an in-place `y = y + 3` in the body — DECLINE, unmoved from the
ORACLE) plus two probes written for S′'s message specifically — `x1_xorc_inplace_in_body` (bd `2g52`'s
own `volatile` `z ^= v` shape, beside the measure-owned invariant read clause (ii-c) admits) and
`x2_xorc_plus_outofplace` (the same, plus a GENUINE out-of-place per-trip rail, so the trace can
answer *"did it discharge the relabel too?"* from what IS emitted rather than from an absence).
Measurements in `GATES.md`.

⚠ **And the standing obligation, which is the part to carry forward rather than the answer:** (a) is a
property of `isInteriorTerminalHandle`'s clause (I1) and of `cqrt_{addc,xorc}` being void, and (b) is a
property of `tryCaseA`/`railLocalQualifies`. **If the hoisted-template half (§6) is ever built, it
changes (I1)'s customers and it must re-derive BOTH** — that increment is the one that makes S′'s
hazard live, not this one.

---

## §13 — A BUILD FINDING THAT ALMOST BECAME A MEASUREMENT (record it, it is the third form of the trap)

⚠ **`cq-opt` SEGFAULTED ON A FOUR-INSTRUCTION MODULE WHILE `libCQPass.so`, BUILT FROM THE SAME
SOURCES IN THE SAME `cmake --build`, LOWERED IT CORRECTLY** — and `make` reported the tree UP TO DATE.

`CLAUDE.md` records the trap as *"`--target CQPass` ALONE leaves `cq-opt` stale and lit reports FALSE
GREEN"*, and bd `z9t1`'s session recorded the mirror (*"a stale `cq-opt` makes a FIXED program look
broken by hand"*). **This is a third form: the two targets DIVERGED inside a single incremental
build.** The mechanism is that `TaintSet` gained a member in the MIDDLE of the struct, so any object
compiled against the older header has every later field at the wrong offset — an ODR/layout mismatch
whose signature is a wild jump in an unrelated function (here `cq::lowerOps`, with a garbage
`_sigtramp` frame), not a clean assertion.

**The discriminator that found it in one command, and the one to reach for next time:** run the SAME
module through `cq-opt` and through `opt -load-pass-plugin libCQPass.so`. They are gated to be
byte-equivalent (`tools/cq_opt_equivalence.py`), so a disagreement between them is a BUILD fact, never
a lowering one. `make`'s "up to date" is not evidence: its dependency graph said so while one target
was broken.

⚠ **THE CONSEQUENCE FOR THIS TRACK'S OWN NUMBERS, stated rather than buried:** every measurement taken
with an incrementally-built `cq-opt` before the clean rebuild is suspect on principle, even the ones
that look coherent (the S1/S2 binaries did not crash and `lit` was 2038/2039 green, which is *evidence*
and not *proof*). **Everything in §2 and in `GATES.md` below the clean-rebuild line was re-measured on
the clean binary.** The fix was `rm -rf build/ir-pass/CMakeFiles/cq-opt.dir` + reconfigure + rebuild —
and note that deleting the dir removes `build.make`, so the reconfigure is not optional.
