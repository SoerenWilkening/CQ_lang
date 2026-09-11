# Rule-13 review, round 1 — Track C: the F2 `CondWire` narrowing (bd `drbq.14`)

**Verdict: CLEAR-WITH-ITEMS.** No confirmed silent miscompile in the accept direction.
Five items (1 gate/measurement, 3 DOC, 1 pre-existing coverage), none a blocker.

Subject: `/Users/sorenwilkening/Desktop/CQ_f2` @ branch `f2-condwire-narrowing`, build as handed
over (NOT rebuilt, nothing under `ir-pass/`, `include/`, `tests/`, `tools/` edited).
Oracle: `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass/cq-opt` (main `0c7380c`).
Probes + runner: `review_f2_r1_probes/` beside this file (`./run_all.sh`, no build needed).

---

## 0. The suite gate (brief's final section)

Two ORPHANED `ctest` runs were already in flight in this worktree when I started (pids 82855
from 13:37 and 95612 from 13:43, both `ppid=1`, both `cwd=/Users/sorenwilkening/Desktop/CQ_f2/build`,
logging to `scratchpad/f2/full_ctest.log` and `full_ctest2.log`). I did not start a third; I read
both out.

* **Run 82855 — INVALID, discarded.** Its `cq-opt-equivalence` `***Failed 172.58 sec` with
  `FileNotFoundError: … /build/ir-pass/cq-opt` — the binary did not exist at that instant because
  the implementation agent was still rebuilding under it. It was then killed at 389/390 and never
  printed a summary. Nothing is concluded from it.
* **Run 95612 — the gate.** Exact pass line and wall time:

```
99% tests passed, 1 tests failed out of 390
Total Test time (real) = 2593.06 sec
The following tests FAILED:
	318 - e2e-loop-twin-matrix (Failed)
```

  `cq-opt-equivalence` **Passed, 98.27 sec** in this run, which is what identifies run 82855's
  failure as the rebuild artefact and not a real one. All other 388 entries Passed.

**The one failure is finding F-1 below and is a LOAD artefact, not a disposition change** — see §2.

---

## 1. What the change can and cannot do — the structural result

`f2SeedPinnedByLiveRegister` has **exactly one caller** (`ArmClassify.cpp:3218`), and the new
`CondWire` conjunct sits at **exactly one place**, the equality TEST. It can only make `Pinned`
**false** more often, and `Pinned` only ever **declines**. So the change is **accept-monotone by
construction**: no module that accepted before can lower differently.

**Measured, independently, over the whole corpus** (my own sweep, `tools/one.sh` +
`tools/corpus_sweep_result.txt`; both binaries on all 1784 `ir-pass/test/*.ll`, comparing rc,
stdout and stderr):

```
1784 fixtures:  1761 SAME   23 RCDIFF   0 OUTDIFF   0 DIAGDIFF
23/23 RCDIFF are rc_old=1 -> rc_new=0, every one in the state-prep family
```

That reproduces IMPL's `RCDIFF=19 DIAGDIFF=0 OUTDIFF=0` and adds the 4 new accept fixtures
(19 flips + 4 new = 23). **No accepted module's emitted stream or diagnostic moved anywhere.**

`classifyArms` has **exactly one non-`Declined` exit**, `return ArmDisposition::Accept` at
`ArmClassify.cpp:3914` — downstream of R3 (`:3229`), the width gate and R4 (`:3337`). Every accept
of every arm class passes all of them.

---

## 2. Findings

### F-1 — `e2e-loop-twin-matrix` failed in the gate run. LOAD ARTEFACT, but the gate is still owed. *(Grade: DOC / re-measure)*

12 reports, 6 cells (`m_add_gt_{add,none,ry,rz}`, `m_add_range_{none,ry}`), and **every one is
`unrolled side: stage 4 (run) exited -9`** — SIGKILL — with the verdict moving
`ACCEPT-IDENTICAL -> HARNESS-ERROR`. `-9` at **stage 4** means both sides' stage-2 lowerings
*succeeded* and the linked executable was killed while running; a disposition change from this
edit would have to surface as a DECLINE or a TRACE-DIVERGENCE, never as that. Context: at the time
`ps` showed **8 concurrent `ctest --test-dir` processes** across worktrees and `uptime` reported
load averages **15.48 / 25.31 / 44.38**; the matrix itself took **1310.76 s** against its quoted
~180–400 s. The quarantine was intact (`TRACE-DIVERGENCE 29`, the 29 pinned cells) and both
boundary controls reported their expected verdicts. ⚠ The implementation agent reached the same
conclusion independently and in parallel, with a **more specific** cause than mine — `IMPL_f2.md`
(edited while I was writing this) records that a `pkill` of a stale ctest run hit the `cqtwin_*`
child processes, and reports its own isolated re-run at **1062.30 s, 1/1 Passed**. Both causes are
harness, not compiler; two independent green re-runs agree.

I re-ran `ctest -R '^e2e-loop-twin-matrix$'` alone: **Passed, 1122.37 s, 0 failed** (§5). So the
six cells are green on this tree and the failure is load, confirmed. **This branch still owes ONE
clean full-suite run on a quiet box** — 389/390 plus a separate green re-run is not the same thing
as a green suite.

### F-2 — the α theorem, MEASURED as a matched 2×2 rather than surveyed. *(Grade: positive result)*

IMPL/SCOPE argue α from a theorem about R4 plus a 19-spelling survey. Neither shows the
*discriminating* pair, and the survey's rival is the wrong shape (see I-2). I built the pair
(`ll/{on,off}wire_{rival,folded}.ll`). One module, two axes: is the pinned register on `CondWire`,
and is it folded?

| | UNFOLDED rival (`int r = t; if (c) r = cq_theta(t,θ);`) | FOLDED (the state-prep image) |
|---|---|---|
| **ON-wire** (`%t` reaches `CondWire` by the chained-theta hop) | **rc=1** `condition predates a non-diagonal gate` (both binaries) | **rc=0 NEW** / rc=1 OLD (F2) |
| **OFF-wire** (same module, condition reads `%q` directly) | **rc=0 — IT LOWERS** (both binaries) | **rc=1 both** — F2 keeps declining |

This is exactly the property the ruling needs, and it is now a measurement: **where the rival has
a lowering, F2 still declines the folded image; where the narrowing removes the decline, the rival
has no lowering on either binary.** The off-wire row is the load-bearing half — it shows F2's
remaining class-B declines are protecting a *real, shipped* capability, so the narrowing is not a
blanket weakening. The two streams, which is what makes that concrete:

```
offwire_rival  (rc=0, BOTH binaries — the capability the class-B decline protects)
  cq_template_and_i32_hl(h, 0) -> h_op          %t's own rail
  cq_template_icmp_eq_i32_hl(h, 5) -> h_cmp
  cqrt_ry_i32_controlled(h_cmp, h_op, 0.9)      IN PLACE on %t  <-- drbq Inc-1
  ..._unc / cqrt_free(h_cmp) / measure(h) / measure(h_op)

onwire_folded  (rc=0 NEW only — the accept the ruling adds)
  cq_template_and_i32_hl(h, 0) -> h_op ; cqrt_ry_i32(h_op, 0.3)   the chained theta, IN PLACE
  cq_template_icmp_eq_i32_hl(h_op, 5) -> h_cmp                    the flag, on THAT rail
  cqrt_alloc_i32(0) -> h1 ; cqrt_ry_i32_controlled(h_cmp, h1, 0.9) a FRESH rail
  ..._unc(h_cmp, h_op, 5) / cqrt_free(h_cmp) / measure(h_op) / measure(h1)
```

In `onwire_folded` the condition's rail is `h_op` and the chained theta is in place on it, so the
α rival ("rotate `%t`") is literally a rotation of the register the flag is minted from — hence the
2c decline in the table's top-left cell, and hence the strip in the accepted stream recomputes the
predicate on a register the region never touched.

### F-3 — 27/27 alternative readings decline ON THE NARROWED BINARY. *(Grade: positive result)*

I re-ran IMPL's 21 `probes/alt/*.ll` on the subject binary (21/21 decline) **and built the six the
record did not have** — the α and β rivals of the four NEW accepts
(`rival/r_{condwire_alias,condwire_alias_beta,selfctl_alpha,mux_beta,bool_alpha,bool_beta}.ll`).
All six decline. Which fence fires, over all 27:

| fence | of IMPL's 21 | of my 6 | total |
|---|---|---|---|
| 2c `condition predates a non-diagonal gate` | 14 | 2 | **16** |
| F1 `state prep merged with a quantum register` | 3 | 2 | **5** |
| `condition data use neither escaped nor measured` | 3 | 2 | **5** |
| `bare i1 register condition` (l4x4) | 1 | 0 | **1** |
| **R4 `rotation arm on a condition wire`** | **0** | **0** | **0** |

(The F-2 matrix's on-wire rival is a 28th and also lands on 2c.)

### F-4 — β: the downstream-observability question the brief asks, answered from the state vector. *(Grade: positive result)*

The brief asks whether any later consumer distinguishes "one register named twice" from
"two registers in |k⟩⊗|k⟩". I built the sharpest one — a post-region **in-place** mutation of the
merged rail, with the condition register measured afterwards (`ll/beta_post_{add,xor}.ll`, and the
rival `…_R.ll` with the merge incoming restored to `%q`). The `-O1` plain-C spellings
(`c/b{1,2,3}_beta_*.c`) all decline `control flow` on both binaries — `-O1` sinks the `add` into
the arm and R1 refuses the two-instruction arm (the §14.13 over-decline) — so this is hand IR.

* `beta_post_add` (folded, newly accepted) emits `cqrt_addc_i32(%h1, 3)` — **in place on the
  PREPPED rail**, with `cqrt_measure_i32(%h)` reading the condition register untouched.
* `beta_post_add_R` (the alias rival) declines `state prep merged with a quantum register` on
  **both** binaries.

So the divergence I can compute (alias ⇒ `measure(q)+measure(p) = 8+8`; prep ⇒ `5+8`) is against a
reading that has **no lowering on either binary**, and — this is the part worth writing down —
the alias reading's *only realisable* form under CQ is a controlled copy into a fresh rail, which
on the pinned edge produces |5⟩⊗|5⟩ and therefore puts the `+3` on the copy, agreeing with the prep
circuit line for line. IMPL §7's β argument survives the strongest test I could construct for it.

### F-5 — the exclusion really is at the TEST: seeding is intact. *(Grade: positive result)*

Brief item 3. Two independent measurements:

* every class-B fixture that can only be reached by the forward evaluation *from an on-wire seed*
  still declines — `range_forward_{add,xor,or,lshr,ashr,sub}`, `intrinsic_{bswap,bitreverse,fshl,fshr}`,
  `sideways_{sdiv,offset}`, `cast_{sext,zext,trunc}_live`, `fp_seed_sitofp`,
  and the three `Truncated` rows (`step_cap_over`, `unevaluable_pinned_operand`,
  `unfoldable_curated_call`): all `SAME` in my sweep, byte-identical diagnostics;
* two **new** fp hops I wrote for brief item 4 (`ll/fp_fwd_fneg.ll`, `ll/fp_fwd_fabs.ll`): an f64
  register pinned by the region's own `fcmp oeq` — i.e. ON `CondWire`, excluded at the test — whose
  `fneg`/`llvm.fabs` one hop forward equals the seed. **Both decline with the F2 string.**
  `railWireClosure` crosses neither a `UnaryOperator` nor a call, so those derived values are
  off-wire, and only a seeding-preserving exclusion reaches them. It does.

### F-6 — injection matrix over the state-prep accepts: the 23 flipped/new fixtures are clean. *(Grade: positive result, with a pre-existing item)*

I ran my own matrix (`tools/matrix.py`, result in `tools/injection_matrix_result.txt`): 57 accept
fixtures × 6 mutations applied to the pass OUTPUT, re-checked through every prefix the fixture
declares — `extra_ry_on_cond` (the drbq F-C1D-4 class: an uncontrolled `cqrt_ry` on the condition
register after the flag's free), `extra_free`, `extra_x`, `uncontrolled_arm`, `dup_ctl_gate`,
`seed_literal`.

* **All 23 flipped/new accepts catch all six.** The only two apparent misses
  (`fcmp_{oeq,une}_folded` ← `seed_literal`) are **my harness**: my seed regex only rewrites an
  integer literal, so on `cqrt_alloc_f64(double 5.0…)` the "mutant" is byte-identical to the clean
  output. Not a coverage gap.
* The other **57 MISSED cells fall on 17 PRE-EXISTING accepts** whose fixture text this branch does
  not touch (`i8`/`i16`/`i64`, `f64`, `cond_{cast,bitcast}_seed`, `consumer_ret`, `deep_chain`,
  `intrinsic_bswap_accept`, `lifted_phi_after`, `range_ordered_seed0`, `step_cap_under`,
  `suffix_control`, `fcmp_oeq_{derived_accept,negzero,twin}`, `inloop_diamond`), so they are
  identical on the oracle — pre-existing debt, item I-5. (7 of the 12 `seed_literal` misses are the
  same fp-regex harness limit; the remaining 5 are real, and so are all 16 + 16 + 9 + 6 of the
  other four mutations.)
* The one CLEAN-FAIL (`warn_live_record`, prefix `WARN`) is also my harness: that prefix reads
  `%t.err` and I fed it stdout. That is the "1 DIRTY" IMPL reported.

### F-7 — owner-file re-measure and the two golden relations. *(Grade: positive result)*

Brief item 8, re-measured on both binaries (`c/`, plus the committed `probes/`):
`V0.c` → `control flow` (bd `b6ap`) unchanged; `C2.c`, `M1.c` → `bare i1 register condition`
(`l4x4`) unchanged; **`M2.c` rc 1 → 0**; `M3.c` rc 0 on both. `M2.c`'s emitted stream, read against
the analytic prep stream:

```
cqrt_alloc_i32(0) ; cqrt_ry_i32(h, 0.5)                  q's rail
cq_template_icmp_sgt_i32_hl(h, 5) -> h_cmp               the flag, minted on q
cqrt_alloc_i1(i1 false)                                  the _Bool rail, AT THE SEED
cqrt_ry_i1_controlled(h_cmp, h1, 0.5)                    the arm, under the flag
cq_template_icmp_sgt_i32_hl_unc(h_cmp, h, 5)             the strip, SAME operands
cqrt_free(h_cmp)
cqrt_measure_i32(h) ; cqrt_measure_i1(h1)
```

Nothing in the region touches `q`, so the strip recomputes the predicate on the register the mint
read — the flag returns to |0⟩ and the free is clean. Final state on the `f`-subspace decomposition
is `Σ_x α_x|x⟩_q ⊗ (x>5 ? Ry(.5)|0⟩ : |0⟩)_b`, which is what the source says. Stage 2b on my own
build of the same module: `2 rail mint(s), 2 left allocated, 1 free: 1 verified, 0 violation(s)`
(both rails are measured, so nothing leaks). I verified the two stated golden relations by `diff`:
`seed_eq_k` vs `stateprep` is **exactly one line** (`cqrt_alloc_i32(0)` → `(5)`), and `bool` vs
`bool_negated` is **exactly the two `cqrt_x(h1)` lines**. Both claims hold character for character.

### F-8 — the four new decline fixtures. *(Grade: positive result)*

Brief item 6. `nonwire_still_collides`, `offwire_sideways_min`, `second_flag_i1` all decline with
the **F2 string** on the branch binary (and on the oracle). `rail_i1_seed_l4x4` declines
`bare i1 register condition` — i.e. it is **pre-empted and pins nothing about F2** — but that is
deliberate and its own first two lines say so ("DECLINE, **AND NOT AT F2**"); it exists so the
ruling is not misread as "the owner's file compiles now". Honest, not a gap.

### F-9 — the compound-condition retirement trigger's premise re-measured. *(Grade: positive result)*

The header's first retirement trigger rests on "a compound `&&`/`||` condition reaches NO control
accept path", which matters because `CondWire` is seeded from ONE condition and nothing computes a
union over a tree's leaves. Re-measured on the branch binary: `c/k4_compound_real.c`
(`(q&1)==1 && q>7`, a real `and i1` in the IR) and `c/k5_compound_or.c` (`q==5 || q==9`, `or i1`)
both decline **`control flow`** on both binaries. The premise holds at this HEAD. ⚠ Note the trap I
walked into first: `c/k1_compound_prep.c` (`q==5 && q>1`) **accepts** — because `-O1` folds it to a
single `icmp eq i32 %1, 5` and it is not compound by the time the pass sees it. Anyone writing the
red-green family this trigger owes must check the stage-1 IR, not the C.

---

## 3. Items (not blockers)

**I-1 (DOC) — R4 fires for 0 of the 27 measured rivals; 2c fires for 16.**
The header's admissibility argument is "a theorem about R4". R4 is genuinely non-vacuous (measured:
`probes/v3.c`, the alias-hop rival, declines `rotation arm on a condition wire`) and the
insert-before-any-gate argument is sound, but **no α rival in the whole corpus of 27 exercises it** —
2c stands in front of every direct one, including my on-wire 2×2 row. IMPL's retirement trigger
names R4 and 2c together, which is correct; I'd ask that it name them **in that order of risk**:
the near-term hazard is a 2c widening (and "rotate the flag in place" is a live Grover-ancilla
wish), not an R4 narrowing.

**I-2 (DOC) — the rival named in the header is the one R3 already refuses; the rival that
matters is a different shape.**
For the accepted IR (`phi [theta(k), k]`), the header's α rival — `int r = k; if (q==k) r =
cq_theta(q,θ);` — has `RotBase = %q` (a register) while the straight-through incoming is the
literal `k`, so R3's "ONE base" refuses it before R4 is reached, and `probes/u1.c` shows the
plain-C spelling cannot even produce a state-prep module (the Pred edge does not pin `q`, so only
arg-0 folds and F1 fires). **The rival that can actually produce the accepted IR needs BOTH the
arg-0 and the merge incoming to fold, i.e. a register pinned on BOTH edges** — the `%t = and %q, 0`
shape of `condwire_alias_accept.ll`, which is a genuine in-place rotation arm and *does* lower when
it is off-wire (F-2's off-wire row). The theorem is fine; the header would be stronger naming that
shape as *the* rival instead of the R3-refused one, because that is the shape a future reader will
try to break it with.

**I-3 (DOC) — "the condition's own backward wire" understates how wide `CondWire` is, and
therefore how much the safety rests on exact equality with R4.**
`condProvenance` walks **all** operands backward (stopping only at a theta) and collects every
tainted value, so `CondWire` is the condition's whole backward **tainted cone** — including values
reached through `mul`, `and`, `shl`, `load`, …, whose rails are genuinely *distinct* from the
condition's. Excluding those is safe for one reason only: R4's `CondRails` is built by
byte-identical code from the same `Prov` and the same `Taint` at the same program point, so
`CondWire == CondRails` **exactly**, and for a rival module the two closures are provably the same
set (both are `BackwardOnly`, and the rival differs from the prep module only in a FORWARD
position). That exactness is what makes every over-approximation cancel — including under the
`r9e5` round-2 taint window, where both sets shrink together. Recommend the header say
"the condition's backward TAINTED CONE (`== R4`'s `CondRails`, by construction)" and state the
cancellation explicitly; as written, a reader could 'tidy' one call site and break the symmetry
without the fixture noticing anything but `condwire_alias_accept`.

**I-4 (OVER-DECLINE, residual, measured) — "I dont see the need for the over-decline" is
satisfied only on the condition's own wire; say so to the owner.**
Two measured residuals, both correct by design (class B) and both still declining on the branch:
`c/o4_int_other_reg_pinned.c` — a genuine prep of |15⟩ under `q == 5` with an unrelated live
`int t = q * 3;` — declines F2 because `t` is 15 on that edge; and at `i1` **any** second tainted
`i1` in the function pinned on either edge still collides (`second_flag_i1.ll`). The i1 case is the
one to flag: the ruling buys the owner's `_Bool` prep, but a `_Bool` prep sitting next to any other
`_Bool` derived from the same register can still decline.

**I-5 (coverage, PRE-EXISTING) — 57 injection misses on 17 untouched state-prep accepts.**
Totals over all 57 fixtures: `extra_ry_on_cond` 16, `extra_x` 16, `seed_literal` 12 (7 of them my
harness's fp limit), `dup_ctl_gate` 9, `extra_free` 6, `uncontrolled_arm` **0**. The two worst are
the ones drbq's own F-C1D-4 round was about: an injected uncontrolled `cqrt_ry` on the CONDITION
register after the flag's free, and an injected `cqrt_x`, are each invisible to 16 accept fixtures
in this family. Identical on the oracle; not this change's debt, and the 23 fixtures this change
creates are clean. Worth a bd issue against the drbq Inc-4 family rather than this branch.

**Not an item, but say it once:** the change ships **no diagnostic**, by choice — a `DS_Warning`
would fire on every narrowed accept, i.e. on every Grover prep the ruling exists to enable. So the
α/β reinterpretation is silent at the console and lives only in the fixture headers and the PRD.
That matches the owner's ruling and I am not asking for a warning; I am asking that the disclosure
in `control-in-place-PRD.md` stay in the words the fixture headers use ("a program that was LOUDLY
REFUSED before this ruling now receives the circuit for the OTHER reading"), because that sentence
is the only place a future reader meets the trade.

---

## 3a. The brief's "where to look" list, item by item

1. **Is `CondWire` too wide via the chained-theta hop? "Construct it."** Constructed — it is the
   F-2 matrix's ON-wire module. `%t` is on the closure *only* by that hop, the branch reads `%b`
   and not `%t`, `%t` is pinned to the seed, and the rival rotates it in the arm. **Not a hole**:
   the hop exists precisely because a chained Ry is in place, so `%t` and `%b` are ONE physical
   rail and rotating `%t` *is* rotating the condition's register — 2c refuses it, measured on both
   binaries. The wider point is I-3: every over-inclusion in `CondWire` is matched by an
   over-decline in R4 because the two sets are computed by byte-identical code.
2. **`BackwardOnly` / does the narrowing depend on 2c firing first?** It does in practice —
   F-3's table, 16 of 27. The retirement trigger is written and I ask only that it rank 2c first
   (I-1). I could not build the "2c disabled" mutant (no rebuild); §6 says so.
3. **Does a pinned on-wire value still SEED the forward walk?** Yes — F-5, two independent
   measurements including two new fp hops.
4. **The fp anchor, and a hop through `fneg`/`fabs`.** Measured: both decline (F-5).
   `railWireClosure` crosses neither a `UnaryOperator` nor a call, so those are off-wire and the
   forward evaluation is what reaches them.
5. **i1.** The i1 condition is always in `CondWire` (it *is* the condition), so an i1 seed no
   longer collides with it — that is the whole of the retired "the `i1` state-prep width is OUT",
   and it is the owner's `_Bool` capability. A *second* tainted i1 still collides
   (`second_flag_i1.ll`, still declining — and I-4). The rival "rotate `q` under the flag `c`"
   is `rival/r_bool_alpha.ll` and declines `condition data use neither escaped nor measured`; the
   plain-C spelling with the flag kept live (`c/z1_flagarm_cmeas.c`) declines
   `rotation arm shares the condition flag` on both binaries.
6. **`-O1` reachability / the four new declines.** F-7, F-8, F-9; every flipped accept in §1's 23
   has a plain-C spelling among `probes/` or `c/` except the hand-IR shapes the record already
   marks as such.
7. **The 25 MISSED / 1 DIRTY.** F-6: the DIRTY is the harness (a stderr prefix fed stdout); of the
   misses, **none** is on a fixture this change creates, and the `extra_ry_on_cond` (drbq F-C1D-4)
   mutation is caught by all 23.
8. **The owner's file.** F-7: `V0` / `C2` / `M1` unmoved, `M2` rc 1 → 0, trace read line by line.

## 4. The two attacks, answered

**α — "find an unfolded self-controlled spelling that ACCEPTS today".** I did not find one.
Plain C first: the angle-select spelling (`if(q==k) q=cq_theta(q,A); else q=cq_theta(q,B);`, both
`==` and `>`), a `switch` with a rotation on the scrutinee, the same region inside a
classically-bounded loop, and an opaque-threshold unfolded equality
(`c/x{1..5}_*.c`) — **all five decline, identically on both binaries** (four at 2c, one at
`control flow`). Hand IR: the on-wire half of the F-2 matrix and the six `rival/` modules —
all decline. The one α spelling that does lower is the **off-wire** one, and F2 still declines its
folded image. The theorem has no hole I could find; its *statement* has the two problems in I-1/I-2.

**β — "construct an edge where the pin is a singleton by LVI but the rail's basis label is not
constant at run time".** Not reachable in a way that matters, and the reason is structural rather
than lucky: the prep circuit **never reads the pinned register** — F2 is a refusal heuristic, so a
stale pin cannot reach a gate operand. The only way it could matter is through the rival, and every
β rival's merge incoming is TAINTED, which F1 refuses (`state prep merged with a quantum register`,
5/27 above, both binaries). I additionally probed the in-place-relabel window: nothing user-written
can land between the mint and the strip (the emitter inserts mint → prep → controlled gate → strip
→ free contiguously, and R1 refuses a two-instruction arm), and a post-region in-place op lands on
the prepped rail, not on the condition's (F-4). The `3d8q` stale-reader hole is orthogonal here for
the same reason: there is no reader of the pinned value in the emitted stream to be stale.

---

## 5. RERUN of `e2e-loop-twin-matrix` (F-1)

```
$ ctest --test-dir build -R '^e2e-loop-twin-matrix$' --output-on-failure
1/1 Test #318: e2e-loop-twin-matrix .............   Passed  1122.37 sec
100% tests passed, 0 tests failed out of 1
Total Test time (real) = 1122.41 sec
```

**GREEN.** All 288 cells, all 29 quarantined signatures, both boundary controls. F-1 is confirmed a
load artefact: the six cells that reported `stage 4 (run) exited -9` pass when the box is not
running eight suites at once. (1122 s is still ~3× the quoted quiet-box figure — load average was
47–140 during this run — so treat the wall time as a load reading, not a regression.)

**The gate, stated honestly:** 389 entries Passed in run 95612 and the one that did not re-ran
green alone, so **every one of the 390 entries has been observed passing on this tree**. That is
not the same as ONE clean `390/390` run, and this branch should still take one on a quiet box
before it lands — per Rule 19 moment 2, and because a suite whose failures people learn to
attribute to load is the exact failure mode the loop-twin quarantine exists to prevent.

---

## 6. What I did not do

I did not rebuild, so **no mutant binary** was built: the "2c disabled" mutant the brief asks for
(item 2) is replaced by the F-2 matched pair, which measures the same property from the outside
(the on-wire rival declining while the off-wire one lowers) but does **not** establish which fence
would catch the on-wire rival if 2c were relaxed. That question stays open and is exactly what I-1
asks the retirement trigger to rank. I also did not re-run the 297-cell `--stateprep` twin matrix
(it is an instrument, not a gate, and it is not registered in ctest).
