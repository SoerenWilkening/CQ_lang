# TRACK_FMT3 — bd `test_C_libtooling-fmt3`: the erased-inner-branch fold

**Status: PHASE 2 IMPLEMENTED (option B, owner ruling 2026-09-28) — see §9, which supersedes the
Phase-1 recommendation text in §7. §1–§8 are the Phase-1 record, kept as written (dated 2026-09-28).**
Branch `worktree-agent-aea6988dda116aa5b`, off `main` `9a230646`. Frozen oracle
`cq-opt.main_9a230646` (sha-256 `3f6db37f5cf937b4d70f5736…`). My clean build of `9a230646`
is BIT-IDENTICAL to it (`cq-opt` `3f6db37f…`, `libCQPass.so` `356df92e…`, re-measured after the
prototype was reverted). The option-(A) measurement prototype (`fmt3_probes/proto_optionA_probe.patch`,
NEVER committed, reports only) was `cq-opt.proto` `93f6aa96…`. The bd `z0re` subject snapshot used
for the zt0b probes is `cq-opt.z0re` `51b5f78d…`.

Probes and instruments, all under `fmt3_probes/`: `mkprobes.sh` (writes `src/`), `run.sh` /
`run_family.sh` / `run_family2.sh` (verdict + STRICT 2b + link + run, per header, per binary),
`ab_hdr.py` (frontend A/B: the same `cq-opt`, two `CQ.h` headers), `mk_s1.py` + `sweep_probe.py`
(option-A population), `asel_nomerge.sh` (the three e2e stream movers). Raw outputs:
`family.txt`, `family2.txt`, `ab_hdr.{NULL,REAL}.txt`, `sweep_A_{lit,e2e,probes}.txt`.

---

## 1. Mechanism — MEASURED, not inferred

`a6.c` (review r1A F-r1A-2):
```c
int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
return cq_measure(r) + cq_measure(t) + cq_measure(q2);
```
`clang -O1 -mllvm -print-after-all` (`scratchpad/fmt3/a6.pa.txt`), pass by pass:

1. **IPSCCP** substitutes `t := 5` into the inner arm's `cq_theta` **while the compare is still
   `icmp eq %t, 5`** — so in the SOURCE the rotated register IS the erased compare's own operand.
2. The first **InstCombine** SINKS `%t = sdiv %q, 4` past the whole region (its only users are after
   it) and rewrites the compare sideways to `(and %q, -4) == 20`.
3. The **LATE SimplifyCFG** (module-optimization pipeline, after LoopLoadElimination/InstCombine — the
   instance with hoist/sink-common-insts) hoists the two now-identical `cq_theta(5, .9)` calls and
   ERASES the inner branch.

What reaches the pass is `r = 5; if (q2 > 3) r = cq_theta(5, .9);` with `%t` live, measured, and
defined AFTER the region. **It is the stage-1 IR of the legitimate program `n12.c`
(`if (q2 > 3) r = cq_theta(5, .9);`, no inner branch at all), identical modulo φ operand order, and
the two traces are byte-identical.** F2 asks LVI about the region's own `q2 > 3` edges, which say
nothing about `%q`; the flat twin `a6f.c` declines only because there the pinning compare survives.

**A SECOND ROUTE, and it refutes the premise today's zt0b ruling was scoped on.** `n13.c`:
`if (q2 > 3) { if (q == 20) r = cq_theta(t, .9); else r = cq_theta(5, .9); }`, `t = q/4`
defined BEFORE the branch. IPSCCP pins `q`, not `t`, so the arms are NOT identical; SimplifyCFG sinks
them with ONE φ `[t, 5]`, FoldTwoEntryPHINode makes `select (q == 20), t, 5`, and InstSimplify's
`simplifyWithOpReplaced(t, q := 20)` = `sdiv 20, 4` = `5` = the false value, so the select folds to
`5`. **The rotated register `t` is NOT the erased compare's operand (`q`).** `n13`'s stage-1 IR is
again identical to `a6`'s and `n12`'s. So:

* bd zt0b's note (*"The rotated register is the erased inner compare's own operand in every spelling
  found (select(X==Y,X,Y)->Y needs X in the compare)"*) is FALSE as a class statement — the owner's
  2026-09-28 ruling ("the alpha trade extends to a pin on an erased inner branch (runtime seed, rotated
  register = the erased compare's own operand) — accept") was given on it (L7).
* The ruling's in-scope (`a6`) and out-of-scope (`n13`) members produce the SAME module, so **no IR
  predicate can implement the ruling as worded** — nor separate either from the legitimate `n12`.

**What the fold loses, stated precisely (and why it is the stale-reader class).** On the erased edge
the pinned register holds exactly `|K⟩` (a product state), so "rotate it in place" and "rotate a fresh
`|K⟩`" agree on every register EXCEPT the pinned register's own OLD NAME. The only observable
difference is a later read of that name — `cq_measure(t)` in `a6`/`n13`. Written visibly, CQ declines
exactly that read: `n21.c` (`r = t; if (q == 20) r = cq_theta(t,.9); … cq_measure(t)`) DECLINES
`stale rail record read past a controlled Ry`, and without the read (`n21b.c`) it ACCEPTS as the
in-place controlled-Ry arm. So the fold does not replace a realizable circuit with a wrong one; it
**erases the evidence of a program CQ would refuse** (a stale read after an in-place rotation, inside an
if/else that is a register mux) and compiles the legitimate program it now looks like. That is
PRD §14.11 Q3's shape ("a program whose correct disposition is a decline … made indistinguishable from
the accept class by a fold that deleted the evidence") with the BRANCH deleted instead of the register —
and, unlike Q3, the register IS read, so Q3's boundedness argument does not extend to it.

## 2. The class, measured (oracle `9a230646`; STRICT 2b; args `83 3`)

| probe | shape | oracle | under option B (nomerge) |
|---|---|---|---|
| `a6` | literal 5, `t==5`, nested diamond | **ACCEPT** 13 lines | DECLINE `nested control flow` |
| `a4` | on-wire literal (`q==5`, rotates `q`) | **ACCEPT** 12 | DECLINE `nested control flow` |
| `n1` | inner `!=` | **ACCEPT** 13 | DECLINE nested |
| `n2` | inner `switch` | **ACCEPT** 13 | DECLINE nested |
| `n4a` / `n4b` | literal `0` / `-1` (`t = q ^ 3`) | **ACCEPT** / **ACCEPT** | DECLINE / DECLINE nested |
| `n5` | **f64** (`d == 5.0`, via sink + select + simplify; IPSCCP cannot pin fp) | **ACCEPT** 13 | DECLINE nested |
| `n6b` | **i1** (`b = q & 1`) | **ACCEPT** 16 | DECLINE nested |
| `n8` | inside a classically-bounded loop | **ACCEPT** 31 | DECLINE nested |
| `n11` | `a6` without the later read of `t` | **ACCEPT** 11 | DECLINE nested |
| `n13` | **rotated `t` ≠ compare operand `q`** (§1) | **ACCEPT** 13 | DECLINE nested |
| `n14` | arm `cq_theta(t + 1)` vs literal 6 | **ACCEPT** 13 | DECLINE nested |
| `n17` | `W = q + 1`, inner `q == 5` | **ACCEPT** 13 | DECLINE nested |
| `n9` | **NO region**: `if (t==5) r=cq_theta(t,.9); else r=cq_theta(5,.9);` | **ACCEPT** 7 — an UNCONDITIONAL prep | DECLINE `if/else state prep allocates two rails` |
| `n17f` | **NO region**, `W = q + 1` | **ACCEPT** 8 | DECLINE `rotation arm on a condition wire` |
| `zt_p1` | zt0b's runtime-seed, no region | ACCEPT (oracle **and** z0re) | DECLINE `condition predates a non-diagonal gate` (both) |
| `zt_a1`/`a3`/`a5` | zt0b runtime-seed nested (r1A F-r1A-1) | oracle F1-decline; **z0re ACCEPT** | DECLINE nested (both binaries) |
| `n12` | the LEGITIMATE program (control) | ACCEPT 13 | ACCEPT 13, unchanged |
| `a6f` | flat twin | DECLINE F2 | DECLINE F2 |
| `n3` deeper nest · `n7` drbq.13 nested · `n10` classical outer · `n16` nested diamonds · `n13f` flat mux · `n22` unfoldable mux | — | DECLINE (control flow / taint escape) | DECLINE |
| `n15` | `t = (i64)q * 3; if (t == 5)…` | ACCEPT | ACCEPT — ⚠ NOT a member: `q*3 == 5` is infeasible, `-O1` deletes the dead arm legitimately |
| `n6` | first i1 spelling (`cq_theta(true,…)` is `int`) | DECLINE | ⚠ probe typo, superseded by `n6b` |
| `n21` | VISIBLE form: `r = t; if (q == 20) r = cq_theta(t,.9);` then `cq_measure(t)` | DECLINE `stale rail record read past a controlled Ry` | same |
| `n21b` | `n21` without the stale read | ACCEPT 9 (in-place controlled Ry on `t`) | same |
| `n18` | shipped Ry-stem angle select `if (q>3) p=cq_theta(p,.9); else p=cq_theta(p,.3);` | ACCEPT 11 | ACCEPT 13 — STREAM move, same unitary |
| `d13a1` | drbq.13's `a1.c` (literal-base angle select) | DECLINE `rotation angle` | DECLINE `if/else state prep allocates two rails` (STRING) |
| `n19` | my bool-cascade variant (coarse-fence cost probe) | DECLINE `value-arm swap-route` | same — superseded by the real owner slices in the e2e sweep |

**Fifteen accepting members on the oracle, every width/kind tried (i32 literals incl. 0/-1, i1, f64),
every inner branch kind (`==`, `!=`, `switch`), nested and NOT nested, flat and in a loop; four more on
the z0re subject.** Only deeper nesting (`n3`) and the angle-select variant (`n7`) decline, for
unrelated reasons.

## 3. The options

| option | closes the class? | A→D over the corpus (oracle-accepting modules) | goldens / gates broken | soundness | cost |
|---|---|---|---|---|---|
| **(A1)** coarse F2, typed: decline a Constant-seed prep that passed F2 if any tainted value of the seed's type ANYWHERE in the function (off `CondWire`/`PeelClones`/`PhiDesc`, not the arm) has an unconditional range containing the seed | **NO.** Region members only (`a6`…`n17`); cannot reach `n9`, `n17f`, `zt_p1` — no region, F2 never asked. Must scan past the region (the rotated register is SUNK after it), so it is "any other register" in practice | **lit 34 of 115** · **e2e 16 of 35** · probe dirs 18 of 23 (15 intended) | **the owner's programs**: `slice_control_cascade_three_bools`, `slice_grover_oracle_uncompute`, `slice_railbank_owner_cascade`, `slice_control_cascade_loop_carried_handle`, `slice_4jok_owner_plus_hoisted`, + 11 more e2e goldens | sound for what it reaches; declines the legitimate `n12` (same IR) | ~40 lines at F2 |
| **(A2)** as A1, any int/fp type | same gap | lit 49 of 115 · e2e **24 of 35** · probes 18 of 23 | A1's + the two-bools cascades, `slice_control_phase_mergephi*`, the undef-seed slices | as A1 | as A1 |
| **(B)** `__attribute__((nomerge))` on the 16 `cq_theta_*` declarations in `CQ.h` | **YES** — all 19 measured members decline (nested/no-region, literal/runtime, i1/i32/f64, loop) | e2e: **0 A→D**; stage 1 moves in **3 of 608** (source, CASE) jobs, all STREAM (below) · probe dirs: the 15 members + `zt_*` (4, incl. **owner-ruled accepts**) | 3 goldens restream: `slice_control_angle_select_ry{,_derived_base,_ne}` (same unitary: `cRy(f,A); X f; cRy(f,B); X f` instead of the by-difference `Ry(B); cRy(f,A−B)`, STRICT 2b clean), so `e2e-angle-select-ry-twin-identical` (and any gate pinned to that stream) goes red; the IF/ELSE spelling no longer folds into `AngleSelectEmit`'s Ry stem (⚠ CORRECTED in Phase 2, §9.3: the TERNARY spelling still reaches it — this cell first claimed C could no longer reach it, which was wrong) | keeps the evidence: the branch survives and the EXISTING fences (nested / two-rail / 2c / F2) decline it; `nomerge` is honoured by LLVM 19's SimplifyCFG hoist and sink (measured: `cq_theta_nomerge.c` red → green) | 16 attribute tokens + 1 frontend fixture + 3 goldens; reverses today's zt0b ACCEPT ruling |
| **(C)** rule it acceptable (extend α to every erased-branch pin, literal or runtime, any rotated register) | n/a — documents it | 0 | 0 | the α argument extends: every well-formed rival of a merged branch is an if/else of rotation arms on DIFFERENT registers (a register mux, which CQ declines — "two rails = decline"), and the only observable difference is a STALE read the unfolded program would be refused for (`n21`). Retirement trigger: the day a register-mux if/else of rotation arms, or a read past an in-place rotation, lowers | docs + a pin fixture + the L7 corrections (§6) |

Option-A population details: the prototype printed, at every literal prep that PASSES F2, whether A1/A2
would fire; its verdicts were byte-identical to the oracle on every module (null control below). "Of 115"
etc. are the ACCEPTING modules with ≥1 literal prep reaching F2's end; a decline elsewhere in the module
is not an A→D. Witness examples: `trunc nuw i8 … to i1` of a bank cell, another region's `cq_theta_i1`,
the root register `%q` — i.e. A1 collapses to "any other quantum register".

## 4. What I ran, literally

* **Build**: `cmake --build build -j4` (clean `9a230646`) → `cq-opt` `3f6db37f…` = oracle. Prototype
  rebuild → `93f6aa96…`; source reverted, rebuilt → `3f6db37f…` again.
* **Probe family** (`run_family.sh`, `run_family2.sh`): 35 C probes × {base, nomerge} header on the oracle
  (+ the z0re snapshot for the four `zt_*`), each ACCEPT through STRICT 2b + link + run. Table §2.
* **`-print-after-all`** on `a6.c` (§1).
* **Frontend A/B** `ab_hdr.py` over every `tests/e2e/*.c` × CASE: denominator **633 jobs, 608 compiled at
  stage 1 on both headers, 25 need other TUs/flags and were NOT swept**. NULL CONTROL FIRST (nomerge vs
  nomerge): **0 stage-1 movers, 0 verdict movers of 608**. Real (base vs nomerge): **3 stage-1 movers of
  608**, all 3 STREAM, 0 A→D, 0 D→A. ⚠ The first real run reported **598** stage-1 movers — my
  normaliser left one extra blank line from the added attribute group; fixed (blank lines dropped) and the
  608 persisted pairs re-diffed with `rediff_hdr.py` → `ab_hdr.REAL.rediff.txt`: 3. (`ab_hdr.py` itself now carries the fix.) The verdict comparison was unaffected (3 either way).
* **Option-A sweeps** (`sweep_probe.py`, prototype vs oracle): lit **2407 modules, NULL 0 movers**; e2e
  base stage-1 **608, NULL 0**; probe dirs (mine + z0re / r1A / r1B `src/`) **231, NULL 0**. ⚠ The first
  probe-dir sweep was DISCARDED: `mk_s1.py` named modules by `dirname` only, all four dirs are `src/`, and
  they overwrote each other (duplicate names in the output gave it away); fixed, re-run.
* **frontend lit** with the nomerge header swapped in (then restored, `git diff include/CQ.h` empty):
  **10 discovered, 10 passed** (incl. the new fixture). On the shipped header the new fixture FAILS at
  `CHECK: br i1` (red for the right reason).
* **ir-pass lit** on the clean binary with the option-A red fixture present: see §5.
* **NOT run**: full ctest (Rule 19); allocator sweeps (no pass code changed); e2e slices beyond the three
  movers; the twin matrix; the 25 multi-TU e2e jobs under the nomerge header; hand-IR corpora other than
  `ir-pass/test`; any mutant (no predicate added).

## 5. Red fixtures (written, UNCOMMITTED, pending the owner's choice)

* **(A)** `ir-pass/test/control_inplace_ry_reject_stateprep_erased_inner_pin.ll` — `a6`'s stage-1 IR,
  `RUN: not %cq-opt …`, a PROPOSED new string `state prep seed may be a folded live register`. RED on the
  oracle-identical binary: `lit --filter erased_inner_pin` → **1 failed**. Full lit on the clean binary:
  **2408 discovered, 2406 passed, 1 XFAIL (`lowering_invert_add_i32.ll`), 1 failed = exactly this red fixture** (462.8 s at `-j4` on a box at load ~300+).
* **(B)** `tests/frontend/cq_theta_nomerge.c` — `if (q == 5) r = cq_theta(q,.9); else r = cq_theta(5,.9);`
  must keep `br i1` and two calls. RED on the shipped header, GREEN with the attribute (measured both).
  Phase 2 of (B) would also add `a6`/`n13`/`n9` as e2e decline pins and restream the three goldens.

## 6. L7 items owed AT THE SOURCE whichever option is chosen

1. `ArmClassify.cpp` F2 header, "THE RESIDUAL …": *"InstCombine's RELATIONSHIP folds (`x - x`,
   `simplifyWithOpReplaced`) can mint a constant no lattice sees, and every one measured DELETES the
   register"* — FALSE: `n13`/`n14`/`n17` mint the seed by `simplifyWithOpReplaced` with the register LIVE
   and MEASURED. And *"the seed can only BE a fold if `clang` PERFORMED that fold [with] the machinery
   above"* assumes the fold's edge is the region's own; here the pinning edge was ERASED.
2. bd zt0b's "rotated register = the erased compare's own operand in every spelling found" (above) and the
   scope of the 2026-09-28 ruling built on it.
3. The z0re branch's TRACK_Z0RE §4 / S3 comment premise ("the DIAMOND prep of a literal is safe only
   because F2 asks … on one of the branch's edges"), already flagged by r1A — lands with z0re, not here.

## 7. Recommendation

**(A) is not a candidate**: it cannot reach the no-region members (`n9`, `n17f`, `zt_p1`), it declines the
legitimate twin `n12`, and it costs 16–24 of 35 accepting e2e literal-prep programs including the owner's
cascade and Grover files. **The real choice is (B) vs (C)**, and it is the owner's:

* **(B) nomerge** is the only option that CLOSES the class, because the evidence exists only until the late
  SimplifyCFG; after it every member is the legitimate program. Its measured cost is small (3 e2e streams,
  same unitary, 0 A→D) but it (i) REVERSES today's zt0b accept ruling for `zt_p1`/`zt_a1`/`a3`/`a5`, and
  (ii) stops the IF/ELSE spelling folding into `AngleSelectEmit`'s Ry stem (⚠ CORRECTED in Phase 2: the TERNARY spelling `r = cq_theta(r, c ? A : B)` still reaches it, §9.3; "retires the C-level route" was wrong) (recoverable later by teaching the pass
  the unmerged if/else of two chained Ry on ONE register — register-aware merging the compiler, not
  `clang`, would then own).
* **(C)** is consistent with α, zt0b and §14.11 Q3 and costs nothing, but it must be ruled on the TRUE
  scope: any rotated register pinned on the erased edge (not only the compare's operand), literal or runtime,
  and it accepts programs whose visible form CQ declines (`n21`).

My recommendation is **(B)**: it is the one option whose safety does not depend on an unfalsifiable "no
rival lowers" argument, it is the Prime-Directive direction, and the zt0b reversal is a decline of programs
whose unfolded form CQ already declines. If the owner prefers to keep zt0b's accepts, (C) with the corrected
scope and an explicit retirement trigger is the honest alternative; (A) should not be built.

## 8. ATTACK FIRST (for whoever reviews Phase 2)

1. Any other `-O1` transform that MERGES or ERASES a `cq_theta` without honouring `nomerge`
   (`FoldTwoEntryPHINode` needs speculatable arms; LICM/EarlyCSE/GVN need readonly — argued, not swept).
2. Whether `nomerge` on the DECLARATION reaches calls through `_Generic` and `cq_ry` (measured for `cq_theta`
   spellings; `cq_ry` not separately).
3. Loop-rotated / LICM'd programs where the merge happens in a preheader.
4. The 25 multi-TU e2e jobs not swept under the nomerge header.
5. `cq_phi` and `cq_measure` are deliberately NOT given `nomerge`; argue that a merged `cq_measure` pair
   cannot hide an erased pin.

---

## 9. PHASE 2 — option B implemented (owner rulings 2026-09-28)

Rulings (bd fmt3 / zt0b / z0re, bd memory `owner-ruling-fmt3-nomerge-2026-09-28`): **option B** —
`nomerge` on the 16 `cq_theta_*` declarations; **accept the restreamed goldens** (same unitary); the
by-difference emission of the unmerged if/else is a FOLLOW-UP (filed: bd `test_C_libtooling-gjn2`,
P2, related to fmt3 and drbq.13); **today's α-extension ruling is WITHDRAWN** on the n13 evidence;
`cq_measure` gets `nomerge` only on a measured reason (§9.6 — none found; the measured evidence
points the other way).

### 9.1 What changed

| file | change |
|---|---|
| `include/CQ.h` | `CQ_THETA_NOMERGE_` (= `__attribute__((nomerge))`) on all 16 `cq_theta_*` declarations; a `#error` when the compiler lacks the attribute (measured: fires under `#undef __has_attribute`); the WHY (the a6/n13 indistinguishability) in the header comment. `cq_phi` and `cq_measure` unchanged. The committed header yields stage-1 IR byte-identical to the Phase-1 measured variant on 40 sources (`hdr_equiv.sh`: 0 differ), so Phase-1's measurements carry over. |
| `docs/frontend.md` | §3.1 "Why every `cq_theta_*` is `nomerge`" (mechanism, indistinguishability, cost, the ternary spelling, why not `cq_phi`/`cq_measure`, the `#error`); §8 Stage-1 note. |
| `tests/e2e/CMakeLists.txt` | **HARNESS FIX (pre-existing trap, measured):** the stage-1 cache key is computed at CONFIGURE time and `include/*.h` was not a configure dependency, so after editing CQ.h a plain `cmake --build` kept the old key and served the OLD header's stage-1 IR — measured: `e2e-slice-control-angle-select-ry` PASSED its PRE-nomerge golden under the new header. Now `file(GLOB_RECURSE … CONFIGURE_DEPENDS include/*.{h,hpp,inc})` + `CMAKE_CONFIGURE_DEPENDS`; measured: a header-only edit re-runs CMake and changes the key (`a06f36b3…`), reverting restores it (`09f3cff2…`), and the slice then FAILS its stale golden as it must. Residual: `ctest` with no preceding build. Plus: 3 `_ternary` slices, 2 in-loop if/else slices, 1 new twin gate, 2 twin gates re-pointed. |
| goldens | REGENERATED (3): `slice_control_angle_select_ry{,_ne,_derived_base}.expected.log` (§9.2). MOVED byte-for-byte (3): the pre-fmt3 goldens of those three became the `_ternary` goldens. NEW (2): `slice_control_inplace_ry_loop_ifelse{,_unrolled}.expected.log`. |
| `tests/frontend/cq_theta_nomerge.c` | a6 / n13 / n9 / n17f keep their inner branch and both calls; the Ry if/else is two calls and no angle select; the ternary is one call with a select; `cq_phi`'s if/else still merges. RED on the pre-fmt3 header (a6, n13, n9, n17f, ry_ifelse), GREEN on the new one. |
| `ir-pass/test/control_inplace_ry_reject_stateprep_nomerge_{nested_pin,nested_offoperand,noregion_pin,noregion_offoperand}.ll` | the four C programs' NEW stage-1 IR (transcribed from `out/*.nomerge.s1.ll`), each a decline with its measured string and an L8 retirement trigger. ⚠ These pin the pass verdict on the new shape; they are green on the unchanged pass BY CONSTRUCTION — the red-green of this change lives at the frontend fixture, the only layer where the header acts. |
| comments (L7) | `ArmClassify.cpp` F2 header ("every one measured DELETES the register" — FALSE, n13/n14/n17/n17f), the `(b) ONE CONTENT ARM ONLY` clause and the two-prep clause (both "unreachable from plain C" — now reachable: n23 / n9 / d13a1 measured), `classifyAngleSelect`'s header; `SelectClassify.cpp`; `AngleSelectEmit.h`; `ControlPlan.h`; 11 lit fixture headers (dated notes after the falsified sentence); the three if/else slices' headers. **No pass CODE changed.** |

### 9.2 The regenerated goldens — same unitary, argued by hand

Let `f = [cond]` be the compare flag (an ANCILLA minted by `cq_template_icmp_*`), `R(θ)` the tensored Ry
on `r`'s rail. Per-qubit Ry about one axis composes additively, `R(a)R(b) = R(a+b)`, exactly.

* `slice_control_angle_select_ry` (`q == 5`: 0.9 else 0.3). OLD: `R(0.3); cR_f(fl(0.9−0.3))` → f=1:
  `R(0.3 + 0x1.3333333333334p-1)` = `R(0.9 + 2^-54)`; f=0: `R(0.3)`. NEW:
  `cR_f(0.9); X f; cR_f(0.3); X f` → f=1: `R(0.9)` (the ¬f gate is off); f=0: `R(0.3)`. Same map; the
  NEW stream is EXACT where the old carried the documented 2^-54 rad. The X pair is on the ancilla, is
  self-inverse, and restores `f` before `icmp_eq_…_unc` strips it (so the free is at |0⟩ — STRICT 2b
  `2 verified, 0 violation`; two free sites because `main` inlines `slice`, as before).
* `…_ne` (`q != 5`; `-O1` canonicalises to `icmp eq`, TRUE successor = the source's ELSE arm). NEW:
  `cR_f(0.3); X f; cR_f(0.9); X f` → q==5: `R(0.3)`, q!=5: `R(0.9)`. OLD: `R(0.9); cR_f(−fl(0.6))`.
  Same map. STRICT 2b `2 verified, 0 violation`.
* `…_derived_base` (the same on the out-of-place `mul` rail `h2`, then `addc(h2, 1)`). Same argument;
  the FREEZE this slice probes still holds (one `cqrt_free`, the flag's; the `mul` rail left allocated;
  the two M-A warnings unchanged). STRICT 2b `1 verified, 0 violation`.

Emitter of the new streams: the in-place Ry arm's if/else form (drbq Inc 1;
`control_inplace_ry_ifelse.ll` pins exactly this stream shape at the IR level).

### 9.3 `AngleSelectEmit`'s Ry stem stays covered — at BOTH levels

* IR: the `control_angle_select_*.ll` fixtures are unchanged and green.
* C, e2e: the select written out, `r = cq_theta(r, c ? A : B)` —
  `slice_control_angle_select_ry{,_ne,_derived_base}_ternary.c`. MEASURED (`ternary_module_eq.py`): each
  hands the pass function bodies IDENTICAL to what the pre-fmt3 header's fold produced from the if/else
  (`_derived_base_ternary` needs `noinline` on `slice` to keep the module shape — without it `-O1`
  inlines the smaller body into `main`: same trace, twice the warnings; `inline_check.sh` shows it is the
  spelling, not the header, that decides that). Each trace is BYTE-IDENTICAL to the pre-fmt3 golden of
  its if/else sibling, so those goldens were MOVED, not regenerated, and
  `e2e-angle-select-ry{,-ne}-twin-identical` keep their names and their oracle (the unchanged `_twin`
  slices) and now compare the `_ternary` goldens.

### 9.4 An ACCEPT the header CREATED (not asked for) — pinned with a twin gate

The in-loop if/else of two chained Ry on one register. Pre-fmt3 the arms merged into an angle select and
DECLINED — measured on the oracle with the old header: `n24.c` → `control flow inside a loop body`;
`slice_control_inplace_ry_loop_ifelse{,_unrolled}.c` → `condition predates a non-diagonal gate` (both).
With `nomerge` both reach the drbq Inc-3 rolled in-place Ry arm's if/else form (until now hand-IR only,
`control_inplace_ry_inloop_ifelse.ll`) and ACCEPT: rolled golden **byte-identical** to the hand-unrolled
twin (39 lines; also `n24` rolled == `n24T` unrolled, 33 lines), STRICT 2b clean, lowered IR
**K-independent** (62 lines at K=3 and at K=1000; only the bound constant differs). Gate:
`e2e-inplace-ry-loop-ifelse-twin-identical`. ⚠ An ACCEPT-direction change reached from C: it owes the
Rule-13 round's attention (ATTACK FIRST 3). Asymmetry it leaves: the TERNARY spelling in a loop still
declines at S7 (pre-existing).

### 9.5 The two no-region programs, and the other class members, NOW

| probe | before (oracle, pre-fmt3 header) | now (oracle, committed header) |
|---|---|---|
| `n9` (no region, literal) | ACCEPT — unconditional prep, `t` unrotated | DECLINE `if/else state prep allocates two rails` (pinned: `…_nomerge_noregion_pin.ll`) |
| `n17f` (no region, `W = q+1`) | ACCEPT — unconditional prep of 6 | DECLINE `rotation arm on a condition wire` (pinned: `…_nomerge_noregion_offoperand.ll`) |
| `n2f` (no region, `switch`) | ACCEPT 7 lines | DECLINE `if/else state prep allocates two rails` |
| `a6` / `n13` (nested) | ACCEPT | DECLINE `nested control flow` (pinned: `…_nomerge_nested_{pin,offoperand}.ll`) |
| `a4 n1 n2 n4a n4b n5 n6b n8 n11 n14 n17` | ACCEPT | DECLINE `nested control flow` |
| `zt_p1` (zt0b runtime seed, no region) | ACCEPT | DECLINE `condition predates a non-diagonal gate` — ⚠ the zt0b accept ruled earlier today is REVERSED, per the withdrawal |
| `zt_a1/a3/a5` | oracle F1-decline; z0re subject ACCEPT | DECLINE `nested control flow` on BOTH binaries |
| `d13a1` (drbq.13's a1) | DECLINE `rotation angle` | DECLINE `if/else state prep allocates two rails` (STRING move; still declined, as ruled) |
| `n23` (bool rail, Ry if/else) | DECLINE `bare i1 register condition` (at l4x4.a) | same string, now at the `(b)` clause |
| `n12` (the legitimate program) | ACCEPT | ACCEPT, unchanged |

⚠ THE COORDINATOR'S BRIEF EXPECTED a6/n13 "to decline at F2 with the flat twin's string". MEASURED
OTHERWISE: they decline `nested control flow` — nesting speaks before F2 is asked. The verdict is the
twin's (decline); the string is whichever fence speaks first. The fixtures say so and carry the
retirement trigger for the day nesting lowers.

### 9.6 `cq_measure` — no measured reason for `nomerge`; one measured reason AGAINST

`m1` / `m2` (`if (t == 5) m = cq_measure(t); else m = cq_measure(5);` and the `q == 20` / `t` variant):
`-O1` merges the two measures into `cq_measure(5)` — a CLASSICAL measure, no trace line — so the
user-written measure of `t` vanishes (base and committed header alike; with `nomerge` on `cq_measure`
too they would decline `value-arm swap-route`, measured with a variant header). ARGUED SOUND: the pin is
EXACT, so on the pinned branch the measured register is in the eigenstate `|5⟩`, the outcome is 5 on
EVERY branch, no which-branch information is extracted and nothing collapses — `m = 5` with nothing
measured is the same channel. That is the difference from `cq_theta`, whose in-place rotation CHANGES
the pinned register. `m3` (`if (q > 5) m = cq_measure(a); else m = cq_measure(b);`, two live
registers): it merges into a measure of the 4.4 controlled-copy mux and ACCEPTS (16 lines, STRICT 2b
clean) — sound (measuring a basis copy is measuring the source); `nomerge` on `cq_measure` would turn it
into a DECLINE (measured). So the evidence is AGAINST adding it; not added, reported to the coordinator.

The ternary spelling is safe for the same reason (coordinator addendum; z0re round 2's `t5nm`): a
select written on ARG-0 (`cq_theta((q == s) ? q : s, θ)`) is a VALUE — CQ reads it as a 4.4 mux into a
FRESH rail, never as an in-place rotation of `q` — so InstSimplify folding it to `s` changes nothing
observable. Register identity is claimed only when arg-0 IS the register, and only a MERGE of two calls
could conflate two such identities; `nomerge` forbids exactly that.

### 9.7 What I ran, literally (Phase 2)

Binaries: no pass code changed. `cq-opt` `3f6db37f…`, `libCQPass.so` `356df92e…`, `cq-opt-debugalloc`
`36033dbf…` — bit-identical to the frozen oracle's three. Every verdict difference below is the HEADER.

* **Header A/B, single-TU** (`ab_hdr.py`, oracle `cq-opt`, every `tests/e2e/*.c` × CASE):
  NULL CONTROL FIRST (committed vs committed): **636 jobs, 611 compiled on both, 0 stage-1 movers,
  0 verdict movers**. REAL (pre-fmt3 `orig_inc/CQ.h` == `git show 9a230646:include/CQ.h` vs committed):
  **638 jobs, 613 compiled on both, 25 need other TUs/flags and were NOT swept; 5 movers** = 3 STREAM
  (the three regenerated if/else goldens) + 2 D→A (the two new in-loop slices, §9.4). The 3 `_ternary`
  slices do not move (their stage 1 is header-independent). (NULL ran before the two in-loop slices were
  added: 636 vs 638.) Files `ab_hdr.P2.{NULL,REAL}.txt`.
* **Header A/B, multi-TU** (`ab_hdr_multi.py`, all **32** `run_slice_multi.sh` registrations, CQ TU
  `-include CQ.h`, libs without, llvm-link, oracle): NULL **0 / 0**; REAL **0 stage-1 movers, 0 verdict
  movers**; POSITIVE CONTROL (a header with `__attribute__((const))` on `cq_theta_si32`) **26 stage-1
  movers, 1 verdict mover** — the harness can see a header change. Files `ab_hdr_multi.{NULL,REAL,POSCTL}.txt`.
* **`e2e-loop-twin-matrix`** (run as the tool, `--jobs 4` instead of the entry's 6, load discipline):
  first run **FAILED on exactly 1 of 382 cells**, `m_none_rifelse_none_none_none`
  DECLINE-BOTH-DIFFERENT → ACCEPT-IDENTICAL (the §9.4 class; its own comment named it the tripwire for
  this). Expected file updated BY HAND with the reason (never `--regenerate`, bd `gfsk`); re-run:
  **382 cells match, 70 quarantined match their pinned signatures, 4/4 boundary controls, rc 0**.
  `loop_twin_matrix_quarantine_test.py`: **58 cases, 0 failures**.
* **ctest** `-R 'frontend|angle-select|stateprep|inplace|railbank-register' -j3`: **71/71 passed**
  (incl. frontend-lit, the 14 angle-select entries, the in-loop pair and its twin gate, the two railbank
  register-twin gates which compile C with the new header). After the last CQ.h comment edit:
  `-R 'frontend|angle-select|loop-ifelse|nomerge'` **18/18**.
* **`lit -j4 ir-pass/test`** (clean binary): **2411 discovered, 2410 passed, 1 XFAIL, 0 failed**.
* The stage-1 cache key configured in `build/` equals `s1_cache_key.py` over the committed headers
  (`bd10b210…`) — the ctest numbers above ran on the NEW header's stage 1, not a stale cache.
* `update_code_map.py` + `--check`: rc 0.
* NOT RUN: full `ctest -j6` (Rule 19 — the merge gate); allocator sweeps and `cq-opt-equivalence-full`
  (no pass code changed: the binaries are the oracle's, bit for bit); `tools/angle_select_twin_matrix.py`
  and `tools/inplace_twin_matrix.py` (instruments, not gates; the former's Ry SUBJECT is the if/else
  spelling and will now DIVERGE from its by-difference twin — noted on bd `gjn2`); the z0re S3 slices
  (not on this branch; the orchestrator re-runs the header A/B after z0re lands).

### 9.8 L1 / L2 / L3

* **L1** — no pass stage changed; nothing between the two control rounds is touched. N/A.
* **L2** (a set WIDENED: the set of programs whose if/else survives `-O1`) — the OTHER sets computed
  over the same closure are every predicate that assumed the merge: `classifyAngleSelect` (Ry stem now
  reached only by the ternary), the `(b)` rail clause and the two-prep clause (now reachable from C), the
  in-loop in-place Ry if/else (now reachable from C — an ACCEPT, §9.4), F2's residual argument (§9.1
  comments). Each was re-asked by a probe (n23, n9, d13a1, n24, the matrix) rather than by reading.
* **L3** (a set NARROWED: the programs `-O1` hands the pass as a select-angle `cq_theta`) — the other
  predicate naming that shape is AngleSelectEmit's S-gates; they are unchanged and still pinned at the IR
  level and, via the ternary, at the C level. `cq_phi`'s Rz stem is untouched (its merge still happens —
  pinned in `cq_theta_nomerge.c`).

### 9.9 ATTACK FIRST (for the Rule-13 round)

1. **Any other `-O1` transform that ERASES a branch without merging two calls.** `nomerge` only stops
   SimplifyCFG's hoist/sink (and codegen tail-merging). I argued, not measured, that nothing else at `-O1`
   can make two arms identical and delete the branch; the retirement trigger is written into F2's header.
2. **`nomerge` coverage**: `_Generic` dispatch, `cq_ry`, the f80 row, `extern "C"`, a C++ TU; a user who
   declares `cq_theta_si32` HIMSELF without the attribute (hand-written prototype) bypasses the header.
3. **The accept §9.4 CREATED**: the rolled in-place Ry if/else reached from C. Attack with a condition on
   the rotated register's own wire, a derived condition, a bool rail condition in a loop, a carried `r`
   read after the loop, the matrix's quarantined axes crossed with `rifelse`.
4. **Inlining shifts**: an if/else that is no longer merged is a bigger body; `-O1` may inline (or not)
   differently, so multi-function programs can reach the pass in a new shape (bd `1yeu`: every corpus is
   one function per module). `inline_check.sh` measured one such case (spelling-driven).
5. **The CONFIGURE_DEPENDS fix**: `ctest` run without a build still uses the last configure's key;
   `run_slice_multi.sh` is uncached (unaffected). Is there any other configure-time snapshot of CQ.h?
6. **The cq_measure argument (§9.6)**: find a merged `cq_measure` pair whose outcome is NOT deterministic
   on the erased edge (i.e. a measure-merge that hides a real measurement).
7. **Deeper nesting** (`n3`, `n16`) and the `switch` forms decline for other reasons today; the day
   nesting lowers, the fixtures' L8 triggers must fire as written.

### 9.10 Proposed CLAUDE.md text (not edited — orchestrator's call)

* Rule 9's list, replace *"it folds an if/else over one register into **one call with a `select` on the
  ANGLE** (drbq Inc 2b)"* with: *"it folds an if/else over one register into **one call with a `select` on
  the ANGLE** — for `cq_phi` only since bd `fmt3` (2026-09-28): `CQ.h` puts `nomerge` on every
  `cq_theta_*`, because the same merge ERASED a branch whose arms had become identical only through an
  IPSCCP pin and handed the pass a different, legitimate-looking program (the `cq_theta` if/else now
  lowers as two controlled Ry; the ternary `cq_theta(r, c ? A : B)` still reaches the angle select)"*.
* §1 table, row "folded if/else angle select, **Ry stem**": add *"from C: the ternary spelling; the
  if/else no longer folds (bd `fmt3`)"*; and a row for *"the if/else of two chained Ry on one register
  (flat and ROLLED)"* — the in-place Ry arm's if/else form, `cRy(f,A); X f; cRy(f,B); X f`.
* A standing lesson: **when an optimisation ERASES the evidence, fix it where the evidence still exists.**
  A fence after the erasure can only be coarse (option A measured 16–24 of 35 e2e literal preps lost,
  including the owner's own files) and still cannot reach a program with no region left to fence.
* Build & Test: the stage-1 cache key is computed at configure time; `include/*.h` is now a configure
  dependency (a header edit + `cmake --build` reconfigures). Before this fix a CQ.h edit served STALE
  stage-1 IR to every e2e slice (measured).
