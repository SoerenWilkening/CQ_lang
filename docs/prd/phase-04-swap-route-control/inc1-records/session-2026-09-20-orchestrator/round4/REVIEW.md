# Round 4 — INDEPENDENT Rule-13 adversarial review of bd `11qv` + bd `h1ip` (+ `h7ee` R2-1)

**Subject:** branch `11qv-narrow-carried-handle`, commit `d79bd31a`
("feat(loop): bd 11qv + h1ip — the carried handle at every width, and behind a
runtime trip guard"), reviewed detached-HEAD in an isolated worktree.

**Reviewer:** independent; did not write the change. Reviewed against the diff
`git diff 00c36e93..d79bd31a` read in source, not against the task summary
(Rule 11).

## VERDICT: **FINDINGS** — 1 × P1, 2 × P2, 3 × P3.

The P1 is an **`opt` ABORT (exit 134) on a plain-C program that the ORACLE
refuses with a clean loud diagnostic**, reached through the gate — (P4) — that
was written specifically to prevent exactly that abort.

---

## Binaries — every measurement below is keyed to one of these two

| role | binary | sha-256 |
|---|---|---|
| ORACLE (main checkout `build/`, read-only, never written) | `cq-opt` | `e7bbfd69a9e25d3832373b8418d24239a4ddebf79d75e9e3a9252c254e0192f2` |
| ORACLE | `libCQPass.so` | `84061321f9d6f9747b80a29e55210674d79411ad11c104f582cc76aac4622156` |
| SUBJECT (this worktree `build/`, `d79bd31a`, `cmake --build build -j4`, both targets) | `cq-opt` | `b1f3fd903e62531effc3a156c7ad2532d05a0e8d6a10ac9b29c0a1f6830fa90a` |
| SUBJECT | `libCQPass.so` | `843144f267a39930ba32d7273f8781b857b1b2f25aeacffb34f2ee3861d0d9c5` |

Oracle hash verified against the task statement before any measurement. The
oracle `build/` was never built into or written to.

**Harness null control, run first** (CLAUDE.md L10 — an instrument nobody has
tried to fool is one nobody should trust): `probes/a0_control_no_third.ll` is the
shipped accept shape. SUBJECT `EXIT=0` with a 38-line trace; ORACLE `EXIT=1`
`cq loop lowering: loop-carried tainted value crosses iterations`. The harnesses
(`probes/ll.sh`, `probes/c.sh`, `probes/pass.sh`) refuse an empty input file and
refuse to score ACCEPT on an empty lowered module — the 0-byte passthrough
vacuity trap (bd memory `empty-module-accepts-vacuity-trap`).

---

## Findings

| # | sev | one line | probe |
|---|---|---|---|
| F-1 | **P1** | (P4)'s `cq_`/`cqrt_` PREFIX allowance lets `P.mutateType(i32)` run under a user nothing rewrites → verifier-invalid module → **`opt` exit 134** where the oracle emitted a clean decline | `c1_p4_cqrt_user.ll`, `c2_p4_from_c.c` |
| F-2 | P2 | The promotion whitelists an out-of-loop φ into `PromotedCarriedHandlePhis` on the strength of **one** proved incoming; its other TAINTED incomings are `continue`d with no proof, and `declineClassicalMuxes` then accepts a φ over three distinct quantum registers | `a2_bypass_third_mergerail.ll` (accept), `a1_bypass_third_tainted.ll` (spine backstop) |
| F-3 | P2 | (Z1)/(Z8) admit a GUARD that is **inside an outer loop**: the `cqrt_alloc` is minted once per outer trip and a rolled nested loop nest now lowers, which CLAUDE.md "Loop scope" lists among what declines | `b1_nested_guard.ll`, `b2_nested_from_c.c` |
| F-4 | P3 | The stated safety argument for `taint.HandleWidth[&P]` names a consumer that is **structurally unreachable**; the record IS load-bearing, at a stage neither comment names | `d1_narrow_cast_user.ll` |
| F-5 | P3 | bd `11qv` ships the **first e2e golden in the tree** that pins a literal the source did not write (missing `signext` on narrow classical template/alloc params). Defect class PRE-EXISTING and measured so | `sx_signext.c` + `sx_nosignext.ll`, `sx3_negseed.c`, `sx4_negcmp.c`, `sx6_flat_qminus3.c` |
| F-6 | P3 | (Z3)'s widening from `isIntegerTy(32)` to `isIntegerTy()` admits **i80 and i128** by shape, and `allocFn` RESOLVES both even though the runtime ships neither; only a fence in another file stands between them and a phantom mint | `f1_i128_carried.ll` (not reached — argued, not constructed) |

---

### F-1 — **P1.** (P4)'s prefix allowance reaches `mutateType` and aborts `opt`

**What (P4) claims.** `LoopLowering.cpp`, `promoteLoopCarriedHandleSeeds`:

```cpp
auto *CI = dyn_cast<CallInst>(UI);
Function *CF = CI ? CI->getCalledFunction() : nullptr;
if (CF && (CF->getName().starts_with("cq_") ||
           CF->getName().starts_with("cqrt_")))
  continue;
```

with the comment *"the only untainted users that legally reach here are the `cq_*`
SINK calls, whose own lowering stage rewrites the operand to the `i32` handle"*,
and the stated purpose *"A user that is NOT rewritten keeps reading a value whose
type moved under it, and the module ends the pass VERIFIER-INVALID: `opt` ABORTS
(exit 134), which is a crash, not a decline — and Rule 1 says the answer to
'unsure' is a LOUD DECLINE, never an abort."*

**Why the claim is false.** The prefix set is wrong in three ways and each is a
door:

* `cqrt_*` is the **already-lowered** runtime ABI. **No stage rewrites a
  `cqrt_*` call** — that is the whole point of the family.
* `cq_template_*` also matches `starts_with("cq_")`, is likewise never rewritten,
  and a **hand-written** `cq_template_*` is a recognised input class in this tree
  (`ir-pass/test/lowering_mc_late_fallback_handwritten.ll`).
* `cq_invert_*` matches too and is a Phase-8 handoff that is not built.

Those are **exactly** the three prefixes `declineTaintEscapes` exempts
(`TaintPropagation.cpp:826`: `if (N.starts_with("cqrt_") ||
N.starts_with("cq_template_") || N.starts_with("cq_invert_")) continue;`). So any
call that survives the escape guard through that exemption ALSO passes (P4) — the
two lists are the same list, and the second one trusts what the first one merely
tolerated.

**Minimal probe (plain C, `clang -O1`, no hand-written IR) — `probes/c2_p4_from_c.c`:**

```c
#include "CQ.h"
extern void cqrt_probe_sink(short);
int main(void) {
    short a = 5;
    bool b0[3];
    for (int i = 0; i < 3; ++i) {
        b0[i] = cq_theta(b0[i], 0.5);
        if (b0[i]) a -= 3;
    }
    cqrt_probe_sink(a);
    return (int)cq_measure(a);
}
```

Commands and verbatim output:

```
$ ./c.sh probes/c2_p4_from_c.c --oracle
### c2_p4_from_c  [--oracle ]  bin=e7bbfd69a9e25d38
EXIT=1
--- stderr ---
error: <unknown>:0:0: in function main i32 (): cq loop lowering: loop-carried tainted value crosses iterations

$ ./c.sh probes/c2_p4_from_c.c
### c2_p4_from_c  [subject ]  bin=b1f3fd903e62531e
EXIT=134
--- stderr ---
Call parameter type does not match function signature!
  %out = call i32 @cqrt_alloc_i16(i16 0)
 i16  tail call void @cqrt_probe_sink(i32 noundef signext %out) #3
LLVM ERROR: Broken module found, compilation aborted!
```

**The isolating probe that names the φ itself — `probes/c1_p4_cqrt_user.ll`** (one
edit from `probes/c0_p4_control.ll`, which accepts cleanly on the subject:
`EXIT=0`, 38-line trace, STRICT 2b `1 verified, 0 violation(s), 0 unproven`):

```
$ ./ll.sh probes/c1_p4_cqrt_user.ll --oracle
EXIT=1
error: <unknown>:0:0: in function main i32 (i32): cq loop lowering: loop-carried tainted value crosses iterations

$ ./ll.sh probes/c1_p4_cqrt_user.ll
### c1_p4_cqrt_user  [subject]  bin=b1f3fd903e62531e
EXIT=134
--- stderr ---
Call parameter type does not match function signature!
  %a = phi i32 [ %cq.carried, %entry ], [ %out, %head ]
 i16  call void @cqrt_sink_i16(i32 %a)
LLVM ERROR: Broken module found, compilation aborted!
...
1.	Running pass "VerifierPass" on module "probes/c1_p4_cqrt_user.ll"
```

The broken operand printed by the verifier is `%a` — **the header φ that
`P.mutateType(Type::getInt32Ty(...))` retyped**. The proximate cause is this
increment's own mutation, admitted by this increment's own gate.

**Why this is P1 and not a curiosity.** Rule 1: *"the answer to 'unsure' is a
loud decline, never an abort."* On this module the oracle is a well-behaved
compiler that says something true and exits 1; the subject crashes with an LLVM
internal error and a stack dump. Rule 12's whole discipline (a decline fixture
mirroring the diagnostic character-for-character) is unavailable for a shape that
produces no diagnostic at all.

**HONEST CAVEAT, MEASURED, AND IT MUST BE READ WITH THE FINDING.** The *sibling*
class — a narrow **emitter-minted rail** (not a φ) handed to a prefix-exempt
external — already aborts on the **ORACLE**. `probes/c3_flat_i16_twin.c` (the
loop-free i16 twin of c2):

```
$ ./c.sh probes/c3_flat_i16_twin.c --oracle       ->  EXIT=134  (same message)
$ ./c.sh probes/c3_flat_i16_twin.c                ->  EXIT=134  (same message)
```

So the abort **class** is pre-existing. What bd `11qv` adds is the φ-retype door
and, with it, a population: `c1`/`c2` are modules the oracle refused *cleanly* and
the subject *crashes* on. CLAUDE.md's own wording applies verbatim — *"pre-existing"
is true of the defect and FALSE of its population.* (P4) exists precisely to close
the φ door and does not.

**Fix shape (not a request for a decline — Rule 17).** (P4) should enumerate the
callees whose lowering stage demonstrably rewrites the operand — `cq_theta_*`
(RotationLowering) and `cq_measure_*` (MeasureLowering); `cq_phi` has no register
operand — rather than trust a name prefix. Red/green pair to write with it: RED
`c1_p4_cqrt_user.ll` (must SKIP the promotion and then decline at
`declineClassicalMuxes`), GREEN `c0_p4_control.ll` (unchanged accept), plus a
`cq_template_`-spelled isolating control.

---

### F-2 — **P2.** A φ is whitelisted on one incoming; its other tainted incomings are never proved

**Mechanism.** In `loopCarriedHandlePhi` the bypass walk is:

```cpp
for (unsigned i = 0, e = OP->getNumIncomingValues(); i != e; ++i) {
  Value *In = OP->getIncomingValue(i);
  if (In == V || taint.Tainted.count(In))
    continue;                                   // <-- NO PROOF AT ALL
  if (In != Pf.Seed || !Pf.GuardBB || OP->getIncomingBlock(i) != Pf.GuardBB)
    return std::nullopt;
  Pf.BypassIncomings.emplace_back(OP, i);
}
```

and in the promotion:

```cpp
for (auto &BI : Pf->BypassIncomings) {
  BI.first->setIncomingValue(BI.second, H);
  taint.PromotedCarriedHandlePhis.insert(BI.first);   // <-- the WHOLE phi
}
```

The `taint.Tainted.count(In) → continue` line is pre-existing and was harmless
while the φ was never whitelisted. It is not harmless now: the entry inserted is
the **φ**, not the incoming, and `declineClassicalMuxes` accepts on that entry:

```cpp
if (taint.PromotedCarriedHandlePhis.count(Phi))
  continue;
diagnoseEscape(Phi, kMsgClassicalPhi);
```

`declineClassicalMuxes`' own comment says what it is refusing and why: *"every
other live tainted-reading phi — mixed handle/literal, **distinct registers**,
**derived fresh-rail incomings**, **cross-block chains**, loop-reachable merges —
is declined: its record/uncompute story is path-dependent and unproven."* Under
F-2 a φ over distinct registers from a cross-block chain is admitted, and the
admission argument covers exactly one of its three edges.

**Probe — `probes/a2_bypass_third_mergerail.ll`** (one edit from
`a0_control_no_third.ll`: a third predecessor carrying an unrelated 4.4 merge rail):

```
$ ./pass.sh probes/a2_bypass_third_mergerail.ll --oracle
EXIT=1
error: ... cq loop lowering: loop-carried tainted value crosses iterations

$ ./pass.sh probes/a2_bypass_third_mergerail.ll
### a2_bypass_third_mergerail [subject] bin=b1f3fd903e62531e
EXIT=0
```

Emitted (elided), STRICT 2b `9 rail mint(s) of which 7 left allocated, 1 template
rail mint(s) of which 1 left dirty, 2 cqrt_free site(s): 2 verified, 0
violation(s), 0 unproven`:

```llvm
exit:  ; preds = %head, %g, %qside
  %r  = phi i32 [ %out, %qside ], [ %cq.carried, %g ], [ %out3, %head ]
  %m5 = call i32 @cqrt_measure_i32(i32 %r)
```

**Why P2 and not P1.** I could not exhibit a wrong unitary on this probe: all
three incomings are `i32` handles, exactly one path is live per execution, which
one is a classical fact, and the measure lands on the live register. The finding
is that the **grant does not cover what it admits**, not that this particular
circuit is wrong.

**The backstop that exists is incidental, and that is the part to read twice.**
`probes/a1_bypass_third_tainted.ll` differs from `a2` only in *which* tainted
value sits on the third edge (a bare `cq_theta` handle instead of a merge rail).
It gets past `declineClassicalMuxes` identically and is stopped four stages later
by the uncompute spine:

```
$ ./ll.sh probes/a1_bypass_third_tainted.ll
EXIT=1
error: ... cq uncompute: tainted handle reaches an unrecognized user
```

A fence that fires on one spelling of a class and not on a one-operand neighbour
is not a fence for that class (CLAUDE.md L4).

**Fix shape.** Either require every non-`V` incoming of `OP` to be a recorded
bypass incoming before inserting `OP` into `PromotedCarriedHandlePhis`, or
whitelist at incoming granularity rather than at φ granularity.

---

### F-3 — **P2.** The "guard" may be inside an outer loop; a rolled nested nest now lowers

Nothing in the new code requires `GuardBB` to be outside every enclosing loop, or
its other successor to leave the loop nest:

```cpp
if (Pre->getTerminator()->getNumSuccessors() > 1) {
  Pf.GuardBB = Pre;
} else if (BasicBlock *UP = Pre->getUniquePredecessor()) {
  if (auto *GB = dyn_cast<BranchInst>(UP->getTerminator()))
    if (GB->isConditional() && (GB->getSuccessor(0) == Pre || GB->getSuccessor(1) == Pre))
      Pf.GuardBB = UP;
}
```

and `promoteLoopCarriedHandleSeeds` iterates `LI.getLoopsInPreorder()`, i.e. inner
loops of a nest included.

**Probe — `probes/b1_nested_guard.ll`** (the inner loop's guard IS the outer
header):

```
$ ./pass.sh probes/b1_nested_guard.ll --oracle
EXIT=1
error: ... cq loop lowering: loop-carried tainted value crosses iterations

$ ./pass.sh probes/b1_nested_guard.ll
EXIT=0
```

Emitted:

```llvm
ohead:                          ; preds = %olatch, %entry     <-- OUTER LOOP HEADER
  %j = phi i32 [ 0, %entry ], [ %jnext, %olatch ]
  %guard = icmp sgt i32 %n, 0
  %cq.carried = call i32 @cqrt_alloc_i32(i32 5)               <-- MINTED PER OUTER TRIP
  br i1 %guard, label %ph, label %olatch
...
olatch:                         ; preds = %iexit, %ohead
  %r = phi i32 [ %cq.carried, %ohead ], [ %out3, %iexit ]
  %m = call i32 @cqrt_measure_i32(i32 %r)
```

CLAUDE.md "CORRECTNESS RISK §2 — Loop scope" lists *"Irreducible cycles,
multi-latch and **nested loops**"* among what declines. The increment's records
(`IMPL_H1IP.md`, `IMPL_11QV.md`) do not scope, measure or fixture a nested nest.

**Why P2 and not P1.** The emitted circuit looks right: each outer trip mints a
fresh `|5⟩`, runs the inner loop on it, and measures a fresh rail. The cost is one
extra left-allocated rail per outer trip, which Rule 6 accepts in the
qubits-not-scarce regime. The finding is that an **unscoped accept-direction
widening into a declared-out-of-scope shape** landed with no measurement — exactly
the class the project's loop work has repeatedly had to retract.

`probes/b2_nested_from_c.c` is the plain-C spelling: ORACLE `EXIT=1`
(`loop-carried tainted value crosses iterations`), SUBJECT `EXIT=0`, 28 trace
lines, STRICT 2b clean. ⚠ It is **not** a witness for the rolled nested shape —
`clang -O1` unrolls its outer loop, so the emitted module has no nest. Said out
loud so it is not later cited as though it were; `b1` is the witness.

---

### F-4 — **P3.** The `HandleWidth` justification names an unreachable consumer (L7)

Both new comments — (Z3)'s and the promotion's — ground the `taint.HandleWidth[&P]
= Pf->Abi` record on this:

> *"Without that record a Q+Q compare over two retyped `i16` φs would recover
> `i32` from `abiWidthFromType` and mint `cq_template_icmp_<pred>_i32(h,h)` for two
> `i16` registers — a WRONG-WIDTH SYMBOL"* — via `logicalOperandWidth`.

**`logicalOperandWidth` has exactly one caller, `qqSelectLeafWidth`
(`CompareLowering.cpp:344,366-367`), and every caller of THAT runs inside
`detectControlRegions` / `lowerControlRegions`** (`SelectClassify`,
`SelectMergeEmit`, `mintCondNetwork`, `compareFlagMintable`). Both rounds of
control detection and emission finish at `CQLoweringPass.cpp:616`
(`repropagateControlMerges`); `promoteLoopCarriedHandleSeeds` is at `:766`. **A
retyped φ can never reach `qqSelectLeafWidth`.**

The other Q+Q path, `CompareLowering::rewriteCompare` (the DATA-position compare,
`:509-513`), reads `taint.HandleWidth.lookup` **raw** and leaves `QqWidth` empty
when the entry is absent, which takes the loud Q+Q bail — *"NEVER default empty ->
i32"*. So a missing record there is a **decline**, not a wrong symbol either.

**The record is nevertheless load-bearing, at a stage neither comment names**:
`lowerOps`' up-front cast capture, `OpcodeLowering.cpp:997`
(`taint.HandleWidth.lookup(Cast->getOperand(0))`). Measured —
`probes/d1_narrow_cast_user.ll` (narrow carried φ with a `sext i16 %a to i32`
user), SUBJECT `EXIT=0`:

```llvm
%h_cast = call i32 @cq_template_sext_i16_to_i32(i32 %a)
declare i32 @cq_template_sext_i16_to_i32(i32)
```

Without the record `Cast->getSrcTy()` reads the laundered `i32` and this would be
`cq_template_sext_i32_to_i32`.

Right conclusion, wrong ground. CLAUDE.md L7 and its 2026-09-14 twist: a
justification that is not corrected at the source comment is re-derived wrong by
the next round. The comment should name `OpcodeLowering.cpp:997` (and say that the
compare paths are structurally unreachable / decline-safe), otherwise a future
widening will "retire" the record on the strength of measuring the compare path
and find nothing.

---

### F-5 — **P3.** The first golden that pins a literal the source did not write

`WidthDispatch::allocFn` and `WidthDispatch::addTemplate` build the callee type
with `FunctionType::get(Handle, {…, Classical}, false)` +
`M.getOrInsertFunction(...)` and attach **no parameter attributes**. The runtime
bodies are compiled from C with `int16_t` / `int8_t` parameters, which clang gives
`signext` and then reads out of the full 32-bit parameter register.

**Measured ABI divergence — `probes/sx.sh`:**

```
== NATIVE C caller (clang emits signext) ==
cq_template_add_i16_hl(h0, -3) -> h0
cq_template_add_i8_hl(h0, -3) -> h1
== the PASS's declaration shape (no signext) ==
cq_template_add_i16_hl(h0, 65533) -> h0
cq_template_add_i8_hl(h0, 253) -> h1
```

**The class is PRE-EXISTING and C-reachable before the diff.** `probes/sx6_flat_qminus3.c`
(`short a = 0; a = cq_theta(a,0.5); a -= 3;`) on the **ORACLE**:

```
cqrt_alloc_i16(0) -> h0
cqrt_ry_i16(h0, 0x1p-1)
cqrt_addc_i16(h0, 65533)
cqrt_measure_i16(h0) -> 0
```

**What this diff adds, measured.** Over all 398 shipped `tests/e2e/*.expected.log`,
only two files contain any narrow (`i1`/`i8`/`i16`) `_hl`/`_lh` template call, and
the **only negative literal in the whole golden corpus** is in the file this
increment adds:

```
$ grep -l "_i8_hl\|_i16_hl\|_i1_hl\|_i8_lh\|_i16_lh\|_i1_lh" tests/e2e/*.expected.log
tests/e2e/slice_libm_real_asinl.expected.log            # literals 0 and 2 — unaffected
tests/e2e/slice_loop_carried_handle_narrow.expected.log # NEW
$ grep -n "add_i16_hl" tests/e2e/slice_loop_carried_handle_narrow.expected.log
7:cq_template_add_i16_hl(h0, 65533) -> h3
...  (3 occurrences; the source wrote `a -= 3`)
```

Rule 2 makes the golden the contract; this one now pins `65533` where the source
wrote `-3`, and `LiteralIntegrity.cpp`'s one invariant is *"an emitted gate's
LITERAL operands must denote the source's value, identically at every site the
lowering copies them to."*

The promotion's **own new emission** hits it too — `probes/sx3_negseed.c`
(`short a = -3;`), SUBJECT `EXIT=0` (the ORACLE refuses the narrow carried handle,
so there is no oracle comparison for this program):

```llvm
%cq.carried = call i32 @cqrt_alloc_i16(i16 -3)     ; IR
```
```
cqrt_alloc_i16(65533) -> h0                        ; what the runtime reads
```

**The door where it changes an ANSWER, newly reachable** — `probes/sx4_negcmp.c`
(`if (a > -3)` inside the carried loop). ORACLE `EXIT=1`
(`cq controlled lowering: iteration-local value read after the loop under quantum
control`); SUBJECT `EXIT=0`:

```llvm
%h_cmp = call i32 @cq_template_icmp_sgt_i16_hl(i32 %9, i16 -3)
```
```
cq_template_icmp_sgt_i16_hl(h0, 65533) -> h1
```

A signed comparison whose classical operand the callee observes as `65533` and
not `-3`.

**Why P3 and not higher.** For `add`/`alloc` at exactly the declared width the
16-bit register state is unchanged (`65533 ≡ -3 mod 2^16`), and the trace runtime
does not compute, so what I demonstrate is a wrong **operand crossing a
cross-TU ABI boundary** (which is UB), not a wrong **answer**. The class is
pre-existing in `WidthDispatch`, untouched by this diff. What is new is the
golden and the newly reachable signed-narrow-compare spelling — and "pre-existing"
is true of the defect and false of its population.

---

### F-6 — **P3.** (Z3) admits i80/i128 by shape; `allocFn` resolves both; only another file's fence stops a phantom mint

(Z3) went from `!P.getType()->isIntegerTy(32)` to `!P.getType()->isIntegerTy()`
plus `Pf.Abi = abiWidthFromType(...)` non-empty. `abiWidthFromType`
(`OpcodeSupport.cpp:236-249`) maps **80 → `"i80"`** and **128 → `"i128"`**, and
`typeForAbiWidth` (`WidthDispatch.cpp:57-59`) knows both — so
`WidthDispatch::allocFn("i128")` **returns a valid callee for
`@cqrt_alloc_i128`**, a symbol the runtime does not ship (the 7 allocators are
i1/i8/i16/i32/i64 + f32/f64, plus f16/f80). (P2) checks only `if (!Alloc) continue;`
and therefore does not refuse it.

What actually stands in the way is (P1)'s `taint.ControlOwnedRails` requirement
plus `widthHasReversibleCopy`'s `b <= 64` fence in the merge emitters, i.e. a
fence in a different file that neither (Z3) nor (P2) says it is relying on. I
could **not** construct a reaching module (`probes/f1_i128_carried.ll` dies
earlier — there is no i128 theta/measure suffix), so this is argued, not measured,
and filed at P3 accordingly.

Cheap hardening: make (P2) ask `widthHasReversibleCopy(Pf->Abi)` (or an explicit
in-surface width list) rather than only `allocFn != null`, so the phantom-mint
fence is local to the clause that needs it.

---

## WHAT I ATTACKED AND DID NOT FIND

1. **(Z8)'s pointer-identity on the SEED — the F1 MANUFACTURED-IDENTITY shape
   (the task's priority 1).** Attacked by construction and **not found**, and the
   reason is narrower than the author's argument: the bypass walk only visits φs
   that USE `&P` or `LatV`. A coincidentally-equal seed constant belonging to a
   *different* C object can therefore only be rewritten if that φ **also reads the
   loop variable** — in which case, on the bypass edge, the two objects hold the
   same value by construction and `H` holds exactly that value. A φ for a
   genuinely unrelated variable (`int a = 5, t = 5;` with `t` not derived from the
   loop) is never a user of `&P`/`LatV` and is never touched. Verified by reading
   the walk and by failing to build a counterexample.
   ⚠ The three-incoming case the task asked about **does** slip through — but as
   F-2 (the unproved *tainted* incoming), not as a seed-identity defect. A third
   *untainted* incoming either is not `Pf.Seed` or does not arrive from `GuardBB`,
   and both return `std::nullopt`.
2. **Dominance of the hoisted `cqrt_alloc`.** `H` is minted at
   `GuardBB->getTerminator()`. For the header φ: with a preheader, `GuardBB` is the
   preheader's *unique* predecessor and therefore dominates it; without one,
   `GuardBB == Pre`. For each bypass φ: `GuardBB` is by construction the incoming
   block, and `H` precedes its terminator. (P3)'s `DT.dominates(SI, PreTerm)` is
   asked about the *guard's* terminator when `BypassIncomings` is non-empty, which
   correctly refuses a seed defined in the bypassed preheader. No defect found.
3. **The guard's other successor re-entering the loop.** Cannot happen: the header
   has a single external predecessor (checked in both the preheader and
   no-preheader paths), and a preheader with two predecessors fails
   `getUniquePredecessor()`.
4. **`freeze` as an unrewritten (P4) user** — `probes/c4_freeze_user.ll`: SUBJECT
   `EXIT=0`, the `freeze` is gone from the lowered module. No abort.
5. **Rule 8 / bd `s82e` on the guarded shape — a trailing non-diagonal gate.**
   `probes/e1_guard_postrot_rolled.c` (trailing `cq_theta` on the carried
   register): SUBJECT `EXIT=1` `cq controlled lowering: control flow under quantum
   control`; ORACLE `EXIT=1` `loop-carried tainted value crosses iterations`.
   `probes/e2_guard_condrot_rolled.c` (trailing gate on a register the condition
   reads): **identical** decline on both binaries (`cq taint escape: tainted value
   stored to memory`). The author's claim that the rolled form is strictly more
   conservative here **holds on the two spellings I could build**. I did *not*
   find a spelling where the rolled guarded form accepts with a trailing
   non-diagonal gate.
6. **L1 (round-1 vs round-2).** `promoteLoopCarriedHandleSeeds` is at
   `CQLoweringPass.cpp:766`/`:1267`, i.e. **after** the `repropagateControlMerges`
   fixpoint at `:616`/`:1219`, so the RECORD half of the predicate is asked at
   final taint in both entry points. The two round-1 GRANT sites
   (`iterationLocalTaintEscape` clause (c3) and `invariantRegisterRootsImpl`
   clause (i)) do now grant for more φs (narrow widths, guarded loops), and their
   backstop is `declineClassicalMuxes` one stage later. The residual the file
   itself names — a `use_empty()` φ, which `declineClassicalMuxes` skips — is
   **not made worse by (P0)**: that guard skipped dead φs before and after, so
   (P0) removes a mutation without removing a backstop. I did not construct a
   module in which a round-1 grant on a dead φ produces a wrong in-body discharge;
   `clang -O1` deletes a dead φ, so it is IR-only, and I ran out of budget before
   building it by hand. **Recorded as NOT ATTACKED TO COMPLETION, not as cleared.**
7. **Narrow-width circuit correctness.** `probes/t16_rolled.c` vs
   `probes/t32_rolled.c` (the `short`/`int` twin pair): the two traces are
   identical symbol-for-symbol modulo the width token, with the sole exception of
   the F-5 literal rendering (`65533` vs `-3`). `probes/t16_rolled.c` vs
   `probes/t16_unrolled.c` diverges only at trip 1 in the documented
   rolled-vs-flat way (`-O1` const-folds the flat twin's trip-1 arms to `2`/`5`);
   trips 2 and 3 match. `probes/w1_bool_seed_true.c` (a `bool` accumulator) lowers
   at the `i8` `_Bool` wire (`cqrt_alloc_i8`, `cqrt_copy_i8_controlled`)
   consistently. No width defect found in the retype itself.
8. **The shipped fixtures for this family.** `lit ir-pass/test --filter
   'loop_carried'` on the SUBJECT: **13 passed, 0 failed** (0.68 s). Stated with
   its denominator: 13 of 2108 discovered tests, not a suite run.

---

## WHAT I DID NOT DO

* **No full `ctest -j6`.** The orchestrator owns that gate and is running it. I
  therefore make **no claim** about the suite, the e2e layer, the twin matrix, or
  `cq-opt-equivalence`. The only test-layer statement above is the 13-fixture
  filtered `lit` run, and it is labelled as sampled.
* **No corpus A/B** over the 2106 `ir-pass/test/*.ll` fixtures. I did not verify
  the author's claim that **(P4) has 0 movers over 2106 fixtures**; I attacked the
  gap (P4) *admits* instead, and found F-1 there. The 0-mover claim, if true, says
  (P4) is vacuous over the shipped corpus — which is consistent with F-1, not a
  refutation of it.
* **No rolled-vs-unrolled twin-matrix run** and no `e2e-loop-twin-matrix`
  invocation.
* **No mutation/injection matrix** over the new conjuncts (Z1/Z3/Z8/P0/P4). I
  measured (P4) by attacking it, not by deleting it.
* **No statevector reasoning beyond the analytic arguments above** (owner decision
  2026-06-10; there is no simulator).
* **F-6 is argued, not measured** — I could not construct a module that reaches
  `allocFn("i128")` through (P1).
* **Item 6 above (the L1 dead-φ grant residual) is not attacked to completion.**
* I did not attack: a multi-latch or irreducible body against the new (Z1)
  single-external-predecessor path; `cq_template_*` / `cq_invert_*` as the (P4)
  spelling (argued from the same prefix test that F-1 measures with `cqrt_*`); the
  interaction of the bypass rewrite with an OUTER-LOOP HEADER φ (attempted and
  found unconstructible under the two-incoming / all-non-V-must-be-bypass
  constraints, but I do not claim it is impossible).

---

## Suggested disposition

* **F-1 must not ship as is.** It is an abort where the oracle declines cleanly,
  through the gate written to prevent it, on a plain-C module.
* **F-2 and F-3** are accept-direction widenings whose granting arguments do not
  cover what they admit; each wants a conjunct and a red/green pair before the
  landing, or an explicit owner ruling that the widening is intended.
* **F-4** is a source-comment correction that must land **in the same change**
  (CLAUDE.md L7's 2026-09-14 twist: a record correction not applied to the source
  is not a correction).
* **F-5** and **F-6** are filings, with **F-5** carrying a concrete question for
  the owner: is `cq_template_add_i16_hl(h0, 65533)` an acceptable golden contract
  for `a -= 3`, or does the narrow-parameter `signext` omission need fixing in
  `WidthDispatch` before any golden pins it?

---

## Probe index (`round4/probes/`)

| file | role | ORACLE | SUBJECT |
|---|---|---|---|
| `a0_control_no_third.ll` | harness null control / shipped accept shape | DECLINE (crosses iterations) | ACCEPT, 38 lines |
| `a1_bypass_third_tainted.ll` | F-2, third incoming = bare theta handle | DECLINE | DECLINE at the uncompute spine |
| `a2_bypass_third_mergerail.ll` | **F-2 witness** | DECLINE | **ACCEPT** |
| `b1_nested_guard.ll` | **F-3 witness** (rolled nest) | DECLINE | **ACCEPT** |
| `b2_nested_from_c.c` | F-3, plain C (outer loop unrolled — not the nest witness) | DECLINE | ACCEPT |
| `c0_p4_control.ll` | F-1 null control (narrow carried handle, no extra user) | DECLINE | ACCEPT |
| `c1_p4_cqrt_user.ll` | **F-1 witness**, φ named by the verifier | DECLINE (exit 1) | **exit 134** |
| `c2_p4_from_c.c` | **F-1 witness, plain C** | DECLINE (exit 1) | **exit 134** |
| `c2b_p4_from_c_i32.c` | F-1 width control (i32, no retype owed) | ACCEPT | ACCEPT |
| `c3_flat_i16_twin.c` | F-1 pre-existing-class control (loop-free) | exit 134 | exit 134 |
| `c4_freeze_user.ll` | F-1 attack via `freeze` — not found | — | ACCEPT |
| `d1_narrow_cast_user.ll` | **F-4 witness** (`cq_template_sext_i16_to_i32`) | DECLINE | ACCEPT |
| `f1_i128_carried.ll` | F-6 attempt — does not reach | DECLINE | DECLINE (measure prototype) |
| `e1_guard_postrot_{rolled,flat}.c` | Rule-8 trailing gate on the carried register | DECLINE | DECLINE |
| `e2_guard_condrot_rolled.c` | Rule-8 trailing gate on a condition register | DECLINE | DECLINE |
| `sx_signext.c` + `sx_nosignext.ll` | **F-5 ABI control pair** | — | `-3` vs `65533`/`253` |
| `sx3_negseed.c` | F-5, the promotion's own `cqrt_alloc_i16(i16 -3)` | DECLINE | ACCEPT, prints `65533` |
| `sx4_negcmp.c` | F-5, signed narrow compare vs a negative literal | DECLINE | ACCEPT, prints `65533` |
| `sx5_flat_negliteral.c` / `sx6_flat_qminus3.c` | F-5 pre-existing witnesses | ACCEPT (`cqrt_addc_i16(h0, 65533)`) | — |
| `t16_rolled.c` / `t16_unrolled.c` / `t32_rolled.c` | narrow-width correctness twins | DECLINE / ACCEPT / DECLINE | ACCEPT ×3 |
| `w1_bool_seed_true.c` | `bool` carried handle (i8 `_Bool` wire) | DECLINE | ACCEPT |
| `ll.sh` / `c.sh` / `pass.sh` / `sx.sh` | harnesses (each refuses an empty input and an empty lowered module) | — | — |
