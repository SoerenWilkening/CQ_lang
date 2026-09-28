# Track CEPM + 3ZR4 — a Phase-6 call whose lifted callee returns a CLASSICAL value is not tainted at propagation

Session 2026-09-28 (parallel). Branch `worktree-agent-a3c46257bc3bd028d`, based on `main`
`9a230646` (code `c1136be2`). Beads: `test_C_libtooling-cepm` (P2, over-decline) and
`test_C_libtooling-3zr4` (P3, over-decline from C). Both stay OPEN for the Rule-13 rounds.
Probes, harnesses and raw results: `cepm_probes/` next to this file.

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
| **SUBJECT (final)** | **`cb4ed3c2f6251bc7e85bf8dc`** | **`d3e11a7e55d0b18966d62c84`** | `cq-opt-debugalloc` `3b9f963b1da8351197ac0d6e`; frozen copy `scratchpad/cepm/cq-opt.subj1` |

The comment-only L7 edits made after `cb4ed3c2` was frozen rebuild to the SAME hash
(`cb4ed3c2`, measured), so every measurement below is on the final binary. After the
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
   predicted a classical result". Argued UNREACHABLE (§4.1); pinned by mutant only (§6.4).
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
| round-2 `repropagateControlMerges` drain | yes | mask grows in round 2 (`r2g`/`r2b`: round-1 `01` classical, round-2 `11` quantum) | the round-2 drain itself: `t` is tainted IN ROUND 2, exactly when the twin's `t = y + 1` is |
| `detectAndLowerOnwardControl`'s drains | yes | same | same |
| `propagateFromSeeds` (MergePhiPeel ×3, delta) | yes | same | same |
| every stage between the last drain and `specialize()` (both control rounds, lowerLoops, IO/QRAM/Shadow, promote, classical-mux guard + lift) | read the result as CLASSICAL | the clone returns a register (argued impossible, §4.1) | `specialize()`'s check, in both entry points (the shim calls `specialize()` too); `DS_Error` exits, so nothing a window stage did reaches the output |

**Does the change GROW taint?** No — it only withholds it (the set is a subset of the
oracle's at every point before `specialize()`). **Does it shrink taint at a new site?**
Yes: the withheld result and its forward cone. That cone was previously scrubbed by
`specialize()` for a classical verdict; now it is never tainted, so the scrub finds
nothing to scrub (`taint.Tainted.count(Site)` false) and bd l3oi's record stays empty for
it.
**Round-2 shift (r2g/r2b/r2d/r2l).** A site whose return depends only on a round-2 argument
is now tainted in round 2 instead of round 1. That class already exists on the oracle (any
round-2-only site, e.g. `h(c, y)`); the shift adds members to it, and it is the twin's
timing. Measured: `r2l` DECL-SAME; `r2b` oracle DECLINE → subject ACCEPT, semantically the
twin's circuit (§5.3); `r2d` both warn `live derived record` and accept.

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

#### 5.2.1 ⚠ r2b / r2d — two D→A moves that are NOT twin-identical, disclosed

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
| M5 | the `specialize()` check | MISSED — **argued unreachable** (§4.1); no subject exists, as the argument predicts |
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
  adds customers (`br`, `fp`, `ch`, `cph`, `yc`, `sw`, `tp` — traces twin-identical; `tp`'s
  twin warns too).
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
5. **Round-2 mask growth (`r2g`/`r2b`/`r2d`/`r2l`).** A round-1-classical, round-2-quantum
   result consumed in round 1 by a stage that is not re-run in round 2 (the loop layer is
   the obvious one; `r2l` declines on both sides — find one that accepts). `r2b`/`r2d` are
   D→A moves into the pre-existing quantum-clone copy-out class (§5.2.1): decide whether the
   lyyf-(B) ruling covers a record the COMPILER keeps (the copy-out) rather than one the
   user's source keeps, and whether cepm should instead keep such a site tainted from
   round 1 (i.e. predict with the site's FINAL mask) — which would restore the oracle's
   decline for exactly these two.
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

## 11. Proposed CLAUDE.md text (not applied — the orchestrator owns CLAUDE.md)

> **bd cepm / 3zr4 (2026-09-28): a Phase-6 call whose lifted callee is PREDICTED to return a
> classical value is not tainted at propagation.** `specCallResultPredictedClassical`
> (SpecializeClone.h) asks `predictReturnTainted` inside every `propagateWorklist` drain;
> `specialize()` CHECKS it (`kMsgPredictedClassicalQuantum`). ⚠ **A call's RESULT taint is no
> longer a proof about its INPUTS** — ask `readsTaintedValue` (6.5 was the one predicate
> caught relying on the proxy, CLAUDE.md L3). ⚠ "A callee that READS its argument yet returns
> classical is IR-only from C" was FALSE: a read through a call the pass cannot prove pure
> (a callee in another TU whose own callee is in yet another) is C-reachable. bd l3oi's fence
> keeps the predictor's over-approximation: an inner classical clone, a branch that does not
> reach the return.
