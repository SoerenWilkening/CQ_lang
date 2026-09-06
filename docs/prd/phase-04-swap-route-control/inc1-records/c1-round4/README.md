# c1-round4 — the reproducers of the FOURTH C-1 round (bd `7yd0`, 2026-09-06)

Committed following the `c1-round3/` precedent so a re-clearance can re-derive every number
without the session scratchpad. Full argument: `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.14**.

Two binaries, named everywhere below:
* **`main`** = `/Users/sorenwilkening/Desktop/CQ_lang` @ **a3c1513** (Inc 0 + Inc 1 landed).
  This is the PRE-FIX subject; it was never edited or rebuilt by this round.
* **`fix`** = branch **`c1-round4`** (this tree).

Pipeline for every row: `clang -O1 -include CQ.h` → `cq-opt -passes=cq-lowering` →
`free_pairing_check.py` (STRICT) → link (templates before runtime) → run. `opt` exits 0 and
stage 2b reports `0 violation(s), 0 unproven` for EVERY row on BOTH binaries — the defect is
invisible to both gates, which is the point.

`mints/unc` = `cq_template_{and,lshr}_i32_hl` mints / `_hl_unc` discharges in the TRACE.

| program (+ its `_unrolled`/`_u` twin) | what the invariant root is | `main` rolled | `main` twin | `fix` rolled | `fix` twin |
|---|---|---|---|---|---|
| `q5sel_preadd_*` | **4.4 SELECT merge** `%out` | 4/0, 44 lines | 4/4, 52 | **4/4, 52** | 4/4, 52 — **`cmp` IDENTICAL** |
| `q4b_preadd_*` | **Phase-4 VALUE-ARM ROUTE** `%out` (`cqrt_copy_i32`) | 4/0, 57 | 4/4, 65 | **4/4, 65** | 4/4, 65 — **IDENTICAL** |
| `q7_k32_*` | 4.4 select merge, **K = 32** | **32/0**, 240 | 31/31, 301 | **32/32**, 304 | 31/31, 301 — twin unfaithful at bit 31 (`ashr`), so the O(K) claim is the ROLLED column |
| `g1_region_then_preadd_*` | a `cq_theta` ROOT MINT whose OTHER use is a **preceding REGION's compare** (no merge at all) | 3/0, 36 | 3/3, 42 | **3/3, 42** | 3/3, 42 — **IDENTICAL** |
| `c2_m04_onward_then_preadd` (needs `tu_extf.c`) | the same, with a **6.5 classical-call arm** as the preceding region | 3/0, 43 | — | **3/3, 49** | — |
| `q5v_xor{,_u}` | 4.4 select merge, `m ^= 7` | 4/0, 44 | 4/4, 52 | **4/4, 52** | 4/4, 52 — but the twin is UNFAITHFUL (`-O1` distributes `xor` over the bit test; the documented `xorpre`/`r71` class), so nothing witnesses it |
| `q5v_none{,_u}` | merge, **NO preheader op** — BOUNDARY CONTROL | 4/4, 51 | 4/4, 51 | 4/4, 51 | identical — **unchanged** |
| `q5ctl_theta_preadd_*` | theta root, **WITH** a preheader op — BOUNDARY CONTROL | 4/4, 40 | 4/4, 40 | 4/4, 40 | identical — **unchanged** |
| `q5w_mux_*` | 4.5 switch DATA-MUX | identical | identical | identical | measured OUT of the population: all-`ConstantInt` arms fold the preheader op into the case constants |
| `o1_call_preadd_*` (needs `tu_extf.c`) | 6.5 arm `%out` with a preadd | DECLINE `cq controlled lowering: value-arm swap-route under quantum control` | — | same DECLINE | — — the 6.5 MERGE row is UNREACHABLE, not unfixed: with a constant else-value `-O1` sinks the `+7` INTO the arm |
| `x2_preadd_keep` | LEAK CONTROL — the pre-op value is READ later | 3/0 | — | 3/0 **byte-unchanged** | — M-C itself goes out of place (G6), so the commit still refuses |
| `c2_m11d_two_loops_no_preadd` | OQ-C2-1's own program | 6/3, 62 | 6/6, 68 | 6/3, 62 **byte-unchanged** | ⚠ **NOT bought back** — refused by the M-C fence (G7 arm (e)), not by `hasOneUse` |
| `y1_preadd_chained_prerecord` | the round-3 F-C1C-1 program | DECLINE `cq loop lowering: pre-loop in-place op no longer provable at lowering` | — | same DECLINE | — the (1b) tripwire, still the net |

## The whole-population figure

485 programs (the union of every `p/` directory of session `adc5590a` — `fix_c1_work`,
`review_c1_work`, `fix_c1b_work`, `review_c1b_work`, `fix_c1c_work`, `review_c1c_work`,
`clearance2_work` `p/`+`p2/`+`p3/`, `review_inc2_r2_work`, plus this round's own), each run on
`main` and on `fix` and compared by normalised STATUS **and** by byte-diff of the trace:

**477 UNCHANGED, 8 MOVED** — `q5sel_preadd_rolled`, `q4b_preadd_rolled`, `q7_k32_rolled`,
`q5v_xor`, `c2_m04_onward_then_preadd` and the two new twin-matrix cells (all 6 gaining
`_unc` + `cqrt_free` pairs), plus `c1c_a1_constexpr_imm`, whose LOWERED IR is byte-identical
and whose only difference is the printed value of a `ptrtoint (@g_tab+12)` load address in two
separately linked binaries (the artefact `review_c1c` recorded on the same probe).

**0 ACCEPT → DECLINE, 0 DECLINE → ACCEPT, 0 decline strings changed**
(`ACCEPT→ACCEPT 332 · DECLINE→DECLINE 122 · LINKFAIL 2 · S1FAIL 29`, the last two classes
identical on both binaries by construction). STRICT stage 2b over all 332 `fix` accepts:
**330 `0 violation(s), 0 unproven`, 2 `0 violation(s), 4 unproven`** — the two are
`f0_break_plain` / `f3_break_global_phase_before`, the `--allow-unproven` dtzb break family.

---

## REBASE onto the landed Increment 2 (2026-09-06, session `82e6b530`)

⚠ **EVERY `main` COLUMN ABOVE WAS MEASURED AGAINST a3c1513 AND THAT COMMIT IS NO LONGER
`main`.** `main` is now **b99b853** (docs) on top of the CODE commit **258d974** — Inc 2, value
arms by the CONTROLLED-COPY MERGE. The lens `review_c1d.md` (F-C1D-1) re-measured the finding on
that landed binary and it is **still live there**: `q4b_preadd` 4/0 (52) vs 4/4 (60),
`q5sel_preadd` 4/0 (44) vs 4/4 (52), `g1_region_then_preadd` 3/0 (36) vs 3/3 (42). So the table's
`main` columns are correct **as of a3c1513** and the rows whose LINE COUNTS moved with Inc 2 are
re-measured against 258d974 in the `q4b` block below.

**Duplicated reproducers, deliberately.** Increment 2 committed its own copies of fourteen of
these files at `docs/prd/phase-04-swap-route-control/inc2-records/` — `q4b_preadd_{rolled,unrolled}.c`,
`q5sel_preadd_*`, `q5ctl_theta_preadd_*`, `q5v_{none,xor}{,_u}.c`, `q5w_mux_*`, `q7_k32_*` — and
they are **byte-identical to the copies here** (spot-checked with `diff -q` on
`q4b_preadd_{rolled,unrolled}`, `q5sel_preadd_rolled`, `q7_k32_rolled`). Neither copy is deleted:
`inc2-records/` records what the Inc-2 review measured on ITS binary, `inc1-records/c1-round4/`
records what this round measured on `main` a3c1513 and on the fix. Read them as two measurements
of one program, not as one file in two places.

### `q4b` re-measured on the landed Inc 2 — the row this round could only ARGUE

`q4b_preadd_{rolled,unrolled}.c` is the same source in both directories. Its `%out` producer
CHANGED with Increment 2: on a3c1513 it was the **Phase-4 value-arm ROUTE** (one `cqrt_copy_i32`
into `%out` after a `cqrt_cswap` route); on 258d974 it is the **CONTROLLED-COPY MERGE** (two
`cqrt_copy_i32_controlled`, no route at all). The trace LINE COUNTS move with that, which is why
the table above (57 / 65) and this block (52 / 60) disagree and both are right.

| binary | rolled (`and|lshr _hl` mints / `_hl_unc`, lines) | hand-unrolled twin | `cmp` |
|---|---|---|---|
| `main` **a3c1513** (the table above) | 4 / 0, 57 | 4 / 4, 65 | DIVERGE |
| `main` **258d974** (Inc 2 landed) | **4 / 0, 52** | 4 / 4, 60 | **DIVERGE, 8 lines** |
| REBASED `c1-round4` | **4 / 4, 60** | 4 / 4, 60 | **IDENTICAL** — and byte-identical to `main` 258d974's OWN unrolled twin |
| ORACLE **52d7764** | *unexpressible* — stage 1 fails, the shipped `void cq_phi(double)` does not exist there. Its register-form transliteration (`p = cq_phi(p, 0.7)`) is a DIFFERENT program: the ROLLED spelling DECLINES (`cq taint escape: tainted value muxed by a classical-condition phi`) and the UNROLLED one accepts at 4/4, 65 lines, emitting 4 `cqrt_cswap` + 4 `cqrt_rz_i32_controlled` — the routed TENSORED Rz this epic retired | — | — |

STRICT stage 2b is `0 violation(s), 0 unproven` on every row that lowers, on both binaries.
Pinned by `ir-pass/test/control_phase_kickback_mixed_value_merge_preadd_inloop.ll` and the
e2e pair `tests/e2e/slice_control_phase_perbit_loop_value_merge_preadd{,_unrolled}.c` +
`e2e-phase-perbit-loop-value-merge-preadd-twin-identical`. Narrative:
`RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.15**.

---

## The lens on the REBASED tree (`review_c1e`, 2026-09-06) — the `c1e_a*.c` reproducers

The independent Rule-13 lens on the rebased branch (`aa9d702`) returned **CLEAR-WITH-ITEMS**
(`inc1-records/session-82e6b530/review_c1e.md`). Its finding **F-C1E-2** is a **LEAK class that is
PRE-EXISTING and byte-identical to `main` 258d974**: a preheader in-place op whose PARENT has a
second *unlowered tainted* user is correctly refused by `classifyInPlaceReassignment` (G7 arm (e),
or G6 when the merge's copies are emitted after the pre-op), so the commit never marks it, the
preheader op lowers OUT of place onto a fresh rail, and the loop body's per-activation which-path
ancillas keep leaking. **Round 4 neither introduced nor widened it**; on one member it strictly
improves it. Sixteen files, eight rolled/unrolled pairs, copied here verbatim from the lens's
attack battery so the class has reproducers in the tree rather than only in a scratchpad.

RE-MEASURED for this record by `docs_c1e` (full pipeline, STRICT stage 2b, `main` 258d974 and the
rebased branch), counting `cq_template_{and,lshr}_i32_hl` MINTS / `_hl_unc` DISCHARGES in the trace:

| file (`c1e_…_{rolled,unrolled}.c`) | the shape | `main` rolled | this branch rolled | unrolled twin | rolled trace, main vs branch |
|---|---|---|---|---|---|
| `a1_head_add_read_by_loop` | a dtzb-shaped chain head `c = p + 3` that the LOOP reads (`t = c + 7`) | 4/0, 44 | 4/0, 44 | 4/4, 52 | **byte-IDENTICAL** |
| `a2_source_p_preadd` | the preadd is on the value arm's SOURCE `p`, not on `%out` | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a3_chainfinal_preadd` | the preadd is on the arm's CHAIN-FINAL, which the merge also reads | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a9_out_prevalue_measured` | `int keep = p;` before the preadd, `keep` measured after — a CORRECT G6 refusal, the `x2_preadd_keep.c` control one shape over | 4/0, 45 | 4/0, 45 | 4/4, 53 | **byte-IDENTICAL** |
| `a11_select_head_add` | the same as `a1` over a 4.4 `select` merge | 4/0, 44 | 4/0, 44 | 4/4, 52 | **byte-IDENTICAL** |
| `a4_out_two_loops` | merge `%out`, `+7`, loop, `+5`, second loop | 8/0, 73 | 8/0, 73 | 8/8, 91 | **byte-IDENTICAL** |
| `a17_out_two_loops_nofold` | the same with `^5` between the loops | 8/0, 73 | **8/4, 81** — the FIRST loop discharges | **DECLINES on BOTH binaries** (`cq controlled lowering: condition predates a non-diagonal gate under quantum control`), so there is no byte-identity witness | main ≠ branch — a strict IMPROVEMENT |
| `a16_source_p_preadd_diffusion` | `a2` plus a post-loop diffusion `t = cq_theta(t, .11)` | **DECLINES** `cq controlled lowering: control flow under quantum control` | same decline | same decline | — |

⚠ **ONE REFINEMENT TO THE LENS'S OWN WORDING, measured separately here.** F-C1E-2 groups
"`a4`/`a17` … 8/0 on main, 8/4 on the subject". That is **`a17` alone**: `a4` is 8/0 on BOTH
binaries with byte-identical rolled traces. The two sources differ by one token (`p = p + 5` vs
`p = p ^ 5`).

**Why this is a leak and not a wrong unitary, stated as measured.** `a16` is the diffusion variant
— the shape that would turn a leaked which-path record into interference between branches carrying
distinct ancilla labels — and it **DECLINES loudly on every binary**. STRICT stage 2b reports
`0 violation(s), 0 unproven` on every accepting row above, which is the epic's standing point: a
TEMPLATE-minted rail has no `cqrt_alloc` for the checker to count. The class is the disclosed
OQ-C1D-1 / PRD §0 **E2** residual, one shape over; tracked on bd `test_C_libtooling-3qlq.13`.
Narrative: `RETIRE_SWAP_ROUTE_INC1_NOTES.md` **§3.15**.

⚠ Four of the lens's OTHER attack twins are **UNFAITHFUL, not defects** (finding F-C1E-3) and are
deliberately NOT copied here — `a8` (`^6`), `a10` (`+7; ^6`), `a15` (`+7; +5`) and `a17`: when the
constant's low bits are clear, `-O1` DISTRIBUTES the per-bit test onto the PRE-op register on the
UNROLLED side only, so the two spellings stop being the same program. That is the documented OQ-27 /
`m_xor_range` quarantine class and CLAUDE.md's own `addpost` precedent. `q4b`'s `+7` is immune
because 7 has all its low bits set.
