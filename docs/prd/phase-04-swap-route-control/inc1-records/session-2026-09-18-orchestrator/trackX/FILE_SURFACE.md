# Track X — FILE SURFACE + THE WITNESS VERDICT (bd `test_C_libtooling-x5fp`)

Session 2026-09-18, orchestrated. Worktree
`/Users/sorenwilkening/Desktop/Projects/CQ_lang/.claude/worktrees/agent-aacc88be824ade5ef`,
branch `x5fp-clobber-per-activation`. Every verdict below was MEASURED on the frozen ORACLE
`build/ir-pass/cq-opt` sha256 `9bd01598d574b344646281a144cf628ed4ed947d6d20df61cfcb717d321a13b3`
(`libCQPass.so` `3e3dc35d…`) — and my own worktree build at `-j2`, BOTH targets, reproduces those
two hashes **byte for byte**, so "oracle" and "pre-edit subject" are the same binary here.

---

## 0. THE ONE LINE AT THE TOP, AS THE BRIEF ASKS FOR IT

**NO ACCEPT WITNESS EXISTS. There is no program — C at `-O1`, nor hand IR — for which S-1 is the
only wall. The increment lands as a PARKED BRANCH.** The measurement that decides it is a
ONE-OPERAND isolating pair (§2.3): `h1` declines `arm rewrites a condition operand`, and `h2b` —
the same module with the compare's second operand changed from the classical carrier to a constant,
so that §3c cannot fire — declines `cq controlled lowering: control flow inside a loop body under
quantum control`. Removing the clobber does not produce an accept; it produces the next wall.

---

## 1. TWO CORRECTIONS TO bd `x5fp`'s OWN TEXT, both measured

### 1a. The owner's program does NOT reach the `diagonalAliasHit` prong. It reaches its TWIN.

bd `x5fp` names *"`ArmClassify.cpp:4593` `diagonalAliasHit`+`StraightThrough`"*. Measured with
`CQ_CTRL_DBG=1` on the oracle:

| probe | anchor printed | ⇒ site |
|---|---|---|
| `x01_owner_scalar.c` (= `trackL/probes/s_loop_n2.c`) | `%15 = zext i1 %14 to i8` | **`ArmClassify.cpp:5901-5905`** — the HOISTED/LEAF disposition, `const bool Clobber = StraightThrough && Prov.count(StraightThrough) != 0;` |
| `h1_inloop_diamond_value_backedge.ll` | `%r1 = add nsw i32 %r, 3` = `Chain.Ops.front()` | `ArmClassify.cpp:5774-5781` — the `diagonalAliasHit(Routed, Prov)` prong |

The reason is structural and is worth writing down because it changes what the increment is:
`walkValueChain` follows **`BinaryOperator`s only**, and the owner's `_Bool` arm is
`%15 = zext i1 (@cq_theta_i1 (trunc i8 %9)) to i8` — a CAST, so `Chain.Ops` is **empty**, the
`if (!Chain.Ops.empty())` block is skipped entirely, and control falls to the leaf disposition.
(`Chain.Ops.front()` on that path would be a read of an empty `SmallVector`.)

**The consequence is the load-bearing half: at `:5901-5905` BOTH branches are `declineArm(...)
; return Declined`.** `Clobber` chooses only the STRING — `arm rewrites a condition operand`
(PERMANENT) versus `value-arm swap-route` (deferred). **No narrowing at that site can ever produce
an accept.** The site whose outer test gates an accept is `:5774`, and that one is reached only
from hand IR (§2.2).

### 1b. For the owner's program the §3c fence is an ARTEFACT OF THE `i8` WIRE (bd `r903`), not a wall on the critical path.

`h5_inloop_i1_carried_theta_arm.ll` is x01 with the `trunc`/`zext` pair removed — i.e. what x01
would look like if bd `r903`'s `_Bool`-wire transparency had landed. The arm is then a bare
`@cq_theta_i1` call, `inPlaceRotationArmTheta` (R1) claims it, and the VALUE path — the only path
that consults §3c — is never entered. **Measured: it declines `cq controlled lowering: condition
predates a non-diagonal gate under quantum control`** — S-2, the 2c wire fence, which is
bd `drbq.12` = **Track D**, this session, Group 2.

So on the owner's scalar-loop spelling the peel ladder is not `S-1 → S-2 → S-3 → S-4` with S-1
first *in principle*; S-1 is first only because the `_Bool` is carried at its memory type. Land
`r903` and S-1 disappears from that program without this track touching anything. Recorded for the
orchestrator; NOT a reason to close `x5fp` (the fence still mislabels a back-edge overlap as
information-theoretically impossible — §3).

---

## 2. THE WITNESS QUESTION, answered by measurement

All rows on the ORACLE `9bd01598`; runner
`trackX/probes/run.sh` (stage-1 `clang -O1 -g`, then `cq-opt`, then stage-2b + link + run on an
accept). `.ll` probes are fed to `cq-opt` directly.

### 2.1 From C at `-O1`, the `:5774` prong is STRUCTURALLY UNREACHABLE

`valueArmIsPureChain` requires the arm block to contain **nothing but** the chain's
`BinaryOperator`s — and `-O1` if-converts exactly that shape into a `select`, so the diamond the
prong needs never survives:

| probe | shape | verdict |
|---|---|---|
| `x05_flat_backedge_free_clobber.c` | `if (q >= 3) q = q + 3;` — the textbook §3c clobber | **ACCEPT** (15 lines): `-O1` made it a 4.4 `select`; §3c never consulted |
| `x07_flat_diamond_chain_clobber.c` | a FOUR-op chain, `s = q+1` as the condition | **ACCEPT** (17 lines): `-O1` speculated all four ops and folded the compare to `icmp sgt %1, 1` |

So every shipped fixture that pins the `:5774` prong is hand IR, and so are the two witness
candidates below.

### 2.2 The three witness candidates, and why each fails

| # | candidate | what it was meant to show | measured |
|---|---|---|---|
| A | `x02_classical_carrier_value.c` — the back edge closed through a CLASSICAL carrier (`cq_measure` is the taint sink), both registers iteration-local | a C program with a back-edge-only overlap | **ACCEPT already** (42 trace lines, STRICT 2b clean) — `-O1` if-converts the arm into a 4.4 select, and the select path has NO §3c-style clobber fence at all |
| B | `x08_inloop_chain_backedge_clobber.c` — the same with a four-op chain | keep the diamond alive in C | **ACCEPT already** (69 lines) — if-converted again |
| C | `h1_inloop_diamond_value_backedge.ll` — hand IR, a real rolled diamond, the overlap through the back edge only | reach `:5774` with a back-edge-only overlap | **DECLINE `arm rewrites a condition operand`** — reached, as intended |

Candidate C is the only one that reaches the prong. Its isolating controls are what settle the
question.

### 2.3 THE DECIDING PAIR — one operand apart

| probe | difference from `h1` | measured verdict |
|---|---|---|
| `h1_inloop_diamond_value_backedge.ll` | — | `arm rewrites a condition operand` (site `:5774`) |
| `h2b_inloop_diamond_value_onecond_control.ll` | the compare's 2nd operand is `0` instead of the classical carrier `%a`; the φ, the CFG and every other value are unchanged | **`control flow inside a loop body`** |
| `h2_inloop_diamond_value_nobackedge.ll` | the carrier φ deleted as well | `control flow inside a loop body` |
| `h4_flat_diamond_value_noclobber.ll` | not in a loop, no clobber | **ACCEPT**, 15 trace lines, STRICT 2b clean |
| `h3_flat_diamond_value_clobber.ll` | not in a loop, genuine within-activation clobber | `arm rewrites a condition operand` (the negative control that must NOT move) |

The wall behind S-1 is named in source, not inferred — `ControlDetect.cpp`, **"IN-LOOP SCOPE FENCE,
part 2 — a method-B VALUE arm inside a loop"**, which runs *after* `classifyArms` returns:

```
if (R.InLoop && (R.ClassArm == ArmClass::Value || R.ClassArmFalse == ArmClass::Value)) {
  diagnoseUnderControl(BI, "control flow inside a loop body");
```

That is bd `3qlq.6` / bd `1dbk` item 1 (the in-loop VALUE arm), **not** bd `ej5w` (whose subject is
`LoopLowering`'s X1 clause, a different site reached by a different spelling), and it is not this
track's.

### 2.4 Why a back-edge-only overlap FORCES an in-loop value arm (so the result generalises)

For the overlap to exist *only* around the back edge, `condProvenance` must reach `Routed`
exclusively through some φ's LATCH incoming, and the region must be inside that same loop — a
region *after* the loop reads its operands in one activation and the arm writes after that read, so
its overlap is an ordinary sequential one, not a back-edge one (`h3`'s class).

Inside the loop the region is a VALUE arm by construction (the §3c string exists on no other arm
class), and the three remaining §3c sites are refused earlier for their own reasons, all read in
source:

* the 6.5 classical-call arm — `ControlDetect.cpp` **"IN-LOOP SCOPE FENCE, part 1"** SKIPS
  `classifyClassicalCallArm` entirely when `R.InLoop`;
* the `switch` twin (`SwitchArmProve.cpp:238`) — `ControlDetect.cpp:821` declines a tainted-scrutinee
  `switch` on a cycle *before* the G-ladder;
* the `:5901-5905` twin — both branches decline (§1a).

**Hence: S-1 is never the only wall, in any spelling, on any binary.**

---

## 3. WHAT THE INCREMENT THEREFORE IS — a D→D string move, and why it is still worth landing

The fence's own source comment states the rule it is currently breaking:

> The PERMANENT string fires ONLY on the proven diamond identity … Everything else in the
> provenance-overlap family declines GENERIC `control flow` (§8 review 2026-06-10 — the Defect-2
> lesson, inverted: **never brand a shape information-theoretically impossible on unproven
> evidence**).

A back-edge overlap is exactly unproven evidence: within one activation the flag is minted strictly
before the arm writes, and the rails are disjoint (§4). So the increment moves those modules off the
PERMANENT string onto the honest one — `control flow inside a loop body` at `:5774` (via
ControlDetect part 2) and `value-arm swap-route` at `:5901` — and leaves an L8 retirement trigger
saying which bead turns each into an ACCEPT. That is CLAUDE.md L6 ("a structural guard wearing a
semantic label") applied to the DIAGNOSTIC rather than to the accept set, and it is all that is
available until bd `3qlq.6` lands.

---

## 4. FILE:FUNCTION SURFACE (tight, and Group-2 relevant)

**One production file: `ir-pass/src/ArmClassify.cpp`.** Nothing else under `ir-pass/`,
`include/`, `runtime/`, `tools/`. No new frozen symbol, no ABI, no new decline string.

| # | site (line numbers AS LANDED, `677472eb`) | function | what changes |
|---|---|---|---|
| 1 | NEW, file-local, `:798` — inside the anonymous namespace that opens at `:446`, after `recordLivePerActivation` and after `railWireClosure` (`:526`), which it needs | `condProvenanceInActivation` | `condProvenance` (`:281`) expression for expression, plus ONE pruning rule: when the walk reaches a `PHINode P`, it does not enter incoming values arriving on a **back edge of the loop `L` that contains the region's branch**. With `L == nullptr` it IS `condProvenance`, byte for byte. |
| 2 | NEW, file-local, `:904` | `clobberHoldsPerActivation` | the three conjuncts of §5, and the ONLY consumer of (1) |
| 3 | `:5959` (was `:5774` pre-edit) | `classifyArms`, the `diagonalAliasHit` prong | the outer test gains the per-activation conjunct |
| 4 | `:6099` (was `:5901` pre-edit) | `classifyArms`, the hoisted/leaf disposition | `Clobber` gains the same conjunct, by CALLING the same predicate — never by re-deriving it |

`condProvenance` itself is **NOT TOUCHED** — see §6, the L2 obligation.

`railWireClosure` (file-local, `:526`) is CALLED, not re-derived, for the rail-disjointness conjunct.

### Group-2 collision surface with Track D (bd `drbq.12`)

Track D edits `condWireDisposition`'s P4 prong (~`:2844`) and `RegionTreeDetect.cpp`. My edits are
at `~:300` (a new function) and `~:5774` / `~:5901`. **Disjoint line ranges; one shared file.**
The only semantic coupling is `condProvenance`, which I do not modify — so Track D's P4 window and
the 2c fence see the identical cone before and after my branch. `git merge` should be mechanical.

---

## 5. THE PREDICATE, and the over-accept it must NOT open

The overlap is treated as a non-clobber only when ALL THREE hold:

* **(P1)** `Region.InLoop`, and `L = LI->getLoopFor(BI->getParent())` is non-null — "activation"
  means one trip of *the region's own* loop. Pruning a back edge of a loop the region is not in
  says nothing about the region's activation, and would open `h3`'s class.
* **(P2)** the clobber evidence is absent from `condProvenanceInActivation` — i.e. the overlap
  exists ONLY around the back edge. (`Hit` at site 2, `StraightThrough` at site 3.)
* **(P3)** **RAIL DISJOINTNESS**: `railWireClosure(Routed, BackwardOnly)` is disjoint from the union
  of `railWireClosure(M, BackwardOnly)` over the members of the in-activation provenance.

**(P3) is not belt-and-braces; it closes a hole that (P1)+(P2) alone would open into an already-open
P1.** The construction: a loop-carried rail φ `%p`, the condition `icmp sgt %p, 2` at the top of the
body, a dtzb IN-PLACE `%p2 = add %p, 1` between the compare and the branch, and the region routing
`%p2`. `%p2` reaches the condition's cone only through the back edge, so (P1)+(P2) would grant —
yet `%p2` names the SAME PHYSICAL RAIL as `%p`, the flag is minted from a basis the `addc` has
already relabelled, and the arm relabels it again. The 2c fence does **not** catch it: its walker is
spelled over `thetaOnPathTo`, which counts a `cq_theta` and does **not** count the dtzb in-place
`add`/`xor` (`WireWalk.h`'s recorded vocabulary gap — bd `a3z7`, re-raised to P1 in CLAUDE.md §5).
Today §3c catches that shape by accident, through the back-edge path. (P3) keeps it caught, and it
keeps it caught by asking the ONE owner of physical-rail identity rather than a second spelling of
it (Rule 14).

---

## 6. THE L2 OBLIGATION, discharged explicitly (the bead's own instruction: *narrow both or neither*)

`condProvenance` is the completeness carrier for **R4**, for **F2**'s `CondWire`, for gate **2c**,
for the rail ladder and for `CompareLowering`'s record — its own header says so at length, and it
says the two directions fail OPPOSITELY: narrowing it makes **R4 vacuous** (an over-ACCEPT, a flag
stripped against a relabelled register — Rules 6/8) while it only SHRINKS **F2**'s exclusion set (an
over-decline).

**Direction used here: I narrow the §3c PRONG, not the CONE.** `condProvenance` keeps its full
backward closure and every one of its callers keeps the identical set, byte for byte. The new
`condProvenanceInActivation` is a SECOND, STRICTLY SMALLER set with exactly one consumer (the two
§3c sites in `classifyArms`), and the §3c test becomes `full-cone hit ∧ ¬in-activation-absent`, so a
module can only move from DECLINE to DECLINE or from DECLINE to (a later) DECLINE — never from
DECLINE to ACCEPT while the in-loop value fence stands.

**Why 2c is NOT narrowed with it, stated rather than assumed.** 2c asks a different question —
*"is there a non-diagonal GATE on the condition's wire between the read and the mint?"* — and it
already owns per-activation machinery of its own (the P4/P5 prongs and
`chainedThetaBetweenDefAndBranch`, bd `hn29`/`leyd`/`52og`, landed 2026-09-15). Giving it a second,
differently-spelled per-activation reading out of this track is the drbq Inc-3 (b′) defect. Its own
back-edge over-decline is bd `drbq.12` — **Track D, this session, same group** — and it is being
narrowed there, in its own vocabulary, with its own Rule-13 round.

---

## 7. WHAT IS NOT CLAIMED

* No accept is recovered, at any site, in any spelling. The branch is PARKED.
* Nothing here says the owner's cascade gets closer to compiling. It does not: after this branch
  `x01` still declines, one string later.
* §1b is a measurement about `h5`, a hand-IR module. It is NOT a claim that bd `r903` is easy, nor
  that landing it makes x01 compile — `h5` itself then declines at S-2.
* The `:5901` site's `value-arm swap-route` string names a retired mechanism (CLAUDE.md §2, the
  rename is bd `OQ-13`). This branch does not rename it.
