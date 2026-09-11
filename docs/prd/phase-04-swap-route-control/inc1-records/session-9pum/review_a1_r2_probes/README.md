# `review_a1_r2_probes` — Rule-13 ROUND-2 probes for Track A.1 (reviewing the round-1 FIX)

> ⚠ **ERRATA 2026-09-11 — THREE ROWS BELOW ARE STALE AND READ AS IF A MISCOMPILE STILL SHIPS.**
> This file was written against the pre-round-2-fix checkpoint `b439944`. On the LANDED commit
> `7203d1c` the three `ACCEPT ✘` rows **`io3.c`, `gs1.c` and `multi/io3m.c` are DECLINE**
> (`condition predates a non-diagonal gate`) — F-A1R2-1 is CLOSED by the round-2 narrowing of the
> `Covered` exemption to a per-entry `WireRuled` bit, and the pre-existing 7.6 I/O-sink / 7.5
> guarded-Shadow-store flag-mint hole it names is filed and CLOSED as bd `test_C_libtooling-61k6`.
> Every other row in this file is unmoved, including the discriminators that make those three
> readable (`io5` already DECLINE, `io0`/`gs0` accept controls, `io4` DECLINE on both, the seven
> `c_*` consumers). See `../FIX_A1_R2.md` for the fix and `../../session-f2-i1/MERGE_f2_1.md` §4.5
> for the independent re-measurement of exactly these three rows on the merged tree.

`./run.sh` re-derives every verdict table in `../review_a1_r2.md` on BOTH binaries.
It compiles into `mktemp -d` only and writes nothing here.

  ORACLE  `/Users/sorenwilkening/Desktop/CQ_lang/build/ir-pass`   (`main` 0c7380c, read-only)
  SUBJECT `/Users/sorenwilkening/Desktop/CQ_trackA/build/ir-pass` (checkpoint `b439944`)

Override with `ORA=`, `SUB=`, `LLVM=`, `INC=`. Single-TU probes are plain `clang -O1`;
`multi/*.c` are TWO TUs (`<probe>.c` + `multi/lib3.c`) built per-TU at `-O1`, `llvm-link`ed,
then ONE `cq-lowering` — the shipped 6.5 `%out` recipe.

Round-1's probes are NOT duplicated here; run `../review_a1_r1_probes/run.sh` for `k*`, `c*`,
`b1`/`b2`, `o7*`, `g*`, `sp*`, `sw*`, `o3_kick`.

## The headline pair (F-A1R2-1 — CONFIRMED silent miscompile, PRE-EXISTING)

| probe | consumer | ORACLE | SUBJECT | note |
|---|---|---|---|---|
| `io3.c` | 7.6 controlled I/O sink | ACCEPT | **ACCEPT** ✘ | flag minted from `Ry(.9)Ry(.25)`; stream byte-identical to the oracle |
| `gs1.c` | 7.5 guarded Shadow store | ACCEPT | **ACCEPT** ✘ | same, `cqrt_qram_store_i32_controlled` |
| `io4.c` | phase kickback, SAME wire shape | DECLINE | DECLINE ✔ | the project's own verdict on the shape |
| `multi/io5.c` | 7.6 sink, sibling revealed only at ROUND-2 taint | ACCEPT | **DECLINE** ✔ | not in the blind set ⇒ not exempted — the discriminator |
| `multi/io3m.c` | `io3` as two TUs | ACCEPT | ACCEPT ✘ | pairs with `io5` on one harness |
| `io1.c` / `gs2.c` | same consumers, condition MEASURED before | ACCEPT | DECLINE ✔ | proves the record + rung (ii) reach them |
| `io0.c` / `gs0.c` | clean controls | ACCEPT | ACCEPT | — |
| `c_{sel,kick,angle,call,val,nest,abort}.c` | the consumers that DO catch it | DECLINE | DECLINE | the population boundary |

## F-A1R2-2 — Q-3: the `InPlaceRailOps` crossing has a reachable DECLINE face

| probe | ORACLE | SUBJECT | note |
|---|---|---|---|
| `f4f.c` | ACCEPT | **DECLINE** | `measure(h); xorc(h,9); icmp_sgt(h,5)` — bd `r903`(b) through an in-place relabelling. Declines ONLY because of the crossing |
| `f4h.c` | ACCEPT | ACCEPT | the same loop with a DIFFERENT register measured — the discriminating control |
| `f4a.c` | DECLINE (`staleRailRecordRead`) | DECLINE (new rung) | `add` spelling: `-O1` rewrites the compare SIDEWAYS onto the measured register, which is why the fix's `ip1`/`ip3` missed the face |
| `x1`/`x2`/`x3`/`m1` | ACCEPT | mixed | the straight-line `xor` vs `add` asymmetry; M-C refuses in-place there (G7), so `x1`/`x3` accept CORRECTLY on a fresh `cq_template_xor_i32_hl` rail |

## F-A1R2-3 — the rail-path accept class (three further members beyond `b1`/`b2`)

`r3.c` (loop-carried classical seed), `b3.c` (loop-invariant non-constant seed — `-O1` does not
LICM the mint out), `b4.c` (mint in a guarded sub-block) — all DECLINE → ACCEPT, all correct.
`r1.c` (origin in the preheader, register loop-carried), `r2.c` (chained in-body theta) decline
on both, as they must. `r4.c` is the compare twin of `b1` (accepts on both).

## The rest

`s01`–`s07` decline shapes (all ACCEPT → DECLINE, all correct); `a01`–`a07` accept controls;
`od1`–`od4` over-decline hunt (`od1b` is `od1`'s `_Bool` twin and declines on `main` too —
parity, not a new refusal); `d3a`–`d3d` the drbq Inc-3/Inc-4 arms; `ab0`–`ab2` the abort park;
`f4b`–`f4e` the cast and Q+Q faces (Q-5: both operands ARE seeded); `multi/w3`–`w11` the
round-2 window at six consumers; `multi/q4a`/`q4b` the Q-4 attempt (declines earlier on both).
