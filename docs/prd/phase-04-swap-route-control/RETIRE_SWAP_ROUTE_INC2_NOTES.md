# Increment 2 implementation notes — value arms by controlled-copy merge

> bd `test_C_libtooling-3qlq` child `3qlq.3`, implementing PRD §7. The increment
> itself is recorded in `$SP/progress/impl_inc2.md`; **this file is the round-1
> record.** Written on branch `3qlq-inc2` against the pre-3qlq **oracle**
> `52d7764` and the increment's own **subject-before** binary `8c526d9`, both
> named explicitly wherever a number is quoted.
>
> **Rule-13 round 1: two READ-ONLY lenses (V1 the mechanism, V2 the switch half
> + fixture/golden truth) and one FIX agent (§1).** Neither lens found a
> confirmed miscompile — a first for this file family, which was 4-for-4 going
> in — and the fix agent found one more record defect of its own while repairing
> theirs (§1.9). §1.11 is the running "what worries me" list and is where a
> round 2 should aim.

---

## §1 — Rule-13 round 1: findings and their dispositions

Reviews: `$SP/progress/review_inc2_V1.md` (50 plain-C programs + 9 hand-IR
modules, each through stage 1 → 2 → STRICT 2b → 3 → 4 on **both** binaries) and
`$SP/progress/review_inc2_V2.md` (a 14×8 injection matrix, a 1586-fixture
whole-corpus disposition sweep, 950 fuzzed switch-value programs and an
independent basis-state evaluator). Fix agent `fix_inc2_r1`.

| # | grade | disposition |
|---|---|---|
| F-V1-1 | unreviewed accept-class WIDENING | **KEEP + PIN** (owner OQ-22). §1.1 |
| F-V1-2 | mutate-then-decline | **FENCED**, and it turned out to be REACHABLE. §1.2 |
| F-V1-3 | doc truth (fp row) | corrected in source. §1.3 |
| F-V1-4 = F-V2-3 | doc truth + a real change of LEAK CLASS | PRD errata + source + slice headers. §1.4 |
| F-V1-5 | clear, missing pin | fixture + the G6/G7 consumer list. §1.5 |
| F-V1-6 | clear, wrong rationale | rationale corrected in source. §1.6 |
| F-V1-7 | missing witness | 4th twin pair + `cmp` gate. §1.7 |
| F-V1-9 | PRE-EXISTING Rule-1 gap | bd `3qlq.8`; the VALUE half closed as a side effect of F-V1-2. §1.2 |
| F-V2-1 | doc truth (a whole file header) | 3 sites rewritten. §1.9 |
| F-V2-2 | doc truth (a slice names a gate that does not exist) | header rewritten. §1.9 |
| F-V2-4 | census under-count | corrected. §1.8 |
| F-V2-5 | **fixture truth: contiguity dropped** | all 7 accepts restored; measured red-green. §1.10 |
| F-V2-6 | **fixture truth: a dirty flag free was invisible** | strip pinned + counts added + the switch discriminator. §1.10 |
| F-V2-11 | inherited silent `continue` | split into `continue` / `bailLoud`. §1.9 |
| F-FIX-1 | **new, found by the fix agent** | the two flagship SLICE headers were the F-V2-1 class too. §1.9 |

Commits on `3qlq-inc2`, in order: `0efe1f0` (sources), `b624826` (F-V1-1),
`143e92a` (F-V1-7), `acc1a30` (F-V1-5), `46b07ab` (F-V2-5/6/2), `b727da8`
(F-V1-2/F-V1-9), `1677a77` (F-V1-4 errata + F-FIX-1), and this file.

---

### §1.1 — F-V1-1: the widening is real, is at EVERY width, and is now pinned

Routing the value diamond through `emitSelectRegion` inherits
`SelectMergeEmit`'s `taint.HandleWidth[Out] = Abi` (bd p119.6). The retired
`emitValueRegion` wrote no such entry, and `HandleWidth` is exactly the side
table a downstream **cast** (`OpcodeLowering`) and a downstream **Q+Q data
compare** (`CompareLowering::rewriteCompare`) read to recover the logical width
of a laundered `i32` handle — neither falls back to the SSA type. So five plain-C
programs that DECLINED on `52d7764` with `no template for opcode …` now lower.

**The load-bearing row is `int e = (p == r);` at i32** — the widening is not a
sub-i32 artefact. Two hand-back sentences of the increment (that the only
side-effect widening was the Q+Q *condition*, and that the width axis "agrees on
every width a value arm can reach") are **false as written** and are corrected
here and in `SwapRouteEmit.cpp`'s header.

Kept, per the orchestrator's OQ-22 disposition: suppressing it would mean
deliberately re-introducing a known p119.6 defect on one path. Pinned by five
ACCEPT fixtures and one e2e slice, all **red-green measured** — 5 of 5 FAIL on
the oracle, 5 of 5 PASS on this binary:

- `control_swap_value_accept_i8_merge_cast.ll`, `…_i64_merge_cast.ll` — a
  `sext`/`trunc` consumer off a sub-i32 and a wide merge.
- `control_swap_value_accept_qq_compare_on_merge.ll` (**i32, the flagship**),
  `…_qq_compare_i8.ll`, `…_qq_compare_i16.ll`.
- `tests/e2e/slice_control_value_merge_qq_compare.c` (+ golden, 29 lines, STRICT
  2b rc=0) — e2e because it is the only layer that LINKS, i.e. the only proof
  that `cq_template_icmp_eq_i32` and its `_unc` twin resolve and signature-match
  when reached from a value-arm merge.

I looked for the failure mode the brief warned about — a *laundered* width that
mismatches the template chosen — and did not find one: every emitted stream is an
out-of-place template at the width the source declares, and stage 2b is clean on
all five.

### §1.2 — F-V1-2: the pre-mutation fence, and the reproducer the review said did not exist

`emitValueRegion` pre-flights, then **mutates** (hoist → `SelectInst::Create` →
RAUW the merge φ → `flattenRegion`), and only then calls `emitSelectRegion`,
which can still `return` after a failed `lowerCompareToFlag`. The retired route
minted the flag as its FIRST emission step, so its bail left the region intact.
Restored by re-asking `comparePredLowerable` **and** `compareFlagMintable` in
lockstep before the first mutation — the same pair, in the same order, as
`AngleSelectEmit` step 0b and the 6.5 classical-call gate (Rule 14: never a third
spelling).

> **⚠ THE ROUND-1 CLAIM "no reproducer is possible" IS SUPERSEDED, and this is
> the fix agent's most useful measurement.** V1 wrote that the only
> `comparePredLowerable`-true / `compareFlagMintable`-false shape is an i128
> condition, and that such a `br` "never reaches the control layer at all on
> EITHER binary" (finding F-V1-9). That is true of the **phase** arm and **false
> of the value arm**: detection *does* hand an i128-condition value diamond to
> `emitValueRegion`. Measured on `f1_i128cond.ll`:
>
> | binary | rc | first diagnostic | `cq controlled lowering:` count |
> |---|---|---|---|
> | oracle `52d7764` | 1 | `no template for opcode 'icmp i1' in tainted context` | **0** |
> | subject-before `8c526d9` | 1 | the same | **0** |
> | this commit | 1 | `cq controlled lowering: control flow under quantum control` | 1 |
>
> `CQ_CTRL_DBG=1` names `%c = icmp sgt i128 %qw, 5`. So the fence has a pin —
> `control_swap_value_reject_i128_cond.ll`, red-green against the pre-fix binary
> — **and it closes the VALUE half of F-V1-9's Rule-1 gap.** Nothing moved in the
> accept direction: both binaries exit non-zero and neither emits a gate.
>
> The **PHASE** half is unchanged and still open: `f2_i128cond_phase.ll` reports
> only the template error on every binary. Filed as bd
> `test_C_libtooling-3qlq.8`, with all three reproducers committed under
> `docs/prd/phase-04-swap-route-control/inc2-records/` (the plain-C spelling does
> not compile — `cq_theta`'s `_Generic` has no `__int128` association — so the
> shape is hand-IR-only at this frontend, which is why they are filed records and
> not slices).

### §1.3 — F-V1-3: the fp row's conclusion holds; its reason did not

The increment's totality table said an fp value arm is unreachable because
"`ArmClassify` declines an FP-typed merge as an ANGLE before the chain base is
read". Measured: a `phi double` diamond **is** claimed — by
`flattenPredMuxRegions`, which runs at `CQLoweringPass.cpp:196`, *before*
`detectControlRegions` at `:322`, and whose own W5 witness (bd vyqi) says it
takes "the flat sole-2-incoming SCALAR-FP-phi diamond … which `ArmClassify`'s fp
fence categorically declines". So the region never reaches the value path at all.
A shape PredMux will not claim (an `fp128` arm, refused by its E4 width gate)
declines `value-arm swap-route` **identically on both binaries**, earlier than
the fp merge fence. Both measured; artifacts under
`$SP/progress/fix_inc2_r1_work/`.

Consequence, now written in `emitValueRegion`'s pre-flight: its
`copyControlledFn` fp arm is an **unreached backstop** behind two fences, and it
is the one place where the new pre-flight is *stricter* than the emitter it
guards (`emitSelectRegion` would resolve `copyControlledFpFn`) — a latent
NARROWING, safe direction, measured by nothing. **Comment, not fixture:** no
constructible diamond reaches it, and fabricating one would be a false coverage
claim.

### §1.4 — F-V1-4 = F-V2-3: the leak class changed, and 3qlq.5 is unsound by default

PRD §3 and §7.1 describe the replacement as ending "… `6 _unc`; strip; free f",
with "`t`, `f` freed clean". **As shipped that is true of `f` and of `p`, and
false of `t`.** The chain's INTERMEDIATES are `_unc`'d and freed by the whole-DAG
spine; the chain's **FINAL** rail `t = R(p)`, whose live consumer is the
controlled copy, is left **allocated and DIRTY**. An if/else leaks two; the V3
switch leaks each delta `d_i` as well. V2's basis-state evaluator quantified it —
registers still allocated at program end / how many hold a non-|0⟩ label:

| program | route (`main`) | Inc 2 |
|---|---|---|
| `slice_control_value_diamond` | 9 allocated / **3 dirty** | 4 / **4** (q, p, **R(p)**, out) |
| `slice_control_switch_value` | 5 / **3** | 5 / **5** (+ d₀, d₁) |
| 3-content-case switch | 6 / **3** | 6 / **6** |

Total allocation goes DOWN; the count of permanently-dirty rails goes **up by one
per arm/case**. It is Rule-6 sound — `R(p)` is a deterministic function of the
RETAINED `p`, so writing it into a fresh |0⟩ ancilla is a unitary on
(p, ancilla) and tracing the ancilla out leaves the reduced state on (q, p, out)
unchanged — and it is a **leak, never a dirty free**: `free_pairing_check.py`
STRICT is rc=0 everywhere, and V2's evaluator reports zero dirty frees.

**But the leak class is not the route's**, which returned every rail it minted to
|0⟩, and that difference is load-bearing for PRD §9 follow-on **3qlq.5 (free the
value-arm SOURCE): it is UNSOUND BY DEFAULT under this stream.** With `R(p)` /
`d_i` retained, an increment that frees `p` performs a hidden measurement of a
register those rails still record. Under the route that follow-on was safe in
isolation; it no longer is, and it must discharge the finals/deltas first.

Corrected in four places: PRD §3 and §7.1 (inline errata blocks pointing here),
`SwapRouteEmit.cpp` step 5 (which had said "exactly as the route left them" —
true of `p`, false of the final), `SwitchValueEmit.cpp`'s new header, and the two
flagship slice headers (§1.9).

### §1.5 — F-V1-5: §3c/M-C is clear, and the property now has a tripwire

The hazard, stated once: `lowerOps`' M-C converts a tainted `add`/`sub`/`xor`
into an in-place `cqrt_addc`/`cqrt_xorc` and RAUWs the result to the **parent's**
handle. On a chain HEAD (whose parent is the routed register `Q`) that would make
a **diamond**'s second copy `copy_controlled(f, Q, out)` read a relabelled `Q`
(`out = f?R(p):R(p)` — the arm silently lost), and an **if/else** with both heads
converted collapse its two copy sources onto one register. Invisible to
`opt -verify`, to the golden byte-diff (the gate multiset is unchanged) and to
stage 2b (nothing is freed dirty).

It never fires, on every shape either reviewer or I could construct, and the
structural reason is that every chain head reads `Q` while `Q` always has a
second user (the second controlled copy, or the sibling arm's head), so G6
refuses the earlier head and G7 the later. **The finding is that Inc 2 made a
load-bearing property of the value merge — the two copy sources denote distinct
physical registers, which is `SelectClassify`'s gate 6, and the `br`-value path
does not run it — depend on a fence in another subsystem written for a different
customer**, one whose own source calls itself a weak tripwire and contemplates a
future `At == bo` widening.

Shipped: `ArithLowering.cpp`'s G6/G7 comment now lists the value merge as
CONSUMER 2 (with the two wrong-unitary shapes spelled out), and
`control_swap_value_ifelse_head_out_of_place.ll` pins the disposition. It carries
**two functions on ONE-LINK chains** deliberately — with a longer chain the
head's result feeds a fresh rail and the collision would not show; the diamond
needs ONE conversion to break, the if/else two. Injection-validated by splicing
the M-C conversion in by hand: **CAUGHT** by `CHECK` and `NOROUTE` in both
functions.

### §1.6 — F-V1-6: the totality fence is clear; one sentence was wrong

The recorded rationale — "the pre-3qlq route also ran the chain UNCONTROLLED (on
a `|0>` rail, i.e. `0 sdiv n`)" — is the **classical-trace** reading and is
misleading as physics: `cqrt_cswap(f, p, rail)` leaves the rail in a
**superposition** of `p0` and `0` correlated with the flag, so the routed chain
gate had to be defined over `p0`'s whole range too. The conclusion is unchanged
and *strengthened*: the obligation was identical under the route, so the fence
NARROWS the accept class, which is always safe. Restated in source, because the
sentence as written could later be quoted to argue the fence is over-strict.

Recorded with it: `isSafeToSpeculativelyExecute`'s **`INT_MIN / -1` arm is
exercised by nothing** — `clang -O1` folds `p / -1` to `sub i32 0, %p` before the
pass sees it, so only the possibly-zero-divisor arm has a reproducer.

### §1.7 — F-V1-7: the fourth twin gate

The increment shipped three `cmp` twin gates (diamond, if/else, mixedops).
`control_swap_value_diamond_polarity.ll` pins the emitted SYMBOLS for a negated
condition, but symbols cannot see an operand swap: the multiset
`{copy_controlled, x, copy_controlled, x}` is identical either way, and so is the
free/strip pairing stage 2b checks. Byte identity against the PRE-HOISTED SELECT
spelling — which reaches the same emitter with **no polarity decision to make** —
is the only measurement that does.

Shipped: `slice_control_value_polarity{,_twin}.c` + goldens (23 lines each,
STRICT 2b rc=0, `cmp` **IDENTICAL**) + `e2e-value-polarity-twin-identical`. All
four value twin gates pass.

### §1.8 — F-V2-4: the cswap census, re-measured

The increment's hand-back said "ONE minter and FOUR call sites". Re-measured by
me (`grep -rn "emitRoute(" ir-pass/src ir-pass/include`): **SEVEN call sites in
three files** — `NestedRouteEmit.cpp:162,176,178,194` (four: outer route-in,
inner route-in, inner route-BACK, outer route-BACK), `SwitchRouteEmit.cpp:159`
and `:172`, `AbortParkEmit.cpp:381` — plus one unrecorded appearance path,
`EmitInverse.cpp:261`, which RE-EMITS an existing `cqrt_cswap` under the
involution family (it never mints the declaration). One minter,
`ControlledSymbols::cswapFn`, reached only from `emitRoute`.

**The material claim is unchanged and holds: ZERO value-path call sites remain**,
and V2 confirmed it independently at the golden level — goldens containing
`cqrt_cswap` went 5 at `main` → 3 at HEAD, all three byte-identical on both
binaries. "AbortParkEmit only" becomes true after **Inc 1** retires the two PHASE
routes, and the increment correctly declined to claim it early.

### §1.9 — the record-truth family (F-V2-1, F-V2-2, F-V2-11, and F-FIX-1)

`CLAUDE.md`'s fenv paragraph records the failure mode: prose that hardens by
repetition into a de-facto ruling. Four sites, all corrected:

1. **F-V2-1** `SwitchValueEmit.cpp:1–30` was **byte-identical to `main`** and
   described the retired route in the present tense, including a `#include`
   (`emitRoute`) the same commit deleted. Rewritten: the retired stream stated
   explicitly AS retired, then the shipped preload + XOR-delta recipe, the
   mutual-exclusion argument, and what is left allocated. Also
   `SwitchRouteEmit.h`'s `emitSwitchValueRegion` doc and the `CaseStream` doc
   comment, which contradicted its own field comment two lines below.
2. **F-V2-2** `slice_control_value_derived.c` named a `cmp` gate and a twin file
   that do not exist; `CMakeLists.txt` said the opposite and was right. The
   header now carries the measured both-binaries decline of the twin V2 wrote.
3. **F-V2-11** `SwitchValueEmit.cpp`'s `if (!Arm.Block || Arm.Values.empty())
   continue;` — a silent skip on a shape the comment itself calls malformed,
   where every neighbour bails loudly. SPLIT: a null block still `continue`s
   (its merge incoming IS `p`, which the preload already holds), an empty value
   list now `return bailLoud(R)`. Unreachable at HEAD, so a comment says so
   rather than a fabricated fixture.
4. **F-FIX-1 — MINE, and the same class one layer out.** Neither lens read the
   `.c` slice headers. `tests/e2e/slice_control_value_diamond.c` was **last
   touched by the 4.2 commit `7139b7a`** and still described "compute the chain
   on a |0> work rail … CSWAPs p into the rail … route-back-dagger", and
   `tests/e2e/slice_control_switch_value.c` (last touched by the 4.5 commit)
   likewise, with 8 and 9 stale route mentions. **Their goldens had been
   regenerated by the increment and their prose had not** — so the two flagship
   customers of the two rewritten emitters each contradicted their own
   `.expected.log`. Both rewritten; both goldens unchanged (the gates still
   pass), because only prose moved. A fifth site,
   `EmitInverse.cpp`'s cswap-seam guard, still said "the swap-route value-arm
   emitter brackets its R† route cswaps itself" — corrected to name the emitters
   that actually still route, and to say which one survives Inc 1.

### §1.10 — F-V2-5 and F-V2-6: the fixture layer, measured red-green

The increment re-derived seven accept fixtures from the pass output and, in doing
so, dropped **every** `CHECK-NEXT` (`control_swap_value_ifelse.ll` went 28 → 0 —
a regression in kind, not just in count). With bare positional directives, symbol
ORDER is pinned and **adjacency is not**, so an inserted gate is invisible.
`control_swap_value_accept_div_const.ll` additionally pinned the flag's
`cqrt_free` without the strip that must precede it — a **dirty free, i.e. a
hidden measurement that collapses q** (Rule 6) — and carried no count prefixes at
all.

Measured with a 7-mutation × 8-accept matrix, clean control first
(`$SP/progress/fix_inc2_r1_work/inject.py`; mutations are textual on the LOWERED
output, i.e. "a future build emitted this stream"):

| | mutations NOT CAUGHT |
|---|---|
| pre-fix (`git show acc1a30:…`) | **13** — `M11_stray_ry` in **7 of 7** accepts, plus `M9_drop_flag_strip`, `M5_drop_chain_unc`, `M7_drop_rail_free`, `M10_dup_ccopy` and `M12_free_before_strip` all uncaught in `accept_div_const`, and `M10` in `accept_nonclobber` |
| after | **0** — every applicable mutation caught by ≥1 prefix, most by two |

Shipped: a contiguous `CHECK`→`CHECK-NEXT` chain from the first alloc to the
measure in all seven, with **the strip pinned immediately before its free** in
each; `FCNT`/`CCNT` added to `accept_div_const`, `CCNT` to `accept_nonclobber`;
and a NEW **switch-half accept discriminator**
`control_swap_switch_value_accept_div_const.ll` (`p/3` inside a case), without
which the switch side of the totality fence was indistinguishable from "decline
every div". That last one is rc=0 on **both** binaries, so it is on the same side
of the fence on both — unlike its decline twin, which the oracle accepts.

> **LLVM-19 / FileCheck TRAP, cost two failing fixtures while writing this.** A
> comment paragraph containing the literal token `CHECK` followed by a colon is
> parsed as a DIRECTIVE, wherever it appears. Prose that *describes* the
> directives must never spell one. (`bd remember`-worthy; the same shape as the
> drbq Inc-4 windowing lesson.)

### §1.11 — what worries me, i.e. where a round 2 should aim

1. **The REVIEWER FLAG the increment itself raised is still unlensed.** Inc 2
   makes `emitSelectRegion` reachable with inputs `classifySelectRegion` would
   REFUSE — specifically a **coherent Rz-lineage operand** (a derived base),
   which `SelectClassify` conservatively rejects and the `br`-value classifier
   deliberately accepts (the 9hh discipline). Both round-1 lenses checked the
   *other* gates (2c stale-condition, fp/vector/i128 width, Q+Q condition,
   `compareFlagMintable`) and both left this one to a future lens. The witness in
   the tree is `slice_control_value_derived` + `control_swap_value_diamond_derived.ll`;
   the 4.4 refusal is documented as CONSERVATIVE, not as a proven miscompile, but
   nobody has proved the accept.
2. **The whole `emitValueRegion` correctness argument now leans on a fence in
   `ArithLowering`** (§1.5). It is a *weak tripwire* by its own source comment,
   and its widening is already contemplated there.
3. **The dirty finals (§1.4)** are sound only while `p` is retained. The
   invariant that keeps `p` alive is `ChainWalk::forwardConsumerCount`'s fan-out
   bail (consumer count ≥ 2 in every shape either of us could build), i.e. bd
   memory `select-merge-no-chainwalk-exemption` — which now protects a second
   path and does not say so.
4. **V3 has no byte-identity twin of any kind** (F-V2-10): the uncontrolled
   preload is not expressible in C. Its floor is a self-regenerated golden, a
   fixture derived from that same output, and an analytic argument — thinner than
   V1/V2's, and stated here because it was stated nowhere.
5. **The two open owner questions the increment filed** (Q+Q *condition*
   capability, the run-time classical SHIFT AMOUNT passed through to the gate)
   are unresolved, and the second is genuinely pre-existing — identical on both
   binaries — so it is a Phase-9 ABI question, not an Inc-2 one.
6. **The `value-arm swap-route` decline string now names a RETIRED mechanism** (6
   source sites, 28 fixtures). Deliberately not renamed here: zero behaviour,
   large churn, three shared files, and the string still covers the PHASE routes
   until Inc 1 lands.

---

## §2 — What round 1 measured that should not have to be re-measured

- **Whole-corpus disposition sweep, 1586 fixtures × 2 binaries: exactly THREE
  differences**, all of them Inc 2's own new fixtures (two speculation
  NARROWINGS, one Q+Q condition moving into the control dialect). Zero
  pre-existing fixtures changed disposition.
- **The three original twin gates are non-circular**, by two independent
  measurements: the twin `.c` files really are a different `-O1` shape (2 phis +
  2 branches vs 2 selects, and the modules differ), and the **ORACLE** binary
  reproduces all three twin goldens byte-for-byte — so the identity says "the
  Inc-2 diamond stream equals a stream the PRE-Inc-2 compiler already emitted for
  the manually hoisted program".
- **950 fuzzed switch-value programs** (1–4 content cases, negative case values,
  chains of 0–3 links over 8 stems, passthrough arms), 3 seeds: 928 accepted,
  **0 semantic mismatch, 0 dirty free, 0 disposition drift** against the oracle.
- **V2's basis-state evaluator** (OQ-23, owner decision pending): a value/switch
  region contains only PERMUTATION gates, so re-interpreting the flattened trace
  as a classical reversible circuit and checking every basis input **is** a
  complete check of the region's unitary — and it is the only thing in reach that
  witnesses "freed at |0⟩", which the golden byte-diff structurally cannot. It is
  **not** a statevector simulation. Recorded as a measurement round 1 made; NOT
  added as a ctest gate (the 2026-06-10 no-simulation decision is the owner's to
  revisit).
- V1's mechanical audit of every `cqrt_free` across 38 accepting subject traces:
  each names either a rail a `_unc` returned to |0⟩ on the lines immediately
  above, or a compare-minted flag stripped by its own `…_hl_unc`. **Zero unproven
  frees**; no free of a merge out-rail, a chain final or a source anywhere.

---

## §3 — THE REBASE ONTO THE LANDED INCREMENT 1 (2026-09-06, agent `rebase_inc2`)

Branch `3qlq-inc2` was written against `dfb8e83` (the pre-Inc-1 `main`). Increments
0 and 1 landed on `main` as ONE squash commit **a3c1513** on 2026-09-06, so this
branch was rebased onto it: `git rebase a3c1513`, 15 commits replayed. The
pre-rebase tip **87a90d7** is kept as the local ref `3qlq-inc2-prerebase` so any
claim below can be re-derived.

### §3.1 — The overlap is SEVEN files, not six, and only TWO conflicted

MEASURED by `comm -12` over `git diff --name-only dfb8e83 a3c1513` (962 files,
Inc 1) and `git diff --name-only dfb8e83 87a90d7` (55 files, Inc 2):

| file | conflict? | resolution |
|---|---|---|
| `ir-pass/src/SwapRouteEmit.cpp` | **YES**, at `0efe1f0`, ONE include line | both sides kept — Inc 1's `ChainWalk.h` (`markBranchPhaseGate`) beside Inc 2's widened `CompareLowering.h` comment (`+ compareFlagMintable`) |
| `ir-pass/test/control_swap_value_diamond_derived.ll` | **YES**, at `5b1d723`, two hunks | Inc-2 structure + Inc-1's migration note; then RE-DERIVED from the rebased binary (§3.3) |
| `ir-pass/include/ControlPlan.h` | no | auto-merged; Inc-2's `Shadow` emit-order paragraph is history-true and reads correctly beside Inc 1's |
| `ir-pass/src/ArithLowering.cpp` | no | auto-merged (the G6/G7 CONSUMER-2 paragraph) |
| `ir-pass/src/EmitInverse.cpp` | no | auto-merged, then CORRECTED BY INTENT (§3.4) |
| `docs/prd/.../retire-swap-route-PRD.md` | no | auto-merged; Inc-2's inline errata in §3/§7.1 and Inc-1's §0 E1–E10 coexist, and §0 **E1 already carries Inc 2's dirty-chain-final text** |
| `tests/e2e/CMakeLists.txt` | no | auto-merged; both blocks present, no duplicate `add_test(NAME …)` and no duplicate slice source (checked with `uniq -d`) |

The big file did not conflict because the two increments touch DISJOINT regions of
it: Inc 1's hunks are at lines 20–40 / 129 / 1249+ / 1356+ / 1594+ (the kickback
emitters), Inc 2's at 5–40 / 190–490 (`ValueArmStream` + `emitValueRegion`). Only
the include block is shared.

**Faithfulness check.** For each of the seven, the number of changed lines in
`git diff dfb8e83 3qlq-inc2-prerebase -- <f>` and in `git diff a3c1513 HEAD -- <f>`
is IDENTICAL (10 / 29 / 13 / 520 / 24 / 161), i.e. Inc 2's delta was carried
verbatim onto the new base. The one exception is the fixture, 116 → 115, which is
the `cqrt_rz_i32` CHECK line Inc 1 had already removed the source for (§3.3).

### §3.2 — The epic's cswap goal is now MET, and this is the measurement

`grep -rn 'emitRoute(' ir-pass/src ir-pass/include` on the rebased tree returns
**three lines: the definition (`SwapRouteEmit.cpp:1327`), the declaration
(`SwapRouteEmit.h:105`) and ONE call site, `AbortParkEmit.cpp:396`.**
`NestedRouteEmit.{cpp,h}` do not exist (Inc 1 deleted them) and `SwitchRouteEmit`'s
phase path mints a kickback. §1.8's "SEVEN call sites in three files" is the
measurement **at the pre-rebase base** and stays as written; this paragraph is its
successor, not a correction of it. `cqrt_cswap` is minted by `AbortParkEmit` alone.

### §3.3 — `control_swap_value_diamond_derived.ll`: re-derived, and its NAME is now history

Inc 1's migration DELETED the fixture's `%pd = cq_phi_si32(%p, 0.9)` (an
uncontrolled `cq_phi` is a global phase and is deleted under D2, and the register
spelling no longer exists), so the body is a PLAIN base while Inc 2's re-derived
CHECK block still expected `cqrt_rz_i32(%P, 0.9)`. Re-derived from the REBASED
binary's own output: the one Rz `CHECK-NEXT` is gone and nothing else moved.
**The file no longer pins a derivation**, which its header now says outright
rather than letting the filename carry the claim. Re-spelling the body with
`cq_theta` would restore the property in one line and is deliberately NOT done
here — the body is an Inc-1 LANDED decision, not the rebase's to reverse. The
property is carried instead by the e2e slice (§3.5). This is the OQ-9 class
("the DERIVED-BASE idiom dissolves — 28 fixtures").

### §3.4 — `EmitInverse.cpp`'s cswap seam, corrected BY INTENT

Inc 2's round-1 fix rewrote the seam comment to name "the live routing emitters"
as `NestedRouteEmit`, `SwitchRouteEmit` and `AbortParkEmit`, "the first two
retired by Inc 1". On the rebased tree Inc 1 IS applied, so that sentence was
false in the present tense the moment the rebase completed. Rewritten in the
singular against the §3.2 measurement: the park is the only `emitRoute` caller and
the guard guards exactly it.

### §3.5 — `slice_control_value_derived.c` did not COMPILE, and the repair is measured

The slice's derived base was `p = cq_phi(p, 0.9)`; under the Inc-1 header that is
a hard compile error (`too many arguments to function call, expected single
argument 'angle'`), so stage 1 failed. Two repairs were measured before choosing:

| repair | measured |
|---|---|
| (a) delete the line | the program becomes BYTE-IDENTICAL to `slice_control_value_diamond.c` and its trace byte-identical to that slice's golden — a duplicate (the Inc-1 **OQ-5** precedent, where `slice_loop_break_qq_phase` was DELETED for exactly this) |
| (b) `p = cq_theta(p, 0.9)` | **KEPT.** Accepts on THREE binaries: pre-3qlq oracle `52d7764` 29 lines (route), landed Inc-1 `main` 29 lines (route), rebased HEAD **24 lines** (merge) = the diamond's 23 plus ONE unconditional `cqrt_ry_i32` on the same handle, strictly before the hoisted chain. STRICT stage 2b rc=0 on all three. Not a new accept class — the same customer, new mechanism. |

The rotation is Ry, not Rz, so the old "diagonal alias" wording is history; what
the emitter sees (both SSA names RAUW'd to ONE handle) is unchanged, and that is
the property the slice exists to exercise. Golden regenerated, 24 lines.

### §3.6 — ⚠ THE INC-2 REVIEWER FLAG IS **NOT** DISSOLVED BY INC 1 — measured, and it goes to round 2

`OWNER_QUESTIONS.md`'s Inc-2 REVIEW FLAG closes with: *"after Inc 1 there is NO Rz
lineage any more (cq_phi is register-free), so this class must be re-asked
post-rebase."* Re-asked. **MEASURED: the class survives, with `cq_theta` as the
derivation.** The pre-hoisted select twin of §3.5's repair (b) — `int t = R(p);
p = (q>5) ? t : p;` after the same pre-region rotation — DECLINES
`cq controlled lowering: control flow under quantum control` on the rebased
binary, exactly as the `cq_phi`-derived twin declined on the oracle and on the
pre-rebase branch. So `emitSelectRegion` is STILL reachable through the
`br`-value classifier with a coherent ROTATION-lineage operand that
`SelectClassify` would refuse at its own front door. §1.11 item 1 is unchanged by
the rebase and is still the first thing a round 2 should aim at.
Reproducers: `slice_control_value_derived.c` (accept) and, for the twin, the same
body with `int t = R(p); p = (q>5) ? t : p;`.

---

## §4 — Rule-13 ROUND 2 (2026-09-06), post-rebase

> ⚠ **NUMBERED §4, not "§2 — round 2".** The `fix_inc2_r2` brief calls this
> section "§2"; §2 was already taken by round 1's re-measure ledger and §3 by the
> rebase, so round 2's record is §4 and nothing was renumbered. Read §1 (round 1),
> §2 (what round 1 measured), §3 (the rebase) and §4 (round 2) in that order.

One READ-ONLY lens (`review_inc2_r2`, subject `3qlq-inc2` @ `6ee3ea3`, controls
`main` a3c1513 = INC-1-ONLY and the pre-3qlq oracle 52d7764) and one fix agent
(`fix_inc2_r2`). **Ten findings, ONE of them a leak — and that one is PRE-EXISTING
on the landed `main` and not Inc 2's.** Inc 2's own mechanism is CLEAR on
everything this round could reach.

| # | grade | disposition |
|---|---|---|
| F-I2-1 | **LEAK** (rolled != unrolled, O(K)) — **PRE-EXISTING on `main`**; Inc 2 adds a FOURTH producer of the rail | **RECORDED, NOT FIXED HERE**: bd `test_C_libtooling-7yd0`, fixed as a separate C-1 round 4 on `main` AFTER Inc 2 lands. 18 reproducers + the discrimination table under `inc2-records/`; PRD §0 **E11**. §4.1 |
| F-I2-2 | CLEAR (the increment's own REVIEWER FLAG) + one doc item | **RESOLVED IN THE INCREMENT'S FAVOUR**, with the mechanism named. §4.2 |
| F-I2-3 | fixture truth (the F-V2-1 class, a sixth site) | fixture **RE-DERIVED** + header rewritten + the p119.8 discriminator MEASURED by mutation. §4.3 |
| F-I2-4 | doc / latent (an Inc-1 LANDED consequence) | ONE comment at each of the two vacuous gates; **no code deleted**. §4.4 |
| F-I2-5 | CLEAR (kickback-phased register through a controlled copy) | recorded, and cited in the gate-5 comment as the reason the retired fence has no successor hazard. §4.4 |
| F-I2-6 | NOTE (the `&&` byte-identity item) | **NO SUBJECT** — both spellings decline on all three binaries. §4.5 |
| F-I2-7 | OVER-DECLINE, pre-existing, identical on all three | **PINNED AS A PAIR** of fixtures + named as an owner item ("the base-from-cond asymmetry"). §4.5 |
| F-I2-8 | CLEAR (the rebase itself) | nothing owed. §4.6 |
| F-I2-9 | CLEAR (the `ArithLowering` G6/G7 tripwire under C-1's new `InPlaceRailOps` writers) | nothing owed. |
| F-I2-10 | CLEAR (mixed shapes + the loop fence) | nothing owed. |

### §4.1 — F-I2-1: recorded, deliberately not fixed on this branch

Full account in `inc2-records/README.md` (round-2 section) and PRD §0 **E11**.
Two sentences that must travel with it:

* **It is pre-existing on the landed `main`**, and that is a MEASUREMENT, not an
  inference: the 13-line headline reproducer `q5sel_preadd_{rolled,unrolled}.c`
  contains no Inc-2 feature and behaves identically on `main` a3c1513 and on this
  branch (rolled 44 trace lines / 4 `and_hl` mints / **0** `_unc`; unrolled 52 / 4
  / **4**; at K=32, 240/32/**0** against 301/31/31 — **O(K)**).
* **Inc 2 adds a fourth producer of the rail shape**, i.e. more customers
  (`q4b_preadd_*`: 52 vs 60 here, 57 vs 65 on `main`). That is the whole of Inc 2's
  relationship to it.

**No fixture on this branch pins the leak as an accept** — pinning it would bless
it. The round-4 fix on `main` pins the discharge. The 18 records are committed so
that fix has a red-green to start from.

### §4.2 — F-I2-2: the increment's own reviewer flag, RESOLVED

§1.11 item 1 and §3.6 left this open: the `br`-value classifier accepts a derived
base that `SelectClassify` refuses at its own front door. **The asymmetry is real
and survives Inc 1** (re-measured here on all three binaries, with `cq_theta` as
the derivation): `q1_derived` ACCEPTS — subj **24** trace lines, INC-1-ONLY **29**,
oracle **29** — while its pre-hoisted select twin `q1_derived_twin` DECLINES
`cq controlled lowering: control flow under quantum control` on **all three**. The
unchained control `q1_plain`/`q1_plain_twin` both accept everywhere (23 lines on
the subject for both). So the refusal is specific to the CHAINED theta, not to the
select.

**WHICH gate, and why it is an ARTIFACT.** The refusal is gate 5's
`hasCoherentDownstreamUse`, and the flagged rotation is the base's OWN producing
theta. `rotationAncestry(Op)` is seeded at `Op` and only walks when `Op` **is
itself** a rotation call; for a derived operand (the chain RESULT) the ancestry is
the singleton `{Op}` and the exemption is empty, while the lineage-wide seeding
added by the kjd1 clearance reaches the base's ancestor whose rotation user is then
"off-ancestry". The gate's own comment says the exemption exists to keep
`select(c, theta(theta(q)), x)` — that shape does accept; the same base one
arithmetic hop away does not. **This is a SEEDING artifact, not a proven hazard.**

**The diamond's ACCEPT is SOUND on this evidence.** After the flatten the region is
`|q,p,t=R(p),0⟩ → |q,p,t, c(q)?t:p⟩`: two controlled-XOR copies into a FRESH |0⟩
ancilla, with the flag minted and stripped by an exact inverse pair that touches
nothing between. That is a PERMUTATION, hence LINEAR, hence correct for an
arbitrary input superposition — amplitudes and relative phases ride the branch they
belong to. Nothing in it reads the operands' rotation lineage.

**And the genuine hazard the seeding WAS built for is caught on the diamond path
too.** The kjd1 fork shape (`int a = p; int p1 = cq_theta(p,0.9); if (c) a = R(a);`
— a SUPERSEDED record) DECLINES `cq opcode lowering: operand predates a
non-diagonal gate` on **all three binaries** in all three orderings measured
(`q1f_fork_diamond`, `q1f_fork_twin`, `q1f_fork_after`), through the pass-wide
`declineStaleRecordOps`. So the `br` path is not unprotected; it is protected by a
different, later fence.

**Disposition: the 4.4 refusal is an OVER-DECLINE that COULD be widened, and that
is an owner item, not this round's.** Widening `rotationAncestry`'s seeding is a
Rule-13-core accept-class change and needs its own red-green plus a lens.

**The DOC half IS done, in source.** `hasCoherentDownstreamUse`'s ancestry-exemption
comment ("keeping the sanctioned chained-prep accept `select(c, theta(theta(q)), x)`")
is the sentence a future reader would use to conclude the gate is exact, and it is
exact only when the operand IS the rotation call. A paragraph now sits directly
under it recording the singleton-`Ancestry` mechanism, the three-binary
measurement, the permutation/linearity argument, the `declineStaleRecordOps`
backstop, and that widening the seeding is an owner item rather than a bug to fix
in passing. Comment only — `cq-opt` rebuilds **byte-identical**.

### §4.3 — F-I2-3: `lowering_switch_value_nonI32_cast.ll` re-derived

The eighth OUTDIFF of the lens's 1673-fixture sweep, and the only one Inc 2 had
not re-derived: its output moved from the route (`icmp mint; alloc i64; cswap;
add_i64_hl; cswap; …; copy_i64; cswap; add_unc; cswap; cswap; free`) to the
preload + XOR-delta recipe, and **nothing went red**, because its three directives
(one positive `trunc` line and two negatives) are about the bd p119.8 width record
alone and are blind to the mechanism. Its header still described the route in the
present tense.

Re-derived from the rebased binary's own output: the whole region stream,
`CHECK-NEXT`-adjacent from the first alloc to the measure, with `NOROUTE` (a
whole-file PURE-negative block — no count inside it, the drbq Inc-4 windowing
lesson) and `FCNT`/`CCNT`/`PCNT` each in its own prefix. Header rewritten with the
retired route marked as history and with the reason nothing caught the move.

**The p119.8 property is pinned by ONE positive directive and that is MEASURED, not
asserted:** commenting out `SwitchValueEmit.cpp`'s `taint.HandleWidth[Out] = Abi;`
and rebuilding makes the pass OVER-DECLINE — `no template for opcode 'trunc i32' in
tainted context`, `opt` exit 1 — so the failure lands on the FIRST RUN line. The
mutation was reverted and the rebuilt `cq-opt` is **byte-identical** to the pre-fix
one (`cmp`).

**RED-GREEN vs INC-1-ONLY: three of the six prefixes discriminate** — the default
adjacency block, `NOROUTE` (on `cqrt_cswap`) and `CCNT` (the route emits zero
`cqrt_copy_i64_controlled`). `FCNT` and `PCNT` do NOT: the route also frees exactly
four rails and also emits exactly one uncontrolled preload copy. That is written
into the header, because a prefix that cannot tell the two mechanisms apart must
not be quoted as if it could.

### §4.4 — F-I2-4 / F-I2-5: two 4.4 gates are VACUOUS since a3c1513

`isPhiCall` is `isCallToPrefix(V, "cq_phi_")` in **seven identical definitions
across seven files** (`grep -rn 'bool isPhiCall' ir-pass/src`), and the shipped
intrinsic is `void cq_phi(double)` with NO suffix (`include/CQ.h:73`). So in
`SelectClassify`: gate 5's PHASE half (`operandCarriesPhase`) can never return
true, and gate 6's `operandsAlias` closure degenerates to `{A}`, i.e. the gate to
pointer equality `A == B`.

**No code was deleted** (the predicate already carries a "vacuous, deliberately
kept" block, and the freeze-time dead-code list owns that decision). What was
missing is the note AT THE TWO GATES, which a reader would otherwise take at face
value; one comment was added above each, saying why the vacuity is safe:

* gate 5 — the WI-3 class is **structurally gone**: a branch phase has no register
  operand (D1) and an uncontrolled one is deleted (D2), so no value can have a
  `cq_phi` in its lineage. The successor shape (a register carrying relative phases
  IMPARTED by a kickback) is **not** that hazard: **F-I2-5** measured
  `q1k_disjoint_phase_then_value` ACCEPT at 27 lines on the subject (32 on
  INC-1-ONLY) and **byte-identical to its pre-hoisted select twin**, and the
  argument is linearity — a basis copy loses a phase only when the phase sits
  BETWEEN two branches carrying the SAME label, which a per-branch kickback never
  produces.
* gate 6 — the nearest LIVE analogue never reaches it. **MEASURED on all three
  binaries**, `int t = cq_theta(q,0.9); p = (q>5) ? t : q;` declines
  `cq controlled lowering: condition predates a non-diagonal gate under quantum
  control` at gate **2c** (reproducer
  `$SP/progress/fix_inc2_r2_work/p/g6_theta_alias.c`). The gate-5 channel-B
  fallback is labelled ANALYTIC in the comment, not measured, with the ancestry
  argument spelled out — because 2c fires first and the shape cannot be observed
  past it.

Both comments say what a future re-arming would have to do, and both say **not** to
teach `isPhiCall` the new spelling (a `void(double)` call has no arg-0 wire and no
arg-1 angle; every clause downstream would read the wrong operand).

### §4.5 — F-I2-6 (no subject) and F-I2-7 (the base-from-cond asymmetry)

**F-I2-6 has no subject.** `if (q>3 && r<12) { 6-op chain }` and its `?:` twin BOTH
decline `cq controlled lowering: control flow under quantum control` on subj,
INC-1-ONLY **and** the oracle (`-O1` short-circuits `&&` into two branches, which
the value path refuses), so the byte-identity comparison round 1's brief asked for
cannot be run. Recorded, not pinned: a fixture asserting "both spellings decline"
would duplicate two existing compound-condition declines and pin nothing new.

**F-I2-7 is the OPPOSITE asymmetry to the reviewer flag, and it is now pinned.**
`int p = q + 11; if (q>3) { 6-op chain }` DECLINES `cq controlled lowering:
non-routable value multiplexer under quantum control` while its pre-hoisted select
twin ACCEPTS (22 trace lines) — **identically on all three binaries**, with the
twin's lowered `@slice` **byte-identical across all three** (`cmp`). Two new
fixtures:

* `ir-pass/test/control_swap_value_reject_base_from_cond.ll` — the decline, string
  mirrored in full, plus `CHECK-NOT` on the §3c string and on any lowering.
* `ir-pass/test/control_swap_select_base_from_cond.ll` — the accept, the WHOLE
  region stream `CHECK-NEXT`-adjacent, plus `NOROUTE`/`CCNT`/`FCNT`.

Both are captured from real `clang -O1` (SSA renamed only), and **their headers
record what `-O1` did**: reassociation moved the arm chain onto `%q`, so
`ChainBase != Routed` — the two bases the decline is about are the OPTIMISER's, not
the source's. **There is deliberately no red-green here and both headers say so**:
the pair records a PRE-EXISTING over-decline and passes on INC-1-ONLY and on the
oracle too. It must not be quoted as a witness of an Inc-2 change.

**Owner item name: "the base-from-cond asymmetry."** A bd issue for it is the
orchestrator's to file. Note it points the OPPOSITE way to §4.2's reviewer flag —
there the diamond accepts where the select refuses; here the select accepts where
the diamond refuses. Only one of the two had been written down.

⚠ **The accept fixture was STRENGTHENED after the injection matrix caught a hole in
it.** As first written its `CHECK` block started at the flag mint and left the
arithmetic prologue to the counts; the harness then reported `M5_drop_chain_unc`
**NOT CAUGHT** (deleting the chain's `mul_i32_hl_unc` does not move the free
count). Extending the block to the whole region catches all seven mutations. This
is the F-V2-5 lesson arriving from a third direction and is why the injection
matrix is run on NEW accepts and not only on re-derived ones.

### §4.6 — F-I2-8: the rebase, independently re-verified by the lens

The lens re-derived §3's claims from scratch rather than reading them: **0 RCDIFF /
0 DIAGDIFF over the 1673 fixtures common to `main` and this branch**, 8 OUTDIFF (7
re-derived by Inc 2 + F-I2-3); **ZERO value-path `cqrt_cswap`** in the output of any
of the 1685 subject fixtures (the 6 that carry one are the 5 AbortParkEmit fixtures
plus `lowering_uncompute_interior_leak_unrecorded_route`, whose cswaps are
HAND-WRITTEN in its INPUT), `emitRoute` with ONE call site (`AbortParkEmit.cpp:396`);
`#cqrt_rz_i1 == #!cq.branchphase` in every accepting fixture, totals **263 = 263**,
and 0 of 135 marked fixtures carrying a mark off a `cqrt_rz_i1` call; all 16
value/switch-value fixtures `bp=0`; four twin gates re-derived BY HAND and PASSing;
11 Inc-2 slices reproducing their goldens byte-for-byte at STRICT 2b rc=0;
**injection matrix 15 accepts × 7 mutations = 15/15 controls clean, 0 NOT CAUGHT**;
and the red-green of the 12 subject-only fixtures against INC-1-ONLY holding (with
the two i128/qq declines discriminating by STRING, not by rc).

**The rebase's conflict table, in one paragraph** (§3.1 has the rows): the two
increments overlap in SEVEN files, of which only TWO conflicted — one include line
in `SwapRouteEmit.cpp` (both sides kept) and `control_swap_value_diamond_derived.ll`
(Inc-2 structure + Inc-1's migration note, then re-derived from the rebased binary).
The other five auto-merged and were verified BY INTENT, which caught two things a
clean merge cannot: `EmitInverse.cpp`'s cswap-seam prose named a retired emitter as
live, and `tests/e2e/slice_control_value_derived.c` **did not compile** under the
Inc-1 header. Faithfulness was checked by comparing changed-line counts before and
after the replay (identical for six of seven; the fixture 116 → 115, exactly the Rz
`CHECK` line whose source Inc 1 had already deleted).

### §4.7 — What `fix_inc2_r2` ran (only what it ran)

* Every measurement quoted in §4.1, §4.2, §4.4 and §4.5 was **re-run by the fix
  agent** on the three binaries through the full pipeline (stage 1 → 2 → **STRICT
  2b** → 3 → 4), not copied from the review. STRICT `free_pairing_check.py` rc=0 on
  every accepting lowering; no `--allow-unproven` anywhere.
* `ctest -R ir-pass-lit`: **PASS** (39.6 s). Direct `lit ir-pass/test`: **1687
  discovered, 1686 passed, 1 expectedly failed** (the standing
  `lowering_invert_add_i32.ll` XFAIL). Corpus 1685 → **1687** (the F-I2-7 pair).
* `ctest -j6 -R 'e2e-value-.*twin-identical|e2e-slice-control-switch-value|e2e-slice-control-value'`:
  **15/15 PASSED**, 26.5 s — the four `cmp` twin gates
  (`e2e-value-{diamond,ifelse,mixedops,polarity}-twin-identical`), the ten value
  slices, and `e2e-slice-control-switch-value`.
* **Injection matrix on the two fixtures this round wrote/re-derived** (7 mutations
  each, `$SP/progress/fix_inc2_r2_work/inject.py` — the lens's tool with `INPUT`
  skipped, since that prefix is checked against `%s` and not the lowered output):
  `lowering_switch_value_nonI32_cast.ll` **7/7 CAUGHT**;
  `control_swap_select_base_from_cond.ll` **6/7 → strengthened → 7/7 CAUGHT**.
* **Census over the three fixtures it touched** (the full-corpus census is the
  lens's, on a binary this round leaves byte-identical): `cqrt_cswap` **0**,
  non-i1 `cqrt_rz` **0**, `!cq.branchphase` **0** in all three outputs.
* **A mutation build and its revert** (§4.3), with `cmp` proving the tree restored.
* It did **NOT** run the full `ctest`, the loop-twin matrix, `frontend-lit`, the
  runtime entries, or the e2e suite beyond the 15 entries named above.
