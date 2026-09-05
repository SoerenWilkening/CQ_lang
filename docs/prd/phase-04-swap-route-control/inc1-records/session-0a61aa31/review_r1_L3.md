# review_r1_L3 — Rule-13 ROUND 1, lens L3: P7's boundary / Rule 1 "no third path"

SUBJECT `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`),
binaries `build/ir-pass/cq-opt` + `build/ir-pass/libCQPass.so`, archives `build/runtime/*.a`.
ORACLE `$SP/wt/pre-3qlq` (52d7764). READ-ONLY: I wrote nothing into the checkout.
All reproducers, logs and lowered IR live under `$SP/progress/review_r1_L3/`
(`p/` sources, `out/{subject,oracle}/` artifacts, `repro/` the two standalone `.ll`
reproducers, `run.sh` / `batch.sh` / `multi.sh` the harnesses, `litprobe/` the lit
pipeline-semantics probe). 295 artifacts; every number below is MEASURED with the
command shown.

---

## F-L3-1 — CONFIRMED SILENT MISCOMPILE (round-1 headline)

**Claim (one line):** `deleteGlobalPhases` (P7) runs at `CQLoweringPass.cpp:342`, which is
BEFORE `repropagateControlMerges` at `:375` — and that stage's `detectAndLowerOnwardControl`
(`TaintPropagation.cpp:1325`) is a **SECOND, FULL round of `detectControlRegions` +
`lowerControlRegions`**. A `cq_phi` sitting in an **ONWARD** tainted-control arm (a region
whose condition reads a control-merge out-rail and is therefore *classical at round 1*) is
therefore **deleted as a "global phase" before its region has ever been looked at**, and the
program then compiles at exit 0 with the branch phase silently gone.

Rule 1's premise — "by the time this runs, `detectControlRegions` has claimed or declined
every tainted `br`; there is no third path" (`TaintPropagation.h`, `CQLoweringPass.cpp:330-341`)
— is **false at that program point**: the round-2 taint does not exist yet. The Rule-1 assert
that was written to catch exactly this (`reachedThroughTaintedBranch`) cannot see it either,
for two independent reasons: (i) the onward branch's condition is not in `taint.Tainted` at
line 342, and (ii) the round-1 tainted branch that *would* have been found on the predecessor
walk has already been **erased by its own flatten** at `:326`. Both are structural, not
accidental.

### Reproducer A — the onward P2 ANGLE SELECT (the worst of the two)

`$SP/progress/review_r1_L3/p/t1_onward_angle_select.c` + `tests/e2e/classical_call_under_control_lib.c`
(the *same two-TU harness* the shipped `e2e-slice-control-cond-onward-ctl-phase` uses):

```c
int ext_f(int a);                       /* body arrives by llvm-link, as in the shipped slice */
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int y = 5;
    if (q > 5) y = ext_f(7);                        /* R1: 6.5 classical-call arm -> %out */
    if (y > 50) cq_phi(0.9); else cq_phi(0.3);      /* P2 angle select on the onward rail */
    return cq_measure(y);
}
```
`clang -O1` gives (measured, `out/subject/t1_onward_angle_select.cq.ll`):
`%8 = select i1 %7, double 9.0e-01, double 3.0e-01` + `tail call void @cq_phi(double %8)`,
with `%7 = icmp sgt i32 %6, 50` over the R1 merge phi `%6`.

Standalone module (post-`llvm-link`, fixture-ready):
`$SP/progress/review_r1_L3/repro/repro_t1_onward_angle_select.ll`

```
$ build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering \
      -S repro/repro_t1_onward_angle_select.ll -o t1.out.ll
exit=0     grep -c 'call void @cqrt_rz' t1.out.ll  -> 0
           grep -c 'call void @cq_phi'  t1.out.ll  -> 0
$ python3 tools/free_pairing_check.py <lowered>   -> PASS (STRICT)
$ <link + run>                                    -> 23 trace lines
```

**SUBJECT trace (excerpt — the whole R2 region):**
```
cq_template_icmp_sgt_i32_hl(h2, 50) -> h5
cqrt_alloc_f64(0x0p+0) -> h6
cqrt_alloc_f64(0x1.ccccccccccccdp-1) -> h7     <-- 0.9, the ANGLE, as quantum f64 DATA
cqrt_copy_f64_controlled(h5, h7, h6)
cqrt_x(h5)
cqrt_alloc_f64(0x1.3333333333333p-2) -> h8     <-- 0.3, ditto
cqrt_copy_f64_controlled(h5, h8, h6)
cqrt_x(h5)
cq_template_icmp_sgt_i32_hl_unc(h5, h2, 50)
cqrt_free(h5)
cqrt_measure_i32(h2) -> 0
```
`h6` — the muxed **angle**, materialised on an f64 rail — is an operand of **nothing** and is
never freed. **Zero `cqrt_rz` of any width is emitted.**

**Two defects in one trace.** (1) The branch phase `P(0.9)`/`P(0.3)` is silently dropped:
the `cq_phi` consumer was deleted at `:342`. (2) With its only consumer gone, the *angle*
`select` is re-classified at round 2 as a plain fp-DATA select and lowered through the 4.4/kjd1
`cqrt_copy_f64_controlled` merge — i.e. **an ANGLE lowered as quantum DATA**, the exact
Rule-3 wire-crossing `CLAUDE.md` names ("A floating-point merge φ is an angle, not data — do
not cross these wires").

**Correct circuit** (PRD §6.2 P2, and exactly what the subject emits when the same select sits
under a *round-1* condition — control `p/t2_roundone_angle_select.c`, subject exit 0,
`cqrt_rz_i1` × 2 per inlined copy):
```
h5 = icmp_sgt(out, 50);  cqrt_x(h5); cqrt_rz_i1(h5, 0.3); cqrt_x(h5); cqrt_rz_i1(h5, 0.9);
icmp_sgt_unc(h5, out, 50); cqrt_free(h5)
```

**ORACLE, closest old-surface spelling** (`p/t1_old.c`, `if (y>50) y=cq_phi(y,0.9); else y=cq_phi(y,0.3);`):
exit 0, and it DOES emit a phase on that branch —
`cqrt_rz_i32(h2, 0x1.3333333333333p-2)` + `cqrt_rz_i32_controlled(h5, h2, 0x1.3333333333334p-1)`
(the 2b by-difference form). The old gate was the TENSORED one this epic exists to replace, but
the **region was recognized and a gate was emitted**; at HEAD nothing is.

### Reproducer B — an onward arm carrying a phase BESIDE a value op (the oracle DECLINED this)

`p/n1_phase_valuearm_w.c` (+ the same lib); standalone module
`repro/repro_n1_onward_phase_valuearm.ll`:

```c
int slice(void) {
    int q = 3; q = cq_theta(q, 0.5);
    int w = cq_theta(9, 0.2);
    int y = 5;
    if (q > 5) y = ext_f(7);                     /* R1 -> %out */
    if (y > 50) { cq_phi(0.25); w = w + 1; }     /* onward: BRANCH PHASE + value arm on w */
    return cq_measure(w) + cq_measure(y);
}
```
SUBJECT: **exit 0**, stage-2b STRICT PASS, 29 trace lines, `grep -c 'cqrt_rz' -> 0`.
The trace routes `w` under the very same flag —
`cq_template_icmp_sgt_i32_hl(h3, 50) -> h6` … `cqrt_cswap(h6, h1, h7)` …
`cq_template_add_i32_hl(h7, 1)` … — so **the compiler itself treats that branch as
quantum-conditional while dropping the phase on it**. That is unambiguously a different
unitary: the relative phase `e^{i·0.25}` between the `(q>5)` and `(q≤5)` components is absent.

ORACLE, old-surface twin `p/n1_old.c` (`w = cq_phi(w, 0.25); w = w + 1;`):
**exit=1, `cq controlled lowering: mixed phase/value arm under quantum control`.**
So this is an **over-accept of a shape the oracle declined for a real reason** — the brief's
own CONFIRMED-MISCOMPILE criterion.

Control `p/n1b_valuearm_w.c` (same program, `cq_phi` deleted from the source): exit 0, 23
lines — proving the residual is what round 2 accepted.
Control `p/o2_roundone_control.c` (the SAME arm content `{cq_phi(0.25); w=w+1;}` under a
**round-1** tainted condition): **exit=1, `cq controlled lowering: impure value arm under
quantum control`.** The acceptance in B is therefore caused by the deletion, not by any
deliberate widening.

### Why neither gate can see it
The golden byte-diff cannot see a *missing* gate stream it has never had a golden for, and
`free_pairing_check.py` **PASSES STRICT on both reproducers** — a dropped phase mints and frees
nothing, so rail pairing stays perfect. Verify-clean, stage-2b-clean, links, runs.

### Proposed fix
`ir-pass/src/CQLoweringPass.cpp:342` (and its twin `:713`): move `deleteGlobalPhases(M, wd,
taint)` to **after** `repropagateControlMerges(M, wd, taint, plan6)` (`:375` / `:718`), i.e.
after the yn71 onward-control fixpoint has run to a fixpoint. The soundness argument the
current comment gives ("position is the whole soundness argument … every tainted `br` has been
claimed or declined") then becomes true rather than false: `detectAndLowerOnwardControl`'s
`while (true)` loop runs the full `detectControlRegions` — including the new
`classifyPhaseKickback` pre-peel — so an onward P1/P2 phase region is claimed there (ANALYTIC:
I cannot rebuild to measure it; the emitters are the same ones, reached through the same
`handleBranchRegion`). Interactions to re-check when moving it: `declineTaintEscapes` is re-run
*inside* `repropagateControlMerges` and already carves `taint.PhaseCalls`
(`TaintPropagation.cpp:593`), so no new escape decline appears; and see F-L3-3 for the
`detectSpecializations` round-2 re-run, which does NOT know about `PhaseCalls`.
`reachedThroughTaintedBranch` should then be asked with round-2 taint on the round-2-flattened
CFG, which is its correct position.

### Pinning fixtures
* `ir-pass/test/control_phase_kickback_onward_merge.ll` — verbatim
  `repro/repro_t1_onward_angle_select.ll` (self-contained: `ext_f`'s body is linked in). Today
  it must be an ACCEPT fixture asserting `cqrt_rz_i1` × 2 on the R2 flag and a whole-file
  `CHECK-NOT: cqrt_alloc_f64` / `CHECK-NOT: cqrt_copy_f64_controlled`. It currently FAILS that.
* `ir-pass/test/control_phase_kickback_reject_onward_mixed_arm.ll` — verbatim
  `repro/repro_n1_onward_phase_valuearm.ll`; must **decline** (`mixed phase/value arm` or
  `impure value arm`, matching the round-1 spelling `p/o2_roundone_control.c` produces), never
  accept.
* e2e: the new-surface rewrite of `tests/e2e/onward_ctl_phase_caller.c` — see F-L3-2. This is
  one of prep-b's 66 slices, so the rewrite lands directly on this hole.

---

## F-L3-2 — OVER-DECLINE (same root cause): a SHIPPED e2e capability is lost

**Claim:** the new-surface twin of the shipped slice `tests/e2e/onward_ctl_phase_caller.c`
(ctest `e2e-slice-control-cond-onward-ctl-phase`) no longer compiles.

`p/j1_onward_ctl_phase.c` — the same program with `if (y > 50) cq_phi(0.25);` (void call, no
reassignment; the exact PRD §6.2 P1 flat kickback diamond, just on an onward rail):

```
SUBJECT: exit=1  cq controlled lowering: control flow under quantum control
ORACLE  (tests/e2e/onward_ctl_phase_caller.c, old spelling, same two-TU harness):
         exit=0, 2b STRICT PASS, 18 trace lines — BYTE-IDENTICAL to the committed golden
         tests/e2e/onward_ctl_phase_caller.expected.log
```
Mechanism: the phase is deleted at `:342`; round 2 then meets an **empty** tainted diamond and
declines `control flow` through `recoverRegion`'s catch-all. Note carefully what this means for
grading — **the decline is not a protection**. It is an accident of the residual being
unlowerable; when the residual *is* lowerable you get F-L3-1 instead. Same fix.

---

## F-L3-3 — DOC-OR-FIXTURE-TRUTH (latent, one fallback away from a hole)

**Claim:** two Phase-6 recognizers were left reading the now-permanently-empty
`taint.PhiCalls` and were **not** given `taint.PhaseCalls`, so the register-free branch phase
is no longer recognized as a quantum primitive inside a specialization candidate:

* `ir-pass/src/SpecializeReject.cpp:54` — `buildIntrinsicSets`: `S.Rotations.insert(taint.PhiCalls…)`
* `ir-pass/src/SpecializeDetect.cpp:34` — `intrinsicSites`: same union

MEASURED (`p/d1_clone_branchphase.c`, `p/d2_clone_globalphase.c`, `p/q3_spec_classical_phase.c`,
all `clang -O1` plain C, subject):
```
cq specialization: callee contains a non-reversibilizable construct under quantum lift (nested call)
```
ORACLE, old-surface twin `p/d2_old.c`:
```
cq specialization: callee contains a quantum primitive (cq_*); only classical functions are lifted
```
Both LOUD, so this is **not** a miscompile today: safety has silently moved from the
quantum-primitive recognizer onto the unrelated *declaration-only callee* fallback ("nested
call"). Two consequences: (a) the diagnostic now names the wrong reason, and (b) the fallback
is the only thing left — if `@cq_phi` ever acquires a body in the module the scan would recurse
into it, find nothing, and clone a Bennett-wrapped body containing an unlowered branch phase.
It also matters for F-L3-1's fix: after `deleteGlobalPhases` moves later, the round-2
`detectSpecializations` (`TaintPropagation.cpp:1535`) will see surviving `cq_phi` calls, and a
TAINTED-ANGLE one satisfies `readsTainted`.
**Fix:** add `taint.PhaseCalls` to both sets (`SpecializeReject.cpp:54`,
`SpecializeDetect.cpp:34`) and restore the `QuantumPrimitive` reject kind for it.
**Fixture:** a decline fixture mirroring the `quantum primitive (cq_*)` string on
`p/d1_clone_branchphase.c`'s `-O1` IR.

*(Systematic sweep done for this lens: I audited every `taint.PhiCalls` reader
(`grep -rn PhiCalls ir-pass/src ir-pass/include`, 50 sites). The `GateCalls` in-place-gate
vocabularies — `LoopLowering.cpp:2909,2944`, `LoopUnrollPrepass.cpp:225`,
`TaintPropagation.cpp:1209`, `ArmClassify.cpp:2883` — are CORRECTLY left vacuous: a kickback
puts no gate on any register, so a `cq_phi` is not a rail gate. The per-emitter `PC.erase`
scrubs are correct for the same reason. The two above are the only readers whose vacuity
removes a real recognizer.)*

---

## F-L3-4 — OVER-ACCEPT of an unlowerable program (loud at LINK, not at `opt`)

**Claim:** `deleteGlobalPhases` derives its survivors as
`for (User *U : PhaseFn->users()) if (auto *CI = dyn_cast<CallInst>(U))` — so a **non-call
user** of `@cq_phi` (an address-take) is neither deleted nor declined, and the extern survives
to stage 3.

`p/s1_fnptr.c`, plain `clang -O1` C:
```c
void (*volatile pf)(double) = cq_phi;
int slice(void){ int q=cq_theta_si32(0,0.3); pf(0.5); return cq_measure_si32(q); }
```
```
SUBJECT stage2 exit=0 ; stage2b exit=0 ; stage3 exit=1
  Undefined symbols for architecture x86_64:  "_cq_phi", referenced from: _pf in s1_fnptr…o
```
Not silent (the linker catches it) and the pre-3qlq oracle had the same *class* for a direct
call (impl step-0 record: "the 2 `call void @cq_phi(double)` SURVIVE verbatim"), which Inc 1
fixed for direct calls only. But Rule 1 says there is no third path, and this is one: `opt`
exits 0 on a module it did not lower. The `if (q==5) pf(0.5);` variant (`p/s2_fnptr_arm.c`)
declines correctly (`control flow`). The `invoke` spelling declines correctly
(`p/u1_invoke_phase.ll` → `cq taint propagation: front-end intrinsic cq_phi reached via
invoke; only a direct call is supported`).
**Fix:** `ir-pass/src/TaintPropagation.cpp`, in `deleteGlobalPhases`' survivor walk — any user
of `PhaseFn` that is not a direct `CallInst` to it is a loud decline, not a skip.
**Fixture:** `lowering_reject_phi_address_taken.ll`.

---

## F-L3-5 — DOC-OR-FIXTURE-TRUTH: the "`opt` exit 0 on a verifier failure" claim is FALSE

This is the brief's round-1 special item. The claim appears **twice in shipped source**:
* `ir-pass/include/ArmAnalysis.h:250-251` — "MEASURED as `PHI nodes not grouped at top of basic
  block!`, a BROKEN MODULE at `opt` exit 0, on exactly the customer above"
* `ir-pass/src/SwapRouteEmit.cpp:1364-1366` — the same sentence
and in `$SP/progress/impl_inc1a.md` ("`PHI nodes not grouped at top of basic block!` at **`opt`
exit 0** — a broken module, not a decline").

**MEASURED, and it says the opposite.**
1. `cq-opt` builds the pipeline `CQLoweringPass → VerifierPass() → print`
   (`ir-pass/tools/cq_opt_main.cpp:111-112`). `VerifierPass`'s default `FatalErrors=true` makes
   a failure `report_fatal_error`. Exercised through the identical pass on a deliberately broken
   module (`p/broken_dom.ll`, a dominance violation the LL parser accepts):
   ```
   $ /usr/local/opt/llvm@19/bin/opt -disable-verify -passes='verify' -S p/broken_dom.ll -o /dev/null
   Instruction does not dominate all uses! …
   LLVM ERROR: Broken module found, compilation aborted!   (+ stack dump, frame #8 = VerifierPass::run)
   exit=134
   ```
   So a post-`cq-lowering` verifier failure exits **134 (SIGABRT)**, loudly, with no module
   printed — never 0.
2. `cq-opt` also verifies the INPUT (`cq_opt_main.cpp:94`); a broken input is exit 1
   (`cq-opt: input module is broken`, measured on the same file).
3. Separately measured and worth recording: **`cq-opt` exits at the FIRST `DS_Error`**
   (`LLVMContext::diagnose`'s default handler `exit(1)`) and never writes `-o`. Two independent
   declines in one module print ONE line (`p/e1_two_declines.c`: only `f1`'s message appears; no
   `.s2.ll` is produced). Every "decline then P7 assert" ordering question is therefore moot
   under `cq-opt`.
4. lit's internal shell (`execute_external=False`, which `ir-pass/test/lit.cfg.py` uses) DOES
   catch a mid-pipeline abort. Measured with a 3-test standalone suite
   (`$SP/progress/review_r1_L3/litprobe/`, a stub that prints then `kill -ABRT`s):
   * `%prog | %filecheck %s` → **FAIL** ("error: command failed with exit status: -6") even
     though FileCheck matched. Positive fixtures are safe.
   * `not %prog 2>&1 | %filecheck %s` → **PASS**. A *decline* fixture would swallow an abort if
     the expected text were printed first — structurally impossible here, because a CQ decline
     `exit(1)`s before any later stage can abort, but worth knowing.

**Grade / action:** the alarming half of the implementer's note ("every fixture that relies on
verify-clean ⇒ exit 0 is weaker than documented") is **NOT reproduced and is contradicted by
measurement**. The observation was most likely the exit status of a *pipeline* rather than of
`cq-opt`. The two shipped comments should be corrected to "a BROKEN MODULE — `cq-opt`/`opt`
abort with `LLVM ERROR: Broken module found, compilation aborted!`, exit 134" or backed by a
committed reproducer; leaving a false "exit 0" claim in the Rule-13 core is exactly the
hardened-by-repetition failure mode `CLAUDE.md` records for the `fenv` prose. I could not
construct a broken module from the subject at `fa96336` — the `phaseAngleTail` fence holds on
every probe I threw at it (`p/v1_tailphi_late.ll` phi consumed in a later block,
`p/v2_tailphi_twouse.ll` phi consumed through an `fadd`, plus the C-level empty-arm variants):
all decline loudly with `control flow under quantum control`. So the fence is doing its job;
only the justification's exit code is wrong.

---

## F-L3-6 — DOC/latent: the second entry point's `deleteGlobalPhases` is MODULE-wide

`CQLoweringPass.cpp:570` adds `onlyInF(taint.PhaseCalls)` so the work list is restricted to
`F`, but `deleteGlobalPhases` at `:713` derives its survivors from `PhaseFn->users()`, which is
module-wide — so the shim would delete `cq_phi` calls in functions **other than `F`**. This is
consistent with, but not covered by, the pre-existing AXIS-F hazard note at `:553-561`, which
enumerates the module-wide stages and says the restriction "scopes ONLY the rotation/measure
work lists to F". Harmless today (`runOnFunction` is a DEAD SHIM — `Plugin.cpp` registers only
`run()`; zero callers). **Fix:** extend the AXIS-F comment at `CQLoweringPass.cpp:553` to name
`deleteGlobalPhases` as a third module-wide stage, or scope it to `F`.

---

## F-L3-7 — DOC (minor): a COMPOUND condition is reported as "a bare i1 condition"

`p/h4_nest_true.c`, plain C: `if (q==5) { if (p==7) cq_phi(0.4); }` — `clang -O1` folds the
nest to `select i1 %a, i1 %b, false`, so `classifyPhaseKickback`'s `dyn_cast<CmpInst>` fails and
the program declines
`cq controlled lowering: branch phase on a bare i1 condition under quantum control`.
The program has no bare `i1` condition; it has a compound one (P3/P4, part B). The classifier's
own header says this is deliberate ("it is not a `CmpInst` either, so it takes the same
partitioned message"), and the ORACLE said `control flow under quantum control` for the same
source. Loud either way; but the string now asserts something false about the program, and Inc
1b will want the bare-`i1` string to mean the bare-`i1` shape. **Fix:** split the two — keep
`branch phase on a bare i1 condition` for a tainted `i1` that is not a `SelectInst`, and give a
compound tree its own (or the pre-existing `control flow`) string.

---

## CLEAR — everything else this lens probed

All measured on the subject with the full pipeline (stage 1 → 2 → 2b STRICT → 3 → 4) unless the
program declines at stage 2. Sources under `p/`, artifacts under `out/subject/`.

**P7 accept side (classical control ⇒ delete, D2) — all correct, all exit 0, 2b PASS:**
`a1_straightline` (uncontrolled), `a2_classical_cond` (`if (volatile c)`), `a3_classical_loop`
(a classical `for`), `a4_only_phi` (a module whose ONLY quantum surface is `cq_phi` — the
passthrough predicate; 1 trace line, no leaked decls), `q1_callee_global` (`cq_phi` in a
non-specialized `noinline` callee called unconditionally), `r3_dead_fn_phase` (`cq_phi` in a
never-called external function), `g5_kick_then_phase` (a global phase AFTER a claimed kickback
region: the region's gates are emitted and the trailing phase is deleted),
`i1_break_then_phase` (a global phase after a 7.4 value-arm `break` loop — the break branch has
been stripped to the classical bound by `lowerLoops` before `:342`, so the deletion is correct
and the assert is not needed), `g1_abort_then_phase` (a phase after a 7.2 abort park: the park
flattens the tainted `br` to `br label`, the parked component is entangled with a `grave` rail
that is never touched again, so the relative phase is unobservable and the deletion is sound).

**"No third path" — every way I could put a `cq_phi` under a tainted `br` that another owner
might claim and flatten. ALL decline loudly (`opt` exit 1), and the deletion never precedes the
decline because `cq-opt` exits at the first `DS_Error`:**

| probe | shape | subject |
|---|---|---|
| `b1_qq` | Q+Q compare | `no template for opcode 'icmp i1' in tainted context` |
| `b3_mixed` | phase + value op in one arm | `control flow` |
| `b4_switch` / `h1..h3` | tainted `switch` (folded selects; 4-case; mixed case) | `rotation angle` / `control flow` |
| `c1_abort` | `{cq_phi; abort();}` (7.2 abort park) | `control flow` |
| `c2_return` | `{cq_phi; return 3;}` (7.2 controlled return) | `control flow` |
| `c3_iosink` | `{cq_phi; putchar('x');}` (7.6 I/O) | `cq I/O output sink: conditional output is not a lowerable single-sink if(q) diamond` |
| `c4/f4_store` | `{cq_phi; g[0]=1;}` (iw81.7 guarded store) | `control flow` |
| `c5/f3_callarm` | `{cq_phi; r=pure(s);}` (6.5 classical-call arm) | `control flow` |
| `c6_nested`,`h4` | depth-2 nest | `control flow` / `bare i1 condition` (F-L3-7) |
| `c7_seq_qq` | sequential, second region Q+Q | `no template for opcode 'icmp i1'` |
| `c8_qloop` | quantum-bounded loop | `loop under quantum control` |
| `c9_callee`,`q2` | `{ h(); }` with `cq_phi` inside `h` | `control flow` |
| `f1/f2_rotarm` | `cq_phi` beside an in-place `cq_theta` arm (either order) | `control flow` |
| `f5_datamux` | phase + data mux | `value-arm swap-route` |
| `i2` | `cq_phi` in a 7.4 `break` arm | `cq loop lowering: early break does not reconverge` |
| `g3/g4` | controlled `return` / I/O then a phase | `value-arm swap-route` / `cq I/O output sink: …` |
| `r1_tainted_angle` | uncontrolled tainted angle | `cq rotation lowering: unsupported quantum-derived rotation angle` |
| `u1_invoke_phase.ll` | `invoke void @cq_phi` | `…reached via invoke; only a direct call is supported` |

I read the arm-content gate of each competing owner to confirm the decline is structural and
not luck: `IOSinkLowering.cpp:586` (`A.Arm->size() != 2` ⇒ `kMsgIOControl`),
`PredMuxFlatten.cpp:2818-2872` (a `CallInst` that is neither a curated `memory(none)` intrinsic
nor a pending-spec pure callee ⇒ `leave("E4-dataflow")`, so PredMux can never hoist a `cq_phi`
out of an arm), `ArmClassify.cpp:1465-1485` (`valueArmIsPureChain` rejects any off-chain
instruction). Every *claimed* region kind I could reach also removes its tainted terminator
(measured on `g1`: the abort park leaves `br label %2`), which is why
`reachedThroughTaintedBranch` never fires in any of my 90+ probes — the assert is, as far as I
can measure, **unreachable under `cq-opt`**, while the hazard it was written for is real and
lives one stage later (F-L3-1).

**Phase-6 clones / Bennett wrap:** a `cq_phi` inside any specialization candidate declines at
`detectSpecializations` (`CQLoweringPass.cpp:269`, i.e. *before* `:342`), whether the phase is
under a tainted branch in the clone (`d1`), unconditional (`d2`), or under a classical
condition (`q3`). A callee with tainted control flow and no phase declines too (`d3`:
`callee contains tainted control flow under quantum lift`). So the "a branch phase in a clone
must not be deleted as global" hazard is not reachable — but the *reason* is the wrong one, see
F-L3-3.

**Tainted angle inside a kickback arm:** `r2_tainted_angle_arm`
(`if (q==5) cq_phi((double)q * 0.1);`) accepts at exit 0 — and is **CORRECT**: `-O1` pins `q=5`
on the arm edge (the drbq Inc-4 F2 fold class) so the angle arrives as the constant `5.0e-01`,
which is exactly the angle the source demands on the branch that fires. Verified in both the
stage-1 IR (`tail call void @cq_phi(double 5.000000e-01)`) and the emitted gate
(`call void @cqrt_rz_i1(i32 %h_cmp, double 5.000000e-01)`).

**Both pipeline entry points** run `deleteGlobalPhases` (`:342` and `:713`) — confirmed by
`git diff dfb8e83..HEAD -- ir-pass/src/CQLoweringPass.cpp`. See F-L3-6 for the one caveat.

---

## VERDICT

**L3: NOT CLEAR — 1 CONFIRMED SILENT MISCOMPILE (F-L3-1, two plain-C reproducers through the
shipped two-TU e2e harness, both exit 0 / stage-2b STRICT PASS / linked / run, one of them an
over-accept of a shape the pre-3qlq oracle declines loudly and one of them lowering a rotation
ANGLE as quantum f64 DATA), 1 OVER-DECLINE of a shipped e2e capability from the same root
(F-L3-2), 1 latent recognizer gap (F-L3-3), 1 loud-at-link over-accept (F-L3-4), and 3
doc/message truth items (F-L3-5 — the "`opt` exit 0 on a verifier failure" claim is measured
FALSE, `cq-opt` exits 134; F-L3-6; F-L3-7).** The single root cause of the first two is one
line's POSITION: `deleteGlobalPhases` at `CQLoweringPass.cpp:342`/`:713` runs before the
round-2 (dugh/yn71) control detection at `:375`/`:718`, so P7's Rule-1 premise is false exactly
where the second round of tainted control lives.
