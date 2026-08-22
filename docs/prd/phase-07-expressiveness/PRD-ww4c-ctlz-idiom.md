# PRD — bd `ww4c`: the shift-count loop → `llvm.ctlz` idiom recognizer

**Date:** 2026-08-22 · **Branch:** `ww4c-ctlz-idiom` · **Phase:** 7 (expressiveness), libm
campaign · **Type:** PRD — **no pass change, no fixture, no implementation in the session
that wrote this.**

**Decided by:** owner GO 2026-08-22 on
[`DECISION-m57l-vs-ww4c.md`](DECISION-m57l-vs-ww4c.md) (*"go with ww4c — write the PRD"*),
over bd `m57l`, which stays **open and deferred**.

**Inputs, none re-derived here:** bd `ww4c`, bd `m57l`, bd `19v3`
([`SPIKE-19v3-loop-bound-population.md`](SPIKE-19v3-loop-bound-population.md) §4a/§4b), bd
`8zj2`, bd `eyhj`, bd `ywws`, bd `k02s`, bd memory
[`narrowed-quantum-trip-rule-2026-08-21`].

**New measurement in this PRD** (§3, §4 — taken while writing it, single-file compiles and
one arithmetic sweep, no census, no rebuild): the real `-O1` IR of all three target loops,
and an exhaustive 2³² verification of the closed form specified in §4. Both **change the
design** the decision memo assumed. They are marked ⚑ where they do.

---

## 1. The ruling this is built on

The memo's §3.4 asked an owner question — *does a loop-idiom recognizer count as injection
coverage?* — and flagged that the GO must **not** be read as answering it by inference
(that is `CLAUDE.md`'s documented failure mode: the fenv prose, where an agent-authored
justification hardened by repetition into a de-facto ruling). It was put back to the owner
in one line before this PRD was drafted.

> **Owner, verbatim (2026-08-22):**
> *"yes, it counts as injection coverage — the body stays openlibm's"*
>
> and, in the same exchange, the framing that is the **ratio** rather than decoration:
> *"we only replace the form of the loop, the rest of the injected opcode source remains
> the same"*.

**What the ruling turns on — the first clause.** Rule 18's axis is **whose source**: inject
theirs (injection), ship ours (CQ-PROVIDED), or never see a body at all (per-function name
recognition, which Rule 18 retires as fiction). Structural rewriting of *their* IR is not on
that axis — it is what compilation is. The precedent is already in-tree: `LoopUnrollPrepass`
unrolls `__polevll` Horner loops inside injected bodies and those cells count, and stock
LLVM ships `LoopIdiomRecognize` and fires it on a neighbouring spelling of this very idiom.

**A note for whoever quotes this later.** The owner's *second* clause — "the original
injection cannot be compiled" — is the **motive**, not the argument. Taken alone it licenses
CQ-PROVIDED equally well (that is precisely the `sin`/`cos`/`tan` justification). Quote the
first clause.

**Consequence:** when the two cells land, the **injection numerator moves 98 → 100**. Not a
new scoreboard row, not CQ-PROVIDED; [`libm-scoreboard-two-numbers`] is unchanged in shape.

### 1.1 The honesty obligation the ruling carries — binding, and mechanically discharged

If the accept predicate is tuned until `ilogb`'s spellings fall inside it, that **is**
per-function recognition in a structural costume. It would be invisible in the census number
and visible only in the predicate. This is Rule 17's mirror image: the Rule warns against
*narrowing* the accept shape until the target falls **outside** it; the dual hazard here is
*widening* it until the target falls **inside**.

It is discharged by construction, not by assertion. §5's predicate is stated over IR
structure with no reference to `ilogb`, `s_ilogb.c`, any function name, any seed constant or
any width the targets happen to use; and §10's probe family is required to contain **both**
directions:

* shapes that **are** the idiom and are **not** `ilogb` — a different width, a different
  seed, a different enclosing function, no enclosing guard — which must **accept**;
* shapes that **resemble** `ilogb` and are **not** the idiom — above all the f80 mask-shift
  of `ilogbl`/`logbl` — which must **decline**.

A landing that accepts only the three target loops has failed this obligation even if every
test is green.

---

## 2. Scope

### 2.1 In

| cell | loops rewritten | source |
|---|---|---|
| `ilogb.f64` | **two** | `s_ilogb.c:40` (the `lx` loop) and `:42` (the `hx` loop) |
| `ilogbf.f32` | **one** | `s_ilogbf.c:35` |

**98 → 100 is the whole payoff**, measured by bd `19v3` over the whole census (125 cells
probed; 19 carry a loop; 13 first-block on a loop; 10 hit Q1; 5 first-block on a loop with a
usable bound; **2** have nothing further behind them). Both `m57l` and `ww4c` reach exactly
these two, so the choice was never about coverage.

### 2.2 Out, and it must stay out

* **`fmod` / `remainder` / `remquo`.** Their blocker stack is exactly **four loops deep**
  and the back two are vacuous (constant-max `-2`) or `CouldNotCompute`. `fmodf.f32` /
  `fmodl.f80` / `remainderf.f32` die a gate earlier at `kMsgBreakMultiSite` (the 7.4
  multi-break widening under `8h7d`). **They are out of scope and they stay declining.**

  > ⚠ **CORRECTED 2026-08-22 (bd `ww4c.3` adversarial round).** This bullet used to end
  > *"Nothing in this PRD touches them"*, and that is **measurably false**. `e_fmod.c`
  > lines **54, 56, 63, 65** are four verbatim copies of this very idiom — `fmod` inlines
  > `ilogb`'s exponent extraction for *both* operands — so the fence claims them, and the
  > census diag of `fmod.f64` and `remainder.f64` moved one layer deeper as a result:
  > `cq controlled lowering: loop under quantum control` → `cq loop lowering: multiple
  > early-break sites`. **Both still decline, no cell regressed, and coverage is
  > unchanged** (they stay in bucket `loop-carried`) — so the *scope* claim holds and only
  > the *blast-radius* claim was wrong. Note this is a same-bucket move, invisible to a
  > status/bucket A/B and recoverable only by diffing the `diag` field.
  >
  > **It is also the §1.1 honesty obligation discharged where it counts**: the predicate
  > fires on the same idiom in a function that is not `ilogb`, which is precisely what a
  > per-function recognizer in structural costume could not do.
  >
  > **And the loop bd `k02s` warns about is NOT claimed.** `e_fmod.c:112`'s
  > `while (hx < 0x00100000) { hx = hx+hx+(lx>>31); lx = lx+lx; }` — the one that does not
  > terminate on `hx==0, lx==0` once the tainted guard is speculated away — fails **Z3**
  > (its latch value is an `add`, not `shl`), **Z5** (`icmp ult`, not `icmp sgt … 0`) and
  > **Z4** (no counter at all). Three independent grounds, which is the defence-in-depth
  > §5.1 argues for, doing its job on the one loop where it mattered most.
* **`ilogbl.f80` / `logbl.f80`.** A different idiom (§5.3) with no derivable bound, deferred
  under bd `ywws`. They must **decline**, and §5.3 is the fence that makes them.
* **`m57l`** — the rolled quantum-bounded loop. Not built, not closed, not superseded as a
  *design*; it simply has no customer today.
* **bd `qck7`** (the `CLAUDE.md` Rule 18 amendment) stays **PARKED**. `ww4c` does not need
  it, and amending the prose before a fence exists licenses a lowering the compiler cannot
  emit.

---

## 3. ⚑ What the pass actually sees — measured, and it corrects the design

Rule 9 forbids assuming IR shape and Rule 11 forbids trusting a prior session's summary of
it. All three loops were compiled from the real openlibm sources at the ship floor
(`clang -O1`, Homebrew clang 19.1.7, `/private/tmp/openlibm`). This is a single-file compile,
**not** a census.

### 3.1 `ilogb.f64` — the two loops are **structurally different**

```llvm
;; loop A — s_ilogb.c:40, the `lx` loop.  GUARDED.
13:                                               ; preds = %11
  %14 = icmp sgt i32 %5, 0
  br i1 %14, label %15, label %34                 ; guard-bypass goes STRAIGHT to the return merge

15:                                               ; preds = %13, %15
  %16 = phi i32 [ %18, %15 ], [ -1043, %13 ]      ; counter,  C0 = -1043
  %17 = phi i32 [ %19, %15 ], [ %5,    %13 ]      ; shift recurrence, entry = %5 (raw low word)
  %18 = add nsw i32 %16, -1
  %19 = shl nuw i32 %17, 1
  %20 = icmp sgt i32 %19, 0
  br i1 %20, label %15, label %34, !llvm.loop !6

;; loop B — s_ilogb.c:42, the `hx` loop.  UNGUARDED — clang folded the guard away.
21:                                               ; preds = %11
  %22 = shl nuw nsw i32 %6, 11                    ; the PRE-SHIFT, in the preheader
  br label %23                                    ; unconditional

23:                                               ; preds = %21, %23
  %24 = phi i32 [ -1022, %21 ], [ %26, %23 ]      ; counter,  C0 = -1022
  %25 = phi i32 [ %22,   %21 ], [ %27, %23 ]      ; shift recurrence, entry = %22
  %26 = add nsw i32 %24, -1
  %27 = shl nuw i32 %25, 1
  %28 = icmp sgt i32 %27, 0
  br i1 %28, label %23, label %34, !llvm.loop !9

34:
  %35 = phi i32 [ %33, %31 ], [ -2147483647, %8 ], [ 2147483647, %29 ],
                [ -1043, %13 ], [ %18, %15 ], [ %26, %23 ]
  ret i32 %35
```

`ilogbf.f32` (`s_ilogbf.c:35`) is loop B's shape exactly — preheader `%8 = shl nuw nsw i32 %3, 8`,
unconditional entry, `C0 = -126`.

### 3.2 The three facts that change the design

1. **Two of the three target loops are UNGUARDED.** Only loop A carries an `icmp sgt` guard;
   for loop B and `ilogbf` clang proved the entry value positive (`%6 != 0` from the
   dominating branch, `%6 < 2²⁰` from the subnormal test) and folded the guard. **A
   recognizer that matches "guard + do-while" as one region reaches one of three loops.**
   The unit of work must be the **loop alone**.
2. **The pre-shift lives in the preheader, outside the loop** (`shl %6, 11`, `shl %3, 8`), and
   loop A has none. So the pre-shift is **invariant to the fence** — the recognizer takes the
   shift recurrence's preheader incoming *as it is* and must **never look through it**. This
   is an accept-side property needing a positive fixture pair, not a decline (§5.4).
3. **Every loop is a rotated do-while**: the sole exiting block **is** the latch, the exit
   test is on the *post-shift* value, and the body executes at least once. The closed form
   must be derived for **that** loop, not for the source `for` statement.

---

## 4. ⚑ The transformation

### 4.1 The closed form, derived

For the rotated do-while `do { c--; x <<= 1; } while ((signed)x > 0)` on `iN` (N a power of
two), with entry value `v`, let `f(v)` be the number of body executions. Then

> **f(v) = 1 + (ctlz<sub>N</sub>(v << 1) mod N)**, on the **whole** domain.

*Proof.* Let `u = v << 1` (wrapping). The body always runs once, so `f ≥ 1`, and the further
executions are governed by `u`.
**Case `u ≤ 0`:** the `while` fails immediately, `f = 1`. If `u < 0` then `ctlz(u) = 0`; if
`u = 0` then `ctlz(u) = N` and `N mod N = 0`. Either way the formula gives `1 + 0 = 1`. ∎
**Case `u > 0`:** let `L = ctlz(u) ∈ [1, N-1]`, so `u`'s leading one sits at bit `N-1-L`.
After `k` further shifts it sits at `N-1-L+k`, which is the sign bit exactly at `k = L`; for
every `k < L` the leading one is below the sign bit and still in range, so `u << k > 0` and
the loop continues. Hence exactly `L` further executions, `f = 1 + L`, and `L mod N = L`. ∎

`mod N` is `and (N-1)` for N a power of two, and every shipped `ctlz` width (i8/i16/i32/i64)
is one. The escaping counter is therefore

> **c_exit = C0 − f(v) = (C0 − 1) − (ctlz(v << 1) & (N − 1))**

### 4.2 Verified exhaustively, not argued

`tools`-free scratch sweep over **all 2³²** `i32` inputs, simulation as the oracle:

| claim | mismatches over 2³² |
|---|---|
| bare do-while: `f(v) == 1 + (ctlz(v<<1) & 31)` | **0** |
| guarded region: `g(v) == ctlz(v) & 31` | **0** |
| *unrepaired* naive `g(v) == ctlz(v)` | **1** (at `v == 0`) — independently reproduces the memo's figure |
| max trips (both forms) | **31** — independently reproduces 19v3's C4 figure |

The third row is the memo's §3.2(a) measurement reproduced; the first is new and is what this
PRD specifies. The i64 row rests on the §4.1 proof (width-generic) plus boundary +
randomized checks — **it is not exhaustively verifiable and the PRD does not claim it is**
(§10 fixture `Z9-i64`).

### 4.3 ⚑ The emission — four ops, no `select`, no 4.4 merge

The decision memo's §3.2(a) budgeted `ctlz + sub + icmp + a tainted select` (the 4.4/kjd1
controlled-XOR copy merge: flag mint → two `cqrt_copy_<W>_controlled` → `cqrt_x` bracket →
compare-`_inv` strip → `cqrt_free`), *twice* for `ilogb.f64` — **~10 tainted ops**. That
estimate was correct **for LLVM's canonical output**, which repairs the `x == 0` case with a
`select` because it recognizes the `while (x != 0)` idiom, whose closed form is
`N − cttz`-shaped. We are writing the emitter, and for the `sgt 0` idiom the repair is a
**mask** (§4.1: `ctlz(0) = N`, and `N & (N-1) = 0`). So:

```llvm
;; replaces the loop body in the header block, which keeps its preheader edge
  %s1 = shl i32  %entry, 1                          ; cq_template_shl_i32_hl
  %z  = call i32 @llvm.ctlz.i32(i32 %s1, i1 false)  ; cq_template_ctlz_i32     <- immarg FALSE
  %m  = and i32  %z, 31                             ; cq_template_and_i32_hl
  %c  = sub i32  (C0 - 1), %m                       ; cq_template_sub_i32_lh
  br label %exit
```

**Four tainted ops per loop — 12 total across the three loops (8 for `ilogb.f64`, 4 for
`ilogbf.f32`) — and no `select`, no flag mint, no controlled copy, no `cqrt_free`, no
dependence on `SelectClassify`/`SelectMergeEmit` at all.** This *reduces* the memo's cost
basis; it does not disturb the decision. It is a design-time derivation plus an arithmetic
sweep — **Rule 2 says the evidence is the e2e golden**, which Increment 2 owes.

Concretely, `ilogb.f64` loop A becomes `sub i32 -1044, %m` and loop B `sub i32 -1023, %m`;
`ilogbf.f32` becomes `sub i32 -127, %m`. End-to-end sanity, checked by hand against the
source semantics: the smallest subnormal double (`hx=0, lx=1`) takes loop A, `%5 = 1`,
`s1 = 2`, `ctlz = 30`, giving `-1044 - 30 = -1074` — which is `ilogb(2^-1074)`. ✔

### 4.4 Zero new frozen symbols — verified on the archive, not asserted

```
T _cq_template_ctlz_i32      T _cq_template_ctlz_i32_unc
T _cq_template_shl_i32_hl    T _cq_template_shl_i32_hl_unc
T _cq_template_and_i32_hl    T _cq_template_and_i32_hl_unc
T _cq_template_sub_i32_lh    T _cq_template_sub_i32_lh_unc
```

(`nm -g build/runtime/libcq_templates.a`.) All four forward templates and all four `_unc`
twins already exist. `tools/opcode_table.yaml` carries `sub` with `fwd_lh`/`unc_lh`, `and`
and `shl` with `fwd_hl`/`unc_hl`; `tools/intrinsic_table.yaml:136` carries `ctlz` at
i8/i16/i32/i64 with `[fwd, unc]`. **Rule 15 is untouched — no YAML edit, no regeneration, no
Phase-11 freeze-surface movement.**

### 4.5 Three emission rules that are not optional

1. **`is_zero_poison` must be the literal `i1 false`.** `PoisonFacts.cpp:27-38`
   (`curatedIntrinsicCanBePoison`) returns `!Flag || !Flag->isZero()` for
   `ctlz`/`cttz`/`abs` — so it reports *cannot be poison* **only** when the flag is a
   `ConstantInt` **zero**. `PredMuxFlatten.cpp:174-207` refuses to flatten any cone
   containing such an intrinsic when that predicate says it can be poison, and **LLVM's
   canonical form emits `i1 true`**. The value is unaffected either way:
   `intrinsic_table.yaml:33-38` drops the immarg and lowers the **total** function, so
   `ctlz(0) = N` honestly, and both `fwd` and `_unc` use the same total `f`.

   > ⚠ **Inc-3 correction — the RULE STANDS, its JUSTIFICATION did not.** This item used to
   > continue: *"Copying it verbatim declines the very cell this ticket exists to unblock —
   > and the enclosing `if (hx == 0)` diamond must flatten for the cell to lower."*
   > **Measured false, independently by two adversarial lenses:** both target cells rebuilt
   > with `i1 true` lower **identically** — same exit code, same template count, lowered IR
   > differing only in the `ModuleID` line. The reason is the one bd `ut09` records:
   > PredMux's region claim is a **disjunction**, and the real cells' return merges carry
   > **six** and **four** incomings, so they ride the `>2`-incoming disjunct and the
   > poison-gated clause is never consulted for them. `i1 false` remains **required** — it
   > keeps the chain admissible to the shielded-cone definedness proof on any claim path
   > that *does* route through that clause (the 2-incoming merge of
   > `…_guarded_no_preshift.ll` reaches it), and it is the honest spelling regardless — but
   > it must not be quoted as the thing that unblocked `ilogb`. Nothing did; the cells were
   > never blocked on it.
2. **No `nsw` / `nuw` / `exact` on any emitted instruction.** They are poison-generating
   annotations; PredMux's neutralisation machinery has to strip them, and the closed form
   wants wrapping semantics anyway (the §4.2 oracle used them).
3. **The `and` mask is `N-1` taken from the shift recurrence's own type**, never a literal
   31. A width-hardcoded mask is a silent miscompile at every other width.

### 4.6 The mutation — deliberately the smallest one that works

**Do not delete blocks.** The header keeps its preheader edge and becomes straight-line:

1. Compute the §4.3 chain in the header, before the phis' former position.
2. RAUW the escaping counter (`%18` / `%26`) with `%c`.
3. Replace the header's conditional terminator with `br label %exit`, dropping the back edge.
4. The two header phis now have a single incoming — replace each with its preheader value.
5. Delete the dead `add` / `shl` / `icmp` via a **collect-then-mutate `WeakTrackingVH`
   worklist**, never an inline `RecursivelyDeleteTriviallyDeadInstructions` under a block
   iterator (memory [`dce-under-block-iterator-loopphi-uaf`]: that crashes across a loop-phi
   back edge because the operand is not a dominator).

Consequences worth stating, because each is a hazard avoided:

* **No block is erased**, so this adds no eighth site to the `LiteralIntegrity`
  `declineAddressTakenBlocks` / `removeUnreachableBlocksChecked` discipline, and no
  `BlockAddress` can be RAUW'd to `inttoptr (i32 1 to ptr)` behind our backs.
* **The exit phi stays valid.** For loop A the merge keeps two *distinct* predecessors —
  `[-1043, %13]` from the guard bypass and `[%c, %15]` from the collapsed header. A design
  that deleted the loop and rewired `%13` straight to `%34` would give one block two edges
  into a phi with different values.
* **The guard is never touched.** Loop A's `%14` stays as ordinary tainted control flow for
  PredMux, which can now claim the region because it is acyclic.
* **The rewrite converts a control dependence into a data dependence.** Today the escaping
  counter is *classical* — 19v3 §4b measured that exactly one value escapes each of the nine
  candidate loops and it has no `@cq_theta` in its cone, its quantum-ness coming entirely
  from control flow, which Rule 3 does not track. After the rewrite it is a tainted `sub`.
  **That is the mechanism, stated plainly: it is the reason the cell lowers.** It also means
  the `TaintSet` is stale the moment a claim lands (§8).

---

## 5. The accept predicate — Z1–Z9

The whole risk lives here. bd `ww4c`'s 40-cell grid measured **SCEV's shift-compare firing
rule**, which is a different question: this is a **structural** match with its own spec, and
the two must not be assumed to coincide. Every condition below is checked on the loop as
`LoopInfo` presents it, by pure SSA analysis, before any mutation (Rule 9).

| | condition | why it is not a formality |
|---|---|---|
| **Z1** | ⚠ **Amended by Inc 3 — this row was stale in BOTH directions and the shipped fence is the authority.** **TOP-LEVEL** (`getParentLoop() == nullptr`), not merely "innermost"; **exactly one** latch, **exactly one** exiting block, and the exiting block **is** the latch (a rotated do-while); a unique **out-of-loop PREDECESSOR** — *not* a dedicated preheader, deliberately weaker so the guarded `s_ilogb.c:40` loop is not lost (§5.4, and `…_reject_two_preds.ll` is the decline fixture) — and a unique exit block. **Z1(c):** the exit must **not** be able to reach the header (`isPotentiallyReachable`). | §4.1 derives `f` for *this* control shape. Any other shape has a different closed form or none. **Z1(c) is the Inc-3 over-accept fix:** `getParentLoop()` is a *LoopInfo* property and LoopInfo models only **natural** loops, so an **irreducible** cycle around the header is invisible to it — a shift loop inside one was CLAIMED, putting the emitted gates inside a cycle. See `…_reject_irreducible_cycle.ll`. |
| **Z2** | The header carries **exactly two** phis: a *shift recurrence* and a *counter*, each with exactly two incomings (preheader, latch). No other phi anywhere in the loop. | A third loop-carried value is a value we have no closed form for. |
| **Z3** | The shift recurrence's latch value is `shl <recurrence>, 1` — opcode exactly `Shl`, amount a `ConstantInt` exactly `1`. **`ashr`, `lshr`, non-constant amounts and amounts ≠ 1 all decline.** | `ashr` never terminates toward the sign bit. Stride ≠ 1 has a *different* closed form, and 19v3 measured SCEV reporting 32 for strides 1/2/16/31 whose true maxima are 31/16/2/1 — a naive recognizer is wrong in both directions. |
| **Z4** | The counter's latch value is `add <counter>, -1` — a `ConstantInt` exactly `-1`. The counter's preheader incoming is a `ConstantInt` `C0`. | Any other step is a different closed form (`C0 ± k·f`). See §5.2 for why this narrowness is scope and not evasion. |
| **Z5** | The exiting condition is `icmp sgt <the recurrence's own latch value>, 0`. **The compared operand must BE that value** — not a value derived from it — and the constant must be `0` and the predicate exactly `sgt`. Both branch polarities are accepted by normalising the *continue* condition (Rule 9: `-O1` inverts). | **This is the fence that excludes the f80 family (§5.3), and it is also what guarantees termination.** A value repeatedly shifted left marches monotonically into the sign bit; a value *derived* from it has no such property. |
| **Z6** | The loop contains **nothing else**: the two phis, the `shl`, the `add`, the `icmp`, the `br`. No calls, no memory access, no `alloca`/`gep`, no other instruction, no metadata-bearing side effect. | Far stricter than "no side effects", and it is exactly the measured shape. Relaxation is a later widening with its own review. |
| **Z7** | Exactly one value escapes the loop, and it is the **counter's latch value**. The shift recurrence must have **no** out-of-loop user. | An escaping shift register would owe a second closed form (`v << f`). Deferred, not silently dropped. |
| **Z8** | The shift recurrence's **preheader incoming is TAINTED**. | Quantum relevance, mirroring `LoopUnrollPrepass`'s U7. A purely classical loop is not ours to churn. ⚠ **Inc-3 correction:** this cell used to add "and this is what keeps all 253 existing ctest entries byte-stable" — measured a **misattribution**. Z8 declines exactly **one** loop in the whole tree (`…_skip_classical.ll`, added by this branch); byte-stability is delivered 100 % by the structural fence Z1–Z7/Z9 and 0 % by Z8. It first carries load when §5.2's Z3/Z6/Z9 widenings land. |
| **Z9** | The recurrence type is an integer of width in the shipped `ctlz` set **{i8, i16, i32, i64}**. `i1`, `i80`, `i128`, vectors and non-integers decline. | The mask needs a power-of-two width and a generated `ctlz` template at that width. |

**Letter choice:** `Z` because every neighbouring letter is taken — `E1–E15` (the
`LoopLowering` fence), `U1–U8` (`LoopUnrollPrepass`), `L1–L4`/`Q1`/`X1` (`tryCaseA`),
`B1/B2` (`tryBreak`), `D1–D7` (eq-fold), `G0–G11` (switch), `C1–C5` (19v3's bound
conditions). Do not reuse `C`.

### 5.0b ⚠ Poison flags are IGNORED — added by Inc 3 (bd `ww4c.4`)

`Z3`/`Z4` test opcode and operands and **never** inspect `nsw`/`nuw`, so every flag
combination is inside the accept set (measured, 6/6 cells claim). That is not hypothetical:
the **real** openlibm `-O1` IR carries `add nsw i32 %16, -1` and `shl nuw i32 %17, 1` on
*both* `ilogb` recurrences, so **the two shipped cells are flagged loops**.

Accepting them is **sound, and in the safe direction**. `shl nuw X, 1` is poison whenever
`X`'s top bit is set, so a flagged source loop entered with such a value is immediate UB
(poison compare → `br i1 poison`); the substituted chain carries **no** flags (§4.5 rule 2)
and is **total**. Replacing UB with a defined value is **refinement** — we only ever remove
undefined behaviour, never introduce it.

**The qualifier this puts on §4.2, so the headline evidence is not mis-quoted:** *"exact on
the whole domain, 0 mismatches over 2³²"* is a statement about the **unflagged** loop, which
is what the oracle modelled (wrapping semantics). On a **flagged** loop the original has no
defined value on the poison inputs at all, so agreement there is **refinement, not
value-equality**. Correctness is unaffected in the direction that matters; what would be
wrong is to read the sweep as proving the *source* loop computes that value on all 2³²
inputs — it does not, it is UB on some of them and we define them.

### 5.1 Two independent grounds, on purpose

`ilogbl`/`logbl` fail **Z5** *and* **Z4**. `ashr` fails **Z3** *and* (in every real spelling)
**Z5**. Defence in depth is deliberate: the loop campaign is **3-for-3** at finding
over-accepts in adversarial rounds, one of them **after** the epic had been cleared, and
single-fence designs are what that record is made of.

### 5.2 What is deliberately narrow, and why it is scope rather than a punt

`Z3` (stride ≠ 1), `Z4` (step ≠ −1, including the mirror `+1`), `Z6` (any body instruction),
`Z7` (escaping shift register) and `Z9` (`i128`/`i80`) are all **additive widenings**, each
mechanical, each owed a decline fixture **now** and a ticket. They are narrow because a first
landing with a small review surface is worth more than coverage nobody asked for — **not**
because the lowering is hard. Rule 17's test is whether a decline is being substituted for
work we set out to do: the three target loops sit **inside** the accept set, so it is not.
If a future census cell needs one of these, widen it deliberately with its own Rule-12/13
round.

### 5.3 The f80 mask-shift — measured, and why it must decline

`ilogbl` at `-O1` (this is the real IR, not a paraphrase):

```llvm
19:                                               ; preds = %17, %19
  %20 = phi i32 [ %22, %19 ], [ 32, %17 ]         ; counter — INCREMENTS
  %21 = phi i64 [ %23, %19 ], [ 2147483648, %17 ] ; the MASK is the induction variable
  %22 = add nuw nsw i32 %20, 1
  %23 = lshr i64 %21, 1
  %24 = and i64 %23, %8                           ; compared operand is DERIVED
  %25 = icmp eq i64 %24, 0
  br i1 %25, label %19, label %33, !llvm.loop !9
```

| | accepted (`ilogb`/`ilogbf`) | declined (`ilogbl`/`logbl`) | fence |
|---|---|---|---|
| shift | `shl <rec>, 1` | `lshr <mask>, 1` | Z3 (direction) |
| what is shifted | the **data** | a **mask**; the data is loop-invariant | Z5 |
| compared operand | the recurrence **itself** | `and <recurrence>, <invariant data>` | **Z5** |
| predicate | `sgt … 0` | `eq … 0` | Z5 |
| counter | `add …, -1` | `add …, 1` | **Z4** |
| terminates on every input | **yes** — max 31, measured (§4.2) | **no** — diverges when the tested word is 0 | — |

Their safety **today is an accident** (bd `ywws`): SCEV reports `CouldNotCompute`, so no
unsound bound can be built from them. The only bound that exists is conditional on a
**tainted** guard that PredMux demonstrably removes. `SCOPING-L3-…md` §6 item 1 proposes
exactly a "shift-until-normalized" recognizer, and bd `k02s` records that as its blocking
precondition. **A recognizer that claims these loops is a silent miscompile**, and Z4/Z5
are why this one does not.

### 5.4 The pre-shift is an ACCEPT-invariance item, not a decline

`s_ilogb.c:42` and `s_ilogbf.c:35` pre-shift in the preheader (`shl %6, 11`, `shl %3, 8`);
`s_ilogb.c:40` does not. Because it is **outside the loop**, the fence never sees it: the
recognizer takes the recurrence's preheader incoming as an opaque `Value` and **must not look
through it**. Both spellings accept and must be pinned by a positive fixture pair. The real
hazard here is the opposite of a decline — an implementation that tried to *fold* the
pre-shift into the closed form would get the constant wrong. If the owner intended a decline
here instead, this is the one item in the brief this PRD reads differently, and it is flagged
in §12.

### 5.5 No new diagnostic — the decline surface is unchanged

Following `LoopUnrollPrepass`'s discipline exactly: **accept-only**. A loop that fails any
Z-condition is left **byte-untouched** and keeps its existing loud owner — for all these
shapes, `tryCaseA`'s **Q1** at `LoopLowering.cpp:1161`,
`diagnoseUnderControl(TE, "loop")` → `cq controlled lowering: loop under quantum control`
(`ControlDetect.cpp:53`). The recognizer **never diagnoses**, so it cannot turn an accept
into a decline, and Rule 12's negative fixtures assert **the existing message that owns the
shape**, character-for-character.

> ⚠ **Inc-3 correction.** This paragraph used to say the negatives assert *that* message —
> Q1's — which is false for two of them, and the exceptions are the interesting ones:
> `…_reject_multi_exit.ll` asserts `cq loop lowering: multiple early-break sites` (a
> different loop owner claims it first), and `…_guarded_no_preshift.ll` asserts
> `cq controlled lowering: control flow under quantum control` **after** the ctlz claim
> succeeds — it is the one shipped fixture where the recognizer *does* claim and a
> **different** owner then declines. Both are still loud, still character-for-character,
> and still correct; what was wrong was the claim that Q1 is the universal owner.

**Read this the right way, because it is the whole risk profile:** the failure mode of this
pass is not a wrong decline. It is a **wrong claim**.

---

## 6. Why this is not bd `k02s` — the claim to attack first

bd `k02s` says a "shift-until-normalized" recognizer would recover a **guard-conditional**
bound, and that this is the R1 class `QramLowering.cpp:703-708` exists to prevent: *"the
SPECULATED read runs on every basis state, so in-bounds must hold UNCONDITIONALLY … not
merely on the originally-guarded path."* PredMux removes every guard (measured: `br i1` 5→0
and 4→0, `switch` 1→0), so a fact that holds only on the guarded path is a fact the lowering
speculates away.

**This PRD's design does not rely on any guard, at any point.** §4.1's closed form is exact
on the **whole** domain of the bare do-while — that is precisely why §3.2's discovery (two of
three loops are unguarded) drove the choice of closed form, and why §4.2 swept all 2³² rather
than the guard-admitted subset. There is no reachability premise to be speculated away:

* **Definedness, unconditional.** `ctlz(x, false)`, `shl x, 1`, `and`, `sub` with no poison
  flags are total on the entire type domain — no poison, no UB, no side effect, **fixed gate
  count**. This is item 2's reachability obligation discharged *structurally* rather than by
  proving reachability.
* **Value equality, unconditional.** §4.1/§4.2 — 0 mismatches over 2³², not 0 mismatches over
  the reachable inputs.

**The distinction worth carrying** (and the sentence a reviewer should try hardest to break):
a **value** that is only correct on the reachable domain could in principle be argued safe,
because the flattener preserves the path predicate that selects it — but a **trip bound**
that only holds on the reachable domain never can, because the number of gates emitted is not
a per-basis-state quantity and no `select` can discard a circuit that was never finite.
`ww4c` substitutes a value with a **fixed** gate count; `SCOPING-L3` §6 item 1 and `m57l`
substitute a *structure* whose size depends on a bound. That is why `k02s` binds them and not
this — **and this PRD does not lean on that argument anyway**, because it takes the stronger
whole-domain position. If the Rule-13 round breaks the distinction, this design is unaffected;
if it breaks *whole-domain equality*, the design is dead.

**`k02s` stays open** and should be updated — not closed — when this lands: `ww4c` is the
first concrete recognizer to carry item 2's obligation, and it discharges it by construction
rather than by a reachability proof.

---

## 7. What could still make this wrong

Listed so the Rule-13 round has targets rather than a mandate.

1. **A Z-condition is checkable but not sufficient.** The 3-for-3 record says assume this.
2. **`-O1` polarity or shape drift** (Rule 9) — a spelling where the continue-condition
   normalisation in Z5 admits a loop whose exit test is not what it looks like.
3. **The escaping-value analysis (Z7) misses a user** — an LCSSA phi, a debug intrinsic
   operand, a use inside a nested region — and the RAUW leaves something behind.
4. **Fan-out on the entry value.** `%5` in `ilogb.f64` also feeds `%9 = or i32 %6, %5`. Rule 8
   bails whole-chain reversal on >1 forward consumer of a non-terminal handle. This is the
   whole-DAG spine's business and pre-exists this change, but Increment 2 must show
   **strict** free-pairing on the real cells, not `--allow-unproven`.
5. **The enclosing diamonds might not flatten** once the loops are gone. 19v3's static-K peels
   of these exact cells reached `opt` exit 0 with an empty blocker stack, which is strong —
   but that was the *peeled* module, not this rewrite's output.
6. **A width where the mask reasoning fails.** Guarded by Z9; the i64 row is proof-plus-
   spot-check, not exhaustive (§4.2).
7. **Dead-code deletion order** — memory [`dce-under-block-iterator-loopphi-uaf`] and
   [`orphaned-emitted-gates-three-producers-2026-08-17`]: a replaced node that is not tracked
   becomes a forward gate nobody uncomputes.

---

## 8. Placement and architecture

**New files:** `ir-pass/src/CtlzIdiomPrepass.cpp` + `ir-pass/include/CtlzIdiomPrepass.h`,
registered in `ir-pass/CMakeLists.txt` beside `src/LoopUnrollPrepass.cpp` (line 68). Modelled
on `LoopUnrollPrepass` *deliberately* (Rule 14 — reuse the discipline, not the transform):
same accept-only contract, same fence-in-a-header documentation, same
`DominatorTree`/`LoopInfo` direct-construction idiom, same one-claim-per-call driver.

**Signature and driver**, mirroring `unrollConstTripLoops`:

```cpp
// Rewrites AT MOST ONE fence-passing loop per call; returns true iff it mutated
// the module. `taint` is STALE after a true return (the claim mints new tainted
// SSA and erases the loop's) until the caller re-propagates.
bool recognizeCtlzIdiomLoops(llvm::Module &M, TaintSet &taint);
```

**Slot in `CQLoweringPass::run`** — immediately after the `unrollConstTripLoops` fixpoint
(`CQLoweringPass.cpp:216-220`) and before `detectSpecializations`:

```cpp
while (recognizeCtlzIdiomLoops(M, taint)) {
  taint = propagate(M, wd);
  while (flattenPredMuxRegions(M, taint))
    taint = propagate(M, wd);
}
```

The rationale is `LoopUnrollPrepass`'s, one item at a time:

* **After the `promoteFp80Union` + PredMux fixpoints** — Z8 must read taint that has
  **settled through those two fixpoints**. ⚠ *Inc-3 correction: NOT "the same settled taint
  the rest of the pipeline reads" — measured false. Z8 reads a **strictly smaller** set than
  `lowerLoops`/`tryCaseA`, because **argument** taint is minted later by
  `detectSpecializations`, which runs after this fixpoint and never re-triggers it. The
  measured consequence is a real accept-set boundary: an idiom loop hosted in a **callee**,
  reached only through a tainted call argument, is **never claimed** — it declines loudly
  with `cq specialization: callee contains tainted control flow under quantum lift`.*
* **Before `detectSpecializations`** — the spec-scan and any later clone must see the
  rewritten body.
* **Before `lowerLoops`** — a claimed loop is gone before Q1 would decline it.
* **A fixpoint with a full re-propagate, and a nested PredMux fixpoint** — the claim mints
  tainted SSA (§4.6), and the enclosing region was **cyclic** (PredMux never claims a region
  containing a loop) and becomes claimable the moment the loop is gone. This is exactly the
  sequencing that makes the guard disappear *after* the rewrite, which is why §4/§6 refuse to
  depend on it.
* **Disjointness from `lowerLoops`' rolled-in-place claims is structural, not positional:**
  Case A needs a tainted header phi peeling through in-place gates to itself, which Z6
  forbids (no `cq_*` call in the loop); Case B needs an in-loop `cq_theta` mint, same
  fence; `tryBreak`/Q1 need a tainted exiting condition — which these loops *have*, and
  which is exactly why Z1–Z9 must be airtight rather than merely disjoint. **This pass and
  Q1 are competing for the same loops.** That is the one place the `LoopUnrollPrepass`
  analogy does **not** hold, and it must be said out loud in the header.

---

## 9. Increments

Each is independently committable and independently green. **Increment 0 ships first,
deliberately** — the memo's §3.2(c) staging: land the recognizer on proven ground rather
than on two unknowns at once.

### Increment 0 — the `ctlz` link proof (bd: new child of `ww4c`)

`cq_template_ctlz_i32` has **never appeared in a linked e2e golden** (zero hits across
`tests/e2e`; `ctpop` has two, `bswap` one). It is proven at the IR layer
(`ir-pass/test/lowering_intrinsic_ctlz_i32.ll`) and in the archive (§4.4) — and **unproven at
the only layer that links**.

* **Deliverable:** `tests/e2e/slice_intrinsic_ctlz.c` + `.expected.log`, registered in
  `tests/e2e/CMakeLists.txt` exactly like `e2e-slice-intrinsic-ctpop` (line 1864).
* **Shape:** copy `slice_intrinsic_ctpop.c`'s two-lineage structure verbatim — (A) a
  **measured** `__builtin_clz`-derived `ctlz` proving the forward producer; (B) a **dead**
  one kept alive by a `cq_phi`, proving the void `_unc` twin and the Class-2
  recompute-from-live-source discipline (source uncomputed and freed only **after** its own
  `_unc`).
* **Note in the slice header:** `__builtin_clz(0)` is UB in C and clang emits
  `i1 true`; the slice must either feed a provably non-zero value or use
  `__builtin_clzg`/an explicit intrinsic spelling so the fixture pins the **`false`** form
  this PRD depends on. Pin both if they differ — that difference is §4.5(1) in miniature.
* **Done:** `ctest -R '^e2e-slice-intrinsic-ctlz$'` green (~1.7s); free-pairing **strict**.
* **Cost:** ~1 hour. It is owed under Rule 16 regardless.

### Increment 1 — the recognizer

* `CtlzIdiomPrepass.{h,cpp}` with the Z1–Z9 fence and the §4.6 mutation.
* Wired into `CQLoweringPass.cpp` at the §8 slot; `ir-pass/CMakeLists.txt` updated.
* Full §10 lit matrix, **red-green per predicate** (Rule 12: write the fixture, watch it
  fail, implement minimally).
* **Done:** `ctest -R ir-pass-lit` green; every existing fixture byte-stable. ⚠ *Inc-3
  correction: not "Z8 is what guarantees this" — measured, Z8 declines exactly ONE loop in
  the tree and it is a fixture this branch added. Byte-stability comes from the structural
  fence Z1–Z7/Z9; nothing pre-existing has this shape at all.*

### Increment 2 — the two cells

* `tests/e2e/slice_libm_real_ilogb.c` + `slice_libm_real_ilogbf.c` + goldens, vendored per
  memory [`libm-real-slice-recipe`] and styled on `slice_libm_real_logb.c` (mechanical edits
  only; `EXTRACT_WORDS`/`GET_FLOAT_WORD` expanded to the `__builtin_memcpy` idiom).
* **Free-pairing STRICT** — no `--allow-unproven`. If it cannot be strict, that is a finding,
  not a flag to pass.
* Census re-measure to confirm **98 → 100** and update the SCOPE table in
  `tools/library_coverage/.../full_census.py` (the corpora are present:
  `/private/tmp/openlibm`, `/private/tmp/bc`; fingerprint 409 must be re-confirmed before
  quoting a number).
* **Done:** both slices green; census numerator moves; `ROADMAP.md`/campaign row updated.

### Increment 3 — the Rule-13 adversarial round, **budgeted here, not hoped for**

The loop campaign is **3-for-3** at finding over-accepts, including **three found in a round
that ran AFTER the epic was closed as "Rule-13 cleared"**. Assume this shape hides them too.

Independent reviewer(s), analytic/trace reasoning only (no simulation — owner decision
2026-06-10), given these **named claims to refute**, in priority order:

1. **Whole-domain equality (§4.1/§4.2)** — the closed form, the proof, and the sweep's
   oracle. Break this and the design is dead.
2. **Z5 is sufficient for termination and excludes every mask-shift spelling** (§5.3).
3. **The §6 value-vs-bound distinction** — the `k02s` argument.
4. **§4.6 leaves no orphan** — every use of the erased values is rewritten; the exit phi and
   its predecessors are valid; nothing is deleted under an iterator.
5. **§4.5(1)** — the emitted immarg really is `false` at every site, and PredMux really does
   flatten the enclosing diamond afterwards.
6. **Z8 keeps the suite byte-stable** — no classical loop anywhere in the corpus is claimed.

Produce a written clearance in `docs/prd/phase-07-expressiveness/`, in the style of
`WI7_SWITCH_CLEARANCE.md` / `FP_SELECT_CLEARANCE.md`.

---

## 10. Test matrix (Rule 12 — red-green, every predicate)

> ⚠ **AMENDED BY INCREMENT 3 (bd `ww4c.4`).** As written this section set a requirement no
> fixture could meet and mis-filed one entry, and both were caught only when Inc 3 tried to
> discharge it:
>
> 1. **"each must show … `i1 false`" was unsatisfiable at the layer these fixtures check.**
>    A positive fixture FileChecks the pass's *stdout*, which is the fully lowered module —
>    and Rule 15's width-only ABI has already dropped the immarg by then
>    (`cq_template_ctlz_i32(i32 %h)` carries no flag). The requirement is now **met by a
>    different mechanism**: `env CQ_SPEC_DBG=1 … 2> %t.spec.ll` captures the
>    pre-`detectSpecializations` module on **stderr**, where the `@llvm.ctlz` call is still
>    intact, and an `IMMARG` check prefix pins `i1 false` there. Stdout is byte-identical
>    with the env var set (measured), so this costs **no extra `opt` spawn** and does not
>    disturb the existing `CHECK`/`CLEAN` prefixes. Shipped in
>    `…_{unguarded_preshift,both_loops,chained}.ll`, mutant-validated against `i1 true`.
> 2. **`…_guarded_no_preshift.ll` is listed below as a POSITIVE and it is not one.** It
>    ships as a `not` fixture: the recognizer *does* claim the loop (the fixture asserts the
>    `CQ_CTLZ_DBG` line), and PredMux then declines the isolated 2-incoming
>    const-fallthrough diamond via its W7 clause (e), so the module exits non-zero. It is
>    the ACCEPT-then-different-owner-declines case, which is a category this table lacked.
> 3. **Wildcards are not enough.** Every positive originally asserted the chain with
>    `%{{…}}` operands, which pins symbols and literals but **not dataflow** — three genuine
>    miscompiles of `c_exit` passed, including one that breaks the design at exactly `v == 0`
>    (the mask drop), plus a `both_loops` variant that swaps which loop each constant
>    terminates. All positives now use FileCheck **captures**, mutant-validated.

**Positive lit fixtures** (`ir-pass/test/lowering_ctlz_idiom_*.ll`) — each must show the
four-op chain **with captured operands**, the `i1 false` immarg **via the `IMMARG` stderr
prefix**, and **no** residual loop:

| fixture | pins |
|---|---|
| `…_unguarded_preshift.ll` | `ilogb.f64` loop B / `ilogbf.f32` — unconditional entry, preheader pre-shift **not** looked through (§5.4) |
| `…_guarded_no_preshift.ll` | `ilogb.f64` loop A — guard left untouched, exit phi keeps two distinct predecessors |
| `…_both_loops.ll` | both `ilogb.f64` loops in one function, mutually exclusive arms, **two** claims |
| `…_inverted_polarity.ll` | Rule 9 — the swapped-successor spelling of Z5 |
| `…_i64.ll` | **is the idiom, is not `ilogb`** — different width, exercising the type-derived mask (§1.1) |
| `…_generic_seed.ll` | **is the idiom, is not `ilogb`** — different `C0`, different function name, no libm context |

**Negative lit fixtures** — each asserts the loop is **left alone** and the *existing* Q1
message appears character-for-character (`RUN: not %cq-opt … | %filecheck`):

`…_reject_ashr.ll` (Z3) · `…_reject_shift_amount_2.ll` (Z3) · `…_reject_dynamic_shift.ll`
(Z3) · `…_reject_counter_step.ll` (Z4, the `+1` mirror) · `…_reject_counter_nonconst_init.ll`
(Z4) · **`…_reject_mask_shift_f80.ll`** (Z5 — the `ilogbl`/`logbl` shape transcribed from
§5.3's real IR; **the single most important fixture in this PRD**) ·
`…_reject_derived_compare.ll` (Z5 — compare on `and <rec>, <inv>`) ·
`…_reject_predicate_ne.ll` (Z5 — the `while (x != 0)` idiom, whose closed form is
*different*, not absent) · `…_reject_body_call.ll` (Z6) · `…_reject_body_store.ll` (Z6) ·
`…_reject_escaping_shift.ll` (Z7) · `…_reject_three_phis.ll` (Z2) ·
`…_reject_multi_exit.ll` (Z1) · `…_reject_i128.ll` (Z9) · **`…_skip_classical.ll`** (Z8 — a
classical instance of the idiom must be left **byte-identical**, and this one asserts *no*
diagnostic at all).

**Fixture economy** (measured, `CLAUDE.md`): `ir-pass-lit` is spawn-bound, not work-bound —
reuse one `%cq-opt … > %t.cqd0.ll` and point every extra `--check-prefix` at that file, and
do **not** add a standalone `-passes=verify` RUN line.

**e2e:** Increment 0's `slice_intrinsic_ctlz`, then Increment 2's two real cells. Rule 16
wants ≥1 e2e golden; this ships three.

---

## 11. Rule 19 — which gates this trips

The full `ctest -j6` is **mandatory, not a judgement call**, at these moments in this work:

* **#5 (accept/decline predicate changed)** — Increment 1 by definition.
* **#3 (harness change)** — `ir-pass/CMakeLists.txt` and `tests/e2e/CMakeLists.txt` both move.
* **#2 (pre-push / session end)** — every increment that touches code, fixtures or goldens.

Not tripped: #4 (no template regeneration — §4.4) and, strictly, #1 (the Rule-13 core list
does not name a prepass) — **but Rule 13 applies on its merits regardless**, which is what
Increment 3 is.

Inner loop between gates stays targeted: one fixture ≈ 1.5 s, one slice ≈ 1.7 s,
`ir-pass-lit` ≈ 60–105 s. Report only what was run. **This PRD is docs-only and needs no
suite run at all** (Rule 19's docs-only row).

---

## 12. Open items for the owner — none blocking

1. **§5.4, the pre-shift.** The brief lists it under "the decline partition must at minimum
   cover"; the measured IR puts it **outside** the loop, so this PRD treats it as an
   accept-invariance property with a positive fixture pair rather than a decline. If a
   decline was intended, say so and Z-conditions gain a tenth.
2. **§5.2's deliberate narrowness** (stride ≠ 1, step ≠ −1, non-empty body, escaping shift
   register, `i128`/`i80`) is scope, not evasion — flagged explicitly because Rule 17 was
   invoked in the brief and a reader should not have to infer which side of it these fall on.
3. **§4.3 changes the memo's cost basis** — 4 ops per loop instead of ~10, and the 4.4/kjd1
   select merge drops out of the design entirely. It makes the chosen lever cheaper, so it
   does not reopen the decision, but the memo should not be quoted with the old figure.

---

## 13. What this PRD does **not** establish

* **Nothing here was emitted, linked or run as a lowering.** Rule 2: a green compile would
  not be evidence anyway. The §4.2 sweep verifies **arithmetic**, not a circuit.
* **The i64 row is not exhaustively verified** (§4.2) — proof plus boundary/randomized checks.
* **"The cells reach `opt` exit 0" is a prediction, not a measurement.** It rests on 19v3's
  static-K peels of these exact cells (blocker stack empty behind the bound; `ilogb.f64`
  K=33: 9489 gates, free-pairing 2581/2581 strict; `ilogbf.f32` K=33: 4296/1161), which is
  the **peeled** module, not this rewrite's output. Increment 2 measures it.
* **No census was re-run for this PRD.** 98 → 100 is quoted from bd `19v3` / the decision
  memo, not re-derived; Increment 2 owes the re-measure at a confirmed fingerprint.
* **`SPIKE-8zj2` §3b's `ilogb.f64` peel figures (4584/34/1239) remain UNRESOLVED** and are
  not used anywhere above. Do not quote them.
* **Rule 18 condition (i) is unmeasurable for this family** — `/private/tmp/Bennett.jl` does
  not exist. Nothing here depends on it; the ruling in §1 is the licence, not Bennett parity.
