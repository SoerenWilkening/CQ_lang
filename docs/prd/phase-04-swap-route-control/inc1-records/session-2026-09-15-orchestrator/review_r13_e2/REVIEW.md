# Rule-13 adversarial review — Track E2 (bd `fve8`), round 1

**Subject**: branch **`fve8-undef-measure`**, commit **`8eed7a2d`**, worktree
`/Users/sorenwilkening/Desktop/CQ_E2`.
**Reviewer**: independent; did not write the code, ran **no build** and **no test suite**. Analytic
and trace reasoning plus the per-probe pipeline against the two binaries that already exist.
**Date**: 2026-09-15.

## VERDICT: **FINDING** — one **P1 over-accept** (`F-E2-1`), two **P2** defects already in shipped
source (`F-E2-2`, a false byte-identity claim; `F-E2-3`, an incomplete retirement-trigger set), plus
an opinion on the track's open item 3 and four housekeeping notes.

⚠ **No finding says "revert".** `F-E2-1`'s class **pre-exists at HEAD** and I measured it doing so;
what E2 adds is a population and a **silence**, and the correct disposition is an **owner ruling**
plus a corrected disclosure, not a fence invented by this review. `F-E2-2` and `F-E2-3` are each one
paragraph, in two places apiece, one of which is `ir-pass/src/MeasureLowering.cpp`.

The change's **core mechanism is sound and I could not break it**: 13 independent attacks held,
including the two seams that would have been expensive to miss — the Group-1 bank-load seam and
`declineUnpairedUndefLiterals`. All three findings sit on the **argument and the instrument**, not on
the seven production lines.

---

## 0. Binaries — verified before believing any verdict

```
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d          ← ORACLE, MATCHES GATES.md
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/libCQPass.so
94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b          ← MATCHES
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_E2/build/ir-pass/cq-opt
57e7420c50ddf8027d9c686672a1db282ed03d8bd94e5d9c366a8d2bfdc15439          ← SUBJECT, MATCHES
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_E2/build/ir-pass/libCQPass.so
35fb4c26c1519cb185a5a1b683a93d0be4a95928f7035fc86c4619bd90ccf7ee          ← MATCHES
```

All four hashes match `trackE2/GATES.md`. **No cited-but-stale gate line.** Nothing was rebuilt in
either tree; the ORACLE tree was never written to.

Probe material: `/private/tmp/…/scratchpad/r13e2/` (`src/`, `ll/`, `run.sh`, `stream.sh`,
`full.sh`). Every number below carries its command.

---

## 1. `F-E2-1` — **P1, over-accept.** The user's *quantum* measurement disappears, silently, and the track's own instrument cannot see it

### The shape, as a program

```c
#include "CQ.h"
int main(void){ int u; int q = cq_theta(0, 0.3); return cq_measure(q + u); }
```

The author wrote a **measurement of a quantum register**. `clang -O1` folds
`add nsw i32 %q, undef` → `undef`, so the module the pass sees is:

```llvm
%1 = call i32 @cq_theta_si32(i32 noundef 0, double noundef 3.000000e-01)
%2 = call i32 @cq_measure_si32(i32 noundef undef)          ; the taint is GONE from the operand
ret i32 %2
```

### Measured

```
$ ./run.sh oracle  src/y1_quantum_measure_folded_to_undef.c
exit=1   cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value
$ ./run.sh subject src/y1_quantum_measure_folded_to_undef.c
exit=0   STDERR-BYTES: 0
$ ./full.sh subject src/y1_quantum_measure_folded_to_undef.c
ret=0 | 2b: 1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven
       | trace-sha=684d2394674bd01b | lines=2
    cqrt_alloc_i32(0) -> h0
    cqrt_ry_i32(h0, 0x1.3333333333333p-2)
```

**Two trace lines. There is no `cqrt_measure_i32` in the circuit at all** — confirmed on the
hand-IR minimal pair, where the emitted module contains **zero** occurrences of the string
`cqrt_measure` (not even a declaration):

```
$ ./run.sh oracle  ll/y1_min.ll   → exit=1, the undef-operand decline
$ ./run.sh subject ll/y1_min.ll   → exit=0, 0 bytes stderr, cqrt_measure count: 0
$ ./run.sh {oracle,subject} ll/y1_min_control.ll   → exit=0 on BOTH, cqrt_measure count: 2
```

(`y1_min_control.ll` is the identical module with the measure operand spelled `%1` — the theta's
result — i.e. the program the source names once `u` is initialised. It emits
`cqrt_alloc_i32` / `cqrt_ry_i32` / `cqrt_measure_i32`.)

The **C-level** written-zero twin makes the gap explicit:

```
$ ./full.sh oracle src/y1b_written_zero.c        # int u = 0; … cq_measure(q + u)
trace-sha=ea3c225a0aadc87e | lines=3
    cqrt_alloc_i32(0) -> h0
    cqrt_ry_i32(h0, 0x1.3333333333333p-2)
    cqrt_measure_i32(h0) -> 0
```

`684d2394674bd01b` (2 lines, no measurement) vs `ea3c225a0aadc87e` (3 lines, with the measurement).

### ⚠ The track's refinement instrument is structurally blind to this

```
$ python3 trackE2/probes/refinement_check.py <y1 stage-1>
IDENT   y1.s1.ll  (1 operand(s) rewritten)
refinement: population 1 module(s) (0 outside the population), 1 BYTE-IDENTICAL, 0 DIVERGENCE(S), 0 SUBJ-DECLINE
```

It reports **byte-identical**, because the one-token IR twin rewrites only the measure operand and
therefore inherits the fold that already erased the taint. This is CLAUDE.md **L10** exactly — *an
instrument's failure mode is to report a PASS* — and it is why this finding is not in
`IMPL_E2.md`: the gate that was supposed to catch a divergence here **agrees with the subject**.

### Mechanism

Clause (1a) fires on `isa<UndefValue>(Handle)` **in the IR the pass sees**. `-O1`'s
`add X, undef → undef` fold can carry a *tainted source expression* into that slot, because the fold
**deletes the data-flow edge to the theta**. `taint.Tainted` is then correct and irrelevant: the
operand genuinely has no quantum lineage *in the module*, so branch (1) is entered legitimately and
(1a) reports 0.

### The mitigating fact, measured — this is a population widening, not a new class

```
$ ./run.sh oracle src/y2_quantum_measure_mul_undef.c   # int u; … cq_measure(q * u)
exit=0, stage-1 shows:  %2 = tail call i32 @cq_measure_si32(i32 noundef 0)
$ ./full.sh oracle src/y2_quantum_measure_mul_undef.c
trace-sha=684d2394674bd01b | lines=2      ← the IDENTICAL stream y1 now gets on the SUBJECT
$ ./run.sh oracle src/y3_quantum_measure_and_undef.c   # `q & u`  → same, exit=0 on the ORACLE
```

`mul X, undef` and `and X, undef` fold to a **concrete `0`** at stage 1, so those spellings already
take branch (1) and **already ship this exact circuit on the ORACLE**. ⇒ *A user-written quantum
measurement vanishing into branch (1) after an `-O1` fold is HEAD behaviour.* **E2 emits no stream
HEAD could not already emit.** What E2 changes is that the `undef`-folding spellings move from a
**loud refusal** to a **silent accept**.

### Why it is still a P1 and not a note

* The ORACLE's refusal was the Prime-Directive-correct disposition for an input the compiler cannot
  make sense of, and it was **the only diagnostic standing in front of this shape**.
* The owner's ruling (`DECISIONS.md` E2) retires clause 4 for *"`cq_measure` of an `undef`/`poison`
  operand"*. The rival reading put to the owner, and the only one E2 discloses, is the **classical**
  program `int u; return cq_measure(u);`. The rival here is materially different and is stated
  nowhere: *the author wrote a measurement of a quantum register and receives a circuit with no
  measurement in it, a prepared rail left allocated, and 0 bytes of stderr.*
* Direction check (the prompt's item 1, and CLAUDE.md §4c's z9t1 positive — *"bd `z9t1` **removes** a
  vanished user measurement here — it does not create one"*): **here the direction is the wrong
  one.** Rule 5's hard invariant (never *insert* a measurement) is intact; its mirror is not.

### What I do **not** recommend

A fence of the form *"decline an `undef` measure operand whose def chain once held taint"* is **not
writable**: after `-O1` the taint is gone from the IR, which is precisely why branch (1) takes it.
The only decidable discriminator I can construct is a Rule-5-mirror **postcondition** — *"the module
lowered a theta whose handle is never measured"* — and that fires on every legitimately-unmeasured
register (`e2q`, `z8c`, and the whole uncompute-and-leak family). So this is an **owner question**,
and it is the same question bd `21mg` left open as Q-1 and E2 carries as its **retirement trigger
(iii)**: *does every user-written `cq_measure` have to reach the 7.6 output tape?* If it does, both
y1 and the pre-existing y2/y3 stop compiling, and this finding closes with that ruling.

### Red-green pair (write both; y2 is the control that proves the class pre-exists)

| file | direction | today |
|---|---|---|
| `ir-pass/test/lowering_measure_undef_operand_after_taint_fold.ll` (= `ll/y1_min.ll`) | **ACCEPT** on the SUBJECT, `CHECK-NOT: cqrt_measure` — pins that the user's measurement is absent | ORACLE: decline. SUBJECT: exit 0 |
| `ir-pass/test/lowering_measure_taint_fold_control.ll` (= `ll/y1_min_control.ll`) | ACCEPT with `CHECK: cqrt_measure_i32` | both binaries |

Whichever way the owner rules, the **first** fixture must exist, because it is the only artefact in
the tree that would make the next reader see this shape.

### Minimum action even if the owner rules "keep accepting"

**The disclosure must name this rival.** `IMPL_E2.md` §6 and its verbatim copy in
`MeasureLowering.cpp` state one rival (`int u; return cq_measure(u);`). Under the standard CLAUDE.md
§4c sets — *"the rival reading, stated as a program and not as an IR shape"* — the second rival
belongs beside it, together with the y2/y3 measurement that shows the class is HEAD's and not E2's.

---

## 2. `F-E2-2` — **P2, and it is already in shipped source.** *"byte-identical to what a written `= 0` produces"* is FALSE

The **normative** disclosure (`IMPL_E2.md` §6 half (2)) and its verbatim copy in
`ir-pass/src/MeasureLowering.cpp` say:

> *"the emitted stream is **BYTE-IDENTICAL** to what a written `= 0` produces — measured over the
> decline's whole censused population, 0 divergences"*

Measured **false on the track's own probe** `e2e_undef_used_twice.c`:

```
$ SUBJECT lowering of `int u; int m = cq_measure(u); return m + u;`      →  ret i32 undef
$ ORACLE  lowering of `int u = 0; int m = cq_measure(u); return m + u;`  →  ret i32 0
```

What was actually measured (`IMPL_E2.md` §3.1) is the **one-token IR twin**, which rewrites *only*
the measure operand. §8 states the limitation correctly — *"the operand's OTHER uses are not
rewritten … `e2e` keeps `u` as `undef` at the second read"* — so **the record contradicts itself,
and the source comment carries the wrong half.**

**Soundness is unaffected**, and that is worth saying plainly: the real ground is LangRef —
each read of an `undef` may independently be any value of its type, so rewriting one read to `0`
while another stays `undef` is a legal refinement. The byte-identity is **corroboration**, and the
corroboration is overstated by exactly the multi-use case.

This is CLAUDE.md's *"TWO DIFFERENT 164s, EQUAL BY COINCIDENCE"* class (a measurement from
instrument A quoted as evidence for claim B) and **L7-with-a-twist** (a record correction that is
not applied to the source is not a correction). ⚠ It is also the sentence a future agent will quote,
because it is the one at the mechanism.

**Fix — one edit, both places:** *"byte-identical to the same module with that one operand token
written as the type's zero"*, with §8's sentence kept adjacent. Do **not** weaken §3.1, which is
already precise.

---

## 2b. `F-E2-3` — **P2.** E2 is only **half** a customer of `z9t1`'s trigger (ii), and its own trigger set is incomplete

The prompt asks what would make E2's paragraph **wrong** rather than out of date. Answering that
requires taking the track's own claim apart, and it does not survive intact.

`IMPL_E2.md` §6 trigger 2 and the source copy both say:

> *"The clause starts rewriting anything that is not `isa<UndefValue>`, **or `undef` stops being
> uniqued per type**. Those are the refinement's **only two** load-bearing facts. ⚠ This is the same
> pair `RotationLowering.cpp` names as its own trigger (ii) — which therefore now has a **SECOND
> CUSTOMER**…"*

**The two halves do not travel together, and only one of them reaches E2.**

* **The `isa<UndefValue>` half is a genuine second customer.** Same predicate, same direction (it
  gates a decline everywhere else and a rewrite here), same consequence if widened.
* **The uniquing half has no mechanism in E2.** Uniquing is load-bearing for bd `z9t1` because F1's
  second sub-clause is a literal `Value*` **identity** test —
  `MergePhi->getIncomingValue(unsigned(PredIdx)) != RotBase`, which I located by reading the source
  rather than by citing CLAUDE.md, and it is at **`ArmClassify.cpp:4685`** in this worktree, **not**
  the `:3905-3908` CLAUDE.md §4c records (Rule 11: line numbers drift; that citation is stale, which
  is worth one line in the next CLAUDE.md pass) — so manufacturing a uniqued zero makes two
  operands *the same pointer* — that is the whole `z9t1` disclosure. **E2 performs no identity test
  anywhere**: it asks a type question (`isa<UndefValue>`) and RAUWs the measurement's **result** to
  `Constant::getNullValue(Measure->getType())`. And E2's manufactured zero **cannot** reach F1 even
  in principle: `lowerMeasures` runs at `CQLoweringPass.cpp:776` / `:1201`, i.e. **after**
  `repropagateControlMerges` and therefore after every `detectControlRegions` / `classifyArms` /
  F1 / F2 in both entry points.

**Why this is a defect and not pedantry.** It is the **mirror of L3** — *when you add a caller to a
shared argument, read the trigger and state which direction you are using it in* — the same shape
CLAUDE.md records as costing a P1 filing on 2026-09-14 (`WireWalk.h` / `readerStalesItself`). And
its practical cost is in the dangerous direction: the sentence **"those are the refinement's only two
load-bearing facts"** presents the pair as **exhaustive for E2**, and it is not. E2's actual
load-bearing set is:

1. only a whole-value `undef`/`poison` is rewritten *(shared with `z9t1`)*;
2. the RAUW target is the type's zero **of `Measure->getType()`** *(E2's own trigger (i))*;
3. **`lowerMeasures` runs after every `Value*`-identity fence in the pass** — **stated nowhere**,
   and it is what makes the borrowed uniquing worry vacuous here.

Fact 3 is the row the closure table is missing, and it is the one a reordering would silently break:
move `lowerMeasures` earlier — the exact hazard bd `21mg`'s own retirement trigger already names for
a *different* reason (*"moving it passes an `i32` HANDLE through as data"*) — and E2's manufactured
zeros start arriving at F1 alongside `z9t1`'s, with the two rules compounding at a pointer-identity
test neither was measured against.

**Fix:** split trigger (ii) into the half that transfers and the half that does not, and add fact 3
as a trigger in its own right, cross-referenced to bd `21mg`'s ordering trigger so the two live
together. One paragraph, in `IMPL_E2.md` §6 and at the mechanism.

---

## 3. What I attacked and what **held** — 13 checks, with the command

Recorded in full, because the prompt asks what would have caught a finding if there had been one.

1. **Binary hashes vs `GATES.md`** — 4/4 match (§0). No stale citation.
2. **Rule 5, insertion direction.** (1a) only deletes; it cannot mint a `cqrt_measure_<W>`. And it
   can never take a *quantum* measure: branch (1)'s entry is `!taint.Tainted.count(Handle)`,
   textually unchanged, and `taint.Tainted` holds only `Instruction`s — the sole seed is
   `out.Tainted.insert(CI)` on a `@cq_theta` `CallInst` (`TaintPropagation.cpp:186`), and the only
   growth is `propagateWorklist`'s `auto *I = dyn_cast<Instruction>(U); if (!I) continue;`. So an
   `UndefValue` operand is untainted **by construction**, in every round including the round-2
   fixpoint, and (1a) can never take a quantum measure.
3. **Clause order, both directions.** `valueCarriesUndef` opens `if (isa<UndefValue>(C)) return true;`
   (`LiteralIntegrity.cpp:91-92`), so (1a)'s population is a **strict subset** of (1b)'s old one:
   (1a) can swallow nothing (1b) did not already swallow. The track's forward claim (testing (1b)
   first would re-swallow the retired shape) and its converse both hold.
4. **(1a) now sits ABOVE the `Handle->getType() != Measure->getType()` guard** — a real structural
   change the source comment only waves at (*"independently of the unreachable type guard below"*).
   `Constant::getNullValue(VoidTy)` is `llvm_unreachable` ⇒ **Release UB**, so I attacked
   reachability directly. `declMatchesPrototype` (`TaintPropagation.cpp:249-256`) requires
   `FT->getReturnType() == T && FT->getParamType(0) == T` with `T = wd.llvmTypeFor(Sfx)`; a
   non-matching decl is `diagnoseMalformedDecl`'d and **never enters `MeasureCalls`**. Measured:
   `ll/w1_void_return_measure.ll` (`declare void @cq_measure_si32(i32)` + `call … (i32 undef)`) and
   `ll/w2_type_mismatch_measure.ll` (`i64 @cq_measure_si32(i32)`) both die at
   `cq measure lowering: unsupported declared prototype`, **identically on both binaries**. No crash
   path. ✔
5. **Group-1 seam (the prompt's item 6) — verified, and it is the cheap half of this review.**
   `isa<UndefValue>` requires a `Constant`; `valueCarriesUndef` opens `dyn_cast<Constant>(V)` and
   returns `false` otherwise (`LiteralIntegrity.cpp:113-119`). A rail-bank `load` is a `LoadInst`
   and reaches **neither** new clause; it lands on the pre-existing
   `Measure->replaceAllUsesWith(Handle)` path exactly as before. Branch (1)'s entry condition is
   byte-for-byte `if (!taint.Tainted.count(Handle))`. **The track's cross-track statement (§5) is
   correct as written.**
6. **`declineUnpairedUndefLiterals` (GUARD 1) cannot be disarmed — and I built the shape the track
   called *"constructible … simply not in the corpus"*.**
   `src/g1_guard1_two_slots.c` (`double a; int u; q=cq_theta(0,a); r=cq_theta(0,a); cq_measure(u)+…`)
   moves **D→D onto a different string**: ORACLE `cq_measure_<sfx> operand is an undef/poison
   literal…`, SUBJECT `cq literal integrity: undef/poison literal reaches two emitted gate operands`.
   The control with the undef measure deleted gives that same literal-integrity string on the
   ORACLE. ⇒ E2 **removes a preemption in front of** GUARD 1; it does not lower its count. The
   structural reason the track gives (a `@cq_measure_<sfx>` call is not an
   `isEmittedRuntimeCallee`, so its operand was never counted) is the right one. ✔
6b. **"Is 4986 the right population, and is *raising the count* the only way a newly-reached stage
    can misbehave?" (the prompt's item 4) — no, on the second half.** The newly-reached stages on a
    previously-preempted module are `lowerBreakReversePlay` → `lowerLateReassignments` → `uncompute`
    → GUARD 1 → `declineSurvivingIntrinsicCalls`. Beyond "GUARD 1's count rises" there are two other
    ways they can misbehave, and I checked both:
    * **crash / use-after-free** — the only new structural exposure is that (1a) *erases* a call the
      ORACLE left in place, so `taint.MeasureCalls` now holds a dangling entry for this shape.
      Closed by item 7: **zero** post-`lowerMeasures` readers.
    * **emitting a stream nobody has read** — this is the real one. The 24 `D→A` movers produce 24
      circuits that **did not exist on the ORACLE**, so no prior review, golden or corpus row covers
      them. The track refinement-checked 12 modules; only ~2 of the 24 movers are in that 12. I
      closed 11 more of them plus 9 of my own (item 11), so **32 modules** of the union are now
      byte-identity-checked against their one-token twins, 0 divergences.
    On the **population** half: 4986 is the PROTOCOL corpus (`ir-pass/test/*.ll` + every session's
    `track*/probes` and `review_*_probes`). It **excludes the e2e layer**, which is the only layer
    that LINKS — I swept that separately and closed it (item 13). With those two together I have no
    population objection.
7. **No dangling `taint.MeasureCalls`.** (1a) *erases* a call the ORACLE left in place. Every reader
   of `taint.MeasureCalls` — `ArmClassify` ×2, `SwitchClassify` ×2, `SelectClassify`,
   `SpecializeDetect`, `SpecializeReject`, `TaintPropagation`'s repropagate — runs **strictly
   before** `lowerMeasures` (`CQLoweringPass.cpp:776` and `:1201`). Zero post-`lowerMeasures`
   readers. ✔
8. **Obligation (b), re-measured independently.** `kMsgUndefOperand` has exactly **one** customer:
   `MeasureLowering.cpp:337`, clause (1b). No other site in `ir-pass/src` or `ir-pass/include` emits
   that string. ✔
9. **The scoping correction (§2.2) is real, and I reproduced it.**
   `opt -passes=verify -S` reprints `ptrtoint (ptr undef to i32)` as **`i32 undef`** and
   `bitcast (i32 undef to float)` as **`float undef`**. `SCOPE_M.md` §1.3(b) calls `e2i` *"the same
   species"* as `e2k` and §1.4 proposes it **as a decline fixture** — that fixture would have shipped
   green with no subject (fixture-hygiene defect (c)). The track's correction is **owed back to
   `SCOPE_M.md` and to bd `fve8`'s note**, and it is on the track's own open list (item 2). ✔
10. **Fixtures validated by BINARY mutation, not by re-reading prefixes.** Running each fixture's own
    prefixes with the same FileCheck invocation lit uses:
    * `lowering_reject_measure_undef_operand.ll` — ORACLE: `exit=1 outbytes=0`, **every** prefix
      (`CHECK`, `NOCLASSICAL`, `ACC`) **FAILS**; SUBJECT: `exit=0 outbytes=197`, all **PASS**.
    * `lowering_accept_measure_undef_zero.ll` — ORACLE: `exit=1 outbytes=0`, all six prefixes
      (`CHECK`, `MOD`, `COUNT`, `NOALLOC`, `NOUNDEF`, `NOINTR`, `ACC`) **FAIL**; SUBJECT:
      `exit=0 outbytes=830`, all **PASS**.
    * `lowering_reject_measure_undef_global_init.ll` — identical on both binaries (correct: the
      residual is untouched), so its non-vacuity must come from module mutation. I reproduced the
      track's M1/M2 myself: `{i32 1, i32 2}` → exit 0 `ret i32 ptrtoint (ptr @g to i32)`, and
      operand → whole-value `i32 undef` → exit 0 `ret i32 0`; **both flip the fixture's own RUN
      pipeline**. ✔
    ⚠ Non-empty confirmed at every ACCEPT (`outbytes` 197 / 830, never 0) — the 0-byte-module
    passthrough trap does not apply here.
11. **The refinement population, extended 12 → 32 by this review.** The track measured 12 modules but
    its own §4 names **24** `D→A` corpus movers; the 12 it refinement-checked are its fixtures and
    its own probes, so the 11 historical movers it named (`trackU/{probes,fix_r1_probes}/u{1,4}.c`,
    `trackU/review_r1_probes/r05_seed_and_measure.c`, `trackU/review_r2_probes/a2_measure_undef.c`,
    `trackU/review_r3_probes/pN_clause4_direct_u.ll`, `trackC/probes/{c6_undef_bool.c,
    i0_poison_operand.ll}`, `diag_2026-09-14_probes/u{1,4}.c`) were **not** in it. I ran the track's
    own instrument over them, and over my own nine probes:
    ```
    refinement: population 11 module(s) (0 outside the population), 11 BYTE-IDENTICAL, 0 DIVERGENCE(S), 0 SUBJ-DECLINE
    refinement: population  9 module(s) (0 outside the population),  9 BYTE-IDENTICAL, 0 DIVERGENCE(S), 0 SUBJ-DECLINE
    ```
    **The claim scales; the gap I went looking for is not a hole.** (It remains a one-token-IR-twin
    claim — see `F-E2-1` and `F-E2-2` for what that instrument cannot see.)
12. **Destinations the population did not cover (the prompt's item 5).** Every one is a `D→A` mover
    with **0 bytes of stderr**, STRICT stage-2b clean, and — where it links — a trace **byte-identical
    to its written-zero twin** run on the ORACLE:

    | probe | destination of the outcome | SUBJECT trace sha | twin (ORACLE) |
    |---|---|---|---|
    | `z1` | `switch` scrutinee guarding quantum arms | `6ce3829ef2c7c3ed` | **equal** |
    | `z2` | inside a `cq_invert_begin/_end` bracket | (link unresolved on **both** binaries — pre-existing) | lowered streams equal |
    | `z3` | stored to a global | `ea3c225a0aadc87e` | **equal** |
    | `z4` | argument of a `noinline` classical call | `ea3c225a0aadc87e` | **equal** |
    | `z5` | loop-carried classical phi, beside a rolled in-loop `cq_theta` | `e53ecc1a125bc066` | **equal** |
    | `z6` | `cq_measure(cq_measure(u))` — nested sink | `e3b0c44298fc1c14` (empty) | **equal** |
    | `z7` | **two** whole-value undef measures in one module | `ea3c225a0aadc87e` | **equal** |
    | `z9` | result **unused** | `ea3c225a0aadc87e` | **equal** |
    | `x1` | **cross-function** (bd `1yeu`): undef measure in fn A, quantum in fn B | `ea3c225a0aadc87e` | **equal** |
    | `z8` | undef **rotation angle** beside the undef measure (E1 × E2) | `243328cdcef5e209` | see below |

    ⚠ **`z8` deserves its own line because a rotation-angle destination is the f64/angle family.**
    `double a; int u; q = cq_theta(0, a); cq_measure(u) + cq_measure(q);` moves `D→A` and emits
    `cqrt_ry_i32(h0, 0x1.800000004p-1037)` — a garbage angle. **That is E1's ruled behaviour
    (bd `dnqo`: *"ship as-is … `cqrt_ry_<W>(h, undef)` links, runs and prints a garbage angle"*), not
    E2's**, and I proved it by control: `z8c_undef_angle_only.c` (the same program with the undef
    measure deleted) **already accepts on the ORACLE** with the **identical** trace sha
    `243328cdcef5e209`. E2 removed a preemption; the circuit is one HEAD already emits. ✔
    ⚠ Note separately that E2's *own* token behaves correctly in this module: no rail is allocated for
    the classical measure, and `e2s`'s angle destination becomes a **defined** `0x0p+0` rather than an
    `undef`, which is the RAUW-target discriminator working.
13. **The e2e layer, which E2 ships no gate on (§7.1) — measured, 409/409.** The track's claim that
    no committed golden can move is an **argument**; I turned it into a measurement. Compiling every
    `tests/e2e/*.c` at the harness's own stage-1 flags and grepping for a whole-value
    `undef`/`poison` `@cq_measure_<sfx>` operand:
    ```
    409 .c files · 389 compile standalone · 0 HIT · 20 do not compile
    ```
    and the 20 are **structurally incapable** of holding one, not merely uncovered:
    * **18** are `tests/e2e/*_lib.c` carrying a deliberate
      `#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"`.
      Verified they call **no** `cq_*` intrinsic at all — the only match in any of them is the guard
      `#ifdef cq_theta` itself (`for f in tests/e2e/*_lib.c; do … grep -cE 'cq_(theta|measure|phi)\s*\('`
      → **zero non-comment call sites in all 22 lib TUs**).
    * **2** are `slice_control_select_{bool,cmp}_round2_window.c`, the **unregistered,
      golden-less** conversion-header files kept by the bd `3d8q` landing (CLAUDE.md §4c). Their
      `.expected.log` files **do not exist**, and the only mentions of them in
      `tests/e2e/CMakeLists.txt` (lines 5470/5489/5493/5556/5560) are **comments recording that the
      goldens were deleted** — they are not registered tests.
    ⇒ **No registered e2e slice can move**, and that is now measured rather than argued.
    ⚠ **My own instrument disagreed with itself here and I record it rather than quietly taking the
    last number** (L10 applies to reviewers too): three invocations of this sweep returned 20, then
    **1**, then 20 non-compiling files. The outlier was a parallel spelling of my own harness. I
    settled it by running `clang` on individual members and reading the actual diagnostic, which is
    how the 18/2 split above was established — not by trusting any of the three totals.

**What would have caught `F-E2-1` if the track had run it:** a **C-level** twin sweep — SUBJECT on
the `undef` spelling against ORACLE on the `= 0` spelling of *the same C source* — rather than the
one-token IR twin. The track ran exactly one such comparison (`e2g`/`e2h`, `GATES.md` line
*"C-level twin"*), on a program where the two coincide. Two more probes on that instrument
(`e2e`/`e2f`, which the track already had on disk, and any `cq_measure(q + u)` spelling) would have
produced both findings.

---

## 4. Opinion on the track's open item 3 — the residual decline as an over-decline candidate

Asked for explicitly. **I agree with not taking the swap in this change — but the track's stated
reason is the weaker of the two available, and the filing should be re-grounded before someone acts
on it.**

* **The track's reason is hygienic**: *"it would leave `kMsgUndefOperand` with no customer at all —
  a string with no fixture is the mirror of a fixture with no subject."* Under the owner's
  2026-09-11 ruling (*an over-decline is a defect to remove, not a free safety margin*), **hygiene is
  not a ground for keeping an over-decline.** The correct response to "no customer" is to delete the
  string, and E2's own retirement trigger (iv) already says so in those words. So this reason,
  standing alone, would not survive a challenge.
* **The reason that does survive is semantic, and it is the L3-mirror.** `slotCarriesUndef`'s
  `SkipGlobals=true` exists for **emitted gate slots**, and its argument — *"a `GlobalValue`'s
  operands are its INITIALIZER, while the value under test is the global's ADDRESS, which is defined
  no matter what it is initialised to"* (`LiteralIntegrity.cpp:93-94`) — is an argument about
  **literal integrity at the `-O0` stage-3 link**: the same token must denote the same value at every
  slot the lowering copies it to. A **measurement** asks a different question (*what value does this
  read report?*), and nobody has ruled whether an initializer's `undef` field is reachable from it.
  Swapping the predicate would be **adding a caller to a shared predicate without asking whether the
  callee's argument reaches the new caller** — precisely the mirror-of-L3 defect CLAUDE.md records as
  costing a P1 filing on 2026-09-14 (`WireWalk.h` / `readerStalesItself`). `WireWalk.h`'s
  instruction — *widen the vocabulary or fence the caller in the same change* — applies verbatim.
* **Practical weight: near zero.** I re-derived the membership rule independently and it agrees with
  §2.1: a residual member needs a `GlobalValue` in the operand's constant chain, because the LLVM-19
  parser folds everything else (measured, §3 item 9). In C that means a program spelling roughly
  `cq_measure((int)(intptr_t)&g)` with `g` partly uninitialised. No customer writes it.

**Recommendation:** leave the residual declining; **re-write the filing's rationale on the semantic
ground**, keep trigger (iv) as the binding half (*if the swap is made, `kMsgUndefOperand` must be
DELETED in the same change*), and record that the hygienic reason is not load-bearing. If the owner
does want the swap, it needs its own ruling, not developer discretion — the question being asked is
*"does a measurement read a global's initializer?"*, which is a semantics question the project has
never answered.

---

## 5. Housekeeping — four notes, none a finding

1. **Two records disagree on which track owns this work.** `DECISIONS.md` E2 ends *"**Track M.**"*;
   `ROUTING.md:167` says *"Track E2 spawned into Group 1 on branch `fve8-undef-measure`"*. ROUTING is
   later and is what shipped. Harmless, but the merge gate attributes movers **per track by string**
   (`IMPL_E2.md` §5), so the two names should be reconciled before that attribution is read.
2. **`refinement_check.py`'s docstring is false about its own mechanism.** It says both binaries read
   *"files written into the SAME temp directory with the SAME basename"*; the code writes `m.ll` and
   `twin_m.ll`. It is **harmless** — `body()` strips `; ModuleID` and `source_filename`, which is
   where the path leaks — but an instrument's self-description being wrong is the L10 class, and this
   instrument is the one the ruling rests on.
3. **`ir-pass/test/lowering_reject_measure_undef_operand.ll` is now an ACCEPT under a `reject_`
   name.** Deliberate and correct (bd `gahu` / L8 — a `git mv`'d fixture can be resurrected by a
   merge), the header says so, and this review endorses it. It should be added to bd `gahu`'s list,
   which already tracks three such fixtures from bd `z9t1`; it is now **four**.
4. **Out of scope, measured identical on both binaries, flagged only so it is not mistaken for E2's:**
   `ll/w3_vector_undef.ll` (`declare <2 x double> @cq_measure_v2f64(<2 x double>)` with an `undef`
   operand) **accepts at exit 0 on the ORACLE and the SUBJECT alike**, because an unrecognised suffix
   never enters `MeasureFns` and `declineSurvivingIntrinsicCalls` only knows `wd.allSuffixes()`. A
   reserved-name question that predates this change.

---

## 6. Summary table

| id | class | severity | shape | disposition |
|---|---|---|---|---|
| `F-E2-1` | over-accept; undisclosed rival; instrument blind spot | **P1** | `int u; int q = cq_theta(0,0.3); return cq_measure(q + u);` — `-O1` folds the operand to `undef`, (1a) reports 0, the user's **quantum** measurement is absent from the circuit, 0 bytes stderr | **Owner question** (it is bd `21mg` Q-1 / trigger (iii)); class pre-exists at HEAD via `q * u` / `q & u`; **disclosure must name the rival either way**; red-green pair specified in §1 |
| `F-E2-2` | documentation defect, in shipped source | **P2** | *"byte-identical to what a written `= 0` produces"* is false for the multi-use shape (`e2e`, the track's own probe); what was measured is the one-token IR twin | One edit in `IMPL_E2.md` §6 **and** `MeasureLowering.cpp` |
| `F-E2-3` | incomplete retirement-trigger set (L3-mirror), in shipped source | **P2** | E2 declares itself a "SECOND CUSTOMER" of `z9t1`'s trigger (ii) as a **pair**; the uniquing half has no mechanism in E2, and the fact that *does* carry the argument — `lowerMeasures` runs after every `Value*`-identity fence — is stated nowhere | Split the trigger; add the ordering fact, cross-referenced to bd `21mg`'s ordering trigger |
| item 3 | over-decline candidate (the track's own) | **P2** | the `GlobalValue`-initializer residual at (1b) | **Do not swap**; re-ground the filing on the semantic (L3-mirror) reason, not the hygienic one |

**A green suite clears nothing here, and neither do this review's thirteen held checks.**
`F-E2-1` and `F-E2-2` are the same thing seen twice — the boundary of what the one-token refinement
twin can see — and `F-E2-1` was reachable only by asking the twin question at the **C** level, on a
program with real quantum content, which is the one comparison the track ran exactly once.
`F-E2-3` is the borrowed-argument failure, and it is the one this project has now filed three times
(`WireWalk.h`/`readerStalesItself`, the `lgamma`/`tgamma` Bennett-grounding mistake, and here).

**Rule-13 budget note.** CLAUDE.md's measured hit rate says the next round finds something. This was
round 1 on a change the track itself called *"the sole sink; small is not exempt"*, and it produced
one P1 and two P2s. **Do not close this as Rule-13-cleared on one round** — and in particular, the
composition that has had **no** review at all is `F-E2-1` against the rail-bank headline, since both
land in `lowerMeasures`' branch (1) and the headline's whole purpose is to keep a *different* class
of value out of it (`MERGE_FILINGS` F-1's lesson: *a composition is not cleared by clearing its
parts*).
