# REVIEW_D_R3 — Track D, Rule-13 ROUND 3 (narrow): `readerRunsAtMostOncePerActivation` (leg 1b)

**Reviewer:** independent; did not write the code and did not run rounds 1 or 2.
**Date:** 2026-09-14.
**Verdict: CLEAR-WITH-ITEMS.** No over-accept found. Two findings, both
decline-direction / record-accuracy. **Round 4 on leg 1b is NOT warranted.**

## 0. Binary identity — FIRST ACT

```
$ shasum -a 256 /Users/sorenwilkening/Desktop/CQ_3d8q/build/ir-pass/cq-opt \
                /Users/sorenwilkening/Desktop/CQ_3d8q/build/ir-pass/libCQPass.so \
                /Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt
4394b3495c1c539fd88b03a08144feed1d723a604feb3f02e3e931f67ced54ef  CQ_3d8q/build/ir-pass/cq-opt          SUBJECT  ✓ matches brief
7f7ff051d12b51123f4dac85d81bda13386791c00a72b4897377feec951011b5  CQ_3d8q/build/ir-pass/libCQPass.so    SUBJECT  ✓ matches brief
f7b65d8ccd7bc472303d13b3c7bd7a78c03d990a4147fe7589ef73a85487b0bc  CQ_lang/build/ir-pass/cq-opt          ORACLE   ✓ matches brief
$ git -C /Users/sorenwilkening/Desktop/CQ_3d8q log --oneline -1   →  e509e418  ✓
```

Nothing in this review is measured against, or cited from, the VOID intermediate
`6480de5f`. Every row below is `4394b349` (SUBJECT) vs `f7b65d8c` (ORACLE).

**Constraints honoured:** no `cmake`, no build, no suite, **one** lit invocation
(§5), no corpus sweep, no twin matrix, no relink, no `pkill`. All probes written
under `trackD/review_r3_probes/` in the MAIN checkout; nothing written under
`ir-pass/ include/ runtime/ tests/ tools/` of any checkout. Every generated `.ll`
is checked non-empty by the harness (`run.sh`, `[ -s "$f" ] || exit 1`).

---

## 1. THE HEADLINE ANSWER — "can leg 1b admit a reader that actually runs twice?"

**No — not by any construction I could build, and the proof is tight.** Two
independent arguments, one analytic and one measured.

### 1.1 The analytic argument, re-derived from the code (not from `IMPL_D.md`)

Read off `WireWalk.cpp:528-593` directly. Let `B = R->getParent()`, `L`, `H`,
`PH`, `Lat` as in the source.

> `#execs(R)` = `#entries(B)` (a basic block runs each instruction once per entry)
> = `#(H→B edges taken)` **by C5** (`B->getUniquePredecessor() == H`; and C6's
>   distinctness rules out `H` reaching `B` on both edges, so the edge is unique
>   as well as the predecessor)
> = `#(arrivals at H with guard == Want)` **by C6**
> ≤ `#(arrivals at H from PH with guard == Want)` **by C4 + C7** (arrivals are
>   exactly `{PH, Lat}`; from `Lat` the guard is `!Want`)
> ≤ `#execs(PH)` after the first `R` = **0** **by C8a**, so ≤ 1. ∎

The step I attacked hardest is **C7's quantifier**, because the whole thing
collapses if `guardValueOnLatchEdge` returns "false" in an existential rather
than a universal sense. It does not:

* evaluator **(i)** reads `P->getIncomingValueForBlock(Lat)` and requires a
  `ConstantInt`. A φ's incoming for an edge *is* its value on every traversal of
  that edge. Universal by construction. C4's **edge-count** check (`pred_size(H)
  != 2`) is what makes "the Lat incoming" singular — without it a duplicated
  latch edge would give `getIncomingValueForBlock` a first-match answer that is
  not the only one. That clause is load-bearing and I could not get past it (p5).
* evaluator **(ii)** hands the rewritten predicate to `SE.isKnownPredicate`.
  `ScalarEvolution::isKnownPredicate` is `isKnownViaNonRecursiveReasoning`
  (constant ranges / no-wrap / splitting) **or** `isKnownViaInduction`
  (`isLoopEntryGuardedByCond` ∧ `isLoopBackedgeGuardedByCond`) — **both** are
  "holds on every iteration of the loop", which is exactly the quantifier C7
  needs. An AddRec's `getRangeRef` is bounded by `getConstantMaxBackedgeTakenCount`,
  and the value carried on the latch edge at iteration *n* is the AddRec at *n*
  with *n* ≤ BTC, i.e. **inside** the range SCEV reasoned over. I specifically
  checked the SCEV position-independence trap (a latch incoming whose SCEV is an
  AddRec of a *sibling* loop, reachable because `getSCEV` is not use-site
  relative): the exit value of a sibling AddRec is that AddRec evaluated at its
  own BTC, so a universally-proven predicate still covers it. Sound.
* everything else is `std::nullopt`, and `if (!OnLatch || *OnLatch == Want)
  return false;` sends both `nullopt` and the wrong polarity to DECLINE.

**C8a is the clause doing the real work against the hardest attack** (§2, p3).
`isPotentiallyReachable` is conservative-TRUE — its 32-block scan limit and its
`DT->dominates(BB, StopBB)` shortcut both return `true` — and TRUE here means
decline. Note the composition that makes C8a total rather than partial: leg 1b is
only *consulted* when leg 1 already found a cycle through `R`, so `R` reaches `R`,
so (by C5) `R` reaches `H`, so `R` reaches every exit of `L`; therefore **any**
path that re-enters `PH` is visible from `R`, not only the ones that textually
"go through" `R`.

### 1.2 The measured argument — 26 probes, `review_r3_probes/`

`./run.sh <f>.ll` runs SUBJECT and ORACLE; `A n` = accept with *n* `cqrt_*` calls.

| probe | shape | true `#execs(R)` | SUBJECT | ORACLE | reading |
|---|---|---|---|---|---|
| `b0_base_accept` | `if(i==0)`, 3 trips | **1** | **A 4** | A 4 | the accept; §4 |
| `p1_runtime_step` | **runtime STEP** `i += %step`, `if(i==0)` | **every trip when `%step==0`** | **D** | A 4 | ★ **the a5 variant that was not built** — declines |
| `p2_period2_guard` | period-2 guard (`f ^= 1`) | **trips 1,3,5** | **D** | A 4 | ★ |
| `p3_irreducible_reentry` | **irreducible** outer cycle re-enters `PH`; `L` is TOP-LEVEL so C2 passes | **once per re-entry** | **D** | A 4 | ★★ **C8a is the only clause that stops this** |
| `p4_c5_second_door` | a second `br` into `B` | 2 | D | A 4 | C5 |
| `p5_c4_dup_latch_edge` | `switch` latch, **two** edges → `H` | many | D | A 4 | C4 edge COUNT |
| `p6_c6_switch_header` | `H` terminator is a `switch` | 1 | D | A 4 | C6 (safe over-decline) |
| `p7_guard_eq1_residual` | `if(i==1)` | 1 | D | A 4 | the disclosed a3 residual, reproduced |
| `p8_third_shape_trunc` | guard is `icmp eq (zext %i), 0` | 1 | D | A 4 | third `-O1` shape → `nullopt`, **not** fall-through |
| `p9_wrap_unbounded` | no `nuw/nsw`, **unbounded** BTC | 1 + wrap | D | A 4 | ★ integer-wrap attack declines |
| `p10_c2_nested` | `L` nested in an outer loop | once per outer trip | D | A 4 | C2 |
| `p11_nuw_unbounded` | `nuw nsw`, unbounded BTC | 1 | **A 4** | A 4 | sound — `nuw` ⇒ strictly increasing, wrap is poison |
| `p12_c6_both_succ` | `br i1 %g, %B, %B` | every trip | D | A 4 | C6 distinctness |
| `p13_b0_unrolled_twin` | hand-unrolled `b0` | 1 | **A 4** | A 4 | §4 Rule-2 twin |
| `p14_two_readers_once` | **two sibling `cq_theta` on `%q`** inside the once-block | 1 each | **D** | A 6 | ★★ leg 1b does **not** open the sibling hole: `Self` exempts only `R` itself, the walk still returns the sibling |
| `rc1_or_two_trips` | `.c` `if(i==0\|\|i==2)`, 3 trips | **2** | **D** | A 4 | ★ real `-O1` |
| `rc2_even_two_trips` | `.c` `if((i&1)==0)`, 4 trips | **2** | **D** | A 4 | ★ real `-O1` |
| `rc3_once_control` | `.c` `if(i==0)` | 1 | A 4 | A 4 | control |
| `rc4_flag_reset_twice` | `.c` one-shot flag **re-set** mid-loop | **2** | **D** | A 4 | ★ attacks evaluator (i)'s idiom in source |
| `rc5_lt1` | `.c` `if(i<1)` | 1 | A 4 | A 4 | predicate generality, sound |
| `rc6_runtime_start_guarded` | `.c` **runtime START** `for(i=u;i<u+3;i++) if(i==u)` under `if(u>0)` | 1 | **A 4** | A 4 | ★ sound accept — **see F-D3-1** |
| `rc7_two_flags_and` | `.c` `if(i==0 && n>2)` | ≤1 | D | A 4 | over-decline residual — **F-D3-2** |
| `m1_negative_mutant_slt1` | the Rule-12 negative with `%n`→`1` | 1 | **A 4** | A 4 | ★ the negative fixture is **LIVE** |
| `m2_negative_mutant_slt2` | …with `%n`→`2` | 2 | D | A 4 | mutation control |
| `m3_flag_orig` | `lowering_stale_reader_inloop_once_flag_accept.ll` verbatim | 1 | A 4 | A 4 | evaluator (i) |
| `m4_flag_never_clears` | …latch incoming `true`→`false` (flag never clears) | **every trip** | **D** | A 4 | ★ evaluator (i)'s polarity is **LIVE** |

**Every ORACLE cell is ACCEPT.** All 18 declining probes are programs `main`
silently miscompiles today; that is the pre-existing bd `3d8q` defect, and it is
the measure of what this increment closes — not a defect of leg 1b.

**Zero over-accepts.** Thirteen distinct "R really runs twice" constructions
(p1, p2, p3, p4, p5, p12, p9, p10, rc1, rc2, rc4, m2, m4) are all refused.

---

## 2. Clause-by-clause: "what satisfies all the others and violates only this one"

| clause | witness that isolates it | declines? |
|---|---|---|
| **C1** classical guard | not isolable: `fix_r2_probes/src/ob1e_tainted_guard.c` shows the condition-wire fence reaches a tainted loop-header guard first on ORACLE, B12 **and** B13. I re-derived why an isolating witness cannot exist: a tainted `%g` is a tainted loop-header branch, which the loop layer refuses on its own. **C1 is defence in depth and the source says so** — I checked the in-source wording and it does not overclaim. | n/a — deeper fence wins |
| **C2** top-level | `p10_c2_nested` | ✔ D |
| **C3** preheader + single latch, `B != H` | implied by p5 (`getLoopLatch()` → null on a 2-edge latch) | ✔ D |
| **C4** two header **edges**, count **and** set | `p5_c4_dup_latch_edge` — `switch` latch with two cases to `H`; `pred_size(H) == 3`. This is the clause that keeps evaluator (i)'s `getIncomingValueForBlock` honest. | ✔ D |
| **C5** `B`'s only pred is `H` | `p4_c5_second_door` | ✔ D |
| **C6** distinct successors, `Want` off the SUCCESSOR | `p12_c6_both_succ` (both successors `B`); `p6_c6_switch_header` (not a `BranchInst`); polarity live via `m3`/`m4`, whose guard is `br i1 %f, %latch, %read` — i.e. the shipped accept fixture **is** the reversed-polarity case, so Rule 9 is pinned by the accept itself | ✔ D |
| **C7** semantic step | `p1`, `p2`, `p9`, `m2`, `m4`, `rc1`, `rc2`, `rc4` | ✔ D ×8 |
| **C8a** `PH` unreachable from `R` | `p3_irreducible_reentry` — **this is the clause with no substitute.** `L` is genuinely top-level (the outer cycle is irreducible, `mid→pre` is not a back edge because neither block dominates the other), so C2 passes, C3–C7 all pass, and only C8a stops it. | ✔ D |
| **C8b** CFG backstop | redundant by the proof, as the source says; I could not construct a case where it disagrees with C8a, and if it ever does the conjunction declines. Keeping it costs one bounded walk. No objection. | n/a |

**Combinations.** I also ran the two combinations that looked most likely to let
one clause's proof "borrow" another's premise: C4+C7 (`p5`: a duplicated latch
edge that would make the φ read a value it never saw — refused at the *count*
before the φ is ever read) and C2+C8a (`p3`: irreducible re-entry that defeats C2
and is caught by C8a). Both decline.

---

## 3. The two evaluators, and the seam

* **(i) the one-shot `i1` flag.** Live and correctly polarised: `m3` accepts on a
  `[false,%entry],[true,%latch]` φ with the reader on the **false** successor;
  `m4` (latch incoming → `false`, i.e. the flag never clears and the reader runs
  every trip) declines. `rc4` attacks the same idiom from C source by re-setting
  the flag mid-loop — declines.
* **(ii) the compare on the IV.** Live across `eq` (`b0`, `rc3`), `slt`
  (`rc5`, `m1`), constant and **runtime** start (`rc6`), constant and unbounded
  trip count (`p11`), with and without `nuw nsw` (`p9` vs `p11`).
* **The seam.** A guard that is an `i1` φ whose latch incoming is *not* a
  `ConstantInt`, a compare whose operand is a φ **not** in `H`, a loop-variant
  non-φ operand, a `zext`/`trunc` of the IV (`p8`), a boolean `and`/`or` tree
  (`rc7`), an `fcmp`, a non-integer operand — all reach the single
  `return std::nullopt` path and **decline**. I found **no third shape that falls
  through**: there is no path out of `guardValueOnLatchEdge` that is neither a
  proof nor `nullopt`, and `readerRunsAtMostOncePerActivation` treats `nullopt`
  and wrong-polarity identically. The L5 posture ("hand the semantic question to
  LLVM's machinery and name what is skipped") is implemented as described.
* **Third `-O1` shapes that exist and decline (over-decline only):** `p8`
  (`zext` of the IV — real for 64-bit/`size_t` loops) and `rc7` (`and`-tree).
  Filed as **F-D3-2**.

---

## 4. Rule 2 — I read the stream, not the exit code

`b0` (rolled, reader once in a 3-trip loop) vs `p13` (the same program hand-
unrolled to straight-line C semantics), gate stream after stripping SSA names:

```
cqrt_alloc_i32(i32 0)
cqrt_ry_i32(h, 2.500000e-01)
cqrt_ry_i32(h, 9.000000e-01)
cqrt_measure_i32(h)
```

`diff` of the two streams: **empty — ROLLED == UNROLLED.** And `b0`'s full
lowered IR is **byte-identical to the ORACLE's** (`ModuleID` stripped), i.e. the
fix restores exactly the circuit the pre-fence compiler emitted for this shape
and adds nothing. One `Ry(.3)` on the seed, one `Ry(.9)` on the same rail, one
measure — the correct one-rotation circuit, not a per-trip repetition.

---

## 5. Non-exportedness as a fence — **enforced, verified three ways**

```
$ nm -gU CQ_3d8q/build/ir-pass/libCQPass.so | c++filt | grep -i 'readerRunsAtMostOnce|guardValueOnLatchEdge|readerStalesItself'
00000000000b6860 T cq::readerStalesItself(llvm::CallInst const*, llvm::Value*, llvm::DominatorTree const&,
                                          llvm::LoopInfo const*, llvm::ScalarEvolution*, cq::TaintSet const*)
```

1. **Neither leg-1b symbol appears in the dynamic symbol table** — both are in
   the anonymous namespace that closes at `WireWalk.cpp:595`. Only
   `readerStalesItself` is exported.
2. **No source reference to either name outside `WireWalk.cpp`** (whole-tree
   grep; the only other hit is the *prose* in `WireWalk.h:289`).
3. **`readerStalesItself` has exactly ONE code call site** —
   `OpcodeLowering.cpp:503` — and it is itself reached only from
   `recordStaleQuantumReaders`. The three new parameters are **not defaulted** in
   the header, so a future caller must consciously supply `LoopInfo` +
   `ScalarEvolution` + `TaintSet`; and `if (LI && SE && Taint && …)` at
   `WireWalk.cpp:651` makes a `nullptr` in any slot byte-identical to the
   pre-fix behaviour. I verified that guard in the code, not from the prose.

**No indirect caller path exists.** The three other entry points that could have
acquired the relaxation — `gateIsHarmless`, `recordBarrierCutsPath`,
`findNonDiagonalWireGate`/`collectNonDiagonalWireGates` — are untouched by the
diff and cannot name the predicate.

**Blast radius is narrower than "the fence".** The grant's *only* effect is
`Self.insert(CI)`, and `Covered` is asked per-entry inside the walker: it
suppresses **`R` as evidence against itself** and nothing else. `p14` is the
measurement — two sibling `cq_theta` on `%q` inside the once-guarded block, each
of which individually runs once, still **declines**, because each one's walk
still returns the *other*. Leg 1b therefore cannot re-open the sibling-theta
family, which is the shape bd `3d8q` exists for.

**Lit, the one run in budget:**
```
$ cd CQ_3d8q/build && lit ir-pass/test --filter 'stale_reader'
Passed: 15 (of 1943 discovered, 1928 excluded).  Testing Time: 1.12s
```
15/15 green on the SUBJECT binary, including the three new fixtures. *(That is a
filtered lit run and nothing else — I ran no suite, no e2e, no stage 2b, no
sweep, no twin matrix.)*

**Fixture hygiene (Rule 12 (b)/(c)) — validated by MUTATION, not by re-reading
prefixes.** The Rule-12 negative
`lowering_reject_stale_reader_inloop_repeatable_guard.ll` is **not vacuous and
its subject exists**: `m1` (`%n` → `1`, reader once) **flips it to ACCEPT**, `m2`
(`%n` → `2`, reader twice) keeps it declined. The accept fixture
`…once_flag_accept.ll` is likewise live: `m4` (one token in the φ) flips it to
DECLINE. Both `CHECK` sets are pinned by a live property.

---

## 6. FINDINGS

### F-D3-1 — RECORD ACCURACY. The `a5` row states a **category** that is not a fence. `IMPL_D.md` §15.1
**Severity: LOW** (no miscompile; a future agent would believe a fence exists
where none does — the class this project calls "an agent-authored justification
that hardens by repetition", L7).

`IMPL_D.md` §15.1 reads *"`a5_runtime_start.ll` (IV starts at `%u1`) — DECLINE —
correct and load-bearing: with `%u1 == -1` the guard is true again on trip 2.
⚠ If this ever accepts, leg 1b has become an over-accept in the unforgivable
class."* Read as written, that says **a runtime start declines**. It does not.

**Probe `rc6_runtime_start_guarded.c`** — `if (u > 0) for (int i = u; i < u+3;
i++) if (i == u) { … }` — is an IV that starts at a runtime value, reaches leg 1b
(measured: `-O1` leaves the reader in block `%10`, guarded by `icmp eq %8, %0` on
the header φ `%8 = phi [%16,%13],[%0,%4]`), and **ACCEPTS on `4394b349`**.

It is **SOUND**: the rewritten latch value is `{%0+1,+,1}<nsw>`, which SCEV proves
`ne %0`, so the reader runs on trip 1 only. `a5` declines not because its start is
runtime but because **SCEV cannot decide `{%u1+1,+,1} ne 0`**. The real invariant
is *"`std::nullopt` is the decline direction"*, which is what the code implements.

The distinction matters for the trigger the row is carrying: as written, "if this
ever accepts, leg 1b has become an over-accept" is **false as a rule** — a
sibling of `a5` already accepts and is correct. A future agent who widens
anything and sees a runtime-start accept will not know whether they have broken
the fence or merely handed SCEV a decidable question.

**Minimal fix (docs only, no code):** reword the `a5` row and the accept
fixture's header to *"`a5` declines because **SCEV cannot decide** the rewritten
predicate — not because the start is runtime; `rc6` is a runtime start that
accepts soundly. The invariant is that `guardValueOnLatchEdge` returns
`std::nullopt` for anything it cannot prove, and `nullopt` declines."* Add `rc6`
(or its `.ll`) as a companion accept fixture if a pin is wanted.

### F-D3-2 — OVER-DECLINE residual, same class as the disclosed `a3`. **Severity: LOW**
Two further evaluable-looking guards that decline although the reader provably
runs at most once:

* `p8_third_shape_trunc` — `icmp eq (zext i32 %i to i64), 0`. `-O1` produces this
  routinely for `size_t`/64-bit induction variables; the operand is neither a
  header φ nor loop-invariant, so it is `nullopt`.
* `rc7_two_flags_and` — `if (i == 0 && n > 2)`. A conjunction one of whose
  conjuncts is a once-true guard is once-true; `C` is an `and i1`, not a φ and
  not an `ICmpInst`, so `nullopt`.

**Disposition: FILE, do not fix in this round.** Both are decline-direction, and
widening either is an ACCEPT-direction relaxation that owes its own Rule-13 round
— exactly the disposition `IMPL_D.md` §15.1 already chose for `a3` (`if (i==1)`).
Recommend they be filed **on the same bead as `a3`**, so the three residuals of
one predicate travel together rather than being rediscovered separately.

### Item 4 of the brief — the `a3` residual is confirmed **over-decline only**
`p7_guard_eq1_residual` reproduces the decline. The residual is structural and
one-directional: the leg proves *"guard is `!Want` on **every** latch arrival"*,
which **implies** "at most one execution" (§1.1). The converse does not hold —
that is the residual — but an implication that is only ever used in the sound
direction cannot produce an over-accept. `isKnownPredicate` returning `false`
(undecided) is routed to `nullopt` → decline, never to "assume false". **There is
no shape in which the narrowness of C7 grants rather than refuses.**

### Not findings, checked and sound
* **The C1 / round-2 taint window (L1).** The in-source residual paragraph at the
  clause matches the code: C1 reads round-1 taint; the `Delta` re-ask is scoped
  to readers whose record grew, so a reader granted in round 1 is not re-asked.
  I confirmed the escape argument is *independent of leg 1b* — a round-2-tainted
  loop-header branch is a tainted branch in a loop, refused by the loop layer —
  and that the retirement trigger ("the day a tainted loop-header branch lowers,
  re-derive this paragraph") is written where it will be read. Directionally the
  window can only *add* declines (CFG flattening turns guarded blocks into
  unconditional ones, which C6 refuses), so it cannot manufacture an accept.
* **`isPotentiallyReachable` conservatism.** Both of its bail-outs — the 32-block
  scan limit and `DT->dominates(BB, StopBB)` — return `true`, and TRUE at C8a is
  DECLINE. The conservative direction is the safe one here, and it is the one
  LLVM 19 actually takes.
* **`getIncomingValueForBlock`'s assert.** Release builds have assertions off, so
  a missing `Lat` incoming would be an out-of-bounds read. C4's edge-set check
  runs *before* both evaluators and guarantees `Lat ∈ preds(H)`, and a well-formed
  φ in `H` has an incoming per pred edge. Safe as ordered — **the ordering is
  load-bearing and should not be "tidied"**.
* **`p11` (accept under `nuw` with an unbounded trip count).** Sound: `nuw` means
  the wrap is poison and the poison is branched on, so LLVM's own semantics
  license the monotonicity. This is the same assumption SCEV makes everywhere in
  the pass; not a new exposure.

---

## 7. Gates — `ran:` / `cited:`

```
ran:   shasum -a 256 on SUBJECT cq-opt + libCQPass.so and ORACLE cq-opt        → all 3 match the brief
ran:   26 probe modules through BOTH binaries (review_r3_probes/run.sh)        → 0 over-accepts
ran:   cd CQ_3d8q/build && lit ir-pass/test --filter 'stale_reader'            → 15/15 PASS (1.12 s)
ran:   nm -gU libCQPass.so | c++filt                                           → leg-1b symbols absent
ran:   whole-tree grep for readerStalesItself / readerRunsAtMostOncePerActivation → 1 code call site
ran:   rolled-vs-unrolled gate-stream diff (b0 vs p13)                         → identical
ran:   b0 lowered-IR diff SUBJECT vs ORACLE                                    → byte-identical
ran:   mutation validation of the Rule-12 negative and the flag accept (m1-m4) → both LIVE
NOT run (out of scope / forbidden by brief): cmake, ctest, corpus sweep, twin matrix, e2e, stage 2b.
cited (not re-run): fix_r2_probes ob1e tainted-guard rows; IMPL_D.md §15.1 a1/a2/a4/a6 rows.
```

---

## 8. VERDICT — **CLEAR-WITH-ITEMS**

Leg 1b is the narrowest accept-direction change I have reviewed in this codebase:
one caller, one predicate, eight required clauses, `nullopt`-declines-everything,
file-local, inert without its three pointers, and its grant suppresses exactly one
instruction as evidence against itself. Twenty-six probes — thirteen of them
genuine "the reader runs twice" constructions, seven of them real `.c` through
`clang -O1`, four of them mutation-validations of the shipped fixtures — produced
**zero over-accepts**, and the two findings are a docs reword and a residual to
file alongside one already disclosed.

**Items to carry:** F-D3-1 (reword the `a5` row; docs only), F-D3-2 (file with
the `a3` residual).

**Round 4 on leg 1b: NOT warranted.** Rule 13's budget warning ("the measured hit
rate says the next round finds something") is a statement about *large* surfaces
— the 13-hole `break` epic, the 8-instance C-1 family. This surface is eight
conjoined clauses behind one call site, every exit but one is a decline, and both
rounds of attack (mine, and the author's own six `adv` probes) converged on the
same two decline-direction residuals from different directions. A fourth round
should be spent on **F-D2-1** — the over-ACCEPT that round 2 found, that
reproduces on the ORACLE, and that this round did not touch — not on leg 1b.
