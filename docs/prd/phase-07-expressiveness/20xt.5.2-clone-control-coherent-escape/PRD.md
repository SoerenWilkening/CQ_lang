# PRD — bd 20xt.5.2 (clone): inner-atanl clone-control coherent-escape bypass

**Status:** DONE (shipped, Rule-13-cleared). Branch `3c6m.14-control-l6`.
Extends the 3c6m.14 L6 PredMux design of record + the 20xt.4 spec-callee QROM
read PRD (`../PRD-20xt.4-spec-callee-qram-read.md`) — read those first; this PRD
covers ONLY the delta. This is the FINAL atan2l blocker.

## 0. Context and scope

After (d) [20xt.5, unreachable switch-defaults] and (e) [20xt.5.1, fold-residue
select] landed, atan2l's TOP-LEVEL fully flattens and its inner `atanl` call
hoists as a direct `tail call fastcc @atanl(%u_pack)`, which Phase-6
specialization CLONES into `@__cq_q_atanl_1`. The clone body has INTERNAL tainted
control: an argument-reduction cascade of tainted diamonds, a region-internal
`phi i64` index over the constants `{0,1,2,3,-1}`, and two const-global QROM reads
`atanhi[id]` / `atanlo[id]` in a diamond arm whose loaded values reach the clone's
non-`main` `ret` (via `fmuladd`) with NO measure.

**Root cause (verified, bd 20xt.5.2):** the clone's scoped PredMux flatten
(`lowerCloneControl`, `flattenPredMuxRegions(claimAll=true)`) LEAVES at its
E4-gep gate on the `atanhi[id]` read, because `classifyQromReadUnderControl`'s
coherent-escape no-cloning fence
(`QramLowering.cpp`, `getName()!="main" && coherentlyEscapesToReturn`) returns
`No` for a read whose value flows to the clone's non-`main` ret. `lowerCloneControl`
then LOUD-declines `"callee contains tainted control flow under quantum lift"`
(`Specialization.cpp:520`). This is the same over-decline the 20xt.4 Inc-1
Rule-13 review flagged as note (ii): the coherent-escape bypass was at
`lowerQramReads` (the emitter) only, NOT at `classifyQromReadUnderControl` (the
claim), so an ARM-resident clone read whose value reaches the clone ret
over-declines at the E4/PredMux route.

**This increment (clone):** thread an `inBennettClone` flag into
`classifyQromReadUnderControl` that BYPASSES the coherent-escape fence, and drive
it from PredMux's `ClaimAll` at the E4-load / E4-gep claim gates. `ClaimAll=true`
is set ONLY by `lowerCloneControl` (the sole `flattenPredMuxRegions(claimAll=
true)` caller), so it is EXACTLY the "inside a Bennett clone" predicate. This
brings the CLAIM into agreement with the EMITTER (`lowerQramReads(inBennettClone=
true)`, which already bypassed the fence in Inc 1) — Rule 14, claim and emit
cannot diverge.

**Freeze-orthogonal** — no new runtime symbol, no YAML change (reuses the frozen
`cqrt_qram_{alloc,load}_f<W>(+_unc)` ABI).

### Why the bypass is SOUND (Bennett)

A top-level `return tbl[q]` (non-`main`) returns a value entangled with the
LOCAL index `q`; the whole-DAG uncompute dirty-frees `q`, dephasing the returned
carrier to a classical mixture (verify-clean silent miscompile) — hence the
fence. A clone read is NOT that shape: `emitBennettWrap` COPIES the return out to
a FRESH |0⟩ basis rail BEFORE the reverse, then reverses the WHOLE forward stream
— the `cqrt_qram_load_<W>_unc` AND the index computation — leaving
Σ aᵢ|inputᵢ⟩|f(inputᵢ)⟩. The index is uncomputed cleanly, never dirty-freed; the
answer lives on a separate rail. `emitBennettWrap` is called UNCONDITIONALLY
(`Specialization.cpp:998`, whether `ReturnTainted` or not) and captures EVERY
`isForwardQramLoad` in the clone (`Specialization.cpp:918`), so a claimed read is
ALWAYS reverse-played — the bypass cannot create an unreversed dirty rail. And
`ClaimAll=true` ⟹ a successful flatten ⟹ the wrap runs (or a later stage declines
loudly → `opt` exits non-zero → no miscompile).

### The bypass removes ONLY the coherent-escape reason

Every OTHER gate of `classifyQromReadUnderControl` is untouched: a non-const /
non-array global, an unsupported cell width, an untainted (and not
tainted-by-flatten) index, a narrow (non-pointer-width) index, and — the
safety-critical one — the bounds proof. A NON-pow2 / not-known-bits-provable
clone read still returns `No` (the E4 walk still LEAVES at E4-gep), so no
unmasked OOB `cqrt_qram_load` is ever emitted on the excluded basis states. The
blocker-c OOB discipline (`qromIndexKnownInBounds` / `kMsgQramCloneUnbounded`) is
intact.

## 1. The i64 index-select turned out already-handled

The bd note listed "the i64 index-select in lowerCloneSelect (the phi over consts
{0,1,2,3,-1})" as a third piece. It needs NO new code: `scanBody` accepts a
region-internal `phi i64` (width OK), the flatten converts it to a select-chain,
and `lowerCloneSelect` is already WIDTH-PARAMETRIC (`allocFn(Abi)` +
`copyControlledFn(Abi)`), lowering an i64 const-arm select via the
`cqrt_alloc_i64` + `cqrt_copy_i64_controlled` merge — exactly as it lowers the i32
4.4 select. The masked NeedsMask index (`and id, 3`) is inserted by the flatten
(RegionFlattener MaskLoads) BEFORE `lowerCloneSelect`, so `lowerQramReads`' bounds
re-proof sees `and(.., 3)` → known-bits [0,3] → passes.

## 2. Scope boundary (declined / deferred, NOT this increment)

- **Provable-phi-index clone read (over-decline, SAFE).** When the flattened
  phi-index is Provable (e.g. all arms `{0,1,2}`, no OOB sentinel) the flatten
  inserts NO mask, so by the time `lowerQramReads`' `qromIndexKnownInBounds`
  fence runs the index is an opaque `cqrt_alloc_i64` (lowerCloneSelect) handle
  whose known-bits are unprovable → the clone declines `kMsgQramCloneUnbounded`.
  This is a SAFE over-decline that declined BEFORE this increment too (at
  `scanBody`/flatten for coherent-escape), so it is NOT a regression — the
  increment strictly ADDS the NeedsMask accept, never removes an accept. atan2l
  itself is NeedsMask (its phi includes `-1`/`4294967295` → the `and id, 3`
  mask), so it is unaffected. A follow-up could mask pow2 clone reads uniformly
  (Provable ⇒ identity mask) to make the emitter fence pass; deferred (touches
  the safety-critical OOB fence, its own Rule-13).
- **fcmp-condition integer index-select (deferred widening).** At plain `-O1`
  clang if-converts a SMALL range-id selection to a chain of `select i1 <fcmp>,
  iW, iW`. `scanBody`/`lowerCloneSelect` decline an fcmp-condition select across
  the board (as `isLiftableFpSelect` documents). This is a genuinely separate
  capability, not the phi-index target shape.

## 3. Files

- `ir-pass/include/QramLowering.h` — `classifyQromReadUnderControl` gains a
  trailing `bool inBennettClone = false`.
- `ir-pass/src/QramLowering.cpp` — the impl + public wrapper thread the flag; the
  coherent-escape fence is guarded `if (!inBennettClone && …)`.
- `ir-pass/src/PredMuxFlatten.cpp` — the E4-load / E4-gep claim gates pass
  `/*inBennettClone=*/ClaimAll`.

## 4. Verification

- **Rule 12 red-green.** Three fixtures (CHECK-NOTs `CHECK-LABEL`-scoped +
  interleaved so they scan the CLONE body, not the dead un-lowered original or the
  trailing declares — the Rule-13 vacuous-CHECK-NOT fix; each verified to FAIL on
  an injected `cqrt_free(%arr)` dirty free and an injected `br i1`):
  `spec_accept_qrom_read_arm_coherent_escape.ll` (a spec-clone with an arm-resident
  NeedsMask QROM read whose value escapes to the clone ret — RED pre-fix `"callee
  contains tainted control flow under quantum lift"`, GREEN post-fix);
  `spec_accept_qrom_read_arm_two_tables.ll` (the LITERAL atanl `atanhi[id]`/
  `atanlo[id]` shared-index FAN-OUT — one index rail, two per-read masks, each read
  reversed once in LIFO order, no double-free, no array free); and
  `spec_reject_qrom_read_arm_nonpow2.ll` (the IDENTICAL single-read shape with a
  `[3 x double]` non-pow2 table STILL declines at E4-gep — the bypass did not
  weaken bounds). The existing
  `lowering_reject_qram_read_under_control_cohescape.ll` (top-level, non-clone)
  stays declining — the bypass is clone-scoped.
- **e2e golden.** `e2e-slice-spec-qrom-read-arm-escape` (`reduce` = a `noinline`
  callee with a tainted diamond whose arm reads `kTable[((long)(x*4))&3]` and
  whose merged value escapes to the ret with no measure). 34-line deterministic
  trace, analytically correct (`|x⟩|0⟩ → |x⟩|f(x)⟩`, f = `(x>1)?(kTable[id]+x):x`):
  1 `cqrt_ry` + 1 `cqrt_measure` (Rule 5), 1 `cqrt_qram_alloc_f64` (array handle
  NEVER freed), the load rail reversed via `cqrt_qram_load_f64_unc` before free
  (Rule 8), 0 double-frees, input qubit + result correctly not-freed.
- **atan2l census (O1+instcombine model).** opt-exit-0 + LINKS + RUNS: a 1598-line
  deterministic trace, 1 ry + 1 measure, 2 `cqrt_qram_alloc_f64` (atanhi/atanlo)
  each read reversed, 0 double-frees, masked (`and id, 3`) indices in-bounds. So
  atan2l reaches **COMPILES (spec-clone)** in the census model.
- Full ctest 185/185 (184 baseline + 1 new e2e ctest entry; the 3 new lit
  fixtures ride the existing `ir-pass-lit` aggregate entry, not new ctest tests).

## 5. Honesty (Rule 2)

atan2l opt-exits-0 + LINKS + RUNS AFTER this increment (census bucket flips to
`COMPILES (spec-clone)`). A separate ticket (3c6m.53) promotes it to VERIFIED via
a real-openlibm committed golden at the plain `-O1` ship floor. The QROM ABI is
frozen; no new frozen symbol.
