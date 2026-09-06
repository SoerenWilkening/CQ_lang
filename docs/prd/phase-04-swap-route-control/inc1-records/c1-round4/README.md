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
