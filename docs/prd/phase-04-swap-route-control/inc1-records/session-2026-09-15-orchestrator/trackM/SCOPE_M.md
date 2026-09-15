# Track M — SCOPE: E2 (bd `fve8`) and E3 (bd `yiid`), an implementable design and a measured cost

Session 2026-09-15, scoping agent. **No pass source edited, nothing built, no `ctest`.**
Every number below was measured by this agent on the frozen ORACLE, with the command shown.
`IMPL_D.md` §14's own numbers were **re-taken rather than inherited** (Rule 11) and **one of
them is now VOID** — §5.1.

```
ORACLE, verified at session start and unchanged throughout:
  0e280fc62a91cec2336769edde8a873563a21ee4869744331a0fcf6811549c6d  build/ir-pass/cq-opt
  94602c7896e7a7ee1d0d0d54625a073f6a35fd6c9fe0af6e9c714b2043df507b  build/ir-pass/libCQPass.so
```

Read `FILE_SURFACE.md` first — it carries the three answers the orchestrator asked for.
`probes/README.md` maps every probe to its question and its ORACLE verdict.

---

# PART 1 — E2, bd `fve8`: retire clause 4 for `undef` at the sink

## 1.1 What happens today, measured

| probe | program | ORACLE |
|---|---|---|
| `e2a_direct_undef_bool.c` | `_Bool b; return cq_measure(b);` | **D** `cq_measure_<sfx> operand is an undef/poison literal; a classical measurement needs a defined value` |
| `e2c_direct_undef_int.c` | `int u; return cq_measure(u);` | **D**, same |
| `e2j_poison_operand.ll` | `cq_measure_si32(i32 poison)` | **D**, same |
| `e2e_undef_used_twice.c` | `int u; int m=cq_measure(u); return m+u;` | **D**, same |
| `e2g_undef_measure_with_quantum.c` | an undef measure **beside** a real theta | **D**, same — it preempts the whole module |
| `e2b`/`e2d`/`e2f`/`e2h` (the written-zero twins) | | **A**, 0 / 0 / 0 / 3 trace lines |

```
$ trackM/probes/m.sh trackM/probes/src/e2a_direct_undef_bool.c
```

The φ-routed spelling compiles — that is bd `fve8` itself, 4 of 710 rows, measured by
Track U last session and not re-taken here (it is not in dispute and the ruling accepts it).

## 1.2 The code sites

| site | today | must become |
|---|---|---|
| `ir-pass/src/MeasureLowering.cpp:151` | `if (!taint.Tainted.count(Handle)) {` — branch (1), the CLASSICAL measure (bd `21mg`) | unchanged |
| `ir-pass/src/MeasureLowering.cpp:152-155` | `if (valueCarriesUndef(Handle)) { diagnoseMeasure(…kMsgUndefOperand…); continue; }` | **split in two** — §1.3 |
| `ir-pass/src/MeasureLowering.cpp:191` | `Measure->replaceAllUsesWith(Handle);` | needs a **second RAUW target** for the undef case — §1.3(c) |
| `ir-pass/src/MeasureLowering.cpp:105-107` | `kMsgUndefOperand` | **KEPT** (it retains a customer — §1.3(b)) |
| `ir-pass/src/MeasureLowering.cpp:81-104` | the 4-ground rationale block for the decline | rewritten: grounds 1 and 2 now argue the **residual**, not the whole predicate |
| `ir-pass/include/MeasureLowering.h:67-68` | *"An `undef`/`poison` CLASSICAL operand is a loud decline of its own"* | rewritten in the same change — **L7-with-a-twist: a record correction that is not applied to the source is not a correction**, and this file's twin sentence is exactly the shape that was found wrong three rounds running in `RotationLowering.cpp` |

## 1.3 The design, three clauses

**(a) The whole-value clause — ACCEPT.** `isa<UndefValue>(Handle)` (which covers `poison`:
`PoisonValue` derives from `UndefValue`) ⇒ **no diagnostic**. The measurement lowers as the
type's concrete zero.

**(b) The residual clause — KEEP DECLINING, and this is a measured decision, not caution.**
`valueCarriesUndef` is `carriesUndefImpl(C, Seen, /*SkipGlobals=*/false)`
(`LiteralIntegrity.cpp:113-119`), so it walks **into a referenced global's initializer**.
Two probes decide it:

```
e2k_global_initializer_undef.ll   @g = global {i32,i32} {i32 1, i32 undef}
                                  cq_measure_si32(i32 ptrtoint (ptr @g to i32))   -> D
e2l_global_initializer_defined.ll identical but {i32 1, i32 2}                    -> A (exit 0)
```

The two differ **only in a field of a global the measured operand never reads**. The operand
in `e2k` is a **fully defined value** — the address of `@g`, truncated — and is **not**
`isa<UndefValue>`. Rewriting it to zero would be a **VALUE CHANGE**, not a refinement.
`e2i_constexpr_undef_operand.ll` (`ptrtoint (ptr undef to i32)`) is the same species.

This is **bd `z9t1`'s own conjunct, verbatim in shape**: `RotationLowering.cpp:439-440`
carries `if (!isa<UndefValue>(Seed)) return false; // ... but only a WHOLE-VALUE undef is
rewritable (the ConstantExpr residual)`, for the identical reason — *"the predicate gates a
DECLINE everywhere else and a REWRITE here"*. E2 is the same predicate flipping the same
way at a different site and owes the same narrowing.

**⇒ Answer to the brief's item (b): the decline string does NOT lose its last customer.** It
loses its *whole-value* customer and keeps the residual. That changes the obligation from
"delete the string / decide about renaming" to "re-ground the string's rationale on the
residual and pin it with a fixture that is not the one being inverted". `OQ-13`'s
stale-string problem does not arise.

**(c) The RAUW target — `Constant::getNullValue(Measure->getType())`, NOT `Handle`.** The
owner's words are *"measures the type's concrete zero"*, and the target is the
**measurement's outcome**, not the operand. Measured difference, on
`e2g_undef_measure_with_quantum.c`'s stage-1:

```
  %2 = tail call i32 @cq_measure_si32(i32 noundef undef)
  %4 = add nsw i32 %3, %2
```

RAUW-to-`Handle` leaves `add nsw %3, undef`; RAUW-to-zero leaves `add nsw %3, 0`, which is
**exactly** what the zero twin `e2h` lowers to today (`%1 = add nsw i32 %m, 0`, measured).
The refinement claim is only true of the second spelling.

⚠ The operand's **other** uses are NOT rewritten (`e2e_undef_used_twice`: `m + u` keeps
`u` as `undef`). That is deliberate and it mirrors `z9t1`, which normalizes the theta seed
and the theta-carrying φ incomings and nothing else. State it; do not quietly widen it.

**Nothing else changes.** Branch (1) already emits no symbol, no gate, no rail and no trace
line, so E2 adds **zero** runtime surface, touches no YAML (Rule 15 never enters) and moves
no ABI.

## 1.4 Red-green

| fixture | direction | content |
|---|---|---|
| `ir-pass/test/lowering_reject_measure_undef_operand.ll` | **INVERT** to an accept | the existing `i1 undef` module; `RUN: not` → `RUN:`, `CHECK: error…` → a positive check that the measure is gone and `ret i1 false` remains, plus `CHECK-NOT: cqrt_alloc` / `CHECK-NOT: cqrt_measure_` retained as a **whole-file** prefix (Rule 12(a): never inside the negative prefix). ⚠ Rename is bd `gahu`'s trap — a `git mv`'d fixture can be **resurrected by a merge** (L8). Keep the filename; rewrite the header to say the name is historical and why. |
| `ir-pass/test/lowering_accept_measure_undef_zero.ll` | NEW accept | the `poison` spelling (`e2j`), pinning `ret i32 0` — proves (a) covers `PoisonValue` without a second predicate |
| `ir-pass/test/lowering_reject_measure_undef_constexpr.ll` | NEW decline | `e2i` + `e2k` **in separate files** (⚠ `LLVMContext::diagnose` EXITS on the first `DS_Error`, bd `br4a`, so two functions in one file pin ONE diagnostic — measured and stated in the existing fixture's own header at `:25-27`) |

**The refinement measurement, with its population and its command.** Not an assertion:

```
POPULATION: every module in {ir-pass/test/*.ll} ∪ {every session dir's track*/probes,
            review_*_probes} whose stage-1 holds `@cq_measure_<sfx>(<ty> ... undef|poison)`
            with the operand `isa<UndefValue>`  — measured TODAY: 1 (the fixture above);
            the population must be RE-TAKEN on the corpus at implementation time because a
            crude grep is a LOWER BOUND, never a census (Rule 11).
TWIN:       the same module with that one token rewritten `undef` -> the type's zero.
GATE:       SUBJECT(undef module).lowered-IR  ==bytes==  ORACLE(zero twin).lowered-IR
            for every member, 0 divergences, 0 A->D.
COMMAND:    for f in $POP; do
              sed 's/\(@cq_measure_[a-z0-9]*(\[^)]*\)undef/\10/' $f > $f.zero.ll
              SUBJECT/cq-opt -passes=cq-lowering -S $f      -o s.ll
              ORACLE /cq-opt -passes=cq-lowering -S $f.zero.ll -o o.ll
              diff <(grep -v '^; ModuleID' s.ll) <(grep -v '^; ModuleID' o.ll)
            done
```
⚠ Lowered-IR md5s are **not comparable across sweeps** (`PROTOCOL.md` S3, the temp
`ModuleID`) — compare within a row, as above, never by a stored hash.

## 1.5 Retirement triggers

1. **`valueCarriesUndef` stops walking global initializers** (`SkipGlobals` flips, or
   `slotCarriesUndef` replaces it at this site). Then `e2k` is no longer a decline and the
   residual clause's whole justification moves. Re-derive; the tripwire is
   `lowering_reject_measure_undef_constexpr.ll`.
2. **Clause (a) starts rewriting anything that is not `isa<UndefValue>`, or `undef` stops
   being uniqued per type.** Those are the refinement's only two load-bearing facts — the
   same pair `RotationLowering.cpp` names as its trigger (ii) — and either one gone makes
   this an **over-accept**.
3. **7.6 decides that the output tape carries every user-written measurement.** Branch (1)
   emits no trace line at all; E2 moves one more shape into it. Same open question as
   §7.2 below; they must be answered together.

---

# PART 2 — E3, bd `yiid` (P1): (b) BROAD, taint STOPS at `cq_measure`, POSITION-AWARE

## 2.1 The mechanism, in one sentence, and why it is NOT a taint-set change

`IMPL_D.md` §14.5 says the difficulty is that *"`q` before the measurement and `q` after it
are the same SSA value"*, so (b) is a position-aware kill and not a set removal. **That is
true and it has a much smaller consequence than §14.5's sketch supposes**, because the
compiler does not need a positional taint predicate at all — it needs a **USE RELABEL**:

> For every `@cq_measure_<sfx>` call `M` and every **use** `U` of `M`'s operand `%q` other
> than `M`'s own operand slot, when `M` **dominates** `U`, rewrite `U` to read **`M`'s
> result** instead of `%q`.

After that rewrite `%q` has **no uses positioned after `M` at all**, so:

* taint flows correctly with **zero change to `propagateWorklist`** — a measure result is
  already never tainted (`isMeasureSink`, `TaintPropagation.cpp:217-227`), so everything
  downstream of the relabel is classical **by the existing rule**;
* a post-measure `cq_theta(q, θ)` becomes `cq_theta(m, θ)` — an ordinary **SOURCE** theta,
  lowered by `lowerRotations`' existing `Chained == false` path to
  `cqrt_alloc_<W>(<the measured value>)` + `cqrt_ry_<W>` — **the owner's "it just requires a
  `c_alloc` again", with no new emitter**;
* a post-measure `cq_measure(q)` becomes `cq_measure(m)` — bd `21mg`'s **classical** measure,
  already shipped;
* **types match by construction**: `declMatchesPrototype` (`TaintPropagation.cpp:249-256`)
  forces `cq_measure_<sfx> : T(T)`, so `M`'s result type **is** `%q`'s type. No cast, no
  width table, no `CastLowering` involvement.

## 2.2 The measurement that makes this an ACCEPT-ONLY widening onto an ALREADY-CLEARED stream

The relabel rewrites a module into another module **the shipped compiler already lowers**.
Measured two ways.

**(i) The C-level explicit-re-seed twins all ACCEPT on the ORACLE.**

| probe | spelling | ORACLE |
|---|---|---|
| `e3a_twin_reseed_from_m.c` | `m=cq_measure(q); a=cq_theta(**m**,.5)` | **A**, 6 lines, STRICT 2b clean |
| `e3b` re-measure the name | | **A**, 6 |
| `e3c` two siblings | | **A**, 9 |
| `e3d` pure op on `m` | | **A**, 6 |
| `e3e` in-loop | | **A**, 14 |
| `e3f` at `_Bool` | | **A**, 7 |
| `e3g` at `double` | | **A**, 6 — `cqrt_alloc_f64` / `cqrt_measure_f64`, types match |

**(ii) The relabel applied TEXTUALLY to the stage-1 IR of the declining originals ACCEPTS,
and one of them is BYTE-IDENTICAL to the C twin.**

```
$ diff out/m14a_measure_then_theta.s1.ll relabelled/m14a_measure_then_theta.relabel.ll
12c12
<   %3 = tail call i32 @cq_theta_si32(i32 noundef %1, double noundef 5.000000e-01) …
>   %3 = tail call i32 @cq_theta_si32(i32 noundef %2, double noundef 5.000000e-01) …
   ← EXACTLY ONE OPERAND OF ONE INSTRUCTION
$ diff <lowered body of m14a.relabel>  <lowered body of e3a twin>   → IDENTICAL_BODIES
$ diff m14a.relabel.trace              e3a.trace                    → TRACES_BYTE_IDENTICAL
```

| relabelled | ORACLE before | ORACLE after |
|---|---|---|
| `m14a` measure → rotate | A 5 (**chained on the measured rail** — the wrong circuit) | **A 6**, fresh `cqrt_alloc_i32(%m)` |
| `m14b` measure → rotate → re-measure the name | **D** `…predates a non-diagonal gate` | **A 6** |
| `m14c` measure → in-loop re-use | **D** same | **A 12** — 3 independent rails, 3 i.i.d. measures |
| `m14d` measure → two siblings | **D** same | **A 9** — two independent rails |
| `m14f` measure → pure op | **D** `operand predates…` | **A 6** |
| `m14e` two siblings with **NO** measurement — the CONTROL | **D** | *(not relabelled — nothing to relabel)* **D** ✓ |

That is the 3qlq-Inc-2 argument in its strongest form: the widened accept's stream is
**read off the shipped compiler**, not invented (Rule 14, and Rule 2's byte-identity witness).

## 2.3 The code sites

| site | today | must become |
|---|---|---|
| `ir-pass/src/TaintPropagation.cpp:471-509` (`propagate`) | `collectAndSeed` loop → `propagateWorklist` → `return out;` | insert `relabelPostMeasureUses(M, out, MeasureFns)` **between** the collect loop (`:492-497`) and `propagateWorklist` (`:505`) |
| `ir-pass/src/TaintPropagation.cpp` (new, file-local + exported) | — | `relabelPostMeasureUses` (~40 lines): per function, lazy `DominatorTree`; for each `M ∈ out.MeasureCalls`, `Value *Q = M->getArgOperand(0)`; for each `Use &U : Q->uses()` with `U.getUser() != M` and `DT.dominates(M, U)` → `U.set(M)`; iterate to a fixpoint over the measure list (bounded by `MeasureCalls.size()+1`) |
| `ir-pass/include/TaintPropagation.h:44-72` (`TaintSet`) | — | `SmallVector<WeakTrackingVH,4> PostMeasureRelabels` — the L1 RECORD (§2.6) |
| `ir-pass/src/CQLoweringPass.cpp:571` (`run`) and `:1115` (`runOnFunction`) | `repropagateControlMerges(M, wd, taint, plan6);` | add `declineNewPostMeasureReads(M, taint);` **immediately after**, in BOTH entry points (§2.6) |

**No `WidthDispatch`, no `runtime/`, no `tools/opcode_table.yaml`, no `include/CQ.h`.**
Re-verified rather than inherited from §14.4: `cqrt_alloc_<W>` already takes a runtime value
(`m14h_runtime_seed_alloc.c` → `cqrt_alloc_i32(1)` from `argc`), and the relabelled `m14a`
emits `%h1 = call i32 @cqrt_alloc_i32(i32 %m)`. **§14.4's "no ABI change, no new symbol" is
CONFIRMED.**

## 2.4 The position predicate — **plain `DominatorTree::dominates(Instruction*, Use&)`**, and the L3-mirror statement the brief requires

`WireWalk` predicates I considered, and the direction I would be using each in. Per the
L3-mirror lesson (which cost a P1 filing on 2026-09-14, bd `a3z7`), each is stated, not
assumed:

| predicate | its retirement trigger / modality | E3's direction | verdict |
|---|---|---|---|
| `WireWalk::provablyBefore(A,B,DT)` (`WireWalk.h:184-200`) | *"if `B` runs, `A` already did, **and `A` never runs again after it**"*; header: *"proves a CONDITIONAL-on-`B` property, never a post-dominance one"* | I would use it in the **GRANTING** direction (`true` ⇒ relabel) | **NOT CALLED.** Its second leg (`!isPotentiallyReachable(B,A)`) is a **strictly stronger** obligation E3 does not need, and it **refuses correct relabels**: a measure inside a loop body with the read after it (`e3h`) is reachable-from-the-read across the back edge, so `provablyBefore` is false while the relabel is correct (each trip, `M` runs before `U` with the same reaching definition). Adding a granting caller with a *weaker* need to a predicate whose two existing callers use it in **opposite** directions is exactly what `WireWalk.h:222` forbids. |
| `WireWalk::phiTracksWire` | header: *"Any third caller must state which direction it uses"*; the **dtzb vocabulary gap** is live (bd `a3z7`, `IMPL_D.md` §15.4) | n/a | **NOT CALLED.** |
| `WireWalk::readerStalesItself` / `findNonDiagonalWireGate` | `RequireEmitDominance` is an ACCEPT-direction policy bit | n/a | **NOT CALLED.** E3 *shrinks* their subject set rather than calling them (§2.5). |
| `ArmClassify::railMeasuredBeforeReadPoint` (`ArmClassify.cpp:2815`, exported `ArmAnalysis.h:175`, **9 call sites**) | *"the ONE spelling (Rule 14)"* of *"is this register measured before this read point"* | I would need it in the **GRANTING** direction | **NOT CALLED — and this is the most important line in this document.** Its modality is **∃path** (`:2883-2893`: *"Can the read point execute after this measurement on SOME path?"*), chosen deliberately because it gates a **DECLINE**. E3 needs **∀path**. Calling it in the granting direction would relabel a use that is only *sometimes* post-measure — on the other path the name still denotes a live superposition, and the relabel would be a **silent miscompile**. ⚠ **That predicate and E3 are complementary, not interchangeable**, and the implementer must write that sentence into the new function's header. |

⚠ **The `isPotentiallyReachable` identity trap the brief names is avoided by construction**:
E3 never asks a same-instruction reachability question. `DT.dominates(Def, User)` with
`Def == User` reduces to `comesBefore(itself)` = false, and the `U.getUser() != M` conjunct
excludes the case anyway — belt and braces, because a Release build asserts nothing.

**Why plain dominance is SUFFICIENT and not merely weaker.** `DT.dominates(M, U)` ⇒ on every
execution of `U`, `M` has already executed in the current activation, with `%m` the reaching
definition. Physically the rail then holds a basis state and `%m` is its label, so the name
`q` at `U` denotes `%m` — which is the ruling. And the closure is total: after the rewrite
there is **no** post-`M` reader of `%q` left to be wrong about, so nothing can relabel
`%q`'s rail between `M` and a later read, because there is no later read.

**The safe direction is NO RELABEL**, and that is what makes a partial predicate sound: an
unrelabelled use keeps today's behaviour exactly, which is already adjudicated (either a
decline, or the single-read chain §14.2 argues is the same state up to a spectator qubit).

## 2.5 The loop back edge — the brief's question, answered

| probe | program | today | under E3 |
|---|---|---|---|
| `e3j_inloop_measure_only.c` | `for(…) s += cq_measure(q);` (the brief's shape, `IMPL_D.md` §14.0's `r5g`) | **A, 5 lines** | **UNCHANGED, by construction.** `q`'s only use is the measure's own operand slot, which `U.getUser() != M` excludes. Nothing to relabel, in any spelling. |
| `e3h_inloop_measure_then_read.c` | `for(…){ m=cq_measure(q); a=cq_theta(q,.5); … }` | **D** `…predates a non-diagonal gate` | **RELABELLED** — `DT.dominates(M,U)` holds inside the body. Fresh rail per trip, seeded from that trip's (identical) outcome. This is the probe that separates `dominates` from `provablyBefore`. |
| `e3i_inloop_read_then_measure.c` | `for(…){ a=cq_theta(q,.5); m=cq_measure(q); … }` — the MUST-NOT-RELABEL control | **D** same | **UNCHANGED, still D.** Dominance fails; trip 1 reads an unmeasured rail and trip 2 a measured one, and the source names neither — the same ambiguity the owner ruled a DECLINE on 2026-09-14. |

"Positioned after" is not a total order in a loop, and dominance is the reading that is
correct per **activation** rather than per **program point**: it says *this* trip's `M`
precedes *this* trip's `U`, which is precisely what the relabel needs.

## 2.6 The L1 round-2 obligation — **measured FALSE, not assumed**

bd `z9t1` discharges its own L1 obligation structurally, on the ground that every
theta-duplicating stage is followed by a full `taint = propagate(M, wd)`. **That ground does
not extend to E3**, and I checked rather than inherited:

> `repropagateControlMerges` (`TaintPropagation.cpp:1833`) **does not call `propagate` or
> `collectAndSeed`.** It rebuilds the three `FnSet`s by hand from `taint.{Theta,Phi,Measure}Calls`
> (`:1864-1873`) and calls `propagateWorklist` directly (`:1886`).

So a relabel placed inside `propagate` runs at round 1 and at every *full* re-propagate, but
**not** at the round-2 fixpoint. The L1 cure is the pattern, not a prediction:

* **RECORD at the site that asks.** `relabelPostMeasureUses` records what it rewrote in
  `taint.PostMeasureRelabels` (`WeakTrackingVH`, because a later flatten/RAUW can null it —
  the same discipline `RailCondReads` uses).
* **RE-ASK after the fixpoint, in BOTH entry points.** `declineNewPostMeasureReads`, inserted
  immediately after `repropagateControlMerges` at `CQLoweringPass.cpp:571` and `:1115`, re-runs
  the *analysis* half and **declines loudly** if it finds a **new** relabellable USER read that
  round 1 did not. It must **not** rewrite: a late taint *shrink* is unsound once a stage has
  already lowered something as quantum. A decline is the safe direction and the expected
  population is **zero** — which the implementer measures rather than assumes.
* **Emitter scaffolding is excluded** by the same test `propagateWorklist` already uses at
  `:457-461` (`cqrt_` / `cq_template_` callees are not user data flow). A
  `cqrt_copy_<W>_controlled` whose dst is `%q` after a measure is a rail operation, not a
  name read, and must neither be relabelled nor declined.
* **Order relative to `lowerMeasures` is a contract with a retirement trigger** (bd `21mg`,
  `MeasureLowering.cpp:37-51`): `lowerMeasures` sits **after** `repropagateControlMerges` in
  both entry points so `taint.Tainted` is final there. E3 changes nothing about that slot,
  and the new stage sits **before** it — but the implementer owes one sentence in
  `MeasureLowering.cpp`'s header saying the relabel is upstream and the contract still holds,
  or the next reader re-derives it.

⚠ `LLVMContext::diagnose` **EXITS on the first `DS_Error`** (bd `br4a`), so
`declineNewPostMeasureReads`' slot is semantic, not cosmetic: placed after
`repropagateControlMerges` it speaks only for modules that reached the fixpoint clean, which
is the only population it has anything to say about. It is a BACKSTOP, never a preemptor —
the same argument `declineRecordedStaleQuantumReaders` carries at `CQLoweringPass.cpp:755-764`.

## 2.7 What E3 RETIRES, measured

`recordStaleQuantumReaders` / `declineRecordedStaleQuantumReaders` (bd `3d8q`) keep their
whole population **except** the measured-name shapes, which E3 removes **by construction**:
after the relabel there is no taint to be stale about. Measured: `m14b`, `m14c`, `m14d` all
decline on `cq opcode lowering: rotation/measure operand predates a non-diagonal gate` today
and all three ACCEPT relabelled, while `m14e` — **the same two siblings with the measurement
deleted** — is untouched and still declines. §14.7's claim is confirmed on this ORACLE.

Also retired, and **NOT anticipated by `IMPL_D.md` §14** (each measured here):

| shape | today | relabelled |
|---|---|---|
| `e3k` post-measure read as a tainted BRANCH CONDITION | **D** `cq controlled lowering: condition measured before the control route under quantum control` | **A** — classical condition; the `cq_phi` is an uncontrolled global phase and is **DELETED** (Rule 3) |
| `e3o` post-measure read STORED to memory | **D** `cq taint escape: tainted value stored to memory` | **A** |
| `e3q` post-measure read used as a ROTATION **ANGLE** | **D** `cq rotation lowering: unsupported quantum-derived rotation angle` | **A** — a classical *runtime* angle (`e3r` twin: A, 6 lines) |

⚠ **`e3q` deserves an explicit owner sentence.** Rule 3 says a quantum-derived angle is a
loud decline; after the relabel the angle is a *measured* value, i.e. classical, and the
emission is the already-shipped runtime-angle form. It is sound under (b), it is a
capability gain, and it is **not in §14's cost at all** — so it must be disclosed rather
than discovered at a group gate.

## 2.8 The blast radius — **21 of 22 shipped fixtures move, and one moves the wrong way**

Instrument: `probes/post_measure_ir_scan.py` (self-tested 7/7 over 5 known positives and 2
known negatives; ⚠ its first spelling counted LLVM-19 `#dbg_` records as uses and failed
**7 of 7** — Rule 12(c) on an instrument, caught by self-test and not by re-reading) and
`probes/relabel.py` (the **same-block** subset: lexical order inside a block *is* dominance,
so it is a strict SUBSET of what E3 rewrites and can only UNDER-state the radius).

```
$ python3 probes/post_measure_ir_scan.py 'ir-pass/test/*.ll'
--- 2039 modules scanned: DEFINITE 23 use(s) in 22 module(s);
    POSSIBLE(upper bound) 873 use(s) in 608 module(s) ---
$ for f in <the 22>; do relabel.py … | ORACLE cq-opt; done      # 22 ORIG vs 22 RELABELLED
```

| | count | fixtures |
|---|---|---|
| **D → A** | **15** | `control_inplace_ry_reject_rail_measured_before`, `…_rail_round2_measured_parent`, `control_phase_kickback_reject_{cmp_derived_folded_to_parent,cmp_measured_before,mergephi_measure_before,rail_measured_early,rail_round2_measured_parent}`, `control_swap_reject_select_{cmp_measured_before,dualuse,rail_measured_before,rail_measured_parent_before_chain,rail_round2_plainc_twotu,rail_round2_window}`, `control_swap_select_cmp_round2_window_accept`, `lowering_uncompute_postmeasure_use` |
| **A → D** ⚠ | **1** | `control_angle_select_ry_alias_pre_gate` — §2.9 |
| **D → D, string MOVES** | **2** | `control_phase_kickback_reject_cmp_inplace_xor_measured_parent`, `control_swap_reject_select_mergephi_measure_before` — both re-route from `condition measured before the control route` to `tainted value muxed by a classical-condition {phi,select}`. Their `CHECK` lines mirror character-for-character and must be rewritten. |
| **D → D, unchanged** | 1 | `control_inplace_ry_reject_stray_op` — the only NON-mover of the 22 |
| **A → A, STREAM MOVES** ⚠ | **3** | §2.10 — and **A → A identical: 0** |
| **committed goldens** | **0 of 383** | `probes/post_measure_trace_scan.py`, self-tested 6/6 |

⚠ **`≤608` modules hold a CROSS-BLOCK post-measure use my instrument cannot adjudicate**
(it computes no dominator tree). Most are pre-measure uses in another block; the real number
is between 22 and 608 and **only the implementer's own predicate can measure it**. Budget a
full corpus sweep as the *first* implementation gate, not the last.

## 2.9 ⚠ The A → D regression — `control_angle_select_ry_alias_pre_gate`

```
  %r  = cq_theta_si32(%u1, 0.3)
  %mm = cq_measure_si32(%r)                       ; the diagonal alias read, BEFORE the gate
  %c  = icmp eq i32 %q, 5                         ; %q is a DIFFERENT tainted register
  %ang= select i1 %c, double 0.9, double 0.3
  %t  = cq_theta_si32(%r, double %ang)            ; ---> relabelled to cq_theta_si32(%mm, %ang)
```

Relabelled, the theta's base goes from CHAINED to SOURCE, and the folded **angle-select**
classifier — whose Ry stem lowers BY DIFFERENCE on a *quantum* base
(`AngleSelectEmit`) — no longer recognizes the shape, so gate 3 fires:
`cq controlled lowering: rotation angle under quantum control`. Measured, ORACLE, both
directions.

**This is an over-decline E3 CREATES.** The program is legal under the ruling (re-prep from
`%mm`, then rotate by a quantum-controlled angle). Three dispositions, and the choice is the
implementer's to bring back, not to make silently:

1. **Accept and file it** — safe direction, but it regresses a shipped, Rule-13-cleared
   ACCEPT, which is the one thing "ACCEPT-only widening" promises not to do.
2. **Fence the relabel** at a theta whose angle is a folded select — shape-specific and
   ugly, and it re-introduces exactly the kind of syntactic enumeration L5 says loses.
3. **Teach the Ry stem the classical-base (state-prep) spelling** — real work, and the
   principled answer.

Whichever is taken, **write it down before implementing**. `IMPL_D.md` §14 does not contain
this shape, which is why §14's "0 shipped accepts" reads clean and is not.

## 2.10 ⚠ E3 DELETES A USER-WRITTEN `cq_measure`, AND IT REACHES THE 7.6 OUTPUT TAPE

Three shipped ACCEPT fixtures keep their verdict and move their **stream**. Two of them lose
a measurement the user wrote:

```
lowering_stale_reader_chain_accept            lowering_io_tape_measure_then_tape
  < %m3 = call i32 @cqrt_measure_i32(i32 %h)    < %tape = call i32 @cqrt_tape_alloc()
  < %s  = add i32 %m, %m3                       < %0 = call i32 @cqrt_tape_write_i32(i32 %tape, i32 %h)
  --- > %s = add i32 %m, %m                     --- > %r = call i32 (ptr,...) @printf(ptr @.d, i32 %m1)
control_inplace_ry_stateprep_fcmp_oeq_twin: the same shape at f64 (`%m1 = cqrt_measure_f64` gone)
```

The **circuit** is right — measuring one register twice is idempotent, so one trace line is
the physically-correct stream, and this is (b) working as designed. The **contract** is the
question: the golden trace is CQ's contract (Rule 2), and bd `21mg`'s open Q-1 asks whether
the **7.6 output tape** must carry every user-written measurement. `IMPL_D.md` §14.7 named
this and deferred it (*"decide that with 7.6, not here"*). **It now has a measured customer
inside a shipped fixture, and the 7.6 output-tape ABI is one of the five items the freeze is
gated on (CLAUDE.md, Status in brief).**

Rule 5 forbids *inserting* a measurement and E3 inserts none. It is silent on *removing*
one, and that silence is exactly the unruled boundary L7 warns about. **Owner question,
§7.2.**

*(The positive of the same class, recorded so this is not read as all-cost: bd `z9t1`
RESTORES a vanished user `cq_measure` in `lowering_unroll_const_trip`. The two are different
events and must not be netted — the same discipline CLAUDE.md applies to the 2026-08-23
census ±3/±4.)*

## 2.11 Red-green for E3

| fixture | direction | subject |
|---|---|---|
| `lowering_postmeasure_reseed_accept.ll` | NEW **accept** | `m14a` relabelled; positive `CHECK` on `cqrt_alloc_i32(i32 %m)` — the runtime seed — in its own whole-file prefix |
| `lowering_postmeasure_reseed_twin_identical` (e2e) | NEW **slice + golden** | the twin-identity witness: the widened program and its explicit-`m` twin byte-identical, the 3qlq-Inc-2 pattern (`e2e-*-twin-identical`, 40 today) |
| `lowering_postmeasure_two_siblings_accept.ll` | NEW **accept** | `m14d` relabelled — two independent rails |
| `lowering_reject_premeasure_read_inloop.ll` | NEW **decline** | `e3i` — the read PRECEDES the measure in the body; must keep declining on `…predates a non-diagonal gate`, character-for-character |
| `lowering_postmeasure_unmeasured_siblings_reject.ll` | **the CONTROL** | `m14e` — two siblings with **no** measurement; must keep declining. One line apart from the accept above, and that one line is the whole discrimination |
| `lowering_postmeasure_inloop_measure_only_unchanged.ll` | NEW **accept** | `e3j` — the brief's back-edge case; pins that E3 is a **no-op** on it |
| the **21 movers of §2.8** | EDIT | each with a header saying what moved and why, and — L8 — a **retirement trigger** for the next reader |
| `lowering_postmeasure_round2_new_read_reject.ll` | NEW **decline** | `declineNewPostMeasureReads` firing. ⚠ If no input can reach it (expected), say so in the header and pin it by **binary mutation** the way `control_swap_reject_select_rail_round2_window.ll` was — a decline fixture whose subject cannot occur pins nothing (Rule 12(c)) |

⚠ Run `trackM/probes/impl/vacuity.py` (session 2026-09-13) over every new accept batch, and
note it is itself bd `jdec` (it reports `checked 0` instead of failing). A `0-byte .ll`
ACCEPTS through the passthrough early-out — check every probe is non-empty before scoring it.

## 2.12 Retirement triggers for E3

1. **`repropagateControlMerges` starts calling `propagate`/`collectAndSeed`** — then the
   round-2 re-ask is redundant and should be *deleted*, not left as dead weight. Conversely,
   **any new stage that mints or rewrites a use of a `@cq_theta` result** re-opens the L1
   window and owes the re-ask a look.
2. **`declMatchesPrototype` stops forcing `cq_measure_<sfx> : T(T)`** — the "no cast needed"
   claim is built on that single line (`TaintPropagation.cpp:249-256`).
3. **`ArmClassify::railMeasuredBeforeReadPoint` changes modality from ∃path to ∀path**, or
   gains an accept-direction caller — then the two predicates are no longer complementary
   and the "not called" argument in §2.4 must be re-derived from scratch.
4. **`AngleSelectEmit`'s Ry stem learns a classical base** — §2.9's regression disappears and
   its disposition should be revisited.
5. **7.6 rules on the output tape** — §2.10 and §1.5(3) both move.

---

# 3. What I could NOT turn into a predicate site

Stated because an unstated gap hardens into a ruling (L7):

* **The cross-block population.** 22 fixtures are DEFINITE; up to 608 hold a cross-block use
  my textual scanner cannot classify. I could not compute dominance without building LLVM,
  so **the real blast radius is unmeasured between those bounds.** No estimate is offered.
* **Whether round 2 can create a new post-measure user read.** I can name the stages that
  mint or RAUW values in that window (`MergePhiPeel`'s compare clones, the emitters' M-α/M-β
  RAUWs, `detectAndLowerOnwardControl`) but I could not *run* them against a subject binary.
  The design therefore carries a **loud decline** rather than a proof, and the expected
  population of that decline (zero) is a prediction the implementer must measure.
* **A derived rail on the same physical register.** `b = q+1; m = cq_measure(q); c = b+1;`
  — `c` reads `b`, not `q`, so E3 does not relabel it, yet physically `b`'s rail collapsed
  with `q`'s. (b) as *ruled* is about **the name**, so this is out of scope by the ruling's
  own words — but it is a **residual with no fence**, and I could not find a site where it
  could become one without re-deriving a wire relation `railWireNamesBackward` already owns
  in the opposite direction. **Named, not solved.**
* **Whether the `A→D` regression (§2.9) has siblings.** I found one by measuring 22 fixtures.
  The class is "a classifier that requires a CHAINED base"; `AngleSelectEmit`,
  `emitInPlaceRotationRegion` and the state-prep `F1`/`F2` fences are all in it. I probed
  only the angle select. **A crude scan is a lower bound, never a census** (Rule 11).
* **The ConstantExpr residual's true population.** `e2i`/`e2k` prove it is *reachable*; I did
  not measure how many real inputs reach it. It may be zero, in which case the kept decline
  is pinned only by hand-IR — acceptable, but say so.

---

# 4. COST

## E2

| | measured / derived |
|---|---|
| production lines | **~12** changed in `MeasureLowering.cpp` (split one `if`, add one `RAUW` target, rewrite the rationale block), **~4** in `MeasureLowering.h` |
| files | 2 source + 3 fixtures |
| fixtures | 1 **inverted**, 2 **new** (accept-poison, decline-constexpr) |
| goldens | **0** |
| ABI / YAML / symbols | **none** |
| Rule-13 rounds | **1** — it is a sink-side clause, not the lowering core, and its whole argument is one `isa<UndefValue>` conjunct with a measured counter-example (`e2k`) |
| corpus sweep | 1, attributable by one string |

## E3

| | measured / derived |
|---|---|
| production lines | **~40–70**: the relabel (~40), the `TaintSet` record (~3), the round-2 re-ask (~25 incl. its diagnostic) |
| files | `TaintPropagation.{cpp,h}`, `CQLoweringPass.cpp` (×2 slots) |
| fixtures | **≥21 EDITED** (measured; 15 invert D→A, 2 change string, 1 A→D, 3 stream; only 1 of the 22 is untouched) **+ 7 new** |
| goldens | **0 committed goldens move** (measured 0/383) **+ 1–2 new slices** (twin-identity + the capability) — ⚠ `IMPL_D.md` §14.6's *"2 of 367"* is **VOID**, §5.1 |
| ABI / YAML / symbols | **none** — re-confirmed, not inherited |
| Rule-13 rounds | **≥3.** It is in the taint core by definition; it inverts 15 Rule-13-cleared decline fixtures; it creates one ACCEPT→DECLINE; it has an undischarged L1 window. The measured hit rate on this project says the next round finds something, and "budget the rounds up front" is Rule 13's own instruction. |
| corpus sweep | 1 full, **as the FIRST gate** (to close the 22-vs-608 bracket), plus 1 at hand-off |
| open OWNER questions before implementation | **2** (§7) |

---

# 5. Corrections to the inherited record (Rule 11)

## 5.1 ⚠ `IMPL_D.md` §14.6's golden cost is VOID: **0 of 383, not 2 of 367**

§14.6 names `slice_control_select_bool_round2_window.expected.log` and
`slice_control_select_cmp_round2_window.expected.log` as the two goldens (b) would shorten.
**Both goldens were DELETED at `66428ddc`** (the stale-reader merge gate) and both slices
unregistered — CLAUDE.md §4c records the conversion, and the kept `.c` files carry the
header saying so.

```
$ ls tests/e2e/ | grep round2_window     # the two .c files and their _lib.c; NO .expected.log
$ python3 probes/post_measure_trace_scan.py tests/e2e
--- 0 of 383 committed goldens hold a post-measure handle re-use ---   (self-test 6/6 first)
```

**A measurement is a fact about a moment** (PROTOCOL.md's own opening lesson). §14's figure
was true on 2026-09-14 and is false today; the *direction* it implied — "(b)'s shipped cost
is two goldens" — was the wrong reading even then, because it measured goldens and not the
**decline fixtures whose subject IS the shape** (§2.8: 22 of them, 21 movers).

## 5.2 `IMPL_D.md` §14.0's *"`cq_measure` is a taint SINK and NOTHING ELSE"* is not complete

`ArmClassify::railMeasuredBeforeReadPoint` (`:2815`, 9 call sites, plus
`SelectClassify.cpp:972/1029` and `RegionTreeDetect.cpp:235`) is a fully-developed
measurement predicate on the **control** path, with its own per-activation origin barrier and
its own Rule-14 "ONE spelling" claim. The accurate statement is: **`cq_measure` is modelled
on the control path as a DECLINE condition and nowhere on the data path.** E3 is the data
half, and §2.4 states why the two are complementary rather than one predicate.

## 5.3 Confirmed from §14, on THIS ORACLE

§14.1's chaining stream, §14.4's runtime-seed alloc, §14.7's six-row table (`m14a` A/5,
`m14b`/`m14c`/`m14d`/`m14e` D, `m14f` D, `m14g` A/12, `m14h` A/3) — **all reproduce exactly**.

---

# 6. Sequencing recommendation

1. **E2 lands first**, inside Group 1, as a small self-contained clause. It is ~12 lines and
   one Rule-13 round.
2. **E3 does not land this session.** It is one increment of its own, opened by the two
   owner questions below, and it must be sequenced **after** the headline because it changes
   what `propagate` returns — the input to every stage the rail bank adds. That is
   `MERGE_FILINGS` F-1's lesson (*a composition is not cleared by clearing its parts*)
   applied before the fact, and `DECISIONS.md` E3 already says so.
3. When E3 is built, its **first** gate is the full corpus sweep, not the last — the
   22-vs-608 bracket is the number that decides whether the fixture work is a day or a week.

# 7. The two OWNER QUESTIONS E3 must be opened with

## 7.1 Does a post-measure re-use that deletes a user-written `cq_measure` need to keep its trace line?

(b) makes a second `cq_measure` of the same name lower classically — **no symbol, no gate, no
trace line**. Measured on two shipped fixtures, one of which (`lowering_io_tape_measure_then_tape`)
loses `cqrt_tape_alloc` + `cqrt_tape_write_i32` and emits a `printf` instead. The circuit is
right (measurement is idempotent); the **contract** is the question, and the 7.6 output-tape
ABI is a freeze gate. This is bd `21mg` Q-1, now with a measured customer.

## 7.2 Is the `control_angle_select_ry_alias_pre_gate` regression acceptable, fenced, or fixed?

E3 turns a CHAINED theta into a SOURCE theta, and the folded angle-select's Ry stem requires
a quantum base — so a **shipped, Rule-13-cleared ACCEPT becomes a DECLINE**. Three
dispositions in §2.9. Per the owner's 2026-09-11 ruling an over-decline is a defect, so
"accept and file" is the weakest of the three; but fixing it properly means teaching
`AngleSelectEmit` a classical base, which is its own increment.

*(A third item is disclosed rather than asked: §2.7's `e3q` makes a MEASURED value a legal
rotation angle. It is sound under (b) and is an existing capability reached by a new
spelling, but Rule 3's text says "a quantum-derived angle is a loud decline" and a reader
will trip over it. It belongs in the increment's disclosure paragraph.)*
