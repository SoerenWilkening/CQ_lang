# Increment 2 probes (bd `test_C_libtooling-fn1q`, the E6 rail LEAF)

```
ORACLE  cq-opt 1b396ed08b01b8ecac7… | SUBJECT cq-opt a179aba6192dbe963c7b…
```

| probe | what it exhibits |
|---|---|
| `railleaf_false_polarity.ll` | the arm on the FALSE successor — the polarity that routes ¬rail through `buildNegation`'s unchecked `cast<BinaryOperator>`. **Mutation-validated: without the rail arm this ABORTS.** |
| `railleaf_under_xor.ll` | a rail under a two-operand `xor i1` — the `Strict` boundary. Declines on both, by design. |
| `nonrail_i1.ll` | a tainted `trunc i32 %q to i1` condition — declines, because the leaf is `isCondRailLeaf` (a `cq_theta_i1` CALL) and not "any tainted i1" |
| `railphi_classical_prep.ll` | a 2-incoming `i1` φ whose prep sits under a **CLASSICAL** condition |
| `railphi_tainted_prep.ll` | the same with a **TAINTED** prep condition |
| `flat_trail.c` / `flat_trail2.c` / `rolled_trail2.c` / `unrolled_trail2.c` | protocol item 5 — a TRAILING non-diagonal gate on the condition's own register, at 4 and 2 variables, rolled and unrolled |
| `rolled_trail.c` / `unrolled_trail.c` | ⚠ **THE MIS-AIMED FIRST DRAFT, KEPT ON PURPOSE.** They write `bb[i]` twice per trip and die at `cq rail bank: array is written from more than one store site` — a RAIL-BANK fence with nothing to do with control. A verdict read off them is a verdict about the wrong fence (bd `46oo`). The `*_trail2.c` pair is the re-aimed version. |

## ⚠ THE MEASUREMENT THAT DECIDES INCREMENT 3, AND IT CORRECTS A FIXTURE HEADER

Measured on the E6-bypassed build (`CQ_PREDMUX_NOE6=1`):

| probe | verdict with E6 bypassed |
|---|---|
| `railphi_tainted_prep.ll` | **ACCEPTS** (exit 0) |
| `railphi_classical_prep.ll` | **still DECLINES** `control flow` |

So admitting `isCondRailPhiShape` at E6 is **not sufficient on its own**: the
downstream 4.4 select path proves a rail φ through `preppedRailPhiRegionIdx`, which
needs a CLAIMED state-prep region to own it — and a prep under a classical condition
is not a region at all.

⚠ **`ir-pass/test/control_predmux_reject_rail_phi_cond.ll` IS THE CLASSICAL-PREP
SPELLING, so its retirement trigger as first written ("when the rail-phi increment
lands this becomes an ACCEPT") IS FALSE** — it will still decline, for a second and
independent reason. Corrected at the source in the same change that records this
(L7: a record correction that is not applied to the source is not a correction), and
`railphi_tainted_prep.ll` is the shape increment 3 actually has to take.
