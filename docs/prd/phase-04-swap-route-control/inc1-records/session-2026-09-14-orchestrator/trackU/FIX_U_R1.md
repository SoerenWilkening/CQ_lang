# Track U — FIX record for review round 1 (bd `z9t1`)

Worktree `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero`.
Subject of the round: tip `8865f7d5`, `cq-opt` `a5773be142835fb8`. ORACLE
`f7b65d8ccd7bc472` (`/Users/sorenwilkening/Desktop/CQ_lang/build`, read-only, hash re-verified as my
first act — it matches `PROTOCOL.md`). Probes: `fix_r1_probes/`, driver `fix_r1_probes/drive.sh`
(a worktree-local rewrite of the reviewer's — the original writes its artefacts next to its input,
which for me would have been the read-only main checkout).

**Every verdict below is two runs, SUBJECT and ORACLE, on the SAME stage-1 file.** Decline rows carry
a sha256 of the FULL stderr, not a tag-regex rendering (PROTOCOL S3).

---

## 0. Disposition summary

| finding | brief's instruction | what I did |
|---|---|---|
| **F-U1-1** | fix it (arg-1 conjunct) — **SUPERSEDED mid-task by the coordinator: HOLD** | **NOT fixed. Implemented, measured, then REVERTED.** The four measurements the ruling needs are §2. Source comments corrected to state the composition as OPEN. |
| **F-U1-2** | correct the record | done, §3 — and the "ONE OBJECT, READ TWICE" scope is replaced, not softened |
| **F-U1-3** | correct the record, verify both new claims myself | done, §4 — both verified from source, with one correction to the reviewer's own wording |
| **F-U1-4** | fix three record inconsistencies | done, §5 — and **the reviewer's own counts are off; corrected with measurements** |
| **F-U1-5** | file, do not fix | written up, §6 |

⚠ **The F-U1-1 code is NOT in this commit.** I had implemented and gated it before the coordinator's
hold arrived; I reverted the predicate and withdrew the two decline fixtures to
`fix_r1_probes/pending_ruling/`. The **rebuilt binary is BIT-IDENTICAL** to the round's subject
(`a5773be142835fb8`), which is the mechanical proof that nothing behavioural landed — see §7.

---

## 1. F-U1-1 — reproduced exactly, at the size the review stated it

```
fix_r1_probes/drive.sh fix_r1_probes/r14_double_seed_and_angle.c
```

| probe | ORACLE `f7b65d8c` | SUBJECT `a5773be1` |
|---|---|---|
| `r14` (`double d; d = cq_theta(d,d);`) | **exit 1**, 246 B, `cq literal integrity: undef/poison literal reaches two emitted gate operands` | **exit 0**, stderr **0 B** |
| `r15` (two distinct uninitialized doubles) | exit 1, 244 B, same string | exit 0, 0 B |
| `r17` (defined seed, undef angle) | exit 0 | exit 0, **IR IDENTICAL** |
| `r03` (`_Bool` seed defined, undef angle) | exit 0 | exit 0, **IR IDENTICAL** |

Stage-1 shows why: `%1 = tail call double @cq_theta_f64(double noundef undef, double noundef undef)`
— at CQ type `double` the seed and the angle are **one uniqued `double undef`**, so it filled two
emitted slots and GUARD 1's per-function threshold of **2** fired.

**Two compositions the review did not measure, both of which I found and both of which matter to the
ruling:**

* **`r21_crosswidth_seed_and_angle.c`** — `_Bool b; double th; b = cq_theta(b, th);`. `i1 undef` and
  `double undef` are **two different uniqued constants**, so a "same `UndefValue` object" conjunct —
  the fix the brief spells — **would not have caught it**. ORACLE exit 1 / 248 B; SUBJECT exit 0 / 0 B.
  The composition is about the SLOT COUNT, not about constant identity.
* **`r22_nonlocal_other_undef_slot.c`** — the surviving slot on a **different theta**
  (`b = cq_theta(b,0.5); c = cq_theta(c,th);`). ORACLE exit 1 / 248 B; SUBJECT exit 0 / 0 B.
  **No conjunct local to the theta can see this one at all.** Had the brief's fix landed as written,
  it would have closed r14/r15 and left r21 and r22 open — a fix that reads complete and is not.

---

## 2. The four measurements the ruling needs (coordinator's request 2a–2d)

### (a) Does the GENUINE pairing hazard still fire after z9t1? — **YES, unchanged.**

GUARD 1's subject is a literal the LOWERING COPIES to several emitted sites: a rotation's adjoint is
`EmitInverse`'s `cqrt_ry_<W>(h, fneg θ)`, and `fneg poison` folds back to `poison`, so ONE source
angle becomes TWO slots.

```
# a1 — the shipped mirror, unchanged
<BUILD>/ir-pass/cq-opt -load-pass-plugin <BUILD>/ir-pass/libCQPass.so -passes=cq-lowering \
    -S ir-pass/test/lowering_reject_undef_literal_paired_rz_angle.ll -o /dev/null
# a2 — the same module with the FIRST theta's seed ALSO undef, so z9t1 fires and
#      deletes the alloc slot:  fix_r1_probes/a2_pairing_survives_with_undef_seed.ll
```

| probe | ORACLE | SUBJECT | full-stderr sha |
|---|---|---|---|
| `a1` `lowering_reject_undef_literal_paired_rz_angle.ll` (seed `%x`, angle `poison`) | exit 1 | exit 1 | **`6aae90a25c28` on both** |
| `a2` the same, seed changed to `undef` (z9t1 FIRES and removes the alloc slot) | exit 1 | exit 1 | **`d2151e0b0c8d` on both** |

**Reading.** z9t1 deleting the seed's slot does **not** disarm the forward/adjoint pairing, because
that pairing contributes **two** slots by itself. Every genuine pairing break GUARD 1 was built for
still declines. What z9t1 silences is only the case where the two slots are **two independent source
operands** — a seed and an angle — which are the same `Constant` solely because `undef` is uniqued
per type.

### (b) In the r14 module, is the surviving undef read at exactly ONE emitted slot? — **YES, one.**

The complete lowered body on the SUBJECT, every emitted-callee call:

```llvm
%h = call i32 @cqrt_alloc_f64(double 0.000000e+00)
call void @cqrt_ry_f64(i32 %h, double undef)      ; <-- the ONLY undef-bearing slot
%m = call double @cqrt_measure_f64(i32 %h)
```

Three emitted calls, **exactly one** undef-bearing slot (`grep -c`), and **no adjoint**: the rail is
measured, so nothing reverse-plays the Ry and the angle is read at one static site in a module with no
loop. That is structurally the shape `lowering_accept_undef_literal_single_slot.ll` blesses — "with
exactly ONE slot there is no second read to disagree with".

### (c) Where does the blessed single undef actually sit? — **the report's word was half right.**

`ir-pass/test/lowering_accept_undef_literal_single_slot.ll`, read in full:

* **ORIGIN — "a select arm" is CORRECT.** `%a = select i1 %c, double undef, double %q`, the fixture's
  own comment calling it "clang's OWN output … for the dead early-exit merge edge of nexttoward's
  `x == y` test".
* **DESTINATION — it is an ALLOCATOR VALUE OPERAND, not a rotation angle.** The blessed emitted slot
  is `%selop = call i32 @cqrt_alloc_f64(double undef)`, reached through `SelectMergeEmit` and fed to
  `cqrt_copy_f64_controlled`.

So r14's surviving slot (a rotation **ANGLE**) is not the *same slot kind* as the blessed one (an
**alloc seed**). State that precisely rather than as "the same blessed envelope": the two share the
property the fixture's soundness argument actually rests on — **one slot, therefore no second read to
disagree with, and the rail is never freed** — and differ in which operand carries it.

**⚠ And the measurement that was not asked for but changes the picture:** the project **already ships
a committed golden that pins a materialized `undef`**.

```
grep -n "cqrt_alloc_f64" tests/e2e/slice_libm_ld80_nexttoward.expected.log
368:cqrt_alloc_f64(0x1.100000002p-1038) -> h114
```

`0x1.100000002p-1038` is **the same bit pattern** the review quoted as r14's "garbage angle". The
blessed single-slot case is not merely accepted in principle — its materialized value is a committed
golden line in a green suite.

### (d) Is the emitted circuit for r14 DETERMINISTIC? — **YES, across runs and across relinks.**

```
fix_r1_probes/d_determinism.sh fix_r1_probes/r14_double_seed_and_angle.subject.s2.ll
```

Two **independent** link invocations into different temp dirs, producing **two different executables**
(`dc3219cb9736f19e`, `f188e1def2bceba2`), three runs each:

```
cqrt_alloc_f64(0x0p+0) -> h0 | cqrt_ry_f64(h0, 0x1.100000002p-1038) | cqrt_measure_f64(h0) -> 0x0p+0
```

**6 of 6 identical.** The printed angle is not run-to-run junk; it is the deterministic `-O0` stage-3
materialization of an f64 `IMPLICIT_DEF` on this toolchain — the very value already committed at line
368 of the nexttoward golden. So the review's "register junk, not a program value" is right that it is
**not a program value** and wrong to imply it is **unstable**.

⚠ **State the limit honestly.** This is stability across two links in one session on one toolchain and
one optimization level. It is NOT a proof of stability across clang versions, `-O` levels or
platforms, and the value is still one the source never wrote. It would be a poor thing to pin a NEW
golden on — but the project has already pinned one.

### What these four add up to (offered as evidence, not as a ruling)

GUARD 1 is the **pairing** break. After z9t1 it still declines every module where one source literal
reaches two emitted sites ((a)). The r14 family is not that: its two slots were two independent
operands, and after the rewrite exactly one remains, with no second read ((b)) and a deterministic
materialization already blessed elsewhere in the tree ((c), (d)). The counter-consideration to weigh
against that: the surviving slot is a rotation **angle**, and a rotation by an unspecified angle is a
continuous family of unitaries, where an unspecified **alloc** is one unspecified basis state — the
blessed precedent is the latter.

**Population, measured** (`fix_r1_probes/theta_operand_census.py`, a parser over all 1936 fixtures):
**0** fixtures exercise the seed-AND-angle composition; 11 carry a seed-only undef, 3 an angle-only
undef. It is reachable from ordinary C and has zero corpus population.

---

## 3. F-U1-2 — "ONE OBJECT, READ TWICE" is not what the code implements

**Verified.** The predicate is: a whole-value `undef` seed, plus **every** same-typed `UndefValue`
incoming of **every** phi that has this theta as an operand. Nothing tests that the two reads come
from one C object, and after `-O1` nothing could — the reviewer's `r08_two_objects_q.c` (seed taken
from a *different* uninitialized object) lowers to a gate stream identical to the one-object spelling.

**Corrected text** (now in `IMPL_U.md` §2(b) and in `RotationLowering.cpp`): the soundness ground is
the **per-`undef` refinement** — each rewrite independently replaces an `undef` with a value LangRef
already licenses — and the scope is stated as the code's own, not as a C-level story.

**And the property the record should claim, which I verified rather than copied:** an `undef` seed is
a **`Constant`**, and `valueCarriesUndef` returns false for every non-`Constant`
(`LiteralIntegrity.cpp`: `dyn_cast<Constant>(V); if (!C) return false;`). A variable that was never
written cannot be the condition's own live register, which would be an `Instruction`. **So this rule
can only ever produce a FRESH prep, which is what rules out the F2 α reading.**

**Re-grounded.** `control_inplace_ry_reject_stateprep_undef_incoming.ll` does not survive because of a
"both edges" scope — its **seed is `i32 0`**, so `normalizeUndefRotationSeed` returns at the
`valueCarriesUndef` gate and the phi loop is never reached.

---

## 4. F-U1-3 — the `specialize` argument, on the stronger ground, both claims verified by me

**The qualifier is correct.** `SpecializeReject.cpp:50-54`:
`S.Rotations.insert(taint.ThetaCalls.begin(), taint.ThetaCalls.end())` under the comment *"Exact-pointer
membership of the front-end intrinsic call sites `propagate` already collected … (NEVER name-prefix —
C7)"*. So R2 is *"`scanBody` rejects every body containing a theta **that `propagate` collected**"*.

**The stronger ground — I verified all three limbs, and correct one of the reviewer's words:**

1. `propagate` is the **first module-touching statement** of both entry points. `run`
   (`CQLoweringPass.cpp:113-115`): `WidthDispatch wd(M); TaintSet taint = propagate(M, wd);`.
   `runOnFunction` (`:747-755`): `Module &M = *F.getParent(); WidthDispatch wd(M); TaintSet taint =
   propagate(M, wd);`. ⚠ The reviewer wrote "the FIRST statement"; it is the first **after** the
   `WidthDispatch` construction (and, in `runOnFunction`, the `getParent()`), neither of which mutates
   the module. Say it that way — the sentence will be quoted.
   (Also worth carrying: `runOnFunction` is documented in-tree as a **DEAD SHIM** with zero callers.)
2. `collectAndSeed` is called for **every non-declaration function**, unconditionally
   (`TaintPropagation.cpp:480-484`: `for (Function &F : M) { if (F.isDeclaration()) continue; …}`),
   and inside its `IsTheta` arm `normalizeUndefRotationSeed(CI)` is called with **no taint gate and no
   region gate**. `resolveSources` runs at `:464`, before it, so arity 2 and
   `paramType(0) == returnType` are already proven.
3. `ir-pass/src` contains **ZERO** `UndefValue::get` / `PoisonValue::get`
   (`grep -rn "UndefValue::get\|PoisonValue::get" ir-pass/src/ ir-pass/include/` → **1 hit, and it is
   a COMMENT** in `ir-pass/include/LiteralIntegrity.h:136` observing that this very grep is clean).

⇒ *"No `@cq_theta_<sfx>` collected by `propagate` has a whole-value `undef`/`poison` arg-0"* holds from
before the first pass stage and is **taint-independent**. That is the lead; the `specialize` walk is a
corollary.

---

## 5. F-U1-4 — the closure record, with the reviewer's own numbers corrected

**(a) grep or parse — BOTH lines were unsafe to trust, so I re-measured.** `GATES.md` row 34 said
"(grep, not a sweep)"; `IMPL_U.md` §6 said "parsing every theta call's arg-0, not by grep". Rather than
pick, I wrote `fix_r1_probes/theta_operand_census.py` — a parser over **all 1936** fixtures, reporting
**both** operands (the F-U1-1 composition needs the angle, which no earlier instrument reported for the
`.ll` corpus at all):

```
SEED undef/poison only : 11        ANGLE undef/poison only : 3
BOTH                   : 0         PARSE-SKIP              : 2
```

The 2 PARSE-SKIP rows are the two `*_constexpr_*_seed.ll` fixtures, i.e. exactly the deliberately
un-normalized `ConstantExpr` residual — the instrument reports them rather than counting them clean.
Why a grep is the wrong instrument, concretely: `clang -O1` writes `i1 noundef zeroext undef`, so the
substring `undef` is on **every** clang-emitted call via the `noundef` attribute; the operand's value
is its **last token**.

**(b) the `*_lib.c` exclusion — the closure HOLDS; the reviewer's counts do not.** Measured:

| | reviewer | measured |
|---|---|---|
| `tests/e2e/*.c` | 394 | **394** ✓ |
| `*_lib.c` | 22 | **22** ✓ |
| `*_lib.c` containing the token `cq_theta` | 21 | **18** ✗ |
| actual `cq_theta` CALLS in any of them | 0 | **0** ✓ |

All 18 occurrences are `#ifdef cq_theta` compile-time tripwires (17 files) plus one explanatory comment
in `slice_multi_lib.c:8` whose own `#ifdef` is at `:11`. **Nothing is lost**, which is the reviewer's
conclusion and it stands. Also corrected: `IMPL_U.md` §6's "all 391 `tests/e2e/*.c`" describes neither
the directory (**394**) nor the scan (**372** = 394 − 22 skipped); 391 was the pre-change count, before
this increment added three slices.

**(c) "carries the trigger token" is MEASURED, not proved.** A seed `ConstantExpr` that the *parser*
folds to `undef`/`poison` would carry no token and still trigger the rule. The reviewer tried
(`c2_no_token_poison.ll`, `i32 add nuw (i32 -1, i32 1)`); LLVM 19 folded it to `i32 0` and both
binaries were byte-identical. I did not construct one either. Recorded as *neither agent could build
one in LLVM 19*, which is a measurement, not a closure.

---

## 6. F-U1-5 — filed, not fixed: one intervening instruction kills the phi half

`fix_r1_probes` inherits the reviewer's `r11_indirect_merge.c` — u2's shape with `b1 = !cq_theta(b1, 0.5);`.
The phi half walks `Theta->users()` and normalizes only a phi that has the theta **directly** as an
operand, so one instruction in between leaves the merge incoming `undef`, F1's pointer-identity
sub-clause still fails, and the module declines `cq controlled lowering: control flow under quantum
control` — **identically on both binaries** (the reviewer measured 225 B each).

Not a regression: it is an **over-DECLINE residual** of the increment's chosen scope. Under the owner's
2026-09-11 ruling ("our end-goal is to not decline any code that will lead to a valid quantum circuit")
an over-decline of a program that would lower to a valid circuit is a **defect to file**. It belongs
beside bd `bwsh` — which `IMPL_U.md` §8 already proposes re-scoping to the "undef through an
instruction" residual, and this is the same wall reached from the phi side rather than the seed side.
Widening it means chasing instruction operands, which is the `bwsh` conversation and owes its own
Rule-13 round. **For the orchestrator to file; I did not widen anything.**

---

## 7. Gates — and why the expensive ones are CITED and not re-run

⚠ **The hold means this commit changes no behaviour, and that is MECHANICALLY CHECKED, not asserted.**
After reverting the predicate, `git diff` over `ir-pass/` contains **no non-comment line**:

```
git diff -U0 ir-pass/ | grep -E '^[+-]' | grep -v '^[+-][+-]' | grep -vE '^[+-]\s*//' | grep -vE '^[+-]\s*$'
   (no output)
```

and the rebuild is **BIT-IDENTICAL** to the round's subject binary:

```
cmake --build build -j8            # exit 0; 2 pre-existing -Wunused-parameter warnings, untouched functions
shasum -a 256 build/ir-pass/cq-opt build/ir-pass/libCQPass.so
  a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff  cq-opt
  957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194  libCQPass.so
```

`ir-pass/test/` is back to **1936** `.ll` files — the count `GATES.md` row 36 records for that binary.

**So, by the PROTOCOL's own rule that a gate result is a fact about a BINARY:** `ir-pass-lit`
(row 36), the 2793-row corpus sweep (row 32), the 98-row tail (row 33), the injection matrix (row 31)
and the vacuity scan (row 30) are all recorded against `a5773be142835fb8` and are **CITED, not
re-run**. Re-running them would measure the same binary twice, which is the redundancy the protocol
exists to remove. Had the F-U1-1 conjunct landed, every one of them would have been owed afresh — and
I had in fact rebuilt for it (`dedb3d53836771f4…`) before the hold.

Run/cited lines are in `GATES.md`.

---

## 8. What is NOT done, stated plainly

* **F-U1-1 is unfixed and the tree over-accepts r14/r15/r21/r22 today.** That is the standing state,
  by instruction, pending the ruling.
* **The two decline fixtures I wrote are withdrawn, not deleted** —
  `fix_r1_probes/pending_ruling/lowering_reject_undef_theta_seed_{with,crosswidth}_undef_angle.ll`.
  **Measured RED** (`cq-opt` exit 0, 0 B — so the `not … | FileCheck` RUN line fails) on `a5773be1`,
  which is the red half of red-green and the finding itself. ⚠ **I did NOT run the fixture FILES
  through FileCheck on the withdrawn `dedb3d53` build** — what I measured there were the C probes
  they transcribe (`r14`, `r21`), whose declines were restored with byte-identical full stderr. State
  it that way; the green half is owed if the ruling restores the decline. The `crosswidth` row is the
  one that distinguishes the slot predicate from constant identity, and the f64 row cannot substitute
  for it. A positive control at f64 with a real angle was drafted and dropped (it duplicates
  `lowering_accept_undef_theta_seed_widths.ll`'s f64 row).
* **No corpus sweep was run on a new binary** because there is no new binary; §7 is the argument, and
  it is a hash comparison rather than a promise. **Nothing is left unaudited by this** — but note the
  cited sweep (row 32) was itself **PARTIAL** when recorded (`ir-pass/test` fixtures 1–1581 of 1928,
  stopped under load), closed by the 98-row undef-token tail and the remainder parse. I did not
  re-open that; the remainder question is now answered more strongly by §5(a)'s whole-corpus census.
* **I ran no suite layer at all** — no `ir-pass-lit`, no `^e2e-`, no full `ctest`, no equivalence
  sweep. Everything above is per-probe two-binary measurement plus direct file reads.
