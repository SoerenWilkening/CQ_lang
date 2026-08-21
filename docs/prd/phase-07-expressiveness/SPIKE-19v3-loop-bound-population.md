# SPIKE 19v3 — which libm cells does a compile-time-derived loop bound actually reach?

**Date:** 2026-08-21 · **Type:** measurement spike — **no pass change, no fixture, no
ruling** · **Tracker:** bd `19v3`; feeds bd `m57l` (implementation) and bd `eyhj`
(owner gate, ruling **confirmed by the owner 2026-08-21**).
**Predecessor:** `SPIKE-8zj2-ilogb-logb-loop-bounds.md` — 8 cells. This is the same
question over the **whole census surface**, with the **same instrument**
(`tools/library_coverage/loop_bounds/`), because the last time this family was scoped
without measuring, "4 cells" was wrong.

Every headline below went through an independent adversarial refutation round. **It
refuted or qualified six of them, including one real over-accept defect in this spike's
own instrument** — the same way 8zj2 found two in its. Those corrections are in the text,
not in a footnote.

---

> ## VERDICT
>
> **The bucket-(A) population is 2 cells: `ilogb.f64` and `ilogbf.f32`** — exactly bd
> `m57l`'s already-corrected scope. The spike's job was to find out whether the owner's
> "as many math.h/libm functions as possible" is bigger than that. **Measured, it is not.**
>
> Of 125 probed cells, **19 carry a loop** at the module the pass reaches, **13** decline
> with a loop as first blocker, **10** hit the specific Q1 gate `m57l` lifts — and only
> **5** first-block on a loop with a usable bound. Of those 5, only 2 have nothing further
> behind them.
>
> **Bucket (B) — derivable-looking but NOT total — is non-empty and was caught only by
> exhaustive enumeration.** `k_rem_pio2.c:404` (in `cosf`/`sinf`/`tanf`.f32) carries a
> constant trip bound of **4**; its sibling loops at `:310`/`:314` carry the *same* bound
> and are genuinely total. Remove `:404`'s one dominating guard — which PredMux
> demonstrably does — and the loop **does not terminate** on `%509 = -1`, and runs
> 4 294 967 295 times on `-2`. Nothing in the SCEV report distinguishes the three.
>
> **The bound derivation is the easy part and is already done. All three of `m57l`'s rail
> problems are confirmed on all 5 candidate cells, and a fourth is added here** (§4b): the
> loops contain **no classical bound anywhere in the IR** — B=33 is a SCEV bit-width
> inference with no IR counterpart — so `m57l`'s emitter can reuse none of the existing
> `tryBreak` bound machinery and must synthesize the counter, the bound and the exit.

---

## 0. Method, and what validates it

Real openlibm injection at the **`-O1` ship floor**; corpus verified at `@82e90ae` with
the README's required fingerprint **`409 []`** (`406` would mean step 1b's `lgamma`/`ldexp`
shims were skipped, and an under-linked corpus **under**-measures).
`build/ir-pass/libCQPass.so` was **never rebuilt**, by me or by any agent (mtime unchanged
throughout). Every SCEV number comes from the LLVM 19 API via the committed reporter.
**`cq-spike-excise` was never used** (bd `66rz`).

**Instrument validation (Rule 11), four independent legs:**

* The sweep recomputes each cell's census status and **reproduces `full_census_O1.json` on
  126/126 rows** — every status, every bucket, and all 21 decline diagnostics
  character-for-character.
* **Loop counts cross-checked against stock LLVM** `opt -passes='print<loops>'` over all
  375 stored modules × both SE flavours: **750 comparisons, 0 disagreements.**
* **Carving faithfulness:** the `spec`/`fp80` modules are carved out of the pass's stderr;
  an independent re-carve of all cells is **byte-identical in 125/125**, the discarded
  tail is empty or exactly the one error line, and `define` counts match `inl.ll` exactly.
* The peel instrument reproduces all 5 baseline declines character-for-character and has a
  **working positive control** (an injected `trunc i32 → i7` produces
  `no template for opcode 'trunc i7' in tainted context`).

> **Count correction.** "126 census cells" is the enumeration; **125 were probed**.
> `nexttowardl.f80` is `no-body` (openlibm ships no `s_nexttowardl.c` — bd `keol`), so it
> has no module at any point. It cannot become a loop cell under source injection, but
> every "of 126" below should be read as "of 125 probed".

### 0a. `CQ_FP80_DBG` is NOT far enough — measuring there over-counts by 14 cells

bd `19v3`'s trap list says to measure the module the pass sees and names `CQ_FP80_DBG`
(`CQLoweringPass.cpp:174`), because that is what 8zj2 used. **Measured, that point is too
early.** Three points were measured for every cell:

| point | what it is | line |
|---|---|---|
| `inl` | the census's own pre-lowering module | — |
| `fp80` | after the `promoteFp80Union` fixpoint (`CQ_FP80_DBG`) | :174 |
| `spec` | before `detectSpecializations` — **after** `flattenPredMuxRegions` **and** `unrollConstTripLoops` | :223 |

`lowerLoops` runs at **:279**.

**`inl` and `fp80` agree for all 125 cells** — `promoteFp80Union` changes no loop count,
generalising 8zj2's 4-cell check. **`spec` differs for 15 f80 cells**, and the difference
is large: 14 drop to **zero** loops (33 cells / 172 loops at `inl` → **19 cells / 76 loops**
at `spec`), and `tgammal.f80` drops 17 → 4.

Mechanism **attributed, not inferred**: `CQ_UNROLL_DBG=1` message counts match the
vanished loops exactly (`logl.f80` 4→4, `acoshl.f80` 12→12, `tgammal.f80` 17→13 leaving 4),
with a positive control that prints. It is `LoopUnrollPrepass` taking the `__polevll`
Horner loops.

> Measuring at `fp80` would have reported **14 extra loop-bearing cells** with no loop at
> all by the time `lowerLoops` runs — including two *declining* cells (`lgammal.f80`,
> `powl.f80`) that would have looked like loop targets. Both actually decline on
> `cq specialization: callee contains tainted control flow under quantum lift`.

### 0b. "The module the loop lowerer sees" is a counterfactual for 6 of the 19

This qualification came out of the refutation round and the headline must carry it.
`lowerLoops` (`LoopLowering.cpp:1532`) opens with `if (!AnyTainted) continue;` and never
builds `LoopInfo` for an untainted function; and `propagateWorklist` walks `V->users()`
only, so taint is **strictly intraprocedural** — a tainted call argument taints the
`CallInst`, never the callee's `Argument`. Measured: `@cq_theta` appears in `@probe` only,
in every one of the 19 cells. Therefore:

* `tgamma.f64` and `tgammaf.f32` — their only loop is in `@tgamma`, not `@probe`.
* `tgammal.f80` — its trip-33 loop is in `@powil` (0 `@cq_*` calls in the body).

**Under the reading "loops `lowerLoops` would examine", the population is 17, not 19.**
And separately: `opt` exits at the **first** `DS_Error`, decided by **stage order, not
source order** (demonstrated with a constructed two-decline module plus a positive
control), so for `cosf`/`sinf`/`tanf`.f32 (`declineTaintEscapes`, :244) and the three
`tgamma` cells (`detectSpecializations`, :235) **`lowerLoops` is never reached at all**.

**None of this moves the 13, the 5 or the 2.** It moves only how "19" may be described.

### 0c. The two ScalarEvolutions agree — as a null result, not a cleared risk

All 375 `pm` vs `passstyle` file pairs diffed raw: **192 differing lines, all 192 the
`=== function @…` banner, 0 substantive differences** — byte-level agreement across every
reported field, not just the two numbers the adjudicator compares.

> Two corrections. (i) `LoopBoundProbe.cpp`'s own comment said the pass builds a "DEFAULT
> (conservative) `TargetLibraryInfo`". **It does not** — it is triple-derived, the same
> Impl `TargetLibraryAnalysis` builds; the only real difference is the per-Function
> binding. Fixed in the source. (ii) Three attempts to construct a case where the two
> flavours *could* differ all failed, because SCEV's TLI reaches only the one-level
> `simplifyInstruction` in `createSCEV`. **So this is a null result with unestablished
> falsifying power.** 8zj2's 4-cell agreement was measured on the same near-identical
> pair, so "it generalises" joins two non-independent results.
>
> Do not quote this next to `report.txt`'s `cross-view disagreements: 15` — that line is
> cross-**module-point** (the Horner unroll), a different question. Both are true.

---

## 1. The population

| | cells |
|---|---|
| census rows / probed | 126 / **125** |
| **cells with ≥1 loop at `spec`** | **19** (76 loops) — 17 in a function `lowerLoops` would examine (§0b) |
| …declining with a **loop as first blocker** | **13** |
| …hitting **Q1**, the gate `m57l` lifts | **10** |
| …hitting `kMsgBreakMultiSite` instead | **3** (`fmodf.f32`, `fmodl.f80`, `remainderf.f32`) |
| …**first-blocking on a loop with a usable bound** | **5** |
| …**with no further loop behind it** | **2** |
| cells with loops but a **non-loop** first blocker | 6 |
| declining cells with **no** loop at `spec` | 2 (`lgammal.f80`, `powl.f80`) |
| COMPILES / exit0-spec cells with a loop at `spec` | **0** |

**The 13, by the gate they actually hit** — a grep for the Q1 string alone finds 10 and
silently mis-buckets 3:

| gate | cells |
|---|---|
| `cq controlled lowering: loop under quantum control` (Q1, `:1161`) | `fmod.f64` · `ilogb.f64` · `ilogbf.f32` · `ilogbl.f80` · `logbl.f80` · `remainder.f64` · `remainderl.f80` · `remquo.f64` · `remquof.f32` · `remquol.f80` |
| `cq loop lowering: multiple early-break sites` (`kMsgBreakMultiSite`, `:968`) | `fmodf.f32` · `fmodl.f80` · `remainderf.f32` |

Structurally corroborated beyond the string: for all 13, the diagnostic's `file:line:col`
resolves back to a `!DILocation` on a `br` that **is** the latch/exiting terminator of a
reported loop; and the contrapositive holds — neither declining cell with zero loops
carries a loop-named message.

**Scope cross-reference.** 17 of the 19 loop-bearing cells are already `decided-decline`;
the other 2 (`tgamma.f64`, `tgammaf.f32`) are `lever-gap` for a reason that is not a loop.
The entire loop population sits inside the owner-decided set that bd `eyhj`'s GO re-opens.

### 1a. The census surface itself has a blind spot — it can only grow "19"

The sweep faithfully reproduces the census's cell set, but that set omits injectable
`math.h` names. Parsing `OLM_DLLEXPORT` out of `openlibm_math.h`: 209 declared names, 41
neither a census cell nor keep-set. After removing macro helpers, `nan*` (by design) and
names absent from the corpus, what is genuinely unmeasured is **Bessel `j0 j1 y0 y1` +
f32**, **`lgamma_r`×3**, **`sincos`/`sincosl`** (no census shape for a void return with two
by-ref outs), and ~50 `<complex.h>` entries (outside `math.h` by construction).

The 11 corpus-resident ones were run through the sweep's own `run_cell`: the f64 Bessel
cells have **0 loops**; **`j0f`/`j1f`/`y0f`/`y1f`.f32 have 39 loops each**, contributing the
same `k_rem_pio2.c:310`/`:314`/`:404` shapes the trig cells already contribute.

**So "19" would be 23 and "6" would be 10 on a widened surface. "13" is unaffected, and
the bucket-A set acquires no new shape.** (That the Bessel `:404` behaves like the trig
`:404` is **inferred** from being the same inlined `__kernel_rem_pio2` body, not measured.)

---

## 2. The four buckets

Over all **76** loops, applying the **five-condition** test (constant ∧ non-negative ∧
small ∧ reachability-total ∧ `1 ≤ shift ≤ W-1`) rather than `isa<SCEVConstant>`:

| bucket | loops | |
|---|---|---|
| **(A) — usable AND total** | **16** | C4 **measured** by exhaustive enumeration, §2e |
| **(B) — usable-looking, NOT total** | **3** | `k_rem_pio2.c:404` × `cosf`/`sinf`/`tanf`.f32 — §3 |
| **vacuous constant** — the over-accept trap | **30** | a literal `SCEVConstant` that is unusable |
| **(C)/(D)** — `CouldNotCompute` | **27** | §2f splits these |

> **How 19 became 16, stated honestly.** The mechanical part of the test (C1–C3, C5) passes
> **19** loops, and `adjudicate.py` marks all 19 `NEEDS-C4` — it explicitly "never promotes
> one to bucket (A) on its own authority". An earlier draft of this memo cut 19→16 using
> *opacification survival*, which is the inversion `LoopBoundProbe.cpp` forbids in
> capitals. **The cut is now made by the C4 evidence in §2e/§3, which was measured for
> this memo.** The set is the same; the derivation was wrong and is corrected.

### 2a. The "small" cut is not a judgement call on this population

```
   4        cosf/sinf/tanf.f32   k_rem_pio2.c:310, :314, :404
  33        ilogb.f64 :40 :42 · ilogbf.f32 :35 · fmod.f64 + remainder.f64 e_fmod.c:54 :56
            · remquo.f64 s_remquo.c:62 :64 · tgammal.f80 e_powl.c:0
  ------------------------------------------------------------------- gap
  2147483644 / 2147483647 / 4294967295      (9 loops, all k_rem_pio2.c)
```

**Nothing sits between 33 and 2.1 billion**, so `small` separates identically at 64, 1000
or 10⁶. *(This is a property of this corpus, not of the condition — see §2d.)*

### 2b. What the five-condition test buys — measured, not argued

8zj2 found its two over-accepts on **one** cell. On the full population they are the
**majority of what a naive predicate accepts**:

| predicate | loops accepted (of 76) | over-accepts |
|---|---|---|
| `isa<SCEVConstant>` alone | **49** | **30** |
| `getSmallConstantMaxTripCount(L) != 0` | **40** | **21** |
| the five-condition test (C1–C3, C5) | **19** | — |

**The worst bound a naive recognizer would have used is 4 294 967 295 trips**
(`k_rem_pio2.c:372`). 61 % of `isa<SCEVConstant>`'s accepts here are wrong. The trap also
reproduced **live inside the instrument**: on an isolated `:404` with its guard removed,
the reporter prints `VERDICT bound-kind = CONSTANT (no SSA operand => value-independent)`
for a bound whose printed SCEV visibly contains `%q` and whose constant-max is 2⁶⁴−1.

### 2c. A third rendering trap: C2 is not independently meaningful

`getSmallConstantMaxTripCount` returns **4294967295** on `fmod.f64`'s vacuous bound (8zj2's
finding) **and 0** on other equally vacuous ones (`k_rem_pio2.c:399`, `:404`-outer,
`:412`). **Neither return value distinguishes vacuity, in either direction.**

The printed *sign* is width-dependent. The clean matched pair is **`fmod.f64`
`e_fmod.c:99` (i32) printing `-2` and `cosf.f32` `k_rem_pio2.c:372` printing
`4294967294`** — the **same APInt value**, same trip number `4294967295`, opposite rendered
sign at different widths.

> **Correction, from the refutation round.** An earlier draft paired `e_fmod.c:99` with
> `k_rem_pio2.c:399`. Those are **different values** (4294967294 vs 4294967295), so that
> pair did not demonstrate width-dependence; and the flat claim "an i64 vacuous bound
> renders as 4294967295" is **false** — a constructed i64 control renders `-2`. `:372` is
> the pair that actually proves it.

Live in the shipped adjudication: `cosf.f32` alone has **7 vacuous loops with `C2 = 1`**,
including `:372`, whose numerically identical twin in `fmod.f64` gets `C2 = 0`.

### 2d. …and "magnitude alone decides" is false in BOTH directions

An earlier draft concluded "only the magnitude of the constant-max BTC decides". **Refuted
twice**, both now committed as controls in `probes/opaque_control.ll`:

* **Not sufficient** — `@shift_width_poison`: the ilogb `shl`-until-sign idiom with shift
  amount **equal to the width**. Constant-max **32**, trip **33**: C1, C2, C3 all pass and
  the magnitude is perfectly small. `shl i32 %v, 32` is **poison** and the loop never
  terminates. Only **C5** rejects it — the word "only" wrote C5 out of the test.
* **Not necessary** — `@vacuous_narrow`: `i < n` at **i6**. The wrapped bound is 2⁶−2 = 62,
  so the trip bound is **63 ≤ 64** and **C3 "small" PASSES on a vacuous bound**. It is
  caught only by the i6 signed rendering `-2`, i.e. by C2.

**C2 fails at i64, C3 fails at i6; neither is a vacuity test alone.** They cover for each
other on this corpus only because every width here is ≥ 32. Wording that survives: *a
vacuous bound is detected by the unsigned magnitude of the constant-max BTC read as an
APInt **at its own width**, together with the shift-range condition; the printed decimal
and both trip-count return values are unreliable on their own.*

### 2e. C4 — the leg nobody had run — is now MEASURED, exhaustively

C4 (reachability-totality) was `NEEDS-C4` on all 19. It was measured by exhaustive
enumeration over **all 2³² start values**, on the **rotated** recurrence the pass sees
(8zj2 got a count wrong the first time by enumerating source semantics instead):

| shape | loops | recurrence | result |
|---|---|---|---|
| **A** | 9 (`ilogb`×2, `ilogbf`, `fmod`×2, `remainder`×2, `remquo`×2) | `%xs = shl nuw i32 %x, 1`, exit `icmp sgt %xs, 0` | **max 31 trips at `0x00000001`; count(trips > 33) = 0 of 4 294 967 296** |
| **B** | 1 (`tgammal.f80` `@powil`) | `%69 = lshr i32 %66, 1`, exit `icmp ult %66, 4` | **max 31 trips at `0x80000000`; count(trips > 33) = 0** |
| **C** | 2 (`k_rem_pio2.c:310`, `:314`) | literal start `0`, literal step `1`, literal limit `4` | **exact trip count 4, total by construction** |
| **(B-bucket)** | 3 (`k_rem_pio2.c:404`) | `zext(1 + smin(%509,3))` | **FAILS — §3** |

This is the **strong** form: the sweep is over *arbitrary* starts, so the bound survives
PredMux removing every dominating guard, and survives reading a poisoned `shl nuw` start as
any wrapped value. **33 is a valid over-approximation of a true max of 31.**

Independently, **poison flags** were stripped (`shl nuw` → `shl`, `lshr exact` → `lshr`)
across every bucket-A cell: every bound **unchanged at 32/33**. So "structural" rests on
the 2³² enumeration and the flag-strip, **not** on the opacification leg.

### 2f. Splitting (C) from (D) — a structural screen, not a totalization measurement

8zj2 **measured** totalization for exactly one shape (a mask-exhaustion exit on the f80
scan makes SCEV report `i32 31`). The 27 `CouldNotCompute` loops screen by exit shape:

| shape | loops | reading |
|---|---|---|
| register exhaustion, `icmp eq iN %reg, 0` | **13** | shares 8zj2's measured-totalizable shape: `s_ilogbl.c:38,:42` · `s_logbl.c:37,:41` · `k_rem_pio2.c:0,:321,:370` (×3) |
| shift-until-normalized, `icmp slt/ult %reg, 2^k` | **9** | the `fmod`/`remquo` normalize loops — **8zj2 §6b measured their bound to be GUARD-CONDITIONAL** |
| fp condition, no integer register to exhaust | **5** | `b_tgamma.c:201` (×2) · `e_tgammal.c:271,:277,:286` |

> **Do not read row 1 as "13 cells of bucket (D)"** — it says they share the shape, not
> that each totalizes. And row 2 is the important one: totalizing those 9 would *create* a
> bound for a loop that genuinely diverges on a basis state PredMux admits — i.e. it
> manufactures the bucket-(B) hazard rather than escaping it. `SCOPING-L3.md` §6 item 1
> proposes exactly that recognizer. `k_rem_pio2.c:321` has two exiting blocks (one `fcmp`,
> one `icmp eq`) and is the one row a different reading could move.

---

## 3. Bucket (B), reported loudly: `k_rem_pio2.c:404`

Source (`k_rem_pio2.c:403-406`), inner loop `for(fw=0.0,k=0;k<=jp&&k<=jz-i;k++)`, with
`jp = 3` at the `rem_pio2f` call site. The rotated form the pass sees:

```llvm
  %509 = freeze i32 %508                       ; jz - i
  %510 = icmp slt i32 %509, 0
  br i1 %510, label %.loopexit.i.i.i, label %511    ; <-- THE GUARD
511:
  %512 = call i32 @llvm.smin.i32(i32 %509, i32 3)
  %513 = add nuw nsw i32 %512, 1
  %514 = zext nneg i32 %513 to i64                  ; <-- trip register
515:
  %524 = add nuw nsw i64 %516, 1
  %525 = icmp eq i64 %524, %514
```

**Isolated to a single branch, by hand-edited variants re-queried through the same probe:**

| variant | constant-max BTC | trip |
|---|---|---|
| base | **3** | **4** |
| guard `br i1 %510,…` → `br label %511` | **−1** (2⁶⁴−1) | **0** |
| strip `nuw nsw`/`nneg` (poison flags only) | 3 | 4 |
| both | −1 | 0 |

**The bound rests 100 % on the dominating guard and 0 % on the poison flags** — so
flag-blinding would not have caught it either. Exhaustive enumeration over all 2³² values
of `%509` with the guard removed:

```
trip <= 4      : 2147483648   (exactly the q >= 0 half)
trip > 2^31    : 2147483647   (q <= -2; q = -2 gives 4294967295)
NON-TERMINATING: 1            (q = -1 => %514 == 0, the i64 equality never holds)
```

**C4 genuinely fails.** This is the R1 shape `QramLowering.cpp:703-708` exists to prevent,
except *branch*-conditional rather than poison-conditional. Its siblings `:310`/`:314`
carry the identical trip bound of 4, are entered by an unconditional `br label`, and have
literal start/step/limit — in a fact-free isolated context they keep a **literal** BTC with
zero SSA operands, which is fact-freeness rather than an opacification artifact.

> **Stakes, stated fairly.** `cosf`/`sinf`/`tanf`.f32's first blocker is **not** a loop —
> it is `cq taint escape: tainted value reaches an unsupported instruction`, and
> `lowerLoops` is never reached (§0b). A loop capability does not touch these cells today.
> Bucket (B) is reported loudly because a future recognizer — in particular
> `SCOPING-L3.md` §6 item 1 — would walk straight into it, and because it is the concrete
> proof that "constant, small, non-negative" is not enough.

---

## 4. What the capability would actually clear

### 4a. First blocker only

| cell | first-blocking loop | its bound |
|---|---|---|
| `ilogb.f64` | `s_ilogb.c:42` | **33 usable**; the other loop (`:40`) is usable too |
| `ilogbf.f32` | `s_ilogbf.c:35` | **33 usable**; the cell's only loop |
| `fmod.f64` | `e_fmod.c:56` | **33 usable**; `:99` vacuous, `:113` `CouldNotCompute` |
| `remainder.f64` | `e_fmod.c:56` | **33 usable**; `:97` vacuous, `:113` `CouldNotCompute` |
| `remquo.f64` | `s_remquo.c:64` | **33 usable**; `:108` vacuous, `:122` `CouldNotCompute` |
| the other **8** | — | **no loop in the cell has a usable bound at all** |

**Robust to line matching.** Three diagnostics point 1–2 source lines off their header (the
`for`/`while` statement vs the body — the offset 8zj2 recorded for `e_fmod.c:96` vs `:97`).
It changes nothing: for all 8 non-reached cells **every** loop is vacuous or
`CouldNotCompute`.

**Genuine static-K peels** (`cq-spike-peel`, body live, exit tests preserved; every
precondition `report_fatal_error`s so it cannot fabricate one):

| cell | peel | exit | after the peel |
|---|---|---|---|
| `ilogbf.f32` | `:35`, K=33 | **0** | **cleared** — 4296 gates, 34 `shl` sites, free-pairing 1161/1161 strict |
| `ilogb.f64` | `:42`+`:40`, K=33 | **0** | **cleared** — 9489 gates, 66 `shl` sites, free-pairing 2581/2581 strict |
| `fmod.f64` | `:56`+`:54` | 1 | `e_fmod.c:97` — another loop, **`multiple early-break sites`** |
| `remainder.f64` | `:56`+`:54` | 1 | `e_fmod.c:97` — same |
| `remquo.f64` | `:64`+`:62` | 1 | `s_remquo.c:106` — another loop, Q1 again |

> **Two corrections the refutation round forced.** (i) An earlier draft said the three
> `fmod`-family cells would have "only their FIRST blocker cleared" — **measured, two are
> cleared in each** (both 33-bounded siblings are in reach). (ii) It said they land "on a
> further loop that is vacuous or `CouldNotCompute`" — true for `remquo.f64` only;
> `fmod`/`remainder` land on a **qualitatively different** decline
> (`kMsgBreakMultiSite`), same stage, different sub-predicate.

**The blocker stack in `fmod`/`remainder`/`remquo` is exactly 4 loops deep and contains
nothing else.** Peel all four — unsound as a capability, two have no usable bound — and each
cell lowers clean, verify-clean, 0 residual `@cq_*`, strict free-pairing (`fmod.f64` at
K=33: 600 031 gates, 140 328/140 328). **No opcode, QRAM, fp or control layer is hiding
behind these loops.** Re-running SCEV on the peeled modules confirms the back two loops'
bounds are unchanged: peeling the front loops does not unlock the back ones.

> **What the peels do NOT establish.** Every free-pairing number above is for the
> **peeled/unrolled** circuit. `m57l` explicitly emits the loop **rolled**, which is a
> different circuit; none of these strict-clean results transfers to it. K=2 and K=33 give
> identical diagnostics throughout, so the peels bound the *depth*, not any emission.
>
> **⚠ Unreconciled discrepancy with `SPIKE-8zj2` §3b.** It records `ilogb.f64` at K=33 as
> "4584 gates, 34 `shl` gates, free-pairing 1239/1239". Here `ilogb.f64` needs **both**
> loops peeled to reach exit 0 at all (a one-loop peel declines at `s_ilogb.c:40`) and then
> measures 9489/66/2581; the recorded figures sit much closer to this run's **`ilogbf.f32`**
> row (4296/34/1161), and "34 `shl` gates" is 33+1, i.e. one loop's worth. Reproduced
> independently by two instruments here. 8zj2's peel script is deliberately uncommitted, so
> this cannot be resolved. **Do not quote 8zj2 §3b's `ilogb.f64` peel figures without
> re-measuring.**

### 4b. The escaping answer is a CLASSICAL COUNTER — and `m57l`'s stated mechanism is wrong

Taint was computed by a line-for-line mirror of `TaintPropagation.cpp:276-314`, **validated
5/5**: the mirror's first-tainted-exit loop predicts the shipped plugin's own recorded
diagnostic line for every quantum cell.

**Across all 9 quantum candidate loops: exactly one value escapes each, and it is CLASSICAL
in every one** — `add nsw <header-phi>, -1` seeded from a literal (`-1022`/`-1043`/`-126`),
with no `@cq_theta` in its cone. **Zero tainted values escape any of the 9**; the tainted
shift register's users are entirely loop-local. bd `m57l` note (3a)'s substantive claim is
**confirmed and generalised** from ilogb to the whole candidate set.

**But (3a)'s stated mechanism is measured-false on the real cells, and the correction makes
the problem worse, not better.** (3a) says the rejecting fence is `tryBreak`'s **(B2)** —
*"requires a TAINTED merge phi in the exit block … Here there is none"*.

1. **The exit block DOES carry a tainted merge phi, and (B2) would PASS, in all 5 cells.**
   `ilogb.f64`'s `%33` is the only phi in `ilogb.exit` and it **is** tainted — via a
   **non-loop** incoming (`%32 = add nsw %31, -1023`, `%31 = lshr i32 %6, 20`, the normal
   -exponent path). The loop's own incoming on that same phi is the classical counter.
2. **The fence that actually rejects is (B1)**, `decomposeFusedExit` (called at
   `LoopLowering.cpp:999`), whose own comment names this case: *"A bare tainted icmp (no
   fused classical bound — v5_qbound) … returns nullopt ⇒ NOT a break: leave it for L1."*
   All 9 exit conditions are a bare `icmp sgt i32 <shl>, 0`. *(Derived independently twice
   — by hand from `spec.ll`, and by the taint mirror.)*
3. **⚠ So (B2) is not a protective fence for these cells; (B1) is the only one.** If (B1)
   were relaxed, `emitBreakForward` would **not** be "handed nothing to copy" as (3a) says
   — it would be handed a phi the taint set marks TAINTED whose live value on the
   loop-exit path is the **classical counter**. *The taint bit on that phi is a union over
   paths, not a property of the loop's answer.* **That is a live over-accept shape and it
   belongs in `m57l`'s decline matrix.**
4. **A fourth structural blocker `m57l` does not name.** In all 9 loops the sole exiting
   terminator is entirely tainted — **there is no classical bound disjunct anywhere in the
   CFG**. B=33 is a SCEV bit-width inference with **no IR counterpart**. `tryBreak`'s whole
   partition presumes a classical bound exists to fall through to, so `m57l`'s emitter can
   reuse none of `decomposeFusedExit` / `boundComparesInductionToInvariant` /
   `hasFiniteClassicalTripBound`: it must **synthesize** the counter, the bound and the exit.

**X1 cross-iteration dirty rails: YES on all 9.** Each has exactly one tainted header phi
whose latch incoming is `shl nuw i32 <phi>, 1`; `shl` is deliberately excluded from
`inPlaceValueRailOperand` (`:128`, "information-LOSING"), so `peelInPlaceBase ≠ phi` and the
base is tainted — the `kMsgCrossIter` shape, satisfying neither L4(a) nor L4(b). *(X1 does
not fire today because Q1 runs first; it is what these loops hit the moment `m57l` lifts
Q1.)* The verdict is **discriminating, not blanket**: the *other*, non-candidate loops in
the `fmod` family do contain L4(a)-clean self-cycle phis.

**So all three of `m57l`'s rail problems are confirmed on all 5 candidate cells — plus a
fourth — while the bound derivation, the part the ticket budgeted least for, is done.**

### 4c. `tgammal.f80` belongs in no payoff count

Its trip-33 loop is a **genuine bucket-(A) member** (C1–C5 all met, C4 by the 2³²
enumeration above) — and it reaches nothing. Three independent reasons, each sufficient:

* It is the sole loop of **`@powil`**, a separate un-inlined function with **0 tainted
  defs** (as has its only caller `@stirf`), so `lowerLoops`'s `AnyTainted` gate skips it.
* Its exit condition `icmp ult i32 %66, 4` is **classical** — it is not a quantum-bounded
  loop at all in the module the pass sees.
* The cell's first blocker is not a loop and precedes `lowerLoops`. Identified to the
  instruction by attaching synthetic `!DILocation`s to `@stirf`'s entry allocas and
  re-running the unmodified plugin: it is **`%7 = alloca i32`, the `int *` out-parameter
  slot for `frexpl(x, &e)`** inside the inlined `powl` body — the by-ref axis (7.5 Shadow /
  `g387`), the same axis `lgammal.f80`'s `scope_ref` already names.

The loop is openlibm's binary-exponentiation `while(n){ ww*=ww; if(n&1) y*=ww; n>>=1; }`
(`e_powl.c:626-634`). Its `!dbg` line is **0** because rotation merged the preheader and
in-body `n >>= 1`; the true line survives on `!llvm.loop` as `e_powl.c:628`.

**Mechanism confirmed identical to ilogb's** by a 16-variant probe: it tracks the type
width exactly (i7→7 … i128→128), survives deleting the fp payload / entry guard / counter,
is invariant to the shift stride (1, 2, 16, 31 all report 32 while the true maxima are 31,
16, 2, 1), and dies on a data-dependent amount, on stride 0, and on `ashr`. **C5 is
load-bearing for `lshr` too**: stride 32 and 33 are poison and non-terminating, and SCEV
still reports 32.

> **Census correction.** `tgammal.f80`'s `scope_ref` says "the loops sit behind `stirf`".
> Half wrong: the `@powil` loop does, but the three `e_tgammal.c:271/:277/:286` reduction
> loops are in `@probe`, on the **other arm** of the tainted branch `q > 13.0`
> (`spec.ll:85-92`) — mutually exclusive with the `stirf` arm, not behind it.

---

## 5. Instrument defects found in THIS spike's own tooling

Recorded because 8zj2 found two in its own and this is the same discipline. All are fixed
or fenced in `LoopBoundProbe.cpp`; the counterexamples are committed as
`probes/opaque_control.ll` so the limits are reproducible, not merely written down.

1. **`cq-spike-opaque` printed SURVIVES after a NULL mutation.** The collector replaces
   only integer/fp values, so a bound resting on a **pointer**, an **object size**, or
   **`!range` metadata** is never touched. `@ptr_small` (8-byte alloca, pointer-compare
   exit) and `@global_range_bound` (in-loop load with `!range`) each hold a small
   non-negative constant bound passing C1+C2+C3 and reported SURVIVES after **zero**
   replacements. **Fixed:** an unmissable `*** NULL MUTATION … any SURVIVES verdict is
   VOID ***` banner now fires, verified on both.
   *Mitigating, and measured:* over the 76 loops there are **3** null mutations
   (`k_rem_pio2.c:370` ×3), all `CouldNotCompute`→`CouldNotCompute`. **No bucket-(A)
   result on this population rests on one.**
2. **A bare "survives" count is meaningless.** Of 76 loops, 43 "survive" — but **27 are
   `CouldNotCompute`→`CouldNotCompute`**, which any mutation or none produces. Only **16**
   had a real baseline bound to lose. Read off the probe alone, `ilogbl.f80` (whose bound
   8zj2 established *is* guard-conditional) and `ilogb.f64` are indistinguishable.
3. **The probe does not delete the entry guard; 8zj2's hand test did.** It is stronger on
   the value leg and weaker on the guard leg, so it does not "reproduce" that test.
   (8zj2 in fact ran the opacification leg on `ilogb.f64` **only**; `ilogbf.f32` was cleared
   structurally and the f80 pair by enumeration.)
4. **`opaque.json` is keyed by a non-unique `!dbg` string** and silently merges distinct
   loops (`cosf.f32` has 13 loops but 12 entries; the `:404` entry conflates a depth-1 and a
   depth-2 loop). No bucket-A loop shares a `!dbg`, so the result stands — but the artifact
   must not be quoted per-loop.
5. **`adjudicate.py`'s C5 screen is module-wide, not loop-scoped** — over-strict, the safe
   direction, and it passed for all 76 so it never bound a classification. The loop-scoped
   check was done by hand for every 33-bound candidate: all amount **1** at width **32**.
6. **The `TargetLibraryInfo` comment was wrong** (§0c) — corrected in source.

---

## 6. What this does NOT establish

* **Nothing was emitted, linked or run as a rolled lowering.** Per Rule 2 a green compile
  would not be evidence anyway. The peels model an **unroll**, which `m57l` explicitly
  rules out.
* **It does not show a predicated body would be correct.** C4 is the *precondition* for
  such a lowering, not evidence that one is sound. §4b measures three (now four) rail
  problems standing between the bound and an emission.
* **Everything is at `CENSUS_OPTLEVEL=O1` only.** The loop population is opt-level
  dependent by construction — the 33-cells-at-`inl` → 19-at-`spec` collapse is the proof —
  so these are claims about the O1 ship floor, not about the source.
* **The "no deeper layer" result is bounded by what a peel can expose**, and only for the
  5 cells peeled.
* **Bennett condition (i) is unmeasured for every cell here.** `/private/tmp/Bennett.jl`
  does not exist (not merely empty), so no CQ-PROVIDED scoping of this family is possible
  until it is restored. Nothing in this memo depends on it.
* **The two-SE-flavour agreement has unestablished falsifying power** (§0c).
* **The Bessel `:404` behaviour is inferred, not measured** (§1a).

---

## 7. Standing corrections this spike makes to the record

| record | correction |
|---|---|
| bd `m57l` note (3a) | the rejecting fence is **(B1)**, not (B2); the exit merge phi **is** tainted in all 5 cells; and relaxing (B1) exposes a **live over-accept** (§4b.3) |
| bd `m57l` scope | its 2-cell target is **confirmed** as the whole bucket-(A) population; the "flag lifecycle is the hard part" instinct is confirmed and understated — there are **four** rail problems |
| `SPIKE-8zj2` §3b | its `ilogb.f64` K=33 peel figures do not reproduce under two independent instruments here; **unresolved**, do not quote without re-measuring |
| `SPIKE-8zj2` §6c ("`fmodf.f32` does not hit Q1") | correct, and it is **3 cells**, not 1 — `fmodl.f80` and `remainderf.f32` too |
| bd `19v3`'s own trap list ("measure at `CQ_FP80_DBG`") | insufficient — `LoopUnrollPrepass` runs after it and removes 96 loops across 15 cells (§0a) |
| census `scope_ref`, `tgammal.f80` | "the loops sit behind `stirf`" is half wrong — 3 of its 4 loops are on the other arm of a tainted branch (§4c) |
| `SCOPING-L3.md` §6 item 1 | reconfirmed as a bucket-(B) hazard, now with a second worked example (`k_rem_pio2.c:404`) beside its own normalize loop |
| the census surface | omits Bessel ×8, `lgamma_r` ×3, `sincos` ×2 and ~50 `complex.h`; "19" would be **23** on a widened surface, "13" unchanged (§1a) |
