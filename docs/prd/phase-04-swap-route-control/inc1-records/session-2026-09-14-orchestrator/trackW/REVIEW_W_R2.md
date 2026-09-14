# Track W — ADVERSARIAL REVIEW round 2 (Rule 13), bd `wx8g`

**Verdict: CLEAR-WITH-ITEMS.** Both round-1 over-ACCEPTs are fixed and the fixes hold under every
attack I built. **No new over-ACCEPT attributable to this increment was found.** Seven items: two
recorded justifications on Rule-13 fences that are measurably FALSE (one of them a mis-aimed
retirement trigger whose precondition is already met at HEAD), one scope sentence the new contract
needs, one latent lifetime class that is F-W1-1's shape one container over, one diagnostic-quality
regression, and two disclosures. Round 3 is warranted, but **not on this fix** — see §9.

**Reviewer:** independent; did not write this code and did not perform round 1. **Date:** 2026-09-14.
**Probes:** `$SES/trackW/review_r2_probes/` — 56 `.c`, three harnesses (`rv2.sh`, `rv2multi.sh`,
`rv2link.sh`), 45 traces / 45 lowered `.ll` / 31 stderr captures. Kept strictly separate from
round 1's PRE-fix `review_r1_probes/` (CLAUDE.md L8); every artefact carries an `.r2sub` / `.r2ora`
infix so the two generations cannot collide under one name.

---

## 0. Binary check — FIRST ACT, both match the brief exactly

```
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_wx8g/build/ir-pass/{cq-opt,libCQPass.so}   # SUBJECT
40edde36678c7dd4937b63b017700804fad90feeb33263742d3e1b29170b994d  …/cq-opt
e82fe15c6aae983ef397873e7c344c72730aba3f213e248ca1c52267e2d07bd0  …/libCQPass.so
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}   # ORACLE
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  …/cq-opt
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  …/libCQPass.so
$ git -C /Users/sorenwilkening/Desktop/CQ_wx8g rev-parse HEAD
1dee47e2c1220bc3ea911679138cd720fd1221c0
```

All four match `REVIEW_BRIEF_W_R1.md` / the round-2 brief. **No build, no `ctest`, no corpus sweep,
no twin matrix, and — unlike round 1 — ZERO `lit` invocations** (the one allowance is unused). Every
verdict below is a `cq-opt` run on a `.ll` produced by `clang -O1 -g` from a committed probe, or a
direct `cq-opt` run on a committed fixture.

---

## 1. Round 1's two over-ACCEPTs — fixed, and the fixes hold under attack

I re-derived both rather than inheriting them.

### 1.1 F-W1-1 (`Diagnosed` outliving its `LoopInfo`) — CLOSED, and the two-set split is necessary

The fix is right on both halves. `AskedEscape` / `AskedMarking` are declared **inside** the
`for (Function &F : M)` body beside the `DominatorTree`/`LoopInfo` that own the `Loop` objects, and
keyed on `L->getHeader()` — a `BasicBlock *`, which outlives the analysis.

**The split's stated reason is CORRECT and I verified the mechanism, not the prose.** With one shared
set the dedup would be `if (!Asked.insert(Hdr).second) continue;` at the top of the entry body, and
because conjunct 1 is now clause-(c)-only, a (b′) entry reaching that line first consumes the slot and
the (c) entry's conjunct 1 is never asked — the same suppression one level down. Note the short-circuit
in `if (G.IterationLocal && AskedEscape.insert(Hdr).second)` is load-bearing: a (b′) entry must not
consume `AskedEscape`, and it does not.

**The only shape in which the split can matter is ONE LOOP carrying entries with different bits**, and
it exists. `w2b_sameloop_mixed.c` — a loop with a (b′) grant (the carried `r`, alloc'd in the
preheader, rotated in place under the loop-invariant `_Bool` `b`) **and** a (c) grant (the
iteration-local `w` under the per-trip `_Bool` `t`):

```
$ ./rv2.sh sub w2b_sameloop_mixed w2b_sameloop_mixed_un w2b_sameloop_mixed_derived w2b_sameloop_mixed_derived_un
w2b_sameloop_mixed          |r2sub|ACCEPT|lines=22
w2b_sameloop_mixed_un       |r2sub|ACCEPT|lines=22      ← BYTE-IDENTICAL
w2b_sameloop_mixed_derived  |r2sub|ACCEPT|lines=38
w2b_sameloop_mixed_derived_un|r2sub|ACCEPT|lines=38     ← BYTE-IDENTICAL
$ ./rv2.sh ora w2b_sameloop_mixed w2b_sameloop_mixed_derived
… |r2ora|DECLINE|control flow inside a loop body    (both)
```

The lowered IR confirms the two clauses coexist in ONE rolled loop
(`w2b_sameloop_mixed.r2sub.ll`): `%h2 = cqrt_alloc_i32(7)` in the **preheader** with
`cqrt_ry_i32_controlled(%h, %h2, 0.3)` inside the body (the (b′) carried rail), and
`%h3 = cqrt_alloc_i32(3)` minted **inside** the body with `cqrt_ry_i32_controlled(%h1, %h3, 0.2)`
(the (c) iteration-local one), under one `br label %2` / `br i1 %10, label %2` back edge. Both are
new capability and both are twin-identical.

### 1.2 F-W1-2 (the record at one clause only) — CLOSED, and I could not find a grant that misses it

The `push_back` now sits on the far side of `if (!Rollable) { decline; return; }` inside
`ArmClassify`'s `if (Region.InLoop)` block. I attacked the claim *"a new clause cannot be added
without passing through it; the only way to miss it is a decline"* three ways:

* **Structurally.** The block is inside `if (CallInst *T = inPlaceRotationArmTheta(…))`, ABOVE R6's
  user scan and above the `Region.ClassArm = InPlaceRotation` / `Region.setRoutedBase` / `continue`.
  Every path out of it is either the `push_back` or a `declineArm` + `return Declined`. The per-ARM
  `continue` means an if/else with two rotation arms writes **two** records; the dedup absorbs that.
* **Can `Region.InLoop` be false for a region inside a loop?** No: `ControlDetect.cpp:630-636` is
  `if (regionEntryInLoop(BI)) { if (!LI || !flatRegionRollableInLoop(R, *LI)) decline; R.InLoop = true; }`
  — set-or-decline, with a reducibility-independent cycle walk, not a `LoopInfo` query.
* **Is the `StatePrep` class covered?** Yes, same block, `MintSeed = T`. Measured:
  `w2e7_stateprep` ACCEPT 9, twin-identical.

**I found no R7 grant path that reaches an accept without the record.** The grant paths that reach an
accept without a record are the ones R7 does not own, and they leak — that is F-W2-3, and it is
pre-existing.

### 1.3 The F-W1-3 exclusion / `offset.ll` coupling (the brief's item 3) — sound, and I probed around it

* **The exclusion does not rescue a loop that has a real candidate.** `w2l_inplace_plus_chain.c` — the
  dtzb in-place `q += 3` **plus** a per-trip `(u>>1)&1` chain, marking refused — **DECLINES** at
  `:12:20` (the hoisted gate, i.e. conjunct 2). The exclusion removes one instruction from the scan,
  not the scan.
* **The `offset.ll` shape is unmoved by the increment.** `w2c_inplace_cmp.c` (the compare-condition C
  analogue: `for (…) { if (q==5) r = cq_theta(r,.9); q = q+3; }`) is **byte-identical between SUBJECT
  and ORACLE** at 17 trace lines. Its flat twin declines `condition measured before the control route`
  on both, so there is no oracle twin for that spelling — which is why I dated the coupling a
  different way (F-W2-6).
* **Could an excluded kind still need the marking?** The five excluded kinds mint no
  `cq_template_*` rail. The one I could not dismiss on paper — an `InPlaceRailOps` member — is
  reachable in a loop only as a dtzb-claimed *carried* value-rail self-update
  (`collapseRailPhisIn` step 3), and `w2c_inplace_rail` / `w2c_inplace_cmp` show the rolled body then
  contains no template rail at all. The residual risk is not the *kind*, it is the *container*
  (F-W2-4).

---

## 2. F-W2-1 — RECORD ACCURACY, and it is a MIS-AIMED RETIREMENT TRIGGER whose precondition is ALREADY MET

**Severity: record accuracy on a Rule-13 fence + L8. Behaviour is unaffected; the conclusion survives
with a much smaller margin than the comment claims.**

`bodyHasSpineDischargeCandidate`'s header (`LoopLowering.cpp:3788-3791`) says, in full:

> *"The set is also FINAL here: its only `erase` is `invariantRegisterRoots`' rollback, **inside
> `lowerLoops`**, which runs before this stage in both entry points (RETIREMENT TRIGGER: a new
> `markInPlaceRailOp`/`erase` site **after `lowerLoops`** makes this read a set that is still moving)."*

Measured, both halves are false as written:

```
$ grep -rn 'markInPlaceRailOp(\|invariantRegisterRoots(' ir-pass/src/LoopLowering.cpp
  192: void markInPlaceRailOp(…)                    ← the helper
 1766: markInPlaceRailOp(BO, taint);                ← in emitBreakForward      (from lowerLoops)
 2349: markInPlaceRailOp(BO, taint);                ← in tryCaseA              (from lowerLoops)
 2747: markInPlaceRailOp(BO, taint);                ← in collapseRailPhisIn    ← NOT lowerLoops
 3479:   taint.InPlaceRailOps.erase(I);             ← in invariantRegisterRoots
 3689/3694: invariantRegisterRoots(…)               ← in collapseFlattenedLoopRails
```

`collapseRailPhisIn` and `invariantRegisterRoots` are both called from **`collapseFlattenedLoopRails`**,
which runs at `CQLoweringPass.cpp:473` (round 1, **after** `lowerLoops` at `:373`) **and again as the
LAST STATEMENT of `repropagateControlMerges`** (`TaintPropagation.cpp`, the 3qlq F-R1-1 onward
loop-rail pass). So:

* a `markInPlaceRailOp` site after `lowerLoops` **already exists** — two of them, one at round 2;
* the erase likewise fires at round 2;
* a future reader who checks the trigger against the code answers *"no such site"* from the comment and
  *"yes, two"* from `grep`. That is the L8 failure mode inverted: a trigger that reads as unarmed when
  it is already armed.

The **conclusion** — "final by the time `declineUnmarkedRolledIterLocal` reads it" — still holds, because
the round-2 collapse is the last statement of `repropagateControlMerges` and the re-ask is three
statements later (`reverifyRailCondReads`, `reverifyCmpCondReads`, then the re-ask). But the margin is
*three statements*, not *a whole stage*, and the comment tells a reader the opposite.

**Minimal fix (comment only, no binary movement — the implementer has already measured that a
comment-only rebuild is bit-identical):** restate the boundary as `declineUnmarkedRolledIterLocal`'s
own slot, and name the round-2 `collapseFlattenedLoopRails` call inside `repropagateControlMerges` as
the LAST writer. Trigger becomes *"a `markInPlaceRailOp`/`erase` site added between that call and this
stage"*.

---

## 3. F-W2-2 — the "by construction" claim protecting the conjunct asymmetry is MEASURABLY FALSE

**Severity: record accuracy / CLAUDE.md L7 (an agent-authored justification hardening into a rule).
The CODE is right; the stated REASON is not, and a future widening leaning on it would be unsound.**
This is the brief's item 4: *break it or confirm it.* **Broken.**

The claim appears three times (`LoopLowering.cpp:3949-3953`, `TaintPropagation.h`'s contract,
`FIX_W_R1.md`), in these words:

> *"NOT ASKED OF A (b)/(b′) ENTRY, and the reason is definitional rather than cautious: (c3) refuses
> when anything tainted defined in `L` is read outside `L`, and a loop-**CARRIED** rotated register is
> read outside `L` — that is what 'carried' means."*

**Counter-example, measured: `w2b_sameloop_mixed.c` (§1.1).** That module ACCEPTS. Acceptance requires
the clause-(c) grant, and clause (c3) is `iterationLocalTaintEscape(L, Taint) == nullptr` — a **∀ over
the whole loop**, not over one register. So (c3) held for that loop. And `r`, the (b′) carried register,
is a tainted header φ **defined in `L`** whose only users (the arm's `cq_theta`, the merge φ, a
`cq_measure`) are **all inside `L`** — it is `cq_measure`d every trip and never read after the loop.
`iterationLocalTaintEscape` has no φ exemption (`LoopLowering.cpp:3714-3730`, verified by reading the
whole body). Therefore a loop-carried register that (c3) does **not** refuse exists, and "carried ⇒
read outside `L`" is false. A loop-carried accumulator measured each trip is an ordinary shape, not a
contrivance.

**Why the code survives anyway** — and this is the sentence that should replace the false one.
Conjunct 1 re-asks a premise that **only clause (c) ever had**: (b′)'s round-2 re-ask is the *collapse
itself*, which declines loudly with `kMsgCrossIter` when the header φ is not claimable
(`ArmClassify.cpp`'s own (b′) note says so). In every case where conjunct 1 *would* decline a (b′)
entry, (c3) fails because something tainted defined in `L` escapes — which for a carried shape is
normal and is not what (b′) proved. So the asymmetry is sound; it is sound for a reason about
*premises*, not about what "carried" means.

**Minimal fix (comment only):** delete the definitional lemma at all three sites and state the premise
argument. Keep the second half of the sentence — *"asking it there would decline every shipped drbq
Inc-3 in-loop arm"* — which I did not falsify: in every shipped/probed (b′) shape I built
(`w2c_inplace_cmp`, `offset.ll`'s C analogue, `d1`) the carried register IS measured after the loop.

---

## 4. F-W2-3 — "the record must be at EVERY grant" is implemented for every **R7-loop** grant, and the leak class is REGION-INDEPENDENT

**Severity: PRE-EXISTING over-ACCEPT / silent miscompile (three measured programs, all byte-identical
on the ORACLE). Out of this increment's scope, adjacent to its contract, and it is where the next
silent miscompile lives.**

`TaintSet::RolledLoopRegionGates`' contract says the record covers *"**every** clause, (b)/(b′) and (c)
alike"* and cites L1's *"the record must be at EVERY grant site — a second grant clause added without a
`push_back` here re-opens the window with NO DIAGNOSTIC ANYWHERE."* That is exactly true of the R7-loop
grant. A later reader will read it as *every in-loop grant*. It is not, and the difference is measurable.

The mechanism conjunct 2 exists to catch — `markIfRailLocal` **refusing** the marking, so the body's
per-trip `cq_template_*` rails are never `_unc`-ed and never freed — is triggered by
`markIfRailLocal`'s *"accumulating loop-invariant tainted input"* clause (`LoopLowering.cpp:3547-3553`)
and has **nothing to do with the region**. Three programs, each rolled against its hand-unrolled twin:

| probe | rolled | twin | leaked per program | SUB vs ORA |
|---|---|---|---|---|
| `w2h_phase_inloop_invread.c` — an in-loop **PHASE** region (8h7d.5), no record | ACCEPT **30** | **38** | `and_unc` 2 vs 6, `lshr_unc` 0 vs 2, `cqrt_free` 2 vs 6 — **4 entangled which-path rails** | **byte-identical** |
| `w2h3_select_iterlocal_invread.c` — an in-loop **4.4 data select**, no record | ACCEPT **44** | **48** | `cq_template_lshr_i32_hl_unc` + `cqrt_free` ×2 | **byte-identical** |
| `w2k_noregion_invread.c` — **NO tainted control flow at all** | ACCEPT **16** | **20** | `cq_template_lshr_i32_hl_unc` + `cqrt_free` ×2 | **byte-identical** |

```
$ ./rv2.sh sub w2k_noregion_invread w2k_noregion_invread_un ; ./rv2.sh ora w2k_noregion_invread
w2k_noregion_invread    |r2sub|ACCEPT|lines=16| … 0 violation(s), 0 unproven
w2k_noregion_invread_un |r2sub|ACCEPT|lines=20| … 0 violation(s), 0 unproven
w2k_noregion_invread    |r2ora|ACCEPT|lines=16|  (SUB == ORA byte-for-byte)
```

`w2k` is the cleanest statement of the root and it needs **six lines of C**: a bounded loop, one
per-trip derived chain, and one read of a loop-invariant tainted register. `opt` exit 0, verify-clean,
STRICT stage 2b `0 violation(s), 0 unproven` — structurally blind, as `free_pairing_check.py`'s own
header says. This is bd `1m5p`'s class-A neighbourhood stated at its root, and it is the same
refusal-clause the 3qlq C-1 "MIXED LOOP" fix addressed for the *direct* read of an invariant register
(`invariantRegisterRoots`); a read **through a derived op** (`y & 1`) still refuses.

**What this increment did right:** for the R7 slice of that class it converted a silent leak into a
loud decline. **What it should say:** one sentence in the `RolledLoopRegionGates` contract scoping
"every grant" to "every R7-loop grant", and naming the in-loop phase / select / no-region forms as an
open bead. `markIfRailLocal`'s refusal is a **leak, not a decline** — that is the thing to fix, and
fixing it also retires F-W2-7.

---

## 5. F-W2-4 — the THIRD level the brief asked for: F-W1-1's class is closed for `Loop *` and OPEN for the two containers conjunct 2 now reads

**Severity: latent over-ACCEPT, UNCONSTRUCTED. Reported because it is F-W1-1's exact shape one
container over, and because the fix introduced one of the two consumers.**

Closed, measured:

```
$ grep -rn 'SmallPtrSet<\(const \)\?Loop \*\|DenseMap<.*Loop \*\|SmallVector<\(const \)\?Loop \*' ir-pass/src ir-pass/include
Uncomputation.cpp:1651:    SmallVector<Loop *, 4> IterLoops;
Uncomputation.cpp:1652:    DenseMap<Loop *, SmallVector<CallInst *, 4>> IterByLoop;
```

Both are declared **after** `LoopInfo LI(DT)` inside the same per-function body (read at
`Uncomputation.cpp:1638-1663`) — correctly scoped. There is no third `Loop *` hazard.

Open. Conjunct 2 makes its accept decision by **positive membership** in two raw-pointer sets, neither
of which is ever scrubbed when its subject is erased:

* **`taint.IterationLocalBlocks`** (`SmallPtrSet<const BasicBlock *, 8>`).
  `grep -rn 'IterationLocalBlocks\.\(erase\|clear\)' ir-pass/src ir-pass/include` → **nothing**.
  `RegionFlatten.cpp` erases arm/cond/merge blocks at 7 sites, and it runs again at ROUND 2 inside
  `detectAndLowerOnwardControl`, i.e. **after** the round-1 `collapseFlattenedLoopRails` marking. A
  recycled `BasicBlock *` makes `Marked` stay TRUE for a block that was never marked → accept.
  `repropagateControlMerges` already reasons about exactly this for `Round1FlattenedPreds` and argues
  the direction there is safe; for conjunct 2 the direction is **not** safe.
* **`taint.InPlaceRailOps`** (`SmallPtrSet<Instruction *, 4>`; only `erase` is the rollback). Its NEW
  consumer uses membership to **SUPPRESS a safety check**, with no re-verification at that site —
  `lowerOps`' two tripwires run later and ask a different question about a different instruction. A
  recycled `Instruction *` silently excludes a real candidate.

I did **not** construct either exploit and I say so plainly; both are allocator-dependent in exactly the
way F-W1-1 was (and F-W1-1 reproduced on four `LoopInfo` instances in one module, so the tree's
allocator does recycle). **Minimal fix, cheap either way:** make the two containers `WeakTrackingVH`-
keyed, or scrub them at the erase sites `LiteralIntegrity.cpp` already centralises.

⚠ Related hygiene note, not a finding: the F-W1-1 regression fixture
`control_inplace_ry_reject_inloop_iterlocal_twofn.ll` declined **pre-fix only because addresses were
recycled** across four `LoopInfo` instances (its `@main` carries both loops inlined, so even the
in-function axis had to alias). Post-fix its decline is structural, so it is a sound *forward* pin; but
as a *regression* detector against re-introducing a module-scoped set it is only as good as the
allocator. Worth one sentence in the fixture header.

---

## 6. F-W2-5 — a decline at `<unknown>:0:0` that the ORACLE reports with a real source anchor

**Severity: Rule-1 diagnostic quality, user-facing, NEW on this binary for the modules I built.**

Built through the **shipped two-TU `llvm-link` 6.5 recipe** (`tests/e2e/run_slice_multi.sh`: per-TU
`clang -O1 -g -emit-llvm`, `llvm-link`, one `cq-lowering`), with `-g` on:

```
$ ./rv2link.sh sub w2i2_h1_round2 w2i2_lib
w2i2_h1_round2|r2sub|DECLINE|cq controlled lowering: condition predates a non-diagonal gate …|   ← NO anchor
$ cat w2i2_h1_round2.r2sub.err
error: <unknown>:0:0: in function slice i32 (): cq controlled lowering: condition predates a non-diagonal gate under quantum control
$ ./rv2link.sh ora w2i2_h1_round2
w2i2_h1_round2|r2ora|DECLINE|control flow inside a loop body|./w2i2_h1_round2.c:16:18   ← LOCATED
```

Same on the compare-condition spelling `w2i3_h1_cmpcond.c` (SUBJECT `<unknown>:0:0`, ORACLE
`./w2i3_h1_cmpcond.c:17:15`). The increment's widening lets the module travel past the loop gate to the
**2c condition-wire fence**, whose anchor carries no `!dbg`.

This is verbatim the class this increment's own source names — `declineUnmarkedRolledIterLocal`'s
comment says *"a diagnostic that loses its `!dbg` reports `<unknown>:0:0` and is INVISIBLE to every gate
this project runs except a full-stderr hash — one shipped past a green 1946-fixture lit run … (Track P,
2026-09-14)"* — and the implementer added the anchor-of-last-resort fallback at conjunct 1 while the
same defect is live at the 2c site the widening now routes traffic to.

**Honest limit:** I did not establish that the anchorless 2c decline is unreachable on the ORACLE by
some other module; one flat attempt (`w2i4_flat_2c.c`) ACCEPTS on both binaries at 19 lines. What is
measured is that **on these two modules the SUBJECT loses a source location the ORACLE had.**
**Minimal fix:** the same fallback pattern at the 2c decline site — anchor on the offending gate when
the condition has no `!dbg`.

---

## 7. Two disclosures

### F-W2-6 — a NEW CUSTOMER for bd `a3z7`, and I dated it

`w2c_inplace_rail.c` (bare-`_Bool` rail region + a dtzb in-place `q += 3`) is **ORACLE DECLINE →
SUBJECT ACCEPT 14**, and it **diverges from its hand-unrolled twin** at the same 14 lines:

```
rolled                          twin
cqrt_addc_i32(h1, 3)            cq_template_add_i32_hl(h1, 3) -> h3
cqrt_measure_i32(h1)            cqrt_measure_i32(h3)
cqrt_addc_i32(h1, 3)            cq_template_add_i32_hl(h1, 6) -> h4
cqrt_measure_i32(h1)            cqrt_measure_i32(h4)
```

**Dated, so it is not attributed here by default:** the identical substitution reproduces
byte-for-byte **on the ORACLE with no control region at all** — `w2c_noregion_inplace.c`
(`for (k<2) { q = q+3; s += cq_measure(q); }`), 6 lines rolled vs 6 flat, same divergence on BOTH
binaries. That is bd `a3z7` class B (*"the M-C in-place-vs-out-of-place decision on a trailing
`a += off`"*) exactly: pre-existing and arm-class-independent. Note the **rolled** side is the better
circuit here — the flat twin is the one leaving two rails unreversed — so this is not an over-accept.
It is a new customer for a quarantined divergence and `FIX_W_R1.md` does not mention it.

### F-W2-7 — `d3`'s residual is an over-DECLINE and is not filed

Re-measured on this binary: `w2g_mut_d3_invread` (a byte-copy of `d3_invariant_read.c`) **DECLINES**,
its hand-unrolled twin **ACCEPTS at 34**; the one-token sibling `w2g_mut_d1_no_invread` ACCEPTS at 32
and is **byte-identical** to its twin. So the fixture's verdict is caused by exactly the token it
claims (mutation control, Rule 12(c)) — but under the owner's 2026-09-11 ruling the residual is an
**over-decline**, because the twin proves a valid circuit exists. `FIX_W_R1.md` files `d4` against bd
`1m5p` and does not file `d3`. F-W2-3 shows the same marking refusal is a silent **leak** everywhere
outside R7, which is the stronger reason to fix `markIfRailLocal` rather than to live with the decline.

**Recorded so it is not re-chased (pre-existing, NOT this increment's):** `w2e3_xor_on_rotated.c`
(`s += cq_measure(r ^ 5)` after an in-loop rail Ry arm) declines
`cq opcode lowering: operand predates a non-diagonal gate` at `:9:14` — **identically on the ORACLE, at
the same anchor** — while its flat twin ACCEPTS at 12 lines. `declineStaleRecordOps` never received
R6's per-activation certificate (`recordLivePerActivation`). bd `3d8q` neighbourhood.

---

## 8. What I confirmed and could NOT break

* **The two-loops-in-ONE-function axis** (the brief's item 6: the three new fixtures are two
  FUNCTIONS). `w2a_twoloop_pass_fail` **DECLINE** `:18:31`, `w2a_twoloop_fail_pass` **DECLINE** `:8:31`
  (order-independent), `w2a_twoloop_passonly` **ACCEPT 28 and byte-identical** to its twin. Both
  anchors are the hoisted gate = conjunct 2, not the classifier. *(Incidentally the shipped twofn
  fixture's `@main` already carries both loops inlined, so the axis is covered there too — which the
  fixture header does not say.)*
* **Three functions, failing kernel THIRD** (round 1 built it second): `w2j_threefn_fail_third`
  **DECLINE** `:19:31`. **Both-passing two-kernel control**: `w2j_twofn_passonly` **ACCEPT 28**
  (ORACLE DECLINE) — so the twofn fixture's decline is caused by the failing kernel, not the module
  shape. Mutation control, Rule 12(c).
* **The newly-admitted family is twin-identical, 10 for 10, and EVERY ONE is a new accept.**
  `w2e1_two_chains` 36=36 · `w2e2_measured_template` 16=16 · `w2e4_two_rail_regions` 13=13 ·
  `w2e5_negated` 10=10 · `w2e7_stateprep` 9=9 · `w2e8_inner_classical_loop` 8=8 · `w2g_mut_d1` 32=32 ·
  `w2b_sameloop_mixed` 22=22 · `w2b_sameloop_mixed_derived` 38=38 · `w2a_twoloop_passonly` 28=28.
  `./rv2.sh ora` on all ten: **ORACLE DECLINE `control flow inside a loop body`, every one** →
  SUBJECT ACCEPT, byte-identical to its hand-unrolled twin.
* **K-independence of the rolled form.** `w2f_kindep.c` at `CQ_K` = 3 / 7 / 1000: **135 lowered lines,
  1 `cqrt_ry_i32_controlled` call site, 3 `cqrt_alloc` call sites** at every K, `opt` exit 0
  (`grep -c 'call void @cqrt_ry_i32_controlled'` / `grep -c 'call i32 @cqrt_alloc'`, not the declares).
* **H-1, the residual NEITHER the implementer NOR round 1 built** — a clause-(c) loop whose second
  tainted branch exists only at round 2. Built in two spellings on the shipped two-TU 6.5 recipe
  (`w2i2_h1_round2.c` bare-`_Bool`, `w2i3_h1_cmpcond.c` compare). **Both DECLINE on the SUBJECT** — at
  the **2c condition-wire fence**, and structurally so: a loop-invariant `%out` condition read every
  trip, in a loop firing a non-diagonal gate every trip, is precisely what 2c refuses. **H-1 is not
  reachable through the 6.5 `%out` route.** Conjunct 1 itself therefore remains un-exercised; other
  round-2 taint-growth routes (`MergePhiPeel`'s clones, a 4.5 switch data-mux) were not attempted.
* **The composition with Track M in a loop** (`w2e9_prep_then_select.c` — an in-loop bool-controlled
  prep whose merge φ conditions a 4.4 select) DECLINES `control flow inside a loop body`; its flat twin
  declines `value-arm swap-route`. No over-decline claim available (no oracle twin); recorded as a
  residual for bd `ej5w`/`xdu2`.

---

## 9. What I did NOT examine

* **Every layer the brief excluded**: full `ctest`, the `^e2e-` layer, `cq-opt-equivalence-full`, the
  twin matrix (338 cells), the corpus sweep. ⚠ Note the ORACLE-vs-SUBJECT corpus sweep in `GATES.md`
  is `cited:` for the **pre-fix** binary `95a33b2e` only, and the fix moved the binary twice since; the
  (b′) widening is a DECLINE-direction change, so the merge gate's sweep is the first one that covers
  it. The implementer's full `ir-pass-lit` (1940 pass) and the 33-slice targeted golden byte-diff are
  what stand for it today.
* **The injection matrix and the vacuity instrument.** I deliberately did not inherit any vacuity
  verdict (the brief's item 7 — the implementer measured 2 false `VACUOUS` against a 6-module
  universe); instead I mutation-validated the two new DECLINE fixtures directly (§7, §8) and confirmed
  each flips to ACCEPT when its stated cause is removed.
* **`railChainRootMint`'s byte-for-byte equivalence** to `railPhiRootMint`'s old tail — unexamined in
  both rounds.
* **The F-W2-4 address-recycling exploit** — argued, not constructed.
* **Whether the anchorless 2c decline (F-W2-5) is reachable on the ORACLE** — one attempt, inconclusive.
* **The `runOnFunction` shim** (round 1's F-W1-4) — zero callers; I accepted round 1's reading.

---

## 10. Verdict, ranked findings, and round 3

**CLEAR-WITH-ITEMS.**

| # | finding | severity |
|---|---|---|
| **F-W2-3** | The leak class conjunct 2 catches is REGION-INDEPENDENT; three measured programs (in-loop phase, in-loop select, and a loop with NO control flow at all) leak 2–4 rails per program with no record and no re-ask. **All byte-identical on the ORACLE — pre-existing, not this increment's population.** The contract's "every grant" needs scoping to "every R7-loop grant". | pre-existing over-ACCEPT / silent miscompile |
| **F-W2-5** | A decline at `<unknown>:0:0` (2c fence) on two `-g` modules the ORACLE declines with a real source anchor — the Track P class, live at the site this widening routes traffic to. | Rule-1 diagnostic quality, NEW |
| **F-W2-1** | The `InPlaceRailOps` finality claim and its RETIREMENT TRIGGER are factually wrong: the insert and the erase both already fire after `lowerLoops`, from `collapseFlattenedLoopRails`, including at round 2. Conclusion survives; the stated boundary does not. | record accuracy / L8 |
| **F-W2-2** | *"(c3) refuses every loop-CARRIED shape by construction"* is FALSE — `w2b_sameloop_mixed` is a loop where (c3) holds and a carried register is measured only inside. The code is right for a different reason (premises, not the meaning of "carried"). | record accuracy / L7 |
| **F-W2-4** | F-W1-1's lifetime class is closed for `Loop *` and OPEN for `IterationLocalBlocks` and `InPlaceRailOps` — both raw-pointer sets, never scrubbed, both read by conjunct 2 in the ACCEPT direction, one of them a NEW consumer. Unconstructed. | latent over-ACCEPT |
| **F-W2-6** | A newly-accepted program diverges from its twin on the M-C in-place/out-of-place decision. DATED to bd `a3z7` by a no-region control that reproduces byte-for-byte on the ORACLE. | disclosure |
| **F-W2-7** | `d3`'s residual is an over-DECLINE (twin ACCEPTs at 34) and is not filed; the pre-existing `w2e3` over-decline is recorded so it is not re-chased. | bookkeeping |

### The carve-out retirement, now that §2.1a's supporting claim is retracted — my independent judgement

**The retirement is correct and I would land it.** Its remaining support is narrow but it is the right
narrow: a bare `_Bool` condition really does mint nothing and derive nothing, which I attacked in
§1.1/§8 through ten byte-identical twin pairs (all ten ORACLE-DECLINE → SUBJECT-ACCEPT), a chained per-trip
condition rail, a negated arm, an in-loop state prep, a strictly-deeper classical loop, and
K-independence at K=1000 — and could not break. The retired carve-out was never the fence anybody
thought it was: for `w2e3_xor_on_rotated` the ORACLE declines *earlier*, at `declineStaleRecordOps`,
with the same string and anchor as the SUBJECT — the carve-out was a scope boundary sitting in front of
fences that were already doing the work.

**But the honest form of the safety argument is not "the condition mints nothing".** It is: *"the
condition mints nothing, AND every in-loop leak the body can mint is caught by the marking
postcondition."* The second conjunct is the one that does the work, it is the one F-W1-2 showed was
half-wired, and §4 shows it is wired for the R7 slice of a class that is region-independent. So I would
state the retirement's ground as **"the fence is the marking postcondition, and the condition kind is
irrelevant to it"** — which is both true and the sentence that would have predicted F-W1-2 instead of
being falsified by it. With that framing the increment is internally consistent; with the §2.1 framing
it is one more measurement away from another retraction.

### Is round 3 warranted?

**Yes — but not on this fix.** Nothing in §2–§7 is an over-ACCEPT this increment introduced; F-W2-1,
F-W2-2 and the F-W2-4 mitigation are **comment and container changes**, and F-W2-5 is a one-site anchor
fallback of a pattern the tree already owns. A round on that surface would spend the third budgeted
round re-reading prose.

The budgeted round is better spent on **F-W2-3**, which is where this project's next verify-clean
silent miscompile already is: `markIfRailLocal`'s *"accumulating loop-invariant tainted input"* refusal
is a **leak, not a decline**, six lines of ordinary C reproduce it with no quantum control flow at all,
and `opt` exit 0 / verify-clean / STRICT stage 2b `0 violation(s)` on both sides. That work also
retires F-W2-7 and removes the reason conjunct 2 has to exist in its present form.

**Recommendation to the merge gate:** land the fix with the four comment/anchor repairs
(F-W2-1, F-W2-2, F-W2-5, the fixture-header sentence in §5), file F-W2-3 / F-W2-4 / F-W2-6 / F-W2-7 as
beads, and run the session's one corpus sweep against `40edde36` rather than citing the `95a33b2e` one
— the (b′) widening is decline-direction and that sweep predates it.
