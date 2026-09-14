# Track S — bd `s82e`: THE (R-leak)/(R-diverge) DETERMINATION

**Status: STOPPED AT THE FORK, per BRIEF_S §2.** The owner ruling D2 ("PROVE IT") rests on a premise
this track was told to test before writing a fix. **The premise is FALSIFIED.** No fix has been
written; no pass source has been touched. The worktree's `cq-opt` is BIT-IDENTICAL to the frozen
ORACLE, so every number below is an ORACLE number by construction.

---

## 0. VERDICT — **(R-diverge)**, and the bead's own three programs are the BENIGN half of the class

| program | rolled | hand-unrolled twin | leaked rails entangled with | that register afterwards | verdict |
|---|---|---|---|---|---|
| `w2k_noregion_invread` (bead) | 16 | 20 | `u` — the **per-trip** register | never read again; left allocated in BOTH forms | **(R-leak)** benign |
| `w2h_phase_inloop_invread` (bead) | 30 | 38 | `u` — per-trip | never read again; left allocated in BOTH | **(R-leak)** benign |
| `w2h3_select_iterlocal_invread` (bead) | 44 | 48 | `u` — per-trip | never read again; left allocated in BOTH | **(R-leak)** benign |
| **`s1_live_shift`** (Track S) | **10** | **14** | **`y` — the LOOP-INVARIANT register** | **`cqrt_ry_i32(h0,0.9)` then `cqrt_measure_i32(h0)`** | **(R-DIVERGE)** |
| **`s2_live_derived_region`** (Track S) | **19** | **25** | **`y`** | **`cqrt_ry_i32(h0,0.9)` then `cqrt_measure_i32(h0)`** | **(R-DIVERGE)** |
| `s3_live_rootmint_region` (control) | 22 | 22 | — (discharged) | same Ry + measure | **BYTE-IDENTICAL** |

All six ACCEPT at `opt` exit 0, verify-clean, STRICT stage 2b **`0 violation(s), 0 unproven`** on both
halves of every pair, and every rolled subject is genuinely ROLLED (a real back edge — verified in the
lowered IR, not inferred from the trace; an `_hl` template's second operand is a *classical* operand,
not necessarily a compile-time constant, so a trace showing `(h0, 1)` then `(h0, 2)` is NOT evidence of
unrolling).

### 0.1 The witness, read off the two traces

`s1_live_shift.c` — six lines of C, **no tainted control flow anywhere**:

```c
int y = cq_theta(5, 0.5);
int s = 0;
for (int k = 1; k <= 2; ++k) s += cq_measure((y >> k) & 1);
y = cq_theta(y, 0.9);                       /* the interference */
return s + cq_measure(y);
```

```
ROLLED (10)                                  HAND-UNROLLED TWIN (14)
 1 cqrt_alloc_i32(5) -> h0                    1 cqrt_alloc_i32(5) -> h0
 2 cqrt_ry_i32(h0, 0x1p-1)                    2 cqrt_ry_i32(h0, 0x1p-1)
 3 cq_template_lshr_i32_hl(h0, 1) -> h1       3 cq_template_lshr_i32_hl(h0, 1) -> h1
 4 cq_template_and_i32_hl(h1, 1) -> h2        4 cq_template_and_i32_hl(h1, 1) -> h2
                                              5 cq_template_lshr_i32_hl_unc(h1, h0, 1)   <-- MISSING ROLLED
                                              6 cqrt_free(h1)                            <-- MISSING ROLLED
 5 cqrt_measure_i32(h2) -> 0                  7 cqrt_measure_i32(h2) -> 0
 6 cq_template_lshr_i32_hl(h0, 2) -> h3       8 cq_template_lshr_i32_hl(h0, 2) -> h3
 7 cq_template_and_i32_hl(h3, 1) -> h4        9 cq_template_and_i32_hl(h3, 1) -> h4
                                             10 cq_template_lshr_i32_hl_unc(h3, h0, 2)   <-- MISSING ROLLED
                                             11 cqrt_free(h3)                            <-- MISSING ROLLED
 8 cqrt_measure_i32(h4) -> 0                 12 cqrt_measure_i32(h4) -> 0
 9 cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1)     13 cqrt_ry_i32(h0, 0x1.ccccccccccccdp-1)
10 cqrt_measure_i32(h0) -> 0                 14 cqrt_measure_i32(h0) -> 0
```

`s2_live_derived_region.c` is the same verdict through an in-loop **PHASE region** whose invariant base
is DERIVED (`p = y*3`): the twin additionally emits, all **before** the `cqrt_ry_i32(h0,0.9)` at its
line 18, `and_unc(h4,h1,4)`+`free(h4)`, `and_unc(h2,h1,2)`+`free(h2)` and
**`mul_i32_hl_unc(h1,h0,3)`+`free(h1)`** — the derived base itself, a full 32-qubit which-path copy of
`y`.

### 0.2 The analytic argument (no simulation — owner decision 2026-06-10)

`cq_template_lshr_i32_hl(h0,1) -> h1` is an out-of-place reversible op: it mints a fresh `|0⟩` rail and
applies CNOTs from `y`'s qubits `j ≥ 1` onto `h1`'s qubit `j-1`. `h1` is therefore a **which-path copy**
of 31 of `y`'s qubits, maximally correlated with them.

* **Unrolled.** `lshr_unc` runs the same CNOTs again (`x ⊕ x = 0`), returning `h1` to `|0⟩` — **a product
  state, disentangled** — and the `cqrt_free` is then a proven-`|0⟩` free (Rule 6, Bennett). At line 13
  the `Ry(0.9)` therefore acts on each `y`-qubit in its **pure** state `|ψ_j⟩ = α_j|0⟩ + β_j|1⟩`.
* **Rolled.** `h1` and `h3` are never uncomputed and never freed. Each `y`-qubit `j ≥ 1` stays maximally
  entangled with one or two ancilla qubits that are never touched again, so its reduced state at line 9
  is the **decohered** mixture `ρ_j = |α_j|²|0⟩⟨0| + |β_j|²|1⟩⟨1|`.

`cqrt_ry_<W>` is TENSORED (`CLAUDE.md` CORRECTNESS RISK §0), so per qubit with `R = Ry(0.9)`:

```
pure     :  P(1) = α² sin²(0.45) + β² cos²(0.45) + α β sin(0.9)
dephased :  P(1) = α² sin²(0.45) + β² cos²(0.45)
```

The `α β sin(0.9)` interference term is present in one circuit and absent in the other, and `α_j, β_j`
are both non-zero for every qubit (`y` is seeded at 5 and then `Ry(0.5)`-rotated, so no amplitude is
zero). `cqrt_measure_i32(h0)` at line 10 is the **only observable this program has**, and the two
circuits give it different distributions.

**So the two forms are not "the same unitary with a bigger leak". They are different channels on the
retained subsystem, and the difference is visible in the program's only output.** This is `CLAUDE.md`
Rule 8 in its literal words — *"a permutation that leaves a rail dirty **and entangled** still dephases
under later interference"* — and it is the same conclusion `LoopLowering.cpp:3169-3182` already records
in source for the sibling C-1 shape (*"Rolled and unrolled are therefore DIFFERENT UNITARIES"*).

### 0.3 Why D2's dichotomy does not hold — the third option is what the compiler ALREADY emits

D2 rejected **DECLINE** and **DISCHARGE**, reading "discharge" as *free the entangled rail* — which
would indeed be the Rule-6/Rule-8 hidden measurement. But the hand-unrolled twin does **not** free an
entangled rail. It emits **`_unc` THEN `cqrt_free`**: the adjoint first, which *disentangles* the rail
and restores `|0⟩`, and only then a proven-`|0⟩` free. That is Bennett and it is Rule-6 compliant. It is
not a third thing the compiler might learn to do — **it is what this same compiler emits today for the
straight-line spelling of the same source.**

`s3_live_rootmint_region` closes the point from the other side: the identical live-register interference
pattern, in a shape `invariantRegisterRoots` (3qlq C-1) already serves, is **rolled == unrolled
BYTE-IDENTICAL at 22 lines, with the rolled form discharging all four per-trip rails in-body**. So
*"the rolled form cannot pair the discharge here"* is false as a general claim about rolled loops. The
machinery exists, works, and is reached for one family of invariant bases and not another.

### 0.4 What D2's premise WAS true of

D2's evidence was the owner's rolled **value-arm** cascade — *"16 handles minted, 6 freed, 6 left over —
`h0 h5 h10` superseded `a`, `h3 h8 h13` the `a-3` temporaries."* Those are **superseded value
registers** in an out-of-place update chain. A superseded rail cannot be uncomputed without destroying
the answer that replaced it, so leaving it allocated genuinely *is* Rule 6's accepted leak, and freeing
it genuinely *would* be a hidden measurement. **That class is real and D2 is right about it.**

bd `s82e`'s class is a different one: **interior template rails whose adjoint the flat spine already
emits**, refused only because a marking predicate would not grant the in-body discharge. The two were
conflated because the bead's three exhibits happen to be the benign half (§0, rows 1–3) — their leaked
rails are entangled only with a *per-trip* register that is garbage in both forms.

---

## 1. ROOT-CAUSE REFINEMENT — the bead names the wrong site for 5 of the 5 measured programs

bd `s82e` and F-W2-3 attribute the class to `markIfRailLocal`'s *"accumulating loop-invariant tainted
input"* clause (`LoopLowering.cpp:3547-3553`). Measured, **that clause is not the firing site for any of
the five leaking programs**, because `markIfRailLocal` is never CALLED for any of them:

* `collapseFlattenedLoopRails` — the **only** caller of `invariantRegisterRoots` and `markIfRailLocal`
  (`LoopLowering.cpp:3689/3692/3694/3705`) — opens with `if (taint.InLoopFlattenedPreds.empty()) return;`
  (`:3598`), and `InLoopFlattenedPreds` is filled at exactly two sites, both in `SwapRouteEmit.cpp`
  (`:2908`, `:2933`) — i.e. only by an **in-loop region flatten**.
* **`w2k` and `s1` have no tainted control flow at all**, so nothing is flattened, `collapseFlattenedLoopRails`
  returns at its first statement, and the only marker that ever runs is **`markIfIterationLocal`**
  (`:2406`, called from `lowerLoops` at `:4182`). Its own clause — *"Every tainted OPERAND must be
  defined in L"* (`:2459-2464`) — is the silent refusal, and **it has no `invariantRegisterRoots`
  escape at all**. That is `CLAUDE.md` **L2** exactly: 3qlq Inc 1 widened `markIfRailLocal`'s closure by
  supplying it `Roots`, and left the *identical* clause in its sibling `markIfIterationLocal`
  un-widened.
* `w2h`, `w2h3` and `s2` DO flatten an in-loop region, so `collapseFlattenedLoopRails` runs — but
  `collapseRailPhisIn` returns `NotClaimed` (no tainted header phi) and `invariantRegisterRoots` then
  returns **false**, so the `else if` at `:3693` short-circuits and `markIfRailLocal` is again never
  called. The refusing site is `invariantRegisterRootsImpl` clause **(ii)** (`:3290-3302`), which admits
  only a classical-arg-0 `cq_theta`.
* And the reason clause (ii) refuses `w2h`/`w2h3` — whose invariant base **is** a root mint (`y =
  cq_theta(5,0.5)`) — is that **`-O1` LICM hoists the loop-invariant `y & 1` into the preheader**
  (rolled trace line 3, `cq_template_and_i32_hl(h0,1) -> h1`, *before* the loop). The body then reads
  the **hoisted TEMPLATE rail `h1`**, not `y`. That is verbatim the case `invariantRegisterRoots`' own
  header already says it refuses and measures as the discriminating control `z_preheader_rail8`
  (`LoopLowering.cpp:3205-3210`). `CLAUDE.md` Rule 9's LICM fence, one more time.

**Consequence for the fix:** a fix aimed at `markIfRailLocal`'s clause would move **none** of the five
programs. The bead's "WHAT A FIX NEEDS" is aimed at a site that never executes for its own exhibits.

---

## 2. What is NOT yet decided, and why I stopped

BRIEF_S §2: *"If it is (R-diverge), **STOP and come back** — that is an owner decision again, not
yours."* It is (R-diverge). Nothing in `ir-pass/`, `include/`, `runtime/`, `tools/` or `tests/` has been
touched on this branch; the only files added are this record and `trackS/probes/`.

The three dispositions now on the table are **not** D2's three, and the first is new:

* **(S-a) BUILD THE PAIRING** — extend the root-mint admission of `invariantRegisterRoots` to
  `markIfIterationLocal`'s slot, and/or teach clause (ii) to peel a **hoisted loop-invariant template
  rail** back to its root mint. `s3` shows the discharge is emittable for this exact interference
  pattern. ⚠ This is the widening `Uncomputation.cpp:982-1000` names explicitly, and its stated price is
  non-negotiable: *"the obligation is a real multiplicity test (same enclosing marked body, or equal
  trip multiplicity), not a re-reading of these two."* A hoisted preheader gate paired with an in-body
  `At` is `K` adjoints against **one** forward gate — an **over-reversal**, which is a worse failure
  than the leak (a wrong unitary AND a dirty free, vs a wrong unitary alone).
* **(S-b) DECLINE the divergent sub-case only** — loudly refuse a loop that leaves a rail entangled with
  a register that is **live after the loop**, while leaving the benign per-trip sub-case (rows 1–3)
  accepting. This is narrower than the blanket decline D2 rejected: it would **not** touch the owner's
  rolled cascade, whose leftovers are superseded value registers with no later interference.
* **(S-c) D2 AS WRITTEN** — the explicit "left allocated because entangled" disposition. This remains
  correct **for the superseded-value-rail class D2 was shown**, and is **unsound as stated for the
  class bd `s82e` measures**, because §0.2's programs have no proof to make: their disposition is not
  "correctly left allocated", it is "wrong".

**These are owner decisions.** Under the 2026-09-14 **Q3** ruling (*correctness over expressiveness*)
and the 2026-09-11 ruling (*an over-decline is a defect*), (S-a) is the ruling-consistent target and
(S-b) is its Prime-Directive fallback for whatever (S-a) cannot prove. (S-c) alone would ship a
disposition that is provably false for `s1`/`s2`.

---

## 3. Instrument note (BRIEF_S §4, `CLAUDE.md` L10) — carried in every record this track writes

**The rolled-vs-hand-unrolled trace pair is the ONLY instrument in the tree that sees this class.**
STRICT stage 2b `free_pairing_check.py` reports **`0 violation(s), 0 unproven` on all ten modules
measured above**, including both halves of both divergent pairs — it counts `cqrt_alloc` **SITES**, and
a template-minted rail has no `cqrt_alloc` to count. **2b is not clearance here and is not cited as
such.** `e2e-loop-twin-matrix` is the tree's rolled-vs-unrolled instrument, and this track does not run
it (PROTOCOL: the merge-and-gate agent does).

## 4. Gate lines

See `GATES.md`. Every measurement above is `ran:`, none `cited:`.

---

## 5. The witness, MADE TO FAIL ON PURPOSE (`CLAUDE.md` L10 — and it lied three times first)

My instrument is `trackS/probes/rs.sh` + a trace diff, copied from Track W's `rv2.sh`. **Before citing a
single number from it I attacked it, and the inherited spelling failed three attacks in the PASS
direction.** All three are now closed and re-attacked; the cases live in `probes/selftest/`.

| # | attack | inherited `rv2.sh` behaviour (MEASURED) | hardened `rs.sh` |
|---|---|---|---|
| 1 | **STALE TRACE.** Run a probe successfully; then make stage 3 impossible (drop `main`) **without changing the basename**; re-run. | **`mutant_stale2\|ssub\|ACCEPT\|lines=8`** — a count for a run that never linked and never executed. `clang … && ./a > $P.trace` leaves the *previous* run's trace in place, and `wc -l` reads it. | `LINKFAIL\|<ld message>`; every artefact for the basename is `rm -f`'d before the probe runs. |
| 2 | **EMPTY MODULE.** A 0-byte `.c`. | **`mutant_empty\|ssub\|ACCEPT\|lines=`** with stage 2b `0 violation(s)` — the passthrough early-out accepting nothing (bd memory `empty-module-accepts-vacuity-trap`). | `VACUOUS-S1 (no @cq_ intrinsic call …)`. Also fires on a well-formed but quantum-free module (`mutant_noquantum`). |
| 3 | **EMPTY COUNT PRINTED AS A RESULT.** `lines=` with no integer. | printed and would have been read as a row. | `NOTRACE`. |
| 4 | **IS "BYTE-IDENTICAL" A REAL COMPARISON?** Perturb `s3`'s twin by one angle digit (`0.3` → `0.31`). | — | the diff fires on exactly one line (`cqrt_rz_i1(h2, 0x1.3333…p-2)` vs `0x1.3d70…p-2`), so `s3`'s `22 == 22` identity is a **live** check, not a vacuous one. |

**After hardening, all twelve determination probes were re-run and every number above is unchanged** —
the hardened harness is not a weaker command than the one that produced them (`CLAUDE.md` L10: *a
harness that runs a weaker command than lit measures itself, not the fixtures*).

⚠ **This is a finding about Track W's harness, not only mine.** `rv2.sh`
(`$SESP/trackW/review_r2_probes/rv2.sh`) has defect 1 verbatim, and it is the harness that produced
F-W2-3's 16/20, 30/38 and 44/48. Those three numbers are **right** — I reproduced all three
independently on a hardened harness — but they were produced by an instrument that *could* have lied.
Worth one line in whatever succeeds it.

---

## 6. L1 / L2 / L3 (BRIEF_S §5) — answered for the SITE, since no fix has been written

### L1 — where the refusal sits relative to the round-2 fixpoint, measured

| stage | entry point 1 (`CQLoweringPass::run`) | entry point 2 (the `runOnFunction` shim) | taint it sees |
|---|---|---|---|
| `lowerLoops` → `markIfIterationLocal` (`LoopLowering.cpp:4182`) | `:393` | `:1000` | **ROUND-1 only. NEVER re-asked.** |
| `collapseFlattenedLoopRails` → `invariantRegisterRoots` / `markIfRailLocal` | `:493` (round 1) | **absent** | round 1 |
| `repropagateControlMerges` → `collapseFlattenedLoopRails` (last statement) | `:509` | `:1027` | round 2, post-fixpoint |

**`markIfIterationLocal` — the site that actually refuses `w2k` and `s1` — runs at ROUND-1 taint in
both entry points and is never re-asked.** A value that only `repropagateControlMerges` taints is
invisible to it: `CLAUDE.md` L1's **PREDICATE** species, live and unrepaired. Any fix placed there owes
the standard cure — RECORD the question at the site that asks it and RE-ASK it after the fixpoint in
**both** entry points.

⚠ The shim's pre-existing twin-pipeline divergence (`TaintPropagation.cpp:1869-1872`: the shim does
**not** call the round-1 `collapseFlattenedLoopRails` at all, inherited from bd `8h7d.5`, "the shim has
zero callers") is **not mine to repair and must not be widened**. Note that (S-a), if built at
`markIfIterationLocal`, would land in the one stage the shim *does* run in both entry points — which is
a reason to prefer it, not a hazard.

### L2 — the set that shares the closure, and the one that was left behind

The *"tainted operand defined outside `L`"* refusal is spelled **three times** over the same walk:

| site | spelling | got 3qlq Inc 1's `Roots`/`onRail` escape? |
|---|---|---|
| `markIfRailLocal` `LoopLowering.cpp:3546-3553` | `!L->contains(OpI->getParent()) && !onRail(Op)` → `return` | **YES** — `Roots` from `collapseRailPhisIn` ∪ `invariantRegisterRoots` |
| `markIfIterationLocal` `:2459-2464` | `if (!OpI \|\| !L->contains(OpI->getParent())) return;` | **NO — no `Roots` parameter at all** |
| `tryBreak` (B4 body scan) `:1975-1978` | its own refusal | n/a (a different question) |

**That is `CLAUDE.md` L2 verbatim** — *"when you WIDEN a set, ask what OTHER set was computed over the
same closure"*. 3qlq Inc 1 widened one of the two identical clauses and left the sibling untouched, and
the sibling is the one a loop with **no tainted control flow** reaches.

⚠ **And the `L2` warning BRIEF_S §5 carries about this triple is load-bearing and I did not disturb
it**: for `store i32 %h, ptr %gep` the operand list is `{value, pointer}` so the tainted value is caught
by accident, while a `load`'s only operand is the pointer, so the load side never fires
(`$SESP/trackL/SCOPE_L1a.md` §4.4(B)). Do not "tidy" the three to scan the pointer operand only.

### L3 and its MIRROR — no caller added, and the trigger the next one must read

I added **no** caller to any shared predicate. The mirror obligation is therefore about **(S-a)**, and
it is explicit, in another file, and aimed at exactly this:

> `Uncomputation.cpp:982-1000`: *"Nothing here refuses that pairing. It cannot arise today for a reason
> that lives in ANOTHER FILE: `markIfRailLocal` … refuses to mark any body that reads a tainted value
> DEFINED OUTSIDE `L` and not on the rail … **WIDEN THAT MARKING AND THIS BECOMES REACHABLE with no
> test to catch it. If you are here because you relaxed it, the obligation is a real multiplicity test
> (same enclosing marked body, or equal trip multiplicity), not a re-reading of these two.**"*

**Direction of use, stated as L3's mirror requires:** (S-a) is a **GRANTING** widening of that marking,
i.e. exactly the direction the trigger forbids without the multiplicity test. `invariantRegisterRoots`
already pays that price for its own admission — its whole proof is *"a root mint CANNOT be that gate"*
(`LoopLowering.cpp:3200-3212`: an alloc-minted rail is excluded from the M-B interior partition by
`isInteriorTerminalHandle` clause (I1), so the interior driver can never place an `At` for it). A
widening that admits anything **other** than a root mint — in particular the **hoisted loop-invariant
TEMPLATE rail** that `w2h`/`w2h3`/`w2k` actually read after LICM — does **not** inherit that argument
and owes the multiplicity test in full. That is the single hardest part of (S-a) and it is why I am not
guessing at it.

⚠ One more, in the opposite direction: `invariantRegisterRoots`' header already names this exact case
as the **discriminating control it deliberately refuses** (`z_preheader_rail8`, `:3205-3210`). It is a
retirement trigger in all but name, and (S-a) must argue with it rather than around it.

---

## 7. ATTACK SURFACE handed to the Rule-13 reviewer

Three rounds budgeted (BRIEF_S §6) — **none spent**, because the fork closed the increment before a fix
existed. What a reviewer should attack first, in order:

1. **The (R-diverge) determination itself.** It rests on `cqrt_ry_<W>` being TENSORED (`CLAUDE.md` §0)
   and on the leaked rail being a CNOT-copy that is never touched again. Attack: is there a reading in
   which `s1`'s leaked `h1` is *not* entangled with `h0` — e.g. if `cq_template_lshr_i32_hl` were an
   in-place relabel rather than an out-of-place copy? (It is not: the trace shows a fresh `-> h1` and
   the unrolled twin's `lshr_unc(h1, h0, 1)` takes **both** rails, which is the adjoint of a
   two-register op.)
2. **`s3` as the control — I ATTACKED THIS ONE MYSELF AND IT HELD.** If `s3` were byte-identical for a
   reason *other* than the rolled form discharging in-body, §0.3's "the machinery exists and works"
   collapses. MEASURED in `s3_live_rootmint_region.ssub.ll`: block `%2` is the loop body (`preds = %2,
   %0`, back edge `br i1 %6, label %1, label %2, !llvm.loop !32`), and the forward mints
   (`cq_template_and_i32_hl`, `cq_template_icmp_eq_i32_hl`) **and** the discharge
   (`icmp_eq_i32_hl_unc`, `and_i32_hl_unc`, **both** `cqrt_free`) are ALL inside `%2` — in-body, once
   per trip. The `cqrt_ry_i32(%h, 9.0e-01)` interference is in the exit block `%1`, after the loop.
   So the rolled form genuinely pairs one adjoint per forward gate per activation and discharges
   **before** the interference. Nothing is left for a reviewer here; attack the *other* four.
3. **The benign/divergent split.** I classify rows 1–3 benign because the leaked rail's partner `u`
   is dead. Attack: a program where the *per-trip* register is itself later interfered (e.g. `u`
   accumulated into a carried register, or measured **after** a further rotation) — that would move a
   bead exhibit from (R-leak) to (R-diverge) and would widen the population again.
4. **The three programs most likely to be the next hole**, if (S-a) is ever built: (i) a hoisted
   loop-invariant template rail read by the body **and** consumed in the preheader (the exact
   preheader-`G` / in-body-`At` multiplicity pairing `Uncomputation.cpp:990` names); (ii) a loop whose
   invariant base is a root mint reached through a **dtzb in-place chain** (`peelInPlaceBase` grants it,
   `onRail` and clause (ii) must agree — Rule 14, three spellings of one question); (iii) a **nested**
   loop where the inner body is marked and the outer invariant read is refused, so the multiplicity is
   `K_inner × K_outer` against one.
5. **bd `1yeu` — the structural instrument gap.** Every probe here is ONE FUNCTION PER MODULE. A
   cross-function spelling of this leak (the invariant register passed as an argument) is invisible to
   every corpus and gate in the tree, including mine. I did not build one and I say so.

---

## 8. The bd `wx8g` record correction (BRIEF_S §5, last bullet) — LANDED IN SOURCE, PENDING IN `bd`

`TaintPropagation.h:790` has said *"READ 'EVERY GRANT' AS 'EVERY R7-LOOP GRANT'"* since Track W's review
round 2. But **three sites a reader meets FIRST still said the unscoped thing**, and `CLAUDE.md`'s
L7-with-a-twist is explicit that a correction not applied where the reader reads is not a correction.
Scoped, comment-only:

* `ir-pass/include/TaintPropagation.h:772` — the headline `⚠ IT COVERS EVERY GRANT …`, 18 lines **above**
  the scoping note, so it was the first thing a reader met.
* `ir-pass/src/ArmClassify.cpp:5074` — `CLAUDE.md's L1: THE RECORD MUST BE AT EVERY GRANT.` at the
  record site itself, with the two new divergent programs named.
* `ir-pass/test/control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll:35` — the fixture header.

**MEASURED: the rebuild after these edits is BIT-IDENTICAL to the ORACLE** (`cq-opt`
`5c6f7490a81c7505…`, `libCQPass.so` `5276f7ab…`), so no gate result moves and every gate line in
`GATES.md` remains valid for the tip.

⚠ **NOT DONE: the `bd wx8g` NOTES text itself.** I did not write to `.beads` — five tracks are running
concurrently against a local Dolt DB, and a worktree-local bd write is a merge hazard the PROTOCOL does
not cover. **Exact text for the orchestrator to append to bd `wx8g`:**

> 2026-09-14 (bd `s82e` / Track S): SCOPE CORRECTION. This increment's re-ask covers **every R7-LOOP
> grant**, not "every grant". The leak class is REGION-INDEPENDENT and the R7 slice is a strict subset;
> a sibling with no tainted control flow at all still leaks silently. Scoped in source at
> `TaintPropagation.h:772`, `ArmClassify.cpp:5074` and
> `control_inplace_ry_reject_rail_inloop_carried_invariant_read.ll:35` (the site at
> `TaintPropagation.h:790` already carried it). ⚠ Track S additionally MEASURED that the residual class
> is not uniformly a Rule-6 accepted leak: `s1_live_shift` (10 vs 14) and `s2_live_derived_region`
> (19 vs 25) leave a per-trip rail entangled with a loop-INVARIANT register that is afterwards
> re-rotated and measured, so rolled and unrolled are DIFFERENT UNITARIES there — see bd `s82e`.

---

## 9. What I could not do

* **No fix.** BRIEF_S §2 instructs a STOP on (R-diverge); the disposition is an owner decision.
* **No `bd` write** (§8) — text handed over instead.
* **No twin-matrix run** (PROTOCOL: the merge-and-gate agent's). **Cells requested — see §10.**
* **No corpus sweep / injection matrix / `ctest -R ir-pass-lit` at hand-off.** These gate an
  implementation, and there is none: the binary is bit-identical to the ORACLE, so a sweep would
  compare a binary with itself and an injection matrix would have no new accept to mutate. Running them
  would be a gate that measures nothing — the failure mode `CLAUDE.md` L10 names. The one fixture I
  touched was run (`lit --filter`, 1 passed).
* **No cross-function spelling** of the leak (bd `1yeu`) — structurally invisible to every instrument
  in the tree, mine included.

## 10. Twin-matrix cells REQUESTED (BRIEF_S §4 — named, with reasons; I do not generate them)

Whatever disposition is chosen, the tree today has **no cell that can see this class**, because
`e2e-loop-twin-matrix`'s axes are all *in-loop control regions* and two of the five leaking programs
have **no tainted control flow at all**.

| requested cell | reason |
|---|---|
| `m_noregion_invread_dead` (= `w2k_noregion_invread` + twin) | the benign (R-leak) half, at 16 vs 20. Pins that the class exists and that the current disposition for a DEAD partner is the accepted leak. **Expected verdict: DIVERGE (quarantined, blessed).** |
| `m_noregion_invread_live` (= `s1_live_shift` + twin) | the **(R-diverge)** half at 10 vs 14, with no control flow at all. This is the cell that would have caught the class. **Expected verdict today: DIVERGE. It must NOT be blessed** — it is a wrong unitary, and quarantining it would do exactly what `CLAUDE.md` L10 warns about (*"a gate expected to be red is a gate people stop reading"*). |
| `m_region_derivedbase_live` (= `s2_live_derived_region` + twin) | 19 vs 25 — the same divergence reached through an in-loop PHASE region with a DERIVED invariant base, i.e. `invariantRegisterRoots` clause (ii). Separates "no region" from "region, wrong base". |
| `m_region_rootmint_live` (= `s3_live_rootmint_region` + twin) | **the positive control, 22 == 22.** Without it the three cells above look like "rolled loops leak" instead of "this closure gap leaks", and a future widening has nothing to regress against. |

⚠ Per `CLAUDE.md` L10 and the quarantine file's own rules, the `_live` cells must be adjudicated in
writing, **never** `--regenerate`d — bd `gfsk`: `--regenerate` once silently ate 54 lines of Rule-13
ruling prose from a baseline header and reported success.

---
---

# PART II — THE IMPLEMENTATION (owner re-ruling **D4**, 2026-09-14c)

D2's premise was withdrawn on the §0 determination and the owner ruled **(S-b)**: ship a LOUD DECLINE
for the narrow divergent sub-case only, and FILE the pairing as **bd `tu9q`** (P1) rather than build it.
Rationale as put to the owner: it closes an open P1 silent miscompile this session, it is far narrower
than the blanket decline D2 rejected, and it does not touch the owner's rolled cascade. The accepted
cost is that programs which COULD be compiled correctly decline until `tu9q` is built.

## 11. EXPECTED CORPUS MOVERS — stated BEFORE the sweep, as the protocol requires

Subject binary `00b84dc1facb1c9f…` vs ORACLE `5c6f7490a81c7505…`, over `ir-pass/test/*.ll` (1998 files,
4 of them mine) plus this track's probes.

1. **`loop_leak_dephase_reject_noregion_live.ll` and `loop_leak_dephase_reject_region_derivedbase_live.ll`
   — ACCEPT → DECLINE**, string `cq loop lowering: rolled body leaks a rail entangled with a register
   rotated after the loop`. By construction; they are the increment's red-green pair.
2. **`loop_leak_dephase_accept_pertrip_dead.ll` and `loop_leak_dephase_accept_marked_rootmint.ll` — NO
   MOVE.** They are new files, so they appear as `A:<md5>|A:<md5>` on both binaries with equal md5.
3. **0 to a handful of pre-existing ACCEPT → DECLINE**, each of which must independently satisfy all
   four conjuncts: an UNMARKED loop body, a CHAINED `@cq_theta_*` outside the loop whose block the loop
   header dominates, an interior tainted `BinaryOperator` with a real template stem in the loop's own
   blocks, and a tainted-operand ancestry path from that op to the rotated register. **Every one is a
   real instance of the class** — the same divergence measured at §0 — and each must be attributed
   individually. Most in-loop fixtures fail conjunct (1) (the body IS marked) or conjunct (2) (the
   rotation is INSIDE the loop), so I expect few.
4. **ZERO DECLINE → DECLINE string changes.** The stage runs AFTER `declineRecordedStaleQuantumReaders`,
   which is after every other decline owner, and `LLVMContext::diagnose` EXITS on the first `DS_Error`
   — so any module that already declined keeps its existing string. A string change here is a FINDING
   and would mean the slot argument is wrong.
5. **ZERO DECLINE → ACCEPT.** The stage only ever adds a decline; it mutates nothing.

**Anything else is a FINDING.** In particular: an ACCEPT → DECLINE on a loop whose body op is an
IN-PLACE rail op (`taint.InPlaceRailOps`, the dtzb `add`/`xor` that RELABELS a rail rather than minting
one) would be an **OVER-DECLINE**, because an in-place op leaks nothing. I could not construct a probe
that reaches the stage in that shape — both attempts died upstream (`s4_superseded_value`: `-O1` folded
the whole loop to `a - 6` so `LI.empty()` and the stage never ran — a WORTHLESS probe, recorded as such
rather than quietly replaced; `s4_inplace_accum_live`: declines `cq taint escape: tainted value muxed by
a classical-condition phi` on **both** binaries, i.e. pre-existing and upstream). The sweep is therefore
the instrument for this question, and if it produces such a mover the fix is one conjunct
(`!taint.InPlaceRailOps.count(&I)`), red-green against that mover.

## 12. THE DECLINE AS SHIPPED — the predicate, spelled

`declineDephasingUnmarkedLoopRails` (`LoopLowering.cpp`, declared in `LoopPlan.h`), called from
`CQLoweringPass.cpp` at **both** entry points (`:710` and `:1117`), immediately AFTER
`declineRecordedStaleQuantumReaders` and immediately before `lowerRotations`. **Pure analysis: it
declines or it does nothing. It mutates no IR and no `taint` set.**

    "cq loop lowering: rolled body leaks a rail entangled with a register rotated after the loop"

For each natural loop `L` in each function, ALL FOUR conjuncts must hold:

| # | conjunct | what it excludes, and which fixture pins that |
|---|---|---|
| 1 | **the body is UNMARKED** — no block of `L` is in `taint.IterationLocalBlocks` | a MARKED body discharges in-body, once per trip, and is byte-identical to its twin. Pinned by `loop_leak_dephase_accept_marked_rootmint.ll`, which carries the IDENTICAL hazard shape and MUST stay accepting |
| 2 | **a CHAINED `@cq_theta_*` outside `L` whose block `L->getHeader()` dominates** | a theta with a CLASSICAL arg 0 is a SOURCE — a fresh rail, no existing register to dephase. A theta INSIDE the loop is not "after". A loop with no post-loop rotation at all is the benign half: pinned by `loop_leak_dephase_accept_pertrip_dead.ll` (the bead's own `w2k`), which leaks 16-vs-20 and is nevertheless an ACCEPT |
| 3 | **an INTERIOR tainted `BinaryOperator` with a real `binaryStem` in `L`'s OWN blocks** | a rail every one of whose users is a `cq_measure` is MEASURE-OWNED and left allocated by BOTH forms (Rule 6) — not a divergence. A COMPARE rail is the region's own flag, which `emitCondNetwork` strips and frees itself — so the scan is `BinaryOperator` only, not every lowerable opcode. Subloop blocks are excluded for the multiplicity reason `markIfRailLocal` gives at its own `L->blocks()` loop |
| 4 | **a tainted-operand ancestry path from that op to the rotated register** | a per-trip chain that copies something nothing interferes later. This is a transitive backward walk, not `peelInPlaceBase` — the derived-base half (`p = y*3`) needs to reach `y` THROUGH a `mul`, which `peelInPlaceBase` does not cross |

`diagnose` + `return` on the first hit: `LLVMContext::diagnose` EXITS on the first `DS_Error` (bd `br4a`),
so one diagnostic per module is all a fixture can pin.

**Why it asks the OUTCOME and not any refusal CLAUSE** — the coordinator's binding point 1, and it comes
straight out of §1: `markIfRailLocal`'s clause (where bd `s82e`'s own text points) fires for NONE of the
five leaking programs. A decline keyed there moves zero programs.

**What "interior ⇒ leaks" rests on:** if the body is unmarked, `Uncomputation`'s in-loop guard
`canRepeat(&BB) && !taint.IterationLocalBlocks.count(&BB)` skips every interior candidate in it, at
three sites (`collectInteriorPlans`, the dead-terminal driver's §2.9 backstop, and the final-`At`
fence). So an unmarked body's interior rails are minted, never `_unc`-ed and never freed. That is the
mechanism, not an inference.

### 12.1 Measured, subject `00b84dc1facb1c9f…` vs ORACLE `5c6f7490a81c7505…`

| program | ORACLE | SUBJECT | |
|---|---|---|---|
| `s1_live_shift` | ACCEPT 10 (twin 14) | **DECLINE** at `s1_live_shift.c:11:14` | the divergent half |
| `s2_live_derived_region` | ACCEPT 19 (twin 25) | **DECLINE** at `s2_live_derived_region.c:11:22` | the region half |
| `w2k_noregion_invread` | ACCEPT 16 | **ACCEPT 16** | benign — unmoved |
| `w2h_phase_inloop_invread` | ACCEPT 30 | **ACCEPT 30** | benign — unmoved |
| `w2h3_select_iterlocal_invread` | ACCEPT 44 | **ACCEPT 44** | benign — unmoved |
| `s3_live_rootmint_region` | ACCEPT 22 (twin 22) | **ACCEPT 22** | the positive control — unmoved |

Both declines carry a real source location (`!dbg`), which is Rule 1's requirement and the property
Track P's F-P2 found a regression in by sweep.

## 13. FIXTURE TABLE — the three directions the coordinator required

| fixture | direction | what it pins |
|---|---|---|
| `loop_leak_dephase_reject_noregion_live.ll` | **DECLINE** | the divergent sub-case with NO tainted control flow at all — the cleanest statement of the class. String mirrored character-for-character |
| `loop_leak_dephase_reject_region_derivedbase_live.ll` | **DECLINE** | the same divergence through an in-loop PHASE region with a DERIVED invariant base (`invariantRegisterRootsImpl` clause (ii)). A fix aimed only at the control path would leave the other silently wrong, and vice versa — **keep both** |
| `loop_leak_dephase_accept_pertrip_dead.ll` | **ACCEPT (benign half)** | `w2k`, the bead's own exhibit: it LEAKS (its `LEAK` prefix pins 0 `_unc` and 0 `cqrt_free`) and is nevertheless correct. If this ever declines, the decline has stopped being narrow and has become the blanket one ruling D2 rejected |
| `loop_leak_dephase_accept_marked_rootmint.ll` | **ACCEPT (positive control)** | the SAME post-loop interference in a shape `invariantRegisterRoots` serves — 22 == 22 byte-identical, discharge IN-BODY. Conjunct (1) is the whole difference and this is the only thing pinning it |

The **superseded-value-rail** direction has NO fixture, and I say so rather than claim one: both probes
died upstream (§11). The sweep is the instrument for it.

## 14. L1 — the record-and-re-ask answer

**There is no record, and that is the answer, not an omission.** L1's hazard is a stage computing
something over a premise the round-2 fixpoint falsifies; its standard cure is RECORD-at-the-site +
RE-ASK-after-the-fixpoint in both entry points, and its standard failure is a seventh emission site that
forgets the `push_back` (`markBranchPhaseGate`, 6 call sites). This stage sidesteps that class entirely
by reading the **OUTCOME after the fixpoint** instead of recording a question at the refusal:

* `taint.IterationLocalBlocks` has exactly three writers — `markIfIterationLocal` (inside `lowerLoops`),
  `markIfRailLocal` via the round-1 `collapseFlattenedLoopRails`, and the same function again as the
  **LAST STATEMENT of `repropagateControlMerges`**. All three precede this slot in both entry points.
* So a fourth marking clause added tomorrow needs no edit here: it either marks (and this stage stays
  silent) or it does not (and this stage asks its four conjuncts). **RETIREMENT TRIGGER: a writer of
  `IterationLocalBlocks` added AFTER the round-2 fixpoint, or this call moved above it.**
* And it is asked at **FINAL taint**, so the L1 PREDICATE species — a value only
  `repropagateControlMerges` taints being invisible — cannot arise. A predicate written at
  `markIfIterationLocal`'s own clause, which runs inside `lowerLoops` at ROUND-1 taint and is never
  re-asked, would have had exactly that defect.

⚠ Both call sites are present (`CQLoweringPass.cpp:710` and `:1117`) — the `runOnFunction` shim
included. Note the shim's PRE-EXISTING divergence (it never calls the round-1
`collapseFlattenedLoopRails`, bd `8h7d.5`) is NOT widened by this: the stage reads whatever the shim's
own markers produced, and a shim that marks LESS declines MORE, which is the safe direction.

## 15. THE WITNESS AND ITS "MADE TO FAIL ON PURPOSE" RECORD (L10) — part II

The injection matrix over the two new accepts **scored 7 of 7 applied mutations MISSED against the
first draft of the fixtures**, including deleting the `_unc` and deleting a `cqrt_free` — the very
discharge the positive control exists to pin. Three rounds of strengthening later it is **applied 8,
MISSED 0, N/A 4**. The three causes, each worth carrying:

1. **Loose positives.** The first draft used unordered positives with no counts; a deletion one line
   away from a named line walked through. Fixed with contiguous ordered runs (and only where the run
   really is contiguous — `-g` interleaves `#dbg_value` RECORDS, which are lines to FileCheck).
2. **`CHECK-LABEL` scoping — and this is the one worth the paragraph.** `-O1` inlines `@slice` into
   `@main`, so each module carries TWO copies of the stream. With one label the block runs to EOF and
   every positive could be satisfied by the `@main` COPY: deleting the rail mint **from `@slice`** scored
   MISSED. Closed with a trailing `CHECK-LABEL: define i32 @main`. **This is bd `1yeu`'s
   one-function-per-module gap seen from the inside — the second function is not a spare, it is a
   decoy** — and it is now written into both fixture headers.
3. **A pure-negative prefix nothing could reach.** `LEAK`'s two `-NOT`s (0 `_unc`, 0 `cqrt_free` — the
   accepted leak) were unexercised by every mutation. ⚠ The inherited vacuity checker
   (`$SESP/trackD/probes/vacuity.py`) matches only HANDLE-FORM negatives and would have printed
   `checked 0` over this batch — the exact lie `CLAUDE.md` L10 records. So vacuity was closed by
   **MUTATION** instead: mutation `f_add_discharge` injects a `_unc` + `cqrt_free` pair into the
   leaking fixture, and `LEAK` catches it. Every prefix on every new fixture is now exercised by at
   least one mutation.

The harness itself was attacked first: invoked with **no fixture argument** it exits non-zero rather
than printing `0 mutations, MISSED 0` (bd-recorded L10 instance), every mutation is bounded by the
enclosing `define` (the across-a-function-boundary false MISSED), and a mutation that does not apply
is printed as `N/A` and counted separately — **`N/A` is a hole, not a pass**. The 4 N/A are honest:
`pertrip_dead` has no `_unc`, no `cqrt_free` and no post-loop `ry` to mutate, BY DESIGN, and
`marked_rootmint` has no `lshr` rail for `f_add_discharge`.

## 16. ATTACK SURFACE for the Rule-13 reviewer (part II — the decline as shipped)

Three rounds were budgeted at §7 for the determination and **none was spent there**, because the fork
closed the increment. They are all available for the decline. In priority order:

1. **CONJUNCT (3) IS THE NARROWEST AND THEREFORE THE LEAKIEST.** It scans `BinaryOperator` only. A
   leaked interior rail minted by a **cast** (`CastLowering`), an **fneg**, or a **compare that is NOT a
   region flag** would be missed, and the class would survive silently in that spelling. I chose
   narrow deliberately (widening to compares would decline shipped region accepts, since a flag rail IS
   an interior binary-ish rail whose strip the emitter owns), but the residual is real and unmeasured:
   **I did not construct a cast-minted instance.** This is the most likely next hole.
2. **CONJUNCT (2)'s "after the loop" IS A DOMINANCE TEST, NOT A REACHABILITY ONE.** `L->getHeader()`
   dominating the gate's block is SOUND (every path to the gate runs the loop first) but INCOMPLETE: a
   rotation reached only through a side path the header does not dominate is missed. Deliberately not
   `llvm::isPotentiallyReachable` — this file's own note at `provablyBefore` records why its exclusion
   set is wrong here. A miss leaves the PRE-EXISTING leak and can never create a NEW over-accept, but
   attack it: a multi-exit loop, or a rotation inside a classical `if` after the loop.
3. **THE IN-PLACE OVER-DECLINE I COULD NOT PROBE.** A dtzb IN-PLACE rail op (`taint.InPlaceRailOps`)
   passes conjunct (3) — it is a `BinaryOperator` with a stem — yet mints NO rail, so firing on it
   would be an OVER-DECLINE. Both my probes died upstream (§11) and the corpus sweep is the only
   instrument left. If a mover turns out to be this shape, the fix is one conjunct
   `!taint.InPlaceRailOps.count(&I)`. ⚠ And note the direction: `InPlaceRailOps` is a raw `Instruction *`
   set nothing scrubs (F-W2-4), so using it to SUPPRESS a decline means a recycled pointer silently
   excludes a real candidate — which is not a new over-accept (it is the pre-existing leak) but must be
   said out loud if the conjunct is ever added.
4. **CONJUNCT (1) IS ALL-OR-NOTHING PER LOOP.** `Marked` is true if ANY block of `L` is in
   `IterationLocalBlocks`. A loop only PARTIALLY marked — if such a thing can be produced — would be
   treated as marked and skipped. `markIfRailLocal` and `markIfIterationLocal` both insert all of `L`'s
   own blocks at once, so this cannot arise today; it is a structural coincidence, not an invariant
   anyone stated, and that is exactly the species `CLAUDE.md` says to write down rather than rely on.
5. **THE THREE BEAD PROGRAMS STAY ACCEPTING, AND THAT IS A DELIBERATE, RULED LEAK.** If a reviewer can
   build a program in which the leaked rail's partner is a PER-TRIP register that is nevertheless later
   interfered (accumulated into a carried register, or rotated before the trip ends), it moves a bead
   exhibit from (R-leak) to (R-diverge) and the population widens again. I flagged this at §7.3 and did
   not build it.
6. **bd `1yeu` — and this increment measured it from the inside.** Every probe and fixture here is one
   or two functions in one module. The `CHECK-LABEL` finding (§15.2) is that gap turned into a false
   MISSED; a genuinely CROSS-FUNCTION spelling of this leak (the invariant register passed as an
   argument, the loop in a callee) is invisible to every instrument in the tree including mine.

## 17. NOT DONE / COULD NOT DO — part II

* **bd `tu9q` is NOT built**, by ruling. I did not touch the multiplicity pairing, and
  `Uncomputation.cpp:982-1000`'s retirement trigger (a granting widening owes a real multiplicity test)
  is untouched and still armed.
* **No probe for the superseded-value-rail / in-place direction** (§11, §16.3).
* **No cast-minted or cross-function instance** (§16.1, §16.6).
* **The `bd wx8g` NOTES text** is still handed over rather than written (§8).
* **Twin-matrix cells** are requested at §10, not generated (PROTOCOL: the merge-and-gate agent's).
  ⚠ With the decline landed, two of those four requests CHANGE: `m_noregion_invread_live` and
  `m_region_derivedbase_live` are now **DECLINE-BOTH-SIDES on the subject** rather than divergent
  accepts, so they should be generated against the MERGED binary and adjudicated as declines. The other
  two (`m_noregion_invread_dead` = the blessed benign divergence, `m_region_rootmint_live` = the
  identical positive control) are unchanged and still wanted.

## 18. THE CORPUS SWEEP — 2013 rows, 7 movers, every one attributed

`probes/corpus_09694fb88985df25.txt`. ORACLE `5c6f7490a81c7505…` vs SUBJECT `09694fb88985df25…`, both
binaries on the SAME stage-1 file per row. ⚠ The shared `corpus.sh`'s tag regex renders a whole decline
FAMILY as an empty `D:`, so a decline→decline STRING change is invisible to it (`PROTOCOL` S3); this
sweep records `D<exit>:<sha256 of the FULL stderr>:<string>` and compares that, which closes it.

```
TOTAL rows 2013  (1998 ir-pass/test/*.ll + 15 trackS probes)
MOVERS 7 · CLANGERR 0 · DECLINE->DECLINE string changes 0 · DECLINE->ACCEPT 0
```

| mover | category (§11) | attribution |
|---|---|---|
| `loop_leak_dephase_reject_noregion_live.ll` | **1** | the increment's own red-green pair |
| `loop_leak_dephase_reject_region_derivedbase_live.ll` | **1** | " |
| `trackS/probes/s1_live_shift.c` | **1** | the same two programs through the `.c` path |
| `trackS/probes/s2_live_derived_region.c` | **1** | " |
| `control_phase_kickback_mixed_hoisted_template_leak_control.ll` | **3** | **a genuine instance — see §18.1** |
| `control_phase_kickback_mixed_preheader_volatile_imm_leak_control.ll` | **3** | " |
| `control_phase_kickback_mixed_short_sext_leak_control.ll` | **3** | " |

Predictions 4 and 5 held exactly: **0 decline→decline string changes** (the slot argument — this stage
speaks last and only where nothing else did) and **0 decline→accept**. **0 unattributable movers.**

### 18.1 The three pre-existing movers — and the fixture that proves the discrimination is exact

All three are the SAME source modulo the invariant base's spelling:

```c
int slice(int u){ int q=cq_theta(u,.5); int r=cq_theta(u,.3); int p = <BASE>;
  for(i<3){ if((p>>i)&1) cq_phi(.2); r=cq_theta(r,.1); }
  q=cq_theta(q,.9); return cq_measure(q)+cq_measure(r); }
```

with `<BASE>` = `q*3` (a `cq_template_mul` rail), `q + <volatile load>` (a dtzb add), or a hoisted
`sext i16` — each a hoisted loop-invariant **TEMPLATE** rail that `invariantRegisterRootsImpl` clause
(ii) refuses, so the body is never marked.

**They are genuine instances of the class, and the proof is in their OWN headers.** Each records
`3/0 rolled` against `3/3 hand-unrolled` for the per-bit `and` rails — that is the (R-diverge)
signature — and each source ends `q = cq_theta(q, .9); cq_measure(q)`, a TENSORED non-diagonal `Ry` on
the very register the three leaked rails are which-path copies of, followed by a measurement of it. The
headers nonetheless called that leak *"the PRIME-DIRECTIVE disposition, not an oversight"* and *"the
safe direction (Rule 6)"*. **That claim is false for these programs**, on the measurement the headers
themselves carry. All three are CONVERTED to declines, the false claim corrected in each, with the
`tu9q` retirement trigger (and a note NOT to restore the old CHECK prefixes verbatim, because they
pinned the LEAKING stream).

⚠ **THE TREE ALREADY CONTAINED THE CONTROL, AND IT IS BETTER THAN MINE.**
`control_phase_kickback_mixed_invariant_carried_inloop.ll` is that same source with the invariant base a
ROOT MINT rather than a template rail — `invariantRegisterRoots` admits it, the body is marked, the
spine discharges in-body — and it is **`A:32d17cb8675d` on BOTH binaries, md5-identical**. Conjunct (1)
is the entire difference. Three of the six `*_leak_control.ll` fixtures move and three do not
(`claim_across_loops`, `onward_deadgate`, `preheader_add_outofplace` are unmoved), which is the
narrowness claim measured rather than asserted.

⚠ **Q-R1-1 MUST BE RE-READ AND I CANNOT EDIT `CLAUDE.md` FROM HERE.** `CLAUDE.md` §5 files *"an in-loop
hoisted loop-invariant TEMPLATE rail read by the body's condition (Q-R1-1, a Prime-Directive decline,
not a proof)"* among the OVER-DECLINES. For the sub-case with a post-loop non-diagonal gate the opposite
is now measured: **the ACCEPT was the defect.** Q-R1-1's remaining population is the sub-case with no
later interference, which still accepts and still leaks. The correction is landed in
`LoopLowering.cpp`'s `invariantRegisterRoots` header and in all three fixture headers; **`CLAUDE.md` §5
itself is the orchestrator's to amend** (L7-with-a-twist: a correction not applied where the reader
reads is not a correction, and §5 is where a reader looks).

### 18.2 Diagnostic locations

The three converted fixtures report `<unknown>:0:0`. **That is not a lost anchor**: they carry NO debug
info at all (`grep -c '!dbg'` = 0, no `llvm.dbg.cu`) because they were built without `-g`, so there is
no location to lose. Every `-g` subject DOES get a real one — `s1_live_shift.c:11:14`,
`s2_live_derived_region.c:11:22`, and 30 `!dbg` nodes in each new decline fixture. This is the F-W2-5 /
F-P2 class and it was checked, not assumed.
