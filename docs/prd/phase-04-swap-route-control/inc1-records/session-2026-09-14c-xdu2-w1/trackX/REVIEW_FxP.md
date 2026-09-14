# Rule-13 adversarial opinion — the F × P COMPOSITION (`MERGE_FILINGS.md` §2 / `MERGE_REPORT.md` §5b)

Track X, session 2026-09-14c. Analytic / trace-level reasoning only; **no statevector
simulations** (owner decision 2026-06-10). Every verdict below is read off the emitted STREAM,
not off the exit code — *every shipped Grover golden was the identity and its traces were
self-consistent.*

## VERDICT: **CLEAR-WITH-ITEMS** (4 items, none a miscompile; item 1 is about the EVIDENCE and is the one that matters)

The two accepts the merge gate created are, as far as analytic reading goes, **correct**. What is
not clear is the evidence base: **one of the two committed witnesses is vacuous on its own
reachable support**, and the composition surface was sampled by a corpus rather than enumerated.

Binary for every row: ORACLE `cq-opt 5c6f7490a81c7505…` / `libCQPass.so 5276f7ab7416b36b…`, which
§0 of `X5_REDERIVATION.md` measures to be **HEAD's compiler** (pass source byte-identical).

---

## 1. `r19_phi_and_prepcond.c` — the PHASE consumer. **The emitted unitary is right.**

```c
bool b0 = cq_theta((bool)0, 0.5);
bool b1 = 0;
if (b0) { b1 = cq_theta(b1, 0.5); }
if (b1 && b0) cq_phi(0.3);
return cq_measure(b0) + cq_measure(b1);
```
```
 1  cqrt_alloc_i1(0) -> h0          6  cqrt_toffoli(h0, h1, h2)
 2  cqrt_ry_i1(h0, 0.5)             7  cqrt_rz_i1(h2, 0.3)
 3  cqrt_alloc_i1(0) -> h1          8  cqrt_toffoli(h0, h1, h2)
 4  cqrt_ry_i1_controlled(h0,h1,0.5)9  cqrt_free(h2)
 5  cqrt_alloc_i1(0) -> h2         10-11 measure h0, h1
```
STRICT 2b `3 rail mint(s) of which 2 left allocated, 1 cqrt_free site(s): 1 verified, 0
violation(s), 0 unproven`; 11 trace lines.

**Line by line against the source, with `c = cos(0.25)`, `s = sin(0.25)`.**
After 2, `q0 = c|0⟩ + s|1⟩`. After 4, `c|0⟩₀|0⟩₁ + s|1⟩₀(c|0⟩₁ + s|1⟩₁)` — the controlled prep,
correct, and **emitted BEFORE the kickback**, which is the whole ordering question. 6 writes
`b0∧b1` into a fresh `|0⟩` ancilla (a reversible AND; the only populated branch it sets is
`|1⟩₀|1⟩₁`, amplitude `s²≈0.0612`, **non-zero**). 7 is `Rz(θ) = diag(e^{-iθ/2}, e^{+iθ/2})` on
the flag, i.e. a relative `e^{iθ}` between the flag's two branches **times a global phase that is
already discarded** — this is Rule 7's kickback, uncontrolled on the flag, nothing emitted on `q`
at all. 8 restores the ancilla to `|0⟩` on every branch, which is what makes 9 a proven-`|0⟩`
free (Rule 6). **Net: `diag(1,1,1,e^{i·0.3})` on `(b0,b1)` — exactly `if (b1 && b0)
cq_phi(0.3)`.**

**The invariants read straight off the stream.** `h0` and `h1` are the USER's registers and
appear only as `cqrt_toffoli` CONTROLS, as the control of `cqrt_ry_i1_controlled`, and in
measures — **never `cqrt_x`-bracketed, never freed**. There is no `cqrt_x` in this stream at all
(none is needed: the tree is a bare AND with no negated leaf). Two rails left allocated = the two
user registers, correct.

**The composition-specific hazard, and why it does not bite.** `b0` is simultaneously the prep
region's CONTROL and a tree leaf of the kickback. Between `h0`'s mint and its read at line 6 the
only gate touching `h0`'s wire is line 4's `cqrt_ry_i1_controlled`, where `h0` is the CONTROL —
block-diagonal in `h0`'s basis, so it does not relabel `h0` and the read at 6 sees the same basis
labels the source compare did. `h1`'s wire **does** carry a non-diagonal gate (it is that gate's
TARGET), and the kickback reads it **after**, which is the position-aware accept and not a stale
read. Had either classification gone the other way the module would have DECLINED — the safe
direction.

**Ordering is safe by construction, not by luck, and Track P proved it.** `ArmClassify.cpp:6266-
6291` carries the theorem: a `PhaseKickback` has real block fields, so `lowerControlRegions`' bd
`hcrg` alias pre-flight sees `kickback.Pred == prep.MergeBB` and takes the sanctioned
`sequentialChainAlias` edge, emitting the kickback first **while the φ is still live**, after
which M-β rewrites the emitted gate's operand to the theta call. Every emitter inserts
**positionally**, so the trace order is block order — source order — regardless of the schedule.
The measured stream confirms it. I attacked this with `fp_x8`, which inserts a further
non-diagonal gate on the φ leaf's own wire between the prep and the kickback: the emitted
`cqrt_ry_i1(h1, 0.2)` lands **between** line 4 and the toffoli, in source order. ✅

---

## 2. `m28.c` — the VALUE consumer. **The stream is right. The WITNESS IS VACUOUS.** (item 1)

```c
int a = 5; bool b0 = 0, b1 = 0;
if (a >= 3){ b0 = cq_theta(b0, 0.5); }     /* a == 5 classically -> unconditional */
if (b0 == 1) a -= 3;                        /* a = 2 if b0 else 5 */
if (a >= 3){ b1 = cq_theta(b1, 0.5); }      /* a >= 3  <=>  b0 == 0  -> NEGATED control */
if (b1 && b0) a -= 3;
```

Read the third region's condition: after `if (b0==1) a -= 3`, `a` is 2 when `b0==1` and 5 when
`b0==0`, so `a >= 3` **is** `b0 == 0`. The emitted prep is the negated-control spelling
`cqrt_ry_i1(h1, 0.5); cqrt_ry_i1_controlled(h0, h1, -0.5)` — Rule 7's additivity form, correct.
State after it: `c|0⟩₀(c|0⟩₁ + s|1⟩₁) + s|1⟩₀|0⟩₁`.

⚠ **The amplitude on `|b0=1, b1=1⟩` is EXACTLY ZERO.** So `cqrt_toffoli(h0,h1,h7)` sets the flag
on **no populated branch**, the `copy_i32_controlled(h7, h6, h8)` arm never fires, and `h8 = h3`
identically. **The fourth region — the one and only region the F × P composition newly enables in
this module — acts as the identity on the entire reachable support.** Its controlled-copy merge
is indistinguishable, by anything this program can produce, from several *incorrect* merges.

The stream itself is nonetheless correct when read as a circuit: `h6 = h3 - 3` (out-of-place —
the `-> h6` return is a fresh rail, so `h3` survives to be the ¬flag copy source, which is the
M-C in-place-vs-out-of-place decision going the right way); `h7 = b0∧b1`; `h8 = h7 ? h6 : h3`;
`h7` X-bracketed and returned to `|0⟩` by the second toffoli before its free; `h0`/`h1` only ever
controls; all four `cqrt_x` on the ancillas `h2`/`h7`.

**The non-vacuous twin exists and it accepts.** `fp_x5b_m28_positive_delta3.c` is m28 with the
third region's polarity flipped (`if (a < 3)`), so `b1` is prepared on the `b0==1` branch and
`|1,1⟩` carries amplitude `s² ≈ 0.0612`. It **ACCEPTS**, STRICT 2b `8 rail mint(s) of which 6
left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`, 29 trace lines, and
its stream is **identical to m28's except the prep spelling** (one `cqrt_ry_i1_controlled(h0, h1,
0.5)` in place of m28's `cqrt_ry_i1(h1,0.5)` + `cqrt_ry_i1_controlled(h0,h1,-0.5)` pair).
Everything downstream — `h2`…`h8`, the toffoli flag, both controlled copies, both frees — is the
same. **On that module the merged arm actually fires, and the merge is right.**

⚠ **A second reason m28's "STRICT 2b clean" is weaker than it reads.**
`cq_template_add_i32_hl(h3, -3) -> h6` is never `_unc`'d and never freed — a **TEMPLATE**-minted,
which-path-entangled rail left allocated. That is *legal* (Rule 6 leaves a not-provably-`|0⟩`
rail allocated; CLAUDE.md §1 records the value arm's chain-final rail as a deliberate live
example) and it is *pre-existing*, not composition-created. But `free_pairing_check.py` is
**structurally blind to a leaked TEMPLATE-minted rail** — it counts `cqrt_alloc` sites, and `h6`
has none — so the `0 violation(s)` line is silent about the composition's only leak. **The value
side of this composition therefore has a vacuous trace AND a stage-2b gate blind to its one
residual.** Neither is a defect; both are statements about what the cited evidence can witness.

---

## 3. The fence inventory — what each track's rounds saw standing, by `file:line`

| | Track F alone | Track P alone | composed |
|---|---|---|---|
| `r19`, `m28` | `control flow` — the leaf-grammar wall | `state prep seed is proven equal to the condition register` — F2 | **ACCEPT** |

**What Track F's rounds had in front of them (and so never examined a lowered stream for):** the
kickback's condition-tree grammar with `AllowRailPhi = false`. The φ-leaf admission is
`ArmClassify.cpp:6059-6066` (`collectCondTree(…, /*AllowRailPhi=*/true)` — "THE SECOND AND LAST"
such call site) and the per-leaf rung 0 at `ArmClassify.cpp:6391`
(`preppedRailPhiRegionIdx(P, plan) == kNoParent` → decline). Emission-side membership is
`CondTreeEmit.cpp:211` (`llvm::is_contained(Tree.RailPhiLeaves, P)`). Without Track P every one
of those is inert and a merge φ falls through to `bare i1 condition` / `control flow`.

**What Track P's rounds had in front of them (and so never examined a lowered stream for):** F2
firing. The conjunct is `ArmClassify.cpp:2187`
(`… && !Taint.isPeelClone(V) && !PhiDesc.count(V) && f2Exact(V, S) == Seed`), the set is built by
`collectStatePrepPhiDescendants` (`ArmClassify.cpp:1794`, dominance skip at `:1904`), and the
call + decline are `ArmClassify.cpp:4932-4938`.

**The interaction, stated exactly — and it is tighter than either filing says.** In `r19` the
value F2 excludes **is Track P's own tree root**. Read off the stage-1 IR (`-O1`, no `-g`):

```llvm
  %1 = tail call i1 @cq_theta_i1(i1 false, double 5.0e-01)   ; b0 — the region's CONDITION
  br i1 %1, label %2, label %4
2:  %3 = tail call i1 @cq_theta_i1(i1 false, double 5.0e-01) ; the arm theta, SEED = false
4:  %5 = phi i1 [ %3, %2 ], [ false, %0 ]                    ; M — pred incoming IS the seed (F1 ok)
    %6 = and i1 %1, %5                                       ; <- the tree root, a USER of M
    br i1 %6, label %7, label %8                             ; the kickback; its Pred IS MergeBB
```

⚠ `%6` is an `and`, not a `select` — the `select i1` spelling is what the TWO-leaf probe in §4
produces, and the two must not be conflated. On the FALSE edge of `br i1 %1` we have `%1 = false`,
so `%6` folds to `false`, which **is** the prep's seed; and `%6` is reached by F2's forward users
walk from `%1`, the only tainted value dominating `Pred`. So F2's witness exists *only because the
tree exists*, and F's φ-descendant exclusion is *what removes it*. The availability
ground still licenses the removal, and the reason is worth writing down: the tree root is defined
in the region's merge block, so it cannot be spelled at the arm theta's arg-0 nor on the merge
φ's pred edge, in any module (§3 of `X5_REDERIVATION.md`). ✅ **No circularity: F2 asks about
region 2's slots, and region 3's condition can occupy neither.**

**Where a composition defect *would* have lived, and why it does not.** Track M's F-M1 finding
was precisely an ordering hole of this shape — a `SelectRegion` inert in the `hcrg` precedence
graph letting a prep emit LAST — closed by recording `PrepRegionIdxs`
(`SelectClassify.cpp:1325`, consumed at `SwapRouteEmit.cpp:2735`). Track P deliberately did **not**
record one for the kickback, and `ArmClassify.cpp:6266-6291` argues why: the kickback has real
block fields, the `hcrg` edge is FORCED, and recording a `PrepRegionIdxs` edge would demand the
opposite order and close a precedence CYCLE, declining the module. That is the one place the two
increments could have disagreed about order, and they do not.

---

## 4. Other F × P compositions — what I looked for, and what came back

A corpus finds what is in it; these were constructed.

| probe | shape | verdict |
|---|---|---|
| `fp_x2_or_tree.c` | `if (b1 \|\| b0) cq_phi(0.3)` over the same two rail leaves | **ACCEPT** — and the OR is emitted correctly: `cnot(h0,h2); cnot(h1,h2); toffoli(h0,h1,h2)` is `b0 ⊕ b1 ⊕ (b0∧b1) = b0 ∨ b1`, then `rz`, then the exact mirror to return `h2` to `\|0⟩` before its free. Non-vacuous (fires on 3 of 4 branches) |
| `fp_x7_negated_prep_or_tree.c` | the prep on the NEGATED arm (`ry; ry_controlled(-θ)`) + an OR tree | **ACCEPT**, correct, non-vacuous |
| `fp_x8_gate_between_prep_and_kickback.c` | a further non-diagonal gate on the φ leaf's own wire between prep and kickback | **ACCEPT**, `cqrt_ry_i1(h1,0.2)` emitted in source order between the two — ordering attack failed |
| `fp_x5b_m28_positive_delta3.c` | m28 with non-vacuous polarity | **ACCEPT**, stream = m28's modulo the prep spelling (§2) |
| `fp_x6_twofn_cross_function.c` | TWO F × P customers in ONE module (bd `1yeu`'s blind spot) | **ACCEPT**; each function's stream is identical to its single-function form — no cross-function interference found |
| `fp_x3_two_preps_two_phi_leaves.c` | TWO prep merge φs as the two leaves of one kickback tree | **DECLINE** `condition predates a non-diagonal gate`, anchor `%10 = select i1 %9, i1 %5, i1 false` — item 2 |
| `fp_x4_inloop_phi_leaf_FxPxW.c` | the φ-leaf kickback rolled inside a bounded loop (F × P × **W**) | **DECLINE** `control flow` — item 3 |
| `fp_x1_value_consumer_nonvacuous.c` | value consumer with a CLASSICAL `a` | ACCEPT, but `-O1` short-circuits the `&&` into two sequential diamonds, so it is **not** the composition shape — recorded so nobody cites it as one |

⚠ `fp_x1` and the first `fp_x5` (`a -= 1`, which InstCombine folds to `add(a, sext(b0&b1))` and
lowers as pure arithmetic) are the reminder that **this composition's shape is `-O1`-fragile**:
the two-leaf tree survives only when the arms do not fold to constants and the delta is not ±1.
Any future fixture for it must pin that, or it will silently stop testing the composition.

---

## 5. The four items, each a `bd`-fileable paragraph

**ITEM 1 — `m28`, the composition's committed VALUE witness, is VACUOUS on its own reachable
support; replace or accompany it with `fp_x5b`.** In `m28` the third region's condition `a >= 3`
is `b0 == 0` after `if (b0==1) a -= 3`, so `b1` is prepared on the ¬`b0` branch and the state
before the fourth region is `c|0⟩₀(c|0⟩₁+s|1⟩₁) + s|1⟩₀|0⟩₁`: the amplitude on `|b0=1,b1=1⟩` is
exactly zero, the `cqrt_toffoli(h0,h1,h7)` flag is 0 on every populated branch, and the
controlled-copy merge the F × P composition newly enables is the identity there. `MERGE_FILINGS.md`
§2 and `MERGE_REPORT.md` §5b cite m28's "29 trace lines, STRICT 2b clean, well-formed stream" as
the composition's value-side evidence; that is true about the STREAM and vacuous about the
UNITARY — the project's own headline lesson. `fp_x5b_m28_positive_delta3.c` (m28 with `a < 3`) is
non-vacuous, accepts, and emits a stream identical to m28's except the prep spelling; it is the
witness that should be committed. Cost: one slice + golden, or one lit fixture. Severity P2 —
evidence debt on a shipped accept, not a known miscompile.

**ITEM 2 — over-decline: TWO prep merge φs as the two leaves of one kickback tree.**
`fp_x3_two_preps_two_phi_leaves.c` (`if (g) b0 = …; if (g) b1 = …; if (b1 && b0) cq_phi(0.3);`)
declines `condition predates a non-diagonal gate` with `CQ_CTRL_DBG` anchor
`%10 = select i1 %9, i1 %5, i1 false`. That is a valid quantum circuit, so under the owner's
2026-09-11 ruling it is a defect to remove rather than a safety margin. bd `4aiu`'s own note
predicts the shape is unreachable for a *different* reason ("at most ONE φ leaf can satisfy the
in-`Pred` requirement at the KICKBACK, because two distinct diamonds have two distinct merge
blocks", so `PrepRegionIdxs` being a LIST is unexercised there) — the measured decline fires on
the **wire fence** instead, which means the in-`Pred` grammar is not even reached and `4aiu`'s
stated reason is not the operative one. Which prong of `condWireDisposition` fires, and whether
it is answering about the *other* prep's non-diagonal gate on a *different* wire, is not isolated
here. Severity P3, and it is a scoping question before it is a fix.

**ITEM 3 — the composition surface was SAMPLED, not ENUMERATED, and three-way compositions were
never constructed.** The 2026-09-14 merge landed SIX increments; `MERGE_REPORT.md` §5a attributed
290 corpus movers per track and labelled 8 "COMPOSITION", all of them PAIRS found by sweeping a
corpus. A corpus finds what is in it. The F × P × W triple exists as a natural program
(`fp_x4_inloop_phi_leaf_FxPxW.c` — the φ-leaf kickback rolled in a bounded loop) and declines
`control flow` today, which is safe and is bd `52og`'s known asymmetry; but nothing in the tree
*looked* for it, and no gate would have caught it had it accepted wrongly. Recommendation for the
next merge-and-gate brief: after the per-track attribution, **enumerate the triples among tracks
that touch one predicate chain** and construct a probe per triple, rather than relying on the
corpus to contain one. Severity P3, process.

**ITEM 4 — the value-arm composition's only residual is invisible to the gate that cleared it.**
In `m28` / `fp_x5b`, `cq_template_add_i32_hl(h3, -3) -> h6` is never `_unc`'d and never freed: a
TEMPLATE-minted, which-path-entangled rail left allocated. This is legal (Rule 6: a
not-provably-`|0⟩` rail is left allocated, never freed) and documented (CLAUDE.md §1 / Rule 6's
live example of a value arm's chain-final rail), and it is pre-existing rather than
composition-created. But `free_pairing_check.py` counts `cqrt_alloc` sites and is structurally
blind to a template-minted rail, so its `0 violation(s)` on these modules is silent about exactly
this residual. Not a defect; file it so the `STRICT 2b clean` line cited for the composition is
never read as clearance for the leak class. Severity P4, documentation/instrument scope.

---

## 6. What this opinion did NOT do

* **No simulation.** Amplitudes above are analytic, from `Ry(θ)|0⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩`
  and the trace-only runtime's own gate semantics. There is no simulator and there will not be
  one (Rule 2).
* **No two-binary movers.** The single-track binaries `147cb3d6…` / `96fdd3a9…` / `283e3b33…` no
  longer exist on this box, so "Track F alone declines / Track P alone declines" is **cited** from
  `MERGE_REPORT.md` §5b's measurement, not re-run here.
* **No corpus sweep and no suite beyond `ir-pass-lit`** — this change edits comments only, so it
  moves no corpus row (PROTOCOL §S2's logic).
* **The `fp_x3` decline was not isolated to a prong** (item 2 says so).

## 7. FILED

| bd | item | P |
|---|---|---|
| **`test_C_libtooling-gzgs`** | item 1 — `m28` is a vacuous VALUE witness; `fp_x5b` is the non-vacuous twin | P2 |
| **`test_C_libtooling-leyd`** | item 2 — two prep merge φs as one kickback tree's two leaves over-declines, and `4aiu`'s stated reason is not the operative fence | P3 |
| **`test_C_libtooling-oej0`** | item 3 — the composition surface is sampled by a corpus, never enumerated; no three-way composition was ever constructed | P3 |
| **`test_C_libtooling-19vy`** | item 4 — stage 2b's `0 violation(s)` on these accepts is blind to their one residual (the leaked template-minted rail `h6`) | P4 |
