# review_r1_L2 — Rule-13 ROUND 1, lens L2
## "Strip after a diagonal gate; operand relabelling between mint and strip"
Subject: `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`),
binaries `build/ir-pass/cq-opt` + `build/ir-pass/libCQPass.so`, archives `build/runtime/*.a`.
Oracle: `$SP/wt/pre-3qlq` (52d7764), its own binaries + archives.
Reproducers, IR, traces: `$SP/progress/review_r1_L2/` (`c/` 50 sources, `ll/` 2 hand-IR,
`out/` 39 full-pipeline runs, `run.sh` the 4-stage driver).
Every cited program was run stage 1 → 2 → **2b STRICT** → 3 → 4 on the named binary.
**Stage 2b `free_pairing_check.py` reported `0 violation(s), 0 unproven` on all 39 runs,
including every miscompiling one** — measured, not assumed.

---

## F-L2-1 — CONFIRMED MISCOMPILE (plain C, 5 reproducers, hits a SHIPPED e2e slice)
**The whole-DAG uncompute spine emits the ADJOINT of the kickback gate on the ziov
shared-condition-flag path, cancelling the branch phase to EXACTLY zero. The program's
only quantum output is erased.**

### Reproducer (the smallest; `c/sharecond.c`)
```c
int slice(void) {
  int q = cq_theta(3, 0.5);
  int c = (q > 5);
  if (c) cq_phi(0.25);          /* the ONLY quantum output of this program */
  return cq_measure(q) + cq_measure(c);
}
```
### SUBJECT trace (`out/sharecond.subject.trace`, `opt` exit 0, 2b STRICT clean)
```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_sgt_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1p-2)                      <-- the branch phase
cq_template_zext_i1_to_i32(h1) -> h2
cqrt_rz_i1(h1, -0x1p-2)                     <-- ITS ADJOINT, emitted by the spine
cq_template_icmp_sgt_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h0) -> 0
cqrt_measure_i32(h2) -> 0
```
### The flagship 2-gate form (`c/sharecond_2gates.c`) — this IS a shipped slice
`c/sharecond_2gates_old.c` is the same program on the retired surface; run on the ORACLE it
produces a trace **byte-identical to the committed
`tests/e2e/slice_control_cond_datause.expected.log`** (verified with `diff`, IDENTICAL).
So `c/sharecond_2gates.c` is exactly what prep-b's rewrite of that slice will be.

| | |
|---|---|
| ORACLE (`out/sharecond_2gates_old.oracle.trace`, 10 lines) | `…icmp_sgt_hl(h0,5)->h1` · `rz_i32_controlled(h1,h0,.25)` · `rz_i32_controlled(h1,h0,.75)` · `zext(h1)->h2` · `add(h0,h2)->h3` · `zext_unc(h2,h1)` · `free(h2)` · `measure(h3)` — **no strip, no free of h1, no adjoint** (the ziov contract, stated verbatim in the slice header) |
| SUBJECT (`out/sharecond_2gates.subject.trace`, 14 lines) | the same, **plus** `rz_i1(h1,-0x1.8p-1)` · `rz_i1(h1,-0x1p-2)` · `icmp_sgt_hl_unc(h1,h0,5)` · `free(h1)` inserted between `free(h2)` and the measure |

### The unitary
Write `c(x) = [x>5]`, `θ = 0.25 + 0.75`.
1. mint → `Σ αx |x⟩_h0 |c(x)⟩_h1`
2. the two `rz_i1` → `Σ αx e^{iθc(x)} |x⟩|c(x)⟩`
3. `zext`/`add` → `Σ αx e^{iθc(x)} |x⟩|c(x)⟩|c(x)⟩|x+c(x)⟩`, `zext_unc` + `free(h2)`
4. **the two adjoint `rz_i1`** → `Σ αx e^{iθc(x)}e^{-iθc(x)} |x⟩|c(x)⟩|x+c(x)⟩ = Σ αx |x⟩|c(x)⟩|x+c(x)⟩`
5. strip, free, measure.

The final state carries **no phase at all**. The intended state is
`Σ αx e^{iθc(x)} |x⟩|x+c(x)⟩`. The `zext` copy in between is a basis permutation that leaves
`h1`'s label untouched, so the adjoint cancels the forward gate **exactly** — this is not an
approximation and not a rounding residual. `if (c) cq_phi(θ)` compiles to the IDENTITY.
That is the same defect class the whole epic exists to retire (PRD §1: "every shipped Grover
golden is the identity on q"), reappearing one code path over inside the fix.

### Root cause (measured, not inferred)
`ir-pass/src/ChainWalk.cpp:226` — `isInPlaceGateOn`'s generic uncontrolled-rotation row:
```cpp
  if ((N.starts_with("cqrt_ry_") || N.starts_with("cqrt_rz_")) &&
      G->arg_size() == 2 && G->getArgOperand(0) == H)
    return true;
```
The kickback gate `cqrt_rz_i1(f, θ)` matches it **exactly** (name, arity 2, handle at arg 0),
so the spine reads the branch phase as an *in-place gate on the flag rail*. With
`ChainWalk.cpp:459` (`preservesBasisUnderRecord`'s `cqrt_rz_` row) also true and the only
other user of `h1` being a template producer (`zext`), `isInteriorTerminalHandle(h1)` is TRUE:
the M-B interior partition claims the flag, `DagTraversal` puts the `cqrt_rz_i1` into
`D.Calls`, and `emitDagReversal` + `EmitInverse.cpp:192` emit `cqrt_rz_i1(h1, -θ)`.

**A/B that isolates it, both on the subject, both plain C:**
* `c/sharecond.c` — flag users = {`cqrt_rz_i1`, `zext`} → **adjoint emitted** (miscompile).
* `c/sharecond_tailphi.c` — identical program plus an `else` arm, so the flag also has
  `cqrt_x` users. `cqrt_x` is a permutation `isInPlaceGateOn` deliberately refuses ⇒
  unrecognized consumer ⇒ `NotClosed` ⇒ **nothing is claimed, no adjoint, no strip, no free**
  (`out/sharecond_tailphi.subject.trace`, 13 lines) — which is precisely the oracle's ziov
  behaviour. The only difference between the two flag user-sets is the `cqrt_x`.

The reason the ORACLE is immune is written down in this very file:
`isInPlaceGateOn`'s Inc-2a note refuses `cqrt_rz_<W>_controlled` **for exactly this reason**
("as a DAG LINK the gate joins `D.Calls`, so `emitDagReversal` emits its adjoint"). Inc 1
replaces that `_controlled` gate with an *uncontrolled* one on the flag and the generic row
above admits it. This is the 8h7d.5 F-1/F-3 lesson verbatim — **a set was narrowed for the
`_controlled` stem and the other set (the uncontrolled row) was never asked the same
question.**

### Confirmed reproducers (all plain C, all subject exit 0, all 2b STRICT clean)
| file | trace | shape |
|---|---|---|
| `c/sharecond.c` | `out/sharecond.subject.trace` | `int c=(q>5); if(c) cq_phi(θ);` + `measure(c)` |
| `c/sharecond_2gates.c` | `out/sharecond_2gates.subject.trace` | the shipped `slice_control_cond_datause` shape, N=2 gates |
| `c/sharecond_neg.c` | `out/sharecond_neg.subject.trace` | `icmp ne` (no `cqrt_x`, so still exposed) |
| `c/sharecond_ret.c` | `out/sharecond_ret.subject.trace` | flag escapes via `ret` instead of a measure |
| `c/sharecond_derived.c` | `out/sharecond_derived.subject.trace` | derived condition `q & 7` + shared flag |

### Proposed fix
`ir-pass/src/ChainWalk.cpp:226` (`isInPlaceGateOn`) — refuse a gate the control emitters
recorded as a BRANCH PHASE. Add a `TaintSet::BranchPhaseGates` set (mirroring
`DischargedFlagGates`), populated at the two emission sites
`ir-pass/src/SwapRouteEmit.cpp:1449` (`emitPhaseKickbackRegion`'s `emitArm` gate loop) and
`:1477` (its merge-tail loop) — and, PRECAUTIONARILY, `ir-pass/src/AngleSelectEmit.cpp`'s Rz
stem, which is not reachable today (`control_angle_select_phase_{constants,runtime}.ll` both
emit mint==strip, and a select over a shared compare declines) — and make the row read
`&& !taint.BranchPhaseGates.count(G)`. That reproduces the route's / the `_controlled` rz's
verdict exactly: unrecognized consumer ⇒ `NotClosed` ⇒ Rule-6 safe leak ⇒ the oracle's ziov
stream. **Then ask the 8h7d.5 question about every other set computed over the same
closure**: `preservesBasisUnderRecord` (`ChainWalk.cpp:459`), `railOf`,
`Uncomputation::preservesBorrowedParent` clause (1) (`Uncomputation.cpp:595`) and
`EmitInverse::isInverseEmittable` (`EmitInverse.cpp:192`) all key on the same
`cqrt_rz_`+arity-2 shape.
*(A narrower alternative — make `emitPhaseKickbackRegion` DECLINE loudly on
`R.ShareCondFlag` — is safe and one line, but it regresses a shipped e2e accept, so it is a
fallback, not the fix.)*

### Pinning fixtures
1. `ir-pass/test/control_phase_kickback_sharecond.ll` — accept; whole-file pure-negative
   `NOROUTE` prefix carrying `; NOROUTE-NOT: @cqrt_rz_i1(i32 %{{.*}}, double -` and
   `; NOROUTE-NOT: @cqrt_free(i32 %h_cmp)`, counts in their own `C<n>` prefixes.
   **There is no such fixture today — see F-L2-3.**
2. e2e: the post-migration `tests/e2e/slice_control_cond_datause.expected.log` must be the
   oracle golden with only the two `cqrt_rz_i32_controlled(h1,h0,·)` lines replaced by
   `cqrt_rz_i1(h1,·)` (PRD §10.2 diff class (a)). At HEAD the subject would produce four
   extra lines; a golden regenerated from HEAD would BLESS the miscompile.

---

## F-L2-2 — PRE-EXISTING CLASS, but Inc 1 makes owner-decision **D4** its headline customer
**The D4 per-bit idiom, ROLLED, leaks one entangled `and` rail PER ITERATION; the
hand-unrolled twin uncomputes and frees every one of them. The two circuits are different
unitaries on `q`.**

`c/inloop_perbit.c` (`for (i<4) if ((q>>i)&1) cq_phi(0.3);`) vs `c/unroll_perbit.c` (the same
four `if`s written out). Both subject, both exit 0, both 2b STRICT clean.
`diff out/inloop_perbit.subject.trace out/unroll_perbit.subject.trace` — the unrolled form has
four extra pairs and the rolled form none:
```
> cq_template_and_i32_hl_unc(h1, h0, 1)
> cqrt_free(h1)                                (×4, one per bit)
```
Lowered IR (`out/inloop_perbit.subject.s2.ll`): the loop body mints `%h_op =
cq_template_and_i32_hl(%h, %4)` and never `_unc`s or frees it — K live rails at K=32, the
PRD's own measured case.

**Analytic:** `a_i = bit_i(q)` left allocated is `Σ αx e^{iφ(x)}|x⟩|a_0(x)⟩…|a_{K-1}(x)⟩`.
The ancillas are a reversible record of `x`, so no later diffusion/interference step can mix
different `x` — which is the whole point of a marking oracle. The unrolled circuit is the one
the source means.

**It is NOT Inc 1's defect and NOT arm-class-specific — measured on the ORACLE.**
`c/perbit_ry_old.c` (drbq Inc-3 in-loop controlled-**Ry** arm, per-bit condition) on the
ORACLE: the `and` rail IS uncomputed. `c/perbit_ry_old_nogate.c` — the same program with the
`q = cq_theta(q,0.1)` removed from the body — on the ORACLE: the `and` rail is **leaked**
(`out/perbit_ry_old_nogate.oracle.s2.ll` has no `and_i32_hl_unc`; 2b reports "4 rail mint(s)
of which 4 left allocated"). The discriminating variable is **whether the loop body carries a
rail gate on the condition register**, not the arm class and not the kickback:
* subject, kickback, body gate present (`c/perbit_kick_gate.c`) → uncomputed ✔
* subject, kickback, no body gate (the D4 idiom) → leaked ✘
* oracle, Ry arm, body gate present → uncomputed ✔
* oracle, Ry arm, no body gate → leaked ✘

**Why it still belongs in this round.** The implementer's hand-back records the D4 measurement
as "with ONE `_unc`+`free` — the `and` rail is left allocated, Rule 6, and stage 2b agrees"
and does **not** record that the hand-unrolled twin discharges it. The project's stated
witness for every in-loop lowering is BYTE-IDENTITY with the hand-unrolled twin (8h7d.5,
drbq Inc 3), and this pair diverges. Owner decision D4 names this loop as *the* idiom for
marking a multi-bit target, so Inc 1 adds the increment's own flagship customer to a
known-defective path — the phrasing CLAUDE.md already uses for drbq Inc 3's classes.
**Not this reviewer's to bless.** Disposition options: a pinned-signature quarantine cell in
`tools/loop_twin_matrix.quarantine.txt` with a new bd class, or an owner ruling.

Fix location if it is to be fixed: the interior-DAG terminal selection for a loop-carried
template rail (`ChainWalk::isInteriorTerminalHandle` / `Uncomputation`'s in-loop discharge),
not anything in this increment.

---

## F-L2-3 — DOC-OR-FIXTURE-TRUTH: the `R.ShareCondFlag` branch ships with ZERO coverage
`emitPhaseKickbackRegion`'s ziov path (`SwapRouteEmit.cpp:1403` `FlagAt`, `:1425–1426`
`SharedCondFlags`, `:1492` the skipped strip+free) — the branch that miscompiles in F-L2-1 —
is exercised by **no lit fixture and no e2e slice at HEAD**.

MEASURED: every one of the 11 accept fixtures was run through `build/ir-pass/cq-opt` and its
output counted; a ziov emission is the only one with a mint and no strip:
```
control_phase_kickback_derived_cond      mint=2 strip=4 rz_i1=2
control_phase_kickback_diamond           mint=2 strip=2 rz_i1=2
control_phase_kickback_f64_cond          mint=0 strip=2 rz_i1=2
control_phase_kickback_ifelse_tail_phi   mint=2 strip=2 rz_i1=4
control_phase_kickback_inloop            mint=2 strip=2 rz_i1=2
control_phase_kickback_negated           mint=2 strip=2 rz_i1=2
control_phase_kickback_seq               mint=3 strip=3 rz_i1=3
control_phase_kickback_two_calls         mint=2 strip=2 rz_i1=3
control_angle_select_phase_constants     mint=2 strip=2 rz_i1=3
control_angle_select_phase_runtime       mint=2 strip=2 rz_i1=3
```
(`grep -c` over `cq-opt -passes=cq-lowering -S <fixture>`; mint == strip everywhere, i.e. the
`if (!R.ShareCondFlag)` branch is taken in all 10.) The emitter's ziov paragraph
("THE ZIOV SHARED-FLAG PATH IS HONOURED … byte-for-byte the rule `emitRegion` follows",
`SwapRouteEmit.cpp:1311–1318`) is therefore an **unverified claim**, and it is false at HEAD:
the spine puts the strip and the free back, plus the adjoint.

Fix: ship the F-L2-1 fixture and re-derive the `slice_control_cond_datause` golden from the
ORACLE (diff class (a)), never from HEAD.

---

## F-L2-4 — OBSERVATION (low): gates emitted on a MEASURED condition register
`c/measured_before.c` — `int m = cq_measure(q); if (q == 5) cq_phi(0.25);` — ACCEPTS on the
subject and emits `cqrt_measure_i32(h0)` and only then `cq_template_icmp_eq_i32_hl(h0,5)`,
`cqrt_rz_i1`, the strip and the free (`out/measured_before.subject.trace`). The nearest oracle
spelling `c/measured_before_old.c` **declines** `cq controlled lowering: control flow under
quantum control` — but that program also gates `q` after the measure, so it is not a clean
twin and there is **no oracle spelling of this shape**. Analytically the emitted stream is
harmless (after collapse the kickback is a global phase on the selected branch), so this is
**not** graded a miscompile; it is dead work on a measured register that the project's own
FreePoint discipline ("a post-measure gate is a loud reject, never a silent skip") treats as a
loud reject elsewhere. Worth an explicit decision rather than an accident.

---

## What this lens checked and found CLEAR (each with its measurement)
1. **In-place `cq_theta` on `q` inside the arm** — `c/arm_theta_mixed.c` declines
   `cq controlled lowering: condition predates a non-diagonal gate under quantum control`.
2. **In-place dtzb `add` on `q` inside the arm** — `c/arm_add_mixed.c` declines
   `cq controlled lowering: arm rewrites a condition operand under quantum control` (§3c).
3. **Ry between the compare and the branch** — `c/stale_theta_between.c` declines
   `condition predates a non-diagonal gate`. Same for an Ry on the DERIVED rail
   (`c/derived_rail_theta_before.c`) and a sibling Ry on the ROOT wire
   (`c/derived_root_theta_before.c`, `c/sibling_theta_before.c`).
4. **In-place `add`/`xor` between the compare and the branch** — NOT reachable from `-O1` C
   (SimplifyCFG always sinks it past the diamond: `c/stale_add_between.c`,
   `c/stale_xor_between.c` both emit `addc`/`xorc` AFTER the free, correct). Forced in hand IR
   (`ll/addbetween.ll`): the pass lowers the `add` **out of place** into a fresh rail
   (`cq_template_add_i32_hl(%h,7) -> %h_op`) because the flag mint emitted at `BI` is a later
   record read of `%h`, so M-C's G6/G7 refuses the in-place conversion. The mint and the strip
   both read the untouched `%h`. **Correct, and correct for a stated reason** — but note the
   reason lives in M-C, not in any kickback fence: `condWireDisposition`'s positional scan
   (`ArmClassify.cpp:1738`) only looks for `cq_theta_` calls, and
   `findNonDiagonalWireGate` only flags `cq_theta_`, so **neither sees an in-place
   `add`/`xor`**. If the mint position ever moves earlier (it does on the ziov path, where it
   is at the compare), that protection changes character.
5. **Merge-block content between the tail φ and the tail `cq_phi`** — `c/tail_theta_mid.c`
   (an in-place `q = cq_theta(q,0.4)` sitting between them, plain `-O1` C) ACCEPTS and hoists
   the tail gates ABOVE the Ry. **That is correct**: the gate is `rz_i1` on the FLAG, and a
   gate on the flag commutes with any gate on `q`, so `[mint; phase; strip; U]` is exactly the
   only physically realizable reading of "phase the branch that was taken", the branch label
   being `c(x_before)`. Verified in the trace (`out/tail_theta_mid.subject.trace`). Same for a
   `cq_measure` between them (`c/tail_measure_between.c`) and for an extra unconditional
   `cq_phi` in the merge (`c/tail_two_phases.c`, correctly deleted as a global phase, D2).
   `c/tail_theta_between.c` — the same idea with genuinely empty arms — is folded by `-O1`
   into an angle `select` and declines `condition predates a non-diagonal gate`.
6. **Sequential regions, bd hcrg ordering + the new `sequentialChainAlias` widening to
   `PhaseKickback`** — `c/seq_theta_between.c` and `c/seq_add_between.c` (an Ry / an in-place
   `addc` between the two regions) both emit region 1's whole mint→strip→free stream, then the
   gate on `h0`, then region 2's — i.e. no region's mint or strip is ever relabelled by the
   other, and the reversed emission order does not leak into the gate stream. (The bare
   `c/seq_plain.c` is folded by `-O1` into a `switch` and declines `control flow` — P5, part
   B's scope, not an ordering defect.)
7. **Derived condition, chain `_unc` ordering** — `c/derived_and.c`:
   `and_hl(h0,7)->h1` · `icmp_eq_hl(h1,3)->h2` · `rz_i1(h2,·)` · `icmp_eq_hl_unc(h2,h1,3)` ·
   `and_hl_unc(h1,h0,7)` · `free(h1)` · `free(h2)`. The chain `_unc` runs strictly AFTER the
   flag strip, both rails are stripped before either free, 2b STRICT clean. Holds with a live
   register (`c/derived_and.c`), a dead register (`c/derived_and_dead.c`), a post-region Ry on
   the root (`c/derived_and_theta_after.c`), a measured derived rail
   (`c/derived_measured.c`), an in-place `addc` on the derived rail after the region
   (`c/derived_addafter.c`) and an in-place Ry on the derived rail after the region
   (`c/derived_theta_on_rail.c`).
8. **N gates per arm with something between them** — structurally impossible:
   `ArmClassify.cpp`'s `collectArm` requires `BB->size() == N + 1` with every non-terminator a
   register-free phase call, so no instruction can sit between two gates of one arm. Read, not
   only argued.
9. **The `cqrt_x` bracket is closed before the strip and before the free** — checked
   mechanically over all 39 traces (per-handle `cqrt_x` parity at every `_unc` and every
   `cqrt_free`): **0 violations**.
10. **fp condition** (`c/fp_cond.c`: `fcmp_ogt_f64_hl` mint + matching `_hl_unc` strip) and a
    **cast condition** (`c/cast_cond.c`, folded by `-O1`) both correct.
11. **In-loop kickback with a body gate on `q`** (`c/inloop_grover.c`, the rolled Grover) —
    per-trip mint/strip pairs, each reading `h0` in the basis its own trip's mint read, with
    the body `cqrt_ry_i32(h0,·)` strictly between one region's free and the next region's
    mint. Correct.

## Verdict
**NOT CLEAR — one CONFIRMED SILENT MISCOMPILE (F-L2-1), plain-C reachable, on the shape of a
SHIPPED e2e slice, in a code path with zero fixture coverage (F-L2-3); plus one measured
rolled≠unrolled divergence on the increment's own D4 headline idiom that is a PRE-EXISTING,
arm-class-independent class the increment adds a customer to (F-L2-2, owner disposition), and
one low-grade over-accept observation (F-L2-4).**
The operand-relabelling surface this lens was pointed at — the thing the emitter's header
calls "unconditional in a way no other arm class can claim" — is genuinely clean (items 1–11).
The miscompile is one layer down: the branch phase itself is not protected from the
uncomputation spine, which is the drbq Inc-2a `_controlled`-Rz lesson repeated for the
uncontrolled stem.
