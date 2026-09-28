# TRACK_FMT3 — bd `test_C_libtooling-fmt3`: the erased-inner-branch fold

**Status: PHASE 1 ONLY (measure the options, stop, report). No Phase-2 code is committed.**
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
| **(B)** `__attribute__((nomerge))` on the 16 `cq_theta_*` declarations in `CQ.h` | **YES** — all 19 measured members decline (nested/no-region, literal/runtime, i1/i32/f64, loop) | e2e: **0 A→D**; stage 1 moves in **3 of 608** (source, CASE) jobs, all STREAM (below) · probe dirs: the 15 members + `zt_*` (4, incl. **owner-ruled accepts**) | 3 goldens restream: `slice_control_angle_select_ry{,_derived_base,_ne}` (same unitary: `cRy(f,A); X f; cRy(f,B); X f` instead of the by-difference `Ry(B); cRy(f,A−B)`, STRICT 2b clean), so `e2e-angle-select-ry-twin-identical` (and any gate pinned to that stream) goes red; `AngleSelectEmit`'s Ry stem becomes unreachable from C at `-O1` | keeps the evidence: the branch survives and the EXISTING fences (nested / two-rail / 2c / F2) decline it; `nomerge` is honoured by LLVM 19's SimplifyCFG hoist and sink (measured: `cq_theta_nomerge.c` red → green) | 16 attribute tokens + 1 frontend fixture + 3 goldens; reverses today's zt0b ACCEPT ruling |
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
  (ii) retires the C-level route into `AngleSelectEmit`'s Ry stem (recoverable later by teaching the pass
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
