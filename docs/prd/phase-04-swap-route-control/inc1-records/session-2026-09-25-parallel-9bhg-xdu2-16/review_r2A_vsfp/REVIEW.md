# Rule-13 round r2A on bd `test_C_libtooling-vsfp` round 2 — the liveness predicate and what it deletes

**Verdict: NOT-CLEAR.** One P1 (introduced; filed bd `test_C_libtooling-otam`), two P2, two P3.

| tag | binary | `cq-opt` sha256[:16] |
|---|---|---|
| SUBJECT | `0a485382` (worktree `agent-abf65d7dcfbff38c8`, its `build/`) | `d17c95e8353711b1` |
| ORACLE | `main` `aee8f4f8`, frozen `scratchpad/frozen/cq-opt.main_aee8` | `69250feaf68bbe49` |
| MUTANT M1 | SUBJECT + `taint = propagate(M, wd)` after `foldVolatileConstAllocaLoads` and `eraseDeadVolatileScalarStores` in `run()` (private worktree, removed) | `0f79b5be1088c69a` |

Harness: `probes/run.sh <S|O|path> <file.c|.ll>` = the `run_slice.sh` pipeline (clang `-O1`, cq-opt,
stage 2b, link, run). All C probes and the stage-1/lowered IR of every exhibit are under `probes/`.
Twins are `<name>T.c` (the same program with the `volatile` line removed, i.e. the fenv-intended
program). No corpus sweep, no allocator sweep, no mutation matrix was re-run (brief).

---

## F-WA-1 — P1, INTRODUCED: the fenv stages' new arm fold GROWS the taint set and nothing re-propagates → rail handles reach classical code, a user `cq_measure` vanishes, and the loop layer accepts what the twin declines

**Mechanism.** Round 2 gave `foldVolatileConstAllocaLoads` and `eraseDeadVolatileScalarStores` a
`deleteDeadCones(F, …, Emptied)` call. When the erased store / folded load was the only thing in an
arm of a TAINTED branch whose merge has a two-entry φ, step 4 of `deleteDeadCones` rewrites the φ to
`select %taintedCond, vT, vF` (+ `MergeBlockIntoPredecessor`, which RAUWs the φ to the select). That
select is a NEW tainted value. Both call sites in `CQLoweringPass::run` ignore the stage's return
value and do not re-`propagate` (`CQLoweringPass.cpp:341`, `:357`). The next `propagate` happens only
if some LATER stage happens to return true (the promotion, slot B's drop, fp80, PredMux…). When none
does, `detectSpecializations`, `declineTaintEscapes`, `lowerLoops` and `lowerOps` run on a TaintSet in
which the select (and, for a φ of constants, everything downstream of it) is CLASSICAL, while control
detection — keyed on the tainted CONDITION — still claims the select as a 4.4 data select and RAUWs it
to its `%out` rail handle. Every classical consumer then computes with a handle.

**Exhibits** (all: SUBJECT `opt` exit 0, **0 bytes stderr**; ORACLE `control flow under quantum
control`; the twin's verdict in the last column):

| probe | C (the arm is `{ volatile int z = 1; r = 5; }`, else `r = 9`) | SUBJECT lowered IR | 2b | twin (SUBJECT and ORACLE agree) |
|---|---|---|---|---|
| `stale3c.c` | `return cq_measure(f(r));`, `f` a same-TU `noinline` helper | `%1 = tail call i32 @f(i32 noundef %out)` / `ret i32 %1` — **no clone, no `cqrt_measure`: the user's measurement VANISHED**, 12 trace lines | STRICT clean (exit 0) | `__cq_q_f_1` lifted, measured, 21 lines |
| `stale4.c` | same, arm emptied by the CONST fold (`volatile int k = 7; … (void)k;`) | identical defect (`call @f(i32 %out)`, no measure) | STRICT clean | = `stale3cT` |
| `loop2.c` | `for (i = 0; i < argc; i++) { if (q > i) {vol; d = 2;} else d = 1; acc += d; } return cq_measure(acc);` | `%9 = add nuw nsw i32 %out, %8` across the back edge, `ret` of the sum — **classical arithmetic on rail handles in a runtime-trip loop, `cq_measure` VANISHED** | STRICT clean | **DECLINE** `cq loop lowering: loop-carried tainted value crosses iterations` |
| `stale3b.c` | `return r + cq_measure(q);` | `%1 = add nsw i32 %m, %out` (handle + measured value) | STRICT clean | `cqrt_addc_i32(%out, %m)` |
| `stale3a.c` | `g_sink = r; return cq_measure(q);` | `store i32 %out, ptr @g_sink` | exit 1 (UNDECIDABLE MEMORY CONSTRUCT — the only exhibit any gate sees) | **DECLINE** `cq taint escape: tainted value stored to memory` |

**Controls.**
- `stale5.c` (in-binary control): `stale3c` plus one unrelated promotable `volatile int w = argc;`.
  `promoteVolatileScalarLocals` now returns true and re-propagates, and the SUBJECT lifts
  `__cq_q_f_1` and measures (21 lines). Same fold, same select — the verdict depends on whether an
  unrelated stage happens to re-propagate. That is the stale-taint signature.
- `CQ_DEADCONE_DBG` on `stale3c`: `volatile-erase deleted 0 in @main (folded 1 empty arm(s))`; on
  `stale4`: `volatile-constfold … (folded 1 …)`. No other deletion event.
- MUTANT M1 (the two call sites re-propagate when the stage returns true): `stale3b`, `stale3c`,
  `stale4`, `stale2` are TRACE-IDENT with their twins (4 of 4 pairs, bash, denominator printed);
  `stale3a` and `loop2` decline with the twin's exact strings. M1 over the shipped suite:
  `lit ir-pass/test` on its own site config (`config.cq_opt` = the mutant, checked) —
  **2363 discovered, 0 failures (lit rc 0)**. So the obvious fix moves no shipped fixture — and,
  equivalently, **no shipped fixture can tell the broken binary from the fixed one** (F-WA-3).
- Red-green proposal: `probes/fwa1_stale_taint_redgreen.ll` (stage-1 IR of `stale3c.c` + a RUN/CHECK
  header): SUBJECT FileCheck **rc 1** (red), M1 **rc 0** (green); ORACLE declines (old verdict).
  Output byte counts were checked (an empty-module run of the first draft was caught that way).

**Class.** CLAUDE.md L1's third species (a TAINT-GROWTH EVENT), in the pre-guard window where a
plain re-`propagate` is the whole cure (no guard has run yet, so no `adjudicateTaintDelta` is owed).
It is also the L3 mirror: a new CALLER (`foldVolatileConstAllocaLoads` → `deleteDeadCones`) was added
to a stage whose header still reads *"folded values are CLASSICAL, so taint is unaffected and no
re-propagate is needed"* (`QramLowering.h`, above `foldVolatileConstAllocaLoads`). And it is the
§4h/§4i vanishing-user-gate class by a new route: the user's `cq_measure` is lowered as a
never-quantum measure (bd 21mg) because its operand's taint was never recomputed.

**Why the round's own fixtures did not see it.** All three fenv-arm fold fixtures
(`spec_accept_dropped_arg_volatile_arm_{const,value,constfold}.ll`) fold a branch in a CALLEE `h` on a
parameter that is classical in module taint, and slot B's drop then fires (`drop arg 0 of @h`) and
re-propagates — measured with `CQ_DEADCONE_DBG`/`CQ_DEADARG_DBG`. No fixture folds a fenv-emptied arm
of a MODULE-LEVEL TAINTED branch with a φ in the merge.

**INTRODUCED:** the ORACLE has no fold (it declines every exhibit at `control flow under quantum
control`); round 1 had no fold in these stages.

**Fix direction (measured, not prescribed):** re-`propagate` after both stages when they return
true (M1), in both entry points; or make `deleteDeadCones` report "created a select" and have every
caller owe the re-propagate. Either way, write the obligation into `DeadValueLiveness.h`'s
`deleteDeadCones` contract as a retirement trigger (L8): *"step 4 can create a tainted `select`; a
caller that does not re-`propagate` afterwards leaves `taint.Tainted` stale."*

## F-WA-2 — P2: three written claims falsified by F-WA-1 (L7 — correct at the source)

1. `QramLowering.h`, `foldVolatileConstAllocaLoads`: *"folded values are CLASSICAL, so taint is
   unaffected and no re-propagate is needed (the foldVolatileConstGlobalLoads precedent)"* — false
   since round 2 added the `deleteDeadCones(…, Emptied)` call (`stale4`).
2. `TRACK_VSFP.md` §R2.4 L1 stage table, rows (5) *"no; the fold's select is on values already
   present"* and (6) *"no; deleted keys self-scrub"* in the "grows taint?" column — false: the
   select is a new value whose taint derives from its condition. The table asked the right L1
   question and answered it wrongly; the round-2 record's own method would have found this.
3. `CQLoweringPass.cpp` slot A: *"It SHRINKS the taint set and grows nothing, so it owes no
   `adjudicateTaintDelta`"* — the drop's fold also mints a tainted select. The CONCLUSION survives
   (the drop re-propagates when it changes anything and no guard has run yet), the ground does not.
   Right conclusion, wrong ground — the §4g/§5 L7 shape.

## F-WA-3 — P2: the mutation matrix has no mutant for the caller-side re-propagate, and the suite is blind to it

§R2.10's matrix mutates the fold (L7/L8/L9, V3/V4) but never the taint freshness after it; M1 above
shows the fixed and broken binaries are indistinguishable over all 2363 fixtures (0 failures either
way). The TRACK's "32 KILLED, 0 MISSED" is true of the mutants it ran and silent on this axis. Pin with
the red-green file above (or its C form, `stale3c.c` / `loop2.c` as e2e slices with their twins).

## F-WA-4 — P3: `runOnFunction` (dead shim) — the drop is a FIFTH module-wide stage and its intrinsic skip is F-scoped

In `runOnFunction` the drop runs after `onlyInF(...)` has filtered `ThetaCalls/PhiCalls/PhaseCalls/
MeasureCalls` to `F`, so `intrinsicSites(taint)` — the drop's LOAD-BEARING skip for a module that
DEFINES a reserved front-end symbol (F-VA-5, `spec_accept_dropped_arg_reserved_symbol_angle.ll`) — no
longer covers other functions' sites: a reviver would zero a user's rotation angle in a function other
than `F`. (The liveness root side is still covered by the reserved-name root.) Harmless while the shim
has zero callers; the shim's AXIS-F hazard list names four module-wide stages and should name this one.
Argued from the code, not constructed (the entry point is unreachable).

## F-WA-5 — P3 (process): scratch collision

This round used `scratchpad/r2A/` for its probes before noticing the directory already held the
bd 9bhg round-r2A working set (05:45–06:50). New files only were added under new names, but
`scratchpad/r2A/run.sh` was overwritten (if that round had one). That round's record is committed
(`review_r2A_9bhg/`), so nothing of record is lost; noted so nobody trusts that `run.sh` as theirs.

---

## What was attacked and held

- **Body-purity exception** (`bodyIsSideEffectFree`), hand-written callees without attributes
  (`probes/purity2.ll`): kept (root) — `load volatile` of a global, `load atomic acquire`,
  `load atomic monotonic`, a body with `unreachable`; deleted — `load atomic unordered`, `sdiv x, 0`,
  a plain `mul`. All deletions are LLVM-legal DCE (UB or unordered); `-O1` would delete each inside
  one TU. No acyclic call-free non-side-effecting body produces a CQ-observable effect (every CQ
  effect is a call, and every call disqualifies the body). `linkonce_odr`/`weak`/`available_externally`
  fail `hasExactDefinition` (argued). `invoke`/`callbr` are terminators (roots). No finding.
- **User gates**: every `cq_*`/`__cq_*`/`cqrt_*` direct call is a root by name even when membership is
  stale; an indirect call is a root; a callee containing any gate has a call so its call site is a
  root; an arm containing a gate is not "empty". No vanishing gate through the deletion itself —
  F-WA-1's vanishing measure comes from stale TAINT, not from deleting the call.
- **Empty-arm / φ fold CFG surgery** (read, plus `stale2`, `stale8`–`stale10`, `loop1`): φ
  availability argument holds (an empty arm defines nothing; its sole predecessor is P);
  third-predecessor merge is left alone (`threepred.c`: SUBJECT = ORACLE decline, the twin accepts —
  an over-decline in the safe direction, not introduced); `br c, X, X` cannot become a candidate
  (`getSinglePredecessor` is null); self-loop and loop-header shapes are refused by `S0 == P` /
  `OnlyOurs`; arms and `S` with address taken are skipped. Angle selects (`stale9`, `stale10`) and a
  select feeding `cq_theta` arg-0 (`stale8`) are TRACE-IDENT with their twins even under stale taint
  (those consumers key on the condition / on final taint). `loop1` (constant trip 3; its lowered shape
  was not inspected) is TRACE-IDENT; only the runtime-trip `loop2` diverges.
- **Passthrough**: both entry points run the drop after the early-out; a no-quantum module with dead
  calls and an emptied-arm shape (`probes/pass.ll`) is byte-identical to `opt -passes=verify` output.
- **Slot A → B window**: by-ref inline (a store-bearing producer, never pure), rail bank (stores are
  roots; `cqrt_alloc` mints are reserved-name roots; allocas marked by metadata), the folds: no raw
  plan held across the window was found (argued from the code; nothing constructed). The one stale
  record in the window is `taint.Tainted` itself — F-WA-1.

## What I did NOT attack

- The emitted circuits, the backstop `declinePhantomCloneArgReads`, `SpecDeadArgMask`, M-C (d0) and
  the 9bhg composition (the concurrent reviewer's surface).
- Whether any post-guard stage can create a tainted select through `deleteDeadCones` (none of its four
  callers runs after the guards today; argued, not constructed).
- A tainted-condition fold whose φ merges two QUANTUM values (the 4.4 both-arms-quantum select) under
  stale taint, and a classical-condition fold over quantum incomings beyond `stale7` (which the
  classical-mux guard declines on both binaries).
- Multi-TU (`llvm-link`) spellings of F-WA-1 (the callee-side fenv fold followed by NO drop), `-g`
  builds, `switch`-terminated arms (not folded by design).
- e2e / ctest on M1 (lit only); corpus A/B, census and allocator sweeps (brief: the implementer ran
  them). The libm census vanishing-subject spot check (item 6) was reduced to the implementer's
  census, which is complete for `deleteDeadCones`/drop events by construction of its two levers.
