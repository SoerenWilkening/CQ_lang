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
