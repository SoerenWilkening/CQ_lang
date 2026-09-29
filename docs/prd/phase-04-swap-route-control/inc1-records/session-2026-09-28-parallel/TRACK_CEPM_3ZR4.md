# Track CEPM + 3ZR4 — a Phase-6 call whose lifted callee returns a CLASSICAL value is not tainted at propagation

Session 2026-09-28 (parallel). Branch `worktree-agent-a3c46257bc3bd028d`, based on `main`
`9a230646` (code `c1136be2`). Beads: `test_C_libtooling-cepm` (P2, over-decline) and
`test_C_libtooling-3zr4` (P3, over-decline from C). Both stay OPEN for the Rule-13 rounds.
Probes, harnesses and raw results: `cepm_probes/` next to this file.

> **ROUND 3 (pre-merge, §15)** — the round-2 review's items (comments, fixtures; no pass-code change),
> then the merge of `main` (rhk5 + z0re) and the composition pins (§15.7 onward). The FINAL subject is
> the MERGED binary `cq-opt` `45c895c2f50757a63f583889` (§15.7).
>
> **ROUND 2 (after the Rule-13 round-1 reviews, §14) — READ §14, THEN §12.** The callee seed is
> removed (bd `we38`), a φ-decider must SELECT the incoming, and the P3 comments are fixed at the
> source. The FINAL subject is round 2's `cq-opt` `89186a3011a22882d44bc201`. ⚠ This branch must
> not land alone: landing order is rhk5 → z0re → cepm (§14.4).
>
> **ROUND 1b (commit after `3a2d690e`, §12) — READ §12 FIRST.** The orchestrator ruled that a
> round-2 MASK-GROWTH site (`r2b`/`r2d`) must behave as on the oracle. Round 1b adds a SETTLE
> step and a STICKY rule inside the propagation drain; `r2b`/`r2d` now decline with the oracle's
> string, every other measured verdict is unchanged, and the compiler-kept copy-out class went
> to the owner (bd `ffir`). The FINAL subject is round 1b's `cq-opt` `02522b6a4fdb8911eafe965e`
> (§1). Sections 0–11 describe round 1 and are corrected in place where round 1b falsified them
> (§4.4's L1 table, §5.2.1, §10 item 5).

## 0. Headline

- **The fix is the bead's candidate route, used as written.** `propagateWorklist` — every
  drain — no longer taints the RESULT of a would-be Phase-6 call whose callee
  `predictReturnTainted(callee, <mask this drain sees>)` calls classical
  (`specCallResultPredictedClassical`, SpecializeClone.{h,cpp}). No stage before
  `specialize()` then reads the integer as a register, so bd l3oi's fence has nothing
  to refuse. `specialize()` CHECKS the prediction and declines loudly if a clone returns
  a register where propagation predicted a classical result
  (`kMsgPredictedClassicalQuantum`).
- **bd cepm's population is C-REACHABLE after bd vsfp, and larger than the bead says.**
  The bead (and the six `taint_reject_scrubbed_handle_*.ll` headers) says a callee that
  READS its argument yet returns classical is "IR-ONLY from C at -O1" / "C-reachable only
  via `volatile int z = a;`". Both are FALSE, measured:
  - `volatile int z = a;` is erased by the fenv stage and the argument then dropped
    (battery `selvl`: ACC-SAME on the oracle — not a member).
  - A read that reaches a call the pass cannot prove pure IS a member from C: `h(a, k)
    { g(a); return k + 1; }` with `g`'s own callee in another TU, so `-O1` infers `g`
    nothing and `DeadValueLiveness` keeps the call as a ROOT. With that callee the
    oracle declines **every** shape the bead lists — the l3oi branch/select/phase/clone-
    reader shapes, d88e's `l19`/`a03`/`a04`/`l04`, 9bhg's return-across-a-boundary shape,
    a switch, a classical φ, a loop body, a printf — and the subject accepts each one
    TRACE-IDENTICAL to its hand-inlined twin (§5).
- **bd 3zr4 on `main` is not the ordered-scrub mechanism its text describes.** That
  mechanism (`specialize()` draining `Pending` in storage order and re-computing masks)
  is bd 9bhg's PARKED branch (tag `archive/2026-09-27/9bhg-provisional-return`), never
  landed. On `main` the round-2 site's result was tainted conservatively in round 2,
  `replanReseedSpecialization` grew the round-1 reader's mask to `11`, its clone read the
  integer as a handle, and bd l3oi's clone-reader clause declined. The bead's own repro
  (`h(a,k) = k + 1`) ACCEPTS on the oracle since bd vsfp (its argument is dropped:
  battery `z3ig`). With a READING callee (`z3`) the oracle declines and the subject
  accepts, twin-identical. The same change fixes it: the round-2 drain asks the same
  predictor, so the stale mask is never built — no sort, in any drain order.
  ⚠ The four "falsified comments" the brief names (`specialize()`'s "Pending is in
  LAYOUT order", `declineScrubbedHandleReads`' "Pending is in layout order",
  `TaintPropagation.h`'s "a use laid out before its definition", the `_layout.ll`
  retirement trigger) are NOT on `main` (grep: 0 hits; `…_clone_arg_layout.ll` does not
  exist). They live on the parked 9bhg branch; nothing to correct here.
- **One L3 finding, fixed in the same change.** `classifyClassicalCallArm` (6.5) used
  "the call's RESULT is untainted" as its proof that every INPUT is classical, and said
  so in writing. bd cepm falsifies that proxy. The classifier now asks the inputs
  (`readsTaintedValue`, exported for it), which keeps the 6.5 population exactly the
  oracle's (§4.3).
- **What still declines, and why.** bd l3oi's fence keeps a population: sites the
  predictor over-approximates — an inner clone that returns classical (C-reachable,
  battery `in2`, fixture `spec_reject_predicted_classical_inner_clone.ll`) and a tainted
  branch that does not reach the return (IR-only; the six l3oi fixtures' empty diamond).
  These are the safe direction and unchanged from the oracle.

## 1. Binaries (sha-256 prefixes, measured)

| binary | cq-opt | libCQPass.so | note |
|---|---|---|---|
| ORACLE `main` 9a230646 (frozen) | `3f6db37f5cf937b4d70f5736` | `356df92e0b58bbf787c41a25` | |
| worktree, unmodified | `3f6db37f5cf937b4d70f5736` | `356df92e0b58bbf787c41a25` | BUILD NULL CONTROL: bit-identical |
| subject v1 (before the §4.3 L3 fix) | `f9ee08b029dc3807865a8339` | — | battery `new1` only |
| subject round 1 (commit `3a2d690e`) | `cb4ed3c2f6251bc7e85bf8dc` | `d3e11a7e55d0b18966d62c84` | `cq-opt-debugalloc` `3b9f963b1da8351197ac0d6e`; frozen copy `scratchpad/cepm/cq-opt.subj1` |
| subject round 1b (commit `7f0be42f`, §12) | `02522b6a4fdb8911eafe965e` | `49e7c01f5c0ba2417e287ddc` | `cq-opt-debugalloc` `d73534dc2decb0c933d87d22`; frozen copy `scratchpad/cepm/cq-opt.subj2` |
| **SUBJECT (final, round 2, §14)** | **`89186a3011a22882d44bc201`** | **`7dfff7e13c395111f3818d5c`** | `cq-opt-debugalloc` `ce5f3060e69a5e17904b02af`; frozen copy `scratchpad/cepm/cq-opt.subj3` |

The comment-only L7 edits made after `cb4ed3c2` was frozen rebuild to the SAME hash
(`cb4ed3c2`, measured), so every round-1 measurement in §§5–6 is on the round-1 binary; §12's
are on round 1b's (whose later comment edit also rebuilt to the same hash, measured). After the
mutation builds the restored tree rebuilt bit-identical to it (`cb4ed3c2`).

## 2. Mechanism (measured, read off the lowered IR — Rule 11)

### 2.1 Why the bead's members stopped reproducing, and what still does

Every probe in the bead (d88e's `l19`/`a03`/`a04`/`l04`, the l3oi fixtures, 3zr4's repro)
uses a library `h(a, k) = k + 1` that IGNORES `a`. bd vsfp's `dropDeadCallArguments`
rewrites such an argument to `0` before propagation, so the call is not a Phase-6 site
and `t` is classical from the start — the oracle already compiles those like their twins
(`selig`, `z3ig`: ACC-SAME on the oracle).

A pure callee (the only kind `scanBody` accepts) keeps a parameter LIVE only through a
liveness ROOT (`DeadValueLiveness.h`): a terminator, or a call whose purity the pass
cannot prove. `clang -O1` deletes an empty diamond, so from C the root is a call:

```c
// TU vh:  void g(int a);  int h(int a, int k) { g(a); return k + 1; }
// TU vg:  int f2(int a);  void g(int a) { f2(a); }        // f2 external: g gets no memory(none)
// TU vf2: int f3(int a);  int f2(int a) { return f3(a) + 1; }
// TU vf3: int f3(int a) { return a * 3; }
```

`g`'s call is a root (no inferred attributes, and its body holds a call so the body rule
does not clear it), so the drop keeps `a`, `scanBody` accepts `h` (it recurses into `g`,
`f2`, `f3`), and `h(q, m)` is a Pending site with mask `01`. On the oracle its result is
tainted in the drain (`propagateWorklist` taints every user of `q`), every round-1 stage
reads it as a register, and `specialize()` proves `__cq_q_h_01` classical only after both
control rounds — then bd l3oi's fence (or an earlier owner acting on the conservative
taint) declines.

A second family (`…i`, `g` returning `int`, 3 TUs) is also C-reachable and behaves the
same in C; its hand-inlined twin differs (§5.2).

### 2.2 bd 3zr4 on `main`

`z3` (`if (q > 5) y = ext_f(7); t = h(y, m); u = g2(t, q);`), oracle:
- round 1: `y` classical (6.5 arm), `h(y, m)` not a site, `t` classical, `g2(t, q)` Pending
  mask `10`;
- round 2: `y` = `%out`, the drain taints `h`'s result `t`, `detectSpecializations(…,
  &live)` appends `h(y, m)` (mask `01`), `replanReseedSpecialization` grows `g2` to `11`;
- `specialize()`: `g2`'s clone `__cq_q_g2_11` takes `t` in a HANDLE slot; `h`'s clone
  returns classical; `scrubForwardCone(t)`; l3oi's clone-reader clause refuses.

Subject: the round-2 drain asks `predictReturnTainted(h, 01)` — false — so `t` stays
classical, `g2` is never re-planned, and `main` calls `__cq_q_g2_10(t, h_q)` with `t` in
the literal slot (fixture `spec_accept_predicted_classical_round2_site.ll`).

## 3. The change

1. **`specCallResultPredictedClassical(CI, taint)`** (SpecializeClone.{h,cpp}) — the one
   spelling of "propagation may leave this call's RESULT classical". True iff `CI` is a
   direct `CallInst` to an exact, non-intrinsic, non-variadic, non-reserved-name
   (`cq_`/`__cq_`/`cqrt_`) DEFINITION of arity ≤ 64, called with its own function type,
   non-void, not a front-end intrinsic site (by membership), with ≥1 tainted argument,
   and `!predictReturnTainted(callee, taintArgMask(CI, taint))`. Every conjunct except the
   last only NARROWS where the prediction is asked (a false answer is today's taint).
   `predictReturnTainted` is now declared in SpecializeClone.h (it was file-local in
   practice) — Rule 14: the SAME predictor that already decides the fp-return signature.
2. **`propagateWorklist`** (TaintPropagation.cpp): a `CallInst` user for which the
   predicate is true is NOT inserted into `Tainted` (and not pushed). It is not marked
   visited: a later drain that taints another argument reaches it again and re-asks with
   the grown mask. The 3jru return crossing still inserts call sites of a function whose
   `ret` is tainted, whatever the predicate says.
3. **The check in `specialize()`** (Specialization.cpp): `ResultWasTainted` is read on the
   Pending site BEFORE `resolveSite` (an fp-return retarget erases the call); if the clone
   `ReturnTainted` and the result was not tainted, `kMsgPredictedClassicalQuantum` —
   "cq specialization: lifted callee returns a quantum register where propagation
   predicted a classical result". ⚠ Round 1 called it "argued UNREACHABLE (§4.1)"; since round
   1b it is the STICKY rule's designated backstop, reached by a REPLANNED MASK with the callee body
   untouched (§12.3, Rule-13 r1A F-r1A-3). Pinned by mutants only (§6, §12.5): no C program reaches
   it on the shipped predictor.
4. **The 6.5 L3 conjunct** (ArmClassify.cpp `classifyClassicalCallArm`): `||
   readsTaintedValue(*Call, Taint)` beside the result-taint test; `readsTaintedValue` moved
   out of TaintPropagation.cpp's anonymous namespace and declared in TaintPropagation.h.
5. **L7 at the source**: the `specialize()` §2.7 comment ("conservatively tainted EVERY
   specialized-call result"), `predictReturnTainted`'s "Affects ONLY the fp-return
   rewrite … inert there", `propagateWorklist`'s "except measure sinks and the arg-1
   angle", 6.5's "a CLASSICAL result therefore proves every input is classical",
   ArmClassify.cpp:3726 and MergePhiPeel.cpp:573's "taints EVERY user", and two lift
   comments in TaintPropagation.cpp (`liftOneRegisterMergePhi`'s d88e block,
   `declineFalsifiedMergePhiLifts`' "(5)" argument). The false "IR-ONLY from C" claim is
   corrected in the six l3oi fixtures and annotated in the 23 other fixtures that repeat
   it; `lowering_reject_classical_mux_phi_spec_scrubbed_base_fp.ll`'s header is
   additionally wrong in a way that predates this change (§8).

## 4. Soundness argument — what a reviewer must break

### 4.1 predict == false ⟹ the clone's `ReturnTainted` is false

`buildClone`'s verdict is `RV ∈ cloneTaint.Tainted`. `cloneTaint` starts as `seedClone`'s
closure — the same forward-user closure from the masked parameters that
`predictReturnTainted` computes on the callee (the clone is a verbatim / type-remapped
copy). Every later stage only removes taint or replaces a member of the closure:
- `normalizeReturnMerge` adds a φ of the returns (a user; tainted only if a return is);
- `lowerCloneControl`'s PredMux flatten claims only diamonds whose terminator is in the
  closure — `predictReturnTainted` returns TRUE for any tainted conditional terminator —
  and reseeds by the same closure;
- the inner-call drain SCRUBS classical inner results (only removes) and re-inserts a
  rebuilt inner call that was already a closure member;
- the dead-slot deletion only deletes;
- `lowerCloneSelect`, `lowerQramReads`, `lowerOps` RAUW members of the closure (a tainted
  select / load / op) with a tainted replacement.
So an untainted `RV` stays untainted. The argument assumes the callee body at `specialize()`
is the body the drain saw; every stage in between that mutates a function body is
taint-driven and a pure callee holds no module taint (`scanBody` rejects any `cq_*` in
the callee's transitive body), and the pre-detection normalisers each re-`propagate`.
That assumption is CHECKED, not trusted: §3 item 3.

### 4.2 Every call the predicate leaves untainted is a Phase-6 site or a loud decline

It reads a tainted argument and calls a definition, so `detectSpecializations` (round 1,
or round 2 on its reseed set — every argument tainted in round 2 is in that set, and
MergePhiPeel's growth goes through `adjudicateTaintDelta`) puts it in `Pending` or
diagnoses it. One in neither is refused by `declineTaintEscapes`' `kMsgUnknownCallee`
(it asks `readsTaintedValue`, not the result). For a Pending site the §3 item-3 check is
total over `plan.Pending`.

### 4.3 The L3 finding: 6.5 used the result as a proof about the inputs

`classifyClassicalCallArm`'s first gate was `Taint.Tainted.count(Call)`, documented as
"it IS the all-classical-INPUTS check … a CLASSICAL result therefore proves every input is
classical". With the change a predicted-classical site in a tainted-condition arm passed
that gate; measured on battery `va` with subject v1: the region stopped declining at
`classifyArms` ("value-arm swap-route", the oracle's and the twin's string) and declined
inside 6.5 ("control flow", `doesNotAccessMemory` false for a root-reading callee). A
callee that IS `memory(none)` and has a tainted argument that survives the drop (IR-level:
e.g. a string attribute on the parameter) would pass 6.5's remaining gates and be HOISTED
by its emitter. The fix asks `readsTaintedValue` — which restores the oracle's 6.5
population exactly (`va` DECL-SAME again; 0 lit movers).
**The semantic question, answered but not relied on:** a predicted-classical clone call is
Bennett-wrapped with no output rail — identity on its quantum arguments plus a classical
value — so executing it unconditionally is unitary-correct. The conjunct is kept anyway:
6.5 is "clone-orthogonal" by design, and the review surface of a new accept path through
it is not this bead's.

### 4.4 L1 — every drain, and what reads the prediction before it is checked

| drain / stage | asks the predictor? | premise a later event can falsify | where it is re-asked |
|---|---|---|---|
| `propagate` (each of ~12 calls before detection) | yes (in `propagateWorklist`) | mask grows later | next drain that taints the argument revisits the call (monotone) |
| `declineStaleTaintSet` (fresh `propagate` vs carried) | yes — same rule both sides | — | — |
| round-2 `repropagateControlMerges` drain | yes | mask grows in round 2 (`r2g`/`r2b`: round-1 `01` classical, round-2 `11` quantum) | ⚠ ROUND 1 said "the round-2 drain itself: `t` is tainted IN ROUND 2" — that is what accepted `r2b`/`r2d` and it is REPLACED in round 1b (§12): the round-1 SETTLE step taints such a site at round 1, and a site still classical from an earlier drain is STICKY (never tainted later; `specialize()`'s check declines if its clone returns a register) |
| `detectAndLowerOnwardControl`'s drains | yes | same | same (each drain opens a new generation) |
| `propagateFromSeeds` (MergePhiPeel ×3, delta) | yes | same | same |
| every stage between the last drain and `specialize()` (both control rounds, lowerLoops, IO/QRAM/Shadow, promote, classical-mux guard + lift) | read the result as CLASSICAL | the clone returns a register (argued impossible, §4.1) | `specialize()`'s check, in both entry points (the shim calls `specialize()` too); `DS_Error` exits, so nothing a window stage did reaches the output |

**Does the change GROW taint?** No — it only withholds it (the set is a subset of the
oracle's at every point before `specialize()`). **Does it shrink taint at a new site?**
Yes: the withheld result and its forward cone. That cone was previously scrubbed by
`specialize()` for a classical verdict; now it is never tainted, so the scrub finds
nothing to scrub (`taint.Tainted.count(Site)` false) and bd l3oi's record stays empty for
it.
**Round-2 shift (r2g/r2b/r2d/r2l).** ⚠ SUPERSEDED BY ROUND 1b (§12). Round 1 tainted a
round-1-recorded site whose return depends on a round-2 argument IN ROUND 2, and `r2b`/`r2d`
moved oracle DECLINE → ACCEPT with streams that are not the twin's (§5.2.1). The orchestrator
ruled they must behave as on the oracle; round 1b taints such sites at round 1.

### 4.5 L2 — other sets computed over the same closure

The 3jru crossing (same drain; unaffected — it inserts directly); `ScrubbedByReturnTaint`
(filled only by the scrub, which now skips these sites); `SpecHandleArgMask` (the clone's
mask — unchanged); `HandleWidth` for a rebuilt fp result (only for `ReturnTainted`);
`BirthOrder`/`StaleDeclined` (keyed on tainted values, so a never-tainted result has none).
Stage-level sets that were built over "the call result is tainted": the loop unroll
prepass's U7 relevance bit (`lp`: the oracle's loop declined `loop-carried tainted value`;
the subject leaves the loop rolled and classical; twin-identical, 124 lines), the value-arm
cone (K5 rejects calls regardless), PredMux E4 (asks `TaintedArg` explicitly).

### 4.6 L3 (narrowing) and its mirror

Narrowing `Tainted` — the other predicates naming "this call is quantum": 6.5 (§4.3,
fixed), `declineTaintEscapes` (operand test, unaffected), M-A's clause-1 record walk
(crosses a clone call to its result regardless of taint: an over-WARN, §8, bd `9k30`), the
free-pairing checker (models every `__cq_q_*` result as a rail: §8, bd `jzwo`).
Adding a caller to a shared predicate: `predictReturnTainted` gains its second caller. Its
header's retirement trigger ("an int/void return never consults it, so this is inert
there") is now false and is corrected; the direction this caller uses it in is the one its
header certifies (`false` ⟹ classical).

## 5. Measurements (what I ran, literally)

### 5.1 Red-green (lit fixtures written from the battery's stage-1 modules)

`cepm_probes/redgreen.py BIN ir-pass/test/spec_*_predicted_*.ll`:
- ORACLE: 18 fixtures, **5 pass, 13 fail** — the 12 ACCEPT fixtures (red: the oracle
  declines each) and `spec_reject_predicted_classical_stale_record.ll` (red: the oracle's
  string is the early stale-record owner's, not the twin's).
- SUBJECT: 18 fixtures, **18 pass**. Under lit: `lit -j4 ir-pass/test --filter predicted`
  18/18 passed.
- The 5 fixtures green on both are pins whose red is a mutant: `…_value_arm` (M8),
  `…_inner_clone`, `…_memory_escape`, `…_recursive_subcall`, `…_some_paths` (no change
  intended; they pin that the predictor stays conservative / `scanBody` still refuses).

New fixtures: ACCEPT `spec_accept_predicted_classical_{branch,select,phase,return,
clone_arg,lift,loop_break,bank,fp_return,switch,classical_phi,round2_site}.ll`; DECLINE
`spec_reject_predicted_classical_{inner_clone,value_arm,stale_record,memory_escape,
recursive_subcall}.ll`, `spec_reject_predicted_quantum_some_paths.ll`.

### 5.2 The twin battery (`cepm_probes/run.sh`, twincmp: argv `5 7` and `2 9`, 2b STRICT)

**Denominator: 66 pairs** (`results/battery_{oracle_9a230646,subject_cb4ed3c2}.txt`, final run
on the frozen oracle and the frozen subject copy): ORACLE **18** twin-identical, SUBJECT **43**.

Final subject, every member (see `results/` for the raw lines). "v" = void-`g` family
(exact twin), "i" = int-`g` family.

| member | ORACLE | SUBJECT | reading |
|---|---|---|---|
| br, sel, ph1, l19, a04, rt9, yc, yb, z3, ch, cph, fp, sw, lp, pr, tp, tre | DECLINE (various owners, C only; twin accepts) | **ACC-SAME** | the cepm/3zr4 population, twin-identical |
| ar, ang, un, lk, j2 | ACC-SAME | ACC-SAME | unchanged (no consumer read the conservative taint) |
| a03 (+ a03i) | DECLINE `rail bank` | ACCEPT; traces identical to the twin by hand, 2b CANNOT adjudicate (§8) | cepm; instrument gap |
| l04 (+i), ld | DECL-DIFF | **DECL-SAME** | now declines at the twin's owner |
| va, pa, pk, pk2, gs | declines | DECL-SAME (va: after §4.3; subject v1 was DECL-DIFF) | a site inside a quantum arm still declines with the twin's string |
| in2 (+i) | VERDICT-DIFF (l3oi) | VERDICT-DIFF (l3oi) | predictor over-approximates through an inner clone: the fence's remaining C population |
| np, nr2 | VERDICT-DIFF | VERDICT-DIFF | pre-existing clone fences (mixed select; a recursive CLASSICAL subcall) — predict-true / scanBody, unchanged |
| nm, selvg | DECL-DIFF | DECL-DIFF | memory escape refused by `scanBody` (twin: store escape) |
| nd, r2l | DECL-SAME | DECL-SAME | unknown callee; round-2 loop |
| selvl, selig, z3ig, nr | ACC-SAME | ACC-SAME | callee's argument dropped by bd vsfp: not members |
| r2g | ACC-DIFF | ACC-DIFF | pre-existing: `-O1` folds `(y+1)*2` to `shl`+`addc` in the twin only; same value |
| r2b | DECLINE `control flow` | ACC-DIFF (§5.2.1) | cepm moves `t`'s taint to round 2 (the twin's timing); a QUANTUM-returning clone, so C keeps its copy-out rail `t = copy(y+1)` allocated where T's `-O1` folded `y + 1 > 3` to `y > 2` |
| r2d | DECLINE | ACC-DIFF, both WARN `live derived record` (§5.2.1) | as r2b plus a trailing Ry on `y`: C's extra rail is a live derived record of `y` across that Ry |
| nq, nq2 | ACC-DIFF / DECL-SAME | same | quantum-returning callee: predict true, unchanged |
| zl12, zl17, za02, za01 | **C ACCEPTS** (side door), T declines | **DECL-SAME** | bd z0re's side door (§9) |
| all `…i` (int-`g`) members | as their "v" twin but ACC-DIFF where "v" is ACC-SAME | ACC-DIFF | the twin's top-level `g(q)` leaves g's result rail allocated (a known twin-side leak; warned when a non-diagonal gate follows: `lki` both warn); h's clone discharges it in its own Bennett wrap. C differs from T by exactly g's reverse block |

#### 5.2.1 ⚠ r2b / r2d — two D→A moves that are NOT twin-identical, disclosed (ROUND 1 — FIXED in round 1b, §12: both decline again, as on the oracle)

These are the round-2 MASK-GROWTH members (`h(q, y)`, `y` a 6.5 `%out`): the round-1 mask
`01` predicts classical, the round-2 mask `11` predicts (and is) QUANTUM (`k + 1` over `y`).
On the oracle `t` was tainted in round 1, and the region `if (t > 3) q2 = cq_theta(q2, .2)`
declined `control flow` in round 1; on the subject `t` is tainted in ROUND 2 — exactly when
the twin's `t = y + 1` is — and the round-2 emitter accepts it, as it accepts the twin.
The traces differ ONLY by the clone's computation (measured, `r2dC`/`r2dT` argv `5 7`):

```
C:  cq_template_add_i32_hl(h2, 1) -> h14 ; alloc h15 ; copy h14→h15 ; add_unc ; free h14   (the clone)
    … cq_template_icmp_sgt_i32_hl(h15, 3) -> h17 ; ry_controlled(h17, q2, .2) ; icmp_unc ; free h17
T:  … cq_template_icmp_sgt_i32_hl(h2, 2)  -> h15 ; ry_controlled(h15, q2, .2) ; icmp_unc ; free h15
```

C leaves `h15 = copy(y + 1)` ALLOCATED: a quantum-returning clone's result is a rail the
spine does not discharge here, and `-O1` could not fold `h`'s `k + 1` into the compare
across the TU boundary. That is the PRE-EXISTING behaviour of every quantum-returning
Phase-6 call — the oracle's `nq` (`h = a + k`, no cepm involvement) is ACC-DIFF against its
twin for the same reason, and `tests/e2e/slice_spec_lift_quantum_base` pins such a stream on
`main` with the owner's lyyf-(B) `live derived record` warning. In `r2d` a trailing Ry on `y`
makes `h15` a live derived record of `y` across a non-diagonal gate; BOTH sides print the
warning (T for `y`'s own 6.5 construction). For this program the measured distribution is
unaffected (`y` is already a function of the live `q`, so the extra copy adds no which-path
information), but in general it is the lyyf-(B) dephasing class. **"Pre-existing" is true of
the defect and FALSE of its population: cepm routes the round-2 mask-growth shape into it**
(the oracle declined these two). Not a P1 by the owner's lyyf-(B) ruling (warned, "the user's
circuit"); flagged for the reviewers (§10 item 5).

### 5.3 Corpus A/B vs the frozen ORACLE (`cepm_probes/ab.py`; NULL CONTROL = subject twice, run FIRST)

| set | denominator | null | movers |
|---|---|---|---|
| `ir-pass/test/*.ll` | 2425 | 0 of 2425 | 13: **12 D→A** (the 12 new ACCEPT fixtures) + **1 STRING** (`…_stale_record.ll`, the new fixture). 0 pre-existing fixture moved |
| `tests/e2e/*.c` stage 1 (default CASE + CASE matrices; 25 of 633 need other TUs/flags, not swept) | 608 | 0 of 608 | **0** |
| `run_slice_multi.sh` registrations (llvm-linked) | 36 | 0 of 36 | 2 D→A: the two new subject slices |
| probes: prior 9bhg / d88e / r2B-9bhg sources (245 built of 246) + this battery (132, final) | 377 | 0 of 377 | 38, ALL from this battery: **30 D→A** (the cepm/3zr4 members + `r2b`/`r2d`, §5.2.1) + **4 STRING** (`l04C`, `l04iC`, `ldC`, `gsC` → each now the twin's string) + **4 A→D** (`zl12C`, `zl17C`, `za02C`, `za01C` — bd z0re's side door closing, each now declining with its twin's exact string, §9). 0 prior-session probe moved (the d88e/9bhg/r2B sources all use an `h` that IGNORES `a`, which bd vsfp's drop already handles) |

Allocator sweeps (`cepm_probes/allocsweep.py`: plain `cq-opt` vs `cq-opt-debugalloc` under
`CQ_OPT_DEBUG_ALLOC=lifo` and `=nofree`; exit, stdout sha, first error): lit corpus **2425
modules, 0 disagreements**; probe corpus **377 modules** (final list), **0 disagreements**.

Affected ctest entries (`ctest -j2 -R 'spec|specialize|classical-call|scrub|cq-opt-equivalence|free-pairing-selftest'`):
**53/53 passed** (incl. the 6 new e2e entries, `taintset-scrub-guard{,-selftest}`, the
sampled `cq-opt-equivalence`, every `e2e-slice-spec*`/`specialize*`/`control-spec*` slice).

### 5.4 e2e

`ctest --test-dir build -R 'spec-predicted-classical'`: 6/6 passed —
`e2e-slice-spec-predicted-classical-{branch,round2}{,-twin}` and
`e2e-spec-predicted-classical-{branch,round2}-twin-identical`. Goldens: branch 34 lines,
round2 53 lines, both BYTE-IDENTICAL to their twins; stage 2b STRICT on all four (branch
`7 verified`, round2 `10 verified`, 0 violations, 0 unproven). RED on the ORACLE: both
subject slices decline (`goldens.sh <oracle> check`), the twins are unchanged.
⚠ The branch subject prints the M-A `non-diagonal gate over a live derived record` warning
and its twin does not (§8); the e2e gates compare traces only.

### 5.5 lit

`cd build && lit -j4 ir-pass/test` on `cb4ed3c2`:
- before the new fixtures: **2407 discovered, 2406 passed, 1 XFAIL, 0 failed** (500 s under
  load);
- FINAL (18 new fixtures + every header correction): **2425 discovered, 2424 passed, 1 XFAIL,
  0 failed** (241.6 s).

## 6. Mutation matrix (`cepm_probes/mut.py`, `fixrun.py`, `mutowner.py`)

Each mutant is a textual source patch built as `cq-opt` only; the restored tree rebuilt
bit-identical to the subject (`cb4ed3c2`, measured after the batch). `fixrun.py` emulates each
fixture's RUN lines with `%cq-opt` := the mutant (17 fixtures using `%debugalloc-cq-opt` are
SKIP, never PASS; 1 XFAIL). N0, M1 ran over ALL 2425 fixtures; every mutant ran over the
**484-fixture subset** that calls a function DEFINED in its module (`subset.py` — the predicate
is false for every other call, so a module outside the subset is byte-identical under every
mutant of it; the whole-corpus N0/M1 results equal the subset's). A kill = a fixture the
subject passes and the mutant does not.

| mutant | removes / forces | result |
|---|---|---|
| N0 | nothing (a `getName().size() > 1e9` conjunct that changes the binary) — NULL | **0 of 2425** (whole corpus), 0 of 484 |
| M1 | the prediction (`specCallResultPredictedClassical` always false = the oracle) | **KILLED 13 of 2425**: the 12 ACCEPT fixtures + `…_stale_record` — each back at the oracle's owner |
| M2 | the non-void conjunct | MISSED — a void call has no reader; argued equivalent |
| M3 | the reserved-name conjunct (`cq_`/`__cq_`/`cqrt_`) | MISSED — no fixture defines a reserved-name callee called with a tainted argument; scope conjunct (§3 item 1) |
| M4 | `hasExactDefinition()` | MISSED — an interposable callee is refused by `scanBody` at detection either way (same string) |
| M5 | the `specialize()` check | MISSED — no subject exists with the round-1 predictor (§4.1). ⚠ Since round 1b the check is the sticky rule's backstop and IS reached by R1/R4/R5 (§12.5) — "argued unreachable" is round-1 text |
| M6 | a WRONG predictor: every site predicted classical, check ON | **KILLED 100 of 484 — 87 by the `specialize()` check itself**; 5 decline earlier at the classical-mux guard, 1 at F1; the remaining 7 are sites whose clone IS classical (the six l3oi fixtures + `…_degenerate`), where "always classical" is right and they now accept |
| M7 | the same wrong predictor with the check OFF | KILLED 24 of 484 (14 accept with a wrong stream, 4 ABORT at exit 134) — **76 fixtures that M6 declines ACCEPT under M7**: the check is the ONLY thing standing between a wrong predictor and those modules |
| M8 | the 6.5 `readsTaintedValue` conjunct | **KILLED 1**: `spec_reject_predicted_classical_value_arm.ll` (the string moves to 6.5's `control flow`) |

Totals: 8 mutants + the null; 4 KILLED (M1, M6, M7, M8), 4 MISSED (M2, M3, M4 argued
scope/equivalent; M5 argued unreachable, and M6-vs-M7 is its positive control: the check is
REACHABLE and load-bearing the moment the predictor is wrong). The one "other move" under
M6/M7, `lowering_reject_break_uncollected_clone.ll`, is a SKIP fixture whose first RUN (plain
`%cq-opt`) failed before the runner reached its `%debugalloc-cq-opt` line.

## 7. What I did NOT run / attack

- The full `ctest -j6` (Rule 19: the merge gate).
- `cq-opt-equivalence-full` (only the sampled ctest entry ran). The one new diagnostic is
  the argued-unreachable `specialize()` check, reached only under mutants M6/M7.
- `+Asserts`, Guard Malloc.
- `invoke` sites (excluded by construction), callbr, a callee reached through an alias.
- A Pending site whose callee body is mutated between the last drain and `specialize()`
  — argued impossible (§4.1), no construction attempted beyond the mutant.
- Recursion INSIDE the predictor (the `in2` residual) — out of scope, §8.

## 8. Findings and beads

- **Instrument gap (P3, NEW bd `test_C_libtooling-jzwo`):** `tools/free_pairing_check.py` models every
  `@__cq_q_*` call result as a rail. A classical-verdict clone result stored to memory
  (`a03`) is refused as `UNDECIDABLE MEMORY CONSTRUCT [L1-rail-stored-to-unmarked-memory]`,
  and the census counts such a result as "template rail left dirty" (`br`: 8/1 vs the
  twin's 7/0). PRE-EXISTING model; this change makes the shape reachable.
- **Over-WARN (P3, NEW bd `test_C_libtooling-9k30`):** M-A's clause-1 record walk crosses a clone call to its
  RESULT without asking whether that result is quantum, so a classical-verdict clone call
  reading `q` makes a later non-diagonal gate on `q` warn `live derived record`.
  PRE-EXISTING on the oracle (`ang`, `un`, `lk`, `j2` warn and accept there); this change
  adds customers (`br`, `fp`, `ch`, `cph`, `yc`, `sw` — traces twin-identical). ⚠ **`tp` was
  listed here in round 1 and that was WRONG** (Rule-13 r1B F-r1B-1): `tp` (`p = q * 3; t = h(p, m);
  if (t > 3) q = cq_theta(q, .2)`) is NOT an over-warn. The template rail `p` is passed only to the
  classical-verdict clone and never uncomputed before the Ry on `q` — a which-path record of `q`
  across a non-diagonal gate, a TRUE positive and a wrong unitary on BOTH sides (C and its twin
  alike). That is bd `rhk5`'s defect (a clone call inside a derived chain's discharge window);
  cepm routes the branch/switch/xor spellings `tp`/`tps`/`tpx` into it (the oracle declined
  them; `tpk`, the same leak with no branch on `t`, accepts on the oracle). On cepm + rhk5 both
  sides discharge `p` before the Ry (r1B measured). See §14.4 for the landing-order note.
- **Stale fixture header (P3, NEW bd `test_C_libtooling-swtv`; pre-existing, noted in the file):**
  `lowering_reject_classical_mux_phi_spec_scrubbed_base_fp.ll` says "the added lines in
  `@hf` (a branch-only read) keep the parameter live" — `@hf` has none, and the file's
  CHECK pins that the drop FIRES; its decline is the classical-mux guard on a classical
  `t`, so bd d88e's fp-base re-ask has no fp subject here (Rule 12 (c)).
- **Residuals of cepm (notes on the bead, not new beads):** the predictor is not recursive
  (`in2`), and treats any tainted branch as reaching the return (IR-only). Both keep bd
  l3oi's fence populated.

## 9. Composition with bd z0re (a) (the parallel track)

With the READING callee, d88e's side-door programs accept on the ORACLE (the arm is an
in-place Ry on the conservatively tainted "register" `t`) and their twins decline
(`state prep seed does not match the merge incoming` ×3, `rotation angle` ×1). On this
branch they follow the DIRECT path and decline **with their twin's exact string**
(`zl12`, `zl17`, `za02`, `za01`: DECL-SAME, 4 of 4). These are **A→D movers on this
branch alone** for reading-callee programs; after bd z0re (a) lands they should accept on
the direct path. The d88e originals (`l12C` etc., callee ignoring `a`) are unaffected: the
drop already sends them down the direct path on the oracle (0 movers in the probes set).
`r03C` was not found in any record on `main`.

## 10. ATTACK FIRST (for the Rule-13 reviewers)

1. **§4.1's closure argument.** Find a clone stage that ADDS a value to `cloneTaint` that is
   not a replacement of a closure member, or a PredMux claim in a clone whose terminator is
   not in the closure. `materializeCopySource` inserts rails for CLASSICAL select arms —
   show one reaching `RV`.
2. **The callee body changing between the drain and `specialize()`.** Any stage that edits a
   function body with no module taint after the last `propagate` (the dead-arg drop's
   slot B, `deleteDeadCones`, the fenv folds, PredMux, the unroll/ctlz prepasses — each is
   followed by a re-`propagate`; verify the order in BOTH entry points, incl. the
   `runOnFunction` shim). If one exists, the guard should fire; construct it.
3. **The guard's totality.** `ResultWasTainted` is read before `resolveSite`; a Pending site
   ERASED or REBUILT before `specialize()` (an emitter that clones or RAUWs a spec call)
   would carry a stale pointer. Enumerate who moves/clones a `CallInst` with a tainted
   argument before `specialize()`.
4. **Other result-as-input proxies (L3).** I fixed 6.5. Search every predicate that decides
   "classical, so hoist/speculate/flatten/ignore" from `Tainted.count(I)` for an `I` that
   can be a call: phase-arm stray-op rules, switch-arm proofs (`SwitchArmProve` mirror),
   GuardedStoreArm, AbortPark, the loop layer's invariance and iteration-local walks,
   `LoopUnrollPrepass` U7 (`lp` measured). A predicted-classical site is identity on its
   quantum arguments, so hoisting it is unitary-correct — but a DUPLICATED copy that is
   not in `Pending` would call the original callee with a HANDLE id as data.
5. **Round-2 mask growth — ROUND 1b (§12), attack these first.**
   - **`LaterTaintOracle` completeness.** Construct a growth it misses: an argument that a
     later drain taints without its backward slice reaching a tainted φ-decider or a
     rotation-holding callee. (The claim is that every taint-growth event starts at a φ a
     later round replaces or at a 3jru crossing; the direct-insert list in `drainWorklist`'s
     3jru comment is the enumeration to check.) A miss must END at `specialize()`'s check
     (sticky); if it ends in an ACCEPT, that is the finding.
   - **The sticky rule's reach.** A site recorded in one generation and grown in a later one
     must stay untainted AND be replanned. Find a grown site that is NOT replanned (its
     grown argument not in the reseed/delta set), so the clone is built with the old mask
     and the now-quantum argument rides a classical slot.
   - **The φ-decider region.** Blocks between `idom(M)` and `M`, plus `M`'s own terminator.
     Find a φ whose incoming choice is decided by a terminator OUTSIDE that walk (an
     irreducible CFG, a multi-entry region, an `invoke`/`callbr` edge).
   - **Generations.** `propagate()`'s drains all share generation 0; is there a pair of
     generation-0 drains with a taint READER between them (so a gen-0 record should have
     been sticky)? `propagate()` is called ~12 times before detection, each rebuilding
     the whole set.
   - The copy-out class itself (`nq`, `r2g`, and `r2b`/`r2d` under round 1) is an OWNER
     question, bd `ffir` — not for the reviewers to rule.
6. **The mask the drain saw vs `Cand.Mask`.** `replanReseedSpecialization` / round-2
   detection compute masks from `taintArgMask` at their own time; construct a site whose
   Pending mask contains an argument tainted by a DIRECT insert no drain visited (the
   `UntaintedMergeRails` list; `lowerIOSinks` runs after round 2).
7. **`classifyClassicalCallArm` + a `memory(none)` callee whose tainted argument survives
   the drop** (IR: a string attribute on the parameter) — under mutant M8 it should be
   claimed and hoisted; decide whether any other owner then admits it.
8. **The reserved-name / void / intrinsic exclusions.** Each is argued a scope conjunct
   (a false answer keeps the oracle's taint). Show one that is load-bearing for
   correctness in the OTHER direction.
9. **Cross-function:** a predicted-classical result returned from `f` (3jru never crosses)
   and then `f`'s own call site re-used as a Phase-6 argument elsewhere (bd 1yeu: every
   corpus is one function per module).

10. **ROUND 2 additions — see §14.6** (`selectsIncoming`'s unreached conservative cases, selectors
    outside the idom region, the removed callee seed).

## 12. Round 1b — a round-2 MASK-GROWTH site behaves as on the oracle

**Orchestrator ruling (2026-09-28, before the Rule-13 rounds):** `r2b`/`r2d` violate the twin
criterion (they accept, their streams are not the twin's — §5.2.1) and must not become new
accepts through this change; a round-2 mask-growth site must behave as on the oracle; the
compiler-kept copy-out class goes to an owner ruling (NEW bd `test_C_libtooling-ffir`, P3, owner
question, with the `r2b`/`r2d`/`nq`/`r2g` evidence; note appended to bd `cepm`).

### 12.1 What went wrong in round 1, precisely

A site RECORDED classical in round 1 (`h(q, y)`, mask `01`) had its mask grown in round 2 (`y`
is a 6.5 `%out`), the round-2 drain re-asked with `11`, got "quantum", and tainted the result IN
ROUND 2. The oracle tainted it at round 1. Everything in between — `lowerLoops`, round-1
control emission — had read it as classical, so the round-2 control emitter accepted a region
the oracle's round 1 declined (`r2b`: `if (t > 3) q2 = cq_theta(q2, .2)`).

### 12.2 The change (TaintPropagation.cpp, TaintPropagation.h, SpecializeClone.h comment)

Three pieces, all inside the one drain function every drain uses (`propagateWorklist` →
`drainWorklist` + `settleSpecPredictions`):

1. **A record.** `TaintSet::SpecPredictedClassical` (a `ScrubMap<const CallInst *, unsigned>`,
   self-cleaning): every site a drain leaves classical on the predictor's word, mapped to the
   drain GENERATION that first did (`TaintSet::SpecPredictGeneration`: 0 for every drain
   `propagate()` runs; +1 at the entry of every GROWTH drain — `skipRuntimeCalls`, i.e. the
   round-2 reseed, its onward fixpoint and `propagateFromSeeds`, each of which runs after some
   stage has read the taint set).
2. **The SETTLE step** (end of every drain, to a fixpoint): each site recorded in THIS
   generation is re-asked with its POSSIBLE final mask — its tainted arguments plus every
   argument `LaterTaintOracle::mayGain` says a later drain can taint — and tainted now (then
   drained) if the predictor calls that quantum. `mayGain` is reachability over the backward
   use-def slice (operands, a call's arguments, a φ's incomings AND the conditional terminators
   of the blocks between the φ's block's idom and the block) to a SEED: a tainted φ-decider (the
   φ a later round replaces with a merge `%out` / a peel select), or a call to a defined callee
   holding a `cq_theta` transitively, or an indirect call (a 3jru crossing may taint its result).
   It runs on the drain's COMPLETE taint, so it is order-independent.
3. **The STICKY rule** (in `drainWorklist`): a site recorded by an EARLIER generation is never
   tainted by a later drain. If its grown (replanned) mask then makes the clone return a
   register, `specialize()`'s check declines loudly. This is the backstop for any growth
   `mayGain` misses: such a site can no longer be ACCEPTED in round 2.

### 12.3 Why it is sound (and why the new predicate needs no completeness proof)

- `mayGain` OVER-approximating (true too often) taints a site at round 1 = exactly what every
  drain did before bd cepm: the oracle's behaviour, the conservative direction for this change.
- `mayGain` UNDER-approximating (missing a growth) leaves the site recorded; the sticky rule keeps
  it untainted in the later drain; `replanReseedSpecialization` grows its Pending mask (the grown
  argument is in the reseed/delta set by construction); the clone returns a register; the check
  declines. **No path accepts.** Measured: mutants R1/R4/R5 (§12.5) disable the settle step or
  blind the oracle, and `r2b`/`r2d` then decline with the check's string instead of the oracle's.
- The sticky rule only withholds taint from a result nothing has tainted yet; it never ADDS a
  gate. Its failure mode is the check's decline.
- `settleSpecPredictions` only inserts sites into `Tainted` and drains them (the pre-cepm drain);
  it terminates (each round taints ≥1 site from a finite record).
- `declineStaleTaintSet`'s fresh `propagate()` runs the same settle step, so the carried and fresh
  sets agree (0 lit movers).

### 12.4 L1 / L2 / L3 for round 1b

- **L1.** The premise the record carries ("this site's result is classical") is exactly what a
  round-2 delta can falsify; round 1b RECORDS it (the map) and makes the round-2 answer a CHECKED
  one (sticky + `specialize()`), never a silent re-taint. The settle step makes the round-1 answer
  the oracle's whenever the growth is visible at round 1.
- **L2.** Widened: the set of sites tainted at round 1 (by the settle step). The other set over
  the same closure is `SpecPredictedClassical` itself — kept consistent (a site tainted by settle
  or by an in-drain revisit is erased from it).
- **L3.** Narrowed: the set of drains that may taint a recorded site (the sticky rule). The other
  predicate that names the same result is `specialize()`'s check (`ResultWasTainted`), which now
  carries the whole burden for a sticky site whose clone is quantum — measured reachable (R1).

### 12.5 Measurements (subject `cq-opt` `02522b6a4fdb8911eafe965e`, `libCQPass.so` `49e7c01f5c0ba2417e287ddc`, `cq-opt-debugalloc` `d73534dc2decb0c933d87d22`)

- **Red-green.** `spec_reject_predicted_classical_round2_mask_growth{,_ry}.ll` (r2b, r2d; the
  oracle's string `cq controlled lowering: control flow under quantum control`): FAIL 2/2 on the
  round-1 subject `cb4ed3c2`, PASS 2/2 on the oracle and on the round-1b subject. All 20
  `spec_*_predicted_*` fixtures: 20/20 on round 1b.
- **lit** (`lit -j4 ir-pass/test`, round 1b): **2427 discovered, 2426 passed, 1 XFAIL, 0 failed**
  (255 s).
- **Twin battery** (66 pairs): ORACLE 18 twin-identical, round 1 43, **round 1b 43**. The ONLY
  verdict changes round 1 → round 1b are `r2b` and `r2d` (ACC-DIFF → oracle's decline,
  VERDICT-DIFF vs the accepting twin, as on the oracle). `r2g` unchanged (ACC-DIFF, the oracle's
  stream), `r2l` unchanged (DECL-SAME).
- **Corpus A/B vs the frozen ORACLE** (null control = subject twice, run first, 0 everywhere):
  lit **2427** → 13 movers, exactly round 1's (12 D→A + 1 STRING, all this change's fixtures; the
  2 new fixtures are NOT movers — identical to the oracle); e2e **608** → 0; multi **36** → 2
  D→A (the new slices); probes **377** → **36** (round 1: 38): 28 D→A + 4 STRING + 4 A→D
  (z0re's side door, §9) — `r2bC`/`r2dC` no longer move.
- **Mutants** (subset of 486 fixtures that call a defined function; base = round-1b subject):

| mutant | removes / forces | result |
|---|---|---|
| N1 | nothing (`|| Flip.size() > 1e9`) — NULL | **0 of 486** |
| R1 | the settle step | **KILLED 2** (r2b, r2d) — both now decline with `specialize()`'s check string, i.e. the STICKY backstop is live and total for them |
| R2 | the sticky rule | MISSED — every known growth is caught by the settle step first; the rule is a backstop by design (R1/R4/R5 show it firing when the settle step misses) |
| R3 | settle AND sticky (= round 1) | **KILLED 2** — both ACCEPT again |
| R4 | `mayGain`'s φ-decider check | **KILLED 2** (declines via the check) |
| R5 | "a tainted decider is a seed" | **KILLED 2** (declines via the check) |
| R6 | the callee-may-yield-quantum seed | MISSED — no fixture/probe reaches a site whose argument is the result of a call to a function holding a `cq_theta` (such a callee's result is either tainted already or 3jru-refused); argued, not constructed |

- **Round 1 vs round 1b directly** (`ab.py cq-opt.subj1 cq-opt.subj2` over the 377 probes, null
  0 of 377): **2 movers, both A→D: `r2bC`, `r2dC`** — no other probe's verdict, string or stream
  changed.

### 12.6 Gates run on round 1b

- `lit -j4 ir-pass/test`: 2427 / 2426 passed / 1 XFAIL / 0 failed.
- Affected ctest (`-R 'spec|specialize|classical-call|scrub|cq-opt-equivalence|free-pairing-selftest'`,
  53 entries): 51/53 on the first run — **`taintset-scrub-guard` and its selftest FAILED**: the
  new `TaintSet::SpecPredictedClassical` member was not exercised by
  `ir-pass/tools/scrub_selftest.cpp` (the gate's rule). Added
  `checkMap("SpecPredictedClassical", …, Call, 2u)`; re-run `ctest -R scrub`: **8/8 passed**
  (incl. both scrub-on-delete selftests and both guard entries). `cq-opt`/`libCQPass.so` hashes
  unchanged by that edit (measured).
- `update_code_map.py --check`: clean.
- Allocator sweeps (plain vs `lifo` vs `nofree`, round-1b build): lit **2427 modules, 0
  disagreements**; probes **377 modules, 0 disagreements**.
- NOT run: full `ctest -j6` (merge gate), `cq-opt-equivalence-full`, `+Asserts`, Guard Malloc.

## 14. Round 2 — the Rule-13 round-1 items (r1A + r1B, both CLEAR-WITH-ITEMS, 0 P1)

Reviews committed untouched with this round: `review_r1A_cepm/` (Surface A, the prediction) and
`review_r1B_cepm/` (Surface B, the emitted circuits and composition), each with its probes.

### 14.1 F-r1A-1 (P2, bd `we38`) — the callee seed was SYNTACTIC; REMOVED

`LaterTaintOracle` counted "a call to a defined callee that holds a `cq_theta` (transitively), or an
indirect call" as a value a later round can taint. That answers "can this call's RESULT be tainted
later?" by NAME (L5). The only channel by which a call result gains taint beyond its operands (which
the walk already follows) is bd 3jru's return crossing, and that growth is refused by
`declineQuantumReturnCalls` at the post-fixpoint slot, before `specialize()`, in both entry points.
An indirect call is never crossed (the crossing requires the call to name the function). So the seed
protected no program, and cost one: `r6b` (`F` holds a `cq_theta` but returns `n + cq_measure(r)`).

**Removed, not narrowed.** Which program does any remaining part protect? None is kept. A future
relaxation of the 3jru refusal would make a missed crossing reach the STICKY rule, whose backstop
is `specialize()`'s loud check — never an accept. The retirement trigger is written in the new
fixture header and at the source.

Pins (red on the oracle and on round 1b where they are accepts):
- `spec_accept_predicted_classical_measured_callee.ll` (`r6b`): ACCEPT, twin-identical (argv `5 7`,
  `2 9`), 2b STRICT clean. Oracle and round 1b decline `classical call result used as a quantum
  register`.
- `spec_reject_predicted_classical_round2_return_crossing.ll` (`r6a`): DECLINE with the 3jru
  owner's exact string `cq taint escape: quantum value returned across a function boundary` on the
  oracle, round 1b and round 2. The STRING is the pin (it is not `specialize()`'s, not l3oi's).

### 14.2 F-r1B-2 (P2) — the φ-decider region was "any branch between idom and block"; now SELECTS

Round 1b counted every conditional terminator between the φ block's idom and the block as a decider.
For a loop header that is the whole body, so `lpp`
(`for (i<3) { t = h(q, i+m); if (q > t) cq_phi(.2); }`) had `i` "may gain taint" from its own body's
tainted phase branch, the site was tainted at round 1 and the compare became Q+Q — round 1 accepted it
twin-identically, round 1b declined it.

Now a branch counts only if it SELECTS which incoming edge of the φ arrives
(`LaterTaintOracle::selectsIncoming`): for each successor S of the branch, E(S) is the set of the φ
block's predecessors through which some path from S FIRST reaches it; the branch selects unless every
E(S) is the same single block. An empty E(S) (an arm that never reaches the φ) or |E(S)| ≥ 2 counts as
selecting (conservative), and a successor walk over `kSelectBudget` (4096) blocks answers "selects".
`lpp`'s branch reconverges before the latch, so every arm yields {latch}: not a selector.
`r2b`/`r2d`'s 6.5 diamond yields one arm per merge edge: a selector — they keep declining.
`decides()` asks `selectsIncoming` BEFORE walking the condition, so a discarded condition's slice
never pollutes the per-query `Seen` set.

Pin: `spec_accept_predicted_classical_loop_body_branch.ll` (`lpp`): ACCEPT, twin-identical, 2b
STRICT clean; rolled kickback `cq_template_icmp_sgt_i32_hl(h, t)` + `cqrt_rz_i1`, with `t` the
clone's classical result in the literal slot. The oracle and round 1b decline
`quantum-quantum compare condition`.

### 14.3 The P3s

- ⚠ **CORRECTED IN ROUND 3 (§15.1): the climb is NOT unreachable** — the merge-φ peel reaches it
  (Rule-13 r2 F-r2-1, pinned by `spec_accept_predicted_classical_peel_diamond_climb.ll`). The bullet
  below is round 2's text and is wrong in its premise.
- **F-r1A-2** (the idom climb is unpinned and, today, unreachable): the retirement trigger is written at
  the source, in `LaterTaintOracle::walk`: the day 6.5 / 4.5 / the IO-sink mux / the peel admits a merge
  whose tainted branch is not a direct predecessor, add `gie` / `ir_fwdC.ll` as a fixture there.
- **F-r1A-3**: `Specialization.cpp`'s check comment no longer says "argued UNREACHABLE … nothing
  changes a callee body"; it names the real mechanism (a REPLANNED mask; the sticky rule's
  backstop) and the mutants that reach it. The TRACK's §3 item 3 and §6 M5 row were corrected too.
- **F-r1A-4**: `TaintSet::SpecPredictGeneration`'s ground is now the real one: each
  `taint = propagate(M, wd)` builds a FRESH set with exactly one generation-0 drain, so no record
  outlives the set a stage read. The false "nothing reads taint between them" is quoted and retired
  in place.
- **F-r1B-4** (L7): `valueArmIsPureChain`'s (K1) prose ("a classical op consuming a chain link would
  itself be tainted") is corrected at the source — false since cepm for a predicted-classical call —
  and (K5)'s "sole fence" enumeration gains the fourth member: an untainted Phase-6 call reading a
  quantum non-chain value, which (K2) refuses in every C spelling and (K5) alone refuses for an
  IR-level `speculatable memory(none)` callee.
- **F-r1B-5** (L7): `TaintPropagation.h`'s peel paragraph ("taints every user … bar a measure sink and
  an angle-only edge") gains the cepm exception, as `MergePhiPeel.cpp:573` did in round 1.
- **F-r1B-6**: `spec_accept_predicted_classical_bank.ll` now pins the property that separates right
  from wrong: the loaded classical integer feeds the sum directly (`CHECK` + `CHECK-NEXT`), and a
  whole-file `MEAS` prefix counts exactly one `cqrt_measure_i32` call and none after it (Rule 12 (a):
  counts are never inside a negative prefix; the RUN writes the output once to `%t.bank.ll`).
  Mutation-validated (`cepm_probes/bankmut.py`): null passes both prefixes; injecting a
  `cqrt_measure_i32` on a loaded integer fails BOTH; routing the load through an extra op fails
  `CHECK`.
- **TRACK §8's `tp` row** (F-r1B-1): corrected — `tp` is a TRUE-positive warning and a wrong unitary on
  both sides (bd `rhk5`'s class), not a 9k30 over-warn.

### 14.4 F-r1B-1 / F-r1B-3 — composition, NO action on this branch (orchestrator ruling)

- `tp` / `tps` / `tpx` (a template rail `p = q*3` passed only to a classical-verdict clone, then an Ry
  on `q`) route into bd `rhk5` on THIS branch alone: accepted, twin-identical, both sides warn, `p`
  never discharged — a wrong unitary on both sides. On cepm + rhk5 both sides discharge `p` before the
  Ry (r1B measured on `1c0a4e17`).
- The side-door programs `zl12` / `zl17` / `za02` / `za01` / `sp` decline on THIS branch alone (the
  oracle accepted them through the side door, correctly) and accept twin-identically on cepm + z0re
  (r1A measured on `6a77a6c9`).
- **Landing order is rhk5 → z0re → cepm.** After those two land, the orchestrator will ask this branch
  to merge `main` and add `tpC`/`tpT` (an accept whose `mul_unc` + `free` of `%h_op` precede the Ry) and
  the side-door programs as pins. Until then this branch must not land alone.

### 14.5 Measurements (round-2 subject `cq-opt` `89186a3011a22882d44bc201`, `libCQPass.so` `7dfff7e13c395111f3818d5c`, `cq-opt-debugalloc` `ce5f3060e69a5e17904b02af`; frozen copy `scratchpad/cepm/cq-opt.subj3`)

- **Red-green** (`cepm_probes/rg3.sh`, 6 fixtures): ORACLE 3 pass / 3 fail (the 3 accepts red); round 1b
  4 pass / 2 fail (`loop_body_branch`, `measured_callee` red); round 2 6/6.
- **lit** (`cd build && lit -j4 ir-pass/test`): **2430 discovered, 2429 passed, 1 XFAIL, 0 failed**
  (213.9 s).
- **Affected ctest** (`-R "spec|specialize|classical-call|scrub|cq-opt-equivalence|free-pairing-selftest"`,
  incl. `taintset-scrub-guard{,-selftest}` and both scrub-on-delete selftests): **53/53 passed**.
- **Reviewers' batteries, with their own harnesses** (`cepm_probes/revbat.sh` + `revdiff.py`; round 1b →
  round 2): r1A 27 pairs, 1 change: `r6b` VERDICT-DIFF → **ACC-SAME**. r1B 27 pairs, 1 change: `lpp`
  VERDICT-DIFF → **ACC-SAME**. No other verdict moved in either battery.
- **Corpus A/B vs the frozen ORACLE** (null control = subject twice, first, 0 in every set):
  lit **2430** → 15 movers (14 D→A + 1 STRING, all this bead's fixtures); e2e **608** → 0; multi **36**
  → 2 D→A (the two new slices); probes **385** → 39 (31 D→A + 4 STRING + 4 A→D, the same classes as
  round 1b plus `lppC`, `lpqC`, `r6bC`, the 3 D→A of the 8 new battery modules).
- **Round 1b vs round 2 directly** (null 0): lit 2430 → **2 D→A** (the two new accept fixtures);
  probes 385 → **2 D→A** (`lppC`, `r6bC`). Nothing else moved.
- **Mutants** (the 489 fixtures that call a defined function; base = round-2 subject; `mut.py`):

| mutant | removes / forces | result |
|---|---|---|
| N2 | nothing (`|| Sets.size() > 1e9`) — NULL | **0 of 489** |
| S1 | `selectsIncoming` (every branch in the region decides = round 1b) | **KILLED 1**: `…_loop_body_branch` |
| S2 | no branch ever selects | **KILLED 2**: `…_round2_mask_growth{,_ry}` (they then decline at the check) |
| S3 | an EMPTY arm set no longer counts as selecting | MISSED — no fixture has an arm that cannot reach the φ block; conservative-direction conjunct |
| S4 | differing single-block sets no longer select | **KILLED 2**: `…_round2_mask_growth{,_ry}` |
| S5 | a MULTI-block arm set no longer counts as selecting | MISSED — conservative-direction conjunct, unreached |
| S6 | the walk budget set to 0 (every branch selects) | **KILLED 1**: `…_loop_body_branch` |
| R7 | re-add the syntactic callee seed | **KILLED 1**: `…_measured_callee` |

  Totals: 7 mutants + the null; 5 KILLED, 2 MISSED (S3, S5: both relax a conservative
  "counts as selecting" case, so each could only turn a round-1-taint into a sticky site whose
  failure mode is `specialize()`'s loud check — and no C program in the corpus or the batteries
  reaches either shape).
- `update_code_map.py --check`: clean.
- **NOT run this round:** the full `ctest -j6` (merge gate), allocator sweeps, `cq-opt-equivalence-full`
  (sampled entry only), `+Asserts`, Guard Malloc.

### 14.6 ATTACK FIRST for the next round (added to §10)

1. **`selectsIncoming`'s conservative cases.** S3/S5 are unreached; construct a C program whose
   φ-decider has an arm that never reaches the φ block (an `abort` arm, a `noreturn` call) or reaches it
   through two predecessors, where a later round replaces the φ — does the site stay classical
   wrongly? (It must end at the check, not in an accept.)
2. **A selector that is NOT between idom and the block** — an irreducible region, an `invoke`/`callbr`
   edge, a switch with duplicate successors (`successors()` repeats a block: E(S) is computed per
   successor, and equal successors produce equal sets, so a switch whose two cases go to the same arm
   is treated as not selecting through them — check that this is right).
3. **The removed callee seed.** Construct a call whose RESULT a later drain taints without the 3jru
   crossing and without its operands being tainted.

## 15. Round 3 (pre-merge) — the Rule-13 round-2 items (`review_r2_cepm`, CLEAR-WITH-ITEMS, 0 P1)

Review committed untouched with this round: `review_r2_cepm/` (with probes). **Part 1 is a commit with
NO pass-code change**: comments, fixtures, records. The rebuilt binaries are BIT-IDENTICAL to round 2's
(`cq-opt` `89186a3011a22882d44bc201`, `libCQPass.so` `7dfff7e13c395111f3818d5c`,
`cq-opt-debugalloc` `ce5f3060e69a5e17904b02af`; measured after the last comment edit, and again after
each mutant build restored the tree).

### 15.1 F-r2-1 (P2) — the climb IS reachable; pinned

Round 2's comment at `LaterTaintOracle::walk` called the climb past the φ block's direct predecessors
"UNPINNED AND, TODAY, UNREACHABLE". That was true of the 6.5 channel only (`gie`, `gsw`, `ir_fwdC.ll`
decline in round 1) and false of the **merge-φ peel**. Take an if/else diamond with two NON-EMPTY phase
arms and two pred-available merge φs: the peel turns a φ into a tainted `select` in a GROWTH drain, the
tainted `br` is the entry block's, and both of the merge's direct predecessors are arm blocks.

- **Pin:** `spec_accept_predicted_classical_peel_diamond_climb.ll`, built from the reviewer's hand IR
  (`review_r2_cepm/probes/ir/pkdC.s1.ll`, copied verbatim to `cepm_probes/ir/`).
- **Mutant C1 (climb removed, re-measured here, `cq-opt.C1` `85175c61…`):** FAIL, the fixture declines
  with `specialize()`'s check string — a loud over-decline. The other new accepts pass under C1.
- The fixture is **green on the oracle** (same stream): its red is the mutant, not the oracle, and the
  header says so. The C ≠ T stream difference is the compiler-kept copy-out class (bd `ffir`), identical
  on the oracle.
- The comment now says what reaches the climb and what happens without it, and quotes and retires
  round 2's sentence (L7). No C spelling is known (`-O1` sinks the common trailing `cq_phi`, `pk1`/`pk2`).

### 15.2 F-r2-2 (P3) — fixture headers named the wrong twin

`mkfix.py`'s `TWIN_SAME` hard-coded round 1's `g(q); int t = m + 1;`. It is now a parameter
(`twin_same()` + `TWIN_LINE`), and regeneration corrected **four** headers, not two: `measured_callee`
(`y + 1`), `loop_body_branch` (`i + m + 1`), and — found by the same regeneration — `loop_break`
(`g(q); if (i + m + 1 > 5) break;`) and `classical_phi` (`g(q); t = m + 1;`). The twin-identity claims
themselves were already measured and hold. The regeneration changed nothing else in any fixture.

Also, per the review's note, `measured_callee`'s `CHECK-NOT: cq_template_icmp` moved from between `br`
and `ret` (decorative) to between the site and its classical compare.

### 15.3 F-r2-3 (P3) — the (K1)/(K5) grounds (`ArmClassify.cpp`)

- **(K1):** the implication "a classical op reading a chain link is tainted" was NEVER true —
  `cq_measure` already broke it before cepm (the (K5) paragraph said so). The comment now says cepm adds
  a SECOND member, and names the real fences: the explicit operand test and the chain's `hasOneUse`.
- **(K5):** the round-2 text credited (K2) with the `speculatable` fact, which is (K4)'s criterion. It
  now says: in C, (K2) refuses because a callee that reads its argument live while returning a
  classical value needs a side effect after `-O1`, and (K4) refuses every C spelling anyway.

### 15.4 F-r2-4 (P3) — the indirect half of the removed seed; fp1/fp3/l3

- **Pin:** `spec_accept_predicted_classical_indirect_call_arg.ll` (`fp3`: `fp = (m > 4) ? G : G2`, both
  classical; `t = h(q, fp(n))`). Red on the oracle and on round 1b; green on round 2.
- **Mutant R8** (re-add ONLY the indirect-call seed, `cq-opt.R8` `9e5ba542…`): FAIL on this fixture and
  on no other of the four checked. The callee-name half stays pinned by `measured_callee` (R7).
- **Correct new accepts of round 2, not in round 2's own A/B** (all twin-identical, argv `5 7` / `2 9`,
  2b STRICT clean; oracle and round 1b decline): `fp1` (fp → a `cq_theta`-holding, measured-return
  callee), `fp3`, `l3` (`lpp` with a runtime trip count `n`). All three are in the probe battery now.

### 15.5 F-r2-5 (P3) — the premise behind "a relaxed 3jru stays loud"

The oracle comment now splits the case: a crossing onto an ARGUMENT of a recorded site ends at the
sticky rule + check; a crossing onto the recorded SITE ITSELF bypasses the sticky rule (3jru inserts
directly) and would satisfy `ResultWasTainted` — what keeps it loud today is `scanBody`'s refusal of a
callee holding a `cq_*` primitive. Both are named as the retirement trigger, and the
`measured_callee` fixture header says the same.

### 15.6 Part 1 — what I ran

- The six changed/new fixtures on the oracle, round 1b and round 2 (`rg3.sh`): round 2 6/6; oracle 1/6
  (only `peel_diamond_climb`, green by design); round 1b 3/6.
- Mutants C1 and R8 on the new fixtures (above).
- `lit -j4 ir-pass/test --filter predicted`: 25/25.
- Hash identity after every rebuild (above).
- Nothing else: part 2 re-runs the full gates on the MERGED binary.

### 15.7 Part 2 — merge of `main` (bd rhk5 `9ad22639` + bd z0re `ba4fdad4`)

- Commit `d13a7413`: `git merge main`. One conflict, `CODE_MAP.md`, resolved by regeneration
  (`tools/update_code_map.py`; `--check` clean). `TaintPropagation.h`, `ArmClassify.cpp` and
  `tests/e2e/CMakeLists.txt` auto-merged; the four targets build.
- **Merged binary:** `cq-opt` `45c895c2f50757a63f583889` — the same hash as Rule-13 r2's private
  composed build (`1f5dbf98` + `ba4fdad4`), measured independently; `libCQPass.so`
  `2d6493e852831ed8b1226629`; `cq-opt-debugalloc` `82ebc3ea45f9e90aab3ff4f7`. Frozen copy
  `scratchpad/cepm/cq-opt.merged`. Reference: frozen main `cq-opt.main_ba4fdad4` (`ac02fafabb9e62b1…`).

### 15.8 The composition pins (TRACK §14.4's owed list)

Nine accept fixtures, generated from C probes (`mkprobes.py`, `comp.sh`); each C program is
**twin-identical** with its hand-inlined twin on the merged binary (argv `5 7`, `2 9`, stage 2b STRICT
clean) and `tools/trace_twin_equiv.py` (rhk5's instrument, its boundary controls passing) says **EQUIV**
on both argv for every pair.

| fixture | probe | main `ba4fdad4` | cepm alone (round 2) | merged |
|---|---|---|---|---|
| `…_template_rail_discharge` | `tp` (r1B) | FAIL (C declines `condition predates…`) | FAIL (accepts, `p` never discharged) | PASS |
| `…_template_rail_discharge_switch` | `tps` (r1B) | FAIL (`control flow`) | FAIL (same leak) | PASS |
| `…_template_rail_discharge_xor` | `tpx` (r1B) | FAIL (`condition predates…`) | FAIL (same leak) | PASS |
| `…_state_prep_seed` | `zl12` | PASS (byte-identical module) | FAIL (`state prep seed does not match…`) | PASS |
| `…_state_prep_seed_bool` | `zl17` | PASS | FAIL | PASS |
| `…_state_prep_seed_same_cond` | `za02` | PASS | FAIL | PASS |
| `…_angle_select_base` | `za01` | PASS | FAIL (`rotation angle`) | PASS |
| `…_state_prep_seed_q2` | `sp` (r1B) | PASS | FAIL | PASS |
| `…_state_prep_seed_const_q2` | `cp` (r1A, z0re's `comp2.c` with the reading callee) | PASS | FAIL | PASS |

- The `tp` family's CHECK is the property: `%h_op`'s `mul_unc`/`xor_unc` and `cqrt_free` sit between
  the clone call and the classical compare, i.e. BEFORE the Ry on `q`. That is exactly what cepm
  alone lacked (bd rhk5's class).
- The side-door family's CHECK is z0re's direct path on a CLASSICAL seed: `cqrt_alloc_i32(t)` and then
  `cqrt_ry_i32_controlled` on the fresh rail (or, for `za01`, an unconditional `ry` plus a controlled
  `ry` by difference). On main these programs accept with a **byte-identical lowered module** (both
  sides, `mainvsmerged.py`), so they are pins against a regression, not movers.

### 15.9 Gates on the merged binary

- `cd build && lit -j4 ir-pass/test`: **2484 discovered, 2483 passed, 1 XFAIL, 0 failed** (216 s),
  including all 9 composition pins.
- Affected ctest (`-R "spec|specialize|classical-call|scrub|cq-opt-equivalence|free-pairing-selftest|
  z0re|twin-equiv"`, which covers rhk5's `twin-equivalent` gates, z0re's slices and twin gates, the
  scrub guard and its selftests): **79/79 passed**.
- `update_code_map.py --check`: clean.
- **Corpus A/B vs frozen main `ba4fdad4`** (null control = subject twice, run first, **0 in every set**):

| set | denominator | movers | classification |
|---|---|---|---|
| lit | 2484 | 19: 18 D→A + 1 STRING | 15 cepm accept fixtures (the 12 of round 1, `loop_body_branch`, `measured_callee`, `indirect_call_arg`) + the 3 new `tp` pins; STRING = `…_stale_record` (cepm, §5.1). `peel_diamond_climb`, the 6 side-door pins and the `round2_mask_growth` pair do NOT move |
| e2e | 634 (26 need other TUs/flags, not swept) | **0** | — |
| multi | 42 | 2 D→A | the two cepm slices |
| probes | 401 (245 prior-session + 156 battery) | 40: 36 D→A + 4 STRING | 30 cepm battery members already classified (§5.2/§14) + `fp1`/`fp3`/`l3` (§15.4) + `tp`/`tps`/`tpx` (new pins); STRING `gs`/`l04`/`l04i`/`ld` → the twin's string (§5.3). **0 A→D** (round 1b's four z0re side-door A→D are gone: those programs accept on both). 0 prior-session probe moved |

  **Every mover is a cepm mover already classified in this record or a new pin. No other mover.**
- **NOT run on the merged binary:** the full `ctest -j6` (merge gate), allocator sweeps,
  `cq-opt-equivalence-full`, `+Asserts`, Guard Malloc, the mutation matrix (the pass code is unchanged
  since round 2 apart from main's own commits, which carry their own rounds).

## 13. Proposed CLAUDE.md text (not applied — the orchestrator owns CLAUDE.md)

> **bd cepm / 3zr4 (2026-09-28): a Phase-6 call whose lifted callee is PREDICTED to return a
> classical value is not tainted at propagation.** `specCallResultPredictedClassical`
> (SpecializeClone.h) asks `predictReturnTainted` inside every `propagateWorklist` drain;
> `specialize()` CHECKS it (`kMsgPredictedClassicalQuantum`). ⚠ **A call's RESULT taint is no
> longer a proof about its INPUTS** — ask `readsTaintedValue` (6.5 relied on the proxy in CODE and
> was fixed; `valueArmIsPureChain`'s (K1)/(K5) prose relied on it in ARGUMENT and was corrected —
> there (K5), refusing every non-intrinsic call, is the fence; CLAUDE.md L3). ⚠ "A callee that READS its argument yet returns
> classical is IR-only from C" was FALSE: a read through a call the pass cannot prove pure
> (a callee in another TU whose own callee is in yet another) is C-reachable. bd l3oi's fence
> keeps the predictor's over-approximation: an inner classical clone, a branch that does not
> reach the return. ⚠ **A prediction is per DRAIN, and a later drain may not overturn it**
> (round 1b): a site whose argument a later round can taint (`LaterTaintOracle`) is tainted by
> the SETTLE step in the drain that recorded it (the pre-cepm behaviour); a site an earlier
> drain left classical is STICKY, and if its grown mask makes the clone quantum `specialize()`
> declines. Tainting it in round 2 instead accepted programs the oracle declines, with streams
> that are not the twin's (`r2b`/`r2d`); the compiler-kept copy-out class behind them is an
> owner question (bd `ffir`).
