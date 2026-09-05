# review_r1_L6 — Rule-13 ROUND 1, lens L6: MIGRATION + SURFACE TRUTH
bd `test_C_libtooling-3qlq.2`, Inc 1 part A (register-free `cq_phi` by kickback).
**READ-ONLY — nothing in the checkout, in `ir-pass/test`, `tests/`, `include/` or
`ir-pass/src` was edited.**

SUBJECT `/Users/sorenwilkening/Desktop/CQ_lang` @ `fa96336` (branch `3qlq-inc1`),
        `build/ir-pass/{cq-opt,libCQPass.so}`, `build/runtime/*.a`, `include/CQ.h`.
ORACLE  `$SP/wt/pre-3qlq` @ `52d7764`, its own `cq-opt` / `libCQPass.so` / archives
        and — load-bearing for this lens — its own **pre-3qlq `include/CQ.h`**, which
        is what a STALE-HEADER build looks like.
ARTIFACTS all under `$SP/progress/review_r1_L6/`: `run.sh` (stage 1→4 harness),
        `p/` (7 C probes on the NEW header), `stale/` (5 C probes on the OLD header),
        `ll/` (12 hand modules), `inj/` (14 injection modules), `mut/` (31 mutated
        fixtures), `fx/`, `out/`, `cmp/`, `survivors.tsv`, `lit_q.log`,
        `handlecheck.py`, `prefixcheck.py`, `sweep_survivors.sh`, `mutate.sh`.
NOT RE-REPORTED: F-L7-1 (spine cancels the kickback on `ShareCondFlag`),
        F-L3-1 (P7 deletes an ONWARD branch phase), F-L3-5 (the verifier-exit claim).

---

## F-L6-1 — CONFIRMED. A THIRD PATH FOR THE RETIRED FAMILY: the Grover oracle on a
## stale header is neither lowered nor declined — `opt` exit 0, gate gone, link error.

**One line.** `ArmClassify`/`SwapRouteEmit` still CLAIM a `@cq_phi_<sfx>` arm gate by
string prefix, but nothing lowers it any more, so for every spelling whose arg-0
`clang -O1` CONST-FOLDS — which is the equality edge, i.e. `if (q == k) q = cq_phi(q, θ)`,
the flagship customer — the region is claimed, the flag is minted / stripped / freed,
**the phase gate is dropped from the circuit**, and the unlowered `@cq_phi_si32` call is
left in the emitted module. Verify-clean, STRICT stage 2b clean, caught only by `ld`.

### Reproducer A — plain C, the pre-3qlq header, `clang -O1`
`$SP/progress/review_r1_L6/stale/g1_eq.c`
```c
int slice(int u) {
    int q = cq_theta(u, 0.5);
    if (q == 5) { q = cq_phi(q, 3.141592653589793); }   /* the Grover oracle */
    return cq_measure(q);
}
```
`clang -I$SP/wt/pre-3qlq/include -include CQ.h -O1` gives (MEASURED,
`stale/g1_eq.s1.ll:16`) `%6 = tail call i32 @cq_phi_si32(i32 noundef 5, double …)`
— **arg-0 const-folded to `i32 5` on the `q == 5` edge**, so the operand is CLASSICAL
and `declineTaintEscapes` structurally cannot fire.

SUBJECT (`build/ir-pass/cq-opt`, exit **0**, no diagnostic):
```
%h     = call i32 @cqrt_alloc_i32(i32 %0)
         call void @cqrt_ry_i32(i32 %h, double 5.000000e-01)
%h_cmp = call i32 @cq_template_icmp_eq_i32_hl(i32 %h, i32 5)
%2     = tail call i32 @cq_phi_si32(i32 noundef %h, double 0x400921FB54442D18)   <-- UNLOWERED
         call void @cq_template_icmp_eq_i32_hl_unc(i32 %h_cmp, i32 %h, i32 5)
         call void @cqrt_free(i32 %h_cmp)
%m     = call i32 @cqrt_measure_i32(i32 %h)
```
`python3 tools/free_pairing_check.py` → `2 verified, 0 violation(s), 0 unproven` (**STRICT PASS**).
Stage 3: `Undefined symbols for architecture x86_64: "_cq_phi_si32", referenced from: _slice, _main`.

ORACLE, same `.s1.ll`, exit 0: `call void @cqrt_rz_i32_controlled(i32 %h_cmp, i32 %h, double PI)`
— the tensored gate the epic exists to remove, but **a gate**.

**What the correct unitary is vs what is emitted.** Under the kickback design the
program must apply `e^{iπ}` to the `q==5` branch. The subject applies the flag mint and
its exact inverse and NOTHING else: the emitted circuit is the **identity on `q`** — the
very defect PRD §1 records for the old lowering, now reached by a different route.

### Reproducer B — the same class from a fixture in the tree, and it is GREEN
`ir-pass/test/lowering_reject_live_record_routed_base_anc.ll` (its header states its own
C source; `$SP/progress/review_r1_L6/p/m1_stale_header.c` is that source, and on the old
header it reproduces the module byte-for-byte). SUBJECT exit 0, output carries
`%rz = call i32 @cq_phi_si32(i32 %h_op, double PI)`; ORACLE emits
`cqrt_rz_i32_controlled(%h_cmp, %h_op, PI)`.
**The fixture PASSES on the subject** (`lit -q ir-pass/test`, it is not in the 362 reds):
its `WARN`/`LOWER`/`NOFREEREC` prefixes are all about the *chained Ry*, so none of them
can see that the phase gate vanished.

### Reproducer C — the reserved-name PROTOTYPE guard for the family is gone as well
`$SP/progress/review_r1_L6/ll/wrongproto_phi_si32_{unused,called_const}.ll`
```
wrongproto_phi_si32_unused        SUBJECT exit=0 (silent)   ORACLE exit=1 "cq rotation lowering: unsupported declared prototype for cq_phi_si32"
wrongproto_phi_si32_called_const  SUBJECT exit=0 (silent)   ORACLE exit=1 (same string)
```
The subject leaves 2 `cq_phi_si32` references in the second module.

### Scope, measured — the boundary is ONE CHARACTER wide
| spelling (old header, `clang -O1`) | SUBJECT | ORACLE |
|---|---|---|
| `if (q == 5) q = cq_phi(q, π)` | **exit 0, 2 surviving calls, gate dropped** | exit 0, gate lowered |
| `if (q >  5) q = cq_phi(q, π)` | exit 1 `cq taint escape: tainted value consumed by an unknown callee` | exit 0, lowered |
| `if (q != 5) q = cq_phi(q, π)` | exit 1, same string | exit 0, lowered |
| `q = cq_phi(q, .25)` uncontrolled | exit 1, same string | exit 0, deleted |
| `switch (q) { case k: q = cq_phi(q,θ); }` | exit 0, **`cqrt_cswap` + tensored `cqrt_rz_i32` ×3, BYTE-IDENTICAL to the oracle** | same |

Module-wide sweep of all 1602 fixtures through the subject
(`sweep_survivors.sh` → `survivors.tsv`): **12 fixtures exit 0 with a surviving
`@cq_phi_<sfx>` CALL** (`control_swap_accept_post_region_theta`,
`control_swap_accept_two_iterations`, `control_swap_eqfold_classical_between`,
`control_swap_eqfold_diamond`, `control_swap_eqfold_polarity`,
`control_swap_inloop_gatefree_body`, `control_swap_inloop_postloop_railop_mc`,
`control_swap_inloop_railop_inplace`, `control_swap_inloop_two_registers`,
`lowering_mc_seq_region_customer`, `lowering_phi_classical`,
`lowering_reject_live_record_routed_base_anc`) — 11 are already red pending migration,
**1 is green**, and **0 fixtures leave a surviving void `@cq_phi`, `@cq_theta_*` or
`@cq_measure_*`**, so the class is specific to the retired family.

### Mechanism, located
* `ir-pass/src/ArmClassify.cpp:99` — `isPhiCall` is still `isCallToPrefix(V, "cq_phi_")`,
  so the retired call still classifies as a phase / in-place-rotation arm gate.
* `ir-pass/src/SwapRouteEmit.cpp:551` `emitInPlaceRotationRegion` — hoists it
  (`G.first->moveBefore(BI)`) and records `taint.ControlledRotations[G.first] = Flag`.
* `ir-pass/src/RotationLowering.cpp:429-441` — the `PhiCalls` loop that used to lower it
  is DELETED, and `emitRz` (`:172`) is dead. Its in-source justification is *"`taint.PhiCalls`
  is now permanently empty and this loop could not fire"* — TRUE, and it is exactly why
  the claimed gate is now consumed by nobody.
* `ir-pass/src/TaintPropagation.cpp:252-290` `resolveSources` — the family is no longer
  resolved, so it is also no longer prototype-validated.

### Shipped claims this falsifies (all three written by this increment)
1. `ir-pass/src/WidthDispatch.cpp:571-575` — *"the pass no longer recognizes them (a call
   to one now declines through the ordinary taint-escape guard)"*. It recognizes them at
   **24 non-comment code sites across 15 files** (22 of them LIVE — the other two are inside
   the dead `phiFn`/`emitRz`), and the guard fires only for a tainted operand. Command:
   `grep -rn 'cq_phi_' ir-pass/src/*.cpp | grep -vE ':\s*//' | grep -E 'starts_with\("cq_phi_"\)|isCallToPrefix\([^,]*, *"cq_phi_"\)|suffixFromName\(|intrinsicSuffix\(|getFunction\(\("cq_phi_"'`.
2. `ir-pass/test/lowering_reject_legacy_phi_register_form.ll` header — *"this IR can only
   come from hand-writing or a stale header — and in either case a loud refusal is strictly
   better than a wrong unitary"*. The fixture pins only the UN-folded operand.
3. `ir-pass/test/lowering_reject_decl_prototype_phi.ll` header — *"Its disposition is pinned
   by `lowering_reject_legacy_phi_register_form.ll` instead"*. Reproducer C shows the
   decl-only and classical-operand halves have no disposition at all.

### Grade
Not a *silent* miscompile as shipped: the program does not link, so no wrong circuit runs
today. It IS a **Rule-1 "no third path" violation and a Prime-Directive violation** — an
unprovable construct that neither lowers nor declines, with `opt` at exit 0 and the pass's
documented postcondition ("all `cq_*` intrinsics gone") broken. It is one linkable
`cq_phi_si32` body away from being silent, and part B is about to rewrite the two emitters
that still consume the family.

### Proposed fix
`ir-pass/src/TaintPropagation.cpp`, inside `resolveSources`'s suffix loop (~line 285):
```cpp
if (Function *F = wd.phiFn(Sfx))        // the RETIRED register form
  diagnoseMalformedDecl(F, "cq rotation lowering");   // or its own string
```
Monotone — it can only ADD declines. Reserved-by-convention is already the shipped rule for
the other 33 names (`lowering_reject_decl_prototype_unused.ll`), so a decl-only decline is
the consistent choice; if the owner prefers, gate it on `!F->use_empty()`. Belt-and-braces:
an end-of-pass assert in `CQLoweringPass.cpp` (after the `frontEndIntrinsicNames()` sweep,
`:342` / `:713` entry points) that **no** front-end intrinsic has a surviving CALL.
⚠ Coordinate with part B: the fix turns `control_swap_switch_phase{,_passthrough}.ll` and
`control_swap_switch_scrutinee_measured.ll` from accepts into declines — those are exactly
P4/P5's rows.

### Pinning fixtures
* `lowering_reject_legacy_phi_register_form_eqfold.ll` — the const-folded arg-0 module
  (`stale/g1_eq.s1.ll`, reduced), `RUN: not`, string mirrored.
* `lowering_reject_legacy_phi_decl_prototype_family.ll` — `declare i32 @cq_phi_si32(i32, float)`,
  no call site (reproducer C, the assertion `lowering_reject_decl_prototype_phi.ll` gave up).
* a whole-file `CHECK-NOT: @cq_phi_` added to `lowering_reject_live_record_routed_base_anc.ll`
  (today the only green fixture blind to a surviving retired call).

---

## F-L6-2 — DOC-OR-FIXTURE-TRUTH. The hand-back's green-fixture census does not reproduce.

`$SP/progress/impl_inc1a.md` states *"**155 fixtures reference the retired family and are
GREEN** (104 declines, 51 accepts). Of the 51 accepts, **47 only DECLARE it** and **4 CALL
it**"*, and `BRIEF_review_r1.md` repeats "155" as this round's sampling target.

MEASURED at `fa96336` (`cd build && lit -q ir-pass/test` → `Total Discovered Tests: 1602`,
`Failed: 362`; `grep -lE '@cq_phi_[a-z0-9]+' ir-pass/test/*.ll` → 491):
```
491 - 362 = 129 GREEN     103 declines / 26 accepts     with a live CALL: 35 (31 decline / 4 accept)
```
The **4 accepts that CALL it are exactly the four named** — so only the totals are wrong,
by 26 / 1 / 25 / 25. No variant of the grep produces 155 (`cq_phi_` → 169, `cq_phi` → 198,
`@cq_phi` → 149, `@cq_phi_` → 129). The implementer's own `impl_inc1a_lit3.log` reports the
same 1239 passed / 1 XFAIL / 362 failed, so this is an arithmetic slip in the write-up, not
a moved binary. Reproduce with the two commands above.
**Everything else in the hand-back's fixture arithmetic DOES reproduce**: 21 files
(11 accept / 10 decline), 0 of them red, corpus 1602, and `red \ grep -lE '@cq_phi_'` = **0**.

---

## F-L6-3 — DOC-OR-FIXTURE-TRUTH. `tests/frontend/cq_phi_smoke.c`'s whole-module claim is
## WINDOWED and cannot catch an old-family CALL — the Inc-3 F-L6-1 lesson, in the file the
## increment rewrote.

The fixture states property (2): *"NO `@cq_phi_<sfx>` symbol is minted at any type"*, and
spells it as a **trailing** `; CHECK-NOT: @cq_phi_` placed AFTER `; CHECK: declare void
@cq_phi(double`. A trailing `-NOT` windows from the last positive match to EOF, and in
every clang-emitted module the `declare` block sits AFTER the function bodies — so the
window excludes exactly the place an old-family CALL appears.

MEASURED, four injections into the fixture's own `clang -O1` output with both controls
(`inj/`; `frontend-lit` itself: **1/1 Passed, 2.24 s**):
```
clean (control, must pass)                         PASS
inject `declare i32 @cq_phi_si32(i32,double)`      CAUGHT (CHECK-NOT)
rename the whole surface to @cq_phi_si32           CAUGHT
drop one `call void @cq_phi(double …)` (control)   CAUGHT (CHECK)
inject `%zz = call i32 @cq_phi_si32(…)` IN @use()  ** NOT CAUGHT **
```
Fix: move the negative into its own whole-file pure-negative prefix
(`; RUN: … | %filecheck %s --check-prefix=NOFAM`, `; NOFAM-NOT: @cq_phi_`) — the discipline
the increment's own `.ll` accepts already apply (`NOROUTE`). Pinning: the injected module
`inj/smoke_injA.ll` is committed as the red half.

---

## F-L6-4 — DOC-OR-FIXTURE-TRUTH. All 11 new accept fixtures leave 2 of the 8 non-`i1` Rz
## widths unguarded, so their stated "no TENSORED Rz" invariant is 6/8 true.

Each accept carries a NOROUTE block whose comment says *"`cqrt_rz_<W>` for W != i1 — the
TENSORED per-register Rz is the defect this increment removes"*. The shipped ABI has
**nine** Rz widths (`runtime/cq_runtime.h:140-148`: `i1,i8,i16,i32,i64,f32,f64,f16,f80`);
every one of the 11 fixtures lists only `i8,i16,i32,i64,f32,f64` — **`f16` and `f80` are
absent from all 11** (`grep -oE 'cqrt_rz_(i[0-9]+|f[0-9]+)'` per file).

MEASURED by injection into `control_phase_kickback_diamond`'s own output, placed AFTER the
`cqrt_free` so no `CHECK-NEXT` chain is disturbed, all six prefixes run:
```
clean (control)                 NOT CAUGHT (passes, as it must)
inject cqrt_rz_i32 (control)    caught by NOROUTE
inject cqrt_rz_i1  (control)    caught by C1 (the count)
inject cqrt_rz_f80              ** NOT CAUGHT **
inject cqrt_rz_f16              ** NOT CAUGHT **
```
Fix: add `; NOROUTE-NOT: cqrt_rz_f16` and `; NOROUTE-NOT: cqrt_rz_f80` to all 11 (or, better,
one `; NOROUTE-NOT: cqrt_rz_{{[^i]}}` style width-complement). Low severity — no path mints
an f80 kickback today — but the fixture's own comment claims the whole complement.

---

## F-L6-5 — DOC-TRUTH. A NAMED PRD §4.1 DELIVERABLE OF THIS INCREMENT DID NOT SHIP: every
## user-facing doc still documents the retired two-argument surface.

PRD `retire-swap-route-PRD.md` §4.1 lists, beside `CQ.h`, *"`frontend.md` §3.3 rewritten:
branch phase; uncontrolled = global phase = deleted; the per-bit loop idiom (D4); the
Grover oracle and the `|0⟩` reflection as the two worked examples"* (restated in §14).
`BRIEF_impl_inc1a` Step 1 reduced the deliverable to `CQ.h` + the smoke test, and the docs
were not touched (`git diff --name-only dfb8e83..HEAD -- docs/` → no `frontend.md`).

At HEAD, MEASURED:
| file:line | text |
|---|---|
| `docs/frontend.md:78` | `\| cq_phi(x, angle) \| Rz(φ) \| Propagates only \| Phase rotation; no-op on classical operands \|` |
| `docs/frontend.md:152` | "cq_phi declared the same way (same 14 widths, same return-type rule)." |
| `docs/frontend.md:197-207` | §3.3 "`cq_phi(x, φ)` applies an Rz(φ)… lowers it to `cqrt_rz_<W>(handle, φ)`. The output remains tainted" |
| `docs/frontend.md:356` | "Phase rotation (Rz) \| `cq_phi(x, φ)`" |
| `docs/backend.md:141, 336-337` | "`@cq_phi_<sfx>(x, φ)` … lowering to `cqrt_rz_<W>` on tainted operand; deletion on classical" |
| `docs/quantum-classical-handling.md:242-247` | "`cq_phi` on a classical operand as a deletion candidate, and `cq_phi` on a tainted operand as taint-propagating only" |
| `docs/example.md:39` | "`cq_phi` (Rz) on a tainted operand" |
| `CLAUDE.md` Rule 3 | "`cq_phi` (Rz) propagates taint but never introduces it (deleted on classical operands)"; "The **arg-1 angle** operand of a rotation is classical" |

Every one of these is now false: `cq_phi` has no register operand, no arg-1, propagates
nothing, and never mints `cqrt_rz_<W>` for W≠i1 on the shipped paths. The `CLAUDE.md` row
matters most — it is a **non-negotiable rule agents are told overrides default behaviour**,
and it now describes an operand that does not exist. Not a correctness finding; it is the
increment's own unshipped scope, and it belongs in "what is left" rather than being
discovered by the next agent.

---

## F-L6-6 — DOC/OWNER. The new one-argument surface silently accepts any classical
## expression as an angle, and silently captures a user-defined `void cq_phi(double)`.

The brief asked me to report `cq_phi(q)` with an INT `q` as a DOC/OWNER item. The premise
is **half right, and the measured half matters**:

* **TAINTED operand — LOUD, not silent.** `int q = cq_theta(u,.5); cq_phi(q);` becomes
  `sitofp i32 → double` feeding the angle, and declines
  `cq rotation lowering: unsupported quantum-derived rotation angle` (exit 1). Under
  control (`if (a > 1.0) cq_phi(a)`) it declines
  `cq controlled lowering: rotation angle under quantum control`. `p/s2_int_arg.c`,
  `p/s5_tainted_double_angle.c`, `p/s6_tainted_double_angle_ctl.c`. So the realistic
  migration slip — "drop the angle, keep the register" — is caught.
* **CLASSICAL operand — SILENT.** `volatile int g = 7; int c = g; if (q == 5) cq_phi(c);`
  compiles with **no diagnostic at `-Wall -Wextra -Wconversion`** and emits
  `cqrt_rz_i1(h1, 0x1.cp+2)` — a 7-radian phase. `p/s3_classical_int_arg.c`, trace in
  `out/s3_classical_int_arg.subj.trace`. Nothing is wrong with the lowering; the point is
  that the type system no longer separates "register" from "angle", so a mis-ported call
  is a legal program.
* **NAME CAPTURE.** A module that DEFINES `void @cq_phi(double)` with an observable body
  has every call to it **silently deleted** by P7 (`ll/phase_defined_body.ll`: the `store
  double %a, ptr @sink` body survives, the call site does not; exit 0, no diagnostic).
  A wrong-*prototype* `@cq_phi` declines loudly, but a right-prototype *definition* is
  captured in silence. The old surface needed one of 15 suffixed names; `cq_phi` /
  `void(double)` is a plain, short, collidable C signature.
* **Not a hole:** an INDIRECT `call void %fp(double)` in a tainted arm declines
  `cq controlled lowering: control flow under quantum control` (`ll/phase_indirect.ll`).

Owner question, not mine to decide: should a *defined* `@cq_phi` in the module be a loud
decline (reserved-name rule) rather than a silent claim?

---

## F-L6-7 — (minor) DOC-TRUTH. `WidthDispatch::phiFn` is dead code with no annotation.

`grep -rn 'phiFn' ir-pass/` → the declaration (`WidthDispatch.h:64`), the definition
(`WidthDispatch.cpp:113`) and nothing else. `RotationLowering::emitRz` was given a
DO-NOT-REVIVE block for exactly this situation (`RotationLowering.cpp:151-171`); `phiFn` was
not. It is also the natural hook for F-L6-1's fix, so it should be either annotated or used.

---

## What I measured that is CLEAR (negative results, stated so they are not re-run)

1. **The old spelling is a hard compile error.** `x = cq_phi(x, 0.25)` against the new
   header: `error: too many arguments to function call, expected single argument 'angle',
   have 2 arguments` + a note at `include/CQ.h:62`. `p/s1_old_register_form.c`. At scale:
   **63 of 63** `tests/e2e/*.c` that call `cq_phi` fail stage 1 on the subject header
   (measured by compiling all 63) — prep-b's scope, and the header's "fails to COMPILE"
   claim is true.
2. **Declare-only retired family:** with no quantum in the module, the pass is
   **byte-identical passthrough** (the `declare` survives); with a `cq_theta` present the
   dead decl is **swept** (`ll/decl_only_{unused,with_theta}.ll`). Both as documented.
3. **P7 with no `cq_theta` anywhere:** `int slice(int u){ cq_phi(0.5); return u+1; }` still
   has both calls deleted at exit 0 — the passthrough early-out really does include
   `PhaseCalls` (`p/s4_phase_only_no_theta.c`).
4. **The 21 new fixtures:** 0 literal `%handle` tokens in any positive directive that is
   absent from the pass output (`handlecheck.py`); every count lives in its own `C<n>`
   prefix as `COUNT-n` + `NOT` (the correct "exactly n" idiom); `NOROUTE` is pure-negative
   and whole-file. 11 accept / 10 decline, all green, corpus 1602 — all reproduce.
5. **The 129 green retired-family fixtures:** 0 missing handle names; **126 behave
   IDENTICALLY to the oracle** (101 same-string declines + 25 byte-identical accepts), the
   3 exceptions being the two new declines and F-L6-1's fixture (`cmp/verdicts.tsv`).
6. **Discrimination test on the 31 green DECLINE fixtures that CALL the family**
   (`mutate.sh`, `mut_compare.tsv`): substituting the callee for an unrelated opaque extern
   of the same type is **caught in 12 and not caught in 19 — the SAME 12/19 split on the
   oracle and on the subject**. So no green decline fixture LOST discriminating power at
   this increment; the 19 weak ones are pre-existing and are prep-a's / L8's ground.
7. **The verifier-exit question** the brief assigned to L3 and L6 is L3's F-L3-5; I confirm
   only the wiring (`ir-pass/tools/cq_opt_main.cpp:93-96` input pre-verify → `return 1`;
   `:112` `VerifierPass()` at LLVM's default `FatalErrors=true`) and did not reproduce an
   exit-0-with-verifier-complaint.
8. **The 3 `control_swap_switch_*` fixtures** still mint the tensored `cqrt_rz_i32` on a
   `cqrt_cswap` route, byte-identical to the oracle — declared part B (P4/P5). I measured
   that this IS reachable from plain C behind the same stale-header door as F-L6-1
   (`stale/g5_switch.c`, subject output byte-identical to the oracle's), which is the
   brief's own trigger; it is **not a regression** (unchanged from the oracle), but it makes
   the surface inconsistent by SHAPE — the diamond lost its lowering while the switch kept
   it — and that inconsistency disappears the moment F-L6-1's fix lands.

---

## VERDICT

**NOT CLEAR — 1 CONFIRMED third-path finding (F-L6-1) + 5 doc/fixture-truth items +
1 owner question.** F-L6-1 is not a silent wrong unitary as shipped (the module does not
link) but it is a Prime-Directive / Rule-1 violation reachable from plain C in the exact
migration scenario the surface change was designed to make safe, it drops the gate from the
flagship program, it is invisible to `opt -verify`, to STRICT stage 2b and to all 1602
fixtures (the one fixture in the class is GREEN), and its fix is a few lines in
`resolveSources` that only ever adds declines. The rest of the surface change holds up:
the header change is a hard compile error at both the single-file and 63-slice scale, the
tainted-angle and indirect-call boundaries are loud, the new fixtures' handle names and
count-prefix hygiene are correct, and the 129 green retired-family fixtures are measurably
not false-green as a population.
