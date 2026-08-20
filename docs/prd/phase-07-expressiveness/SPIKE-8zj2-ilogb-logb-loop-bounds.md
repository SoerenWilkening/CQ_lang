# SPIKE 8zj2 — does the quantum-INDEPENDENT loop-bound claim transfer to the ilogb/logbl family?

**Date:** 2026-08-20 · **Type:** measurement spike, **no pass change, no fixture, no
ruling** · **Tracker:** bd `8zj2`; feeds the gate ticket bd `eyhj`.
**Companion memo:** `SCOPING-L3-data-dependent-trip-loops.md` (the 2026-07-27 memo
whose load-bearing number this spike was filed to re-measure).

> ## VERDICT: the claim transfers to HALF the family, and the family is not one increment.
>
> **`ilogb.f64` and `ilogbf.f32` have a quantum-independent trip ceiling of 33,
> derivable today by a shipped LLVM analysis and sound over the ENTIRE input
> domain (exhaustively verified).**
> **`ilogbl.f80` and `logbl.f80` have no such bound, and this is not a heuristic
> gap — measured, their loop does not terminate at all for one input value, so no
> total bound exists to derive.**
>
> The 4 cells named in the ticket are **2 + 2**, and the split is qualitative, not
> a matter of degree. Any increment scoped as "the 4-cell ilogb/logbl family" is
> mis-scoped.
>
> **Two secondary results outrank the primary one for anyone building on this.**
> (a) The peel test the ticket prescribes — back-edge excision — is a
> **known-false-negative** probe: it reports LOWERS CLEAN even with a real blocker
> injected into the loop body, and it says CLEAN on 6 of 6 looping cells including
> two the project has already ruled permanently out (§3a). (b) There is a **cheaper
> fix than a loop capability** for the same 2 cells — these are count-leading-zeros
> idioms, CQ already lowers `llvm.ctlz`, and the identical computation in LLVM's
> idiom spelling **compiles today** (§4b).

---

## 0. What was actually re-measured, and why it needed re-measuring

The L3 memo's load-bearing number — "SCEV constant max `i32 32`, and the bound is
*quantum-independent* (an i32 width fact)" — was measured on **`fmod`'s** subnormal
loops (`e_fmod.c:54,56`). It had never been measured on the four bodies this
capability would target. Quoting it for them was an unverified transfer.

Method: real openlibm injection at the `-O1` ship floor, corpus re-cloned at
`@82e90ae` with fingerprint `409 []` (the recorded README expectation), the
committed plugin at `0d36334` **never rebuilt**, every SCEV number taken from the
LLVM 19 API rather than transcribed from printer text, and every headline claim
put through an independent adversarial refutation round.

**Population: 8 cells.** The 4 targets, plus `logb.f64` / `logbf.f32` as the
compiling controls for deliverable (4), plus `fmod.f64` / `fmodf.f32` as the L3
memo's own reference cells — because an instrument that has not reproduced the
record it is about to correct should not be trusted (§6). **All 8 statuses
reproduced `full_census_O1.json` exactly**, including every first-blocker
diagnostic character-for-character.

---

## 1. Deliverable (1) — the measurements

Query used, per loop, on the exact pre-lowering module the pass is handed:
`ScalarEvolution::getConstantMaxBackedgeTakenCount(L)` and
`getSmallConstantMaxTripCount(L)`, cross-checked against stock
`print<scalar-evolution>` / `print<loops>` by four independent agents.

| cell | loops | `for`-statement site | exit condition | constant-max BTC | **sound trip bound** |
|---|---|---|---|---|---|
| `ilogb.f64`  | 2 | `s_ilogb.c:40`, `:42` | `icmp sgt <shl>, 0` | **`i32 32`** (both) | **33** (both) |
| `ilogbf.f32` | 1 | `s_ilogbf.c:35`       | `icmp sgt <shl>, 0` | **`i32 32`**       | **33** |
| `ilogbl.f80` | 2 | `s_ilogbl.c:37`, `:41`| `icmp eq (and <lshr>, man), 0` | **CouldNotCompute** | **0 = unknown** |
| `logbl.f80`  | 2 | `s_logbl.c:36`, `:40` | `icmp eq (and <lshr>, man), 0` | **CouldNotCompute** | **0 = unknown** |
| `logb.f64`   | **0** | — | — | n/a | n/a |
| `logbf.f32`  | **0** | — | — | n/a | n/a |

The exact backedge-taken count is `CouldNotCompute` on **all** of them: the actual
trip count is quantum-dependent in every cell. That was never in dispute — it is
why they decline. The only question is whether a quantum-independent **ceiling**
is derivable, and the table answers it 2-yes / 2-no.

**A methodological risk was closed, not assumed.** The pass does not use the pass
manager's `ScalarEvolution`; `LoopLowering.cpp` / `LoopUnrollPrepass.cpp`
hand-construct one with a *default* (conservative) `TargetLibraryInfo`. Measured
both ways on all four cells: **identical answers**. The numbers above are the
numbers the pass itself would see.

### 1a. The f64/f32 bound is a BIT-WIDTH fact — established four ways, not asserted

The mechanism is **behaviourally identified as** LLVM's
`computeShiftCompareExitLimit` ("Compute the exit limit of a loop that is
controlled by a `(IV >> 1) != 0` type comparison… we can still sometimes compute
an upper bound", `ScalarEvolution.h:1860-1867`). *Behaviourally* is the honest
word: Homebrew LLVM 19.1.7 is a **non-assertions build**, so
`-debug-only=scalar-evolution` is unavailable and the routine cannot be named from
a trace on this host. The declaration exists and the fingerprint matches it
uniquely; that is all. Evidence for the bound's character:

1. **It tracks the type width.** Same loop at i8 / i16 / i32 / i64 / i128 →
   `8` / `16` / `32` / `64` / `128`, and it is *independent of the true trip
   count*: a `shl %v, 4` loop whose real worst case is 8 trips also reports 32.
2. **It survives deleting the counter entirely.** So it is not counter-derived —
   the L3 memo's §3 "P3" vacuous-bound hazard is not the mechanism here.
3. **It survives stripping every `nsw`/`nuw` flag and `mustprogress`**, and
   survives changing the counter's initial value. Not overflow reasoning: the
   counter is `{-1043,+,-1}<nsw>`, which under overflow reasoning would admit
   ~2.1 billion steps, so `32` could never have come from it. A genuinely
   counter-derived bound instead reads `i32 2147483647` with a symbolic max
   naming an SSA value.
4. **A data-dependent shift amount goes `Unpredictable`** — and selectively:
   making *one* loop's shift amount data-dependent kills that loop's bound while
   leaving the sibling loop's `32` intact, with the counter byte-identical.

**Three corrections to how this must be worded** (from the adversarial round; each
would have been a real defect in a recognizer written off the loose summary):

* **The firing rule is NOT "the loop compares the shifted value against zero."**
  Measured over a 40-cell predicate × constant grid: the analysis fires iff the
  shift is `shl` or `lshr` (**never** `ashr`) by a positive constant **AND the
  loop-CONTINUE predicate evaluates FALSE at 0**. `icmp sgt %vn, 1` and
  `icmp sgt %vn, 5` still fire; `icmp ne %vn, 5` and `icmp eq %vn, 0` do not.
* **The mechanism is not unconditionally P3-free.** When the shift amount is ≥ the
  bit width (`shl i32 %v, 32`, reproduced at five widths) SCEV *still* reports the
  width — although such a shift is **poison** in LLVM and a no-op on x86, so the
  loop runs forever in reality. That is a P3-family vacuous bound resting on
  poison. It does not touch these cells (their in-loop shift amount is the literal
  `1`; the preheader pre-shifts of 11 and 8 are in range), **but any peel bound
  grounded on this mechanism must additionally require `1 ≤ amount ≤ width-1`.**
* The `32 → 33` backedge-to-trip conversion is mandatory, not cosmetic (§2).

### 1b. The bound is a sound over-approximation — verified EXHAUSTIVELY, not sampled

The reachable input domain of each loop is a masked 32-bit word, small enough to
enumerate **completely**:

| loop | true worst-case trips | SCEV ceiling | margin |
|---|---|---|---|
| `s_ilogb.c:40` (low word, 2³¹ inputs) | **31** | 33 | 2 |
| `s_ilogb.c:42` (high word, 2²⁰ inputs) | **20** | 33 | 13 |
| `s_ilogbf.c:35` (2²³ inputs)          | **23** | 33 | 10 |

This also **confirms the census `scope_ref`'s recorded bounds** for the f64 and f32
cells (`<=31` / `<=23`) — those two numbers are exactly right. Its `<=64` for the
f80 cell is wrong: exhaustively over all 2³² mantissa words, each f80 loop runs at
most **31** trips, and the two are mutually exclusive branches. 64 appears to have
been read off the mantissa width; the closest real quantity is the *counter* `b`,
which reaches `LDBL_MANH_SIZE + 31 = 63`, not the trip count.

### 1c. Circuit cost, since the L3 memo's wall was a cost wall

Loop bodies are **3 work ops** (f64/f32: `add`, `shl`, `icmp`) or **4** (f80), plus
2 phis. A rolled B=33 lowering is ≈ 33 × 3 ≈ **99 tainted ops**. This is nowhere
near the L3 memo's f80 `fmod` K ≈ 32828 unrealizability wall, nor its compile-time
wall (15 s at K=256, unfinished at 20 min at K=1024) — which a *rolled* lowering
does not pay at all.

---

## 2. Deliverable (2) — TRAP-1 compliance, and the size of the trap here

The sound number is LLVM's own `getSmallConstantMaxTripCount` — an **unsigned**
read, **+1** for trip-vs-backedge. The unsound formula
`getSignedRange(getSymbolicMaxBackedgeTakenCount(L)).getSignedMax()` was run
**side by side** so the trap was measured rather than assumed.

**On the ilogb cells the trap only half-fires.** Signed and unsigned ranges
*coincide* at `[32,33)`, so the signedness half does not bite; only the off-by-one
half does (the formula returns `32` = a backedge count where a peel needs `33`).
`isKnownNonNegative(symbolicMax)` = yes.

**On the f80 cells the trap cannot fire at all**, and for a reason worth recording:
the symbolic max *is* `SCEVCouldNotCompute`, on which the standard SCEV operations
are invalid (`llvm_unreachable`, `ScalarEvolutionExpressions.h:704`). There is no
bound of either signedness to misread. These cells are therefore **no evidence
whatsoever about the size of TRAP-1**.

**The reachability half of the deliverable.** The ticket asked for the
`qromIndexKnownInBounds` discipline (`QramLowering.cpp:684-687`). That code states
the obligation exactly, and it transfers verbatim with "trip bound" substituted for
"in-bounds":

> *"the SPECULATED read runs on every basis state, so in-bounds must hold
> UNCONDITIONALLY … not merely on the originally-guarded path"* …
> *"A poison-conditional bound is precisely a bound that holds only on the paths
> the SOURCE executes — i.e. exactly the originally-guarded path the speculation
> removes."*

**The speculation is not hypothetical — CQ's own lowering performs it.** Measured on
the lowered output: `br i1` count **5 → 0** (`ilogb.f64`) and **4 → 0** plus
`switch` **1 → 0** (`ilogbl.f80`). Every conditional branch, including each loop's
entry guard, is tainted and is predicated away by PredMux. So a peeled or rolled
body under quantum control **does** execute on basis states the source guard
excluded. This is the QROM situation verbatim.

Applied here — and this is the spike's sharpest result:

* **`ilogb.f64` / `ilogbf.f32`: the bound is TOTAL and STRUCTURAL.** Three
  independent legs:
  - *Semantic.* Exhaustively over **all 2³²** inputs, guards ignored, the rotated
    `shl`-until-sign body terminates for **every** input, worst case 31 trips.
  - *Analytic.* Deleting loop 1's entry guard **and** replacing both preheader
    incomings with a fresh `declare i32 @opaque_i32()` — destroying all
    provenance — leaves SCEV's answer **unchanged at `i32 32`** on both loops.
  - *Structural.* `ilogbf.f32`'s loop and `ilogb.f64`'s loop 2 are entered
    **unconditionally** in the shipped IR (`br label %9` / `br label %22`). There
    is no guard to remove.
* **`ilogbl.f80` / `logbl.f80`: no total bound exists; theirs is GUARD-CONDITIONAL.**
  Exhaustively over all 2³² mantissa words with the guards speculated away, **two
  inputs never terminate**: `0` and `0x80000000`.

  > **Correction to this spike's own first pass.** That count was initially
  > reported as *one*, measured on **source** semantics. `clang -O1` **rotates**
  > these loops, so the body the pass sees does `m >>= 1` *before* the first test
  > — bit 31 of the word is never examined inside the loop; it is peeled into the
  > entry guard. In the rotated body the pass actually gets, the divergent set is
  > `{0, 0x80000000}`. The conclusion is unchanged and slightly stronger; the
  > number was wrong, and it was wrong because it was measured on the wrong form.

  The ≤31-trip bound holds only under `manl|manh ≠ 0` (`s_ilogbl.c:32`) — **a
  tainted guard**, and one PredMux demonstrably removes. Under the
  `qromIndexKnownInBounds` obligation that is precisely a bound "that holds only
  on the paths the SOURCE executes".

**The safe status of the f80 cells today is an ACCIDENT, and must be recorded as
one.** SCEV happens to report nothing, so nobody can build an unsound peel from it.
A future "shift-until-normalized" recognizer would recover exactly that
guard-conditional bound — and would be a silent miscompile unless it also
discharges reachability.

### 2a. Two follow-up measurements on the f80 half (not proposals — measurements)

**Importing the source's guard does NOT recover the bound.** Expressing both guard
facts as `llvm.assume(man != 0)` + `llvm.assume(man < 2^31)` leaves SCEV at
`Unpredictable` on all three queries. (Independently, `qromIndexKnownInBounds`
passes `AC`/`DT` as null precisely so the `llvm.assume` channel stays shut —
`QramLowering.cpp:749-754` flags re-opening it as an unreviewed widening.)

**Totalizing the loop DOES.** Adding an exit on mask exhaustion — `%still = icmp ne
%mn, 0`, `and`ed into the existing condition — makes SCEV report `constant max
backedge-taken count is i32 31`, because the mask recurrence then terminates the
loop independently of the data.

The distinction matters and should not be blurred: a bound for the f80 cells is not
*recoverable* from the IR as written, but it is *creatable* by first making the loop
total. On every guard-admitted input that rewrite is semantics-preserving; on the
divergent inputs it replaces a non-terminating (classically UB) path with a defined
answer. That is a strictly larger claim than "SCEV already proves a bound", it is a
different piece of work from anything `eyhj` currently describes, and this spike
takes no position on whether it should be done.

### 2b. TWO SOUNDNESS DEFECTS IN THIS SPIKE'S OWN INSTRUMENT — read before reusing it

Both were found by pointing the instrument at cells in its own directory, and both
fail in the **over-accept** direction. Anyone writing the recognizer will reach for
exactly these two predicates.

**(i) `isa<SCEVConstant>` is the wrong "value-independent" test.** `SpikeScev.cpp`'s
`reportLoop` prints `VERDICT bound-kind = CONSTANT (no SSA operand ⇒
value-independent)` with no magnitude and no non-negativity condition — so it
prints it for `fmod.f64`'s fix-point loop, whose constant max is **`-2` =
4294967294**. It declares a vacuous 4-billion bound value-independent. It is right
on the ilogb cells by luck. (This is the field the four cell agents reported as
`boundIsLiteralConstant: true`.)

**(ii) `getSmallConstantMaxTripCount` does NOT return 0 on a vacuous bound.** Two
agents rested on "0 means unknown, so a non-zero answer is the sound bound". On
`e_fmod.c:97` and `e_fmodf.c:78` it returns **4294967295**. So the obvious
recognizer predicate — *non-zero ⇒ we have a usable bound* — **accepts a
4-billion-trip peel**. The shipped `LoopUnrollPrepass.cpp:199-202` survives this
only because it *additionally* demands an **exact** trip count and `Trip ≤ 8`;
strip either clause and the fence opens.

**So a peel bound needs three conditions, not one:** constant *and* non-negative
*and* small — plus the reachability clause of §2 and the
`1 ≤ shift-amount ≤ width-1` clause of §1a.

---

## 3. Deliverable (3) — the answer holds; THE TICKET'S PRESCRIBED METHOD DOES NOT

**The measurement reproduces**: all four cells, after back-edge excision, give
`opt` exit 0, verify-clean, and **zero** residual
`@cq_theta`/`@cq_phi`/`@cq_measure`. Baseline declines reproduce verbatim on the
un-excised modules. Stage-2b `free_pairing_check.py` — which the ticket did not
ask for and `peel_test.sh` does not run — is **strict-clean on all four**
(23 / 9 / 45 / 45 free sites verified, 0 violations, 0 unproven).

### 3a. But back-edge excision is a KNOWN-FALSE-NEGATIVE deeper-layer probe

This is the spike's most consequential secondary finding, and it was **refuted by
construction, not by argument**. Excision deletes the loop's tainted exit branch,
which makes **100 % of each cell's tainted loop-body recurrence dead** (measured:
7 / 4 / 8 / 8 instructions — every `shl` in the f64/f32 cells, every masking
`and`/`lshr` in the f80 cells), and `cq-lowering`'s own DCE then removes it. The
excised run emits **zero** `shl` gates and never lowers the loop body at all.

The witness: **inject a real blocker (`trunc i32 → i7`) into `ilogb.f64`'s loop
body and the peel test still reports "LOWERS CLEAN. No deeper layer."** — while the
identical blocker under a genuine static-K peel declines with *"no template for
opcode 'trunc i7' in tainted context"*.

**And it returns CLEAN on every input it has ever been given.** Run over *all
eight* built cells, it reports LOWERS CLEAN on **6 of 6** looping ones — including
`fmod.f64` and `fmodf.f32`, which the project has already ruled permanently out on
Rule-18 grounds. A discriminator that never discriminates is not evidence.

**So back-edge excision must not be used as a deeper-layer probe.** It cannot see a
blocker that lives inside the loop, which is the only place a loop cell's deeper
layer could be.

**This reaches back to the 2026-07-28 `logbl` ruling**, which rested partly on
"back-edge excision makes it lower COMPLETELY … no deeper layer at all". That
sentence reproduces exactly — and it does not support the weight it was given. The
ruling may well be right; its stated evidence is weaker than it reads.

### 3b. The answer, re-established on a method that can actually see

Hand-built **genuine static-K peels** — body live, exit branches preserved:

* **all 4 cells lower clean at K=2**;
* `ilogb.f64` additionally at **K=3, 5, 9, 17 and 33** — at K=33: **4584 gates,
  34 `shl` gates, free-pairing 1239/1239**.

So the correct statement is: *"a genuine static-K peel of all 4 cells lowers clean
at K=2, and of `ilogb.f64` up to K=33, so no deeper blocker is exposed at those
bounds"* — which is both stronger than the original claim and, unlike it,
actually about the loop.

---

## 4. Deliverable (4) — the family asymmetry, and a CHEAPER FIX than a loop capability

### 4a. Why logb compiles and ilogb does not — and it is NOT a logb-vs-ilogb split

**State it as no-loop-vs-loop, never as logb-vs-ilogb.** Measured, in `@probe` and
in the source:

| body | loops | census status |
|---|---|---|
| `s_logb.c`, `s_logbf.c` | **0** | COMPILES |
| `s_ilogb.c` (2), `s_ilogbf.c` (1), `s_ilogbl.c` (2), **`s_logbl.c` (2)** | ≥1 | DECLINES |

`logbl.f80` is a **`logb` spelling on the losing side** — it inherits `ilogbl`'s
bit-scan rather than `logb`'s multiply, and its file header says why: *"From:
@(#)s_ilogb.c"*. It was written from the integer function. Any framing of this as
"logb compiles, ilogb declines" is false on a quarter of the family.

The loop-free bodies renormalise the subnormal with a single multiply, then
re-extract the exponent — `s_logb.c:39` `x *= two54`, `s_logbf.c:35` `x *= two25`,
visible in the IR as `fmul double %1, 0x4350000000000000` /
`fmul float %1, 0x4180000000000000` and surviving lowering as
`cq_template_fmul_f{64,32}_hl`.

**That the loop is the SOLE blocker is confirmed two independent ways**, neither of
them the discredited excision test of §3a: a from-scratch **loop-free `ilogb`
built from `logb`'s own 2⁵⁴ trick lowers clean** through the identical census
pipeline, and so does a `__builtin_clzll` variant (emitting
`cq_template_ctlz_i64`).

**So "algorithmic, not incidental" must be scoped.** `ilogb` does not *require* a
bit scan — openlibm *chose* one. The difference is in the **source form**, not in
the function's semantics. That is structurally the same situation as Rule 18's trig
amendment, where Bennett backs `sin` and it is openlibm's `k_rem_pio2.c` source
form that is un-injectable.

### 4b. There IS a cheaper fix, and it is not a loop capability

**All four loops are count-leading-zeros idioms**, and **CQ already lowers
`llvm.ctlz`**. Verified end-to-end, not inferred: `intrinsic_table.yaml:136` ships
`ctlz` at i8/i16/i32/i64 with `fwd` + `unc` variants; `cq_template_ctlz_i32` and its
`_unc` twin are real linked symbols in `libcq_templates.a`; and a tainted
`__builtin_clz` compiles through `cq-lowering` at exit 0, emitting
`cq_template_ctlz_i32`. **Zero new frozen symbols.**

So the loop could be replaced by an opcode CQ has already solved — converting a
*loop* problem into an *opcode* problem. Why it does not happen for free:
**LLVM's own `LoopIdiomRecognize` fires on its documented spelling and on neither
of openlibm's**, at `-O1`, `-O2`, `-O3`, and standalone. Measured end-to-end, same
`cq_theta`-derived word, same pass, differing only in source spelling:

| spelling | `llvm.ctlz` at `clang -O1` | loops reaching the pass | `cq-lowering` |
|---|---|---|---|
| `while (x != 0) { x >>= 1; i++; }` (LLVM's idiom) | **yes** | **0** | **exit 0**, emits `cq_template_ctlz_i32` |
| `for (ix=-1022, hx<<=11; hx>0; hx<<=1)` (openlibm f64/f32) | no | 1 | **exit 1**, `loop under quantum control` |
| `while (!(manh & m)) { m >>= 1; b++; }` (openlibm f80) | no | 1 | (same gate) |

Had openlibm written the first spelling, **the cell would compile today, with zero
CQ work** — and nobody would call that anything but injection coverage, because it
is stock `clang` performing a standard loop-idiom rewrite on injected source. That
disposes of the natural objection that an idiom rewrite is "not injection": LLVM
already does exactly this rewrite for a neighbouring spelling, and the result is
uncontroversial. **A CQ-side idiom recognizer is therefore a different option from
rewriting the body** (inadmissible) **and from per-function name recognition**
(retired as fiction) — it is a transformation on injected IR, the same category as
the shipped `LoopUnrollPrepass`.

A CQ-side recognizer is therefore the cheaper lever — one gate instead of ≈99, and
it *dissolves* the quantum-bounded-loop question rather than answering it, since
after the rewrite there is no loop. But it is **not free**, and two things must be
said plainly before anyone scopes it:

* It is still compiler work with full Rule-13 obligations.
* **It inherits the f80 totality problem exactly, and the tree already has the
  scar.** `ctlz`'s `is_zero_poison` immarg is the same question in a new costume.
  `QramLowering.cpp:739-747` records a *real* shipped defect of precisely this
  shape — `__builtin_ctzll` → `llvm.cttz.i64(%bits, i1 true)`, whose immarg
  tightened a range from `[0,64]` to `[0,63]`, emitted unmasked, so that **"on the
  basis state `bits == 0` (`q == +0.0`, which the Ry rail genuinely occupies) the
  true `cttz` is 64, one past the end."** And the reason it could not be caught
  downstream is Rule 15 itself: the width-only ABI **discards** the immarg, so
  `cq_template_cttz_i64` is byte-identical with or without it and *"the bound
  described a value the emitted circuit does not compute."* There is a standing
  refusal for `ctlz(0, true)` at `PredMuxFlatten.cpp:177-196` for the same reason.

  For the f64/f32 cells the operand's non-zeroness is not needed — the `shl` body
  is total (§2), so `is_zero_poison=false` is trivially discharged. For the f80
  cells the divergent inputs `{0, 0x80000000}` **are** the ones a non-total `ctlz`
  would have to exclude — the same basis states, the same rail, the same discarded
  fact. The idiom route therefore reaches the same **2 of 4** cells cleanly, and
  meets the identical totality question on the other two.

### 4c. A THIRD census-convention caveat, absent from the L3 memo

**On x86-64, openlibm does not build `src/s_logbl.c` at all.** `amd64/Make.files`
lists `s_logbl.S` — a single x87 `fxtract` — and the root `Makefile:28-33`
`DUPLICATE_NAMES` / `filter-out $(addprefix src/,$(DUPLICATE_SRCS))` drops the C
twin. The full amd64 override set is `e_remainder{,f,l}.S`, `e_sqrt{,f,l}.S`,
`s_llrint*.S`, **`s_logbl.S`**, `s_lrint*.S`, `s_remquo{,f,l}.S`, `s_rintl.S`,
`s_scalbn{,f,l}.S`, **`e_fmod.S`, `e_fmodf.S`, `e_fmodl.S`**.

So **three** of the cells measured here — `logbl.f80`, `fmod.f64`, `fmodf.f32` —
compile portable C fallbacks the platform never builds. (`amd64/e_fmod.S` is an
`fprem`/`fstsw`/`jne 1b` x87 loop.) `ilogb`, `ilogbf`, `ilogbl`, `logb` and `logbf`
have **no** amd64 override and are genuinely C here; `i387` additionally overrides
`s_logb.S`/`s_logbf.S`, but that is 32-bit x86, not this target.

**This is not in `SCOPING-L3.md`** — `grep -nE "amd64|\.S\b|fprem|fxtract|DUPLICATE"`
over that memo returns nothing. Its entire 9-cell `fmod` family, including the
§3(c) multi-exit argument and the §6.1 normalize-loop item, is measured against C
bodies x86-64 openlibm replaces with assembly. It belongs in that memo's §7 beside
the other two conventions (2-arg `3c6m.62`, by-ref `3c6m.59`).

**It does not change any compiler fact** — assembly has no IR to inject, and the
ruling is about the construct CQ is handed, which is the C. It changes only how a
*coverage* claim on those cells may honestly be quoted.

The other two conventions were checked and **do not apply to the four increment
cells**: all four `probe.c` files are single-argument, and none has an out-param.
They *do* apply to `fmod.f64`: its probe is `fmod(q0, 0.5)`, and the literal
const-folds the `iy` loops away — measured, 4 loops at `e_fmod.c:54,:56,:97,:112`,
with the memo's predicted `:63/:65` pair absent. Its bounds are therefore not the
both-operands-quantum bounds.

---

### 4d. The census `scope_ref` names the wrong re-opening mechanism — confirmed

All four cells carry *"Re-opens only via a static-K unroll (`8h7d`)"*. bd `eyhj`
asserts that names the wrong mechanism. **Measured, it does — and more strongly
than `eyhj` puts it.**

The shipped static-K unroll (`LoopUnrollPrepass.cpp`, the `lf8s` lever) **visits
these loops and claims none of them** — verified empirically, with a positive
control so that silence counts as evidence (Rule 11): `CQ_UNROLL_DBG=1` prints
nothing on all four cells, while the same command on
`ir-pass/test/lowering_unroll_const_trip.ll` prints
`CQ_UNROLL_DBG: fully unrolled trip-2 loop in @horner`. A `CQ_SPEC_DBG=1` dump
after the unroll fixpoint is structurally identical to the input — same blocks,
same phis, same `!llvm.loop` nodes.

It fails **three independent fences** on `ilogb.f64`, the most favourable of the
four (U1, U2, U2b and U4 all pass):

| fence | outcome on `ilogb.f64` |
|---|---|
| U3 — no tainted in-loop control | **FAILS**: the latch condition `icmp sgt %shl, 0` is tainted |
| U5 — exiting condition untainted | **FAILS**: same condition |
| U6 — exact constant trip count   | **FAILS**: `getSmallConstantTripCount` = **0** |

U6 is the decisive one, and it is decisive *structurally*:

```c
unsigned Trip = SE.getSmallConstantTripCount(L);            // LoopUnrollPrepass.cpp:199
if (Trip == 0 || Trip > kMaxUnrollTrip || SE.getSmallConstantMaxTripCount(L) != Trip)
  return false;
```

It demands the **exact** trip count, which a quantum-dependent trip count does not
have and cannot acquire. So **raising `kMaxUnrollTrip` from 8 to 33 would change
nothing** — the cells fail on `Trip == 0`, one clause earlier. The static-K unroll
is not a small cap away from these cells; it is asking a question they structurally
cannot answer.

(This is also why an unroll is the wrong shape regardless: `eyhj`'s own correction
notes Phase 7.3 lowers a classically-bounded loop **rolled in place**
(`LoopLowering.cpp:6-12`, PRD-7.3 §2.1), and §1c above shows a rolled B=33 costs
≈99 tainted ops with no IR growth and no compile-time wall.)

---

## 5. Deliverable (5) — the ilogbl ≡ logbl character-identity claim

**TRUE at source, but the `scope_ref` cites the wrong lines and states it too
narrowly.** The two files each contain **two** loops, and **both pairs** are
character-identical, not just the cited one:

```
src/s_logbl.c:36   for (b = LDBL_MANH_SIZE; !(u.bits.manl & m); m >>= 1)   \
src/s_ilogbl.c:37  for (b = LDBL_MANH_SIZE; !(u.bits.manl & m); m >>= 1)   / cited pair
src/s_logbl.c:40   for (b = 0; !(u.bits.manh & m); m >>= 1)                \
src/s_ilogbl.c:41  for (b = 0; !(u.bits.manh & m); m >>= 1)                / ALSO identical
```

The cited pair is **not the pair either cell actually declines on**: the shipped
first blocker is `s_ilogbl.c:41:4` and `s_logbl.c:40:4` — the *second* pair. This is
the L3 memo's own correction #4 (every recorded diagnostic is a **first blocker
only**) biting again.

Identity holds at IR level too, and exactly: canonicalising each loop body (drop
`#dbg_value` / `!dbg` / `!llvm.loop`, rename every SSA value to `%V`, strip labels)
and hashing gives **equal MD5s for both pairs** across the two files. Same
recurrence from the same literal `2147483648`, same `and`-then-`icmp eq 0` exit,
same operand provenance, same `CouldNotCompute` from SCEV. The only difference
anywhere in the family is the counter init (`32` vs `0`).

**But the `scope_ref` then over-reaches, and it is SHIPPED ON THE WRONG CELLS.**
The string is carried by **three** cells — `ilogb.f64`, `ilogbf.f32`,
`ilogbl.f80` — while naming only `ilogbl`/`logbl`. (`logbl.f80` carries the direct
2026-07-28 ruling instead.) So on two of the three cells that ship it, the
justification is about **files those cells are not built from**.

The bridge that carried it there is the clause *"and f64/f32 are the same idiom in
their own spelling"*. **Measured, they are not the same idiom** — not to SCEV, and
not in fact. The f64/f32 spelling shifts the **data** and tests its sign; the f80
spelling shifts a **mask** and tests an `and`. The first is boundable and total;
the second is neither.

Two further facts make the transfer worse than merely unproven:

* **Even a repaired matcher would not yield 32 for the f80 loops.** Their mask
  recurrence is `i64`, so the bit-width fact available to recover would be **64**,
  not the 32 the `scope_ref` implies.
* **There is no bit-width bound there to recover at all** (§2), because the loop
  is genuinely non-terminating on a zero word. Re-spelling the compare would not
  fix it.

Net: **TRUE-BUT-IMPRECISE** for `ilogbl.f80` (identity real; "loop" singular where
there are two; cited pair is not the blocker pair), and **FALSE-AS-APPLIED** on
`ilogb.f64` and `ilogbf.f32`.

---

## 6. Apparatus validation (Rule 11) — the memo's own numbers, reproduced

Before being trusted on new cells the instrument was pointed at the L3 memo's own,
and reproduces it exactly:

* `fmod.f64`, `e_fmod.c:54` and `:56` — constant max **32**, sound trip **33**.
  ✓ the memo's "SCEV constant max `i32 32`".
* `fmod.f64`, `e_fmod.c:97` (the `while(n--)` fix-point) — constant max **`-2`** =
  4294967294, sound trip **4294967295**, **multi-exit**. ✓ the memo's §3(c).
  (The memo cites this loop as `e_fmod.c:96`; the `while` is on `:97`. One line,
  no consequence, noted only so the two records can be matched.)
* `fmod.f64`, `e_fmod.c:112` (normalize) — **CouldNotCompute**. ✓ the memo's L4.
* `fmodf.f32`, `e_fmodf.c:78` — signed range `[-127,129)` → the unsound formula
  yields **128**, while LLVM's own answer on the same SCEV is **4294967294**.
  ✓ the memo's TRAP-1 example, verbatim.

One correction to this spike's *own* first-pass reporting, recorded because it is
the kind of thing that hardens by repetition: a `SCEVConstant` bound was initially
labelled "value-independent" without qualification. `e_fmod.c:99` shows why that is
not enough — its bound *is* a literal constant and is nonetheless **vacuous**
(4.29 billion trips, and counter-overflow-derived). Constant-ness is necessary, not
sufficient; the bound must also be **total** (§2) and **realizable** (§1c).

### 6a. The L3 memo's VERDICT does not transfer either — in the favourable direction

The memo's "payoff is zero cells" rests on its §6 item 1: *"A sound static bound for
the normalize loop (`e_fmod.c:112`) … **Without this, nothing else matters: the peel
is unemittable in 9/9 cells.**"* That is a statement about the **L4** layer.

**The ilogb cells have no L4 layer — and no L3 or L3a either.** Measured loop
inventories:

| cell | loops | which of the memo's four layers |
|---|---|---|
| `fmod.f64`   | **4** | L1 (`:54`) · L2 (`:56`) · L3 fix-point (`:97`) · L4 normalize (`:112`) |
| `ilogb.f64`  | **2** | **L1/L2 only** |
| `ilogbf.f32` | **1** | **L1/L2 only** |
| `ilogbl.f80` | 2 | the scan pair (an L1/L2-position loop, but unboundable) |
| `logbl.f80`  | 2 | ditto |

So the ilogb cells are the memo's L1/L2 row **standing alone**, with the two layers
that killed the fmod family structurally absent. This is the same observation the
2026-07-28 addendum made for `logbl` — it holds for all four, and for the f64/f32
pair it holds *together with* a usable bound. (The addendum spells that stack
"L2/L4/L5"; the memo's own §1 table names the layers L1/L2, L3, L3a, L4 and has no
L5. Same fact, inconsistent labels — noted so the two can be matched.)

That does **not** make the capability advisable; it means the L3 memo's verdict was
reached on a cell population these four are not members of, and cannot be quoted
against them. Both directions of transfer from that memo were unverified.

### 6b. A safety finding about the L3 memo's OWN recommended next step

`SCOPING-L3.md:294-296` ranks first among the things that would change its answer:

> **A sound static bound for the normalize loop** (`e_fmod.c:112`). Its real bound
> *is* a mantissa-width fact (≤ 23/52/63 shifts, **since `hx|lx ≠ 0` on entry**),
> but SCEV cannot see it … A domain-specific "shift-until-normalized" recognizer
> would remove the blocker.

**That parenthetical is the whole problem, and the memo does not draw the
consequence.** Measured on a verbatim transcription of `e_fmod.c:112-115` with the
`:110` guard ignored:

```
hx=1 lx=0                      ->  20 trips
hx=0 lx=1                      ->  52 trips
hx=0 lx=0  (GUARD-EXCLUDED)    ->  NON-TERMINATING (blew a 4096 tripwire)
```

The entry condition is `e_fmod.c:110`'s **tainted early return** — and §2 measured
that PredMux speculates exactly such guards away (`br i1` 5 → 0). **A recognizer
built as item 1 describes would recover a guard-conditional bound, which is the
R1-class silent miscompile `QramLowering.cpp:703-708` exists to prevent.**

Items 1 and 2 are listed in that memo as independent. They are not: **item 2's
reachability clause is what makes item 1 safe**, and item 1 as written carries no
reachability obligation at all.

### 6c. Two checks that could have invalidated everything, and did not

* **The f80 numbers survive `promoteFp80Union`.** Four of the five verifying
  reports measured `inl.ll`, which still carries the `union IEEEl2bits`
  alloca/store/load — but `CQLoweringPass.cpp:170` runs `promoteFp80Union` to
  fixpoint *before* anything else, so that is not the module the pass analyses.
  Re-run on the actual post-promotion module (via `CQ_FP80_DBG=1`): both loops in
  both f80 cells still report `Unpredictable constant max backedge-taken count`.
  Unchanged.
* **`fmodf.f32` does not hit Q1 at all.** It declines at
  `e_fmodf.c:76:2` with `cq loop lowering: multiple early-break sites`
  (`kMsgBreakMultiSite`, `LoopLowering.cpp:968`) — a *different* gate from the
  single `diagnoseUnderControl(_, "loop")` site at `:1161`. "These cells all hit
  one gate" is true of the four increment cells and false of the family beside
  them; do not generalise it.

---

## 7. What this does NOT establish

* **It does not show these cells have classical trip counts.** They do not. It shows
  two of them have a provable quantum-independent **ceiling**. Rule 18's 2026-07-28
  ruling says *"the test is the trip count alone"* — whether a ceiling plus a
  predicated body satisfies that is exactly the owner's question in bd `eyhj`, and
  this spike deliberately does not answer it.
* **It does not show a predicated body would be correct.** Nothing was emitted,
  linked, or run. §2's totality result is the *precondition* for such a lowering,
  not evidence that one would be sound.
* **Nothing here was linked or executed as a program.** "Compiles" would not be
  "verified" (Rule 2) even if it had been.
* The f80 non-termination result is about the **loop in isolation**; in the
  unmodified source the guard makes it unreachable. Its significance is entirely
  conditional on the guard being removed — which §2 measures PredMux actually
  doing (`br i1` 4 → 0, `switch` 1 → 0), so the condition is met in practice.
* **Whether the f64/f32 cells hide surrounding-control blockers is unmeasured.**
  `opt` exits at the first `DS_Error`, so nothing past the loop diagnostic is
  visible. §3b's static-K peels bound this to "no blocker inside the loop at
  K ≤ 33"; they say nothing about a second blocker elsewhere in the function.
* **Bennett condition (i) is unmeasured for any of these cells.** The checkout at
  `/private/tmp/Bennett.jl` is empty (0 files), so no CQ-PROVIDED scoping of this
  family can be done until it is restored.

---

## 8. Standing corrections this spike makes to the record

| record | correction |
|---|---|
| census `scope_ref` on `ilogb.f64` / `ilogbf.f32` / `ilogbl.f80` | **FALSE-AS-APPLIED** on the first two (§5); its `<=64` f80 bound is wrong (§1b); its "static-K unroll" re-opening mechanism is wrong (§4d) |
| the 2026-07-28 `logbl` ruling's evidence | rested partly on back-edge excision, now shown to be a **known-false-negative** probe (§3a). The ruling is not shown wrong; its stated evidence is weaker than it reads |
| `SCOPING-L3.md` §1 L1/L2 row | **understates itself** — the bound is not only quantum-independent but structural, guard-free and total (§2) |
| `SCOPING-L3.md` §6 item 1 | needs the **reachability obligation of item 2 attached**; as written it would recover a guard-conditional bound (§6b) |
| `SCOPING-L3.md` §7 conventions | missing a **third** caveat: the amd64 `.S` override, which hits `fmod`/`fmodf`/`logbl` (§4c) |
| this spike's own first pass | divergent-input count 1 → **2** (measured on source instead of rotated IR, §2); "SCEVConstant ⇒ value-independent" is the wrong predicate (§2b) |
