# VERDICT: CLEAR-WITH-ITEMS

Rule-13 adversarial review, **round 2**, of the round-1 fix on bd
`test_C_libtooling-3qlq.4` ("Inc 1b" — the bare `_Bool` RAIL-LEAF condition),
branch `3qlq-inc1b-rail-cond` @ `596cd73`, measured against the **pre-fix**
branch commit `8a8f8cf` and against `main` @ `170ede1`.

> **Tree measured.** Every figure below was taken on a `596cd73` build of
> `libCQPass.so` + `cq-opt` (`cmake --build build -j8`, both targets), against a
> `8a8f8cf` worktree build (the **PRE** binary, preserved as
> `…/review_1b_r2/cq-opt.prefix`) and the round-1 `main` worktree
> (`…/review_1b/wt-main`, `170ede1`, the **MAIN** binary). Probes, harnesses
> (`rc.sh` C, `rh.sh` hand-IR, `rm2.sh` two-TU, `corpus.py`) are under
> `…/399370cc-…/scratchpad/review_1b_r2/`.

**No CONFIRMED silent miscompile is introduced or left by the fix in the class it
was written to close.** The widening is **decline-monotone** — proven analytically
(§Negative space A) and measured three ways: **0 RCDIFF / 0 DIAGDIFF / 0 OUTDIFF**
over all **1732** pre-existing `.ll` fixtures, **19 movers over 124 plain-C
programs and every one of them `accept → decline`**, and **0 decline→accept**
anywhere. All four round-1 reproducers are fixed, the discriminating accepts
survive, and the accept boundary of the widening is **pinned by 11 pre-existing
fixtures** (measured with a blanket-refusal mutant, §Negative space F).

Four ITEMS, none of them a blocker:

| id | severity | one line |
|---|---|---|
| F-1b2-1 | **CONFIRMED-MISCOMPILE, PRE-EXISTING** (identical on `main`) | the linear rule is unenforced when the stale READER is a `cq_theta` call or a `cq_measure` sink — 1 line of plain C, `opt` exit 0, stage-2b clean, byte-identical to a *different* well-formed program. Not this fix's; file it (the `eqpx` precedent). |
| F-1b2-2 | ITEM (rolled ≠ unrolled) | the fix introduces a rolled/hand-unrolled **disposition** split on the F-1b2-1 shape: rolled ACCEPTS, unrolled DECLINES. The unrolled side is the correct one; the rolled side is F-1b2-1. |
| F-1b2-3 | DOC / dead code | `collectWireValues`' new `Taint` parameter has **no caller that supplies it** — the `collectWireValues` half of the fix is inert, and the `thetaOnPathTo` parity gap (bd `r903`) is 100 % open, not partly closed. |
| F-1b2-4 | DOC | the rewritten `railCondWireDisposition` header (the F-1b-4 fix) is **still not literally true**: it drops the positional prong on the ground that the widened walk asks the rail's whole wire, but the compare path's own P5 comment says that prong exists for *"a theta on ANOTHER wire, which no wire walk can see"* — which the widened walk still cannot. Measured safe today for a structural reason the header does not state. |

---

## What I ran

| layer | what | result |
|---|---|---|
| corpus regression | all **1732** `.ll` fixtures in the **PRE-FIX** tree, PRE binary vs FIX binary (stdout + stderr + exit code) | **0 RCDIFF, 0 DIAGDIFF, 0 OUTDIFF** |
| corpus, mutant | all **1736** HEAD fixtures, FIX vs blanket-refusal mutant **M-X** | **11 fixtures redden** — the accept boundary IS pinned (§F) |
| plain C @ `-O1` | **124** programs (83 round-1 `p/*` + 41 new) on FIX **and** PRE | **19 movers, 100 % `accept → decline`; 0 `decline → accept`; 0 OUTDIFF among both-accept** |
| hand IR | 8 new modules (`h/w1`–`w4`, `h/m10`–`m11`) + the round-1 `h/*` | see below |
| Rule 1 | all 124 C programs greped for a surviving `@cq_{theta,phi,measure}` call or a surviving tainted `br i1` | **65 accept / 59 decline, 0 violations** |
| ctest | `-R 'twin-identical\|phase-bool\|free-pairing-selftest\|quarantine-selftest'` | **38/38 passed, 4.13 s** |
| lit | `ctest -R ir-pass-lit` | see §Negative space G |
| stage 2b | `free_pairing_check.py` on every accepting probe | **0 violation(s)** everywhere |

The four new decline fixtures are genuine **red-green**: each exits **0
(ACCEPT)** on the PRE binary and declines on the FIX binary —

```
control_phase_kickback_reject_rail_sibling_theta.ll             pre rc=0 → cq controlled lowering: condition predates a non-diagonal gate
control_phase_kickback_reject_rail_sibling_theta_crossblock.ll  pre rc=0 → cq controlled lowering: condition predates a non-diagonal gate
control_phase_kickback_reject_sibling_theta_template_parent_cmp.ll pre rc=0 → cq opcode lowering: operand predates a non-diagonal gate
control_phase_kickback_reject_rail_measured_sidepath.ll         pre rc=0 → cq controlled lowering: condition measured before the control route
```

---

## F-1b2-1 — CONFIRMED-MISCOMPILE, **PRE-EXISTING** (identical on `main`): the linear rule is unenforced when the stale READER is a `cq_theta` call or a `cq_measure` sink

**Severity: CONFIRMED-MISCOMPILE / PRE-EXISTING.** `opt` exit 0, verify-clean,
stage-2b `0 violation(s)`, byte-identical output on **MAIN `170ede1`**, **PRE
`8a8f8cf`** and **FIX `596cd73`**. **This fix neither introduces nor widens it**
— it is the same *defect class* the fix closes, one consumer over, and it belongs
on its own bd id (the `eqpx` / round-1-`p81` precedent). It does **not** block.

### Reproducer — one line of plain C, no control flow at all

```c
/* p/f1_two_siblings_nocontrol.c */
#include "CQ.h"
int main(void){ int q=cq_theta(0,0.3); int b=cq_theta(q,0.5); int c=cq_theta(q,0.9); return cq_measure(b)+cq_measure(c); }
```

Measured on **all three** binaries (`ACCEPT`, `free_pairing_check` `0 violation(s)`):

```
cqrt_alloc_i32(0) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cqrt_ry_i32(h0, 0x1p-1)
cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1)
cqrt_measure_i32(h0) -> 0
cqrt_measure_i32(h0) -> 0
```

### Why it is wrong — measured, not argued

`b` and `c` are two in-place Ry on ONE physical rail (`lowerRotations` RAUWs both
to `q`'s handle, `Chained = taint.Tainted.count(arg0)`). The source names two
*different* states of one register — `Ry(.5)|q⟩` and `Ry(.9)|q⟩` — which is a
no-cloning request (Rule 8) and, under the documented linear rule
(`docs/frontend.md` §3.2: *"A rotation consumes the old name … a read of the
pre-gate value that the compiler cannot prove executes before the gate is refused
— loudly, lowering nothing"*), an ill-formed program the compiler's own policy is
to DECLINE. It does not. The emitted circuit measures `Ry(1.4)|q⟩` twice.

The round-1 proof pattern reproduces exactly — the subject's stream is
**byte-identical** to that of a *different, well-formed* program:

| file | source | trace |
|---|---|---|
| `p/f1_two_siblings_nocontrol.c` | `b=cq_theta(q,.5); c=cq_theta(q,.9); measure(b)+measure(c)` | the 6 lines above |
| `p/f1w2_chain_measure_twice.c` | `a=cq_theta(q,.5); c=cq_theta(a,.9); measure(c)+measure(c)` — a chain, no aliased name | **byte-identical** (`diff` empty) |

So the subject's emitted circuit *is* the correct compilation of `f1w2`, and the
subject's own meaning (`b = Ry(.5)|q⟩`) appears nowhere in it.

### It is CLAUDE.md's own F-3 shape, out of loop

`p/g1_chain_measure_both.c` is, verbatim, the program CLAUDE.md records as a
confirmed silent miscompile for the in-loop rail path (bd `8h7d.5` round 3,
finding F-3, *"`a` naming the pre-`b` register"*):

```c
int main(void){ int q=cq_theta(0,0.3); int a=cq_theta(q,0.125); int b=cq_theta(a,0.25); return cq_measure(a)+cq_measure(b); }
```

→ **ACCEPT on all three binaries**, emitting `ry(h0,.3); ry(h0,.125); ry(h0,.25);
measure(h0); measure(h0)`. `LoopLowering::staleRailRecordRead` — the fence that
closed F-3 — only reasons over a **loop-collapsed** rail chain, so the loop-free
spelling is untouched.

### The exact boundary, measured

| probe | reader of the stale name | verdict (all three binaries) |
|---|---|---|
| `g3_pureop_after_theta.c` — `int d=q+1;` after `a=cq_theta(q,.5)` | a **pure op** | **DECLINE** `cq opcode lowering: operand predates a non-diagonal gate` |
| `g4_sibling_measure_only_c.c` — `return cq_measure(c)+b;` | a **pure op** (`+` on the stale `b`) | **DECLINE**, same string |
| `f1`, `g1`, `g2_measure_parent.c` | a **`cq_measure` sink** | **ACCEPT** |
| `e6_sibling_after_branch.c`, `l1_inloop_sibling_invariant.c` | a **`cq_theta` call** | **ACCEPT** |

### Root cause

`OpcodeLowering.cpp::inLowerOpsScope` — the set `declineStaleRecordOps` sweeps —
is exactly `BinaryOperator | UnaryOperator | CastInst | isDataPositionCompare(Cmp)
| isCuratedReversibleIntrinsic(CallInst)`. A `@cq_theta_*` call and a
`@cq_measure_*` call are **not in it**, so the wire question is never asked for
them. The *walker* answers it correctly — including, since this fix, across a
template/compare/cast/phi/merge parent — it is simply never called.

### Proposed fix (and the machinery is already there)

Sweep `@cq_theta_*` (arg-0 only) and `@cq_measure_*` calls with the same
position-aware `checkStaleOp`, **excluding `I` itself** from the candidate set
(the reader is itself a gate on the seed's wire). Traced by hand against the
existing `Exempt`/`gateIsHarmless` logic on the four programs above:

* `f1`, reader `%c`, seed `%q`: candidates `{%b, %c}`; `%c` is `I` (excluded);
  `gateIsHarmless(%c, %b, …)` fails `DT.dominates(%c,%b)` (`%b` precedes) →
  **DECLINE**. ✔
* the well-formed chain, reader `%c = cq_theta(%a,.9)`, seed `%a`: widened
  ancestry `{%a,%q}` is `Exempt`; the only other theta user is `%c` itself →
  **no candidate, ACCEPT**. ✔ (This is the discriminating accept the change needs.)
* `g1`, reader `cq_measure(%a)`, seed `%a`: `%b` is a non-exempt theta on the
  wire and precedes the measure → **DECLINE**. ✔
* `cq_measure(%b)` in the well-formed chain, seed `%b`: ancestry `{%b,%a,%q}` all
  `Exempt` → **ACCEPT**. ✔

Red-green per Rule 12, plus the accept controls above, plus a re-measure of
`p07_chained_after.c` and `control_phase_kickback_rail_post_ry.ll` (a post-region
chained theta must keep its `ProvenPostRegion` accept).

---

## F-1b2-2 — ITEM: the fix introduces a rolled ≠ hand-unrolled **disposition** split on the F-1b2-1 shape

**Severity: ITEM.** The *unrolled* side is the correct one; the *rolled* side is
F-1b2-1 and is byte-unchanged from `main`. Recorded because this project treats a
rolled/unrolled divergence as a first-class signal (bd `8h7d.5`,
`e2e-loop-twin-matrix`), and because it is the fix's own footprint.

```c
/* p/l1_inloop_sibling_invariant.c  — ROLLED */
#include "CQ.h"
int slice(int u){ int q=cq_theta(u,0.5); int t=q&1; int acc=0;
  for(int i=0;i<3;i++){ int b=cq_theta(t,0.5); if(b==1) cq_phi(0.7); int c=cq_theta(t,0.9); acc+=cq_measure(c); }
  return acc; }
int main(void){ return slice(3); }
```

`p/l1u_unrolled.c` is the same body written out three times.

| spelling | MAIN | PRE | FIX |
|---|---|---|---|
| rolled (`l1`) | ACCEPT | ACCEPT | **ACCEPT** |
| hand-unrolled (`l1u`) | ACCEPT | ACCEPT | **DECLINE** `condition predates a non-diagonal gate` |

and the rolled trace on FIX is **byte-identical** both to the rolled trace on PRE
and to the **hand-unrolled trace on PRE** (`diff` empty, 24 lines) — i.e. the fix
declined the unrolled spelling as a stale-condition miscompile and left the rolled
spelling emitting exactly the circuit it refused.

**Why the split is not itself unsound.** They decline for different reasons, and
only one of them is about the condition. Unrolled: copies 2 and 3 read a `t` that
copy 1's `c` already moved, so the **condition** is stale → the fix's own fence
fires, correctly. Rolled: `gateIsHarmless` leg 2 grants the barrier `%8`
(`b = cq_theta(t,.5)`, which re-executes every trip before the branch), so the
**condition is genuinely fresh at the mint** — I re-derived this by hand and the
accept is right. What is wrong in the rolled form is `c = cq_theta(t,0.9)` reading
the stale `t` and `cq_measure(c)` reading the accumulated rail — i.e. F-1b2-1.

**Proposed disposition:** none of its own. Fixing F-1b2-1 closes both spellings;
until then the pair is the cheapest witness that the class is open, and belongs in
the F-1b2-1 bd issue as its in-loop member.

---

## F-1b2-3 — DOC / dead code: `collectWireValues`' new `Taint` parameter has no caller that supplies it

**Severity: DOC.** MEASURED:

```
$ grep -rn "collectWireValues(" ir-pass/ | grep -v '^ir-pass/include/WireWalk.h'
ir-pass/src/WireWalk.cpp:64:  void collectWireValues(Value *Seed, bool CrossValueRouting,   <- definition (anonymous namespace, file-local)
ir-pass/src/WireWalk.cpp:211: collectWireValues(const_cast<Instruction *>(V), /*CrossValueRouting=*/true, Wire);   <- the ONLY call, 3 args
```

`collectWireValues` is file-local (anonymous namespace) and has exactly one
caller, `thetaOnPathTo`, which passes three arguments, so the defaulted `Taint`
is **always `nullptr`** and the new disjunct in that function is **unreachable**.

This is not a correctness defect, but two pieces of shipped prose read as if it
were live and should be corrected before they harden (the F-1b-4 lesson, and
`CLAUDE.md`'s `fenv` paragraph):

* the **commit message** — *"`findNonDiagonalWireGate`/`collectWireValues` take an
  optional trailing `const TaintSet*` **and cross a chained theta's arg-0 edge
  whenever the parent is TAINTED**"* — is true of the first and vacuous of the
  second;
* `WireWalk.h`'s new block says *"A null `Taint` keeps the old ancestry (the
  per-activation `thetaOnPathTo` caller, whose parity gap is recorded with bd
  `test_C_libtooling-r903`)"*, which correctly names the gap but reads as a
  *choice among callers*. There is no choice: **no** caller supplies it.

**Why it matters beyond tidiness.** `thetaOnPathTo`'s only consumer is
`phiTracksWire`, and there the polarity is **inverted** — `ArmClassify.cpp:645`
says so in as many words: *"`phiTracksWire`'s other caller uses it as a BARRIER,
where `false` refuses and over-refusing is free; HERE it is a PRECONDITION, so
`true` GRANTS and an over-permissive answer would be an OVER-ACCEPT."* A narrow
wire closure makes `thetaOnPathTo` answer **false** more often, hence
`phiTracksWire` **true** more often, hence the R6 precondition and
`gateIsHarmless` leg 2's barrier granted more often. **The parity gap is in the
accept direction**, and it is 100 % open, not partly closed.

**I could not reach it** (§Negative space D): the shapes in which `phiTracksWire`
is the decider are exactly the shapes in which the widened ancestry does not reach
the sibling either (the seed is a PHI, so the theta-arg-0 crossing never fires;
when the seed is a theta the crossing fires but `SeedDef` is a `CallInst` and
`phiTracksWire` is not consulted). That is an argument about today's callers, not
an invariant.

**Proposed fix:** either delete the unused parameter, or thread `Taint` into
`thetaOnPathTo`/`phiTracksWire` **as its own change with its own Rule-13 round**
(it moves an accept-direction predicate, so it is not a free widening), and in
either case restate the two sentences above to say which half shipped live.

---

## F-1b2-4 — DOC: the rewritten `railCondWireDisposition` header is still not literally true

**Severity: DOC.** Round 1's F-1b-4 found the header's justification for dropping
the positional prong false; the fix rewrote it. The new text says:

> "Two prongs of the compare version are deliberately absent: the same-block/positional
> scan and the `ShareCondFlag` clause … The prong stays absent because the walk with
> `Taint` asks the rail's whole wire, in this block or another, with the DT prong."

The compare path's own P5 comment, twelve lines away and **unchanged**, states the
prong's purpose differently:

> "the positional scan fires even for a theta on **ANOTHER wire**, which no wire walk can see"

and, at the code:

> "a tainted-operand theta between the compare and the branch is a decline **even on
> another wire**, and no position-aware proof can reach it … the scan also covers
> wires the walk never sees."

The widened walk closes the **same-wire** half (that is F-1b-1) and still cannot
see the other-wire half, so the rail path is missing a backstop the compare path
keeps. The header now gives a *narrower* reason that reads as a *complete* one.

**Measured, and it is safe today for a reason the header does not state.** The
only aliasing a wire walk cannot see is the dtzb in-place `add`/`xor`, which the
forward walk deliberately does not cross. I built it both ways:

```llvm
; h/w1_rail_inplace_bridge.ll — RAIL condition
  %b = call i1 @cq_theta_i1(i1 %u0, double 5.000000e-01)
  %x = xor i1 %b, true
  %c = call i1 @cq_theta_i1(i1 %x, double 9.000000e-01)
  br i1 %b, label %arm, label %merge          ; would be STALE if %x were in place
```

FIX and PRE both **ACCEPT**, and the accept is **correct** — measured, the `xor`
lowers **OUT of place**:

```
%h_op = call i32 @cq_template_xor_i1_hl(i32 %h, i1 true)   ; a FRESH rail
call void @cqrt_ry_i1(i32 %h_op, double 9.000000e-01)      ; %c is on %h_op
call void @cqrt_rz_i1(i32 %h, double 0x3FE6666666666666), !cq.branchphase
```

The structural reason: a condition's rail is **always** read later by the branch
in `R.Pred`, and M-C's G6 ("no data use AFTER the site") therefore refuses the
in-place conversion on that rail — so the one aliasing the walk cannot see cannot
arise on a condition rail. `h/w2_cmp_inplace_bridge.ll`, the compare spelling of
the same shape, **DECLINES on both binaries** via P5 — i.e. the compare path
**over-declines** the identical (safe) program.

**Proposed fix:** state the real reason in the header — "the prong's residual
target is an in-place `add`/`xor` alias the walk does not cross, and M-C's G6
structurally refuses that conversion on a rail the branch reads later" — with
`w1`/`w2` committed as the ACCEPT / over-decline pair, or add the prong to the
rail path too (cheap, decline-only, and removes the asymmetry).

---

## F-1b2-5 — OVER-DECLINES (list only; none is a correctness problem)

The 19 plain-C movers are enumerated in §Negative space B. **Seventeen of them are
genuine** — each has two in-place Ry on one physical rail with the branch reading
the earlier name, i.e. exactly F-1b-1 reached through a new parent kind. Two are
over-declines, both already documented, and one pre-existing asymmetry is listed
with them:

| probe | shape | new string | note |
|---|---|---|---|
| `p/p20_measure_sidepath.c` | `if(v) r=cq_measure(b); if(b) cq_phi(θ);` — measure on a classical side path | `condition measured before the control route` | round 1 (F-1b-2) established this is a Rule-6 **letter** violation with **no wrong unitary** (after the measurement the register is a basis state, so the emitted `Rz` and the source's `cq_phi` on a collapsed `b` are both global). Declining it is the safe direction and matches the fence's rewritten header; it is an over-decline all the same. |
| `h/w2_cmp_inplace_bridge.ll` | compare condition + an out-of-place `xor` + a theta on the fresh rail | `condition predates a non-diagonal gate` | **PRE-EXISTING**, not a mover — the compare path's P5 positional prong fires on a theta that is provably on a *different* rail (measured: `cq_template_xor_i32_hl` mints it). The rail path accepts the same program correctly (F-1b2-4). |
| `h/w4_select_parent.ll` | select-router parent, sibling theta | `condition predates a non-diagonal gate` (was `tainted value muxed by a classical-condition select`) | **not** a disposition change — declines on both binaries; only *which* diagnostic wins moved. Hand-IR only; no shipped fixture pins it (0 DIAGDIFF over 1732). Worth knowing before writing a fixture on this shape. |

**Not a blanket refusal — measured on plain C.** Three legitimate programs whose
theta hangs off a tainted non-theta parent all still ACCEPT on the FIX binary:
`p/oc1_two_templates.c` (two thetas on **two different** template rails of one
`q`), `p/oc3_template_parent_post_chain.c` (template parent + a post-region
**chained** theta), `p/oc4_bool_template_parent_single.c` (the F-1b-1 program with
the sibling removed), plus `p/x1c_selmerge_out_nosibling.c` (a 4.4 merge `%out`
parent, single theta) and round 1's `p/p07_chained_after.c`.

---

## Negative space — what I attacked and found nothing

### A. The Exempt-set widening is decline-monotone — proof, then measurement

This was the brief's most important question ("prove the change is monotone or
find the counterexample"). **Proof.** The new disjunct fires only when `CI` is a
`cq_theta_` call and `Arg0` is tainted **and not** a `cq_theta_`/`cq_phi_` call
(if it were, the old condition already crossed). So each newly-reached ancestry
value `V := Arg0` is a **non-theta**; on the next iteration
`isCallToPrefix(CI,"cq_phi_")` and `isCallToPrefix(CI,"cq_theta_")` are both
false, so the loop `break`s. Therefore:

1. **`Exempt` never gains a `cq_theta_` call.** The forward walk skips a candidate
   only at `if (Exempt.count(CI)) continue;`, and that test is reached only for
   `cq_theta_` users — so **no gate that was flagged before can become exempt**.
2. **`Work` only grows**, so the forward reachable set is a **superset**.
3. **The per-candidate proof is unchanged**: `gateIsHarmless(EmitPoint, CI, Seed,
   Seeds, DT)` takes `Seed` (this iteration's original seed) and `Seeds` (the
   caller's array), neither of which the widening touches.
4. Hence if the old walk returned non-null for some gate `G`, `G` is still a
   candidate and still non-harmless, so the new walk returns non-null.
   `findNonDiagonalWireGate != nullptr` is **monotone**. Only the *identity* of
   the first returned gate (hence a `!dbg` anchor) can change.

Termination is unaffected: at most one extra hop, ending at a non-call or a
non-theta call.

**Disposition monotonicity at the callers.** `condWireDisposition` /
`railCondWireDisposition` can move `None → ProvenPostRegion`; at the kickback site
(`ArmClassify.cpp:4029`) both are accepts, so this is behaviourally identical
there; at `classifyArms` (`:2204`) it only sets `DeferredWireGate`, which changes
the *message* of an otherwise-declining region, never the verdict. Measured: **0
DIAGDIFF over 1732 fixtures**, so no shipped message moved.

**Measurement.** 1732 pre-existing fixtures PRE vs FIX: **0/0/0**. 124 plain-C
programs: **19 movers, all `accept → decline`, 0 `decline → accept`, and 0 OUTDIFF
among the 65 that accept on both.**

### B. The 19 movers (PRE → FIX), all `rc 0 → 1`

```
p20_measure_sidepath                    condition measured before the control route
p80_sibling_theta_from_C                condition predates a non-diagonal gate
p80b_ifc                                condition predates a non-diagonal gate
p81_sibling_theta_int_twin              condition predates a non-diagonal gate   (PRE-EXISTING on main — round-1 OQ-1b-R1-2, now closed)
a02_cmp_parent      (icmp parent)       condition predates a non-diagonal gate
a03_cast_parent     (trunc parent)      condition predates a non-diagonal gate
a04_select_merge_parent                 condition predates a non-diagonal gate
a09_inplace_xor_parent                  condition predates a non-diagonal gate
e1_cmp_ne / e2_cmp_gt / e4_dataselect   condition predates a non-diagonal gate
e7_tree                                 operand predates a non-diagonal gate     (opcode layer)
e8_nest                                 condition predates a non-diagonal gate
l1u_unrolled                            condition predates a non-diagonal gate
m1_measure_after_region_inloop          condition measured before the control route
x1_selmerge_out_sibling / x1b (bool)    condition predates a non-diagonal gate
x5_switchmux_sibling                    condition predates a non-diagonal gate
x6_qram_sibling                         condition predates a non-diagonal gate
```

Every one of `a02`/`a03`/`a04`/`a09`/`e*`/`x1`/`x5`/`x6` is a **new parent kind**
for F-1b-1 (compare, cast, 4.4 select merge, in-place-`xor` reassignment, 4.5
switch data-mux, QROM read) that accepted on the pre-fix binary — so the fix
closes a **class**, not the one shape round 1 reported.

### C. Attack 1(b) — crossing into a PHI / select parent

* A genuine **two-register** phi parent (`h/w3_phi_parent_two_regs.ll`) is refused
  earlier, on **both** binaries, by `declineClassicalMuxes`
  (`cq taint escape: tainted value muxed by a classical-condition phi`). So the
  only phis that can be a theta's tainted parent and survive are one-register
  routing phis and lowered merge out-rails — all of which denote **one** rail, so
  walking forward from them cannot flag a theta on a different rail.
* The walk cannot **miss** a gate it used to find: by §A.2 the reachable set is a
  superset, and `CrossValueRouting` phi/select hops are pushed identically.
* A loop-header phi parent (`p/a06_loopphi_parent.c`, `p/x7_loopout_sibling.c`)
  declines identically on both binaries at
  `cq loop lowering: loop-carried rail has multiple in-place consumers`.

### D. Attack 4 — the `thetaOnPathTo` parity gap

Structural, not measured-exploitable; see F-1b2-3 for the accept-direction
polarity. The reason I could not reach it: `phiTracksWire` is consulted from
`gateIsHarmless` only when `SeedDef` is a `PHINode`, and from R6
(`recordLivePerActivation`) only when the record member `M` is a `PHINode` — but
the widened ancestry crossing fires only when the **seed is a `cq_theta` call**.
The two conditions are disjoint at the seed:

* seed is a **phi** ⇒ the backward closure `break`s at the phi (not a `CallInst`),
  the crossing never fires, and the candidate set is unchanged from PRE;
* seed is a **theta** ⇒ the crossing fires, but `SeedDef` is a `CallInst` and
  `phiTracksWire` is never asked about it.

The residual is the **superseding-phi** loop inside `gateIsHarmless` (a phi drawn
from `Seeds`, i.e. from `condProvenance`, can still be handed to `phiTracksWire`
with a narrow closure). I could not build a program that reaches it *and* has a
narrow/wide disagreement; that is a statement about my probes, not a proof.

### E. Attack 5 — `isPotentiallyReachable` in `railMeasuredBeforeBranch`

The fence now discriminates exactly as its rewritten header says:

| probe | shape | FIX | PRE |
|---|---|---|---|
| `h/m11_measure_reachable_sidepath.ll` | measure on a classically-guarded side path that **reaches** the branch | **DECLINE** | ACCEPT |
| `h/m10_measure_unreachable_arm.ll` | measure in a sibling arm the branch can **never** follow | **ACCEPT** | ACCEPT |
| `p/m1_measure_after_region_inloop.c` | measure after the region **inside a loop** (reaches the branch next trip) | **DECLINE** | ACCEPT |
| `p/m3_measure_after_straightline.c` | measure strictly after the region | ACCEPT | ACCEPT |
| `p/m4_measure_before_uncond.c` | unconditional measure before the branch | DECLINE | DECLINE |

`m1` is a real capture: pre-fix, iteration 2's `cqrt_rz_i1` fired on an
already-measured register. The `!DT` path is *narrower* than before (old code
returned `true` unconditionally with a null tree; new code asks the CFG walk) —
that narrowing is sound because a measurement the branch can never follow really
is downstream, and `isPotentiallyReachable` bails **`true`** past its 32-block
scan limit, i.e. toward refusal.

The pre-existing compare-side hole round 1 named is **unchanged and still open**:
`p/p30_int_twin_measure_sidepath.c` (an **unconditional** `cq_measure(b)` then
`if (b == 1) cq_phi(θ)`) still ACCEPTS on all three binaries and mints
`cq_template_icmp_eq_i32_hl` from the measured register. Disclosed as bd `r903`;
not widened here.

### F. The accept boundary of the widening IS pinned — measured with a mutant

A fixture suite that only contains the four new *declines* would not stop a future
change turning the crossing into a blanket refusal. I measured whether it would.
**Mutant M-X** (built in a throw-away worktree at `596cd73`): when the F-1b-1
taint crossing fires, clear the per-seed `Exempt` set — i.e. every chained theta on
a tainted non-theta parent becomes a candidate. Liveness confirmed
(`x1c_selmerge_out_nosibling`, `e6_sibling_after_branch`, `a10_grandparent_inplace`
all flip to DECLINE). Over HEAD's **1736** fixtures, **11 redden** (all
`ACCEPT → DECLINE`):

```
control_angle_select_ry_derived_base_late_use_frozen.ll
control_swap_accept_post_region_theta.ll
control_swap_accept_two_iterations.ll
control_swap_inloop_postloop_railop.ll
control_swap_inloop_postloop_railop_mc.ll
control_swap_inloop_railop_inplace.ll
lowering_inloop_derived_cond_leading_gate.ll
lowering_mc_late_grover2_offset.ll
lowering_mc_seq_region_customer.ll
lowering_uncompute_interior_leak_ry_on_rail.ll
spec_reseed_theta_source.ll
```

So the non-blanket property is a **measurement**, not an assertion. (None of the
four *new* fixtures is among them; the property rides on pre-existing accepts. A
one-line note in the new fixtures' headers naming this set would make the
red-green pair self-documenting.)

### F2. The F-1b-3 angle-select guard is inert, as round 1 predicted — verified

`AngleSelectEmit.cpp:245`'s new `!isCondRailLeaf(Cond) &&` is defence in depth, and
I confirmed it changes nothing today. `p/as1_rail_angle_select.c`
(`bool b=cq_theta(0,.5); double a = b ? .9 : .3; cq_phi(a); return cq_measure(b);`)
and `p/as2_rail_angle_select_dead.c` (the same with `b` dead) both ACCEPT with
**byte-identical** traces on PRE and FIX —

```
cqrt_alloc_i1(0) -> h0 ; cqrt_ry_i1(h0,.5) ; cqrt_rz_i1(h0,-.3) ; cqrt_rz_i1(h0,.9)
```

— the two kickback gates keep `Cond` live, so step 4's `use_empty()` is false in
both spellings and the guard is never the decider. The rail is **left allocated**
(`0 cqrt_free site(s)`, Rule-6 safe direction) in both. The guard is correct to
add: it removes an emission-order accident, at zero measured cost.

### G. Suites

* `ctest -R ir-pass-lit` — **Passed, 44.35 s, 0 failed** (1736 `.ll` on disk,
  `ls ir-pass/test/*.ll | wc -l`). I did **not** run the full ctest suite (out of
  scope for this review); the fix's own record reports e2e 367/367 with zero
  golden churn, and I confirm `git status --porcelain tests/` is empty.
* `ctest -R 'twin-identical|phase-bool|free-pairing-selftest|quarantine-selftest'`
  — **38/38 passed, 4.13 s**, including all six in-loop rolled-vs-unrolled
  `cmp` twin gates and the loop-twin quarantine self-test.
* Attack 3 (loops), independently: `p/l2_grover_loop.c` (Grover rolled) and
  `p/l3_perbit_loop.c` (D4's per-bit idiom) accept with traces **byte-identical**
  between PRE and FIX.

### H. Attack 6 — Rule 1, no third path

All **124** plain-C programs, both accepting (65) and declining (59): **zero**
outputs contain a surviving `@cq_theta_*` / `@cq_phi` / `@cq_measure_*` call, and
**zero** contain a `br i1 %v` whose `%v` is defined by a `cq_template_*` or
`cqrt_*` call. `free_pairing_check.py` reports `0 violation(s)` on every accepting
probe. The four new decline fixtures' shapes exit non-zero with **0 bytes on
stdout** (so their IR-text `CHECK-NOT`s are vacuous — correctly documented in each
header; the `not` wrapper is what pins them).

### I. Attack 7 — the compare twin, every spelling I could reach

No spelling of the sibling-before-the-branch shape is left accepting:

| spelling | layer that declines |
|---|---|
| `if (b)` on a `_Bool` (rail leaf) | control — `condition predates a non-diagonal gate` |
| `if (b == 1)` / `if (b != 0)` / `if (b > 0)` on an `int` | control — same string |
| `b ? 7 : 9` (tainted data select) | control — same string |
| `b == 1 && q > 5` (condition tree) | **opcode** — `operand predates a non-diagonal gate` |
| nested `if (b==1){ … if(q>5) … }` | control — same string |
| angle select `cq_phi(b ? .9 : .3)` | control — same string (was `rotation angle` on PRE) |
| `switch (b)` | pre-empted by an unrelated QRAM decline; not reachable at `-O1` |

Note the brief's premise that "the compare twin now declines in the OPCODE layer"
holds only for the **tree** spelling (`e7`); the plain `icmp` spellings decline in
the **control** layer. Both are loud and both mirror an existing string.

---

## Owner questions

* **OQ-1b-R2-1.** F-1b2-1 needs its own bd id and an owner call on scope: it is a
  CONFIRMED silent miscompile from one line of plain C, present on `main`, and the
  proposed fix (sweep `cq_theta`/`cq_measure` readers with the existing
  `checkStaleOp`) is small — but it is a Rule-13-core widening of
  `declineStaleRecordOps` and will need its own adversarial round. Ship it as a
  follow-on to `3qlq.4`, or fold it in?
* **OQ-1b-R2-2.** F-1b2-3: delete `collectWireValues`' unused `Taint` parameter, or
  thread it into `thetaOnPathTo`/`phiTracksWire`? The second moves an
  **accept-direction** predicate (`ArmClassify.cpp:645`) and must not ride this
  commit.
* **OQ-1b-R2-3.** F-1b2-4: correct the `railCondWireDisposition` header to the real
  (structural) reason, or add the positional prong to the rail path and delete the
  asymmetry? The prong is decline-only and cheap; `h/w2` shows the compare path
  already pays an over-decline for it.
* **OQ-1b-R2-4.** F-1b2-5: `p/p20_measure_sidepath.c` is now a decline that round 1
  established is not a wrong unitary. Keep the stricter fence (my recommendation —
  it is what makes `m1` decline) and record `p20` as a documented over-decline?
