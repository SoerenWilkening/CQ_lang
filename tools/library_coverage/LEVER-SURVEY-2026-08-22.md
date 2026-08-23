# Coverage-lever survey — what is left to build, measured 2026-08-22

> **What this is.** A measured answer to *"what do we work on next to increase the
> number of compileable `math.h` functions?"* Every lever that could move the
> published headline was probed at HEAD `9dbce3f` against the live corpus
> (fingerprint **409 syms / 251 bc**, `CENSUS_OPTLEVEL=O1`,
> `BC=/tmp/bc OPENLIBM=/tmp/openlibm`), not read off the record. That distinction
> earned its keep: **two `SCOPE` entries cite a mechanism deleted in `ce069c6`**, and
> **three of the 100 injection-covered cells are measured against bodies openlibm does
> not build**.
>
> **What this is NOT.** A status page. Authoritative numbers live in
> `full_surface/full_census_O1.json` + `probe.mathh_union_scoreboard()`; authoritative
> scope lives in the `SCOPE` dict in `full_surface/full_census.py`. When this file
> disagrees with either, believe them and fix this file. Every figure here is
> **as-of 2026-08-22** and is deliberately date-stamped rather than silently restated.
>
> **Method.** Six lanes, each measuring one lever, each then handed to two adversarial
> verifiers whose brief was to refute rather than agree. Four of the twelve verifiers
> and the quantum-trip lane died on a session limit — see §6 for exactly what that
> leaves single-measured. Corrections the verifiers landed are folded in below and
> marked, because three of them reversed a lane's own evidence.

---

## 0. The answer, and the arithmetic

> **⚑ §2.2 HAS LANDED — 2026-08-23, bd `3c6m.63`.** The survey recommended sequencing
> it first and that is what happened, so the "today" row below is **superseded**: the
> published state is now **155/183 (85%) headline / 97/120 injection**. The `−3`
> measured exactly as predicted (`nextafterl.f80`, `nexttoward.f64`,
> `nexttowardf.f32`), with one thing the survey did not predict: **`nexttowardl.f80`
> was never a corpus gap either** — openlibm mints it by `strong_reference` from the
> same `src/s_nextafterl.c` the collision was hiding, so it moved `no-body` →
> `decline` and the `corpus-gap` row emptied. Whole-census A/B: **6 cells moved, 120
> byte-identical.** Everything below in §2.2 is left as written (it is the evidence
> that justified the work); the outcome is recorded in
> `full_surface/README.md`'s 2026-08-23 entry, which is authoritative.

**The live plan, after the owner deferred `fpclassify` on 2026-08-22 (bd `3c6m.65`),
with §2.2 struck through as DONE:**

| step | headline | injection (campaign) |
|---|---|---|
| ~~as surveyed 2026-08-22~~ | ~~158/183 (86%)~~ | ~~100/120~~ |
| **✅ faithful corpus (§2.2) — LANDED 2026-08-23** | **155/183 (85%)** | **97/120** |
| + bd `eur4` f32 trig leaves (§2.1) | 158/183 (87%) | 97/**117** (denominator only) |
| + `isnormal` (§2.3) | 159/183 (88%) | 97/117 (unchanged) |
| *(deferred)* `fpclassify` (§3) | *+1 → 160/183* | *unchanged* |

*(The `eur4`/`isnormal` rows are the survey's own arithmetic re-based onto the landed
`155`; they are **derived, not re-measured**, and each still owes its own measurement
at the time it lands.)*

Read the middle column as *"CQ compiles N of the 183 modelled `math.h` cells"* and the
right one as compiler progress, per the 2026-08-22 headline ruling (bd `fhas`)
conditions (a)–(c). **Nothing on this list moves the injection numerator upward.** The
only lever that ever could — the tgamma pair, ceiling `+2` — is measured dead in §4.1.

The honest summary: **under the current modelled surface and the standing rulings,
injection coverage is at its structural ceiling minus a couple of cells.** The remaining
live movement is `eur4` plus `isnormal`, and one correction owed in the other direction.

> **Note the sign of the whole board.** Once §2.2 lands, the *total* of every live lever
> is **+1 headline cell** and **−3 injection cells**. That is not a discouraging result
> to be worked around — it is the measured state, and the `−3` is the only item here
> that changes what the published number *means*. Sequence §2.2 first for that reason:
> shipping `eur4` first publishes `161/183` on a foundation already known to be off by
> three.

---

## 1. "Measured dead" does not mean "cannot do"

This survey uses *measured dead* to mean **buildable, but worth zero cells today**. It
is a cost/benefit verdict on a *lever*, never a capability claim about CQ. Four
distinct things get collapsed into "we can't" if this is not written down:

| kind | example here | what it actually means |
|---|---|---|
| **worth 0 cells** | tgamma pair (§4.1); `uwnw` in-clone switch (§4.2) | build it and the census does not move — the cells stay blocked behind further layers |
| **owner-ruled out** | the `fmod`/`remainder`/`remquo` nine; the Payne–Hanek six | scope, not physics. **Every `decided-decline` carries a named re-opening condition by construction** |
| **not a compiler fact** | ~~`nexttowardl.f80`~~ — **REFUTED 2026-08-23, this surface now has no member** | ~~there is no body to compile — openlibm ships no `s_nexttowardl.c`~~. openlibm **does** mint it, as `openlibm_strong_reference(nextafterl, nexttowardl)` at `src/s_nextafterl.c:80`; the corpus collision (§2.2) hid that file, and the ld80 twin has the alias commented out. The cell is now probed and **declines** like any other. The CATEGORY is still real and worth keeping — this is just a reminder that "upstream ships nothing" is a claim about the corpus recipe until you have checked it |
| **presentation choice** | bd `sj30` surface expansion (§4.3) | fully doable today with zero compiler work; it is the *percentage* that is unattractive, and that is an owner call |

The project's vocabulary has exactly **one** permanent category — the C-physics wall
(no-cloning / linearity / superposed-return non-injectivity), per the `3c6m` epic
charter. **Nothing in §4 is that.** Do not quote a §4 item as "impossible"; the census
axis note (bd `libm-census-scope-axis-2026-07-28`) makes the same point about
`decided-decline` and it applies here verbatim.

---

## 2. Do these

### 2.1 bd `eur4` — three f32 branchless trig leaves. **+3, the only clean win.**

Headline **158 → 161/183** (86% → 88%); CQ-PROVIDED **6/6 → 9/9**; injection
**numerator flat at 100**, denominator **120 → 117**. Quote the denominator shrink with
it or it is the retired `165/174` pattern in miniature — `eur4`'s own 2026-08-10 note
says so.

**There is no compiler blocker.** Candidate leaves written to scratch measured: `opt`
exit 0 with **empty stderr**, 0 residual `@cq_*`, `free_pairing_check.py` **strict**
(0 violations, 0 unproven), link exit 0, run exit 0. The census probe with the leaf
shimmed into the defmap returns `status='COMPILES', diag='surv:[]'` for
`sinf.f32`/`cosf.f32`/`tanf.f32`. Scoreboard delta confirmed by patching a scratch copy
of `full_census_O1.json` and re-running `probe.mathh_union_scoreboard()` →
`(161, 183, [injection 100/117, CQ-PROVIDED 9/9, …])`.

> ### ⚠ THE FINDING THAT CHANGES THE WORK — the f32 leaf is **NOT a retype**.
>
> A pure-`float` retype of `branchless/sin.c` **lowers, links, runs, passes
> free-pairing strict, and produces a clean deterministic golden** — and measures
> **1.93e9 ulp** wrong at |x|≤1e4 (300k-sample sweep vs host libm; 466 ulp at |x|≤100,
> 7.68e6 at |x|≤1e3). A 2-term Cody–Waite split of π/2 at float precision cancels only
> ~34 bits. openlibm's own float recipe — **reduce and evaluate in `double`, float in /
> float out** — measures **≤1 ulp out to |x|≤1.6e6** and lowers just as cleanly (it adds
> `cq_template_fpext_f32_to_f64` / `fptrunc_f64_to_f32`, both already in 5 committed
> goldens).
>
> **Nothing in the suite would have caught the bad one.** `grep -rln 'ulp' tools/ tests/`
> hits only prose in the leaf headers and census markdown — **zero mechanical checks**.
> `run_slice.sh:83` is a byte-diff against the golden, and the runtime is trace-only
> (`cq_measure` returns 0), so the golden pins the **gate stream and the classical
> literal operands, never a computed result**. This is Rule 2 ("verify-clean is
> necessary, never sufficient") relocated from the compiler into the leaf.
>
> **Ship the double-intermediate rendering, with a measured ULP sweep recorded in the
> leaf header.** The width-parity framing is also better that way: Bennett's
> SoftFloatLib is f64, so an f64 kernel with `fpext`/`fptrunc` at the boundary is a
> stronger condition-(i) footing than a genuine width parity-inversion.

**Gate wording is settled** (owner ruling 2026-08-10): "9 cells" is a **tripwire, not a
cap**; the ruling is per **stem** (sin/cos/tan already ruled) and condition (ii) is
mechanical and per **width** (`probe.cq_provided_cells()` — leaf + slice + golden +
whole-token ctest registration + `_leaf_in_sync`, all on disk). Authoring three real f32
leaves takes the row 6 → 9 legitimately with **no fresh per-spelling ruling**.
`probe.cq_provided_rejected()` today returns all five requirements unmet for each f32
spelling — none of them a code problem.

**Effort.** 9 new files (`branchless/{sinf,cosf,tanf}.c`, `tests/e2e/slice_branchless_*`
+ goldens), 3 `add_test` rows (ctest 253 → 256), a deliberate `full_census_O1.json`
regeneration, and — the largest line item — **~30 grep hits across 10 files that assert
"no f32 leaf exists", five of them inside generator strings** (`probe.py:404-405`,
`:410`, `:524`). Leave those and the README prints a computed "9/9 CQ-provided" beside
prose saying the three are rejected. **Rule 13 does not apply** (leaves are user source,
zero core modules touched). **Rule 19 gate 2 fires** at push.

**Two traps.** (a) `_leaf_in_sync` is a drift trap *by design* — the leaf and slice hold
two textual copies of one algorithm; do **not** factor the body into a shared header or
the cell silently demotes with reason `in-sync` while the row quietly reports 8/9.
(b) `full_census.py:152-158`'s three f32 SCOPE entries will **not** trip the stale check
(line 481 excludes `provider='cq'` cells) but will be emitted as `upstream_scope_ref`
still saying *"NO branchless leaf exists at f32"*. Silent, not loud — edit by hand.

**`eur4`'s own acceptance criteria is stale and self-contradictory**: it reads *"census
cells confirmed still declining (no scoreboard movement claimed)"*, which is false at
HEAD — `wprobe.build_defmap` (`:411-413`) auto-injects the CQ leaf the moment
`cq_provided_cells()` admits a spelling, measured. Its later 2026-08-10 note prices it
correctly. Resolve which text governs before starting.

### 2.2 The corpus collision — a **`-3`** measurement-integrity ticket ✅ **DONE 2026-08-23**

> **LANDED, bd `test_C_libtooling-3c6m.63`.** Injection **100/120 → 97/120**, headline
> **158/183 → 155/183**. Everything predicted below measured true; three things it did
> not predict are recorded in `full_surface/README.md`'s 2026-08-23 entry — (1)
> `nexttowardl.f80` was **not** a corpus gap (openlibm mints it by `strong_reference`
> at `src/s_nextafterl.c:80`, which the collision hid, so it moved `no-body` →
> `decline` and its diagnostic is byte-identical to `nextafterl.f80`'s); (2)
> `remainderl.f80`/`remquol.f80` changed **bucket** (`loop-carried` →
> `memory-store (Shadow)`), which falsifies the `9/9 have a loop SCEV cannot bound`
> evidence line for two of the nine while leaving the ruling itself intact; and (3)
> the `<machine/ieee.h>` shim is **retired** — it only ever existed to build the two
> ld80 files openlibm does not build, and both `src/` bodies compile cleanly under the
> plain flag set. The recipe is now `full_surface/build_corpus.py`, and trap (b) is
> closed by a new ctest gate, `e2e-census-slice-sync`.

**Not a lever. A defect in the number**, and it should land before anyone quotes 100
again. Tracked as bd `test_C_libtooling-3c6m.63`.

The corpus recipe (`full_surface/README.md` "Reproduce") globs
`$OLA/src/*.c $OLA/bsdsrc/*.c $OLA/ld80/*.c` into `bc/$(basename ${c%.c}).bc` with
**`ld80` last**, so the **10 basenames present in both `src/` and `ld80/`** resolve to
the ld80 body — which **openlibm's own build excludes**. Verified independently:

```
s_nextafterl.bc   source_filename = ".../ld80/s_nextafterl.c"
s_nexttoward.bc   source_filename = ".../ld80/s_nexttoward.c"
s_nexttowardf.bc  source_filename = ".../ld80/s_nexttowardf.c"
s_truncl.bc       MISSING  (the ld80 build fails and destroys the src output slot)
```

against `openlibm/CMakeLists.txt:174/297/307/309` naming `src/` for every one, and
`ld80/Make.files:8-9` having them **commented out**.

**Measured effect of rebuilding the five collided *covered* cells from `src/`:**
`hypotl.f80` and `modfl.f80` unchanged; **`nextafterl.f80`, `nexttoward.f64`,
`nexttowardf.f32` all flip `COMPILES` → `decline`.** Injection **100/120 → 97/120**,
with no offsetting `+1` (`nexttowardl` still declines). Attribution is clean — the
`src/` variants of `s_nexttoward.bc`/`s_nexttowardf.bc` declare only llvm intrinsics, so
each flip is its own body, not a cross-effect.

> **Sharpest consequence.** `nexttowardf.f32` is one of the campaign's own recent `+1`s
> (bd `k710`, 2026-08-10, `97 → 98`). That clearance rests on the **store-only**
> `volatile float u = x*x;` at `ld80/s_nexttowardf.c:63`, cleared by the fenv ruling.
> The two files are genuinely different implementations, and `src/`'s scalar is
> `volatile float t` which **is read** (`t = x*x; if(t==x) return t; else return x;`) —
> a **live** value, not the store-only idiom. **The k710 `+1` does not reproduce on the
> body that ships.**

**No shipped gate sees any of this.** The README preflight (`251 .bc → 409 syms`,
missing-list empty) passes on **both** corpora — the faithful one is 410. This is the
retired `165/174` error class in a new place: **a number measuring a program that ships
nowhere.**

**A standing memory is now refuted for this gap.** bd `census-corpus-ieee-shim-tegx`
(2026-07-27) concluded in bold that *"a corpus fix moves no cell across compile/decline,
it only tells the truth about WHY"* — true of the **missing-TU** gap it measured
(`fmodl`/`remquol` needing `machine/ieee.h`), **false** of the **collision** gap: this
one moves 3. It also asserts *"s_truncl is NOT needed: truncl resolves from
src/s_truncl.c"*, which is false on the shipped corpus where **no `s_truncl.bc` exists at
all** (no census cell moves — `truncl` is recognition keep-set — but the memory is
stale). Anyone sizing this question by searching "corpus" finds `tegx` first and gets
the wrong answer.

**Two traps.** (a) Do **not** "fix" `nexttowardl` by shimming its alias onto the ld80
body — that manufactures a `+1` out of source that ships nowhere. The alias really is
`openlibm_strong_reference(nextafterl, nexttowardl)` at **`src/s_nextafterl.c:80`**,
which the collision hides. (b) A corpus swap **silently desynchronizes**
`tests/e2e/slice_libm_real_nextafterl.c` (header line 2 vendors the ld80 body) from its
census cell **without turning any test red** — the same silent-planning-miscompile shape
`check_scope()` exists to catch, one level up.

### 2.3 `isnormal` — **+1**, small and self-contained

Tracked as bd `test_C_libtooling-3c6m.64`. Headline → 159 (with §2.1, 162); macros
**10/12 → 11/12**. Injection untouched.

> **One question travels with this ticket now that §3 is deferred.** `fpclassify`'s
> decision (3) — *is the type-generic macros row compiler-progress-bearing?* — is not
> `fpclassify`-specific. This cell also needs genuine compiler work (Rule 12 + Rule 13 +
> Rule 19 gate 5) and also moves **only** the macros row, so under headline ruling (c) it
> is real work that the campaign number cannot express. Decide that before shipping, not
> after: the alternative is a changelog line claiming coverage progress for a row the
> ruling says does not carry it.

**The recorded reason is a mislabel.** `isnormal` expands to
`@llvm.is.fpclass.f64(double, i32 264)` — an **LLVM intrinsic**, not a library call,
with **no injectable body anywhere**. `264 = fcNegNormal|fcPosNormal = fcNormal`. The
census records *"library function — source-injection required (Rule 18)"* because
`probe.py:964` maps the pass's generic `unknown callee` string into the library bucket,
and that string cannot distinguish an intrinsic from a libc symbol. `-fno-builtin` does
not help, and hand-writing the un-macroed conjunction is re-folded by instcombine to the
same intrinsic — **no source-level workaround exists; it must be a pass-side rewrite.**

**Both candidate expansions were measured to lower today**: the bit form
(`bitcast f64→i64`, `and 0x7FFF…`, `icmp uge`, `icmp ult`, `and i1`) and the fp form
(`llvm.fabs` + `fcmp oge` + `fcmp olt` + `and i1`), each `opt` exit 0.

**Shape**: a narrow `is.fpclass` expansion prepass, curated to the one mask this surface
produces (264) and loud-declining every other `FPClassTest`. A general 10-bit decoder is
a **verify-clean wrong predicate** neither the golden byte-diff nor
`free_pairing_check.py` can witness — both would see a self-consistent stream. Mirror
`IntrinsicLowering.cpp`'s exact-ID discipline. Register it in the peephole slot beside
`foldIdentityBitcasts` / `promoteVolatileScalarLocals`, **before** `declineTaintEscapes`;
it mints tainted SSA from a tainted operand so it needs the re-propagate fixpoint, not
the no-re-propagate bitcast-fold pattern. Rule 12 + **Rule 13** + Rule 19 gate 5 apply.

**Doctrine footing — use the right authority.** The on-point precedent is the shipped
`CtlzIdiomPrepass` and the owner ruling quoted at `ir-pass/include/CtlzIdiomPrepass.h:11-13`
("Rule 18's axis is WHOSE SOURCE, and structurally rewriting…"). It is **not** bd
`bennett-grounding-asymmetry-2026-07-28`: that memory's decomposition clause is
explicitly scoped to an **injected body**, and its stated contrast case (`fmod` folding
to an in-grid `frem` with no injectable body left) is structurally what
`llvm.is.fpclass` is here. Rule 18 condition (2) is **in play**, not bypassed.

**Refuse the tempting harness-only "fix"**: `openlibm_math.h:124-127` defines
`isnormal(x) → __isnormal(x)`, and `/tmp/bc/s_isnormal.bc` has a body that injects and
lowers **clean**. That measures a **different program** than the one a user with the
system `<math.h>` compiles.

---

## 3. DEFERRED — `fpclassify`

> **⏸ DEFERRED by owner ruling 2026-08-22** (*".65 is future work and therefore
> deferred."*), tracked as bd `test_C_libtooling-3c6m.65`, status `DEFERRED`. This
> section is **not an open question awaiting an answer** — the three decisions below are
> deliberately not being made now, and no compiler work should be scoped against this
> cell until they are. It is kept in full because the measurement is expensive to redo
> and the decisions are exactly what a future session would otherwise re-derive.
>
> **What survives the deferral.** Decision **(3)** — *is the type-generic macros row
> compiler-progress-bearing?* — binds **§2.3 (`isnormal`) too**, because that cell also
> needs genuine compiler work and also moves only the macros row. Deferring this ticket
> defers decisions (1) and (2), which are `fpclassify`-specific; it does **not** dispose
> of (3). Answer it when `isnormal` is picked up.
>
> **Re-measure before acting.** The PredMuxFlatten witness asymmetry below is a live
> source fact a future PredMux touch may change, and the three differentials were run at
> HEAD `9dbce3f`.

### `fpclassify` — **+1** (→ 160/183, on top of §2.1 and §2.3)

Tracked as bd `test_C_libtooling-3c6m.65`. Unlike `isnormal` it **is** a real call
(`@__fpclassifyd`, `SDK …/math.h:139-147`) and openlibm **does** ship an injectable body
(`src/s_fpclassify.c`, `/tmp/bc/s_fpclassify.bc`, zero undefined syms). **Injecting it
still declines**, identically at O1/O2/O3:

```
error: /private/tmp/openlibm/src/s_fpclassify.c:38:6: in function probe i32 ():
       cq controlled lowering: value-arm swap-route under quantum control
```

**Root cause isolated to one line by three differentials.** (1) Inserting a *dead*
identity tainted diamond into one arm — selects untouched, no value change — flips the
module to **exit 0**, fully lowered, `free_pairing_check` "11 verified, 0 violations, 0
unproven". (2) Replacing the two arm `select`s with plain `ConstantInt` incomings makes
the **same** switch accept via the 4.5 data-mux. (3) Respelling the selects as nested
tainted diamonds also accepts. So the flattening machinery already handles this region
and **only the claim witness is missing**: `PredMuxFlatten.cpp:2131`'s switch-rooted arm
has **2** witnesses (`Claim = NestedTainted || ClaimableRead`) where the br-rooted arm at
`:2484` has **7** — including `NumMergePhis == 1 && SolePhiIncomings > 2`, which this
merge (1 phi, 3 incomings) satisfies but cannot reach.

> **That asymmetry is unticketed.** bd `ih70` item (3) files a *different* switch gap
> (the W6 stranded-cond-phi). What legitimately transfers from `ih70` is only its warning
> that the anti-overlap argument must be re-derived against the 4.5 G-ladder — and
> `ih70`'s "do NOT land standalone" note is scoped to its hygiene items (a)–(e), **not**
> to this; implementing the witness *is* the "real reason" that note anticipates. Budget
> the inherited (a)–(e) hygiene on top.

**Three decisions, all owner calls, none developer discretion:**

1. **FP_\* encoding mismatch.** Apple's codes (`FP_NAN=1, FP_INFINITE=2, FP_ZERO=3,
   FP_NORMAL=4, FP_SUBNORMAL=5`) disagree with openlibm's
   (`0x01/0x02/0x04/0x08/0x10`) on four of five. Injecting openlibm's `__fpclassifyd`
   under the system `<math.h>` compiles a program whose returned class code does not
   match the user's constants — **covered while computing a different function**. The
   `slice_libm_real_*` pattern avoids this by vendoring and renaming to `olm_*`; the
   census probe calls the symbol directly.
2. **Bucketing.** Macro row, or a census cell? As a census cell it is injection
   `100/120 → 101/121` and macros `10/12 → 10/11` — **same 159 total**, but it moves the
   injection **denominator**, which is the edit class the `165/174` lesson is about.
   *(Off the 2026-08-22 baseline; on the landed §2.2 one it reads `97/120 → 98/121`. The
   point — a `+1` that moves the denominator too — is unchanged.)*
3. **The doctrine tension underneath both macro cells.** Headline ruling (c) says the
   campaign number is the injection row alone because rows (1) and (3) move without
   compiler work. **The macros row does not fit that description** — both these cells
   need genuine compiler work and move only that row. Either the macros row is
   compiler-progress-bearing, or this work is real and uncountable.

Also note: the harness half is real but secondary — `probe.py::probe_cell` has **no
injection stage at all**, and `full_census.py:517`'s `if "macro" in spec["flags"]:
continue  # not a real call` is **factually false** for `fpclassify` on this target.
So this is **not** harness-only; it needs both halves.

---

## 4. Measured dead — buildable, worth zero cells

### 4.1 The tgamma pair — the census's only `lever-gap`, and it moves **0**

Ceiling if *everything* were cleared: **+2** injection numerator (100 → 102, headline
158 → 160), measured by counterfactual. Cost: multi-session, Rule-13, touching **four of
the seven** modules Rule 13 names. **Four layers, three measured here for the first
time:**

| layer | measured diagnostic |
|---|---|
| 1 | `large_gam { double, double } (double)`: fp/aggregate return has no reversible copy — `SpecializeReject.cpp:564-571` |
| 2 | `__log__D { double, double }` — the **same gate, a second site** |
| 3 | `tgamma` self-recursion at `b_tgamma.c:310` (`kMsgRecursion`) — **first measurement** of a layer bd `8zi1` had only inferred, and it confirms the line is **:310**, not :309/311/313 |
| 4 | clone `__cq_q_tgamma_1` still **95 blocks / 49 condbr** after `lowerCloneControl`'s `claimAll` fixpoint → `Clone.size() != 1` backstop. **Still declines** after additionally excising the `b_tgamma.c:200` loop back edge *and* neutralizing all five inner calls — so the flatten failure is the whole-body CFG |

Layers 2–4 were revealed by **labelled, non-semantics-preserving IR surgery** (return-type
rewrites, self-calls → `fmul`, back-edge excision). Every diagnostic quoted is literal
`opt` stderr, but **the pass never ran on the real body past layer 1**. The surgery only
ever *removed* difficulty, so the conclusion errs conservative — quote these as "measured
on a structural probe", never as "what the pass will emit".

**The gate fires on aggregate-ness, not fp-ness** — a callee returning `{i32,i32}`
declines with the identical `kMsgFpAbi` message, because `abiWidthFromType`
(`OpcodeSupport.cpp:230-264`) handles only integers and scalar fp and returns `{}` for
any struct at `:263`. Any future widening must partition on **element types**, not on
"is it fp". And **no stock LLVM 19 pass splits the struct return** — six pipelines
measured (`scalarizer`, `sroa`, `argpromotion`, `ipsccp`, `default<O3>`, and a composite),
all leave `aggdefs=2 / extractvalue=4` intact. This must be CQ-side work.

Layer 4 is additionally gated on doctrine: the `b_tgamma.c:200` exit is
`fcmp ogt`, which `boundComparesInductionToInvariant` (`LoopLowering.cpp:381`)
structurally cannot read (`dyn_cast<ICmpInst>`), and **clones get no loop lowering at
all** — `Specialization.cpp` has zero references to `lowerLoops`.

> **Verifier corrections, both against the lane's own framing — carry these, not the
> originals.**
> - **The yardstick was false.** The largest body `lowerCloneControl` has flattened is
>   **not** `@log` at 22/11 loop-free; it is **`@expl` at 36 blocks / 19 condbr WITH 2
>   `!llvm.loop` markers** (`coshl.f80`, clone `__cq_q_expl_1`, `opt` rc=0). A
>   loop-marked body **has** been flattened. The directional point survives — 95/49 is
>   still ~2.6× the true ceiling — but the "nothing that big, and never with a loop"
>   framing overstates.
> - **`__log__D` is not new.** bd `8zi1` item 5 names it, its `{double,double}` return,
>   its `mathimpl.h:68` definition and its IR 51/757 callsite — and reads it as
>   **upside** ("the lever clears ≥3 sites, not one"). What *is* new is only that the
>   **census `scope_ref` omits it**.
> - **The customer set is a lower bound, not an exact 2.** `wprobe.py:551` breaks on the
>   first error and `full_census.py:397` states the doctrine verbatim — every recorded
>   diagnostic is a **first blocker only**. "No other cell is blocked on the aggregate
>   gate" is only supportable as "no other cell is blocked **first**".

**Record fix owed** — see §5.1.

### 4.2 `powl.f80` / `lgammal.f80` / `tgammal.f80` — 0 cells, and two records are wrong

**`powl.f80` and `lgammal.f80` have the *identical* first blocker**, re-measured at HEAD:

```
/private/tmp/openlibm/src/s_frexpl.c:45:2 : cq specialization:
callee contains tainted control flow under quantum lift
```

`s_frexpl.c:45` is `switch (u.bits.exp) {` — a **tainted switch inside a lifted Phase-6
clone** (`SpecializeReject.cpp:590-594`, `kMsgInBodyControl`), i.e. bd `uwnw`, open and
unbuilt. They differ only in the enclosing function (`frexpl` vs `logl`, where `frexpl`
is inlined — 0 `define @frexpl`, blocks named `frexpl.exit*`).

**This refutes `powl.f80`'s recorded ground**, which says *"by-ref out-param under
specialization = the g387/7.5 Shadow axis"*. The by-ref stores are **layer 2**
(`SpecializeReject.cpp:747-752`), not the first blocker — and **`g387`'s
`lowerByRefMath`/`isByRefMathCall` were deleted in `ce069c6`** ("retire libm
name-recognition"); only two stale comments survive at `ByRefInline.cpp:7,301`.

`tgammal.f80` is right **in kind** (an `alloca i32` = the `frexpl(x,&e)` out-param slot,
falling to the catch-all at `:912` since `grep -n Alloca SpecializeReject.cpp` returns
zero hits) but its recorded SSA name `%7` is **pre-`promoteFp80Union` numbering**; post
promotion `@stirf`'s entry block opens with exactly `%2 = alloca i32 / %3 = alloca i32`.

> **The "one shared capability" premise is REFUTED.** These need **three** different
> capabilities — in-clone switch (`uwnw`), in-clone scalar-alloca/by-ref memory (**no
> ticket exists**), and in-clone loops — and `Specialization.cpp` calls **none** of
> `lowerLoops` / `lowerShadowMemory` / `lowerByRefInline`. The clone body gets only
> `lowerCloneSelect` (`:248`), `lowerCloneControl` (`:471`),
> `lowerQramReads(inBennettClone=true)` (`:937`), `lowerOps` (`:943`) and
> `emitBennettWrap`. The Shadow origin walk rejects a scalar alloca outright
> (`QramLowering.cpp:319-321`, "VLA / scalar alloca — no compile-time shape"), so wiring
> it up is **not** a wiring job.

Building `uwnw` clears layer 1 of two cells and moves **0**. That is a **deduction**
from two measured facts (the post-promotion `@frexpl` carries 1 switch and exactly 3
`store i32 …, ptr %1`; `SpecializeReject.cpp:747-752` rejects every `StoreInst`
unconditionally), not a probe of a post-`uwnw` pass — none can exist while `uwnw` is
unbuilt. For `lgammal.f80` it is weaker still: `@logl` carries 4 allocas / 1 switch / 4
`!llvm.loop` refs, so *a* deeper layer certainly exists but **which gate fires second is
genuinely unmeasured**.

### 4.3 bd `sj30` surface expansion — doable today, but the number goes down

Measured, not predicted. Option (b) (POSIX/GNU: Bessel + `sincos` + `lgamma_r`) buys
**+3 cells for +14 denominator**:

- headline **158/183 (86%) → 161/197 (81.7%)**
- injection **100/120 → 103/134 (76.9%)**

*(Both computed off the 2026-08-22 baseline, which §2.2 has since moved to 155/183 and
97/120. The **deltas** — +3 cells for +14 denominator — are what this section is about
and they are unchanged; re-base before quoting the absolute figures.)*

And all three movers are thin. **Two are double-counts in all but name**:
`lgamma_r.f64` / `lgammaf_r.f32` measure **byte-identical status and byte-identical
surviving-callee list** to the already-counted `lgamma.f64` / `lgammaf.f32`, because
openlibm's public `lgamma` **is** `lgamma_r(x,&signgam)` (the corpus's own
`lgamma_public_shim.bc`). The third rests **entirely** on CQ's leaves: `s_sincosl.c:27-31`
is literally `*s = sinl(x); *c = cosl(x);`, and on an upstream-only defmap the cell
declines at `ld80/e_rem_pio2l.h:141:9`.

All **8 Bessel cells decline**: f64 at `e_j0.c:288:6` / `e_j1.c:282:13`, f32 at
`k_rem_pio2.c:310:54`. `jn`/`yn`/`sincosf` are absent from the shipped defmap (build
failures: undeclared `j0`…`y1f`; undeclared `M_PI_2`) — both **cheaply recoverable**
(measured rc=0 with a 4-line `-include` prototype header, and with the recipe's existing
`-DM_PI_2` respectively), and both still decline once recovered.

**The lane's real find**: the six f64 Bessel cells all block on `pzero`/`pone` selecting
**one of four constant coefficient tables** by tainted comparisons — a 3-way pointer phi
feeding a load, which a constructed control reproduces as
`cq QRAM access: pointer resolves to multiple array origins`
(`QramLowering.cpp:346`, `kMsgQramMultiOrigin`). **That capability has ZERO customers on
the current 183-cell surface** — scanning all 126 census cells for a diagnostic
containing "origin" returns the empty list. It is the bd `m57l` *fence-with-no-customer*
shape again: the lever and the expansion are a package, and the package is still
net-negative on the published percentage.

Two riders. Seven of the eleven declines block on the **identical instruction** as
`sinf`/`cosf`/`tanf.f32` (`k_rem_pio2.c:310:54`), so §2.1's leaves have a larger
downstream population **if** the surface is ever widened — but say **≤6**, not 7
(`sincosf.f32` inlines its own kernel and never calls `sinf`/`cosf`), and what those land
on next is **unmeasured**. And `complex.h` really is `{ double, double }` in IR (`cexp`,
`ccos`, `clog`, `cpow`, `conj`) — the **same aggregate-return axis as §4.1** — but 12 of
the 60 spellings return plain `double`, **no complex cell was probed**, `_Complex` is
outside `cq_theta`'s source set (`SCOPED-CANDIDATES.md`), and the Bennett-parity check
`sj30` requires is **unmeasurable** (checkout absent when last measured, 2026-08-22).

### 4.4 `nexttowardl.f80` — not compiler work

openlibm ships no `s_nexttowardl.c` at any width. The symbol exists only as
`openlibm_strong_reference(nextafterl, nexttowardl)` at **`src/s_nextafterl.c:80`** — a
`.set` alias the corpus collision (§2.2) hides. See §2.2's trap (a): do not manufacture a
`+1` from it.

---

## 5. Record fixes owed

`check_scope()` is the Rule-12 analog for the `SCOPE` table, but it tests **membership
and labels only** — it provably cannot see a stale *reason*. All four items below are
invisible to it.

### 5.1 `tgamma.f64` / `tgammaf.f32` still carry `scope: lever-gap`

`lever-gap` is defined at `full_census.py:105-106` as *"A real capability we could build
that WOULD move this cell. \*\*\* THIS IS THE ACTIONABLE SET. \*\*\*"* — twelve days after
bd `8zi1`'s owner ruling of 2026-08-10 (*"REUSABLE CAPABILITY, 0 CENSUS CELLS,
DEPRIORITIZED … parked BEHIND bd k710"*). **bd `k710` has since closed**, and `8zi1` was
never revisited. Consequence: the census's own `ACTIONABLE LEVER GAP: 2 cell(s)` banner
is pointing at work the owner already parked. Tracked as bd `test_C_libtooling-3c6m.66`.

### 5.2 Three `SCOPE` grounds cite a retired mechanism

`powl.f80` (refuted outright, §4.2), `tgammal.f80` and `lgammal.f80` all rest on the
`g387` by-ref axis, whose implementation was **deleted in `ce069c6`**. Tracked as bd
`test_C_libtooling-3c6m.66` alongside §5.1.

### 5.3 Stale bd memory: `census-corpus-ieee-shim-tegx`

Two claims now false — *"a corpus fix moves no cell across compile/decline"* (refuted for
the **collision** gap: it moves 3) and *"s_truncl is NOT needed: truncl resolves from
src/s_truncl.c"* (no `s_truncl.bc` exists on the shipped corpus at all). Updated in place
2026-08-22.

### 5.4 `probe.py:964` mislabels intrinsics as library functions

Any `unknown callee` decline is reported as *"library function — source-injection
required (Rule 18)"*, which is wrong for `isnormal` and for any future intrinsic-shaped
cell. Folded into bd `test_C_libtooling-3c6m.64`.

---

## 6. What was NOT measured — read this before trusting a gap

- **The quantum-trip-loop lane (bd `eyhj` / `m57l`) did not run** — it died on a session
  limit. `CLAUDE.md` already records its payoff at HEAD as **zero cells** (both intended
  customers, `ilogb.f64`/`ilogbf.f32`, were taken by `ww4c`'s `CtlzIdiomPrepass`
  instead), but that is **the record, not a fresh measurement**. The `fmod`/`remainder`/
  `remquo` nine and the Payne–Hanek family were likewise not re-probed this round.
- **§2.1 (`eur4`) is single-measured.** Both its adversarial verifiers died on the same
  limit. It was measured end-to-end — leaf authored, lowered, free-pairing-checked,
  linked, run, census flipped, scoreboard patched — which is stronger than most, but it
  has had no refutation pass.
- **§2.2's `-3` was verified**, and the verification is what raised it from `-1`: the
  original lane measured 1 of the 5 affected cells and left 4 unmeasured. Do not quote
  `-1`.
- **No full `ctest` was run** by any lane (forbidden by the brief). Every "this change
  keeps the suite green" claim in §2/§3 is **unmeasured**.
- **Bennett condition (i) is unmeasurable** — the checkout is absent on this box, matching
  `CLAUDE.md`'s 2026-08-22 note. Do not re-assert it as checked anywhere in §2.1.
- **Layers 2–4 of §4.1** and the deeper layers of §4.2 are structural-probe results and
  deductions respectively, never pass verdicts on the real body.

---

## 7. Reproducing any of this

```bash
# scoreboard (the headline + its mandatory composition)
python3 -c "import sys;sys.path.insert(0,'tools/library_coverage');\
import probe;print(probe.mathh_union_scoreboard())"

# one census cell, with the diagnostic and its source line
BC=/tmp/bc OPENLIBM=/tmp/openlibm CENSUS_OPTLEVEL=O1 \
  python3 tools/library_coverage/full_surface/dump_ir.py <fn>
#   NB dump_ir.py hardcodes default<O2> at line 32 — override it to honour
#   CENSUS_OPTLEVEL, or you are not measuring the O1 baseline.

# corpus provenance (the §2.2 collision)
/usr/local/opt/llvm@19/bin/llvm-dis -o - /private/tmp/bc/<file>.bc | grep source_filename
```

The census corpus fingerprint at the time of this survey is **409 syms / 251 bc**. If
yours differs, re-measure before quoting anything here — and note that the faithful
corpus of §2.2 is **410 syms / 252 bc**, which is what shipped on **2026-08-23**. So
`409/251` is now the *defective* fingerprint: seeing it means you are on the old
corpus. Build with `full_surface/build_corpus.py`, never the retired shell block.

---

## Ticket index

| bd | what |
|---|---|
| `test_C_libtooling-3c6m.63` | **P1** corpus collision, `-3` measurement integrity (§2.2) |
| `test_C_libtooling-eur4` | f32 trig leaves — updated with the ULP finding (§2.1) |
| `test_C_libtooling-3c6m.64` | `isnormal` / `llvm.is.fpclass` expansion prepass (§2.3) |
| `test_C_libtooling-3c6m.65` | **⏸ DEFERRED** (owner, 2026-08-22) — `fpclassify`: three decisions + the PredMux switch witness (§3) |
| `test_C_libtooling-3c6m.66` | `SCOPE` record fixes: stale `lever-gap` + three retired grounds (§5.1, §5.2) |
| `test_C_libtooling-8zi1` | tgamma pair — layers 2/3/4 now measured (§4.1) |
| `test_C_libtooling-sj30` | surface expansion — now priced (§4.3) |
