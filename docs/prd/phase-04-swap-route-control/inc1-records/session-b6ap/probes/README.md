# Probe family — bd `test_C_libtooling-b6ap` (MULTI-PHI MERGE PEEL), scoping session

Session `01NHxGVinGBKbb499HFCuwhT`, 2026-09-11, **read-only scoping**, measured against the
landed `main` binary `build/ir-pass/cq-opt` at **`0c7380c`** (`git status --porcelain` clean apart
from this untracked directory). Nothing under `ir-pass/`, `include/`, `runtime/`, `tests/`,
`tools/` or `example/` was touched; no ctest was run.

## How each probe was run

* `.c` probes: `run.sh <name>` — `clang -Iinclude -include CQ.h -O1 -emit-llvm -S` →
  `build/ir-pass/cq-opt -load-pass-plugin build/ir-pass/libCQPass.so -passes=cq-lowering -S` →
  link `libcq_templates.a` **before** `libcq_runtime.a` → run → `tools/free_pairing_check.py`
  (STRICT, no `--allow-unproven`).
* `.s1.ll` probes (`h*`): `runll.sh <name>` — the same pipeline from stage 2 on **hand-edited IR**.
  Every `h*` file is a `p*` probe's own `-O1` output with the peel applied BY HAND (one merge phi
  replaced by a `select`, the other phis left alone); the header of each says which.
* `LLVM=/usr/local/opt/llvm@19/bin`. Decline anchors were read with `CQ_CTRL_DBG=1`.

`V0`..`V10` / `C1`..`C5` referenced in the SCOPE doc are the earlier measurement agent's probes and
live in the sibling scratchpad `ownerfile/`; the four re-run here are transcribed as
`p00_owner_bool.c` (= `V0`, the owner's file verbatim), `p01_owner_intb1.c` (= `V1`),
`p09_owner_int.c` (= `V9`) and `p85_v8int.c` (the int twin of `V8`); `c4_baseline_int_onephi.c` is `V9`'s `C4` verbatim.

## Verdicts (MEASURED, `main` `0c7380c`)

| probe | shape | verdict |
|---|---|---|
| `p00_owner_bool` | the owner's file verbatim (bool `b0`, bool `b1`) | **DECLINE** `control flow`, anchored `br i1 %1, label %4, label %2` |
| `p01_owner_intb1` | owner's file, `int b1` | **DECLINE** `control flow` |
| `p09_owner_int` | owner's file, `int b0` + `int b1` (compare condition) | **DECLINE** `control flow` |
| `p20_peel_bool_sel_first` | MANUAL peel, bool, select before the prep region | **DECLINE** `control flow` — `-O1` re-phi-ifies the select; stage-1 IR **byte-identical to `p01`** |
| `p21_peel_bool_sel_after` | MANUAL peel, bool, select after | **DECLINE** `control flow` (same re-fusion) |
| `p22_peel_int_sel_first` | MANUAL peel, int | **DECLINE** — stage-1 IR **byte-identical to `p09`** |
| `p23_peel_int_sel_after` | MANUAL peel, int, select after | **DECLINE** (same) |
| `h01a_peel_merge` | hand peel of `p01`, select in the MERGE | **DECLINE** `bare i1 register condition` (the ARM, bd `l4x4`) |
| `h01b_peel_pred` | hand peel of `p01`, select in the PRED | **DECLINE** `bare i1 register condition` |
| `h09a_peel_merge_cmp` | hand peel of `p09`, select REUSES the region's compare | **DECLINE** `condition data use neither escaped nor measured` (ziov) |
| `h09b_peel_pred_cmp` | same, select in the PRED | **DECLINE** (same) |
| `h09c_peel_owncmp` | hand peel of `p09`, select gets its OWN compare clone, in the MERGE | **ACCEPT** 22 lines, 2b `0 violation(s), 0 unproven` |
| `h09d_peel_owncmp_pred` | same but the select+clone in the PRED | **ACCEPT** 22 lines, 2b clean — trace DIFFERS from `h09c` (emission order) |
| `p30_chain_2phi` | 2 phis both arm-defined, arm fully speculatable | **ACCEPT** 25 lines (claimed by **PredMux**, not by the region path) |
| `h30_both_armdefined` | hand IR of the same | **ACCEPT** 25 lines (PredMux) |
| `h30b_armdefined_speculatable` | 2 phis, one arm-defined speculatable `mul`, arm ALSO holds a `cq_theta` | **DECLINE** `control flow` — PredMux E4 refuses the call; NOT peelable |
| `p88_two_preps` | 2 phis, BOTH arm-defined CALLS (two state preps in one arm) | **DECLINE** `control flow` — the decline that must SURVIVE |
| `p31_three_phi` | 3 phis (2 peelable data muxes + 1 prep) | **DECLINE** `control flow` |
| `h31_threephi_peeled` | the same, both muxes peeled (own compare clone each) | **ACCEPT** 33 lines, 2b clean |
| `p40_owner_sdagger` | owner's file + `b0 = cq_theta(b0,-0.5)` after the regions | **DECLINE** `control flow` (still the 2-phi wall — S† is BEHIND it) |
| `p50_fp_extra_phi` | extra phi typed `double`, consumed by `(int)d` | **DECLINE** `control flow`; `-O1` narrowed the mux to `i32` — not an fp probe |
| `p87_fp_mux` | extra phi genuinely `double` (a real fp data mux) + a state-prep arm | **DECLINE** `control flow` |
| `h87_fp_peeled` | the same, peeled | **DECLINE** `state prep seed is proven equal to the condition register` (F2) |
| `h87b_fp_peeled_seed7` | ditto with seed `7` instead of `0` | **DECLINE** (same string) — so it is NOT a real seed collision |
| `h87e_fp_otherlit` | ditto, clone compares against `99` | **DECLINE** (same) |
| `h87d_fp_constarms` | ditto, fp select arms are CONSTANTS | **ACCEPT** 25 lines, 2b clean |
| `h87f_nosel` | ditto, no select at all (the `fadd` kept live) | **ACCEPT** 15 lines, 2b clean |
| `h87c_fp_phase_peeled` | fp mux peeled, arm is a `cq_phi` PHASE | **ACCEPT** 21 lines, `cqrt_copy_f64_controlled` (kjd1), 2b clean |
| `p89_fp_control` | the prep region alone, no fp mux | **ACCEPT** 14 lines, 2b clean |
| `p60_phase_arm` | a-mux phi + a PHASE arm, int condition | **DECLINE** `control flow` |
| `h60_phase_peeled` | the same, peeled (merge left with ZERO phis) | **ACCEPT** 20 lines, kickback + 4.4 select, 2b clean |
| `h61_bool_phase_peeled` | `V4` (bool rail + phase arm + a-mux phi), peeled | **ACCEPT** 16 lines, 2b clean — **no `l4x4` needed** |
| `p70_call_arm` | 6.5-shaped arm with a foldable callee | **ACCEPT** 25 lines — `-O1` const-folded it to two selects, not a 6.5 arm |
| `p71_call_arm_opaque` | real 6.5 classical-call arm (`noinline const`, opaque arg) + a-mux phi | **DECLINE** `control flow` |
| `h71_call_arm_peeled` | the same, peeled | **ACCEPT** 25 lines, 2b clean |
| `p80_round2_out_cond` | a 6.5 region, then a FUSED 2-phi diamond whose condition reads its `%out` | **DECLINE** `control flow` — the wall is a **ROUND-2** region |
| `p81_round2_onephi` | the same with one phi (drop `cq_measure(a)`) | **ACCEPT** 22 lines, 2b clean — the round-2 path itself works |
| `h80_round2_peeled` | `p80` peeled | **ACCEPT** 33 lines, 2b clean |
| `p90_qq_mux` | extra phi over TWO TAINTED registers (`%p` vs `%p+3`, both pred-available) | **DECLINE** `control flow` |
| `h90_qq_peeled` | the same, peeled → a Q+Q 4.4 select | **ACCEPT** 23 lines, 2b clean |
| `p85_v8int` | int twin of `V8`: the ARM ROTATES the condition register, + a-mux phi | **DECLINE** `control flow` |
| `h85_v8int_peeled` | the same, peeled | **DECLINE** `condition predates a non-diagonal gate` — the wire fence fires |
| `h8v8_rotcond_peeled` | bool `V8`, peeled | **DECLINE** `bare i1 register condition` (arm classifier fires FIRST) |
| `c4_baseline_int_onephi` | `h09c`'s program with `cq_measure(a)` deleted (ONE phi) — the WITNESS BASELINE | **ACCEPT** 11 lines, 2b clean |
| `p86_two_armdefined` | intended non-peelable; `-O1` IPSCCP const-folded the chain on the equality edge | **DECLINE** `control flow` — probe is NOT the intended shape (superseded by `p88`) |

---

# IMPLEMENTATION-ROUND ADDENDUM (2026-09-11, bd `test_C_libtooling-b6ap`)

The `z*` files below were written by the IMPLEMENTATION agent, not the scoping
one. They are HAND IR (`runll.sh`-style, stage 2 onward) and every verdict is
measured on **both** binaries: **ORACLE** = the primary checkout's
`build/ir-pass/cq-opt` at `main` `0c7380c`; **SUBJECT** = the `merge-phi-peel`
worktree's own build with `peelIndependentMergePhis` in it.

`w01`/`w02` are the two committed e2e slices' sources, kept here so the probe
family and the slice family can be diffed against each other.

## What the implementation round probed that the scoping round did not

| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `z01_angletail_only` | 1 phi, a `phaseAngleTail` ANGLE, EMPTY arm | DECLINE `rotation angle` | DECLINE `rotation angle` (unchanged) |
| `z02_angletail_plus_mux` | the same + an int data mux, EMPTY arm | DECLINE `rotation angle` | DECLINE `rotation angle` (unchanged) |
| **`z03_tailphi_plus_mux`** | **an ANGLE-TAIL phi BESIDE a data mux, phase arm** | DECLINE `control flow` | **ACCEPT** — the peeled ANGLE goes to `classifyAngleSelect`'s **Rz stem** (two `cqrt_rz_i1` on one flag), **NOT** to the kjd1 fp data merge; there is no `cqrt_alloc_f64` anywhere. Committed as `control_peel_angle_tail_datamux.ll` |
| **`z04_hcrg_chain`** | **SCOPE H-1: two SEQUENTIAL fused regions, region 1's merge hosts region 2's branch AND the peeled select, and region 1's flatten ERASES it** | DECLINE `NESTED control flow` | **ACCEPT** 41 lines, 2b `0 violation(s)`, source order preserved, 4 flags freed. Committed as `control_peel_seq_chain.ll` |
| `z05_inloop` | a fused 2-phi region inside a classically-bounded loop | DECLINE `control flow` | DECLINE `control flow` — **P9**, the implementation's one added clause |
| `z06_nonmuxable` | the sibling phi is `i128` | DECLINE `control flow` | unchanged — P5 |
| `z07_condtree` | the condition is an `and` of two tainted compares | DECLINE `control flow` | unchanged — P7 / OQ-4 |
| `z08_threepred` | a 3-pred merge whose extra edge `-O1`… **does not** remove (the guard is a foldable INTERNAL global, so the edge IS folded before the peel) | DECLINE `control flow` | **ACCEPT** — a legitimate 2-pred merge by the time the peel runs; see `z13` for the real 3-pred case |
| `z09_undef_incoming` | the mux's pred incoming is `undef` | DECLINE `control flow` | unchanged — **P3b**, SCOPE H-9, which the scoping round left unprobed |
| `z10_identity_phi` | the sibling phi's two incomings are the SAME value | DECLINE `control flow` | unchanged — P6 |
| `z13_threepred_external` | `z08` with an **external** global, so the merge really has 3 preds | DECLINE `control flow` | unchanged — **P1**'s `hasNPredecessors(2)` |
| **`z15_round2_mux_raw`** | `p80` with the peeled mux consumed **raw** (not measured) | DECLINE `control flow` | **ACCEPT**, and the consumer lowers (`cqrt_addc_i32`) — the round-2 half of the taint finding below |
| **`z20_inplace_xor_bridge`** | **SCOPE H-5**: the condition wire is mutated IN PLACE by a dtzb `cqrt_xorc` before the region, and the peel puts a SECOND tainted compare on it | DECLINE `control flow` | **ACCEPT** — the `cqrt_xorc_i32(h, 9)` fires ONCE, before BOTH flag mints, and both mints read the same post-xor register. The clone is a second READ of the wire, never a second mutation |
| **`z22_argument_incoming`** | SCOPE §15.4 — P3 admits an `Argument` incoming | DECLINE `control flow` | **ACCEPT** — `cqrt_alloc_i32(i32 %u)` materialises the classical argument as one controlled-copy source, the shipped 4.4 mechanism |
| **`z23_pred_phi_incoming`** | SCOPE §15.4 — an incoming that dominates `BI` only through a CLASSICAL phi in `Pred` | DECLINE `control flow` | **ACCEPT**, 2b clean — the peel does not follow the phi, it just uses the value, and `DT.dominates` answers the question directly |
| **`z22_argument_incoming`** | SCOPE §15.4 — P3 admits an `Argument` incoming | DECLINE `control flow` | **ACCEPT** — `cqrt_alloc_i32(i32 %u)` materialises the classical argument as one controlled-copy source, the shipped 4.4 mechanism |
| **`z23_pred_phi_incoming`** | SCOPE §15.4 — an incoming that dominates `BI` only through a CLASSICAL phi in `Pred` | DECLINE `control flow` | **ACCEPT**, 2b clean — the peel does not FOLLOW the phi, it uses the value, and `DT.dominates` answers the question directly |
| **`z21_inplace_xor_after_merge`** | the same with a SECOND in-place xor sitting in the MERGE, after the phis | DECLINE `control flow` | **ACCEPT** — the clone is inserted at `getFirstNonPHI`, i.e. BEFORE that xor, so both flags read the PRE-mutation state exactly as the branch did; `cqrt_xorc_i32(h, 3)` is emitted after both strips |

## ⚠ THE FINDING: `z08`/`z11`/`z12`/`z16`/`z17`/`z18`/`z19` — "taint follows the phi" was WRONG

The peel's first spelling copied the **phi's** taint onto the select it built.
That is not what the source spelling produces, and the difference is a **wrong
unitary**, not a cosmetic one.

`propagateWorklist` taints **every user** of a tainted value (bar a measure sink
and an angle-only edge). A `phi` is **not** a user of the branch condition, so a
constant-armed merge phi is UNTAINTED; a `select` **is** one, so the identical mux
written in the source is TAINTED. With the select left classical its downstream
users stayed classical too, so a consumer of the 4.4 merge OUT-RAIL reached the
backend **un-lowered**:

```
  %s = add nsw i32 %m, %out      <- SUBJECT, first spelling: adds the runtime HANDLE TAG
  call void @cqrt_addc_i32(i32 %out, i32 %m)   <- ORACLE on the hand-peeled twin: correct
```

MEASURED at `opt` exit 0, verify-clean, stage-2b `0 violation(s)` on `z08`, `z18`
and `z19` — the bd `afmv` "handle tag, not the superposed value" class. `z12`
(the hand-peeled twin of `z08`) lowers it CORRECTLY **on the oracle**, which is
how the divergence surfaced at all: the peel's contract is *"produce the module
the hand peel already is"*, and a taint difference breaks it silently.

Fixed by tainting the select unconditionally **and** re-running the shipped
forward walk from the new values (`TaintPropagation::propagateFromSeeds`, one
spelling, never a second copy — Rule 14). After the fix `z08`'s lowered module is
**byte-identical** to `z12`'s. `z11`/`z16`/`z17` are the isolation ladder that
narrowed it (a raw select result in an `add`; the same module plus an unused
global; plus a foldable volatile guard) and are kept so the narrowing can be
re-walked.

## The two e2e slice sources

| probe | ORACLE | SUBJECT |
|---|---|---|
| `w01_slice_int_src.c` (= `p09_owner_int`) | DECLINE `control flow` | **ACCEPT 22 lines**, STRICT 2b clean |
| `w02_slice_phase_bool_src.c` (bare rail + phase arm + TWO muxes) | DECLINE `control flow` | **ACCEPT 28 lines**, STRICT 2b clean |

`w02` carries two muxes rather than one on purpose: with a single mux the merge
holds ONE phi and the `>= 2` containment gate refuses it (SCOPE OQ-5).

## `S02` / `S03` / `S04` — the ROUND-2 review's three, copied in from `review_b6ap_r2_probes/`

Added by the round-2 FIX (they are the reviewer's probes; the originals stay in
`review_b6ap_r2_probes/`, these copies are the ones the record cites).

| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `S02_stale_mux_record.c` | `int r = cq_theta(m,.2); int s = m + 1;` on the peeled mux — the peel flips the theta SOURCE → CHAINED, so `s` reads the rail's PRE-Ry record | `control flow` | **`cq opcode lowering: operand predates a non-diagonal gate`** (the twin gives the same string) |
| `S03_stale_mux_sibling.c` | the same with the `add` replaced by a SECOND chained theta — two SIBLINGS on one mux rail, both measured | `control flow` | **ACCEPT**, exit 0, 2b clean, ONE register: `ry(h8,.2); ry(h8,.6); measure(h8); measure(h8)` |
| `S04_sibling_plain_oracle.c` | the SAME defect with NO PEEL ANYWHERE (`int m = q + 1;`) | **ACCEPT on the ORACLE**, 8 lines, one register | same |

`S02` is **M-D's customer** — the only thing in the tree that pins call 5 of
`adjudicateTaintDelta` (`declineStaleRecordOps`); it is transcribed as the lit
fixture `control_peel_reject_stale_mux_record.ll`, whose header carries the
mutant.

`S03` is **bd `test_C_libtooling-3d8q`**, NOT this increment's: the pass-wide
stale-record guard sweeps PURE ops only, so a `cq_theta` / `cq_measure` READER of
a stale name is never asked. `S04` is the control that proves it — the same wrong
stream with no peel in the program, on the ORACLE. What IS this increment's is the
POPULATION: a 4.4 merge OUT-RAIL is now a shared parent, so `3d8q`'s customer set
grows with the peel, and its fix will have to cover a rail nobody wrote in the
source. Recorded here and on the `3d8q` issue; see IMPL §7 Q11.
