# `railbank_twin_pairs` — the corpus of the register-twin decline gate

bd `xdu2` / L-1a W1, Rule-13 review F-1 (session 2026-09-15, fix agent).

Each row is TWO programs that denote the SAME circuit: `<name>.bank.c` writes a
rail into a bounded array (the rail bank) and `<name>.reg.c` is its ARRAY-FREE
spelling. `tools/railbank_register_twin_gate.py` asserts

* **P1 — the bank DECLINES whenever the register spelling DECLINES.** A breach is
  a VIOLATION and fails the gate: the register spelling saying *"this program has
  no valid circuit"* while the bank emits one is exactly review finding F-1.
* **P2 — when BOTH accept, the emitted traces are BYTE-IDENTICAL.** A breach is a
  TRACE-MISMATCH and fails the gate.

The converse — the bank declining where the register spelling accepts — is an
**over-decline**, printed and counted, never failed on (owner ruling 2026-09-11:
a defect to FILE, not a miscompile, and not a margin either).

> ⚠ **A pair is only as good as its twin-ness.** A `.reg.c` that is not the
> array-free spelling of its `.bank.c` measures the author's mistake, not the
> compiler's. The claim for each row is below, in one line, so the claim can be
> attacked rather than assumed.

| row | the claim | verdict on `784c14fa` (pre-fix) | verdict after the fix |
|---|---|---|---|
| `p01_stale_invariant_park` | ONE loop-invariant rail's name in N cells, the rail then relabelled non-diagonally, the cells measured after. **THE P1.** | **VIOLATION** | ok-both-decline |
| `p02_legit_order` | `p01` with the measure loop moved ABOVE the rotation. One line apart, a different circuit, and a legitimate one. | ok-identical | ok-identical |
| `p03_percell_theta_bool` | **THE CAPABILITY** — a DISTINCT theta per cell, minted INSIDE the walk loop. `_Bool` cells, the owner's own spelling. | ok-identical | ok-identical |
| `p04_percell_theta_int` | the capability at `int` cells. | ok-identical | ok-identical |
| `p05_stale_before_park` | the rail is relabelled BEFORE it is parked, so the parked name is already stale at the store. **Found by this gate, not named by the review.** | **VIOLATION** | ok-both-decline |
| `p06_double_measure` | one rail measured N times through the bank, then rotated. bd `yiid`'s boundary, NOT this fence's; both halves accept on the ORACLE. Kept so a future over-decline of it is visible as a row. | ok-identical | ok-identical |
| `p07_sibling_register_rotated` | per-cell theta bank PLUS an unrelated register rotated between the loops. A fence seeded with the wrong thing declines this. | ok-identical | ok-identical |
| `p08_nonmain_stale` | `p01` outside `main`, house style (two defines survive the lowering). | **VIOLATION** | ok-both-decline |

Rows added by bd `xdu2.1` (Track B, 2026-09-24), after bd `xdu2.4` made the bank
RUNTIME-SIZED. The third column is the verdict on `d0720cb1` (`cq-opt`
`c6f61f80a5d524c6`), i.e. the tree the rows were written against — the fence
already carried the memory hop, so there is no pre-fix column for these; their
red is the source-mutation matrix in `TRACK_B.md` §4.

| row | the claim | verdict on `d0720cb1` |
|---|---|---|
| `p09_rt_stale_invariant_park` | `p01` on a runtime-sized `int b[n]` bank — the hop's `isArrayAllocation()` branch. | ok-both-decline |
| `p10_parked_parent_add` | `q` parked, then `t = q + 3` (the M-C late in-place candidate on `q`), then the cells measured. If M-C converted the add in place the bank would read `q + 3`; it must stay out of place. | ok-identical |
| `p11_rt_parked_parent_add_loop` | `p10` on a runtime bank with a runtime-trip add loop on the parked parent. | ok-identical |
| `p12_phase_between` | a register-free `cq_phi` (diagonal) between park and read — must NOT count as a relabel. | ok-identical |

Rows added by bd `xdu2.1`'s Rule-13 round-2 finding F-1 (Track B, 2026-09-24):
a parked rail relabelled by an IN-PLACE `xor` the rolled in-loop collapse
commits. **These three were VIOLATIONs on the pre-fix binary** (`cq-opt`
`c6f61f80a5d524c6`, main `e36d9df4`: bank ACCEPTS, register twin declines
`rail record read past an in-place gate on the same rail`). That is the
review's measurement; this track re-measured it on the reviewer's probes.

| row | the claim | pre-fix | after the fix |
|---|---|---|---|
| `p13_inloop_xor_park` | `q` parked, then `for(k){ if(q>k) cq_phi(.3); q ^= 3; }`, then the cells measured (reviewer `P1_bank.c`). | **VIOLATION** | ok-both-decline |
| `p14_inloop_xor_park_other_cond` | `p13` with the loop condition on a different register `r` (`P1_bank_ry.c`). | **VIOLATION** | ok-both-decline |
| `p15_inloop_xor_const_trip` | constant trip count (3) and a trip-dependent immediate `q ^= k` (`r_qxk3_bank.c`). | **VIOLATION** | ok-both-decline |
| `p16_inloop_xor_read_before_and_after` | the bank read in one loop BEFORE the xor loop (legitimate) and one AFTER it (stale). Found by Track B's mutation matrix: a fence that asks only the first cell load passes it. | **VIOLATION** | ok-both-decline |

⚠ **Two shapes were measured and deliberately NOT added**, because their pair is
not a twin at the `-O1` floor rather than because the compiler is wrong
(`TRACK_B.md` §2): `q` parked, then `q = q + 3` / `q ^= 5`, then the cells
measured. `clang -O1` SINKS the add below the bank's measure loop in the bank
spelling and not in the register spelling, so P2 reports a TRACE-MISMATCH whose
two streams differ only in where one out-of-place `cq_template_add_i32_hl`
sits relative to three measures of the rail it READS — a computational-basis
copy that commutes with those measures. Rows `p10`/`p11` are the same question
with the order pinned by a use.

## What this corpus does NOT cover

Stated so absence is not read as clearance:

* it compares the bank against the register spelling **as this compiler treats
  it**, so a defect the two SHARE is invisible here. `p06` is that case by
  construction (bd `yiid`: `cq_measure` is not modelled as a wire event, so
  measuring one name repeatedly accepts in both spellings).
* **P2 compares the emitted STREAM**, not the unitary (Rule 2) and not rail
  identity (stage 2b's — and the two programs differ there by construction: N
  alloc SITES in the register spelling, one rolled site in the bank).
* every row here is ONE FUNCTION PER MODULE, which is bd `1yeu`'s structural
  instrument gap for the whole tree, not this gate's alone.
* the CONDITIONAL bank store has no row, because both of its condition classes
  decline before the question is decidable (review item I-2). When one accepts,
  this corpus owes a row — and so do the three obligations named at PASS G.
