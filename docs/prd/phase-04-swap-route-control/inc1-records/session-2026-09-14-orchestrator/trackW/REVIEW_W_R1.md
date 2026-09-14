# Track W — ADVERSARIAL REVIEW round 1 (Rule 13), bd `wx8g`

**Verdict: NOT CLEAR.** Two over-ACCEPTs (one of them a reproducible silent miscompile on ordinary
two-kernel C with no attributes), three measured over-DECLINES sharing one root cause, and one
record-hygiene item. Round 2 is warranted and its scope is given in §6.

**Reviewer:** independent; did not write this code. **Date:** 2026-09-14.
**Probes:** `$SES/trackW/review_r1_probes/` (41 `.c`, harness `rv.sh`, 79 trace/IR/stderr artefacts).

---

## 0. Binary check — FIRST ACT, both match the brief

```
$ shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so                     # MAIN = ORACLE
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  build/ir-pass/cq-opt
f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d  build/ir-pass/libCQPass.so
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_wx8g/build/ir-pass/{cq-opt,libCQPass.so}   # SUBJECT
daeb93a36bdc57b3cbb769eaf88bb71c784671989747a2b582bbc50e352308d2  …/cq-opt
2f7ed0a69fbda48dcead831db242ced39da0209ad731fd1bf6e5178b97152090  …/libCQPass.so
```

Both identical to `REVIEW_BRIEF_W_R1.md`. Subject tip `11fc1b3c33ae9b14cecd7ec5c6b120e606ff9d9d`.
No build, no suite, no corpus sweep, no twin matrix were run. **One** lit invocation was used, as a
control on the gated binary:

```
$ cd /Users/sorenwilkening/Desktop/CQ_wx8g/build && lit ir-pass/test --filter 'inloop_iterlocal|rail_inloop'
Passed: 26 (26 of 26)   Testing Time: 1.77s
```

Every finding below is invisible to those 26.

---

## 1. Claimed witnesses — verified on a sample (Rule 11), not restated

| pair | claim | my measurement |
|---|---|---|
| `w_a_carried_bool` (`v1_wa`) | rolled == unrolled, 8 lines | **BYTE-IDENTICAL**, 8 = 8 ✓ |
| `w_g_derived_cond_iterlocal` (`v2_wg`) | rolled == unrolled, 27 lines | **BYTE-IDENTICAL**, 27 = 27 ✓ |
| `w_j_no_invariant_root_derived` (`ctl_wj`) | DECLINE at conjunct 2, anchor `13:31` | **DECLINE**, `./ctl_wj.c:13:31` ✓ |
| `w_i_no_invariant_root` (`ctl_wi`) | ACCEPT, 14 lines | **ACCEPT**, 14 ✓ |
| ORACLE refuses the whole rail-in-loop family | — | `v1_wa`/`a1`/`a2`/`d1`/`d3` all DECLINE `control flow inside a loop body` on `f7b65d8c…` ✓ |

I also built two shapes the implementer did not, both of which the retirement is right about and both
of which are **new, correct** capability — reported so the record is not one-sided:

* `a1.c` — an **iteration-local CONDITION rail** (`bool b = cq_theta(…)` minted per trip) beside a
  loop-carried rotated register. ORACLE DECLINE → SUBJECT ACCEPT, 9 lines, **byte-identical** to
  `a1_un.c`.
* `a2.c` — the condition rail **chained per trip** (`b = cq_theta(b,.1); if (b) r = cq_theta(r,.2);`).
  ORACLE DECLINE → SUBJECT ACCEPT, 10 lines, **byte-identical** to `a2_un.c`; stream is
  `ry_i1(h0,.1); ry_i32_controlled(h0,h1,.2)` ×2, no ancilla, no `cqrt_x`, no free.

The per-activation fences also hold where I attacked them: `c2_measure_after.c` (the rail condition
measured in the body *after* the region — positionally later, per-activation earlier) declines
`condition measured before the control route` **rolled and unrolled alike**; `c3_rotate_after.c`
(the condition's wire rotated after the region) declines `control flow` rolled, because the trip-2
condition is a header φ and not a rail leaf.

---

## 2. F-W1-1 — over-ACCEPT / SILENT MISCOMPILE. `Diagnosed` outlives the `LoopInfo` that owns its keys

**Severity: over-ACCEPT / silent miscompile. Highest. Reproduces on ordinary C with no attributes.**

### Claim

`declineUnmarkedRolledIterLocal` (`LoopLowering.cpp:3826-3902`) declares

```cpp
SmallPtrSet<const Loop *, 4> Diagnosed;          // :3829 — OUTSIDE the function loop
for (Function &F : M) {
  …
  DominatorTree DT(F);
  LoopInfo LI(DT);                               // :3845 — INSIDE; it OWNS the Loop objects
  for (const WeakTrackingVH &H : taint.RolledIterLocalGates) {
    …
    Loop *L = LI.getLoopFor(I->getParent());
    …
    if (!Diagnosed.insert(L).second)
      continue;                                  // :3855 — skips BOTH conjuncts
```

`Loop` objects are allocated by `LI` and destroyed with it at the end of each function iteration.
`Diagnosed` keeps those pointers. The next function's `LoopInfo` re-uses the same allocation, so
`Diagnosed.insert(L).second` returns **false for a different loop in a different function** and the
entire re-ask — conjunct 1 (the (c3) re-ask) *and* conjunct 2 (the marking postcondition) — is
`continue`d over. The record was made, the grant stands, and nothing checks it.

### Probe — four controls isolate `Diagnosed` as the only order-sensitive state

```
$ cd $SES/trackW/review_r1_probes && ./rv.sh sub ctl_wj b1_twofn b1_twofn_rev b2_norecord b3_failfail
ctl_wj       |sub|DECLINE|control flow inside a loop body            # w_j alone — correct
b1_twofn     |sub|ACCEPT |lines=40 | stage-2b 0 violation(s)         # ← WRONG
b1_twofn_rev |sub|DECLINE|control flow inside a loop body            # same two fns, reversed
b2_norecord  |sub|DECLINE|control flow inside a loop body            # 1st fn makes NO clause-(c) record
b3_failfail  |sub|DECLINE|control flow inside a loop body            # 1st fn is the failing one
```

* `b1_twofn.c` = `f_pass` (the `w_i` shape, which **passes** the re-ask and is therefore inserted into
  `Diagnosed`) followed by `f_fail` (the `w_j` shape, which **must** decline at conjunct 2).
* `b1_twofn_rev.c` is the identical pair in the opposite module order → declines. Order is the only
  variable.
* `b2_norecord.c` replaces the first function with a clause-(b′) loop, which writes **no** record, so
  `Diagnosed` is empty when `f_fail` is reached → declines. This rules out any explanation other than
  the set.
* `b3_failfail.c` (two failing functions) declines at the first, confirming `diagnoseUnderControl`
  exits and `Diagnosed` therefore only ever accumulates **passing** loops.

**Robustness:** reproduces with a different passing first function (`b4_variant.c`, 37 lines, ACCEPT)
and with an unrelated third function between them (`b5_threefn.c`, 40 lines, ACCEPT). It is not a
single allocator coincidence.

**No attribute needed.** `b6_noattr.c` — two ordinary kernels called once each from `main`, no
`noinline` — ACCEPTS. `-O1` keeps them separate (loops inhibit inlining):

```
$ grep '^define' b6_noattr.sub.ll
define i32 @kernel_a() …   define i32 @kernel_b() …   define i32 @main() …
$ grep -c 'cq_template_and_i32_hl('    b6_noattr.sub.trace   → 2
$ grep -c 'cq_template_and_i32_hl_unc' b6_noattr.sub.trace   → 0
```

### The emitted stream — this is a leak, not a skipped check (Rule 2)

`b1_twofn`'s `f_fail` half (trace lines 15–40, 26 lines) against the hand-unrolled twin
`ctl_wj_un.sub.trace` (30 lines):

```
rolled (WRONG)                            hand-unrolled twin (CORRECT)
cq_template_and_i32_hl(h4,2)  -> h6       cq_template_and_i32_hl(h0,2)  -> h2
cq_template_icmp_eq_i32_hl…   -> h7       cq_template_icmp_eq_i32_hl…   -> h3
cqrt_x(h7) / cry / cqrt_x(h7)             cqrt_x(h3) / cry / cqrt_x(h3)
cq_template_icmp_eq_i32_hl_unc(h7,h6,0)   cq_template_icmp_eq_i32_hl_unc(h3,h2,0)
cqrt_free(h7)                             cq_template_and_i32_hl_unc(h2,h0,2)   ← MISSING
                                          cqrt_free(h2)                          ← MISSING
                                          cqrt_free(h3)
```

`and_unc` appears **0** times against **2** mints. **One entangled which-path record of `u`'s bits is
leaked per activation** — precisely the 19-vs-27 signature this increment exists to prevent, shipped
*through* the fence that was built to prevent it.

`opt` exit 0. `opt -verify` clean. STRICT stage 2b: `4 rail mint(s) of which 4 left allocated,
1 cqrt_free site(s): 1 verified, 0 violation(s), 0 unproven` — structurally blind, exactly as
`free_pairing_check.py`'s own header says (a template-minted rail has no `cqrt_alloc` to count).

### Why no shipped gate sees it

Every e2e slice in the tree is `slice()` + `main`; every twin-matrix cell generates one kernel; every
new lit fixture has one loop-bearing function. The **two-function axis is not covered by any
instrument in this tree.** That is the reason this survived 1937 fixtures, 15 e2e entries, a complete
corpus sweep and a 0-MISSED injection matrix.

### Minimal fix

Move the declaration inside the per-function body, **or** key it on `L->getHeader()` (a
`BasicBlock *`, which lives as long as the module). The tree already owns the correct shape one
function away and this is the only departure from it (Rule 14):

```
$ grep -rn 'SmallPtrSet<const Loop \*\|SmallPtrSet<Loop \*' ir-pass/src ir-pass/include
LoopLowering.cpp:3829:  SmallPtrSet<const Loop *, 4> Diagnosed;      ← the only one in the tree
```

`reverifyRailCondReads` — its neighbour in the same pipeline slot — keys its own `Diagnosed` on
`const Value *` and keeps its `DominatorTree`s alive in a module-scoped
`DenseMap<Function *, unique_ptr<DominatorTree>>`. The new function departed from both halves of that
pattern.

**⚠ Fixing this will expose F-W1-3's over-declines more often, not less.** Land the two together.

---

## 3. F-W1-2 — over-ACCEPT / SILENT MISCOMPILE. The retirement admits a clause-(b′) rail region onto a path measured to leak, where the increment's own re-ask is never asked

**Severity: over-ACCEPT / silent miscompile, with an owner-disposition component.**
**This is the answer to the brief's question about half 1.**

### Claim

Half 1 retires the carve-out for **every** `RailCond && Region.InLoop` region. Its safety argument
(IMPL_W §2.1 REASON 2) is that *"a bare `_Bool` condition MINTS NOTHING AND DERIVES NOTHING"*, so the
C-1 mixture is vacuous. That sentence is **true of the condition and false of the region's loop**: the
*body* can mint per-trip template rails for reasons that have nothing to do with the condition, and
half 2's entire safety net (`RolledIterLocalGates` + `declineUnmarkedRolledIterLocal`) is written
**only at the clause-(c) grant**. A rail region whose rotated register is loop-CARRIED is granted by
clause (b′) — **no record, no re-ask, no conjunct 2**.

### Probe

```
$ ./rv.sh sub d3_invariant_read d3_invariant_read_un d2_control_noderail d2_control_noderail_un
d3_invariant_read      |sub|ACCEPT|lines=30| 0 violation(s)
d3_invariant_read_un   |sub|ACCEPT|lines=34| 0 violation(s)      ← the hand-unrolled twin
d2_control_noderail    |sub|ACCEPT|lines=27
d2_control_noderail_un |sub|ACCEPT|lines=27
$ ./rv.sh ora d3_invariant_read
d3_invariant_read      |ora|DECLINE|control flow inside a loop body    ← the ORACLE REFUSED IT
$ diff d3_invariant_read.sub.trace d3_invariant_read_un.sub.trace
  # per activation, MISSING from the rolled form:
  >  cq_template_and_i32_hl_unc(h3, h2, 2)
  >  cqrt_free(h3)
$ diff d2_control_noderail.sub.trace d2_control_noderail_un.sub.trace   → BYTE-IDENTICAL
```

`d3_invariant_read.c` is `d1_carried_rail_plus_derived.c` (which **is** twin-identical, 32 = 32) plus
one thing: the body also *reads* the loop-invariant rail `b` in a non-control position
(`cq_measure(u + (int)b)`). That read trips `markIfRailLocal`'s **"accumulating loop-invariant tainted
input"** clause (`LoopLowering.cpp:3546-3553`), the whole marking is refused, the body never enters
`taint.IterationLocalBlocks`, and the spine leaks the per-trip `and` rail.

`d2_control_noderail.c` is the same loop with `b` deleted entirely — twin-identical 27 = 27. So the
trigger is the loop-invariant tainted read, isolated to one token.

### The defect is pre-existing; the CUSTOMER is new — and that distinction is the finding

```
$ ./rv.sh sub d4_noRailRegion d4_noRailRegion_un   →  28  vs  34   (DIVERGES)
$ ./rv.sh ora d4_noRailRegion d4_noRailRegion_un   →  28  vs  34   (DIVERGES)
$ diff d4_noRailRegion.sub.trace d4_noRailRegion.ora.trace          →  SUB == ORA
```

`d4_noRailRegion.c` is `d3` with the rail region removed. It diverges **byte-for-byte identically on
the ORACLE and on the SUBJECT**, so the leak mechanism is pre-existing and arm-class-independent
(it is bd `1m5p`'s class-A shape plus the per-trip `and`). **But the ORACLE REFUSES `d3`.** CLAUDE.md's
own formulation for `1m5p`/`a3z7` applies verbatim: *"'pre-existing' is true of the defect and FALSE
of its population — the increment that exposed them adds customers to a known defective path."* Here
it is stronger than `1m5p`: this is not a quarantined divergence between two accepted forms, it is a
**newly accepted program whose rolled stream is a different unitary from its hand-unrolled twin's.**

### IMPL_W predicts the opposite, in writing

IMPL_W §2.1 / `ArmClassify.cpp:3780-3786`:

> *"…and `markIfRailLocal` exempts it at its 'accumulating loop-invariant tainted input' clause because
> `invariantRegisterRoots` admits exactly a classical-arg-0 `cq_theta` dominating the header — which a
> `_Bool` mint is — on BOTH halves of `collapseFlattenedLoopRails`' dispatch."*

`d3` measures that claim FALSE. `b` is a classical-arg-0 `cq_theta_i1` dominating the header, and the
marking is refused anyway. The sentence is load-bearing for the retirement and it is not true.

### Minimal fix

This is CLAUDE.md's L1 lesson verbatim — *"the record must be at EVERY emission site … a seventh
emitter that forgets it re-opens the window with NO DIAGNOSTIC ANYWHERE"*. The record must be written
at **every** R7-loop grant, not only at clause (c).

⚠ It is **not** a one-line move, and the reviewer should say so rather than hand over a patch that
looks cheap: for a (b)/(b′) grant only **conjunct 2** may be asked — conjunct 1 re-asks (c3), which
refuses every loop-CARRIED shape by construction (the carried register escapes the loop; that is what
"carried" means). So `RolledIterLocalGates` needs a per-entry bit naming the granting clause (or a
second vector), and the conjunct-1 call must be gated on it. Checked for compatibility with the
shipped accepts: `v1_wa`, `a1`, `a2`, `d1` all have bodies with **no** spine-discharge candidate, so
`bodyHasSpineDischargeCandidate` skips conjunct 2 for them and they keep lowering; `d3` has one and
would decline. That design change needs its own Rule-13 round.

**If the owner prefers not to widen the record**, the honest alternative is to restore the carve-out
for the clause-(b)/(b′) half only — i.e. retire it for iteration-local rails and keep it for carried
ones — and file `d3` against `1m5p`. Either way, shipping a new accept onto a path measured to
miscompile is not available.

---

## 4. F-W1-3 — over-DECLINE, three measured shapes, one root cause. `bodyHasSpineDischargeCandidate` is a proxy and it is too coarse

**Severity: over-DECLINE (a defect under the owner's 2026-09-11 ruling).** This is the fifth the brief
asked for; there are three.

The brief asks directly: *"is `bodyHasSpineDischargeCandidate` the right question, or a proxy for
it?"* — **It is a proxy.** It asks *"is there a tainted instruction that is not a
{θ, φ, measure, PHI}?"*. The question it stands for is *"will `FreePoint`/`Uncomputation` place
anything inside the body?"* Three constructs answer yes to the proxy and no to the question. All three
are one token away from an accepting sibling and all three have a hand-unrolled twin that ACCEPTS.

| probe | one-token delta from `ctl_wi.c` (ACCEPT, 14 lines) | rolled | twin | the twin's body stream |
|---|---|---|---|---|
| `od3_inplace_cand.c` | `+ r = r ^ 3;` | **DECLINE** `12:20` | ACCEPT 16 | `cqrt_xorc_i32(h1, 3)` — **in place**, 0 `_unc`, 0 `free` |
| `od2_measured_cand.c` | `cq_measure(r)` → `cq_measure(r + 1)` | **DECLINE** `13:20` | ACCEPT 16 | `cqrt_addc_i32(h1, 1)` — **in place**, 0 `_unc`, 0 `free` |
| `od4_measured_template.c` | `cq_measure(r)` → `cq_measure(r & 3)` | **DECLINE** `13:20` | ACCEPT 16 | `cq_template_and_i32_hl(h1,3) -> h2; cqrt_measure_i32(h2)` — a **measured** rail is never uncomputed and never freed |

```
$ ./rv.sh sub ctl_wi od2_measured_cand od2_measured_cand_un od3_inplace_cand od3_inplace_cand_un \
                    od4_measured_template od4_measured_template_un
ctl_wi                    |sub|ACCEPT |lines=14
od2_measured_cand         |sub|DECLINE|control flow inside a loop body   # ./od2_measured_cand.c:13:20
od2_measured_cand_un      |sub|ACCEPT |lines=16
od3_inplace_cand          |sub|DECLINE|control flow inside a loop body   # ./od3_inplace_cand.c:12:20
od3_inplace_cand_un       |sub|ACCEPT |lines=16
od4_measured_template     |sub|DECLINE|control flow inside a loop body   # ./od4_measured_template.c:13:20
od4_measured_template_un  |sub|ACCEPT |lines=16
```

All three anchors are **column 20 / 20 / 20 = the hoisted arm gate `cq_theta(r, 0.2)`**, i.e.
conjunct 2 of `declineUnmarkedRolledIterLocal`, not the R7 classifier (whose `declAnchor(Region)`
would name the condition at column 13). Same anchor shape as the implementer's own `w_j` at `13:31`.

In every one of the three, `taint.IterationLocalBlocks` is **provably irrelevant**: the twin's stream
contains zero `_unc` and zero `cqrt_free` inside the body, so there is nothing for the marking to
license the spine to place.

### Minimal fix — and it must not be done casually

`od2`/`od3` share a single root cause: the op is an **M-C in-place reassignment** and mints no rail.
The tree already owns that verdict as a committed record — `taint.InPlaceRailOps`, written by
`classifyInPlaceReassignment` and re-verified at `lowerOps` under final taint. Skip an instruction
that is in it, by **calling** the record rather than re-deriving the predicate (Rule 14; the drbq
Inc-3 (b′) defect is the counter-example). `od4` (a template rail whose only terminal consumer is a
measurement) is a separate, harder question and should be filed rather than guessed at.

⚠ This is an **ACCEPT-direction** change to a fence, and the predicate's own comment says so:
*"RETIREMENT TRIGGER: adding a fifth kind to this list is adding a claim that it mints nothing —
re-derive it against `lowerOps`, not against this comment."* Treat that trigger as binding: the fix
needs its own Rule-13 clearance, and the two it closes are worth less than a wrong fifth exclusion.

### One over-decline I could NOT substantiate, recorded so it is not re-chased

`od1_escape_bool.c` — an iteration-local register that LCSSA-escapes under a **bare** `_Bool`
condition, i.e. (c3) refusing where the body has no spine candidate at all — looks like a fourth
over-decline, and (c3) is indeed ungated by `bodyHasSpineDischargeCandidate` where conjunct 2 is
gated. But `od1_escape_bool_un.c` (its hand-unrolled twin) **also declines**, with
`nested control flow`: `-O1` fuses the two repetitions into a depth-2 nest. So **no oracle twin
exists** and the claim cannot be made on this tree's own evidence discipline. Recorded as
unsubstantiated, not as a finding. The asymmetry (c3 ungated / conjunct 1 ungated / conjunct 2 gated)
is nevertheless worth an explicit sentence in IMPL_W, because a reader will ask.

---

## 5. Adjudications the brief asked for by name

### 5.1 The fence retirement (half 1) — my judgement

**Argument 1 ("no oracle twin" is about the wrong twin) — SOUND, and I verified it rather than
restating it.** The discipline in this tree is rolled-versus-hand-unrolled and l4x4.b shipped the flat
`_Bool` capability that supplies the twin. Measured: `v1_wa` 8 = 8, plus my own `a1` 9 = 9 and `a2`
10 = 10, all byte-identical, all ORACLE-DECLINE → SUBJECT-ACCEPT. The retirement of *this* reason is
correct and well evidenced.

**Argument 2 ("it is the C-1 mixture" is vacuous for a rail) — TRUE OF THE CONDITION, FALSE OF THE
REGION.** I could not break the narrow claim: a bare `_Bool` condition really does mint nothing and
derive nothing, `emitInPlaceRotationRegion` really does hand the register to `cqrt_ry_<W>_controlled`
as arg-0, the negated arm really is Ry additivity with no `cqrt_x` on a user register, and the three
`_Bool` traces really do contain zero `cq_template_*`/`cqrt_x`/`cqrt_free`. I attacked it four ways —
an iteration-local condition rail (`a1`), a chained per-trip condition rail (`a2`), a condition
measured after the region (`c2`), a condition rotated after the region (`c3`) — and all four are
either twin-identical or correctly declined.

**But the carve-out it replaced was not guarding the condition; it was guarding the LOOP.** The C-1
leak signature is a per-trip chain the rolled form never discharges, and that chain can be minted by
the body for reasons the condition kind says nothing about — `d1` (twin-identical, fine) and `d3`
(**leaks**, F-W1-2) differ only in whether the body reads a loop-invariant rail. Half 2 built exactly
the right instrument for this (`RolledIterLocalGates` + conjunct 2) and then wired it to only one of
the three R7-loop grant clauses. **So the retirement is right in principle and under-fenced in
practice**, and the fix is to finish wiring the instrument that is already there, not to restore the
carve-out.

### 5.2 Does (c3)'s first-offender form survive L4? — YES, and the implementer's reasoning is right

L4's failure mode requires an **exemption**: a return-first walker is defeated because an
already-ACCEPTED item placed in front of an unaccepted one ends the walk on a ruled-out hit.
`iterationLocalTaintEscape` carries no per-entry `WireRuled` bit and no exemption of any kind; every
tainted instruction defined in `L` owes the identical obligation. I checked both consumers:

* clause (c3) — `return iterationLocalTaintEscape(L, Taint) == nullptr;` — a pure ∀, for which one
  witness is a complete answer to ∃;
* conjunct 1 — `if (Instruction *Esc = iterationLocalTaintEscape(L, taint))` — uses `Esc` **only** as
  a diagnostic anchor, never as a set, and says so.

That is the one place a later reader could mistake it for a set, and it is correctly commented. No
finding.

**One gap in the recorded retirement trigger.** It names only *"if an exemption is ever added"*. L4's
sibling is L2: a ∀ must also be re-derived when its **closure** moves. (c3)'s closure is
`L->blocks() × taint.Tainted` — the subloop inclusion, and the taint round it is asked at. Either
moving is the same hazard and neither is named. Recommend widening the trigger's wording.
(Severity: documentation.)

### 5.3 H-3 (`cq_phi` as a clause-(c2) mint) — adjudicated UNREACHABLE, on a stronger ground than "believed"

The implementer's belief is correct, and the mechanism is more specific than the one stated. In
`peelInPlaceStep` (`LoopLowering.cpp:299-307`) a `GateCalls` member is stepped **through** only when
`CI->getArgOperand(0)` is TAINTED. For the register-free `void cq_phi(double)` arg-0 is the ANGLE, so
the walk **stops at** a `cq_phi` rather than stepping through it — which means a `cq_phi` can only be
*returned* as the base if it was the input `V` itself. Both callers pass a value of **register
type**: `railPhiRootMint` passes a φ incoming, clause (c2) passes `RotBase` (the rotated register) or
`T`. A `void` call is never an operand of anything, so neither can ever be one. Deliberately shipping
no fixture is the right call — a fixture here would be a vacuous negative, which PROTOCOL.md S3 names
as a defect in its own right.

Two notes for the record: the `starts_with("cq_theta_")` test in (c2) is therefore **dead today**, and
its retirement trigger should say so and name what makes it live (a `cq_phi` acquiring a register
operand — a Key Prohibition, but so was the `cq_phi_<sfx>` family). And it is *not* a finding against
`railPhiRootMint`: the same argument covers it.

### 5.4 `staleRailRecordRead` "it does not become anything" — I could not break it, with one caveat

The two-step argument is (c1) ⇒ no tainted header φ ⇒ no claimed chain ⇒ the fence has no subject; and
iteration-locality ⇒ one physical register per activation ⇒ no name spans two activations **unless it
escapes, which (c3) refuses**. I attacked the second step directly (`c2`, `c3`, `a2` — a condition
whose state differs per trip) and could not produce a clause-(c) rail whose name spans activations.
`w_k`-style non-interference held in the implementer's own measurement and my `a1`/`a2` are consistent
with it.

**The caveat is F-W1-2**: the argument is stated as protecting *"a clause-(c) rail"*, and the
retirement also admits **(b′)** rail regions, for which neither (c1) nor (c3) is asked at all. The
§6 argument is sound for the shapes it names and does not cover the shapes half 1 additionally
admits. Same root as F-W1-2; no separate fix.

---

## 6. F-W1-4 — record hygiene. The `runOnFunction` mirror inherits a FALSE premise

**Severity: documentation / hygiene (zero callers today).**

`declineUnmarkedRolledIterLocal` is mirrored into `runOnFunction` (`CQLoweringPass.cpp:983`) for
WI-1.12 twin-pipeline parity. But that shim **never calls the round-1
`collapseFlattenedLoopRails`** — a pre-existing gap documented at `TaintPropagation.cpp:1810-1816`
(*"⚠ That shim does NOT call the ROUND-1 `collapseFlattenedLoopRails` at all … the shim has zero
callers"*) — and the round-2 call is handed `Round1FlattenedPreds` as `AlreadyProcessed`, so it
**skips exactly the loops the shim flattened at round 1**. Consequence: in the shim, a clause-(c) loop
can never be marked, and conjunct 2 fires on every one of them that has a candidate. The mirror is
syntactically faithful and semantically not; the new re-ask is the first stage to *depend* on a
marking the shim cannot produce. Worth one sentence in IMPL_W §3 and a bead against the shim.

---

## 7. What I did NOT examine

* **H-1** (a clause-(c) loop whose second tainted branch appears only at round 2, over an additive
  marking granted at round 1). I did not build it. Constructing it needs a 6.5 classical-call-arm
  `%out` region *inside* a clause-(c) loop, and the two-region loops I did build (`c1_tworegions`)
  decline on both sides. **It remains the sharpest un-probed residual and I did not clear it.**
* **H-2** (the mixed loop) — confirmed by inspection as an over-decline today, not probed; the
  monotonicity inversion the implementer warns about is a round-2 design question.
* The **twin matrix** (328 cells) and the **corpus sweep** — both out of scope for a reviewer by the
  PROTOCOL matrix. **I therefore did not independently verify the 3-mover sweep result or the 40 `i1`
  cell predictions in IMPL_W §9**, and note that §9 is itself a hand reconstruction the implementer
  flagged as non-authoritative.
* **K-independence** at `-DCQ_K=1000` — not re-measured; I measured only `CQ_K=2`.
* The **injection matrix** (40 applied / 0 MISSED) and the **vacuity** run (29/0) — not re-run.
  ⚠ Note that neither could have caught F-W1-1 or F-W1-2: both instruments operate on single-function
  fixtures, and the two-function axis is uninstrumented in this tree.
* `railChainRootMint`'s byte-for-byte equivalence to `railPhiRootMint`'s old tail — I read it and the
  two new conjuncts are correctly ordered (`arg_size() < 1` before `getArgOperand(0)`) and monotone
  toward decline, but I ran no corpus sweep to confirm no shipped module moved.
* The e2e slices and goldens shipped with the increment — not run.

---

## 8. Verdict and round 2

**NOT CLEAR.**

| # | finding | severity |
|---|---|---|
| **F-W1-1** | `Diagnosed` outlives its `LoopInfo`; the round-2 re-ask is silently skipped for every function after the first passing one. Reproduces on plain two-kernel C. One entangled which-path rail leaked per activation. | **over-ACCEPT / silent miscompile** |
| **F-W1-2** | The retirement admits a clause-(b′) rail region onto a measured-leaking path where no record and no re-ask exist. ORACLE DECLINE → SUBJECT ACCEPT, 30 vs 34 lines. The underlying leak is pre-existing; the customer is new. | **over-ACCEPT / silent miscompile** |
| **F-W1-3** | `bodyHasSpineDischargeCandidate` over-counts M-C in-place ops and measured template rails; three one-token over-declines with accepting twins. | **over-DECLINE** |
| **F-W1-4** | The `runOnFunction` mirror depends on a marking that shim cannot produce. | **record hygiene** |
| — | (c3)'s retirement trigger names exemptions but not closure widening (L2). | **documentation** |

**Round 2 is warranted.** Scope, in priority order:

1. **The F-W1-1 fix.** One line, but it is Rule-13 core and it *widens the decline set*, so re-derive
   which currently-accepted multi-function modules start declining. Land it with F-W1-3.
2. **The F-W1-2 design** — recording at every R7-loop grant with a per-entry clause bit, conjunct 2
   only for (b)/(b′) — or the owner's decision to re-narrow half 1 instead. This is a new fence and
   owes a full round of its own.
3. **F-W1-3's exclusion widening**, which is accept-direction and carries its own recorded retirement
   trigger.
4. **H-1**, which neither the implementer nor I built.
5. **An instrument for the two-function axis.** Two findings in this round were invisible to 1937
   fixtures, 15 e2e entries, a complete corpus sweep, a 0-MISSED injection matrix and a 328-cell twin
   family for the same structural reason. At minimum, the merge gate should add one multi-kernel e2e
   slice pair; ideally a twin-matrix axis.

CLAUDE.md's measured hit rate says round 2 finds something. The implementer budgeted three rounds and
that budget looks right rather than pessimistic — round 1 found two over-accepts, and one of them
(F-W1-2) was **introduced by the fix half of this very increment failing to cover the other half's
widening**, which is the "two of them introduced by a fix" pattern verbatim.
