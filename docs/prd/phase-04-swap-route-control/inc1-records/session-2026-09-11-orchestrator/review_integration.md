# Rule-13 INTEGRATION review — the four landed tracks as ONE binary

**Verdict: CLEAR-WITH-ITEMS.** No confirmed silent miscompile was found in the COMBINATION.
Four items, all in the DECLINE direction or documentation; one of them (I-1) corrects two
statements that are written down in the tree and are false as measured.

| field | value |
|---|---|
| subject | `/Users/sorenwilkening/Desktop/CQ_l4x4/build/ir-pass/{cq-opt,libCQPass.so}`, md5 `67aea34ec0…`, built 2026-09-11 21:06, newer than every `ir-pass/**` and `include/**` source in that worktree |
| subject source | byte-identical to `main` e96f89c: `git diff main l4x4b-bool-ry-arm --stat -- ir-pass include runtime tests tools` = **empty** (re-verified by me, first action) |
| oracle | `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}` at `main` 0c7380c, md5 `7399f5779c…`, **not rebuilt, not touched** |
| behavioural identification | the oracle DECLINES the owner's file `control flow`; the subject ACCEPTS it at 19 trace lines (§1). 334 of 770 corpus rows differ (§6) |
| my writes | this file + `review_integration_probes/` only. `ir-pass/`, `include/`, `tests/`, `tools/` untouched in every checkout; nothing built, nothing committed |
| independent gate | `cd /Users/sorenwilkening/Desktop/CQ_l4x4/build && lit -s ir-pass/test` → **1893 discovered, 1892 Passed, 1 Expectedly Failed, 0 unexpected**, 39.98 s |
| probes | **99** (97 single-TU + 2 two-TU), `review_integration_probes/`, runner `ab.sh` / `full.sh` / `run_multi.sh`; 34 accept on the subject, **every one traced and read against its source**, all STRICT stage 2b `0 violation(s), 0 unproven` |

---

## §1 THE OWNER'S FILE — the 19 lines re-derived from the state vector, independently

`example/grover/grover_oracle_uncompute.c`, unedited, `clang -O1` + the subject: `opt` exit 0,
**stderr 0 bytes**, stage 2b `6 rail mint(s) of which 5 left allocated, 1 cqrt_free site(s):
1 verified, 0 violation(s), 0 unproven`, links, runs, **19 trace lines byte-identical to
`MERGE_l4x4_1.md` §4**.

The stage-1 IR `-O1` hands the pass is four blocks: `%1 = cq_theta_i1(false, 0.5)`,
`br i1 %1, %4, %2` (the arm on the **FALSE** edge), an arm defining `%3 = cq_theta_i1(false,
0.5)`, and a merge carrying **two** φ — `%5 = phi i32 [5,%2],[2,%0]` (the `a` mux, both
incomings available at the pred ⇒ **peelable**) and `%6 = phi i1 [%3,%2],[false,%0]` (the `b1`
prep, arm incoming defined in the arm ⇒ **not** peelable). That is the b6ap `NotPeelable <= 1`
shape exactly, and it is why the peel takes `%5` and leaves `%6` for l4x4.b.

**The ideal state**, writing `Ry(θ)|0⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩`:

```
|ψ⟩ = cos(.25)·|0⟩_b0 ⊗ Ry(.5)|0⟩_b1 ⊗ |5⟩_a   +   sin(.25)·|1⟩_b0 ⊗ |0⟩_b1 ⊗ |2⟩_a
```

(`a` is 5 iff `b0 = 0`, and `b1` is prepared iff `a ≥ 3` iff `b0 = 0`.)

**The emitted stream realises exactly that**, in three blocks:

| lines | gates | what they realise |
|---|---|---|
| 1–2 | `alloc_i1(0)→h0; ry_i1(h0,.5)` | `b0 = Ry(.5)\|0⟩`. The `a>=3` guard folds away (`a` is the literal 5) |
| 3–5 | `alloc_i1(0)→h1; ry_i1(h1,.5); ry_i1_controlled(h0,h1,−.5)` | the **negated** prep. `b0=1 ⇒ Ry(−.5)Ry(.5) = I ⇒ \|0⟩` (the `[false,%entry]` incoming); `b0=0 ⇒ Ry(.5)\|0⟩`. Exact: one-axis Ry additivity `Ry(a)Ry(b)=Ry(a+b)` is exact in ℝ **and** `−0.5` is an IEEE sign flip, not an `fsub`, so there is no rounding subject here at all |
| 6–16 | `alloc_i1(0)→h2; cnot(h0,h2); alloc_i32(0)→h3; alloc_i32(2)→h4; copy_i32_controlled(h2,h4,h3); x(h2); alloc_i32(5)→h5; copy_i32_controlled(h2,h5,h3); x(h2); cnot(h0,h2); free(h2)` | the peeled `a` mux as r9e5's rail-root CNOT-copy select. After `cnot` the pair is `Σ α_x\|x⟩_{h0}\|x⟩_{h2}`; `h2=1` writes 2, the X-bracketed copy writes 5 when `h2=0`; the second `cnot` returns `h2` to `x⊕x=0` on **every** branch, so the `free` is a proven-\|0⟩ free (Rule 6, 2b `1 verified`) |
| 17–19 | three measures | source order, summed as `(m(b1)+m(b0))+m(a)` matching the stage-1 `add` order |

`h0` is read **three times as a CONTROL** (5, 7, 15) and measured once (17); it is **never
`cqrt_x`-bracketed and never freed** — Inc 1b's diagonal-only invariant and Rule 6's required
direction, since `Ry(.5)|0⟩ ≠ |0⟩`. The only two `cqrt_x` sit on the emitter-owned ancilla `h2`.

**The ORDER SWAP re-derived (brief item 5).** The emitted order is *b0 prep; b1 prep; a-mux*,
i.e. the last two are swapped against source. I re-derive the commutation rather than quoting it:

* the b1 block is `U = (I ⊗ Ry(.5)_{h1}) · (|0⟩⟨0|_{h0}⊗I + |1⟩⟨1|_{h0}⊗Ry(−.5)_{h1})` —
  block-diagonal in `h0`'s computational basis, acting on `h1`;
* the mux block touches `h0` only through `cqrt_cnot(h0, h2)`, where `h0` is the **control**, so
  `V = Σ_x |x⟩⟨x|_{h0} ⊗ V_x` on `(h2,h3,h4,h5)` — block-diagonal in the **same** basis;
* the target sets are disjoint (`h1` vs `h2,h3,h4,h5`), and two operators block-diagonal in one
  register's basis with disjoint targets commute: `U V = Σ_x |x⟩⟨x| ⊗ (U_x ⊗ V_x) = V U`.

I then tried to **break** leg (iii) — make the mux read the prep's target — every way plain C
allows, and every one declines (§3, O/Q/Y series).

---

## §2 THE NEIGHBOURHOOD OF THE OWNER'S FILE (brief item 1)

Oracle → subject. Every subject ACCEPT was traced and read against its source; all are
stage-2b clean.

| program | oracle | subject | reading |
|---|---|---|---|
| `V0` as written | `control flow` | **ACCEPT 19** | §1 |
| `C` `int b0 / int b1` | `control flow` | **ACCEPT 22** | b6ap's committed golden shape |
| `B` `bool b0 / int b1` | `control flow` | **ACCEPT 19** | `MERGE_l4x4_2` §5 row B, confirmed |
| `A` `int b0 / bool b1` | `control flow` | `state prep seed is proven equal…` | row A — **cause is I-1, not the recorded one** |
| `N1` + `if (b1) cq_phi(.3)` | `bare i1 register condition` | `branch phase on a bare i1 condition` | `b1` is the region's MERGE φ, not a rail root (Inc-1b `boi6` residual). Safe |
| `N2` + `if (b1) a += 1` | `control flow` | **ACCEPT** | `-O1` folds the arm to `a + zext(b1)`: no region at all. Q+Q add into a fresh rail, `zext` `_unc`'d and freed, `h3` left allocated. Correct |
| `N3` + `if (b1) b0 = cq_theta(b0,.2)` | `bare i1…` | `control flow` | safe |
| `N4` **S† on `b0` after everything** | `control flow` | **ACCEPT 20** | `cqrt_ry_i1(h0,−.5)` emitted **after** the un-copy `cnot` and the `free`, i.e. source order. The register is measured, never freed. **The S† passes the `_controlled` gate's fences** — the drbq structural freeze is on the controlled gate's arg-1 TARGET (`h1`), not on its control |
| `N4b` **S† on `b1`** (the frozen target) | `control flow` | **ACCEPT 20** | uncontrolled `ry_i1(h1,−.5)` after the region; `h1` frozen (never freed), measured. Correct |
| `N5` `b1` measured **before** its prep | `control flow` | **ACCEPT 21** | `ry(h0,.1); measure(h0); …; ry(h0,.5); ry_controlled(h1,h0,−.5)` — source order; an in-place Ry arm on a post-measurement basis state is a legal unitary and CQ inserted no measurement (Rule 5) |
| `N6` `b0` measured **before** the fused region | `control flow` | `condition measured before the control route` | A.1/r9e5 rung (ii). **OVER-DECLINE of this program** (the stream would be source-faithful) and the shipped posture; see I-4 |
| `N7` the two regions in a `for (i<2)` | `arm rewrites a condition operand` | **the same string, identically** | the §3c clobber fence fires **before** l4x4.c's `control flow inside a loop body`; no accept between them |
| `U0` the owner's commented block uncommented | — | — | **`clang` HARD COMPILE ERROR**, twice: `too many arguments to function call, expected single argument 'angle', have 2`, with a note at `CQ.h:73 void cq_phi(double angle)`. Exactly 3qlq Inc 1 D1. Never reaches the pass |
| `U1` the same block with the register-free `cq_phi` | `control flow` | `control flow` | the extra `if (b1 == 0) a -= 3` region declines on both |
| `N9` `int a = 5` → run-time `a` | `state prep seed…` | `control flow` | **the predicted F2 string is NOT what fires**: with the guard live there are three regions, and the shape declines earlier. Reported, not a defect |

---

## §3 THE COMPOSITION ATTACKS

### 3a. Peel × A.1 (brief item 2) — **the composition HOLDS, measured**

`R6_window_novalue` is the 9pum round-2 window whose compare is a **peeled** fused diamond's
condition (two TUs' worth of `%out` taint from a `noinline const` callee, then
`b = cq_theta(r,.25); b3 = cq_theta(r,.9)`, then `if (b==13) { a-=3; z=4; }` — two peelable φ):

* **ORACLE: ACCEPT**, and the emitted stream is the miscompile verbatim —
  `cqrt_ry_i32(%out,.25); cqrt_ry_i32(%out,.9); cq_template_icmp_eq_i32_hl(%out,13)`: the flag
  minted from `Ry(.9)Ry(.25)|out⟩` while the source compares `Ry(.25)|out⟩`;
* **SUBJECT: DECLINE `condition predates a non-diagonal gate`.**

So A.1's `CmpCondReads` record reaches the peel's compare CLONE and `reverifyCmpCondReads`
re-asks it after the round-2 fixpoint. `R7` (the same window with a hand-written `?:`, no peel)
moves identically, which is the control.

I also checked the placement obligation in source rather than assuming it: the peel is called
immediately before **all three** `detectControlRegions` sites (`CQLoweringPass.cpp:451/938`,
`TaintPropagation.cpp:1430`), the two round-1 sites pass a `Delta` to `adjudicateTaintDelta`,
and the round-2 site's `Delta = nullptr` is covered by `repropagateControlMerges`' own
`reseed = UntaintedMergeRails ∪ (Tainted − beforeTaint)` with `beforeTaint` snapshotted at
function ENTRY — the inclusion argument is written at both ends and `detectAndLowerOnwardControl`
has exactly one caller. `reverifyRailCondReads` / `reverifyCmpCondReads` run **after**
`repropagateControlMerges` in both entry points, and before `lowerRotations`, so a recorded rail
is still a live `@cq_theta_i1` call. `markRailCondRead` keeps **every** read point, not the
first (`ArmClassify.cpp:2383`), so the rail-root CNOT copy (`CondTreeEmit.cpp:248`) and l4x4.b's
two controlled-Ry reads (`SwapRouteEmit.cpp:939/960`) are each re-verified.

⚠ **The coverage is thinner than it looks and rests on two over-declines**, which is worth
saying because it is what a future round will trip over: the BOOL flavour of this attack
(`R1`/`R2`/`R4`) is unreachable because of **I-1**, and a 6.5 classical-call arm followed by a
flat region is a pre-existing hcrg over-decline (`W1`/`W2`, filed `35t0`). `R6` is the only
plain-C spelling of the attack I could build that reaches the fence.

### 3b. Peel × F2 × l4x4 (brief item 3) — **finding I-1**, over-decline

See §4.

`P4b` (`int r = 5; if (q == 5) r = cq_theta(5, .9);` **beside a peeled mux**) **ACCEPTS** on the
subject and declines `control flow` on the oracle, and `P5b` (no peel) accepts too: F2's
narrowing is not confused by the clone for a NON-`i1` seed, and `condProvenance`/`CondWire`
still cover the region's own compare. `P3` (int seed 7, peeled) accepts. The damage is confined
to `i1` seeds.

### 3c. A.1 × l4x4 (brief item 4)

* **`b0 ^= 1` before the branch is not expressible at `-O1`**: clang flips the branch polarity
  and SINKS the `xor` to the measure (`%7 = xor i1 %1, true` in the merge), so there is no
  in-place `i1` relabel for `railWireNamesBackward`'s `InPlaceRailOps` crossing to cross. The
  program declines (`S5`, F2's string) on the sunk `xor` folding to the seed on the arm edge —
  an over-decline, F2's forward closure, not a composition effect.
* **Fence ORDER with an iteration-local `bool` driving a prep in a loop**: `L1` (prep), `L2`
  (in-place Ry arm), `L3` (loop-INVARIANT rail) all decline **`control flow inside a loop
  body`** — l4x4.c's carve-out fires FIRST and A.1's per-activation barrier is never reached.
  `L4` (the owner's two regions inside a loop) declines `value-arm swap-route`. **No accept
  sneaks between them.**
* Non-finite angles on the NEGATED prep (l4x4 round-1 F-1) still decline on the merged binary:
  `INFINITY`, `-INFINITY`, `NAN` → `rotation angle` (`F1a/F1b/F1c`).

### 3d. b6ap × l4x4 emission order (brief item 5)

The commutation is re-derived in §1. Every way I could make it NOT a commutation declines:

| probe | shape | subject |
|---|---|---|
| `O1`/`O1b` | the peeled mux copies the **pre-rotation** name of the in-place-Ry arm's own register (`if (c) { a = r; r = cq_theta(r,.5); }`), both polarities | `stale rail record read past a controlled Ry` |
| `O4` | the prep target read as a mux incoming | `operand predates a non-diagonal gate` |
| `Y1`/`Y2` | the mux copies a template rail DERIVED from the rotated register | `control flow` |
| `Q1` | an in-place-Ry arm and a peeled mux over the same register's pre-value in ONE diamond | `operand predates a non-diagonal gate` |
| `O2` | **two preps in one fused diamond** | `control flow` (the `>1 arm` fence) |
| `W5` | the mux's operand is a quantum rail derived from the condition register | `control flow` |
| `Z3` | **the prep's angle depending on the mux** | `control flow`. It is not expressible anyway: the angle operand is classical by Rule 3, so `0.5 * a` with a quantum `a` is a quantum-derived angle, declined before any ordering question arises |

And where the swap IS a commutation the circuit is right: `Y4`/`Q5` (TWO peeled muxes + one
prep → two independent CNOT-copy merges, two ancillas, two proven-\|0⟩ frees), `T3` (arm on the
TRUE edge → the un-negated `ry_i1_controlled(h0,h1,+.5)` with **no** unconditional `ry`), `T4`
(the peeled mux is an fp DATA select — `cqrt_copy_f64_controlled` — beside the bool prep; the
f64/angle wire is **not** crossed: the angles stay immediates of `cqrt_ry_i1*`), `S7` (three
source regions, two fused + one flat, all three preps correctly conditioned on `b0 = 0`).

### 3e. The whole-DAG spine on the combined stream (brief item 6)

`b0` now has three emitted readers (the `_controlled` control and the two `cnot`s).

| probe | subject | disposition |
|---|---|---|
| `S1` dead `b0` | ACCEPT | `h0` **left allocated, never freed** ✓ (a leak, the Rule-6 direction) |
| `S2` dead `b1` | `control flow` | — |
| `S3` dead `a` | ACCEPT | the mux is DCE'd, the prep stands alone, 2 rails left allocated, 0 frees |
| `S4` only `b0` measured | `control flow` | — |
| `S6` `b0` used as DATA after the region | ACCEPT | `zext(h0)→h6`, Q+Q add, `zext_unc(h6,h0)`, `free(h6)`; `h0` and `h3` left allocated ✓ |
| `X1` the control rail is a `cq_theta` CHAINED onto a template chain that is otherwise dead | ACCEPT (+ the pre-existing M-A warning) | the `and` rail is `_unc`'d and freed **before** the in-place `ry_i1`; the control rail itself is never freed ✓ |
| `Q3` the prep target measured before the region | ACCEPT | source order preserved |

**No free of an entangled rail was produced by any of the 99 probes**, and all 34 subject
accepts are `0 violation(s), 0 unproven`. ⚠ Stated with its limit: stage 2b cannot witness
"freed at \|0⟩" for a wrong unitary and is structurally blind to a leaked TEMPLATE-minted rail,
so this is necessary and not sufficient — the state-vector readings above are the evidence.

---

## §4 FINDINGS

### I-1 — OVER-ACCEPT? no. **OVER-DECLINE, and it falsifies two written claims.** The peel's compare CLONE re-introduces the `i1` F2 collider that Track C removes

**Measured, from plain C, four programs:**

| probe | shape | oracle | subject |
|---|---|---|---|
| `P1_intcmp_i1seed_singlephi` | `int b0` rail, `bool b1` seed `false`, merge holds **only** the prep φ | `state prep seed is proven equal…` | **ACCEPT** |
| `P2_intcmp_i1seed_peeled` | **the same, plus one peelable `int a` φ** | `control flow` | `state prep seed is proven equal…` |
| `P1t_seed_true` | seed `true`, no peel | `state prep seed…` | **ACCEPT** |
| `P2t_seed_true_peeled` | seed `true`, peeled | `control flow` | `state prep seed…` |

**Bisected to ONE instruction in hand IR.** `HP_f_nopeel.ll` (an `int` compare condition, an
`i1` prep φ, nothing else) **ACCEPTS** on the subject. Adding the peel's clone alone — one
`%clone = icmp eq i32 %1, 1` in the merge block, no select — gives `HP_g_sel_only.ll`, which
**DECLINES** with F2's string. `HP_c_merge.ll` (clone + select at the merge, the peel's exact
output shape) declines; so do `HP_d` (`icmp sgt %1, 1`) and `HP_e` (`icmp eq %1, 77`), so it is
the presence of a second tainted compare on the condition's own operand, not that compare's
predicate.

**Two written statements are false as measured, and both matter:**

1. `MERGE_l4x4_2.md` §5 and the Track-C landing message both ground row A (`int b0`/`bool b1`)
   on *"a bool prep under an int COMPARE condition still collides on the compare FLAG itself
   (not in CondWire)"*. `P1`/`P1t` show the region's own compare **is** excluded — it is
   `Region.Condition`, which `railWireClosure` seeds `CondWire` with. The residual is narrower
   than recorded (it needs a **peel**) and its cause is different (the CLONE).
2. `ir-pass/src/MergePhiPeel.cpp`'s insertion-point comment argues that merge placement
   *"keeps the peeled compare OUT of the live-on-the-edge set `f2SeedPinnedByLiveRegister`'s
   backward half walks, which is a gratuitous new interaction with the drbq state-prep fence."*
   The interaction is there. It is not through the backward half (the clone is defined after the
   branch and the LVI dominance filter excludes it) — it is reached some other way, and I did not
   finish isolating which; the fact is measured either way.

**Direction: SAFE.** F2 can only ever ADD colliders, so this is purely an over-decline; no
program accepts that the un-peeled twin declines. **Cost:** every `_Bool` state prep under an
`int` compare inside a FUSED (peeled) diamond — i.e. exactly the owner's row-A spelling, and
the reason `R1`/`R2`/`R4` (§3a) cannot be built. **Recommended disposition:** record the
corrected ground in `MERGE_l4x4_2.md` §5 and at `MergePhiPeel.cpp`'s comment (docs, this
session), and file the widening (exclude the peel's clone from F2's collider set — the clone
is by construction the SAME compare on the SAME wire as `Region.Condition`, so excluding it is
the identical argument) as a follow-on rather than doing it here.

### I-2 — DOC / pre-existing. `cq_invert_begin/_end` around the owner's program now ACCEPTS, emits the FORWARD stream, and only `ld` notices

`Z1_invert_around.c` (the owner's file wrapped in `cq_invert_begin()`/`cq_invert_end()`): oracle
`control flow`, **subject `opt` exit 0**, stage 2b clean, 19 forward gates — and
`@__cq_invert_begin` / `@__cq_invert_end` survive as unresolved externs, so the link fails
(`Undefined symbols … ___cq_invert_begin`). No adjoint is emitted; the bracket is silently a
no-op at the IR level. **Pre-existing and unchanged by this session** — the minimal twin
`Z1b_invert_simple.c` lowers **byte-identically (same md5)** on oracle and subject and fails to
link on both; manual inversion is Phase 8 and unimplemented. What the combination does is
**add customers** to that path (the whole owner-file family now reaches it). This is CLAUDE.md's
own F-L6-1 shape — "noticed only by `ld`, one linkable body away from silent" — and is worth a
line in the PRD rather than a fix here.

### I-3 — DOC. A new accept lands on the filed `3d8q` class

`G8_sibling_after.c` (`t = θ(false,.1); b0 = θ(t,.5); [the fused region]; c = θ(t,.9);` with
both `b0` and `c` measured) declines `control flow` on the oracle and **ACCEPTS** on the subject.
Its emitted stream is source-order correct (`ry .1; ry .5; region; ry .9`), but `b0` and `c`
name ONE rail and both `cq_measure` calls become `cqrt_measure_i1(h0)` after the `.9` — the
pre-existing bd `3d8q` P1 class ("the stale-record guard sweeps PURE ops only, so a `cq_theta`
or `cq_measure` READER of a stale name is never asked"). Not this session's defect; recorded
because this session **adds customers** to it (the drbq Inc-3 sentence).

### I-4 — OVER-DECLINE, consistent with the shipped posture, recorded so it is not rediscovered

`N6_b0_measured_before.c` — `b0` measured before the fused region — declines
`condition measured before the control route` although the emitted stream would be
source-faithful (the measure precedes every control read in source order too). This is A.1's /
r9e5's rung (ii) asked with `isPotentiallyReachable`, which is deliberately position-coarse; the
same over-decline exists on the compare path. It cost me the only clean way to isolate *which*
recorded read point (the peel's select or the prep's controlled-Ry) fires, since a peel requires
a non-peelable φ beside it and therefore always coexists with a region: `M1`/`M2`/`M3` reduce to
`-O1`-selectified shapes that are **byte-identical on both binaries** (same md5) and never peel.
Both read points ARE recorded (§3a), so the composition is covered either way.

---

## §5 WHAT WAS ATTACKED AND FOUND SOUND (negative results, stated so the next round can skip them)

* **The three-legged commutation** behind the emission-order swap — re-derived, and all seven
  ways to break leg (iii) decline (§3d).
* **The rail-root CNOT copy is gated correctly**: `CondTreeEmit.cpp:137`
  `CopyRoot = CopyRailRoot && isCondRailLeaf(Root)`, so a compound/compare root never gets the
  extra ancilla — which is why the 4.4 goldens did not move; and `SelectMergeEmit`'s inverted
  drift guard (`Net.RootIsRail` ⇒ loud `control flow`) is a detect-before-mutate bail.
* **The peel's own taint growth is adjudicated at all three sites** (§3a), and
  `markRailCondRead` keeps every read point, not the first.
* **The condition register is never `cqrt_x`-bracketed and never freed** in any of the 34
  accepts; the only `cqrt_x` are on emitter-owned ancillas.
* **The fp/angle wire is not crossed** by the combination (`T4`: an fp DATA mux beside a bool
  prep emits `cqrt_copy_f64_controlled` and keeps the angles as `cqrt_ry_i1` immediates).
* **`E2_peel_all_phis_cmp.ll`** (a merge both of whose φ are peelable) lowers **byte-identically
  on both binaries**; `E1` (rail condition) declines on both. The "peel empties the merge" shape
  produced no divergence.

---

## §6 CORPUS-LEVEL (brief item 7) — 770 rows, ORACLE vs SUBJECT, all twelve session corpora

`review_integration_probes/corpus.sh` → `corpus_oracle_vs_subject.txt`. One uniform recipe
(`.c` → `clang -O1`; `*_caller.c` `llvm-link`ed with its sibling lib; `.ll` direct); a row is
(exit code, diagnostic string, **md5 of the lowered IR when accepting**, compared WITHIN the
row so both binaries see the same stage-1 file), so an unchanged verdict over a changed circuit
still reads as a mover.

```
rows                                    770   (0 clang errors)
movers (oracle != subject)              334
  ACCEPT -> DECLINE                      37   <- all 37 in session-9pum, all on A.1's two strings
  DECLINE -> ACCEPT                     194
  DECLINE -> a different DECLINE        103
both ACCEPT, CIRCUIT CHANGED              0   <- must be 0
```

**Every mover is attributable to a landed track's own recorded effect:**

* the **37** `ACCEPT → DECLINE` are entirely inside `session-9pum` and carry
  `condition predates a non-diagonal gate` (`9pum_caller`, `k7/k8/k9`, `io3`, `gs1`, `io3m`,
  `o3_kick`) or `condition measured before the control route` (the rest) — A.1's landing message
  verbatim, including its one accepted parity over-decline;
* the **194** `DECLINE → ACCEPT` split by ORACLE string as `control flow` 123 (b6ap's peel),
  `bare i1 register condition` 52 (l4x4.b), `state prep seed is proven equal…` 13 (F2's
  intended flip), `nested control flow` 1 (`z04_hcrg_chain`, named in b6ap's own probe README),
  and **`condition measured before the control route` 5 — which are exactly
  `b1, b2, b3, b4, r3`**, the iteration-local class A.1's landing message names as
  "DECLINE→ACCEPT, pinned". There is **no** `DECLINE → ACCEPT` row in the 9pum corpora other
  than those five, which is the check that matters for a decline-only track;
* **all 194 accepting movers re-lowered and put through STRICT stage 2b: 194 clean,
  0 violations, 0 unproven.**

---

## §7 WHAT I DID NOT DO

* No rebuild anywhere; no edit to `ir-pass/`, `include/`, `tests/`, `tools/`; no commit.
* I did **not** finish isolating *by which route* F2 reaches the peel's clone (I-1). The
  behaviour is bisected to one instruction and reproduced in hand IR and in plain C; the
  mechanism inside `f2SeedPinnedByLiveRegister` is left to whoever takes the follow-on.
* I did not run the full `ctest`; `MERGE_l4x4_2.md` §6 records **403/403** and
  `cq-opt-equivalence-full` **1893/0** on this exact tree, and I independently re-ran
  `lit -s ir-pass/test` → 1893 / 1892 / 1 XFAIL / 0 unexpected.
* I did not re-run the twin matrices (instruments, and `e2e-loop-twin-matrix` ran green inside
  the merge's two `-j6` runs).
