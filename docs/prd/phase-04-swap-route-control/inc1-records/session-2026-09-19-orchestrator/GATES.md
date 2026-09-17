# GATES — session 2026-09-19 (bd `zujr`)

Every row is hash-keyed to the binary it was measured on (PROTOCOL F-11). Nothing
is copied forward; each line was re-run on the binary named.

ORACLE  `cq-opt` `07d937842bfb5135…`  (`main` `bda59791`, `libCQPass.so` `19dcfde08ffbb69c…`)
SUBJECT `cq-opt` `e7bbfd69a9e25d38…`  (`libCQPass.so` `84061321f9d6f974…`)  ← the closing binary

| gate | result | cited on |
|---|---|---|
| full `ctest -j6` | **464/464 in 561.64 s** (load 6.5) | `e7bbfd69…` |
| `cq-opt-equivalence-full` | **2106 fixtures, 0 mismatches** | `e7bbfd69…` |
| `e2e-loop-twin-matrix` | all 312 cells match; **70 quarantined cells diverge with their pinned signature**; **4/4 boundary controls** as pinned | `e7bbfd69…` |
| corpus A/B, all `ir-pass/test/*.ll` | **15 movers of 2106 — 12 D→A, 3 D→D with a moved string, ZERO A→D** | `07d93784…` vs `e7bbfd69…` |
| the owner's rolled cascade | `opt` exit 0, stderr 0 bytes, **50 trace lines**, STRICT 2b `2 verified, 0 violation(s), 0 unproven` | `e7bbfd69…` |
| K-independence | **75 lowered lines at K=3 and at K=1000** | `e7bbfd69…` |
| conjunct mutant matrix (Rule-12/F-6) | **1:1, MISSED 0** — Z3→narrow_width, Z4→tainted_seed, Z6→accumulator, Z8→guarded, each killing its own fixture and no other; the Z3 mutant aborts `opt` with exit 134 on a verifier-invalid module | four scratch mutant builds |
| fixture non-vacuity | all 11 re-derived railbank fixtures and the 2 new accept fixtures **FAIL on the ORACLE** | `07d93784…` |
| twin-matrix header preservation (bd `gfsk`) | `--regenerate` **preserved 493 header lines byte-for-byte**; diff of `^#` lines EMPTY | `e7bbfd69…` |

## Counts at close (re-measured, not quoted)

| quantity | value |
|---|---|
| ctest entries | **464** (was 459) |
| `^e2e-` | **454** (was 449) |
| `^e2e-slice-` | **396** (was 392) |
| `twin-identical` | **44** (was 43) |
| `ls ir-pass/test/*.ll` | **2106** (was 2099) |
| `ls tests/e2e/*.expected.log` | **398** (was 394) |
| twin matrix | **312** expected + **70** quarantine = **382** cells (unchanged) |
| `--allow-unproven` usages | **16** grep hits in `tests/e2e/CMakeLists.txt` (4 slices × 4 lines; unchanged) |

## ⚠ What was NOT run

The Rule-13 round-1 reviewer ran **no ctest entry and no full suite** — by
instruction, so it could not perturb the binaries it was measuring. Its
corroborations are IR-level and e2e-slice-level only, and they are listed in
`REVIEW_R13.md`. **Rounds 2 and 3 of bd `zujr`'s own ≥3-round budget are OWED and
are filed, not done.**
