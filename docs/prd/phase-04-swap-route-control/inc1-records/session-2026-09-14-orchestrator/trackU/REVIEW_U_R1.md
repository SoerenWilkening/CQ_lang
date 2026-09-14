# Track U — ADVERSARIAL REVIEW round 1 (Rule 13), bd `z9t1` — VERDICT

**Reviewer:** independent adversarial reviewer, round 1. I did not write the code.
**Date:** 2026-09-14.
**Subject:** `/Users/sorenwilkening/Desktop/CQ_undef`, branch `undef-seed-zero`, HEAD
`8865f7d55104c52644080c41ed8ee02b17e1c89f` (confirmed clean worktree).
**Probes:** `$SES/trackU/review_r1_probes/` (driver `drive.sh`, 24 probe modules, every one run through
BOTH binaries on the same stage-1 file).

## 0. Hash gate — PASS (my first act)

```
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_undef/build/ir-pass/{cq-opt,libCQPass.so}
shasum -a 256 /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/{cq-opt,libCQPass.so}
```

| binary | measured | brief | |
|---|---|---|---|
| SUBJECT `cq-opt` | `a5773be142835fb8a7f0f5a324934d48698c93c12ee231ce8b2c5406741885ff` | same | ✅ |
| SUBJECT `libCQPass.so` | `957d2e14f1eca2e31b94e59b52532d69236b45fb39aae4fdb47d45ded4750194` | same | ✅ |
| ORACLE `cq-opt` | `f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc` | same | ✅ |
| ORACLE `libCQPass.so` | `f9e898badfd4207a758d27638a34b7e147bd3b702e5611b4fad0e0403879039d` | same | ✅ |

All four match. No build was run by me; `cmake` was never invoked. No lit or ctest layer was executed —
the one Rule-11 spot-check budget was spent instead on **direct `cq-opt` + `FileCheck` runs**, which are
strictly more informative than a lit re-run and cost one spawn each.

---

## VERDICT: **CLEAR-WITH-ITEMS**

Five findings, one of them in the unforgivable *direction* (over-ACCEPT) though not, on the evidence I
have, a wrong unitary. Nothing I found changes a circuit that the compiler already emitted correctly.

| id | claim | severity |
|---|---|---|
| **F-U1-1** | a whole DECLINE→ACCEPT mover class through `declineUnpairedUndefLiterals` is unreported, and one member of it lands an **`undef` rotation ANGLE** in the emitted module | **over-ACCEPT** (population widening) |
| **F-U1-2** | the "ONE OBJECT, READ TWICE" precondition in the source comment and IMPL §2(b) is not what the code implements and is not expressible in the IR | documentation (L7) |
| **F-U1-3** | the L1/`specialize` argument is correct but rests on the weaker of two grounds, and its load-bearing clause needs a pointer-membership qualifier | documentation |
| **F-U1-4** | three inconsistencies in the corpus/e2e closure record (one of which I closed for the implementer) | record hygiene |
| **F-U1-5** | an unnamed over-decline residual: one intervening instruction between the theta and the merge and the phi half does not fire | over-DECLINE (file, don't fix) |

---

## F-U1-1 — the `declineUnpairedUndefLiterals` mover class, and the `undef` angle it lets through

**Claim.** z9t1 does not only move modules through the two strings the brief predicted. It also moves
modules through a **third** diagnostic — `cq literal integrity: undef/poison literal reaches two emitted
gate operands` (`LiteralIntegrity.cpp` GUARD 1, bd `xy9n`) — and in the `double`/f64 spelling the
resulting ACCEPT emits **`call void @cqrt_ry_f64(i32 %h, double undef)`**: an `undef` in a gate operand,
which is precisely what that guard exists to refuse. This class is named nowhere in `IMPL_U.md` §5, §6 or
§7, and IMPL §2(f) affirmatively states the opposite for arg-1 ("Out of scope, unchanged, pinned").

**Probe.** `review_r1_probes/r14_double_seed_and_angle.c` (and `r15_double_two_objects.c`, the
two-distinct-objects twin):

```c
#include "CQ.h"
int main(void) { double d; d = cq_theta(d, d); return (int)cq_measure(d); }
```

```
LLVM=/usr/local/opt/llvm@19/bin
$LLVM/clang -Iinclude -include CQ.h -O1 -g -emit-llvm -S r14_double_seed_and_angle.c -o r14.s1.ll
<BUILD>/ir-pass/cq-opt -load-pass-plugin <BUILD>/ir-pass/libCQPass.so -passes=cq-lowering -S r14.s1.ll -o r14.<K>.s2.ll
```

| | verdict |
|---|---|
| **ORACLE** `f7b65d8c` | **exit 1**, 249 B stderr: `cq literal integrity: undef/poison literal reaches two emitted gate operands` |
| **SUBJECT** `a5773be1` | **exit 0**, stderr **0 bytes**, stage 2b STRICT clean (`1 rail mint … 0 violation(s), 0 unproven`) |

Subject's emitted stream, and the linked run (3× consecutive, `clang s2.ll libcq_templates.a
libcq_runtime.a`):

```llvm
%h = call i32 @cqrt_alloc_f64(double 0.000000e+00)
call void @cqrt_ry_f64(i32 %h, double undef)          ; <-- the undef gate operand
%m = call double @cqrt_measure_f64(i32 %h)
```
```
cqrt_alloc_f64(0x0p+0) -> h0
cqrt_ry_f64(h0, 0x1.100000002p-1038)                  ; <-- register junk, not a program value
cqrt_measure_f64(h0) -> 0x0p+0
```

**Root cause (read from the source, not guessed).** At CQ type `double` the SEED and the ANGLE are the
same LLVM type, so **one uniqued `double undef` constant occupies two emitted gate slots** and GUARD 1's
per-function threshold (**2**, `LiteralIntegrity.cpp`) fires. `normalizeUndefRotationSeed` rewrites the
seed slot to `0.0`, the count falls 2 → 1, and the guard goes silent — because the 1-slot case is a
*deliberately* ruled-in ACCEPT, pinned by `lowering_accept_undef_literal_single_slot.ll` and load-bearing
for the committed `slice_libm_ld80_nexttoward` golden.

**Both verdicts on the controls, so the finding is stated at the right size:**

| probe | oracle | subject | reading |
|---|---|---|---|
| `r17_double_angle_only.c` (defined seed, undef angle) | ACCEPT, `cqrt_ry_f64(h, double undef)` | **IR IDENTICAL** | the lone-undef-angle accept is **PRE-EXISTING** |
| `r03_angle_undef.c` (`_Bool`, undef angle) | ACCEPT, `cqrt_ry_i1(h, double undef)` | **IR IDENTICAL** | same |
| `r14` / `r15` (undef seed **and** undef angle at f64) | **DECLINE** | **ACCEPT** | z9t1 **adds customers** to that pre-existing hole |
| `r06_array.c`, `r07_widths.c` (2+ undef-seeded thetas, no undef angle) | **DECLINE**, same string | ACCEPT, correct `alloc_<W>(0)`+`ry` per rail, stage 2b clean | the **benign** half of the class — a genuine over-decline removed |

So the emitted shape is inside the project's already-blessed envelope, which is why I do not call this a
silent miscompile. What it *is*: **"pre-existing" is true of the defect and FALSE of its population** —
CLAUDE.md's own clause — and the change was recorded as leaving arg-1 alone when, in this composition, it
demonstrably does not.

**Severity.** over-ACCEPT. Not blocking on its own; blocking under a strict reading of "the emitted
module must not carry an `undef` gate operand that a guard was catching".

**Minimal fix (I recommend (a)).**
* **(a)** In `normalizeUndefRotationSeed`, refuse the rewrite when the SAME `UndefValue` object also
  occupies this theta's **arg-1** — three lines, Prime-Directive-shaped (the rewrite must not *disarm* a
  guard), plus the decline fixture that mirrors the `cq literal integrity` string character-for-character.
  The two ruled spellings are unaffected: neither has an undef angle.
* **(b)** Accept the widening deliberately, and land (i) a lit fixture pinning the f64 seed+angle module
  as an ACCEPT with its stream, (ii) a retraction of IMPL §2(f)'s "unchanged, pinned", and (iii) the class
  named in §6's mover taxonomy. I like this less: the emitted trace carries a **garbage angle**, which is a
  stream no golden can honestly pin.

Either way, **§6's mover taxonomy must gain the `cq literal integrity` row** — an increment that moves
three fixtures is entitled to say "nothing else moved" only about the corpus it swept, and the class is
reachable from ordinary C.

---

## F-U1-2 — "ONE OBJECT, READ TWICE" is a C-level story the IR cannot carry

**Claim.** `RotationLowering.cpp`'s comment and `IMPL_U.md` §2(b) state the phi half as being about *one
uninitialized object read twice*, and scope it as "only where the object was undefined on BOTH edges".
The code checks no such thing. Its actual predicate is: *a whole-value `undef` seed, plus **every**
same-typed `UndefValue` incoming of **every** phi that has this theta as an operand.*

**Probe.** `r08_two_objects_q.c` — u2's exact shape with the seed taken from a **different**
uninitialized object than the merge's straight-through incoming:

```c
bool b1;   /* the merge's straight-through incoming */
bool x;    /* a DIFFERENT object -- the seed */
if (a >= 3){ b1 = cq_theta(x, 0.5); }
```

| | verdict |
|---|---|
| ORACLE | exit 1 — `cq controlled lowering: state prep seed does not match the merge incoming under quantum control` |
| SUBJECT | exit 0, stderr 0 B |

`diff` of the emitted gate stream against `r09_u2_copy` (the *one*-object spelling): **identical except
`!dbg` numbering**. `-O1` spells both objects `undef` and nothing downstream can tell them apart.

**Is it unsound? No — but for a different reason than the one written down.** What actually carries the
phi half is that **each rewrite is independently a refinement of an `undef`** (LangRef: any value of the
type may stand in), so the two-object case is licensed exactly as the one-object case is. I checked the
rival reading explicitly: the state-prep circuit says "on the straight-through edge the register holds the
seed"; the rival says "it holds object B" — and since B is `undef`, `0` is a legal value for B, so the two
readings **agree**. There is no F2-style α/β hazard here either: an `undef` seed is a *Constant*, which
means the variable was never written, which means the prepped register can never be the condition's own
live register (that would be an `Instruction`, and `valueCarriesUndef` is false for every non-`Constant`).
**The undef rule can only ever produce a FRESH prep.** That is a good property and the record should claim
it, because it is the one that rules out the α reading.

**Also re-grounded:** the record keeps `control_inplace_ry_reject_stateprep_undef_incoming.ll` declining by
citing the "both edges" scope. That is the wrong ground. I measured it directly on both binaries (full
stderr sha `0af03bddc2cc` on each): it declines because **its seed is `i32 0`, so the rule never fires at
all** — the phi loop is unreachable without a rewritten seed, since `normalizeUndefRotationSeed` returns
before it on a non-undef seed.

**Severity.** documentation (L7 — an agent-authored precondition that would harden by repetition).
**Fix.** Replace the "one object" paragraph with the per-`undef` refinement argument; add the
"a Constant seed ⇒ a fresh register ⇒ never the condition's own rail, so the F2 α reading cannot arise"
sentence; re-ground the untouched-fixture claim on "the seed is not an undef".

---

## F-U1-3 — the L1 / `specialize` argument, re-derived from source

The brief told me the implementer flagged their own first draft as wrong and "reads just as convincing", so
I did not accept the second draft either. I re-derived it.

**Their claim (1) is TRUE but needs a qualifier.** `SpecializeReject.cpp:47-54`: `Sets.Rotations` is filled
from `taint.ThetaCalls` by **EXACT POINTER** membership (the file says so: *"NEVER name-prefix — C7"*).
So the load-bearing precondition R2 is properly stated as *"`scanBody` rejects every body containing a
theta **that `propagate` collected**"*, not *"containing a theta"*. A theta **clone** minted after the last
full `propagate` — `SwapRouteEmit`'s negated-arm `T->clone()` is the live instance — is **not** in
`ThetaCalls` and is therefore invisible to `scanBody`. For z9t1 this is harmless (a clone of a normalized
call is normalized, and the clone lands in the function being lowered, not in a callee candidate body), but
the sentence as written will be quoted against a different change later.

**There is a stronger ground the record does not use, and on it the whole `specialize` discussion is
unnecessary.** Verified from source:

1. `propagate(M, wd)` is the **FIRST statement** of `run` (`CQLoweringPass.cpp:114`, right after
   `WidthDispatch wd(M)`) and of `runOnFunction` (`:755`). Nothing mutates the module before it.
2. `collectAndSeed` walks **every non-declaration function** (`for (Function &F : M)`, `:474-477`) and calls
   `normalizeUndefRotationSeed(CI)` on **every** theta **unconditionally** — not taint-gated, not
   region-gated.
3. `resolveSources` (and with it `declMatchesPrototype`) runs at `:457`, **before** `collectAndSeed` at
   `:476`, so arity 2 and `paramType(0) == returnType == T` are already proven — `arg_size()` is safe and
   `Constant::getNullValue` is called on one of nine scalar types.

⇒ **"No `@cq_theta_<sfx>` in the module has a whole-value `undef`/`poison` arg-0" holds from before the
first pass stage, and is taint-independent.** It can only be broken by (i) minting an undef — and
`ir-pass/src` contains **ZERO** `UndefValue::get` / `PoisonValue::get` (`grep -rn`, measured) — or (ii)
writing one into arg-0, and the four `setArgOperand(0, …)` sites (`AngleSelectEmit.cpp:541`,
`SwapRouteEmit.cpp:917/948/1469`) each write an SSA value or the pre-validated routed base `Q`, which is a
tainted register. I also checked the other undef-minting route I could think of: `llvm::removeUnreachableBlocks`
(7 sites via `removeUnreachableBlocksChecked`) poisons dead instructions through `DeleteDeadBlock`, but an
unreachable definition cannot dominate a reachable use, so no live theta's arg-0 can acquire one.

**Direct probes.** `s1_specialize_theta.c` / `s2_specialize_int.c` (a theta inside a `noinline` callee):
identical verdicts on both binaries (`s1` declines `cq taint escape: tainted value returned at non-i32
width` on both; `s2` accepts on both, subject with the normalized seed).

**Severity.** documentation. **Fix.** Lead §1 with the unconditional-first-`propagate` invariant; add the
pointer-membership qualifier to claim (1).

---

## F-U1-4 — three record inconsistencies in the closure argument (one I closed for you)

**(a) grep or parse?** `GATES.md` row 34 calls the unswept-remainder measurement **"(grep, not a sweep)"**;
`IMPL_U.md` §6 says it was **"measured by parsing every theta call's arg-0, not by grep"**, and makes a
point of why grep is wrong (`noundef` contains `undef`). One of the two lines is false and a reader cannot
tell which instrument ran. Record hygiene — fix the row.

**(b) the e2e scan's `*_lib.c` exclusion — CLOSED, but it was unstated.** `probes/e2e_stage1_undef_seed_scan.sh`
carries `case "$b" in *_lib.c) return;; esac` and the record says "all 391 `tests/e2e/*.c`". The directory
holds **394**; 22 are `*_lib.c` and **21 of them contain the token `cq_theta`**, so on the record's face 21
theta-bearing TUs were unaudited. I closed it: they do not compile standalone (all `CLANGERR`), and by
textual inspection **every `cq_theta` occurrence in a `*_lib.c` is inside an `#ifdef cq_theta` compile-time
tripwire, not a call**. Nothing is lost. Say so rather than leaving it implicit.

**(c) "carries the trigger token" is not literally a closure.** A seed `ConstantExpr` that the *parser*
folds to `undef`/`poison` would carry no `undef`/`poison` token and would still trigger the rule. I tried to
build one (`c2_no_token_poison.ll`, `i32 add nuw (i32 -1, i32 1)`); LLVM 19 folded it to `i32 0` and both
binaries were byte-identical, so the residual risk looks nil — but the argument should be written as
*measured*, not *proved*.

**Severity.** record hygiene.

---

## F-U1-5 — an unnamed over-decline residual: one intervening instruction kills the phi half

**Claim.** The phi half fires only for a phi that has the theta **directly** as an operand
(`for (User *U : Theta->users())`). One instruction between the theta and the merge and the incoming stays
`undef`, so F1's pointer-identity sub-clause still fails and the module declines. `IMPL_U.md` §8 lists two
residuals (the clause-5 phi-as-seed one, and the `ConstantExpr` one); this third one is not named.

**Probe.** `r11_indirect_merge.c` — u2 with `b1 = !cq_theta(b1, 0.5);`:

| | verdict |
|---|---|
| ORACLE | exit 1 — `cq controlled lowering: control flow under quantum control` |
| SUBJECT | exit 1 — **same string, same anchor, 225 B each** |

Under the owner's 2026-09-11 ruling an over-decline of a program that would lower to a valid circuit is a
defect to file. **Severity.** over-DECLINE. **Fix.** File it (alongside bd `bwsh`); do not widen inside this
increment — chasing instruction operands is the `bwsh` conversation and it owes its own Rule-13 round.

---

## What I attacked and found CLEAN (positive clearance record)

Every row below is two runs, subject vs oracle, on the same stage-1 file.

**1. The headline, verified independently and not taken on the record's word.**
`r12_u5_uninit.c` (the owner's cascade with `_Bool b1;`) vs `r13_u5_init.c` (`_Bool b1 = 0;`) — linked and
run through `libcq_templates.a`+`libcq_runtime.a`:
* oracle DECLINES `r12` (`state prep seed does not match the merge incoming`), subject accepts, 0 B stderr;
* **29 lines = 29 lines, `diff` BYTE-IDENTICAL to the initialized twin**;
* and **byte-identical to the shipped `tests/e2e/slice_control_cascade_two_bools.expected.log`**;
* STRICT stage 2b: `8 rail mint(s) of which 6 left allocated, 2 cqrt_free site(s): 2 verified, 0 violation(s), 0 unproven`.
Same for `r09_u2_copy` vs `r10_u2_init_twin` (gate stream identical modulo `!dbg`; 2b `1 verified, 0/0`).
That is the strongest instrument available to me and it says the new ACCEPT gets the circuit the
already-Rule-13-cleared initialized program gets — **read off the stream, not the exit code**: the negated
prep by additivity (`ry_i1(h2,.5)`, `ry_i1_controlled(h0,h2,−.5)`), `h0` read only as a CNOT control and
never bracketed or freed, the two `cqrt_x` on the ancilla `h2` whose `x⊕x=0` return makes its free a
proven-|0⟩ one.

**2. The φ-incoming widening — 8 probes, no over-accept.** `r01_two_objects.c` / `r02_seed_undef_other_init.c`
(classical-condition mux — identical declines, 229 B / 238 B); `h1_loop_header_phi.ll` (loop-header phi,
preheader `undef`, latch = the theta — identical declines); `h2_three_incoming.ll` (a 3-incoming phi, one
`undef`); `h3_undef_on_arm_edge.ll` (the `undef` on the ARM edge, inverting the F1 shape);
`h4_two_phi_users.ll` (the theta feeding TWO phis, the second in an unrelated merge) — **all four identical
on both binaries**. Note a self-limiting property I verified in the source and which the record does not
state: the phi loop runs **only after** the seed rewrite, so a CHAINED theta (arg-0 an `Instruction`) never
reaches it at all — which is why a loop-carried rail's header phi cannot be touched.

**3. `isa<UndefValue>` vs `valueCarriesUndef`, both directions.** `PoisonValue` derives from `UndefValue`,
so one `isa` covers both spellings (`lowering_accept_poison_theta_seed_zero.ll` green on the subject).
`c1_constexpr_leaf.ll` — a `ptrtoint (gep … i64 undef …)` seed — **IR identical on both binaries**; the
emitted slot keeps `ptrtoint (ptr @g to i32)`, i.e. the expression is not rewritten. And I checked the
implementer's negative control is not vacuous in the Rule-12(c) sense: `llvm-as | llvm-dis` on
`control_inplace_ry_reject_stateprep_constexpr_undef_seed.ll` shows the seed
`ptrtoint (ptr getelementptr inbounds ([4 x i32], ptr @g, i64 undef, i64 1) to i32)` **survives the parse
with its `undef` leaf intact**.

**4. All nine reachable widths, measured — the record fixtures three.** `r07_widths.c` (i8/i16/i64/float),
`r18_fp80_half.c` (`x86_fp80 0xK00000000000000000000`), `w1_half.ll` (`half 0xH0000`), plus i1/i32/double
from the other probes. Every one mints the right zero from the operand's own type.

**5. arg-1, the ANGLE, is untouched in isolation (Rule 3).** `r03_angle_undef.c`: **IR IDENTICAL** on both
binaries, `cqrt_ry_i1(h, double undef)` preserved. (The composition where it is *not* untouched is F-U1-1.)

**6. SOURCE-only.** `r04_chained.c`: one alloc, two `cqrt_ry` on the same handle, oracle `alloc_i1(i1 undef)`
→ subject `alloc_i1(i1 false)`, chain otherwise unchanged.

**7. Clauses 3 and 4.** Every accept I produced has **0 bytes of stderr** — no warning, no note, exit 0.
`r05_seed_and_measure.c` (an undef seed **and** a never-quantum undef measure in one function): both
binaries decline with the identical 264 B message. And a structural argument the record can use: a phi that
carries a theta's result is *always* tainted, so a phi the rule touches can never be measured as a
never-quantum value — clause 4 is safe by construction, not by luck. Direct two-binary runs with a
**full-stderr sha** on `lowering_reject_measure_undef_operand`, `lowering_reject_undef_literal_paired_rz_angle`,
`lowering_reject_undef_literal_paired_undef_spelling`,
`control_inplace_ry_reject_stateprep_undef_incoming` and `lowering_accept_undef_literal_single_slot`: **all
five identical between binaries** (`e6e686e0c6bd`, `6aae90a25c28`, `6aae90a25c28`, `0af03bddc2cc`,
`e3b0c44298fc`).

**8. The u1rp move is NOT vacuous (Rule 12(c)).** `control_predmux_reject_selectform_rotation_theta_poison_angle.ll`
is `…_poison_seed.ll` **with the poison moved one slot**, token-for-token otherwise. Its twin now ACCEPTS.
So deleting the `Call->args()` scan flips this file, exactly as claimed — the arm-kill holds, and the pin
is live.

**9. All nine new/rewritten fixtures are green on the subject binary**, checked by running `cq-opt` directly
and feeding the output to `FileCheck` with the **same `--implicit-check-not` flags each RUN line carries**
(the harness bug the implementer records in §9 — I did not repeat it): default prefix and `STREAM` prefix
both pass on `lowering_accept_undef_theta_seed_{zero,widths,chained,phi_residual}`,
`lowering_accept_poison_theta_seed_zero`, `control_accept_undef_theta_seed_stateprep`,
`control_inplace_ry_reject_stateprep_{undef,poison}_seed`,
`control_predmux_reject_selectform_rotation_theta_poison_seed`.

**10. The in-loop composition.** `r19_loop_uninit.c` vs `r20_loop_init.c`: both accept on both binaries;
the subject's uninitialized gate stream is **identical to the initialized twin's**.

---

## What I did NOT examine — stated plainly

* **No build, no ctest, no lit layer.** Forbidden to me and not run. I did not execute `ir-pass-lit`,
  `^e2e-`, `runtime`, `cq-opt-equivalence-full`, `e2e-loop-twin-matrix`, or any twin matrix. Every verdict
  above is a per-probe two-binary measurement, plus direct `FileCheck` on 9 fixtures. **Nothing here is a
  suite result and none of it should be reported as one.**
* **The implementer's own instruments, not re-run:** the 2793-row corpus sweep, the 98-row undef tail, the
  injection matrix (`inject_u.py`, 67 applied / 0 MISSED / 23 N/A), `vacuity.py`. I did not audit
  `inject_u.py`'s `prefixes` fix; I accepted the 67/0/23 at face value, mitigated only by item 9 above.
* **The three new e2e slices**: I read neither their `.c`, their goldens, nor their `CMakeLists.txt`
  registration. Whether `e2e-undef-seed-cascade-twin-identical` is wired correctly is unverified by me — I
  reproduced its *claim* by hand instead (`r12` vs the shipped golden).
* **Shapes never attacked with an undef seed:** the 4.5 `switch` family, depth-2 nests, the 6.5 classical
  call arm, `cq_invert` / `EmitInverse`, `AbortParkEmit`, QRAM/IO, and multi-function modules beyond
  `s1`/`s2`.
* **Track L's rail-bank composition** beyond `r06_array.c` (`_Bool b[2]`). Larger N, and the bounded rail
  array of bd `xdu2`, untouched.
* I did not attempt to bound `-O1` rewrites of the ruled spellings across optimization levels; everything
  was measured at the `-O1` floor.

---

## Round 2: **RECOMMENDED**, narrow

CLAUDE.md's measured hit rate (7.4 break: 13 holes over three rounds, three of them *after* the epic was
closed as cleared; 3qlq C-1: 8 over 6 rounds, two introduced by a fix) says round 1 finding one
safety-direction item is a reason to run round 2, not a reason to stop. Scope it to:

1. **The disposition of F-U1-1** — if fix (a) lands, the fix itself is a new lowering-core edit and owes its
   own review of the *conjunct*, plus the decline fixture and an injection-matrix row.
2. **The shapes I did not attack** with an undef seed: `switch` (4.5), depth-2 nest, the 6.5 classical-call
   arm, and `cq_invert`/`EmitInverse` — the last of these is the one I would put first, because the seed's
   value is the one thing an adjoint has to reproduce.
3. **A second reader on F-U1-3's invariant.** I believe "no theta has a whole-value undef arg-0 after the
   first `propagate`" is airtight, but it is exactly the kind of module-wide claim that the L1 history says
   gets falsified by the one stage nobody enumerated.
