# 3qlq Increment 1 — PRE-IMPLEMENTATION dispositions of the e2e `.c` slices

> **Rule 16 record.** This file is the measurement the Increment-1 diff is read
> against. Every number and every diagnostic string below is MEASURED, with the
> command that measured it; nothing here is estimated. Written by agent `prep_b`
> on 2026-09-05, **before any pass change exists**, on branch `3qlq-inc1-slices`.
> The lowering it describes is DESIGNED, NOT IMPLEMENTED.

## 0. What was measured, and with what

| | |
|---|---|
| stage 1 | `/usr/local/opt/llvm@19/bin/clang` 19.1.7, `-I<scratch include> -include CQ.h -O1 -emit-llvm -S` |
| the header | a scratch copy of `include/CQ.h` with the 15-width `cq_phi_<sfx>(x, θ)` family, its `f80` conditional declaration, the `CQ_PHI_LDBL_` macro and the whole `_Generic` dispatch replaced by ONE extern `void cq_phi(double angle);` (PRD §4.1). **`include/CQ.h` in the tree is UNCHANGED** — the Increment-1 implementer owns that file. |
| stage 2 (**the ORACLE**) | `$SP/wt/pre-3qlq/build/ir-pass/cq-opt -load-pass-plugin $SP/wt/pre-3qlq/build/ir-pass/libCQPass.so -passes=cq-lowering`, i.e. the **pre-3qlq** pass at commit `52d7764` |
| stage 2b | `tools/free_pairing_check.py -q` (STRICT — no `--allow-unproven`) |
| stage 3 | `clang <s2.ll> <oracle>/runtime/libcq_templates.a <oracle>/runtime/libcq_runtime.a` (the runtime is identical for every binary in this epic — owner decision D3 adds no symbol) |
| sweep script | `$SP/progress/tools/sweep.sh`, raw TSV `$SP/progress/pre_dispositions.tsv` |

Three rows were **corrected by hand** after the sweep: `onward_ctl_phase_caller`,
`spec_select_caller` and `spec_twoarm_caller` are **multi-TU** slices
(`run_slice_multi.sh`), and the sweep compiled only the CQ TU, so their first
reading of `cq taint escape: tainted value consumed by an unknown callee` was a
**harness artifact** — the callee was merely an undefined declaration. Re-measured
with `llvm-link` of both TUs, exactly as `run_slice_multi.sh` does.

## 1. Headline counts (measured)

| | count | command |
|---|---|---|
| `.c` slices mentioning `cq_phi` at HEAD `dfb8e83` | **66** | `grep -l 'cq_phi' tests/e2e/*.c \| wc -l` |
| of those, mentioning it ONLY in prose (untouched) | **3** | `slice_control_value_diamond.c`, `slice_libm_real_lgammaf.c`, `spec_fp_select_fcmp_caller.c` |
| **migrated** to the register-free surface | **63** | |
| `cq_phi` **CODE** call sites in those 63 files, before | **111** | comment-stripped scan of `git show dfb8e83:<file>` |
| `cq_phi(...)` occurrences the two rewriters changed | **161** | 107 in-place + 30 `if (c) x = cq_phi(x,θ)` + 18 `(void)` keep-alive + 6 rename. The 50 above 111 are SOURCE-INTENT pseudo-code lines in the headers, which mirror the code; both were rewritten, prose was not |
| `cq_phi` CODE call sites across all 74 slices, after | **132** | = 111 migrated + 21 in the 11 new slices |
| 2-arg `cq_phi(` occurrences left in the tree | **8**, all backtick-quoted PROSE about the OLD lowering | `grep -nE 'cq_phi *\([^)]*,' tests/e2e/*.c` |
| **new** §6.5 slices | **11** | |
| new ctest entries | **14** (11 slices + 3 `cmp` twin gates), ALL `DISABLED TRUE` | `ctest -N` in a clean configure: 341 total = 327 pre-existing + 14 |
| slices measured against the oracle | **74** | 63 migrated + 11 new |
| of those, the oracle **DECLINES** (exit 1) | **52** | |
| of those, the oracle **ACCEPTS** (exit 0) | **22** | |

**Every one of the 22 accepts then fails STAGE 3 with `Undefined symbols: _cq_phi`.**
The oracle does not recognise `void @cq_phi(double)` — the name carries no
`_<sfx>` suffix, so it is an ordinary unknown external — leaves the call in the
lowered IR, and the oracle runtime has no such symbol. That is the correct
pre-increment disposition of an accepting slice, not a defect in the migration.

## 2. The three causal probes

These are the measurements that turn "the golden will lose a line" into a
statement about what the slice still proves. Each is a MEASURED counterfactual,
not an argument.

### PROBE 1 — the keep-alive is gone, and it takes the lineage with it (15 slices)

`(void) cq_phi(<dead>, θ)` was a **keep-alive**. `cq_phi` is a side-effecting
extern that **reads its operand**, and that read is the only reason `clang -O1`
DCE could not drop the dead arithmetic those slices exist to exercise. A
register-free `cq_phi(θ)` reads **nothing**.

Measured on `slice_intrinsic_bswap` — whose header says lineage (B) exists to
prove `cq_template_bswap_i32_unc` resolves at the LINK layer — the ORACLE emits:

```
%h1 = call i32 @cqrt_alloc_i32(i32 %0)
call void @cqrt_ry_i32(i32 %h1, double 1.000000e-01)
call void @cqrt_ry_i32(i32 %h1, double -1.000000e-01)
call void @cqrt_free(i32 %h1)
```

Zero `cq_template_bswap_i32`, zero `_unc`. The `llvm.bswap.i32` is absent from
**stage-1** IR — the loss happens before the pass runs. The loss is not one trace
line; it is the whole chain and the symbol the slice was written to link.

### PROBE 2 — the in-place-Ry loop family loses its loop-VARIANT condition (8 slices)

Those eight slices carry `q = cq_phi(q, 0.1)` in the loop body, and
`slice_control_inplace_ry_loop.c`'s own header says why: *"WHY THE `cq_phi` ON `q`
IS NOT DECORATION (PRD §13.1)"* — it keeps the **condition** register loop-variant.
Measured, on the migrated source vs a one-line counterfactual:

| source | where `clang -O1` puts the compare | oracle |
|---|---|---|
| migrated `cq_phi(0.1)` | `%3 = icmp eq i32 %1, 5` in the **ENTRY block** (LICM hoisted it) | **DECLINES** `cq controlled lowering: condition predates a non-diagonal gate under quantum control` |
| counterfactual `q = cq_theta(q, 0.1)` | `%11 = icmp eq i32 %10, 5` in the **LOOP HEADER**, reading the header φ | **ACCEPTS**, exit 0, two `cqrt_ry_i32_controlled` |

The hoist is a **stage-1** event. No Increment-1 lowering can undo it; the only
repair is a different variant-maker, which is a semantic change to eight slices
and four `cmp` twin gates, not a migration.

### PROBE 3 — `slice_select_rail_alias_cond`'s mechanism cannot be spelled at all

Its header states the mechanism: *"`%q` and `%r = cq_phi(%q,·)` are SSA-DISTINCT …
therefore not foldable by InstCombine — unlike `x==x`"*. The faithful rewrite of a
rename through the gate is `int r = q; cq_phi(0.25);`, which makes `r` **be** `q`.
Measured stage-1 IR of the migrated slice:

```
%4  = tail call i32 @cq_measure_si32(i32 noundef 22)          ; case A: q<r folded FALSE
%6  = tail call double @cq_measure_f64(double noundef 2.0)    ; case B: qf<rf folded FALSE
%11 = tail call i32 @cq_measure_si32(i32 noundef 11)          ; case D: qe==re folded TRUE
%13 = fcmp ord double %12, 0.0                                ; case E SURVIVES
```

Three of five cases are constants before the pass runs; the oracle then declines
`cq_measure_<sfx> operand not recognized; expected a tainted i32 handle`. The
alias the slice exists to exercise **cannot be written with a register-free
`cq_phi`**, because there is no gate to rename through.

## 3. Two measured shape findings that are not about any one slice

**(a) PRD §6.2 P5 loses its only plain-C customer.**
`slice_control_switch_phase.c` is `switch (q) { case 0: cq_phi(.1); case 1:
cq_phi(.2); case 2: cq_phi(.3); }`. Once the arms differ **only in a `double`
constant**, `clang -O1` converts the switch to a **lookup table**:

```
@switch.table.main = private unnamed_addr constant [3 x double] [double 0.1, double 0.2, double 0.3]
  %2 = icmp ult i32 %1, 3
  br i1 %2, label %3, label %7
3: %5 = getelementptr inbounds [3 x double], ptr @switch.table.main, i64 0, i64 %4
   %6 = load double, ptr %5
   tail call void @cq_phi(double %6)
```

There is no `switch` left to lower. The oracle declines it with the **QRAM**
diagnostic (`const-global table read under tainted control: index not provably
in-bounds`). This is structural, not incidental: the register-free surface makes
every homogeneous-phase switch arm identical except for a constant, which is
exactly the shape SimplifyCFG tables. P5 needs either hand-written IR or a slice
whose arms differ structurally.

**(b) An angle select can arrive as a merge φ, which §6.1 does not list.**
`slice_control_phase_ifelse_derived.c` measures as:

```
  tail call void @cq_phi(double 9.000000e-01)          ; uncontrolled -> D2 delete
  %2 = icmp sgt i32 %1, 5 ; br i1 %2, label %3, label %4
3: tail call void @cq_phi(double 2.500000e-01)
4: %5 = phi double [ 1.250000e-01, %3 ], [ 7.500000e-01, %0 ]
   tail call void @cq_phi(double %5)
```

— a P1 arm followed by an angle select spelled as a **`phi double`**, not a
`select`. §6.1's measured table has only the `select` spelling; `SelectClassify`
is reached from a `select`, so a φ-spelled angle select is a shape the accept/decline
partition has not been asked about.

## 4. Per-slice table

`pre-increment result` is the ORACLE's verdict, verbatim. `expected post-increment
class` is ANALYTIC (PRD §6.2 P1–P7 / §6.3), not measured — nothing implements
Increment 1 yet.

| file (`tests/e2e/`) | | pre-increment result (MEASURED) | expected post-increment class (ANALYTIC) | note |
|---|---|---|---|---|
| `onward_ctl_phase_caller` | migrated | MULTI-TU (classical_call_under_control_lib.c): cq controlled lowering: control flow under quantum control | P1 | the ONWARD region's arm is now ONE void call; the phase lands on the R2 flag, not on %out |
| `slice_bitint` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_classical_if_gate` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 ×2 | ⚠ both gates deleted; the slice's FIRES / does-NOT-fire contrast has nothing left to contrast |
| `slice_classical_switch_gate` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 ×7 | ⚠ all seven deleted; the golden loses every rz line |
| `slice_compare_qq` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_control_angle_select_rz` | migrated | DECLINES exit 1 — `cq taint escape: tainted value consumed by an unknown callee` | P2 | §3 retires the 2b by-difference form + the 2^-40 fence for this stem |
| `slice_control_angle_select_rz_twin` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P1 + P7 | the unconditional cq_phi(0.3) is a deleted global phase; the twin RELATION survives (see header) |
| `slice_control_cond_datause` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | §6.3 DECLINE | ⚠ arm holds N=2 cq_phi calls. Was an ACCEPT at HEAD |
| `slice_control_cond_onward_phase` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 | ⚠ UNCONTROLLED -> deleted. The dugh re-propagation this slice exists for has NO customer left |
| `slice_control_grover_2iter` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×4 |  |
| `slice_control_grover_derived_oracle` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×2 | derived condition |
| `slice_control_grover_derived_oracle_2iter` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×4 |  |
| `slice_control_grover_derived_oracle_offset` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×2 |  |
| `slice_control_grover_loop` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P6 ×2 |  |
| `slice_control_grover_loop_derived` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P6 ×2 |  |
| `slice_control_grover_loop_derived_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×4 |  |
| `slice_control_grover_loop_dynamic` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P6 ×2 | run-time classical bound |
| `slice_control_grover_loop_leading_gate` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P6 |  |
| `slice_control_grover_loop_leading_gate_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×2 |  |
| `slice_control_grover_loop_offset` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P6 |  |
| `slice_control_grover_loop_offset_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×2 |  |
| `slice_control_grover_loop_range_oracle` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P6 / P3 | compound `a>5 && a<20` condition inside a loop |
| `slice_control_grover_loop_range_oracle_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P3 ×2 |  |
| `slice_control_grover_loop_two_regs` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P6 ×2 | two independent registers |
| `slice_control_grover_loop_two_regs_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×4 |  |
| `slice_control_grover_loop_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×4 |  |
| `slice_control_inplace_ry_loop` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_inplace_ry_loop_grover` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow inside a loop body under quantum control` | P6 (phase) + drbq Inc-3 (Ry arm) |  |
| `slice_control_inplace_ry_loop_grover_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P1 ×2 + drbq Inc-1 (Ry arms) |  |
| `slice_control_inplace_ry_loop_leading_gate` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_inplace_ry_loop_leading_gate_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_inplace_ry_loop_leak` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_inplace_ry_loop_leak_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_inplace_ry_loop_two_regs` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_inplace_ry_loop_two_regs_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_inplace_ry_loop_unrolled` | migrated | DECLINES exit 1 — `cq controlled lowering: condition predates a non-diagonal gate under quantum control` | DECLINE `condition predates a non-diagonal gate` | ⚠⚠ CAUSAL PROBE 1: the Rz kept the condition register loop-VARIANT. It is gone, LICM hoists the compare AT STAGE 1, and no Inc-1 lowering can undo a stage-1 hoist |
| `slice_control_nested_phase` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P4 | MEASURED: stays a genuine homogeneous depth-2 phase nest |
| `slice_control_phase_andcond` | NEW | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P3 | byte-identical `@slice` body to the nest. NEW |
| `slice_control_phase_angle_select` | NEW | DECLINES exit 1 — `cq taint escape: tainted value consumed by an unknown callee` | P2 | constant arms. NEW |
| `slice_control_phase_angle_select_runtime_arms` | NEW | DECLINES exit 1 — `cq taint escape: tainted value consumed by an unknown callee` | P2, run-time arms | ⚠ rests on §12 Q3 ASSUMED 'admitted for Rz'. NEW |
| `slice_control_phase_diamond` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | §6.3 DECLINE | ⚠ arm holds N=2 cq_phi calls. Was an ACCEPT at HEAD |
| `slice_control_phase_grover` | NEW | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×4 | flat diamonds, one cq_phi each. NEW |
| `slice_control_phase_grover_loop` | NEW | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P6 | rolled; twin of the unrolled. NEW |
| `slice_control_phase_grover_loop_unrolled` | NEW | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×6 | NEW |
| `slice_control_phase_ifelse_derived` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | §6.3 DECLINE + a NEW shape | ⚠ arm holds N=2; and -O1 leaves `%5 = phi double [0.125],[0.75]` feeding one cq_phi — an angle select spelled as a MERGE PHI, which §6.1 does not list |
| `slice_control_phase_ifne` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P1 | the ¬flag `cqrt_x` bracket |
| `slice_control_phase_nest` | NEW | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P3 | folds to `select i1 %a,%b,false`. NEW |
| `slice_control_phase_nest_deep` | NEW | DECLINES exit 1 — `cq controlled lowering: impure phase arm under quantum control` | P4 **or** §6.3 mixed-arm DECLINE | ⚠ FLAGGED: outer arm carries an Ry on a 3rd register. NEW |
| `slice_control_phase_perbit_loop` | NEW | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P6 | D4's idiom, K=4; twin of the unrolled. NEW |
| `slice_control_phase_perbit_loop_k32` | NEW | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P6 | K=32; the K-independence witness. NEW |
| `slice_control_phase_perbit_loop_unrolled` | NEW | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×4 | NEW |
| `slice_control_seq_grover` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×2 | the flagship: `if (q==5) cq_phi(PI)` + `if (q==0) cq_phi(PI)`, the two regions PRD §1 quotes |
| `slice_control_seq_regions` | migrated | DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control` | P1 ×2 | the hcrg sequential pair |
| `slice_control_switch_eqfold` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | §6.3 DECLINE | ⚠ arm holds N=2 cq_phi calls. Was an ACCEPT at HEAD |
| `slice_control_switch_phase` | migrated | DECLINES exit 1 — `cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)` | NONE — P5 loses its only plain-C customer | ⚠⚠ MEASURED: -O1 turns the three arms into a `[3 x double] @switch.table.main` lookup + range check + ONE cq_phi(load). There is no switch left to lower |
| `slice_ctlz_idiom_loop` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_f16` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_f80` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_fp80_union_unc` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_funnel_fshl_qq` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_intrinsic_bswap` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_intrinsic_ctlz` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_intrinsic_ctpop` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_intrinsic_fma` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_intrinsic_fpmath` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_loop_break_qq_phase` | migrated | ACCEPTS (exit 0); 2b FAIL; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 | ⚠ RENAME site: p == p0 now, so this slice and slice_loop_break_qq.c are the same program |
| `slice_loop_iter_local` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_loop_phase_accum` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 | ⚠ the ENTIRE loop body was one uncontrolled Rz; deleted, the body is empty |
| `slice_select_rail_alias_cond` | migrated | DECLINES exit 1 — `error: <unknown>:0:0: in function slice void (i32, double): cq_measure_<sfx> operand not recognized; expected a tainted i32 handle` | DECLINE `cq_measure_<sfx> operand not recognized` | ⚠⚠ CAUSAL PROBE 3: 4 RENAME sites; 3 of the 5 cases fold to constants at stage 1 |
| `slice_uncompute_dead_dag` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_uncompute_dead_shapes` | migrated | ACCEPTS (exit 0); 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 + PURPOSE LOST | ⚠⚠ CAUSAL PROBE 2: the keep-alive is gone, so the dead lineage the slice exists to exercise is DCE'd at stage 1 with its `_unc` |
| `slice_uncompute_interior_region_derived_cond` | migrated | DECLINES exit 1 — `cq controlled lowering: control flow under quantum control` | P1 | derived (`sqrt`) condition |
| `spec_select_caller` | migrated | MULTI-TU (spec_select_lib.c): ACCEPTS, exit 0; 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 | the onward phase line leaves the golden; the specialisation is unaffected |
| `spec_twoarm_caller` | migrated | MULTI-TU (spec_twoarm_lib.c): ACCEPTS, exit 0; 2b PASS; stage 3 LINK-FAIL `Undefined symbols: _cq_phi` | P7 | same |
## 5. OWNER QUESTIONS

These are consequences of decisions D1/D2 that the PRD does not cost, and they are
not `prep_b`'s to decide (BRIEF_common: *"If an implementation or review finding
CONTRADICTS a §2 decision or a §12 assumption, STOP that thread, write it under
`## OWNER QUESTION`"*). None of them contradicts D1 or D2; each is a **coverage**
consequence of them, and each has a measured reproducer above.

### OQ-1 — the keep-alive has no replacement, and 15 slices depend on it

**The question.** With `cq_phi` register-free, CQ.h offers no primitive that
*reads* a quantum value without also being a sink. What should the 15 keep-alive
slices use, and who writes it?

**Why nothing in the tree is a drop-in** (each checked, not assumed):
* `cq_measure(x)` — the **sole sink**. It makes the chain a measured one, so the
  whole-DAG spine hits `uncompute: dead chain would free a measured register`,
  which PRD §1 already records as the reason the correct kickback spelling
  declines at HEAD. It also inserts a measurement the slice's author did not
  intend, which is the shape Rule 5 exists to keep the *compiler* from doing.
* an ordinary extern `void sink(unsigned)` — a tainted value into an unknown
  callee is `declineTaintEscapes`, measured on this very sweep (it is what the
  multi-TU artifact in §0 was).
* a `volatile` non-escaping local — deleted by
  `eraseDeadVolatileScalarStores` under the 2026-08-10 fenv ruling, which exists
  precisely to delete this.
* `q = cq_theta(q, θ)` — reads its operand, but it is a **non-diagonal** gate and
  the sole taint SOURCE; substituting it changes the physics of every one of the
  15 (it is a rail-relabelling gate for `staleRailRecordRead`, `WireWalk` and
  `declineStaleRecordOps`, where an Rz was exempt).

**What is at stake if nothing is done.** The 15 slices still compile and still
have goldens; they simply stop proving what their headers say they prove. That is
the `165/174` / bd `3c6m.63` failure mode exactly — *a test measuring a program
that ships nowhere* — and it is invisible to a green suite, because the goldens
are regenerated from whatever the pipeline now emits. The symbols at risk are the
`_unc` twins of the curated-intrinsic family and the dead-DAG shapes:
`cq_template_bswap_i32_unc`, `…_ctlz_…`, `…_ctpop_…`, `…_fma_…`, `…_minnum_…`,
`…_fshl_…`, the f16/f80 `fadd` twins, the `i40` and-mask twin, the fp80-union
path, and the whole-DAG LIFO shapes in `slice_uncompute_dead_{dag,shapes}.c`.

**Options, none chosen here.** (i) accept the loss and delete the (B) lineages,
recording the coverage drop; (ii) keep a **register-taking** `cq_phi`-like extern
in `CQ.h` **for tests only**, which contradicts D3's "the two frontend concepts
would be redundant" if it is a runtime symbol but not if it lowers to the existing
`cqrt_rz_<W>` — an ABI question; (iii) give the 15 slices a real consumer instead
of a keep-alive (measure the terminal, which changes each slice's uncompute shape
and its golden). All three are visible design decisions.

### OQ-2 — eight in-place-Ry loop slices and four `cmp` twin gates lose their shape

Probe 2. `cq_phi` was the loop-variant maker for the **condition** register in
`slice_control_inplace_ry_loop{,_unrolled,_leading_gate,_leading_gate_unrolled,
_two_regs,_two_regs_unrolled,_leak,_leak_unrolled}.c`. Migrated, all eight decline
`condition predates a non-diagonal gate`; the counterfactual with `cq_theta`
accepts. The four `e2e-cmp-…` twin gates over those goldens go with them.

**The question.** Is the drbq Inc-1/Inc-3 controlled-in-place **Ry** family
re-based on `cq_theta` as its variant-maker (a source edit to eight slices, and
their goldens regenerate to a different — Ry-bearing — stream), or does that
family lose its in-loop e2e coverage? Note the capability itself is untouched:
this is about whether any committed program still exercises it.

### OQ-3 — PRD §6.2 P5 (homogeneous-phase switch) has no plain-C customer

Finding 3(a). Measured: `-O1` tables the arms. Either P5 gets a hand-written lit
fixture and no e2e slice (which is a real gap — e2e is the only layer that LINKS,
Rule 2), or the slice is rewritten so the arms differ structurally rather than
only in a constant, or P5 is scoped out of Increment 1.

### OQ-4 — `slice_select_rail_alias_cond` and `slice_loop_break_qq_phase` are unspellable

Probe 3, and the rename in `slice_loop_break_qq_phase.c`. Both slices exist to
exercise a property of a **renaming** in-place gate (`%q` vs `%r = cq_phi(%q,·)`;
"a comparand carrying a relative phase"). A register-free `cq_phi` renames nothing,
so neither property can be written in CQ any more. `slice_loop_break_qq_phase.c`
becomes byte-for-byte the same program as `slice_loop_break_qq.c`; three of
`slice_select_rail_alias_cond`'s five cases fold to constants and the slice
declines. Delete, re-base on `cq_theta`, or accept two duplicated slices.

### OQ-5 — four shipped ACCEPT slices become §6.3 DECLINES on the "N>1 cq_phi per arm" row

`slice_control_phase_diamond`, `slice_control_cond_datause`,
`slice_control_switch_eqfold` and `slice_control_phase_ifelse_derived` all carry
two `cq_phi` calls in one arm and are ACCEPTS at HEAD. §6.3's first decline row
refuses them.

**Worth noting before the owner rules**, because §6.3's stated reason does not
survive the surface change: it says *"summing angles is the 2b rounding class
again"*. Under kickback there is **nothing to sum** — two `cqrt_rz_i1(f, θ₁)` and
`cqrt_rz_i1(f, θ₂)` on the SAME minted flag are exact, need no `fsub`, and compose
to `P(θ₁+θ₂)` on the branch by the physics of §3, not by floating-point
arithmetic the compiler performed. The N>1 refusal therefore looks like a
**scoping** choice rather than a correctness one, and it costs four shipped
slices. Not `prep_b`'s call, but the owner should rule on it knowing the reason
quoted in the PRD is a Ry-stem reason.

### OQ-6 — `slice_control_phase_nest_deep.c` is a MIXED nest, and two PRD rows both claim it

The brief specified the inner block carry *"a `cq_theta` on a third register before
the inner compare"* to survive SimplifyCFG's fold threshold. It does (measured, §4
note and the slice header). But that puts an **Ry in the outer arm and a phase in
the inner**, which §6.2 P4 (written for the 4.3 **homogeneous** nest) and §6.3
("mixed arms: `cq_phi` beside a value op or an Ry in the same arm") both claim,
with opposite verdicts. The oracle's own word for it today is `impure phase arm`.
The **homogeneous** genuine nest is already covered by the migrated
`slice_control_nested_phase.c`, so this slice's unique contribution IS the mixed
combination; it is committed with the ambiguity written into its header rather
than resolved.

### OQ-7 — an angle select spelled as a `phi double`

Finding 3(b). `SelectClassify` is entered from a `select`; a merge-φ angle select
is a shape §6.1's measured table does not contain and the accept/decline partition
has not been asked about. It is reachable from plain C today
(`slice_control_phase_ifelse_derived.c`).

## 6. What this record does NOT cover

* **No golden was created, regenerated or deleted.** `.expected.log` is out of
  `prep_b`'s scope by brief; the audit owns them once the lowering exists.
* **`include/CQ.h` is unchanged in the tree.** The scratch header lives at
  `$SP/progress/prep_b_include/CQ.h`.
* **`ir-pass/` is untouched.**
* The 14 new ctest entries are `DISABLED TRUE`. Enabling them is the deletion of
  one `set_tests_properties(...)` call in `tests/e2e/CMakeLists.txt`, named in a
  comment there.
* The three prose-only slices are **verified unaffected**: `slice_control_value_diamond`
  and `slice_libm_real_lgammaf` lower to IR that differs from their shipped-header
  lowering ONLY in `ModuleID` / `source_filename` (`diff` of the two `s2.ll` with those
  two lines removed is EMPTY), so the header change reaches nothing that does not call
  `cq_phi`.
* **No explicit-ancilla kickback spelling exists in the e2e corpus.** The brief
  anticipated sites of the form `bool m = (q == 5); m = cq_phi(m, PI);` needing a
  rewrite to `if (q == 5) cq_phi(PI);`. There are **zero** — the one `cq_phi` on a
  compare result (`slice_compare_qq.c:47`, `(void) cq_phi(eq, 0.30)`) is a KEEP-ALIVE
  on a dead flag, not a phase on a branch. So no site in this migration needed that
  transformation, and none was applied.
* The "expected post-increment class" column is **analytic**. Nothing implements
  Increment 1, so no post-increment disposition in this file is measured.
