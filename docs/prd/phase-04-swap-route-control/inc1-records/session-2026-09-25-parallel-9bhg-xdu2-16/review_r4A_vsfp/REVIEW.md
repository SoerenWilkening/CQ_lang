# Rule-13 round r4A — bd `test_C_libtooling-vsfp` round 4 (`5e38bef2`)

**Scope (this reviewer):** the round-4 changes inside clones and the reader classification:
`rewriteRecordedDeadSlotUse` (the shared rewrite, f061), `buildClone`'s dead-cone deletion and inner-call
inherit (sqjq), `isCopyDestination` / `userProgramReads` (xh17). The fold machinery (tracking seeds,
`simplifySelectInst`, section/absolute) belongs to the concurrent reviewer r4B.

**Binaries (sha-256, first 16):** SUBJECT `cq-opt` `829769d92e05c4e4` (the worktree `build/`, not rebuilt);
ORACLE main `aee8f4f8` `69250feaf68bbe49`; for attribution, the track's own `vsfp/bin/cq-opt.r2`
`46400716e3788c17` and `cq-opt.r3` `3cb890ef25187b4b`. No private build was needed.

**Method:** hand-written IR and multi-TU C probes, each lowered, run through stage 2b STRICT, linked
(templates before runtime), and its trace compared with a twin. Twins are the **DAE twin** (the same program
with the dead parameter removed by hand, so it still goes through specialization — the fair twin for a
clone with a tainted return, whose Bennett copy-out never matches a fully inlined twin) or, for r3A's IR
probes, the **INL twin** (LLVM's inliner + instcombine/simplifycfg/adce, the track's recipe). All rows are
re-run by `probes/tools/results.sh` (bash; output `probes/results/results.txt`). Comparator controls: `N2`
and `f2b` report TRACE-DIFF (the comparator is not vacuous), and every compared trace has a non-zero line
count, printed with it.

## Verdict: **NOT-CLEAR**

One P1 (F-YA-1): a plain-C program compiles at `opt` exit 0 with clean stderr, clean verifier and stage 2b
STRICT clean, and the compiled executable **SIGSEGVs**. The ORACLE compiles it correctly. Round 3 introduced
the defect and round 4 did not fix it. Round 4's new inner-call inherit **extends it into clone bodies**. It
is not a wrong unitary, but it is a silent miscompile of the classical ABI with every gate green.

Everything I attacked in round 4's own claims held: sqjq, f061 and xh17 are fixed as described, on the r3A
spellings and on 8 new nested spellings (below).

## Findings

### F-YA-1 — P1 — the neutralising rewrite nulls a `byval` / `nonnull` POINTER slot (bd `test_C_libtooling-91k9`)

`rewriteRecordedDeadSlotUse` rewrites **every** recorded-dead slot to
`Constant::getNullValue(<param type>)` and strips only `range` / `nofpclass`. The record
(`deadParamMask`) covers **every** parameter, pointer parameters included. The pre-`specialize()` drop that
the header comments say it mirrors ("the drop's rewrite", "the constraint DAE strips too") is narrower on
purpose (`SpecializeDetect.cpp` `dropEligibleParam` / `dropEligibleParamAttrs`). It never rewrites a
pointer ("scope: a pointer is never rewritten"), a `byval`/`inalloca`/`preallocated` slot, or a slot
carrying any attribute outside `noundef/signext/zeroext/inreg/range/nofpclass`. Such a slot is "left alone
for the post-`specialize()` backstop". That backstop has been a rewrite since round 3, and it applies none
of those conditions. DAE also strips the whole UB-implying set, not just two attributes. So the
justification is L7's shape: a comparison with a rule that is stricter than the code it is cited for.

**Repro** (`probes/csrc/bv.c` + `bv.lib.c`, stage-1 `bv.s1.ll`):
```c
struct Big { int x[8]; };
int h(int a, struct Big s) { return a * 3; }              /* lib TU */
... int q = cq_theta(m & 7, .5); int r = h(q, b); return cq_measure(r) + b.x[0];
```
SUBJECT: `opt` exit 0, stderr clean, 2b `1 verified, 0 violation(s), 0 unproven`, lowered call
`call i32 @__cq_q_h_01(i32 noundef %h, ptr noundef nonnull byval(%struct.Big) align 8 null)`. The program
prints 2 trace lines and dies with **rc 139** (the call site's byval copy reads address 0).
ORACLE and round 2: rc 5, 8 lines. Round 3: rc 139. The defect was **INTRODUCED by round 3**
(bd `tzfa`'s neutralisation); round 4 did not fix it.

**Round 4's extension** (`probes/csrc/bvn2.c`, `h(a, s)` passes its byval `s` to `g`): round 4's new
direct-parameter inherit in `buildClone` also nulls the **inner** call:
`@__cq_q_g_01(i32 noundef %h_op, ptr noundef nonnull byval(%struct.Big) align 8 null)`. Round 3 left `%1`
at that call. The result is rc 139 on round 3 and on the SUBJECT, and rc 5 on round 2 and the ORACLE.

**Non-byval variant** (`probes/csrc/pn.c`, `int p[static 4]`): the program runs, but the lowered call is
`ptr noundef nonnull null` into a parameter declared `align 4 dereferenceable(16)`. That is immediate UB in
the emitted IR. It is harmless only because stage 3 links at `-O0`.

**Why no gate saw it:** the verifier does not check `nonnull`/`byval` against a constant. Stage 2b sees
rails, not pointers. The phantom-read decline asks `isQuantumCallerValue`, which is false for a classical
pointer, so the rewrite is silent. The rewrite also buys nothing for such a slot: a classical pointer that
nobody reads has no rail, no consumer set and no spine.

**Fix direction:** apply the drop's eligibility inside the one rewrite. Do not rewrite a non-integer/fp
slot or a pass-pointee-by-value slot, and strip `AttributeFuncs::getUBImplyingAttributes()` where it does
rewrite. Correct the three comments that cite "the drop's rewrite" / "the constraint DAE strips too".
Red-green: `bv.c` and `bvn2.c` as e2e slices (the run's rc and trace must equal the twin's), plus an IR
fixture `CHECK-NOT: byval{{.*}}null` on both call sites.

### F-YA-2 — P3, PRE-EXISTING — the inherit covers only values rooted at a DEAD parameter (bd `test_C_libtooling-cpac`)

`buildClone` seeds the `clone-dead-slot` deletion only with the users of dead parameters. Take
`h(a,b){ t = a*5; r0 = g(t,b); return r0 + a; }`, where `g`'s slot 0 is recorded dead. Because `a` is
live, `t` is not a seed. It is lowered to `cq_template_mul_i32_hl`, reversed and freed by `h`'s Bennett wrap,
and `g` receives its handle (`probes/src/N2.ll`). The unitary is unchanged (a compute plus uncompute on a
borrowed input; 2b `5 verified`). The trace is 26 lines against the DAE twin's 23. The ORACLE emits the
byte-identical stream, so this is pre-existing and not an h0-class hazard (`t` reads a live parameter).
The "inner call inherits the dead slot" wording is true only of a dead parameter's cone. The fix is to
also seed with every operand an inner clone call passes in a recorded-dead slot.

### F-YA-3 — P3 — comment accuracy and a name-keyed predicate

- `DeadValueLiveness.h`: "`buildClone` … only deletes". Step 3 also **rewrites** operands of live calls
  (the inherit). The conclusion (no select, no taint growth, no adjudication owed) still holds, because
  a rewrite to a constant shrinks and never grows.
- `isCopyDestination` decides "construction" from the **callee name prefix** `cqrt_copy_` plus the last
  argument. It is sound today by enumeration. Every emitter rail that exists at `resolvePhantomCloneArgReads`
  time is built by `cqrt_copy_<W>[_controlled]` with the destination last (`SelectMergeEmit`,
  `ClassicalCallArmEmit`, `SwitchValueEmit` preload and controlled copies, `SwitchDataMuxEmit`, the
  `IOSinkLowering` value mux). `BreakReversePlay`'s `copyFn(R, Out)` is minted after this point, in
  `lowerBreakReversePlay`. The tape-write and abort-park `OutputRails` have no users. The accept-direction
  relaxation (round 3 counted **no** runtime use of an emitter rail as a read; round 4 counts every
  non-destination use) is therefore sound only while no emitter builds a user-visible rail with
  `cqrt_cswap` / `cqrt_cnot` / `cqrt_toffoli` / `cqrt_x`. That condition should be written into the
  function's comment as a retirement trigger (L8). The decline-direction change for non-emitter values is
  safe by construction.

## The attack list, item by item

1. **Inner clone calls receiving 0.**
   - Cached clone reused from three contexts: top level, via `h1` (dead instruction) and via `h2` (dead
     parameter passed straight through) (`N3`). TRACE-IDENT with the DAE twin, 2b `5 verified`.
   - Inner tainted-return clone with `ensureTwin`: `@__cq_q_g_11_unc(i32 %r, i32 0, i32 %b)`. The twin
     is synthesised from the already-pruned inner body, and the outer wrap's `_unc` call copies the
     rewritten operand (`N1`, TRACE-IDENT).
   - Three levels, `main → k → h → g`, with `k` passing a derived value and `h` passing its parameter
     straight through (`N5`, TRACE-IDENT).
   - The cached body cannot "assume 0": the slot is unread in the body, and every caller's record is keyed
     on the clone itself (`isRecordedDeadSlot` reads `SpecDeadArgMask[Callee]`). A caller that passes a
     live value in that slot (`N2`) is harmless.
   - An fp inner call REBUILT by `retargetSite` gets an `i32 0` in the rebuilt call's slot (`N7`, `N8`,
     TRACE-IDENT). An fp dead slot with an integer return also holds (`N4`, TRACE-IDENT).
   - Recursion: not constructed (see below).
2. **The dead-cone deletion.** No non-TaintSet container holds a clone-body instruction at that point.
   `TaintedCloneCalls` members are clone calls, and those are liveness roots
   (`SpecHandleArgMask[Callee]`), never deleted. `InnerCalls` is dead after the drain loop. The fp
   `HandleWidth` records are keyed on parameters and on rebuilt inner calls (both roots).
   `ScrubbedByReturnTaint` and the rest of `cloneTaint` are `WeakVH`/`ScrubMap`. The clone is one block
   (`lowerCloneControl` returns false on `Clone.size() != 1`), so the arm fold cannot fire. Any live user
   of a dead instruction must reach it through a recorded-dead call slot, the only edge `FunctionLiveness`
   skips, so step 3's "can only be such a slot" holds.
3. **`isCopyDestination`.** See F-YA-3 for the enumeration. The `cq_template_*_inv/_unc`, `cqrt_addc` and
   `cqrt_ry_*_controlled` families either do not yet exist when the reader question is asked (`lowerOps`
   runs after it), or are not built on emitter rails. No over-accept was constructible. An `i1` `%out` used
   as a later select's bare condition (`X1`) is refused at an earlier wall (`floating-point quantum
   argument … has no reversible copy` on an `i1` clone argument; the twin declines too), so it is not
   exercised.
4. **Twin identity.** r3A's 8 sqjq spellings (`a1_{add,deadop,icmp,sext,xorself}`, `a2_chain`,
   `a3_width`, `g1c` with `-g`) and `n5_nested` are all TRACE-IDENT with INL. So are f061's `fpfloatb`,
   `f1b` and `fplongdb`. `f2b` is TRACE-DIFF, the known Bennett copy-out, as the track records. xh17's
   `e2b` is TRACE-IDENT. New nested spellings `N1`, `N3`, `N4`, `N5`, `N7`, `N8` are TRACE-IDENT with their
   DAE twins, with 2b STRICT and 0 violations throughout. The C-level nested spelling `cn.c` (a
   volatile-fold empty arm in `g`, dead `a*5+1` in `h`), with and without `-g`, is TRACE-IDENT with its
   DAE twin `cnD.c`. The ORACLE computes the dead cone there: 33 lines against 27.

## What I did NOT attack

- **Recursion.** I did not construct a clone calling itself with the dead slot. The body must be one block
  after the flatten, so an unconditional self-call cannot terminate, and I relied on `classifyCandidate`'s
  cycle walk, by reading only.
- `byval` / `inalloca` inside a **module-level twin call**: `@__cq_q_g_01_unc(i32, i32, ptr null)` carries
  no `byval` at the call site while the twin's parameter does. This is pre-existing on round 2. It is
  harmless while the twin never reads the slot. Not filed.
- Any corpus, allocator or mutation sweep, per the owner's efficiency instruction. `+Asserts` was not used.
- The fold machinery, the tracking seeds, `simplifySelectInst` and the section/absolute conjunct, which
  are r4B's scope.
- Mixed masks: an outer clone of the same callee under two masks, where the classical-mask clone keeps an
  empty classical diamond. That is an IR-only artifact that declines at the one-block backstop.
