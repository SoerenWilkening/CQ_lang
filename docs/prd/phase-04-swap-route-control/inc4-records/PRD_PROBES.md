# PRD agent — probes run for PRD §14 (Inc 4, controlled state prep, bd drbq.5)

Everything below was **compiled at `-O1` and run through the pass**. Sources in
`$S/prd/ir/<name>.c`; `-O1` IR in `<name>.s1.ll`; HEAD stderr in `<name>.head.diag`,
oracle stderr in `<name>.oracle.diag`; lowered IR `<name>.s2.ll`; traces `<name>.trace`.
Driver `$S/prd/run.sh`.

**Both binaries are the SAME FILE** — `md5 -q` of `build/ir-pass/cq-opt` and
`$S/wt/pre4/build/ir-pass/cq-opt` are both `8931bc461dc1db08e90288880f7d67be`
(measured). Every probe below was nonetheless run through BOTH; **0 disagreements
in 35 probes**. Where I write "declines" it means: `opt` exit 1 on both, identical
stderr.

These are IN ADDITION to the probe agent's 70 (`$S/probe/RESULTS.md`), and they
cover the three questions the brief assigned to me specifically.

## (a) The a8c0 STRAIGHT-THROUGH fold — is it real, and does F1 catch it?

| probe | source | `-O1` pred incoming / seed | result |
|---|---|---|---|
| `q01_st_ne0_prep0` | `int r = q; if (q != 0) r = cq_theta(0,.9);` | **`0`** (folded from `q`) / `0` | IR **BYTE-IDENTICAL** to `q04` |
| `q04_genuine_ne0_prep0` | `int r = 0; if (q != 0) r = cq_theta(0,.9);` | `0` / `0` | the genuine prep |
| `q02_st_ne5_prep5` | `int r = q; if (q != 5) r = cq_theta(5,.9);` | **`5`** / `5` | IR **BYTE-IDENTICAL** to `q05` |
| `q05_genuine_ne5_prep5` | `int r = 5; if (q != 5) r = cq_theta(5,.9);` | `5` / `5` | the genuine prep |
| `q03_st_ne5_prep0` | `int r = q; if (q != 5) r = cq_theta(0,.9);` | **`5`** / `0` | seed ≠ incoming ⇒ **F1 declines** |
| `q17_gt_alias_st` | `int r = q; if (q > 5) r = cq_theta(0,.9);` | **`%1`** (NOT folded) / `0` | non-constant incoming ⇒ **F1 declines** |
| `q18_gt_prep` | `int r = 0; if (q > 5) r = cq_theta(0,.9);` | `0` / `0` | clean Inc-4 accept |

`diff` on the `@slice` bodies: `q01 == q04` and `q02 == q05`, character for
character. **Confirms fold B (the probe agent's) independently and adds the
`q03` case: when the fold's constant is `k` and the seed is not `k`, F1 alone
declines.** The general statement this establishes: *whenever the straight-through
edge is the equality-proving edge, the folded pred incoming IS `k`, so F1's
"incoming == seed" forces seed == k, which is exactly what F2 refuses.* F2 is
therefore the ONLY thing standing between Inc 4 and `q01`/`q02`, and F1 is what
makes the coverage complete.

## (b) IPSCCP runs before InstCombine — is an F2 keyed on the IR compare complete?

The worry: an ordered compare that *proves* equality on one edge might fold the
operand while leaving the compare un-canonicalized, so an F2 reading `icmp eq/ne`
would miss it. **Measured on four spellings: it does not happen — canonicalization
to `icmp eq` is what the pass sees in every case.**

| probe | source condition | compare in the `-O1` IR | arm seed |
|---|---|---|---|
| `q06_ult1` | `unsigned u = q; if (u < 1u)` | `icmp eq i32 %1, 0` | folded to `0` |
| `q07_ule0` | `if (u <= 0u)` | `icmp eq i32 %1, 0` | folded to `0` |
| `q08_sle_intmin` | `if (q <= INT_MIN)` | `icmp eq i32 %1, -2147483648` | folded to `-2147483648` |
| `q09_sge_intmax` | `if (q >= INT_MAX)` | `icmp eq i32 %1, 2147483647` | folded to `2147483647` |

All four are then F2-ambiguous (seed == k) and F2 declines all four.
**Limit, stated as a limit:** this is four measured spellings, not a proof.
The residual risk is a fold with a NON-equality compare surviving to the pass;
none was produced in 105 probes across the two agents.

**Compound conditions — the one place the fold happens and F2's compare test
would not see it.** Measured:

| probe | source | condition in IR | arm seed |
|---|---|---|---|
| `q10_compound_eq_and` | `if (q == 5 && p > 2) r = cq_theta(q,.9);` | `select i1 %3, i1 %4, i1 false` | **folded to `5`** |
| `q11_compound_prep` | same, `cq_theta(5,.9)` | same | `5` |
| `q12_compound_phase` | `if (q == 5 && p > 2) q = cq_phi(q,.9);` | same | — |
| `q13_simple_phase` | `if (q == 5) q = cq_phi(q,.9);` | `icmp eq` | — |
| `q14_compound_ry` | compound cond, chained Ry arm | same | — |
| `q15_simple_ry` | simple cond, chained Ry arm | `icmp eq` | — |

`q13` and `q15` **ACCEPT** (exit 0, linked, ran, strict 2b clean). `q12` and `q14`
**DECLINE** `cq controlled lowering: control flow under quantum control`.
READ (`ArmClassify.cpp:1383-1387`): `if (!isa<CmpInst>(Region.Condition))` declines
outright. **So a compound condition reaches NO control accept path today and F2
does not need to walk `and`/`or` leaves — but the FOLD fires under a compound
condition, so the day compound conditions are admitted F2 becomes incomplete.**
Written up in §14 as a retirement trigger.

> ⚠ **DOC-FALSE found on the way:** PRD §3 says the flag mint handles
> "compound `&&`/`||` conditions via the 3c6m.12 flag network, unchanged".
> Measured `q12`: a compound-condition PHASE arm **declines** on both binaries.
> Whatever the 3c6m.12 flag network serves, it is not this path.

## (c) The DERIVED-TEMP fold residual — and eight attempts to break it

The claim under test: `cq_theta(q-k+c, θ)` folded under `q == k` is FAITHFUL,
because on the proven edge the folded temp's basis IS the constant and the temp
has no reader outside the arm.

**The load-bearing half is MEASURED: when the derived temp has another reader, the
fold does not happen at all.**

| probe | source | result |
|---|---|---|
| `q20_outside_temp_k5` | `int t = q - 5; if (q == 5) r = cq_theta(t,.9);` | arm folds to `cq_theta(i32 0,.9)`; **the `sub` is GONE** |
| `q22_temp_outside_reader` | same **+ `cq_measure(t)`** | `%2 = add nsw i32 %1, -5` **SURVIVES**; the arm reads `%2`, NOT a constant |
| `q23_temp_second_region` | same **+ a second region conditioned on `t`** | `sub` survives; arm reads `%3` |
| `q26_arm_temp_and_q` | the temp defined INSIDE the arm | folds; IR ≡ `p01` byte-for-byte |

So `-O1` at this level does **not** do a per-use PredicateInfo rename here: it
either folds the value everywhere (and DCEs the definition) or not at all. The
"no other reader" premise is therefore **enforced by the fold**, on the measured
shapes. Two probes that keep the definition alive both keep the arm's arg-0
non-constant, which lands on R1/R4 and declines.

**Break attempts, all measured:**

| probe | shape | outcome |
|---|---|---|
| `q19_outside_temp` | `int t = q + 3; if (q == 0) r = cq_theta(t,.9);` | **FOLDS to `cq_theta(i32 3,.9)` and deletes the `add`.** The fold is NOT restricted to values defined inside the arm, and NOT to the compare's own operands. Seed `3` ≠ incoming `0` ⇒ F1 declines |
| `q24_temp_loopphi` | `int t=0; for(i<2) t=q+i; if (q==0) r=cq_theta(t,.9);` | loop unrolls, `t = q+1`, folds to **`cq_theta(i32 1,.9)`**. Seed `1`, k `0`, incoming `0` ⇒ F1 declines. **But with `int r = 1;` it would pass BOTH fences** — the folded seed need not equal `k` |
| `q25_temp_select` | `int t = cc ? q : 0; if (q == 0) r = cq_theta(t,.9);` | the `select` is **SUNK INTO the arm** and NOT folded; arm has a stray op ⇒ R1 declines |
| `q27_cast_launder` | `cq_theta((int)(signed char)q, .9)` under `q == 0` | folds to `cq_theta(i32 0,.9)`; seed `0` == k `0` ⇒ **F2 declines** |
| `q28_mul_zero` | `cq_theta(q * 0, .9)` under `q == 5` | folds **unconditionally** to `0`; seed `0` ≠ k `5` ⇒ **ACCEPT**, and it is exactly faithful (`q*0` is `|0⟩` for every `q`, unentangled) |
| `q29_sub_self` | `cq_theta(q - q, .9)` under `q > 5` | folds unconditionally to `0` ⇒ **ACCEPT**, faithful |
| `q30_xor_self_gt` | `cq_theta(q ^ q, .9)` under `q > 5` | ditto ⇒ **ACCEPT**, faithful |
| `q21_temp_two_readers` | temp read by `printf` inside the arm | declines `cq I/O output sink: conditional output is not a lowerable single-sink if(q) diamond` |

**Verdict: the argument survives, and it is NOT the argument F2 rests on.** See
§14.2c — F2 is a fence on the one sub-family where the folded constant is
indistinguishable from the CONDITION REGISTER ITSELF (`f = identity`, so
`f(k) == k`); the derived-temp accepts are the sub-family where the folded value
is provably a different physical wire from `q`. `q24` shows the residual is wider
than "seed == 0": the folded seed is `f(k)` for whatever `f` the source wrote.

## (d) The seed literal is MODULE-UNIQUED — the R4/R6 hazard

| probe | source | measurement |
|---|---|---|
| `q31_seed_const_shared` | `int r=0; if(q==5) r=cq_theta(0,.9); int u=cq_theta(0,.7); …` | inside `@slice`, `ConstantInt i32 0` has **THREE users**: the arm theta (= `T`), the merge φ, **and `%7 = cq_theta(i32 0, 0.7)` AFTER the region** |

If an implementer relaxes `inPlaceRotationArmTheta`'s taint gate and leaves R4/R6
pointed at `RotBase`, `railWireClosure(ConstantInt 0, BothWays, …)` inserts the
constant into `BaseWire`/`BaseWireOrder` **before** its taint gate
(`ArmClassify.cpp:457-462`, read), and R6 then enumerates `%7` as a "user of a
rail member", fails `provablyBefore(%7, BI)`, and declines
`stale rail record read past a controlled Ry` on a program with no record at all.
Foreign-function users of the same literal (`ret i32 0` in `@main`) are skipped
only because `DT->isReachableFromEntry` returns false for a block not in the
tree — i.e. by accident of an unrelated guard. §14.5 specifies the fix.

## (e) The CHAINED TWIN — the Inc-4 witness, measured

| probe | source | result |
|---|---|---|
| `t01_twin_seed0` | `int r = cq_theta(0, 0.0); if (q == 5) r = cq_theta(r, 0.9);` | **ACCEPT**, links, runs, 10-line trace, strict 2b `4 rail mints / 4 left allocated / 2 free sites: 2 verified, 0 violations, 0 unproven` |
| `t02_twin_seed7` | seed 7 | ACCEPT, trace differs only in `cqrt_alloc_i32(7)` |
| `t03_twin_ne` | `!=` polarity | ACCEPT, 12 lines, `cqrt_x(h2)` brackets |
| `t04_twin_f64` | `double` | ACCEPT, `cqrt_alloc_f64(0x0p+0)` / `cqrt_ry_f64_controlled` |

Traces reproduced verbatim in §14.8. These agree line-for-line with the probe
agent's p09a–d, independently produced.

## (f) `-0.0` and the `int r;` (undef) spelling — cross-checks of the probe agent

Re-read from `$S/probe/*.s1.ll` rather than re-run: `p07b` has
`phi double [ %4, %3 ], [ -0.000000e+00, %0 ]` against a seed of `0.000000e+00`,
and `p07c` is the mirror — **both reachable from ordinary C**, in both directions.
`p11` (`int r;` uninitialized) has **no branch at all**: `-O1` emits
`tail call void @llvm.assume(i1 %2)` and the `cq_theta` is unconditional.
Confirmed by reading the committed IR.

## (g) `fcmp oeq` — the hole I expected F2 to have, MEASURED CLOSED

| probe | source | arm's arg-0 in the `-O1` IR |
|---|---|---|
| `q32_fcmp_oeq_fold` | `double q…; double r=0.0; if (q == 0.0) r = cq_theta(q,.9);` | **`double %1` — NOT folded** |
| `q33_fcmp_oeq_prep` | same with `cq_theta(0.0,.9)` | `double 0.000000e+00` |
| `q34_fcmp_oeq_five` | `double r=5.0; if (q == 5.0) r = cq_theta(q,.9);` | **`double %1` — NOT folded**, incoming `5.0` |

`diff` q32 vs q33 differs on exactly that one line, so the fp shapes are NOT
byte-identical the way the integer ones are. LLVM's `propagateEquality` will not
substitute across `fcmp oeq` because `oeq` is not a bitwise-equality proof
(`+0.0 == -0.0`). q32 and q34 decline today on **R4** — printed as
`condition predates a non-diagonal gate` (masked), unmasked with `cq_phi`.
**Consequence: F2 keyed on `ConstantInt` is complete for the fp family, by an
LLVM invariant rather than by luck.** Recorded in §14.2b with a retirement
trigger and in the decline table as row FP-1.

## (h) Late correction — two instruments already exist in the working tree

While §14 was being written the probe/matrix agent added, to the same working
tree: `tools/inplace_twin_matrix.py --stateprep` (a **297-cell `sp_*` pool** with
its own `--prep-oracle`, `reduce_prep` and `classify_prep`) and
`tools/loop_twin_matrix.py`'s cell `m_ry_rprep_none_none_none`
(`DECLINE-BOTH-DIFFERENT`, expected 258 → **259**, assert `(120, 36, 118)`).
Measured by re-reading the working tree and by
`python3 -c "import inplace_twin_matrix as m; len(m.prep_cells())"` → 297.
§14.7, §14.9 and §14.12 worry 4 were CORRECTED in place; the original text said
to build an instrument that already existed. **I did not RUN either** — both need
a lowering that does not exist yet.
