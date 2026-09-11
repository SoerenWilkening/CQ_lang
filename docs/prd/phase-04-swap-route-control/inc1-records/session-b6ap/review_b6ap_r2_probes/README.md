# `review_b6ap_r2_probes` — Rule-13 ROUND-2 probes (bd `test_C_libtooling-b6ap`, reviewing the round-1 FIX)

ORACLE `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass` (`main` `0c7380c`,
read-only). SUBJECT `/Users/sorenwilkening/Desktop/CQ_b6ap/build/ir-pass`
(branch `merge-phi-peel`, the round-1 fix). Nothing here was committed.

## Runners

| script | what |
|---|---|
| `./ab.sh <name>` | run `<name>.c` (or `<name>.s1.ll`) through BOTH binaries: exit code, first diagnostics, runtime trace, stage 2b |
| `./twin.sh <name>` | the CONTRACT test — SUBJECT's lowering of the FUSED module vs ORACLE's lowering of `<name>t_handpeel.s1.ll` |
| `python3 handpeel.py <name>` | build that twin MECHANICALLY from `<name>.s1.ll`: name every unnamed value/block, then replace each constant-incoming 2-value merge φ of the tainted diamond by an `icmp`/`fcmp` clone + `select`. This is the peel done by hand, so the twin is provably the SAME module |
| `./sweep.sh <dir>` | re-run a whole probe corpus on both binaries; prints `name \| oracle \| subject` |
| `./pair.sh <dir> <fused> <handpeeled>` | trace comparison for a pre-existing implementer probe pair |
| `auto/` | the generated twins + `auto/t.sh`, the batch form of `twin.sh` |
| `sweep_r1probes.txt`, `sweep_implprobes.txt` | the two corpus sweeps (39 + 48 entries) |

## Probes, by group

`⇄` = SUBJECT(fused) trace BYTE-IDENTICAL to ORACLE(hand-peeled twin);
`≡` = same diagnostic string as the twin.

### L — `lowerLoops` (`:365`), a taint-consuming stage NOT in the four
| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `L01_loopbound` | the mux is a LOOP TRIP COUNT | `control flow` | `nested control flow` (loud) |
| `L02_inloop_xorc` / `L03_inloop_addc` | in-place `^=`/`+=` with the mux as the immediate (`-O1` closes the form) | `control flow` | `muxed by a classical-condition phi` / ACCEPT (a correct Q+Q `add`) |
| `L04_inloop_xorc_real` / `L05_inloop_addc_real` | the same in a REAL rolled loop | `control flow` | `muxed by a classical-condition phi`; twins `L04t`/`L05t` decline `loop-carried tainted value crosses iterations` on BOTH ≡ |
| `L06_ctlz_idiom` | the ww4c shift-count idiom over a peel-tainted entry | `control flow` | `nested control flow` (loud) |

### I / M — `lowerControlledIOSinks` (`:349`) and P10's breadth
| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| `I01_io_arm_2phi` | a 2-φ merge with an I/O-sink arm | `conditional output is not a lowerable single-sink if(q) diamond` | **same string** — the stage's own decline closes the row |
| `I02_io_consumer` | the mux as an unconditional sink value | `control flow` | `continued lineage` (loud) |
| `M02` writer call / `M03` `memset` / `M04` `memcpy` / `M05` plain `store` | arms that WRITE but are not a `StoreInst` | `control flow` | `control flow` — all four |

### K — delta completeness, one consumer class each
`K01` later-block classical φ ≡ · `K02` `switch` ≡ · `K03` `llvm.bswap` ≡ ·
`K05` GEP `store` ≡ · `K07` i32 `ret` ≡ · `K08` output tape ≡ ·
**`K09` QROM index ⇄ · `K10` Shadow index ⇄ · `K11` chained `cq_theta` on the mux rail ⇄**

### R — the `r20` variations (brief item 4)
`r20` lowered IR vs `r23`: identical apart from `; ModuleID`.
`R01` two tainted args ⇄ · `R02` void helper that stores → loud spec decline ·
`R03` inlinable ⇄ · `R04` measure the mux itself ⇄ · `R05` transitive 6.3 clone ⇄

### S — M-D, `declineStaleRecordOps` over the delta
| probe | shape | ORACLE | SUBJECT |
|---|---|---|---|
| **`S02_stale_mux_record`** | `r = cq_theta(m,.2); s = m + 1;` — the peel flips the theta SOURCE → CHAINED, so `s` reads the pre-Ry record | `control flow` | **`operand predates a non-diagonal gate`** ≡ — **M-D's customer** |
| `S03_stale_mux_sibling` | two SIBLING thetas on the mux rail, both measured | `control flow` | ACCEPT, one register ⇄ — **bd `3d8q`** |
| `S04_sibling_plain_oracle` | the same defect with NO PEEL | **ACCEPT on the ORACLE, 8 lines** | same — proves `S03` is pre-existing |

### W — round-2 sites (brief item 6), on the round-2 pin's own hand-IR shape
`W20` store escape → `stored to memory` · `W21` unknown callee → `unknown callee` ·
`W22` Phase-6 clone ⇄ (39) · `W23` a ROUND-3 region on the round-2 mux ⇄ (41).
`W10`–`W13` are the plain-C attempts; `-O1` emits selects there, so they do not
reach the round-2 peel (recorded so the next round does not repeat them).

### A / Z / C / CF / CL / RL / BC — the rest
| probe | shape | outcome |
|---|---|---|
| `A01`/`A02` | a peeled ANGLE select into a Phase-6 candidate / a `cq_phi` | `rotation angle under quantum control` on BOTH |
| `Z02_9paa_unlowered_phi` | the delta contains an UNLOWERED region's merge φ; `detectSpecializations` at its third program point enters the call into `Pending` (fix OQ3) | ACCEPT ⇄ (48) |
| `C01_fcmp_cond` | the region's condition is an `fcmp` (the CLONE is an `FCmpInst`) | ACCEPT ⇄ (32) |
| `C02_invert` | a `cq_invert_begin/_end` bracket over a mux-derived chain | ACCEPT, emitted-symbol stream identical to the twin |
| `CF1_freeze_derived` | a `freeze` of a mux-derived value — the re-asked escape net's identity-freeze FOLD (a mutation) runs a second time | ACCEPT ⇄ (32) |
| `CL1_clone_body_control` | a candidate whose BODY has control, at the third program point | `callee contains tainted control flow under quantum lift` |
| `RL1`/`RL2` | the r9e5 rail fences (measured-before / sibling theta) through a rail-root peel | same string on BOTH |
| **`BC1_identity_bitcast`** | `bitcast i32 %mux to i32` — tainted only AFTER `foldIdentityBitcasts` ran | **FUSED: SUBJECT declines `no template for opcode 'bitcast i32'`; the HAND-PEELED twin lowers at exit 0 on BOTH binaries** — finding **F-B6R2-1** |
| `BC2_bitcast_control` | the same module with the bitcast on a propagate-time tainted value | `control flow` on both (not a clean control; the four-way `BC1` matrix in §4 is the measurement) |
