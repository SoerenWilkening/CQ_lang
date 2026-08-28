# SPIKE — Record-family Increment 0: the census

**Status:** measurement complete, 2026-08-27; **census 0.1 RE-RUN 2026-08-27
under the OWNER-RULED predicate** (see §2R — the pre-ruling 0.1 numbers in §2.1
–§2.4 are **superseded but retained verbatim**). **Nothing in the pass, the
runtime, the tests or any existing file was changed.** This spike adds only
`tools/record_census/`, this document, and the machine-readable JSON records
beside it.

> **READ §2R BEFORE QUOTING ANY 0.1 NUMBER.** The owner ruling of 2026-08-27
> changed the M-A predicate (liveness-keyed, alloc rails included). §2.1–§2.4
> measure the **plan-of-record draft** predicate and are kept only so the two
> populations stay comparable — every headline they carry moved. §9.1, the
> spike's most consequential finding, is **settled by the ruling** (see §9.1R).

> **REVISION 2 — 2026-08-27, applying the Inc-0 adversarial review** (full list in
> §10). The four things a reader must not miss: **census 0.4 was RE-RUN** under the
> ruled predicate and is now **9 fixtures over a CHANGED set**, not 13 (§5, §5.2);
> **§9.8 is new and is a planning blocker** — the ruled SC fence does not fix
> `slice_control_seq_grover`, the campaign's own customer; **§2R.5 prices THREE
> readings of clause 3** (3 / 5 / 8 declining modules), not two, because the
> shipped predicate silently narrows the ruling; and **§1.4 gained blind spots A8
> and U4**, of which **A8 makes census 0.1 unfit to measure a post-M-C Grover
> corpus** until it is upgraded.

**Scope:** Inc 0 of the record-family campaign — the plan of record is the comment
titled *"PLAN OF RECORD (DRAFT, 2026-08-27)"* on
**bd `test_C_libtooling-6uqc`**. The defect family is bd `6uqc` (interior rails
never uncomputed), bd `lom0` (post-region chained-theta over-decline), bd `nepx`
(the shipped seq-grover golden encodes a dephased circuit), bd `iwr7` (orphan
zext rails beside a QRAM load) and bd `1739` (`free_pairing_check.py` is blind to
template-minted rails).

**Why this increment exists:** the campaign turns on numbers — how many green
modules a new guard would decline, how many goldens an in-place lowering would
move, how big the Inc-5 target population is. This project's second failure mode
(after the verify-clean silent miscompile) is *a number that measures the wrong
program* — the retired `165/174` class. So every figure below is produced by a
committed, re-runnable script whose header states what it measures and in which
direction it approximates, and the headline of census 0.3 is verified by a second
independent method.

---

## 0. Contents

| § | Census | Answers | Script |
|---|---|---|---|
| 2 | 0.1 Guard population (**plan-v1, SUPERSEDED**) | Would M-A (Inc 1 / Inc 3) decline anything green? | `census_01_guard_population.py --predicate plan-v1` |
| **2R** | **0.1 Guard population — RULED PREDICATE** | **the live answer** | `census_01_guard_population.py` |
| 3 | 0.2 M-C population | How many sites, how many goldens regenerate? | `census_02_mc_population.py` |
| 4 | 0.3 Orphan rails | Inc-5 before-picture | `census_03_orphan_rails.py` |
| 5 | 0.4 Message churn (**RE-RUN under the ruled predicate**) | Which negative fixtures lose their pinned message? | `census_04_message_churn.py` |
| 6 | 0.5 `free_pairing_check` A1 | Does Inc 2 carry a checker change? | `probe_a1_nonconst_immediate.ll` |
| 7 | 0.6 Risk-1 design artifact | Is the dephasing premise real, numerically? | `design_artifact_record_dephasing.py` |
| 8 | — | **What these numbers decide** | — |
| 9 | — | **Contradictions with the plan of record and the bd issues** | — |

---

## 1. Methodology, corpora, and the two views

### 1.1 Corpora (derived, never hand-listed)

* **lit** — all 1119 `ir-pass/test/*.ll`. **510 lower** (`cq-opt` exit 0); 609
  decline. (609, not 610: `lowering_predmux_purecallee_deep_chain.ll` declares
  `RUN: not` but its `not` applies to a *generated* input, so the committed `.ll`
  itself exits 0. Recorded, not smoothed.)
* **e2e** — all 250 slice entries read out of `ctest --show-only=json-v1`, so the
  real per-slice flags come from the harness that runs them (230 single-TU
  `run_slice.sh`, 20 multi-TU `run_slice_multi.sh`). **All 250 lower.** The 4
  non-slice `e2e-*` ctest entries (the free-pairing selftest, the keepset vendor
  check, the census-slice-sync check, the fixture-guard-liveness check) are
  identified and excluded.
* **goldens** — all 249 `tests/e2e/*.expected.log` (census 0.3 only).

**Nothing was skipped.** Every lit fixture and every e2e slice was processed;
`lower_ll` / `lower_slice` report the exit code, and no slice failed stage 1 or
stage 2.

### 1.2 Two views, and why there are two

* **LOWERED IR** (censuses 0.1, 0.2). The faithful view — the emitted gate stream
  is the artefact whose physics is at issue.
* **PRE-LOWERING IR** (census 0.4, and as a cross-check for 0.1). Required,
  because a **declining module produces no lowered IR at all** — measured:
  `cq-opt` exits non-zero and writes nothing. Census 0.4 is entirely about
  declining modules, so it cannot use the lowered view. It uses
  `tools/record_census/source_ir.py`, a deliberately separate model.

> **The "faithful / weaker" framing above needs one correction after the
> 2026-08-27 ruling (§2R.5), and it is not cosmetic.** For the ruling's
> *deadness* clause the pre-lowering view is the **stronger** one, because the
> guard lives at that stage: at run-line 281 there is no `cqrt_free`, no `_unc`
> and no compiler-emitted adjoint `cqrt_ry`, so "no use of R after T" is a plain
> SSA-user question. The lowered view carries all three of those constructs, and
> read literally the ruling counts them as data uses — over-exempting relative to
> the guard being specified. The two views are **complementary per clause**, not
> ranked once and for all: lowered is faithful about *what gates are emitted*,
> pre-lowering is faithful about *what the guard can see*.

M-A sits in the `declineStaleRecordOps` slot (**derived**: `CQLoweringPass.cpp`
line 281), i.e. after `propagate` / the volatile+bitcast folds / `promoteFp80Union`
/ the PredMux fixpoint / `unrollConstTripLoops` / `recognizeCtlzIdiomLoops` /
`declineTaintEscapes`, and **before** `lowerLoops` (309), `detectControlRegions`
(321), `lowerQramReads` (357), `lowerRotations` (404), `lowerOps` (405),
`uncompute` (415). So at the M-A slot `@cq_theta` is still a call — which is why
the pre-lowering model is the one that matches where the guard will live.

### 1.3 Reuse (Rule 14)

`tools/free_pairing_check.py` is **imported as a module**, not re-implemented: its
`parse_module` / `Call` / `Function` / `balanced` / `split_args` / `norm_arg`
parser, its `is_negation` adjoint matcher, and — critically — its authoritative
per-symbol effect model `classify()` are what the censuses run on. Re-spelling
either is how two predicates drift apart (the bd `uow0` lesson).

### 1.4 Parsing approach and its known blind spots

Line-oriented, over textual LLVM IR (exact: `llvm-as`'s grammar is line-oriented,
and nothing here depends on formatting the verifier does not guarantee — Rule 9).
Full lists are in each script's header; the load-bearing ones:

| # | Blind spot | Direction |
|---|---|---|
| A1 | **Program order = textual order within a function.** 775 of 1303 functions in the lowered corpus have >1 block. | unknown-sign; reported, never assumed |
| A2 | No interprocedural edges (a rail into a Phase-6 clone is opaque). | UNDER-counts records; UNDER-counts M-C eligibility |
| A3 | `_inv` mints a rail the ABI does not name. **Measured: 0 `_inv` mints in the whole lowered corpus** (post bd `8txa`), so this blind spot is currently empty. | — |
| A4 | The lit corpus is hand-written IR; some fixtures spell already-lowered form or deliberately off-ABI prototypes. | produced exactly one false positive, §9.3 |
| A5 | **The lowered view cannot see TAINT** — handles are `i32`. A `cqrt_ry` on a deliberately untainted rail reads as a chained theta. Caught by the source-IR cross-check (§9.3). | OVER-counts |
| A6 | Clause 3's raw-line scan (§2R) reads every `%token` on a non-call line as a use, block labels included. A label and an SSA value cannot share a name in one function, so on well-formed IR this is exact. | — (grammar assumption, stated) |
| A7 | `@llvm.dbg.*` calls are skipped as non-uses. **Measured 0** in the lowered corpus (built without `-g`); the counter fires loudly if that changes. | — |
| **A8** | **The §1.5 adjoint-Ry filter MIS-PAIRS a user chained theta whose angle negates an earlier theta on the same handle** — the Grover S† spelling. See below; latent today, **fatal on the Inc-4 corpus**. | **BOTH — drops a real site AND mints a phantom one** |
| U1 | The pre-lowering model has no liveness/discharge to observe. | OVER-counts (the right direction for 0.4) |
| U1c | **Added 2026-08-27:** the pre-lowering model DOES model the ruled clause 3, and there it is the **stronger** view — pre-lowering there are no discharge ops at all, so "no use after T" needs no exception list. This is the cross-check that prices §2R.5. | — (see §2R.5) |
| U3 | The pre-lowering model does not replay PredMux / unroll / ctlz rewriting. | unknown-sign; **measured cost: 1 fixture**, `lowering_bitcast_measure_after_rerotate` (§2R.5) |
| **U4** | **`wire_of` does not walk merge phis**, and the one-register merge-phi lift (`declineClassicalMuxes`, run-line **381**) runs **AFTER** the M-A slot (281) — so the pre-lowering model counts the **pre-phi spelling of the wire itself** as a separate alloc-class record. | **OVER-counts** |

#### A8 — the adjoint-Ry filter mis-pairs a user S†

`_pair_adjoint_ry` (`census_01_guard_population.py`) keeps a per-handle stack of
`cqrt_ry` angles and marks a call **adjoint** when its angle negates the top of
that stack. In lowered IR a compiler-emitted adjoint and a user's chained theta
are textually identical (§1.5), so the stack is the only discriminator — and it
is the **wrong** one whenever the user *writes* the negation. Measured on
hand-built lowered probes:

| probe | truth | census reports |
|---|---|---|
| `ry(h,0.5)` · `add_hl(h,7)` · `ry(h,−0.5)` | 1 user chained theta | **0 sites** |
| same, then the full spine reversal `ry(h,+0.5)` · `add_unc` · `free` · `ry(h,−0.5)` | user site at line 13 | **1 site — at line 15, the SPINE's adjoint** (a phantom; the real one is still dropped) |
| control: the same shape with `−0.25` instead of `−0.5` | 1 user chained theta | 1 site, correctly at line 13 |

So the defect has **both** signs at once: the user's real site is dropped, and a
compiler-emitted adjoint can be **promoted** to a phantom chained site.

**It is latent on today's corpus** — the reviewer measured **0/250 e2e** and
**4/510 lit**, all four already explained (§10's validate disagreements) — for a
structural reason: today a `q += c` between the two rotations mints a **fresh
rail**, so the S and S† `Ry`s land on **different handles** and the stack never
pairs them. `slice_control_seq_grover` is exactly that: `ry(h0,0.5)` … `ry(h4,−0.5)`.

**But that structural reason is precisely what M-C removes.** An in-place
`cqrt_addc` keeps the wire on one handle, so after Inc 2 the S/S† pair lands on
**the same handle** and the filter starts mis-firing — on bd `lom0`'s own target
shape, and on the Inc-4 Grover slice this campaign is building toward.

> **CONSEQUENCE, and it is a hard prerequisite, not a caveat.** Census 0.1 must
> be **upgraded or retired before any corpus containing the Inc-4 Grover slice is
> measured with it.** The upgrade is known and cheap: take chained-theta sites
> from the **pre-lowering `@cq_theta` view** (which cannot confuse a user theta
> with a compiler adjoint, because the compiler adjoint does not exist yet) and
> use the lowered view only for the rail graph. Not attempted here — this spike
> does not edit a measurement it has already published numbers from.

#### U4 — the merge-phi wire, witnessed

Constructed witness, measured at HEAD:

```
%q  = call @cq_theta_si32(i32 7, 0.5)      ; source theta
      br i1 %c, label %arm, label %merge   ; CLASSICAL condition
%q2 = call @cq_phi_si32(i32 %q, 0.25)      ; arm: Rz, in place
%p  = phi i32 [ %q2, %arm ], [ %q, %entry ]
%q3 = call @cq_theta_si32(i32 %p, 0.125)   ; chained theta on the SAME wire
```

`cq-opt` exits **0** and emits **one** `cqrt_alloc_i32` — `declineClassicalMuxes`
lifts the phi to its wire base, so `%q`, `%q2`, `%p` and `%q3` are all one rail.
The pre-lowering model nevertheless reports `anc=1`, counting
`%q=call@cq_theta_si32` as an alloc-class record of the wire it **is**. The two
facts that make this a blind spot rather than a predicate question: `wire_of`
closes over `@cq_theta`/`@cq_phi` calls but not over `phi` nodes, and the lift
that would have collapsed the spelling runs 100 run-lines **after** the slot the
model is meant to represent. Direction is **OVER-counting**, so every 0.4 figure
inherits it as an upper bound.

### 1.5 One measurement bug found and fixed inside this spike

The first draft of census 0.1 read **189** chained thetas. It was counting the
**compiler-emitted adjoint `cqrt_ry(h, -θ)`** that `uncompute`/`EmitInverse`
emits, which in lowered IR is textually indistinguishable from a user's chained
`cq_theta`. Measured on `lowering_theta_alloc_i32.ll`: ONE `@cq_theta`, TWO
`cqrt_ry`. M-A runs at run-line 281, long before `uncompute` at 415, so an
adjoint Ry is not a site it can ever see. The census now pairs forward/adjoint Ry
the way `free_pairing_check` reduces a write history (`fpc.is_negation` on the
angle, per handle) and reports **22**, with 189 retained as the labelled upper
bound. **The MODULE hit lists did not change** — the filter drops 3 of 14 hit
SITES (`lowering_io_tape_interleaved_rotation`:16,
`lowering_io_tape_partial_freeze_order`:17,
`lowering_io_tape_qram_borrowed_index`:24, each an adjoint Ry in a module whose
user theta is also a hit), leaving 11 — but the population figure was wrong by
8.6x and would have been quoted.

---

## 2. Census 0.1 — guard population, **PLAN-V1 PREDICATE (SUPERSEDED 2026-08-27)**

> **SUPERSEDED BY §2R, RETAINED IN FULL.** Everything in §2.1–§2.4 measures the
> *plan-of-record draft* predicate as this spike first encoded it. The owner
> ruling of 2026-08-27 replaced that predicate; the live numbers are in §2R. This
> section is kept, unedited apart from this banner and the pointers below, for
> exactly one reason: the delta between the two populations is the evidence that
> the ruling did what it intended, and a delta needs both sides on the page.
> **It is still re-runnable** — the old predicate ships behind a flag.

**Re-run (the superseded population):**
```
python3 tools/record_census/census_01_guard_population.py --predicate plan-v1 \
    --json docs/prd/record-family/census-0.1-guard-population-plan-v1.json
```
Machine-readable: [`census-0.1-guard-population-plan-v1.json`](census-0.1-guard-population-plan-v1.json)
(regenerated by the revised script; its 16 headline keys were verified
**identical** to the pre-ruling artifact, retained verbatim as
[`census-0.1-guard-population-plan-v1-preruling.json`](census-0.1-guard-population-plan-v1-preruling.json)
— the revision changed the schema and added predicates, and changed **no**
plan-v1 figure).

### 2.1 Predicate (the plan's, encoded verbatim) — SUPERSEDED, see §2R.1

* **chained theta** — a `cqrt_ry_<W>(%h, θ)` whose immediately preceding call is
  **not** the `cqrt_alloc_<W>` that minted `%h`, minus the adjoint-Ry pairs of
  §1.5.
* **record** — a rail minted by `cq_template_*` or `cqrt_qram_load_<W>`.
  `cqrt_alloc_*` rails are **not** records under the plan's definition; they are
  counted separately (see §9.2, which is a real contradiction).
* **entanglement** — a directed rail graph: mint edges `operand → result`; gate
  edges `read → write` from `fpc.classify()`; `cqrt_cswap`'s two written slots
  additionally joined (the bd `0gwl` note). `_unc` adds no edge — it is recorded
  as a discharge. **ANCESTORS** = backward-reachable; **DESCENDANTS** =
  forward-reachable; **CORRELATED** = undirected-reachable (an upper bound that
  also catches siblings).
* **live at the theta** — minted before it, no `cqrt_free`, no `_unc` naming it.
* **exclusions** — the wire itself; a control-discharged compare (a
  `cq_template_{icmp,fcmp}_*` rail some `_unc` names and some `cqrt_free` frees);
  a rail measured before the theta. Both exclusions are counted as hits as well
  as applied.

### 2.2 Totals — SUPERSEDED, see §2R.2

| | |
|---|---|
| lowered modules analysed | **760** (510 lit + 250 e2e) |
| chained thetas | **22** in **19** modules (upper bound incl. adjoint Ry: 189 in 123) |
| chained-theta sites with a non-empty record set | **11** |
| **Inc 1 (descendant half) newly declines** | **7 modules** — **6 real, 1 artefact (§9.3)** |
| **Inc 3 (ancestor half) adds** | **3 modules** |
| chained theta, no live record | 9 modules (3 have a live *alloc*-minted ancestor — §9.2; 0 have a live correlated sibling) |
| exemption hits, "record measured before the theta" | **0** |
| exemption hits, "control-discharged compare" | **0** |
| `_inv` mints in the corpus | **0** |
| chained-rule disagreements (immediately-preceding vs first-Ry) | 2 (`lowering_qram_guarded_store_railof`, `lowering_uncompute_borrowed_operand_free_order`) |

### 2.3 Inc 1 — the descendant half (7 modules) — SUPERSEDED, see §2R.3

| module | fn / line | wire | live descendant records |
|---|---|---|---|
| `lit:lowering_classical_mux_phi_lift_diaghop_before_sibling` | `main`:17 | `%h` | `%h_op = cq_template_add_i32_hl` |
| `lit:lowering_classical_mux_phi_lift_op_before_sibling` | `main`:16 | `%h` | `%h_op = cq_template_add_i32_hl` |
| `lit:lowering_io_tape_interleaved_rotation` | `slice`:14 | `%h` | `%h_op = cq_template_add_i32_hl` |
| `lit:lowering_io_tape_qram_borrowed_index` | `slice`:22 | `%h_op` | `%0 = cqrt_qram_load_i32`, `%h_op2 = cq_template_xor_i32_hl` (+ alloc `%h`) |
| **`lit:lowering_stale_record_add_before_theta`** | `example`:9 | `%h` | `%h_op = cq_template_add_i32_hl` |
| **`lit:lowering_stale_record_alias_before_theta`** | `example`:10 | `%h` | `%h_op = cq_template_add_i32_hl` |
| `lit:lowering_uncompute_sink_move_past_unwalked_gate` | :25 | `%idx` | `%L = cqrt_qram_load_i32` — **FALSE POSITIVE, §9.3** |

The two bolded fixtures are **the documented accept boundary** of
`declineStaleRecordOps`. See §9.1 — this is the most consequential finding in the
spike.

### 2.4 Inc 3 — the ancestor half (3 further modules) — SUPERSEDED, see §2R.3

| module | fn / line | wire | live ancestor records |
|---|---|---|---|
| **`e2e:e2e-slice-control-seq-grover`** | `slice`:24, `main`:55 | `%h_op3` | `%h_op = cq_template_add_i32_hl` (+ alloc `%h`) |
| `lit:lowering_io_tape_partial_freeze_order` | `slice`:15 | `%h_op1` | `%h_op = cq_template_add_i32_hl` (+ alloc `%h`) |
| `lit:lowering_qram_fp64_measure_no_dirty_free` | :21 | `%0` | `%h_cast`, `%h_cast4 = cq_template_fptosi_f64_to_i32` (+ 3 alloc rails) |

`slice_control_seq_grover` is exactly bd `nepx`'s example, found independently by
two methods. `slice_control_seq_regions` is **NOT** a hit — see §9.4.

---

## 2R. Census 0.1 RE-RUN — the **RULED** predicate (owner ruling 2026-08-27)

**The ruling.** bd `test_C_libtooling-6uqc`, comment *"OWNER RULING 2026-08-27"*:
M-A's predicate is **LIVENESS-KEYED**. A chained theta `T` on wire `W` declines
only over records that are **DEAD at T**. **LIVE records are user data — their
dephasing is source semantics, so the program is ACCEPTED.** The ruling states
this explicitly preserves `lowering_stale_record_add_before_theta.ll` and its
alias sibling **by principle, not as a special case**, which is exactly the
contradiction §9.1 raised.

**Re-run (the live population):**
```
python3 tools/record_census/census_01_guard_population.py \
    --json docs/prd/record-family/census-0.1-guard-population.json

# the two acceptance tests + the known artefact, with their witnesses
python3 tools/record_census/census_01_guard_population.py --acceptance

# the priced ambiguity of §2R.5
python3 tools/record_census/census_01_guard_population.py \
    --predicate ruled-spine-aware \
    --json docs/prd/record-family/census-0.1-guard-population-spine-aware.json

# the pre-lowering cross-check, now on BOTH verdicts, under either predicate
python3 tools/record_census/source_ir.py --validate [--predicate plan-v1]
```
Machine-readable: [`census-0.1-guard-population.json`](census-0.1-guard-population.json).
All three predicates are computed on **every** run from the same parse of the
same lowered module, so the delta below is a difference between two readings of
ONE measurement, not between two runs.

### 2R.1 Predicate, encoded literally

A rail `R` counts against a chained theta `T` on wire `W` iff **all** of:

1. **entangled with `W`** — transitively, **ancestors AND descendants**. `R` may
   be `cq_template_*`-minted, `cqrt_qram_load_<W>`-minted, **or
   `cqrt_alloc_<W>`-minted**. *(The alloc inclusion is the NEW clause; §9.2
   showed plan-v1's record definition did not cover bd `nepx`'s own leading
   example `h0`.)*
2. **not discharged before `T`** — no `cqrt_free(R)`, and no `_unc` adjointing
   `R`'s own producer (an `_unc` whose **out** slot is `R`) at a position before
   `T`.
3. **DEAD at `T` in the data sense** — **no use of `R` after `T`** except its own
   discharge ops (`cqrt_free(R)`; an `_unc` whose adjointed rail is `R`). A
   post-`T` `cqrt_measure_*(R)`, a template call **reading** `R`, a cswap/route
   slot, a copy/tape sink, or a plain-IR use such as `ret` **is a data use** ⇒ `R`
   is **LIVE** ⇒ **exempt**. *(This is the clause the ruling added.)*
4. **not measured before `T`** (collapse exemption — unchanged).
5. **not the wire itself** (the in-place gate chain on the same handle —
   unchanged).

> **DISCLOSURE — clause 3 as SHIPPED is NARROWER than the ruling's words, in the
> over-exempting direction.** The ruling says "a future free/_unc is a
> discharge"; the `ruled` predicate reads that as **`R`'s OWN discharge** — a
> `cqrt_free(R)`, or an `_unc` whose **out** slot is `R` — and therefore counts
> an `_unc` that merely **READS** `R` (while discharging some *other* rail) as a
> **data use**, which EXEMPTS `R`. The word "own" is the census's, not the
> ruling's. It is the safest reading to *ship as a measurement* (it exempts more,
> so it never over-states the population) and the **least** safe as a *guard*
> (exempting more means declining less, and under-declining is the direction the
> Prime Directive exists to stop). **§2R.5 prices all three readings side by
> side — 3 / 5 / 8 declining modules — and this narrowing is exactly the
> difference between the first two columns.** Inc 1 must not inherit the shipped
> default by accident.

Two things the ruling did **not** touch, and which are preserved verbatim from
the pre-ruling revision: the **chained-theta rule** (§2.1) and the **§1.5
compiler-emitted adjoint-Ry filter** (still 22 sites, upper bound 189 — but read
that filter with **blind spot A8**, §1.4, before quoting it on a Grover-shaped
corpus).

The plan's carve-out (b) — a *control-discharged compare* is Phase 4's to own —
is **not in the ruling's five clauses**, so it is **not applied** under `ruled`.
The rails it would have removed are counted anyway: **0**, same as plan-v1's
measured 0. Nothing turns on it either way today.

### 2R.2 Totals (ruled predicate)

| | plan-v1 (§2.2) | **ruled** |
|---|---|---|
| lowered modules analysed | 760 | **760** (510 lit + 250 e2e) |
| chained thetas | 22 in 19 modules | **22 in 19 modules** (unchanged) |
| upper bound incl. adjoint Ry | 189 in 123 | **189 in 123** (unchanged) |
| **Inc 1 (dead-DESCENDANT half) newly declines** | 7 modules (6 real + 1 artefact) | **1 module — and it is the §9.3 ARTEFACT. ZERO real modules.** |
| **Inc 3 (dead-ANCESTOR half) adds** | 3 modules | **2 modules, both real** |
| **total modules M-A would newly decline** | **10** | **3 (2 real)** |
| chained theta, no counting record | 9 modules | **16 modules** |
| rails exempted by clause 3 (LIVE after `T`) | n/a | **16** |
| exemption hits, "record measured before the theta" | 0 | **0** |
| exemption hits, "control-discharged compare" | 0 | **0** (would-be 0) |
| `array`/`tape` rails seen in a cone (in neither record class) | — | **2** (`%arr1` in two fixtures) |
| `_inv` mints in the corpus | 0 | **0** |
| multi-block functions (blind spot A1) | 775 / 1303 | **775 / 1303** |
| chained-rule disagreements | 2 | **2** |

### 2R.3 The three hits, in full

| half | module | fn / line | wire | counting rails |
|---|---|---|---|---|
| **Inc 3** | **`e2e:e2e-slice-control-seq-grover`** | `slice`:24, `main`:55 | `%h_op3` | `%h = cqrt_alloc_i32` **(new under the ruling)**, `%h_op = cq_template_add_i32_hl` |
| **Inc 3** | `lit:lowering_qram_fp64_measure_no_dirty_free` | `shadow_fp_measure`:21 | `%0` | `%h`, `%h2`, `%h3` (`cqrt_alloc_f64`, **new**), `%h_cast`, `%h_cast4` (`cq_template_fptosi_f64_to_i32`) |
| Inc 1 | `lit:lowering_uncompute_sink_move_past_unwalked_gate` | :25 | `%idx` | `%L = cqrt_qram_load_i32` — **KNOWN ARTEFACT, §9.3** (already-lowered fixture, rail declared untainted by its own comment; the guard would not fire) |

`slice_control_seq_grover` is the acceptance case: `h0`/`h1` are dead at the
S† `Ry`, and it **remains** a hit. `slice_control_seq_regions` is still **not** a
hit under either predicate (§9.4 stands unchanged).

### 2R.4 DELTA vs plan-v1 — 10 → 3 modules, **7 out, 0 in**

Every drop is clause 3 (the rail is LIVE after the theta), with its witnessing
use printed by the script:

| module | rail | why it now EXEMPTS |
|---|---|---|
| **`lit:lowering_stale_record_add_before_theta`** | `%h_op = cq_template_add_i32_hl` | `cqrt_measure_i32(%h_op)` at line 10 — **the pinned accept boundary, restored by principle** |
| **`lit:lowering_stale_record_alias_before_theta`** | `%h_op = cq_template_add_i32_hl` | `cqrt_measure_i32(%h_op)` at line 11 — same, one diagonal hop removed |
| `lit:lowering_classical_mux_phi_lift_op_before_sibling` | `%h_op = cq_template_add_i32_hl` | `cqrt_measure_i32` at line 17 |
| `lit:lowering_classical_mux_phi_lift_diaghop_before_sibling` | `%h_op = cq_template_add_i32_hl` | `cqrt_measure_i32` at line 18 |
| `lit:lowering_io_tape_interleaved_rotation` | `%h_op = cq_template_add_i32_hl` | `cqrt_tape_write_i32` at line 15 — a 7.6 **output sink** is a data use |
| `lit:lowering_io_tape_partial_freeze_order` | `%h_op = cq_template_add_i32_hl` | read by `cq_template_add_i32_hl_unc` at line 18 (an `_unc` discharging a **different** rail) — **see §2R.5** |
| `lit:lowering_io_tape_qram_borrowed_index` | `%0 = cqrt_qram_load_i32`; `%h_op2 = cq_template_xor_i32_hl` | `cqrt_tape_write_i32` at 23; read by `cqrt_qram_store_i32_unc` at 27 — **partly §2R.5** |

**Nothing moved IN.** The alloc-minted inclusion (clause 1) added **zero**
modules on its own. It does admit new *rails* — `seq-grover`'s `%h` (bd `nepx`'s
`h0`) and `lowering_qram_fp64_measure_no_dirty_free`'s three `cqrt_alloc_f64`
rails — but both modules were **already** hits via their template-minted
siblings, so the module count is unchanged. Every **other** alloc rail the clause
newly admits is exempted by clause 3. The two clauses pull in opposite directions
and, on this corpus, clause 3 wins everywhere clause 1 would have been the only
reason to decline. *(Read that with §2R.5: under the spine-aware reading clause 1
does move 3 modules in, all of them alloc-only.)*

The two acceptance tests the revision was required to pass, and the artefact
guard, are pinned in the script itself (`--acceptance`, exit non-zero on
failure) so a future edit cannot quietly break them:

```
PASS lit:lowering_stale_record_add_before_theta      ruled=exempt   (want exempt)
PASS lit:lowering_stale_record_alias_before_theta    ruled=exempt   (want exempt)
PASS e2e:e2e-slice-control-seq-grover                ruled=HIT      (want HIT)
PASS lit:lowering_uncompute_sink_move_past_unwalked_gate  ruled=HIT  (known artefact, §9.3)
```

### 2R.5 ONE AMBIGUITY, measured and NOT resolved here

The ruling's clause 3 exempts a rail with a "data use" after `T`, and its
parenthetical says *"a future free/_unc is a discharge, not a data use; a future
measure/template-read/ret IS a data use"*. Read **literally** the discharge
exception covers `cqrt_free(R)` and the `_unc` whose adjointed rail **is** `R`.
But the LOWERED corpus contains two further post-theta mentions of `R` that no
source program asked for **and that do not exist at the M-A slot**:

* an `_unc` that merely **READS** `R` while discharging some *other* rail —
  emitted by `uncompute` (run-line 415) or the Phase-4 teardown (321);
* the compiler-emitted **adjoint** `cqrt_ry(R, −θ)` — emitted by `EmitInverse`.

M-A sits at `declineStaleRecordOps`, **run-line 281**. At that point the module
has no `_unc`, no `cqrt_free` and no adjoint Ry *at all*, so the real guard
cannot see either construct and would find `R` **dead**. **This is the exact
sibling of the §1.5 defect** that cost the pre-ruling census an 8.6x error, so it
is measured rather than assumed away:

**There are THREE readings, not two, and the shipped default is the narrowest of
them.** State this first, because the shipped `ruled` predicate does not merely
*encode* the ruling — it **NARROWS** it. The ruling's words are "a future
free/_unc is a discharge"; the code reads that as **`R`'s OWN discharge** (a
`cqrt_free(R)`, or an `_unc` whose **out** slot is `R`), and therefore treats an
`_unc` that merely **READS** `R` while discharging some other rail as a **data
use**. Nothing in the ruling says "own"; the narrowing is the census's, it is in
the **over-exempting** direction, and it is priced here rather than buried:

| reading | discharge = | Inc 1 | Inc 3 | total declining |
|---|---|---|---|---|
| **`ruled`** (R's-OWN-discharge — the shipped default, the narrowest) | `cqrt_free(R)`; an `_unc` whose out slot is `R` | 1 (artefact only) | 2 | **3** |
| *intermediate* (any `_unc` **mention** of `R` is a discharge; the adjoint `Ry` is still a data use) | + an `_unc` that merely reads `R` | 2 | 3 | **5** |
| **`ruled-spine-aware`** (no spine-emitted mention is a data use) | + the compiler-emitted adjoint `cqrt_ry(R, −θ)` | 2 | 6 | **8** |

*(`ruled` and `ruled-spine-aware` are computed by the script on every run;
the intermediate column is derived from the same run's per-rail
`exempt_live_after` witnesses — a rail flips iff its **only** post-`T` uses are
`_unc` calls. Exactly two rails flip: `lowering_io_tape_partial_freeze_order`'s
**ancestor** `%h_op` (`18:cq_template_add_i32_hl_unc`), which moves that module
into Inc 3, and `lowering_io_tape_qram_borrowed_index`'s **descendant** `%h_op2`
(`27:cqrt_qram_store_i32_unc`), which moves that module into Inc 1. Every other
exempting witness list contains an adjoint `cqrt_ry`, so nothing else moves.)*

The `ruled` → `ruled-spine-aware` difference is **8 rail-at-theta exemptions in 5
modules**: `e2e-slice-io-chained-theta`, `lowering_io_tape_chained_theta`,
`lowering_io_tape_partial_freeze_order`, `lowering_io_tape_qram_borrowed_index`,
`lowering_uncompute_borrowed_operand_free_order`.

> **Two of those five must be discounted before the delta is quoted as a
> population.**
>
> * **`lowering_uncompute_borrowed_operand_free_order` is an ARTEFACT** — the
>   same class as §9.3, and it is recorded here because it was NOT flagged when
>   the delta was first written. The fixture is authored in already-lowered form:
>   its three `@cq_theta_si32` calls take three **distinct untainted**
>   arguments (`%u0`, `%u1`, `%u2`), so they are *source* thetas; and the three
>   `cqrt_ry_i32(%z,·)` / `(%v,·)` / `(%q,·)` at the committed fixture's lines
>   58–60 are **hand-written raw runtime calls** in an already-lowered fixture,
>   not rotations the pass minted from a `@cq_theta`. Those three are the
>   census's "chained sites" (lowered lines 24/25/26). The lowered-IR view cannot
>   tell a raw `cqrt_ry` from a lowered theta (blind spot A5); `source_ir` reports
>   `chained: 0`. **M-A guards `@cq_theta` rotations at run-line 281 and would not
>   fire there.**
> * **`e2e-slice-io-chained-theta` and `lowering_io_tape_chained_theta` are the
>   SAME PROGRAM** — the lit fixture is the e2e slice's twin and its own header
>   quotes the six lines of C verbatim.
>
> **Honest restatement: the spine-aware delta is 4 hit modules over 3 distinct
> programs** — `io-chained-theta` (slice + lit twin), `lowering_io_tape_partial_freeze_order`,
> `lowering_io_tape_qram_borrowed_index`.

**The canonical case is `e2e-slice-io-chained-theta`, which is the program §9.2
argued should count.** Its source is
`int x = cq_theta(seed,0.5); int y = x + 1; int z = cq_theta(y,0.25);` — `x` is
**dead in C** after the add. In the lowered stream `%h`'s only post-theta
mentions are `cq_template_add_i32_hl_unc(%h_op, %h, 1)` and
`cqrt_ry_i32(%h, −0.5)`, i.e. the spine reversing itself. Literal `ruled`:
exempt. Intermediate: still exempt (the adjoint `Ry` carries it). Spine-aware:
**hit**.

**Independent confirmation, from the other view.** `source_ir.py --validate` now
compares *two* verdicts, and the pre-lowering model — which sees exactly the IR
the guard will see, and pre-lowering has **no discharge ops at all**, so clause 3
there is a plain SSA-user question with no exception list to get wrong — reports
a record-hit disagreement that **overlaps** the delta set:

```
validate 2/2 — RECORD-HIT verdict under `ruled`:   agree 505, disagree 5
  source-only   lowering_io_tape_chained_theta        (src_hits=1 low_hits=0)
  source-only   lowering_io_tape_partial_freeze_order (src_hits=2 low_hits=0)
  source-only   lowering_io_tape_qram_borrowed_index  (src_hits=6 low_hits=0)
  source-only   spec_reseed_theta_source              (known over-taint, §10)
  lowered-only  lowering_uncompute_sink_move_past_unwalked_gate (§9.3 artefact)
```

> **CORRECTION — "two views, two methods, the same five modules" was FALSE and is
> withdrawn.** The two sets are both of size 5 and they **overlap in 3**. The
> validate set is lit-only by construction (it runs over the lit corpus), so it
> cannot contain `e2e-slice-io-chained-theta`; it also contains two modules the
> delta set does not (`spec_reseed_theta_source`, the known over-taint, and the
> §9.3 lowered-only artefact), and omits
> `lowering_uncompute_borrowed_operand_free_order`. §10 already states the
> composition correctly — *"the §9.3 artefact, the `spec_reseed_theta_source`
> over-taint, and the THREE lit modules of §2R.5"* — and this paragraph now
> agrees with it. **What the cross-check does confirm, and it is still the
> load-bearing part: on all three lit modules the two independent views disagree
> in the SAME direction** (pre-lowering says HIT, the literal lowered reading says
> exempt), which is what makes the ambiguity real rather than a parser artefact.
> The coincidence of the two set sizes is what made the sentence look checked.

**This is an owner decision, not a measurement one**, and Inc 1 must make it
explicitly:

> Is a post-`T` mention of `R` emitted by the uncompute spine / Phase-4 teardown
> (an `_unc` read, an adjoint `Ry`) a **data use** that exempts `R`, or **spine
> traffic** that the guard cannot see and must not be exempted by?

The census's own reading is that the ruling meant *source-level* data use — it
says "LIVE records are USER DATA" — and that spine traffic is not user data. But
the ruling's exception list as written does not say so, and this spike does not
get to widen a ruling. **Both populations are shipped, both are re-runnable, and
`ruled` is the default because it is the literal one.** Note the direction: the
literal reading is the OVER-EXEMPTING one, i.e. it under-declines — the unsafe
direction for a guard whose job is to stop a silent miscompile.

#### 2R.5a The independent review's recommendation — **RULED: APPROVED (owner, 2026-08-27)**

The Inc-0 adversarial review took the physics question on and **settled it in
favour of the spine-aware reading**, on the ground that the census could only
gesture at: **all three real disagreeing programs are genuinely dephased at the
theta.** The record is live and entangled with the wire **at the instant the `Ry`
fires** — that is the only moment that matters for §7.1's interference term — and
the spine's later `_unc` / adjoint-`Ry` traffic is the compiler undoing *itself*,
not the user reading data. A rail whose sole post-`T` mentions are the spine
reversing its own bookkeeping was never user data at `T`.

It further recommended that the guard **run LATE (post-uncompute), keyed on
emitter-recorded spine-op sets** rather than on a textual `_unc`/`Ry` shape test —
i.e. the emitters record which calls they minted, and the guard asks "is every
post-`T` mention of `R` in that set?". That is provable exactly, whereas the
census's text model can only guess.

**Neither is adopted here.** It is recorded as the review's recommendation, it
runs against the shipped default, and the M-A slot it implies is **not** run-line
281 — which is a plan change, not a predicate change. **Owner confirmation
required before Inc 1 encodes either.**

Under `plan-v1` the same cross-check disagrees on `lowering_bitcast_measure_after_rerotate`
only (`src_hits=1 low_hits=0`): its `%b = bitcast i32 %h to i32` is folded away by
`foldIdentityBitcasts` **before** the M-A slot, so the source model counts a
record the guard will never see — blind spot U3, not a predicate question.

### 2R.6 What §2R changes about the campaign

* **Inc 1 (the descendant half) newly declines NOTHING REAL on this corpus.**
  Under plan-v1 it took 6 real modules including two deliberately-pinned accept
  fixtures; under the ruling it takes **0** (its one hit is the §9.3 artefact, on
  a rail the fixture itself declares untainted). See §8 for what that does to
  "is Inc 1 shippable standalone".
* **Inc 3 (the ancestor half) is the increment that carries the campaign's
  customer**: 2 modules, one of which is `slice_control_seq_grover` — bd `nepx`'s
  own example, found here independently by two methods.
* **§9.1 is settled** (see §9.1R): the ruling chose neither horn of the dilemma
  as posed, and instead added the clause that makes both fixtures accept *for a
  stated reason*.

---

## 3. Census 0.2 — the M-C population

> **RULED 2026-08-27 (owner, bd `test_C_libtooling-6uqc`): the M-C fence is the
> NARROW single-consumer reading — the `SC` row below. 233 sites / 68 goldens at
> HEAD.** The wider readings measured here are **not** adopted: the **74**
> strict-eligible sites that `SC` excludes (those with an *earlier* out-of-place
> consumer of the parent) are **DEFERRED, with their "safe by accident" status
> recorded** — §8 measured that each happens to have no later adjoint reading the
> parent *in today's corpus*, so `strict` is not currently unsound but rests on a
> property of the corpus rather than of the fence. `R1`/`R2`/`R4` are likewise
> deferred. §9.7 (the fence-wording contradiction) is thereby **SETTLED**; the
> other columns are retained as the price of each alternative, not as options
> still open.
>
> Nothing else in census 0.2 changed: the ruling is a **choice among the columns
> already measured here**, not a re-measurement. The Inc-2 numbers to plan from
> are therefore **233 sites / 68 goldens (49 libm-hybrid + 19 core)**.

**Re-run:**
```
python3 tools/record_census/census_02_mc_population.py \
    --json docs/prd/record-family/census-0.2-mc-population.json
```
Machine-readable: [`census-0.2-mc-population.json`](census-0.2-mc-population.json),
including `eligible_strict_sites[*].later_uses` — **the complete parent-handle
user list for every eligible site, which is the Inc-2 reviewer's accept table
(plan Risk 2)**.

### 3.1 The fence, as encoded

**F1** callee `cq_template_{add,sub,xor}_<W>_{hl,lh}`. **F2** `W` in the in-place
runtime grid, **measured from `runtime/cq_runtime.h` at run time, not asserted**:
`{i1, i8, i16, i32, i64}` (the script hard-fails if the `addc`/`xorc` grids ever
disagree). **F3** `_hl` for all three ops; `_lh` for `add`/`xor` only — `c - q` is
not an in-place add. **F4** the parent handle (arg 0 for `_hl`, arg 1 for `_lh`)
has no later use other than `cqrt_ry`/`cqrt_rz` on that same handle; anything
else — another template call, `cqrt_measure`, `cqrt_cswap`, an `_unc` that *reads*
it, a copy/tape sink, or a plain-IR use such as `ret`/`store`/`phi` —
disqualifies. Uses are found by a **raw-text token scan over the function's own
line range**, not by the call parser alone, so `ret i32 %P` cannot slip through.

### 3.2 Totals

| | sites | e2e goldens that change |
|---|---|---|
| `add`/`sub`/`xor` `_hl`/`_lh` calls in the corpus | 904 | — |
| after F2 (width) + F3 (direction) | 820 | — |
| declined on width | **0** | — |
| declined on direction (`sub … _lh`) | **84** (in 39 modules) | — |
| **ELIGIBLE, fence exactly as written (F4 strict)** | **307** | **84** (55 libm/hybrid, 29 core) — *not adopted; its 74 extra sites are DEFERRED* |
| + **R1** ignore this site's own `_unc` | 322 | 86 |
| + **R2** also allow `addc`/`xorc`/`x` on the parent | 322 | 86 |
| + **R4** also allow the SPINE to own the parent (an `_unc` whose *out* slot is the parent, plus its `cqrt_free`) | **362** | **93** |
| **SC** ⟵ **RULED 2026-08-27, THIS IS THE FENCE**: strict **and** no earlier out-of-place consumer (the plan's own "single-consumer" wording) | **233** | **68** (49 libm/hybrid, 19 core) |
| candidate sites with a later `cqrt_free(P)` | 46 | — |

Op mix of the SC set: `add_i32_hl` **159**, `add_i64_hl` 42, `xor_i32_hl` 29,
`xor_i64_hl` 2, `add_i16_hl` 1 — **159 + 42 + 29 + 2 + 1 = 233**, the headline.
**No `_lh` site is eligible under any column**, and only 2 `sub_hl` sites are
(both strict-only, not SC).

> **This mix must be GENERATED from the JSON, never typed.** It was first written
> with `add_i32_hl` at **155**, which summed to 229 and not to the 233 headline
> three lines above — a four-count discrepancy that no reader would have caught
> without adding up a five-row table. Regenerate it with:
> ```
> python3 -c "import json,collections; d=json.load(open('docs/prd/record-family/census-0.2-mc-population.json')); \
> c=collections.Counter(r['sym'] for r in d['eligible_single_consumer_sites']); \
> print(c.most_common(), sum(c.values()))"
> ```
> **and check the sum against the table row.** A published composition that does
> not add up to its own total is the `165/174` failure mode in miniature: the
> total was right and the composition beside it was not.

Of the 307 strict-eligible sites, **303 have ZERO later use of the parent at
all** — the parent rail is never read again, never uncomputed, never freed. That
is the same population census 0.3's "undischarged" column measures from the other
side.

### 3.3 Core (non-libm) goldens that change under the SC reading

`bitcast-words`, `branchless-{acosh,asinh,atanh,cbrt,log,log10,log1p,log2,logb,logl,pow,pow-qq}`,
`byref-inline`, **`control-seq-grover`**, `loop-break-qq-derived`, `multi-2file`,
`multi-zerolib`, `theta-add-measure`.

Note the twelve `branchless-*` entries are the **CQ-PROVIDED** leaves (Rule 18's
amendment); their goldens are the mechanical condition-(ii) evidence, so
regenerating them is a deliberate, reviewable act rather than a routine refresh.

> **`control-seq-grover`'s entry in that list is a PARTIAL change — read §9.8
> before regenerating it.** Only **1 of its 3** candidate sites per function is
> SC-eligible; the other two are inside the deferred 74. Its golden will differ,
> and the differing golden still encodes a **dephased** circuit. A "golden
> changed" signal on this slice is not evidence that bd `nepx`'s defect is fixed.

---

## 4. Census 0.3 — orphan rails (the Inc-5/6 before-picture)

**Re-run:**
```
python3 tools/record_census/census_03_orphan_rails.py --crosscheck \
    --json docs/prd/record-family/census-0.3-orphan-rails.json
```
Machine-readable: [`census-0.3-orphan-rails.json`](census-0.3-orphan-rails.json).

Handles are printed from a **globally monotonic, never-reused** counter
(`cqrt_alloc_handle`, `runtime/cq_runtime.c:64-68`), so a textual sweep over a
golden is exact rather than approximate.

### 4.1 Orphans (bd `iwr7`'s definition, extended to every producer)

| | |
|---|---|
| goldens scanned | **249** |
| template/QRAM rail definitions | **38 486** |
| **ORPHAN records** (defined by `cq_template_*` / `cqrt_qram_load_*`, never mentioned again) | **14** |
| orphan `_inv` phantom mints | **0** |
| tape rails (kept by design, excluded) | 9 |
| goldens containing ≥1 orphan | **10** |
| orphans defined on the last line of a golden | 0 |
| **by producer family** | `zext` **14**, everything else **0** |

Per golden: `exp` 1, `expf` 1, `cosh` 1, `coshf` 1, `sinh` 1, `sinhf` 1, `erf` 2,
`erff` 2, `erfc` 2, `erfcf` 2 — **exactly bd `iwr7`'s ten goldens and its
root-caused count of 14** (`lowerQramReads`' `hasOneUse` guard). The
`cq_template_icmp_*` family bd `iwr7` also listed (`slice_libm_real_frexp`, 2) is
**gone**, consistent with bd `qesi` having been fixed and that golden regenerated.
**Extending the sweep from `{icmp, zext}` to EVERY rail-minting producer found no
third family.**

**Cross-check (the sanity rule):** an independent single-pass `awk` pipeline that
never touches this script's parser reports **14**. `--crosscheck` runs it and
fails loudly on disagreement; it printed `cross-check AGREES`.

### 4.2 The wider population — the actual Inc-5 target (reported separately)

An orphan is "never mentioned again". bd `6uqc`'s defect shape is *mentioned
again on every line that consumes it* and is therefore invisible to that
definition. The wider count — template/QRAM rails with **no `_unc` naming them in
the out slot, no `cqrt_free`, and no `cqrt_measure`**:

| | |
|---|---|
| **undischarged records** | **12 880** |
| in | **174 of 249 goldens** |
| top families | `fmul` 1541, `fadd` 1149, `and` 939, `bitcast` 883, `fsub` 852, `fma_f80_qq` 617, `trunc` 594, `zext` 571, `or` 559, `fma_f64_qq` 558, `add` 557, `lshr` 476 |
| top goldens | `lgamma` 762, `hybrid_lgammal` 692, `lgammaf` 641, `acoshl` 485, `asinhl` 484, `erfcl` 418, `erfl` 405, `sinhl` 354 |

Hand-verified against `slice_control_seq_grover.expected.log`: **2** undischarged
rails, `h1` (the `add`) and `h4` (the `sub`) — bd `nepx`'s own example — and
**neither is an orphan**. `slice_control_seq_regions`: **0**.

---

## 5. Census 0.4 — message-ownership churn (plan Risk 5)

> **RE-RUN 2026-08-27 UNDER THE RULED PREDICATE.** The population first committed
> here (**13** fixtures) was produced by `source_ir.py` **before** it was revised
> for the owner ruling — i.e. by what is now the `plan-v1` record class. The
> shipped script yields **9**, over a **different set**. This section measures the
> `ruled` run; the superseded one is retained as
> [`census-0.4-message-churn-preruling.json`](census-0.4-message-churn-preruling.json)
> and is re-runnable behind `--predicate plan-v1`.

**Re-run:**
```
python3 tools/record_census/census_04_message_churn.py \
    --json docs/prd/record-family/census-0.4-message-churn.json

# the SUPERSEDED pre-ruling population
python3 tools/record_census/census_04_message_churn.py --predicate plan-v1 \
    --json /tmp/census-0.4-plan-v1.json
```
Machine-readable: [`census-0.4-message-churn.json`](census-0.4-message-churn.json).
The `--predicate plan-v1` run reproduces the retained pre-ruling artifact on
**every** headline key, on the at-risk fixture set, and row-for-row modulo the two
keys the revision added (`src_exempt_live_after`, `src_records_after_theta`) —
verified, the 0.1 precedent. **The retained file is kept verbatim rather than
regenerated**, so it still carries the schema it was written with.

Each negative fixture's **actual `cq-opt` stderr** is read (not its `CHECK`
lines). Each message is located in `ir-pass/{src,include}` **with comments
stripped** — this pass documents its diagnostics in prose, and
`"control flow under quantum control"` appears verbatim in two comments
(`CQLoweringPass.cpp:287`, `PredMuxFlatten.cpp:2714`), which mis-attributed two
messages before the comment strip was added. Stage order is derived from
`CQLoweringPass::run` (statement-level calls taking `M`), with one-hop
`#include`-based attribution for helper modules such as `ArmClassify.cpp` that
define no pass entry themselves.

> **EVERY NUMBER IN THIS SECTION IS AN UPPER BOUND, and the script's own C1
> header says so.** Step 4 assumes M-A fires whenever the predicate holds,
> whereas the real guard carries the carve-outs census 0.1 measured; and the
> pre-lowering model's U-series blind spots (notably **U4**, §1.4) over-count.
> What is *no longer* an inflating term under `ruled` is `source_ir`'s U1 — the
> model now DOES carry the ruled deadness clause (U1c). Read `9` as "at most 9",
> never as "9".

| | |
|---|---|
| M-A slot | `CQLoweringPass.cpp:281` (`declineStaleRecordOps`) |
| record predicate | **`ruled`** (owner ruling 2026-08-27) |
| negative lit fixtures | **610** |
| with a chained theta AND ≥1 counting record (pre-lowering model) | **9** |
| **AT RISK** (current message emitted at/after the M-A slot) | **9** *(upper bound)* |
| safe (an earlier stage still wins) | **0** |
| messages the census could not locate | **0** |
| *(the superseded `--predicate plan-v1` run, over the same 610)* | *13 with a record · **13** at risk · 0 safe · 0 unmapped* |

### 5.1 The 9 fixtures and the message each currently pins

| fixture | anc/desc | pinned message | emitting stage |
|---|---|---|---|
| `control_swap_reject_nested_theta` | 0/1 | `cq controlled lowering: control flow under quantum control` | control emitters @run:293 |
| `control_swap_reject_select_stale_leaf_crossblock` | 0/1 | `… condition predates a non-diagonal gate …` | `ArmClassify`/`SelectClassify`/`SwitchClassify`/`RegionTreeDetect` @run:321 |
| `control_swap_reject_select_stale_leaf_onewire` | 0/1 | `… condition predates a non-diagonal gate …` | same |
| `control_swap_reject_select_stale_leaf_theta` | 0/2 | `… condition predates a non-diagonal gate …` | same |
| `control_swap_reject_switch_stalecond_router` | 1/0 | `… condition predates a non-diagonal gate …` | same |
| **`control_swap_reject_switch_value_router_base_backstop`** | 1/0 | `cq opcode lowering: operand predates a non-diagonal gate` | `OpcodeLowering` **@run:281** |
| **`control_swap_reject_value_diamond_router_base_backstop`** | 1/0 | `cq opcode lowering: operand predates a non-diagonal gate` | `OpcodeLowering` **@run:281** |
| **`lowering_reject_bitcast_chained_theta_arg0`** | 0/1 | `cq opcode lowering: operand predates a non-diagonal gate` | `OpcodeLowering` **@run:281** |
| `lowering_reject_frozen_wire_phi_result` | 1/0 | `cq rotation lowering: unsupported frozen quantum wire` | `RotationLowering` @run:404 |

**THREE of these pin `declineStaleRecordOps`'s own message at the M-A slot
itself** — the three bolded rows above. Whether M-A steals them depends on an
implementation-order choice *within one slot*: the plan says M-A is called "from
the `declineStaleRecordOps` slot pre-mutation", which does not say whether it runs
before or after the existing guard. **Inc 1 must decide that explicitly**;
running M-A second keeps those three fixtures green with no edit.

### 5.2 The set CHANGED; it did not shrink

13 → 9 is not a subset relation. **Only 4 of the 13 survive** (the three
`select_stale_leaf_*` and `lowering_reject_bitcast_chained_theta_arg0`); **9 left
and 5 arrived.**

| | fixtures |
|---|---|
| **survived** (4) | `…select_stale_leaf_crossblock`, `…_onewire`, `…_theta`, `lowering_reject_bitcast_chained_theta_arg0` |
| **left** (9) | `control_swap_reject_select_fp_theta_fork`, `…_select_stalecond_chained_theta`, `…_select_stalecond_chained_theta_i32`, `control_swap_reject_stalecond_derived_cond_preadd`, `control_swap_reject_switch_value_stalebase`, `control_swap_reject_value_stalebase_inarm`, `lowering_reject_bitcast_select_stale`, `lowering_reject_bitcast_tape_stale`, `lowering_reject_stale_record_loop` |
| **arrived** (5) | `control_swap_reject_nested_theta`, `control_swap_reject_switch_stalecond_router`, `control_swap_reject_switch_value_router_base_backstop`, `control_swap_reject_value_diamond_router_base_backstop`, `lowering_reject_frozen_wire_phi_result` |

The two directions have different causes, and **three** distinct clause changes
are responsible — each one checked per fixture, not inferred:

* **all 9 that left** did so on **clause 3**. Every one has `anc/desc = 0/0`
  under `ruled` with an `exempt_live_after` witness, and `0/1` under `plan-v1`.
  The witnesses, as the model prints them: `%d used at 34:call`
  (`lowering_reject_stale_record_loop`), `%d used at 31:icmp`
  (`…stalecond_derived_cond_preadd`), `%b used at 28:;, 29:call`
  (`lowering_reject_bitcast_tape_stale`), `%v1 used at 39:phi` and `%v1 used at
  45:phi` (the two `…stalebase…`), `%sel used at 31:call`
  (`…select_fp_theta_fork`), `%c`/`%t` `used at 30:select` and the `_i32`
  sibling's at `21:select`, `%b used at 29:;, 30:select`
  (`lowering_reject_bitcast_select_stale`). **Not one left for any other reason.**
* **4 of the 5 that arrived** did so on **clause 1** — the alloc-minted
  inclusion, which pre-lowering is spelled as a `@cq_theta_*` result outside the
  wire. The counting record is literally `%q0=call@cq_theta_si32` /
  `%p0=call@cq_theta_si32` / `%q=call@cq_theta_f64`.
* **the 5th, `control_swap_reject_nested_theta`, arrived for a THIRD reason that
  is easy to misattribute**: its record is `%c1=icmp`, and it counts only because
  the `ruled` predicate **drops the control-position-compare carve-out** (§2R.1 —
  the carve-out is not among the ruling's five clauses). Under `plan-v1` that
  rail is `exempt_control_compare`.

**That last bullet is a correction to §2R.2's "0 exemption hits", and it should be
read as one.** The **0** is measured on the LOWERED corpus, which is entirely
*positive* modules; on the **declining** corpus the carve-out is not inert at all
— **6** negative fixtures carry a control-position-compare exemption under
`plan-v1` (`control_predmux_fp_diamond_stalecond_declines`,
`control_swap_reject_nested_theta`, `…select_stalecond_chained_theta{,_i32}`,
`control_swap_reject_stalecond_chained_theta`,
`control_swap_reject_value_stalecond`), and on one of them it flips the at-risk
verdict. §8's "the carve-out is inert on the current corpus" therefore holds for
the corpus it was measured on and **not** for the fixtures census 0.4 is about.

**Nothing here says the churn got smaller.** It says the churn moved to a
different set of fixtures, one that Inc 1 must re-derive against the guard it
actually writes — including whether that guard carries the carve-out — rather
than inherit from either run.

### 5.3 The narrowing funnel (generated — `narrowing_funnel` in the JSON)

| stage | `ruled` | `plan-v1` |
|---|---|---|
| negative lit fixtures | 610 | 610 |
| … with a chained theta | 49 | 49 |
| … + a record on either side (no position clause, no deadness clause) | 48 | 41 |
| … + the record must already EXIST at the theta (U1b, mirrors 0.1's `live_at`) | 28 | 18 |
| … + the record must be DEAD at the theta (clause 3; `plan-v1` has no such clause) | **9** | **13** |

The position clause is the big filter in both columns: the fixtures it removes
describe an op scheduled *past* a theta, which is `declineStaleRecordOps`'s **own**
case and not an M-A site. Written without it, M-A would take 48 (or 41).

---

## 6. Census 0.5 — `free_pairing_check.py` rule (A1) vs a non-constant immediate

**Probe:** `tools/record_census/probe_a1_nonconst_immediate.ll` — a hand-authored
lowered-IR module, **deliberately not registered with lit or ctest**.

**Re-run:**
```
python3 tools/free_pairing_check.py --explain \
    tools/record_census/probe_a1_nonconst_immediate.ll
```

### 6.1 VERDICT: **A1 ACCEPTS a non-constant classical immediate. Inc 2 carries no checker change for the Grover shape.**

```
OK @probe_load       line 46 [%h] via A1-classical-immediate (witness lines 41,43,45)
OK @probe_two_loads  line 64 [%h] via A1-classical-immediate (witness lines 58,60,63)
OK @probe_const      line 95 [%h] via A1-classical-immediate (witness lines 93,94)
UNPROVEN A1-imm-not-classical @probe_rail  line 75 [%h]   <- negative control FIRES
UNPROVEN A1-imm-not-classical @probe_param line 86 [%h]   <- boundary
free_pairing_check: 6 rail mint(s) of which 1 left allocated, 5 cqrt_free site(s):
3 verified, 0 violation(s), 2 unproven      rc=1
```

* `@probe_load` — `%imm = load volatile i32, ptr @off` in the `cqrt_addc_i32`
  immediate slot: **discharged by A1**. `provably_not_a_rail` answers True for a
  plain instruction result that is neither a known rail nor a formal parameter.
* `@probe_two_loads` — the **exact customer shape**: two *separate* volatile loads
  (`slice_control_seq_grover.c` makes `off` volatile precisely so the `+off`/`-off`
  pair survives canonicalization, so (A2)'s write-history reduction cannot pair
  them and only (A1) can discharge the rail). **Also discharged by A1.**
* `@probe_rail` — the bd `az1h` shape, a real rail in the immediate slot:
  **flagged**. The instrument is live; a verdict from the other functions means
  something.
* **`@probe_param` is the one boundary Inc 2 must know about.** A formal
  **parameter** in the immediate slot is refused (`provably_not_a_rail` explicitly
  declines to vouch for one), so if M-C ever lowers `q += k` where `k` is a
  function parameter — a Phase-6 clone's classical argument is exactly that shape
  — stage 2b reports UNPROVEN and the slice **fails** (rc=1). That is either a
  checker change or an M-C decline, and it is a decision, not an accident.

---

## 7. Census 0.6 — Risk-1 design artifact (the dephasing premise)

**File:** `tools/record_census/design_artifact_record_dephasing.py`.

> **DESIGN ARTIFACT — NOT A TEST, NOT A GATE, NEVER WIRED INTO ctest.** Same
> category as `docs/design/rssa-swap-control/prototype_semantics.py`. Rule 2 and
> the owner decision of 2026-06-10 put simulation out of scope as a correctness
> gate; this file may be cited as a numeric illustration of the standard
> record/decoherence argument and **never** as evidence that a lowering is
> correct.

**Re-run:** `python3 tools/record_census/design_artifact_record_dephasing.py`

### 7.1 Section A — the premise

| a, b (rad) | (i) no record, P(0) | (ii) CNOT record traced out, P(0) | interference term | closed form −½·sin a·sin b |
|---|---|---|---|---|
| π/2, π/2 | **0.000000000000** | **0.500000000000** | −0.500000000000 | −0.500000000000 |
| 0.5, −0.5 | 1.000000000000 | 0.885075576467 | +0.114924423533 | +0.114924423533 |
| 0.5, 0.25 | 0.865844434437 | 0.925150322646 | −0.059305888209 | −0.059305888209 |

The recorded value equals the classical mixture
`cos²(a/2)cos²(b/2) + sin²(a/2)sin²(b/2)` to 1e-12 by a third, independent
computation; the reduced-state purity drops to 0.5 (maximally mixed) at
a = b = π/2. **The premise holds numerically.**

### 7.2 Section B — the `slice_control_seq_grover` shape, θ = 0.5 rad

> **THE M-C ROW BELOW IS THE *STRICT*-FENCE NUMBER, NOT THE RULED *SC* ONE.** It
> assumes no ancestor rail is minted at all, i.e. that **every** site in the
> program lowers in place. Under the fence actually ruled (SC, §3), only **1 of
> the 3** sites per function is eligible and the `sub` still mints an ancestor —
> so `P(|0⟩)` after Inc 2 is **not** 1.000 for this slice. See **§9.8**. This
> artifact predates the fence ruling and has not been re-run for the SC shape.

| | P(wire = \|0⟩) after the S† |
|---|---|
| **M-C lowering** (in-place `cqrt_addc`, no ancestor rail minted — the **STRICT** fence) | **1.000000000000** — S† returns the wire exactly to \|0⟩ |
| **shipped lowering** (out-of-place `_hl`, ancestor kept live) | **0.885075576467** = cos⁴(θ/2) + sin⁴(θ/2); purity 0.885 |
| d = 4 register, no record | 1.000000000000 |
| d = 4 register, `\|a⟩ → \|a+3 mod 4⟩` record (the real `add_hl(h0, 3)`, not a CNOT) | 0.885510525061 |

The d = 4 row exists so the claim does not rest on the qubit special case: any
*injective basis-label copy* makes the reduced state diagonal, and an out-of-place
`add_hl(q, 3)` is exactly that.

---

## 8. What these numbers decide

> **REVISED 2026-08-27 under the owner-ruled predicate (§2R).** The two paragraphs
> that the ruling moved are restated first; the superseded text follows,
> struck-through in prose rather than deleted, because the delta is the evidence.

### 8R (ruled predicate — the live answers)

**Is Inc 1 shippable standalone? — YES, and it is now nearly free, but that
CHANGES WHAT IT BUYS.** Under the ruling Inc 1 (the dead-**descendant** half)
newly declines **ZERO real modules**: its single census hit is the §9.3 artefact,
an already-lowered fixture whose rail its own comment declares **untainted**, so
the guard cannot fire there. The regression cost that made Inc 1 contentious —
reversing two deliberately-pinned accept fixtures — **is gone by construction**,
because the ruling's clause 3 exempts exactly those (`%d` is measured after the
theta ⇒ live ⇒ user data). Inc 1 is therefore a **pure net with no measured
regression on this corpus**.

The flip side, and it must be said plainly: **an increment that declines nothing
on the whole corpus has no positive witness in the corpus either.** Inc 1's
value becomes entirely prospective — it catches the bd `6uqc` P4 straight-line
shape, which is *not represented* among the 760 modules. Rule 12 therefore
carries the whole load: Inc 1 must ship with **new** decline fixtures written for
the P1/P4 probe programs in bd `6uqc`'s comments, since no existing fixture will
turn red to prove the guard works. A guard that changes no test result is
indistinguishable from a guard that does nothing.

**Message churn MOVED — it did not shrink, and predicting that it would was
wrong.** This paragraph previously said the pre-ruling **13** was "now a strict
upper bound". Census 0.4 has since been **re-run under the ruled predicate**
(§5), and that claim is **measured false**: the population is **9**, but only
**4** of the 13 survive — **9 left and 5 arrived**, so the two sets are not
nested and 13 bounds nothing. The reasoning behind the prediction was half right
(clause 3 does exempt records, and it is why all 9 left) and missed the two
clauses pulling the other way: clause 1 admits alloc-minted rails (4 arrivals)
and the `ruled` predicate drops the control-position-compare carve-out (1
arrival). Read §5.2 for the per-fixture attribution. **The lesson is the one this
spike keeps re-learning: a predicate change is not a monotone filter, and a
population under a new predicate must be re-measured, never bounded by
argument.**

**Inc 3 (the dead-ANCESTOR half) is where the campaign's customer lives:** 2
modules, both real, one of them `slice_control_seq_grover` — bd `nepx`'s own
example, found here independently by two methods. Under plan-v1 the Inc-1 / Inc-3
split was "6 real then 3 more"; under the ruling it is **"0 then 2"**. That is a
sequencing argument, not a sizing one: if Inc 1 alone cannot be witnessed by the
corpus, **the pair Inc 1 + Inc 3 can be** (`seq-grover`), so shipping Inc 3
promptly after Inc 1 is what gives the guard an end-to-end witness. Splitting
them is still justified — they are different cone directions and different
proofs — but Inc 1 should not be allowed to sit alone for long.

> **AND READ §9.8 BEFORE SEQUENCING ANY OF IT.** `seq-grover` is Inc 3's witness
> *and* Inc 2's customer, and under the ruled **SC** fence Inc 2 does **not** fix
> it — only 1 of its 3 sites per function is SC-eligible, so the ancestor record
> survives, the slice stays dephased, and **Inc 3 then declines it**. "Ship Inc 3
> promptly after Inc 1" and "Inc 2 fixes the customer" cannot both be planned for
> without resolving that first.

**One thing Inc 1 must decide that this census cannot:** §2R.5's ambiguity. The
literal reading of clause 3 is the **over-exempting** one, and it costs 5 modules
and 8 rails. Both readings ship in the script; the owner picks.

### 8.old (plan-v1 predicate — SUPERSEDED, retained)

~~**Is Inc 1 shippable standalone?** *Yes, but it is not free and it is not
mechanical.*~~ It newly declines **6 real modules** (7 minus the §9.3 artefact) and
turns **13 negative fixtures'** messages over to a new guard — of which 2 are
resolvable by ordering M-A *after* `declineStaleRecordOps` in the shared slot.
**← both figures are the plan-v1 ones and both moved: under the ruling it is 9
fixtures over a DIFFERENT set, of which 3 pin the M-A slot. See §5.2.** But
**two of the six are the documented accept boundary of the existing stale-record
guard** (§9.1), so Inc 1 is not "add a net"; it is "reverse a recorded
accept decision", which needs the same owner ruling class as bd `nepx`.
**← The ruling of 2026-08-27 is exactly that owner ruling, and it went the other
way: the boundary STAYS accepted, by principle. See §9.1R.**

~~**Inc 3 (ancestor half) is small and safe:**~~ 3 further modules, one of which is
the very slice bd `nepx` says is already wrong. Splitting Inc 1 / Inc 3 is
justified by the measurement. **← now 2 modules; see §8R.**

**Does the M-A carve-out for control-position compares matter?** *Measured: no,
not today.* **0 exemption hits** of either kind, in either direction, over 760
modules — because a Phase-4 compare flag is always stripped and freed before any
later theta, so plain liveness already excludes it. This is the direct answer to
session-review amendment (1) ("confirm via Inc0 census"): the carve-out is inert
on the current corpus and is therefore a correctness provision for future shapes,
not a regression-avoidance one. The corpus contains only 22 chained thetas, so
this is weak evidence — write the carve-out anyway, but do not claim it was
validated. **Under the ruling this becomes moot in the same direction:** the
ruling's five clauses do not contain the carve-out at all, so `ruled` does not
apply it, and the count of rails it *would* have removed is still **0**. Plain
liveness (clause 2) already subsumes it on this corpus, under both predicates.

> **CORRECTION — "the carve-out is inert" holds for the LOWERED corpus and NOT for
> the corpus census 0.4 is about.** Both the **0** figures above are measured over
> 760 **lowered** modules, which are by construction the ones that **compile**. On
> the **declining** corpus the carve-out is live: **6** negative lit fixtures carry
> a control-position-compare exemption under `plan-v1`, and on one of them
> (`control_swap_reject_nested_theta`) dropping the carve-out is the sole reason
> the fixture entered the at-risk set (§5.2). The generalisation from a positive
> corpus to a declining one was never measured; it is now, and it does not hold.

**Inc 2 regeneration size:** session-review amendment (2) set the threshold at
"> ~20 goldens ⇒ split the regeneration into its own reviewed commit". Measured:
**68 goldens** under the plan's own single-consumer wording, **84** under the
fence as handed to this census, **93** if Inc 2 also rewrites the uncompute plan.
**The threshold is exceeded 3–4x under every reading.** Split the regeneration,
and expect the 19–37 core goldens (§3.3) to need individual explanation while the
49–56 libm ones move mechanically.

**Inc 2 fence choice is a real decision, not a detail:** strict-F4 307 vs
single-consumer 233 sites. Every strict-eligible site with a prior out-of-place
consumer (74 of them) happens to have **no** later adjoint reading the parent in
today's corpus, so strict is not currently unsound — it is *resting on an
accident of the corpus*. Prefer SC. **RULED 2026-08-27: SC it is — the NARROW
single-consumer fence, 233 sites / 68 goldens. The 74 wider-reading sites are
DEFERRED with their "safe by accident" status recorded (§3, §9.7).**

**Inc 5 target population:** the orphan count (14, one family, one known root
cause in `lowerQramReads`) is a **rounding error**; the real Inc-5 population is
the **12 880 undischarged template/QRAM rails in 174 of 249 goldens**. Any Inc-5
plan sized from bd `iwr7`'s 14 is sized from the wrong number. Note also that the
14 orphans have a *named, local* producer fix (the `hasOneUse` guard), so they are
arguably not Inc-5 work at all.

**Inc 2 vs the checker:** no change needed for the volatile-load immediate;
one open decision for a parameter immediate (§6.1).

---

## 9. Contradictions with the plan of record and the bd issues

These are the findings worth arguing about. None is smoothed over.

### 9.1 Inc 1 would REVERSE a deliberately-pinned accept boundary — **SETTLED, see §9.1R**

`ir-pass/test/lowering_stale_record_add_before_theta.ll` and its sibling
`…_alias_before_theta.ll` are **both Inc-1 hits**. `OpcodeLowering.cpp`'s comment
block names the first by file and calls it the boundary that must stay accepted:

> `d = q + 1` SCHEDULED BEFORE a chained `theta(q, t2)` **stays accepted**: the
> template fires pre-Ry, capturing the record onto its own fresh rail — matching
> SSA semantics — and the later Ry on `q`'s wire cannot touch that rail (fixture
> `lowering_stale_record_add_before_theta.ll` pins this boundary).

And the sibling fixture's own header says the same thing in stronger words — it
calls the shape "this legitimate use-then-re-rotate program" and requires that it
"keep lowering" (bd `6j1`):

> the add is SCHEDULED BEFORE the chained theta. The template is emitted AT the
> add's position … capturing exactly the record `%qd` denotes onto its own fresh
> rail (the `lowering_stale_record_add_before_theta.ll` boundary, one diagonal hop
> removed). The closure must only ADD seeds for the backward wire walk — it must
> not erase the dominance proof that makes this legitimate use-then-re-rotate
> program keep lowering.

The plan's session-review amendment (4) lists that same fixture as "the accept
boundary — all as the plan states", i.e. as something the plan preserves.
**It does not.** M-A's whole premise is that the fresh rail `%h_op` is a *live
basis record* at the later `Ry`, and §7.1's numbers say the later Ry is dephased
by exactly that rail. The comment's reasoning ("the later Ry cannot touch that
rail") is true and *irrelevant* — the Ry does not need to touch the record to be
dephased by it.

So one of two things is true and the campaign should say which:
* the existing comment/fixture pin an **over-accept** of the P4 class bd `6uqc`
  describes, and Inc 1 correctly flips them (my reading — it is the same argument
  bd `nepx` makes about the golden); or
* M-A's descendant half is too wide.

Either way, **Inc 1 cannot be described as "a permanent net that declines nothing
currently accepted on purpose"**, and it needs the owner-ruling treatment bd
`nepx` is already getting, not just a Rule-13 round.

#### 9.1R RESOLUTION — owner ruling 2026-08-27

**The ruling took NEITHER horn as posed, and that is the interesting part.** It
did not accept that the fixtures pin an over-accept (horn 1), and it did not
merely narrow the descendant half (horn 2). It changed the *axis*: M-A's
predicate became **liveness-keyed**, so a record with a data use after the
rotation is **user data**, and its dephasing is **source semantics** rather than a
compiler defect. Under that clause both fixtures accept **because `%d` is
measured after the theta**, not because a shape-matcher was tuned to spare them.
Quoting the ruling: *"this preserves `lowering_stale_record_add_before_theta.ll`
and its alias sibling BY PRINCIPLE, not special case."*

Measured consequence: both fixtures **drop out of the M-A population** (§2R.4),
and this census re-ran with a pinned acceptance test (`--acceptance`) that fails
loudly if either ever re-enters.

**What the fixtures' own comments got right and wrong is now clear, and both
halves matter.** The comment's *mechanism* claim — "the later Ry on `%q`'s wire
cannot touch that rail" — remains **true and irrelevant** (§7.1's numbers: a
record dephases a later rotation without being touched). What the comment got
right is the *conclusion*, for a reason it never stated: `%d` is **live user
data**, the program asked for that record, and a compiler is not entitled to
refuse a program because the user's own data decoheres their own qubit. The
census's §9.1 was right that the stated reasoning does not support the pin; the
ruling supplies reasoning that does. **The fixture comments should be updated in
Inc 1 to say the true thing** — a comment that defends a correct boundary with a
wrong mechanism is exactly the "hardened by repetition" failure mode CLAUDE.md
records for the `fenv` prose.

### 9.2 The plan's RECORD definition does not cover bd `nepx`'s own leading example — **ADOPTED into the ruling**

> **RESOLVED 2026-08-27:** the ruling's clause 1 says records are *"entangled with
> W (ancestors AND descendants, **alloc-minted rails included**)"*. The
> definitional question this section raised is answered in the direction it
> argued for. **Its own worked example is now the load-bearing evidence for the
> §2R.5 ambiguity**: in `e2e-slice-io-chained-theta` the compiler-materialised
> `h0` *is* dead in C after the add, and the pre-lowering model calls it a hit —
> but read literally on LOWERED IR the ruling exempts it, because the spine's own
> `_unc` read and adjoint `Ry` count as "uses". Read §2R.5 with this section.
>
> **One correction to the numbers below, made by re-measurement.** This section
> says *"**19 further modules** have a chained theta whose only live entangled
> neighbour is an alloc-minted rail"* and lists 7 e2e slices + "12 lit fixtures".
> The machine-readable record does **not** support 19: `chained_theta_alloc_ancestor_only`
> is **3** under plan-v1 (`e2e-slice-io-chained-theta`, `lowering_io_tape_chained_theta`,
> `lowering_uncompute_borrowed_operand_free_order`) and **5** under the ruled
> predicate, and §2.2's own table row says 3. The 19 appears to have been counted
> over the **adjoint-Ry upper bound** (189 sites in 123 modules), i.e. over sites
> the §1.5 filter removes — the same class of error §1.5 documents. The
> section's ARGUMENT is unaffected and was adopted; its "19" is not a number to
> quote.

The plan defines records as *template-minted rails* (`cq_template_*` results,
`cqrt_qram_load_*` results). bd `nepx`'s headline sentence is:

> `cq_template_add_i32_hl(h0, 3) -> h1` ← **h0** kept live … at the S-dagger Ry
> the state is `sum_a c_a |a>_h0 |a+3>_h1 |a>_h4`: **h0** and h1 are basis records
> of h4's value

**`h0` is `cqrt_alloc_i32`-minted, so under the plan's own definition it is not a
record.** The census reports alloc-minted ancestors/descendants in separate
columns for exactly this reason:

* `seq-grover` is an Inc-3 hit **either way** (h1 alone carries it), so no verdict
  changes there;
* but **19 further modules** have a chained theta whose *only* live entangled
  neighbour is an alloc-minted rail — `e2e-slice-io-chained-theta`,
  `e2e-slice-qram-guarded-store{,-fp,-multi,-swapped}`,
  `e2e-slice-qram-local-uncompute{,-fp}`, and 12 lit fixtures. Those 19 flip
  between "green" and "declined" on the definition alone.

Worth stating precisely, because it points at the right fix: in
`e2e-slice-io-chained-theta` the source is `int x = cq_theta(seed,0.5); int y =
x + 1; int z = cq_theta(y,0.25);` — `x` is **dead** in C after the add, so the
live `h0` is a *compiler-materialised* record, not one the source asked for. That
is an **M-C** case (never mint the ancestor), not an M-A case. Deciding this
definitional question is a prerequisite for Inc 1, and answering it "records
include alloc-minted ancestors" without Inc 2 first would decline 19 more modules.

### 9.3 One Inc-1 hit is a corpus artefact, and it exposes a real blind spot

`lowering_uncompute_sink_move_past_unwalked_gate.ll` is written in
**already-lowered form** and its own comment says the rail is deliberately
untainted:

```
%idx = call i32 @cqrt_alloc_i32(i32 7)      ; live, but UNTAINTED — never walked
call void @cqrt_ry_i32(i32 %idx, double 2.500000e-01)
```

M-A guards *tainted* rotations, so it would not fire. The lowered-IR census cannot
see taint at all (handles are `i32` — blind spot A5), so it counts this. **Real
Inc-1 count: 6, not 7.** It was caught only by the independent pre-lowering
cross-check, which is the reason that cross-check exists.

### 9.4 bd `nepx` is WRONG about `slice_control_seq_regions`

bd `nepx` says, of the dephasing it diagnoses in `slice_control_seq_grover`:
*"Same for slice_control_seq_regions."* **Measured, by two independent methods:
it is not.**

`slice_control_seq_regions.c` is `q = cq_theta(q,0.5); if(q>5) cq_phi; if(q>3)
cq_phi; measure`. Its committed golden contains:

* exactly **one** `cqrt_ry`, and it is a *source* theta (immediately preceded by
  its `cqrt_alloc_i32(7)`) — so **zero chained thetas**, confirmed by the
  lowered-IR census and by the pre-lowering model (`chained: 0`);
* **no out-of-place arithmetic at all** — no `add`/`sub` template, hence no
  ancestor rail;
* both compare flags `h1`, `h3` minted, cswap-routed, `_unc`-stripped and freed,
  and both work rails `h2`, `h4` freed. Census 0.3 reports **0 undischarged rails**
  in that golden (against 2 for seq-grover);
* every gate after the single Ry is `cqrt_cswap` (the region's own routing
  mechanism, control = the flag it then strips) or diagonal `cqrt_rz`. There is no
  later non-diagonal gate for a record to dephase.

The mechanism bd `nepx` describes — "out-of-place `_hl` templates keep their
source rail **and** a later non-diagonal gate fires after them" — requires both
halves, and `seq_regions` has **neither**. The ticket's generalisation
("Every future multi-segment program with `q += c` between rotations has the same
defect") is correct; the specific attribution to `seq_regions` is not, and
**`slice_control_seq_regions.expected.log` should not be regenerated** under bd
`nepx`'s owner ruling. Only `slice_control_seq_grover.expected.log` is affected.

This also contradicts the Inc-0 task framing, which stated both slices were
expected ancestor hits and instructed that a census not showing them was wrong. It
was worth debugging: the census is right and the expectation was inherited from
the ticket.

### 9.5 bd `iwr7`'s corpus figure is stale, its count is exact

bd `iwr7` says "swept all **239** `tests/e2e/*.expected.log`". There are now
**249**. Its DESCRIPTION's per-golden numbers were orphan-cone *roots*; its NOTES
correction to **14** gates is exactly what this census measures, and the ten
goldens match name for name. Nothing else changes.

### 9.6 bd `1739` hole 1, quantified

The ticket says `free_pairing_check.py` is blind to template-minted rails.
Census 0.3 sizes that blindness: **12 880** template/QRAM rails across **174 of
249** goldens are minted, never discharged and never freed — every one of them
structurally invisible to the checker, in a suite that is green. That is the
number to use when arguing for doing bd `1739` before bd `iwr7` and bd `kqqv`.

### 9.7 The F4 fence as handed to Inc 0 is not the plan's own wording — **SETTLED: the NARROW reading wins**

> **RULED 2026-08-27:** *"M-C fence = the NARROW single-consumer reading (233
> sites / 68 goldens at HEAD); the 74 wider-reading sites are deferred with their
> 'safe by accident' status recorded."* Inc 2 is scoped to **SC**. The paragraph
> below stands as the measurement that made the choice decidable.

The plan (via bd `nepx`) says *single-consumer*; the fence handed to this census
says *only consumers **after** this call*. 307 vs 233 sites, 84 vs 68 goldens.
Neither reading is wrong on today's corpus (§8), but Inc 2 must pick one on
purpose, and the SC reading is the one whose soundness does not depend on the
corpus.

### 9.8 THE RULED SC FENCE DOES NOT FIX THE CAMPAIGN'S OWN CUSTOMER

**This is a first-order planning fact and it was not visible until the SC ruling
and the census 0.1 ruling were read together.** Each is fine on its own; the
combination leaves `slice_control_seq_grover` — bd `nepx`'s example, the slice
this whole campaign is named after — **still dephased after Inc 2, and then
LOUDLY DECLINED after Inc 3.**

**Measured, from `census-0.2-mc-population.json` (`all_candidates`, filtered to
the module) and the committed golden.** `slice_control_seq_grover` has **3
candidate sites per function**, in both `slice` and `main` (6 total):

| # | site | parent | prior consumers | strict | **SC** |
|---|---|---|---|---|---|
| 1 | `add_i32_hl(%h, %1)` → `%h_op` | `%h` (**alloc**) | none | ✓ | **✓ ELIGIBLE** |
| 2 | `sub_i32_hl(%h_op, %2)` → `%h_op3` | `%h_op` (record) | `%h_cmp1 = icmp_eq_i32_hl(%h_op, 5)` — the **region-1 compare**, at an EARLIER line | ✓ | **✗ excluded** |
| 3 | `add_i32_hl(%h_op3, %3)` → `%h_op4` | `%h_op3` (record) | `%h_cmp = icmp_eq_i32_hl(%h_op3, 0)` — the **region-2 compare**, earlier | ✓ | **✗ excluded** |

*(`%1`/`%2`/`%3` are the three volatile loads of `off`; the slice makes `off`
volatile precisely so the `+off`/`−off` pair survives `-O1` — see §6.1.)*

**Only site 1 is SC-eligible. The other 4 sites (2 per function) are inside the
DEFERRED 74** — they are excluded by SC's extra clause for one reason and one
only: their parent has a **PRIOR out-of-place consumer**, and that consumer is
the tainted-condition **region compare** the source itself wrote.

**What that means for the customer, step by step.** The chained theta in question
is the S† `cqrt_ry_i32(h4, −0.5)`, whose wire is `h4`. Under SC-only M-C:

* site 1 lowers in place ⇒ `h0` and `h1` collapse into **one** rail. Good — that
  is the whole of what SC buys here.
* site 2 does **not** ⇒ the `sub` still mints a **fresh** rail for the S† wire
  and **keeps its parent (the collapsed `h0`/`h1`) live**.
* that parent has **no use after the sub** — the golden's `h1` is never mentioned
  again — so at the S† `Ry` there is **still a live, DEAD-at-`T` basis record of
  the wire's value**: exactly the ancestor structure bd `nepx` diagnosed, one
  rail shorter.

*(Handle numbers above are the committed golden's; after M-C they renumber. The
structure, not the numbering, is the claim.)*

**`slice_control_seq_grover` therefore stays dephased after Inc 2.** And because
the surviving ancestor is *dead* at the theta, **Inc 3's M-A fires on it**: after
Inc 3 the slice does not merely stay wrong, it stops compiling — a **loud
decline** on the campaign's own headline program.

> **§7.2's `P(|0⟩) = 1.000` M-C row is the STRICT-fence number, not the SC one.**
> That row assumes *"in-place `cqrt_addc`, **no ancestor rail minted**"*, which is
> what happens when all three sites lower in place. Under the ruled SC fence site
> 2 still mints one, so the SC post-Inc-2 figure is **not** 1.000. The design
> artifact was written before the fence was ruled and has not been re-run for the
> SC shape; do not quote its M-C row as the SC outcome.

> **§3.3's listing of `control-seq-grover` among the changing goldens is a
> PARTIAL change under SC.** One of three gate-stream sites per function moves;
> the golden changes, but not into the fixed circuit. A reviewer regenerating it
> and seeing a diff must not read that diff as "the customer is fixed".

**The candidate resolution — RULED: APPROVED (owner, 2026-08-27; the position-aware, spine-discharge-aware deadness fence is adopted), and
deliberately not adopted here.** Replace SC's *"no earlier out-of-place
consumer"* clause with a **position-aware deadness fence**: *the parent has no
data use **AFTER** this call*, evaluated **spine-discharge-aware** (a prior
consumer is harmless once its own adjoint has already fired before this call).
On seq-grover that admits sites 2 and 3, because the golden shows region 1's
compare fully torn down — `icmp_eq_i32_hl_unc(h2, h1, 5)` then `cqrt_free(h2)` —
**before** the `sub` reaches `h1`.

Two things make this worth putting to the owner rather than dismissing:

* **it is provable exactly IN THE COMPILER, unlike in this text census.** §8's
  reason for preferring SC was that strict-F4's soundness "rests on a property of
  the corpus rather than of the fence" — but that was a limit of *measurement*: a
  textual sweep cannot order an emitter's own teardown against a later call. The
  pass **can** — the emitters know which `_unc`/`free` they minted and where — so
  in the compiler this is a *proof*, not an accident. The SC clause is a
  conservative stand-in for a check the census could not perform.
* **the alternative is that Inc 2 ships without fixing what Inc 2 exists to
  fix.** Deferring the 74 is fine as scope control; deferring the 4 sites that
  carry the campaign's only end-to-end witness is a different decision, and it
  should be made knowingly.

**Not a recommendation to widen the fence unilaterally.** The Prime Directive
direction is unchanged — over-accepting an in-place rewrite is a silent
miscompile — and the resolution above needs its own Rule-13 round and decline
partition. What is being reported is that **the ruled fence and the ruled M-A
predicate, both individually correct, do not compose into a fix for the customer
program**, and that no one asked for that combination.

---

## 10. Files this spike added

```
tools/record_census/census_common.py                    corpora + lowering cache + shared model
tools/record_census/census_01_guard_population.py       census 0.1 (3 predicates + --acceptance)
tools/record_census/census_02_mc_population.py          census 0.2
tools/record_census/census_03_orphan_rails.py           census 0.3 (+ --crosscheck)
tools/record_census/census_04_message_churn.py          census 0.4 (--predicate ruled|plan-v1)
tools/record_census/source_ir.py                        pre-lowering model (+ --validate [--predicate])
tools/record_census/probe_a1_nonconst_immediate.ll      census 0.5 probe (NOT registered)
tools/record_census/design_artifact_record_dephasing.py census 0.6 DESIGN ARTIFACT (NOT a test)
docs/prd/record-family/SPIKE-inc0-census.md             this document
docs/prd/record-family/census-0.1-guard-population.json               RULED predicate (headline)
docs/prd/record-family/census-0.1-guard-population-spine-aware.json   the §2R.5 priced ambiguity
docs/prd/record-family/census-0.1-guard-population-plan-v1.json       SUPERSEDED predicate, re-run
docs/prd/record-family/census-0.1-guard-population-plan-v1-preruling.json
                                                        the pre-ruling artifact, retained verbatim
docs/prd/record-family/census-0.2-mc-population.json
docs/prd/record-family/census-0.3-orphan-rails.json
docs/prd/record-family/census-0.4-message-churn.json                  RULED predicate (headline)
docs/prd/record-family/census-0.4-message-churn-preruling.json        the pre-ruling artifact, retained verbatim
```

**Revision 2026-08-27 (owner ruling).** Only `census_01_guard_population.py`,
`source_ir.py`, this document and the 0.1 JSONs changed. `census_01`'s revision is
additive: the chained-theta rule, the §1.5 adjoint-Ry filter, the rail graph and
the plan-v1 population are all **byte-for-byte reproducible** (`--predicate
plan-v1`; verified identical on all 16 headline keys against the retained
pre-ruling artifact). `source_ir.py` gained the ruled record class + clause 3 and
a second validate verdict; its **chained-theta** verdict is unchanged (506 agree /
1 source-only / 3 lowered-only). **No pass, runtime, test, golden or harness file
was touched.**

**Revision 2 — 2026-08-27, applying the Inc-0 adversarial review.** Two files and
this document changed; **still no pass, runtime, test, golden or harness file was
touched.**

* **`census_04_message_churn.py`** gained `--predicate ruled|plan-v1` (default
  `ruled`), a `narrowing_funnel` counter so §5.3 is generated rather than typed,
  a `predicate` key in the report, and two per-row keys
  (`src_exempt_live_after`, `src_records_after_theta`). **`census-0.4-message-churn.json`
  was REGENERATED** — the committed artifact had been produced by the *pre-ruling*
  `source_ir`, i.e. under what is now `plan-v1`, and it is retained verbatim as
  `census-0.4-message-churn-preruling.json`. `--predicate plan-v1` reproduces that
  retained artifact on every headline key, on the at-risk fixture set, and
  row-for-row modulo the two added keys.
* **this document**: §5 rewritten from the new run (13 → 9 over a **changed** set,
  §5.2); §8R's "the 13 is now a strict upper bound" claim **withdrawn as measured
  false**; §2R.1 gained the three-reading narrowing disclosure and §2R.5 the
  three-reading price table, the `lowering_uncompute_borrowed_operand_free_order`
  artefact finding, the withdrawal of "the same five modules", and §2R.5a (the
  review's spine-aware + late-guard recommendation, **pending owner
  confirmation**); §3.2's op mix corrected 155 → **159**; §1.4 gained blind spots
  **A8** and **U4**; **§9.8** added (the SC fence does not fix the campaign's own
  customer), with pointers from §3.3 and §7.2.
* **Nothing in censuses 0.1 / 0.2 / 0.3 / 0.5 / 0.6 was re-measured** — the
  reviewer byte-reproduced them. Every 0.2 figure quoted in §9.8 is read out of
  the existing `census-0.2-mc-population.json`.

The lowered-IR cache lives under `build/.record_census/` (gitignored; keyed by
SHA-256 of the `cq-opt` + plugin bytes and the input bytes, never a timestamp).
`rm -rf build` is a full reset. First run ≈100 s at 8 threads; later runs ≈8 s.

**Validation of the weaker (pre-lowering) model**, run by
`python3 tools/record_census/source_ir.py --validate`: over the 510 lowering lit
fixtures it agrees with the lowered-IR census on **506**, disagreeing on 4, each
explained —

* 3 `lowered-only` (`lowering_qram_guarded_store_railof`,
  `lowering_uncompute_borrowed_operand_free_order`,
  `lowering_uncompute_sink_move_past_unwalked_gate`): fixtures written in
  already-lowered form, with no `@cq_theta` to see (and §9.3's untainted rail).
  **This bullet already contained the evidence that
  `lowering_uncompute_borrowed_operand_free_order` is an ARTEFACT, and §2R.5 quoted
  it as a real hit module anyway** — a disagreement listed in one section and
  ignored two sections up. §2R.5 now marks it; the lesson is that a
  "disagreements, each explained" list is only useful if every *other* section
  that names those modules has read it;
* 1 `source-only` (`spec_reseed_theta_source`): the pre-lowering model propagates
  taint through a classical call `@cls(%q, 7)`, whereas the real pass *scrubs* a
  classical return, making the next `cq_theta` a fresh source rather than a
  chained one. A known over-taint, in the safe direction for census 0.4.

**The second verdict, added 2026-08-27** (`--validate` now also compares the
RECORD-HIT verdict): **505 agree, 5 disagree** under `ruled` — the §9.3 artefact,
the `spec_reseed_theta_source` over-taint above, and the **three lit modules of
§2R.5**, where the pre-lowering model (which has no discharge ops to
misinterpret) says HIT and the literal lowered reading says exempt. Under
`plan-v1`: **508 agree, 2 disagree** — the artefact plus
`lowering_bitcast_measure_after_rerotate`, whose `%b` is folded away by
`foldIdentityBitcasts` before the M-A slot (blind spot U3).

> **The independent confirmation is the DIRECTION on the OVERLAP, not set
> equality.** An earlier draft said the ruled disagreement set was "exactly
> §2R.5's". It is not — both sets have 5 members and they **overlap in 3**
> (§2R.5's correction). What is confirmed, and it is enough: on all **3** lit
> modules in the overlap the two independent views disagree in the **same
> direction** — pre-lowering says HIT, the literal lowered reading says exempt.
> A shared cardinality is not a shared set. It is the same error §5.2 records in
> the other direction — there a *smaller* count (13 → 9) was read as a subset when
> only 4 members are common. **In both cases the count was right and the
> population claim attached to it was not**; both were caught by listing the
> members, which is the only check that works.


## Post-Inc-1 note (2026-08-28): census INC1 vs the shipped guard's population

Census 0.1 counts the clone-RETURN rail (`%r = __cq_q_inner_1(...)`, the copy-destination
class) as a descendant record; the shipped Inc-1 guard deliberately does NOT (ruled
deferred to Inc 3, pinned by `lowering_live_record_clone_return_rail_accept.ll`). So the
census's INC1 figure reads ONE HIGHER than the guard's real population until the
copy-destination class lands — do not diff the two naively. Recorded by the Rule-13
re-review (N4).

**Inc-3 addendum (2026-08-28):** the copy-destination class LANDED in Increment 3
(`collectAncestorRecords`' copy-destination edge; `lowering_live_record_clone_return_rail_accept.ll`
was renamed to `..._measured_accept.ll` because M-C 2a had made its `u = r+1` an in-place
`cqrt_addc` on the returned rail, so the user's own measurement now collapses that rail
before the second Ry; the residual over-accept it used to pin is
`lowering_reject_live_record_clone_return_rail.ll`, spelled with a `mul`). The INC1-vs-guard
offset above is therefore closed. Two further corrections from the Inc-3 Rule-13 round: the
`?:` select-merge OUT rail (severance class 2) was NEVER masked by bd `lom0` — it compiled at
HEAD `d2828e3` from three lines of C (`lowering_reject_live_record_select_merge_out.ll`); and
`lowering_uncompute_borrowed_operand_free_order`, the §2R.5 spine-aware-only prediction that
did not flip, is an already-lowered fixture whose `cqrt_ry` calls are hand-written (in no
emitter-recorded set), so the guard cannot fire on it — the A5 artefact class, not a miss.
