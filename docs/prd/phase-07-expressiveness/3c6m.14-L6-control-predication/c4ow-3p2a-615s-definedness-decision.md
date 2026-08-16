# Definedness at the accept predicate — bd c4ow + bd 3p2a + bd 615s

**Status:** SHIPPED, branch `3c6m.14-control-l6`, 2026-08-15, as **two** commits
(c4ow+3p2a merged; 615s separate).
**Scope:** `ir-pass/src/IOSinkLowering.cpp`, `ir-pass/src/SpecializeReject.{h,cpp}`,
`ir-pass/src/PredMuxFlatten.cpp`. **No new TU, no frozen symbol, no YAML edit, no
new runtime template, no new gate sequence, no new emission path.** 15 new lit
fixtures (1035 → 1050); 4 existing fixtures re-pointed at an earlier diagnostic.
**Successor to** `xy9n-7udx-literal-integrity-decision.md` and
`u1rp-poison-family-decision.md`, whose framing this document assumes, and to the
bd s6ao QROM round, whose method it follows.

---

## 0. THE ONE SENTENCE

All three tickets are the **same defect class in three accept predicates**: a
predicate written to mean *"this value is known"* was spelled in a way that admits
a value which **denotes nothing** — and in each case that spelling was not sloppy,
it was the natural reading of the intent right up until someone asked what
`undef`/`poison` does to it.

| ticket | predicate | intent | spelling | what slipped through |
|---|---|---|---|---|
| c4ow | `collectTapeTargets` classical co-arg | "compile-time KNOWN, so dropping it is free" | `isa<Constant>` | `undef`/`poison` **are** `Constant`s |
| 3p2a | `SpecializeReject::scanBody` | "computes a reversible classical FUNCTION of its arguments" | an opcode whitelist that `continue`s past terminators | a body of just `ret i32 poison` passes **vacuously** |
| 615s | `classifyConeNode` leaf rule | "this cone is DEFINED once its annotations are dropped" | `Constant / Argument leaf — defined` | an `Argument` with `nofpclass`/`range`/`nonnull`/`align` is poison if the caller lies |

Every one is a **monotone-restrictive** change: each can only turn an accept into
a decline. That is stated up front deliberately — it tells a Rule-13 round to hunt
crashes, non-termination and over-declines rather than miscompiles (the bd s6ao
containment lesson).

---

## 1. bd c4ow — AND THE FRAMING THE TICKET GOT WRONG

### 1.1 The ticket's stated harm is FALSE

bd c4ow says a poison classical co-arg is "silently DROPPED rather than emitted",
so "the golden trace has one fewer field than the program specifies". **Measured
on the shipped pre-change plugin:**

```
printf("%d %d\n", q, i32 7)       ->  1 × cqrt_tape_write_i32, @printf erased, exit 0
printf("%d %d\n", q, i32 poison)  ->  BYTE-IDENTICAL
```

Dropping a **classical** co-arg is the shipped, documented 7.6 design — only
*tainted* args are taped (`collectTapeTargets`' own doc comment). So a defined `7`
is dropped too, nothing is lost relative to it, and no observable moves. A
reviewer falsifies the tape-length framing in thirty seconds, which is exactly why
the source comment, the fixtures and this document all lead with the **fence
contract** instead.

### 1.2 What is actually wrong

The fence means *"this co-arg is compile-time KNOWN, so dropping it costs the
program nothing"*, and `isa<Constant>` is how that intent is spelled.
`undef`/`poison` are `Constant`s that **denote no value**, so the predicate
admitted precisely the input its rationale excludes. Prime Directive: an unproven
accept surface should not exist, and the input is UB, so the decline is free.

**Do not call them "the one kind of `Constant`" for which that is true** — a first
draft did and the Rule-13 round falsified it. A `ConstantExpr` that *generates*
poison without *containing* an `UndefValue` (the bd bu96 class, e.g. an
out-of-bounds `inbounds` gep under a `ptrtoint`) denotes no value just as much,
and `slotCarriesUndef` returns false on it — measured: still accepted, co-arg
dropped, module byte-identical to the `i32 7` accept fixture's. The fence
discriminates on the **spelling**. That residual is knowingly inherited from bu96
(decline-to-fix), but note bu96's licence does **not** transfer here: bu96 is sound
on the *pairing* axis and nothing at this site is paired. What makes it harmless
here is §1.1 — dropping a classical co-arg is byte-neutral whatever it denotes.

### 1.3 Reach — proven, trivial

```c
int y; printf("%d %d\n", x, y);
```

`clang -O1` emits `i32 noundef undef` in the arg list, **with no warning**.
(`noundef undef` is a contradiction LLVM tolerates; the frontend stamps the
attribute from the C prototype, the middle end materialises the value from the
uninitialised local.)

### 1.4 One site, two callers

`collectTapeTargets` is already the shared Rule-14 validator for **both** emitters
— `lowerIOSinks` (step 3) and `lowerControlledIOSinks` (step 5, once per arm). Both
call it **before** their emitter's first `CreateCall` (the controlled path's first
mint is step 7a's flag), so this is a genuine **claim-time** decline and there is
no second fence to keep in step. One clause, two fixtures — the controlled fixture
pins the Rule-14 *sharing*, not a second guard.

### 1.5 The predicate, and the trap next to it

The fence calls **`slotCarriesUndef`**, the `GlobalValue`-address-skipping
predicate — never `valueCarriesUndef`.

A `printf` argument list is **dominated by global ADDRESSES**: the format string is
one on every single call. `valueCarriesUndef` descends into a global's
**INITIALIZER**, which is a different value from the address in the slot, and
`clang -O1` really emits

```llvm
@v = global { i32, [12 x i8] } { i32 3, [12 x i8] undef }
```

for a partially-initialised `union { long double f; int i; }` — the fp80 idiom this
project is built on. Under `valueCarriesUndef` that **well-defined** program
declines. `lowering_io_accept_global_pad_coarg.ll` is the arm-kill.

**After this batch there are three `slotCarriesUndef` call sites and exactly ONE
`valueCarriesUndef` caller** — `classifyConeNode`'s cone leaf, where the
over-decline is PRE-EXISTING and removing it is an accept WIDENING (bd ajw7, still
OPEN, its two-line fix written and then deliberately reverted). **Do not unify
them.** That is the single most dangerous edit available in this area.

A **tainted** arg cannot reach the new clause: taint is seeded at `@cq_theta_*`
call results and propagated to `Instruction` users, so `taint.Tainted` holds no
`Constant` and the tainted branch always wins for a non-`Constant`. The check is
therefore on the classical branch only, where it can fire.

---

## 2. bd 3p2a — THE CERTIFICATE, AND A SUBSUMPTION NOBODY EXPECTED

### 2.1 The ticket's harm claim is also false, and this one matters more

bd 3p2a says the clone's poison return "is used as an i32 QUBIT HANDLE". It is
not, and **structurally cannot be**: `buildClone` sets

```cpp
bool ReturnTainted = RV && cloneTaint.Tainted.count(RV);
```

and a `Constant` is never in a taint set, so a literal-poison return is always
classified **classical** and lands in a template's LITERAL slot. Measured
end-to-end at the shipped `-O0` stage 3, the complete trace of the exhibit is

```
cqrt_alloc_i32(3) -> h0
cqrt_ry_i32(h0, 0x1p-1)
cq_template_add_i32_hl(h0, 0)      ; h0 is a REAL rail; the 0 is the poison
```

— no gate on a phantom rail, and no forward/adjoint pairing break either, because
an adjoint copies the forward's **operands** so both reads hit one SSA register.

(The ticket's claim is not invented: it is a true description of a **different**
surface — the bd 3c6m.14.2 exhibit in
`control_predmux_reject_selectform_purecallee_retpoison.ll`, where PredMux's
deleted pure-callee disjunct admitted a poison-returning callee into a shielded
cone. That clause is gone. What survived is the specialization path, and there the
value is classical.)

### 2.2 Reach — proven, and multi-TU-only

```c
/* leaf.c   */ int leaf(int a) { int x; return x; }     ->  ret i32 undef
/* caller.c */ int r = leaf(q); ...
```

Single-TU it is **unreachable** — IPSCCP replaces the call with `undef` and deletes
it. But CQ ships `run_slice_multi.sh` (per-TU `-O1` → `llvm-link` → one
`cq-lowering`), and there the clone **is** minted: measured `opt` exit 0,
`@__cq_q_leaf_1` emitted with a `ret i32 undef` body, feeding
`cq_template_add_i32_hl`.

### 2.3 The fix, and its scope

`scanBody`'s `ret` arm now runs `returnDerivesFromUndef(RV)` — a backward cone
walk over the returned value, visited-set terminated, descending every operand of
an `Instruction`, stopping at `Argument`/`Constant`/global (tested by
`slotCarriesUndef` on the way in), and never entering a callee's BODY because
`scanBody` already recurses into every nested visible callee in its own frame.
New reason `SpecReject::UndefReturn`, new message

```
cq specialization: callee return value denotes no value (undef/poison)
```

**The walk, not an operand test.** A one-line `slotCarriesUndef(R->getReturnValue())`
catches `ret i32 poison` and walks straight past `%c = xor i32 poison, 7; ret %c`.
bd u1rp already recorded this failure once — *"an arguments-only scan fences depth
1"* — and `spec_reject_ret_undef_derived.ll` is what stops it recurring.

### 2.4 THE SUBSUMPTION — the load-bearing finding, and a first draft that was wrong

The first draft of the source comment asserted that the return-cone scope leaves
`Specialization::ensureTwin`'s `findUndefOperandInBody` fence (bd xy9n) untouched.
**The fixtures falsified it immediately:** all three of that fence's rows are built
on `%c = xor i32 undef, 7` → `%y = mul i32 %a, %c` → `ret i32 %y`, so the undef is
*in the return cone* and the new fence declines all three earlier.

That is not an accident of those probes. It is **exact subsumption of the twin
fence's harmful cell**, and the argument is short:

> The twin's job is to zero the clone's out rail, which it does by **re-executing
> the body** and un-copying the recomputed result: `cqrt_copy_i32(<recomputed
> ResultRail>, out)`. `ResultRail` **is** the clone's returned value. So the
> un-copy fails — leaving `out` dirty for the `cqrt_free` that follows, the Rule-6/8
> hidden measurement — **iff** the recomputed RETURN differs between the two bodies,
> **iff** the return derives from `undef`. Every other divergence is
> self-cancelling: a SCRATCH gate's forward and adjoint sit in the **same** body and
> read the same materialisation, so each copy restores its own rail.

**Measured**, on the isolated shape (undef feeds a scratch `mul`, return cone
clean), with the twin fence armed off and linked at `-O0`, twice, byte-identical:

```
cq_template_mul_i32_hl(h0, 73903) -> h1     ; forward clone
cq_template_mul_i32_hl_unc(h1, h0, 73903)   ; ... its own adjoint
cq_template_mul_i32_hl(h0, 7)     -> h6     ; TWIN  *** DIFFERENT ***
cq_template_mul_i32_hl_unc(h6, h0, 7)       ; ... its own adjoint
```

Two different multipliers — **and the out rail is still correctly zeroed**, because
the twin un-copies via the recomputed `add(h0,1)`, which never touches `%c`.

Consequences, all shipped explicitly rather than left to be discovered:

* Three twin fixtures now assert the **specialization** diagnostic. Their modules
  are byte-identical; each gained a `WHAT CHANGED WITH bd 3p2a` section carrying
  the original exhibit *and* this argument.
* `findUndefOperandInBody` **stays**. Deleting a fence because a different one
  covers its measured population is an accept WIDENING inside a tightening commit —
  the standing bd ajw7 lesson. Its remaining reach (undef in DEAD or SCRATCH body
  positions) is an over-decline, and that is said in the file rather than implied.
* `spec_reject_twin_undef_dup_scratch.ll` is new, and exists so that fence keeps a
  **reaching** fixture (Rule 12). Its header states in its first paragraph that it
  pins an over-decline — a fixture claiming a harm it cannot show is worse than no
  fixture.
* `control_predmux_reject_selectform_purecallee_retpoison.ll` is likewise
  re-pointed. Its `CQ_PREDMUX_DBG` RUN line — which asserts `leave … gate=E6-condtree`
  and is the *actual* arm-kill for the deleted pure-callee disjunct — **passes
  unchanged**, because `flattenPredMuxRegions` (~194) runs before
  `detectSpecializations` (~235). Two sibling rows pin that clause independently.

### 2.5 What is honestly NOT claimed

There is **no measured live miscompile** behind bd 3p2a. The harmful duplication
path was already fenced (verified: a three-level probe whose poison-returning leaf
is reached through a twinned middle clone declines today at
`findUndefOperandInBody`). This change moves the decline to the **accept
predicate**, where the certificate is issued, and closes the certificate hole
itself. That is a Prime-Directive tightening, and it is described as one.

---

## 3. bd 615s — OPTION 1 ONLY, AND THE HALF THAT STAYS OPEN

### 3.1 The change

`classifyConeNode` returns `ConeNode::Fail` for an `Argument` carrying any of
LLVM 19's four **poison-on-violation** parameter attributes — `nofpclass`,
`range`, `nonnull`, `align`.

`coneDefinedAfterFlagDrop` promises *"defined once its poison-generating
annotations are dropped"* and on that promise the flatten rewrites a
poison-SHIELDED `select(a, b, false)` into a plain `and(a, b)`, which **observes**
`b` on basis states the shield excluded. An attributed parameter is poison arriving
from **outside** the function, where no drop this pass performs can reach it:
`dropPoisonGeneratingAnnotations()` mutates INSTRUCTIONS, and the attribute lives
on the caller's call site in another function. Refusing beats mutating.

### 3.2 Monotone-restrictive, and inert at emit time

`Leaf → Fail` only, so the claimed set can only shrink. `stripPoisonCone` treats
`Fail` exactly like `Leaf` (`C != Interior` → `continue`), an `Argument` has no
operands to recurse into and no annotation to drop, and the claim runs first
anyway — so the emit side is untouched.

### 3.3 Arm-kill, measured

With the clause disabled, the `range` probe is **accepted** (exit 0), the diamond
flattened, and `%cc = add i32 %c, 1` — defined only if the caller honours
`range(i32 0, 10)` — reaches

```llvm
%h_cmp1 = call i32 @cq_template_icmp_sgt_i32_hl(i32 %h, i32 %cc)
call void @cqrt_toffoli(i32 %h_cmp, i32 %h_cmp1, i32 %g)      ; the `and`
call void @cq_template_icmp_sgt_i32_hl_unc(i32 %h_cmp1, i32 %h, i32 %cc)
call void @cqrt_free(i32 %h_cmp1)
```

With it on: `leave @probe … gate=E6-condtree`.

**Be precise about which defect this is.** It is NOT the xy9n pairing break — `%cc`
is one SSA register read twice, and `declineUnpairedUndefLiterals` correctly counts
zero literal slots. It is the defect `coneDefinedAfterFlagDrop` exists to prevent:
the conjunction is now evaluated on basis states where the source's short circuit
never evaluated `b` at all.

### 3.4 Per-attribute reachability — stated, not assumed

| attribute | reaching fixture | note |
|---|---|---|
| `range` | `control_predmux_reject_selectform_range_arg.ll` | clean red-green (exit 0 → exit 1) |
| `nofpclass` | `control_predmux_reject_selectform_nofpclass_arg_redgreen.ll` | clean red-green, and a real accept **loss**: BASE emits 18 controlled gates, SHIP declines. Written *because* the round falsified the older `…_nofpclass_arg.ll`'s claim to "carry the family" — that row's fp leaf is all-classical, so it declines downstream either way and only its **DBG** line discriminates. It witnesses the *relocation*; the `_redgreen` row witnesses the loss |
| `nonnull` | **none** | measured: a bare `ptr` control declines identically. A pointer cast is refused by `definedOpAfterFlagDrop` and a pointer-typed compare leaf declines upstream |
| `align` | **none** | same measurement |

The four are shipped as **one predicate** with two reaching fixtures plus an accept
control, not as four predicates. The complete LangRef enumeration is preferred over
"whichever two happen to be reachable this month" — the bd s6ao lesson is that the
enumeration is what LLVM keeps moving, and a partial one invites the
*which-channel-did-we-forget* bug. The unreachable two cost two `hasAttribute`
calls inside an already monotone-restrictive predicate.

### 3.5 THE RESIDUAL — the populated half stays open, and the reason is NOT cost

**A BARE `Argument` is still `Leaf`, and that is literally false in exactly the
same way.** A caller may pass `poison` to any parameter, and the `select`→`and`
canonicalization then observes it on basis states the shield excluded.

**The first draft of this section justified leaving it open with a cost number
that the Rule-13 round measured wrong by ~14x, in the direction that discourages
closing the hole.** It read: *"28 of the 49 shielded select-forms in the corpus
reach a bare `Argument` … refusing bare arguments would decline 28 real
select-forms."* Both halves are false:

* **The corpus was never named, and it is `ir-pass/test`** — this pass's own
  hand-written fixtures, not real code. (In `PredMuxFlatten.cpp` "real" means
  openlibm, which has 39 forms — the number cited 100 lines below.) 19 of the 28
  are exit-code-inverted **decline** rows that already decline for other reasons,
  and 27 of the 28 reach a bare arg only because hand-written fixtures do not
  bother to write `noundef`.
* **A SHAPE census is not a FENCE measurement.** `tools/predmux_cone_census.py`
  says exactly that in its own header, and it was quoted as one anyway.

**The fence measurement**, by arm-kill (every `Argument` → `Fail`; exit code *and*
emitted IR per module; reproduced independently three times, once in an isolated
rsync'd tree with its own cmake build):

| corpus | modules | change |
|---|---|---|
| `ir-pass/test` | 1048 | **3**, all exit 0 → 1 — the residual pin itself plus the two u1rp controls `…_incone_flags_stripped` and `…_retattr_dropped` |
| e2e stage-1 | 220 | **0** |
| full e2e ctest under the arm | 240 slices + goldens | **green** |

The non-`noundef`-only arm gives the identical 3 / 0. So the **pre-existing** accept
lost by closing the populated half is **two fixture rows and zero real code** — and
adding `noundef` to those two rows' parameters (what `clang -O1` would have emitted
anyway) makes both accept again with byte-identical lowering.

> **So the other half is open because this work was scoped to Option 1 by owner
> ruling, not because closing it is expensive.** State it that way round.

And the ground the residual rests on is narrower than it reads. *"`clang -O1`
stamps `noundef` on real parameters"* holds for **428/428** openlibm and **60/60**
e2e stage-1 formal parameters — but **not** for a record-typed parameter coerced to
an integer, where clang deliberately omits it because the struct padding may be
undef. Measured from ordinary C: `struct{int a,b;}` by value gives
`define i32 @probe(i64 %0, i32 noundef %1)`, and the bare `%0` reaches an
**accepted** shielded cone (`icmp` ← `trunc nuw` ← `lshr` ← `%0`). No correctness
consequence was exhibited — an `Argument` is one register at the ABI boundary, so
it cannot produce the bd u1rp per-use divergence, which needs a literal `undef`
`Constant` in two lowered gate slots — but the ruling's stated reason does not
cover that shape.

`control_predmux_accept_selectform_bare_arg.ll` pins the residual deliberately and
carries these corrected numbers, precisely so `…_nofpclass_arg.ll` is never quoted
as having closed the Argument-leaf class. bd 615s carries them too, so the next
decision is made on real numbers.

### 3.6 Option 2 is DEFERRED, not forgotten

Stripping `nofpclass` alongside the three declared families in `stripPoisonCone`:
zero population, zero readers (`grep nofpclass ir-pass/` was empty before this
change), and it is a **drop-widening on the exact surface where bd u1rp reverted
one**. Refusing beats mutating.

---

## 3bis. bd 615s INCREMENT 2 — THE ENUMERATION REPLACED BY ONE QUESTION

**Status:** shipped on top of `b5fb9f2`, 2026-08-16. `classifyConeNode`: an
`Argument` is a defined cone leaf **iff it carries `noundef`**.

### 3bis.1 Why the enumeration was the wrong shape

Increment 1 listed the four poison-on-violation parameter attributes and failed
those. That is a **presence scan** — "is a poison-conditional fact present?" — the
framing bd s6ao's post-mortem names as the error, because the enumeration is what
LLVM keeps moving. The **converse** question has a direct LLVM answer, and it is
better in both directions at once:

| cell | increment 1 | increment 2 |
|---|---|---|
| bare `Argument`, no attributes | accepted (the open half) | **declined** |
| register-coerced by-value record param | accepted | **declined** |
| `noundef nofpclass(nan inf)` — what real fast-math clang emits | **declined** (over-decline) | accepted |

### 3bis.2 The ground, quoted rather than generalised

Verbatim LangRef 19, from the list of positions where a poison value triggers
**immediate UB**:

> "The parameter operand of a `call` or `invoke` instruction, when the function
> **or invoking call site** has a `noundef` attribute in the corresponding
> position."

The UB is located **at the call**, which happens-before every instruction of the
callee body — so on any execution that *reaches* the rewritten code, the parameter
was defined. There is no ordering objection to answer.

**The first draft did not say this.** It said "either the value is defined, or the
program is already UB, so nothing we do is licensed or unlicensed", and the round
pointed out that at that generality it is the s6ao move in different clothes.
**The discriminator:** s6ao's escape hatch was a *well-defined* execution on which
the artifact then read out of bounds; this one is *no execution at all*.

Corroborated twice, independently: LLVM makes the identical inference on the
identical construct (`isGuaranteedNotToBeUndefOrPoison` on an `Argument` is
`noundef || dereferenceable || dereferenceable_or_null`, measured by an 11-case
`freeze`-fold probe under stock `instcombine`, with `noundef` dominating a
co-located attribute), and the IR CQ consumes has *already* been transformed by
`clang -O1` under that inference.

### 3bis.3 THE COST — and the second powerless number this file had to retract

Increment 2's first draft justified the tightening with "3 fixtures and **zero
real modules**; real code always carries the attribute (428/428 openlibm, 60/60
e2e)". **Retracted, for the same reason increment 1's "28 of 49" was.**

Measured with the **maximal arm** — `Fail` on *every* `Argument`, the strictest
this predicate can be — over the 220 e2e stage-1 modules, comparing exit code and
emitted IR: **0 differ**. No real-code corpus available in this project can
distinguish *any* setting of this clause (and 0 of 252 openlibm modules carry a
`cq_*` intrinsic at all, so the pass early-outs on them as passthrough). The zero
is literally true and carries no information.

> **A shape census is not a fence measurement — and neither is a fence measurement
> with no reach.** The entire evidentiary basis for this predicate is hand-authored
> IR plus purpose-built C exhibits. That is worth saying twice, because this one
> comment has now shipped a powerless number in *both* directions: increment 1's
> discouraged closing the hole, increment 2's understated the price of closing it.

**The real cost is not zero.** `clang` omits `noundef` from every register-coerced
by-value record parameter, so ordinary C passing a `struct` by value now declines
**module-wide** where it previously lowered a 144-gate circuit. It is the *same
cell* as the hole — clang omits the attribute there because the coerced value may
carry undef padding — so closing the hole necessarily declines it. The fence is
**coarse, not wrong**: the cone usually reads a defined *field* out of that value
and CQ has no per-field proof. Filed as an additive widening.

### 3bis.4 Residuals, each filed

* field-granular admission for a coerced record parameter (the accept above);
* `freeze(bare_arg)` over-declines — one line, but a widening;
* the `Constant` half of the same `return ConeNode::Leaf` line still rests on bd
  bu96's **pairing** axis while the `Argument` half now rests on **definedness** —
  one line, two standards, and the weak one admits a poison `ConstantExpr` leaf
  from ordinary `-O1` C. Pre-existing under both increments;
* on a UB input CQ **emits** rather than declines, and for a caller passing literal
  `undef` the emitted circuit is bd u1rp-shaped. Permitted (UB at the call), and
  `declineUnpairedUndefLiterals` cannot see it because at guard time the value is
  an `Argument`, not a literal.

---

## 4. VERIFICATION

* `ctest --test-dir build -j6` — **253/253 PASS**, all 243 e2e slices and their
  committed goldens green. **No golden moved**, and that is positive evidence:
  nothing in the corpus pinned a poison-derived value, so the over-accepts bought
  no capability. A golden going red here would have been evidence of a *shipped*
  over-accept, not a regression to regenerate.
* `lit ir-pass/test` — 1048 discovered, **1047 pass + 1 expected XFAIL**.
* `cq-opt-equivalence-full` — **1048 fixtures, 0 mismatches** (stdout, stderr and
  exit code against stock `opt`).
* Arm-kills run before the fixtures were written, not after: the 615s `Argument`
  clause, the xy9n twin fence, and `moveBody`'s `dropPoisonGeneratingFlags`.
* **Rule-13: an 11-agent adversarial round** — seven independent lenses
  (over-accept per ticket, crash/termination/over-decline, claim falsification,
  fixture arm-kill over 10 arms, pipeline interaction, 615s scope), per-finding
  adversarial verifiers, and a completeness critic. **Not one lens found a new
  over-accept.** Every finding was MINOR/NIT except two **documentation** MAJORs
  about the false cost number in §3.5. The round additionally produced a
  **252-module openlibm BASE-vs-SHIP IR differential: 0 differ**, and re-ran the
  full ctest and full equivalence sweep on the final tree state.
* Corrections the round forced, all applied: the §3.5 cost number; "the one kind of
  `Constant`" in c4ow (a bu96-class poison `ConstantExpr` is a second and still
  passes); "no second fence to keep in step" (true only of printf/putchar —
  `AbortParkEmit` drops noreturn-sink args untested, bd `ogwt`); "a scratch gate's
  forward and adjoint sit in the SAME body" (false for a `ReturnTainted` inner
  clone call — two bodies; the conclusion survives, the reason did not); the
  effective scope of 3p2a (transitive, so a nested callee's dead all-classical
  `ret undef` now declines the outer candidate — a pure over-decline);
  `spec_accept_undef_outside_return_cone.ll`'s "no twin is synthesized" licence
  (false — bd `jj3o`); and five vacuous `CHECK-NOT` lines that FileCheck'd stdout
  while diagnostics go to stderr.

---

## 5. WHAT A FUTURE AGENT MUST NOT DO

1. **Do not unify `slotCarriesUndef` and `valueCarriesUndef`.** Three call sites vs
   one, and the one is deliberate (bd ajw7).
2. **Do not delete `findUndefOperandInBody`** because bd 3p2a covers its harmful
   cell. That is an accept widening; it needs its own review and its own commit.
3. **Do not widen `returnDerivesFromUndef` to a whole-body scan.** It adds only
   over-declines and strips the twin fence of its last reaching fixture.
4. **Do not read `…_nofpclass_arg.ll` as closing the Argument-leaf class.** The
   populated half of bd 615s is open.
5. **Do not quote the tickets' stated harms.** bd c4ow's "lost tape field" and bd
   3p2a's "poison qubit handle" are both measurably false; the real grounds are in
   §1.2 and §2.1.
