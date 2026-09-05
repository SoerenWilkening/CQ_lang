# GOLDEN_REGEN.md — the Increment-1 golden regeneration record

bd epic `test_C_libtooling-3qlq` ("retire the swap route"), Increment 1
(register-free `cq_phi`), PRD
`docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md` §10.2.
Written by agent `prep_b2`, 2026-09-05. Every number here is MEASURED, with the
command that measured it.

## 0. What this file is, and what it is not

It is the answer to ONE question, asked of every golden this increment touched:
**is the diff one of the four ADMITTED substitutions, or is it a new program?**
A golden regenerated from a compiler that emits the wrong unitary is perfectly
self-consistent — it is a picture of whatever the compiler did — so the trace
byte-diff cannot catch it. What can is a claim about the SHAPE of the change,
which is what `tools/golden_multiset_audit.py --epic 3qlq` enforces.

It is **not** a correctness argument. The audit itself says so in as many words:
*"IT SAYS NOTHING ABOUT THE UNITARY. The whole POINT of Increment 1 is that the
OLD traces were the identity on `q`; proving a diff is the admitted substitution
does not prove the NEW unitary is the oracle."* That claim belongs to the Rule-13
lenses (PRD §10.3).

## 1. The commands

```
# stage 1 -> 2 -> STRICT 2b -> 3 -> 4 on all 71 slices, SUBJECT binary
$SP/progress/prep_b2_work/sweep_subj.sh $(cat $SP/progress/prep_b2_slices_final.txt)
    clang   /usr/local/opt/llvm@19/bin/clang -I<repo>/include -include CQ.h -O1
    cq-opt  $SP/wt/prep-b/build/ir-pass/cq-opt  (+ libCQPass.so, branch 3qlq-inc1-slices)
    2b      python3 tools/free_pairing_check.py -q   (STRICT — no --allow-unproven)
    link    templates BEFORE runtime, SUBJECT archives

# the audit's own mutant validation, then the audit
python3 tools/golden_multiset_audit.py --epic 3qlq --selftest
python3 tools/golden_multiset_audit.py --epic 3qlq --rev 52d7764 <the 71 goldens>
```

## 2. Headline (MEASURED)

| | |
|---|---|
| slices swept | **71** (61 migrated with a pre-existing golden + 10 new) |
| stage 2 exit 0 | **71 / 71** |
| stage 2b STRICT PASS | **71 / 71** (0 `--allow-unproven`) |
| stage 3 link + stage 4 trace | **71 / 71** |
| audit `--selftest` | **PASS, 0 survivors** (25 mutants + 10 controls + 2 tolerance pins) |
| audit statuses | 33 `SUBSTITUTION-ONLY` · 1 `AMBIGUOUS-d` · 1 `AMBIGUOUS-ca` · 10 `NEW-FILE` · **26 `FINDING`** |
| every one of the 26 `FINDING`s | a **REWRITTEN PROGRAM** listed in §4 below — 15 (OQ-2) + 10 (OQ-3) + 1 (OQ-5) |
| `cqrt_rz_i1` with a NEGATIVE angle, tree-wide | **0** (`grep -l 'cqrt_rz_i1(h[0-9]*, -' tests/e2e/*.expected.log`) |
| `cqrt_rz_<W>_controlled` surviving, tree-wide | **0** |
| non-`i1` `cqrt_rz` surviving, tree-wide | **0** of 303 goldens (56 carry a `cqrt_rz`, all `_i1`) |
| `cqrt_rz_i1` lines, tree-wide | **161** |

The last three rows are PRD §5's table (`cqrt_rz_{i8..f80}` become "not emitted")
verified at the only layer that LINKS. The negative-angle row is the standing
witness for round-1 finding **F-L7-1** (the whole-DAG spine adjointing the
kickback gate with `rz_i1(f, −θ)`, which cancelled the user's phase exactly): a
single negative angle on a flag anywhere in this tree would be that defect back.

## 3. The four admitted substitutions (PRD §10.2), and what was seen

* **(a)** `cqrt_rz_<W>_controlled(f, h, θ)` -> `cqrt_rz_i1(f, θ)`, same `f`, same θ.
* **(b)** the routed quintuple (`alloc`/`cswap`/`rz`/`cswap`/`free`) -> one
  `cqrt_rz_i1(f, θ)` per θ. **(b-NEST)** is the 4.3 depth-2 form.
* **(c)** an UNCONTROLLED `cqrt_rz_<W>(h, θ)` line DELETED (owner decision D2 — a
  global phase). Counted per FORWARD/ADJOINT line, so an uncomputed register
  loses a PAIR.
* **(d)** the drbq Inc-2b BY-DIFFERENCE pair -> the exact two-gate form
  `x(f); rz_i1(f,B); x(f); rz_i1(f,A)`.

⚠ **THE (b)-NEST SHAPE WAS A MODEL AND THE MEASUREMENT CONFIRMED IT.** The audit's
docstring flags its nest row as *"the PRD's 'Compound conditions' paragraph
transcribed onto the node shape `SelectMergeEmit.cpp` already emits"*, ONE golden,
unmeasured, and instructs: *"when the implementer's first real trace exists, DIFF
IT AGAINST THIS MODEL AND FIX WHICHEVER IS WRONG."* Done, and they AGREE
line-for-line — `slice_control_nested_phase` audits `SUBSTITUTION-ONLY`, with
observed and expected deltas identical:

```
 -9 [cqrt_alloc_i32(0) x2, cqrt_cswap x4, cqrt_free x1, cqrt_rz_i32(0x1.8p-1), cqrt_rz_i32(0x1p-2)]
 +5 [cqrt_alloc_i1(0) x1, cqrt_rz_i1(0x1.8p-1), cqrt_rz_i1(0x1p-2), cqrt_toffoli x2]
 (A4) cqrt_cswap 4 -> 0    (A5) cqrt_toffoli 0 -> 2
```

⚠ **THE (d) TOLERANCE FIRED AND PASSED, which is the point of it.** On
`slice_control_angle_select_rz` the OLD trace carries `D = fl(A−B)`, so `A` is
recoverable only as `fl(B+D)`: recovered `0x1.ccccccccccccep-1` against the new
trace's `0x1.ccccccccccccdp-1` — **ONE ULP APART**, error 1.110e-16 against a
tolerance of 3.331e-16. An `==` there would have failed the flagship golden.

## 4. Per-golden table (all 71)

`class` is the audit's verdict. **REWRITTEN PROGRAM** means the audit correctly
reported `FINDING` and the finding is EXPECTED: the `.c` was changed, so the
golden is a new program's trace and not a substitution of the old one. Every such
row names the owner question that authorises the rewrite and the file's own
header carries the measurement.

| slice | class | diff (handle-normalised multiset) |
|---|---|---|
| `onward_ctl_phase_caller` | SUBSTITUTION-ONLY (a)x1 | -1 / +1 lines: -[cqrt_rz_i32_controlled(h, h, 0x1p-2)] +[cqrt_rz_i1(h, 0x1p-2)] |
| `slice_bitint` | **REWRITTEN PROGRAM** (OQ-2) | -3 / +3 lines: -[cqrt_ry_i64(h, -0x1.999999999999ap-4); cqrt_rz_i64(h, -0x1.3333333333333p-2); cqrt_rz_i64(h, 0x1.3333333333333p-2)] +[cq_template_icmp_eq_i64_hl(h, 5) -> h; cq_template_icmp_eq_i64_hl_unc(h, h, 5); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_classical_if_gate` | SUBSTITUTION-ONLY (c)x1 | -1 / +0 lines: -[cqrt_rz_i32(h, 0x1p-2)] +[(none)] |
| `slice_classical_switch_gate` | SUBSTITUTION-ONLY (c)x2 | -2 / +0 lines: -[cqrt_rz_i32(h, 0x1.199999999999ap-1); cqrt_rz_i32(h, 0x1p-1)] +[(none)] |
| `slice_compare_qq` | **REWRITTEN PROGRAM** (OQ-2) | -4 / +5 lines: -[cqrt_ry_i32(h, -0x1.999999999999ap-3); cqrt_ry_i32(h, -0x1.999999999999ap-4); cqrt_rz_i32(h, -0x1.3333333333333p-2); +1 more] +[cq_template_add_i32(h, h) -> h; cq_template_add_i32_unc(h, h, h); cq_template_icmp_eq_i32_hl(h, 4) -> h; +2 more] |
| `slice_control_angle_select_rz` | AMBIGUOUS-d | -2 / +4 lines: -[cqrt_rz_i32(h, 0x1.3333333333333p-2); cqrt_rz_i32_controlled(h, h, 0x1.3333333333334p-1)] +[cqrt_x(h) x2; cqrt_rz_i1(h, 0x1.3333333333333p-2); cqrt_rz_i1(h, 0x1.ccccccccccccdp-1)] |
| `slice_control_angle_select_rz_twin` | AMBIGUOUS-ca | -2 / +1 lines: -[cqrt_rz_i32(h, 0x1.3333333333333p-2); cqrt_rz_i32_controlled(h, h, 0x1.3333333333334p-1)] +[cqrt_rz_i1(h, 0x1.3333333333334p-1)] |
| `slice_control_cond_datause` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.8p-1); cqrt_rz_i32_controlled(h, h, 0x1p-2)] +[cqrt_rz_i1(h, 0x1.8p-1); cqrt_rz_i1(h, 0x1p-2)] |
| `slice_control_cond_onward_phase` | SUBSTITUTION-ONLY (c)x1 | -1 / +0 lines: -[cqrt_rz_i32(h, 0x1p-2)] +[(none)] |
| `slice_control_grover_2iter` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_grover_derived_oracle` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_derived_oracle_2iter` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_grover_derived_oracle_offset` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_loop` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_grover_loop_derived` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_grover_loop_derived_unrolled` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_grover_loop_dynamic` | SUBSTITUTION-ONLY (a)x6 | -6 / +6 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x6] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x6] |
| `slice_control_grover_loop_leading_gate` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_loop_leading_gate_unrolled` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_loop_offset` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_loop_offset_unrolled` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_loop_range_oracle` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_loop_range_oracle_unrolled` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_grover_loop_two_regs` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_grover_loop_two_regs_unrolled` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_grover_loop_unrolled` | SUBSTITUTION-ONLY (a)x4 | -4 / +4 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x4] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x4] |
| `slice_control_inplace_ry_loop` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_inplace_ry_loop_grover` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_inplace_ry_loop_grover_unrolled` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_inplace_ry_loop_leading_gate` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_inplace_ry_loop_leading_gate_unrolled` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_inplace_ry_loop_leak` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_inplace_ry_loop_leak_unrolled` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_inplace_ry_loop_two_regs` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_inplace_ry_loop_two_regs_unrolled` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_inplace_ry_loop_unrolled` | **REWRITTEN PROGRAM** (OQ-3) | -2 / +2 lines: -[cqrt_rz_i32(h, 0x1.999999999999ap-4) x2] +[cqrt_ry_i32(h, 0x1.999999999999ap-5) x2] |
| `slice_control_nested_phase` | SUBSTITUTION-ONLY (b-NEST) | -9 / +5 lines: -[cqrt_cswap(h, h, h) x4; cqrt_alloc_i32(0) -> h x2; cqrt_free(h); +2 more] +[cqrt_toffoli(h, h, h) x2; cqrt_alloc_i1(0) -> h; cqrt_rz_i1(h, 0x1.8p-1); +1 more] |
| `slice_control_phase_andcond` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_angle_select` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_angle_select_runtime_arms` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_diamond` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.8p-1); cqrt_rz_i32_controlled(h, h, 0x1p-2)] +[cqrt_rz_i1(h, 0x1.8p-1); cqrt_rz_i1(h, 0x1p-2)] |
| `slice_control_phase_grover` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_grover_loop` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_grover_loop_unrolled` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_ifelse_derived` | SUBSTITUTION-ONLY (a)x3 + (c)x1 | -4 / +3 lines: -[cqrt_rz_i32(h, 0x1.ccccccccccccdp-1); cqrt_rz_i32_controlled(h, h, 0x1.8p-1); cqrt_rz_i32_controlled(h, h, 0x1p-2); +1 more] +[cqrt_rz_i1(h, 0x1.8p-1); cqrt_rz_i1(h, 0x1p-2); cqrt_rz_i1(h, 0x1p-3)] |
| `slice_control_phase_ifne` | SUBSTITUTION-ONLY (a)x1 | -1 / +1 lines: -[cqrt_rz_i32_controlled(h, h, 0x1p-2)] +[cqrt_rz_i1(h, 0x1p-2)] |
| `slice_control_phase_nest` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_perbit_loop` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_perbit_loop_k32` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_phase_perbit_loop_unrolled` | NEW-FILE | NEW FILE (no golden at 52d7764) |
| `slice_control_seq_grover` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1) x2] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1) x2] |
| `slice_control_seq_regions` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.8p-1); cqrt_rz_i32_controlled(h, h, 0x1p-2)] +[cqrt_rz_i1(h, 0x1.8p-1); cqrt_rz_i1(h, 0x1p-2)] |
| `slice_control_switch_eqfold` | SUBSTITUTION-ONLY (a)x2 | -2 / +2 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.8p-1); cqrt_rz_i32_controlled(h, h, 0x1p-2)] +[cqrt_rz_i1(h, 0x1.8p-1); cqrt_rz_i1(h, 0x1p-2)] |
| `slice_ctlz_idiom_loop` | **REWRITTEN PROGRAM** (OQ-2) | -3 / +3 lines: -[cqrt_ry_i32(h, -0x1.999999999999ap-4); cqrt_rz_i32(h, -0x1.3333333333333p-2); cqrt_rz_i32(h, 0x1.3333333333333p-2)] +[cq_template_icmp_eq_i32_hl(h, -1043) -> h; cq_template_icmp_eq_i32_hl_unc(h, h, -1043); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_f16` | **REWRITTEN PROGRAM** (OQ-2) | -5 / +3 lines: -[cqrt_free(h); cqrt_ry_f16(h, -0x1.999999999999ap-3); cqrt_ry_f16(h, -0x1.999999999999ap-4); +2 more] +[cq_template_fcmp_oeq_f16_hl(h, 0x1p+2) -> h; cq_template_fcmp_oeq_f16_hl_unc(h, h, 0x1p+2); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_f80` | **REWRITTEN PROGRAM** (OQ-2) | -5 / +3 lines: -[cqrt_free(h); cqrt_ry_f80(h, -0x1.999999999999ap-3); cqrt_ry_f80(h, -0x1.999999999999ap-4); +2 more] +[cq_template_fcmp_oeq_f80_hl(h, 0x8p-1) -> h; cq_template_fcmp_oeq_f80_hl_unc(h, h, 0x8p-1); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_fp80_union_unc` | **REWRITTEN PROGRAM** (OQ-2) | -20 / +3 lines: -[cqrt_free(h) x6; cq_template_and_i80_hl(h, 0x0000ffffffffffffffff) -> h; cq_template_and_i80_hl_unc(h, h, 0x0000ffffffffffffffff); +12 more] +[cq_template_icmp_eq_i64_hl(h, 16385) -> h; cq_template_icmp_eq_i64_hl_unc(h, h, 16385); cqrt_rz_i1(h, 0x1p-2)] |
| `slice_funnel_fshl_qq` | **REWRITTEN PROGRAM** (OQ-2) | -5 / +3 lines: -[cqrt_free(h); cqrt_ry_i32(h, -0x1.8p-2); cqrt_ry_i32(h, -0x1p-3); +2 more] +[cq_template_icmp_eq_i32_hl(h, 0) -> h; cq_template_icmp_eq_i32_hl_unc(h, h, 0); cqrt_rz_i1(h, 0x1.3333333333333p-1)] |
| `slice_intrinsic_bswap` | **REWRITTEN PROGRAM** (OQ-2) | -3 / +3 lines: -[cqrt_ry_i32(h, -0x1.999999999999ap-4); cqrt_rz_i32(h, -0x1.3333333333333p-2); cqrt_rz_i32(h, 0x1.3333333333333p-2)] +[cq_template_icmp_ugt_i32_hl(h, 100) -> h; cq_template_icmp_ugt_i32_hl_unc(h, h, 100); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_intrinsic_ctlz` | **REWRITTEN PROGRAM** (OQ-2) | -3 / +6 lines: -[cqrt_ry_i32(h, -0x1.999999999999ap-4); cqrt_rz_i32(h, -0x1.3333333333333p-2); cqrt_rz_i32(h, 0x1.3333333333333p-2)] +[cq_template_add_i32(h, h) -> h; cq_template_add_i32_unc(h, h, h); cq_template_icmp_eq_i32_hl(h, 12) -> h; +3 more] |
| `slice_intrinsic_ctpop` | **REWRITTEN PROGRAM** (OQ-2) | -3 / +3 lines: -[cqrt_ry_i32(h, -0x1.999999999999ap-4); cqrt_rz_i32(h, -0x1.3333333333333p-2); cqrt_rz_i32(h, 0x1.3333333333333p-2)] +[cq_template_icmp_eq_i32_hl(h, 16) -> h; cq_template_icmp_eq_i32_hl_unc(h, h, 16); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_intrinsic_fma` | **REWRITTEN PROGRAM** (OQ-2) | -5 / +3 lines: -[cqrt_free(h); cqrt_ry_f64(h, -0x1.999999999999ap-3); cqrt_ry_f64(h, -0x1.999999999999ap-4); +2 more] +[cq_template_fcmp_oeq_f64_hl(h, 0x1p+2) -> h; cq_template_fcmp_oeq_f64_hl_unc(h, h, 0x1p+2); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_intrinsic_fpmath` | **REWRITTEN PROGRAM** (OQ-2) | -5 / +3 lines: -[cqrt_free(h); cqrt_ry_f64(h, -0x1.999999999999ap-3); cqrt_ry_f64(h, -0x1.999999999999ap-4); +2 more] +[cq_template_fcmp_oeq_f64_hl(h, 0x1.8p+0) -> h; cq_template_fcmp_oeq_f64_hl_unc(h, h, 0x1.8p+0); cqrt_rz_i1(h, 0x1.3333333333333p-2)] |
| `slice_loop_iter_local` | **REWRITTEN PROGRAM** (OQ-2) | -18 / +9 lines: -[cq_template_xor_i32_hl(h, 9) -> h x3; cq_template_xor_i32_hl_unc(h, h, 9) x3; cqrt_free(h) x3; +3 more] +[cq_template_icmp_eq_i32_hl(h, 2) -> h x3; cq_template_icmp_eq_i32_hl_unc(h, h, 2) x3; cqrt_rz_i1(h, 0x1p-1) x3] |
| `slice_loop_phase_accum` | SUBSTITUTION-ONLY (c)x3 | -3 / +0 lines: -[cqrt_rz_f64(h, 0x1.999999999999ap-4) x3] +[(none)] |
| `slice_select_rail_alias_cond` | **REWRITTEN PROGRAM** (OQ-5) | -45 / +2 lines: -[cqrt_x(h) x6; cqrt_copy_i32_controlled(h, h, h) x4; cqrt_free(h) x3; +26 more] +[cq_template_fcmp_ord_f64_hl(h, 0x0p+0) -> h; cq_template_fcmp_ord_f64_hl_unc(h, h, 0x0p+0)] |
| `slice_uncompute_dead_dag` | **REWRITTEN PROGRAM** (OQ-2) | -8 / +6 lines: -[cqrt_free(h); cqrt_ry_i32(h, -0x1.999999999999ap-3); cqrt_ry_i32(h, -0x1.999999999999ap-4); +5 more] +[cq_template_icmp_eq_i32_hl(h, 4) -> h; cq_template_icmp_eq_i32_hl_unc(h, h, 4); cq_template_icmp_sgt_i32_hl(h, 100) -> h; +3 more] |
| `slice_uncompute_dead_shapes` | **REWRITTEN PROGRAM** (OQ-2) | -9 / +22 lines: -[cqrt_ry_f32(h, -0x1.999999999999ap-2); cqrt_ry_i32(h, -0x1.3333333333333p-2); cqrt_ry_i32(h, -0x1p-2); +6 more] +[cqrt_free(h) x3; cq_template_fcmp_oeq_f32_hl(h, -0x1.2p+3) -> h; cq_template_fcmp_oeq_f32_hl_unc(h, h, -0x1.2p+3); +17 more] |
| `slice_uncompute_interior_region_derived_cond` | SUBSTITUTION-ONLY (a)x1 | -1 / +1 lines: -[cqrt_rz_i32_controlled(h, h, 0x1.921fb54442d18p+1)] +[cqrt_rz_i1(h, 0x1.921fb54442d18p+1)] |
| `spec_select_caller` | SUBSTITUTION-ONLY (c)x1 | -1 / +0 lines: -[cqrt_rz_i32(h, 0x1.91eb851eb851fp+1)] +[(none)] |
| `spec_twoarm_caller` | SUBSTITUTION-ONLY (c)x1 | -1 / +0 lines: -[cqrt_rz_i32(h, 0x1.91eb851eb851fp+1)] +[(none)] |

## 5. The 26 REWRITTEN PROGRAMS, with the reason and the measurement

Each of these audits `FINDING` **by design** — the audit is a claim about the diff
of ONE program's trace, and these are a DIFFERENT program's trace. The audit's own
docstring predicted fifteen of them (`_C_CAVEAT`: *"FIFTEEN of the 31 (c) goldens
will legitimately come back as FINDINGS, and that is the tool working, not a bug
in it"*); the other eleven are the loop family and the alias slice, which prep-b
raised as OQ-2/OQ-4 (PRE_DISPOSITIONS.md §5) and the orchestrator dispositioned.

### 5.1 The 15 KEEP-ALIVE slices (OQ-2) — `cq_phi(θ)` -> `if (<dead terminal> <cmp> k) cq_phi(θ)`

The old `(void) cq_phi(x, θ)` was the only opaque READER in `CQ.h` that kept a
dead tainted chain alive past `-O1` DCE. Register-free it reads nothing, so the
chain — and the `_unc` twin the slice exists to link — vanishes at STAGE 1
(prep-b PROBE 2). The replacement consumer is a KICKBACK UNDER A DERIVED
CONDITION, which exercises the forward chain, the mint, `cqrt_rz_i1`, the strip,
the chain's own `_unc` and the frees.

| slice | new condition | `_unc` symbol recovered (measured in the golden) |
|---|---|---|
| `slice_bitint` | `if (zc == (u40)5)` | `cq_template_and_i64_hl_unc` (the i40 mask) |
| `slice_compare_qq` | `int acc = eq + pi; if (acc == 4)` | `cq_template_icmp_eq_i32_unc` (Q+Q) |
| `slice_ctlz_idiom_loop` | `if (ix == -1043)` | `ctlz_i32` · `and_i32_hl` · `or_i32_hl` · `shl_i32_hl` · `sub_i32_lh` |
| `slice_f16` | `if (d == (_Float16)4.0f)` | `cq_template_fadd_f16_unc` |
| `slice_f80` | `if (d == 4.0L)` | `cq_template_fadd_f80_unc` |
| `slice_fp80_union_unc` | `if (u.bits.exp == 16385u)` | `bitcast_f80_to_i80` · `lshr_i80_hl` · `trunc_i80_to_i16` · `zext_i16_to_i64` · `and_i64_hl` · `add_i64_hl` |
| `slice_funnel_fshl_qq` | `if (dead == 0u)` | `cq_template_fshl_i32_qql_unc` |
| `slice_intrinsic_bswap` | `if (d > 100u)` | `cq_template_bswap_i32_unc` |
| `slice_intrinsic_ctlz` | `int g = d + (int) c; if (g == 12)` | `cq_template_ctlz_i32_unc` |
| `slice_intrinsic_ctpop` | `if (d == 16)` | `cq_template_ctpop_i32_unc` |
| `slice_intrinsic_fma` | `if (f == 4.0)` | `cq_template_fma_f64_qlq_unc` |
| `slice_intrinsic_fpmath` | `if (e == 1.5)` | `cq_template_fmin_f64_unc` |
| `slice_loop_iter_local` | `if (t == 11)` | `icmp_eq_i32_hl_unc` per activation (the iteration-local discharge) |
| `slice_uncompute_dead_dag` | `if (b > 100)` · `if (prod == 4)` | `shl_i32_hl_unc` + `cqrt_xorc_i32` + `mul_i32_unc` |
| `slice_uncompute_dead_shapes` | `if (t > 100)` · `long lp = lb * (long)cq_theta(y,.35); if (lp == 15L)` · `float fp = fn * cq_theta(z,.45); if (fp == -9.0f)` | `shl_i32_lh_unc` · `sub_i32_lh_unc` · `sext_i32_to_i64_unc` · `fneg_f32_unc` |

**ZERO of the 15 needed the brief's `cq_measure` fallback**, and no `_unc`
coverage was lost.

⚠ **TWO THINGS HAD TO BE MEASURED RATHER THAN ASSUMED, and both changed the edit.**

1. **A plain `==` against a constant is folded THROUGH an invertible op.** Five
   sites silently lost the very symbol they exist for before this was caught.
   MEASURED folds at `clang -O1`: `bswap(c) == K` becomes `c == bswap(K)` and the
   `llvm.bswap.i32` disappears; `clz(c) == 12` becomes a range test on `c`;
   `sext(b) == K` becomes `b == K`; `-fc == K` becomes `fc == -K`;
   `(a<<2)^9 == 9` becomes a mask test. The fix is a condition the folder cannot
   invert: an ORDERED compare, or a Q+Q op against a SECOND tainted register
   (both operands non-constant). The recovered symbol in the table above is the
   witness that it worked — this is exactly the bd `3c6m.63` failure mode (a test
   measuring a program that ships nowhere), caught by looking rather than by a
   green suite.
2. **`slice_compare_qq`'s obvious spelling declines.** `if (eq == 1)` collapses to
   `br i1 (icmp eq i32 %p, %q)` — a Q+Q BRANCH condition — and the module declines
   `no template for opcode 'icmp i1' in tainted context`. Fixed by
   `int acc = eq + pi; if (acc == 4)`, which keeps the Q+Q compare LIVE while the
   BRANCH condition is Q+C. See finding F-B2-2 in `$SP/progress/prep_b2.md`.

### 5.2 The 10 in-place-Ry LOOP slices (OQ-3)

`cq_phi` was the loop-VARIANT maker for the CONDITION register. Register-free the
compare is loop-invariant, `clang -O1` LICM-hoists it into the entry block, and
`condWireDisposition`'s P4 precondition declines — MEASURED IDENTICALLY ON THE
PRE-3qlq ORACLE, so this is the migrated source's stage-1 shape, not Increment 1's
lowering.

* **8 slices** (`..._loop{,_unrolled}`, `..._leading_gate{,_unrolled}`,
  `..._two_regs{,_unrolled}`, `..._leak{,_unrolled}`): `q = cq_theta(q, 0.05);`
  ADDED after each `cq_phi(0.1);`. The uncontrolled `cq_phi(0.1)` is KEPT where it
  stood — D2 deletes it, so it documents the original intent and costs the trace
  nothing (that half of the diff is substitution (c)).
  ORACLE decline: `cq controlled lowering: condition predates a non-diagonal gate
  under quantum control`.
* **2 slices** (`..._grover{,_unrolled}`): the S† `cq_theta` MOVED to sit BETWEEN
  the two `if`s. With `cq_phi` register-free the two adjacent equality tests on one
  register are fused by SimplifyCFG into ONE `switch i32 %q, [5 -> phase arm,
  3 -> Ry arm]` — a MIXED-arm switch, §6.3's decline row. ORACLE declines the same
  two files with the same two strings (`control flow` flat / `control flow inside a
  loop body` rolled).

**All four twin pairs are BYTE-IDENTICAL after the rewrite** (`cmp` gates
`e2e-inplace-ry-loop{,-leading-gate,-two-regs,-leak,-grover}-twin-identical`), and
so is the `_grover` pair.

### 5.3 `slice_select_rail_alias_cond` (OQ-5) — three of five lineages RETIRED

The slice existed for a compare whose two operands are SSA-DISTINCT but ONE RAIL,
and the ONLY CQ construct that built such a pair was the RENAMING in-place gate
`%r = cq_phi(%q, θ)`. Under D1 `r` IS `q`, so `x < x` / `x == x` fold to constants
at stage 1 and the module declined
`cq_measure_<sfx> operand not recognized; expected a tainted i32 handle`.
Lineages (A) int `<`, (B) f64 `<` and (D) int `==` are retired; (C) `p * p` and
(E) `(qg >= qg) ? 1.0 : 2.0` are kept.

⚠ **RECORDED COVERAGE LOSS, not papered over.** The ALIASED-OPERAND COMPARE has no
spelling left at any width: `cq_template_icmp_slt_i32(h,h)`,
`cq_template_icmp_eq_i32(h,h)`, `cq_template_fcmp_olt_f64(h,h)`,
`cq_template_fcmp_oge_f64(h,h)` and their four `_unc` twins leave this golden. Only
the ARITHMETIC alias (C) `cq_template_mul_i32(h0, h0)` survives. And (E) is NOT an
alias witness any more either — MEASURED: `clang -O1` rewrites `x >= x` to
`fcmp ord x, x` and then to `fcmp ord x, 0.0`, so the emitted line is
`cq_template_fcmp_ord_f64_hl(h2, 0x0p+0)`, a Q+C compare. (E) is kept as a live
customer of the kjd1 fp-DATA select copy family, which it still is.

## 6. THREE REGISTRATIONS REMOVED (not regenerated)

| what | why (MEASURED on BOTH binaries) |
|---|---|
| `e2e-slice-loop-break-qq-phase` + `slice_loop_break_qq_phase.{c,expected.log}` | OQ-5. The slice's subject was a loop-invariant comparand carrying a RELATIVE PHASE (`p = cq_phi(p0, 0.3)`). Under D1 `p` IS `p0`, so the source is the same program as `slice_loop_break_qq.c`: the two stage-1 modules differ ONLY by the uncontrolled `call void @cq_phi(double 0.3)` and its `declare`, which D2 deletes, so the LOWERED IR is identical. Keeping it would be a second copy of `e2e-slice-loop-break-qq` wearing a claim it no longer tests. |
| `e2e-slice-control-phase-nest-deep` + `slice_control_phase_nest_deep.c` | OQ-7. A MIXED nest (an Ry in the outer arm, a phase in the inner). Exit 1, `cq controlled lowering: impure phase arm under quantum control`, on the SUBJECT and the ORACLE alike. A declining program has no e2e form; the decline is pinned in lit. The HOMOGENEOUS depth-2 nest (P4) keeps its customer in `slice_control_nested_phase.c`. |
| `e2e-slice-control-switch-phase` + `slice_control_switch_phase.expected.log` (the `.c` is KEPT, unregistered, with the record in its header) | OQ-4 / OQ-11. PRD §6.2 P5 LOWERS (Inc 1b: 3 accept + 7 decline lit fixtures) but has NO plain-C customer at `-O1`: a phase arm's whole content is `call void @cq_phi(double)`, so SimplifyCFG's common-code sinking always applies and the three arms become a `[3 x double] @switch.table` of ANGLES with ONE shared call. Exit 1, `cq QRAM access: const-global table read under tainted control: index not provably in-bounds (no known-bits proof; table size not a power of two)`, on BOTH binaries. Giving P5 an e2e customer needs the TABLE-FOLD RECOGNIZER — an owner decision. |

## 7. ONE SLICE SOURCE FIXED FOR A REASON THAT IS NOT A REWRITE (finding F-B2-1)

`slice_control_phase_grover_loop.c` (NEW, no golden ever existed) was written with
`int q = 0;` and the first `cq_theta` INSIDE the loop. `clang -O1` then builds the
header phi `%q = phi i32 [0, entry], [%rot, latch]` — a CLASSICAL constant merged
with a tainted value — and `declineClassicalMuxes` refuses the module with
`cq taint escape: tainted value muxed by a classical-condition phi`.
MEASURED on BOTH binaries with a two-line probe: `int q=0; for(i<3) q=cq_theta(q,.3);`
declines identically on the pre-3qlq ORACLE and the Increment-1 SUBJECT; adding one
`cq_theta` before the loop makes both accept. It is a pre-existing,
arm-class-independent property of the taint layer. The seed was moved out of the
loop in the rolled slice and its unrolled twin (the body re-ordered so the two files
stay exactly one activation apart), which is also the shape the shipped
`slice_control_grover_loop.c` has always had.

Result: both accept, **33 trace lines, BYTE-IDENTICAL**; K-independence re-measured
on the LOWERED IR — `@slice` is **25 lines at K=3 and 25 at K=1000**.

## 8. What this record does NOT witness

* **The unitary.** See §0. The audit proves the SHAPE of a diff; PRD §10.3's
  Rule-13 lenses own the physics.
* **"Freed at |0>".** No trace label can say it, at any ABI. Stage 2b
  (`tools/free_pairing_check.py`) owns that, and it ran STRICT — no
  `--allow-unproven` anywhere in these 71 — with 71/71 PASS. Note the single
  `--allow-unproven` this increment removed from the tree went with
  `slice_loop_break_qq_phase` (§6).
* **The 232 goldens with no `cqrt_rz`.** They are not in scope for Increment 1 and
  are unchanged; `git status --porcelain tests/e2e` lists exactly the 71 above
  plus the two deletions.

## 9. ONE `cmp` TWIN GATE RETIRED — `e2e-angle-select-rz-twin-identical`

It was the ONLY red in the e2e layer after the regeneration, and it is a gate that
became FALSE rather than a regression. It asserted `compare_files` between
`slice_control_angle_select_rz.expected.log` and its BY-DIFFERENCE manual twin.
Under owner decision D2 the twin's leading `cq_phi(0.3)` is UNCONTROLLED — a
GLOBAL PHASE — and the pass deletes it. MEASURED, the whole relation:

```
subject  cqrt_x(f); cqrt_rz_i1(f, 0x1.3333333333333p-2);       P(0.3) on !f
         cqrt_x(f); cqrt_rz_i1(f, 0x1.ccccccccccccdp-1)        P(0.9) on  f
twin                cqrt_rz_i1(f, 0x1.3333333333334p-1)        P(fl(0.9-0.3)) on f
```

The two are the SAME STATE up to the factor `e^{i0.3}` that D2 removes, so the byte
gate would be asserting that a deleted global phase is observable. Both slices keep
their registration and their golden; the relation — the twin's single angle is
`fl(A − B)` of the subject's two — is stated in both headers and is checkable by
hand from the two committed files. The drbq Inc-4 state-prep group set the
precedent verbatim: *"the two goldens differ by a reduction and a `compare_files`
gate would assert something FALSE"*.

⚠ And there is no repair available, which is the part to carry (prep-d, OQ-15):
**no byte-identity twin exists for the Rz angle select at all.** The obvious
candidate `if (q==5) cq_phi(A); if (q!=5) cq_phi(B);` is BYTE-IDENTICAL at `-O1`
to the if/else itself, so it is the same module and witnesses nothing. P2's witness
for the Rz stem is the audit's substitution (d) — which fired and passed (§3) —
plus the analytic argument, which belongs to the Rule-13 lenses.

The FIVE other `cmp` twin gates over goldens this increment regenerated are GREEN:
`e2e-inplace-ry-loop{,-leading-gate,-two-regs,-leak,-grover}-twin-identical`, plus
the two NEW ones `e2e-phase-grover-loop-twin-identical` and
`e2e-phase-perbit-loop-twin-identical`, and `e2e-phase-nest-andcond-identical`.


## 10. The 74-slice disposition table — MEASURED, against PRE_DISPOSITIONS.md's ANALYTIC column

`expected` is `PRE_DISPOSITIONS.md` §4, written by `prep_b` BEFORE any lowering
existed and explicitly labelled analytic. `measured` is this agent's final sweep on
the Increment-1 binary, AFTER the source edits §5-§7 describe. Rows marked in the
last column left the ctest registration (§6).

| slice | kind | expected class (ANALYTIC) | MEASURED on the SUBJECT | note |
|---|---|---|---|---|
| `onward_ctl_phase_caller` | migrated | P1 | ACCEPT, 17 lines, 2b PASS |  |
| `slice_bitint` | migrated | P7 + PURPOSE LOST | ACCEPT, 18 lines, 2b PASS |  |
| `slice_classical_if_gate` | migrated | P7 ×2 | ACCEPT, 6 lines, 2b PASS |  |
| `slice_classical_switch_gate` | migrated | P7 ×7 | ACCEPT, 6 lines, 2b PASS |  |
| `slice_compare_qq` | migrated | P7 + PURPOSE LOST | ACCEPT, 26 lines, 2b PASS |  |
| `slice_control_angle_select_rz` | migrated | P2 | ACCEPT, 13 lines, 2b PASS |  |
| `slice_control_angle_select_rz_twin` | migrated | P1 + P7 | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_cond_datause` | migrated | §6.3 DECLINE | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_cond_onward_phase` | migrated | P7 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_2iter` | migrated | P1 ×4 | ACCEPT, 28 lines, 2b PASS |  |
| `slice_control_grover_derived_oracle` | migrated | P1 ×2 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_derived_oracle_2iter` | migrated | P1 ×4 | ACCEPT, 35 lines, 2b PASS |  |
| `slice_control_grover_derived_oracle_offset` | migrated | P1 ×2 | ACCEPT, 22 lines, 2b PASS |  |
| `slice_control_grover_loop` | migrated | P6 ×2 | ACCEPT, 23 lines, 2b PASS |  |
| `slice_control_grover_loop_derived` | migrated | P6 ×2 | ACCEPT, 45 lines, 2b PASS |  |
| `slice_control_grover_loop_derived_unrolled` | migrated | P1 ×4 | ACCEPT, 45 lines, 2b PASS |  |
| `slice_control_grover_loop_dynamic` | migrated | P6 ×2 | ACCEPT, 33 lines, 2b PASS |  |
| `slice_control_grover_loop_leading_gate` | migrated | P6 | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_grover_loop_leading_gate_unrolled` | migrated | P1 ×2 | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_grover_loop_offset` | migrated | P6 | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_grover_loop_offset_unrolled` | migrated | P1 ×2 | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_grover_loop_range_oracle` | migrated | P6 / P3 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_loop_range_oracle_unrolled` | migrated | P3 ×2 | ACCEPT, 19 lines, 2b PASS |  |
| `slice_control_grover_loop_two_regs` | migrated | P6 ×2 | ACCEPT, 30 lines, 2b PASS |  |
| `slice_control_grover_loop_two_regs_unrolled` | migrated | P1 ×4 | ACCEPT, 30 lines, 2b PASS |  |
| `slice_control_grover_loop_unrolled` | migrated | P1 ×4 | ACCEPT, 23 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 16 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_grover` | migrated | P6 (phase) + drbq Inc-3 (Ry arm) | ACCEPT, 26 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_grover_unrolled` | migrated | P1 ×2 + drbq Inc-1 (Ry arms) | ACCEPT, 26 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leading_gate` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leading_gate_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 18 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leak` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_leak_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 21 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_two_regs` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 27 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_two_regs_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 27 lines, 2b PASS |  |
| `slice_control_inplace_ry_loop_unrolled` | migrated | DECLINE `condition predates a non-diagonal gate` | ACCEPT, 16 lines, 2b PASS |  |
| `slice_control_nested_phase` | migrated | P4 | ACCEPT, 15 lines, 2b PASS |  |
| `slice_control_phase_andcond` | NEW | P3 | ACCEPT, 17 lines, 2b PASS |  |
| `slice_control_phase_angle_select` | NEW | P2 | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_phase_angle_select_runtime_arms` | NEW | P2, run-time arms | ACCEPT, 10 lines, 2b PASS |  |
| `slice_control_phase_diamond` | migrated | §6.3 DECLINE | ACCEPT, 8 lines, 2b PASS |  |
| `slice_control_phase_grover` | NEW | P1 ×4 | ACCEPT, 22 lines, 2b PASS |  |
| `slice_control_phase_grover_loop` | NEW | P6 | ACCEPT, 33 lines, 2b PASS |  |
| `slice_control_phase_grover_loop_unrolled` | NEW | P1 ×6 | ACCEPT, 33 lines, 2b PASS |  |
| `slice_control_phase_ifelse_derived` | migrated | §6.3 DECLINE + a NEW shape | ACCEPT, 11 lines, 2b PASS |  |
| `slice_control_phase_ifne` | migrated | P1 | ACCEPT, 9 lines, 2b PASS |  |
| `slice_control_phase_nest` | NEW | P3 | ACCEPT, 17 lines, 2b PASS |  |
| `slice_control_phase_nest_deep` | NEW | P4 **or** §6.3 mixed-arm DECLINE | DECLINE: cq controlled lowering: impure phase arm under quantum contr | OQ-7 DELETED |
| `slice_control_phase_perbit_loop` | NEW | P6 | ACCEPT, 39 lines, 2b PASS |  |
| `slice_control_phase_perbit_loop_k32` | NEW | P6 | ACCEPT, 291 lines, 2b PASS |  |
| `slice_control_phase_perbit_loop_unrolled` | NEW | P1 ×4 | ACCEPT, 39 lines, 2b PASS |  |
| `slice_control_seq_grover` | migrated | P1 ×2 | ACCEPT, 15 lines, 2b PASS |  |
| `slice_control_seq_regions` | migrated | P1 ×2 | ACCEPT, 11 lines, 2b PASS |  |
| `slice_control_switch_eqfold` | migrated | §6.3 DECLINE | ACCEPT, 8 lines, 2b PASS |  |
| `slice_control_switch_phase` | migrated | NONE — P5 loses its only plain-C customer | DECLINE: cq QRAM access: const-global table read under tainted contro | OQ-4/11 UNREGISTERED |
| `slice_ctlz_idiom_loop` | migrated | P7 + PURPOSE LOST | ACCEPT, 46 lines, 2b PASS |  |
| `slice_f16` | migrated | P7 + PURPOSE LOST | ACCEPT, 17 lines, 2b PASS |  |
| `slice_f80` | migrated | P7 + PURPOSE LOST | ACCEPT, 20 lines, 2b PASS |  |
| `slice_fp80_union_unc` | migrated | P7 + PURPOSE LOST | ACCEPT, 32 lines, 2b PASS |  |
| `slice_funnel_fshl_qq` | migrated | P7 + PURPOSE LOST | ACCEPT, 17 lines, 2b PASS |  |
| `slice_intrinsic_bswap` | migrated | P7 + PURPOSE LOST | ACCEPT, 13 lines, 2b PASS |  |
| `slice_intrinsic_ctlz` | migrated | P7 + PURPOSE LOST | ACCEPT, 20 lines, 2b PASS |  |
| `slice_intrinsic_ctpop` | migrated | P7 + PURPOSE LOST | ACCEPT, 13 lines, 2b PASS |  |
| `slice_intrinsic_fma` | migrated | P7 + PURPOSE LOST | ACCEPT, 19 lines, 2b PASS |  |
| `slice_intrinsic_fpmath` | migrated | P7 + PURPOSE LOST | ACCEPT, 15 lines, 2b PASS |  |
| `slice_loop_break_qq_phase` | migrated | P7 | ACCEPT 187 lines | OQ-5 DELETED |
| `slice_loop_iter_local` | migrated | P7 + PURPOSE LOST | ACCEPT, 18 lines, 2b PASS |  |
| `slice_loop_phase_accum` | migrated | P7 | ACCEPT, 3 lines, 2b PASS |  |
| `slice_select_rail_alias_cond` | migrated | DECLINE `cq_measure_<sfx> operand not recognized` | ACCEPT, 17 lines, 2b PASS |  |
| `slice_uncompute_dead_dag` | migrated | P7 + PURPOSE LOST | ACCEPT, 22 lines, 2b PASS |  |
| `slice_uncompute_dead_shapes` | migrated | P7 + PURPOSE LOST | ACCEPT, 43 lines, 2b PASS |  |
| `slice_uncompute_interior_region_derived_cond` | migrated | P1 | ACCEPT, 19 lines, 2b PASS |  |
| `spec_select_caller` | migrated | P7 | ACCEPT, 12 lines, 2b PASS |  |
| `spec_twoarm_caller` | migrated | P7 | ACCEPT, 30 lines, 2b PASS |  |

### 10.1 Every row where MEASURED differs from the analytic expectation (12), and why

| slice(s) | expected | measured | why |
|---|---|---|---|
| the four `§6.3 DECLINE` rows — `slice_control_phase_diamond`, `slice_control_cond_datause`, `slice_control_switch_eqfold`, `slice_control_phase_ifelse_derived` | DECLINE (`N>1 cq_phi` per arm) | **ACCEPT** | **OQ-6, decided before implementation.** N `cqrt_rz_i1` on ONE minted flag is exact and performs no arithmetic; PRD §6.3's stated ground ("summing angles is the 2b rounding class again") is a **Ry-stem** ground that does not survive D1. Implemented by `impl_inc1a`. `..._ifelse_derived` additionally needed **OQ-8** (an angle select spelled as a merge-tail `phi double`), also implemented. |
| the eight `DECLINE condition predates a non-diagonal gate` rows (`slice_control_inplace_ry_loop*`) | DECLINE | **ACCEPT** | **OQ-3, executed here** (§5.2). The predicted DECLINE is exactly what this agent measured BEFORE the rewrite, on both binaries. |
| `slice_select_rail_alias_cond` | DECLINE `cq_measure_<sfx> operand not recognized` | **ACCEPT** | **OQ-5, executed here** (§5.3). Same: the predicted DECLINE is the pre-rewrite measurement. |
| `slice_control_phase_grover_loop` | P6 (accept) | ACCEPT after a SOURCE FIX | finding **F-B2-1**, §7. As `prep_b` wrote it, it declined `tainted value muxed by a classical-condition phi` on BOTH binaries. |
| `slice_control_inplace_ry_loop_grover{,_unrolled}` | P6 / P1×2 + drbq | ACCEPT after a SOURCE FIX | §5.2, second bullet. `-O1` fused the phase `if` and the Ry `if` into one mixed-arm `switch`; the ORACLE declines both files with the same two strings. |

**There is no row where the compiler ACCEPTED something this record expected to
DECLINE for a CORRECTNESS reason.** Every accept above is either an orchestrator
decision taken before implementation (OQ-6 / OQ-8) or a slice rewritten here under
an explicit disposition (OQ-2 / OQ-3 / OQ-5); in the two F-B2 cases the pre-rewrite
measurement reproduces on the pre-3qlq oracle byte for byte.

## 11. The e2e layer after this work

`ctest --test-dir build -j6 -R '^e2e-' --output-on-failure`, run TWICE.

* first run, before the §9 gate was retired: **99% passed, 3 failed of 328**, 1187.58 s.
* **FINAL run, after `cmake -S . -B build`: 99% passed, 2 failed of 327**, 738.33 s
  (`$SP/progress/prep_b2_e2e3.log`). **NEITHER red is this increment's e2e work**, and
  neither is a lowering change — both are named below with their owner and the
  measurement that identifies them.

The reds, each with its owner:

| red | owner | reason (MEASURED) |
|---|---|---|
| `e2e-angle-select-rz-twin-identical` | **this agent — FIXED, and GONE from the final run** | §9. The gate became FALSE under D2 and was retired; both its slices pass individually (re-measured 2/2 after the reconfigure) and pass in the final 327. |
| `e2e-fixture-guard-liveness` | **prep-a / the fixture re-derive** | 7 SKIPs, every one verified to carry **2** `@cq_phi_<sfx>` references (`grep -c '@cq_phi_[a-z0-9]'`): `lowering_io_tape_rz_preserving`, `lowering_live_record_mb_{router_phi,sibling_alias}_accept`, `lowering_uncompute_interior_leak_{region_wire_measured,route_in_interval}`, `lowering_uncompute_interior_region_{chain,routed_base}`. Each is in the retired family, the pass declines it (rc=1), so its anchored `NOFREE` guard cannot be checked. **0 DEAD guards.** `impl_inc1b` reported this identical failure for this identical reason. |
| `e2e-loop-twin-matrix` | **prep-d2** (round-1 F-L5-7, OQ-18) | `274 cells — 50 ACCEPT-IDENTICAL, 33 DECLINE, 191 other; 15 quarantined`. Its GENERATOR emits programs on the RETIRED two-argument surface, so they fail at stage 1 (`clang` error). It needs `--phi-surface void` and regenerated tables. |

## 12. FINDING F-B2-3 — FOUR slices whose SUBJECT was the uncontrolled Rz itself

Not a defect and not a mismatch: all four audit `SUBSTITUTION-ONLY` class (c), which
is owner decision D2 working exactly as written (an uncontrolled or
classically-controlled `cq_phi` is a global phase and is DELETED). They are recorded
because a slice that still compiles, still has a golden, and no longer exercises the
thing its header claims is the bd `3c6m.63` / `165/174` failure mode, and it is
invisible to a green suite. **This agent did NOT rewrite them** — the remedy is the
same class of decision the orchestrator took for OQ-2 / OQ-3 / OQ-5, and it is not
`prep_b2`'s to take.

MEASURED (`grep -c cqrt_rz_i1` on the new golden vs `grep -c cqrt_rz` on 52d7764's):

| slice | golden then -> now | what the slice claimed to prove | what survives |
|---|---|---|---|
| `slice_classical_if_gate` | 1 rz -> **0**, 6 lines | a CLASSICAL condition gating a quantum Rz: one arm FIRES, one does NOT — the contrast IS the test | nothing of the contrast; the golden is two `alloc/ry/measure` triples |
| `slice_classical_switch_gate` | 2 rz -> **0**, 6 lines | the same over a 7-arm classical `switch` (incl. a 2-gate arm and a default) | as above — byte-identical to `slice_classical_if_gate`'s golden |
| `slice_loop_phase_accum` | 3 rz -> **0**, 3 lines | an Rz accumulating a phase over a classically-bounded loop | nothing: the loop body was ONE uncontrolled `cq_phi`, so the body is empty and the golden is `alloc; ry; measure` |
| `slice_control_cond_onward_phase` | 1 rz -> **0**, 19 lines | an ONWARD phase on a value produced by a control merge (the `dugh` re-propagation) | the 4.5 switch DATA-MUX half is intact and fully exercised (3 eq-flag mints, 3 controlled copies, 3 strips, 3 frees); only the ONWARD phase is gone |

Two more lose an Rz line without losing their subject, and are listed so the count
is complete rather than because they need anything: `spec_select_caller` and
`spec_twoarm_caller` (1 rz -> 0 each) keep their whole specialization stream (12 and
30 trace lines) — the deleted line was a trailing onward phase.

**Proposed remedy, for whoever rules on it** (one line each, all inside the existing
machinery): re-base the first three on the Ry stem — `if (taken) q1 = cq_theta(q1, .25);`
and `for (...) q = cq_theta(q, .1);` — which restores the FIRES / does-NOT-fire
contrast and the loop accumulation without touching what the slices are about (a
CLASSICAL branch must not become quantum control); and give
`slice_control_cond_onward_phase` a kickback onward region (`if (r == 9) cq_phi(.25);`)
so the merged value is read by a real consumer. Each would then be a REWRITTEN PROGRAM
under §5's rules.
