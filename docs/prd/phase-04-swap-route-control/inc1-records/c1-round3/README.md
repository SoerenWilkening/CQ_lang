# C-1 review round 3 (2026-09-06) — the reproducers, committed so they can be re-derived

Every program here is plain C, compiled with the ordinary slice pipeline
(`clang -Iinclude -include CQ.h -O1 -emit-llvm -S`, then `cq-opt -passes=cq-lowering`, then
`free_pairing_check.py`, link, run). The two-TU cases are `llvm-link`ed with `tu_extf.c`
(`int ext_f(int a){ return a+100; }`), which is what makes the `%out` rail a 6.5
classical-call arm whose DERIVED values are tainted only at ROUND 2.

Findings and dispositions are in `RETIRE_SWAP_ROUTE_INC1_NOTES.md` §3.11. The four binaries
named there are: **542d588** (the pre-fix subject, main), **FIX-1** (the round-1 C-1 fix),
**FIX-2** (the round-2 C-1 fix, `638334c`) and this HEAD.

| file | finding | 542d588 | FIX-1 | FIX-2 | HEAD |
|---|---|---|---|---|---|
| `z23_preadd_r2derived_imm.c` (+`tu_extf.c`) | F-C1B-1 | 47 lines, correct | 47, correct | **51, `cqrt_addc_i32(h7, 6)` — a rail handle in the immediate slot** | 47, byte-identical to 542d588 |
| `z26_preadd_r2derived_add1.c` (+`tu_extf.c`) | F-C1B-1, COMMUTED | 47 | 47 | **51, `cqrt_addc_i32(h6, 7)` — the WRONG rail mutated** | 47, byte-identical |
| `z27_prexor_r2derived.c` (+`tu_extf.c`) | F-C1B-1, xor stem | 47 | 47 | **51, `cqrt_xorc_i32(h7, 6)`** | 47, byte-identical |
| `z29_preadd_r2derived_and.c` (+`tu_extf.c`) | F-C1B-1, `y & 7` | 47 | 47 | **51, `cqrt_addc_i32(h7, 6)`** | 47, byte-identical |
| `z21_preadd_volatile_imm.c` | the (1a) COST | 3 mints / 0 `_unc` | 3/0 | 3/3 (a round-2 accept) | **3/0, byte-identical to 542d588** |
| `y1_preadd_chained_prerecord.c` | **F-C1C-1** | 33 lines, measures `h0`,`h1`,`h2` | 33, same | **39, measures `h0`,`h1`,`h0` — `q` and `a` collapse onto ONE register** | **LOUD DECLINE** |
| `y3_preadd_chained_prerecord_unrolled.c` | F-C1C-1's TWIN WITNESS | 39, `h0`,`h1`,`h2` | same | same | same — so on FIX-2 rolled ≠ unrolled |
| `y2_preadd_chained_nopreread.c` | F-C1C-1's ACCEPT control (one token) | 3/0 | 3/0 | 3/3 | 3/3, byte-identical to FIX-2 |
| `w3_claim_across_loops_measured_gate.c` (+`tu_extf.c`) | **F-C1B-2**, the observable pin | 3/0, 45 lines | 3/0, 45 | **3/3, 51 — loop B marked on loop A's claim** | 3/0, 45, byte-identical to 542d588 |
| `w3u_..._unrolled.c` | its twin | DECLINES on all four (`loop-carried rail has multiple in-place consumers`) | | | |
| `w4_claim_across_loops_two_invariants.c` (+`tu_extf.c`) | F-C1B-2's control | 3/3, 46 | 3/3 | 3/3 | 3/3, byte-identical on all four |
| `z32_claim_across_loops_nomeas.c` (+`tu_extf.c`) | the lens's own F-C1B-2 program | DECLINES `cq uncompute: tainted handle live range crosses a loop backedge` on all four — the marking difference is visible only under an instrumented build | | | |

`z32` is why F-C1B-2 was graded LATENT: it declines at a later fence on every binary. `w3` is
the fifth spelling, built in this round, that does not.
