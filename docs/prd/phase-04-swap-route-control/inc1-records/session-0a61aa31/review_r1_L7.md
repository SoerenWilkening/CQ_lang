# review_r1_L7 — Rule-13 round 1, lens L7 (free / uncompute interaction)
bd `test_C_libtooling-3qlq.2` Inc 1 part A (register-free `cq_phi` by kickback).
READ-ONLY. Nothing in the tree was edited.

SUBJECT  `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`),
         `build/ir-pass/cq-opt` + `build/ir-pass/libCQPass.so` + `build/runtime/*.a`.
ORACLE   `$SP/wt/pre-3qlq` @ `52d7764`, its own `cq-opt` / `libCQPass.so` / archives.
HARNESS  `$SP/progress/review_r1_L7/run.sh <file.c> <subj|orac>` — stage 1 (`clang -O1`
         `-I<repo>/include -include CQ.h`) → stage 2 (`cq-opt -passes=cq-lowering`) →
         stage 2b (`tools/free_pairing_check.py`, **STRICT**, no `--allow-unproven`) →
         stage 3 (link, templates before runtime) → stage 4 (run). Outputs in
         `$SP/progress/review_r1_L7/out/<base>.<which>.{s1.ll,s2.ll,2b.txt,trace,diag,status}`.
MEASURED 52 plain-C probes, 54 pipeline runs: **40 accept-and-run**, **12 loud stage-2
         declines**, 2 stage-1 (source) failures that are my own probe errors, not findings
         (`ls out/*.status | wc -l` = 54; `cat out/*.status | awk '{print $1}' | sort |
         uniq -c`). Every accept was linked and RUN. No lit/ctest was run (read-only lens).

---

## F-L7-1 — CONFIRMED-MISCOMPILE
**The whole-DAG uncompute spine emits `cqrt_rz_i1(f, −θ)` and CANCELS the kickback
phase: on the ziov `ShareCondFlag` path the user's `cq_phi(θ)` is compiled to the
identity.** Plain C, `clang -O1`, `opt` exit 0, verify-clean, **STRICT stage 2b: 0
violations**, golden-diffable — and neither shipped gate can see it.

### Reproducer (4 statements)
`$SP/progress/review_r1_L7/probes/j3_sharecond_measure_only.c`
```c
int slice(int u) {
    int a = cq_theta(u, 0.5);
    int b = (a == 5);              /* the compare is ALSO read as data → ShareCondFlag */
    if (a == 5) cq_phi(0.25);      /* the kickback */
    return cq_measure(b) + cq_measure(a);
}
int main(void) { (void) slice(5); return 0; }
```

### SUBJECT trace (`out/j3_sharecond_measure_only.subj.trace`, exit 0, 2b PASS)
```
cqrt_alloc_i32(5) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_rz_i1(h1, 0x1p-2)                       <-- the kickback phase
cq_template_zext_i1_to_i32(h1) -> h2         <-- the data use (a CNOT-class copy of h1)
cqrt_rz_i1(h1, -0x1p-2)                      <-- ⚠ THE SPINE'S ADJOINT — cancels it
cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
cqrt_free(h1)
cqrt_measure_i32(h2) -> 0
cqrt_measure_i32(h0) -> 0
```
### The same program with `cq_phi(0.25)` DELETED (`probes/j3_nophi.c`, subject)
```
$ diff -u out/j3_nophi.subj.trace out/j3_sharecond_measure_only.subj.trace
 cq_template_icmp_eq_i32_hl(h0, 5) -> h1
+cqrt_rz_i1(h1, 0x1p-2)
 cq_template_zext_i1_to_i32(h1) -> h2
+cqrt_rz_i1(h1, -0x1p-2)
 cq_template_icmp_eq_i32_hl_unc(h1, h0, 5)
```
### ORACLE, the SAME program in the retired register surface (`probes/j3_old.c`, exit 0)
```
cq_template_icmp_eq_i32_hl(h0, 5) -> h1
cqrt_rz_i32_controlled(h1, h0, 0x1p-2)       <-- the phase gate SURVIVES on the oracle
cq_template_zext_i1_to_i32(h1) -> h2
cqrt_measure_i32(h2) -> 0
cqrt_measure_i32(h0) -> 0
```

### The analytic argument about the unitary
`cq_template_zext_i1_to_i32(h1) -> h2` is a basis-label COPY of `h1` onto a fresh
rail; it does not change `h1`'s label. `cqrt_rz_i1(h1, ±θ)` is diagonal in that same
label. Hence the two Rz's commute with the copy and with each other, and

    Rz(h1,+θ) · copy(h1→h2) · Rz(h1,−θ)  =  copy(h1→h2) · e^{i(θ−θ)·h1}  =  copy(h1→h2)

**exactly** — not approximately, not "unobservable in this trace". The emitted circuit
IS the circuit for the program with the `cq_phi` deleted, which is what the diff above
shows line for line. The required final state is `Σ_x α_x e^{iθ[x==5]} |x⟩ ⊗ |c(x)⟩`;
the emitted one is `Σ_x α_x |x⟩ ⊗ |c(x)⟩`. This is PRD §1's own defect class —
"a self-consistent trace of the IDENTITY on q" — re-entering through a different door.

⚠ **HONESTY ABOUT OBSERVABILITY, stated first because the brief demands it.** I could
NOT construct an *accepted* program in which a measurement distinguishes the two
circuits, and the reason is structural rather than lucky: a branch phase `e^{iθc(x)}`
attached to `|x⟩` is only observable once the `x`-branches are RECOMBINED, i.e. by a
later non-diagonal gate on the condition register — and `ShareCondFlag` REQUIRES a live
record of the condition, which is exactly what `condWireDisposition` refuses to let a
later non-diagonal gate stand over. Measured four ways:
* `probes/f1_sharecond_cancel.c` (`a = cq_theta(a,0.7)` after the region) — DECLINES
  `cq controlled lowering: condition predates a non-diagonal gate under quantum control`
  on BOTH binaries.
* `probes/g2_sharecond_two_regs.c` (recombine a second, entangled register) — same decline.
* `probes/g3_sharecond_derived_ry.c` (recombine a fresh DERIVED rail `c = a+1`) — ACCEPTS
  with the cancellation, but `c` carries no which-path label of its own, so the phase
  stays unobservable there too.
* `probes/j1_escape_caller.c` (return the phased register to a caller that recombines) —
  the register is NOT returned coherently (`cqrt_alloc_i32(0) -> h3` in the callee), so
  that route does not exist today.

So the correct statement is: **the emitted unitary is wrong (provably the identity where
a phase was specified), and today no accepted program can measure the difference.** I
grade it CONFIRMED-MISCOMPILE rather than "latent" for three reasons that are this
project's own: (i) the compiler's contract is the unitary, not one program's
distribution — the whole 3qlq epic exists because the shipped tensored `cqrt_rz_<W>` was
*also* unobservable in every shipped golden; (ii) the same source on the oracle KEEPS its
phase gate, so this is a fidelity REGRESSION, not an inherited hazard; (iii) the fence
protecting the non-shared path is the emitter's own `cqrt_free`, so the defect is one
consumer away from a shape that does recombine (Inc 1b's bare-`i1` condition, part B's
compound conditions, and any future widening of `condWireDisposition` all move it).

### Root cause — a set that was widened without asking what else was computed over it
Before 3qlq, `cqrt_rz_<W>(h, θ)` on a rail meant "the user wrote `x = cq_phi(x,θ)`", a
genuine member of `x`'s reversible chain whose adjoint on uncompute is CORRECT (see
`tests/e2e/slice_uncompute_dead_dag.expected.log`: `cqrt_rz_i32(h4,θ)` …
`cqrt_rz_i32(h4,-θ)`). After D1/D2 the register form is retired and `cqrt_rz_i1(f, θ)`
means "the program's ANSWER, kicked back onto an ancilla". Nothing in the uncompute
spine was told. Three predicates still read the symbol the old way:

* `ir-pass/src/ChainWalk.cpp:226` — `isInPlaceGateOn`'s uncontrolled-rotation row admits
  `cqrt_rz_<W>(H,θ)` ⇒ the kickback gate joins `D.Calls`.
* `ir-pass/src/ChainWalk.cpp:459` — `preservesBasisUnderRecord`'s `cqrt_rz_` row returns
  `true` ⇒ (a) `ChainWalk.cpp:694`, `isInteriorConsumer` clause (a), lets the flag rail be
  an M-B INTERIOR candidate, and (b) `ir-pass/src/Uncomputation.cpp:941`
  (`if (!preservesBasisUnderRecord(G)) return false;`) lets the interior group ADJOINT it.
* `ir-pass/src/EmitInverse.cpp:47` / `:191` — `isInverseEmittable` / `emitInverseCall`
  emit the negated-angle twin.

Note the row at `ChainWalk.cpp:459` argues only that a diagonal gate "relabels nothing",
which is the right argument for the FREE and no argument at all for the ADJOINT. And
`ChainWalk.cpp:149-197` already made exactly the right call one stem over: Inc 2a
REFUSED `cqrt_rz_<W>_controlled` in `isInPlaceGateOn` "because the route is the oracle".
The oracle for THIS gate is the same route, and `j3_old` above shows the oracle keeping it.

It is emitted, unrecorded, by `SwapRouteEmit.cpp:1449` (`emitArm`) and `:1477` (the
merge-tail loop). The emitter's own header (`SwapRouteEmit.cpp:1301`) says the gate "is
NOT recorded in `taint.ControlledRotations` … this gate is UNCONTROLLED and is emitted
here, finished" — true of the emitter and false of the module: no set exists for the
spine to consult.

### Proposed fix
1. Record every emitted kickback gate in a new `TaintSet` image (e.g.
   `taint.BranchPhaseGates`) at `ir-pass/src/SwapRouteEmit.cpp:1449` and `:1477`
   (and the `AngleSelectEmit` Rz-stem site, `ir-pass/src/AngleSelectEmit.cpp`), the way
   `DischargedFlagGates` is recorded three lines further down at `:1498`.
2. Make it OPAQUE to the spine, structurally, at the three sites above — preferably by
   asking membership rather than by name, since after part B `cqrt_rz_i1` is the only Rz
   the pass emits and a name test and a membership test would then be the same set
   spelled twice (`railOf` drift, Rule 14). A gate the spine cannot recognise becomes an
   unrecognized consumer ⇒ `D.NotClosed` ⇒ the flag rail is LEFT ALLOCATED — which is
   Rule-6 safe AND is byte-for-byte the oracle's disposition on `j3_old` (no strip, no
   free, 0 `cqrt_free` sites).
3. **Ask what ELSE is computed over that closure before changing it** (bd `8h7d.5`
   F-1/F-3, three times in the drbq record): `railOf`, `isTerminalHandle`,
   `isInteriorTerminalHandle` (I1/I3), `DagTraversal` step-1 `D.Calls` and step-3 closure,
   `Uncomputation`'s moved-anchor scan and clause (d), `preservesBorrowedParent` clause
   (1b), and the 7.4 `lowerBreakReversePlay` capture. Each needs a written decision.
4. The `!R.ShareCondFlag` half of the emitter is protected TODAY only by its own
   `cqrt_free(Flag)` making the flag an unrecognized-consumer rail; that is an accident,
   not a fence, and the fix should not leave it as the argument.

### Fixtures that should pin it
* `ir-pass/test/control_phase_kickback_sharecond_datause.ll` — ACCEPT. The `-O1` IR of
  `j3_sharecond_measure_only.c`. Whole-file **pure-negative** `NOROUTE` prefix carrying
  `NOROUTE-NOT: call void @cqrt_rz_i1(i32 %{{.*}}, double -` (the cancelling adjoint) and
  `NOROUTE-NOT: fneg`, with the count `CHECK-COUNT-1: call void @cqrt_rz_i1` in its OWN
  `ACNT` prefix (the Inc-3 F-L6-1 / Inc-4 windowing lesson — a positive count inside the
  negative prefix windows every `-NOT` after it). **There are 0 such fixtures today**: none
  of the 21 fixtures the increment added exercises `ShareCondFlag` at all.
* A negated twin (`probes/i1_sharecond_negated.c`, `icmp ne`) — measured to cancel too.
* An e2e pair + a `cmp` gate: `slice_control_phase_kickback_sharecond{,_nophi}.c`, whose
  goldens must differ by **exactly one** `cqrt_rz_i1` line. Today they differ by two, one
  of them negated, which is the whole finding in one `compare_files`.

---

## F-L7-2 — DOC-OR-FIXTURE-TRUTH (and an OWNER QUESTION)
**PRD §9's per-bit idiom shape is FALSE for the idiom it describes.** §9 (line 272) pins
D4's per-bit register-wide Z as
`and(h,1<<i) → icmp eq 0 → x → rz_i1 → x → 2 _unc → 2 free`.
MEASURED on the subject: that is true at **K = 1 only**. From **K = 2 upward the `and`
rail is never uncomputed and never freed** — 1 `_unc`, 1 free, per bit.

`probes/n4_perbit32.c` (`for (i<32) if ((q>>i)&1) cq_phi(0.3);`), subject, exit 0, 2b PASS:
```
cq_template_and_i32_hl(       32      <- 32 derived rails minted
cq_template_and_i32_hl_unc     0      <- none uncomputed
cqrt_free                     32      <- the 32 FLAGS only
cqrt_rz_i1                    32
```
and `probes/n1_perbit_then_ry.c` (K=4 followed by a diffusion `cq_theta(q,-0.5)`) compiles
at **exit 0** with
`warning: cq rotation lowering: non-diagonal gate over a live derived record` (twice) and
four live `and` rails — each a basis record of one bit of `q` — standing at the diffusion.
`probes/n3_perbit2.c` shows the same at K=2. The single-region control
`probes/n2_new_derived_leak.c` DOES discharge its `and` rail and warns about nothing, and
is byte-identical to the oracle's old-surface twin `probes/n2_old_derived_leak.c` apart
from the one intended line — so the leak is a fan-out effect of K ≥ 2 regions off one
register, not something about the kickback.

Why it matters and why it is an owner question, not a defect I can grade: D4 blessed the
per-bit loop as THE replacement for a multi-bit Rz, and it is the epic's own worked idiom.
As emitted it does not COMPOSE with the diffusion that makes a phase useful — K live
which-path records at a non-diagonal gate is a dephased circuit, and CQ only WARNS. No
rail is freed dirty (Rule 6 holds) and stage 2b is STRUCTURALLY BLIND to all of it (it
reports "2 rail mints, 2 left allocated" for a program that leaks 32 rails at run time —
the drbq Inc-3 O(K)-freeze-leak reading, verbatim). The implementer's progress file
records "the `and` rail is left allocated, Rule 6, and stage 2b agrees" — accurate as a
measurement, and the consequence is stated nowhere.

Proposed: correct PRD §9's row to the measured `1 _unc → 1 free (+ the and rail left
allocated)`, and put the composition question (per-bit idiom followed by a diffusion) to
the owner. Fixture: `ir-pass/test/control_phase_kickback_perbit_leak.ll` pinning the
measured shape, plus an e2e slice at K=2 whose golden shows the surviving `and` rails.

---

## F-L7-3 — CLEAR (the lens's headline hazard did NOT materialise), with the mechanism named
**No probe frees a register whose branch carried a kickback phase.** The brief's
construction — `int q = cq_theta(0,.3); if (q == 1) cq_phi(PI);` with `q` dead — was run
eight ways and the register is ALWAYS left allocated; `cqrt_ry_<W>(h,−θ)` + `cqrt_free(h)`
never appears on a phased register.

| probe | shape | register disposition |
|---|---|---|
| `a1_deadroot_new.c` | dead root, no measure | left allocated (trace ends at `cqrt_free(h1)`) |
| `c2_kick_deadroot_noinline.c` | same, `noinline` (spine not gated off) | left allocated |
| `c1_kick_deadroots_new.c` | two roots, derived `mul` condition, all dead | `mul` rail reversed + freed (CLEAN, it is a permutation); both roots left allocated |
| `d1_kick_on_root_then_reversed.c` | kickback on a chain that WITHOUT it fully reverses (`d0_base_reversal.c` emits `ry(h0,−.25); free(h0)`) | whole reversal suppressed; byte-identical to the oracle's old-surface twin `d1_old.c` apart from the one intended line |
| `d2_kick_on_derived.c` | condition on the derived rail | same |
| `k1_sharecond_deadreg.c` | shared flag measured, register dead | left allocated |
| `l1_bool_flag_terminal.c` | `_Bool` flag measured at i1 (flag IS a chain terminal) | left allocated |
| `e1_derived_cond_measured.c` | sqrt-derived condition | measured, not freed |

Two mechanisms produce that, and **only the first is structural**:
1. `isInteriorTerminalHandle`'s **(I1)** (`ChainWalk.cpp:791-812`) excludes a
   `cqrt_alloc_`-minted rail from the M-B interior partition outright, and
   `Uncomputation.cpp:921` (`if (!D.Roots.empty()) return false;`) plus `:993`
   (`if (!Owned.count(railOf(G)))`) mean an alloc root can never be adjointed or freed by
   that partition. Structural. ✓
2. In the DEAD-TERMINAL partition the register is protected because its flag-mint
   consumer (`cq_template_icmp_*_hl`) is not a recovered gate ⇒ `DagTraversal.cpp:338`
   sets `D.NotClosed`. **That is an argument, not a fence, and it is FALSE exactly where
   F-L7-1 lives** — on the `ShareCondFlag` path the mint IS recovered. Today the
   register still survives (measured, `k1`) because the interior partition's own `Owned`
   /`Roots` fences (1) catch it one level up. Two independent subsystems, one of them
   incidental: that is the shape this codebase keeps re-finding.

There is therefore no `railCarriesControlledRotation`-style freeze for a kickback
register, and **none is needed** — a kickback emits no gate on the register at all, so
there is no adjoint that would need a freed flag. The Inc-1 drbq freeze does not
generalise here and its absence is correct.

---

## F-L7-4 — CLEAR
**A dead/derived CONDITION chain is uncomputed AFTER the flag strip and freed clean,
byte-identically to the oracle.** `probes/e1_derived_cond_measured.c` (openlibm-style
`sqrt((double)a+3.0) <= 5.0` condition) — subject vs oracle `probes/e1_old.c`:
19 trace lines each, `diff` is exactly the one intended line
(`cqrt_rz_i32_controlled(h4,h0,π)` → `cqrt_rz_i1(h4,π)`); strip → `sqrt_unc`/`free h3` →
`fadd_unc`/`free h2` → `sitofp_unc`/`free h1` → `free h4`; STRICT 2b `8 verified, 0
violations` on both. `probes/k2_sharecond_deadreg_chain.c` shows the same for an `and`
chain. The physics is sound and worth writing down once: every chain rail's forward gates
are basis PERMUTATIONS, and a diagonal phase applied to the joint state commutes with a
permutation, so `|x, f(x)⟩ → |x, 0⟩` still lands exactly on `|0⟩` and the phase is left
where the kickback put it. Only a NON-diagonal chain gate (`cqrt_ry_<W>`) would break
this — and (F-L7-3) no such rail is ever freed.

---

## F-L7-5 — DOC-OR-FIXTURE-TRUTH
**`emitPhaseKickbackRegion`'s `ShareCondFlag` comment claims a byte-for-byte equivalence
that is precisely where the increment differs from its oracle.**
`ir-pass/src/SwapRouteEmit.cpp:1315-1320`: *"THE ZIOV SHARED-FLAG PATH IS HONOURED … the
strip+free are SKIPPED because the data lineage owns the flag — byte-for-byte the rule
`emitRegion` follows."* True of the emitter's four lines; false of the resulting module,
because `emitRegion`'s gate is `cqrt_rz_<W>_controlled` — which `isInPlaceGateOn`
deliberately REFUSES (`ChainWalk.cpp:149-197`, Inc 2a) — while this one is a plain
`cqrt_rz_i1`, which it ADMITS (`ChainWalk.cpp:226`). "The data lineage owns the flag" is
the sentence that authorises the spine to reverse it, and reversing it is F-L7-1. Also:
`0 of the 21` fixtures the increment adds exercise `ShareCondFlag` (measured:
`git diff --name-only dfb8e83..HEAD -- ir-pass/test`, then
`grep -l 'ShareCondFlag\|share'` over the new `control_phase_kickback_*` /
`control_angle_select_phase_*` files → only `control_phase_kickback_seq.ll`, which
mentions the word in prose and does not exercise the path).

Two related dispositions measured while establishing this, recorded so a fix agent does
not rediscover them as regressions:
* `probes/h2_tailphi_sharecond.c` (merge-tail angle φ + a shared compare) — the flag is
  left allocated with the phase **intact**, `0 cqrt_free sites`, no cancellation. The
  `cqrt_x` polarity brackets make the flag an unrecognized-consumer rail, so the spine
  never claims it. **The presence of F-L7-1 therefore depends on the arm polarity of the
  region** — a coincidence, not a rule (`i1_sharecond_negated.c` cancels because
  `clang -O1` folds `!=` into `icmp ne` and emits no bracket at all).
* `probes/h1_angsel_sharecond.c` (P2 angle select + a shared compare) declines
  `cq controlled lowering: rotation angle under quantum control`; `probes/i2_tape_flag.c`
  declines `condition data use neither escaped nor measured`; `probes/i3_tape_register.c`
  declines `cq I/O output sink: tainted argument has continued lineage`;
  `probes/j2_inloop_sharecond.c` declines `condition predates a non-diagonal gate`.

---

## F-L7-6 — DOC-OR-FIXTURE-TRUTH (latent, PRE-EXISTING, not this increment's)
`ir-pass/src/SwapRouteEmit.cpp:1493-1499` emits `cqrt_free(Flag)` **unconditionally**
after a strip that is `dyn_cast_or_null`'d and may be null:
```cpp
auto *Strip = dyn_cast_or_null<CallInst>(lowerCompareToFlag(..., /*inverse=*/true, ...));
if (Strip) taint.DischargedFlagGates.insert(Strip);
stamp(B.CreateCall(wd.freeFn(), {Flag}));       // fires even when Strip == nullptr
```
A null strip with a live free is a free of a rail that was never returned to `|0⟩` = a
hidden measurement (Rule 6). I could not reach it: forward and inverse legs both go
through `lowerCompareImpl` with the same classification (`CompareLowering.cpp:268`), so a
successful forward mint implies a successful strip. It is **byte-identical to the
pre-existing `emitRegion` code at `SwapRouteEmit.cpp:1156-1165`**, so it is inherited, not
introduced. Recorded only so the next widening of `lowerCompareImpl`'s inverse leg does
not turn a leak into a dirty free with nothing asking.

---

## What the two shipped gates can and cannot witness (stated because both are green)
* `tools/free_pairing_check.py` is **structurally blind** to F-L7-1: its own header makes
  `cqrt_rz` transparent (it is diagonal), so the cancelling adjoint is not a rail event at
  all. It reported `0 violations` on every reproducer, and on `j3` it is arguably *happier*
  than on the correct circuit, because the spine's reversal is what makes the free provable.
* The golden byte-diff sees `cqrt_rz_i1(h1, -0x1p-2)` as an ordinary trace line. There is
  no shipped golden containing it, so nothing goes red.
* `opt -verify` is clean and `opt` exits 0 in all 40 accepting runs.

---

## VERDICT — L7: **NOT CLEAR. One CONFIRMED-MISCOMPILE (F-L7-1, plain-C, `opt` exit 0,
verify-clean, STRICT-2b-clean, oracle-declining-or-oracle-correct), one
DOC-OR-FIXTURE-TRUTH with an owner question attached (F-L7-2, PRD §9's per-bit idiom
shape is false at K ≥ 2 and the idiom does not compose with a diffusion), two further
DOC-OR-FIXTURE-TRUTH items (F-L7-5 shipped-comment claim + zero `ShareCondFlag` fixture
coverage; F-L7-6 inherited latent unconditional free), and the lens's own headline
hazard CLEAR (F-L7-3: no register carrying a kickback phase is ever Ry-adjointed and
freed — one mechanism structural, one incidental and false exactly where F-L7-1 lives)
plus a clean derived-condition chain (F-L7-4).**
