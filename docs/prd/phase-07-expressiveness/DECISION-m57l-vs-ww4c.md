# DECISION MEMO — bd `m57l` vs bd `ww4c`, on the 19v3 measurements

**Date:** 2026-08-21 · **For:** owner · **Type:** decision writeup — **no pass change, no
fixture, no ruling** · **Unblocked by:** bd `eyhj` (closed 2026-08-21).
**Inputs, none of them re-derived here:** bd `19v3`
(`SPIKE-19v3-loop-bound-population.md`), bd `8zj2`
(`SPIKE-8zj2-ilogb-logb-loop-bounds.md`), bd memory
[`narrowed-quantum-trip-rule-2026-08-21`].

> ## RECOMMENDATION: **`ww4c`** — but decide its one non-technical question first, and buy the cheap gate before the recognizer.
>
> The two options reach **the same two cells**. That is now measured, not assumed, so
> this is **purely** a cost/risk comparison and the tie-breaker is what you own
> afterwards. `m57l` costs four measured rail problems — one with **no precedent
> anywhere in the tree** — for a capability bd `19v3` measured to have **no second
> customer**. `ww4c` costs one prepass recognizer over shipped machinery and **zero new
> frozen symbols**, and it does not need the ruling you just made.
>
> **`ww4c` is cheaper by a wide margin and its risks are nameable and bounded. But it
> is not the "one gate, free win" its ticket describes** — three things measured *for
> this memo* make it more expensive than filed (§3.2), and one question it raises is
> yours, not an engineer's (§3.4).
>
> **The third option — neither — is genuinely live and I would not argue against it.**
> 98 → 100 is two cells. The *other* half of the actionable set (`tgamma.f64` +
> `tgammaf.f32`) is also two cells on **one** lever, is **not** loop work, and therefore
> does not inherit the loop campaign's 3-for-3 over-accept record (§4).

---

## 1. The tie: both reach exactly the same 2 cells

`ilogb.f64` and `ilogbf.f32`. **98 → 100.** Measured over the whole census by bd `19v3`,
not inferred from one family:

| | |
|---|---|
| census cells probed | 125 |
| carry ≥1 loop at the module the pass reaches | 19 (17 in a function `lowerLoops` would examine) |
| decline with a **loop as first blocker** | 13 |
| hit **Q1** specifically — the gate `m57l` lifts | **10** |
| first-block on a loop with a **usable bound** | **5** |
| …with **nothing further behind it** | **2** ← the whole payoff |

The three near-misses are near-misses for a measured reason, not a fixable one:
`fmod.f64`, `remainder.f64` and `remquo.f64` *do* first-block on a 33-bounded loop, but
their blocker stack is **exactly four loops deep** and the back two are vacuous
(constant-max `-2`) or `CouldNotCompute`. And `fmodf.f32` / `fmodl.f80` /
`remainderf.f32` never reach Q1 at all — they die one gate earlier at
`kMsgBreakMultiSite`, which is the 7.4 multi-break widening under `8h7d`, a different
ticket.

**So neither option has a coverage argument over the other, and neither has a hidden
upside.** Anything that follows is cost and risk.

---

## 2. `m57l` — four rail problems, all measured present

The ticket's own instinct ("budget for the flag lifecycle being the hard part, not the
bound derivation") is **correct and understated**. The bound derivation — the part it
budgeted least for — is **done**: SCEV already answers for both in-scope cells, and bd
`19v3` closed the totality leg nobody had run (exhaustive over all 2³² starts on the
rotated recurrence: max 31 trips, `count(trips > 33) = 0`, stable under poison-flag
stripping). Everything expensive is downstream of that.

**(1) The still-running flag.** It must be computed **each iteration** from the
loop-carried quantum state, control the body, and then be uncomputed — and it is
**entangled with the rail**. 7.3 Case A works precisely because the rail is a persistent
accumulator touched only by in-place gates, with no in-body free and no uncompute. This
shape has none of that. Rule 6 then forces an explicit answer at loop exit: the flag
rails are entangled, so either they uncompute cleanly inside the body (Case-B style) or
they leak — and a leak is acceptable in the qubits-not-scarce regime **only if
deliberate and recorded**, never incidental.

**(2) The counter-lift across a back edge — no precedent in the tree.** In every one of
the nine candidate loops **exactly one value escapes, and it is CLASSICAL in every one**:
`add nsw <header-phi>, -1` seeded from a literal, with no `@cq_theta` in its cone. Zero
tainted values escape. *The trip count **is** the answer* — a classical integer whose
identity is entangled with the input, because its quantum-ness is created by **control
flow**, and Rule 3 defines taint as **data** flow. So the counter must be **lifted into a
rail**, its increment becoming a controlled add on the still-running flag. That is the
same class as PredMux and the 6.5 classical-call arm — a classical value lifted because
control is quantum — **except across a back edge, which nothing in the tree does today.**

**(3) The X1 cross-iteration dirty rail.** Confirmed on **all nine** candidate loops: each
has exactly one tainted header phi whose latch incoming is `shl nuw i32 <phi>, 1`, and
`shl` is deliberately excluded from `inPlaceValueRailOperand` as information-losing — so
the base is tainted and the shape satisfies neither L4(a) nor L4(b). That is
`kMsgCrossIter` exactly. It does not fire **today** only because Q1 runs first; **it is
what these loops hit the moment `m57l` lifts Q1.** The verdict is discriminating rather
than blanket — the *non*-candidate loops in the same `fmod` family *do* contain L4(a)-clean
self-cycle phis — which is a point in favour of the analysis, not a mitigation.

**(4) NEW from 19v3 — B has no IR counterpart, so the emitter reuses nothing.** In all
nine loops the sole exiting terminator is **entirely tainted**: there is **no classical
bound disjunct anywhere in the CFG**. `B = 33` is a SCEV bit-width inference with no
instruction behind it. `tryBreak`'s whole partition presumes a classical bound exists in
the exit condition to fall through to, so `m57l`'s emitter can reuse **none** of
`decomposeFusedExit` / `boundComparesInductionToInvariant` /
`hasFiniteClassicalTripBound` — it must **synthesize the counter, the bound and the
exit**. This is the blocker the ticket did not name at all, and it is arguably ahead of
the flag lifecycle it did anticipate.

**And the correction that makes the fence position worse, not better.** `m57l`'s own
2026-08-20 note said the rejecting fence is `tryBreak`'s **(B2)** because there is no
tainted merge phi in the exit block. **Measured-false on the real cells:** the exit block
*does* carry a tainted merge phi and **(B2) would PASS in all five candidates** —
`ilogb.f64`'s `%33` is tainted via a **non-loop** incoming (the normal `-exponent` path),
while the loop's own incoming on that same phi is the classical counter. The fence that
actually rejects is **(B1)**, `decomposeFusedExit`. The note's *conclusion* survives
(relaxing (B2) is not the fix) but its *reason* does not — and the consequence is a live
hazard: **(B1) is the only fence standing between these cells and a wrong break
lowering**, and if it is relaxed `emitBreakForward` is not "handed nothing to copy", it is
handed **a phi the taint set marks TAINTED whose live value on the loop-exit path is the
classical counter**. *The taint bit on that phi is a union over paths, not a property of
the loop's answer.* That is an over-accept shape and it needs its own negative fixture.

**The record to price this against.** `LoopLowering.cpp`'s shipped fence is **E1–E15**,
grown by **13 recorded over-accept holes across three adversarial Rule-13 rounds** — and
**three of those were found in a round that ran AFTER the epic had been closed as
"Rule-13 cleared"**. That 3-for-3 hit rate, including one round post-clearance, is the
load-bearing fact for any further loop work: assume this loop shape hides over-accepts
too, and budget the adversarial rounds up front. `m57l` also trips **two** of Rule 19's
five mandatory full-suite gate moments (a Rule-13 core commit *and* a changed
accept/decline predicate).

> **One caveat on the done-criteria, so it is not mis-quoted as progress already banked.**
> bd `19v3`'s static-K peels show these two cells' blocker stack is empty behind the bound
> and their peeled lowering is strict free-pairing clean (`ilogb.f64` K=33: 9489 gates,
> 2581/2581; `ilogbf.f32` K=33: 4296 gates, 1161/1161). **That is the UNROLLED form.**
> `m57l` emits the loop **rolled**, which is a different circuit — none of those
> free-pairing results transfers, and the e2e golden per cell is still owed.
> *(Related: `SPIKE-8zj2` §3b's `ilogb.f64` peel figures — 4584/34/1239 — did not
> reproduce under two independent instruments in 19v3 and are flagged **UNRESOLVED**. Do
> not quote them. Nothing in this memo uses them.)*

---

## 3. `ww4c` — one recognizer, but not the "one gate" its ticket describes

### 3.1 What is genuinely cheap about it, and it is a lot

* **No loop survives, so there is nothing to predicate.** No still-running flag, no flag
  lifecycle, no counter lift, no back-edge work, no `~33`-deep tainted-exit capability.
  All four of `m57l`'s rail problems are **dissolved rather than solved** — the loop is
  gone before `lowerLoops` runs.
* **Zero new frozen symbols.** `intrinsic_table.yaml:136` already ships `ctlz` at
  i8/i16/i32/i64 with `fwd` + `unc`, and `cq_template_ctlz_i32` / `_unc` are **real
  linked symbols in `libcq_templates.a`** (verified: `T _cq_template_ctlz_i32`,
  `T _cq_template_ctlz_i32_unc`). Phase 11's freeze surface is untouched.
* **The `is_zero_poison` immarg is already handled by design, and better than `ww4c`'s
  ticket assumes.** `intrinsic_table.yaml:33-38` states the policy: the trailing `i1` is
  *"a CONSTANT dropped at lowering — the lowered op is the **TOTAL** reversible function;
  both fwd and `_unc` use the same total f, so the rail zeroes correctly
  (poison-on-edge-input is a valid refinement of the source UB)"*. So `ctlz(0)` lowers to
  the honest 32, and the `QramLowering.cpp:739-747` scar **does not transfer as stated**:
  that defect was a *range bound derived from* the immarg going wrong on the zero basis
  state, not the intrinsic's own value. **This is the one place `ww4c`'s ticket is
  pessimistic rather than optimistic.**
* **It does not need bd `eyhj`'s ruling at all** for the cells it reaches, so
  `CLAUDE.md` Rule 18 can stay unamended (bd `qck7` stays parked) and no prose licenses a
  fence that has not been built.
* **It is not `lowerLoops` core.** It is a prepass on injected IR, the same category as
  the shipped `LoopUnrollPrepass` — a different and lower risk profile than editing the
  E1–E15 fence. *(Not zero: bd `b7ai` and bd `3hf1` are open holes in `LoopUnrollPrepass`
  itself, so prepasses in this tree also accumulate.)*

### 3.2 Three things measured **for this memo** that make it more expensive than filed

**(a) It is not one gate — it is a small graph, twice.** Measured just now with stock
`clang -O1/-O2/-O3` on LLVM's own documented idiom spelling, *unguarded*:

```llvm
%2 = icmp eq i32 %0, 0
%3 = tail call range(i32 0, 33) i32 @llvm.ctlz.i32(i32 %0, i1 true)
%4 = sub nuw nsw i32 32, %3
%5 = select i1 %2, i32 0, i32 %4
```

LLVM emits the `ctlz` **unconditionally** and repairs the zero case with a **`select`**.
The same repair is unavoidable for `ilogb`, and I measured it exhaustively rather than
reasoning about it — sweeping the rotated `s_ilogb.c:42` loop over **all 2³² start
values** with the guard removed:

```
max trips over all 2^32       : 31          <- independently reproduces 19v3's C4 figure
trips at x==0                 : 0             (ctlz(0) = 32)
mismatches vs PLAIN ctlz      : 1           <- exactly one input: x == 0
mismatches vs (x==0) ? 0 : ctlz(x) : 0
```

So `trips = ctlz(x)` holds for every input **except** `x == 0`, where the loop does zero
trips and `ctlz` says 32 — and the `hx != 0` guard that would exclude that input is
**tainted**, so PredMux removes it. **The correction is needed for exactly one basis
state, and it is precisely the basis state the guard used to hide.** So the emitted shape
is
`ctlz` + `sub` + `icmp` + a **tainted select**, and the tainted select is the 4.4/kjd1
controlled-XOR copy merge (flag mint → two `cqrt_copy_<W>_controlled` → `cqrt_x` bracket
→ compare-`_inv` strip → one `cqrt_free`). **Shipped machinery, but not free** — and
`ilogb.f64` has **two** such loops (`s_ilogb.c:40` and `:42`), so it is two recognitions
and two merges. Call it ~10 tainted ops, not 1. *(Against `m57l`'s rolled `B=33` over a
3-4-op body — the spike's estimate is ~99 tainted ops — that is still an order of
magnitude, and the honest headline is **"~10 ops instead of ~99, plus no flag
lifecycle"**, not "1 instead of 99".)*

**(b) The recognizer must emit `is_zero_poison = false`, or PredMuxFlatten will refuse
the cone.** `PredMuxFlatten.cpp:177-196` **refuses** to flatten any cone containing
`ctlz`/`cttz`/`abs` with that immarg — *"that `i1` is an **immarg** — an OPERAND, not an
annotation … every mechanism this file has for neutralising poison structurally misses
it, so the only sound handling is to REFUSE"*. And that refusal was itself found by a
Rule-13 round on a **first draft of a fix**, with a linked witness: a shielded cone over
`ctlz(0, true)` was claimed and flattened with `opt` exit 0, `opt -verify` clean and
free-pairing **STRICT 6/6**, and the trace fired a gate on *a rail index `cqrt_alloc_*`
never returned.* LLVM's canonical form emits `i1 true`. A CQ recognizer that copies it
verbatim will decline the cell it was written to unblock — recoverable (emit `false`; the
lowering is the same total function either way) but it is a trap sitting directly on the
path, and `ww4c`'s ticket does not name it.

**(c) `cq_template_ctlz_i32` has never appeared in a linked e2e golden.** It has a lit
fixture (`ir-pass/test/lowering_intrinsic_ctlz_i32.ll`) and it is in the archive, but
**zero** of the 240 e2e slices' goldens contain `ctlz` — in fact `grep -rc ctlz tests/e2e/`
is empty across the whole directory — while `ctpop` has **two**
(`slice_intrinsic_ctpop.expected.log` and the multi-TU
`specialize_intrinsic_caller.expected.log`) and `bswap` one. So the only layer that **links** has never fired this symbol. Not alarming, but
it means the "rides shipped machinery" claim is proven at the IR layer and **unproven at
the link layer**, and the fix is trivial (below).

### 3.3 What it still owes regardless

It is Rule-13 work with a Rule-12 decline fixture and an adversarial probe family. Its
accept predicate has to be exactly right, and `ww4c` already records the measured firing
rule against a 40-cell grid: SCEV's shift-compare analysis fires **iff** the shift is
`shl`/`lshr` (**never** `ashr`) by a **positive constant** and the loop-**continue**
predicate is **false at 0** — *not* the loose "compares against zero" summary, which
misclassifies in both directions. And it must fire where **stock LLVM does not**:
measured today, openlibm's `for (ix=-1022, hx<<=11; hx>0; hx<<=1)` spelling produces **no
`ctlz` at -O1, -O2 or -O3, guarded or unguarded**, while LLVM's own spelling produces one
at all three. So this is genuinely new CQ code, not a flag flip.

### 3.4 The one question that is yours, not an engineer's

**Does a loop-idiom recognizer count as *injection* coverage?** `ww4c`'s answer is that it
is a transformation on **injected IR** — the same category as the shipped
`LoopUnrollPrepass`, which already unrolls `__polevll` Horner loops in injected bodies
and whose cells count — and *not* per-function name recognition, which Rule 18 retires as
fiction. I think that argument holds, and the sharpest form of it is: **stock LLVM ships
`LoopIdiomRecognize` and fires it on a neighbouring spelling; CQ adding one is CQ doing
what the compiler it is built on already does.** Had openlibm written the idiom spelling,
these cells would compile **today** with zero CQ work and nobody would question that it
was injection coverage — the only thing between the two is how the loop is spelled.

But it does bear on what "CQ compiled openlibm's `ilogb`" means, and this campaign has a
standing rule about exactly that class of claim. **Per Rule 17 it needs your scoping
before any code** (*"a decline is not the development escape hatch, and neither is
authoring a recognizer instead of doing the ruling"* — `ww4c`'s own words).

---

## 4. The honest third option: neither

**98 → 100 is two cells** — about +1.7 points on the campaign number. Both options are
Rule-13 compiler work with full-suite gates, adversarial rounds and per-cell e2e goldens.
It is entirely reasonable to spend that budget elsewhere and leave both tickets open.

If you want the concrete alternative rather than a shrug: **the other half of the
actionable set is also two cells on ONE lever, and it is not loop work.** `tgamma.f64` +
`tgammaf.f32` both block on `large_gam { double, double } (double)` — an **aggregate-typed
fp return under quantum lift** — needing multi-value/struct-return support in the Phase-6
specializer (or SROA-ing the pair). Same payoff, one lever, and it does **not** inherit
the loop campaign's 3-for-3 over-accept record. **Caveat, stated because the census states
it about itself:** this table has **mispredicted the next layer three times running on
that gamma pair**, and `b_tgamma.c:200`'s bounded loop plus a depth-1 self-recursion sit
behind `large_gam` and are still **UNMEASURED**. So it is a candidate, not a
recommendation — and if you want it ranked properly it needs the same treatment `19v3`
just gave the loop axis.

---

## 5. Recommendation, staged

1. **Answer §3.4** — the injection-coverage question. If the answer is "a recognizer does
   not count", `ww4c` is dead as a *coverage* lever and the choice collapses to `m57l`
   vs neither. **Do this first; it is free and it can kill the option.**
2. **Buy the cheap gate before the recognizer** — author `tests/e2e/slice_intrinsic_ctlz.c`
   + golden, registered like the existing `ctpop`/`bswap` slices. **~1 hour, one 1.7s
   ctest entry**, and it retires §3.2(c) by proving `cq_template_ctlz_i32` links and
   traces. `ww4c` owes an e2e golden anyway under Rule 16; doing it first means the
   recognizer lands on proven ground instead of two unknowns at once.
3. **Then build `ww4c`**, with §3.2(a) and §3.2(b) written into its PRD up front — it is
   `ctlz` + `sub` + `icmp` + a tainted-select merge, twice for `ilogb.f64`, and the
   immarg must be `false`. Rule 12 red-green on the firing rule from §3.3; Rule 13 round
   budgeted, not hoped for.
4. **Leave `m57l` open and deferred**, with this memo's §2 attached. Do **not** close it:
   it is the only design on record for a quantum-bounded loop, bd `eyhj`'s ruling stands
   behind it, and if a future family ever needs it the four rail problems are already
   enumerated. It simply has **no customer today** — measured.
5. **Leave bd `qck7` (the Rule 18 amendment) parked** while `ww4c` is the chosen path.
   Amending Rule 18's prose before the `LoopLowering` fence exists licenses a lowering the
   compiler cannot safely emit, and `ww4c` does not need the amendment.

**If you overrule toward `m57l`**, the single most important thing is not the flag: it is
§2(4). Budget the emitter for **synthesizing** the counter, the bound and the exit from
nothing, and treat "reuse `tryBreak`'s bound machinery" as measured-unavailable rather
than a starting point.

---

## 6. What this memo does not establish

* **Nothing here was emitted, linked or run as a lowering** of either design. Per Rule 2
  a green compile would not be evidence anyway.
* **The effort figures are structural, not estimated in hours.** "~10 ops vs ~99 ops" is
  a gate count, not a schedule; the `~99` is bd `8zj2`'s arithmetic (3-4-op body × 33),
  not a measurement of an emitted circuit.
* **Rule 18 condition (i) is unmeasurable for this family.** `/private/tmp/Bennett.jl`
  **does not exist** (not merely empty), so no Bennett-parity check on either option is
  possible until it is restored. Do not guess it; nothing above depends on it.
* **The `tgamma` alternative in §4 is unranked.** Its depth behind `large_gam` is
  UNMEASURED and the census has mispredicted that cell's next layer three times.
* **Everything is at `CENSUS_OPTLEVEL=O1`**, the ship floor. The loop population is
  opt-level dependent by construction.
