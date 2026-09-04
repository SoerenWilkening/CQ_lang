# Inc-4 (controlled state-prep) — PRE-IMPLEMENTATION PROBE RESULTS

bd `test_C_libtooling-drbq.5`. Probe+matrix agent, 2026-09-04.
**Everything below was COMPILED and RUN.** Nothing is asserted from reading code alone.

* ORACLE = `$S/wt/pre4/build/ir-pass/cq-opt` (+ its `libCQPass.so`), built from `b506b3b`.
* HEAD   = `build/ir-pass/cq-opt`.
* **Sanity check passed twice over:** the two binaries are MD5-IDENTICAL
  (`cq-opt` `8931bc461dc1db08e90288880f7d67be`, `libCQPass.so`
  `82217c6381c0bf0cf56f92b02b043c96`), *and* all 62 initial probes were run through
  BOTH and the whole transcript diffs to **0 lines** (`$S/head_vs_oracle.diff`).
  The oracle is what it claims to be.
* Pipeline per probe: `clang -O1 -include CQ.h -emit-llvm -S` → `cq-opt
  -passes=cq-lowering` (exit code + stderr) → on accept: `free_pairing_check.py`
  (strict) → link (`libcq_templates.a` before `libcq_runtime.a`) → run → trace.
  Driver: `$S/probe/run.sh`.
* 70 probe programs in `$S/probe/p*.c`; full per-probe C + `-O1` IR + diagnostic +
  trace in **`$S/probe/IR_DIGEST.txt`**; raw transcripts `$S/ALL_ORACLE.txt`,
  `$S/ALL_HEAD.txt`.

---

## 0. HEADLINE — read this before scoping the fence

Two independent `clang -O1` **equality value-propagation** folds make the Inc-4
target shape *textually indistinguishable* from programs CQ must decline. Both
were reproduced with byte-identical whole modules (only `source_filename` differs).

**FOLD A — the ARM edge.** On the successor where `q == K` is a theorem, every use
of `%q` in the arm is replaced by the literal `K`. So

```c
int r = 0; if (q == 0) r = cq_theta(q, .9);   /* p08a — in-place Ry on the CONDITION register (R4: must DECLINE) */
int r = 0; if (q == 0) r = cq_theta(0, .9);   /* p08a_ctl_prep0 — genuine state prep (Inc 4: wants ACCEPT) */
```
compile to **the same module**. Confirmed by `diff` of the two `.s1.ll` files: the
only difference is the `ModuleID`/`source_filename` lines.

**FOLD B — the PRED edge.** The same substitution applies to the merge φ's
pred-edge incoming, so

```c
int r = q; if (q != 5) r = cq_theta(5, .9);   /* p23d — r ALIASES the quantum register q (a Q data mux: must DECLINE) */
int r = 5; if (q != 5) r = cq_theta(5, .9);   /* p23b — classical seed 5 (Inc 4 shape) */
```
also compile to **the same module** (`p23b ≡ p23d`, verified). Likewise
`p23a ≡ p23c` (`int r = 5;` vs `int r = q;` with seed 0).

**This is not a purity artefact and cannot be fixed in `CQ.h`.** `@cq_theta_si32`
is declared with **no** `memory(none)`/`readnone` (attribute group `#1` is just
target flags), so LLVM never CSEs two thetas. The substitution is ordinary
dominance-based equality propagation on an SSA *use*, and it is legal for any i32
value. CQ's handle identity is carried by SSA names; equality propagation destroys
the name. **No frontend attribute recovers it.**

**The project has already ruled on this class, twice, in the OPPOSITE direction to
a naive Inc 4.** `tryEqFoldArm` (`EqFoldArm.cpp`, D1–D8) exists to *undo* fold A
for phase arms — it re-anchors `cq_phi(K, θ)` back onto the handle `H`; its D8
comment calls the wrong-polarity variant "a verify-clean wrong unitary" (bd
`ogw2`). `straightThroughConstFoldHandle` (`ArmClassify.cpp:1320`) is the *same
undo for fold B*. **MEASURED, on the shipped compiler:**

```c
int slice(void){ int q = cq_theta(3,.3); if (q == 0) q = cq_phi(q, .9); return cq_measure(q); }   /* p08l */
```
→ IR arm is `cq_phi_si32(i32 0, 0.9)` (folded) → **ACCEPTS**, emitting
`cqrt_rz_i32_controlled(h1, h0, 0.9)` — re-anchored onto **q's own rail h0**.
i.e. CQ *today* reads a const-folded arm seed on an equality edge as **the handle**,
not as a constant. An Inc 4 that reads the same construct as a **fresh rail**
installs two contradictory readings of one IR shape, and for the `cq_theta` stem
the handle reading is exactly what R4 forbids.

### 0.1 The fence this measurement implies (two-sided, cheap, already-spelt machinery)

> **DECLINE a controlled state prep when the region's edge PROVES the condition
> handle equals the constant in question.**
> * **A1 (arm side).** `Cond` is an equality `icmp` over `{ConstantInt C, handle H}`,
>   `ArmBB` is the edge on which `H == C` holds (`tryEqFoldArm`'s D8 polarity test,
>   verbatim), and `T`'s seed constant `== C` (same type and value). → DECLINE.
> * **A2 (pred side).** Same, with the *straight-through* edge and the merge φ's
>   pred incoming (`straightThroughConstFoldHandle`'s `StraightProvesEq`, verbatim).
>   → DECLINE.
>
> On an `eq`/`ne` diamond at most one edge proves the equality, so at most one
> clause can fire per region.

Verified against every probe: A1 kills p08a/c/d/e/f/g (all ambiguous), A2 kills
p23b (ambiguous); the flagship p01/p02/p04b/p06b/p07/p13/p15/p17 are untouched.
**Price:** two genuine state preps over-decline — `p06a`
(`int r=5; if(q==5) r=cq_theta(5,.9)`) on A1 and `p23a`/`p23b` on A2. That is the
Prime-Directive-correct direction and the brief already anticipated it ("the
SEED == compare-constant coincidence must be a distinct cell").

### 0.2 Three things that make the fence *sufficient*, measured not assumed

1. **A non-identity fold cannot be laundered past it.** `if (q==5) r = cq_theta(q*2,.9)`
   folds to `cq_theta(i32 10, .9)` (p08p/p08t/p08v — *arm-local* `q+5` folds the
   same way). Seed 10 ≠ C 5, so A1 lets it through — and that is **correct**: the
   source's arg-0 is an OUT-OF-PLACE derived rail (a different physical wire from
   `q`, R4-clean) which provably holds exactly 10 on the branch where it is
   rotated, so the fresh-rail circuit agrees with it on values. Its *un-folded*
   twin declines anyway (`Base != Routed` — pred incoming is a constant), so no
   accepted region moves.
2. **Only an EQUALITY pins the handle.** `if ((q & 6) == 2) r = cq_theta(q,.9)`
   does NOT fold (p08r: the arm keeps `cq_theta(%1, .9)`), and neither does the
   `sgt` family. A range that *is* a singleton does fold: `q > 4 && q < 6`
   canonicalizes to `icmp eq %q, 5` and then folds `q → 5` (p08c) — so the fence
   must read the CANONICALIZED compare, which is the only one it ever sees.
3. **The fold is not even guaranteed for a shape that admits it.** `if (q + 1 == 6)
   r = cq_theta(q,.9)` (p08s) canonicalizes the compare to `icmp eq %1, 5` but
   leaves the arm's `cq_theta(%1, .9)` UNFOLDED, and therefore declines on R4
   today. So the same source can arrive folded or unfolded depending on
   incidental pass order — **a fence that reads "this looks like state prep"
   is inherently order-sensitive, which is one more reason to make it a
   DECLINE-on-ambiguity rather than an accept-on-appearance.**

---

## 1. Summary table (ORACLE = HEAD, all 70)

`shape` = what survives `clang -O1`. `seed`/`pred-in` are the arm theta's arg-0 and
the merge φ's pred-edge incoming. All declines are `cq controlled lowering: … under
quantum control` unless noted.

| probe | source (abridged) | `-O1` shape | seed / pred-in | oracle | clause |
|---|---|---|---|---|---|
| p01 flagship | `r=0; if(q==5) r=θ(0,.9)` | diamond, θ in arm, φ`[%4,arm],[0,pred]` | `0` / `0` | DECLINE `control flow` | `inPlaceRotationArmTheta` classical-arg-0 (`ArmClassify.cpp:725`) → fallthrough |
| p02 `!=` | `if(q!=5) r=θ(0,.9)` | `icmp eq`, arm on the **FALSE** successor (Rule 9) | `0`/`0` | DECLINE `control flow` | same |
| p03 if/else same const | `if(q==5) r=θ(0,.9) else r=0` | **collapses to p01's diamond** | `0`/`0` | DECLINE `control flow` | same |
| p04a if/else diff const | `… else r=7` | diamond, φ`[…],[7,pred]` | `0`/`7` | DECLINE `control flow` | data mux (R3 `RotBase != Routed`) |
| p04b seed mismatch | `r=7; if(q==5) r=θ(0,.9)` | diamond | `0`/`7` | DECLINE `control flow` | data mux |
| p05 prep vs chained | `if(q==5) r=θ(0,.9) else r=θ(p,.4)` | real if/else, 2 thetas, no pred incoming | `0`,`%2`/— | DECLINE **`impure phase arm`** | two rails |
| p06a seed==cmp const | `r=5; if(q==5) r=θ(5,.9)` | diamond | `5`/`5` | DECLINE `control flow` | **A1-ambiguous** (≡ p08e) |
| p06b seed≠cmp const | `r=7; if(q==5) r=θ(7,.9)` | diamond | `7`/`7` | DECLINE `control flow` | clean Inc-4 shape |
| p07a f64 | `double r=0.0; θ(0.0,.9)` | diamond, `phi double […],[0.0]` | `0.0`/`0.0` | DECLINE `control flow` | clean Inc-4 shape |
| p07b −0.0 pred-in | `double r=-0.0; θ(0.0,.9)` | `phi double […],[-0.0]` | `0.0`/**`-0.0`** | DECLINE `control flow` | **the §7 bit-identity case, REACHABLE from plain C** |
| p07c −0.0 seed | `double r=0.0; θ(-0.0,.9)` | `phi double […],[0.0]` | **`-0.0`**/`0.0` | DECLINE `control flow` | mirror of p07b |
| p07d f32 | `float` | same shape at f32 | `0.0f`/`0.0f` | DECLINE `control flow` | clean |
| **p08a** cond-reg | `r=0; if(q==0) r=θ(q,.9)` | **≡ p08a_ctl_prep0 byte-for-byte** | `0`/`0` | DECLINE `control flow` | **FOLD A** |
| p08a_ctl_prep0 | `r=0; if(q==0) r=θ(0,.9)` | — | `0`/`0` | DECLINE `control flow` | genuine prep, A1-ambiguous |
| p08b derived `q-5` | `if(q==5) r=θ(q-5,.9)` | **≡ p01 byte-for-byte** | `0`/`0` | DECLINE `control flow` | FOLD A, non-identity → benign |
| p08c range→singleton | `r=5; if(q>4&&q<6) r=θ(q,.9)` | `icmp eq %q,5`; **≡ p06a** | `5`/`5` | DECLINE `control flow` | FOLD A, **identity** |
| p08d alias `int a=q` | `if(q==0) r=θ(a,.9)` | **≡ p08a_ctl_prep0** | `0`/`0` | DECLINE `control flow` | FOLD A, identity |
| p08e seed5 | `r=5; if(q==5) r=θ(q,.9)` | **≡ p06a** | `5`/`5` | DECLINE `control flow` | FOLD A, identity |
| p08f if/else | `if(q==0) r=θ(q,.9) else r=0` | ≡ p08a_ctl_prep0 (φ preds listed in the other order) | `0`/`0` | DECLINE `control flow` | FOLD A, identity |
| p08g `u<1u` | `unsigned u=q; if(u<1u) r=θ(q,.9)` | canonicalized to `icmp eq %q,0`; **≡ p08a_ctl_prep0** | `0`/`0` | DECLINE `control flow` | FOLD A, identity — canonicalization first, then the fold |
| p08h seed5/pred0 | `r=0; if(q==5) r=θ(q,.9)` | diamond | `5`/`0` | DECLINE `control flow` | seed-identity already kills it |
| p08i Rz twin of (a) | `r=0; if(q==0) r=φ(q,.9)` | arm is `cq_phi(i32 0,…)` | `0`/`0` | DECLINE `control flow` | φ over a CLASSICAL arg-0 + constant pred incoming |
| p08j merge over q | `if(q==0) q=θ(q,.9)` | φ`[%4,arm],[%1,pred]` | `0`/**`%1`** | DECLINE `control flow` | pred incoming is the HANDLE → not a prep |
| p08k `ne`-else fold | `if(q!=5){} else r=θ(q,.9)` | folded to `θ(5,.9)`, pred-in 5 | `5`/`5` | DECLINE `control flow` | FOLD A on the `ne`-FALSE edge |
| **p08l** Rz re-anchor | `if(q==0) q=φ(q,.9)` | arm `cq_phi(i32 0,…)`, φ pred-in `%1` | — | **ACCEPT** | `tryEqFoldArm` — emits `cqrt_rz_i32_controlled(h1,h0,.9)` **on q's own rail** |
| p08m `ne`, seed==C | `r=5; if(q!=5) r=θ(5,.9)` | arm on `ne`-TRUE edge (no fold possible) | `5`/`5` | DECLINE `control flow` | **polarity-safe** — A1 must NOT fire here |
| p08n Rz prep | `r=0; if(q==0) r=φ(0,.9)` | φ pred-in `0` | `0`/`0` | DECLINE `control flow` | differs from p08l **only** in the pred incoming |
| p08o Rz eq-fold canonical | `if(q==0) p=φ(p,.9)` | unfolded (p ≠ q) | — | **ACCEPT** | ordinary phase arm |
| p08p derived ×2 | `r=0; if(q==5) r=θ(q*2,.9)` | `θ(i32 10,.9)` | `10`/`0` | DECLINE `control flow` | seed-identity kills it |
| p08q compound pins p | `if(q==5&&p==3) r=θ(p,.9)` | `select i1` cond; `θ(i32 3,.9)` | `3`/`0` | DECLINE `control flow` | **a compound condition pins a SECOND register too** |
| p08r masked | `if((q&6)==2) r=θ(q,.9)` | **NOT folded**, `θ(%1,.9)` | — | DECLINE `condition predates a non-diagonal gate` → **unmasks to `control flow`** with `cq_phi` | R4 (arm on the condition wire) |
| p08s `q+1==6` | `if(q+1==6) r=θ(q,.9)` | compare canonicalized, arm **NOT folded** | — | DECLINE `condition predates…` → unmasks to `control flow` | R4 |
| p08t derived, seed==pred-in | `r=10; if(q==5) r=θ(q*2,.9)` | `θ(i32 10,.9)`, pred-in `10` | `10`/`10` | DECLINE `control flow` | **passes seed-identity; A1 lets it through (correct — see §0.2.1)** |
| p08u alias+add outside | `int a=q; a+=5; if(q==5) r=θ(a,.9)` | add SANK into the arm; `θ(%4,.9)` | — | DECLINE `control flow` | stray op in the arm (R1) |
| p08v arm-local add | `if(q==5){int a=q+5; r=θ(a,.9);}` | **folded to `θ(i32 10,.9)`** | `10`/`10` | DECLINE `control flow` | ≡ p08t |
| p09a–d **the twins** | `r=θ(SEED,0.0); if(COND) r=θ(r,.9)` | Inc-1 chained shape | — | **ACCEPT ×4** | the Inc-4 reference stream (§2) |
| p10 Rz prep | `r=0; if(q==5) r=φ(0,.9)` | arm `cq_phi(i32 0,…)` | `0`/`0` | DECLINE `control flow` | `cq_phi` on a classical operand |
| p11 undef seed | `int r; if(q==5) r=θ(0,.9)` | **NO BRANCH AT ALL** — `llvm.assume(%2)`, region deleted | — | DECLINE **`taint escape: tainted value consumed by an unknown callee`** | UB ⇒ `-O1` assumes the condition; there is no region to lower |
| p12a two regs | 2 preps on r,s under q,p | 2 sequential diamonds | `0`/`0` each | DECLINE `control flow` | — |
| p12b prep then chain | prep r, then `if(p==3) r=θ(r,.4)` | 2 diamonds; region-2 arm is `θ(%7,.4)` on the merge φ | — | DECLINE `control flow` | region 1 |
| p12c prep then prep | 2 preps on the same r | 2 diamonds; region-2 pred-in is region-1's φ | `0`/`%7` | DECLINE `control flow` | region 2 is a **data mux** |
| p12d prep then uncond θ | prep then `r=θ(r,.4)` | diamond + post-region theta | — | DECLINE `control flow` | — |
| p13a–g consumers | measure / ret / `r+1` / `printf` / chained θ / helper call / none | diamond survives in **all seven** | `0`/`0` | DECLINE (`control flow`; p13f `specialization: callee measures under quantum lift`) | consumer axis is orthogonal to the region |
| **p14a** if/else 2 preps | `if(q==5) r=θ(0,.9) else r=θ(0,.4)` | **NO diamond** — ONE `θ(i32 0, %select)` with a tainted-cond ANGLE SELECT | `0` | DECLINE **`rotation angle`** | `classifyAngleSelect` **S3** (`ArmClassify.cpp:3154`) — the *second* Inc-4 customer site |
| p14b diff seeds | `… else r=θ(3,.4)` | real if/else, 2 thetas, no pred incoming | `0`,`3` | DECLINE **`impure phase arm`** | two rails |
| p15a derived cond | `if((q&6)==2)` | diamond, `and`+`icmp` | `0`/`0` | DECLINE `control flow` | — |
| p15b `>` | `if(q>5)` | diamond | `0`/`0` | DECLINE `control flow` | — |
| p15c Q+Q | `if(q==p)` | diamond | `0`/`0` | DECLINE `control flow` | — |
| p15d `&&` | `if(q==5&&p>2)` | `select i1` condition | `0`/`0` | DECLINE `control flow` | `!isa<CmpInst>(Region.Condition)` |
| p15e `\|\|` | `if(q==5\|\|p==2)` | `select i1` condition | `0`/`0` | DECLINE `control flow` | same |
| p16 runtime seed | `int r=seed; if(q==5) r=θ(seed,.9)` | diamond; **pred incoming IS the seed argument `%0`** | `%0`/`%0` | DECLINE `control flow` | classical arg-0; the §7 fence as written (`Constant`) would also decline — **free widening candidate** |
| p17a/b/c/d widths | i8 / i64 / i1 / i16 | clean diamonds at each width | `0`/`0` | DECLINE `control flow` ×4 | — |
| p18a in-loop rolled | prep in a `for(K=2)` body, `r` loop-carried | region in the body; **φ pred-in is the loop-carried `%8`, NOT a constant** | `0`/`%8` | DECLINE `control flow` | **structurally a data mux, not merely R7** |
| p18b hand-unrolled twin | K=2 unrolled | 2 sequential diamonds | `0`/`0`,`%…` | DECLINE **`condition predates a non-diagonal gate`** | (region 2's pred-in is region 1's φ) |
| p18c in-loop iteration-local | `for(…){int r=0; …; printf(r);}` | φ pred-in is the **constant 0** | `0`/`0` | DECLINE `control flow` | **the only in-loop spelling that IS the Inc-4 shape** |
| p19a "nest" | `if(a){if(b){r=θ(0,.9);}}` | **NOT a nest** — `-O1` flattens to ONE `br` on `select i1` | `0`/`0` | DECLINE `control flow` | ≡ p15d; the 4.3 nest is unreachable from this C |
| p19b switch | `switch(q){case1:…case2:…}` | **NO switch arm** — a `phi double` ANGLE MUX feeding ONE `θ(i32 0, %4)` | `0` | DECLINE `control flow` | AnglePhi-shaped |
| p20 prep feeds cond | prep r, then `if(r==1) s=φ(s,.2)` | 2 diamonds; region 2's condition reads region 1's φ | `0`/`0` | DECLINE `control flow` | region 1 |
| p21a classical `c?0:0` | | folds to constant 0 — **≡ p01's shape** | `0`/`0` | DECLINE `control flow` | — |
| p21b classical `c?0:3` | | pred-in is a classical `select i32` | `0`/**`%4`** | DECLINE `control flow` | genuine data mux |
| p22 post-region Ry on q | prep then `q=θ(q,.3)` | diamond + post-region theta on the condition register | `0`/`0` | DECLINE **`condition predates a non-diagonal gate`** | re-spelling; **unmasks to `control flow`** (p22b, `cq_phi`) |
| p22b post-region Rz on q | prep then `q=φ(q,.3)` | diamond | `0`/`0` | DECLINE `control flow` | — |
| **p23a** pred-fold seed0 | `r=5; if(q!=5) r=θ(0,.9)` | pred edge proves `q==5`; pred-in `5` | `0`/`5` | DECLINE `control flow` | **≡ p23c** (`int r=q;`) — FOLD B |
| **p23b** pred-fold seed5 | `r=5; if(q!=5) r=θ(5,.9)` | pred-in `5` == seed == literal | `5`/`5` | DECLINE `control flow` | **≡ p23d** (`int r=q;`) — FOLD B, **A2 is the only thing that stops it** |
| p23c / p23d | `int r=q; …` variants | (the aliasing sources of p23a/p23b) | — | DECLINE `control flow` | — |

**Unmasked clauses.** Three probes printed `condition predates a non-diagonal gate`
(the `declineArm` re-spelling the brief warned about). All three were re-run with
one token changed and unmasked:
`p08r`/`p08s` — arm `cq_theta`→`cq_phi` ⇒ `control flow` (the real clause is R4,
the arm rotating the condition wire); `p22` — post-region `cq_theta`→`cq_phi` on `q`
(p22b) ⇒ `control flow`. **No probe's printed string named its real clause.**

---

## 2. The MANUAL TWIN and the reduction (the Inc-4 witness)

The reference is the Inc-1 chained shape on a rail seeded by an explicit `Ry(0)`:

```c
int r = cq_theta(SEED, 0.0);  if (COND) r = cq_theta(r, 0.9);
```
It **ACCEPTS on the ORACLE** for all four spellings measured (`SEED=0`, `SEED=5`,
`!=` polarity, `double`), links, and runs. p09a's raw trace:

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cqrt_alloc_i32(0) -> h1
cqrt_ry_i32(h1, 0x0p+0)                       <-- (i) DELETE
cq_template_icmp_eq_i32_hl(h0, 5) -> h2
cqrt_ry_i32_controlled(h2, h1, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h2, h0, 5)
cqrt_free(h2)
cqrt_measure_i32(h1) -> 0
cqrt_measure_i32(h0) -> 0
```
strict stage 2b: `4 rail mint(s), 4 left allocated, 2 cqrt_free site(s): 2 verified,
0 violation(s), 0 unproven`.

**THE REDUCTION** (`$S/probe/reduce_twin.py`, applied mechanically):
1. **delete** `cqrt_ry_<W>(h, 0x0p+0)` — a zero-angle Ry **is** the identity;
2. **move** `cqrt_alloc_<W>(SEED) -> h` to immediately before the first
   `cqrt_ry_<W>_controlled(f, h, ·)` naming `h` — a fresh-rail alloc acts on a
   disjoint wire and therefore **commutes** with every gate that does not name its
   handle;
3. renumber handles by first appearance.

Both rewrites are **physical identities**, not the transformation under test. (The
`by-difference-twin-blind-to-arithmetic` lesson applies: this witness must not
share the transformation it witnesses. It does not — the twin performs a REAL
`Ry(0)` on a REAL allocated rail and Inc 4 will perform NEITHER, so the reduction
is exactly the two facts being claimed, made explicit.)

### **EXPECTED POST-Inc-4 TRACE FOR p01** (this is the implementer's target)

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1.3333333333333p-2)
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_alloc_i32(0) -> h2
cqrt_ry_i32_controlled(h1, h2, 0x1.ccccccccccccdp-1)
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h2) -> 0
cqrt_measure_i32(h0) -> 0
```

Seed-5 twin (p09b reduced) is the same with `cqrt_alloc_i32(5)`.
f64 twin (p09d reduced): `cqrt_alloc_f64(0x0p+0) -> h2` /
`cqrt_ry_f64_controlled(h1, h2, …)` / `cqrt_measure_f64(h2) -> 0x0p+0`.
`!=` twin (p09c reduced) puts the alloc **between** the two `cqrt_x(h1)` brackets:

```
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_x(h1)
cqrt_alloc_i32(0) -> h2
cqrt_ry_i32_controlled(h1, h2, …)
cqrt_x(h1)
```
⚠ **That position is a real degree of freedom.** PRD §6 mints the flag at `BI`
then hoists `T` to before `BI`, and `lowerRotations` mints the alloc at the
(hoisted) theta — which lands *after* the mint and *inside* the `cqrt_x` bracket,
matching the reduction. If the implementer hoists the alloc earlier (e.g. to the
top of the pred, which is also correct physics) the byte-diff moves and the
reduction rule has to move with it. **Decide this before writing the golden.**

**Note the freeze is already visible in the twin:** `h1` (the rotated rail) is
never freed — `ChainWalk::railCarriesControlledRotation` marks it `NotClosed`.
For state prep the frozen rail is one the compiler itself allocated, so Inc 4
inherits the Inc-1 freeze unchanged; a `cqrt_free` of it would be a dirty free.

---

## 3. The eq-fold verdict, per probe (asked by the brief)

**Is `p08a` textually indistinguishable from state prep? YES — byte-for-byte, whole
module.** Which of p08 a–j fold:

| | source arg-0 | folds? | resulting seed | indistinguishable from a genuine prep? |
|---|---|---|---|---|
| a | `q` under `q==0` | **YES** | `0` | **YES** — ≡ `cq_theta(0,.9)` (p08a_ctl_prep0), identical module |
| b | `q-5` under `q==5` | **YES** | `0` | **YES** — ≡ p01 exactly |
| c | `q` under `q>4&&q<6` | **YES** (range → `icmp eq 5` first) | `5` | **YES** — ≡ p06a |
| d | `a` (`int a=q`) under `q==0` | **YES** | `0` | **YES** — ≡ p08a_ctl_prep0 |
| e | `q` under `q==5`, `r=5` | **YES** | `5` | **YES** — ≡ p06a |
| f | `q` under `q==0`, if/else | **YES** | `0` | **YES** (φ-pred listing order only) |
| g | `q` under `u<1u` | **YES** (canonicalized to `eq 0` first) | `0` | **YES** — ≡ p08a_ctl_prep0 |
| h | `q` under `q==5`, `r=0` | **YES** | `5` | **no** — pred incoming `0` ≠ seed `5`; the §7 seed-identity fence declines it |
| i | `cq_phi(q,…)` under `q==0` | **YES** | `0` | n/a (Rz stem) — and it **declines today**, while its `merge-over-q` sibling p08l **accepts and re-anchors** |
| j | `q=θ(q,…)` under `q==0`, merge over `q` | **YES** (arg-0) | `0` | **no** — pred incoming is `%1`, the handle |

**8 of 10 fold; 7 of 10 produce IR indistinguishable from a genuine state prep;
5 of those 7 survive the §7 seed-identity fence** (a, b, c, d, e — plus f, g).
Of those, **all but (b) are the IDENTITY fold** (seed == the compare literal), which
is the R4-forbidden aliasing case; (b) is a non-identity fold and is benign.

---

## 4. Scope corrections the PRD should absorb

1. **§7's "If/else with two preps declines (two rails)" describes a shape plain C
   does not produce.** `if(c) r=cq_theta(0,.9); else r=cq_theta(0,.4);` is merged by
   `clang -O1` into ONE theta with a tainted-condition **angle select** (p14a) and
   declines at `classifyAngleSelect` **S3**, not in `classifyArms`. The "two rails"
   shape needs DIFFERENT seeds (p14b) to survive as an if/else, and that one declines
   `impure phase arm`. **Inc 4 therefore has TWO customer sites**: `ArmClassify.cpp:725`
   (`inPlaceRotationArmTheta`) and `ArmClassify.cpp:3154` (`classifyAngleSelect` S3).
   The second is an Inc-2b by-difference candidate on a fresh rail
   (`alloc(0); ry(h, B); ry_controlled(f, h, A−B)`) and is worth a deliberate
   in-scope / out-of-scope ruling rather than an accident.
2. **A runtime seed is structurally the same shape** (p16): the merge's pred incoming
   is the SAME SSA value as the theta's arg-0 (`%0`, a classical function argument),
   just not a `Constant`. `cqrt_alloc_<W>` takes a runtime value, so the §7 fence
   spelled as *"the pred incoming is the SAME VALUE as `T`'s arg-0, and that value
   is classical"* subsumes the `Constant` case and picks p16 up for free. Note the
   `Constant` spelling is NOT redundant: it is what makes `0.0` vs `-0.0` a decline
   (p07b/p07c, both reachable from plain C), because LLVM uniques `ConstantFP` on the
   bit pattern, so value identity already IS bit identity.
3. **`-0.0` is not hypothetical** — p07b and p07c reach the pass from ordinary C in
   both directions (seed `0.0`/pred-in `-0.0` and the mirror).
4. **`int r;` (uninitialized) has no region at all** (p11): reading `r` on the false
   path is UB, so `-O1` emits `llvm.assume` and DELETES the branch. The `undef`
   pred-incoming case the PRD anticipates is unreachable from plain C; if a fence
   for it is wanted it is a HAND-IR fence.
5. **A depth-2 nest and a `switch` do not reach the pass as such** for this shape
   (p19a: flattened to a compound `select i1` condition; p19b: turned into an
   `phi double` angle mux). The PRD's "nested / switch decline" bullets are about
   hand IR here.
6. **In a loop, only the ITERATION-LOCAL spelling is the Inc-4 shape** (p18c: pred
   incoming is the constant `0`). The loop-carried spelling (p18a) has the loop φ as
   its pred incoming and is a genuine data mux — it would decline on seed-identity
   even with R7 lifted. Worth stating, because "in-loop state prep" sounds like one
   thing and is two.
7. **A compound condition pins MORE THAN ONE register** (p08q: `q==5 && p==3` folds
   the arm's `p` to `3`). Compound conditions decline today on
   `!isa<CmpInst>(Region.Condition)`, so A1 need not walk a flag network — **but if
   compound conditions are ever admitted, A1 must be asked of every leaf.** (This is
   the "when you widen a set, ask what OTHER set was computed over the same closure"
   obligation, written down now.)

---

## 5. Things that surprised me

* **The shipped compiler already reads a const-folded arm seed as the HANDLE**
  (p08l accepts and emits `cqrt_rz_i32_controlled` on `q`'s own rail). I expected
  to find the ambiguity; I did not expect to find CQ already resolving it the
  other way for the sibling stem.
* **`clang -O1` folds an ARM-LOCAL derived value too** (p08v `int a = q + 5;`
  inside the arm → `cq_theta(i32 10, .9)`), so "the arm block contains only the
  theta" is a property the fold can CREATE, not only preserve.
* **The fold is not deterministic across equivalent sources** (p08h folds, p08s
  does not, and they differ only in how the compare was written).
* **p11's region disappears entirely** on UB grounds — the diagnostic that comes out
  (`taint escape … unknown callee`, from `llvm.assume` eating the tainted compare)
  has nothing to do with state prep.
* **p18a's in-loop merge φ takes the loop-carried value, not a constant** — I had
  assumed R7 was the only thing standing between Inc 4 and a rolled loop; it is not.

---

**PART 1 COMPLETE.**

---

# PART 2 — THE TWO MATRIX AXES (pre-implementation record)

## 2(a) `tools/inplace_twin_matrix.py` — the STATE-PREP axis (`--stateprep`)

* **A separate POOL, not a sixth axis**, because its two sides are different
  programs from the five-axis cells' two sides.
  Subject `T r = SEED; if (cond) r = cq_theta(SEED, 0.9);` vs. twin
  `T r = cq_theta(SEED, 0.0); if (cond) r = cq_theta(r, 0.9);`.
* **A separate ORACLE flag, `--prep-oracle`.** `--route-oracle` wants the PRE-2a
  binary (`f92d95e`); this axis wants the PRE-Inc-4 one (`b506b3b`). One flag with
  two meanings would be a trap, so the axis takes its own, falling back to
  `--route-oracle`, then to the build under test **with a loud printed warning**.
* **The reduction** (`reduce_prep`): delete `cqrt_ry_<W>(h, 0x0p+0)`; move
  `cqrt_alloc_<W>(SEED) -> h` to just before the first
  `cqrt_ry_<W>_controlled(f, h, ·)`; renumber handles. Both are physical
  identities; the docstring says so and says why (the
  `by-difference-twin-blind-to-arithmetic` discipline applied in advance).
  `seed_matcher` compares the alloc literal **numerically** — C's `%a` prints
  `0x0p+0` where Python's `float.hex()` gives `0x0.0p+0`, and a textual set would
  have silently failed to find every f64 alloc and reported MISMATCH for a harness
  reason. Unit-checked against the measured p09a and p09d traces.
* **Verdicts:** `DECLINE-BOTH` / `DECLINE-BOTH-DIFF` /
  `SUBJECT-DECLINES-TWIN-ACCEPTS` / `IDENTICAL` / `MISMATCH` /
  `SUBJECT-ACCEPTS-TWIN-DECLINES` / `HARNESS-ERROR`.
* **`ifelse2` excluded** (its else arm rotates a second register chained-style);
  `ifelse` kept, and it is informative — both sides fold to an ANGLE SELECT.
  The second region in `clsbetween` / `region2` stays a CHAINED rotation on the
  prepped register, deliberately.
* **`--only sp_` / `--only c_` each select exactly one pool.**
* **Existing cells proven untouched:** all 472 + 40 + 198 cells' generated source
  text is byte-identical to the pristine module's for BOTH arm spellings (0
  changed, 0 renamed); `--list`, `--quick --list`, `--triples --list` all diff to
  0 lines. Report column widths were deliberately left at their original values.
* **No ctest entry** (bd `drbq.9` still pending, per the file's own header).

### PRE-4 VERDICT TABLE — `$S/probe/inplace_stateprep_pre4.txt`

**297 cells, 594 pipelines, 2 min 59 s at `--jobs 8`** on an otherwise-idle box.

| verdict | cells |
|---|---|
| `SUBJECT-DECLINES-TWIN-ACCEPTS` | **215** |
| `DECLINE-BOTH` | **53** |
| `DECLINE-BOTH-DIFF` | **29** |
| `IDENTICAL` | 0 |
| `MISMATCH` | 0 |
| `SUBJECT-ACCEPTS-TWIN-DECLINES` | 0 |
| `HARNESS-ERROR` | 0 |

0 rows flagged `!!`, 0 invariant violations, 0 harness notes. The 82 both-decline
cells are the consumers the CHAINED twin also refuses (`none`, `ret`, `call`,
`value2` → `DECLINE-BOTH`; `launder`, `aliasmeas` → `DECLINE-BOTH-DIFF`) — the
Inc-1 R6 family, orthogonal to state prep. **After Inc 4 the in-scope cells should
move `SUBJECT-DECLINES-TWIN-ACCEPTS` → `IDENTICAL`; that diff is the witness.**

## 2(b) `tools/loop_twin_matrix.py` — ONE state-prep DECLINE control

* New `RY_REGION["rprep"]` = `if (a == 5) { r = cq_theta(0, 0.9); }`, added as
  sub-grid **E2** = the single cell `("ry","rprep","none","none","none")` →
  **`m_ry_rprep_none_none_none`**. Asserted sizes 117 → 118, 273 → **274**.
* The `ry` PREFIX (not `none`) is deliberate and **measured both ways**: with no
  a-register gate `a` is loop-invariant, LICM hoists the compare, and
  `("none","rprep",…)` decides its rolled disposition on the hoist
  (`condition predates a non-diagonal gate`) before the loop clause is reached.
* **Existing cells proven untouched:** generated all 273 pre-edit cells' sources
  from the edited module and from `git show HEAD:tools/loop_twin_matrix.py` —
  **0 cells whose source text changed**, 0 removed, exactly 1 added; both
  boundary controls' sources identical.
* `--regenerate` ran the whole 274-cell matrix + 2 controls and **did not refuse**
  (`regenerated … (259 cells; 15 quarantined and omitted)`), so no quarantined
  signature and no boundary control had moved.
* **The `expected.txt` diff is exactly +1 row** (plus the 3-line header text I
  edited in `EXPECTED_HEADER`); the 258 pre-existing rows are byte-identical:

  ```
  m_ry_rprep_none_none_none DECLINE-BOTH-DIFFERENT	cq controlled lowering: control flow under quantum control	cq controlled lowering: condition predates a non-diagonal gate under quantum control
  ```
* **Verification run (check mode) is GREEN**: `274 cells — 186 ACCEPT-IDENTICAL,
  47 DECLINE, 41 other; 15 quarantined (pinned signatures), 2 boundary controls /
  all cells match … / all 15 quarantined cells diverge with their pinned
  signature / both boundary controls identical`.
* `tools/loop_twin_matrix_quarantine_test.py` (ctest
  `e2e-loop-twin-quarantine-selftest`, which imports this module): **12 cases, 0
  failures**.
* ⚠ **What this cell cannot isolate**, recorded in the source beside it: the
  wrapper seeds `r = cq_theta(r, 0.3)` before the loop on every `RY_REGION` cell,
  so the merge φ's pred incoming here is the loop-carried QUANTUM `r` — a genuine
  Q data mux independently of the loop. A red means "Inc 4 widened into a loop OR
  into a non-constant pred incoming"; it does not say which.
