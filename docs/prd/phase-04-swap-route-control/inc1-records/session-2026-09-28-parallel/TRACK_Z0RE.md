# Track z0re — the RUNTIME state-prep seed and the UNTAINTED Ry-stem angle-select base, on the direct path

bd `test_C_libtooling-z0re` (owner ruling 2026-09-28, option (a)), with bd `drbq.14` §14.11 Q2
(granted by that ruling) and bd `drbq.13` (NOT taken — §4, a measured counter-example; reported
back). Branch `worktree-agent-a284a60d747f2ed82`, off `main` `9a230646`. Probes under
`z0re_probes/`. Oracle: the frozen `cq-opt.main_9a230646` (`3f6db37f5cf937b4d70f5736`).
Subject: `cq-opt` `51b5f78d84de5c6befe82496`, `libCQPass.so` `fe42a1e8ad49bb261e64c86c`,
`cq-opt-debugalloc` `8ef237e9e0fcdffd8b770808` (the rebuilt subject after the mutant builds is
byte-identical to the snapshot `z0re_bins/cq-opt.subj_v2` every measurement below used).

**Not self-cleared. This is an ACCEPT-direction widening of F1 and of `classifyAngleSelect` S3
— Rule-13 lowering core — and it owes independent rounds.**

---

## 1. Headline

1. **F1 admits a RUNTIME seed.** `int r = s; if (COND) r = cq_theta(s, θ);` with `s` an untainted
   `Instruction`/`Argument` (the same SSA value as the merge's Pred incoming) lowers to
   `cqrt_alloc_<W>(s)` + `cqrt_ry_<W>_controlled(f, h, θ)` — the Inc-4 prep stream with a runtime
   operand. One shared predicate, `isRuntimeStatePrepSeed` (`ArmClassify.cpp:3912`), called by F1,
   by S3 and by the angle-select emitter's step-0 re-ask. F1's identity clause is unchanged, so a
   runtime seed that is NOT the Pred incoming still declines (`…_runtime_seed_mismatch.ll`), and a
   tainted Pred incoming still declines as the no-cloning mux (`…_quantum_incoming.ll`).
2. **S3 admits an UNTAINTED RUNTIME Ry-stem base.** `if (c) r = cq_theta(t, A); else r =
   cq_theta(t, B);` (one theta on an angle select after `-O1`) lowers by difference on a fresh
   rail: `alloc(t); ry(h, B); ry_controlled(f, h, A−B)`. S1's constant-arms/rounding fences are
   untouched. S7's rail prong, S8 and S9 are SKIPPED for that base (the §14.5 argument).
3. **A LITERAL angle-select base stays DECLINED** — bd drbq.13 is **not** included. Counter-example
   `a1` (§4): `-O1`'s IPSCCP folds a LIVE register into the literal on one edge before SimplifyCFG
   sinks the arms, and F2 — the fence for exactly that at the diamond — is an edge analysis a
   select does not have. **This is the report-back item.**
4. **F2 is re-asked for a non-`Constant` seed** as a RELATIONAL question with LLVM's own
   implication engine (`isImpliedCondition` for integers; the fp anchor's own polarity table,
   extracted as `fcmpEqualityHoldsOnEdge`, for fp), in the same function, over the same candidate
   list, behind the same three exclusions (now one lambda, `excludedAtTest`). It is **fully masked
   by `CondWire`** for every condition that reaches a state prep today and **measured live**
   (mutants M2/M3 kill one fixture each). The constant walk and its `Truncated` half do not run for
   a runtime seed; the argument is §5.2.
5. **A NEW L1 obligation, and the first spelling of its record was WRONG.** A literal seed can
   never turn quantum; a runtime seed derived from a 6.5/4.5 merge `%out` can, between F1's round-1
   verdict and `lowerRotations`' FINAL-taint `Chained` decision — and then the "prep" lowers as an
   in-place controlled Ry that R4/R6 (or S8/S9) never vetted. Fixed by RECORD + RE-ASK:
   `ControlRegion::RuntimeSeedAdmitted` (the classifier's verdict) → the emitters record the source
   theta in `TaintSet::RuntimeSeedSourceThetas` → `declineRound2QuantumPrepSeeds` after
   `specialize()` in BOTH entry points (`state prep seed became quantum`). ⚠ The first build keyed
   the record on the taint AT EMISSION and **accepted** the hazard fixture (§5.4) — the 6.5 region
   emitted first had already RAUW'd the seed to its tainted `%out`.
6. **Twin == side door.** 13 C twin pairs ACC-SAME (all twin-identical, STRICT 2b clean) where the
   oracle had 13 DECL-SAME; two hand-IR side-door pairs carry byte-identical CHECK blocks; three new
   `*-twin-identical` e2e gates.

## 2. The ruling and the scope actually implemented

| shape | before (oracle) | after | note |
|---|---|---|---|
| diamond prep, runtime seed (int / i1 / f64, arg, load, call, φ, `cq_measure` result, loop-variant) | F1 decline | **ACCEPT** | the ruling's (1) |
| diamond prep, runtime seed ≠ Pred incoming | F1 decline | F1 decline (same string) | identity clause |
| diamond prep, runtime seed, TAINTED Pred incoming | F1 decline (`seed does not match`) | F1 decline (`merged with a quantum register`) | STRING mover, the split now names the physics |
| Ry-stem angle select, untainted RUNTIME base | S3 → `rotation angle` | **ACCEPT** | the ruling's (2) |
| Ry-stem angle select, LITERAL base (drbq.13) | S3 → `rotation angle` | S3 → `rotation angle` | **not taken, §4** |
| either, seed tainted after the round-2 fixpoint | F1 / S3 decline | `state prep seed became quantum` | new L1 re-ask |
| hand-IR if/else two-prep (Q4) | `if/else state prep allocates two rails` | unchanged | recorded asymmetry, §9 Q3 |
| fp literal seed pinned by `fcmp oeq` | F2 fp anchor decline | unchanged | notes §9 item 24 untouched |

**fp.** The ruling's text gives an `int` example; its purpose is "twin and side door accept with
the same circuit", and bd z0re's own member list includes the f64 width (`zxdC`, r1B d88e). The
literal-fp precaution (notes §9 item 24) is about an `fcmp oeq` edge pinning a LITERAL seed; a
runtime seed is never an IPSCCP constant fold, and its own `fcmp` question is the relational half.
So fp runtime seeds are ADMITTED, with one fixture and one e2e slice; **flagged as §9 Q2 so the
owner can pull it** (the lever is a one-conjunct `isIntegerTy()` in `isRuntimeStatePrepSeed`).

## 3. Mechanism, measured (Rule 11 — read the IR)

**The `-O1` pipeline has no equality-propagating pass.** `clang -O1 -mllvm -print-pipeline-passes`
on `src/e01.c`: `ipsccp` ×1, `sccp` ×1, `early-cse` ×2, `instcombine` ×8, `simplifycfg` ×9; **no**
`gvn`, `newgvn`, `jump-threading`, `correlated-propagation`. IPSCCP/SCCP substitute only lattice
CONSTANTS (PredicateInfo copies of a condition operand pinned to a constant).

**Probe battery `src/e*.c` (stage 1 read for every relational rival):**

| probe | source | `-O1` IR | oracle | subject |
|---|---|---|---|---|
| e01 | `r=s; if (q==s) r=cq_theta(s,.2)` | as written | F1 | ACCEPT |
| e02 | `r=s; if (q==s) r=cq_theta(q,.2)` (α rival) | arg-0 stays `%q` | 2c | 2c |
| e03 | `if (q > s)` | as written | F1 | ACCEPT |
| e04 | `if (q == s+1)`, seed `s` | as written | F1 | ACCEPT |
| e05 | seed = noinline fn ARGUMENT | as written | F1 | ACCEPT |
| e06 | seed = load of a global | as written | F1 | ACCEPT |
| e07 | seed = `cq_measure(q0)` | as written | F1 | ACCEPT |
| e07u | UNCONDITIONAL `cq_theta(cq_measure(q0), .2)` | — | **ACCEPT** (`cqrt_alloc_i32(%m)`) | ACCEPT |
| e08 | seed = classical φ | as written | F1 | ACCEPT |
| e09 | `r=q; if (q!=s) r=cq_theta(s,.2)` (β rival) | Pred incoming stays `%q` | F1 | `merged with a quantum register` |
| e10 | `r=s; if(q!=s); else r=cq_theta(q,.2)` | arg-0 stays `%q` | 2c | 2c |
| e11 | f64 runtime seed | as written | F1 | ACCEPT |
| e12 | `_Bool s = atoi(..) & 1` | seed materialised TWICE (`trunc` in pred, `and`+`icmp` SUNK into the arm) | `control flow` | `control flow` (§9, bead) |
| e12b | `_Bool s = atoi(..) != 0` | as written | `control flow` | ACCEPT (`cqrt_alloc_i1(%9)`) |
| e13 / e14 | in-loop, seed `s+k` / `s` | rolled | F1 | ACCEPT, rolled |
| e15 | `t=q/4; r=s; if (t==s) r=cq_theta(t,.2)` | arg-0 stays `%t` | 2c | 2c |
| e16 | `r=q; if (q==s) r=cq_theta(q,.2)` | as written | 2c | 2c |

**The one relational fold `-O1` DOES perform, measured (`src/p1.c`, PRE-EXISTING):**
`int t = q/4; int r; if (t == s) r = cq_theta(t, .9); else r = cq_theta(s, .9); … cq_measure(t)`
compiles at `-O1` to an **UNCONDITIONAL** `cq_theta(s, .9)` with `t` live and measured — SimplifyCFG
sinks the two calls (ONE differing operand ⇒ one φ), `FoldTwoEntryPHINode` makes the φ a select,
and InstSimplify folds `select (t == s), t, s` → `s`. The oracle accepts it (exit 0). It produces
no REGION, so neither admitted site is reached; it is the α trade the owner ruled 2026-09-11 for a
folded self-controlled rotation, in an unconditional spelling. Filed as an owner-awareness bead
(§10). It is also why the F2 header says "a diamond whose arm holds a `cq_theta` CALL never becomes
a select" and not "no relational substitution happens at `-O1`".

## 4. Why the LITERAL angle-select base (bd drbq.13) is NOT included — the report-back

`src/a1.c`: `int t = q/4; int r; if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .3); return
cq_measure(r) + cq_measure(t);` compiles at `-O1` to

```
%7  = and i32 %6, -4 ;  %8 = icmp eq i32 %7, 20
%9  = select i1 %8, double 0.9, double 0.3
%10 = call @cq_theta_si32(i32 5, double %9)      ; base = LITERAL 5
%11 = sdiv i32 %6, 4                              ; t — LIVE, measured
```

IPSCCP pinned `t` to 5 in the true arm, SimplifyCFG sank the now-arg-0-identical thetas, InstCombine
moved the compare SIDEWAYS off `t`. The source rotated `t` IN PLACE on the `t == 5` branch; admitting
a literal base prepares a fresh |5⟩ and leaves `t` unrotated. `t` is OFF the condition's wire (the
compare reads `and q, -4`), so this is F2's F-R1-1 class, not the owner-ruled α trade. The diamond
spelling `a8` declines at F2 on both binaries. **F2 cannot be asked of a select**: it anchors on
`LazyValueInfo::getConstantRangeOnEdge`, and LLVM 19 exposes LVI's condition analysis only through
a branch edge or a select-OPERAND use (`getConstantRangeAtUse`) — neither exists for the candidates.
`a2/a5/a7/a9/a10` (on-wire, deleted-register and plain literal spellings) also land on S3's literal
refusal; `a9` (t dead) would be the Q3 deleted-register residual if admitted.

**A RUNTIME base cannot be the image of this fold**: IPSCCP produces constants only, and SimplifyCFG
sinks a call only when at most ONE operand needs a φ (`NumPHIInsts <= 1`), so arg-0 must already
agree in both arms before the sink — `a3`/`a4` (runtime `s` in one arm, register in the other) keep
the if/else UNSUNK and decline at 2c.

**Options for the owner** (bd drbq.13 notes): (a) keep the literal base declined (shipped);
(b) a COARSE fence — decline a literal base when any live tainted value of its type, off `CondWire`,
has an unconditional range containing the literal (sound, monotone, but it declines most
multi-register programs); (c) a precise select-condition F2, which needs either LVI's condition
analysis re-spelled for selects (L5's warning) or a scratch-CFG query. Fixtures pin (a):
`control_angle_select_reject_literal_base_offwire_fold.ll` (a1's IR), and the re-headed
`control_angle_select_reject_state_prep.ll`; mutant M7 (admit the literal) turns both red.

## 5. The change and why it is sound

### 5.1 F1 (`ArmClassify.cpp` ~5540-5580)
Clause 1 now reads `!PreallocatedBankSeed && !isa<ConstantInt> && !isa<ConstantFP> &&
!isRuntimeStatePrepSeed(RotBase, Taint)` → decline. Clauses 2 (Pred incoming pointer-identical to the
seed; tainted incoming → no-cloning split) and 3 (seed type vs callee suffix width) are unchanged.
The merge is faithful by SSA identity: on the `f=0` component the fresh rail holds exactly the bits
the straight-through edge carries. `ConstantExpr` / `GlobalValue` / `undef` / `poison` stay refused
for their recorded reasons. A runtime seed dominates the branch (it is the Pred incoming), so the
hoisted `cqrt_alloc_<W>(s)` is well-placed. `cqrt_alloc_<W>` takes a runtime value at every width
F1 admits (`cq_runtime.h:94-102`; the unconditional `cq_theta(atoi(..), θ)` has always used it).

R4/R6 stay SKIPPED for a prep, and the skip matters MORE for a runtime seed: `railWireClosure(%s)`
inserts `%s` before its taint gate, so R6 would enumerate CLASSICAL reads of `s` after the region as
stale records (`…_runtime_seed_classical_reads.ll`).

### 5.2 F2 for a non-`Constant` seed (`f2SeedPinnedByLiveRegister`, header block at ~1970)
- **The constant walk has no subject** for a runtime seed: every constant-producing pass at `-O1`
  substitutes a CONSTANT, so `f2Exact(V,S) == Seed` cannot hold, and `Truncated`'s premise ("an
  unevaluable function of a pinned register might have folded to the seed") is about a constant the
  fold could have produced. The one way a fold leaves a runtime value in the ARM slot is an
  arm-local expression over a pinned register simplifying to `s` (`smax(W,s)`, `W + s − k`) — an
  out-of-place rail the fold DELETES, i.e. PRD §14.11 Q3's deleted-register residual (both readings
  agree on every rail anything reads). The PRED slot cannot receive one (only a condition operand is
  renamed along the edge, to a constant).
- **The relational rewrite** (replace tainted `W` by `s` where the edge proves `W == s`) has no `-O1`
  producer (§3) and is asked anyway: `isImpliedCondition(BrCond, ICMP_EQ, V, s, DL, edge)` over
  `Cand`, and the fp polarity table over the branch's own `fcmp`, both behind `excludedAtTest`. For
  a single-compare or bare-rail condition the only values a branch can imply equal to `s` are its
  own operands, all in `CondWire` → **fully masked** (the owner's α trade, applied unchanged). M2/M3
  (drop the exclusion) each kill exactly the fixture built for it.
- `excludedAtTest` and `fcmpEqualityHoldsOnEdge` are behaviour-preserving extractions of the
  literal path (one spelling for both TESTs, Rule 14); measured by the corpus A/B (§8.2) — no
  constant-seed module moved.

### 5.3 S3 (`classifyAngleSelect` ~9075-9123) and the emitter
`UntaintedBase && !(IsTheta && isRuntimeStatePrepSeed(RotBase, Taint))` → `NotApplicable`
(unchanged string). For an admitted untainted base the base closure is not computed (`if (!IsPhase
&& !UntaintedBase)`, ~9385), which makes S7's rail prong, S8 and S9 vacuous — the §14.5 skip: the
rotated rail is minted by the emitter's unconditional twin `T0`, so it has no pre-region name. The
theta is unconditional in the source (only its angle is conditional), so the fresh rail is prepared
at |t⟩ on BOTH components — there is no inactive component whose "prepped vs |0⟩" disposition could
be unproven (the old S3 comment's reason, which was the diamond's). Emitter step 0 re-asks the same
predicate (`AngleSelectEmit.cpp:360`); step 5's comment now says S8 is SKIPPED, not proved, for this
base. `ry(h, B); ry_controlled(f, h, A−B)` is Ry-additive per qubit (`cqrt_ry_<W>` is tensored), the
same identity the Inc-2b tainted-base path rests on.

### 5.4 L1 — record and re-ask (NEW; and the measured failure of the first spelling)
**Hazard, built:** `control_inplace_ry_reject_stateprep_runtime_seed_round2_quantum.ll` — a 6.5
classical call under quantum control produces `%y`; `if (q2 + y > 7) r = cq_theta(y, .2)` with
`r = y`. Round 1: `%y` untainted → prep, F1 admits. The 6.5 region RAUWs `%y` → `%out`; round 2
taints it; `lowerRotations` lowers the hoisted theta CHAINED:
`cqrt_ry_i32_controlled(%h_cmp2, %out, .2)` with the flag minted from `add(%out, q2)` — a rotation
on the condition's wire, and `opt` exit 0 with only the M-A `non-diagonal gate over a live derived
record` WARNING (measured on the first build, `cq-opt` `d4bfb35b…`).

**The first fix was wrong, measured:** the emitters recorded the source theta when
`isRuntimeStatePrepSeed(Base, taint)` held AT EMISSION. When the 6.5 region is emitted first in the
same `lowerControlRegions` loop, `Base` is already `%out` (tainted) → nothing recorded → the re-ask
is blind → the fixture still ACCEPTED. **Fix:** the classifier's verdict is carried on the region
(`ControlRegion::RuntimeSeedAdmitted`, set by `classifyArms` at the rotation-arm accept and by
`classifyAngleSelect`), and the emitters record on THAT (`SwapRouteEmit.cpp:965`,
`AngleSelectEmit.cpp:529`). The source theta is captured BEFORE the per-gate loop, so the
rail-negated spelling (where the clone `TNeg` becomes the last gate) still records the theta whose
arg-0 is the seed (`…_runtime_seed_rail_negated.ll`).

**It is reachable from PLAIN C, and the re-ask is load-bearing there** (`src/l3C.c` / `l4C.c`,
2-TU with `__attribute__((const)) int f(int)` in a library TU, and a classical `if (c > 1000)
puts("x");` between the regions — the bd fn1q/35t0 "block in between" trick; without it, `l1`/`l2`
decline `control flow` at the `hcrg` precedence check on the subject). On the subject both decline
`state prep seed became quantum`; under mutant M6 (re-ask disabled) both ACCEPT at exit 0, STRICT
2b `0 violation(s)` (census: `3 template rail mint(s) of which 1 left dirty`), and the stream
(`out/m6/l3C.5_7.trace`) is `h6 = cq_template_add_i32(h3 /*%out*/, h1); h7 = icmp_sgt(h6, 7);
cqrt_ry_i32_controlled(h7, h3, .2)` — an Ry on the `%out` rail the flag's own derived record `h6`
reads, `h6` left dirty and entangled (Rule 8), with only the M-A `non-diagonal gate over a live
derived record` WARNING. On the ORACLE both decline at F1 / S3 (a literal-only seed never reached
this). **So the widening introduces this hazard and the re-ask closes it; neither half is
hand-IR-only.**

**Re-ask slot:** `declineRound2QuantumPrepSeeds` (`ArmClassify.cpp:3948`) right after
`declineScrubbedHandleReads` in `run()` (`CQLoweringPass.cpp:1010`) and `runOnFunction()` (`:1654`).
It asks exactly `lowerRotations`' `Chained = Tainted(arg0)` on the recorded source theta, at the
taint `lowerRotations` starts from (nothing between `specialize()` and it writes `taint.Tainted`).
Placed before `specialize()` it would still be sound (a seed untainted at classification is not a
Phase-6 site `specialize()` re-marks) but would over-decline the exotic seed round 2 taints through
a spec call and `specialize()` scrubs back. Both hazard fixtures decline; M4/M5/M6 each kill.

## 6. L1 / L2 / L3

- **L1.** Stages between the rounds that consume the verdict: the emitters (record on the flag) and
  `lowerRotations` (re-asked). F2's relational half is asked at detection taint and is fully masked
  by `CondWire`; a round-2-tainted value that could be implied equal to `s` must be an operand of
  the branch condition, and for the seed itself the re-ask fires. A condition's CLASSICAL operand
  turning quantum at round 2 is a PRE-EXISTING question for every prep and in-place arm (literal
  seeds included); MEASURED (`src/l5C.c`: literal seed `0`, condition `q2 > y` with `y` a 6.5
  result, `puts` block between): it declines loudly on BOTH binaries with `no template for opcode
  'icmp i1' in tainted context` — the late Q+Q flag-mint refusal, not a named fence, and
  identical before and after this change. `specialize()`
  runs after round 2 and only shrinks taint (plus re-marks sites tainted at propagation); a seed
  untainted at classification cannot be re-marked.
- **L2 (what other set is computed over the same closure?).** The prep's R4/R6 closure and the
  angle select's `BaseWire`/`BaseWireOrder` (S7-rail, S8, S9) — all skipped for the admitted class,
  argued once (§5.1/§5.3). `CondWire` is unchanged and still the R4-identical set; the relational
  test reads it through the same lambda as the constant test. `ControlledRotations` gets the same
  entries as for a literal prep. `iterationLocalRollable`'s (c2) uses `MintSeed = T` for a prep,
  unchanged; the seed can now be loop-variant, and the in-body alloc reads the per-trip value
  exactly as the unrolled twin does (measured, §7).
- **L3 (when a set is narrowed, what else names the gate?).** The literal-only F1 clause was also
  the implicit reason `inPlaceRotationArmTheta`'s comment, the §14.2e comment, the (c2) comment,
  `SwapRouteEmit`'s identity comment and `RotationLowering`'s F1 summary gave — all corrected at
  the source (L7). The old S3 comment's "prepped vs |0⟩" reason is replaced by the real one.

## 7. Twin battery (the correctness criterion)

`z0re_probes/twins.sh` + `mktwins.py`: 11 side-door pairs (C = `t = h(q, m)` with a lib whose `h`
reads `a` into a volatile local; T = hand-inlined `t = m + 1`) + 2 loop pairs (rolled vs
hand-unrolled). Args `5 7` and `2 9`; STRICT 2b on both halves.

| binary | result |
|---|---|
| ORACLE | 13 of 13 **DECL-SAME** (11 at F1's literal clause, 2 at S3 `rotation angle`) |
| SUBJECT | 13 of 13 **ACC-SAME**, 26 of 26 stage-2b `0 violation(s), 0 unproven` |

Added after the first battery (same harness, subject): `lc` (a loop-carried CLASSICAL seed `s = s*2+1`,
rolled vs unrolled) ACC-SAME 24 lines (oracle DECL-SAME at F1); `zgl` (r1B `zgT` rolled vs a
hand-unrolled twin — loop-invariant runtime seed, condition `q2 > i`) ACC-SAME 23 lines; the r1B
pairs `r1b_za` / `r1b_zb` / `r1b_zi` ACC-SAME. Degenerate "pairs" used only for their verdict:
`l1`/`l2` (the L1 shape with the 6.5 merge IS the prep's Pred) decline `control flow` at the
`hcrg` precedence check on the subject (F1 on the oracle); `l3`/`l4` (with a `puts` block between)
decline `state prep seed became quantum` on the subject and ACCEPT under M6 (§5.4); `l5` (a
LITERAL seed with a round-2-tainted condition operand) declines `no template for opcode 'icmp i1'`
on both binaries (§6).

(`l12 l17 a02 a01 r03 zc zf zj zk zm zxd lv li` — the prep under a compare, under a bare `_Bool`,
the prep whose condition reads the spec argument, the angle select, the prep + classical lift, +
in-place add, + second controlled Ry, + unconditional Ry, + lift on the hoisted gate, the angle
select + lift, the f64 width, and the two loops.) ⚠ **What the C side does NOT exercise:** since bd
vsfp the dead-argument drop fires on `volatile int z = a;` too (measured,
`CQ_DEADARG_DBG: drop arg 0 of @h`), so from C both halves reach the DIRECT path. The side door
itself is reachable only from hand IR (a BRANCH-ONLY read of `a`) and is pinned by
`spec_stateprep_runtime_seed_side_door{,_twin}.ll` and `spec_angle_select_runtime_base_side_door{,_twin}.ll`:
the side door ACCEPTS on the oracle and the subject with the stream the twin now produces (the
oracle declined the twin), CHECK blocks identical.

## 8. What was run, literally

### 8.1 lit, ctest, code map
- `cd build && lit -j4 ir-pass/test` on the subject: **2424 discovered, 2423 passed, 1 XFAIL, 0
  failed** (553 s under a load average of 150-400 from other agents); RE-RUN on the final tree
  after the pause (§8.7): **2425 discovered, 2424 passed, 1 XFAIL, 0 failed** (227 s,
  `results/lit_final.txt`).
- `ctest --test-dir build -j4 -R 'z0re|stateprep|angle-select|spec-lift|spec-dropped|inplace-ry'`:
  **90/90 passed** (incl. the 11 new e2e entries and 3 new `*-twin-identical` gates).
- `ctest --test-dir build -j2 -R 'taintset-scrub|cq-opt-equivalence|scrub'`: **9/9 passed**
  (`taintset-scrub-guard` + selftest for the new `TaintSet` member; `cq-opt-equivalence` sampled).
- `python3 tools/update_code_map.py` then `--check`: rc 0 (6316 → 6319 named functions).
- NOT run (Rule 19, owner ruling 2026-09-26): the full `ctest -j6` — the merge gate's.

### 8.2 Corpus A/B vs the frozen ORACLE (`z0re_probes/ab.py`, `results/ab_v2.txt`)
One pass: stage 1 built once (4-way), the SUBJECT run twice, the ORACLE once, ≤4 workers.
Modes `lit` (every `ir-pass/test/*.ll` at the time of the sweep — the later
`…_round2_quantum_from_c.ll` is not in it and was red-greened separately), `e2e` (every
`tests/e2e/*.c`, every CASE of the matrix sources), `multi` (every `run_slice_multi.sh` entry,
llvm-linked as the harness does) and `probes` (every C source in the prior session's `d88e_probes`,
`review_r1A_d88e`, `review_r1B_d88e` and this session's `z0re_probes/src`, 2-TU where a `.lib.c`
exists).

- **Denominator: 3632 jobs; 3607 runnable; 25 NOT swept** — all 25 are `tests/e2e/*_lib.c` library
  TUs, which carry a C18 `#error` tripwire against `-include CQ.h` by design; each is swept as part
  of its `multi` module.
- **NULL CONTROL (subject vs subject), run FIRST in the same pass: 0 movers of 3607.**
- **ORACLE vs SUBJECT: 92 movers of 3607 — 88 D→A, 4 STRING, 0 A→D, 0 STREAM.** Accepts 1902 → 1990.
  - **D→A (88), every one a runtime-seed prep or a runtime-base angle select, and every one
    intended:** the 11 new/flipped z0re accept fixtures (incl. the two hand-IR TWINS — the
    side-door halves were already accepts); the 7 z0re e2e sources + 2 z0re multi modules; the
    d88e/r1A/r1B probe pairs `a01 a02 l12 l17 r03 za zb zc zf zg zi zj zk zm zxd` (C AND T —
    since bd vsfp both halves reach the direct path); this session's probes (`a01 a02 a6 e01 e03
    e04 e05 e06 e07 e08 e11 e12b e13 e14 i8c l12 l17 li lv r03 zc zf zj zk zm zxd`). The r1B
    `za`/`zb`/`zi` members (a classical read / a second unconditional prep of `t` / the angle select
    + `t`) were re-measured as twin pairs (`r1b_*`): ACC-SAME.
  - **STRING (4):** the three new decline fixtures (`…_round2_quantum` ×2: oracle F1/S3 →
    `state prep seed became quantum`; `…_quantum_incoming`: `seed does not match` → `merged with a
    quantum register`) and probe `e09` (the C form of the last).
  - **No pre-existing fixture, e2e slice or multi module moved** other than the three this change
    re-derives deliberately (`…_reject_stateprep_runtime_seed.ll`,
    `spec_reject_dropped_arg_statepred_runtime_seed.ll`, and `control_tainted_diag.ll`, re-spelled so
    it does NOT move). In particular no literal-seed F2 fixture moved: the `excludedAtTest` /
    `fcmpEqualityHoldsOnEdge` extractions are behaviour-preserving on the whole corpus.

### 8.3 Red-green
`z0re_probes/minilit.py` (runs each fixture's RUN lines verbatim with `%cq-opt` bound to a given
binary; boundary control: it was first measured FAILING 21/21 on the subject because of a relative
`%s` — fixed, then 21/21 PASS). The 21 new/changed fixtures: **subject 21 PASS; oracle 15 FAIL,
6 PASS.** The 6 that pass on the oracle are the pins of UNCHANGED behaviour and say so in their
headers: `…_reject_literal_base_offwire_fold`, `…_reject_state_prep` (literal base stays declined),
`…_runtime_seed_mismatch` (same string, now from clause 2), `control_tainted_diag` (loose tail), and
the two hand-IR SIDE-DOOR fixtures (the side door is pre-existing).

### 8.4 Mutation matrix (`z0re_probes/mutants.py`, `mutmatrix.sh`, `results/mutmatrix.txt`)
Each mutant is one edit applied exactly once (the script refuses a patch that matches 0 or ≥2
times), built as `cq-opt`, measured with `minilit.py` over the 21 fixtures.

| mutant | edit | verdict | fixtures that fail |
|---|---|---|---|
| subject | — | boundary control | 0 |
| M0_null | reorder two independent disjuncts in `isRuntimeStatePrepSeed` (binary `7839caad…` ≠ subject) | **0 moved** | 0 |
| M1 | F1 back to literal-only | KILLED | 12 |
| M2 | relational int half without `excludedAtTest` | KILLED | `…_runtime_seed_cond_operand` |
| M3 | relational fp half without `excludedAtTest` | KILLED | `…_runtime_seed_fcmp_cond_operand` |
| M4 | no record at the diamond emitter | KILLED | `…_runtime_seed_round2_quantum` |
| M5 | no record at the angle-select emitter | KILLED | `…_runtime_base_round2_quantum` |
| M6 | re-ask disabled | KILLED | both round-2 fixtures |
| M7 | S3 (+ emitter) admits a LITERAL base | KILLED | `…_literal_base_offwire_fold`, `…_reject_state_prep` |
| M8 | S7-rail/S8/S9 not skipped for an untainted base | KILLED | `control_angle_select_ry_runtime_base` |

8 of 8 killed, MISSED 0; plus the measured "first spelling" of the record (emission-time taint),
which accepted the round-2 hazard fixture (§5.4). Under M1 the hand-IR SIDE DOOR still passes and
its TWIN fails — the z0re asymmetry, reproduced by one mutant. (The matrix ran over the 21 fixtures
that existed then; the later C-derived `…_round2_quantum_from_c.ll` was red-greened against the
subject (PASS), M6 (FAIL) and the oracle (FAIL) by the same `minilit.py`.)

### 8.5 e2e goldens (read line by line)
`slice_z0re_runtime_seed_prep` (13 lines): the dead `q` is uncomputed (`ry −.5`, free — pre-existing
spine behaviour for a non-main dead source); `q2 = alloc(7), ry .3`; flag `q2 > 3`;
`alloc(6)` (the runtime `m + 1`), `ry_controlled(f, h3, .2)`; strip; free; measure `r`, `q2`.
`slice_z0re_angle_select_runtime_base` (10 lines): `alloc(6)`, `ry(h1, .2)`, flag `q > 3`,
`ry_controlled(h2, h1, fl(.7 − .2) = 0x1.fffffffffffffp-2)`, strip, free, measures; `+ t` stays a
classical add. `slice_z0re_runtime_seed_loop` (24 lines) = its unrolled twin byte for byte; three
fresh `alloc(7/8/9)` rails. `slice_z0re_runtime_seed_f64` (13): `cqrt_alloc_f64(0x1.cp+1)` (3.5 =
`m + 1.0`), `cqrt_ry_f64_controlled`. The `_spec` 2-TU goldens are byte-identical to their twins
(the three `compare_files` gates). All STRICT stage-2b clean. Generated by
`z0re_probes/mkgoldens.sh` with the subject snapshot.

### 8.6 Allocator sweeps (`z0re_probes/allocsweep.py`, `results/alloc_{lifo,nofree}.txt`)
Every `ir-pass/test/*.ll` (2425, incl. `…_round2_quantum_from_c.ll`) through plain `build/ir-pass/cq-opt`
(`51b5f78d…`) and through `build/ir-pass/cq-opt-debugalloc` (`8ef237e9…`, built from the same
objects at 12:43) with `CQ_OPT_DEBUG_ALLOC=lifo` and `=nofree`, comparing exit code, stdout
sha-256[:16] and the first `error:` line: **lifo 0 disagreements of 2425; nofree 0 disagreements
of 2425.**

### 8.7 About the session pause
The session was paused by an API limit between ~14:30 and 19:03. The three long measurements above
(A/B 13:51, lifo 14:16, nofree 14:27) had all FINISHED before it (each file carries its full
denominator and final line; the harness writes the counts only at the end), so they were kept, not
re-run. The subject binary was re-hashed after the pause (unchanged, and every modified source is
older than it), and the full lit was RE-RUN on the final tree (§8.1, `results/lit_final.txt`)
because `…_round2_quantum_from_c.ll` postdates the first full run.

## 9. Open questions for the owner / orchestrator
- **Q1 (drbq.13).** The literal Ry-stem angle-select base is kept declined on a measured
  counter-example (§4). Options (a)/(b)/(c) there.
- **Q2 (fp).** fp runtime seeds are admitted on the ruling's purpose (bd z0re's f64 member `zxdC`);
  pull with one conjunct if the owner meant integer only.
- **Q3 (Q4 asymmetry).** The hand-IR if/else two-prep (`if/else state prep allocates two rails`,
  owner ruling Q4) still declines, while its `-O1` image — the angle select on a RUNTIME base — now
  accepts and lowers the ONE-rail reading Q4 described. Not reachable from C (SimplifyCFG always
  folds it), so no C twin disagrees; recorded, not resolved.
- **Q4 (measured seed).** A `cq_measure` result is admitted as a seed (classical feed-forward; the
  unconditional spelling already lowers on the oracle). bd yiid (reading a name after measuring it)
  is untouched.

## 10. Filed / appended
- **NEW bd `test_C_libtooling-whd4`** (P3, over-decline, PRE-EXISTING — same `control flow` string on
  the oracle): a runtime `_Bool` seed `atoi(..) & 1` that `-O1` materialises TWICE (`trunc` in Pred,
  `and`+`icmp` sunk into the arm), so F1's identity and the arm's purity both fail (`src/e12.c`; the
  `!= 0` spelling `e12b` accepts).
- **NEW bd `test_C_libtooling-zt0b`** (P3, owner awareness, PRE-EXISTING — oracle exit 0): `src/p1.c`,
  the one relational fold `-O1` performs into a call operand, which produces an UNCONDITIONAL prep
  from an if/else whose one arm rotated the condition's operand in place (the α trade with no
  region).
- Appended: bd `z0re` (this implementation), bd `drbq.14` (Q2 implemented; the Q4 asymmetry; fp),
  bd `drbq.13` (NOT included — the a1 counter-example and options), bd `ix2v` (population grown:
  `cqrt_alloc_i8(253)` for a runtime `-3`, identical on the unconditional path on the oracle).

## 11. ATTACK FIRST (for the Rule-13 reviewers)

1. **Find an `-O1` rewrite that leaves a RUNTIME value in the arm slot AND the Pred slot of a prep
   diamond while a LIVE tainted register was what the source rotated.** §5.2's "no subject" argument
   rests on (i) the pass inventory and (ii) "an arm-local fold deletes the rotated rail". Attack
   (ii) with an arm-local expression whose rail is NOT deleted (a value also used after the merge
   that `-O1` sinks into the arm AND duplicates?), and attack (i) with `-O2`-only passes the
   regression matrix might exercise.
2. **The relational half is masked by `CondWire` and nowhere else.** Any change to `condProvenance`
   / `railWireClosure` (F2's own trigger) or a compound condition reaching a prep unmasks it —
   check that `isImpliedCondition`'s answer is then the right question (it does not see through
   `add`/`xor` relations; `(q ^ s) == 0` is InstCombine-canonicalised to `q == s` first — verify).
3. **L1 — other routes to a round-2-tainted seed.** The record is keyed on the classifier's verdict
   and re-asked on the source theta's arg-0. Look for a path where the source theta's arg-0 is
   REWRITTEN (not RAUW'd) between emission and the re-ask (`setArgOperand` on a hoisted prep theta —
   the M-β chaining only touches the SECOND gate; LoopLowering's collapse?), or where a prep region
   is emitted by an emitter other than `emitInPlaceRotationRegion` / `emitAngleSelectRegion`.
4. **The re-ask slot is post-`specialize()`.** Stages between round 2 and the slot run on a module
   carrying an unvetted chained "prep" (they only diagnose or mutate IR that is never printed if the
   re-ask fires) — check none of them CRASHES on it (a hoisted theta whose arg-0 is an `%out`
   handle while `ControlledRotations` says prep).
5. **S3's skip of S7-rail/S8/S9.** For a runtime base defined INSIDE a loop and the select outside
   (or vice versa), S7's anchor prong still runs; the rail prong is skipped. Build the shape where a
   runtime base is a loop-carried CLASSICAL φ and the angle select sits in the exit block.
6. **i1 / narrow widths.** `cqrt_alloc_i8(i8 %s)` carries no `signext` (bd ix2v): a negative runtime
   i8 seed traces as `253` (measured, `src/i8cC.c`; the unconditional spelling does the same on the
   oracle, `src/i8uC.c`). Trace-only runtime, so P3 — but the population grew.
7. **`cq_measure` seeds** — is classical feed-forward from a measurement into a controlled prep in
   scope for every backend the owner has in mind?
8. **The hand-IR side door vs twin** CHECK blocks are identical but the modules differ (a clone call
   vs an `add`). Measured (`z0re_probes/lltwin.sh`): both pairs link, run and trace BYTE-IDENTICAL
   at args `5 7` and `2 9` (11 / 10 lines), STRICT 2b clean on all four; the side door's lowered
   module is BYTE-IDENTICAL on the oracle and the subject (the side door path is untouched). The
   side door's 2b CENSUS reports `2 template rail mint(s) of which 1 left dirty` where the twin
   reports `1 … 0` — identical on the oracle, so pre-existing to the side door, not introduced;
   worth a look by whoever owns the clone pipeline's census.

## 12. Proposed CLAUDE.md text (for the orchestrator; not applied)

In §1's table, the state-prep row: "controlled **state prep** (`int r = SEED; if (COND) r =
cq_theta(SEED, θ)`) — SEED a literal **or a RUNTIME classical value (bd z0re, 2026-09-28), the same
SSA value as the Pred incoming**". In the Ry-stem angle-select row: "**CONSTANT arms only**; a
register base, or an untainted RUNTIME base on a fresh rail (bd z0re) — a LITERAL base still
declines (bd drbq.13, IPSCCP-fold counter-example)". In §2's F1/F2 bullet: "F1 admits a literal
or a runtime seed; F2 is re-asked for a runtime seed as a relational question (masked by
`CondWire`); a runtime seed that turns quantum after the round-2 fixpoint declines `state prep seed
became quantum` (record on `ControlRegion::RuntimeSeedAdmitted`, re-ask after `specialize()`)."
